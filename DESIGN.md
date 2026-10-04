# DESIGN.md — Il sistema visivo dell'app

Il riferimento per com'è fatta l'app e per come vanno fatte le parti nuove: colori, caratteri, forme, componenti, illustrazioni e movimento. I dettagli d'implementazione e le trappole tecniche stanno in `AGENTS.md`; qui c'è il **cosa** e il **perché**.

**Va tenuto aggiornato**: ogni modifica che cambia l'aspetto o il movimento dell'app aggiorna la sezione che tocca e aggiunge una riga allo [Storico](#storico).

---

## 1. Fonte e principi

La fonte è il canvas **«Illustrazioni App Educativa»** (claude.ai/artifact/UjtXU3sEDTVdSC7RuCYdjX): le tavole «Componenti UI» e «Creazione profilo» per l'interfaccia, quattro tavole di illustrazioni.

- **Un quaderno colorato, non un'app da ufficio.** Indaco profondo e giallo su un fondo crema, caratteri tondi, oggetti di scuola (righe del quaderno, spirale, matite, il biglietto del traguardo).
- **Le cose si sollevano con un gradino pieno, non con un'ombra sfumata.** Bottoni e card hanno sotto un gradino di colore pieno, più scuro del loro; premuto, il bottone scende sul gradino.
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
| `headerBand` / `onHeaderBand` | `#2B1A6B` / `#FFFFFF` | Banda dell'header e i suoi testi (bianco 14.4:1, all'80% 9.6:1) | — |

### Colori del canvas (decoro, riempimento, gradini)

| Token | Valore | Uso |
|---|---|---|
| `yellow` | `#F6B818` | Bottone secondario, badge, barra, anno scelto. Sopra l'inchiostro (9.4:1), mai il bianco |
| `yellowDeep` | `#B98500` | Gradino e bordo del giallo, strisce della barra |
| `yellowSoft` | `#FBE7A8` | Fondo della barra di avanzamento |
| `orange` | `#EF7D1A` | Card «Traguardo», bottone tondo play. Sopra l'inchiostro (6.0:1) |
| `orangeDeep` | `#B65508` | Gradino dell'arancio |
| `accentDeep` | `#160C3E` | Gradino del bottone indaco |
| `cardShadow` | `#E3C46E` | Gradino oro delle card |
| `paperLine` | `#CFDCF3` | Righe del quaderno |
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

- **Fredoka** (500, 600) — `AppText.headingFont`: titoli di pagina e di riquadro, bottoni, `AppBar`. Sempre 600.
- **Nunito** (400, 600, 700, 800) — `AppText.bodyFont`: tutto il resto. Le etichette dei controlli sono 800.

**Scala** (`AppText`, `lib/theme/app_text.dart`, mai un numero scritto):

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

**Caratteri che mancano.** Nunito non ha `⁻ ˣ ʸ ⁿ ⌫`; Fredoka non ha nemmeno `π √ ∞`. Sul web il carattere di riserva andrebbe scaricato, quindi le etichette li evitano (`1/x`, `x^y`, `asin`, ⌫ come icona) e dove servono `π` o `√` si usa Nunito.

---

## 4. Forme, bordi e gradini

| Elemento | Raggio | Bordo | Gradino |
|---|---|---|---|
| Bottone (`AppButton`) | pillola | contorno: 3 `accent` | 5 px pieno, colore `…Deep` |
| Card (`AppCard`) | 20 (`kCardRadius`) | nessuno; 3 `accent` se scelta | 6 px `cardShadow` |
| Campo di testo | 14 | 3 `border`, 3 `accent` col fuoco, 3 `hard` in errore | — |
| Anno (`YearTabs`) | 12 | 3 `border`; scelto 3 `yellowDeep` su `yellow` | — |
| Opzione di risposta | 14 | 3 `border`, poi il colore dello stato | — |
| Barra di avanzamento alta | 4 | 2 `yellowDeep` | — |
| Card «Traguardo» | 18 | — | 6 px `orangeDeep` |
| Banda dell'header | in basso 28 | — | — |
| Illustrazione | 10% della larghezza | — | — |

**Il gradino è un'ombra senza sfumatura** (`BoxShadow` con `blurRadius` 0 e uno scostamento verticale). Le ombre sfumate non fanno parte del design.

---

## 5. Spazi e impaginazione

- **Margine di pagina 20** (`EdgeInsets.fromLTRB(20, 8, 20, 24)`): titoli e card stanno sulla stessa linea, e le sezioni non aggiungono un margine proprio.
- **24 fra le sezioni della Home**, 12–14 fra le card di una lista.
- **Area di tocco almeno 44 px**: bottoni da 52 (o 44 più il gradino), anni da 44, avatar da 52.
- Il carosello degli argomenti è l'unica striscia che **va da bordo a bordo**: scavalca i 20 di margine e li rimette come padding.

---

## 6. Componenti

### Header — `MainHeaderAppBar` (`lib/widgets/main_header.dart`)
Banda indaco appoggiata al bordo dello schermo, angoli in basso a 28, sotto gli angoli lo sfondo. Identità a sinistra (avatar con badge di modifica, nome, scuola all'80% di bianco), lente e personalizzazione bianche a destra. Gli anni stanno **sotto** la banda, sullo sfondo. Nelle sotto-pagine che la tengono (l'argomento) c'è la freccia indietro prima dell'avatar.

### Bottone — `AppButton` (`lib/widgets/app_button.dart`)
Pillola in Fredoka 600 alta 52, sollevata da un gradino di 5 px.
- `primary`: indaco, testo bianco, gradino `accentDeep`.
- `secondary`: giallo, testo inchiostro, gradino `yellowDeep`; anche sui fondi indaco, dove l'indaco sparirebbe.
- `outline`: bianco, bordo e testo indaco.
- Disabilitato: grigio caldo, giù e senza gradino. Occupato: la rotella al posto del testo.
- Premuto: la faccia scende di tutto il gradino e il gradino sparisce.

Nelle schermate non si usano `FilledButton` né `OutlinedButton`.

### Card — `AppCard` (`lib/widgets/app_card.dart`)
Bianca, raggio 20, gradino oro. Varianti fatte nelle schermate:
- **Quaderno** (card «riprendi»): righe `paperLine` ogni 35 px e cinque anelli della spirale a sinistra; il testo parte a 50.
- **Traguardo** (`StreakCard`): arancio, tagliandi bianchi a sinistra, striscia chiara a destra; contenuti su riquadri bianchi.
- **Scelta** (`SchoolLevelTile`): bordo indaco da 3.

### Campi — `AppTheme.fieldDecoration`
Fondo bianco, bordo da 3 lilla, indaco col fuoco, rosso nell'errore; l'etichetta sale in indaco 800. I campi del dialog di Google restano sottolineati.

### Barra di avanzamento — `ProgressBar` (`lib/widgets/progress_bar.dart`)
Da 10 px in su: fondo `yellowSoft`, bordo `yellowDeep`, riempimento giallo a strisce verticali (2 px ogni 12). Sotto i 10 px: piena e arrotondata, nel colore che si passa.

### Selezioni
- **Anni** (`YearTabs`): quadrati da 44, la «Classe» del canvas. Scelto: giallo, bordo oro, spunta indaco nell'angolo.
- **Avatar** (`AvatarPicker`): cerchi colorati a turno (giallo, turchese, arancio, lilla) con l'icona inchiostro; scelto con bordo indaco e due anelli, bianco e giallo.
- **Opzioni di risposta** (`McqOptionTile`): bordo da 3, verde giusta, rosso sbagliata, indaco scelta.

### Badge
Pillola gialla con l'inchiostro 800 («In corso», «Da iniziare»). I badge di stato e di tipo usano il colore del ruolo su un fondo dello stesso colore al 12–14%.

### Stati vuoti — `EmptyState`
Un'illustrazione (l'albero, o il razzo per i meriti), il titolo in Fredoka e una riga di spiegazione; scorre se la pagina è bassa.

### Testata ondulata — `WaveBottomClipper` (`lib/widgets/wave_clipper.dart`)
Il bordo in basso della testata di «Creazione profilo», scalato sul riquadro: nel benvenuto (con gli angoli in alto arrotondati) e nella registrazione a passi (a filo dello schermo).

### Toolbar delle lezioni (`M3EToolbar` in `LessonScreen`)
Il FAB degli strumenti e il pannello che si apre sono **indaco come la barra di avanzamento della lezione**, con le icone bianche. I colori del FAB vengono da `AppTheme.lessonToolbar`, un tema di `material_3_expressive`: il pacchetto non legge il `Theme` di Flutter, e senza resterebbe sul lilla di default di Material 3.

### Calcolatrice
Tasti da 40: cifre bianche col bordo da 3, operatori gialli e `=` indaco col gradino pieno, funzioni lilla, AC e ⌫ in rosso. Etichette in Nunito 800.

---

## 7. Illustrazioni

Le quattro tavole del canvas, in SVG statico in `assets/illustrations/`, mostrate da `IllustrationView` (proporzioni 600:720, angoli arrotondati, decorative per lo screen reader).

| `AppIllustration` | Soggetto | Dove |
|---|---|---|
| `idea` | Lampadina con gli strumenti | Splash |
| `lezione` | Laptop con calcolatrice e grafici | Onboarding, gli esercizi |
| `albero` | Albero che cresce dal libro | Onboarding, la scuola; stati vuoti «in arrivo» |
| `razzo` | Razzo che decolla dal libro | Onboarding, la serie; stati vuoti di merito |

Una tavola nuova si converte come le altre: sfondo fissato, `<use>` espansi col colore scritto, testi in Nunito.

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
| Anno scelto | Colore, bordo e testi in `medium`; spunta che entra col rimbalzo |
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
- I bottoni e i controlli di scelta (anni, avatar) si annunciano come bottoni allo screen reader, con lo stato «selezionato»; le barre dicono la percentuale; le illustrazioni sono decorative. Un componente nuovo fa lo stesso.
- La scala del testo del sistema vale anche per le formule e i grafici.
- Il movimento ridotto si rispetta ovunque.

---

## 10. Fare e non fare

| Fare | Non fare |
|---|---|
| Colori da `AppPalette`, caratteri da `AppText`, tempi da `AppMotion` | Scrivere colori, misure di testo o durate nei widget |
| Gradino pieno sotto bottoni e card | Ombre sfumate, aloni, sfumature di sfondo |
| Inchiostro sul giallo e sull'arancio | Bianco sul giallo |
| `AppButton` per ogni bottone d'azione | `FilledButton`, `OutlinedButton`, `ElevatedButton` nelle schermate |
| Bordo da 3 sui controlli che si scelgono | Bordi da 1 sui controlli |
| Fredoka 600 per i titoli, Nunito per il resto | Altri caratteri, o Fredoka in grassetto oltre 600 |
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
| Illustrazioni | `lib/widgets/illustration.dart`, `assets/illustrations/` |
| Stati vuoti | `lib/widgets/empty_state.dart` |

---

## Storico

Una riga per ogni modifica al design, la più recente in alto.

| Data | Modifica |
|---|---|
| 2026-10-04 | Toolbar delle lezioni indaco come la barra di avanzamento (FAB e pannello, icone bianche); prima restava sul lilla di default di Material 3. |
| 2026-10-04 | Nasce `DESIGN.md`, a partire dal design già in uso. |
| 2026-10-04 | Micro-interazioni: `AppMotion`; bottoni che scendono sul gradino; rimbalzo dell'avatar; anni animati con spunta; barra animata; registrazione a passi con testata ondulata e passi che entrano di lato; entrata in sequenza della Home; pop e scossa sulle risposte; scossa dei campi obbligatori vuoti. |
| 2026-10-03 | Fase 3, le schermate: illustrazioni in splash, onboarding e stati vuoti; testata ondulata del benvenuto; card «riprendi» a quaderno; serie di giorni come card «Traguardo»; titoli in Fredoka. |
| 2026-10-03 | Fase 2, i componenti: `AppButton` col gradino; card col gradino oro; campi col bordo da 3; barra gialla a strisce; anni come la «Classe» del canvas; avatar con gli anelli; play tondo arancio; calcolatrice nello stile del canvas. |
| 2026-10-03 | Fase 1, i fondamenti: palette del canvas, Fredoka e Nunito in locale, un tema solo chiaro, banda dell'header indaco. |
