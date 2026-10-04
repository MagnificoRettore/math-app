import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../models/user_profile.dart';

/// Simboli proposti all'utente al posto di una foto.
///
/// L'app non ha rete, quindi l'avatar non si carica da nessuna parte: si
/// sceglie fra questi e si salva il **nome** del simbolo
/// (`UserProfile.avatarId`), non il valore [IconData]. I colori li decide la
/// piastra, non il simbolo.
const List<String> avatarOptions = <String>[
  'rocket_launch_rounded',
  'science_rounded',
  'calculate_rounded',
  'menu_book_rounded',
  'school_rounded',
  'palette_rounded',
  'code_rounded',
  'psychology_rounded',
  'pets_rounded',
  'music_note_rounded',
  'sports_soccer_rounded',
  'bolt_rounded',
];

const Map<String, IconData> _avatarIcons = <String, IconData>{
  'rocket_launch_rounded': Symbols.rocket_launch_rounded,
  'science_rounded': Symbols.science_rounded,
  'calculate_rounded': Symbols.calculate_rounded,
  'menu_book_rounded': Symbols.menu_book_rounded,
  'school_rounded': Symbols.school_rounded,
  'palette_rounded': Symbols.palette_rounded,
  'code_rounded': Symbols.code_rounded,
  'psychology_rounded': Symbols.psychology_rounded,
  'pets_rounded': Symbols.pets_rounded,
  'music_note_rounded': Symbols.music_note_rounded,
  'sports_soccer_rounded': Symbols.sports_soccer_rounded,
  'bolt_rounded': Symbols.bolt_rounded,
};

/// Nome del simbolo in [avatarOptions] → icona. Un nome sconosciuto (profilo
/// salvato da un'altra versione) cade sulla persona.
IconData avatarIcon(String name) =>
    _avatarIcons[name] ?? Symbols.person_rounded;

/// Iniziali del nome: prima lettera e iniziale del cognome, cioè la prima e
/// l'ultima parte.
String initialsOf(String name) {
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

/// Avatar tondo del profilo: foto se c'è, simbolo se scelto, iniziali se
/// nessuno dei due.
///
/// Sta in un widget perché le tre schermate che mostrano l'avatar (header,
/// profilo, anteprima del login) devono cadere sulla stessa identità: prima
/// le iniziali erano calcolate in due punti diversi.
class ProfileAvatar extends StatelessWidget {
  final UserProfile user;
  final double size;
  final Color color;
  final Color plateColor;

  const ProfileAvatar({
    super.key,
    required this.user,
    required this.size,
    required this.color,
    required this.plateColor,
  });

  @override
  Widget build(BuildContext context) {
    final photo = user.photoUrl?.trim() ?? '';
    final avatar = user.avatarId.trim();

    Widget content;
    if (photo.isNotEmpty) {
      content = Image.network(
        photo,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(),
      );
    } else if (avatar.isNotEmpty) {
      content = Icon(avatarIcon(avatar), size: size * 0.44, color: color);
    } else {
      content = _fallback();
    }

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Container(color: plateColor, child: content),
      ),
    );
  }

  Widget _fallback() {
    return Center(
      child: Text(
        initialsOf(user.name),
        style: TextStyle(
          fontSize: size * 0.3,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
