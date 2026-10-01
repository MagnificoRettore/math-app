import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'search_overlay.dart';

/// Margine laterale della riga dell'header: 30px a sinistra, il lato destro lo
/// dà `actionsPadding`. Un solo numero per i tre header principali.
const double kHeaderHorizontalMargin = 30;

/// Altezza della riga dell'header delle pagine principali: ospita l'avatar da
/// `kProfileAvatarSize` (`profile_button.dart`) e le icone a destra alla stessa
/// misura, con aria sopra e sotto.
const double kHeaderToolbarHeight = 80;

/// Margine destro delle icone dell'header.
const EdgeInsets kHeaderActionsPadding = EdgeInsets.only(right: 12);

/// La lente della ricerca, nelle `actions` dell'header delle tre pagine
/// principali. Toccarla apre `showSearchOverlay`: una sovrapposizione a tutta
/// pagina, non una nuova pagina da attraversare per tornare indietro.
class HeaderSearchButton extends StatelessWidget {
  const HeaderSearchButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('header-search'),
      icon: Icon(
        Icons.search_rounded,
        color: AppColors.of(context).textPrimary,
      ),
      tooltip: 'Cerca',
      onPressed: () => showSearchOverlay(context),
    );
  }
}
