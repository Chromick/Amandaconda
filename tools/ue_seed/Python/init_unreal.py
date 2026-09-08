"""Boot AMANDACONDA: CombatDriver + HUD (vida/vigor/bytes/arma)."""

try:
    import unreal
    import amandaconda_hud_combat as combat

    # O editor pode sobrescrever [SystemSettings]; reforca o teto leve no runtime.
    unreal.SystemLibrary.execute_console_command(None, "t.MaxFPS 30")
    combat.start_combat_driver()
    print("[AMANDACONDA] HUD + combate no PIE prontos")
    print("[AMANDACONDA] Alt+P | LMB ataque | Ctrl/C roll | cubos na frente")
except Exception as exc:  # pragma: no cover
    print(f"[AMANDACONDA] falha init: {exc}")
    try:
        import unreal

        unreal.log_error(f"[AMANDACONDA] falha init: {exc}")
    except Exception:
        pass
