import 'dart:math';

import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../data/content_repository.dart';
import '../data/lesson_repository.dart';
import '../models/argomento.dart';
import '../screens/argomento_lessons_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/topic_style.dart';
import 'app_card.dart';
import 'topic_background.dart';

/// Il carosello degli argomenti in Home.
///
/// Con la scuola nel profilo mostra tutti gli argomenti di quella scuola, in
/// ordine. Da ospite (o senza scuola) quelli di **un anno a caso** fra gli anni
/// che hanno argomenti, così il carosello non è mai vuoto. Se non c'è niente da
/// mostrare (una scuola ancora senza argomenti) la sezione sparisce, e con lei
/// lo spazio sotto, che per questo sta dentro e non nella lista della Home.
class ArgomentoCarousel extends StatefulWidget {
  const ArgomentoCarousel({super.key});

  @override
  State<ArgomentoCarousel> createState() => _ArgomentoCarouselState();
}

class _ArgomentoCarouselState extends State<ArgomentoCarousel> {
  /// Altezza fissa della striscia, come quella delle foto che sostituisce.
  static const double _height = 180;

  late final PageController _controller = PageController(
    viewportFraction: 0.85,
  );
  int _index = 0;

  /// L'anno dell'ospite si estrae una volta: a ogni rebuild cambierebbe slide
  /// sotto il dito.
  late final (String, String)? _guestYear = _randomYear();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  (String, String)? _randomYear() {
    final years = {
      for (final a in LessonRepository.instance.argomenti)
        (a.levelId, a.yearId),
    }.toList();
    if (years.isEmpty) return null;
    return years[Random().nextInt(years.length)];
  }

  List<Argomento> _argomenti() {
    final repo = LessonRepository.instance;
    final levelId = AuthStore.instance.currentUser?.schoolLevelId ?? '';
    if (levelId.isNotEmpty) {
      return [
        for (final a in repo.argomenti)
          if (a.levelId == levelId) a,
      ];
    }
    final year = _guestYear;
    if (year == null) return const [];
    return repo.argomentiInYear(year.$1, year.$2);
  }

  void _open(Argomento argomento) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArgomentoLessonsScreen(
          argomento: argomento,
          levelId: argomento.levelId,
        ),
      ),
    );
  }

  Widget _slide(Argomento argomento, int index) {
    final c = AppColors.of(context);
    final color = topicColor(c, argomento.icon);
    final year = ContentRepository.instance
        .levelById(argomento.levelId)
        ?.courses
        .where((course) => course.id == argomento.yearId)
        .firstOrNull
        ?.title;
    final count = argomento.lessons.length;
    final details = [
      ?year,
      count == 1 ? '1 lezione' : '$count lezioni',
    ].join(' · ');

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final page = _controller.hasClients
            ? (_controller.page ?? _index.toDouble())
            : _index.toDouble();
        final dist = (index - page).clamp(-1.0, 1.0);
        // La slide attiva sta a scala 1 e piena, le vicine rientrano e si
        // spengono: è la profondità del carosello, non una dissolvenza a caso.
        final scale = 1 - 0.05 * dist.abs();
        final opacity = 1 - 0.4 * dist.abs();
        return Opacity(
          opacity: opacity,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kCardRadius),
            boxShadow: [
              BoxShadow(
                color: c.shadow,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(kCardRadius),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                key: ValueKey('carousel-${argomento.topicId}'),
                onTap: () => _open(argomento),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    TopicBackground(image: null, color: color),
                    // Sopra i pallini, che stanno a 10 dal fondo.
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 28,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            argomento.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: AppText.headline,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black45,
                                  blurRadius: 8,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            details,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: AppText.label,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Si ascolta da sé: in Home è `const`, e il rebuild della lista non lo
    // raggiungerebbe quando l'utente entra, esce o cambia scuola.
    return ListenableBuilder(
      listenable: AuthStore.instance,
      builder: (context, _) {
        final argomenti = _argomenti();
        if (argomenti.isEmpty) return const SizedBox.shrink();
        final selected = _index.clamp(0, argomenti.length - 1);
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: SizedBox(
            height: _height,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                ClipRect(
                  child: SizedBox.expand(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: argomenti.length,
                      padEnds: true,
                      allowImplicitScrolling: true,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (context, index) =>
                          _slide(argomenti[index], index),
                    ),
                  ),
                ),
                // Con una slide sola i pallini non indicano niente.
                if (argomenti.length > 1)
                  Positioned(
                    bottom: 10,
                    child: Row(
                      children: [
                        for (var i = 0; i < argomenti.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == selected ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == selected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
