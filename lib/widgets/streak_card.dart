import 'package:flutter/material.dart';

import '../data/study_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'app_card.dart';

/// La serie di giorni come la card «Traguardo» del design: arancio con il
/// gradino pieno sotto, i tagliandi bianchi sul bordo sinistro e una striscia
/// chiara a destra. Dentro, su un riquadro bianco, la serie e il record, e
/// sotto i sette giorni della settimana. Bassa: niente barre degli obiettivi.
class StreakCard extends StatelessWidget {
  const StreakCard({super.key});

  /// Quanti giorni mostra la fila dei blocchi: una settimana.
  static const int _week = 7;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: StudyStore.instance,
      builder: (context, _) {
        final c = AppColors.of(context);
        final store = StudyStore.instance;
        final streak = store.currentStreak;
        final light = Color.lerp(c.orange, Colors.white, 0.45)!;
        final white = BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(10),
        );
        return Container(
          key: const Key('streak-card'),
          decoration: BoxDecoration(
            color: c.orange,
            borderRadius: BorderRadius.circular(18),
            boxShadow: cardShadow(c),
          ),
          child: Stack(
            children: [
              // La striscia chiara a destra e i tagliandi a sinistra: il
              // biglietto del traguardo.
              Positioned(
                right: 26,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  color: Color.lerp(c.orange, Colors.white, 0.2),
                ),
              ),
              Positioned(
                left: 0,
                top: 16,
                bottom: 16,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 0; i < 4; i++)
                      Container(
                        width: 22,
                        height: 8,
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(6),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(48, 16, 50, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      decoration: white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Il record sta sulla riga dell'occhiello: una riga
                          // in meno, e la card resta bassa.
                          Row(
                            children: [
                              Text(
                                'TRAGUARDO',
                                style: TextStyle(
                                  fontSize: AppText.label,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.8,
                                  color: c.medium,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Record: ${store.bestStreak}',
                                  textAlign: TextAlign.right,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: AppText.label,
                                    color: c.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Serie di $streak ${streak == 1 ? 'giorno' : 'giorni'}',
                            style: TextStyle(
                              fontFamily: AppText.headingFont,
                              fontSize: AppText.headline,
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // I giorni della serie nella settimana: indaco quelli
                    // fatti, arancio chiaro quelli che mancano.
                    Semantics(
                      label:
                          '${streak.clamp(0, _week)} giorni su $_week di questa settimana',
                      child: ExcludeSemantics(
                        child: Row(
                          children: [
                            for (var i = 0; i < _week; i++) ...[
                              if (i > 0) const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: i < streak ? c.accent : light,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
