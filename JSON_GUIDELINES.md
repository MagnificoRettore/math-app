# JSON_GUIDELINES.md — Come si scrivono i JSON dei contenuti

Le regole per i file in `assets/data/lessons/` (e per chi li scrive, a mano o con Claude). **Si aggiornano man mano**: ogni volta che arriva una regola nuova, va aggiunta qui sotto, nella sezione che le compete, e vale da lì in avanti per tutti i file.

## Formattazione

Dopo ogni modifica a un JSON dei contenuti:

```
python3 tool/format_json.py          # formatta tutti i file di assets/data/lessons
python3 tool/format_json.py --check  # non scrive; esce con 1 se qualcosa è da formattare
```

Lo script (`tool/format_json.py`) non cambia il contenuto, solo gli spazi, e **è lui la forma di riferimento**: se una regola di formattazione cambia, si cambia lo script e si riformattano tutti i file.

Regole in vigore:

- Indentazione di **4 spazi**, codifica UTF-8 senza `\u`, una riga vuota (a capo) alla fine del file.
- **Un array di soli numeri sta su una riga**, con `, ` fra i valori: gli estremi del piano, un punto, i domini.
  ```json
  "x": [-4, 8],
  "y": [-3, 3],
  "at": [2, 0]
  ```
  Mai così:
  ```json
  "y": [
      -3,
      3
  ]
  ```
- Un array di coppie di numeri (`"points"`, `"through"`) sta su una riga se ci sta in 100 colonne, altrimenti una coppia per riga, ognuna su una riga.
- Gli altri array (le righe di `content`, le `options`, gli `items`, gli `steps`) vanno **un elemento per riga**.
- L'ordine delle chiavi non si tocca.

## Validazione

`flutter test test/content_validation_test.dart` controlla **tutti** i JSON di `index.json`:

- **Dati:** file registrati e viceversa, id delle lezioni unici, campi obbligatori, tipi di card noti, domande con almeno 2 opzioni e `correctIndex` valido, immagini presenti negli asset, formule LaTeX leggibili (anche nelle etichette dei grafici), `$` senza compagno, id dei riquadri unici nella lezione, nessun elemento di un grafico scartato in silenzio, funzioni che danno almeno un valore, formattazione secondo questo file.
- **Resa:** ogni card di ogni lezione (e ogni esercizio delle verifiche) viene disegnata con i font veri su **320×640, 360×800, 393×852, 412×915 e un tablet 600×960**, con il testo del sistema a ×1.0 e a ×1.3; qualsiasi overflow o errore di disegno fa fallire il test e dice lezione, card, schermo e scala.

Va lanciato dopo ogni modifica ai contenuti. Larghezza minima supportata: 320 px.

## Struttura di un file

- Un file per argomento, registrato in `assets/data/lessons/index.json`.
- Id in kebab-case (`rette-intro`, `rette-plane`); `year` e `section`/`topic` coerenti con i JSON degli esercizi quando c'è un topic dello stesso nome.
- Il formato di `content`, dei box (`image`, `math_formula`, `graph`) e degli step (`info`, `mcq`, `practice_quiz`) è in `AGENTS.md`, sezione «Contenuto e formattazione».

## Regole di contenuto

### Box `math_formula` e `graph`

- **`hidden` è `true` di base** (campo `payload.hidden`): senza scriverlo, la formula o il grafico stanno da soli, **senza card e senza titolo**. Per avere la card col titolo si scrive `"hidden": false`. Non si scrive mai `"hidden": true`: è il default.
- Nei file di prima (`equations`, `esempio`, `moduli`) le formule e i grafici che stavano in card hanno `"hidden": false`, per non cambiare aspetto.

_(Le altre regole di contenuto vanno qui sotto.)_
