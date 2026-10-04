import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../data/auth_store.dart';
import '../data/auth_validators.dart';
import '../data/content_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/avatar_picker.dart';
import '../widgets/google_button.dart';
import '../widgets/password_field.dart';
import '../widgets/progress_bar.dart';
import '../widgets/school_level_tile.dart';
import '../widgets/shake.dart';
import '../widgets/strength_meter.dart';
import '../widgets/wave_clipper.dart';
import 'school_picker_screen.dart';

/// Creazione del profilo in tre passi, come «Creazione profilo» del design:
/// chi sei (avatar e nome), l'account (email, ID, password, termini) e la
/// scuola, che decide lezioni, esercizi e consigli.
///
/// La testata indaco dice il passo e la barra avanza; fra un passo e l'altro
/// il contenuto scorre con una dissolvenza (avanti da destra, indietro da
/// sinistra) e il titolo cambia in dissolvenza. Col movimento ridotto il passo
/// cambia e basta.
///
/// «Continua» controlla il passo al tocco e mostra gli errori nei campi; al
/// passo della scuola resta spento finché la scuola non è scelta. Il back di
/// sistema, dal secondo passo in poi, torna al passo prima invece di uscire.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  static const _titles = ['Chi sei?', 'Il tuo account', 'La tua scuola'];

  /// Di quanto, in frazione della larghezza, il passo nuovo entra di lato.
  static const double _slide = 0.08;

  final _whoForm = GlobalKey<FormState>();
  final _accountForm = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _accountIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _shakes = FieldShakes();
  String _avatarId = '';
  String _schoolId = '';
  bool _termsAccepted = false;
  bool _busy = false;
  int _step = 0;

  /// Il verso dell'ultimo cambio di passo: avanti il passo nuovo entra da
  /// destra, indietro da sinistra.
  bool _forward = true;

  /// Finché l'utente non scrive a mano nell'ID account, il campo segue
  /// l'email: il suggerimento è buono e nessuno lo scrive da solo.
  bool _accountIdTouched = false;

  bool get _last => _step == _titles.length - 1;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _accountIdController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _go(int step) {
    FocusScope.of(context).unfocus();
    setState(() {
      _forward = step > _step;
      _step = step;
    });
  }

  void _continue() {
    if (_busy) return;
    if (_step == 0 && !(_whoForm.currentState?.validate() ?? false)) {
      setState(() => _shakes.shakeEmpty([_nameController]));
      return;
    }
    if (_step == 1) {
      if (!(_accountForm.currentState?.validate() ?? false)) {
        setState(
          () => _shakes.shakeEmpty([
            _emailController,
            _accountIdController,
            _passwordController,
            _confirmController,
          ]),
        );
        return;
      }
      if (!_termsAccepted) {
        _tell('Accetta i Termini e la Privacy Policy per continuare.');
        return;
      }
    }
    if (_last) {
      _submit();
    } else {
      _go(_step + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    Widget content = KeyedSubtree(
      key: ValueKey('registration-step-$_step'),
      child: switch (_step) {
        0 => _whoStep(c),
        1 => _accountStep(c),
        _ => _schoolStep(),
      },
    );
    if (!AppMotion.reduced(context)) {
      content = content
          .animate(key: ValueKey(_step))
          .fadeIn(duration: AppMotion.slow, curve: AppMotion.standard)
          .slideX(
            begin: _forward ? _slide : -_slide,
            end: 0,
            duration: AppMotion.slow,
            curve: AppMotion.standard,
          );
    }

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _go(_step - 1);
      },
      child: Scaffold(
        body: Column(
          children: [
            _StepHeader(
              step: _step,
              steps: _titles.length,
              title: _titles[_step],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                children: [content],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Row(
                  children: [
                    if (_step > 0) ...[
                      AppButton(
                        key: const Key('registration-back'),
                        label: 'Indietro',
                        variant: AppButtonVariant.outline,
                        onPressed: _busy ? null : () => _go(_step - 1),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: AppButton(
                        key: const Key('registration-next'),
                        label: _last ? 'Crea il mio profilo' : 'Continua',
                        expand: true,
                        busy: _busy,
                        onPressed: _last && _schoolId.isEmpty
                            ? null
                            : _continue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _whoStep(AppPalette c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Form(
            key: _whoForm,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label('Scegli il tuo avatar'),
                const SizedBox(height: 14),
                AvatarPicker(
                  value: _avatarId,
                  onChanged: (value) => setState(() => _avatarId = value),
                ),
                const SizedBox(height: 22),
                ShakeWidget(
                  trigger: _shakes.of(_nameController),
                  child: _field(
                    controller: _nameController,
                    label: 'Come ti chiami?',
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty) return 'Inserisci il tuo nome';
                      if (v.length < 2) {
                        return 'Il nome deve avere almeno 2 caratteri';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const OrSeparator(label: 'Oppure registrati con'),
        const SizedBox(height: 12),
        GoogleButton(
          label: 'Registrati con Google',
          onTap: _continueWithGoogle,
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Il profilo è salvato solo su questo dispositivo.',
            style: TextStyle(fontSize: AppText.caption, color: c.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _accountStep(AppPalette c) {
    return AppCard(
      child: Form(
        key: _accountForm,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            ShakeWidget(
              trigger: _shakes.of(_emailController),
              child: _field(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                onChanged: (value) {
                  if (_accountIdTouched) return;
                  final suggested = AuthValidators.accountIdFromEmail(
                    value.trim(),
                  );
                  if (suggested == 'studente') return;
                  _accountIdController.text = suggested;
                },
                validator: (value) => AuthValidators.emailError(
                  value,
                  taken: AuthStore.instance.emailsInUse(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ShakeWidget(
              trigger: _shakes.of(_accountIdController),
              child: _field(
                controller: _accountIdController,
                label: 'ID account',
                autocorrect: false,
                helperText: 'Come ti trovano gli altri: 3-20 caratteri',
                prefixIcon: Icons.tag,
                onChanged: (_) => _accountIdTouched = true,
                validator: (value) => AuthValidators.accountIdError(
                  value,
                  taken: AuthStore.instance.accountIdsInUse(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ShakeWidget(
              trigger: _shakes.of(_passwordController),
              child: PasswordField(
                controller: _passwordController,
                label: 'Password',
                autofillHints: const [AutofillHints.newPassword],
                onChanged: (_) => setState(() {}),
                validator: AuthValidators.passwordError,
              ),
            ),
            const SizedBox(height: 8),
            StrengthMeter(password: _passwordController.text),
            const SizedBox(height: 12),
            ShakeWidget(
              trigger: _shakes.of(_confirmController),
              child: PasswordField(
                controller: _confirmController,
                label: 'Conferma password',
                textInputAction: TextInputAction.done,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) => AuthValidators.confirmError(
                  value,
                  _passwordController.text,
                ),
              ),
            ),
            const SizedBox(height: 4),
            _TermsRow(
              accepted: _termsAccepted,
              onChanged: (value) => setState(() => _termsAccepted = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _schoolStep() {
    return Column(
      children: [
        for (final level in ContentRepository.instance.levels)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SchoolLevelTile(
              level: level,
              selected: _schoolId == level.id,
              onTap: () => setState(() => _schoolId = level.id),
            ),
          ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool autocorrect = true,
    List<String>? autofillHints,
    ValueChanged<String>? onChanged,
    String? helperText,
    IconData? prefixIcon,
  }) {
    final c = AppColors.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      autocorrect: autocorrect,
      autofillHints: autofillHints,
      onChanged: onChanged,
      validator: validator,
      decoration: AppTheme.fieldDecoration(c).copyWith(
        labelText: label,
        helperText: helperText,
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, color: c.textSecondary),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await AuthStore.instance.registerManual(
        name: _nameController.text,
        email: _emailController.text,
        accountId: _accountIdController.text,
        password: _passwordController.text,
        schoolLevelId: _schoolId,
        avatarId: _avatarId,
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      _tell(error.message);
      return;
    }
    if (!mounted) return;
    // La Home è la radice: il profilo è completo, scuola compresa.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _continueWithGoogle() async {
    final user = await signInWithGoogleDemo(context);
    if (user == null || !mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const SchoolPickerScreen(onboarding: true),
      ),
    );
  }

  void _tell(String message) {
    final c = AppColors.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: c.hard,
        ),
      );
  }
}

/// Checkbox dei Termini e della Privacy: il testo apre il foglio con le
/// condizioni, la spunta è ciò che il form pretende.
class _TermsRow extends StatelessWidget {
  final bool accepted;
  final ValueChanged<bool> onChanged;

  const _TermsRow({required this.accepted, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          key: const Key('terms-checkbox'),
          value: accepted,
          onChanged: (value) => onChanged(value ?? false),
          visualDensity: VisualDensity.compact,
        ),
        Expanded(
          child: GestureDetector(
            key: const Key('terms-open'),
            onTap: () => _showTerms(context),
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: AppText.label,
                    color: c.textSecondary,
                    height: 1.35,
                  ),
                  children: [
                    const TextSpan(text: 'Accetto i '),
                    TextSpan(
                      text: 'Termini e Condizioni',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: c.accent,
                      ),
                    ),
                    const TextSpan(text: ' e la '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: c.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Testo segnaposto: le condizioni reali le scrive chi è titolare del
  /// prodotto, non il codice.
  static void _showTerms(BuildContext context) {
    final c = AppColors.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            Text(
              'Termini e Condizioni, Privacy Policy',
              style: TextStyle(
                fontSize: AppText.titleMedium,
                fontWeight: FontWeight.w500,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _placeholder,
              style: TextStyle(
                fontSize: AppText.bodyMedium,
                color: c.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _placeholder =
      'Testo segnaposto. Qui vanno i Termini e le Condizioni e la Privacy '
      'Policy reali del servizio, con titolare del trattamento, base '
      'giuridica, dati raccolti, tempi di conservazione e recapiti.\n\n'
      'Nel frattempo è utile sapere che cosa fa l\'app: il profilo (nome, '
      'email, ID account, avatar) e i tuoi progressi di studio sono salvati '
      'solo su questo dispositivo, in memoria locale. Non viene inviato niente '
      'a server o a terzi e la password non viene conservata in chiaro: ne '
      'resta solo una derivata crittografica.';
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: AppText.titleSmall,
        fontWeight: FontWeight.w500,
        color: AppColors.of(context).textPrimary,
      ),
    );
  }
}

/// La testata indaco di «Creazione profilo»: il bordo in basso ondulato, la
/// freccia per uscire, «PASSO X DI 3», la barra che avanza e il titolo che
/// cambia in dissolvenza.
class _StepHeader extends StatelessWidget {
  final int step;
  final int steps;
  final String title;

  const _StepHeader({
    required this.step,
    required this.steps,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ClipPath(
      key: const Key('registration-header'),
      clipper: const WaveBottomClipper(),
      child: Container(
        width: double.infinity,
        color: c.headerBand,
        padding: const EdgeInsets.only(bottom: 52),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BackButton(color: c.onHeaderBand),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PASSO ${step + 1} DI $steps',
                        style: TextStyle(
                          fontSize: AppText.bodyLarge,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.7,
                          color: c.yellow,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: 220,
                        child: ProgressBar(
                          progress: (step + 1) / steps,
                          height: 14,
                        ),
                      ),
                      const SizedBox(height: 14),
                      AnimatedSwitcher(
                        duration: AppMotion.duration(context, AppMotion.medium),
                        switchInCurve: AppMotion.standard,
                        switchOutCurve: AppMotion.standard,
                        layoutBuilder: (current, previous) => Stack(
                          alignment: Alignment.centerLeft,
                          children: [...previous, ?current],
                        ),
                        child: Semantics(
                          key: ValueKey(title),
                          header: true,
                          child: Text(
                            title,
                            style: TextStyle(
                              fontFamily: AppText.headingFont,
                              fontSize: AppText.display,
                              fontWeight: FontWeight.w600,
                              color: c.onHeaderBand,
                            ),
                          ),
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
}
