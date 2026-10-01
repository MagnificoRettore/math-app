import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../data/content_repository.dart';
import '../data/progress_store.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';
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
import 'customization_screen.dart';
import 'mission_screen.dart';
import 'welcome_screen.dart';

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
        actions: [
          const HeaderSearchButton(),
          IconButton(
            key: const Key('home-customization'),
            icon: Icon(
              Icons.tune_rounded,
              color: AppColors.of(context).textPrimary,
            ),
            tooltip: 'Personalizzazione',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CustomizationScreen()),
            ),
          ),
        ],
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                const JumpBackInSection(),
                const ImageCarousel(),
                const SizedBox(height: 20),
                MissionHero(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MissionScreen()),
                  ),
                ),
                const SizedBox(height: 20),
                const StreakCard(),
                if (user != null) ...[
                  const SizedBox(height: 16),
                  RecommendedSection(user: user),
                ] else ...[
                  const SizedBox(height: 16),
                  _buildGuestCard(context),
                ],
                const SizedBox(height: 8),
                const WeakTopicsSection(),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildGuestCard(BuildContext context) {
    final c = AppColors.of(context);
    return AppCard(
      onTap: () =>
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const WelcomeScreen())),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.indigo.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.person_outline, color: c.indigo, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Crea il tuo profilo per ricevere lezioni ed esercizi '
              'consigliati per la tua scuola.',
              style: TextStyle(fontSize: 14, color: c.textPrimary, height: 1.3),
            ),
          ),
          Icon(Icons.chevron_right, color: c.textSecondary),
        ],
      ),
    );
  }
}
