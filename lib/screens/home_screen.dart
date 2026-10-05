import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../data/content_repository.dart';
import '../theme/app_motion.dart';
import '../widgets/argomento_carousel.dart';
import '../widgets/jump_back_in_card.dart';
import '../widgets/math_fact_card.dart';
import '../widgets/main_header.dart';
import '../widgets/mission_hero.dart';
import '../widgets/pill_nav_bar.dart';
import '../widgets/streak_chip.dart';
import 'mission_screen.dart';

/// La Home. Al primo caricamento le sezioni entrano in sequenza (stagger):
/// ognuna con una dissolvenza e una piccola salita, [AppMotion.stagger] dopo
/// la precedente. Una volta sola: la lista ricrea le sezioni che rientrano
/// scorrendo, e quelle ricreate dopo l'entrata partono già al loro posto.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Di quanto, in frazione della propria altezza, una sezione sale entrando.
  static const double _rise = 0.06;

  /// `true` appena una sezione ha finito di entrare: un `Animate` creato
  /// dopo parte già alla fine, mentre quelli in corsa finiscono la loro
  /// strada.
  bool _entered = false;

  /// Un rebuild solo, alla prima sezione entrata: la lista tiene i widget
  /// dell'ultimo build, e senza quelle che rientrano scorrendo ripartirebbero
  /// da zero.
  void _onEntered() {
    if (_entered || !mounted) return;
    setState(() => _entered = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainHeaderAppBar(
        title: const MainHeaderTitle(),
        actions: const [HeaderStreakChip(), HeaderCustomizationButton()],
      ),
      body: PillNavOverlay(selected: PillTab.home, child: _buildHomeTab()),
    );
  }

  /// La sezione [index]-esima dentro la sua entrata. Col movimento ridotto
  /// niente entrata: la sezione è già lì.
  Widget _enter(BuildContext context, int index, Widget section) {
    if (AppMotion.reduced(context)) return section;
    // Il ritardo sta negli effetti e non in `Animate.delay`, che aspetta con
    // un `Future.delayed` non cancellabile: negli effetti fa parte della
    // corsa del controller, che si ferma col widget.
    final delay = AppMotion.stagger * index;
    return section
        .animate(
          autoPlay: !_entered,
          value: _entered ? 1 : 0,
          onComplete: (_) => _onEntered(),
        )
        .fadeIn(
          delay: delay,
          duration: AppMotion.slow,
          curve: AppMotion.standard,
        )
        .slideY(
          delay: delay,
          begin: _rise,
          end: 0,
          duration: AppMotion.slow,
          curve: AppMotion.standard,
        );
  }

  Widget _buildHomeTab() {
    final levels = ContentRepository.instance.levels;
    if (levels.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Ogni sezione si ascolta da sé (serie, carosello), quindi la lista non
    // ha store da seguire.
    return ListView(
      // Le sezioni si distanziano di 24: il ritmo è della pagina, non di ogni
      // widget, quindi il `SizedBox` sta qui e non dentro le sezioni. Il primo
      // e l'ultimo invece sono padding. Il carosello porta la sua testata, che
      // ha già i 24 sopra: senza argomenti sparisce con lei.
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _enter(context, 0, const JumpBackInCard()),
        _enter(context, 1, const ArgomentoCarousel()),
        const SizedBox(height: 24),
        _enter(
          context,
          2,
          MissionHero(
            showShortcuts: true,
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const MissionScreen())),
          ),
        ),
        const SizedBox(height: 24),
        _enter(context, 3, const MathFactCard()),
      ],
    );
  }
}
