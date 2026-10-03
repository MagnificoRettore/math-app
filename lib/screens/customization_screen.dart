import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/settings_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/app_card.dart';
import '../widgets/theme_toggle.dart';

const _hapticsSwitch = Key('haptics-switch');

/// Personalizzazione: tema e vibrazioni.
///
/// Si apre dall'icona in alto a destra della Home, quindi è a portata di mano
/// per l'ospite come per l'utente registrato: sono impostazioni dell'app, non
/// del profilo.
class CustomizationScreen extends StatelessWidget {
  const CustomizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personalizzazione')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: SettingsStore.instance,
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: const [
                _Label('Aspetto'),
                ThemeToggle(),
                _Label('Risposta'),
                _HapticsCard(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppText.label,
          fontWeight: FontWeight.w600,
          color: c.textSecondary,
        ),
      ),
    );
  }
}

class _HapticsCard extends StatelessWidget {
  const _HapticsCard();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AppCard(
      child: Row(
        children: [
          Icon(Icons.vibration, color: c.indigo),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vibrazioni',
                  style: TextStyle(
                    fontSize: AppText.bodyLarge,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Una scossa breve quando la risposta è giusta o sbagliata.',
                  style: TextStyle(
                    fontSize: AppText.label,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // L'interruttore si ascolta da sé: la card è `const` nella lista della
          // pagina, quindi Flutter la salta quando il padre si ricostruisce con
          // la stessa istanza canonicizzata, e la notifica del padre non basta
          // a girare lo switch.
          ListenableBuilder(
            listenable: SettingsStore.instance,
            builder: (context, _) {
              return Switch(
                key: _hapticsSwitch,
                value: SettingsStore.instance.hapticsEnabled,
                activeThumbColor: c.accent,
                onChanged: (value) {
                  // Il tasto che spegne le vibrazioni vibra comunque: è l'unico
                  // modo di sentire che l'opzione è stata ricevuta.
                  HapticFeedback.selectionClick();
                  SettingsStore.instance.setHapticsEnabled(value);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
