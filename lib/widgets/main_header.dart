import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../data/browse_store.dart';
import '../data/content_repository.dart';
import '../haptics.dart';
import '../screens/customization_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'pill_nav_bar.dart';
import 'profile_button.dart';
import 'profile_summary.dart';
import 'reveal.dart';
import 'school_choice_sheet.dart';
import 'search_overlay.dart';
import 'streak_chip.dart';

/// Margine laterale della riga dell'header: 30px a sinistra, il lato destro lo
/// dà `actionsPadding`. Un solo numero per i tre header principali.
const double kHeaderHorizontalMargin = 30;

/// Altezza della riga dell'header delle pagine principali: ospita l'avatar da
/// `kProfileAvatarSize` (50) e le icone a destra alla stessa misura, con aria
/// sopra e sotto.
const double kHeaderToolbarHeight = 80;

/// Margine destro delle icone dell'header.
const EdgeInsets kHeaderActionsPadding = EdgeInsets.only(right: 12);

/// Raggio degli angoli in basso della banda: sono smussati, i due in alto no,
/// perché in alto la banda è appoggiata al bordo dello schermo.
const double kHeaderBottomRadius = 28;

/// Il `title` degli header delle tre pagine principali: l'identità a sinistra,
/// con l'avatar e il suo badge, e il nome e la scuola che occupano il resto.
///
/// L'indaco non è qui ma sull'`AppBar` che contiene questa riga: è una banda di
/// marca che parte dai due bordi dello schermo e li attraversa tutti, non una
/// pilla con i bordi curvi dentro una pagina colorata. Le icone sono nella stessa
/// banda, nelle `actions`, e quindi bianche come il testo.
///
/// Il nome trunca quando le icone sono tre e lo spazio è poco: su 360px in
/// visita è il nome a cedere, non le icone.
///
/// [levelId] è il livello della pagina, che serve solo da ospite: senza un
/// profilo la visita non esiste (`BrowseStore.levelId` è `null` per contratto)
/// e la riga della scuola verrebbe vuota anche se Lezioni ed Esercizi sanno
/// benissimo quale scuola stanno mostrando.
class MainHeaderTitle extends StatelessWidget {
  final String? levelId;

  const MainHeaderTitle({super.key, this.levelId});

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('header-identity'),
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const ProfileButton(),
        const SizedBox(width: 12),
        // La `Row` dell'`AppBar` non dà larghezza illimitata ai figli, quindi
        // il testo va in `Expanded` per arrivare fino alle icone.
        Expanded(child: ProfileSummary(levelId: levelId)),
      ],
    );
  }
}

/// L'`AppBar` dei tre header principali.
///
/// L'indaco è dell'`AppBar`, che parte dai due bordi dello schermo e li attraversa
/// tutti, e i due angoli in basso sono smussati dal suo `shape`: sotto gli
/// angoli si vede lo sfondo della pagina.
///
/// [bottom] (i `YearTabs` di Lezioni ed Esercizi) sta **sotto** la banda e non
/// nell'`AppBar.bottom`, che lo dipingerebbe d'indaco: il colore è solo della
/// riga dell'header. L'`AppBar` sta in un `Expanded` perché dentro una `Column`
/// senza limite di altezza il suo layout non si chiude.
///
/// [showBack] mette la freccia indietro prima dell'identità: serve alle
/// sotto-pagine che tengono la banda (la pagina di un argomento), dove su iOS
/// e sul web non c'è un back di sistema.
class MainHeaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final PreferredSizeWidget? bottom;
  final List<Widget> actions;
  final bool showBack;

  const MainHeaderAppBar({
    super.key,
    this.title,
    this.bottom,
    this.actions = const <Widget>[],
    this.showBack = false,
  });

  @override
  Size get preferredSize => Size.fromHeight(
    kHeaderToolbarHeight + (bottom?.preferredSize.height ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final bottom = this.bottom;
    return Column(
      children: [
        Expanded(
          child: AppBar(
            automaticallyImplyLeading: false,
            toolbarHeight: kHeaderToolbarHeight,
            leading: showBack ? BackButton(color: c.textPrimary) : null,
            // Con la freccia il margine lo dà già lei: 30 in più staccherebbero
            // l'avatar dalla freccia come se fossero due cose diverse.
            titleSpacing: showBack ? 0 : kHeaderHorizontalMargin,
            backgroundColor: c.background,
            foregroundColor: c.textPrimary,
            // Senza ombra: sotto gli angoli c'è lo sfondo della pagina, e
            // l'ombra lo sporcherebbe.
            elevation: 0,
            scrolledUnderElevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(kHeaderBottomRadius),
              ),
            ),
            centerTitle: false,
            title: title,
            actionsPadding: kHeaderActionsPadding,
            actions: actions,
          ),
        ),
        if (bottom != null)
          SizedBox(height: bottom.preferredSize.height, child: bottom),
      ],
    );
  }
}

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
        // Bianco come il testo dell'header: l'icona sta sulla banda indaco, non
        // sullo sfondo della pagina.
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
      icon: Icon(
        Icons.settings_rounded,
        color: AppColors.of(context).textPrimary,
      ),
      tooltip: 'Personalizzazione',
      onPressed: () =>
          pushRevealed(context, (_) => const CustomizationScreen()),
    );
  }
}

/// Le altre scuole, nelle `actions` di Lezioni ed Esercizi, a sinistra della
/// lente: apre il foglio di scelta per una visita.
///
/// Sta solo dove c'è un profilo. L'ospite ha già il foglio dalla pillola, con
/// un altro testo, quindi qui non aggiungerebbe niente.
///
/// Se si guarda una scuola diversa da quella del profilo, l'icona resta la
/// stessa e prende in pedice l'iniziale della scuola (M, S, U): senza, la
/// pagina sembrerebbe quella di sempre e i progressi mostrati sarebbero quelli
/// di un'altra scuola senza che lo si dica. Il nome per esteso non c'è più,
/// perché con tre icone mandava la riga in overflow: l'icona ha sempre la
/// stessa larghezza.
class SchoolBrowseButton extends StatelessWidget {
  final SchoolChoiceDestination destination;

  const SchoolBrowseButton({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AuthStore.instance, BrowseStore.instance]),
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
        final c = AppColors.of(context);
        final initial = other ? schoolInitial(title) : '';

        return IconButton(
          key: const Key('header-school-browse'),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.school_outlined, color: c.textPrimary),
              if (initial.isNotEmpty)
                Positioned(
                  right: -5,
                  bottom: -5,
                  child: Container(
                    key: const Key('school-browse-initial'),
                    width: 14,
                    height: 14,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.background, width: 1.5),
                    ),
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontFamily: AppText.bodyFont,
                        fontSize: 9,
                        height: 1,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          tooltip: other ? 'Guardi $title' : 'Altre scuole',
          onPressed: () => _pick(context),
        );
      },
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

/// L'iniziale della scuola dal suo titolo: l'ultima parola, quindi «Scuola
/// Media» è M, «Scuola Superiore» S e «Università» U.
@visibleForTesting
String schoolInitial(String title) {
  final words = title.trim().split(RegExp(r'\s+'));
  final last = words.last;
  return last.isEmpty ? '' : last[0].toUpperCase();
}

/// L'header di una delle tre pagine principali: la stessa banda, con le azioni
/// di quella pagina. Lezioni ed Esercizi hanno anche le altre scuole, e il loro
/// titolo dice il livello che mostrano ([levelId]); la Home no.
MainHeaderAppBar mainHeaderFor(PillTab tab, {String? levelId}) {
  return switch (tab) {
    PillTab.home => const MainHeaderAppBar(
      title: MainHeaderTitle(),
      actions: [HeaderStreakChip(), HeaderCustomizationButton()],
    ),
    PillTab.lessons => MainHeaderAppBar(
      title: MainHeaderTitle(levelId: levelId),
      actions: const [
        SchoolBrowseButton(destination: SchoolChoiceDestination.lessons),
        HeaderStreakChip(),
        HeaderCustomizationButton(),
      ],
    ),
    PillTab.exercises => MainHeaderAppBar(
      title: MainHeaderTitle(levelId: levelId),
      actions: const [
        SchoolBrowseButton(destination: SchoolChoiceDestination.exercises),
        HeaderStreakChip(),
        HeaderCustomizationButton(),
      ],
    ),
  };
}
