import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../data/browse_store.dart';
import '../data/content_repository.dart';
import '../haptics.dart';
import '../screens/customization_screen.dart';
import '../theme/app_colors.dart';
import 'school_choice_sheet.dart';
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

/// La personalizzazione, nelle `actions` dell'header delle tre pagine
/// principali: è l'ultima a destra, quindi l'angolo dell'app.
///
/// Stessa icona e stesso tooltip su tutte e tre, e sta anche da ospite: sono
/// impostazioni dell'app, non del profilo.
class HeaderCustomizationButton extends StatelessWidget {
  const HeaderCustomizationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('header-customization'),
      icon: Icon(Icons.tune_rounded, color: AppColors.of(context).textPrimary),
      tooltip: 'Personalizzazione',
      onPressed: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const CustomizationScreen())),
    );
  }
}

/// Le altre scuole, nelle `actions` di Lezioni ed Esercizi, a sinistra della
/// lente: apre il foglio di scelta per una visita.
///
/// Sta solo dove c'è un profilo. L'ospite ha già il foglio dalla pillola, con
/// un altro testo, quindi qui non aggiungerebbe niente.
///
/// Se si guarda una scuola diversa da quella del profilo, l'icona cambia e
/// compare il nome: senza, la pagina sembrerebbe quella di sempre e i progressi
/// mostrati sarebbero quelli di un'altra scuola senza che lo si dica.
///
/// Il `Flexible` sta in cima, non attorno al nome: le `actions` dell'AppBar sono
/// una `Row` che dà larghezza illimitata ai figli, quindi è la riga dei bottoni
/// a dover cedere spazio, e solo lei può farlo. Serve quando la pagina porta
/// tre icone più il nome della scuola in visita: su un telefono stretto, senza,
/// la `Row` sborda a destra invece di troncare il nome.
class SchoolBrowseButton extends StatelessWidget {
  final SchoolChoiceDestination destination;

  const SchoolBrowseButton({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: ListenableBuilder(
        listenable: Listenable.merge([
          AuthStore.instance,
          BrowseStore.instance,
        ]),
        builder: (context, _) {
          if (AuthStore.instance.currentUser == null) {
            return const SizedBox.shrink();
          }
          final other = BrowseStore.instance.isBrowsingOtherSchool;
          final title =
              ContentRepository.instance
                  .levelById(BrowseStore.instance.levelId ?? '')
                  ?.title ??
              '';

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: const Key('header-school-browse'),
                icon: Icon(
                  other ? Icons.visibility_outlined : Icons.school_outlined,
                  color: other
                      ? AppColors.of(context).accent
                      : AppColors.of(context).textPrimary,
                ),
                tooltip: other ? 'Guardi $title' : 'Altre scuole',
                onPressed: () => _pick(context),
              ),
              if (other && title.isNotEmpty) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.of(context).accent,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    AppHaptics.selectionClick();
    final profileLevelId = AuthStore.instance.currentUser!.schoolLevelId;
    final chosen = await showSchoolChoiceSheet(
      context,
      destination: destination,
      signedIn: true,
      currentLevelId: BrowseStore.instance.levelId ?? profileLevelId,
    );
    if (chosen == null) return;
    // La scuola del profilo non è una visita: si torna alla vista di sempre
    // azzerando l'override, invece di scrivere un'id uguale a quella del
    // profilo che nessuno saprebbe più distinguere da una visita vera.
    if (chosen.id == profileLevelId) {
      BrowseStore.instance.reset();
    } else {
      BrowseStore.instance.browse(chosen.id);
    }
  }
}
