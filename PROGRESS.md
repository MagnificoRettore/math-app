# PROGRESS — Math App (Esercizi di Matematica)

Applicazione iOS-native di esercizi di matematica risolti, costruita in Flutter.
Obiettivo: pulire l'interfaccia scaffold di default e costruire l'app completa.

## Stato (ultimo aggiornamento)

- [x] **Step 1 — Documento di avanzamento** (PROGRESS.md)
- [x] **Step 2 — pubspec.yaml**: dipendenze (flutter_math_fork, shared_preferences, google_fonts) + assets
- [x] **Step 3 — Schema dati JSON**: levels.json, high_school.json, university.json + contenuti di esempio
- [x] **Step 4 — Models Dart**: Level, Course, Topic, Exercise, Difficulty, Progress
- [x] **Step 5 — Tema iOS-nativo**: app_theme, app_colors (sfondo #F9F9F9, cards bianche, bordi sottili)
- [x] **Step 6 — Data layer**: ContentRepository (carica JSON), SearchIndex, ProgressStore (shared_preferences)
- [x] **Step 7 — Widget riutilizzabili**: MathText, cards, ProgressBar, DifficultyBadge
- [x] **Step 8 — Screen**: Home, Course, Topic, ExerciseFeed, ExerciseDetail, Bookmarks, Search
- [x] **Step 9 — main.dart + app.dart** (rotte + tema)
- [x] **Step 10 — Test**: smoke test home + test caricamento/ricerca (sostituisce test counter)
- [x] **Step 11 — Verifica**: `flutter analyze` (0 issue), `flutter test` (3/3 passati)
- [x] **Step 12 — Splash page + icone colorate**: splash iniziale con logo "Math App", palette icone colorate (teal, purple, pink, indigo)
- [x] **Step 13 — Lezioni guidate interattive**: lezioni a passi (mcq / numerico / testo) con feedback immediato, animazioni interagibili (torta frazioni, retta numerica) e animazioni di transizione/celebrazione
- [x] **Step 14 — Menù sempre presente**: `MainMenuButton` condiviso (dropdown hamburger in alto a destra) su tutte le schermate principali
- [x] **Step 15 — Profilo utente + consigli**: registrazione manuale (nome/email/password) o `Continua con Google` (simulato, no credenziali), domanda sulla scuola in registrazione; sezione `Per te` in Home con lezioni (non completate) ed esercizi (non tentati, facili prima) del livello scelto. Modalità ospite senza profilo.
- [x] **Step 16 — Menu a pillola in basso**: sostituito il menu hamburger con una pillola flottante in basso con 4 voci (HOME, LEZIONI, ESERCIZI, PROFILO), visibile solo sulle 4 schermate principali. LEZIONI ed ESERCIZI portano direttamente al livello della propria scuola se si è collegati col profilo, altrimenti mostrano un pop-up (bottom sheet) di scelta tra le tre scuole (Media / Superiore / Università) senza aprire pagine intermedie. Segnalibri raggiungibile da Home (icona bookmark), missione da `MissionHero`. Eliminato `MainMenuButton`.
- [x] **Step 17 — Quick win**: ricerca live in Home (debounce 300 ms, push automatico dei risultati con almeno 2 caratteri incluso le lezioni), feedback aptico (haptic) su risposte lezione ed esercizi, rimozione dipendenze morte (`flutter_svg`, `google_fonts`), test navigazione pillola→scuola.
- [x] **Step 18 — Gamification leggera**: `StudyStore` con streak (serie di giorni consecutivi, record personale), obiettivi giornalieri (5 esercizi, 10 minuti di studio) e contatori; `AppSessionObserver` per i minuti di utilizzo; `StreakCard` in Home con le due barre obiettivo e tabellone; snackbar quando un obiettivo viene raggiunto; persistenza `study_stats_v1`.
- [x] **Step 19 — UX & onboarding**: caricamento dati spostato nello splash (min 2 s) con stato di errore e pulsante `Riprova`; campo `loadError` + `reload()` su tutti i repository/store; onboarding al primo avvio (`OnboardingScreen` a 3 slide con indicatore e skip, flag `onboarding_seen_v1` persistito via `SettingsStore`); validazione registrazione potenziata (nome ≥2 caratteri, email valida, password ≥8 caratteri con lettera e numero, campo conferma password).
- [x] **Step 20 — Dark mode completa**: `AppPalette` (ThemeExtension) con palette light e dark e `AppColors.of(context)`; `AppTheme.light` / `AppTheme.dark`; `SettingsStore` persistito (`settings_v1` con `themeMode` e flag onboarding); interruttore `Tema scuro` nella schermata Profilo (ospiti inclusi); migrazione di tutti i widget/screen dalle costanti statiche alla palette dal tema.

## Architettura

```
lib/
  main.dart              # avvio: carica contenuti + progressi + profilo + indice ricerca
  app.dart               # MathApp (MaterialApp + tema)
  theme/                 app_theme.dart, app_colors.dart
  models/                level.dart, course.dart, topic.dart, exercise.dart, difficulty.dart, progress.dart, lesson.dart, lesson_step.dart, user_profile.dart
  data/                  content_repository.dart, search_index.dart, progress_store.dart, lesson_repository.dart, auth_store.dart, recommendation_engine.dart, study_store.dart, settings_store.dart
  screens/               home, course, topic, exercise_feed, exercise_detail, bookmarks, search_results, splash, mission, lesson_list, lesson, welcome, registration, school_picker, profile, onboarding
  widgets/               app_card, math_text, progress_bar, difficulty_badge, level_card, course_row, topic_row, exercise_card, section_header, mission_hero, animated_fraction_pie, animated_number_line, lesson_card, recommended_section, pill_nav_bar, school_level_tile, school_choice_sheet, streak_card, app_session_observer
  utils/                 latex.dart
assets/data/             levels.json, high_school.json, university.json, middle_school.json, lessons.json
```

## Funzionalità implementate

- **Navigazione gerarchica**: Home (livello) → Anno/Corso → Topic → Feed esercizi → Dettaglio soluzione.
- **Rendering LaTeX**: `flutter_math_fork` (KaTeX puro Dart, offline, niente WebView). `MathText` gestisce testo misto con blocchi `$$...$$`.
- **Ricerca globale**: barra in Home; `SearchIndex` indicizza topics, esercizi, tags, formule, passaggi.
- **Progress tracking**: stato `Mastered` / `Needs Review` per esercizio; barre di completamento su topic, corso e livello.
- **Segnalibri**: toggle per esercizio, sezione dedicata nella bottom nav.
- **Offline**: contenuti bundled come asset JSON + progressi in `shared_preferences` (niente rete).
- **Filtro difficoltà**: chips (Tutti / Facile / Medio / Difficile) nel feed.
- **Hints espandibili e formule chiave** nella vista dettaglio.
- **Lezioni guidate interattive**: passi MCQ/numerico/testo, feedback immediato con shake su errore, avanzamento solo a risposta corretta; animazioni interagibili (torta frazioni, retta numerica) e celebrazione finale con confetti. Stato "completata" persistito.
- **Profilo utente**: registrazione manuale o `Continua con Google` (simulato) con scelta della scuola in fase di registrazione; profilo modificabile (cambia scuola, esci) dalla schermata Profilo (menu). Persistenza locale in `shared_preferences`.
- **Menu a pillola in basso**: navigazione flottante con HOME, LEZIONI, ESERCIZI e PROFILO sulle 4 schermate principali. LEZIONI (lezioni guidate del livello scelto) ed ESERCIZI (pagina della scuola) vanno direttamente al livello del profilo se collegati, altrimenti mostrano un pop-up (bottom sheet) con la scelta tra Scuola Media / Superiore / Università, senza aprire pagine intermedie e senza creare profilo.
- **Consigli personalizzati**: sezione `Per te · {Scuola}` in Home con lezioni del livello non ancora completate ed esercizi non tentati (dal più facile); modalità ospite con card che invita a creare il profilo.
- **Streak e obiettivi giornalieri**: serie di giorni di studio (con record personale), obiettivi di 5 esercizi e 10 minuti con barre di avanzamento in Home e snackbar al raggiungimento; minuti contati automaticamente con `AppSessionObserver` (lifecycle), persistiti in `study_stats_v1`.
- **Onboarding al primo avvio**: splash che carica contenuti/progressi/profilo/settings con errore e retry; se l'onboarding non è stato ancora visto viene mostrata la schermata guidata (3 slide, skip) prima della Home.
- **Dark mode**: tema scuro completo basato su `AppPalette` (ThemeExtension) con `AppColors.of(context)`; attivabile da Profilo (interruttore `Tema scuro`), persistito in `settings_v1`, applicato via `MaterialApp.themeMode` + `AppTheme.dark`.

## Decisioni chiave

- **Motore LaTeX**: `flutter_math_fork` (KaTeX puro Dart, rendering offline, niente WebView).
- **Persistenza**: `shared_preferences` (JSON serializzato) per progressi e segnalibri; contenuti bundled come asset JSON.
- **Schema dati modulare**: Levels → Years/Courses → Topics → Exercises.
- **Tema**: minimalista, light (#FFFFFF / #F9F9F9), stile iOS-native (Apple HIG).
- **Lingua contenuti**: italiano.

## Contenuto di esempio

- **Scuola Superiore**: Anno 1 (Frazioni, Equazioni di primo grado), Anno 2 (Equazioni di secondo grado), Anno 3 (vuoto, da estendere).
- **Università**: Analisi I (Limiti, Derivate, Integrali — con integrazione per parti), Algebra Lineare (Matrici), Probabilità (Probabilità elementare, Probabilità condizionata).

## Note / miglioramenti futuri

- Aggiungere altri contenuti negli anni/corsi ancora vuoti (es. Anno 3-5, Analisi II, etc.).
- Possibile passaggio a `google_fonts` per tipografia custom (SF-like) — attualmente si usa il font di sistema.
- La build Linux richiede CMake (non installato in ambiente); la build web compila correttamente.
- Prossimi passi: estendere i contenuti (Anno 3-5, Analisi II, corsi universitari), aggiungere modalità `system` al toggle tema, eventuale export/import progressi e sincronizzazione.

## Log

- Inizio lavori: creazione struttura e documento di avanzamento.
- Step 1-11 completati; `flutter analyze` pulito, `flutter test` verde (3/3), build web OK.
- Step 14: menu hamburger condiviso su tutte le schermate (`MainMenuButton`).
- Step 15: profilo utente (registrazione manuale/Google simulato) con scelta scuola e consigli `Per te` in Home; 17 test verdi.
- Step 16: menu a pillola in basso (HOME/LEZIONI/ESERCIZI/PROFILO) solo sulle 4 schermate principali; LEZIONI/ESERCIZI con destinazione per scuola (profilo) o pop-up di scelta scuola per gli ospiti; `MainMenuButton` eliminato; 17 test verdi, build web OK.
- Step 17: quick win — ricerca live con auto-push (incluso lezioni), haptic feedback, rimozione dipendenze morte; 21 test verdi, build web OK.
- Step 18: gamification leggera — `StudyStore` (streak + obiettivi 5 esercizi/10 minuti), `AppSessionObserver` per i minuti, `StreakCard` in Home, snackbar obiettivo; 27 test verdi, `flutter analyze` pulito.
- Step 19: UX & onboarding — load nello splash con errore/retry (`loadError`/`reload`), `OnboardingScreen` al primo avvio (flag `onboarding_seen_v1`), validazione registrazione (nome/email/password+conferma); test `settings_store_test`.
- Step 20: dark mode completa — `AppPalette` ThemeExtension (light/dark), `AppColors.of(context)` con migrazione di tutti i widget (272 riferimenti), `AppTheme.dark`, `SettingsStore` (`settings_v1`), toggle `Tema scuro` in Profilo; 30 test verdi, `flutter analyze` pulito, build web OK.