import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../data/content_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../models/course.dart';
import '../models/level.dart';
import '../widgets/school_level_tile.dart';
import '../widgets/year_tile.dart';
import '../widgets/app_button.dart';

class SchoolPickerScreen extends StatefulWidget {
  final String initialLevelId;

  /// `true` se la schermata chiude l'onboarding: salva e torna alla home
  /// azzerando lo stack. Dal profilo è `false` e basta tornare indietro.
  ///
  /// Il flag, non un callback: le schermate che aprono questa pagina la
  /// sostituiscono con `pushReplacement`, quindi il loro `BuildContext` è
  /// già morto quando l'utente preme il bottone.
  final bool onboarding;

  const SchoolPickerScreen({
    super.key,
    this.initialLevelId = '',
    this.onboarding = false,
  });

  @override
  State<SchoolPickerScreen> createState() => _SchoolPickerScreenState();
}

class _SchoolPickerScreenState extends State<SchoolPickerScreen> {
  late String _selectedId;
  String _courseId = '';

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialLevelId;
    // L'anno di prima vale finché la scuola resta quella.
    _courseId = AuthStore.instance.currentUser?.courseId ?? '';
  }

  /// Medie e superiori chiedono anche l'anno; l'università no.
  Level? get _selectedLevel =>
      ContentRepository.instance.levelById(_selectedId);

  bool get _needsYear {
    final level = _selectedLevel;
    return level != null &&
        level.id != 'university' &&
        level.courses.isNotEmpty;
  }

  bool get _yearChosen =>
      _selectedLevel?.courses.any((course) => course.id == _courseId) ?? false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final level = AuthStore.instance.currentUser == null
        ? null
        : ContentRepository.instance.levelById(
            AuthStore.instance.currentUser!.schoolLevelId,
          );
    final levels = ContentRepository.instance.levels;
    final onboarding = widget.onboarding;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              onboarding
                  ? 'Scegli la tua scuola per ricevere lezioni ed esercizi '
                        'pensati per te. Potrai cambiarla in qualsiasi momento.'
                  : level == null
                  ? 'Seleziona il tuo livello scolastico.'
                  : 'Ora frequenti ${level.title}. Puoi cambiarlo quando vuoi.',
              style: TextStyle(
                fontSize: AppText.bodyMedium,
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            for (final item in levels)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SchoolLevelTile(
                  level: item,
                  selected: _selectedId == item.id,
                  onTap: () => setState(() {
                    if (item.id != _selectedId) _courseId = '';
                    _selectedId = item.id;
                  }),
                ),
              ),
            if (_needsYear) ...[
              const SizedBox(height: 8),
              Text(
                'Che anno frequenti?',
                style: TextStyle(
                  fontFamily: AppText.headingFont,
                  fontSize: AppText.titleMedium,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              for (final course in _selectedLevel?.courses ?? const <Course>[])
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: YearTile(
                    key: Key('year-${course.id}'),
                    course: course,
                    selected: _courseId == course.id,
                    onTap: () => setState(() => _courseId = course.id),
                  ),
                ),
            ],
            const SizedBox(height: 8),
            AppButton(
              label: onboarding ? 'Crea il mio profilo' : 'Salva',
              onPressed: _selectedId.isEmpty || (_needsYear && !_yearChosen)
                  ? null
                  : _save,
              expand: true,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    await AuthStore.instance.updateSchool(
      _selectedId,
      courseId: _needsYear ? _courseId : '',
    );
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (widget.onboarding) {
      navigator.popUntil((route) => route.isFirst);
      return;
    }
    navigator.pop();
  }
}
