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
- **3 lezioni** passo-passo con **card didattiche** (informative) e **card a quiz** (multiple choice), per un totale di 10 passaggi.
- Tipi di passo (`LessonStepType`):
  - `info` – card con contenuto markdown (testo, formule LaTeX, liste, box) che si scorre e si chiude con «Lezione completata».
  - `mcq` – domanda a scelta multipla: opzioni toccabili, risposta errata con feedback rosso e **animazione shake**, risposta corretta con feedback verde.
- Feedback immediato anche tattile: risposta corretta `HapticFeedback.lightImpact`, errata `heavyImpact`, lezione completata `mediumImpact`.
- **Barra di avanzamento animata** e transizioni fade+scale tra le card.
- **Calcolatrice scientifica** nella toolbar del player (`M3EToolbar`): sheet non modale che si trascina e si chiude con fling; supporta `sin cos tan ln log`, `√ x² ( ) π`, `abs exp AC ⌫ %`, operazioni `− ± + × ÷ ^ =`; modalità `DEG`/`RAD`, tonde chiuse automaticamente. Calcola con lo stesso `ExpressionEvaluator` dei grafici.
- **`fontSizeMultiplier`** per card: scala il font (titolo, contenuto, opzioni, feedback) per far stare più contenuto a schermo (clamp 0.5–2.0).
- Completamento riconosciuto: **serie giornaliera** e obiettivi aggiornati automaticamente.

### Riquadri multifunzione
- Dentro il contenuto delle lezioni si possono inserire **riquadri** (`MultifunctionBox`) di 4 tipi, racchiusi dalla sintassi `::box` / `::endbox` o come oggetti dell'array `content`:
  - `image` – immagine con didascalia.
  - `chart` – grafico statico (barre, linee, torta) disegnato con `CustomPainter`.
  - `interactive_chart` – grafico a linee con **slider parametro** live e **chips legenda** per mostrare/nascondere le serie.
  - `math_formula` – formula LaTeX in evidenza.
- **Callout colorati** (`:::attenzione`, `:::takeaway`) per box «Attenzione» e «Takeaway» all'interno del testo.
- Struttura JSON completa documentata nella sezione [Struttura del JSON delle lezioni](#struttura-del-json-delle-lezioni).

### Studio e motivazione
- **Serie giornaliera (streak)** con record personale e obiettivi giornalieri: **5 esercizi** e **10 minuti** di studio (contatore minuti attivo tramite osservatore di sessione).
- **Punti deboli**: calcolo automatico degli argomenti da ripassare (da `ExerciseStatus.needsReview`), con sezione dedicata in Home, schermata di dettaglio con lezioni consigliate e notifica quando il punto debole viene risolto.
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
- Animazioni: splash/onboarding con fade, transizioni in fade tra le tab, card animate, shake sugli errori.
- **Tab annuali**: i cerchi delle tab anni mostrano i numeri romani (I–V). Le label degli anni usano i nomi ordinali (*prima, seconda, terza, quarta, quinta*).
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
                         # difficulty, progress, lesson, lesson_step, argomento,
                         # user_profile, weak_topic, multifunction_box/
  data/                  # repository + store singleton:
                         # content_repository, lesson_repository, progress_store,
                         # auth_store, settings_store, study_store, search_index,
                         # recommendation_engine, weak_topic_engine
  screens/               # 19 schermate (full-page)
  widgets/               # 29 widget riutilizzabili
assets/
  data/                  # levels.json, middle_school.json, high_school.json,
                         # university.json, lessons/index.json + argomenti lessons/*.json
  images/                # asset immagini: copertine argomenti, cerchi degli anni
```

### Modelli dati
- **Level** → Livello scolastico (`id`, `title`, `subtitle`, `icon`, `dataFile`) che punta al JSON del corso.
- **Course / Section / Topic / Exercise** → gerarchia corso-anno → sezione → argomento → esercizio (con `difficulty`, `tags`, `formulas`, `hints`, `steps`). `Course` e `Topic` hanno un campo opzionale `image` per i cerchi degli anni / le copertine.
- **Difficulty** → enum `easy` / `medium` / `hard` con `fromString()` e label italiane (Facile / Medio / Difficile).
- **ExerciseProgress** → stato (`ExerciseStatus`: `none` / `mastered` / `needsReview`) + segnalibro per esercizio, con **chiave composita** `levelId::exerciseId`.
- **Argomento / Lesson / LessonStep** → lezione guidata: `Argomento` collega un gruppo di lezioni a un argomento del corso; `LessonStep` può essere `info` o `mcq` (vedi [Struttura del JSON delle lezioni](#struttura-del-json-delle-lezioni)).
- **MultifunctionBox** → riquadro embedded nel content (`BoxType`: image / chart / interactive_chart / math_formula) con payload tipizzati.
- **UserProfile** → profilo locale (`AuthMethod` manual o google), salvato su dispositivo.
- **WeakTopic** → argomento debole calcolato dal `WeakTopicEngine`.

### Repository e store (singleton `ChangeNotifier`)
| Store | Persistence key | Contenuto |
|---|---|---|
| `ContentRepository` | — | Carica livelli + corsi/argomenti/esercizi dai JSON (`assets/data/`) |
| `LessonRepository` | — | Carica le lezioni da `lessons/index.json` + file argomento |
| `ProgressStore` | `exercise_progress_v1`, `lessons_completed_v1` | Stato esercizi, segnalibri, lezioni completate |
| `AuthStore` | `user_profile_v1` | Profilo utente locale |
| `SettingsStore` | `settings_v1` | Tema + flag onboarding visto |
| `StudyStore` | `study_stats_v1` | Streak, obiettivi giornalieri, minuti di studio |
| `SearchIndex` | — | Indice full-text su argomenti/esercizi/lezioni |
| `RecommendationEngine` | — | Lezioni ed esercizi consigliati per livello |
| `WeakTopicEngine` | — | Calcola argomenti deboli e lezioni per argomento |

## Contenuti

- **Scuola Media**: 3 corsi · 4 sezioni · 6 argomenti · 7 esercizi.
- **Scuola Superiore**: 5 corsi · 6 sezioni · 9 argomenti · 13 esercizi (incluse le lezioni su equazioni lineari e moduli).
- **Università**: 3 corsi · 3 sezioni · 6 argomenti · 6 esercizi.

Totale: **11 corsi, 13 sezioni, 21 argomenti, 26 esercizi, 3 lezioni guidate** (in 2 argomenti lezioni).

## Struttura del JSON delle lezioni

Le lezioni vivono in `assets/data/lessons/`. Il caricamento parte da `index.json`, che elenca i file degli **argomenti lezioni** da caricare:

```json
{
    "argomenti": ["hs-year1-equations.json", "hs-year2-moduli.json"]
}
```

Ogni file dell'elenco è un **argomento lezioni** (`Argomento`), collegato a un argomento del corso corrispondente tramite gli id `level`/`year`/`section`/`topic`.

```json
{
    "level": "high-school",
    "year": "year2",
    "section": "year2-moduli",
    "topic": "year2-moduli-definition",
    "title": "Moduli",
    "subtitle": "Variabile reale e valore assoluto",
    "icon": "functions",
    "lessons": [
        {
            "id": "mod-equations-intro",
            "title": "Modulo e Equazioni con Modulo",
            "subtitle": "Distanza, espressioni letterali e studio del segno",
            "minutes": 6,
            "steps": [
                {
                    "type": "info",
                    "title": "Che cos'è il Modulo?",
                    "content": [
                        "Il **modulo** indica la **distanza** dallo zero.",
                        {
                            "id": "mod-def-formula",
                            "box_type": "math_formula",
                            "title": "Definizione",
                            "payload": {
                                "tex": "|x| = \\begin{cases} x & \\text{se } x \\ge 0 \\\\ -x & \\text{se } x < 0 \\end{cases}",
                                "mode": "display",
                                "fontSizeMultiplier": 1.2
                            }
                        }
                    ]
                },
                {
                    "type": "mcq",
                    "title": "Verifica",
                    "content": "Qual è la soluzione di $$3x - 1 = 5$$?",
                    "options": ["$$x = 2$$", "$$x = 4$$", "$$x = 3$$"],
                    "correctIndex": 0,
                    "explanation": "Porta $$-1$$ a destra: $$3x = 6$$, quindi $$x = 2$$."
                }
            ]
        }
    ]
}
```

### Tabella dei campi

#### Argomento lezioni
| Campo | Tipo | Descrizione |
|---|---|---|
| `level` | stringa | Id del livello (es. `high-school`). **Obbligatorio.** |
| `year` | stringa | Id dell'anno (es. `year2`). **Obbligatorio.** |
| `section` | stringa | Id della sezione d'appartenenza nel JSON corsi. |
| `topic` | stringa | Id dell'argomento del corso a cui sono collegate le lezioni. |
| `title` | stringa | Titolo visibile dell'argomento. |
| `subtitle` | stringa | Sottotitolo. |
| `icon` | stringa | Nome icona Material (es. `functions`, `menu_book`); mappato a runtime. |
| `lessons` | array | Elenco di **Lesson**. |

#### Lesson
| Campo | Tipo | Descrizione |
|---|---|---|
| `id` | stringa | Identificativo kebab-case (es. `mod-equations-intro`). **Obbligatorio.** |
| `title` | stringa | Titolo della lezione. **Obbligatorio.** |
| `subtitle` | stringa | Sottotitolo mostrato nella lista lezioni. |
| `minutes` | numero | Durata stimata; mostrata come «X min» (se 0 non mostrata). |
| `steps` | array | Sequenza di **LessonStep** mostrate come card scorrevoli. |

#### LessonStep
| Campo | Tipo | Descrizione |
|---|---|---|
| `type` | *enum* | Tipo di passo. Vedere la tabella [Enum `LessonStepType`](#enum-lessonsteptype). |
| `title` | stringa | Titolo della card; per un passo `mcq` è la **domanda**. |
| `content` | stringa o array | Contenuto markdown. Vedere [content come array](#content-come-array). |
| `options` | array di stringhe | Opzioni della domanda (solo `mcq`). |
| `correctIndex` | numero | Indice **0-based** della risposta corretta (solo `mcq`). |
| `explanation` | stringa | Spiegazione mostrata come feedback quando la risposta è corretta (solo `mcq`). |
| `fontSizeMultiplier` | numero (opz.) | Scala il font della card; clamp 0.5–2.0, default 1.0. |

##### Enum `LessonStepType`
Valori accettati e relativo comportamento:

| Valore | Alias accettati | Comportamento |
|---|---|---|
| `info` | `definition` | Card informativa: contenuto markdown scrollabile. Default per passo senza `type`. |
| `mcq` | `multiple_choice` | Card quiz: contenuto (domanda) + `options`; tap su opzione valuta `correctIndex`. |

Valore ignoto → trattato come `info`.

#### Content come array
Il campo `content` accetta due formati:

1. **Stringa markdown** (formato legacy) — ad es. array di righe unite con `\n` o sintassi `::box`/`::endbox` scritta a mano.
2. **Array di segmenti** (preferito) — ogni elemento è:
   - una **stringa** = riga di testo markdown;
   - un **oggetto** = riquadro `MultifunctionBox` (JSON dello stesso oggetto documentato sotto).

In caricamento l'array viene appiattito in una stringa con la sintassi recintata `::box`/`::endbox`.

### Markdown supportato in `content` (`NotesText`)

| Sintassi | Effetto |
|---|---|
| `# ` / `## ` / `### ` | Titolo / intestazione / sottointestazione. |
| `**testo**` | Grassetto. |
| `*testo*` | Corsivo. |
| `__testo__` | Sottolineato. |
| `~~testo~~` | Barrato. |
| `` `testo` `` (inline) | Codice inline (font monospace). |
| `` `...` `` (riga intera) | Blocco monostile con sfondo. |
| `- testo` | Elemento di elenco puntato. |
| `$...$` | Formula LaTeX **inline**. |
| `$$...$$` | Formula LaTeX **a blocco**. |
| `::center` / `::left` / `::right` | Da soli su una riga impostano l'allineamento della **riga successiva**; come prefisso (`::center testo`) allineano la **riga corrente**. |
| `:::chiave` | Apre un **callout** colorato (vedi sotto). |

#### Callout `:::chiave`
Il callout raccoglie tutte le righe seguenti e si chiude con una **riga vuota**, un **heading** (`#`), un altro blocco speciale o la fine del contenuto. Testo inline dopo la chiave (`:::takeaway testo`) entra nel box.

| Chiavi | Box renderizzato |
|---|---|
| `attenzione` · `warning` · `pericolo` | Callout **Attenzione** (colore `medium`, icona avviso). |
| `takeaway` · `suggerimento` · `consiglio` · `tip` | Callout **Takeaway** (colore `accent`, icona lampadina). |
| (qualsiasi altra chiave) | Trattata come testo normale. |

#### Riquadri: sintassi `::box` / `::endbox`
Oltre agli oggetti dell'array `content`, un riquadro può essere scritto direttamente nel markdown:

```
::box
{"id": "...", "box_type": "chart", "title": "...", "payload": {...}}
::endbox
```

La scansione di chiusura è limitata a **200 righe**; se il JSON interno non è valido, il testo torna markdown puro (nessun crash). Esiste anche la forma **single-line**: `::box {json} ::endbox`.

### MultifunctionBox

| Campo | Tipo | Descrizione |
|---|---|---|
| `id` | stringa | Identificativo kebab-case. |
| `box_type` | *enum* | Tipo di riquadro. Vedere [Enum `BoxType`](#enum-boxtype). |
| `title` | stringa | Header della card. `title` vuoto/assente → header omesso e padding della card ridotto. |
| `payload` | oggetto | Corpo specifico per `box_type`. |

##### Enum `BoxType`
| Valore | Payload | Descrizione |
|---|---|---|
| `image` | `ImageBoxPayload` | Immagine con didascalia. **Default** per `box_type` ignoto. |
| `chart` | `ChartBoxPayload` | Grafico statico (barre / linee / torta). |
| `interactive_chart` | `InteractiveChartPayload` | Grafico a linee con slider parametro e legenda attivabile. |
| `math_formula` | `MathFormulaPayload` | Formula LaTeX in evidenza. |

#### Payload `image`
| Campo | Tipo | Descrizione |
|---|---|---|
| `source` | stringa | Sorgente dell'immagine (path asset). Vuota → placeholder. |
| `caption` | stringa (opz.) | Didascalia sotto l'immagine. |

#### Payload `chart`
| Campo | Tipo | Descrizione |
|---|---|---|
| `kind` | *enum* | Tipo di grafico. Vedere [Enum `ChartKind`](#enum-chartkind). |
| `xLabels` | array di stringhe | Etichette dell'asse x. |
| `unit` | stringa (opz.) | Unità mostrata sul tick massimo (es. `cm`). |
| `series` | array | Serie di dati. |

Ogni serie (`ChartSeries`):
| Campo | Tipo | Descrizione |
|---|---|---|
| `label` | stringa | Nome della serie (legenda). |
| `values` | array di numeri | Valori della serie. |
| `colorKey` | stringa (opz.) | Chiave colore (vedere [Colori](#colori-delle-serie)). |

##### Enum `ChartKind`
| Valore | Alias accettati | Grafico |
|---|---|---|
| `bar` | `barre` · `istogramma` | Barre verticali. Default. |
| `line` | `linee` | Linea. |
| `pie` | `torta` | Torta (valori negativi clampati a 0). |

#### Payload `interactive_chart`
| Campo | Tipo | Descrizione |
|---|---|---|
| `xLabel` / `yLabel` | stringa | Etichette assi. Default `x` / `y`. |
| `xMin` / `xMax` / `xStep` | numero | Dominio x e passo di campionamento. Default −3 / 3 / 0.25. |
| `yMin` / `yMax` | numero | Range asse y. Default −5 / 5 (autoscale override). |
| `parameter` | oggetto | Parametro regolato dallo slider. |
| `series` | array | Serie tracciate. |
| `toggleable` | boolean | Se `true` (default) mostra le **chips legenda** per attivare/disattivare ogni serie. |

Parametro (`InteractiveParameter`):
| Campo | Tipo | Descrizione |
|---|---|---|
| `name` | stringa | Nome del parametro (default `t`); usato nelle espressioni. |
| `min` / `max` | numero | Range dello slider. |
| `step` | numero | Passo dello slider. |
| `default` | numero | Valore iniziale (default: punto medio min–max). |

Serie (`InteractiveSeries`):
| Campo | Tipo | Descrizione |
|---|---|---|
| `label` | stringa | Nome della serie (legenda/chip). |
| `expression` | stringa | Espressione valutata su `x` per ogni punto del dominio; può usare il parametro (`t`) e le funzioni del `ExpressionEvaluator`. |
| `colorKey` | stringa (opz.) | Chiave colore. |

#### Payload `math_formula`
| Campo | Tipo | Descrizione |
|---|---|---|
| `tex` | stringa | Formula in LaTeX. |
| `mode` | *enum* | Vedere [Enum `FormulaMode`](#enum-formulamode). |
| `fontSizeMultiplier` | numero (opz.) | Scala la dimensione della formula. |
| `hidden` | boolean | Se `true` non vengono resi la **card di contorno** (`AppCard`) né l'header con titolo: la formula resta visibile come blocco a sé. Default `false`. |

##### Enum `FormulaMode`
| Valore | Alias accettati | Comportamento |
|---|---|---|
| `display` | `block` | Formula a blocco. Default. |
| `inline` | — | Formula inline. |

#### Colori delle serie
`colorKey` risolve in una palette dell'app. Chiavi note: `accent`, `teal`, `purple`, `pink`, `indigo`, `easy`, `medium`, `hard` (minuscole/maiuscole indifferenti). Chiave assente o ignota → colore ciclico dalla palette icone (`iconPalette`).

### `ExpressionEvaluator`
Parser recursive-descent usato dai grafici interattivi (esprime `x`/`t`) e dalla calcolatrice scientifica.

- **Operatori**: `+ - * / ^ %` (potenza a destra-associativa), parentesi.
- **Variabili**: `x` (ascissa del dominio), `t` (parametro dello slider).
- **Costanti**: `pi`, `e`.
- **Funzioni** (parentesi obbligatorie): `sin(x) cos(x) tan(x) ln(x) log(x) sqrt(x) abs(x) exp(x)`.
- Trigonometria in **radianti** di default (grafici); la calcolatrice può passare alla modalità `DEG`.
- Errori di parsing o valori non finiti → la serie non viene tracciata / la calcolatrice mostra «Errore»; mai crash.

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
- **Lezioni** → elenco per argomento (lista argomenti e lista lezioni per argomento) e player interattivo.
- **Risultati ricerca** → argomenti, esercizi e lezioni trovate.
- **Punti deboli** → elenco e dettaglio con lezioni consigliate ed esercizi da ripassare.
- **Mission / Bookmark / Profilo / Registrazione / Scuola** → schermate di supporto.

## Test

20 file di test (`flutter_test`, nessuna libreria esterna, **196 test**) con mock di `SharedPreferences` e reset singloton via `resetForTest()`. Le descrizioni dei test sono in italiano, coerenti con la lingua dell'app. Nei `testWidgets` i reset/load asset vanno fatti in `setUp` (zona reale), mai awaitati nel corpo del test.

## Piattaforme

Solo la build **web** è confermata funzionante; la build Linux desktop richiede CMake (non installato).

## Roadmap

Lo stato di avanzamento e le evoluzioni di progetto sono documentate in `PROGRESS.md`.