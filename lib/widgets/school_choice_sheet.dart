import 'package:flutter/material.dart';

import '../data/content_repository.dart';
import '../models/level.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_text.dart';
import 'school_level_tile.dart';

enum SchoolChoiceDestination { lessons, exercises }

/// Sceglie la scuola da cui guardare.
///
/// Due usi, e la differenza è nel testo più che nelle scelte: da ospite il
/// foglio chiede la scuola ed è definitivo, da utente collegato apre le altre
/// scuole per una visita e lascia quella del profilo dov'è. Il footer da ospite
/// promette «questa scelta non ti verrà più richiesta», quindi non può
/// comparire nel secondo caso.
Future<Level?> showSchoolChoiceSheet(
  BuildContext context, {
  required SchoolChoiceDestination destination,
  bool signedIn = false,
  String currentLevelId = '',
}) async {
  final levels = ContentRepository.instance.levels;
  final isLessons = destination == SchoolChoiceDestination.lessons;
  final bottomInset = MediaQuery.of(context).padding.bottom;

  return showModalBottomSheet<Level>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    sheetAnimationStyle: AnimationStyle(
      duration: AppMotion.slow,
      reverseDuration: AppMotion.medium,
      curve: AppMotion.standard,
    ),
    builder: (sheetContext) {
      final c = AppColors.of(sheetContext);
      return SafeArea(
        child: Container(
          // Il foglio è dello stesso crema della pagina, col bordo lilla da 3
          // dei controlli: le scuole, bianche, ci stanno sopra come card.
          decoration: BoxDecoration(
            color: c.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: c.border, width: 3),
              left: BorderSide(color: c.border, width: 3),
              right: BorderSide(color: c.border, width: 3),
            ),
          ),
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: c.yellow,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.school_outlined,
                      size: 22,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      signedIn
                          ? (isLessons
                                ? 'Altre scuole, lezioni'
                                : 'Altre scuole, esercizi')
                          : (isLessons
                                ? 'Lezioni per scuola'
                                : 'Esercizi per scuola'),
                      style: TextStyle(
                        fontFamily: AppText.headingFont,
                        fontSize: AppText.titleLarge,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                signedIn
                    ? 'Dai un\'occhiata a un\'altra scuola. Quella del tuo '
                          'profilo e i tuoi progressi restano dove sono.'
                    : isLessons
                    ? 'Scegli la tua scuola per vedere le lezioni guidate '
                          'pensate per te.'
                    : 'Scegli la tua scuola per accedere agli esercizi '
                          'organizzati per anno e argomento.',
                style: TextStyle(
                  fontSize: AppText.label,
                  color: c.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              for (final level in levels)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SchoolLevelTile(
                    level: level,
                    selected: signedIn && level.id == currentLevelId,
                    onTap: () => Navigator.of(sheetContext).pop(level),
                  ),
                ),
              if (!signedIn)
                Center(
                  child: Text(
                    'Se crei un profilo, la tua scuola viene ricordata e '
                    'questa scelta non ti verrà più richiesta.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppText.caption,
                      color: c.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
