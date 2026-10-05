#!/usr/bin/env python3
"""Formatta i JSON dei contenuti nello stesso modo, secondo JSON_GUIDELINES.md.

    python3 tool/format_json.py            # tutti i file di assets/data/lessons
    python3 tool/format_json.py file.json  # solo quelli indicati
    python3 tool/format_json.py --check    # non scrive, esce con 1 se qualcosa cambierebbe

Il contenuto non cambia (lo script lo verifica): cambiano solo gli spazi.
"""
import glob
import json
import sys

INDENT = "    "
MAX_INLINE = 100  # colonne oltre cui un array di coppie va una per riga


def is_number(v):
    return isinstance(v, (int, float)) and not isinstance(v, bool)


def is_numeric_list(v):
    return isinstance(v, list) and v and all(is_number(x) for x in v)


def inline(v):
    """Un array di soli numeri, su una riga: [-3, 3]."""
    return "[" + ", ".join(json.dumps(x) for x in v) + "]"


def dump(v, level=0):
    pad = INDENT * level
    inner = INDENT * (level + 1)
    if isinstance(v, dict):
        if not v:
            return "{}"
        items = [f"{inner}{json.dumps(k, ensure_ascii=False)}: {dump(x, level + 1)}" for k, x in v.items()]
        return "{\n" + ",\n".join(items) + "\n" + pad + "}"
    if isinstance(v, list):
        if not v:
            return "[]"
        # [-3, 3]: gli estremi, un punto, i numeri di una lista, sempre su una riga
        if is_numeric_list(v):
            return inline(v)
        # [[0, 0], [2, 0]]: coppie di numeri, su una riga se ci stanno
        if all(is_numeric_list(x) for x in v):
            line = "[" + ", ".join(inline(x) for x in v) + "]"
            if len(pad) + len(line) <= MAX_INLINE:
                return line
        return "[\n" + ",\n".join(inner + dump(x, level + 1) for x in v) + "\n" + pad + "]"
    return json.dumps(v, ensure_ascii=False)


def main(argv):
    check = "--check" in argv
    files = [a for a in argv if not a.startswith("--")] or sorted(glob.glob("assets/data/lessons/*.json"))
    changed = []
    for path in files:
        with open(path, encoding="utf-8") as f:
            original = f.read()
        data = json.loads(original)
        text = dump(data) + "\n"
        assert json.loads(text) == data, f"{path}: il contenuto sarebbe cambiato"
        if text != original:
            changed.append(path)
            if not check:
                with open(path, "w", encoding="utf-8") as f:
                    f.write(text)
    for path in changed:
        print(("da formattare: " if check else "formattato: ") + path)
    if not changed:
        print("tutto già formattato")
    return 1 if (check and changed) else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
