import 'package:flutter/material.dart';

import '../data/settings_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'home_screen.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';

/// La guida all'app: si apre al primo avvio e poi dalle impostazioni
/// (Personalizzazione → «Guida all'app»).
///
/// Al primo avvio ([fromSettings] falso) finire o saltare segna la guida come
/// vista e porta alla Home; dalle impostazioni si torna solo indietro e non si
/// tocca niente.
class OnboardingScreen extends StatefulWidget {
  final bool fromSettings;

  const OnboardingScreen({super.key, this.fromSettings = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const List<({String image, String title, String body})> _slides = [
    (
      image: 'assets/guide/home.png',
      title: 'Tre sezioni',
      body:
          'In basso trovi Lezioni, Home ed Esercizi. Ci passi toccando la '
          'barra o scorrendo a destra e a sinistra. Con la lente cerchi un '
          'argomento o una lezione, con l\'ingranaggio cambi le impostazioni.',
    ),
    (
      image: 'assets/guide/argomenti.png',
      title: 'Argomenti e lezioni',
      body:
          'Ogni anno di scuola ha i suoi argomenti, per esempio «Equazioni '
          'di primo grado». Un argomento raccoglie più lezioni da seguire in '
          'ordine, e un\'altra scuola puoi sempre visitarla senza cambiare '
          'il tuo profilo.',
    ),
    (
      image: 'assets/guide/lezione.png',
      title: 'Come è fatta una lezione',
      body:
          'Una lezione è una fila di card da scorrere: spiegazione con '
          'formule e grafici, domande a risposta multipla e la card «Prova '
          'tu» con esercizi da risolvere. Se sbagli più volte ti consigliamo '
          'di rileggere. Sull\'ultima card tocca «Completa la lezione».',
    ),
    (
      image: 'assets/guide/lezioni.png',
      title: 'I tuoi progressi',
      body:
          'Le lezioni completate si segnano con una spunta verde, e un '
          'argomento è completato quando lo sono tutte le sue lezioni. I '
          'progressi sono legati al tuo profilo, o all\'ospite se non hai '
          'un account.',
    ),
    (
      image: 'assets/guide/esercizi.png',
      title: 'Esercizi e strumenti',
      body:
          'Gli esercizi sono risolti passo passo, alcuni a domande guidate: '
          'segnali come padroneggiati o da ripassare e ritrovi i punti deboli '
          'dalla Home. In lezione e negli esercizi hai a portata di mano la '
          'calcolatrice scientifica.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (widget.fromSettings) {
      Navigator.of(context).pop();
      return;
    }
    await SettingsStore.instance.completeOnboarding();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const HomeScreen(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Future<void> _skip() async {
    await _finish();
  }

  void _next() {
    if (_page >= _slides.length - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    const slides = _slides;
    final isLast = _page >= slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _skip,
                    child: Text(
                      isLast ? '' : (widget.fromSettings ? 'Chiudi' : 'Salta'),
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: AppText.bodyMedium,
                      ),
                    ),
                  ),
                  const Spacer(),
                  for (var i = 0; i < slides.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.only(right: 6),
                      width: i == _page ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page ? c.accent : c.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [for (final slide in slides) _buildSlide(slide)],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: AppButton(
                label: isLast
                    ? (widget.fromSettings ? 'Ho capito' : 'Inizia')
                    : 'Avanti',
                onPressed: _next,
                expand: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(({String image, String title, String body}) slide) {
    final c = AppColors.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Una schermata vera dell'app, istantanea del momento: non si
            // aggiorna da sola (vedi `tool/capture_guide_test.dart`).
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kCardRadius),
                boxShadow: cardShadow(c),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(kCardRadius),
                child: Image.asset(
                  slide.image,
                  height: MediaQuery.sizeOf(context).height * 0.4,
                  excludeFromSemantics: true,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              slide.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppText.headingFont,
                fontSize: AppText.headline,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              slide.body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppText.bodyLarge,
                height: 1.5,
                color: c.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
