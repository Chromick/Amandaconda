"""Recarrega combate Marco 2 na sessão do Editor (Output Log: py reload_marco2.py)."""

import importlib
import unreal

import amandaconda_marco1 as marco1

importlib.reload(marco1)
marco1.destroy_unsavable_python_actors()
marco1.ensure_session_combat()
unreal.log("[AMANDACONDA] Marco 2 recarregado — Play de novo")
print("[AMANDACONDA] Marco 2 recarregado — Play de novo")