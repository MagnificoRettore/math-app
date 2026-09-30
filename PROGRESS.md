# PROGRESS.md

Changelog e roadmap del progetto.

## 2026-09-30 — Il topic come titolo e la barra di avanzamento su «Jump Back In»

- La card non parte più col contatore "Step 2 di 3": la resa era un titolo di lezione che non dice niente da solo, e un numero che competeva con la sezione. Ora il **topic è il titolo grande** (17 w700) e la lezione scende a sottotitolo (13), con sotto una `ProgressBar` alta 8 che si prende tutto lo spazio della colonna. Nessun numero: la barra parla da sola e non aggiunge una riga.
- Lo stacco col blocco successivo mancava: `JumpBackInSection` era seguita da `ImageCarousel` senza nessuno spazio, e la card toccava le immagini. I 20px stanno **dentro** la sezione, non nella lista di `HomeScreen`, altrimenti quando la sezione è nascosta (ospite, nessuna lezione aperta) resterebbe un buco bianco davanti al carousel.
- `LessonResumeEngine.topicProgress(target)` fa il calcolo ed è **posizionale, non di merito**: conta `target.step` card superate della lezione corrente più tutte le card delle lezioni che la precedono nell'argomento, e il denominatore sono tutte le card dell'argomento, anche quelle dopo. Le lezioni precedenti contano **anche se non sono mai state aperte**: un argomento si affronta in ordine, quindi la barra dice dove si è, non cosa si è fatto. Se avesse contato solo il lavoro fatto, saltare una lezione avrebbe azzerato la barra e l'utente avrebbe letto un regresso mentre stava avanzando.
- Non serve più `isLessonCompleted` per la barra, e non serve il `levelId`: il calcolo è posizione pura dentro l'argomento che il target porta già con sé.
- Test: `topicProgress` ha cinque casi nell'engine (primo passo a zero, card superate della lezione in pausa, lezione precedente mai aperta che conta lo stesso, lezione proposta dopo una completata, passo fuori range che non spinge la barra oltre 1). Sul widget il contatore sparisce e al suo posto si asserisce il valore della `ProgressBar`; l'aspetto usa `mod-equations-intro` perché per `eq1-intro` il titolo dell'argomento e quello della lezione sono identici e il finder non li distinguerebbe. Nuovo anche un test geometrico che il blocco sotto non sia attaccato. Ora 252 test in 25 file, con due rossi: i due dell'header, che misurano 12px mentre `kHeaderHorizontalMargin` è ancora 30.

## 2026-09-30 — Sezione «Jump Back In» sulla Home

- Prima sezione della Home (`JumpBackInSection`, prima di `ImageCarousel`): dice da dove riprendere invece di lasciare l'utente a cercare il punto esatto in cui si era fermato. La card porta titolo della lezione, argomento e «Step 2 di 3»; il contatore sparisce sulle lezioni di un solo passo, dove non dice niente.
- Compare solo per l'utente registrato con una scuola scelta e solo se ha già aperto una lezione almeno una volta. Senza quel punto di ripresa non esce niente: proporre un argomento a caso sarebbe rumore, e la sezione vuota accetterebbe il posto di un'aggiunta reale. Solo Home, non anche sulla pagina Lezioni: quella ha già il suo elenco.
- La scelta del bersaglio sta in `LessonResumeEngine`, logica pura senza `instance`, così è testabile senza widget. La catena è: la lezione lasciata aperta torna all'ultimo passo visitato, altrimenti la non completata più vicina cercando prima nel suo argomento e poi nei successivi dello stesso anno. Anno interamente completato ⇒ `null`, e la sezione sparisce invece di ripetere cose già fatte.
- Il motore riparte dall'inizio dell'argomento invece che da dopo la lezione in pausa, quindi può tornare indietro. È voluto: se la lezione in pausa è stata completata altrove, l'utente deve vedere che gli resta qualcosa, non una sezione vuota. Per questo la lezione in pausa viene saltata esplicitamente, per non ripeterla.
- `LessonScreen` accetta `initialStep` (default 0) e salva il punto in `initState` e a ogni `onPageChanged`, così il posto vale anche se l'app viene uccisa. **Non** ripristina le risposte già date: `_solved`, `_selectedOption` e `_wrongOptions` restano puliti, quindi un quiz ricominciato non eredita una risposta data prima. Il passo in arrivo viene clampato, così un salvataggio più grande del contenuto non apre una pagina inesistente.
- La scrittura iniziale è differita al primo frame con `addPostFrameCallback`. Scrivere dritto dalla `initState` faceva notificare `ProgressStore` durante la build della nuova rotta, e le sezioni in ascolto del progresso si rimarcavano da costruire mentre il framework era già dentro la build: eccezione in ogni test che apriva la lezione dalla card. Trovato dai test, non a occhio.
- `_complete()` chiama `clearLessonResume()`: senza, la sezione riproporrebbe all'istante la lezione appena finita.
- Persistenza su `lessons_in_progress_v1` (`levelId`, `lessonId`, `step`). Il resume vale solo per il `levelId` dell'utente, quindi un profilo cambiato non porta in una scuola in cui quella lezione non esiste.
- Test: `test/lesson_resume_engine_test.dart` copre le 10 regole del motore (nessun punto di ripresa, ospite senza scuola, passo clampato, lezione completata altrove, anno finito, contenuto cambiato). `test/jump_back_in_test.dart` copre la card: nascosta per l'ospite, nascosta senza lezione aperta, contatore, apertura al passo giusto e sparizione al completamento. Ora 246 test in 25 file, con due rossi: i due dell'header, che misurano 12px mentre `kHeaderHorizontalMargin` è ancora 30.

## 2026-09-29 — Swipe a sinistra per completare la lezione

- Sull'ultima card la lezione si completa anche scorrendo col dito verso sinistra, senza toccare il bottone. Il gesto lo guarda un `Listener` attorno alla `PageView`: un `GestureDetector` esterno non riceverebbe mai il drag, perché lo vince lo scroll della `PageView`. Contano solo le mosse più orizzontali che verticali, così scorrere il testo o le opzioni non fa partire niente.
- La card segue il dito verso sinistra fino a `_kSwipeCompleteThreshold` (56px) e a quel punto parte `_complete()`. Il progresso del trascinamento sta in un `ValueNotifier` e non in `setState`: arriva a ogni `pointerMove` e ricostruire la pagina a ogni frame non serve, la posizione la dipinge il solo `AnimatedBuilder`.
- Il vincolo dell'esercizio resta: il gesto chiama `_canCompleteAt(index)`, la stessa condizione che mostra il bottone, quindi su una verifica non risolta lo swipe non fa niente (e il bottone non c'è). «Completa la lezione» resta al suo posto: lo swipe è un'alternativa, non l'unico modo.
- `_complete()` ora esce subito se `_celebrating` è già vero: i `pointerMove` dopo la soglia continuano ad arrivare e senza guardia riarmerebbero il timer della celebrazione.
- Test: sotto soglia la lezione resta aperta, oltre soglia arriva il trofeo e il progresso è salvato; su una card non ultima lo swipe cambia pagina e non completa; su una verifica non risolta non succede nulla. Il percorso di risoluzione della verifica è ora in `_risolviVerifica`, condiviso fra il completamento col bottone e quello col gesto.

## 2026-09-28 — Trofeo di fine lezione a schermo intero

- Finita la lezione non compare più uno SnackBar in basso: si copre tutta la lezione con un overlay `Positioned.fill` (dentro lo `Stack` del body, sopra la calcolatrice se fosse aperta) con `Trophy.json` a 240px al centro, il titolo «Lezione completata!» e la scritta «Tocca per continuare». Il fondo è opaco (`c.background`), quindi niente lezione che si vede sotto.
- L'uscita è sempre a portata di mano: un tap ovunque chiude l'overlay e fa pop, e in più un `Timer` di 2400ms fa pop da solo se nessuno tocca (i 71 frame del trofeo a 30fps durano 2.37s, quindi la chiusura arriva appena finita l'animazione). Il `pop` non parte più al tap su «Completa la lezione»: quel tap ora apre solo la celebrazione. Il timer si cancella in `dispose`.
- `Trophy.json` è un JSON normale (500x500, 30fps, precomp e maschere, niente marker e niente espressioni), quindi si passa a `Lottie.asset` così com'è: niente `AssetLottie` e niente `AnimationController`, a differenza dal toggle del tema. Se l'asset non si carica resta un quadrato vuoto delle stesse 240px (`errorBuilder`), così il layout non cambia.
- Test: il caso «risposta sbagliata scuote, quella giusta spiega e completa» ora asserisce overlay, trofeo, istruzione e che la lezione sia ancora aperta, e poi che il tap faccia pop; un caso nuovo copre la chiusura automatica. Il percorso di apertura e di completamento è finito in due helper (`_apriPrimaLezione`, `_completa`) perché serviva due volte, e la lezione viene spinta sopra una `Scaffold` vuota: prima era l'unica rotta, quindi il `pop` lasciava l'albero vuoto. La chiusura automatica vuole un `pumpAndSettle` dopo la durata, perché il timer fa partire il pop ma la transazione della rotta dura ancora qualche frame.


## 2026-09-28 — Il toggle del tema è l'animazione sole e luna

- Nel card «Tema scuro» del profilo (ospite e loggato) lo `Switch` è diventato l'animazione `assets/animations/toggle.json`: si tocca e cambia tema. Una sola implementazione perché `_ThemeToggle` serve a entrambe le versioni della pagina.
- Il file di partenza era `Toogle.lottie`, che è un dotLottie: uno zip con manifest, animazione e state machine, con interazioni click sui layer `Sun` e `Moon`. `lottie` 3.6.1 non legge i `.lottie` e non ha state machine, quindi nessuno dei due poteva funzionare. Estratto `a/Main Scene.json` in `toggle.json` (marker compresi) e cancellato lo `.lottie`, che era un asset che nessuna versione del pacchetto avrebbe potuto riprodurre. Nessuna dipendenza nuova: `lottie` era già in `pubspec.yaml`.
- La state machine è reimplementata a mano sui **marker** della timeline: `Day Idle` (0–0.1), `Day to Night` (0.1–0.4), `Night Idle` (0.4–0.6), `Night to Day` (0.6–1.0). Il tap cambia tema subito e poi porta l'`AnimationController` a fine segmento con `animateTo` e una durata calcolata sulla durata della composizione: 1.0s allandata al buio, 1.33s al ritorno.
- Il segmento idle ripete `count: 3` e poi si ferma. Il loop infinito era più vivo, ma non assesta mai: faceva andare in timeout `pumpAndSettle` in otto test che aprono il profilo e teneva il frame scheduler acceso per sempre. Tre giri danno la stessa scena che respira, poi la card riposa finché non la si tocca.
- Il tema cambia all'inizio della transizione, non a metà: i colori dell'app virano con l'animazione che parte, non con quella che è a metà. Un cambio a metà richiederebbe un `Future.delayed` che può disallinearsi con l'animazione, quindi no.
- Finché la composizione non è caricata resta lo `Switch` di prima, così la card non ha buchi nel primo frame; un tap in quella finestra cambia comunque il tema, solo senza animazione. Sopra l'animazione c'è un `GestureDetector` con `Semantics(toggled:)`, per la lettura da screen reader.
- Test: nuovo `test/theme_toggle_test.dart` — l'animazione al posto dello `Switch`, ferma sul segmento `Day Idle`; il tap che porta su `Night Idle` e poi di nuovo su `Day Idle` seguendo i marker; il tap durante la transizione ignorato. Nessun `pumpAndSettle` dopo l'ingresso nel profilo: si pompano durate fisse.
- Passata in rassegna la suite: tolto il doppione della navigazione al profilo (resta `header_test`, che copre tutte e tre le pagine, invece del doppione in `home_greeting_test` e del caso ospite in `pill_navigation_test`), le 6 asserzioni di geometria dell'header stanno in un helper chiamato dai due casi, i tre grafici «non va in errore» generici sono un caso solo dentro una colonna (i cinque con edge case vero restano), `settings_store_test` usa `resetForTest` awaited invece di `reload()` non awaitato, e i `load()` nel corpo dei test sono spariti dove il `setUp` li fa già. Ora sono 224 test in 23 file, con due rossi: i due dell'header, che misurano 12px mentre `kHeaderHorizontalMargin` è ancora 30.

## 2026-09-28 — Campo di ricerca sulla stessa riga dell'icona del profilo

- Spazio laterale ridotto: margini da 20 a 12px per lato (`kHeaderHorizontalMargin`) e distanza campo-icona da 8 a 6px, quindi la riga passa da 48 a 30px laterali e il campo guadagna 18px. Il margine destro non ha una chiave sua: con `actions` vuoto l'`AppBar` riusa `titleSpacing`, quindi basta una costante sola. La Home non ha il campo ma allinea l'avatar con gli stessi 12px dal bordo, tramite `actionsPadding`, cosi l'icona cade uguale su tutte le pagine.

- Campo e icona cresciuti ancora: 56px l'uno (`kHeaderTextFieldHeight`, `kProfileAvatarSize`), riga dell'header a 80 (`kHeaderToolbarHeight`), raggio del campo 28, lentellino 20 in `prefixIconConstraints` 48x48. La Home non ha il campo ma prende la stessa `toolbarHeight`, altrimenti l'avratto da 56 in una toolbar da 56 resterebbe attaccato ai bordi.
- Distanza fra campo e icona: 24px prima, 8px adesso. Non basta `actionsPadding`: l'`AppBar` tiene 16px di `middleSpacing` fra titolo e actions, e il campo finiva lì dentro. Campo e icona stanno quindi nella stessa `Row` dentro `AppBar.title` (`Expanded` + `SizedBox(width: 8)` + `ProfileButton`) invece che in `title`/`actions` separati. Ospite e utente loggato hanno la stessa larghezza di bottone, così il campo non cambia larghezza passando allo stato loggato.
- `HeaderTextBar` passa da barra sotto l'header a campo dentro `AppBar.title`: sta sulla stessa riga dell'icona del profilo e occupa solo lo spazio che resta. Le tre AppBar di Lezioni e quella di Esercizi hanno `toolbarHeight: kHeaderToolbarHeight` (72) e `titleSpacing: 20` come la Home; i due stati vuoti delle lezioni non hanno più il `bottom`.
- Il campo è alto 48 (`kHeaderTextFieldHeight`) invece dei ~40 precedenti, con raggio 24: metà altezza, quindi una capsula piena e non più un rettangolino. Lentellino `Icons.search` a sinistra e `hintText` «Cerca…». Il `prefixIconConstraints` a 40x40 serve a tenerlo dentro i 48px: con il default l'altezza interna spingerebbe il campo fuori dal `SizedBox` e il testo resterebbe schiacciato.
- `bottom` torna a contenere solo `YearTabs` (88), quindi la costante `kHeaderTextBarHeight + 88` non serve più.
- Avatar da 40 a 48 su tutte le pagine, Home compresa, così non ci sono due misure diverse a schermo; da ospite l'icona passa da 24 a 28 dentro il bottone da 48.
- Test: due nuovi casi in `header_test.dart` — centro verticale di campo e icona entro 1px, icona a destra del campo, campo più stretto dello schermo e alto almeno 48.

## 2026-09-28 — Pillola compatta e centrata, e un drag che poteva non navigare

- **Larghezza**: la barra non è più a filo con i bordi. `Center` + `ConstrainedBox(maxWidth: kPillMaxWidth)` (320) dentro il `SafeArea` di sempre: compatta e centrata, e su tablet non si allunga. Altezza, raggio, ombre, vetro e padding interno invariati. Il `LayoutBuilder` interno non si tocca: `segWidth`, `clampLeft`, `segmentAt` e `indicatorLeft` nascono già da `constraints.maxWidth`.
- **Bug scoperto dalla barra più stretta**: a fine trascinamento `alreadySettled` confrontava la posizione dell'indicatore con quella del segmento con `==`. Con la barra stretta i due valori coincidono a meno di un ulp: il confronto dava `false`, l'indicatore non ripartiva, `AnimatedPositioned.onEnd` non chiamava nessuno e la sezione scelta non veniva mai aperta. Ora il confronto ha una tolleranza di mezzo pixel, che è ciò che voleva dire «l'indicatore è già fermo lì».
- Il widget `PillNavBar` occupa comunque tutta la larghezza (il `SafeArea` sta sopra): chi misura la barra in un test deve usare la superficie, ora con la chiave `pill-surface`. I drag dei test passano da frazioni di quella.
- Test: nuovo caso sulla larghezza (non oltre 320, spazi laterali uguali), geometria del trascinamento ricalcolata sul padding interno, e il test «trascinando la pillola si cambia sezione» che prima puntava al profilo ora copre la terza sezione — quello che ha fatto saltare il bug.

## 2026-09-28 — Header delle pagine principali: profilo in alto a destra, via i segnalibri

- **Pillola a tre sezioni**: `PillTab` vale `home`, `lessons`, `exercises`; PROFILO non è più una sezione. `_itemCount` ora deriva da `PillTab.values.length`, così enum e conteggio non possono divergere. I tre segmenti restano equalizzati su tutta la larghezza della barra.
- **Profilo sotto-pagina**: `ProfileScreen` non ha più la `PillNavOverlay` e torna con la freccia indietro nell'header, altrimenti resterebbe senza via d'uscita visibile. Le sue voci dal profilo funzionano ancora: il profilo esiste anche senza login.
- **`ProfileButton`** (`lib/widgets/profile_button.dart`): pulsante in alto a destra nelle tre pagine principali. Con login mostra il cerchio con foto o iniziali (spostato da `HomeGreeting`, stessa chiave `home-profile-avatar`); da ospite porta direttamente a `RegistrationScreen`. La spinta è un `push` semplice, quindi il back torna alla pagina da cui è stato toccato.
- **Home**: nella barra resta solo la scritta del saluto, a sinistra; via l'azione Segnalibri. `HomeGreeting` non contiene più l'avatar.
- **Lezioni ed Esercizi**: sotto l'header c'è `HeaderTextBar`, un `TextField` che per ora accetta testo e non fa nient'altro. Vive in un `PreferredSize` unico insieme agli `YearTabs`: `AppBar.bottom` accetta un solo figlio. Stessa barra anche nei due stati vuoti delle lezioni.
- **Segnalibri eliminati**: via `BookmarksScreen`, il campo `bookmarked` da `ExerciseProgress` (`isBookmarked`, `toggleBookmark`, `bookmarkedIdsFor`) e il pulsante segnalibro da `ExerciseCard` e dall'header del dettaglio esercizio. I dati già salvati in `exercise_progress_v1` contengono ancora la chiave `bookmarked`: viene semplicemente ignorata in lettura, senza migrazione.
- Test: `header_test.dart` nuovo (icona profilo su home, lezioni ed esercizi, da ospite alla creazione, barra di testo scrivibile su lezioni ed esercizi). In `pill_navigation_test.dart` i casi che passavano da PROFILO ora partono da LEZIONI, la geometria del trascinamento è a 3 segmenti, e l'asserzione «la pillola parte centrata sulla HOME» confronta l'indicatore con il centro della label invece che con frazioni della larghezza. In `section_test.dart` un argomento va portato in vista prima del tap: la barra di testo sposta l'elenco sotto il bordo.

## 2026-09-28 — La pillola non torna più sulla sezione precedente

- **Bug**: cambiando sezione l'indicatore della pillola scivolava indietro sulla sezione da cui si partiva e poi scattava avanti. `_onSnapComplete` azzerava `_pendingTabIndex` prima di navigare, quindi la schermata uscente — che resta dipinta ancora un po' — si ricostruiva con l'indicatore di nuovo sulla sezione di partenza. Due casi: il ritorno animato alla home (`popUntil` tiene la rotta uscente in vista per i 220ms del reverse) e il foglio «Scegli la tua scuola» da ospite (`PopupRoute`, la schermata sotto resta viva). I `pushAndRemoveUntil` non ne soffrivano: la rotta sparisce nello stesso frame, il rebuild non arriva mai.
- **Fix**: la sezione richiesta resta in carico alla pillola finché la schermata da cui si parte non è sparita. `_resetTo` azzera il pending prima di pushare (la rotta sparisce subito, ma la home resta viva: senza azzeramento il back mostrerebbe la pillola sulla sezione richiesta invece di quella dello schermo), il percorso HOME non lo azzera (la rotta esce e muore con la pillola dentro), l'annullamento del foglio sì (la pillola torna scivolando sulla sezione corrente).
- Il rilascio del trascinamento ora mette la sezione come «richiesta» e lascia navigare a fine assestamento, identico al tap: un solo punto di uscita per la navigazione. Se l'indicatore è già allineato al segmento non c'è scorrimento e `AnimatedPositioned.onEnd` non parte, quindi in quel caso si naviga al rilascio: in entrambi i rami la navigazione parte una volta sola. Con `disableAnimations` l'assestamento è a durata zero e si naviga subito.
- Test: tre nuovi casi in `pill_navigation_test.dart` che misurano la posizione dell'indicatore contro il centro del segmento (le icone non bastano: per HOME il glifo outlined e il filled coincidono) campando dentro la transizione — tap verso HOME, drag verso HOME, foglio scuola aperto. Sostituito nel test sull'annullamento l'assert sulle icone, che non verificava niente, con quello sulla posizione.

## 2026-09-27 — Cambio sezione dalla pillola senza lampeggio della home

- **Bug**: con un profilo collegato, il tap su LEZIONI o ESERCIZI mostrava la home per un istante e poi la pagina giusta. In `_performNavigation` il `popUntil((route) => route.isFirst)` e il `push` erano due animazioni in sequenza: prima il ritorno animato alla home (reverse 220ms della rotta precedente), e solo al termine la sfumatura della pagina nuova (280ms). La home era la rotta in cima per tutto il reverse, quindi dipinta a pieno per oltre 100ms.
- **Fix**: unica `Navigator.pushAndRemoveUntil(_fadeRoute(page), (route) => route.isFirst)` nei tre punti che aprono una sezione (PROFILO, lezione/esercizi con scuola dal profilo, scelta della scuola da ospite). La rotta nuova entra nello stesso aggiornamento di history che rimuove le precedenti, quindi la home non viene mai riportata in cima. `PillTab.home` tiene il `popUntil`: lì il ritorno animato è voluto. La home resta la radice dello stack, il back continua a tornare a casa.
- Le rotte di `_fadeRoute` sono opache: durante la sfumatura le schermate sotto non vengono costruite, e il passaggio avviene sul `scaffoldBackgroundColor` (identico a quello degli `Scaffold`), quindi nessun lampo di colore. La schermata uscente non sfuma più: viene coperta.
- Test: due nuovi test in `pill_navigation_test.dart` con un `NavigatorObserver` che registra gli eventi — nessun `didPop` (niente ritorno animato alla home), `didRemove` della sezione precedente, schermata nuova in cima e back che torna alla home. I `didPop` del foglio modale della scelta scuola sono ignorati (`PopupRoute`).

## 2026-09-27 — Toolbar nel footer della card, stessa altezza di «Completa la lezione»

- `lesson_screen.dart`: la `M3EToolbar` esce dal `Stack` della pagina (dove era un `Positioned(left: 16, bottom: 16)` con `SafeArea` e `Transform.scale(1/1.5)`) e diventa un `Positioned(left: 0, bottom: 0)` dentro la card. Compatta è alta esattamente quanto «Completa la lezione`: `Transform.scale(_kFooterControlHeight / M3EToolbarTokens.fabMedium)` con `Alignment.bottomLeft`, quindi il FAB dipinto è a filo della colonna di testo, ha lo stesso spigolo inferiore del bottone e la stessa altezza. Con `bottomCenter` il FAB (49 dipinti dentro una box di 80) restava centrato, con 15,5px di aria dal bordo.
- Tre cose scoperte sul pacchetto, che impongono la `Positioned` invece che un figlio della `Row` del footer: il FAB **collassato** è `fabMedium` (80) e non `fabBaseline` (56) — da espanso scende a 56, quindi la scala cercata era 49/80 e non 49/56; il pacchetto riserva **136px in layout anche da collassato** (pilla sempre disposta, solo clip-paintata a zero) e dentro la `Row` avrebbe rubato 87px di contenuto a ogni card; con larghezza illimitata, come vuole una `Row`, il suo layout verticale va in `Infinity` (`RenderConstrainedOverflowBox was given an infinite size`), da qui il `width` nella `Positioned`. Un tentativo con `SizedBox`+`OverflowBox` per tagliare i 136px è stato scartato: `RenderBox.hitTest` limita il test alla propria box, quindi la pila espansa dipinta sopra risultava **intoccabile** e la calcolatrice irraggiungibile.
- La card ora è uno `Stack`: colonna con contenuto scrollabile più fascia footer alta 49 su **ogni** step, toolbar ancorata al fondo della card sopra quella fascia.
- «Completa la lezione» passa da piena larghezza a compatto a destra su tutti gli step, non solo sulla card di verifica.
- Espansione lifted in `_LessonScreenState` (`_toolbarExpanded` + `onExpandedChanged`): c'è una toolbar per card costruita dal `PageView`, senza stato condiviso ognuna nascerebbe collassata a ogni swipe.
- Tolta la `SafeArea` esterna (aveva senso per un overlay a filo schermo, dentro la card aggiungerebbe l'inset di sistema sotto il footer).
- `minimumSize: Size.fromHeight(49)` sul `FilledButton` scartato: in `Row` dà `BoxConstraints(w=Infinity)` al bottone e il layout esplode. L'altezza 49 esce già dal padding.
- Test: `la toolbar compatta è allineata a Completa la lezione` (nuovo, largo dipinto del pacchetto = lato del FAB quadrato = altezza del bottone, spigolo inferiore in comune, bordo sinistro allineato alla colonna di testo), `la toolbar sta nel footer della card e il FAB la espande` (rinominato: dentro la card, icona che passa da `handyman` a `close`) e `la toolbar apre la calcolatrice e il drag giù la chiude` (finder per chiave `ValueKey('lesson_toolbar_$index')`, `findsOneWidget` → `findsWidgets` per le istanze per pagina). Le rect dipinte del pacchetto non cambiano da espansa, perché i paint bounds includono la pila clip-paintata. Suite: **213 verde**.

## 2026-09-27 — Toolbar lezioni ed esercizi in basso a sinistra, in verticale

- `lesson_screen.dart`: `M3EToolbar` spostata da `Positioned(right: 16)` a `Positioned(left: 16, bottom: 16)`; `axis: Axis.vertical` + `fabPosition: M3EToolbarFabPosition.bottom` → il FAB comprime da 80 a 56 e la pillola degli strumenti si rivela **in alto** invece che a sinistra (`RenderM3EToolbarVerticalFabLayout`). `Transform.scale(1/1.5)` e `SafeArea` invariati.
- `exercise_tools_bar.dart`: `axis: Axis.vertical`, stessa pila verticale in basso a sinistra su `exercise_detail_screen` e `exercise_feed_screen` (niente FAB, barra sempre espansa).
- Appunto: in `Stack`, `Positioned` passa `BoxConstraints.tightFor` con width/height `null` quando sono specificati solo `right`/`bottom` → constraint infiniti, quindi l'`Align` interno del pacchetto già si restringe alla dimensione naturale e l'ancoraggio del `Positioned` è effettivo. Nessun wrapper extra serve.
- Test: +2 (`la toolbar è ancorata in basso a sinistra e si espande in alto`, `la barra strumenti è ancorata in basso a sinistra e verticale` in `test/exercise_tools_bar_test.dart`), entrambi verificano posizione e orientamento geometrici. Suite: **198 verde**.

## 2026-09-23 — Card Prova tu separata in Moduli

- `hs-year2-moduli.json`: la sezione "Prova tu" (equazione $|x-5|=4x$) esce dalla 5ª card "Equazioni con Modulo" e diventa la nuova 6ª card della lezione `mod-equations-intro` → 6 card totali.
- `title` "Prova tu" anche per la 5ª card: la card "Equazioni con Modulo" ora si chiude col takeaway "Verifica le soluzioni".
- Test: "la lezione Modulo e Equazioni con Modulo ha sei card" (6 step, Prova tu non in steps[4], 4x in steps[5]); asserzione stale `steps[3] contains('Esempi pratici')` allineata al dato reale (`x = 5`).
- Test: `fontSizeMultiplier` remove aspettativa 0.85 a livello step (il campo ora vive nei payload `math_formula`). Suite **196 verde**.

## 2026-09-23 — `hidden` nei math_formula sopprime solo la card

- `multifunction_box_widget.dart`: `MathFormulaPayload.hidden` non rende più `SizedBox.shrink` (box nascosto del tutto); ora esclude solo `AppCard` e header titolo e lascia la formula visibile come blocco a sé (`_FormulaView` senza contorno).
- Allineamento col dato reale `hs-year2-moduli.json` (`mod-eq-formula` `|ax + b| = k` con `"hidden": true`): la formula ora si vede.
- Test: "box formula hidden mostra formula senza card" (Math presente, AppCard assente, titolo assente). Suite: **196 verde**.

## 2026-09-23 — Card Esempi pratici separata in Moduli

- `hs-year2-moduli.json`: la card "Modulo ed Espressioni Letterali" (mod-equations-intro) dimezzata — resta teoria + formula; gli esempi con $x=5$/$x=-10$ e il takeaway spostati nella nuova card 4 "Esempi pratici".
- Test: lezione avrà 5 card, verifica contenuto card. Suite: **196 verde**.

## 2026-09-23 — Chiusura calcolatrice con tap fuori

- `scientific_calculator.dart`: barrier trasparente a tutto schermo (tap fuori dalla sheet → `_dismiss()` con animazione di uscita identica al drag). Widget ora occupa full-screen nello Stack: `Align` senza faktor wrapper, gesture foglio con `ValueKey('calc-sheet')`. Scroll del contenuto lezione sopra la sheet resta libero (barrier solo `onTap`, no drag).
- `lesson_screen.dart`: `ScientificCalculatorSheet` in `Positioned.fill` invece di `Positioned(bottom)`.
- Test: 1 nuovo (tap fuori chiude la sheet); finder drag/fling aggiornati alla key foglio. Suite: **196 verde**.

## 2026-09-23 — Fisica drag calcolatrice allineata alla sheet scelta scuola

- `scientific_calculator.dart`: fisica drag della calcolatrice portata a parità con la modal sheet di scelta scuola (`BottomSheet._handleDragEnd`): fling verso il basso >700px/s (`_kMinFlingVelocity`) o trascinamento oltre metà altezza (`_kCloseProgressThreshold` 0.5) → chiude; altrimenti snap back. Follow del dito 1:1: rimosso il clamp a 360px su `_dragOffset`.
- Test: 1 nuovo (drag lento oltre metà altezza chiude). Suite: **195 verde**.

## 2026-09-23 — Chiusura drag calcolatrice meno aggressiva

- `scientific_calculator.dart`: la sheet non si chiude più superando i 120px di trascinamento. Il drag verso il basso ora serve a rivelare momentaneamente il contenuto dietro: al rilascio torna in posizione (snap back) a meno che il gesto non sia volto alla chiusura — fling deciso (>800px/s) oppure trascinamento oltre ~50% dell'altezza reale del foglio (misurata a runtime via `GlobalKey`).
- Test: 1 nuovo (drag parziale lento rivela e riporta su); 2 adattati a fling. Suite: **194 verde**.

## 2026-09-23 — Toolbar lezioni e calcolatrice scientifica

- `lesson_screen.dart`: body in `Stack` con `M3EToolbar` (material_3_expressive) floating in basso a destra. FAB espande/colassa la pillola (morph 80→56); unico tool per ora: **Calcolatrice** (`M3EIcons.calculate_rounded`).
- Nuovo `scientific_calculator.dart`: `ScientificCalculatorSheet` non modale ancorata in basso — scivola su, lascia il contenuto della lezione scrollabile in parallelo (nessuno scrim, hit test sulla sola area), si chiude trascinandola giù (>120px o velocity >800px/s). Griglia scientifica: `sin cos tan ln log`, `√ x² ( ) π`, `abs exp AC ⌫ %`, cifre, `− ± + × ÷ ^ =`.
- `expression_evaluator.dart`: costanti `pi`/`e`, funzioni `sin cos tan ln log sqrt abs exp`; nuovo `tryEvaluate` (restituisce `null` su errore/valore non finito), `evaluate` resta a `0.0`.
- Calcolatrice riusa `ExpressionEvaluator` per il calcolo (`=` → risultato formattato, errori → "Errore").
- Resilienza: su `=` le tonde mancanti vengono chiuse automaticamente (`_autoClose`); `sin(30` → `sin(30)`.
- Modalità angoli: chip tappabile `DEG`/`RAD` nel display (indicazione settaggio attuale); `expression_evaluator` con flag `deg` (`sin/cos/tan` convertiti in radianti, default `false` per i chart). Icône toolbar e contorno ridotte di 1,5 (`Transform.scale`); toolbar sotto la calcolatrice quando aperta; hit-test sheet limitato alla sola area (scroll lezione libero sopra).
- Test: +22 (funzioni/costanti evaluator, tryEvaluate, calcolatrice 6 casi, toolbar→calcolatrice→drag-close). Suite: **191 verde**.

## 2026-09-23 — fontScale per card di lezione

- Nuovo attributo opzionale `fontSizeMultiplier` sugli step JSON delle lezioni: scala il font del testo della card (titolo, contenuto, opzioni MCQ, feedback) senza toccare grafici e padding. Clamp difensivo `0.5–2.0` (default `1.0`).
- `notes_text.dart`: nuovo parametro `fontScale` che scala tutte le dimensioni fisse (title, heading, subheading, mono, corpo, codice inline).
- `lesson_screen.dart`: `_StepCard` applica `step.fontSizeMultiplier` a titolo, `NotesText`, `_OptionTile` e `_FeedbackCard`.
- Demo: step "Equazioni con Modulo" (`mod-equations-intro`) con `fontSizeMultiplier: 0.85` → più contenuto a schermo.
- Test: +2 (`fontScale` scala note, parsing/clamp `fontSizeMultiplier`). Suite: **162 verde**.

## 2026-09-23 — Aria sopra i box nelle note

- `notes_text.dart` `_buildBlock`: i riquadri multifunzione sono avvolti in `Padding(top: 12)` → aria dal testo precedente (il box "Definizione" nella card "Che cos'è il Modulo?" non è più attaccato al testo).
- Test: +1 (margine superiore box). Suite: **163 verde**.

## 2026-09-22 — Box Callout in NotesText

- Nuova sintassi callout `:::chiave` in `notes_text.dart`: apre un box tinto colorato, chiuso da riga vuota, heading `#`/`##`/`###`, altro `:::` o fine contenuto.
- Chiavi: `attenzione|warning|pericolo` → colore `medium` + `warning_amber_rounded` «Attenzione»; `takeaway|suggerimento|consiglio|tip` → colore `accent` + `lightbulb_outline` «Takeaway». Chiave ignota → testo puro (fallback). Testo inline dopo la chiave (`:::takeaway testo`) va nel box; più callout consecutivi restano separati.
- Demo: lezione Moduli `mod-equations-intro` — «Attenzione» (card Esempi pratici) e 2 «Takeaway» (card Espressioni Letterali, Equazioni con Modulo) ora box callout invece di heading.
- Test: 5 nuovi in `notes_text_test.dart`. Suite: **160 verde**.

## 2026-09-22 — Lezione Modulo e Equazioni con Modulo

- Nuova 2ª lezione `mod-equations-intro` nell'argomento Moduli (year2): "Modulo e Equazioni con Modulo" (6 min).
- 3 card didattiche interattive (`info`, content array + box):
  1. "Che cos'è il Modulo?" — formula piecewise, esempi, bar chart "La distanza dallo zero" (barre −7 e 7 alte 7).
  2. "Modulo ed Espressioni Letterali" — piecewise di `|x-3|`, casi $x=5$ / $x=-10$, takeaway su argomento positivo.
  3. "Equazioni con Modulo" — studio del segno, casi di `|x-5|=2`, interactive_chart con serie `x-5`, `k=2`, `k=-2` (intersezioni x=7, x=3), "Prova tu: `|x-5|=4x`".
- Test: repository (Moduli 2 lezioni, 3 card), argomento screen con nuova lezione. Suite: **155 verde**.

## 2026-09-22 — Argomento lezioni Moduli (seconda superiore)

- Nuovo argomento `Moduli` per anno 2 (`assets/data/lessons/hs-year2-moduli.json`) linkato alla sezione `year2-moduli` / topic `year2-moduli-definition`, registrato in `lessons/index.json`.
- Prima lezione `mod-definition` «Definizione»: unica card vuota (step `info` con `content` vuoto) da riempire in futuro.
- Test: repository con 2 argomenti, card vuota Definizione nel player, elenco Moduli in `ArgomentoLessonsScreen`. Suite: **154 verde**.

## 2026-09-22 — Riquadri Multifunzione

Nuova feature: `MultifunctionBox` embedded nel content delle lezioni con sintassi recintata `::box` / `::endbox`.

- **Modelli** (`lib/models/multifunction_box/`):
  - `box_type.dart`: enum `BoxType`, `ChartKind`, `FormulaMode` (fromString + label italiano).
  - `box_payload.dart`: library `sealed class BoxPayload` + parti per i 4 payload.
  - `payloads/`: `image`, `chart` (bar/line/pie), `interactive_chart` (slider `t` + espressioni su `x`/`t`), `math_formula`.
  - `multifunction_box.dart`: nodo comune (`id`, `box_type`, `title`, `payload`) con dispatch polimorfo.
  - `fromJson`/`toJson` per tutti; default robusti, box_type sconosciuto → `image`.
- **Widget**:
  - `expression_evaluator.dart`: parser recursive-descent (`+ - * / ^ %`, parentesi, `x`, `t`); errori → `0.0`.
  - `chart_widgets.dart`: `CustomPainter` nativi — `BarChartPainter`, `LineChartPainter`, `PieChartPainter` (griglia, tick, legenda, autoscale nice).
  - `chart_colors.dart`: mappa `colorKey` → palette app, fallback ciclo `iconPalette`.
  - `interactive_chart_view.dart`: slider parametro live, chips legenda toggle serie.
  - `multifunction_box_widget.dart`: card `AppCard` + header titolo + contenuto per box type.
- **Integrazione**: `notes_text.dart` riconosce `::box` multi-linea e single-line, JSON invalido → testo puro.
- **Test**: 65 nuovi (modello 17, evaluator 23, chart 6, interactive 5, box widget 6, notes_text box + fixture 8). Suite completa: 140 verde.
- Zero nuove dipendenze; grafici offline via CustomPainter.

### Fix da review (round 1)

- `interactive_chart_view.dart`: guard su `step <= 0` → niente divisioni (`divisions: null`), slider non va più in errore.
- `chart_widgets.dart`: `PieChartPainter` clampa valori negativi a 0 (niente sweep negativo); legenda solo se serie > 1, con ellipsis; label x bar/line saltate se più di 6 gruppi; unità (`unit`) mostrata sul tick massimo di bar/line.
- `expression_evaluator.dart`: catch ristretto a `FormatException`/`StackOverflowError` (niente più `catch (_)`).
- `notes_text.dart`: finestra di scan `::endbox` limitata a 200 righe.
- `math_text.dart`: `stripMathDelimiters` reso pubblico, duplicato rimosso da `multifunction_box_widget.dart`.
- `multifunction_box_widget.dart`: formula fullscreen senza `SingleChildScrollView` (pan/zoom via `InteractiveViewer`). → rimosso con expandability, vedi sezione Rimozioni.
- **Test**: +5 (pie valori misti, bar 10 categorie, parentesi estreme, endbox oltre finestra, step zero). Suite completa: **145 verde** (144 dopo rimozione test espansione).
- **Demo**: fixture `notes_mixed_content.txt` esteso con pie valori misti (clamp negativi + legenda) e bar 10 categorie con `unit` (label skip + tick max).

## Lezione reale estesa

- Lezione `eq1-intro` (step 1) in `assets/data/lessons/hs-year1-equations.json` arricchita con 2 card multifunction: `math_formula` "Soluzione generale" (`ax + b = 0 ⟹ x = -b/a`) e `interactive_chart` "La radice al variare di t" (retta `y = 2x + t`, slider `t` −3/3, toggle asse x).

## Content come array

- `LessonStep.content` ora accetta anche **array di segmenti**: stringhe = righe di testo, oggetti = riquadri `MultifunctionBox`; `_contentFromJson` appiattisce a stringa `::box`/`::endbox` in load. `hs-year1-equations.json` riscritto con content array indentato — niente più righe giganti; box JSON human-readable. Compatibile col formato stringa legacy. Test "content come array appiattisce testo e riquadri". Suite: **145 verde**.

## Math formula hidden e title vuoto

- `MathFormulaPayload.hidden` (`"hidden": true`): il box `math_formula` non viene mostrato affatto (`SizedBox.shrink`), niente card né titolo.
- `title` vuoto: header skippato (già) e padding del mini-blocco ridotto (`fromLTRB(16, 8, 16, 8)`).
- Test: round-trip `hidden`, box formua hidden non renderizzato, formula senza titolo non mostra testo. Suite: **148 verde**.
- Fix overflow: `ImageSource` vincola altezza immagine a 200px (`SizedBox` + `ClipRect`) — asset reali (es. `img 1.jpg`) non sovrastano più `maxHeight: 240` e i test non mascherano eccezioni di layout.
- Fixture demo (`notes_mixed_content.txt`): +2 box `math_formula` — uno `hidden` ("Formula nascosta", non renderizzato), uno senza `title` (header assente, card compatta). Test "formula hidden non renderizza e senza titolo compatta" (8 box, 7 card, hidden assente). Suite: **149 verde**.

## Capitolo → Lezioni

- Nuova `ArgomentoLessonsScreen` (`lib/screens/argomento_lessons_screen.dart`): elenco lezioni di un argomento tra livello anno e player.
- Card lezione essenziale: badge numerico a sinistra (indice+1), titolo, sottotitolo, «X min», check "Completata" o chevron; `ListenableBuilder` su `ProgressStore` aggiorna i badge al ritorno.
- `lesson_list_screen.dart` `_openArgomento`: non salta più alla prima lezione — pusha `ArgomentoLessonsScreen`; il player `LessonScreen` resta invariato (completamento → pop alla lista).
- Test: 3 nuovi (`test/argomento_lessons_screen_test.dart`). Suite: **152 verde**.

## Card practice_quiz (step di lezione)

- **Nuovo tipo di step** `LessonStepType.practiceQuiz` (`"type": "practice_quiz"`), non un riquadro multifunzione: è una card a sé nel `PageView` di `LessonScreen`, insieme a `info` e `mcq`. Niente `AppCard` annidata. (Prima versione: `BoxType.practiceQuiz` con `PracticeQuizPayload`, scartata perché produceva una card dentro un'altra card.)
- `LessonStep.exercises` parsato da `exercises[]`: `prompt`, `text?`, `options[]`, `correctIndex`, `explanation?`. Il modello `PracticeExercise` sta in `lib/models/practice_exercise.dart`, fuori dal tree dei box. `correctIndex` fuori range viene ignorato in fase di tap (`hasAnswer`).
- `PracticeQuizView` (`lib/widgets/practice_quiz_view.dart`): **un solo esercizio per volta**, stato pubblico con `reload()`. Il bottone sta nel **footer** della card, a sinistra di «Completa la lezione» (footer che ora contiene anche la toolbar, vedi entry del 2026-09-27), ed estrae il successivo da una coda mescolata; queue svuotata = refill escludendo l'esercizio corrente, quindi niente ripetizioni prima del giro completo. Sparisce con un solo esercizio. Nessun contatore: la card non cambia aspetto. `LessonScreen` tiene una `GlobalKey<PracticeQuizViewState>` per step quiz.
- Il footer della card quiz è allineato a destra (`Row` con `MainAxisAlignment.end`); per `info` e `mcq` il bottone «Completa la lezione» resta a piena larghezza. Con il quiz come ultimo step il bottone compare senza dover risolvere niente.
- `PromptView` (`lib/widgets/prompt_view.dart`): auto-rileva il prompt — percorso/URL immagine (estensione o prefisso `http`) → `ImageSource`, altrimenti `MathText` (quindi matematica mista a testo OK).
- `LessonStep.prompt` aggiunto al modello e parsato da JSON: prima gli step MCQ mostravano solo opzioni e feedback, il prompt era silenziosamente perso.
- Estrazione da `lesson_screen.dart` a widget condivisi: `McqOptionTile` / `McqFeedbackCard` / `ShakeWidget` in `lib/widgets/mcq_option_tile.dart`, usati sia dagli step MCQ sia dalla card. `ImageSource` spostato in `lib/widgets/image_source.dart` (riuso senza ciclo di import).
- Feedback condiviso: corretto → haptic leggero e opzioni disabilitate; sbagliato → haptic pesante e shake. `AnimatedSwitcher` con `layoutBuilder` che scarta il child uscente, così l'esercizio precedente non resta in albero durante la transizione.
- Contenuto: 4 equazioni con modulo in `hs-year2-moduli.json`, nuovo ottavo step `Verifica` di `mod-equations-intro`.
- Test: nuovo `test/practice_quiz_view_test.dart` (4 di modello + 6 di card, incluso il refill a coda svuotata e il tap con `correctIndex` fuori range), in `test/lesson_test.dart` il conteggio step 7 → 8 più 2 test (card di verifica a fine lezione, footer con reload a sinistra del bottone). Nota: dopo gli swipe la `PageView` assorbe i pointer finché lo scroll non è assestato, serve `pump(Duration(seconds: 3))` prima di toccare la card.

## Rimozioni

- **Expandability rimossa**: `is_expandable` rimosso da modello (`MultifunctionBox`), card, fixture e asset lezione; `_openFullscreen` + `Dialog.fullscreen` + `InteractiveViewer` + parametro `fullscreen` di `ImageSource` eliminati. La card non apre più dialog a schermo intero.

## Roadmap

- [ ] Ripulire la renderizzazione degli asset immagine del riquadro usando il pattern placeholder unico.
- [ ] Valutare supporto del riquadro anche nel contenuto degli esercizi (non solo lezioni).
- [ ] Editor visuale del box (solo viewer oggi).