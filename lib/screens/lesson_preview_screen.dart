import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/lesson_repository.dart';
import '../models/argomento.dart';
import '../models/lesson.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/app_card.dart';
import '../widgets/list_filter_bar.dart';
import 'lesson_screen.dart';

/// Gli schermi su cui ogni card deve stare: dal più stretto supportato (320) al
/// tablet, in punti logici. Li usano l'anteprima e il test di validazione dei
/// contenuti (`test/content_validation_test.dart`), così sono gli stessi.
const List<(String, Size)> kPreviewDevices = [
  ('320×640', Size(320, 640)),
  ('360×800', Size(360, 800)),
  ('393×852', Size(393, 852)),
  ('412×915', Size(412, 915)),
  ('600×960 tablet', Size(600, 960)),
];

/// Il testo del sistema: normale e ingrandito (impostazione di accessibilità).
const List<double> kPreviewTextScales = [1.0, 1.3];

/// Anteprima delle lezioni, **solo in debug**: l'elenco di tutte le lezioni e,
/// per quella scelta, la lezione vera dentro una cornice delle dimensioni di un
/// telefono, con la scala del testo a scelta.
///
/// Serve a chi scrive i contenuti: si modifica il JSON, si preme «Ricarica» e
/// la lezione si ridisegna da capo, senza riavviare l'app. In debug Flutter
/// segna a strisce gialle e nere qualsiasi overflow, quindi si vede subito se
/// una formula o un grafico non ci stanno in 320 px.
///
/// Si apre da Personalizzazione, voce «Anteprima lezioni» (c'è solo in debug).
/// Una lezione portata a termine qui segna i suoi progressi come in app.
class LessonPreviewScreen extends StatefulWidget {
  const LessonPreviewScreen({super.key});

  @override
  State<LessonPreviewScreen> createState() => _LessonPreviewScreenState();
}

class _LessonPreviewScreenState extends State<LessonPreviewScreen> {
  int _device = 1;
  double _scale = 1.0;
  Argomento? _argomento;
  Lesson? _lesson;

  /// Cambia a ogni «Ricarica»: la lezione riparte da capo anche se è la stessa.
  int _generation = 0;
  bool _reloading = false;

  /// Rilegge i JSON dagli asset. Gli asset si tengono in una cache: senza
  /// toglierli di lì, un file modificato non si vedrebbe.
  Future<void> _reload() async {
    setState(() => _reloading = true);
    final previousId = _lesson?.id;
    final index = jsonDecode(
      await rootBundle.loadString(
        'assets/data/lessons/index.json',
        cache: false,
      ),
    ) as Map<String, dynamic>;
    rootBundle.evict('assets/data/lessons/index.json');
    for (final file in index['argomenti'] as List<dynamic>) {
      rootBundle.evict('assets/data/lessons/$file');
    }
    await LessonRepository.instance.reload();
    if (!mounted) return;
    setState(() {
      _reloading = false;
      _generation++;
      // La lezione aperta si ritrova per id nel contenuto nuovo.
      _argomento = null;
      _lesson = null;
      for (final a in LessonRepository.instance.argomenti) {
        for (final l in a.lessons) {
          if (l.id == previousId) {
            _argomento = a;
            _lesson = l;
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final lesson = _lesson;
    return Scaffold(
      appBar: AppBar(
        title: Text(lesson == null ? 'Anteprima lezioni' : lesson.title),
        leading: lesson == null
            ? null
            : BackButton(
                key: const Key('preview-back'),
                onPressed: () => setState(() {
                  _lesson = null;
                  _argomento = null;
                }),
              ),
        actions: [
          IconButton(
            key: const Key('preview-reload'),
            tooltip: 'Ricarica i contenuti dai file',
            onPressed: _reloading ? null : _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(child: lesson == null ? _list(c) : _preview(c, lesson)),
    );
  }

  Widget _list(AppPalette c) {
    final argomenti = LessonRepository.instance.argomenti;
    return ListView(
      key: const Key('preview-list'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          'Solo in debug. Scegli una lezione: si apre dentro una cornice della '
          'dimensione di un telefono. Dopo aver modificato un JSON, «Ricarica».',
          style: TextStyle(
            fontSize: AppText.bodySmall,
            height: 1.4,
            color: c.textSecondary,
          ),
        ),
        for (final argomento in argomenti) ...[
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 8),
            child: Text(
              '${argomento.title} · ${argomento.levelId} · ${argomento.yearId}',
              style: TextStyle(
                fontFamily: AppText.headingFont,
                fontSize: AppText.titleMedium,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
          ),
          for (final lesson in argomento.lessons)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                key: Key('preview-lesson-${lesson.id}'),
                onTap: () => setState(() {
                  _argomento = argomento;
                  _lesson = lesson;
                  _generation++;
                }),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lesson.title,
                            style: TextStyle(
                              fontSize: AppText.bodyLarge,
                              fontWeight: FontWeight.w500,
                              color: c.textPrimary,
                            ),
                          ),
                          Text(
                            '${lesson.id} · ${lesson.steps.length} card',
                            style: TextStyle(
                              fontSize: AppText.label,
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: c.textSecondary),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _preview(AppPalette c, Lesson lesson) {
    final size = kPreviewDevices[_device].$2;
    return Column(
      children: [
        // Schermo e scala del testo, con le stesse pillole dei filtri.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Row(
            children: [
              for (final (i, d) in kPreviewDevices.indexed) ...[
                FilterPill(
                  key: Key('preview-device-$i'),
                  label: d.$1,
                  selected: _device == i,
                  onTap: () => setState(() {
                    _device = i;
                    _generation++;
                  }),
                ),
                const SizedBox(width: 8),
              ],
              const SizedBox(width: 8),
              for (final s in const [1.0, 1.3, 1.6]) ...[
                FilterPill(
                  key: Key('preview-scale-$s'),
                  label: 'testo ×$s',
                  selected: _scale == s,
                  onTap: () => setState(() {
                    _scale = s;
                    _generation++;
                  }),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: constraints.maxWidth,
                    minHeight: constraints.maxHeight,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _Frame(
                        key: ValueKey(
                          '${lesson.id}-$_device-$_scale-$_generation',
                        ),
                        size: size,
                        textScale: _scale,
                        lesson: lesson,
                        levelId: _argomento?.levelId ?? 'high-school',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// La cornice del telefono: la lezione vera, in uno schermo di [size] con la
/// scala del testo [textScale]. Ha un `Navigator` suo, così il «Completa la
/// lezione» (che torna indietro) chiude la lezione dentro la cornice e non
/// l'anteprima.
class _Frame extends StatelessWidget {
  final Size size;
  final double textScale;
  final Lesson lesson;
  final String levelId;

  const _Frame({
    super.key,
    required this.size,
    required this.textScale,
    required this.lesson,
    required this.levelId,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.accentDeep, width: 6),
        boxShadow: cardShadow(c),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              size: size,
              padding: EdgeInsets.zero,
              viewPadding: EdgeInsets.zero,
              viewInsets: EdgeInsets.zero,
              textScaler: TextScaler.linear(textScale),
            ),
            child: Navigator(
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (_) => _Finished(lesson: lesson, levelId: levelId),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// La pagina sotto la lezione: la lezione si apre subito sopra di lei, e a
/// lezione finita si ritorna qui, con la possibilità di ripartire.
class _Finished extends StatefulWidget {
  final Lesson lesson;
  final String levelId;

  const _Finished({required this.lesson, required this.levelId});

  @override
  State<_Finished> createState() => _FinishedState();
}

class _FinishedState extends State<_Finished> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  void _open() {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            LessonScreen(lesson: widget.lesson, levelId: widget.levelId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Lezione chiusa',
                style: TextStyle(
                  fontFamily: AppText.headingFont,
                  fontSize: AppText.title,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              FilterPill(
                key: const Key('preview-restart'),
                label: 'Riparti',
                selected: false,
                onTap: _open,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
