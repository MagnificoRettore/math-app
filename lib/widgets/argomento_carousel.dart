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

/// Margine orizzontale della pagina che ospita il carosello (il padding della
/// lista della Home): la striscia lo scavalca per prendersi tutto lo schermo e
/// lo rimette come padding interno, così la prima card resta a filo del testo.
const double _pageMargin = 20;

/// Spazio fra due card.
const double _gap = 12;

/// Quante card stanno in larghezza: due intere e un pezzo della terza, che dice
/// che la striscia si scorre.
const double _visibleCards = 2.2;

/// Il carosello degli argomenti in Home.
///
/// Con la scuola nel profilo mostra tutti gli argomenti di quella scuola, in
/// ordine. Da ospite (o senza scuola) quelli di **un anno a caso** fra gli anni
/// che hanno argomenti, così il carosello non è mai vuoto. Se non c'è niente da
/// mostrare (una scuola ancora senza argomenti) la sezione sparisce, e con lei
/// lo spazio sotto, che per questo sta dentro e non nella lista della Home.
///
/// Le card sono quadrate e se ne vedono circa due: è una lista orizzontale, non
/// un `PageView`, che aggancerebbe e centrerebbe una card per volta.
class ArgomentoCarousel extends StatefulWidget {
  const ArgomentoCarousel({super.key});

  @override
  State<ArgomentoCarousel> createState() => _ArgomentoCarouselState();
}

class _ArgomentoCarouselState extends State<ArgomentoCarousel> {
  /// L'anno dell'ospite si estrae una volta: a ogni rebuild cambierebbe slide
  /// sotto il dito.
  late final (String, String)? _guestYear = _randomYear();

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

  Widget _card(Argomento argomento, double side) {
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

    return SizedBox.square(
      dimension: side,
      // Piatta come tutte le card: nessuna ombra.
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
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        argomento.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppText.headingFont,
                          fontSize: AppText.titleLarge,
                          fontWeight: FontWeight.w600,
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
                          fontSize: AppText.labelSmall,
                          fontWeight: FontWeight.w500,
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
        final screen = MediaQuery.sizeOf(context).width;
        final side =
            (screen - _pageMargin - _gap * (_visibleCards.ceil() - 1)) /
            _visibleCards;
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          // La lista della Home dà 20 di margine per lato: la striscia li
          // scavalca e prende tutto lo schermo, così le card scorrono fino al
          // bordo invece di sparire a 20 px da esso.
          child: SizedBox(
            height: side,
            child: OverflowBox(
              maxWidth: screen,
              child: ListView.separated(
                key: const Key('argomento-carousel-list'),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: _pageMargin),
                itemCount: argomenti.length,
                separatorBuilder: (_, _) => const SizedBox(width: _gap),
                itemBuilder: (context, index) => _card(argomenti[index], side),
              ),
            ),
          ),
        );
      },
    );
  }
}
