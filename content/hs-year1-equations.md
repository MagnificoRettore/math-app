---
level: high-school
year: year1
section: year1-equations
topic: year1-equations
title: Equazioni di primo grado
subtitle: Guida introduttiva passo-passo
icon: functions
---

# Equazioni di primo grado {id=eq1-intro subtitle="Concetti e risoluzione guidata" minutes=5}

## Cos'è un'equazione
### Cos'è
\
Un'equazione è un'**uguaglianza** tra due espressioni che contiene un'*incognita*, cioè un valore **__sconosciuto__** da trovare.
\
#### Esempio
\
::center
$$2x + 3 = 7$$
\
Risolvere l'equazione significa trovare il valore di $$x$$ che la rende vera.
\
~~Il valore è 10~~ il valore è la soluzione dell'uguaglianza.

## Equazione di primo grado
### Titolo
\
#### Intestazione
\
##### Sottointestazione
\
Questo è il **corpo** del testo, con parola *corsiva*, parola __sottolineata__ e parola ~~barrata~~, anche in combinazione **__grassetto sottolineato__**. Posso usare del codice inline: `x = 2`.
\
::left
La formula è: $$2x + 3 = 7$$ e la soluzione è $$x = 2$$.
\
#### Elenco puntato
\
- primo *punto* dell'elenco
- secondo **punto** dell'elenco
- terzo punto con formula $$x + 1 = 2$$
\
::center
$$x = \frac{7 - 3}{2} = 2$$
\
::right
~~formula errata~~: $x = 3$
\
Blocco monostile:
\
`ax + b = 0`
```formula {id=eq1-formula title="Soluzione generale" hidden=false size=1.2}
ax + b = 0 \quad\Rightarrow\quad x = -\frac{b}{a}
```

## L'equazione come intersezione
L'equazione $$2x - 4 = 0$$ vuol dire che la retta $$y = 2x - 4$$ incontra l'asse $x$.
Nel grafico la soluzione è il punto in cui la retta **tocca zero**: $x = 2$.
```graph {id=eq1-chart-function title="La retta y = 2x - 4" hidden=false}
{
    "plane": "cartesian",
    "x": [-4, 8],
    "y": [-10, 10],
    "grid": 2,
    "items": [
        {"type": "function", "expr": "2 * x - 4", "label": "y = 2x - 4", "color": "accent"},
        {"type": "point", "at": [2, 0], "label": "(2,\\,0)", "color": "orange"}
    ]
}
```

## Verifica {type=mcq}

```quiz
prompt: Qual è la soluzione di $$3x - 1 = 5$$?
- [x] $$x = 2$$
- [ ] $$x = 4$$
- [ ] $$x = 3$$
explanation: Porta $$-1$$ a destra cambiando segno: $$3x = 5 + 1 = 6$$, poi dividi per 3 e ottieni $$x = 2$$.
```
