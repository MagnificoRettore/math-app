import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/search_index.dart';
import '../screens/argomento_lessons_screen.dart';
import '../screens/lesson_screen.dart';
import '../theme/app_colors.dart';
import 'app_card.dart';

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
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Chiudi la ricerca',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, _, _) => const SearchOverlay(),
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

/// Riga di risultato: sopra il titolo la pillola che dice il tipo, poi il titolo
/// in grassetto e sotto il contesto — da quale argomento arriva e a che livello.
/// La pillola serve perché «Moduli» e «Modulo e Equazioni con Modulo» sono due
/// titoli e senza etichetta non si sa quale dei due si sta aprendo; il contesto
/// non basta, perché è informazione e non dichiarazione di tipo.
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TipoBadge(tipo: result.type),
          const SizedBox(height: 8),
          Text(
            titolo,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          if (contesto.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              contesto,
              style: TextStyle(fontSize: 13, color: c.textSecondary),
            ),
          ],
          if (dettaglio.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              dettaglio,
              style: TextStyle(fontSize: 12, color: c.textSecondary),
            ),
          ],
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

/// La dichiarazione di tipo del risultato, sopra il titolo.
///
/// Sta **sopra** e non accanto al titolo: il titolo va in ellissi e la riga è
/// già alta, quindi un vicino nella stessa `Row` si mangerebbe la larghezza
/// proprio dove il testo è più a rischio di troncarsi.
///
/// Due colori dalla palette, non uno, perché due tipi che si somigliano vengono
/// letti come uno: `accent` per l'argomento e `indigo` per la lezione. Il teal
/// sembrava la scelta giusta ed è la sbagliata: sul `surface` chiaro sta a
/// 2.33:1 e una scritta a 12px sotto i 4.5:1 non si legge. `indigo` sta a 4.86:1
/// in chiaro e 6.69:1 in scuro. Entrambi animano da soli con `AppPalette.lerp`,
/// quindi seguono la transizione fra i temi senza altro codice.
class _TipoBadge extends StatelessWidget {
  final ResultType tipo;

  const _TipoBadge({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = switch (tipo) {
      ResultType.argomento => c.accent,
      ResultType.lesson => c.indigo,
      ResultType.topic => c.pink,
      ResultType.exercise => c.medium,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tipo.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Escape chiude l'overlay, come il tocco fuori.
class _ChiudiIntent extends Intent {
  const _ChiudiIntent();
}
