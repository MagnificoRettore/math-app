import 'dart:async';

import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../data/browse_store.dart';
import '../data/content_repository.dart';
import '../models/level.dart';
import '../screens/course_screen.dart';
import '../screens/lesson_list_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/weak_points_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'app_card.dart';
import 'school_choice_sheet.dart';

/// La nostra missione: cosa dice l'app e da dove ci si muove.
///
/// `showShortcuts` mette sotto il testo le quattro scorciatoie verso le sezioni
/// vere dell'app. La pagina missione (`MissionScreen`) riusa lo stesso blocco
/// senza, perché lì le scorciatoie porterebbero alle pagine che si sta già
/// leggendo: due righe di menu sopra il testo che descrive il menu.
///
/// Le scorciatoie ci sono per tutti, ospite compreso: la Home è una pagina sola
/// e non deve cambiare disegno con l'accesso. Il livello si risolve al tap, e
/// se non c'è si chiede quale sia — è quello che fa già la pillola in basso.
class MissionHero extends StatelessWidget {
  final VoidCallback? onTap;
  final bool showShortcuts;

  const MissionHero({super.key, this.onTap, this.showShortcuts = false});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: c.accentSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_stories_outlined,
                  color: c.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'La nostra missione',
                  style: TextStyle(
                    fontSize: AppText.title,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Crediamo che la matematica non debba essere un ostacolo: '
            'è un linguaggio che insegna a ragionare. La nostra missione è '
            'aiutare ogni studente a imparare con fiducia, offrendo esercizi '
            'risolti passo-passo, spiegazioni chiare e un percorso di studio '
            'che cresce insieme ai suoi progressi.',
            style: TextStyle(
              fontSize: AppText.bodyMedium,
              height: 1.5,
              color: c.textSecondary,
            ),
          ),
          if (showShortcuts) ...[
            const SizedBox(height: 18),
            const _ShortcutGrid(),
          ],
        ],
      ),
    );
  }
}

/// Le quattro scorciatoie, due per riga.
///
/// Due `Row` con `Expanded` invece di un `Wrap`: la metà della larghezza la
/// calcola il padre, quindi non c'è nessuna larghezza da indovinare e le due
/// righe restano allineate anche se le parole hanno lunghezze diverse.
class _ShortcutGrid extends StatelessWidget {
  const _ShortcutGrid();

  @override
  Widget build(BuildContext context) {
    const gap = 10.0;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _Shortcut(
                icon: Icons.school_outlined,
                label: 'Lezioni',
                onTap: () =>
                    openLevelPage(context, SchoolChoiceDestination.lessons),
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _Shortcut(
                icon: Icons.calculate_outlined,
                label: 'Esercizi',
                onTap: () =>
                    openLevelPage(context, SchoolChoiceDestination.exercises),
              ),
            ),
          ],
        ),
        SizedBox(height: gap),
        Row(
          children: [
            Expanded(
              child: _Shortcut(
                icon: Icons.healing_outlined,
                label: 'Punti deboli',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WeakPointsScreen()),
                ),
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _Shortcut(
                icon: Icons.person_outline,
                label: 'Profilo',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Apre le lezioni o gli esercizi del livello, chiedendo la scuola quando non
/// c'è.
///
/// L'ordine di risoluzione è quello della pillola in basso: la scuola in visita
/// viene prima di quella del profilo, altrimenti cambiando pagina si
/// ripartirebbe da capo su un'altra scuola e la visita finirebbe al primo
/// tocco. Le due scorciatoie non possono portarsi dentro una `Widget`: devono
/// aspettare il tap per sapere da dove chiamarle.
Future<void> openLevelPage(
  BuildContext context,
  SchoolChoiceDestination destination,
) async {
  final user = AuthStore.instance.currentUser;
  final levelId =
      BrowseStore.instance.levelId ??
      ((user?.schoolLevelId ?? '').isNotEmpty ? user!.schoolLevelId : '');
  final level = levelId.isEmpty
      ? null
      : ContentRepository.instance.levelById(levelId);
  if (level != null) {
    unawaited(_pushLevel(context, destination, level));
    return;
  }
  unawaited(_askSchool(context, destination));
}

Future<void> _askSchool(
  BuildContext context,
  SchoolChoiceDestination destination,
) async {
  final chosen = await showSchoolChoiceSheet(context, destination: destination);
  if (chosen == null || !context.mounted) return;
  unawaited(_pushLevel(context, destination, chosen));
}

Future<void> _pushLevel(
  BuildContext context,
  SchoolChoiceDestination destination,
  Level level,
) {
  final page = destination == SchoolChoiceDestination.lessons
      ? LessonListScreen(levelId: level.id)
      : CourseScreen(level: level);
  return Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}

/// Scorciatoia tonda: icona e parola breve su una piastra chiara.
class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: c.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: c.accent, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppText.label,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
