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
L'equazione della retta è la seguente:
```formula {id=rette-explicit size=1.4}
y = mx + q
```
Questa è la sua **forma esplicita**: il parametro $y$ è esplicitato e la retta ha la sua forma in funzione $y = f(x)$.
In alternativa abbiamo la **forma implicita**:
```formula {id=rette-implicit size=1.3}
ax + by + c = 0
```
NOTA: $m$ e $q$ possono essere ricavati dalla forma implicita:
```formula {id=rette-mq size=1.0}
m = -\frac{a}{b} \quad q = -\frac{c}{b}
```

## Nel piano cartesiano
Tenendo in considerazione $y = mx + q$:
```graph {id=rette-plane}
{
    "plane": "cartesian",
    "aspect": "equal",
    "x": [-3, 5],
    "y": [-3, 3],
    "grid": 1,
    "xLabel": "x",
    "yLabel": "y",
    "items": [
        {"type": "function", "expr": "2*x - 2", "color": "accent"},
        {"type": "point", "at": [1, 0], "label": "P", "color": "orange"},
        {"type": "point", "at": [0, -2], "label": "q", "color": "orange"},
        {"type": "point", "at": [2, 2], "label": "m", "guides": true, "color": "teal"}
    ]
}
```
- **$m$ = coefficiente angolare**
- rappresenta l'inclinazione della retta;
- equivale all'ordinata del punto che ha distanza 1 dal punto d'intersezione $P$ con l'asse $x$.
- **$q$ = termine noto**
- è l'ordinata d'intersezione con l'asse $y$.

## Casi particolari
#### Rette orizzontali e verticali
```graph {id=rette-hv title="y = n e x = m"}
{
    "plane": "cartesian",
    "aspect": "equal",
    "x": [-3, 5],
    "y": [-2, 3],
    "grid": 1,
    "xLabel": "x",
    "yLabel": "y",
    "items": [
        {"type": "line", "y": 2, "label": "y = n", "color": "accent"},
        {"type": "line", "x": 3, "label": "x = m", "color": "orange"},
        {"type": "point", "at": [0, 2], "label": "n", "color": "accent"},
        {"type": "point", "at": [3, 0], "label": "m", "color": "orange"}
    ]
}
```
NOTA: la retta orizzontale ha $m = 0$; la retta verticale non ha coefficiente angolare e non si scrive in forma esplicita.
#### Bisettrici
Sono le rette con $q = 0$ e $m = \pm 1$.
```graph {id=rette-bisectors title="y = x e y = -x"}
{
    "plane": "cartesian",
    "aspect": "equal",
    "x": [-4, 4],
    "y": [-3, 3],
    "grid": 1,
    "xLabel": "x",
    "yLabel": "y",
    "items": [
        {"type": "function", "expr": "x", "label": "y = +x", "color": "accent"},
        {"type": "function", "expr": "-x", "label": "y = -x", "color": "orange"}
    ]
}
```
NOTA: se $m > 0$ la retta è crescente, se $m < 0$ è decrescente.

## Come disegnarla
Per esempio, disegniamo:
```formula {id=rette-example size=1.4}
y = 2x - 1
```
Per disegnare una retta basta conoscere **2 suoi punti di passaggio**. Li si può identificare mediante la **tabella dei punti**: si assegna un valore a piacimento a $x$ (o a $y$) e si trova il rispettivo valore dell'incognita che risolve l'equazione.
```formula {id=rette-calc-0 size=1.0}
x=0 \to y=2\cdot 0-1=-1
```
```formula {id=rette-calc-1 size=1.0}
x=1 \to y=2\cdot 1-1=1
```
```formula {id=rette-table size=1.2}
\begin{array}{c|c} x & y \\ \hline 0 & -1 \\ 1 & 1 \end{array}
```
```graph {id=rette-draw title="y = 2x - 1"}
{
    "plane": "cartesian",
    "aspect": "equal",
    "x": [-3, 4],
    "y": [-3, 3],
    "grid": 1,
    "xLabel": "x",
    "yLabel": "y",
    "items": [
        {"type": "function", "expr": "2*x - 1", "label": "y = 2x - 1", "color": "accent"},
        {"type": "point", "at": [0, -1], "label": "(0,\\,-1)", "color": "orange"},
        {"type": "point", "at": [1, 1], "label": "(1,\\,1)", "color": "orange"}
    ]
}
```

## Prova tu {type=practice_quiz}

```quiz
prompt: assets/images/rette-quiz-1.png
text: Identifica l'espressione della retta mostrata.
- [x] $$y = 2x + 1$$
- [ ] $$y = x + 2$$
- [ ] $$y = -2x + 1$$
- [ ] $$y = 2x - 1$$
explanation: La retta sale, quindi $m > 0$, e incrocia l'asse $y$ in $1$, quindi $q > 0$. Un passo a destra di $P$ sale di $2$: $m = 2$.
```

```quiz
prompt: assets/images/rette-quiz-2.png
text: Identifica l'espressione della retta mostrata.
- [ ] $$y = x + 2$$
- [ ] $$y = -x - 2$$
- [x] $$y = -x + 2$$
- [ ] $$y = 2x - 1$$
explanation: La retta scende, quindi $m < 0$ (qui $m = -1$), e incrocia l'asse $y$ in $2$, quindi $q > 0$.
```

```quiz
prompt: assets/images/rette-quiz-3.png
text: Identifica l'espressione della retta mostrata.
- [ ] $$x = 3$$
- [ ] $$y = 3x$$
- [x] $$y = 3$$
- [ ] $$y = x + 3$$
explanation: È una retta orizzontale: $m = 0$. Incrocia l'asse $y$ in $3$, quindi $q > 0$ e l'equazione è $y = 3$.
```

```quiz
prompt: assets/images/rette-quiz-4.png
text: Identifica l'espressione della retta mostrata.
- [ ] $$y = -x$$
- [ ] $$y = x + 1$$
- [ ] $$y = 2x$$
- [x] $$y = x$$
explanation: La retta passa per l'origine, quindi $q = 0$, e sale, quindi $m > 0$: è la bisettrice $y = x$.
```

```quiz
prompt: assets/images/rette-quiz-5.png
text: Identifica l'espressione della retta mostrata.
- [ ] $$y = -2x + 1$$
- [ ] $$y = 2x - 1$$
- [x] $$y = -2x - 1$$
- [ ] $$y = -x - 1$$
explanation: La retta scende, quindi $m < 0$ (qui $m = -2$), e incrocia l'asse $y$ sotto lo zero, in $-1$: $q < 0$.
```
