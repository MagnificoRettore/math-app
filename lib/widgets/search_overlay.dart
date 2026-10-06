import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/search_index.dart';
import '../screens/argomento_lessons_screen.dart';
import '../screens/lesson_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_text.dart';
import 'app_card.dart';
import 'reveal.dart';

/// Cosa vede la ricerca: argomenti e lezioni, per titolo.
const _tipiRicerca = [ResultType.argomento, ResultType.lesson];

/// Sotto questo numero di lettere non si cerca: con una sola lettera quasi
/// ogni titolo torna e la lista diventa inutile.
const _minimo = 2;

/// Attesa fra l'ultima lettera e la ricerca, per non ricalcolare a ogni
/// keystroke mentre l'utente sta ancora scrivendo.
const _debounce = Duration(milliseconds: 300);

/// Apre la ricerca sopra la pagina corrente.
///
/// È una rotta a dialogo, non una pagina: copre tutto e il back la chiude
/// tornando alla pagina da cui si è partiti, senza che l'utente debba
/// attraversare una schermata vuota per tornare indietro.
///
/// L'overlay copre tutta la pagina, quindi dietro non c'è niente da toccare:
/// si chiude con la X, con Escape e con il back del sistema. Il barrier è
/// trasparente per lo stesso motivo — la chiusura toccando «fuori» non esiste,
/// e una configurazione che promette un'uscita inesistente è peggio di nessuna.
Future<void> showSearchOverlay(BuildContext context) {
  final origin = revealOrigin(context);
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Chiudi la ricerca',
    barrierColor: Colors.transparent,
    transitionDuration: AppMotion.duration(context, AppMotion.slow),
    pageBuilder: (context, _, _) => const SearchOverlay(),
    // Si espande dalla lente, e tornando indietro vi si ritira.
    transitionBuilder: (context, animation, _, child) =>
        revealTransition(animation, origin, child),
  );
}

class SearchOverlay extends StatefulWidget {
  const SearchOverlay({super.key});

  @override
  State<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<SearchOverlay> {
  final TextEditingController _controller = TextEditingController();
  Timer? _timer;
  List<SearchResult> _results = const [];
  String _query = '';

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _timer?.cancel();
    final q = value.trim();
    if (q.length < _minimo) {
      setState(() {
        _query = q;
        _results = const [];
      });
      return;
    }
    setState(() => _query = q);
    _timer = Timer(_debounce, () => _search(q));
  }

  void _search(String query) {
    final results = SearchIndex.instance.search(query, types: _tipiRicerca);
    if (!mounted) return;
    setState(() => _results = results);
  }

  /// Apre la pagina del risultato e chiude l'overlay. Il navigator va preso
  /// prima del `pop`: dopo, il contesto dell'overlay è morto.
  void _open(SearchResult result) {
    final navigator = Navigator.of(context);
    final argomento = result.argomento!;
    final page = result.type == ResultType.argomento
        ? ArgomentoLessonsScreen(
            argomento: argomento,
            levelId: argomento.levelId,
          )
        : LessonScreen(lesson: result.lesson!, levelId: argomento.levelId);
    navigator.pop();
    navigator.push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Material(
      color: c.background,
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.escape): _ChiudiIntent(),
        },
        child: Actions(
          actions: {
            _ChiudiIntent: CallbackAction<_ChiudiIntent>(
              onInvoke: (_) {
                Navigator.of(context).pop();
                return null;
              },
            ),
          },
          child: Padding(
            // Con la tastiera aperta il campo non deve finire sotto di lei.
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                    child: Row(
                      children: [
                        Expanded(child: _buildField(context)),
                        IconButton(
                          key: const Key('search-overlay-close'),
                          icon: Icon(Icons.close_rounded, color: c.textPrimary),
                          tooltip: 'Chiudi la ricerca',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: _buildResults(context)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(BuildContext context) {
    final c = AppColors.of(context);
    const radius = BorderRadius.all(Radius.circular(28));
    return TextField(
      key: const Key('search-overlay-field'),
      controller: _controller,
      autofocus: true,
      textInputAction: TextInputAction.search,
      onChanged: _onChanged,
      onSubmitted: _search,
      decoration: InputDecoration(
        hintText: 'Cerca un argomento o una lezione',
        filled: true,
        fillColor: c.surface,
        hintStyle: TextStyle(color: c.textSecondary),
        isDense: true,
        prefixIcon: Icon(Icons.search, color: c.textSecondary, size: 20),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
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
    );
  }

  Widget _buildResults(BuildContext context) {
    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            _query.length < _minimo
                ? 'Scrivi almeno due lettere.'
                : 'Nessun risultato trovato.',
            style: TextStyle(color: AppColors.of(context).textSecondary),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) =>
          _ResultCard(result: _results[i], onTap: () => _open(_results[i])),
    );
  }
}

/// Riga di risultato: a sinistra l'icona che dice il tipo, poi il titolo e
/// sotto il contesto — da quale argomento arriva e a che livello. L'icona serve
/// perché «Moduli» e «Modulo e Equazioni con Modulo» sono due titoli e senza
/// non si sa quale dei due si sta aprendo; il contesto non basta, perché è
/// informazione e non dichiarazione di tipo.
class _ResultCard extends StatelessWidget {
  final SearchResult result;
  final VoidCallback onTap;

  const _ResultCard({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final level = result.level?.title ?? '';
    final isArgomento = result.type == ResultType.argomento;
    final argomento = result.argomento!;

    final titolo = isArgomento ? argomento.title : result.lesson!.title;
    final contesto = isArgomento
        ? _unisci([argomento.subtitle, '${argomento.lessons.length} lezioni'])
        : argomento.title;
    final dettaglio = isArgomento
        ? level
        : _unisci([level, _minuti(result.lesson!.minutes)]);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TipoIcon(tipo: result.type),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titolo,
                  style: TextStyle(
                    fontSize: AppText.titleSmall,
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                  ),
                ),
                if (contesto.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    contesto,
                    style: TextStyle(
                      fontSize: AppText.label,
                      color: c.textSecondary,
                    ),
                  ),
                ],
                if (dettaglio.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    dettaglio,
                    style: TextStyle(
                      fontSize: AppText.caption,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Toglie le voci vuote: un argomento senza sottotitolo o una lezione senza
  /// minuti non devono lasciare un `·` sospeso.
  String _unisci(List<String> parti) =>
      parti.map((p) => p.trim()).where((p) => p.isNotEmpty).join(' · ');

  String _minuti(int minuti) => minuti > 0 ? '$minuti min' : '';
}

/// Il tipo del risultato, a sinistra del titolo, senza scriverlo: icona e forma
/// cambiano insieme (quadrato arrotondato per l'argomento, cerchio per la
/// lezione), così si distinguono anche senza il colore. Lo screen reader
/// legge il tipo da [ResultType.label].
///
/// Colori: `accent` per l'argomento e `indigo` per la lezione, entrambi sopra
/// 4.5:1 sul `surface`; il teal sul chiaro non ci arriva.
class _TipoIcon extends StatelessWidget {
  final ResultType tipo;

  const _TipoIcon({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final (color, icon) = switch (tipo) {
      ResultType.argomento => (c.accent, Icons.folder_copy_rounded),
      ResultType.lesson => (c.indigo, Icons.menu_book_rounded),
      ResultType.topic => (c.pink, Icons.category_rounded),
      ResultType.exercise => (c.medium, Icons.edit_note_rounded),
    };
    final circle = tipo == ResultType.lesson;

    return Semantics(
      label: tipo.label,
      excludeSemantics: true,
      child: Container(
        key: ValueKey('search-type-${tipo.name}'),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

/// Escape chiude l'overlay, come il tocco fuori.
class _ChiudiIntent extends Intent {
  const _ChiudiIntent();
}
