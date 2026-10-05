# DESIGN.md — Il sistema visivo dell'app

Il riferimento per com'è fatta l'app e per come vanno fatte le parti nuove: colori, caratteri, forme, componenti, illustrazioni e movimento. I dettagli d'implementazione e le trappole tecniche stanno in `AGENTS.md`; qui c'è il **cosa** e il **perché**.

**Va tenuto aggiornato**: ogni modifica che cambia l'aspetto o il movimento dell'app aggiorna la sezione che tocca e aggiunge una riga allo [Storico](#storico).

---

## 1. Fonte e principi

La fonte è il canvas **«Illustrazioni App Educativa»** (claude.ai/artifact/UjtXU3sEDTVdSC7RuCYdjX): le tavole «Componenti UI» e «Creazione profilo» per l'interfaccia, quattro tavole di illustrazioni.

- **Un quaderno colorato, non un'app da ufficio.** Indaco profondo e giallo su un fondo crema, caratteri geometrici, oggetti di scuola (la spirale, matite, il biglietto del traguardo).
- **Solo i bottoni si sollevano, con un gradino pieno, non con un'ombra sfumata.** Sotto il bottone c'è un gradino di colore pieno, più scuro del suo; premuto, il bottone scende sul gradino. **Le card hanno solo un'ombra fine e bassa**, che le stacca dal crema senza farle galleggiare.
- **Un tema solo, chiaro.** Il canvas non ha una versione scura.
- **Il colore decora, il contrasto si rispetta.** I colori del canvas restano per riempimenti e decori; come testo si usano toni scuri della stessa famiglia, sempre oltre 4.5:1.
- **Si muove poco e in fretta.** 120–300 ms, curve morbide, e niente movimento per chi l'ha chiesto al sistema.

---

## 2. Colori

Tutti in `AppPalette` (`lib/theme/app_colors.dart`), letti con `AppColors.of(context)`. **Mai un colore scritto in un widget.**

### Base

| Token | Valore | Ruolo | Contrasto (bianco / crema) |
|---|---|---|---|
| `background` | `#FFF4D6` | Fondo delle pagine (crema) | — |
| `surface` | `#FFFFFF` | Card, campi, fogli | — |
| `textPrimary` | `#1F1250` | Testo, «inchiostro» sui fondi chiari e gialli | 16.7 / 15.2 |
| `textSecondary` | `#574E7D` | Testo secondario, etichette | 7.5 / 6.9 |
| `accent` | `#2B1A6B` | Indaco: primary, bottone principale, bordo col fuoco | 14.4 / 13.1 |
| `accentSoft` | `#ECE7FA` | Lilla chiaro: fondi di funzioni e piastre | — |
| `border` | `#CFC7E6` | Bordo lilla dei controlli a riposo | — |
| `headerBand` / `onHeaderBand` | `#2B1A6B` / `#FFFFFF` | Fascia della barra di navigazione e testata di registrazione e benvenuto, coi loro testi (bianco 14.4:1). **Non** l'header delle pagine principali | — |

### Colori del canvas (decoro, riempimento, gradini)

| Token | Valore | Uso |
|---|---|---|
| `yellow` | `#F6B818` | Bottone secondario, badge, barra, anno scelto. Sopra l'inchiostro (9.4:1), mai il bianco |
| `yellowDeep` | `#B98500` | Gradino e bordo del giallo, strisce della barra |
| `yellowSoft` | `#FBE7A8` | Fondo della barra di avanzamento |
| `orange` | `#EF7D1A` | Card «Traguardo», bottone tondo play. Sopra l'inchiostro (6.0:1) |
| `orangeDeep` | `#B65508` | Gradino del bottone tondo play; l'arancio dei grafici, perché `orange` su bianco non arriva a 3:1 |
| `accentDeep` | `#160C3E` | Gradino del bottone indaco |
| `borderDeep` | `#9A92C2` | Gradino del lilla: sotto il cerchio di Home spento nella barra di navigazione |
| `disabled` / `onDisabled` | `#E4DFD4` / `#6F6A86` | Bottone disabilitato, grigio caldo (3.9:1: i controlli disabilitati sono esenti da WCAG) |

### Ruoli che finiscono come testo

Toni scuri della famiglia del canvas: il verde, l'arancio e il rosso del canvas su bianco stanno sotto 4.5:1.

| Token | Valore | Ruolo | Contrasto (bianco / crema) |
|---|---|---|---|
| `easy` | `#2E7D32` | Giusto, completato, «Facile» | 5.1 / 4.7 |
| `medium` | `#B14D06` | «Da ripassare», «TRAGUARDO» | 5.3 / 4.9 |
| `hard` | `#C0391B` | Errore, distruttivo | 5.5 / 5.0 |
| `indigo` | `#463589` | Badge «Lezione» | 9.9 / 9.0 |
| `purple` | `#5048D6` | Colore di argomento | 6.5 / 5.9 |
| `pink` | `#C2406B` | Colore di argomento | 5.0 / 4.5 |
| `teal` | `#1F8577` | Colore di argomento, icone e barre | 4.5 / 4.1 — **non per testo piccolo** |
| `danger` | `#8B1B34` | Terziario: le sezioni «da ripassare» | 9.1 / 8.3 |

`iconPalette` (`#2B1A6B`, `#EF7D1A`, `#2FB3A2`, `#C2406B`, `#5048D6`, `#B98500`, `#2E7D32`) colora icone, serie dei grafici e cerchi degli avatar.

In `ColorScheme` il primary, il secondario (giallo, con l'inchiostro sopra) e il terziario sono dichiarati a mano: `fromSeed` darebbe un altro viola.

---

## 3. Caratteri

Due famiglie, **in locale** in `assets/fonts/` (statiche, un file per peso, licenze OFL): l'app non va in rete.

- **Outfit** (SemiBold 600) — `AppText.headingFont`: titoli di pagina e di riquadro, bottoni, `AppBar` e il nome nella banda dell'header. Sempre 600.
- **Plus Jakarta Sans** (Regular 400, Medium 500) — `AppText.bodyFont`: tutto il resto, compreso il corpo delle lezioni (titoli, intestazioni e grassetto a 500). Le etichette dei controlli sono Medium 500; non si usano pesi più alti.

**Scala** (`AppText`, `lib/theme/app_text.dart`, mai un numero scritto). Le misure non cambiano:

| Interfaccia | px | Documento delle lezioni | px |
|---|---|---|---|
| `display` | 26 | `docTitle` | 24 |
| `hero` | 23 | `docHeading` | 19 |
| `headline` | 21 | `docBody` | 15 |
| `title` | 19 | `docMono` | 12.5 |
| `titleLarge` | 18 | | |
| `titleMedium` | 16 | | |
| `titleSmall` | 15 | | |
| `bodyLarge` | 14 | | |
| `bodyMedium` | 13.5 | | |
| `bodySmall` | 13 | | |
| `label` | 12.5 | | |
| `labelSmall` | 12 | | |
| `caption` | 11.5 | | |
| `micro` | 11 — il pavimento | | |

**Caratteri che mancano** (verificati sulla tabella `cmap` dei file). Outfit non ha `π √ ∞ ≤ ≥ Σ` né gli apici `⁻ ˣ ʸ ⁿ`; Plus Jakarta Sans ha `π √ ∞ ⁻ ≤ ≥` ma non `ˣ ʸ ⁿ Σ`; nessuno dei due ha `⌫`. Sul web il carattere di riserva andrebbe scaricato, quindi le etichette li evitano (`1/x`, `x^y`, `asin`, ⌫ come icona), dove servono `π` o `√` si usa il carattere del testo, e la `Σ` della tavola del razzo è disegnata come tracciato.

**`RichText` non eredita il carattere**: il corpo delle lezioni (`NotesText`, `MathText`) e ogni stile che sostituisce quello ereditato (`AnimatedDefaultTextStyle`) dicono `AppText.bodyFont`, altrimenti finirebbero nel carattere di sistema.

---

## 4. Forme, bordi e gradini

| Elemento | Raggio | Bordo | Gradino |
|---|---|---|---|
| Bottone (`AppButton`) | pillola | contorno: 3 `accent` | 5 px pieno, colore `…Deep` |
| Card (`AppCard`) | 20 (`kCardRadius`) | nessuno; 3 `accent` se scelta | nessuno; ombra fine (`cardShadow`) |
| Campo di testo | 14 | 3 `border`, 3 `accent` col fuoco, 3 `hard` in errore | — |
| Menu dell'anno e filtri (`ListFilterBar`) | 20 (pillola da 40) | 2 `accent` il menu, 2 `border` i filtri; attivo 2 `yellowDeep` su `yellow` | — |
| Opzione di risposta | 14 | 3 `border`, poi il colore dello stato | — |
| Barra di avanzamento alta | 4 | 2 `yellowDeep` | — |
| Card «Traguardo» | 18 | — | nessuno; ombra fine (`cardShadow`) |
| Banda dell'header | in basso 28 | — | — |
| Barra di navigazione | in alto 28; Home tonda | Home: 6 `background` | Home: 5 px pieno, `yellowDeep` accesa, `borderDeep` spenta |
| Illustrazione | 10% della larghezza | — | — |

**Il gradino è un'ombra senza sfumatura** (`BoxShadow` con `blurRadius` 0 e uno scostamento verticale) e **vale solo per i bottoni**, compreso il cerchio di Home della barra di navigazione. Le card non hanno gradino ma **un'ombra fine**, l'unica sfumata del design: `cardShadow` (`lib/widgets/app_card.dart`), `shadow` (indaco al 12%) con blur 10, scostata di 3 in basso. Vale per `AppCard`, la card «Traguardo» e le card del carosello, che ha la lista senza ritaglio (`Clip.none`) perché l'ombra scenda sotto la striscia. Nessun'altra ombra sfumata.

---

## 5. Spazi e impaginazione

- **Margine di pagina 20** (`EdgeInsets.fromLTRB(20, 8, 20, 24)`): titoli e card stanno sulla stessa linea, e le sezioni non aggiungono un margine proprio.
- **La Home è tre sezioni**, in quest'ordine: la serie di giorni (card «Traguardo»), gli argomenti con la testata «Argomenti», la missione. **24 fra le sezioni**, 12–14 fra le card di una lista.
- **Area di tocco almeno 44 px**: bottoni da 52 (o 44 più il gradino), anni da 44, avatar da 52.
- Il carosello degli argomenti è l'unica striscia che **va da bordo a bordo**: scavalca i 20 di margine e li rimette come padding. Senza ombra sulle card, sotto la striscia non serve più spazio per il gradino, e la lista taglia sul suo bordo.

---

## 6. Componenti

### Header — `MainHeaderAppBar` (`lib/widgets/main_header.dart`)
Banda **del colore dello sfondo**, a tutta larghezza (non si stacca dalla pagina). Identità a sinistra (avatar con anello lilla e badge di modifica, nome in Outfit 600 `textPrimary`, scuola `textSecondary`), lente e personalizzazione in `textPrimary` a destra. Profilo, personalizzazione e ricerca **si espandono dal pulsante**: un cerchio che cresce dal suo centro in `AppMotion.slow` e tornando indietro si ritira (`reveal.dart`). Gli anni stanno **sotto** la banda, sullo sfondo. Nelle sotto-pagine che la tengono (l'argomento) c'è la freccia indietro prima dell'avatar.

### Barra di navigazione — `PillNavBar` (`lib/widgets/pill_nav_bar.dart`)
Dalla tavola «Navbar» del canvas. È alta 92 e ha una fascia `headerBand` di 72 a tutta larghezza, con gli angoli in alto a 28; sotto gli angoli c'è la pagina. Sta solo sulle tre pagine principali, e il contenuto sta sopra di lei.
- **Lezioni ed Esercizi** stanno ai lati, sulla fascia, avvicinati a Home: le tre colonne rientrano di 28 dai bordi. Hanno un'icona a tratto da 28 (il libro aperto, il foglio con la spunta e la matita), il nome in Outfit 600 da 14 e sotto un trattino 22×4. Quella scelta è `yellow` col trattino; le altre sono `border`, senza trattino.
- **Home** sta al centro: un cerchio da 70 che sporge sopra la fascia, con il bordo `background` da 6, il gradino pieno da 5 e la casa a tratto `textPrimary` da 30. Acceso è `yellow` su `yellowDeep`, spento `surface` su `borderDeep`. **Premuto scende sul gradino come un bottone**; i lati no. Sotto il cerchio c'è il nome, colorato come i lati.
- Lo stato lo dicono il colore e, allo screen reader, «selezionato». Non c'è un indicatore che scorre né il trascinamento.

### Bottone — `AppButton` (`lib/widgets/app_button.dart`)
Pillola in Outfit 600 alta 52, sollevata da un gradino di 5 px.
- `primary`: indaco, testo bianco, gradino `accentDeep`.
- `secondary`: giallo, testo inchiostro, gradino `yellowDeep`; anche sui fondi indaco, dove l'indaco sparirebbe.
- `outline`: bianco, bordo e testo indaco.
- Disabilitato: grigio caldo, giù e senza gradino. Occupato: la rotella al posto del testo.
- Premuto: la faccia scende di tutto il gradino e il gradino sparisce.

Nelle schermate non si usano `FilledButton` né `OutlinedButton`.

### Card — `AppCard` (`lib/widgets/app_card.dart`)
Bianca, raggio 20, **senza gradino e con l'ombra fine** `cardShadow`, comprese quelle del carosello. Varianti fatte nelle schermate:
- **Serie** (`HeaderStreakChip`): pillola da 36 nell'header, a sinistra dell'ingranaggio, con una fiamma da 20 e il numero in Outfit 600; fiamma e bordo arancio se oggi si è studiato, grigi altrimenti. Il foglio è come quello delle scuole (crema, bordo lilla da 3, angoli da 28): la serie, sette tondi da 38 per la settimana (arancio con fiamma i giorni della serie, oggi col bordo indaco) e il record. La vecchia card «Traguardo» è tolta.
- **Scelta** (`SchoolLevelTile`): bordo indaco da 3.

### Campi — `AppTheme.fieldDecoration`
Fondo bianco, bordo da 3 lilla, indaco col fuoco, rosso nell'errore; l'etichetta sale in indaco Medium 500. I campi del dialog di Google restano sottolineati.

### Barra di avanzamento — `ProgressBar` (`lib/widgets/progress_bar.dart`)
Da 10 px in su: fondo `yellowSoft`, bordo `yellowDeep`, riempimento giallo a strisce verticali (2 px ogni 12). Sotto i 10 px: piena e arrotondata, nel colore che si passa.

### Selezioni
- **Anno e filtri** (`ListFilterBar`): in cima a Lezioni ed Esercizi, una riga di pillole da 40: il menu dell'anno (bianco, bordo indaco, freccia) e «Tutti»/«In corso» (gialla col bordo oro quando è attiva, bianca col bordo lilla altrimenti), **senza spunta**. Sotto, la card «Riprendi da dove eri rimasto» (`ResumeCard`) e la griglia a due colonne (`TopicGrid`): icona colorata, titolo in Outfit 600 e «N lezioni · P%».
- **Avatar** (`AvatarPicker`): cerchi colorati a turno (giallo, turchese, arancio, lilla) con l'icona inchiostro; scelto con bordo indaco e due anelli, bianco e giallo.
- **Opzioni di risposta** (`McqOptionTile`): bordo da 3, verde giusta, rosso sbagliata, indaco scelta.

### Segno «completata» — `CompletedBadge` (`lib/widgets/completed_badge.dart`)
Una spunta bianca in un tondino `easy` da 26, con il bordo bianco da 2 perché si legga anche sui fondi colorati. Sta **nell'angolo in alto a destra**, a 10 dai bordi, di ogni card completata: gli argomenti nella pagina Lezioni e nel carosello della Home (completato = tutte le sue lezioni) e le lezioni nella pagina dell'argomento. La freccia a destra resta. Allo screen reader dice «Completata».

### Badge
Pillola gialla con l'inchiostro Medium 500. I badge di stato e di tipo usano il colore del ruolo su un fondo dello stesso colore al 12–14%.

### Stati vuoti — `EmptyState`
Un'illustrazione (l'albero, o il razzo per i meriti), il titolo in Outfit e una riga di spiegazione; scorre se la pagina è bassa.

### Testata ondulata — `WaveBottomClipper` (`lib/widgets/wave_clipper.dart`)
Il bordo in basso della testata di «Creazione profilo», scalato sul riquadro: nel benvenuto (con gli angoli in alto arrotondati) e nella registrazione a passi (a filo dello schermo).

**Nella registrazione il bordo ondeggia**: con `phase` (un `AnimationController` da 6 s che si ripete, `reclip` del clipper) i punti del bordo oscillano di ±7 unità della tavola con sfasamenti diversi, e il tracciato torna uguale a ogni giro. Solo il tracciato del ritaglio si rifà a ogni frame: il contenuto sta in un `RepaintBoundary`. Col movimento ridotto il bordo sta fermo. Il contenuto del passo parte 28 px sotto la testata, lontano dalla punta dell'onda.

### Bottoni della lezione (`LessonScreen`)
**Galleggiano sopra le card e restano fermi** mentre le card scorrono, sul fondo della card e a filo della sua colonna di testo: la toolbar degli strumenti a sinistra, il reload della verifica (`AppButton` `outline` solo icona) e «Completa la lezione» a destra, tutti alti 49 col gradino. Ognuno c'è solo dove serve per la card corrente, e compare o sparisce con una dissolvenza e una scala da 0.8 in `medium`. Il testo della card scorre fin sopra di loro.

Il FAB degli strumenti e il pannello che si apre sono **indaco come la barra di avanzamento della lezione**, con le icone bianche. I colori del FAB vengono da `AppTheme.lessonToolbar`, un tema di `material_3_expressive`: il pacchetto non legge il `Theme` di Flutter, e senza resterebbe sul lilla di default di Material 3.

### Grafici — `GraphView` (`lib/widgets/graph/`)
Grafici **non interattivi** dal JSON delle lezioni (riquadro `graph`), dentro una card bianca col titolo.
- **Piano cartesiano**: assi per l'origine con le frecce e i nomi in LaTeX, griglia nei due sensi, numeri in Plus Jakarta Sans 11 col meno «−» e un alone bianco, «O» all'origine. Funzioni a 2.6 px con i buchi rispettati (niente verticali agli asintoti), rette a 2 px (tratteggiate per asintoti e guide), punti pieni con un anello bianco.
- **Geometria e regioni**: circonferenze e poligoni a 2.2 px, segmenti con gli estremi a punto, vettori con una punta piena da 11; aree, regioni e figure piene del colore dell'elemento al 16%, sotto tutto, così la griglia si vede attraverso. Il bordo di una regione è continuo per `≤`/`≥` e tratteggiato per `<`/`>`.
- **Retta numerica**: la retta con la freccia e i soli numeri che contano sotto; sopra, una riga per intervallo con la barra da 4 e gli estremi da 5.5, pieni se inclusi e vuoti (fondo bianco, bordo del colore) se esclusi, e una guida tratteggiata alla retta; i punti stanno sulla retta. Etichette in LaTeX sopra la barra, con lo spazio per una frazione fra due righe.
- **Barre**: griglia orizzontale, base sullo zero, barre a angoli superiori arrotondati (5), categorie sotto.
- **Etichette in LaTeX**: funzioni e curve in legenda sotto il grafico (trattino del colore più la formula), punti e rette accanto, figure sul piano (al centro, sopra il cerchio, accanto al segmento), su una piastrina bianca all'88%.
- **Colori**: ogni elemento il suo, da una sequenza ben distinta — indaco, arancio scuro, turchese, rosa, verde, viola — tutti oltre 3:1 su bianco. L'arancio è `orangeDeep`.
- **Proporzioni**: tre quarti della larghezza; con `aspect: equal` la stessa unità sui due assi (una circonferenza è rotonda).
- **Movimento**: all'ingresso le curve si tracciano, i riempimenti si accendono e i punti compaiono (`slow`), una volta sola; col movimento ridotto è già tutto lì.

### Calcolatrice
Tasti da 40: cifre bianche col bordo da 3, operatori gialli e `=` indaco col gradino pieno, funzioni lilla, AC e ⌫ in rosso. Etichette in Plus Jakarta Sans Medium 500. I tasti restano bottoni e quindi tengono il loro gradino.

---

## 7. Illustrazioni

Le quattro tavole del canvas, in SVG statico in `assets/illustrations/`, mostrate da `IllustrationView` (proporzioni 600:720, angoli arrotondati, decorative per lo screen reader).

| `AppIllustration` | Soggetto | Dove |
|---|---|---|
| `idea` | Lampadina con gli strumenti | Splash |
| `lezione` | Laptop con calcolatrice e grafici | Gli esercizi |
| `albero` | Albero che cresce dal libro | La scuola; stati vuoti «in arrivo» |
| `razzo` | Razzo che decolla dal libro | La serie; stati vuoti di merito |

Una tavola nuova si converte come le altre: sfondo fissato, `<use>` espansi col colore scritto, testi in Plus Jakarta Sans 500; un carattere che manca (come la `Σ`) si disegna come tracciato.

---

## 8. Movimento

Durate e curve stanno in **`AppMotion`** (`lib/theme/app_motion.dart`), mai un letterale.

| Costante | Valore | Per |
|---|---|---|
| `fast` | 120 ms | Il tocco (bottone che scende) |
| `medium` | 200 ms | Un cambio di stato (colore, bordo, titolo) |
| `slow` | 300 ms | Entrate, rimbalzi, scosse, barre |
| `stagger` | 60 ms | Lo scarto fra un elemento e il successivo in un'entrata in sequenza |
| `standard` | `easeOut` | Quasi tutto |
| `bounce` | `easeOutBack` | Rimbalzi |

| Interazione | Cosa succede |
|---|---|
| Bottone premuto | Scende di 5 px e il gradino va a zero; torna su al rilascio |
| Avatar scelto | Cresce a 1.08 col rimbalzo; bordo e anelli crescono |
| Anno scelto | Colore, bordo e testi in `medium`; nessuna spunta |
| Bottoni della lezione | Compaiono e spariscono con dissolvenza e scala da 0.8 in `medium`, solo sulle card dove servono |
| Sezione della barra di navigazione | Il trattino dei lati cambia colore in `medium`; il cerchio di Home in `fast`, e premuto scende di 5 px col gradino a zero |
| Barra di avanzamento | Il riempimento va al valore nuovo; al primo disegno è già lì |
| Passi della registrazione | Il contenuto entra con dissolvenza e scorrimento laterale (avanti da destra, indietro da sinistra); il titolo cambia in dissolvenza |
| Home | Le sezioni entrano in sequenza al primo caricamento, una volta sola |
| Risposta giusta | L'opzione fa un pop (1 → 1.06 → 1); la spunta entra in scala |
| Risposta sbagliata, campo obbligatorio vuoto | Scossa: quattro oscillazioni di 10 px che si smorzano |
| Bordo di un campo al fuoco | Già animato da Flutter (167 ms) |

**Regole.**
- **Movimento ridotto**: con `MediaQuery.disableAnimations` le animazioni non partono (`AppMotion.duration` dà zero); lo stato cambia lo stesso.
- **Implicite prima di tutto** (`AnimatedContainer`, `AnimatedScale`, `TweenAnimationBuilder`). `flutter_animate` solo per gli effetti combinati che finiscono (entrate), mai su un elemento sempre presente: ogni `Animate` lascia un timer al montaggio. Il ritardo va negli effetti, non in `Animate.delay`.
- **Niente movimenti ripetuti**: un'entrata vale una volta; scorrendo o tornando su una pagina gli elementi sono già al loro posto.

---

## 9. Accessibilità

- Testo almeno 4.5:1 sul suo fondo; i colori del canvas non passano e restano decoro.
- Area di tocco almeno 44 px.
- I bottoni e i controlli di scelta (anni, avatar) si annunciano come bottoni allo screen reader, con lo stato «selezionato»; le barre dicono la percentuale; le illustrazioni sono decorative. Un componente nuovo fa lo stesso. Senza la spunta, lo stato «selezionato» dell'anno passa solo dall'annuncio e dall'evidenziazione.
- La scala del testo del sistema vale anche per le formule e i grafici.
- Il movimento ridotto si rispetta ovunque.

---

## 10. Fare e non fare

| Fare | Non fare |
|---|---|
| Colori da `AppPalette`, caratteri da `AppText`, tempi da `AppMotion` | Scrivere colori, misure di testo o durate nei widget |
| Gradino pieno sotto i bottoni; sotto le card solo `cardShadow` | Altre ombre sfumate, ombre larghe o scure, aloni, sfumature di sfondo, gradini sulle card |
| Inchiostro sul giallo e sull'arancio | Bianco sul giallo |
| `AppButton` per ogni bottone d'azione | `FilledButton`, `OutlinedButton`, `ElevatedButton` nelle schermate |
| Bordo da 3 sui controlli che si scelgono | Bordi da 1 sui controlli |
| Outfit 600 per i titoli, Plus Jakarta Sans 400 o 500 per il resto | Altri caratteri, Outfit oltre 600, Plus Jakarta Sans oltre 500 |
| Un'illustrazione del canvas negli stati vuoti | Icone grandi in grigio |
| Tema chiaro | Varianti scure di componenti |

---

## 11. Dove sta cosa

| Cosa | File |
|---|---|
| Colori | `lib/theme/app_colors.dart`, `lib/theme/chart_palette.dart` |
| Caratteri | `lib/theme/app_text.dart`, `assets/fonts/` |
| Tema, campi, tema della toolbar delle lezioni | `lib/theme/app_theme.dart` |
| Movimento | `lib/theme/app_motion.dart` |
| Bottone, card, barra | `lib/widgets/app_button.dart`, `app_card.dart`, `progress_bar.dart` |
| Selezioni | `lib/widgets/year_tabs.dart`, `avatar_picker.dart`, `mcq_option_tile.dart`, `school_level_tile.dart` |
| Scossa | `lib/widgets/shake.dart` |
| Header, testata ondulata | `lib/widgets/main_header.dart`, `wave_clipper.dart` |
| Barra di navigazione | `lib/widgets/pill_nav_bar.dart` |
| Illustrazioni | `lib/widgets/illustration.dart`, `assets/illustrations/` |
| Stati vuoti | `lib/widgets/empty_state.dart` |
| Segno «completata» | `lib/widgets/completed_badge.dart` |
| Grafici | `lib/widgets/graph/` (`graph_view.dart`, `graph_painter.dart`, `graph_layout.dart`, `graph_scale.dart`), `lib/theme/chart_palette.dart` |

---

## Storico

Una riga per ogni modifica al design, la più recente in alto.

| Data | Modifica |
|---|---|
| 2026-10-05 | Barra dei filtri: la ricerca è una pillola come le altre; tutte le pillole hanno il gradino pieno e scendono premute (4), il filtro attivo resta giù. Nuova pagina di feedback (tipo come filtri, campo, «Invia», ringraziamento nel tondo giallo). |
| 2026-10-05 | Serie nell'header (pillola con fiamma) al posto della card «Traguardo» in Home; toolbar degli strumenti più grande (62, icone large). La calcolatrice si trascina verso il basso seguendo il dito. |
| 2026-10-05 | Foglio di scelta della scuola: fondo crema con bordo lilla da 3 e angoli da 28, tondo giallo con il cappello accanto al titolo, scuole come card bianche; entra in `slow`. La ricerca di Lezioni ed Esercizi passa dall'header alla barra dei filtri, fissa a destra. |
| 2026-10-05 | Lezioni ed Esercizi con una nuova impaginazione (il menu dell'anno è un foglio bianco col bordo lilla da 3 e angoli da 20, voci a pillola, la scelta gialla col bordo oro): menu dell'anno e filtri in cima (via gli `YearTabs`), card «Riprendi», griglia a due colonne al posto delle liste di card e delle immagini dei topic. |
| 2026-10-05 | Le schede della guida mostrano una schermata vera dell'app (390×844, angoli `kCardRadius`, ombra fine) al posto dell'icona nel tondo giallo. |
| 2026-10-05 | Bordo della testata di registrazione che ondeggia (leggero, fermo col movimento ridotto) e contenuto più staccato; curiosità «Lo sapevi?» che si scrive a macchina al tocco; cambio fra le sezioni con uno scorrimento laterale del 20% più dissolvenza; icona della personalizzazione sostituita da un ingranaggio; guida all'app a cinque schede con un tondo giallo e un'icona. |
| 2026-10-05 | Icona dell'app (segnaposto): una «π» gialla in Plus Jakarta Sans 500 con il gradino `yellowDeep` sotto, su `headerBand` a angoli arrotondati; la versione «maskable» ha il simbolo nell'80% centrale. Solo web (`web/icons`, `favicon.png`); colori del manifest e titolo «Math App». |
| 2026-10-05 | Pagina dell'esercizio: soluzione guidata passo dopo passo (una domanda a scelta multipla alla volta, il passaggio si appende quando si indovina) per gli esercizi che hanno le domande; il percorso in alto va a capo. |
| 2026-10-05 | Esercizi: topic senza immagine di sfondo (solo il colore sfumato); toolbar degli strumenti identica a quella delle lezioni (`AppToolsBar`) su elenco e pagina dell'esercizio, con la calcolatrice funzionante al posto delle azioni vuote. |
| 2026-10-05 | Argomenti: card del carosello più alte (1,15 × la larghezza, tutte uguali); barra di progresso nelle card degli argomenti; card delle lezioni senza alone; pulsante «Vai agli esercizi» in basso a destra della pagina dell'argomento; formule sole nei quiz delle lezioni alla stessa altezza del testo. |
| 2026-10-05 | Home e navigazione: header del colore dello sfondo (via l'indaco, che resta alla barra di navigazione); pagine che si espandono dal pulsante di profilo, personalizzazione e ricerca; «Jump Back In» sempre dopo la serie, con gli stati ospite e vuoto; card «Lo sapevi?» dopo la missione (design provvisorio); swipe orizzontale fra Lezioni, Home ed Esercizi, mentre l'anno si cambia solo dagli `YearTabs`. |
| 2026-10-05 | Registrazione rifatta: testata con la sola freccia e il titolo al centro (via «PASSO X DI N» e barra), avatar grande al centro che apre sopra di sé il rettangolo degli avatar, errori dei campi solo dopo «Continua», metro della password a tutta larghezza con la scritta sotto, passo dell'anno per medie e superiori e riepilogo animato a profilo creato. Barra di progresso nelle card degli argomenti (pagina Lezioni). |
| 2026-10-05 | Piccole correzioni: onboarding senza illustrazioni e splash senza animazione Lottie; campo password con il lucchetto; «Password dimenticata?» centrata; registrazione senza Google; card delle lezioni senza alone; meno spazio fra serie e «Argomenti» (`SectionHeader.top`). |
| 2026-10-04 | Bottoni della lezione fuori dalle card: toolbar, reload e «Completa la lezione» galleggiano fermi sul fondo della card, ognuno solo dove serve, e compaiono con dissolvenza e scala. Il reload diventa un `AppButton` `outline`. |
| 2026-10-04 | Segno «completata» uguale per tutte le card di argomenti e lezioni: spunta bianca in un tondino verde nell'angolo in alto a destra, anche nel carosello. Prima l'argomento aveva una pillola «Completata» e la lezione una spunta al posto della freccia. |
| 2026-10-04 | Card con un'ombra fine (`cardShadow`: `shadow`, blur 10, 3 in basso) su `AppCard`, la card «Traguardo» e le card del carosello; prima erano piatte. |
| 2026-10-04 | Card «Traguardo» alta la metà: via le barre degli obiettivi di oggi, record sulla riga di «TRAGUARDO», settimana a 26, quattro tagliandi. |
| 2026-10-04 | Barra di navigazione: Lezioni ed Esercizi più vicini a Home (colonne rientrate di 28 dai bordi). |
| 2026-10-04 | Barra di navigazione rifatta dalla tavola «Navbar» del canvas: fascia indaco a tutta larghezza con gli angoli in alto a 28, Lezioni ed Esercizi ai lati col trattino giallo, Home in un cerchio che sporge col bordo crema e il gradino pieno, che premuto scende come un bottone; fascia da 72, barra da 92. Via la pillola in vetro e il trascinamento; nuovo `borderDeep`. La Home è serie, argomenti (con la testata «Argomenti») e missione: via la card «riprendi», «Per te» e i punti deboli. |
| 2026-10-04 | Caratteri: Outfit (600) al posto di Fredoka, Plus Jakarta Sans (400, 500) al posto di Nunito; etichette dei controlli, badge e corpo delle lezioni (titoli, intestazioni, grassetto) a 500; il nome nella banda in Outfit. Card piatte, anche nel carosello e la card «Traguardo»; card «riprendi» senza righe; anno scelto senza spunta. Via `cardShadow` e `paperLine`; `orangeDeep` resta per il play e i grafici. La `Σ` del razzo è un tracciato. |
| 2026-10-04 | Grafici, fase 3: retta numerica con intervalli a righe, estremi pieni o vuoti, punti sulla retta. |
| 2026-10-04 | Grafici, fase 2: curve parametriche, circonferenze, segmenti e vettori, poligoni, aree e regioni di disequazioni; riempimenti al 16% e bordi continui o tratteggiati. |
| 2026-10-04 | Grafici delle lezioni rifatti (`graph` al posto di `chart`): piano cartesiano vero con assi per l'origine, frecce, griglia nei due sensi e numeri in Nunito; etichette in LaTeX; colori ben distinti; niente sfumature sotto le curve; barre con lo stesso stile. |
| 2026-10-04 | Toolbar delle lezioni indaco come la barra di avanzamento (FAB e pannello, icone bianche); prima restava sul lilla di default di Material 3. |
| 2026-10-04 | Nasce `DESIGN.md`, a partire dal design già in uso. |
| 2026-10-04 | Micro-interazioni: `AppMotion`; bottoni che scendono sul gradino; rimbalzo dell'avatar; anni animati con spunta; barra animata; registrazione a passi con testata ondulata e passi che entrano di lato; entrata in sequenza della Home; pop e scossa sulle risposte; scossa dei campi obbligatori vuoti. |
| 2026-10-03 | Fase 3, le schermate: illustrazioni in splash, onboarding e stati vuoti; testata ondulata del benvenuto; card «riprendi» a quaderno; serie di giorni come card «Traguardo»; titoli in Fredoka. |
| 2026-10-03 | Fase 2, i componenti: `AppButton` col gradino; card col gradino oro; campi col bordo da 3; barra gialla a strisce; anni come la «Classe» del canvas; avatar con gli anelli; play tondo arancio; calcolatrice nello stile del canvas. |
| 2026-10-03 | Fase 1, i fondamenti: palette del canvas, Fredoka e Nunito in locale, un tema solo chiaro, banda dell'header indaco. |
