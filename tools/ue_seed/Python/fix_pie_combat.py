"""Recarrega combate + reposiciona dummies. Output Log: py fix_pie_combat.py"""

import importlib
import unreal

import amandaconda_marco1 as marco1

importlib.reload(marco1)
marco1.destroy_unsavable_python_actors()
marco1.place_persistent_dummies(save=True)
marco1.spawn_combat_bootstrap()

# Garante tick no bootstrap ja existente
for a in unreal.EditorLevelLibrary.get_all_level_actors():
    if a and (
        isinstance(a, marco1.ACombatBootstrap)
        or a.get_actor_label() == "CombatBootstrap"
    ):
        try:
            a.set_actor_tick_enabled(True)
        except Exception:
            pass

unreal.log("[AMANDACONDA] FIX PIE: dummies na frente do spawn + bootstrap. Pare o Play e Alt+P de novo.")
print("[AMANDACONDA] FIX PIE ok — Stop + Alt+P")
