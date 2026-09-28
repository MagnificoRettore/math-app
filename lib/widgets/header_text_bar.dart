import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Margine laterale della riga dell'header: 12px per lato, così il campo e
/// l'avatar mangiano il minimo di schermo. Con `actions` vuoto l'`AppBar`
/// usa `titleSpacing` anche come margine destro, quindi una sola costante
/// governa i due lati.
const double kHeaderHorizontalMargin = 30;

/// Altezza del campo di ricerca nella riga dell'header.
const double kHeaderTextFieldHeight = 56;

/// Altezza della riga dell'header delle pagine principali: deve contenere il
/// campo da [kHeaderTextFieldHeight] con un po' di aria sopra e sotto. La
/// Home la usa anche senza il campo, per ospitare l'avitratto da
/// [kProfileAvatarSize] alla stessa misura delle altre pagine.
const double kHeaderToolbarHeight = 80;

/// Campo di ricerca nella riga dell'header: per ora non fa niente, accetta
/// solo di ricevere testo. Sta sulla stessa riga dell'icona del profilo e
/// occupa lo spazio che resta.
class HeaderTextBar extends StatelessWidget {
  const HeaderTextBar({super.key, this.hintText = 'Cerca…'});

  final String hintText;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    const radius = BorderRadius.all(Radius.circular(28));
    return SizedBox(
      height: kHeaderTextFieldHeight,
      child: TextField(
        key: const Key('header-text-field'),
        decoration: InputDecoration(
          hintText: hintText,
          filled: true,
          fillColor: c.surface,
          hintStyle: TextStyle(color: c.textSecondary),
          isDense: true,
          prefixIcon: Icon(Icons.search, color: c.textSecondary, size: 20),
          // Il vincolo tiene il campo entro i 56px: il default (48x48, o
          // peggio l'icona da sola) spingerebbe l'altezza interna fuori dal
          // SizedBox e il testo resterebbe schiacciato.
          prefixIconConstraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: c.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: c.accent),
          ),
        ),
      ),
    );
  }
}
