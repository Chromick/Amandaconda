"""Testa helpers Marco 2 sem Unreal (números do balance.json)."""

import ast
import sys
from pathlib import Path

SRC = Path(r"D:\AmandacondaUE\Content\Python\amandaconda_marco1.py")
text = SRC.read_text(encoding="utf-8")

# Extrai só constantes + helpers (sem import unreal)
ns: dict = {}
tree = ast.parse(text)
keep = []
for node in tree.body:
    if isinstance(node, (ast.Assign, ast.AnnAssign, ast.FunctionDef)):
        name = None
        if isinstance(node, ast.FunctionDef):
            name = node.name
        elif isinstance(node, ast.Assign) and node.targets:
            t0 = node.targets[0]
            if isinstance(t0, ast.Name):
                name = t0.id
        if name and (
            name.isupper()
            or name
            in ("vigor_after_spend", "vigor_regen_step", "iframe_active")
        ):
            keep.append(node)
mod = ast.Module(body=keep, type_ignores=[])
ast.fix_missing_locations(mod)
exec(compile(mod, str(SRC), "exec"), ns)

assert ns["vigor_after_spend"](100.0, ns["VIGOR_ATAQUE"]) == 84.0
assert ns["vigor_after_spend"](10.0, ns["VIGOR_ATAQUE"]) is None
assert ns["vigor_after_spend"](100.0, ns["ROLL_VIGOR"]) == 75.0

v, d = ns["vigor_regen_step"](75.0, 0.7, 0.7, False)
assert d == 0.0
v, d = ns["vigor_regen_step"](75.0, 0.0, 1.0, False)
assert abs(v - 115.0) < 0.01 or abs(v - ns["MAX_VIGOR"]) < 0.01  # cap 100
assert v == ns["MAX_VIGOR"]

assert ns["iframe_active"](0.05) is True
assert ns["iframe_active"](0.20) is True
assert ns["iframe_active"](0.31) is True
assert ns["iframe_active"](0.0) is False
assert ns["iframe_active"](0.32) is False

print("OK marco2 helpers")
sys.exit(0)
