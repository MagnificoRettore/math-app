import 'dart:math';

import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../models/user_profile.dart';
import '../screens/profile_screen.dart';
import '../theme/app_colors.dart';

/// Dimensione massima del font del saluto: per nomi lunghi il testo
/// viene ridimensionato in modo automatico, senza mai superare questo limite.
const double kGreetingMaxFontSize = 20;

const List<String> _guestGreetings = [
  'Benvenuto!',
  'Bentornato!',
  'Ciao!',
  'Buono studio!',
  'Pronto a studiare?',
  'Welcome!',
  'Welcome back!',
  "Let's learn!",
  'Ready to learn?',
  'Hi there!',
];

const List<String> _namedGreetings = [
  'Ciao {name}, cosa studiamo oggi?',
  'Pronto a studiare, {name}?',
  'Ciao {name}, buono studio!',
  'Bentornato, {name}!',
  'Ciao {name}!',
  'Hi {name}, ready to learn?',
  'Welcome back, {name}!',
  "Let's go, {name}!",
  'Hi {name}!',
];

class HomeGreeting extends StatefulWidget {
  const HomeGreeting({super.key});

  @override
  State<HomeGreeting> createState() => _HomeGreetingState();
}

class _HomeGreetingState extends State<HomeGreeting> {
  final int _seed = Random().nextInt(1 << 31);

  String _fill(String template, String name) =>
      name.isEmpty ? template : template.replaceAll('{name}', name);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthStore.instance,
      builder: (context, _) {
        final user = AuthStore.instance.currentUser;
        final name = user?.name.trim() ?? '';
        final hasName = user != null && name.isNotEmpty;
        final templates = hasName ? _namedGreetings : _guestGreetings;
        final candidates = [
          for (var i = 0; i < templates.length; i++)
            _fill(templates[(_seed + i) % templates.length], name),
        ];
        return Row(
          children: [
            if (user != null) ...[
              _ProfileAvatar(user: user),
              const SizedBox(width: 12),
            ],
            Expanded(child: _GreetingText(candidates: candidates)),
          ],
        );
      },
    );
  }
}

class _GreetingText extends StatelessWidget {
  const _GreetingText({required this.candidates});

  final List<String> candidates;

  TextStyle _style(AppPalette c) => TextStyle(
    fontSize: kGreetingMaxFontSize,
    fontWeight: FontWeight.w600,
    color: c.textPrimary,
  );

  double _width(String text, TextStyle style, TextScaler scaler) {
    return (TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      textScaler: scaler,
    )..layout())
        .width;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final style = _style(c);
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : double.infinity;
        final fitting = candidates.firstWhere(
          (text) => _width(text, style, scaler) <= maxWidth,
          orElse: () => candidates.reduce(
            (a, b) =>
                _width(a, style, scaler) <= _width(b, style, scaler) ? a : b,
          ),
        );
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            fitting,
            key: const Key('home-greeting'),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        );
      },
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.user});

  final UserProfile user;

  String _initialsOf(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    String first(String value) {
      final runes = value.runes;
      return runes.isEmpty ? '' : String.fromCharCode(runes.first);
    }

    if (parts.length == 1) return first(parts.first).toUpperCase();
    return '${first(parts.first)}${first(parts.last)}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final photo = user.photoUrl?.trim() ?? '';
    return InkWell(
      key: const Key('home-profile-avatar'),
      customBorder: const CircleBorder(),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      ),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c.accentSoft,
          border: Border.all(color: c.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: photo.isEmpty
            ? _Initials(initials: _initialsOf(user.name))
            : Image.network(
                photo,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    _Initials(initials: _initialsOf(user.name)),
              ),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: c.accent,
        ),
      ),
    );
  }
}