# AGENTS.md — Math App & Coding Guidelines

## 1. General Behavioral Guidelines

### Think Before Coding
**Don't assume. Don't hide confusion. Surface tradeoffs.**
- State your assumptions explicitly. If uncertain, ask before implementing.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing and ask.

### Simplicity First
**Minimum code that solves the problem. Nothing speculative.**
- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.
- Ask: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### Surgical Changes
**Touch only what you must. Clean up only your own mess.**
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing project style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.
- Remove imports/variables/functions that YOUR changes made unused.
- The test: Every changed line should trace directly to the user's request.

### Goal-Driven Execution
**Define success criteria. Loop until verified.**
- Transform tasks into verifiable goals:
  - "Add validation" → "Write tests for invalid inputs, then make them pass"
  - "Fix the bug" → "Write a test that reproduces it, then make it pass"
  - "Refactor X" → "Ensure tests pass before and after"
- Always state a brief step-by-step plan before execution:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
```

---

## 2. Project Overview

Flutter application for **Italian students** with solved math exercises (Scuola Media, Scuola Superiore, Università) and interactive step-by-step guided lessons. All content is bundled offline as JSON assets; UI text is in **Italian**.

- **Framework**: Flutter 3.47.2 (stable) · **Dart SDK**: 3.13.2
- **UI style**: Material 3 con il design del canvas «Illustrazioni App Educativa» (indaco, giallo, crema; Outfit e Plus Jakarta Sans), solo tema chiaro. **Il riferimento del design è `DESIGN.md`**: colori, caratteri, forme, componenti, illustrazioni e movimento.
- **Architectural Constraints**: no network calls, no code generation (`build_runner`, `freezed`, `json_serializable`), no third-party state management (Riverpod/Bloc/Provider)
- **LaTeX**: `flutter_math_fork` ^0.7.4 (KaTeX pure Dart, offline, no WebView) · inline nei content con `$$...$$`
- **Persistence**: `shared_preferences` ^2.5.5
- **Hash password**: `crypto` ^3.0.7 → PBKDF2-HMAC-SHA256 in Dart puro, nessuna rete
- **Material 3 Expressive**: `material_3_expressive` ^1.1.2 → `M3EToolbar`, `M3EToolbarTokens`, `M3EIcons`
- **Icone**: `material_symbols_icons` ^4.2960.0
- **Illustrazioni**: `flutter_svg` ^2.3.0 → `assets/illustrations/` (`idea`, `razzo`, `lezione`, `albero`), le quattro tavole del canvas convertite in SVG statico: lo sfondo `{{bg}}` fissato al suo default, ogni `<use>` espanso con il colore scritto (niente `currentColor`), i testi in Plus Jakarta Sans 500 (`π √ ² × ÷` ci sono; la `Σ` del razzo no, ed è un tracciato). `AppIllustration` le nomina, `IllustrationView` le mostra a 600:720 con gli angoli arrotondati ed è decorazione (`ExcludeSemantics`).
- **Lottie**: `lottie` ^3.6.1 legge **solo JSON**, i `.lottie` no: la composizione non si guida, si guida la **timeline** con i **marker** (`composition.getMarker(nome)` dà `start`/`end` 0..1) pilotando un `AnimationController` con `repeat(min:, max:, count:)` e `animateTo`. `LottieBuilder.controller` è un `Animation<double>`: `LottieController` non esiste.

---

## 3. Essential Commands

| Command | Purpose |
|---|---|
| `flutter run` | Run the app (dev) |
| `flutter analyze` | Static analysis — **must stay at 0 issues** |
| `flutter test` | Run all unit + widget tests |
| `flutter test --coverage` | Generate coverage report |
| `dart format .` | Format code |
| `flutter pub get` | Install dependencies |
| `flutter build web` | Build for web (only platform confirmed working) |

---

## 4. Architecture & Key Patterns

### Struttura

```
lib/
  main.dart      # entry: loads content + progress + profile + search index
  app.dart       # MathApp (MaterialApp + theme)
  haptics.dart   # AppHaptics: le vibrazioni dietro l'interruttore
  theme/         # app_theme.dart, app_colors.dart
  models/        # plain Dart classes (level, course, section, topic, exercise,
                 # difficulty, progress, lesson, lesson_step, argomento,
                 # user_profile, local_account, weak_topic, multifunction_box/)
  data/          # singletons: content_repository, lesson_repository, progress_store,
                 # auth_store, browse_store, settings_store, study_store, search_index;
                 # pure logic no instance: weak_topic_engine
  screens/       # full-page widgets
  widgets/       # reusable UI components
assets/data/     # levels.json, middle_school.json, high_school.json, university.json,
                 # lessons/ (lessons/index.json lists the argomento files to load)
```

### Convenzioni

- **State management**: raw `ChangeNotifier` + `ListenableBuilder`, nessun pacchetto terzo.
- **Singletons**: `static final instance = ClassName._()` con costruttore privato, accesso `XStore.instance`. Gli engine di sola logica non hanno `instance`.
- **Serialization**: `fromJson` scritti a mano.
- **Widget che dipendono da uno store**: sempre dentro `ListenableBuilder(listenable: XStore.instance, builder: ...)`.
- **Screens**: costruttori `const`, `StatefulWidget` o `StatelessWidget`.
- **Colors**: mai costanti hardcoded — `final c = AppColors.of(context)` (`ThemeExtension` light/dark).
- **Cards**: il widget condiviso `AppCard` (`kCardRadius` 20, surface, **nessun gradino, un'ombra fine** (`cardShadow` in `app_card.dart`: `shadow` al 12%, blur 10, 3 in basso), il gradino è solo dei bottoni; la stessa ombra hanno le card del carosello (fuori dal `ClipRRect`, lista in `Clip.none`) e la card «Traguardo»; bordino lilla da 2 (`border`) di default, `bordered: false` per le card dentro le lezioni (la card della lezione e i riquadri multifunzione), `borderColor` per colorarlo e `borderWidth` 3 per una card scelta; `glow` opzionale per l'alone nell'angolo).
- **Micro-interazioni**: durate e curve stanno in `AppMotion` (`lib/theme/app_motion.dart`), mai un letterale: `fast` 120, `medium` 200, `slow` 300 ms; `standard` (`easeOut`) e `bounce` (`easeOutBack`) per i rimbalzi. **Il movimento ridotto si rispetta**: `AppMotion.duration(context, base)` dà zero se `MediaQuery.disableAnimations` è vero, quindi lo stato cambia senza animarsi.
- **Bottoni**: `AppButton` (`lib/widgets/app_button.dart`), mai `FilledButton`/`OutlinedButton` nelle schermate. Pillola in Outfit sollevata da un **gradino di colore pieno** (`AppButton.depth`, 5) invece di un'ombra: `primary` indaco su `accentDeep`, `secondary` giallo con l'inchiostro su `yellowDeep` (anche su fondo indaco, dove l'indaco sparirebbe), `outline` bianco col bordo indaco da 3. Disabilitato è `disabled`/`onDisabled` senza gradino; `busy` mostra la rotella e non accetta tocchi.
  - L'altezza totale è `height` più il gradino, e premendo non cambia. **Premuto, la faccia scende di tutto il gradino (5) e il gradino va a zero**, al rilascio torna su: `AppMotion.fast`, `easeOut`. La discesa è una traslazione (`AnimatedContainer.transform`), non un padding, così non rifà il layout. Disabilitato resta giù e senza gradino. «Completa la lezione» ha la faccia da 44, così con il gradino fa i 49 di `_kFooterControlHeight`.
  - Il bordo di `outline` sta in `foregroundDecoration`: nella `decoration` un `Container` lo aggiungerebbe all'altezza.
- **Feedback**: `FeedbackScreen` da Personalizzazione (`open-feedback`): tipo (idea, problema, altro) e messaggio di almeno 10 caratteri, salvato da `FeedbackStore` in `feedback_v1`. **Non c'è un server e la pagina lo dice**: il messaggio non va a nessuno. **Barra dei filtri**: le pillole (`_Pill`) hanno il gradino pieno dei bottoni e simulano la pressione con un `Listener` (giù di 4 premute; il filtro attivo resta giù); la ricerca è `SearchPill` (`header-search`) e apre l'overlay dal `context` del solo pulsante, quindi si espande dal suo centro. **Lezioni ed Esercizi seguono la scuola del profilo** (`BrowseStore.levelId ?? profilo ?? parametro`) e si aggiornano subito quando `AuthStore` cambia scuola o anno.
- **Profilo senza «Salva»**: `_ProfileContent` salva nome e avatar in un `PopScope` quando si torna indietro (nome sotto i 2 caratteri: si scarta); l'ID account è in sola lettura. **La guida** è `OnboardingScreen(fromSettings: true)` da Personalizzazione, con una schermata vera per scheda (`assets/guide/`, rigenerabile con `flutter test tool/capture_guide_test.dart`; istantanee, non aggiornate a ogni cambio). **Calcolatrice**: `ExpressionEvaluator` azzera il rumore sotto 1e-14 su `sin`/`cos` e dà errore a `tan` dove il coseno è 0. **Test**: l'onda della testata di registrazione non finisce mai, quindi i test che usano `pumpAndSettle` mettono `registrationWaveEnabled = false`.
- **Campi**: `AppTheme.fieldDecoration(c)` — bordo da 3 lilla (`border`), indaco col fuoco, `hard` nell'errore, raggio 14, fondo bianco, etichetta che sale in indaco 500.
- **`ProgressBar` si anima quando il valore cambia**: un `TweenAnimationBuilder` (`AppMotion.slow`, `easeOut`) porta il riempimento al valore nuovo, strisce comprese; al primo disegno parte già al suo valore, col movimento ridotto salta subito. Il riempimento è il `child` del builder, così a ogni frame cambia solo la larghezza. Allo screen reader dà la percentuale come `value`.
- **`ProgressBar`**: da 10 px in su è quella del design (fondo `yellowSoft`, bordo `yellowDeep` da 2, riempimento a strisce verticali 2 px ogni 12, raggio 4); sotto i 10 resta piena e arrotondata, perché strisce e bordo non si leggerebbero. Di default il riempimento è `yellow`.
- **Controlli scelti** (`SchoolLevelTile`, `McqOptionTile`, avatar): il bordo da 3 dei controlli del design. Gli anni sono quadrati arrotondati da 12 come la «Classe» del canvas, giallo con bordo `yellowDeep` lo scelto e bianco con bordo lilla gli altri; l'avatar scelto ha il bordo indaco più un anello bianco e uno giallo, i cerchi a turno giallo, turchese, arancio, lilla.
- **Lezioni ed Esercizi hanno la stessa impaginazione** (`LessonListScreen`, `CourseScreen`): la lente (`HeaderSearchButton`) non è più nell'header ma in `ListFilterBar`, fissa a destra (in Home la ricerca non c'è più); in cima `ListFilterBar` (`lib/widgets/list_filter_bar.dart`: `YearDropdown` `year-dropdown`, un menu a tendina con le opzioni `year-option-<Course.id>`, e i filtri `FilterPill` «Tutti» `filter-all` / «In corso» `filter-in-progress`), fissa sopra la lista; poi, se c'è, `ResumeCard` («Riprendi da dove eri rimasto», `resume-card`), l'intestazione «Tutti gli argomenti» e `TopicGrid` (`lib/widgets/topic_grid.dart`): due colonne, ogni riga alta quanto la sua card più alta (`IntrinsicHeight`), card con icona, titolo in Outfit 600 e «N lezioni · P%» (o «N esercizi · P%»). Le card completate hanno `CompletedBadge.corner()`. **«In corso» = iniziati e non finiti** (almeno una lezione/esercizio fatto, non tutti); senza risultati `EmptyState`. Lezioni: la ripresa è `JumpBackInCard.target()` se la lezione è di questa scuola; Esercizi non salvano «l'ultimo aperto», quindi la ripresa è il primo topic iniziato e non finito. In Esercizi la card `tutti-esercizi` è la prima della griglia e c'è solo con «Tutti». L'icona dal nome nei JSON è `topicIcon` (`topic_style.dart`). Il menu dell'anno e il filtro stanno nello stato della schermata e si azzerano cambiando scuola.
- **«Vai agli esercizi»** (`vai-agli-esercizi`, `AppButton` in basso a destra di `ArgomentoLessonsScreen`, la lista ha 88 di padding sotto): compare **solo se** l'argomento ha un topic di esercizi con lo stesso `Course.id` (`yearId`) e `Topic.id` (`topicId`) e almeno un esercizio, perché senza prometterebbe una pagina vuota (oggi 1ª e 2ª superiore). `pushAndRemoveUntil` a `CourseScreen(showPill: true, initialCourseId:)` più `ExerciseFeedScreen` del topic: il back torna all'elenco dell'anno e la Home resta la radice.
- **Segno «completata»** (`CompletedBadge`, `lib/widgets/completed_badge.dart`): tondino verde con la spunta bianca, nell'angolo in alto a destra (`CompletedBadge.corner()` in uno `Stack` sopra la card) di **ogni** card completata: argomenti in `LessonListScreen` e in `ArgomentoCarousel`, lezioni in `ArgomentoLessonsScreen`. Un argomento è completato quando lo sono tutte le sue lezioni (`ProgressStore.isArgomentoCompleted`); il carosello per questo ascolta anche `ProgressStore`.
- **Stato vuoto** (`EmptyState`): un'illustrazione del canvas al posto dell'icona, l'albero di default (lezioni in arrivo) e il razzo per i meriti («Tutto assimilato!», «Punto debole risolto!»); scorre se la pagina è bassa.
- **Schermate col canvas**: lo splash ha la lampadina sopra «Math App» (il caricamento è sceso a 160 perché insieme stiano su un telefono basso); ogni slide dell'onboarding la sua illustrazione (laptop, albero, razzo) e scorre se lo schermo è basso; il benvenuto la testata indaco di «Creazione profilo» con il bordo ondulato (`_WaveBottom`, lo stesso tracciato della tavola scalato sul riquadro). I titoli di pagina e di riquadro da `titleLarge` in su sono in Outfit 600.
- **La serie di giorni** (`HeaderStreakChip`, `lib/widgets/streak_chip.dart`) sta **nell'header** delle tre pagine main, a sinistra dell'ingranaggio: pillola con fiamma e numero (`header-streak`), fiamma arancio se oggi si è fatto qualcosa (`StudyStore.activeToday`) e grigia se no. Il tocco apre `showStreakSheet`: serie, settimana lunedì–domenica (giorni della serie arancio, oggi cerchiato) e record. La serie mostrata è `StudyStore.liveStreak` (zero se ieri e oggi non si è studiato), i giorni colorati vengono da `inStreak`: lo store non tiene lo storico. La card «Traguardo» (`StreakCard`) non c'è più. `StudyStore` conta ancora esercizi e minuti, ma nessuna schermata li mostra.
- **Titoli di componente in Outfit 600**: `SectionHeader`, `EmptyState`, il feedback delle risposte, le righe consigliate (`RecommendationRow`, che ora vive in `ExerciseCard`) e il carosello.
- **Navigation**: Navigator 1.0 imperativo — `push(MaterialPageRoute(...))`, `pushReplacement`, `pop()`. Niente named routes, niente GoRouter. `popUntil((route) => route.isFirst)` prima di spingere le pagine main; splash → home con `pushReplacement` e `PageRouteBuilder` in dissolvenza.

### Contenuto e formattazione

- **Esercizio guidato** (`GuidedSolution`, `lib/widgets/guided_solution.dart`): in `Exercise.steps` ogni elemento è una stringa (solo testo) o un oggetto `{text, prompt, options, correctIndex, explanation?}` (`ExerciseStep`, con la domanda come `PracticeExercise`). Se **tutti** i passaggi hanno una domanda valida (`Exercise.isGuided`) la pagina dell'esercizio mostra la soluzione **una domanda alla volta**: sbagliata, l'opzione si segna e si scuote (`ShakeWidget`) e si riprova; indovinata, resta in vista `_kAdvanceDelay` (600 ms, subito col movimento ridotto) e il passaggio si appende come `ExerciseStepCard`, poi arriva la domanda dopo. Finiti i passaggi compare `McqFeedbackCard`. Con anche un solo passaggio senza domanda vale la soluzione di sempre (tutta insieme). Opzioni e feedback sono quelli dei quiz (`McqOptionTile`). Oggi guidati: `eq-medium-1` e `ms-eq-1`. Il timer si cancella in `dispose`.
- **Topic senza sfondo a scelta**: `Topic.image` e la chiave `image` dei JSON non esistono più (`fromJson` ignora quella dei file vecchi), e `TopicBackground`/`TopicHeader` non hanno il parametro `image`: lo sfondo è solo il colore del topic sfumato.
- **Riquadri multifunzione**: fenced `::box` ... `::endbox` attorno a un nodo JSON `MultifunctionBox` (`box_type`: `image` | `math_formula` | `graph`); JSON invalido ricade su testo semplice.
  - Sono tre tipi e sono quelli che i contenuti usano. `interactive_chart` ci è stato (`interactive_chart_view.dart`) ed è sparito, e `chart` è stato sostituito da `graph`: i tipi si aggiungono quando un argomento li vuole, non prima. `align` e `caption` dell'immagine e il modo `inline` della formula sono andati per la stessa strada.
  - `math_formula`: `"hidden": true` sopprime l'`AppCard` che avvolge e il titolo, la formula sta da sola; `title` vuoto = niente header e padding ridotto. `fontSizeMultiplier` scala il corpo della formula.
  - `image`: **nessuna card** — niente `AppCard` (bordo/ombra), niente `ClipRRect`, niente piastra `accentSoft`. L'immagine sta centrata nella colonna di testo col titolo in piano (15 w500).
  - `graph`: dentro l'`AppCard` col titolo, e dentro `GraphView` (`lib/widgets/graph/`). Un grafico **non interattivo** di alta qualità dal JSON: piano cartesiano, barre o retta numerica. Il formato completo, per chi scrive le lezioni:
    ```json
    { "box_type": "graph", "title": "…", "payload": {
        "plane": "cartesian",            // oppure "bars", "numberLine"
        "x": [-4, 8], "y": [-10, 10],    // domini; se mancano si calcolano
        "aspect": "fit",                 // "equal": stessa unità sui due assi
        "grid": 2,                       // passo di griglia e numeri; se manca si calcola
        "xLabel": "x", "yLabel": "y",    // nomi degli assi, LaTeX
        "items": [
          { "type": "function", "expr": "2*x - 4", "domain": [0, 5], "label": "y = 2x - 4", "color": "accent", "style": "dashed" },
          { "type": "point", "at": [2, 0], "label": "(2,\\,0)", "guides": true },
          { "type": "line", "x": 5 }, { "type": "line", "y": 1 },
          { "type": "line", "through": [[0, 1], [1, 3]] },
          { "type": "curve", "x": "2*cos(t)", "y": "sin(t)", "t": [0, 6.29] },
          { "type": "circle", "center": [1, 1], "radius": 3, "fill": true },
          { "type": "segment", "from": [0, 0], "to": [3, 1] },   // "vector": con la punta
          { "type": "polygon", "points": [[0, 0], [2, 0], [1, 2]] },  // "fill": false per il solo contorno
          { "type": "area", "under": "x^2", "from": 0, "to": 2 },     // oppure "between": ["x + 2", "x^2"]
          { "type": "region", "where": ["y >= x^2 - 3", "y < x + 1", "x <= 4"] }
        ],
        // solo "numberLine": { "type": "interval", "set": "]-1, 5/3]" }, { "type": "point", "at": 3 }
        "categories": ["a", "b"],        // solo "bars"
        "series": [{ "label": "…", "color": "accent", "values": [3, null] }]  // solo "bars"
    } }
    ```
    - `label` è **LaTeX senza `$`** e si disegna con `flutter_math_fork`: funzioni e curve in legenda sotto il grafico, punti e rette accanto, su una piastrina chiara. Le figure hanno l'etichetta sul piano: al centro di poligoni, aree e regioni (media dei vertici del pezzo più grande), sopra la circonferenza, a nord-est della punta di un vettore, e per un segmento accanto al punto medio **scostata in perpendicolare** verso l'alto, perché a nord-est starebbe sul segmento che sale. `color` è un nome (`accent`, `orange`, `teal`, `pink`, `green`, `purple`, `red`, `indigo`); senza, il colore viene da una sequenza di toni ben distinti, tutti oltre 3:1 su bianco (`graphColor`). `orange` è `orangeDeep`: l'arancio pieno su bianco non arriva a 3:1.
    - **Un elemento che non si capisce si salta**, il resto del grafico resta: tipo sconosciuto, punto senza due numeri, funzione vuota, retta per due punti uguali, raggio non positivo, poligono con meno di tre vertici, area con `from` ≥ `to`, curva con `t` rovesciato. Un dominio rovesciato vale come nessun dominio.
    - **La retta numerica** (`NumberLineLayout`, `NumberLinePainter`): l'intervallo si scrive **come sul libro** in `set` — `]a, b[` o `(a, b)` per gli estremi esclusi, `[a, b]` per gli inclusi, `-inf`/`+inf`/`∞` per l'infinito (sempre escluso), gli estremi anche come frazione `5/3`. Ogni intervallo ha **la sua riga**, dall'alto nell'ordine del JSON come le disequazioni di un sistema, con estremi a pallino **pieno se inclusi e vuoto se esclusi** e una guida tratteggiata fino alla retta; verso l'infinito la barra arriva al bordo. I **punti stanno sulla retta** (`"at": 3`), perché un insieme di soluzioni `{3, 7}` si disegna così. Sotto la retta ci sono **solo i numeri degli estremi e dei punti, scritti come nel JSON** (`5/3` resta `5/3`); con `grid` anche quelli a passo regolare, che si diradano contando dallo zero e cedono il posto agli estremi vicini. Senza `x` il dominio sta attorno agli estremi con un margine, così un intervallo verso l'infinito si vede andare avanti.
    - **Le regioni** sono l'intersezione delle condizioni `where`, scritte `x|y op espressione` (`<`, `<=`, `>`, `>=`, anche `≤` `≥`): su `y` l'espressione è in `x`, su `x` è un numero. Il bordo è **continuo per `≤`/`≥` e tratteggiato per `<`/`>`**, disegnato su tutto il grafico come sul quaderno; l'ombra si spezza dove i bordi si incrociano o non esistono. **Una condizione illeggibile salta la regione intera**: togliendo solo lei si colorerebbe una regione più grande di quella scritta.
    - Aree, regioni e figure piene sono del colore dell'elemento al 16% (`_kFillAlpha`), sotto tutto il resto; la circonferenza è piena solo con `"fill": true`, il poligono lo è salvo `"fill": false`. Una circonferenza è rotonda **solo con `aspect: equal`**. Gli estremi di un segmento sono due punti; il gambo di un vettore si ferma alla base della punta, che compare a fine entrata.
    - Il piano è **un vero piano cartesiano**: assi per l'origine (sul bordo se lo zero è fuori, con margine per i numeri), frecce, nomi degli assi in LaTeX, griglia nei due sensi, numeri in Plus Jakarta Sans con il meno tipografico «−» e un alone del colore della card, «O» all'origine. I numeri si diradano se non c'è spazio, **contando dallo zero** (0, 2, 4 e non 1, 3, 5), e saltano quelli che toccherebbero l'altro asse.
    - **Nessuna interazione**: niente tap, tooltip, zoom. L'unico movimento è l'entrata (`AppMotion.slow`, `TweenAnimationBuilder`): curve e rette si tracciano con `PathMetric.extractPath`, punti ed etichette compaiono, le barre crescono. Una volta sola, al montaggio; col movimento ridotto il grafico è già lì.
    - **I buchi sono assenze, non zeri**: `sampledSegments` (`graph_scale.dart`) spezza il path dove `ExpressionEvaluator` non dà un valore, e anche **un'altezza oltre il dominio** sopra o sotto, che è un asintoto: `1/x` non stampa la verticale fra −∞ e +∞. Dentro quella fascia i punti restano, così una curva esce dal bordo invece di fermarsi prima; il painter taglia sul riquadro.
    - **Logica pura senza `package:flutter`**: `graph_scale.dart` (passi «belli» 1/2/2.5/5, tick, trasformazione dati↔pixel, campioni, barre) e `graph_layout.dart` (domini automatici col 5°–95° percentile così un asintoto non schiaccia il resto, e che tengono dentro vertici, estremi, il riquadro delle circonferenze e i campioni delle curve; proporzioni, margini, numeri diradati, rette tagliate; tracciati, riempimenti e bordi delle regioni già calcolati in `samples`, `fills` ed `edges`). I painter disegnano, i test misurano senza widget.
    - Proporzioni: `fit` è alto tre quarti della larghezza; `equal` tiene la stessa unità e, se l'altezza uscirebbe da 0.5–1.3 volte la larghezza, allarga il dominio più corto invece di schiacciare il grafico.
    - I colori di assi, griglia e numeri vengono da `ChartPalette` (`lib/theme/chart_palette.dart`). `GraphStyle` e i painter si confrontano per valore (`listEquals` sui colori): senza, ogni build ridisegnerebbe il grafico identico. Ogni `TextPainter` si libera con `dispose()`.
    - Per lo screen reader il grafico è un'immagine con una descrizione («Piano cartesiano: y = 2x − 4, …»).
- **`ExpressionEvaluator` (`lib/widgets/expression_evaluator.dart`) è il motore della calcolatrice scientifica** (`scientific_calculator.dart`) **e del box `graph`**, che gli passa le funzioni da campionare, le curve in `t`, le aree e le condizioni delle regioni: `sampledSegments` chiama `tryEvaluate` con `x` e considera assente ciò che non torna. I suoi 45 test sono quelli della sola calcolatrice e restano tali.
  - Oltre a `+ - * / ^ %` e alle funzioni di base ha `asin acos atan` (in gradi restituiscono gradi), il fattoriale postfisso `!` (interi da 0 a 170, lega più stretto di segno e potenza: `-3!` è `-(3!)`) e le potenze non finite come **errore**, non come zero: `0^-1` non vale 0. Sono aggiunte: un'espressione che prima era valida dà lo stesso valore, anche nei grafici.
  - Non fa la moltiplicazione implicita (`2 3` resta un errore): `2π` e `2(3)` li risolve la calcolatrice.
- **La calcolatrice** (`ScientificCalculatorSheet`) è una scientifica classica, 8 righe da 5 tasti alti 40 (non 46, per non allungare il foglio): 2nd, trigonometriche e inverse, x², x^y, √, 1/x, n!, ln/e^x, log/10^x, π/e, parentesi, %, memoria (MC, MR, M+, M−, con «M» sul display quando è piena), Ans, ⌫, AC, ±, e le quattro operazioni.
  - Tasti nello stile del design: cifre bianche col bordo da 3, operatori gialli e `=` indaco col gradino pieno, funzioni lilla, AC e ⌫ in rosso. Etichette in **Plus Jakarta Sans 500, non Outfit**: Outfit non ha `π` né `√`.
  - **Le etichette evitano i caratteri che i font non hanno**: Plus Jakarta Sans non ha `ˣ ʸ ⁿ ⌫`, e sul web il carattere di riserva andrebbe scaricato. Per questo `asin`/`acos`/`atan`, `1/x`, `x^y`, `e^x`, `10^x`, e ⌫ è l'icona `backspace_outlined`; sul display l'inversa è `asin(` e il reciproco `^(−1)`.
  - L'espressione è una **lista di token**, non una stringa: ⌫ toglie `sin(` in un colpo, e il `*` della moltiplicazione implicita (`2π`, `2(3)`, `)(`) si mette fra un token che chiude un valore e uno che lo apre. `%` è la percentuale (`/100`), non il resto: il resto resta solo nel motore.
  - Dopo `=` un numero comincia da capo e un operatore continua da `Ans`, come sulle calcolatrici. Il `−` all'inizio, dopo `(` o dopo `× ÷ ^` è il segno; ± cambia il segno del numero in coda. `Ans` e `M` entrano nel parser come letterali tra parentesi, senza la notazione `1e-7` che il tokenizer non legge.
  - 2nd cambia le etichette dei tasti con una seconda funzione e si spegne dopo l'uso.
- **Lesson `content`**: stringa markdown **o** array di segmenti (righe di testo come stringhe, box come oggetti); `LessonStep.fromJson` appiattisce entrambi in una stringa `::box`/`::endbox`. Nei JSON preferisci l'array.
- **Step `type`**: `info` | `mcq` | `practice_quiz` (`LessonStepType`). Ogni step è una card a sé nel `PageView` di `LessonScreen`, mai un box annidato.
- **Formule in linea**: `MathText(inline: true)` fa sì che una formula **da sola** resti una riga di testo (stessa dimensione, nessun margine) invece di una formula «in display» (×1,1 e 8 px sopra e sotto), che rendeva più alte le righe con formule. Lo usano le opzioni e il feedback dei quiz, `PromptView` e le verifiche; gli esercizi (`ExerciseDetailScreen`) tengono il display. Una frazione alza comunque la sua riga: è la formula che è alta.
- **`PromptView`** auto-rileva il prompt: `assets/` iniziali o `http(s)` (`PromptView.isImageSource`) → `ImageSource`, tutto il resto → `MathText` (quindi matematica mista a testo funziona). Il ramo immagine wrappa in `ClipRRect(14)`: è esattamente perché il box `image` non deve.
- **Step `mcq`**: `prompt` (reso da `PromptView`), `options[]`, `correctIndex`, `explanation?`; risolvendolo compare «Completa la lezione».
- **Step `practice_quiz`**: card di verifica con `title` ed `exercises[]` (`prompt`, `text?`, `options[]`, `correctIndex`, `explanation?`); `content` non renderizzato, **un esercizio per volta** (`PracticeQuizView`, stato pubblico `PracticeQuizViewState.reload()`).
  - `Icons.refresh_rounded` fra i bottoni galleggianti, a sinistra di «Completa la lezione»: estrae il successivo da una coda mescolata senza ripetizioni e sparisce se c'è un solo esercizio.
  - Opzioni, feedback e shake condivisi con MCQ via `McqOptionTile` / `McqFeedbackCard`.

### Card di lezione e bottoni galleggianti

- **I bottoni della lezione non stanno nelle card**: toolbar degli strumenti, reload della verifica e «Completa la lezione» sono **in sovraimpressione** (`_floatingControls` in `_LessonScreenState`, un `Positioned.fill` nello `Stack` del corpo, sopra la `PageView` e sotto calcolatrice e trofeo) e **restano fermi** mentre le card scorrono. Stanno dove era il piede della card ferma: in basso a `_kCardControlsBottom` (i due 12 sotto la card più il suo padding) più l'inset di sistema, e ai lati a filo della colonna di testo (`larghezza·(1 − _kViewportFraction)/2 + _kCardSideMargin + _kCardPadding`).
  - Ognuno **c'è solo dove serve** per la card corrente (`_page`): la toolbar sempre, il reload sulle verifiche con più di un esercizio, «Completa la lezione» quando `_canCompleteAt(_page)`. Comparendo e sparendo si dissolvono e scalano da 0.8 (`AnimatedSwitcher`, `AppMotion.medium`); la chiave porta la pagina, così cambiando card fra due verifiche il bottone riparte. Col movimento ridotto cambiano e basta.
  - Il reload è un `AppButton` `outline` solo icona, alto come gli altri (`_kFooterControlHeight`, 49 col gradino); «Completa la lezione» si riduce all'icona se il testo non ci sta (`_completeDoesNotFit`).
  - La card non ha più il piede: il suo `SingleChildScrollView` ha in fondo il padding dei bottoni, così il testo scorre fin sopra di loro invece di finirci sotto. Sullo spazio vuoto fra i bottoni il tocco passa alla `PageView`.
- **Lo swipe verso sinistra sull'ultima card completa la lezione** anche senza bottone.
  - Un `Listener` attorno al `PageView`, non un `GestureDetector` esterno: perderebbe l'arena col drag della `PageView`. Conta solo mosse più orizzontali che verticali e tira la card fino a `_kSwipeCompleteThreshold` (56), poi chiama `_complete`.
  - La condizione è `_canCompleteAt(index)`, la stessa che mostra il bottone, quindi l'esercizio non si bypassa.
- **La toolbar è una sola per tutta l'app**: `AppToolsBar` (`lib/widgets/tools_bar.dart`, `kToolsBarHeight` 62, `M3EToolbarSize.large`, più grande dei bottoni del piede della lezione che restano a 49 (`_kFooterControlHeight`) e a filo dello stesso spigolo), usata dalla lezione e, tramite `ToolsOverlay`, da **elenco esercizi e pagina dell'esercizio** (in basso a sinistra a 20, FAB che apre la calcolatrice a tutto schermo). Non c'è più `ExerciseToolsBar` con le due azioni vuote. Chiave di default `tools_toolbar`, la lezione passa `lesson_toolbar`. `M3EToolbar` è un `Positioned(left: …, bottom: …, width: M3EToolbarTokens.fabMedium)` dentro i bottoni galleggianti, scalata di `_kFooterControlHeight / M3EToolbarTokens.fabMedium` con `Alignment.bottomLeft`: il FAB compatto è a filo della colonna di testo, ha lo spigolo inferiore del bottone e cresce in alto.
  - **Non** sta nella `Row` degli altri bottoni: il pacchetto riserva l'altezza della pila (136px, di cui 80 il FAB) in layout anche da collassata, e con la larghezza illimitata di una `Row` il suo layout verticale va in `Infinity` — da qui il `width` nella `Positioned`.
  - **Una toolbar sola** (chiave `lesson_toolbar`), non una per card: aperta resta aperta cambiando card. Lo stato è `_toolbarExpanded` in `_LessonScreenState`.
  - Il tap è sull'icona del FAB, non sul `getCenter` del pacchetto.
  - **Colori**: FAB e pannello sono `accent` come la barra di avanzamento della lezione. Il pannello prende `backgroundColor`/`foregroundColor`; il FAB no, legge `primaryContainer` dal **tema del pacchetto**, che **non è il `Theme` di Flutter** (`material_3_expressive` usa il `ThemeData` di `material_ui`): per questo la toolbar sta dentro `M3ETheme(data: AppTheme.lessonToolbar)`, uno schema nato dall'indaco con `primaryContainer` indaco e contenuto bianco. Un `Theme` di Flutter attorno non cambia niente.

### Home, ripresa e avanzamento

- **La Home è quattro sezioni**, in quest'ordine: `HomeContinueCard` («Continua», card grande: riprende `ResumeTarget.find()` con barra e percentuale; senza ripresa propone la prima lezione non fatta della scuola, «Inizia»; senza profilo o a tutto finito dice perché), `DailyExerciseCard` («Esercizio del giorno»: `DailyExercise.of(giorno)`, uno per giorno dalla scuola del profilo o da tutte le scuole senza profilo; «Provalo» apre `ExerciseDetailScreen`), `ArgomentoCarousel` con la testata «Il tuo percorso» (le card hanno anche la barra `x/y` delle lezioni fatte) e `MathFactCard` («Lo sapevi?»). Ogni sezione si ascolta da sé, quindi la lista di `HomeScreen` non sta dentro un `ListenableBuilder`. Via «Jump Back In», la missione con le scorciatoie e il banner «Sblocca tutto» (non c'è niente a pagamento). **`MissionScreen`, `MissionHero` e `WeakPointsScreen` non hanno più un punto d'ingresso** (l'entrata era la scorciatoia della missione): il codice c'è ancora, in attesa di decidere se riaprire i punti deboli da qualche parte.
  - **`ResumeTarget`** (`lib/data/resume_target.dart`): la lezione a metà con argomento e punto; lo usano la Home e la card «Riprendi» di Lezioni.
  - **`MathFactCard`** (`lib/widgets/math_fact_card.dart`, dati in `lib/data/math_facts.dart`): una curiosità sulla matematica, tutta offline, una per giorno (giorno dell'anno modulo il numero di curiosità) e il tocco passa alla successiva, che si scrive a macchina. **Le curiosità devono essere fatti verificabili**, non leggende.
- **`LessonResumeEngine` non c'è più**, con `LessonTarget`: il suo lettore era «Jump Back In». Il punto di ripresa (`lessons_in_progress_v1`) si salva ancora, ma oggi nessuna schermata lo mostra.
- **Progressi per utente**: `ProgressStore` chiave lezioni, esercizi e ripresa per `ownerId` (`AuthStore.currentUser.accountId`, o `guest`), e ascolta `AuthStore` per notificare al cambio utente. Le chiavi di `lessons_completed_v1` senza proprietario (`livello::lezione`) passano all'ospite al `load()`.
- **Ripresa lezione**: `LessonScreen(initialStep: 0)` riparte da uno step preciso e **non** ripristina risposte già date (`_solved`, `_selectedOption`, `_wrongOptions` restano puliti).
  - Salva il punto in `initState` e a ogni `onPageChanged`, quindi sopravvive all'app uccisa; `_complete()` chiama `clearLessonResume()`, altrimenti la ripresa punterebbe alla lezione appena finita.
  - La prima scrittura è differita con `addPostFrameCallback`: dalla `initState` la notifica arriverebbe durante la build della nuova rotta.

### Accesso, profilo e avatar

- **Sessione e account sono due cose diverse.** `user_profile_v1` è la **sessione** (il profilo mostrato a schermo), `accounts_v1` è l'elenco degli account del dispositivo (`LocalAccount` = profilo + hash + sale). `signOut()` cancella la sessione e **tiene** l'account, altrimenti non si potrebbe rientrare.
- **Non c'è server, e va detto.** Un account esiste solo su questo dispositivo e «unico» significa unico qui; la validazione «lato server» è `AuthStore`, che risponde `AuthException` con il messaggio da mostrare. `PasswordHasher` (PBKDF2-HMAC-SHA256, 10 000 iterazioni, sale `Random.secure()`) evita la password in chiaro, ma `shared_preferences` su web è `localStorage`: **non è una barriera di sicurezza** e non va raccontata come tale. Per la protezione vera serve un backend, che fuori dallo scope di questo progetto.
- `AuthStore.signIn` accetta **ID account o email** (stesso campo del login) e risponde `SignInResult`: `wrongPassword` e `unknownAccount` stanno separati perché il login deve poter rispondere «password sbagliata» a chi l'ha sbagliata. Un account Google e un profilo anteriore alle password non hanno hash: `googleOnly` e `noPassword` dicono perché non si riaprono col login.
- **`accountId` è derivato dall'email** (`AuthValidators.accountIdFromEmail`) quando non lo sceglie l'utente, quindi i chiamanti che non lo passano non cambiano. Se è già preso prende un suffisso (`anna`, `anna2`).
- Un profilo salvato **prima** di `accounts_v1` diventa account senza credenziale al primo `load()` (`_needsLegacyAccount`): nessuna perdita di sessione, ma da quel profilo non si rientra col login.
- **Le regole dei campi stanno in `AuthValidators`**, logica pura con `taken` ricevuto da fuori: l'unicità è uno stato dello store, non un fatto del validatore. Il `Form` gira in `AutovalidateMode.onUserInteraction`, così «ID account già in uso» e «le password non coincidono» si vedono mentre si scrive.
- **Google è una demo, non un OAuth**: `signInWithGoogleDemo` apre il dialog dimostrativo di `lib/widgets/google_button.dart` e crea l'account in locale. Lo stesso widget `GoogleButton` sta su welcome, login e registrazione, e le iniziali stanno in un posto solo (`initialsOf` in `profile_avatar.dart`).
- **La scelta dell'avatar si anima** (`AvatarPicker`): l'avatar scelto cresce a 1.08 con un rimbalzo (`AppMotion.bounce`, `slow`) e bordo indaco e anelli crescono in `medium`, da trasparenti e senza spessore invece di comparire di colpo. Il picker tiene da sé la scelta corrente: nel profilo il foglio si chiude al tocco, e aspettando il valore dal chiamante l'animazione non si vedrebbe. Per lo stesso motivo il foglio del profilo si chiude dopo `AppMotion.slow` (subito col movimento ridotto), con il `Navigator` preso prima dell'attesa.
- **Avatar a scelta, non upload**: l'app non ha rete e `shared_preferences` non è un archivio di immagini, quindi `avatarId` è il **nome** di uno dei simboli in `avatarOptions` (`material_symbols_icons`), non il `IconData` né un URL. Vuoto = iniziali, ed è quello che fa «Rimuovi foto». `ProfileAvatar` disegna foto, simbolo o iniziali ed è l'unico posto che lo fa: header e profilo devono cadere sulla stessa identità.
- **La registrazione è a passi** (`RegistrationScreen`), come «Creazione profilo» del canvas: 1) chi sei (l'avatar grande al centro, che al tocco apre **sopra di sé** un rettangolo con tutti gli avatar e si richiude dopo la scelta; sotto, il nome), 2) l'account (email, ID, password con il metro a tutta larghezza, conferma, termini), 3) la scuola, 4) l'anno, **solo per medie e superiori** (`UserProfile.courseId`, un `Course.id` dentro la scuola scelta; all'università i passi sono tre). `registerManual` riceve `avatarId`, `schoolLevelId` e `courseId`: il profilo è completo alla fine e il tasto «Crea il mio profilo» cambia passo con la scuola (`_needsYear`).
  - Testata indaco col bordo ondulato (`WaveBottomClipper`, `lib/widgets/wave_clipper.dart`, la stessa del benvenuto): la sola freccia e il titolo del passo **al centro**, in dissolvenza (`AnimatedSwitcher`, `medium`). Niente «PASSO X DI N» né barra di avanzamento.
  - Il passo nuovo entra con `flutter_animate`: dissolvenza più uno scorrimento laterale dell'8% (avanti da destra, indietro da sinistra), `slow` `easeOut`; il contenuto ha la chiave del passo, così l'effetto riparte a ogni cambio. Col movimento ridotto niente `Animate`, il passo cambia e basta.
  - «Continua» controlla il passo al tocco; **gli errori dei campi compaiono solo dopo un «Continua» a vuoto**, non mentre si scrive (`_failed`: da lì il passo si aggiorna a ogni modifica con `onUserInteraction`). Ai passi scuola e anno è spento finché non si sceglie. `PopScope(canPop: passo == 0)`: freccia e back di sistema dal secondo passo tornano al passo prima. I controller stanno nello stato, quindi i dati restano tornando indietro.
  - **A profilo creato** la schermata non esce: diventa un riepilogo animato (avatar che rimbalza in scena, «Profilo creato!», una `_SummaryRow` per nome, ID, scuola ed eventuale anno, in sequenza) e «Inizia» fa `popUntil((route) => route.isFirst)`.
  - **L'anno scelto apre Lezioni ed Esercizi**: `AuthStore.preferredCourseIndex(levelId, courses)` dà l'indice per `LessonListScreen` e `CourseScreen` (`PageController(initialPage:)`), solo se la scuola è la propria e non c'è una visita (`BrowseStore.levelId == null`). `updateSchool` azzera `courseId` se la scuola cambia.
- **`SchoolPickerScreen` non riceve callback, riceve `onboarding`.** Le schermate che aprono la scelta della scuola la `pushReplacement` (la registrazione e il login con Google), quindi sono già smontate quando l'utente preme «Crea il mio profilo»: un `onSaved: () => ...` che chiude il `context` del chiamante naviga da un elemento *defunct* e il tap non fa nulla. In debug «Looking up a deactivated widget's ancestor is unsafe», in release la catena `_parent` è già `null` e va in null-check: stesso sintomo, due cause diverse. Il flag dice solo *cosa* fare (`onboarding: true` → `popUntil((route) => route.isFirst)`, cioè la home che è la radice dello stack; `false` → `pop()` e si torna al profilo), e la navigazione esce dal **proprio** context del picker.
- **«Password dimenticata?» non può funzionare**: non c'è email né server, quindi il link apre un dialog che lo dice. Meglio che un form che non manda niente.
- **L'accesso è il punto d'ingresso dell'ospite**: l'icona del profilo in header, da ospite, spinge `LoginScreen`, e da lì il link «Registrati» apre `RegistrationScreen`. La registrazione non ha un'icona propria. `WelcomeScreen` resta il punto d'ingresso della card ospite in Home, e `ProfileScreen` da ospite mostra «Accedi» e «Registrati»: chi è dentro l'app vede le schermate dell'account, chi è in strada sceglie prima tra registrazione e accesso. Con la sessione aperta l'avatar apre `ProfileScreen`.

### Impostazioni, temi e testo

- **Personalizzazione**: `CustomizationScreen` (`lib/screens/customization_screen.dart`) aperta da `HeaderCustomizationButton` (`lib/widgets/main_header.dart`, `Icons.tune_rounded`, `Key('header-customization')`) nelle `AppBar.actions` **delle tre pagine main**, **sia per l'ospite sia per l'utente registrato**, perché sono impostazioni dell'app e non del profilo: nel profilo non c'è. Le tre pagine hanno lo stesso header, quindi il bottone è lo stesso widget e non una copia: la chiave è `header-customization` e non `home-customization` perché non sta solo in Home.
  - Un gruppo solo, «Risposta» (interruttore vibrazioni): il tema è uno, quello chiaro del design, e il toggle sole/luna non c'è più. La scelta sta in `SettingsStore`, la pagina è un `ListenableBuilder` su di esso.
  - **Un widget `const` nella lista di un `ListenableBuilder` non si ricostruisce**: il padre che si ricostruisce gli passa la stessa istanza canonicizzata e `Element.updateChild` la salta. Vale per l'interruttore delle vibrazioni e per `ArgomentoCarousel`, che per questo si ascoltano **da sé**.
- **Il design viene dal canvas «Illustrazioni App Educativa»** (claude.ai/artifact/UjtXU3sEDTVdSC7RuCYdjX): indaco profondo, giallo, crema, Outfit e Plus Jakarta Sans, bottoni a pillola con un gradino pieno sfalsato, card con un'ombra fine.
  - **Un tema solo, chiaro**: il canvas non ha una versione scura, quindi `AppTheme.dark`, `AppPalette.dark`, `ThemeToggle` e `toggle.json` non ci sono più. `settings_v1` ignora il `themeMode` dei salvataggi di prima.
  - **I colori del canvas restano decoro e riempimento**: `yellow`, `orange`, e i loro `…Deep` per bordi e ombre piene. I ruoli che finiscono come testo (`easy`, `medium`, `hard`, `teal`, `pink`, `indigo`) sono toni scuri della stessa famiglia, perché il verde, l'arancio e il rosso del canvas su bianco stanno sotto 4.5:1: c'è un test che li verifica su bianco e su crema.
  - **I font sono in locale** (`assets/fonts/`, statici, un file per peso, licenze OFL accanto): l'app non va in rete e Flutter non sceglie il peso di un font variabile. `AppText.headingFont` (Outfit, solo 600) e `AppText.bodyFont` (Plus Jakarta Sans, 400 e 500) sono i nomi da usare. `ThemeData.fontFamily` è Plus Jakarta Sans; `display*`, `headline*`, `titleLarge` e `labelLarge` sono rimessi a Outfit 600. **Mai un peso oltre quelli dei file**: Flutter simulerebbe il grassetto (Plus Jakarta Sans oltre 500, Outfit oltre 600).
  - **`RichText` non eredita il `DefaultTextStyle`**, e `AnimatedDefaultTextStyle` lo sostituisce: in entrambi i casi lo stile dichiara `fontFamily: AppText.bodyFont` (`NotesText`, `MathText`, le etichette degli anni), altrimenti il testo esce nel carattere di sistema.
  - **Un bottone con un `textStyle` proprio non eredita il font del tema**: lo stile del bottone sostituisce quello del tema, quindi ogni `textStyle` di un bottone dichiara `fontFamily` (come `AppTheme.wideButton`).
- **Il primary è dichiarato, non derivato**: `ColorScheme.fromSeed` prende dal seme la **tonalità 40**, quindi dall'indaco del design esce un altro viola e il primary non sarebbe quello. `AppTheme` dichiara a mano `primary`, `onPrimary`, `primaryContainer`, `onPrimaryContainer`, `secondary` (il giallo, con l'inchiostro sopra), `tertiary` e `tertiaryContainer`, e dal seme tiene il resto della scala (test sul contrasto 4.5:1 in `home_widget_test.dart`).
- **`AppPalette.danger`** (`0xFF8B1B34`) è il terziario: il colore delle sezioni «da ripassare». Non viene dal seme e non si aggiunge a mano in nessun widget: si usa il campo, o `ColorScheme.tertiary` se serve il ruolo M3.
- **I caratteri vengono da `AppText`** (`lib/theme/app_text.dart`), mai da un letterale: `display` 26, `hero` 23, `headline` 21, `title` 19, `titleLarge` 18, `titleMedium` 16, `titleSmall` 15, `bodyLarge` 14, `bodyMedium` 13.5, `bodySmall` 13, `label` 12.5, `labelSmall` 12, `caption` 11.5, `micro` 11.
  - **Il corpo delle lezioni ha i suoi slot**: `docTitle` 24, `docHeading` 19, `docBody` 15, `docMono` 12.5. È un documento, non un'interfaccia: sta dentro la scala della UI ma non è un suo ruolo, e i `fontSizeMultiplier` dei JSON valgono come prima perché cambiano i valori base, non i rapporti.
  - `micro` è il pavimento e non si scende: sotto gli 11 px non c'è leggibilità. L'unica eccezione storica era l'etichetta della pillola a 10, salita a `micro`.
  - `test/app_text_test.dart` fissa l'ordine degli slot, il titolo delle `AppBar` a `headline` in Outfit 600, il testo in Plus Jakarta Sans e nessun peso del testo oltre 500: sono le invarianti che reggono la gerarchia.
- **`SectionHeader` non ha padding orizzontale**: tutte le pagine che ospitano una testata hanno già i loro 20 px, quindi i 20 della testata sommati mettevano i titoli a 40 mentre le card erano a 20 — disallineati e con 20 px in meno per il testo. C'è un test in `home_widget_test.dart` che confronta il margine sinistro di titolo e card, perché il difetto si vede solo sul telefono.
- **Scala del testo**: non c'è più una scelta dell'utente, quella del **sistema** sì e va rispettata.
  - `RichText` non applica il `textScaler` di `MediaQuery` (default `TextScaler.noScaling`) e dentro `flutter_math_fork` le formule sono `RichText` costruite a mano, quindi il corpo delle lezioni (`MathText`, `NotesText`) resterebbe fermo mentre il resto cresce: `textScaleFactorOf(context)` (`math_text.dart`) legge il fattore e i due widget lo moltiplicano a mano sul loro `fontSize`.
  - `MathApp` **non** tocca il `MediaQuery`: la scala del dispositivo è sua. `mathSpan` resta puro, chi lo chiama ha già scalato.
- **Tastiera**: tap fuori da un campo chiuso e la tastiera scende, **ovunque**. Si fa una volta sola in `MathApp.builder` con `DismissKeyboard` (`lib/widgets/dismiss_keyboard.dart`), che sovrascrive `EditableTextTapOutsideIntent` e `EditableTextTapUpOutsideIntent`: le azioni di `EditableText` sono `Action.overridable`, quindi un `Actions` più in alto vince per tutte le schermate, i dialog e l'overlay.
  - Il default di Flutter (`_EditableTextTapOutsideAction`) unfoca su desktop e sul web ma **non** sui telefoni col dito: da lì il widget.
  - Non basta `unfocus` al tap down, altrimenti scrollare la pagina chiuderebbe la tastiera: si tiene il `PointerDownEvent` e si unfoca al tap up solo se il movimento è sotto `kTouchSlop`, come nell'esempio del framework. Niente `GestureDetector` attorno al corpo di ogni schermata: perderebbe i tap sui widget interattivi che vincono l'arena e non coprirebbe i campi futuri.
- **Vibrazioni**: `HapticFeedback` non ha interruttore globale, quindi ogni chiamata passa da `AppHaptics` (`lib/haptics.dart`), che legge `SettingsStore.hapticsEnabled`. Il tasto che spegne le vibrazioni chiama `HapticFeedback.selectionClick()` diretto: è l'unico modo di sentire che l'opzione è arrivata.

### Sezioni della Home

- **Feedback delle risposte** (`mcq_option_tile.dart`, domande delle lezioni ed esercizi di verifica): sulla sbagliata la card «Non è corretto» si scuote (`ShakeWidget`); sulla giusta l'opzione fa un **pop**, una campana di scala 1 → 1.06 → 1 in `slow`, e la spunta entra in scala con `easeOutBack`. Col movimento ridotto niente scossa né pop, resta il cambio di colore.
  - **Pop e spunta sono implicite** (`TweenAnimationBuilder`), non `Animate`: ogni `Animate` crea al montaggio un `Future.delayed`, anche con ritardo zero e anche guidato da `target`, e su un elemento sempre presente come l'opzione sarebbe un timer per opzione a ogni domanda (nei test, un timer appeso). `flutter_animate` va bene dove si aspetta la fine dell'effetto (le entrate: Home e passi della registrazione).
  - Nei test la scala di un `Transform.scale` si legge da `storage[0]`: `getMaxScaleOnAxis` conta anche l'asse z, che resta 1, e sotto 1 risponde sempre 1.
- **Shake** (`ShakeWidget`, `lib/widgets/shake.dart`): quattro oscillazioni di 10 px che si smorzano, in `AppMotion.slow`, con un `TweenAnimationBuilder` e non con `flutter_animate`. Senza `trigger` si scuote una volta al montaggio (la card «Non è corretto», chiave nuova a ogni tentativo); **con `trigger` si scuote quando il numero cresce, senza ricreare il figlio**, quindi un campo di testo tiene fuoco, testo ed errore. Cambiare la chiave a un campo lo ricreerebbe, e un `Animate` sempre presente lascerebbe un timer al montaggio.
  - **Campi obbligatori vuoti**: registrazione (nome; email, ID, password, conferma), login (identificativo, password) e profilo (nome, ID) avvolgono i campi in `ShakeWidget(trigger: _shakes.of(controller))`; quando la validazione fallisce, `FieldShakes.shakeEmpty` fa crescere il contatore dei soli campi vuoti. Col movimento ridotto niente scossa, restano messaggio e bordo rosso.
  - **Il bordo al fuoco si anima già**: `InputDecorator` interpola ogni cambio di bordo in 167 ms (`_kTransitionDuration` di Flutter), quindi `fieldDecoration` non aggiunge niente.
- **Le sezioni della Home entrano in sequenza** al primo caricamento (`flutter_animate`): dissolvenza e salita del 6%, `slow` `easeOut`, ognuna `AppMotion.stagger` (60 ms) dopo la precedente. Col movimento ridotto nessun `Animate`.
  - **Il ritardo sta negli effetti** (`fadeIn(delay:)`, `slideY(delay:)`), mai in `Animate.delay`: quello aspetta con un `Future.delayed` non cancellabile, e nei test resta un timer appeso a widget già smontato.
  - **Una volta sola**: la lista ricrea le sezioni che rientrano scorrendo. Alla prima sezione entrata `HomeScreen` fa **un** `setState` (`_entered`), così i widget della lista diventano `Animate(autoPlay: false, value: 1)` e una sezione ricreata è già al suo posto; senza quel rebuild la lista ricreerebbe il widget di prima e l'entrata ripartirebbe. La struttura non cambia (l'`Animate` resta), altrimenti le sezioni perderebbero lo stato: il carosello estrarrebbe un altro anno.
  - Nei test `Animate` parte al frame dopo che l'orologio è avanzato: `pump()` più un `pump(durata)` prima di misurare.
- **La Home è una pagina sola**: ospite e collegato hanno lo stesso disegno, cambia solo il contenuto. L'unica differenza accettata è l'identità in testata (icona e «Ospite» invece di avatar e nome).
- **`ArgomentoCarousel`** (`lib/widgets/argomento_carousel.dart`) è il carosello degli argomenti, al posto di quello delle foto: con la scuola nel profilo **tutti gli argomenti della scuola**, in ordine; da ospite o senza scuola quelli di **un anno a caso** fra gli anni che hanno argomenti, estratto una volta per montaggio (a ogni rebuild cambierebbe slide sotto il dito). Il tap apre `ArgomentoLessonsScreen`.
  - Card **un poco più alte che larghe** (altezza = larghezza × 1,15, `_heightFactor`, tutte uguali), circa **due a schermo** (la larghezza è `(larghezza − 20 − 2·12) / 2.2`: due intere e un pezzo della terza, che dice che si scorre). È un `ListView` orizzontale e non un `PageView`, che aggancerebbe e centrerebbe una card per volta. La striscia scavalca i 20 px di margine della lista della Home con un `OverflowBox` largo quanto lo schermo e li rimette come padding: la prima card è a filo del testo, le altre scorrono fino al bordo. Ogni card è `TopicBackground` nel colore di `topicColor`, con titolo e «anno · N lezioni» in bianco.
  - Si ascolta `AuthStore` **da sé** (in Home è `const`, vedi «Un widget `const` nella lista di un `ListenableBuilder`»). La testata «Argomenti» (`SectionHeader`, che ha già i 24 sopra) sta **dentro** il carosello: senza argomenti la sezione sparisce con la sua testata. I 24 prima della missione sono della lista della Home.
- **`MissionHero`** è riusato anche da `MissionScreen`, quindi le quattro scorciatoie (Lezioni, Esercizi, Punti deboli, Profilo) stanno dietro `showShortcuts`, **false di default**: sulla pagina missione sarebbero due righe di menu sopra il testo che descrive il menu. Ci sono **anche da ospite**: il livello si risolve al tap (`BrowseStore.levelId` prima del profilo, come fa la pillola) e se non c'è si chiede quale sia con `showSchoolChoiceSheet`. Per questo `_Shortcut` porta un `onTap` e non una `Widget`: due scorciatoie non possono sapere il livello da una costante.
- **`RecommendationRow`** (`lib/widgets/recommendation_row.dart`): piastra 42, titolo 15 in Outfit 600, badge opzionale, anteprima su due righe, play 42 opzionale. Era condivisa con la sezione «Per te», tolta dalla Home; resta la riga di `ExerciseCard`, che ci delega passandoci stato e difficoltà. `RecommendationEngine` è stato tolto con la sezione.
- **`WeakPointsScreen` ha due stati vuoti**: da ospite «Ancora niente da ripassare» con CTA al benvenuto, collegato «Tutto assimilato!». «Tutto assimilato» è un merito, e un ospite non ha ancora studiato niente: dirglielo sarebbe falso.
- **I punti deboli** si raggiungono dalla scorciatoia della missione: `WeakPointsScreen` elenca un `WeakTopicRow` per topic, ognuno nella sua `AppCard`.

### Navigazione, header e ricerca

- **Swipe fra le pagine principali**: `PillNavOverlay` avvolge il contenuto in un `GestureDetector` (`pill-swipe`, `onHorizontalDragEnd`, soglia 300 px/s) che nell'ordine Lezioni · Home · Esercizi va alla successiva con lo swipe verso sinistra e alla precedente verso destra, chiamando lo stesso `_select` del tocco sulla barra. Un `GestureDetector` fuori e non un `Listener`: il carosello degli argomenti e gli `YearTabs`, orizzontali, vincono l'arena e scorrono senza cambiare pagina. **L'anno di Lezioni ed Esercizi non si cambia più con lo swipe** (niente `PageView`): solo dagli `YearTabs`.
- **PillNavBar** (`lib/widgets/pill_nav_bar.dart`): `PillTab` = `lessons` | `home` | `exercises`, visibile solo sulle 3 pagine main. È la tavola «Navbar» del canvas (vedi `DESIGN.md`), un filo più bassa: fascia `headerBand` di 72 a tutta larghezza con gli angoli in alto a 28, Lezioni ed Esercizi ai lati (le colonne rientrano di `_kSideInset`, 28, per stare più vicine a Home), Home in un cerchio da 70 che sporge sopra la fascia. Va al livello dell'utente se c'è un profilo, altrimenti mostra il foglio di scelta della scuola. `ProfileScreen` è una sotto-pagina: niente barra, back nell'`AppBar`.
  - Il nome resta per i chiamanti, ma non è più una pillola in vetro: niente indicatore che scorre, niente trascinamento. Il tocco naviga subito. Chiavi `pill-lessons`, `pill-home`, `pill-exercises` (nella Home i nomi «Lezioni» ed «Esercizi» ci sono anche nelle scorciatoie della missione) e `pill-surface` per la fascia.
  - **`_pending`** tiene acceso il tab chiesto finché la schermata di partenza è in vista, cioè durante il ritorno animato alla home e col foglio della scuola aperto. Senza, la barra tornerebbe per un istante sulla sezione di partenza. Si azzera quando cambia `selected`, quando la scelta della scuola si annulla e in `_resetTo`.
  - `PillNavOverlay` riserva sotto il contenuto `kPillBottomReserve` (92) più l'inset di sistema: la fascia scende sotto l'inset, i bottoni no. Cerchio, nome e margine di Home superano di poco i 92, quindi il cerchio sta in un `OverflowBox` e sporge in alto come nel design.
  - **Solo Home simula la pressione**, come `AppButton`: al tap down il cerchio trasla di `_kHomeStep` (5) e il gradino va a zero, in `AppMotion.fast`; al rilascio o all'annullamento torna su. Lezioni ed Esercizi non hanno gradino e non si muovono.
  - Le icone sono quelle a tratto del canvas, in SVG con il colore scritto dentro (`SvgPicture.string`). Lo stato lo dicono il colore e la semantica «selezionato»; nei test si legge da lì (`_attiva` in `pill_navigation_test.dart`).
- **I pulsanti dell'header aprono con un'espansione** (`lib/widgets/reveal.dart`): profilo (avatar, badge e icona da ospite), personalizzazione e ricerca si espandono con un cerchio che cresce dal centro del pulsante (`ClipPath` con `_RevealClipper`, `AppMotion.slow`, `easeOut`) e tornando indietro si ritira. `pushRevealed(context, builder)` per le pagine, `showSearchOverlay` per la ricerca (`revealTransition`); **il `context` deve essere quello del pulsante**, che ne dà l'origine (da qui i `Builder` attorno ad avatar e badge). Col movimento ridotto la pagina compare e basta.
- **Header**: scheletro identico sulle 3 pagine main. L'`AppBar` è una banda **dello stesso colore dello sfondo della pagina** (`c.background`, testi e icone `c.textPrimary`/`c.textSecondary`), a tutta larghezza: non si stacca dalla pagina. Lo `shape` con gli angoli in basso a `kHeaderBottomRadius` (28) resta, ma a tinta unita non si vede. `elevation: 0`, altrimenti l'ombra sporcherebbe lo sfondo sotto gli angoli. Il `title` è `MainHeaderTitle` (`lib/widgets/main_header.dart`, chiave `header-identity`): la sola identità, `ProfileButton` a sinistra e `ProfileSummary` in `Expanded`, che arriva fino alle icone. Nelle `actions` la lente (`HeaderSearchButton`, chiave `header-search`, `Icons.search_rounded`) e la personalizzazione (`HeaderCustomizationButton`, chiave `header-customization`), che è **l'ultima a destra** su tutte e tre: cercare è l'azione più frequente, quindi sta subito a sinistra delle impostazioni.
  - Costanti in `main_header.dart`: `kHeaderHorizontalMargin` (30, `titleSpacing`), `kHeaderToolbarHeight` (80, `toolbarHeight`), `kHeaderActionsPadding` (destra 12), `kHeaderBottomRadius` (28). Non c'è padding della pilla: il colore è dell'`AppBar`, quindi l'avatar è di nuovo a filo di `kHeaderHorizontalMargin` e i test lo misurano lì.
  - **La pagina di un argomento** (`ArgomentoLessonsScreen`) tiene la stessa banda, con `MainHeaderAppBar(showBack: true)`: la freccia indietro bianca prima dell'avatar (su iOS e sul web non c'è un back di sistema) e `titleSpacing` a 0, perché il margine lo dà già la freccia. Titolo e sottotitolo dell'argomento scendono nel corpo (`_Heading`), perché nella banda c'è l'identità. Niente pillola: resta una sotto-pagina.
  - **`MainHeaderAppBar`** esiste per i 5 `AppBar` delle 3 pagine main perché **il colore è solo della riga dell'header**: il suo `bottom` (oggi nessuno lo usa: l'anno sta nel corpo, vedi «Lezioni ed Esercizi») sta in una `Column` **sotto** la banda, non nell'`AppBar.bottom`, che lo dipingerebbe dello stesso colore. L'`AppBar` sta in un `Expanded`: in una `Column` senza limite di altezza il suo layout non si chiude. Le sue `preferredSize` sono `kHeaderToolbarHeight` più l'altezza del `bottom`.
  - Il nome trunca quando le icone sono tre e lo spazio è poco: su 360px in visita è il nome a cedere, non le icone a uscire.
- **L'header non è più indaco**: usa `c.background` e i colori del testo del tema (`textPrimary` per nome e icone, `textSecondary` per la scuola; test sul contrasto in `header_band_test.dart`). `AppPalette.headerBand`/`onHeaderBand` restano per la **barra di navigazione** (`PillNavBar`) e la testata di registrazione e benvenuto. L'avatar ha l'anello `border` e il badge di modifica l'anello `background`.
- **`ProfileButton`** (`lib/widgets/profile_button.dart`) è lo slot sinistro della banda: da collegato uno `Stack` con l'avatar da `kProfileAvatarSize` (50) e il badge di modifica da 20 sovrapposto in basso a destra (`right/bottom: -2`, chiave `home-profile-edit-badge`), da ospite l'icona di persona bianca e niente badge.
    - Il badge è l'affordance dell'avatar, non una scorciatoia in più: porta a `ProfileScreen` come l'avatar. Serve un `GestureDetector` suo perché sta **sopra** l'avatar e senza gesto il tap finirebbe a terra; e non `InkWell`, perché lo schermo dell'acqua si disegnerebbe sul `Material` della pagina, fuori dal badge.
    - Lo `Stack` sta in `Clip.none`: il badge deborda di 2px oltre l'avatar.
- **`ProfileSummary`** (`lib/widgets/profile_summary.dart`) è la `Column` al centro della banda, `crossAxisAlignment.start`: nome 18 in Outfit 600 (`kSummaryNameFontSize`), il titolo della banda, e sotto il titolo della scuola 12.5 `w500` all'80% di bianco. Entrambe in ellissi (`maxLines: 1`).
    - Non c'è più il «Ciao,»: la banda è una tessera, non una frase. «Ospite» senza utente, e la riga della scuola sparisce quando la scuola non si sa.
    - La scuola è quella **che si sta guardando**: `BrowseStore.levelId ?? schoolLevelId`, quindi in visita la banda e il bottone dicono la stessa scuola. Da ospite la visita non esiste (`BrowseStore.levelId` è `null` per contratto) e la scuola arriva da `MainHeaderTitle(levelId:)`, che Lezioni ed Esercizi riempiono col livello che stanno mostrando.
- **Altre scuole in visita** (`BrowseStore`, `lib/data/browse_store.dart`): da collegato, Lezioni ed Esercizi hanno `SchoolBrowseButton` (in `main_header.dart`, chiave `header-school-browse`) **a sinistra** della lente. Apre `showSchoolChoiceSheet` con `signedIn: true`, quindi titolo «Altre scuole, lezioni/esercizi» e **niente** footer «questa scelta non ti verrà più richiesta»: da ospite il footer è vero, da collegato no.
  - È una **visita**, non una scelta: il profilo non si tocca, `ProgressStore` è già scoping per livello (`scopedKey`), e niente si persiste, quindi chiude la app e la visita finisce. `levelId` è derivato (`_levelId` confrontato col profilo), non un campo: se l'utente cambia scuola dal profilo e quella capita essere quella in visita, l'id non pilota più le pagine.
  - Mentre si guarda un'altra scuola l'header dice quale (`Icons.visibility_outlined` + il titolo accanto, bianchi come il resto della banda): senza, i progressi mostrati sarebbero quelli di un'altra scuola senza che lo si dica.
    - `SchoolBrowseButton` è un `Flexible` con dentro la sua `Row`: le `actions` dell'`AppBar` sono una `Row` che dà **larghezza illimitata** ai figli, quindi l'unico che può cedere spazio è il bottone che si rende flessibile. Con tre icone più il nome della scuola in visita, su 360px la riga sborda a destra di 14px se il nome non è dentro un `Flexible`.
  - `LessonListScreen` e `CourseScreen` risolvono il livello come `BrowseStore.levelId ?? parametro del costruttore`, quindi **non cambiano firma**. Sul cambio di scuola l'indice dei `YearTabs` torna a 0 e il `PageController` va rifatto: `high-school` ha 5 corsi e `university` 3, l'indice 4 sarebbe fuori range.
  - **La ripresa non si tocca**: `LessonScreen._isOwnLevel` confronta il `levelId` con il profilo, `_rememberResume` ritorna subito se non è il proprio livello e `_complete` chiama `clearLessonResume()` solo sul proprio. Il `completeLesson` invece gira sempre — l'esercizio è stato fatto e la chiave è per livello. `lessons_in_progress_v1` è **uno solo**: scriverlo da una visita sovrascriverebbe la ripresa della propria scuola.
  - `PillNavBar._performNavigation` legge la visita prima del profilo, altrimenti il cambio di sezione ripartirebbe da capo; `ProfileScreen._signOut` fa `BrowseStore.reset()`, altrimenti chi entra dopo si ritrova la scuola del precedente.
  - Sulla Home la banda non ha la scuola da passare (`MainHeaderTitle` senza `levelId`): da ospite senza livello è una riga sola, e va bene così invece di una riga vuota.
- **Overlay ricerca**: `HeaderSearchButton` chiama `showSearchOverlay` (`lib/widgets/search_overlay.dart`), un `showGeneralDialog` su tutta la pagina: è una rotta a dialogo, non una pagina, quindi il back la chiude tornando alla pagina da cui si è partiti.
  - Campo in `autofocus`; chiusura con la X (chiave `search-overlay-close`), `Escape` (`Shortcuts`/`Actions` con un `Intent` privato) e il back di sistema; barrier trasparente e `barrierDismissible` `false` perché dietro non c'è niente.
  - Risultati in una `AppCard` con padding `fromLTRB(18,14,18,14)`; debounce 300ms e minimo 2 lettere (`_debounce`, `_minimo`), con «Scrivi almeno due lettere.» e «Nessun risultato trovato.» come stati vuoti.
  - Ogni riga ha la pillola di tipo (`_TipoBadge`) **sopra** il titolo, da `ResultType.label` («Argomento» o «Lezione»): sopra e non accanto perché il titolo va in ellissi e un vicino nella stessa `Row` mangerebbe la larghezza dove il testo si tronca.
    - I colori sono `accent` (argomento) e `indigo` (lezione): il teal sembrava la scelta giusta ed è la sbagliata, sul `surface` chiaro non passa 4.5:1 a 12px.
    - `contesto` e `dettaglio` sotto il titolo restano: la pillola dichiara il tipo, loro dicono da dove arriva e a che livello.
  - Il tap chiude l'overlay e apre la pagina del risultato: `ArgomentoLessonsScreen` per l'argomento, `LessonScreen(lesson:, levelId:)` per la lezione. Il `Navigator` va preso **prima** del `pop`, dopo il contesto dell'overlay è morto.
- **Cosa cerca**: `SearchIndex` (`lib/data/search_index.dart`) ha `ResultType {argomento, lesson, topic, exercise}` e l'overlay chiede `search(query, types: [argomento, lesson])`: argomenti e lezioni, **per titolo e sottotitolo**. Una lezione si cerca col **proprio** titolo, non con quello dell'argomento.
  - Argomenti e lezioni arrivano da `LessonRepository.instance.argomenti`, che lo splash carica prima di `SearchIndex.build`, e il `Level` è risolto in `build` perché la ricerca guarda **tutti** i livelli, non solo quello dello studente.
  - Il ramo topic/esercizi resta indicizzato e testato (`test/widget_test.dart`) ma non ha più punti d'ingresso nell'app.

---

## 5. Naming & UI Conventions

- **Files**: `snake_case.dart` (e.g. `exercise_detail_screen.dart`)
- **Classes**: `PascalCase` (e.g. `ExerciseDetailScreen`)
- **Private classes/members**: `_` prefix (e.g. `_Logo`, `_OptionTile`)
- **Enums**: `PascalCase` names, `camelCase` values (e.g. `Difficulty.easy`, `ExerciseStatus.needsReview`). Expose a static `fromString(...)` factory and an Italian `label` getter for display text.
- **Content IDs**: kebab-case strings (e.g. `frac-easy-1`, `linear-equations`)
- **JSON keys**: camelCase
- **Difficulty strings**: lowercase in JSON (`"easy"`, `"medium"`, `"hard"`)
- **Persistence keys**: `snake_case_v1` (versioned in `shared_preferences`)

### Persistence Keys (`shared_preferences`)

| Key | Content |
|---|---|
| `exercise_progress_v1` | Exercise status (`none`/`mastered`/`needsReview`) (JSON list) |
| `lessons_completed_v1` | Completed lesson IDs (StringList) |
| `lessons_in_progress_v1` | Last opened lesson: `levelId` + `lessonId` + `step` (JSON) |
| `user_profile_v1` | Sessione: il profilo mostrato a schermo (JSON) |
| `accounts_v1` | Account del dispositivo: profilo + hash e sale (JSON list) |
| `feedback_v1` | Messaggi di feedback lasciati dall'utente, solo su questo dispositivo (JSON list) |
| `settings_v1` | `hapticsEnabled` + onboarding flag (JSON); un `themeMode` dei salvataggi di prima si ignora |
| `study_stats_v1` | Streak, daily counters, study minutes (JSON) |

Version the key when the schema changes (e.g. `settings_v2`), keep a migration path in the store's `load()`.

### UI & Interaction Conventions

- **Body padding**: `EdgeInsets.fromLTRB(20, 8, 20, 24)`
- **Haptic feedback**: always through `AppHaptics` (see «Impostazioni, temi e testo» above)
  - Correct answer → `HapticFeedback.lightImpact()`
  - Wrong answer → `HapticFeedback.heavyImpact()`
  - Lesson complete → `HapticFeedback.mediumImpact()`
  - Exercise status change → `HapticFeedback.selectionClick()`
- **Feedback UI**: shake on wrong answer (`ShakeWidget`, `lib/widgets/shake.dart`: 4 damped swings of 10 px in `AppMotion.slow`; a new key per attempt replays it), pop on the right one (see «Feedback delle risposte»); end-of-lesson celebration: `Positioned.fill` overlay with the Lottie trophy `assets/animations/Trophy.json` at 240px (`repeat: false`), «Lezione completata!» and «Tocca per continuare». A tap anywhere closes it and pops; without a tap a 2400ms `Timer` pops on its own. The `pop` does not start on «Completa la lezione» any more.
- **Animations**: `AnimatedContainer`, `AnimatedSwitcher`, `TweenAnimationBuilder`, or custom `AnimationController`.
- **String-based icons**: JSON stores icon name strings; map them via a private `_iconFor()` method in the widget.

---

## 6. Testing & Quality Assurance Conventions

- **No CI/CD configured**: always run `flutter analyze` and `flutter test` locally before concluding any task.
- **Framework**: `flutter_test` (no third-party test libs).
- **Test isolation**: every store/repository exposes `@visibleForTesting Future<void> resetForTest()` (clears state + `load()`). In `testWidgets` never `await` store resets/asset loads on the fake-async zone — put them in `setUp` (runs in the real zone); `rootBundle` re-loads hang if awaited inside the test body.
- **Mock persistence**: `SharedPreferences.setMockInitialValues({})` in `setUp()`.
- **Async settling**: `await tester.pump(Duration(seconds: 3))` then `await tester.pumpAndSettle()`.
- **Scrollable lists**: `await tester.dragUntilVisible(...)`; use a local helper like `tapVisible()` for reliable taps.
- **Global singletons**: tests use singletons directly (no DI).
- **Test descriptions in Italian**, matching app language.

---

## 7. GitHub & Commits

- Conventional commit prefixes: `feat:`, `fix:`, `test:`, `docs:`, `chore:`
- Messages in Italian or mixed Italian/English.
- Single branch: `main`.
- Update `PROGRESS.md` (the project changelog/roadmap) when adding features. Test counts live there and nowhere else.
- **Update `DESIGN.md` with every change to how the app looks or moves** (colors, type, shapes, components, illustrations, motion): fix the section it touches and add a dated line at the top of its «Storico». A new token, component or animation is not done until `DESIGN.md` describes it.
- Note: Only the **web** build is confirmed working (`flutter build web`); do not attempt Linux desktop builds.
- Note: `utils/latex.dart` was removed — always use `MathText`.