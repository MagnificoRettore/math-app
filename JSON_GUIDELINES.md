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

## Struttura di un file

- Un file per argomento, registrato in `assets/data/lessons/index.json`.
- Id in kebab-case (`rette-intro`, `rette-plane`); `year` e `section`/`topic` coerenti con i JSON degli esercizi quando c'è un topic dello stesso nome.
- Il formato di `content`, dei box (`image`, `math_formula`, `graph`) e degli step (`info`, `mcq`, `practice_quiz`) è in `AGENTS.md`, sezione «Contenuto e formattazione».

## Regole di contenuto

### Box `math_formula` e `graph`

- **`hidden` è `true` di base** (campo `payload.hidden`): senza scriverlo, la formula o il grafico stanno da soli, **senza card e senza titolo**. Per avere la card col titolo si scrive `"hidden": false`. Non si scrive mai `"hidden": true`: è il default.
- Nei file di prima (`equations`, `esempio`, `moduli`) le formule e i grafici che stavano in card hanno `"hidden": false`, per non cambiare aspetto.

_(Le altre regole di contenuto vanno qui sotto.)_
