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

- **Framework**: Flutter 3.47.2 (stable)
- **Dart SDK**: 3.13.2
- **LaTeX rendering**: `flutter_math_fork` ^0.7.4 (KaTeX pure Dart, offline, no WebView)
- **Persistence**: `shared_preferences` ^2.5.5
- **Animazioni Lottie**: `lottie` ^3.6.1 legge **solo JSON**: i file `.lottie` (dotLottie, zip con state machine) non sono supportati, né le state machine o le interazioni interne. I segmenti di una timeline si guidano con i **marker** (`composition.getMarker(nome)` dà `start`/`end` normalizzati 0..1) pilotando un `AnimationController` con `repeat(min:, max:, count:)` e `animateTo`; `LottieBuilder.controller` è un `Animation<double>`, non esiste `LottieController`.
- **Inline LaTeX in content**: `$$...$$` block delimiters
- **Riquadri multifunzione in content**: fenced syntax `::box` ... `::endbox` wrapping a `MultifunctionBox` JSON node (`box_type`: `image` | `chart` | `interactive_chart` | `math_formula`). Invalid JSON falls back to plain text. Charts render via CustomPainter, interactive charts evaluate `expression` strings over `x`/`t` with `ExpressionEvaluator`. In `math_formula` payload, `"hidden": true` sopprime card di contorno (`AppCard`) e titolo, la formula resta visibile come blocco a sé; `title` vuoto = niente header e padding card ridotto.
- **Step lezione `type`**: `info` | `mcq` | `practice_quiz` (`LessonStepType`). Ogni step è una card a sé nel `PageView` di `LessonScreen`, non un riquadro annidato.
- **Footer delle card di lezione**: fascia alta `_kFooterControlHeight` (49, l'altezza di «Completa la lezione») presente su **ogni** step. Contiene il reload (solo card di verifica) e «Completa la lezione» (solo ultimo step, a destra, più compatto che in passato: niente più piena larghezza). Lo swipe verso sinistra sull'ultima card completa la lezione anche senza bottone: lo coglie un `Listener` attorno al `PageView` (un `GestureDetector` esterno perderebbe l'arena col drag della `PageView`), conta solo mosse più orizzontali che verticali, tira la card a sinistra fino a `_kSwipeCompleteThreshold` (56) e a quel punto chiama `_complete`. La condizione è `_canCompleteAt(index)`, la stessa che mostra il bottone, quindi l'esercizio non si bypassa. La `M3EToolbar` è un `Positioned(left: 0, bottom: 0, width: M3EToolbarTokens.fabMedium)` dentro la card, scalata di `_kFooterControlHeight / M3EToolbarTokens.fabMedium` con `Alignment.bottomLeft`, così il FAB compatto è a filo della colonna di testo e ha lo stesso spigolo inferiore del bottone, e cresce in alto. Non sta nella `Row` del footer perché `M3EToolbar` riserva in layout l'altezza della pila (136px) anche da collassata, pur clip-paintandola a zero. C'è una toolbar per card costruita dal `PageView`: lo stato di espansione vive in `_LessonScreenState` (`expanded` + `onExpandedChanged`) per non COLLASSARE a ogni swipe. Il tap sull'icona del FAB, non sul `getCenter` del pacchetto.
- **Step `practice_quiz`**: card di verifica con `title` e `exercises[]` (`prompt`, `text?`, `options[]`, `correctIndex`, `explanation?`); `content` non viene renderizzato. Mostra **un solo esercizio per volta** (`PracticeQuizView`, stato pubblico `PracticeQuizViewState.reload()`). Il bottone `Icons.refresh_rounded` sta nel footer della card, a sinistra di «Completa la lezione», ed estrae il successivo da una coda mescolata senza ripetizioni; sparisce se c'è un solo esercizio. Il prompt passa da `PromptView`, che auto-rileva: percorso/URL immagine (estensione immagine o prefisso `http`) → `ImageSource`, altrimenti `MathText` (quindi anche matematica mista a testo). Opzioni, feedback e shake sono condivisi con gli step MCQ via `McqOptionTile` / `McqFeedbackCard`.
- **Lesson `content`**: può essere stringa markdown oppure **array di segmenti** (righe di testo come stringhe, riquadri come oggetti). `LessonStep.fromJson` appiattisce entrambi in una stringa con sintassi `::box`/`::endbox`; preferisci l'array nei JSON per leggibilità.
- **Step `mcq`**: `prompt` (la traccia, resa da `PromptView`), `options[]`, `correctIndex`, `explanation?`; risolvendolo compare «Completa la lezione».
- **Toggle del tema**: nel card «Tema scuro» di `ProfileScreen` (ospite e loggato) il controllo è l'animazione sole/luna `assets/animations/toggle.json`, non uno `Switch`. Toccarla cambia tema e guida la transizione sui marker `Day to Night` / `Night to Day` (1.0s e 1.33s, durata calcolata dalla composizione), poi si ferma sul segmento idle del nuovo tema. Finché la composizione non è caricata resta lo `Switch` di fallback, così la card non ha buchi.
- **UI style**: Material 3, iOS-native-inspired minimal design
- **Architectural Constraints**: No network calls, no code generation (`build_runner`, `freezed`, or `json_serializable`), no third-party state management (Riverpod/Bloc/Provider).

---

## 3. Essential Commands

| Command | Purpose |
|---|---|
| `flutter run` | Run the app (dev) |
| `flutter analyze` | Static analysis — **must stay at 0 issues** |
| `flutter test` | Run all unit + widget tests (228 tests / 23 files) |
| `flutter test --coverage` | Generate coverage report |
| `dart format .` | Format code |
| `flutter pub get` | Install dependencies |
| `flutter build web` | Build for web (only platform confirmed working) |

---

## 4. Architecture & Key Patterns

```
lib/
  main.dart               # entry: loads content + progress + profile + search index
  app.dart                # MathApp (MaterialApp + theme)
  theme/                  # app_theme.dart, app_colors.dart
  models/                 # plain Dart data classes (level, course, section, topic,
                          # exercise, difficulty, progress, lesson, lesson_step,
                          # argomento, user_profile, weak_topic, multifunction_box/)
  data/                   # singletons (instance pattern): content_repository,
                          # lesson_repository, progress_store, auth_store,
                          # settings_store, study_store, search_index.
                          # Not singletons (pure logic): recommendation_engine,
                          # weak_topic_engine
  screens/                # full-page widgets
  widgets/                # reusable UI components
assets/data/              # levels.json, middle_school.json, high_school.json,
                          # university.json, lessons/
                          # (lessons/index.json lists argomento files to load)
```

- **State management**: raw `ChangeNotifier` + `ListenableBuilder`. No third-party packages.
- **Singletons**: repositories/stores use `static final instance = ClassName._()` with a private constructor. Access via `XStore.instance`. Exception: pure-logic engines (`recommendation_engine`, `weak_topic_engine`) use no `instance`.
- **Serialization**: hand-written `fromJson` factories.
- **Widgets depending on stores**: always wrap in `ListenableBuilder(listenable: XStore.instance, builder: ...)`.
- **Screens**: use `const` constructors; extend `StatefulWidget` or `StatelessWidget`.
- **Colors**: never hardcode color constants — use `final c = AppColors.of(context)` (ThemeExtension palette supporting light/dark).
- **Cards**: use the shared `AppCard` widget (borderRadius 18, consistent surface color + shadow).
- **Navigation**: imperative Navigator 1.0 — `Navigator.of(context).push(MaterialPageRoute(...))`, `pushReplacement`, `pop()`. No named routes, no GoRouter.
  - Reset the stack before pushing main screens: `popUntil((route) => route.isFirst)`.
  - Splash → home/onboarding transition uses `pushReplacement` with a fade `PageRouteBuilder`.
- **PillNavBar**: `PillTab` = `home` | `lessons` | `exercises` (3 voci), visible only on the 3 main screens (Home, Lezioni, Esercizi). It routes to the user's school level if logged in with a profile, otherwise shows the school-choice bottom sheet. `ProfileScreen` is a pushed sub-page: no pill, back button in its AppBar.
- **Header delle pagine principali**: `ProfileButton` (`lib/widgets/profile_button.dart`) in `AppBar.actions` of Home/Lezioni/Esercizi — avatar with photo or initials if logged in, `RegistrationScreen` if guest. Home keeps `HomeGreeting` as title (left, `titleSpacing: 20`); Lezioni/Esercizi put a `Row` in `AppBar.title` a `HeaderTextBar` (`lib/widgets/header_text_bar.dart`) in `Expanded` plus `ProfileButton`, separated by 6px, with `toolbarHeight: kHeaderToolbarHeight` (80) and `titleSpacing: kHeaderHorizontalMargin` (12) — with an empty `actions` the `AppBar` uses `titleSpacing` as right margin too, so one constant governs both sides and the field takes the difference: the field is a 56px `TextField` (search icon, radius 28) that accepts text and does nothing, the avatar is `kProfileAvatarSize` (56). Field and icon live in `title` and not in `actions` on purpose: `AppBar` puts 16px between the title and the actions, and 8px reads much closer. Home has no field, so its icon stays in `actions` and it only borrows `toolbarHeight` to fit the 56px avatar. `YearTabs` stays alone in `AppBar.bottom` (88).

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
| `user_profile_v1` | User profile (JSON) |
| `settings_v1` | `themeMode` + onboarding flag (JSON) |
| `study_stats_v1` | Streak, daily counters, study minutes (JSON) |

Version the key when the schema changes (e.g. `settings_v2`), keep a migration path in the store's `load()`.

### UI & Interaction Conventions
- **Body padding**: `EdgeInsets.fromLTRB(20, 8, 20, 24)`
- **Haptic feedback**:
  - Correct answer → `HapticFeedback.lightImpact()`
  - Wrong answer → `HapticFeedback.heavyImpact()`
  - Lesson complete → `HapticFeedback.mediumImpact()`
  - Exercise status change → `HapticFeedback.selectionClick()`
- **Feedback UI**: shake animation on wrong answer, celebrazione a schermo intero al termine della lezione: overlay `Positioned.fill` con il trofeo Lottie `assets/animations/Trophy.json` a 240px (`repeat: false`), il titolo «Lezione completata!» e la scritta «Tocca per continuare». Il tap ovunque chiude l'overlay e fa pop; se non si tocca, un `Timer` di 2400ms (i 71 frame a 30fps durano 2.37s) fa pop da solo. Il `pop` non parte più al tap su «Completa la lezione».
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
- Update `PROGRESS.md` (the project changelog/roadmap) when adding features.
- Note: Only the **web** build is confirmed working (`flutter build web`); do not attempt Linux desktop builds.
- Note: `utils/latex.dart` was removed — always use `MathText`.