#!/usr/bin/env python3
"""Aggregates benchmark/results/*.json per arm. Usage: python3 benchmark/report.py"""
import glob, json, os, statistics as st
from collections import defaultdict

rows = [r for r in (json.load(open(p)) for p in glob.glob(os.path.join(os.path.dirname(__file__), "results", "*.json"))) if not r["is_error"]]  # a run the API refused is not a result
arms = defaultdict(list)
for r in rows:
    arms[r["arm"]].append(r)

def med(xs): return st.median(xs) if xs else float("nan")
def rng(xs): return f"{min(xs):.0f}-{max(xs):.0f}" if xs else "-"

print(f"{'arm':8} {'runs':>4} {'resolved':>9} {'gate':>6} {'$/resolved':>11} {'p50 wall s':>11} {'wall range':>11} {'p50 out tok':>12} {'commits':>8} {'bad msg':>8}")
for arm in ("plain", "small", "medium", "large"):
    rs = arms.get(arm)
    if not rs: continue
    ok = [r for r in rs if r["resolved"]]
    cost = sum(r["cost_usd"] or 0 for r in rs)
    per = f"{cost / len(ok):.2f}" if ok else "inf"  # total spend over resolved runs, failed runs still cost
    wall = [r["wall_s"] for r in rs]
    print(f"{arm:8} {len(rs):>4} {len(ok)/len(rs):>9.0%} {sum(r['gate_green'] for r in rs)/len(rs):>6.0%} {per:>11} "
          f"{med(wall):>11.0f} {rng(wall):>11} {med([r['output_tokens'] or 0 for r in rs]):>12.0f} "
          f"{med([r['commits'] for r in rs]):>8.0f} {sum(r['bad_subjects'] + r['trailers'] for r in rs):>8}")

print("\nper task, resolved/runs")
tasks = sorted({r["task"] for r in rows})
print(f"{'task':18}" + "".join(f"{a:>9}" for a in ("plain", "small", "medium", "large")))
for t in tasks:
    line = f"{t:18}"
    for a in ("plain", "small", "medium", "large"):
        rs = [r for r in arms.get(a, []) if r["task"] == t]
        line += f"{sum(r['resolved'] for r in rs)}/{len(rs):>7}" if rs else f"{'-':>9}"
    print(line)
