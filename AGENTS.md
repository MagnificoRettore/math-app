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
- **UI style**: Material 3, iOS-native-inspired minimal design
- **Architectural Constraints**: no network calls, no code generation (`build_runner`, `freezed`, `json_serializable`), no third-party state management (Riverpod/Bloc/Provider)
- **LaTeX**: `flutter_math_fork` ^0.7.4 (KaTeX pure Dart, offline, no WebView) · inline nei content con `$$...$$`
- **Persistence**: `shared_preferences` ^2.5.5
- **Hash password**: `crypto` ^3.0.7 → PBKDF2-HMAC-SHA256 in Dart puro, nessuna rete
- **Material 3 Expressive**: `material_3_expressive` ^1.1.2 → `M3EToolbar`, `M3EToolbarTokens`, `M3EIcons`
- **Icone**: `material_symbols_icons` ^4.2960.0
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
                 # pure logic no instance: recommendation_engine, weak_topic_engine,
                 # lesson_resume_engine
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
- **Cards**: il widget condiviso `AppCard` (`kCardRadius` 24, surface + ombra soffice a due strati, `glow` opzionale per l'alone nell'angolo).
- **Navigation**: Navigator 1.0 imperativo — `push(MaterialPageRoute(...))`, `pushReplacement`, `pop()`. Niente named routes, niente GoRouter. `popUntil((route) => route.isFirst)` prima di spingere le pagine main; splash → home con `pushReplacement` e `PageRouteBuilder` in dissolvenza.

### Contenuto e formattazione

- **Riquadri multifunzione**: fenced `::box` ... `::endbox` attorno a un nodo JSON `MultifunctionBox` (`box_type`: `image` | `math_formula` | `chart`); JSON invalido ricade su testo semplice.
  - Sono tre tipi e sono quelli che i contenuti usano. `interactive_chart` ci è stato (`interactive_chart_view.dart`) ed è sparito con `chart`: i tipi si aggiungono quando un argomento li vuole, non prima. `align` e `caption` dell'immagine e il modo `inline` della formula sono andati per la stessa strada.
  - `math_formula`: `"hidden": true` sopprime l'`AppCard` che avvolge e il titolo, la formula sta da sola; `title` vuoto = niente header e padding ridotto. `fontSizeMultiplier` scala il corpo della formula.
  - `image`: **nessuna card** — niente `AppCard` (bordo/ombra), niente `ClipRRect`, niente piastra `accentSoft`. L'immagine sta centrata nella colonna di testo col titolo in piano (15 w700).
  - `chart`: dentro l'`AppCard` col titolo in `titleSmall` w700, e dentro `ChartView`. I tre tipi sono `function` (una curva per espressione), `line` (punti espliciti) e `bar` (un valore per voce di `xLabels`).
    - **Nessuna interazione**: niente tap, tooltip, zoom, legenda cliccabile. L'unico movimento è l'entrata, 400ms (`ChartView._duration`), che traccia il path con `PathMetric.extractPath` e le barre crescendo in altezza. Una volta sola, al mount: rifarla a ogni scroll sarebbe mossa.
    - **I buchi sono assenze, non zeri**: `sampledSegments` (`lib/widgets/chart/chart_scale.dart`) spezza il path dove `ExpressionEvaluator` non dà un valore, quindi `sqrt(x-2)` non stampa una retta verticale dove la funzione non c'è. `null` e i non finiti (NaN) si trattano allo stesso modo: il NaN di `sqrt` passerebbe il confronto coi limiti.
    - Il file `chart_scale.dart` è **logica pura senza `package:flutter`** (numeri, tick, geometria): i painter disegnano e i suoi test girano senza widget. Il dominio y esce da `niceRange`, con passo 1/2/2.5/5 e, se i dati sono tutti non negativi, il basso a zero.
    - I colori degli assi e della griglia vengono da `ChartPalette` (`lib/theme/chart_palette.dart`), una `ThemeExtension` registrata in `AppTheme`: sono una cosa sola dei grafici, quindi non entrano in `AppPalette`. I tracciati usano `color` della serie (`accent`, `indigo`, …) con `iconPalette` come riserva.
    - `shouldRepaint` confronta i colori con `listEquals` e lo stile per valore: senza, ogni build ridisegnerebbe il grafico identico.
- **`ImageSource`**, due modi:
  - default: banda 200px, `BoxFit.cover`, piena larghezza, per le tracce esercizio di `PromptView`.
  - `naturalSize: true`: dimensione naturale, `BoxFit.contain`, altezza limitata a 240px (`ImageSource.maxHeight`), così i grafici non vengono ritagliati.
    - Lì il placeholder dell'asset mancante è fisso 240x180: `width: double.infinity` dentro un `Align` è un'eccezione.
    - Layout `Center` + `ConstrainedBox` e non una width in percentuale: `RenderImage._sizeForConstraints` preserva il rapporto d'aspetto appena il genitore allenta i vincoli.
- **`ExpressionEvaluator` (`lib/widgets/expression_evaluator.dart`) è il motore della calcolatrice scientifica** (`scientific_calculator.dart`) **e del box `chart`**, che gli passa le curve da campionare: `sampledSegments` chiama `tryEvaluate` con `x` e considera assente ciò che non torna. I suoi 40 test sono quelli della sola calcolatrice e restano tali.
- **Lesson `content`**: stringa markdown **o** array di segmenti (righe di testo come stringhe, box come oggetti); `LessonStep.fromJson` appiattisce entrambi in una stringa `::box`/`::endbox`. Nei JSON preferisci l'array.
- **Step `type`**: `info` | `mcq` | `practice_quiz` (`LessonStepType`). Ogni step è una card a sé nel `PageView` di `LessonScreen`, mai un box annidato.
- **`PromptView`** auto-rileva il prompt: `assets/` iniziali o `http(s)` (`PromptView.isImageSource`) → `ImageSource`, tutto il resto → `MathText` (quindi matematica mista a testo funziona). Il ramo immagine wrappa in `ClipRRect(14)`: è esattamente perché il box `image` non deve.
- **Step `mcq`**: `prompt` (reso da `PromptView`), `options[]`, `correctIndex`, `explanation?`; risolvendolo compare «Completa la lezione».
- **Step `practice_quiz`**: card di verifica con `title` ed `exercises[]` (`prompt`, `text?`, `options[]`, `correctIndex`, `explanation?`); `content` non renderizzato, **un esercizio per volta** (`PracticeQuizView`, stato pubblico `PracticeQuizViewState.reload()`).
  - `Icons.refresh_rounded` nel footer della card, a sinistra di «Completa la lezione»: estrae il successivo da una coda mescolata senza ripetizioni e sparisce se c'è un solo esercizio.
  - Opzioni, feedback e shake condivisi con MCQ via `McqOptionTile` / `McqFeedbackCard`.

### Card di lezione, footer e toolbar

- Ogni step ha la fascia `_kFooterControlHeight` (49, l'altezza di «Completa la lezione»): reload (solo card di verifica) e «Completa la lezione» (solo ultimo step, a destra, non più a piena larghezza).
- **Lo swipe verso sinistra sull'ultima card completa la lezione** anche senza bottone.
  - Un `Listener` attorno al `PageView`, non un `GestureDetector` esterno: perderebbe l'arena col drag della `PageView`. Conta solo mosse più orizzontali che verticali e tira la card fino a `_kSwipeCompleteThreshold` (56), poi chiama `_complete`.
  - La condizione è `_canCompleteAt(index)`, la stessa che mostra il bottone, quindi l'esercizio non si bypassa.
- `M3EToolbar` è un `Positioned(left: 0, bottom: 0, width: M3EToolbarTokens.fabMedium)` dentro la card, scalata di `_kFooterControlHeight / M3EToolbarTokens.fabMedium` con `Alignment.bottomLeft`: il FAB compatto è a filo della colonna di testo, ha lo spigolo inferiore del bottone e cresce in alto.
  - **Non** sta nella `Row` del footer: il pacchetto riserva l'altezza della pila (136px, di cui 80 il FAB) in layout anche da collassata, e con la larghezza illimitata di una `Row` il suo layout verticale va in `Infinity` — da qui il `width` nella `Positioned`.
  - Una toolbar per card, costruita dal `PageView`: lo stato di espansione vive in `_LessonScreenState` (`expanded` + `onExpandedChanged`), altrimenti ogni swipe la richiuderebbe.
  - Il tap è sull'icona del FAB, non sul `getCenter` del pacchetto.

### Home, ripresa e avanzamento

- **«Jump Back In»** (`JumpBackInSection`) è la prima sezione di `HomeScreen`, prima di `ImageCarousel`: esiste solo per utente registrato con `schoolLevelId` non vuota e solo se `ProgressStore.lessonResume` punta a qualcosa, mai un argomento a random. Il tap apre `LessonScreen(initialStep: ...)`, e anche il `FilledButton` «Riprendi» in fondo alla card.
  - Il `SizedBox(height: 24)` sotto la card sta **dentro** la sezione e non nella lista di `HomeScreen`: se la sezione manca, nella lista resterebbe un buco.
  - Card: badge «In corso»/«Da iniziare» (legge `LessonTarget.isPaused`, che senza questo non aveva lettori), topic (`argomento.title`) come titolo grande, lezione come sottotitolo, `ProgressBar(height: 10)` con il conteggio **in card**. Nessun numero di tipo «N di M» sulla lezione: era già stato tolto di proposito e riassomigliava al contatore del `LessonScreen`.
  - **`glow` di `AppCard`**: il gradiente sta dentro la sfera e il blur serve solo a farla uscire dai bordi. Su un `Container` di colore pieno `ImageFilter.blur` non sfuma niente, perché sposta pixel tutti uguali.
- **`LessonResumeEngine`** è logica pura (niente `instance`):
  - `target()` sceglie la lezione: quella lasciata aperta all'ultimo passo clampato, altrimenti la non completata più vicina, cercando prima nel suo argomento e poi nei successivi dello stesso anno; anno finito ⇒ `null`. Se la lezione in pausa è stata completata altrove la salta e la ricerca torna anche indietro nell'argomento. Il resume vale solo per il `levelId` dell'utente.
  - `topicProgress(target)` è **posizionale, non di merito**: card superate della lezione corrente (`target.step`, la card aperta non conta) più tutte le card delle lezioni precedenti nell'argomento, **anche se non sono mai state aperte**; denominatore tutte le card dell'argomento, comprese quelle dopo. La barra dice dove si è, non cosa si è fatto. `topicCards(target)` restituisce la stessa coppia di numeri per il testo «N di M card»: non un numero di esercizi, perché l'app traccia le card e non gli esercizi.
- **Ripresa lezione**: `LessonScreen(initialStep: 0)` riparte da uno step preciso e **non** ripristina risposte già date (`_solved`, `_selectedOption`, `_wrongOptions` restano puliti).
  - Salva il punto in `initState` e a ogni `onPageChanged`, quindi sopravvive all'app uccisa; `_complete()` chiama `clearLessonResume()`, altrimenti la sezione riproporrebbe la lezione appena finita.
  - La prima scrittura è differita con `addPostFrameCallback`: dalla `initState` la notifica arriverebbe durante la build della nuova rotta.

### Accesso, profilo e avatar

- **Sessione e account sono due cose diverse.** `user_profile_v1` è la **sessione** (il profilo mostrato a schermo), `accounts_v1` è l'elenco degli account del dispositivo (`LocalAccount` = profilo + hash + sale). `signOut()` cancella la sessione e **tiene** l'account, altrimenti non si potrebbe rientrare.
- **Non c'è server, e va detto.** Un account esiste solo su questo dispositivo e «unico» significa unico qui; la validazione «lato server» è `AuthStore`, che risponde `AuthException` con il messaggio da mostrare. `PasswordHasher` (PBKDF2-HMAC-SHA256, 10 000 iterazioni, sale `Random.secure()`) evita la password in chiaro, ma `shared_preferences` su web è `localStorage`: **non è una barriera di sicurezza** e non va raccontata come tale. Per la protezione vera serve un backend, che fuori dallo scope di questo progetto.
- `AuthStore.signIn` accetta **ID account o email** (stesso campo del login) e risponde `SignInResult`: `wrongPassword` e `unknownAccount` stanno separati perché il login deve poter rispondere «password sbagliata» a chi l'ha sbagliata. Un account Google e un profilo anteriore alle password non hanno hash: `googleOnly` e `noPassword` dicono perché non si riaprono col login.
- **`accountId` è derivato dall'email** (`AuthValidators.accountIdFromEmail`) quando non lo sceglie l'utente, quindi i chiamanti che non lo passano non cambiano. Se è già preso prende un suffisso (`anna`, `anna2`).
- Un profilo salvato **prima** di `accounts_v1` diventa account senza credenziale al primo `load()` (`_needsLegacyAccount`): nessuna perdita di sessione, ma da quel profilo non si rientra col login.
- **Le regole dei campi stanno in `AuthValidators`**, logica pura con `taken` ricevuto da fuori: l'unicità è uno stato dello store, non un fatto del validatore. Il `Form` gira in `AutovalidateMode.onUserInteraction`, così «ID account già in uso» e «le password non coincidono» si vedono mentre si scrive.
- **Google è una demo, non un OAuth**: `signInWithGoogleDemo` apre il dialog dimostrativo di `lib/widgets/google_button.dart` e crea l'account in locale. Lo stesso widget `GoogleButton` sta su welcome, login e registrazione, e le iniziali stanno in un posto solo (`initialsOf` in `profile_avatar.dart`).
- **Avatar a scelta, non upload**: l'app non ha rete e `shared_preferences` non è un archivio di immagini, quindi `avatarId` è il **nome** di uno dei simboli in `avatarOptions` (`material_symbols_icons`), non il `IconData` né un URL. Vuoto = iniziali, ed è quello che fa «Rimuovi foto». `ProfileAvatar` disegna foto, simbolo o iniziali ed è l'unico posto che lo fa: header e profilo devono cadere sulla stessa identità.
- **`SchoolPickerScreen` non riceve callback, riceve `onboarding`.** Le schermate che aprono la scelta della scuola la `pushReplacement` (la registrazione, il login con Google), quindi sono già smontate quando l'utente preme «Crea il mio profilo»: un `onSaved: () => ...` che chiude il `context` del chiamante naviga da un elemento *defunct* e il tap non fa nulla. In debug «Looking up a deactivated widget's ancestor is unsafe», in release la catena `_parent` è già `null` e va in null-check: stesso sintomo, due cause diverse. Il flag dice solo *cosa* fare (`onboarding: true` → `popUntil((route) => route.isFirst)`, cioè la home che è la radice dello stack; `false` → `pop()` e si torna al profilo), e la navigazione esce dal **proprio** context del picker.
- **«Password dimenticata?» non può funzionare**: non c'è email né server, quindi il link apre un dialog che lo dice. Meglio che un form che non manda niente.
- **L'accesso è il punto d'ingresso dell'ospite**: l'icona del profilo in header, da ospite, spinge `LoginScreen`, e da lì il link «Registrati» apre `RegistrationScreen`. La registrazione non ha un'icona propria. `WelcomeScreen` resta il punto d'ingresso della card ospite in Home, e `ProfileScreen` da ospite mostra «Accedi» e «Registrati»: chi è dentro l'app vede le schermate dell'account, chi è in strada sceglie prima tra registrazione e accesso. Con la sessione aperta l'avatar apre `ProfileScreen`.

### Impostazioni, temi e testo

- **Personalizzazione**: `CustomizationScreen` (`lib/screens/customization_screen.dart`) aperta da `HeaderCustomizationButton` (`lib/widgets/main_header.dart`, `Icons.tune_rounded`, `Key('header-customization')`) nelle `AppBar.actions` **delle tre pagine main**, **sia per l'ospite sia per l'utente registrato**, perché sono impostazioni dell'app e non del profilo: nel profilo non c'è. Le tre pagine hanno lo stesso header, quindi il bottone è lo stesso widget e non una copia: la chiave è `header-customization` e non `home-customization` perché non sta solo in Home.
  - Due gruppi: «Aspetto» (toggle del tema) e «Risposta» (interruttore vibrazioni). Le scelte stanno in `SettingsStore`, la pagina è un `ListenableBuilder` su di esso.
  - **Un widget `const` nella lista di un `ListenableBuilder` non si ricostruisce**: il padre che si ricostruisce gli passa la stessa istanza canonicizzata e `Element.updateChild` la salta. Vale per `ThemeToggle` e per l'interruttore delle vibrazioni, che per questo si ascoltano **da sé**: senza, l'interruttore girava solo dopo il cambio tema, perché la sua era l'unica ricostruzione che passava da quella parte della pagina.
- **Il primary è dichiarato, non derivato**: `ColorScheme.fromSeed` prende dal seme la **tonalità 40**, quindi dall'indaco di marca esce un grigio-viola e il primary non sarebbe quello. `AppTheme` dichiara a mano `primary`, `onPrimary`, `primaryContainer`, `onPrimaryContainer`, `tertiary` e `tertiaryContainer`, e dal seme tiene il resto della scala. In scuro `onPrimary` è `accentSoft`: il primary scuro è chiaro, il testo sul bottone pieno deve essere scuro o «Riprendi» non si legge (test sul contrasto 4.5:1 in `home_widget_test.dart`).
- **`AppPalette.danger`** (`0xFF8B1B34`) è il terziario: il colore delle sezioni «da ripassare». Non viene dal seme e non si aggiunge a mano in nessun widget: si usa il campo, o `ColorScheme.tertiary` se serve il ruolo M3.
- **Toggle del tema**: nella card «Tema scuro» (`ThemeToggle`, `lib/widgets/theme_toggle.dart`) il controllo è l'animazione sole/luna `assets/animations/toggle.json`, non uno `Switch`.
  - Il tap guida la transizione sui marker `Day to Night` / `Night to Day`, poi si ferma sull'idle del tema nuovo. Durata fissa `ThemeToggle._transition`, 320ms, in override dei marker (1.0s e 1.33s); finché la composizione non è caricata resta lo `Switch` di fallback.
  - **L'animazione parte prima del tema**: il tap avvia il tratto sole/luna e il cambio tema arriva 40ms dopo (`ThemeToggle._themeChangeDelay`), così l'icona è già in viaggio quando i colori cominciano a interpolare. Il timer non va cancellato in `dispose`: scrive sullo store e non tocca il widget, quindi un cambio richiesto e poi schermata chiusa deve comunque valere.
  - **La curva sta nel tratto, non nel tempo della composizione.** `animateTo` è lineare (`AnimationController`) e la fine del tratto si leggeva come un colpo di freno. La curva si applica con `_drive`, un controller 0..1 a parte che pilota lo span del marker: `Lottie.controller` riceve il `Tween(begin: valoreCorrente, end: fineMarker).animate(CurvedAnimation(parent: _drive, curve: easeOutCubic))`. Un `CurvedAnimation` sul `_controller` degli idle sbaglierebbe i frame fermo (`easeOutCubic(0.19)` non è il frame 0.19) e farebbe finire il tratto su 0.78 invece che sul marker, con la luna a metà.
  - Due controller ⇒ `TickerProviderStateMixin`, non `SingleTickerProviderStateMixin`.
  - `RepaintBoundary` intorno agli 88x48 del Lottie: la composizione ha 11 layer (4 maschere, blur) e senza confine fa rasterizzare sé e la pagina insieme mentre lo schermo si ricolora.
- **Transizione fra temi**: `MaterialApp` riceve `themeAnimationStyle: AppTheme.transitionStyle` (200ms, `Curves.easeOutCubic`) perché il default di Flutter sono 200ms **lineari**, che si leggono come un lampo; `AppPalette.lerp` estende l'animazione ai 20 colori custom.
  - **I colori finiscono 80ms prima dell'icona**, non insieme: 40ms di ritardo più 200ms fanno 240ms, contro i 320ms dell'icona. Due viaggi che si arrestano nello stesso istante si leggono come un unico scatto, ed è il difetto segnalato. Il test «i colori finiscono prima dell'icona» fissa l'invariante, non i numeri: a 200ms di animazione lo sfondo è già quello definitivo e l'icona è ancora in viaggio.
  - `easeOutCubic` e non `easeInOutCubicEmphasized`: quest'ultimo ha una coda lunghissima, e negli ultimi frame i colori quasi non si muovevano mentre l'icona era già ferma, il che si leggeva come un colore bloccato.
  - Il costo per frame **non è il rebuild**: una sonda temporanea ha contato 17 ricostruzioni su 250ms (una per frame, come previsto da `AnimatedTheme`) ma ~2.6ms per frame con 300 widget che leggono i colori, sotto budget. Il costo vero è di rasterizzazione e non si misura in test headless.
  - Nei test `MaterialApp` avvolge l'albero in `AnimatedTheme` **anche senza** `themeAnimationStyle`, quindi appena cambiata la `ThemeData` i colori sono ancora i precedenti: serve `pumpAndSettle` per leggerli.
- **I caratteri vengono da `AppText`** (`lib/theme/app_text.dart`), mai da un letterale: `display` 26, `hero` 23, `headline` 21, `title` 19, `titleLarge` 18, `titleMedium` 16, `titleSmall` 15, `bodyLarge` 14, `bodyMedium` 13.5, `bodySmall` 13, `label` 12.5, `labelSmall` 12, `caption` 11.5, `micro` 11.
  - **Il corpo delle lezioni ha i suoi slot**: `docTitle` 24, `docHeading` 19, `docBody` 15, `docMono` 12.5. È un documento, non un'interfaccia: sta dentro la scala della UI ma non è un suo ruolo, e i `fontSizeMultiplier` dei JSON valgono come prima perché cambiano i valori base, non i rapporti.
  - `micro` è il pavimento e non si scende: sotto gli 11 px non c'è leggibilità. L'unica eccezione storica era l'etichetta della pillola a 10, salita a `micro`.
  - `test/app_text_test.dart` fissa l'ordine degli slot e il titolo delle `AppBar` a `headline` in chiaro e in scuro: sono le due invarianti che reggono la gerarchia.
- **`SectionHeader` non ha padding orizzontale**: tutte le pagine che ospitano una testata hanno già i loro 20 px, quindi i 20 della testata sommati mettevano i titoli a 40 mentre le card erano a 20 — disallineati e con 20 px in meno per il testo. C'è un test in `home_widget_test.dart` che confronta il margine sinistro di titolo e card, perché il difetto si vede solo sul telefono.
- **Scala del testo**: non c'è più una scelta dell'utente, quella del **sistema** sì e va rispettata.
  - `RichText` non applica il `textScaler` di `MediaQuery` (default `TextScaler.noScaling`) e dentro `flutter_math_fork` le formule sono `RichText` costruite a mano, quindi il corpo delle lezioni (`MathText`, `NotesText`) resterebbe fermo mentre il resto cresce: `textScaleFactorOf(context)` (`math_text.dart`) legge il fattore e i due widget lo moltiplicano a mano sul loro `fontSize`.
  - `MathApp` **non** tocca il `MediaQuery`: la scala del dispositivo è sua. `mathSpan` resta puro, chi lo chiama ha già scalato.
- **Tastiera**: tap fuori da un campo chiuso e la tastiera scende, **ovunque**. Si fa una volta sola in `MathApp.builder` con `DismissKeyboard` (`lib/widgets/dismiss_keyboard.dart`), che sovrascrive `EditableTextTapOutsideIntent` e `EditableTextTapUpOutsideIntent`: le azioni di `EditableText` sono `Action.overridable`, quindi un `Actions` più in alto vince per tutte le schermate, i dialog e l'overlay.
  - Il default di Flutter (`_EditableTextTapOutsideAction`) unfoca su desktop e sul web ma **non** sui telefoni col dito: da lì il widget.
  - Non basta `unfocus` al tap down, altrimenti scrollare la pagina chiuderebbe la tastiera: si tiene il `PointerDownEvent` e si unfoca al tap up solo se il movimento è sotto `kTouchSlop`, come nell'esempio del framework. Niente `GestureDetector` attorno al corpo di ogni schermata: perderebbe i tap sui widget interattivi che vincono l'arena e non coprirebbe i campi futuri.
- **Vibrazioni**: `HapticFeedback` non ha interruttore globale, quindi ogni chiamata passa da `AppHaptics` (`lib/haptics.dart`), che legge `SettingsStore.hapticsEnabled`. Il tasto che spegne le vibrazioni chiama `HapticFeedback.selectionClick()` diretto: è l'unico modo di sentire che l'opzione è arrivata.

### Sezioni della Home

- **La Home è una pagina sola**: ospite e collegato hanno lo stesso disegno, cambia solo il contenuto. Le uniche differenze accettate sono la card «riprendi» (serve una lezione in pausa) e l'identità in testata (icona e «Ospite» invece di avatar e nome).
- **`MissionHero`** è riusato anche da `MissionScreen`, quindi le quattro scorciatoie (Lezioni, Esercizi, Punti deboli, Profilo) stanno dietro `showShortcuts`, **false di default**: sulla pagina missione sarebbero due righe di menu sopra il testo che descrive il menu. Ci sono **anche da ospite**: il livello si risolve al tap (`BrowseStore.levelId` prima del profilo, come fa la pillola) e se non c'è si chiede quale sia con `showSchoolChoiceSheet`. Per questo `_Shortcut` porta un `onTap` e non una `Widget`: due scorciatoie non possono sapere il livello da una costante.
- **«Per te» / «Per iniziare»**: un solo `RecommendedSection` con `user` **opzionale**. Da ospite (o senza scuola) la sezione non sparisce: cambia titolo in «Per iniziare», il mini-titolo in «Da dove cominciare» e la riga diventa l'invito a creare il profilo. «Esplora» senza livello apre il foglio di scelta della scuola, con scelta non salvata (è una visita).
  - La riga è di **`RecommendationRow`** (`lib/widgets/recommendation_row.dart`): piastra 42, titolo 15 w600, badge opzionale, anteprima su due righe, play 42 opzionale. `ExerciseCard` ci delega passandoci stato e difficoltà. Le due sezioni condividono il widget invece di avere due righe che si somigliano: è l'unico modo perché restino uguali al primo ritocco.
- **`WeakPointsScreen` ha due stati vuoti**: da ospite «Ancora niente da ripassare» con CTA al benvenuto, collegato «Tutto assimilato!». «Tutto assimilato» è un merito, e un ospite non ha ancora studiato niente: dirglielo sarebbe falso.
- **«I tuoi punti deboli»**: le tre righe stanno in **una card sola** con i `Divider` dentro e «Vedi tutti (N)» in fondo, non in una card ciascuna (tre superfici bianche separate sembrerebbero tre cose diverse). `WeakTopicRow` prende `inGroup` per non ripetere bordo, ombra e raggio, e `rank` per il numero in testa; il contatore «N da ripassare» sta nella testata della sezione, in chip `danger`, e non più in ogni riga.

### Navigazione, header e ricerca

- **PillNavBar**: `PillTab` = `home` | `lessons` | `exercises`, visibile solo sulle 3 pagine main. Va al livello dell'utente se c'è un profilo, altrimenti mostra il foglio di scelta della scuola. `ProfileScreen` è una sotto-pagina: niente pillola, back nell'`AppBar`.
- **Header**: scheletro identico sulle 3 pagine main. L'`AppBar` è una **banda di colore di marca** che parte dai due bordi dello schermo e li attraversa tutti, quindi non è una pilla con i bordi curvi dentro una pagina colorata. In alto i due angoli sono **squadrati** (la banda è appoggiata al bordo dello schermo), in basso sono **smussati** a `kHeaderBottomRadius` (28) e il **viola di Material 3** (`colorScheme.primary`, cioè `accent`) esce dagli angoli: a farlo serve `MainHeaderAppBar`, che è uno `Stack` con il viola sotto e l'`AppBar` sopra, perché il taglio lo fa lo `shape` dell'`AppBar` e senza lo strato sotto gli angoli mostrerebbero lo sfondo della pagina e sembrerebbero un buco. `elevation: 0`, altrimenti l'ombra dell'`AppBar` passa sopra al viola, che è l'unico pezzo visibile sotto la banda. Il `title` è `MainHeaderTitle` (`lib/widgets/main_header.dart`, chiave `header-identity`): la sola identità, `ProfileButton` a sinistra e `ProfileSummary` in `Expanded`, che arriva fino alle icone. Nelle `actions` la lente (`HeaderSearchButton`, chiave `header-search`, `Icons.search_rounded`) e la personalizzazione (`HeaderCustomizationButton`, chiave `header-customization`), che è **l'ultima a destra** su tutte e tre: cercare è l'azione più frequente, quindi sta subito a sinistra delle impostazioni.
  - Costanti in `main_header.dart`: `kHeaderHorizontalMargin` (30, `titleSpacing`), `kHeaderToolbarHeight` (80, `toolbarHeight`), `kHeaderActionsPadding` (destra 12), `kHeaderBottomRadius` (28). Non c'è padding della pilla: il blu è l'`AppBar`, quindi l'avatar è di nuovo a filo di `kHeaderHorizontalMargin` e i test lo misurano lì.
  - **`MainHeaderAppBar`** esiste per i 5 `AppBar` delle 3 pagine main perché il viola degli angoli sta **dietro** l'`AppBar`: un `AppBar` da solo non ha come mostrarlo. Le sue `preferredSize` sono `kHeaderToolbarHeight` più l'altezza del `bottom` (`YearTabs`, 88).
  - Il nome trunca quando le icone sono tre e lo spazio è poco: su 360px in visita è il nome a cedere, non le icone a uscire.
- **La banda è un colore di marca, non del tema**: `AppPalette.headerBlue` (`0xFF3F46E8`) e `headerOnBlue` (bianco) sono **gli stessi in chiaro e in scuro**. Dentro, i colori sono `headerOnBlue` e non quelli del tema: il `textSecondary` sul blu non passa 4.5:1, e le icone nelle `actions` pure bianche (in `accent` sul blu non si leggerebbero).
    - Il nome è pieno, la riga sotto all'80% di bianco: al 70% scende a 3.98:1 e non si legge, c'è un test sul contrasto che lo falsifica (`header_band_test.dart`).
    - La banda quindi **non transiziona** nel cambio tema mentre tutto il resto sì: è la conseguenza di un colore fisso, non un difetto di `lerp`.
    - **`YearTabs`** sta sulla banda, quindi anche i suoi colori sono quelli del blu: etichette bianche (piena la scelta, all'80% l'altra) e bordo bianco all'20%. I cerchi restano `accent`/`surface`: sono superfici opache e si leggono anche loro sul blu.
- **`ProfileButton`** (`lib/widgets/profile_button.dart`) è lo slot sinistro della banda: da collegato uno `Stack` con l'avatar da `kProfileAvatarSize` (50) e il badge di modifica da 20 sovrapposto in basso a destra (`right/bottom: -2`, chiave `home-profile-edit-badge`), da ospite l'icona di persona bianca e niente badge.
    - Il badge è l'affordance dell'avatar, non una scorciatoia in più: porta a `ProfileScreen` come l'avatar. Serve un `GestureDetector` suo perché sta **sopra** l'avatar e senza gesto il tap finirebbe a terra; e non `InkWell`, perché lo schermo dell'acqua si disegnerebbe sul `Material` della pagina, fuori dal badge.
    - Lo `Stack` sta in `Clip.none`: il badge deborda di 2px oltre l'avatar.
- **`ProfileSummary`** (`lib/widgets/profile_summary.dart`) è la `Column` al centro della banda, `crossAxisAlignment.start`: nome 18 `w700` (`kSummaryNameFontSize`) e sotto il titolo della scuola 12.5 `w600` all'80% di bianco. Entrambe in ellissi (`maxLines: 1`).
    - Non c'è più il «Ciao,»: la banda è una tessera, non una frase. «Ospite» senza utente, e la riga della scuola sparisce quando la scuola non si sa.
    - La scuola è quella **che si sta guardando**: `BrowseStore.levelId ?? schoolLevelId`, quindi in visita la banda e il bottone dicono la stessa scuola. Da ospite la visita non esiste (`BrowseStore.levelId` è `null` per contratto) e la scuola arriva da `MainHeaderTitle(levelId:)`, che Lezioni ed Esercizi riempiono col livello che stanno mostrando.
- **Altre scuole in visita** (`BrowseStore`, `lib/data/browse_store.dart`): da collegato, Lezioni ed Esercizi hanno `SchoolBrowseButton` (in `main_header.dart`, chiave `header-school-browse`) **a sinistra** della lente. Apre `showSchoolChoiceSheet` con `signedIn: true`, quindi titolo «Altre scuole, lezioni/esercizi» e **niente** footer «questa scelta non ti verrà più richiesta»: da ospite il footer è vero, da collegato no.
  - È una **visita**, non una scelta: il profilo non si tocca, `ProgressStore` è già scoping per livello (`scopedKey`), e niente si persiste, quindi chiude la app e la visita finisce. `levelId` è derivato (`_levelId` confrontato col profilo), non un campo: se l'utente cambia scuola dal profilo e quella capita essere quella in visita, l'id non pilota più le pagine.
  - Mentre si guarda un'altra scuola l'header dice quale (`Icons.visibility_outlined` + il titolo accanto, bianchi come il resto della banda): senza, i progressi mostrati sarebbero quelli di un'altra scuola senza che lo si dica.
    - `SchoolBrowseButton` è un `Flexible` con dentro la sua `Row`: le `actions` dell'`AppBar` sono una `Row` che dà **larghezza illimitata** ai figli, quindi l'unico che può cedere spazio è il bottone che si rende flessibile. Con tre icone più il nome della scuola in visita, su 360px la riga sborda a destra di 14px se il nome non è dentro un `Flexible`.
  - `LessonListScreen` e `CourseScreen` risolvono il livello come `BrowseStore.levelId ?? parametro del costruttore`, quindi **non cambiano firma**. Sul cambio di scuola l'indice dei `YearTabs` torna a 0 e il `PageController` va rifatto: `high-school` ha 5 corsi e `university` 3, l'indice 4 sarebbe fuori range.
  - **La ripresa non si tocca**: `LessonScreen._isOwnLevel` confronta il `levelId` con il profilo, `_rememberResume` ritorna subito se non è il proprio livello e `_complete` chiama `clearLessonResume()` solo sul proprio. Il `completeLesson` invece gira sempre — l'esercizio è stato fatto e la chiave è per livello. `lessons_in_progress_v1` è **uno solo**: scriverlo da una visita farebbe sparire «Jump Back In».
  - `PillNavBar._performNavigation` legge la visita prima del profilo, altrimenti il cambio di sezione ripartirebbe da capo; `ProfileScreen._signOut` fa `BrowseStore.reset()`, altrimenti chi entra dopo si ritrova la scuola del precedente.
  - Sulla Home la banda non ha la scuola da passare (`MainHeaderTitle` senza `levelId`): da ospite senza livello è una riga sola, e va bene così invece di una riga vuota.
    - `YearTabs` da solo in `AppBar.bottom` (88).
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
| `settings_v1` | `themeMode`, `hapticsEnabled` + onboarding flag (JSON) |
| `study_stats_v1` | Streak, daily counters, study minutes (JSON) |

Version the key when the schema changes (e.g. `settings_v2`), keep a migration path in the store's `load()`.

### UI & Interaction Conventions

- **Body padding**: `EdgeInsets.fromLTRB(20, 8, 20, 24)`
- **Haptic feedback**: always through `AppHaptics` (see «Impostazioni, temi e testo» above)
  - Correct answer → `HapticFeedback.lightImpact()`
  - Wrong answer → `HapticFeedback.heavyImpact()`
  - Lesson complete → `HapticFeedback.mediumImpact()`
  - Exercise status change → `HapticFeedback.selectionClick()`
- **Feedback UI**: shake animation on wrong answer; end-of-lesson celebration: `Positioned.fill` overlay with the Lottie trophy `assets/animations/Trophy.json` at 240px (`repeat: false`), «Lezione completata!» and «Tocca per continuare». A tap anywhere closes it and pops; without a tap a 2400ms `Timer` pops on its own. The `pop` does not start on «Completa la lezione» any more.
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
- Note: Only the **web** build is confirmed working (`flutter build web`); do not attempt Linux desktop builds.
- Note: `utils/latex.dart` was removed — always use `MathText`.