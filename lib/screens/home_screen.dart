import 'dart:async';

import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../data/content_repository.dart';
import '../data/progress_store.dart';
import '../data/search_index.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';
import '../widgets/mission_hero.dart';
import '../widgets/pill_nav_bar.dart';
import '../widgets/recommended_section.dart';
import '../widgets/streak_card.dart';
import '../widgets/weak_topics_section.dart';
import 'bookmarks_screen.dart';
import 'mission_screen.dart';
import 'search_results_screen.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matematica'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.bookmark_outline, color: c.textPrimary),
            tooltip: 'Segnalibri',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const BookmarksScreen())),
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
                MissionHero(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MissionScreen()),
                  ),
                ),
                const SizedBox(height: 20),
                _buildSearchBar(),
                const SizedBox(height: 12),
                const StreakCard(),
                if (user != null) ...[
                  const SizedBox(height: 16),
                  RecommendedSection(user: user),
                ] else ...[
                  const SizedBox(height: 16),
                  _buildGuestCard(),
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

  Widget _buildGuestCard() {
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

  Widget _buildSearchBar() {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        onSubmitted: _performSearch,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Cerca argomenti, formule, esercizi…',
          prefixIcon: Icon(Icons.search, color: c.textSecondary),
          filled: true,
          fillColor: c.surface,
          hintStyle: TextStyle(color: c.textSecondary),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: c.border),
          ),
        ),
      ),
    );
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) return;
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _performSearch(value),
    );
  }

  void _performSearch(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) return;
    final result = SearchIndex.instance.search(query);
    if (result.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchResultsScreen(query: query, results: result),
      ),
    );
    _searchController.clear();
  }
}
