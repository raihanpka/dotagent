#!/usr/bin/env python3
"""Draws docs/workflow.svg from docs/workflow.excalidraw, so the README image follows the diagram.

Usage: python3 scripts/workflow-svg.py          write docs/workflow.svg
       python3 scripts/workflow-svg.py --check  exit 1 when the svg is out of date

It draws rectangles, arrows, and text only, in the style of the diagram. Element ids it knows: e3 e5 e7 e9 (legend text),
e11 e13 e15 (lane titles), e56 (the footer, where some words are bold).
"""
import html
import json
import os
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
SRC = os.path.join(ROOT, "docs", "workflow.excalidraw")
OUT = os.path.join(ROOT, "docs", "workflow.svg")
FONT = "Inter, -apple-system, Helvetica Neue, Helvetica, Arial, sans-serif"
BOLD_WORDS = ["Hooks", "no trailer", "protected paths", "workflow mode", "read only"]
MARKER = (
    '<marker id="{id}" viewBox="0 0 10 10" markerUnits="userSpaceOnUse" markerWidth="11" markerHeight="11" refX="10" refY="5" '
    'orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="{fill}"/></marker>'
)


def esc(text):
    return html.escape(text, quote=False)


def footer_line(line):
    out = esc(line)
    for word in BOLD_WORDS:
        out = out.replace(esc(word), f'<tspan font-weight="700" fill="#212529">{esc(word)}</tspan>', 1)
    return out


def rect(e):
    w = e["width"]
    if w == 26:
        rx, sw = 6, 2
    elif w >= 1500 and e["strokeColor"] == "#ced4da":
        rx, sw = 16, 1.5
    else:
        rx, sw = 14, 2.5
    dash = ""
    if e.get("strokeStyle") == "dashed":
        sw, dash = 2, ' stroke-dasharray="8 6"'
    return (f'<rect x="{e["x"]:g}" y="{e["y"]:g}" width="{w:g}" height="{e["height"]:g}" rx="{rx}" '
            f'fill="{e["backgroundColor"]}" stroke="{e["strokeColor"]}" stroke-width="{sw}"{dash}/>')


def arrow(e):
    points = " ".join(f'{e["x"] + px:g},{e["y"] + py:g}' for px, py in e["points"])
    marker = "r" if e["strokeColor"] == "#c92a2a" else "a"
    dash = ' stroke-dasharray="8 6"' if e.get("strokeStyle") == "dashed" else ""
    ends = (f' marker-end="url(#{marker})"' if e.get("endArrowhead") else "") + (
        f' marker-start="url(#{marker})"' if e.get("startArrowhead") else "")
    return f'<polyline points="{points}" fill="none" stroke="{e["strokeColor"]}" stroke-width="2"{dash}{ends}/>'


def text(e):
    size, align = e["fontSize"], e["textAlign"]
    x = {"left": e["x"], "center": e["x"] + e["width"] / 2, "right": e["x"] + e["width"]}[align]
    anchor = {"left": "start", "center": "middle", "right": "end"}[align]
    bold = size >= 19 or (size == 17 and align == "right")
    fill = e["strokeColor"]
    if size >= 19 or e["id"] in ("e3", "e5", "e7", "e9", "e56"):
        fill = "#212529"
    if e["id"] in ("e11", "e13", "e15"):
        fill = "#495057"
    out = []
    for i, line in enumerate(e["text"].split("\n")):
        step = 28 if e["id"] == "e56" else size * 1.45
        y = e["y"] + (22 if size == 26 else size * 1.1) + i * step
        weight = ' font-weight="700"' if bold else ""
        body = footer_line(line) if e["id"] == "e56" else esc(line)
        out.append(f'<text x="{x:g}" y="{y:.0f}" text-anchor="{anchor}" font-size="{size}"{weight} fill="{fill}">{body}</text>')
    return out


def render():
    with open(SRC, encoding="utf-8") as handle:
        elements = json.load(handle)["elements"]
    height = int(max(e["y"] + e.get("height", 0) for e in elements if e["type"] != "arrow") + 34)
    out = [
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1690 {height}" width="1690" height="{height}" font-family="{FONT}">',
        "<defs>" + MARKER.format(id="a", fill="#343a40") + MARKER.format(id="r", fill="#c92a2a") + "</defs>",
        f'<rect width="1690" height="{height}" fill="#ffffff"/>',
    ]
    for e in elements:
        if e["type"] == "rectangle":
            out.append(rect(e))
        elif e["type"] == "arrow":
            out.append(arrow(e))
        elif e["type"] == "text":
            out.extend(text(e))
    out.append("</svg>")
    return "\n".join(out) + "\n"


def main():
    svg = render()
    if sys.argv[1:] == ["--check"]:
        with open(OUT, encoding="utf-8") as handle:
            if handle.read() != svg:
                sys.exit("docs/workflow.svg is out of date, run: python3 scripts/workflow-svg.py")
        return
    with open(OUT, "w", encoding="utf-8", newline="\n") as handle:
        handle.write(svg)


if __name__ == "__main__":
    main()
