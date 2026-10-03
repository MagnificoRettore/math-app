import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../data/content_repository.dart';
import '../data/progress_store.dart';
import '../widgets/main_header.dart';
import '../widgets/home_greeting.dart';
import '../widgets/image_carousel.dart';
import '../widgets/jump_back_in_section.dart';
import '../widgets/mission_hero.dart';
import '../widgets/pill_nav_bar.dart';
import '../widgets/profile_button.dart';
import '../widgets/recommended_section.dart';
import '../widgets/streak_card.dart';
import '../widgets/weak_topics_section.dart';
import 'mission_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: kHeaderToolbarHeight,
        titleSpacing: kHeaderHorizontalMargin,
        centerTitle: false,
        title: const Row(
          children: [
            ProfileButton(),
            SizedBox(width: 12),
            Expanded(child: HomeGreeting()),
          ],
        ),
        // Le due righe del saluto riempiono la riga da sinistra: a destra ci
        // sono la lente e le impostazioni, non una seconda copia del profilo
        // che sta già a sinistra. La lente viene prima dell'icona di
        // Personalizzazione perché cercare è l'azione più frequente.
        actionsPadding: kHeaderActionsPadding,
        actions: const [HeaderSearchButton(), HeaderCustomizationButton()],
      ),
      body: PillNavOverlay(selected: PillTab.home, child: _buildHomeTab()),
    );
  }

  Widget _buildHomeTab() {
    final levels = ContentRepository.instance.levels;
    if (levels.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListenableBuilder(
      listenable: AuthStore.instance,
      builder: (context, _) {
        final user = AuthStore.instance.currentUser;
        return ListenableBuilder(
          listenable: ProgressStore.instance,
          builder: (context, _) {
            return ListView(
              // Le sezioni si distanziano di 24: il ritmo è della pagina, non
              // di ogni widget, quindi il `SizedBox` sta qui e non dentro le
              // sezioni. Il primo e l'ultimo invece sono padding.
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                const JumpBackInSection(),
                const ImageCarousel(),
                const SizedBox(height: 24),
                MissionHero(
                  showShortcuts: true,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MissionScreen()),
                  ),
                ),
                const SizedBox(height: 24),
                const StreakCard(),
                // La sezione dei consigli è una sola: da ospite non cambia
                // disegno, cambia il contenuto (l'invito a creare il profilo).
                const SizedBox(height: 24),
                RecommendedSection(user: user),
                const WeakTopicsSection(),
              ],
            );
          },
        );
      },
    );
  }
}
