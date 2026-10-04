import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../models/user_profile.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'app_button.dart';

/// Identità raccolta dal dialog dimostrativo di Google.
class GoogleIdentity {
  final String name;
  final String email;

  const GoogleIdentity({required this.name, required this.email});
}

/// Bottone «Accedi/Registrati con Google».
///
/// **Non è un accesso Google.** Non c'è rete nell'app, quindi il dialog chiede
/// nome ed email e crea l'account in locale: è una prova del flusso, non
/// un'identità verificata da Google.
class GoogleButton extends StatelessWidget {
  final String label;
  final Future<void> Function() onTap;

  const GoogleButton({super.key, required this.label, required this.onTap});

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
              const GoogleLogo(),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppText.titleSmall,
                  fontWeight: FontWeight.w500,
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

/// Dialog dimostrativo: nessuna credenziale richiesta.
///
/// Restituisce `null` se l'utente annulla.
Future<GoogleIdentity?> askGoogleIdentity(BuildContext context) async {
  final nameController = TextEditingController(text: 'Studente Google');
  final emailController = TextEditingController(text: 'studente@gmail.com');
  final c = AppColors.of(context);

  final result = await showDialog<GoogleIdentity>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Account Google (demo)'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Accedi con un profilo demo, nessuna credenziale richiesta.',
            style: TextStyle(fontSize: AppText.label, color: c.textSecondary),
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
        AppButton(
          label: 'Continua',
          height: 44,
          onPressed: () => Navigator.of(context).pop(
            GoogleIdentity(
              name: nameController.text.trim().isEmpty
                  ? 'Studente Google'
                  : nameController.text.trim(),
              email: emailController.text.trim().isEmpty
                  ? 'studente@gmail.com'
                  : emailController.text.trim(),
            ),
          ),
        ),
      ],
    ),
  );
  return result;
}

/// Apre il dialog dimostrativo e apre la sessione dell'account.
///
/// Restituisce l'account, o `null` se l'utente ha annullato: chi chiama
/// decide se dopo serve scegliere la scuola o andare a casa.
Future<UserProfile?> signInWithGoogleDemo(BuildContext context) async {
  final identity = await askGoogleIdentity(context);
  if (identity == null) return null;
  return AuthStore.instance.signUpWithGoogle(
    name: identity.name,
    email: identity.email,
  );
}

/// Logo Google a quattro segmenti, disegnato per non aggiungere asset.
class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: const _GoogleLogoPainter(),
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

/// La riga «Oppure … con» sopra [GoogleButton], nel login e nella registrazione.
class OrSeparator extends StatelessWidget {
  final String label;

  const OrSeparator({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        Expanded(child: Divider(color: c.border, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: TextStyle(fontSize: AppText.label, color: c.textSecondary),
          ),
        ),
        Expanded(child: Divider(color: c.border, height: 1)),
      ],
    );
  }
}
