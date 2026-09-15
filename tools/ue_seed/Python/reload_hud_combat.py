"""Recarrega combate. Parar o Play antes."""

import importlib
import unreal

import amandaconda_hud_combat as combat

importlib.reload(combat)
combat.reset_pie_state()
combat.start_combat_driver()
unreal.log(
    "[AMANDACONDA] reload — R/LMB leve | E/RMB pesado | Ctrl roll | Tab lock"
)
print("[AMANDACONDA] Parar -> Alt+P")
print("  R/LMB = leve | E/RMB = pesado (clique) | Ctrl/C = rolamento | Tab/G = lock")
