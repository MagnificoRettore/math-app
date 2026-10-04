import 'package:flutter/material.dart';

import '../data/content_repository.dart';
import '../data/progress_store.dart';
import '../data/recommendation_engine.dart';
import '../models/level.dart';
import '../models/user_profile.dart';
import '../screens/course_screen.dart';
import '../screens/exercise_detail_screen.dart';
import '../screens/welcome_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'exercise_card.dart';
import 'recommendation_row.dart';
import 'school_choice_sheet.dart';
import 'section_header.dart';

/// La sezione dei consigli sulla Home.
///
/// [user] è opzionale perché la Home ha due utenti e **un solo disegno**: da
/// ospite la sezione non sparisce e non cambia faccia, cambia il contenuto.
/// Stessa testata, stesso mini-titolo, stessa riga: da collegato la riga è
/// l'esercizio consigliato, da ospite è l'invito a creare il profilo. Due
/// sezioni diverse nello stesso slot avrebbero fatto due Home diverse.
class RecommendedSection extends StatelessWidget {
  final UserProfile? user;

  const RecommendedSection({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    final level = _level;
    if (level == null) return _guest(context);

    final exercises = RecommendationEngine.recommendedExercises(level.id);
    if (exercises.isEmpty) return const SizedBox.shrink();

    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          'Per te · ${level.title}',
          trailing: TextButton(
            onPressed: () => _openLevel(context, level.id),
            child: Text(
              'Esplora',
              style: TextStyle(fontSize: AppText.label, color: c.accent),
            ),
          ),
        ),
        const _MiniHeader('Esercizi da provare'),
        for (final location in exercises)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ExerciseCard(
              exercise: location.exercise,
              status: ProgressStore.instance.statusOf(
                level.id,
                location.exercise.id,
              ),
              showPlayButton: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ExerciseDetailScreen(
                    level: location.level,
                    course: location.course,
                    topic: location.topic,
                    exercise: location.exercise,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Il livello del profilo. `null` per l'ospite e per un profilo senza scuola:
  /// in entrambi i casi non ci sono consigli da dare, e la sezione diventa
  /// l'invito.
  Level? get _level {
    final levelId = user?.schoolLevelId ?? '';
    if (levelId.isEmpty) return null;
    return ContentRepository.instance.levelById(levelId);
  }

  /// La sezione dell'ospite: stessa anatomia, contenuto d'invito.
  Widget _guest(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          'Per iniziare',
          trailing: TextButton(
            onPressed: () => _browse(context),
            child: Text(
              'Esplora',
              style: TextStyle(fontSize: AppText.label, color: c.accent),
            ),
          ),
        ),
        const _MiniHeader('Da dove cominciare'),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: RecommendationRow(
            plateColor: c.accent,
            plateIcon: Icons.person_outline,
            title: 'Crea il tuo profilo',
            preview:
                'Lezioni ed esercizi consigliati per la tua scuola, con i '
                'progressi salvati sul dispositivo.',
            showPlayButton: true,
            playKey: const Key('guest-join-play'),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const WelcomeScreen())),
          ),
        ),
      ],
    );
  }

  /// «Esplora» da ospite: non c'è un livello su cui aprire, quindi gli chiediamo
  /// qual è. La scelta non viene salvata — è una visita, come per la pillola in
  /// basso — e per questo il foglio si apre senza `signedIn`.
  Future<void> _browse(BuildContext context) async {
    final chosen = await showSchoolChoiceSheet(
      context,
      destination: SchoolChoiceDestination.exercises,
    );
    if (chosen == null || !context.mounted) return;
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => CourseScreen(level: chosen)));
  }

  void _openLevel(BuildContext context, String levelId) {
    final level = ContentRepository.instance.levelById(levelId);
    if (level == null) return;
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => CourseScreen(level: level)));
  }
}

class _MiniHeader extends StatelessWidget {
  final String title;

  const _MiniHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: AppText.bodyLarge,
          fontWeight: FontWeight.w500,
          color: c.textSecondary,
        ),
      ),
    );
  }
}
