# PROGRESS.md

Changelog e roadmap del progetto.

## 2026-09-22 — Riquadri Multifunzione

Nuova feature: `MultifunctionBox` embedded nel content delle lezioni con sintassi recintata `::box` / `::endbox`.

- **Modelli** (`lib/models/multifunction_box/`):
  - `box_type.dart`: enum `BoxType`, `ChartKind`, `FormulaMode` (fromString + label italiano).
  - `box_payload.dart`: library `sealed class BoxPayload` + parti per i 4 payload.
  - `payloads/`: `image`, `chart` (bar/line/pie), `interactive_chart` (slider `t` + espressioni su `x`/`t`), `math_formula`.
  - `multifunction_box.dart`: nodo comune (`id`, `box_type`, `title`, `payload`) con dispatch polimorfo.
  - `fromJson`/`toJson` per tutti; default robusti, box_type sconosciuto → `image`.
- **Widget**:
  - `expression_evaluator.dart`: parser recursive-descent (`+ - * / ^ %`, parentesi, `x`, `t`); errori → `0.0`.
  - `chart_widgets.dart`: `CustomPainter` nativi — `BarChartPainter`, `LineChartPainter`, `PieChartPainter` (griglia, tick, legenda, autoscale nice).
  - `chart_colors.dart`: mappa `colorKey` → palette app, fallback ciclo `iconPalette`.
  - `interactive_chart_view.dart`: slider parametro live, chips legenda toggle serie.
  - `multifunction_box_widget.dart`: card `AppCard` + header titolo + contenuto per box type.
- **Integrazione**: `notes_text.dart` riconosce `::box` multi-linea e single-line, JSON invalido → testo puro.
- **Test**: 65 nuovi (modello 17, evaluator 23, chart 6, interactive 5, box widget 6, notes_text box + fixture 8). Suite completa: 140 verde.
- Zero nuove dipendenze; grafici offline via CustomPainter.

### Fix da review (round 1)

- `interactive_chart_view.dart`: guard su `step <= 0` → niente divisioni (`divisions: null`), slider non va più in errore.
- `chart_widgets.dart`: `PieChartPainter` clampa valori negativi a 0 (niente sweep negativo); legenda solo se serie > 1, con ellipsis; label x bar/line saltate se più di 6 gruppi; unità (`unit`) mostrata sul tick massimo di bar/line.
- `expression_evaluator.dart`: catch ristretto a `FormatException`/`StackOverflowError` (niente più `catch (_)`).
- `notes_text.dart`: finestra di scan `::endbox` limitata a 200 righe.
- `math_text.dart`: `stripMathDelimiters` reso pubblico, duplicato rimosso da `multifunction_box_widget.dart`.
- `multifunction_box_widget.dart`: formula fullscreen senza `SingleChildScrollView` (pan/zoom via `InteractiveViewer`). → rimosso con expandability, vedi sezione Rimozioni.
- **Test**: +5 (pie valori misti, bar 10 categorie, parentesi estreme, endbox oltre finestra, step zero). Suite completa: **145 verde** (144 dopo rimozione test espansione).
- **Demo**: fixture `notes_mixed_content.txt` esteso con pie valori misti (clamp negativi + legenda) e bar 10 categorie con `unit` (label skip + tick max).

## Lezione reale estesa

- Lezione `eq1-intro` (step 1) in `assets/data/lessons/hs-year1-equations.json` arricchita con 2 card multifunction: `math_formula` "Soluzione generale" (`ax + b = 0 ⟹ x = -b/a`) e `interactive_chart` "La radice al variare di t" (retta `y = 2x + t`, slider `t` −3/3, toggle asse x).

## Content come array

- `LessonStep.content` ora accetta anche **array di segmenti**: stringhe = righe di testo, oggetti = riquadri `MultifunctionBox`; `_contentFromJson` appiattisce a stringa `::box`/`::endbox` in load. `hs-year1-equations.json` riscritto con content array indentato — niente più righe giganti; box JSON human-readable. Compatibile col formato stringa legacy. Test "content come array appiattisce testo e riquadri". Suite: **145 verde**.

## Math formula hidden e title vuoto

- `MathFormulaPayload.hidden` (`"hidden": true`): il box `math_formula` non viene mostrato affatto (`SizedBox.shrink`), niente card né titolo.
- `title` vuoto: header skippato (già) e padding del mini-blocco ridotto (`fromLTRB(16, 8, 16, 8)`).
- Test: round-trip `hidden`, box formua hidden non renderizzato, formula senza titolo non mostra testo. Suite: **148 verde**.
- Fix overflow: `ImageSource` vincola altezza immagine a 200px (`SizedBox` + `ClipRect`) — asset reali (es. `img 1.jpg`) non sovrastano più `maxHeight: 240` e i test non mascherano eccezioni di layout.
- Fixture demo (`notes_mixed_content.txt`): +2 box `math_formula` — uno `hidden` ("Formula nascosta", non renderizzato), uno senza `title` (header assente, card compatta). Test "formula hidden non renderizza e senza titolo compatta" (8 box, 7 card, hidden assente). Suite: **149 verde**.

## Capitolo → Lezioni

- Nuova `ArgomentoLessonsScreen` (`lib/screens/argomento_lessons_screen.dart`): elenco lezioni di un argomento tra livello anno e player.
- Card lezione essenziale: badge numerico a sinistra (indice+1), titolo, sottotitolo, «X min», check "Completata" o chevron; `ListenableBuilder` su `ProgressStore` aggiorna i badge al ritorno.
- `lesson_list_screen.dart` `_openArgomento`: non salta più alla prima lezione — pusha `ArgomentoLessonsScreen`; il player `LessonScreen` resta invariato (completamento → pop alla lista).
- Test: 3 nuovi (`test/argomento_lessons_screen_test.dart`). Suite: **152 verde**.

## Rimozioni

- **Expandability rimossa**: `is_expandable` rimosso da modello (`MultifunctionBox`), card, fixture e asset lezione; `_openFullscreen` + `Dialog.fullscreen` + `InteractiveViewer` + parametro `fullscreen` di `ImageSource` eliminati. La card non apre più dialog a schermo intero.

## Roadmap

- [ ] Ripulire la renderizzazione degli asset immagine del riquadro usando il pattern placeholder unico.
- [ ] Valutare supporto del riquadro anche nel contenuto degli esercizi (non solo lezioni).
- [ ] Editor visuale del box (solo viewer oggi).