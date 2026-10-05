import 'package:flutter/material.dart';

import '../data/feedback_store.dart';
import '../haptics.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/shake.dart';

/// Il feedback, dalle impostazioni: che tipo di messaggio è e il testo.
///
/// Senza un server il messaggio resta sul dispositivo, e la pagina lo dice
/// prima dell'invio e nel ringraziamento.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  final _shakes = FieldShakes();
  FeedbackKind _kind = FeedbackKind.idea;
  bool _busy = false;
  bool _sent = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _shakes.shakeEmpty([_controller]));
      return;
    }
    setState(() => _busy = true);
    await FeedbackStore.instance.add(_kind, _controller.text);
    if (!mounted) return;
    AppHaptics.mediumImpact();
    setState(() {
      _busy = false;
      _sent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback')),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: AppMotion.duration(context, AppMotion.medium),
          child: _sent ? _thanks(c) : _form(c),
        ),
      ),
    );
  }

  Widget _form(AppPalette c) {
    return ListView(
      key: const Key('feedback-form'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          'Dicci cosa ne pensi: un\'idea per migliorare l\'app, un problema '
          'che hai trovato o qualsiasi altra cosa.',
          style: TextStyle(
            fontSize: AppText.bodyMedium,
            height: 1.4,
            color: c.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final kind in FeedbackKind.values)
              _KindChip(
                key: Key('feedback-kind-${kind.name}'),
                label: kind.label,
                selected: _kind == kind,
                onTap: () {
                  AppHaptics.selectionClick();
                  setState(() => _kind = kind);
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        Form(
          key: _formKey,
          child: ShakeWidget(
            trigger: _shakes.of(_controller),
            child: TextFormField(
              key: const Key('feedback-field'),
              controller: _controller,
              minLines: 5,
              maxLines: 10,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
              validator: FeedbackStore.messageError,
              decoration: AppTheme.fieldDecoration(c).copyWith(
                labelText: 'Il tuo messaggio',
                alignLabelWithHint: true,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'L\'app non ha un server: il messaggio resta salvato su questo '
          'dispositivo e non viene inviato a nessuno.',
          style: TextStyle(
            fontSize: AppText.caption,
            height: 1.4,
            color: c.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        AppButton(
          key: const Key('feedback-send'),
          label: 'Invia',
          icon: Icons.send_rounded,
          expand: true,
          busy: _busy,
          onPressed: _send,
        ),
      ],
    );
  }

  Widget _thanks(AppPalette c) {
    return Center(
      key: const Key('feedback-thanks'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: c.yellow,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_rounded,
                size: 44,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Grazie!',
              style: TextStyle(
                fontFamily: AppText.headingFont,
                fontSize: AppText.headline,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Il tuo messaggio è stato salvato su questo dispositivo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppText.bodyLarge,
                height: 1.4,
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              key: const Key('feedback-done'),
              label: 'Fatto',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Il tipo di messaggio: giallo col bordo oro quando è scelto, come i filtri.
class _KindChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _KindChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      excludeSemantics: true,
      label: label,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.duration(context, AppMotion.medium),
          curve: AppMotion.standard,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? c.yellow : c.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? c.yellowDeep : c.border,
              width: 2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppText.bodyFont,
              fontSize: AppText.bodyMedium,
              fontWeight: FontWeight.w500,
              color: c.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
