import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../data/content_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/school_level_tile.dart';

class SchoolPickerScreen extends StatefulWidget {
  final String initialLevelId;
  final VoidCallback? onSaved;

  const SchoolPickerScreen({super.key, this.initialLevelId = '', this.onSaved});

  @override
  State<SchoolPickerScreen> createState() => _SchoolPickerScreenState();
}

class _SchoolPickerScreenState extends State<SchoolPickerScreen> {
  late String _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialLevelId;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final level = AuthStore.instance.currentUser == null
        ? null
        : ContentRepository.instance.levelById(
            AuthStore.instance.currentUser!.schoolLevelId,
          );
    final levels = ContentRepository.instance.levels;
    final onboarding = widget.onSaved != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          onboarding ? 'Cosa studi?' : 'La tua scuola',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            onboarding
                ? 'Scegli la tua scuola per ricevere lezioni ed esercizi '
                      'pensati per te. Potrai cambiarla in qualsiasi momento.'
                : level == null
                ? 'Seleziona il tuo livello scolastico.'
                : 'Ora frequenti ${level.title}. Puoi cambiarlo quando vuoi.',
            style: TextStyle(fontSize: 14, color: c.textSecondary),
          ),
          const SizedBox(height: 16),
          for (final item in levels)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SchoolLevelTile(
                level: item,
                selected: _selectedId == item.id,
                onTap: () => setState(() => _selectedId = item.id),
              ),
            ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _selectedId.isEmpty ? null : _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: c.accent,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(onboarding ? 'Crea il mio profilo' : 'Salva'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    await AuthStore.instance.updateSchool(_selectedId);
    if (!mounted) return;
    if (widget.onSaved != null) {
      widget.onSaved!();
      return;
    }
    Navigator.of(context).pop();
  }
}
