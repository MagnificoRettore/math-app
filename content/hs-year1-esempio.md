---
level: high-school
year: year1
section: year1-esempio
topic: year1-esempio-argomento
title: Esempio argomento
subtitle: Tutti i grafici delle lezioni
icon: show_chart
---

# Funzioni e punti {id=ex-arg-funzioni subtitle="Una parabola e un'iperbole sul piano cartesiano" minutes=3}

## Una parabola
La parabola $y = x^2 - 2x - 3$ taglia l'asse $x$ dove $y = 0$, cioè in $x = -1$ e $x = 3$.
```graph {id=ex-parabola title="y = x² − 2x − 3" hidden=false}
{
    "x": [-3, 5],
    "y": [-5, 6],
    "grid": 1,
    "items": [
        {
            "type": "function",
            "expr": "x^2 - 2*x - 3",
            "label": "y = x^2 - 2x - 3",
            "color": "accent"
        },
        {"type": "point", "at": [-1, 0], "label": "A(-1,\\,0)", "color": "orange"},
        {"type": "point", "at": [3, 0], "label": "B(3,\\,0)", "color": "orange"},
        {"type": "point", "at": [1, -4], "label": "V(1,\\,-4)", "guides": true, "color": "teal"}
    ]
}
```
Il **vertice** $V(1, -4)$ sta a metà fra le due intersezioni: le guide tratteggiate ne leggono le coordinate sugli assi.

## Un'iperbole e i suoi asintoti
La funzione $y = \frac{1}{x - 2} + 1$ non esiste in $x = 2$: lì il grafico si spezza.
```graph {id=ex-iperbole title="y = 1/(x − 2) + 1" hidden=false}
{
    "x": [-4, 8],
    "y": [-5, 7],
    "grid": 1,
    "items": [
        {
            "type": "function",
            "expr": "1/(x - 2) + 1",
            "label": "y = \\frac{1}{x-2} + 1",
            "color": "accent"
        },
        {"type": "line", "x": 2, "style": "dashed", "label": "x = 2", "color": "orange"},
        {"type": "line", "y": 1, "style": "dashed", "label": "y = 1", "color": "orange"}
    ]
}
```
Le rette tratteggiate sono gli **asintoti**: la curva si avvicina sempre di più, senza toccarle.

# Geometria analitica {id=ex-arg-geometria subtitle="Circonferenze, triangoli, vettori e curve" minutes=3}

## Una circonferenza
La circonferenza di centro $C(1, 1)$ e raggio $3$ è l'insieme dei punti a distanza $3$ da $C$.
```graph {id=ex-circonferenza title="Centro C(1, 1), raggio 3" hidden=false}
{
    "x": [-4, 6],
    "y": [-4, 6],
    "aspect": "equal",
    "grid": 1,
    "items": [
        {
            "type": "circle",
            "center": [1, 1],
            "radius": 3,
            "fill": true,
            "label": "\\mathcal{C}",
            "color": "accent"
        },
        {"type": "segment", "from": [1, 1], "to": [1, 4], "label": "r = 3", "color": "orange"},
        {"type": "point", "at": [1, 1], "label": "C", "color": "accent"}
    ]
}
```
Sui due assi l'unità è la stessa: per questo la circonferenza è rotonda e non schiacciata.

## Un triangolo e un vettore
```graph {id=ex-triangolo title="Triangolo ABC e vettore v" hidden=false}
{
    "x": [-1, 7],
    "y": [-1, 5],
    "aspect": "equal",
    "grid": 1,
    "items": [
        {
            "type": "polygon",
            "points": [[0, 0], [4, 0], [1, 3]],
            "label": "T",
            "color": "teal"
        },
        {"type": "point", "at": [0, 0], "label": "A", "color": "teal"},
        {"type": "point", "at": [4, 0], "label": "B", "color": "teal"},
        {"type": "point", "at": [1, 3], "label": "C", "color": "teal"},
        {"type": "vector", "from": [4, 0], "to": [6, 3], "label": "\\vec v", "color": "pink"}
    ]
}
```
Il vettore $\vec v$ va da $(4, 0)$ a $(6, 3)$: le sue componenti sono $(2, 3)$.

## Una curva parametrica
Un'**ellisse** si descrive con un parametro $t$: $x = 3\cos t$, $y = 2\sin t$, con $t$ da $0$ a $2\pi$.
```graph {id=ex-ellisse title="Ellisse di semiassi 3 e 2" hidden=false}
{
    "x": [-4, 4],
    "y": [-3, 3],
    "aspect": "equal",
    "grid": 1,
    "items": [
        {
            "type": "curve",
            "x": "3*cos(t)",
            "y": "2*sin(t)",
            "t": [0, 6.2832],
            "label": "x = 3\\cos t,\\ y = 2\\sin t",
            "color": "purple"
        }
    ]
}
```

# Aree e disequazioni {id=ex-arg-disequazioni subtitle="Regioni del piano e intervalli sulla retta" minutes=4}

## L'area fra due curve
La retta $y = x + 2$ e la parabola $y = x^2$ si incontrano in $x = -1$ e $x = 2$. Fra i due punti la retta sta sopra.
```graph {id=ex-area title="Area fra y = x + 2 e y = x²" hidden=false}
{
    "x": [-3, 4],
    "y": [-1, 6],
    "grid": 1,
    "items": [
        {
            "type": "area",
            "between": [
                "x + 2",
                "x^2"
            ],
            "from": -1,
            "to": 2,
            "label": "A",
            "color": "accent"
        },
        {"type": "function", "expr": "x + 2", "label": "y = x + 2", "color": "orange"},
        {"type": "function", "expr": "x^2", "label": "y = x^2", "color": "accent"}
    ]
}
```

## Una regione del piano
Il sistema $y \ge x^2 - 4$ e $y < 2 - x$ è la parte di piano **sopra** la parabola e **sotto** la retta.
```graph {id=ex-regione title="y ≥ x² − 4 e y < 2 − x" hidden=false}
{
    "x": [-5, 4],
    "y": [-5, 7],
    "grid": 1,
    "items": [
        {
            "type": "region",
            "where": [
                "y >= x^2 - 4",
                "y < 2 - x"
            ],
            "label": "R",
            "color": "accent"
        }
    ]
}
```
Il bordo della parabola è **continuo** perché il $\ge$ lo include; quello della retta è **tratteggiato** perché il $<$ lo esclude.

## Un sistema sulla retta numerica
Le soluzioni di $x \ge -1$ e di $x < \frac{5}{3}$ si disegnano una per riga; la soluzione del sistema è dove valgono **entrambe**.
```graph {id=ex-retta title="Sistema di disequazioni" hidden=false}
{
    "plane": "numberLine",
    "items": [
        {"type": "interval", "set": "[-1, +inf[", "label": "x \\ge -1", "color": "orange"},
        {"type": "interval", "set": "]-inf, 5/3[", "label": "x < \\frac{5}{3}", "color": "teal"},
        {"type": "interval", "set": "[-1, 5/3[", "label": "S", "color": "accent"}
    ]
}
```
Il pallino **pieno** in $-1$ dice che l'estremo è incluso, quello **vuoto** in $\frac{5}{3}$ che è escluso.

## {type=mcq}

```quiz
prompt: $$\begin{cases} x \ge -1 \\ x < \frac{5}{3} \end{cases}$$
- [x] $$\left[-1,\ \frac{5}{3}\right[$$
- [ ] $$\left]-1,\ \frac{5}{3}\right]$$
- [ ] $$\left[-1,\ +\infty\right[$$
- [ ] $$\left]-\infty,\ \frac{5}{3}\right[$$
explanation: Valgono entrambe da $-1$ incluso fino a $\frac{5}{3}$ escluso: $\left[-1, \frac{5}{3}\right[$.
```

# Grafici a barre {id=ex-arg-barre subtitle="Confrontare due serie di dati" minutes=2}

## Minuti di studio
Le barre confrontano due settimane giorno per giorno: con due serie compare la legenda.
```graph {id=ex-barre title="Minuti di studio al giorno" hidden=false}
{
    "plane": "bars",
    "xLabel": "",
    "yLabel": "min",
    "categories": [
        "Lun",
        "Mar",
        "Mer",
        "Gio",
        "Ven"
    ],
    "series": [
        {"label": "\\text{Settimana 1}", "color": "accent", "values": [20, 35, 15, 40, 25]},
        {"label": "\\text{Settimana 2}", "color": "orange", "values": [30, 25, 45, 35, 50]}
    ]
}
```
Nella seconda settimana lo studio è cresciuto in quattro giorni su cinque.

# Grafici interattivi {id=ex-arg-interattivi subtitle="Slider e animazioni sui parametri" minutes=3}

## Una retta con due slider
Muovi gli slider: $m$ cambia l'inclinazione della retta, $q$ la sposta in alto o in basso.
```graph {id=ex-int-retta}
{
    "plane": "cartesian",
    "aspect": "equal",
    "x": [-6, 6],
    "y": [-5, 5],
    "grid": 1,
    "params": {
        "m": {"min": -3, "max": 3, "step": 0.5, "value": 1},
        "q": {"min": -4, "max": 4, "step": 0.5, "value": -1}
    },
    "items": [
        {"type": "function", "expr": "m*x + q", "label": "y = mx + q", "color": "accent"},
        {"type": "point", "at": [0, "q"], "label": "q", "color": "orange"}
    ]
}
```
Il punto arancio sta sempre sull'asse $y$, all'altezza di $q$.

## Un'onda che si muove
Con il tasto di riproduzione la fase scorre da sola; l'ampiezza si regola a mano.
```graph {id=ex-int-onda}
{
    "plane": "cartesian",
    "x": [-7, 7],
    "y": [-4, 4],
    "grid": 1,
    "params": {
        "a": {"min": 0.5, "max": 3, "step": 0.25, "value": 1.5},
        "p": {"min": 0, "max": 6.28, "step": 0.1, "value": 0, "animate": true}
    },
    "items": [
        {"type": "function", "expr": "a*sin(x - p)", "label": "y = a\\sin(x - p)", "color": "teal"}
    ]
}
```

# Una parabola con tre slider {id=ex-arg-parabola subtitle="Il vertice e l'asse di simmetria seguono i parametri" minutes=3}

## Muovi i coefficienti
La parabola $y = ax^2 + bx + c$: con $a$ cambia l'apertura, con $b$ e $c$ si sposta. Il punto arancio è il vertice e la retta tratteggiata l'asse di simmetria.
```graph {id=ex-par-grafico}
{
    "plane": "cartesian",
    "x": [-6, 6],
    "y": [-6, 8],
    "grid": 1,
    "params": {
        "a": {"min": 0.25, "max": 2, "step": 0.25, "value": 1},
        "b": {"min": -4, "max": 4, "step": 0.5, "value": 0},
        "c": {"min": -4, "max": 4, "step": 0.5, "value": -2}
    },
    "items": [
        {"type": "function", "expr": "a*x^2 + b*x + c", "label": "y = ax^2 + bx + c", "color": "accent"},
        {"type": "line", "x": "-b/(2*a)", "style": "dashed", "color": "teal"},
        {"type": "point", "at": ["-b/(2*a)", "c - b*b/(4*a)"], "label": "V", "color": "orange"}
    ]
}
```
Il vertice sta sempre sull'asse di simmetria, in $x = -\frac{b}{2a}$.
