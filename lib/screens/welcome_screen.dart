import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../theme/app_colors.dart';
import 'registration_screen.dart';
import 'school_picker_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.background,
        actions: const [],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const _WelcomeHero(),
          const SizedBox(height: 28),
          Text(
            'Crea il tuo profilo',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Raccontaci quale scuola frequenti e ti proponiamo le lezioni '
            'guidate e gli esercizi più adatti a te.',
            style: TextStyle(
              fontSize: 15,
              color: c.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          _GoogleButton(
            onTap: () => _continueWithGoogle(context),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const RegistrationScreen(),
              ),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: c.accent,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Registrati con email'),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Scopri come ospite',
                style: TextStyle(
                  fontSize: 15,
                  color: c.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Il tuo profilo è salvato solo su questo dispositivo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: c.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _continueWithGoogle(BuildContext context) async {
    final identity = await _askGoogleIdentity(context);
    if (identity == null) return;
    await AuthStore.instance.signUpWithGoogle(
      name: identity.$1,
      email: identity.$2,
      schoolLevelId: '',
    );
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SchoolPickerScreen(
          onSaved: () => _goToHome(context),
        ),
      ),
    );
  }

  static void _goToHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF007AFF), Color(0xFF5C6BC0)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.calculate_outlined,
              size: 30,
              color: Color(0xFF007AFF),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Math App\nStudia con noi',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback onTap;

  const _GoogleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _GoogleLogo(),
              const SizedBox(width: 12),
              Text(
                'Continua con Google',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(22, 22),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const stroke = 3.2;
    final radius = size.width / 2 - stroke / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const gap = 0.12;
    const sweep = (3.14159 / 2) - gap;

    const segments = <(double, double, Color)>[
      (0.0, sweep, _blue),
      (3.14159 / 2 + gap / 2, sweep, _red),
      (3.14159 + gap, sweep, _yellow),
      (3 * 3.14159 / 2 + 3 * gap / 2, sweep, _green),
    ];

    for (final (start, sweep, color) in segments) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, start - 3.14159 / 2, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Future<(String, String)?> _askGoogleIdentity(BuildContext context) async {
  final nameController = TextEditingController(text: 'Studente Google');
  final emailController = TextEditingController(text: 'studente@gmail.com');
  final c = AppColors.of(context);

  final result = await showDialog<(String, String)>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Account Google (demo)'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Accedi con un profilo demo, nessuna credenziale richiesta.',
            style: TextStyle(fontSize: 13, color: c.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Nome'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            (
              nameController.text.trim().isEmpty
                  ? 'Studente Google'
                  : nameController.text.trim(),
              emailController.text.trim().isEmpty
                  ? 'studente@gmail.com'
                  : emailController.text.trim(),
            ),
          ),
          child: const Text('Continua'),
        ),
      ],
    ),
  );
  return result;
}