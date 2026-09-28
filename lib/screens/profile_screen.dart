import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import '../data/auth_store.dart';
import '../data/content_repository.dart';
import '../data/settings_store.dart';
import '../models/user_profile.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';
import 'school_picker_screen.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListenableBuilder(
        listenable: AuthStore.instance,
        builder: (context, _) {
          final user = AuthStore.instance.currentUser;
          if (user == null) {
            return _GuestProfile(onCreate: () => _openWelcome(context));
          }
          return _ProfileContent(user: user);
        },
      ),
    );
  }

  void _openWelcome(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const WelcomeScreen()));
  }
}

class _GuestProfile extends StatelessWidget {
  final VoidCallback onCreate;

  const _GuestProfile({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: c.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_outline, size: 44, color: c.accent),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            'Nessun profilo',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Crea il tuo profilo per ricevere lezioni ed esercizi '
            'consigliati per la tua scuola.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: c.textSecondary, height: 1.4),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: onCreate,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: c.accent,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: const Text('Crea il tuo profilo'),
        ),
        const SizedBox(height: 24),
        const _ThemeToggle(),
      ],
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final UserProfile user;

  const _ProfileContent({required this.user});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final level = ContentRepository.instance.levelById(user.schoolLevelId);
    final levelColor = level == null ? c.accent : _colorFor(c, level.icon);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: levelColor.withValues(alpha: 0.14),
              child: Text(
                _initials(user.name),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: levelColor,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: c.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _AuthChip(
              label: user.authMethod == AuthMethod.google ? 'Google' : 'Email',
              icon: user.authMethod == AuthMethod.google
                  ? Icons.g_mobiledata
                  : Icons.alternate_email,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: levelColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    level == null ? Icons.help_outline : _iconFor(level.icon),
                    size: 16,
                    color: levelColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    level?.title ?? 'Scuola non impostata',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: levelColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _ThemeToggle(),
        const SizedBox(height: 12),
        AppCard(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  SchoolPickerScreen(initialLevelId: user.schoolLevelId),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.school_outlined, color: c.indigo),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Cambia la tua scuola',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: c.textSecondary),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          onTap: () => _signOut(context),
          color: c.surface,
          child: Row(
            children: [
              Icon(Icons.logout, color: c.hard),
              const SizedBox(width: 12),
              Text(
                'Esci',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: c.hard,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await AuthStore.instance.signOut();
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'school':
        return Icons.school_outlined;
      case 'account_balance':
        return Icons.account_balance_outlined;
      case 'menu_book':
        return Icons.menu_book_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  Color _colorFor(AppPalette c, String name) {
    switch (name) {
      case 'school':
        return c.accent;
      case 'account_balance':
        return c.purple;
      case 'menu_book':
        return c.teal;
      default:
        return c.accent;
    }
  }
}

class _AuthChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _AuthChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.accentSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: c.accent),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeToggle extends StatefulWidget {
  const _ThemeToggle();

  @override
  State<_ThemeToggle> createState() => _ThemeToggleState();
}

class _ThemeToggleState extends State<_ThemeToggle>
    with SingleTickerProviderStateMixin {
  static const _asset = 'assets/animations/toggle.json';
  static const _dayIdle = 'Day Idle';
  static const _nightIdle = 'Night Idle';
  static const _toNight = 'Day to Night';
  static const _toDay = 'Night to Day';
  static const _idleLoops = 3;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  LottieComposition? _composition;
  bool _animating = false;

  bool get _isDark => SettingsStore.instance.themeMode == ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final composition = await AssetLottie(_asset).load();
    if (!mounted) return;
    setState(() {
      _composition = composition;
      _controller.duration = composition.duration;
    });
    _playIdle();
  }

  Marker? _marker(String name) => _composition?.getMarker(name);

  void _playIdle() {
    final idle = _marker(_isDark ? _nightIdle : _dayIdle);
    if (idle == null) return;
    _controller.repeat(min: idle.start, max: idle.end, count: _idleLoops);
  }

  void _onToggle() {
    if (_animating) return;
    HapticFeedback.selectionClick();
    final next = _isDark ? ThemeMode.light : ThemeMode.dark;
    unawaited(SettingsStore.instance.setThemeMode(next));
    final transition = _marker(next == ThemeMode.dark ? _toNight : _toDay);
    if (transition == null) return;
    _animating = true;
    final total = _controller.duration!.inMilliseconds;
    _controller
        .animateTo(
          transition.end,
          duration: Duration(
            milliseconds: ((transition.end - transition.start) * total).round(),
          ),
        )
        .whenComplete(() {
          if (!mounted) return;
          _animating = false;
          _playIdle();
        });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ListenableBuilder(
      listenable: SettingsStore.instance,
      builder: (context, _) {
        final isDark = _isDark;
        final composition = _composition;
        return AppCard(
          child: Row(
            children: [
              Icon(Icons.dark_mode_outlined, color: c.medium),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tema scuro',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
              ),
              if (composition == null)
                Switch(
                  value: isDark,
                  activeThumbColor: c.accent,
                  onChanged: (_) => _onToggle(),
                )
              else
                Semantics(
                  label: 'Tema scuro',
                  button: true,
                  toggled: isDark,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _onToggle,
                    child: SizedBox(
                      key: const Key('theme-toggle-animation'),
                      width: 88,
                      height: 48,
                      child: Lottie(
                        composition: composition,
                        controller: _controller,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
