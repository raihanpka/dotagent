import json, random, sys
random.seed(11)
out = sys.argv[1]
W, H = 1500, 810
BLUE, GREEN, YELLOW, GRAY, RED = "#a5d8ff", "#b2f2bb", "#ffec99", "#e9ecef", "#ffc9c9"
bw, bh, gap, x0 = 170, 112, 30, 60
def X(c): return x0 + c * (bw + gap)
bands = [(90, "Lead: Sonnet plans and reviews", "#e7f5ff"), (290, "Slicer swarm: one Haiku agent per slice", "#ebfbee"), (490, "Fixed steps: plain commands, no agent", "#fff9db")]
def Y(b): return bands[b][0] + 52
# (id, col, band, fill, title, detail lines)
boxes = [
 ("task", 0, 0, GRAY, "Task", ["Typed prompt plus", "pasted requirements"]),
 ("plan", 1, 0, BLUE, "Plan: Sonnet", ["Writes the plan file,", "8 slices, 400 lines", "More: stop and split"]),
 ("review", 5, 0, BLUE, "Review: Sonnet", ["Fresh context, the", "diff against the plan"]),
 ("slices", 2, 1, GREEN, "Slices: Haiku", ["One agent per slice,", "in order: test, build,", "lint, one commit"]),
 ("branch", 0, 2, YELLOW, "Branch", ["Cut from the", "default branch"]),
 ("pr", 5, 2, YELLOW, "Open PR", ["Push, then gh pr", "create from template"]),
 ("ci", 6, 2, YELLOW, "Watch CI", ["gh pr checks --watch", "Red: fix ladder"]),
 ("merge", 7, 2, YELLOW, "Merge by level", ["Off: stop at the PR", "On-green or full:", "merge with (#N)"]),
]
W = X(8) - gap + 60
by = {b[0]: b for b in boxes}
def bx(b): return X(b[1])
def by_(b): return Y(b[2])
def right(b): return (bx(b) + bw, by_(b) + bh // 2)
def left(b): return (bx(b), by_(b) + bh // 2)
def top(b): return (bx(b) + bw // 2, by_(b))
def bottom(b): return (bx(b) + bw // 2, by_(b) + bh)
A = lambda a, b: (a, b)
def cxm(b): return bx(b) + bw // 2
def cym(b): return by_(b) + bh // 2
arrows = [
 [bottom(by["task"]), top(by["branch"])],
 [right(by["branch"]), (cxm(by["plan"]) - 28, cym(by["branch"])), (cxm(by["plan"]) - 28, by_(by["plan"]) + bh)],
 [(cxm(by["plan"]) + 28, by_(by["plan"]) + bh), (cxm(by["plan"]) + 28, cym(by["slices"])), left(by["slices"])],
 [top(by["slices"]), (cxm(by["slices"]), cym(by["review"])), left(by["review"])],
 [bottom(by["review"]), top(by["pr"])],
 [right(by["pr"]), left(by["ci"])],
 [right(by["ci"]), left(by["merge"])],
]
# fix ladder box in the swarm band, right side
lx, ly, lw, lh = X(3) + 10, Y(1) - 6, X(4) + bw - X(3) - 10, bh + 12
ladder_lines = ["For a failed slice, review gaps, or red CI:", "Tries 1 and 2: a Haiku slicer", "Try 3: a Sonnet slicer, full context", "Still failing: stop and report"]
dashed = [
 [(bx(by["slices"]) + bw + 12, by_(by["slices"]) + bh // 2), (lx, by_(by["slices"]) + bh // 2)],
 [(bx(by["review"]) + 20, by_(by["review"]) + bh), (lx + lw - 30, ly)],
 [(bx(by["ci"]) + 20, by_(by["ci"])), (lx + lw - 70, ly + lh)],
]
hooks = (60, 690, W - 120, 96, ["Hooks check every step. A commit is type(scope): summary on one line with no trailer.", "PR titles follow the same format. The merge level is enforced. No em dash. Whole reads over 500 lines are blocked."])
legend = [(60, 56, BLUE, "Sonnet: plans and reviews"), (400, 56, GREEN, "Haiku: one narrow job"), (700, 56, YELLOW, "Fixed step: git, gh, CI"), (1000, 56, RED, "Escalation, then stop")]
title = "Dotagent: /dotagent:ship"
def esc(t): return t.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
FONT = "Inter, -apple-system, Helvetica Neue, Helvetica, Arial, sans-serif"
if out.endswith(".svg"):
    s = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" font-family="{FONT}">',
         '<defs><marker id="a" markerWidth="10" markerHeight="10" refX="8" refY="5" orient="auto"><path d="M0,0 L10,5 L0,10 z" fill="#343a40"/></marker>'
         '<marker id="r" markerWidth="10" markerHeight="10" refX="8" refY="5" orient="auto"><path d="M0,0 L10,5 L0,10 z" fill="#c92a2a"/></marker></defs>',
         f'<rect width="{W}" height="{H}" fill="#ffffff"/>',
         f'<text x="{W-60}" y="52" text-anchor="end" font-size="26" font-weight="700" fill="#212529">{title}</text>']
    for x, y, c, t in legend:
        s.append(f'<rect x="{x}" y="{y-18}" width="26" height="26" rx="6" fill="{c}" stroke="#343a40" stroke-width="2"/><text x="{x+36}" y="{y+2}" font-size="17" fill="#212529">{t}</text>')
    for by0, label, c in bands:
        s.append(f'<rect x="30" y="{by0}" width="{W-60}" height="176" rx="16" fill="{c}" stroke="#ced4da" stroke-width="1.5"/><text x="{W-48}" y="{by0+30}" text-anchor="end" font-size="17" font-weight="700" fill="#495057">{label}</text>')
    s.append(f'<rect x="{X(2)+16}" y="{Y(1)+16}" width="{bw}" height="{bh}" rx="14" fill="{GREEN}" stroke="#343a40" stroke-width="2"/>')
    s.append(f'<rect x="{X(2)+8}" y="{Y(1)+8}" width="{bw}" height="{bh}" rx="14" fill="{GREEN}" stroke="#343a40" stroke-width="2"/>')
    for b in boxes:
        x, y = bx(b), by_(b)
        s.append(f'<rect x="{x}" y="{y}" width="{bw}" height="{bh}" rx="14" fill="{b[3]}" stroke="#343a40" stroke-width="2.5"/>')
        s.append(f'<text x="{x+bw//2}" y="{y+30}" text-anchor="middle" font-size="19" font-weight="700" fill="#212529">{esc(b[4])}</text>')
        for i, l in enumerate(b[5]):
            s.append(f'<text x="{x+bw//2}" y="{y+56+i*22}" text-anchor="middle" font-size="15" fill="#343a40">{esc(l)}</text>')
    for pts in arrows:
        s.append(f'<polyline points="{" ".join(f"{x},{y}" for x, y in pts)}" fill="none" stroke="#343a40" stroke-width="3" marker-end="url(#a)"/>')
    s.append(f'<rect x="{lx}" y="{ly}" width="{lw}" height="{lh}" rx="14" fill="{RED}" stroke="#c92a2a" stroke-width="2.5" stroke-dasharray="9 6"/>')
    s.append(f'<text x="{lx+lw//2}" y="{ly+28}" text-anchor="middle" font-size="19" font-weight="700" fill="#212529">Fix ladder</text>')
    for i, l in enumerate(ladder_lines):
        s.append(f'<text x="{lx+lw//2}" y="{ly+52+i*21}" text-anchor="middle" font-size="14" fill="#343a40">{esc(l)}</text>')
    for pts in dashed:
        s.append(f'<polyline points="{" ".join(f"{x},{y}" for x, y in pts)}" fill="none" stroke="#c92a2a" stroke-width="2.5" stroke-dasharray="8 6" marker-end="url(#r)"/>')
    x, y, w, h, ls = hooks
    s.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="14" fill="#f8f9fa" stroke="#343a40" stroke-width="2.5"/>')
    for i, l in enumerate(ls):
        s.append(f'<text x="{x+w//2}" y="{y+40+i*28}" text-anchor="middle" font-size="17" fill="#212529">{esc(l)}</text>')
    s.append('</svg>')
    open(out, "w").write("\n".join(s))
else:
    els, n = [], [0]
    def base(t, x, y, w, h, **kw):
        n[0] += 1
        e = {"id": f"e{n[0]}", "type": t, "x": x, "y": y, "width": w, "height": h, "angle": 0, "strokeColor": "#343a40", "backgroundColor": "transparent",
             "fillStyle": "solid", "strokeWidth": 2, "strokeStyle": "solid", "roughness": 0, "opacity": 100, "groupIds": [], "frameId": None, "roundness": None,
             "seed": random.randint(1, 10**9), "version": 1, "versionNonce": random.randint(1, 10**9), "isDeleted": False, "boundElements": None,
             "updated": 1, "link": None, "locked": False}
        e.update(kw); els.append(e); return e
    def text(x, y, w, lines, size=16, align="center"):
        h = int(len(lines) * size * 1.25)
        return base("text", x, y, w, h, text="\n".join(lines), originalText="\n".join(lines), fontSize=size, fontFamily=2, textAlign=align,
                    verticalAlign="top", baseline=int(size * 0.9), containerId=None, lineHeight=1.25, autoResize=False)
    def rect(x, y, w, h, fill, dashed=False, stroke="#343a40", sw=2):
        return base("rectangle", x, y, w, h, backgroundColor=fill, strokeColor=stroke, roundness={"type": 3}, strokeStyle="dashed" if dashed else "solid", strokeWidth=sw)
    def arrow(pts, color="#343a40", dashed=False):
        p1 = pts[0]
        base("arrow", p1[0], p1[1], max(x for x, _ in pts) - min(x for x, _ in pts), max(y for _, y in pts) - min(y for _, y in pts), points=[[x - p1[0], y - p1[1]] for x, y in pts], endArrowhead="arrow", startArrowhead=None,
             strokeColor=color, strokeWidth=3, strokeStyle="dashed" if dashed else "solid", lastCommittedPoint=None, startBinding=None, endBinding=None, roundness={"type": 2})
    text(W - 460, 30, 400, [title], 26, "right")
    for x, y, c, t in legend:
        rect(x, y - 18, 26, 26, c); text(x + 36, y - 16, 300, [t], 17, "left")
    for by0, label, c in bands:
        rect(30, by0, W - 60, 176, c, stroke="#ced4da", sw=1); text(W - 748, by0 + 8, 700, [label], 17, "right")
    rect(X(2) + 16, Y(1) + 16, bw, bh, GREEN); rect(X(2) + 8, Y(1) + 8, bw, bh, GREEN)
    for b in boxes:
        rect(bx(b), by_(b), bw, bh, b[3]); text(bx(b), by_(b) + 10, bw, [b[4]], 19); text(bx(b), by_(b) + 40, bw, b[5], 15)
    for pts in arrows: arrow(pts)
    rect(lx, ly, lw, lh, RED, dashed=True, stroke="#c92a2a"); text(lx, ly + 10, lw, ["Fix ladder"], 19); text(lx, ly + 38, lw, ladder_lines, 15)
    for pts in dashed: arrow(pts, "#c92a2a", True)
    x, y, w, h, ls = hooks
    rect(x, y, w, h, "#f8f9fa"); text(x, y + 20, w, ls, 17)
    json.dump({"type": "excalidraw", "version": 2, "source": "dotagent", "elements": els, "appState": {"viewBackgroundColor": "#ffffff", "gridSize": None}, "files": {}}, open(out, "w"), indent=1)
