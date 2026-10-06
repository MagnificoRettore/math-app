import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../data/auth_store.dart';
import '../data/browse_store.dart';
import '../data/content_repository.dart';
import '../data/shell_navigator.dart';
import '../theme/app_motion.dart';
import '../widgets/argomento_carousel.dart';
import '../widgets/daily_exercise_card.dart';
import '../widgets/home_continue_card.dart';
import '../widgets/math_fact_card.dart';
import '../widgets/main_header.dart';
import '../widgets/pill_nav_bar.dart';
import '../widgets/school_choice_sheet.dart';
import 'course_screen.dart';
import 'lesson_list_screen.dart';

/// La radice dell'app: le tre pagine principali, Lezioni · Home · Esercizi, in
/// un `PageView` fra un header e una barra che restano fermi. Scorre il solo
/// contenuto, col dito o col tocco sulla barra, e l'evidenziato della barra
/// segue la pagina visitata.
///
/// Lezioni ed Esercizi hanno bisogno di una scuola: quella in visita, quella
/// del profilo o, da ospite, quella scelta dal foglio la prima volta che si
/// apre una delle due. Senza, la pagina resta vuota e il foglio si apre appena
/// ci si ferma su di lei; annullandolo si torna alla Home.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _tabs = PillTab.values;

  final PageController _pages = PageController(
    initialPage: PillTab.values.indexOf(PillTab.home),
  );
  final ValueNotifier<PillTab> _tab = ValueNotifier(PillTab.home);

  /// La scuola scelta dal foglio da chi non ha un profilo, una per pagina: da
  /// ospite si sceglie separatamente per Lezioni e per Esercizi.
  final Map<PillTab, String> _picked = {};

  /// L'anno con cui aprire Esercizi, quando lo chiede un'altra pagina.
  String? _courseRequest;

  /// `true` mentre una pagina si muove per un tocco: la barra è già sul tab
  /// chiesto e non deve passare dalle pagine in mezzo.
  bool _animating = false;
  bool _asking = false;

  static String? get _profileLevelId {
    final id = AuthStore.instance.currentUser?.schoolLevelId;
    return id == null || id.isEmpty ? null : id;
  }

  /// La scuola che [tab] sta mostrando.
  String? _levelFor(PillTab tab) =>
      BrowseStore.instance.levelId ?? _profileLevelId ?? _picked[tab];

  @override
  void initState() {
    super.initState();
    ShellNavigator.instance.addListener(_onRequest);
  }

  @override
  void dispose() {
    ShellNavigator.instance.removeListener(_onRequest);
    _pages.dispose();
    _tab.dispose();
    super.dispose();
  }

  void _onRequest() {
    final nav = ShellNavigator.instance;
    final tab = nav.tab;
    if (tab == null || !mounted) return;
    setState(() {
      if (nav.levelId != null) _picked[tab] = nav.levelId!;
      _courseRequest = nav.courseId;
    });
    _goTo(tab);
  }

  /// Il tocco sulla barra, o una richiesta dall'esterno.
  Future<void> _goTo(PillTab tab) async {
    if (tab != PillTab.home && _levelFor(tab) == null) {
      await _askSchool(tab);
      return;
    }
    await _animateTo(tab);
  }

  Future<void> _animateTo(PillTab tab) async {
    _tab.value = tab;
    if (!_pages.hasClients) return;
    _animating = true;
    try {
      await _pages.animateToPage(
        _tabs.indexOf(tab),
        duration: AppMotion.duration(context, AppMotion.slow),
        curve: AppMotion.standard,
      );
    } finally {
      _animating = false;
    }
  }

  /// Il foglio della scuola, per chi non ne ha una. Annullato, si torna a
  /// Home se la pagina era già sotto il dito.
  Future<void> _askSchool(PillTab tab) async {
    if (_asking) return;
    _asking = true;
    // La barra sta già sulla pagina chiesta, come per una scelta in corso.
    _tab.value = tab;
    final chosen = await showSchoolChoiceSheet(
      context,
      destination: tab == PillTab.lessons
          ? SchoolChoiceDestination.lessons
          : SchoolChoiceDestination.exercises,
    );
    _asking = false;
    if (!mounted) return;
    if (chosen == null) {
      await _animateTo(PillTab.home);
      return;
    }
    setState(() => _picked[tab] = chosen.id);
    await _animateTo(tab);
  }

  /// Il dito ha lasciato la pagina: se è una di quelle con la scuola e la
  /// scuola non c'è, la si chiede.
  bool _onScrollEnd(ScrollNotification notification) {
    if (notification is! ScrollEndNotification || _animating) return false;
    final page = _pages.page;
    if (page == null) return false;
    final tab = _tabs[page.round().clamp(0, _tabs.length - 1)];
    if (tab != PillTab.home && _levelFor(tab) == null) _askSchool(tab);
    return false;
  }

  void _onPageChanged(int index) {
    if (_animating) return;
    _tab.value = _tabs[index];
  }

  @override
  Widget build(BuildContext context) {
    final systemBottom = MediaQuery.viewPaddingOf(context).bottom;
    // Scuola in visita e profilo cambiano il livello delle pagine e il titolo
    // dell'header.
    return ListenableBuilder(
      listenable: Listenable.merge([BrowseStore.instance, AuthStore.instance]),
      builder: (context, _) => _buildShell(context, systemBottom),
    );
  }

  Widget _buildShell(BuildContext context, double systemBottom) {
    return ValueListenableBuilder<PillTab>(
      valueListenable: _tab,
      builder: (context, tab, _) => PopScope(
        // Da Lezioni o Esercizi il back torna a Home, poi esce.
        canPop: tab == PillTab.home,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _goTo(PillTab.home);
        },
        child: Scaffold(
          appBar: _Header(tab: tab, levelId: _levelFor(tab)),
          body: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: kPillBottomReserve + systemBottom,
                  ),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _onScrollEnd,
                    child: PageView(
                      key: const Key('main-pages'),
                      controller: _pages,
                      onPageChanged: _onPageChanged,
                      children: [
                        _KeepAlive(child: _lessons()),
                        const _KeepAlive(child: HomeBody()),
                        _KeepAlive(child: _exercises()),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: PillNavBar(selected: tab, onSelect: _goTo),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lessons() {
    final levelId = _levelFor(PillTab.lessons);
    if (levelId == null) return const SizedBox.shrink();
    return LessonListScreen(levelId: levelId, embedded: true);
  }

  Widget _exercises() {
    final level = ContentRepository.instance.levelById(
      _levelFor(PillTab.exercises) ?? '',
    );
    if (level == null) return const SizedBox.shrink();
    return CourseScreen(
      level: level,
      embedded: true,
      initialCourseId: _courseRequest,
    );
  }
}

/// L'header della pagina in vista. Si ricostruisce quando cambiano scuola o
/// profilo, perché il titolo dice quale scuola sta guardando la pagina.
class _Header extends StatelessWidget implements PreferredSizeWidget {
  final PillTab tab;
  final String? levelId;

  const _Header({required this.tab, required this.levelId});

  @override
  Size get preferredSize => const Size.fromHeight(kHeaderToolbarHeight);

  @override
  Widget build(BuildContext context) => mainHeaderFor(tab, levelId: levelId);
}

/// Tiene viva la pagina anche quando esce dallo schermo: filtri, anno scelto
/// e scorrimento restano com'erano tornandoci, e l'entrata della Home non
/// riparte.
class _KeepAlive extends StatefulWidget {
  final Widget child;

  const _KeepAlive({required this.child});

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// Il contenuto della Home. Al primo caricamento le sezioni entrano in
/// sequenza (stagger): ognuna con una dissolvenza e una piccola salita,
/// [AppMotion.stagger] dopo la precedente. Una volta sola: la lista ricrea le
/// sezioni che rientrano scorrendo, e quelle ricreate dopo l'entrata partono
/// già al loro posto.
class HomeBody extends StatefulWidget {
  const HomeBody({super.key});

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  /// Di quanto, in frazione della propria altezza, una sezione sale entrando.
  static const double _rise = 0.06;

  /// `true` appena una sezione ha finito di entrare: un `Animate` creato
  /// dopo parte già alla fine, mentre quelli in corsa finiscono la loro
  /// strada.
  bool _entered = false;

  /// Un rebuild solo, alla prima sezione entrata: la lista tiene i widget
  /// dell'ultimo build, e senza quelle che rientrano scorrendo ripartirebbero
  /// da zero.
  void _onEntered() {
    if (_entered || !mounted) return;
    setState(() => _entered = true);
  }

  @override
  Widget build(BuildContext context) => _buildHomeTab();

  /// La sezione [index]-esima dentro la sua entrata. Col movimento ridotto
  /// niente entrata: la sezione è già lì.
  Widget _enter(BuildContext context, int index, Widget section) {
    if (AppMotion.reduced(context)) return section;
    // Il ritardo sta negli effetti e non in `Animate.delay`, che aspetta con
    // un `Future.delayed` non cancellabile: negli effetti fa parte della
    // corsa del controller, che si ferma col widget.
    final delay = AppMotion.stagger * index;
    return section
        .animate(
          autoPlay: !_entered,
          value: _entered ? 1 : 0,
          onComplete: (_) => _onEntered(),
        )
        .fadeIn(
          delay: delay,
          duration: AppMotion.slow,
          curve: AppMotion.standard,
        )
        .slideY(
          delay: delay,
          begin: _rise,
          end: 0,
          duration: AppMotion.slow,
          curve: AppMotion.standard,
        );
  }

  Widget _buildHomeTab() {
    final levels = ContentRepository.instance.levels;
    if (levels.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Ogni sezione si ascolta da sé (serie, carosello), quindi la lista non
    // ha store da seguire.
    return ListView(
      // Le sezioni si distanziano di 24: il ritmo è della pagina, non di ogni
      // widget, quindi il `SizedBox` sta qui e non dentro le sezioni. Il primo
      // e l'ultimo invece sono padding. Il carosello porta la sua testata, che
      // ha già i 24 sopra: senza argomenti sparisce con lei.
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _enter(context, 0, const HomeContinueCard()),
        const SizedBox(height: 24),
        _enter(context, 1, const DailyExerciseCard()),
        _enter(context, 2, const ArgomentoCarousel()),
        const SizedBox(height: 24),
        _enter(context, 3, const MathFactCard()),
      ],
    );
  }
}
