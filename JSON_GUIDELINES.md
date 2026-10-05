# JSON_GUIDELINES.md — Come si scrivono i contenuti (Markdown → JSON)

Le regole per i file delle lezioni (`content/*.md` e i JSON generati in `assets/data/lessons/`), per chi li scrive, a mano o con Claude. **Si aggiornano man mano**: ogni volta che arriva una regola nuova, va aggiunta qui sotto, nella sezione che le compete, e vale da lì in avanti per tutti i file.

## Come si lavora: Markdown → JSON

Le lezioni **si scrivono in Markdown** (`content/*.md`, un file per argomento). Un compilatore le trasforma nei JSON che legge l'app (`assets/data/lessons/*.json`): **i JSON non si modificano a mano**, sono generati e committati.

```
dart run tool/build_content.dart           # compila content/*.md → assets/data/lessons/*.json (+ index.json)
dart run tool/build_content.dart --check   # non scrive; esce con 1 se i JSON non sono aggiornati
```

Poi: **Ricarica** nell'anteprima (o hot restart) e `flutter test test/content_validation_test.dart`.

Il compilatore (`tool/content/`) è Dart puro. Il test `test/content_markdown_test.dart` controlla che i JSON in assets siano esattamente quelli che escono dai `.md`, che l'esportazione JSON → Markdown → JSON non perda niente, e che gli errori di scrittura siano segnalati con la riga.

## Scrivere una lezione in Markdown

````markdown
---
level: high-school
year: year2
section: year2-rette
topic: year2-rette
title: Le rette
subtitle: Nel piano cartesiano
icon: show_chart
---

# Introduzione {id=rette-intro minutes=6}

## Equazione della retta
Una riga di testo, con una formula $y = mx + q$ e un **grassetto**.
- un punto elenco
\
### Un titolo dentro il testo
```formula {id=rette-explicit size=1.4}
y = mx + q
```
```graph {id=rette-plane title="Una retta"}
{"plane": "cartesian", "x": [-3, 5], "y": [-3, 3], "items": [
    {"type": "function", "expr": "2*x - 2", "color": "accent"}
]}
```

## Prova tu {type=practice_quiz}
```quiz
prompt: assets/images/rette-quiz-1.png
text: Identifica l'espressione della retta mostrata.
- [x] $$y = 2x + 1$$
- [ ] $$y = x + 2$$
explanation: La retta sale ($m > 0$) e incrocia l'asse $y$ in $1$.
```
````

- **Front matter** fra `---`: `level year section topic title subtitle icon` (i primi cinque obbligatori).
- `# Titolo {id=… minutes=… subtitle="…"}`: una **lezione** (`id` obbligatorio). `## Titolo {type=… size=…}`: una **card**. `type` è `info` (di base), `mcq` o `practice_quiz`; `size` è il `fontSizeMultiplier`.
- **Il testo** è una riga per elemento; le righe vuote si ignorano e **`\` da solo** è una riga vuota voluta (uno spazio). Le intestazioni dentro il testo stanno **due livelli sotto** quelle di struttura: `###` titolo, `####` intestazione, `#####` sottointestazione. Elenchi (`- `), callout (`:::takeaway`) e allineamenti (`::center`) restano com'erano nei JSON.
- Il LaTeX si scrive **con un solo backslash** (`\frac`): il compilatore pensa all'escape.
- **Blocchi** (tre apici, con gli attributi fra graffe):
  - ```` ```formula {id=… size=… hidden=false title="…"} ````: il corpo è il LaTeX.
  - ```` ```graph {id=… title="…" hidden=false} ````: il corpo è il JSON del grafico (formato in `AGENTS.md`).
  - ```` ```image {id=… title="…"} ````: il corpo è il percorso dell'immagine.
  - ```` ```quiz ````: `prompt:`, `text:`, `explanation:` e le opzioni `- [ ] …` / `- [x] …` (la giusta è una sola). Una card `mcq` ha un blocco quiz, una `practice_quiz` più d'uno.
- Un'etichetta o un attributo che il compilatore non conosce è un **errore**, non viene ignorato.

Per importare dei JSON scritti a mano: `dart run tool/build_content.dart --import` (JSON → `content/*.md`, una tantum).

## Come si scrivono le cose (convenzioni)

Sono le abitudini delle lezioni già scritte, raccolte qui perché le prossime siano uguali. **Non sono regole date da te finché non le confermi**: correggile o aggiungine, e il file resta l'unico punto di riferimento.

- **Una card, un concetto.** La card si legge su un telefono: frasi brevi, e il titolo della card è breve (poche parole).
- **Una riga di testo per ogni frase o punto.** Niente righe lunghe con più idee; un elenco è fatto di righe `- `.
- **Le formule.** Una formula da sola va in un blocco ```` ```formula ````; dentro una frase si scrive `$x = 2$`. Le lettere e i numeri di una formula sono sempre in LaTeX (`$m$`, `$q$`), anche da soli.
- **Le opzioni dei quiz** sono formule in `$$…$$` quando sono espressioni (`$$y = 2x + 1$$`), testo semplice altrimenti. La spiegazione dice **perché** la risposta è giusta, non solo qual è.
- **Il grassetto** (`**…**`) è per il termine che si definisce, la prima volta che compare.
- **Gli id** sono in kebab-case e cominciano con il nome della lezione (`rette-intro`, `rette-plane`); un id di riquadro è unico nella lezione.
- **L'ultima card** di una lezione è una verifica (`practice_quiz`, «Prova tu»), con almeno 4 esercizi per poterne estrarre uno diverso col reload.
- **Nei grafici** (JSON dentro il blocco) il backslash va raddoppiato (`"\\sin(x)"`), a differenza del testo e delle formule; le etichette sono LaTeX senza `$`; i domini `x` e `y` si scrivono sempre.
- **Il codice dei contenuti** (id, chiavi, `type`) è in inglese, il testo in italiano.

## Grafici interattivi (slider e animazioni)

Un grafico con `params` ha uno slider per parametro e si ridisegna mentre si muovono; è un riquadro `graph` come gli altri.

```graph {id=rette-slider}
{
    "plane": "cartesian",
    "aspect": "equal",
    "x": [-6, 6],
    "y": [-5, 5],
    "params": {
        "m": {"min": -3, "max": 3, "step": 0.5, "value": 1},
        "q": {"min": -4, "max": 4, "step": 0.5, "value": -1, "label": "q"},
        "p": {"min": 0, "max": 6.28, "step": 0.1, "value": 0, "animate": true}
    },
    "items": [
        {"type": "function", "expr": "m*x + q"},
        {"type": "point", "at": [0, "q"], "label": "q"}
    ]
}
```

- **`params`**: un oggetto nome → slider. `min` e `max` obbligatori (`min < max`); `step` (di base un centesimo dell'intervallo), `value` di partenza (di base `min`), `label` LaTeX (di base il nome), `animate: true` aggiunge il tasto che lo fa scorrere da solo avanti e indietro.
- **Il nome** è una lettera o parola (`m`, `q`, `ampiezza`), **non** `x`, `t`, `pi`, `e` né il nome di una funzione (`sin`, `abs`…). Un parametro non valido viene scartato e il test lo segnala.
- **Dove si usano i nomi:** nelle espressioni (`expr`, `under`, `between`, `where`, le `x`/`y` di una `curve`) e come **coordinate** scritte come stringa (`"at": [0, "q"]`, `"radius": "r"`, i punti di un `segment`, `vector`, `polygon`, `line` per due punti…). Una coordinata può essere un'espressione dei parametri (`"m + q"`), non di `x`.
- **`x` e `y` sono obbligatori**: gli assi non si muovono con gli slider.
- Con il movimento ridotto il tasto di animazione non compare.
- Il test di validazione prova il grafico con gli slider ai valori di partenza, tutti al minimo, tutti al massimo e a metà: ogni elemento deve capirsi e ogni funzione dare un valore.

## Formattazione dei JSON generati

Il compilatore scrive i JSON sempre nella stessa forma (e il test la verifica):

- Indentazione di **4 spazi**, UTF-8 senza `\u`, a capo finale.
- **Un array di soli numeri sta su una riga**, con `, ` fra i valori: gli estremi del piano, un punto, i domini.
  ```json
  "x": [-4, 8],
  "y": [-3, 3],
  "at": [2, 0]
  ```
- Un array di coppie di numeri (`"points"`, `"through"`) sta su una riga se ci sta in 100 colonne, altrimenti una coppia per riga.
- Gli altri array (le righe di `content`, le `options`, gli `items`, gli `steps`) vanno un elemento per riga. **Nei grafici dentro il Markdown** un elemento semplice (`{"type": "point", "at": [1, 0], …}`) sta su una riga.
- L'ordine delle chiavi non si tocca.

## Validazione

`flutter test test/content_validation_test.dart` controlla **tutti** i JSON generati (quelli di `index.json`):

- **Dati:** file registrati e viceversa, id delle lezioni unici, campi obbligatori, tipi di card noti, domande con almeno 2 opzioni e `correctIndex` valido, immagini presenti negli asset, formule LaTeX leggibili (anche nelle etichette dei grafici), `$` senza compagno, id dei riquadri unici nella lezione, nessun elemento di un grafico scartato in silenzio, funzioni che danno almeno un valore.
- **Resa:** ogni card di ogni lezione (e ogni esercizio delle verifiche) viene disegnata con i font veri su **320×640, 360×800, 393×852, 412×915 e un tablet 600×960**, con il testo del sistema a ×1.0 e a ×1.3; qualsiasi overflow o errore di disegno fa fallire il test e dice lezione, card, schermo e scala.

Va lanciato dopo ogni modifica ai contenuti. Larghezza minima supportata: 320 px.

## Anteprima (solo in debug)

In un'app in debug: Personalizzazione → **Sviluppo → Anteprima lezioni**. Elenca tutte le lezioni; scelta una, la apre dentro una cornice della dimensione di un telefono (gli stessi cinque schermi del test) con la scala del testo a ×1.0, ×1.3 o ×1.6. Dopo aver modificato un `.md` e compilato (`dart run tool/build_content.dart`), **«Ricarica»** (la freccia in alto) rilegge i file e riapre la stessa lezione da capo. In debug Flutter segna a strisce gialle e nere ogni overflow, quindi si vede subito se una formula o un grafico non ci sta in 320 px.

## Struttura di un file

- Un file per argomento, registrato in `assets/data/lessons/index.json`.
- Id in kebab-case (`rette-intro`, `rette-plane`); `year` e `section`/`topic` coerenti con i JSON degli esercizi quando c'è un topic dello stesso nome.
- Il formato di `content`, dei box (`image`, `math_formula`, `graph`) e degli step (`info`, `mcq`, `practice_quiz`) è in `AGENTS.md`, sezione «Contenuto e formattazione».

## Regole di contenuto

### Box `math_formula` e `graph`

- **`hidden` è `true` di base** (campo `payload.hidden`): senza scriverlo, la formula o il grafico stanno da soli, **senza card e senza titolo**. Per avere la card col titolo si scrive `"hidden": false`. Non si scrive mai `"hidden": true`: è il default.
- Negli argomenti di prima (`equations`, `esempio`, `moduli`) le formule e i grafici che stavano in card hanno `"hidden": false`, per non cambiare aspetto.

_(Le altre regole di contenuto vanno qui sotto.)_
