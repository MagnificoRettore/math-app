# Math App

Applicazione Flutter per **studenti italiani** con esercizi di matematica **risolti passo-passo** (Scuola Media, Scuola Superiore, Università) e **lezioni guidate interattive**. Tutti i contenuti sono inclusi offline come asset JSON; l'interfaccia è interamente in **italiano**.

## Caratteristiche

### Esercizi risolti
- **26 esercizi** organizzati in 3 livelli scolastici, 11 corsi, 13 sezioni e 21 argomenti.
- Ogni esercizio include: problema, **formule chiave** (LaTeX), **suggerimenti** espandibili e **soluzione passo-passo**.
- **Filtri per difficoltà** (Tutti, Facile, Medio, Difficile) nei feed e nell'elenco degli esercizi dell'anno.
- **Stato di avanzamento** per esercizio: *Assimilato* / *Da ripassare* (con feedback tattile), barre di progresso per corso/argomento.
- **Segnalibri**: esercizi salvati e accessibili dalla schermata dedicata o dall'app bar della Home.

### Lezioni guidate interattive
- **5 lezioni** passo-passo con esercizi interattivi (totale 15 passaggi).
- Tipi di passaggio: **multiple choice**, **input numerico** (tolleranza sui decimali, supporto frazioni `a/b`) e **input testuale**.
- Feedback immediato: risposta corretta (feedback verde, `HapticFeedback.lightImpact`) o errata (feedback rosso con **animazione shake**, `heavyImpact`).
- **Animazioni interattive** all'interno delle lezioni: torta delle frazioni (`AnimatedFractionPie`) e retta numerica (`AnimatedNumberLine`).
- **Barra di avanzamento animata**, transizioni fade+slide tra i passaggi e **celebration finale con confetti** al completamento della lezione.
- Riconoscimento del completamento con **serie giornaliera** e obiettivi.
- **Immagini introduttive**: ogni lezione può includere un'immagine nella card di introduzione tramite il campo `"image"` nel JSON.

### Studio e motivazione
- **Serie giornaliera (streak)** con record personale e obiettivi giornalieri: **5 esercizi** e **10 minuti** di studio (contatore minuti attivo tramite osservatore di sessione).
- **Punti deboli**: calcolo automatico degli argomenti da ripassare (da `ExerciseStatus.needsReview`), con sezione dedicata in Home, schermata di dettaglio con lezioni consigliate e celebrazione quando il punto debole viene risolto.
- **Consigli personalizzati**: lezioni ed esercizi suggeriti in base al livello scolastico e ai progressi.

### Ricerca
- **Ricerca full-text** (da Home, debounce 300 ms, minimo 2 caratteri) su argomenti, esercizi (titolo, tag, formule, problema, passaggi) e lezioni; risultati raggruppati per categoria.

### Profilo e onboarding
- **Onboarding** a 3 slide al primo avvio.
- **Registrazione**: account locale (nome, email, password, con validazione) o **Google** (demo locale senza credenziali), entrambi con **scelta del livello scolastico**.
- **Selezione scuola** anche in un secondo momento dal Profilo; profilo con avatar a iniziali, metadati e **tema scuro** (chiaro / scuro / sistema).
- Vista ospite in Home e Profilo con invito alla creazione del profilo.

### UI
- **Material 3**, design minimalista ispirato a iOS, palette determinata per tema (chiaro/scuro).
- **Barra di navigazione "Liquid Glass"** flottante a 4 voci (Home, Lezioni, Esercizi, Profilo) con effetto vetro sfocato, navigazione a **tap e drag**, indicatore animato; se assente un profilo, apre il bottom sheet di scelta scuola.
- **LaTeX offline**: testo matematico renderizzato con `flutter_math_fork` (KaTeX in Dart puro, nessun WebView). Delimitatori `$...$` (inline) e `$$...$$` (blocco) nei contenuti.
- Animazioni: splash/onboarding con fade, transizioni in fade tra le tab, card animate, confetti.
- **Tab annuali con immagine**: i cerchi delle tab anni mostrano un'immagine per corso se presente nel JSON (`"image"`); in caso contrario — o se l'asset manca — mostrano i numeri romani (I–V). Le label degli anni usano i nomi ordinali (*prima, seconda, terza, quarta, quinta*).
- Solo **orientamento portrait**, app in italiano.

## Stack tecnologico

| Componente | Tecnologia |
|---|---|
| Framework | Flutter 3.47.2 (stable), Dart SDK 3.13.2 |
| Renderer LaTeX | `flutter_math_fork` ^0.7.4 (offline, no WebView) |
| Persistenza | `shared_preferences` ^2.5.5 |
| State management | `ChangeNotifier` + `ListenableBuilder` (niente Riverpod/Bloc/Provider) |

Nessuna chiamata di rete, nessun code generation, nessuna dipendenza di gestione stato di terze parti.

## Architettura

```
lib/
  main.dart              # entry: orientamento portrait + runApp
  app.dart               # MathApp (MaterialApp, tema chiaro/scuro, session observer)
  theme/                 # app_theme.dart, app_colors.dart, topic_style.dart
  models/                # plain Dart class: level, course, section, topic, exercise,
                         # difficulty, progress, lesson, lesson_step, user_profile,
                         # weak_topic
  data/                  # repository + store singleton:
                         # content_repository, lesson_repository, progress_store,
                         # auth_store, settings_store, study_store, search_index,
                         # recommendation_engine, weak_topic_engine
  screens/               # 21 schermate (full-page)
  widgets/               # 25 widget riutilizzabili
assets/
  data/                  # levels.json, middle_school.json, high_school.json,
                         # university.json, lessons.json
  images/                # asset immagini: copertine argomenti, cerchi degli anni,
                         # immagini introduttive delle lezioni
```

### Modelli dati
- **Level** → Livello scolastico (`id`, `title`, `subtitle`, `icon`, `dataFile`) che punta al JSON del corso.
- **Course / Section / Topic / Exercise** → gerarchia corso-anno → sezione → argomento → esercizio (con `difficulty`, `tags`, `formulas`, `hints`, `steps`). `Course` e `Topic` hanno un campo opzionale `image` per i cerchi degli anni / le copertine.
- **Difficulty** → enum `easy` / `medium` / `hard` con `fromString()` e label italiane.
- **ExerciseProgress** → stato (`none` / `mastered` / `needsReview`) + segnalibro per esercizio, con **chiave composita** `levelId::exerciseId`.
- **Lesson / LessonStep** → lezione guidata con passaggi (`multipleChoice`, `numeric`, `text`), animazione associata (`pie`, `numberLine`, `none`) e `checkAnswer()` che normalizza input (minuscole, spazi, virgola→punto, tolleranza 1e-6, frazioni).
- **UserProfile** → profilo locale (`AuthMethod` manual o google), salvato su dispositivo.
- **WeakTopic** → argomento debole calcolato dal `WeakTopicEngine`.

### Repository e store (singleton `ChangeNotifier`)
| Store | Persistence key | Contenuto |
|---|---|---|
| `ContentRepository` | — | Carica livelli + corsi/argomenti/esercizi dai JSON (`assets/data/`) |
| `LessonRepository` | — | Carica le lezioni da `lessons.json` |
| `ProgressStore` | `exercise_progress_v1`, `lessons_completed_v1` | Stato esercizi, segnalibri, lezioni completate |
| `AuthStore` | `user_profile_v1` | Profilo utente locale |
| `SettingsStore` | `settings_v1` | Tema + flag onboarding visto |
| `StudyStore` | `study_stats_v1` | Streak, obiettivi giornalieri, minuti di studio |
| `SearchIndex` | — | Indice full-text su argomenti/esercizi/lezioni |
| `RecommendationEngine` | — | Lezioni ed esercizi consigliati per livello |
| `WeakTopicEngine` | — | Calcola argomenti deboli e lezioni per argomento |

## Contenuti

- **Scuola Media**: 3 corsi · 4 sezioni · 6 argomenti · 7 esercizi (inclusa la lezione torta delle frazioni).
- **Scuola Superiore**: 5 corsi · 6 sezioni · 9 argomenti · 13 esercizi (incluse le lezioni su equazioni lineari e moduli).
- **Università**: 3 corsi · 3 sezioni · 6 argomenti · 6 esercizi.

Totale: **11 corsi, 13 sezioni, 21 argomenti, 26 esercizi, 5 lezioni guidate**.

## Comandi

| Comando | Scopo |
|---|---|
| `flutter pub get` | Installare le dipendenze |
| `flutter run` | Avvio in sviluppo |
| `flutter analyze` | Analisi statica (deve restare a **0 issues**) |
| `flutter test` | Eseguire i test (unit + widget) |
| `flutter test --coverage` | Report di copertura |
| `dart format .` | Formattare il codice |
| `flutter build web` | Build per web (unica piattaforma confermata) |

## Struttura delle schermate

- **Splash** → carica store e contenuti, poi avvia Home o Onboarding.
- **Onboarding** → 3 slide + scelta scuola implicita al primo accesso.
- **Home** → missione, ricerca, streak, consigli, punti deboli, segnalibri.
- **Corso (Esercizi)** → tab annuali con argomenti e "Tutti gli esercizi".
- **Exercise feed / Anno / Dettaglio** → esercizi di un argomento o dell'intero anno, con filtri e soluzione passo-passo.
- **Lezioni** → elenco per argomento/sezione e lezione guidata interattiva.
- **Risultati ricerca** → argomenti, esercizi e lezioni trovate.
- **Punti deboli** → elenco e dettaglio con lezioni consigliate ed esercizi da ripassare.
- **Mission / Bookmark / Profilo / Registrazione / Scuola** → schermate di supporto.

## Test

11 file di test (`flutter_test`, nessuna libreria esterna) con mock di `SharedPreferences` e reset singolton via `resetForTest()`. Le descrizioni dei test sono in italiano, coerenti con la lingua dell'app.

## Piattaforme

Solo la build **web** è confermata funzionante; la build Linux desktop richiede CMake (non installato).

## Roadmap

Lo stato di avanzamento e le evoluzioni di progetto sono documentate in `PROGRESS.md`.