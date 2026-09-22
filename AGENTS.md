# AGENTS.md — Math App

## Project Overview

Flutter application for **Italian students** with solved math exercises (Scuola Media, Scuola Superiore, Università) and interactive step-by-step guided lessons. All content is bundled offline as JSON assets; UI text is in **Italian**.

- **Framework**: Flutter 3.47.2 (stable)
- **Dart SDK**: 3.13.2
- **LaTeX rendering**: `flutter_math_fork` ^0.7.4 (KaTeX pure Dart, offline, no WebView)
- **Persistence**: `shared_preferences` ^2.5.5
- **Inline LaTeX in content**: `$$...$$` block delimiters
- **Riquadri multifunzione in content**: fenced syntax `::box` ... `::endbox` wrapping a `MultifunctionBox` JSON node (`box_type`: `image` | `chart` | `interactive_chart` | `math_formula`). Invalid JSON falls back to plain text. Charts render via CustomPainter, interactive charts evaluate `expression` strings over `x`/`t` with `ExpressionEvaluator`. In `math_formula` payload, `"hidden": true` non mostra il blocco; `title` vuoto = niente header e padding card ridotto.
- **Lesson `content`**: può essere stringa markdown oppure **array di segmenti** (righe di testo come stringhe, riquadri come oggetti). `LessonStep.fromJson` appiattisce entrambi in una stringa con sintassi `::box`/`::endbox`; preferisci l'array nei JSON per leggibilità.
- **UI style**: Material 3, iOS-native-inspired minimal design
- **No network calls, no code generation, no third-party state management**

## Essential Commands

| Command | Purpose |
|---|---|
| `flutter run` | Run the app (dev) |
| `flutter analyze` | Static analysis — must stay at **0 issues** |
| `flutter test` | Run all unit + widget tests (68 tests / 11 files) |
| `flutter test --coverage` | Generate coverage report |
| `dart format .` | Format code |
| `flutter pub get` | Install dependencies |
| `flutter build web` | Build for web (only platform confirmed working) |

## Architecture

```
lib/
  main.dart              # entry: loads content + progress + profile + search index
  app.dart               # MathApp (MaterialApp + theme)
  theme/                 # app_theme.dart, app_colors.dart
  models/                # plain Dart data classes (level, course, section, topic,
                         # exercise, difficulty, progress, lesson, lesson_step,
                         # user_profile, weak_topic, multifunction_box/)
  data/                  # repositories + stores (singletons): content_repository,
                         # lesson_repository, progress_store, auth_store,
                         # settings_store, study_store, search_index,
                         # recommendation_engine, weak_topic_engine
  screens/               # full-page widgets (home, course, exercise_feed,
                         # exercise_detail, bookmarks, search_results, splash,
                         # mission, lesson_list, lesson, lesson_topics, lesson_sections,
                         # welcome, registration,
                         # school_picker, profile, onboarding, weak_points,
                         # weak_topic, year_exercises)
  widgets/               # reusable UI components (app_card, math_text, progress_bar,
                         # difficulty_badge, topic_row,
                         # exercise_card, lesson_card, section_header, mission_hero,
                         # recommended_section, pill_nav_bar, school_level_tile,
                         # home_greeting,
                         # school_choice_sheet, streak_card, animated_fraction_pie,
                         # animated_number_line, app_session_observer,
                         # weak_topic_row, weak_topics_section, year_tabs,
                         # multifunction_box_widget, chart_widgets, chart_colors,
                         # interactive_chart_view, expression_evaluator)
assets/data/             # levels.json, middle_school.json, high_school.json,
                         # university.json, lessons.json
```

## Key Patterns

- **State management**: raw `ChangeNotifier` + `ListenableBuilder`. No Riverpod/Bloc/Provider.
- **Singletons**: every repository/store uses `static final instance = ClassName._()` with a private constructor. Access via `XStore.instance`.
- **Test isolation**: every store/repository exposes `@visibleForTesting Future<void> resetForTest()` (clears state + `load()`). In `testWidgets` never `await` store resets/asset loads on the fake-async zone — put them in `setUp` (runs in the real zone); `rootBundle` re-loads hang if awaited inside the test body.
- **Serialization**: hand-written `fromJson` factories. No `build_runner`, `freezed`, or `json_serializable`.
- **Widgets depending on stores**: always wrap in `ListenableBuilder(listenable: XStore.instance, builder: ...)`.
- **Screens**: use `const` constructors; extend `StatefulWidget` or `StatelessWidget`.
- **Colors**: never hardcode color constants — use `final c = AppColors.of(context)` (ThemeExtension palette supporting light/dark).
- **Cards**: use the shared `AppCard` widget (borderRadius 18, consistent surface color + shadow).
- **Navigation**: imperative Navigator 1.0 — `Navigator.of(context).push(MaterialPageRoute(...))`, `pushReplacement`, `pop()`. No named routes, no GoRouter.
  - Reset the stack before pushing main screens: `popUntil((route) => route.isFirst)`.
  - Splash → home/onboarding transition uses `pushReplacement` with a fade `PageRouteBuilder`.
- **PillNavBar**: visible only on the 4 main screens (Home, Lezioni, Esercizi, Profile). It routes to the user's school level if logged in with a profile, otherwise shows the school-choice bottom sheet.

## Naming Conventions

- **Files**: `snake_case.dart` (e.g. `exercise_detail_screen.dart`)
- **Classes**: `PascalCase` (e.g. `ExerciseDetailScreen`)
- **Private classes/members**: `_` prefix (e.g. `_Logo`, `_OptionTile`)
- **Enums**: `PascalCase` names, `camelCase` values (e.g. `Difficulty.easy`, `ExerciseStatus.needsReview`)
- **Enums**: expose a static `fromString(...)` factory and an Italian `label` getter for display text
- **Content IDs**: kebab-case strings (e.g. `frac-easy-1`, `linear-equations`)
- **JSON keys**: camelCase
- **Difficulty strings**: lowercase in JSON (`"easy"`, `"medium"`, `"hard"`)
- **Persistence keys**: `snake_case_v1` (versioned)

## Persistence Keys (`shared_preferences`)

| Key | Content |
|---|---|
| `exercise_progress_v1` | Exercise status (`none`/`mastered`/`needsReview`) + bookmarks (JSON list) |
| `lessons_completed_v1` | Completed lesson IDs (StringList) |
| `user_profile_v1` | User profile (JSON) |
| `settings_v1` | `themeMode` + onboarding flag (JSON) |
| `study_stats_v1` | Streak, daily counters, study minutes (JSON) |

Version the key when the schema changes (e.g. `settings_v2`), keep a migration path in the store's `load()`.

## UI & Interaction Conventions

- **Body padding**: `EdgeInsets.fromLTRB(20, 8, 20, 24)`
- **Haptic feedback**:
  - Correct answer → `HapticFeedback.lightImpact()`
  - Wrong answer → `HapticFeedback.heavyImpact()`
  - Lesson complete → `HapticFeedback.mediumImpact()`
  - Exercise status change → `HapticFeedback.selectionClick()`
- **Feedback UI**: shake animation on wrong answer, confetti celebration on lesson completion.
- **Animations**: `AnimatedContainer`, `AnimatedSwitcher`, `TweenAnimationBuilder`, or custom `AnimationController`.
- **String-based icons**: JSON stores icon name strings; map them via a private `_iconFor()` method in the widget.

## Testing Conventions

- Framework: `flutter_test` (no third-party test libs).
- **Mock persistence**: `SharedPreferences.setMockInitialValues({})` in `setUp()`.
- **Async/asset loading**: `TestWidgetsFlutterBinding.ensureInitialized()` before `await tester.pumpWidget(...)`.
- **Async settling**: `await tester.pump(Duration(seconds: 3))` then `await tester.pumpAndSettle()`.
- **Scrollable lists**: `await tester.dragUntilVisible(...)`; use a local helper like `tapVisible()` (see `lesson_test.dart`) for reliable taps.
- **Global singletons**: tests use singletons directly (no DI).
- **Test descriptions in Italian**, matching app language.

## GitHub & Commits

- Conventional commit prefixes: `feat:`, `fix:`, `test:`, `docs:`, `chore:`
- Messages in Italian or mixed Italian/English.
- Single branch: `main`.

## Notes

- Only the **web** build is confirmed working; Linux desktop requires CMake (not installed).
- `utils/latex.dart` was removed — always use `MathText`.
- `PROGRESS.md` is the project changelog/roadmap — update it when adding features.
- **No CI/CD configured** (no .github/, Docker, Makefile). Don't assume CI runs checks — always run `flutter analyze` + `flutter test` locally before finishing.