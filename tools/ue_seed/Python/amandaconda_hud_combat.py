"""
AMANDACONDA — combate + HUD no PIE (sem depender de tick de Actor Python).

Roda num slate post-tick: leve, pesado, lock-on, roll, vigor, dummy, bytes.
HUD: AAmandacondaHUD (vida / vigor / bytes / arma / lock).

Controles (tecla fisica Windows):
  R / F / V / Q / LMB  = ataque leve
  E / RMB              = ataque pesado (clique)
  Tab / G / MMB        = lock-on
  Ctrl / C             = rolamento / esquiva
"""

from __future__ import annotations

import ctypes
import unreal

# --- Balance ---
DANO_LEVE = 12.0
VIGOR_ATAQUE = 16.0
ALCANCE_UU = 90.0
RAIO_HIT_UU = 70.0
DUMMY_HP = 200.0
HIT_DELAY = 0.22
ATTACK_COOLDOWN = 0.45
HEAVY_VIGOR = 32.0
HEAVY_DANO = 38.0
HEAVY_ALCANCE_UU = 110.0
HEAVY_HIT_DELAY = 0.62
HEAVY_COOLDOWN = 1.15
HEAVY_ANIM_RATE = 0.38
LOCK_RANGE_UU = 1200.0

MAX_VIGOR = 100.0
VIGOR_REGEN = 40.0
VIGOR_REGEN_DELAY = 0.7

ROLL_DUR = 1.07
ROLL_INV_START = 0.10
ROLL_INV_DUR = 0.68
ROLL_VIGOR = 25.0
ROLL_SPEED_UU = 390.0
ROLL_MESH_DIP_UU = 42.0

PLAYER_MAX_HP = 100.0
DUMMY_DANO = 18.0
DUMMY_ALCANCE_UU = 180.0
DUMMY_INTERVALO = 2.4
DUMMY_PREP = 0.55
DUMMY_RECUP = 0.6
BYTES_POR_KILL = 32

ATTACK_SEQ = "/Game/Amandaconda/Animation/GASP/Combat/AS_Attack_Light_01_GASP"
ATTACK_SEQ_2 = "/Game/Amandaconda/Animation/GASP/Combat/AS_Attack_Light_02_GASP"
HEAVY_SEQ = "/Game/Amandaconda/Animation/GASP/Combat/AS_Attack_Heavy_GASP"
HEAVY_MONTAGE = "/Game/Amandaconda/Animation/GASP/Combat/AM_Attack_Heavy_GASP"
LAND_SEQ = "/Game/Amandaconda/Animation/GASP/Combat/AS_Land_GASP"
# GASP aparado para conter apenas aterrissagem + cambalhota (1,07 s).
GASP_ROLL_MONTAGE = "/Game/Amandaconda/Animation/GASP/AM_Roll_Forward_GASP"
MANNEQUIN_ROLL_SEQ = (
    "/Game/Amandaconda/Animation/GASP/Retargeted/AS_Roll_Forward_Mannequin"
)
GASP_ROLL_SEQ = "/Game/Amandaconda/Animation/GASP/AS_Roll_Forward_GASP"
ROLL_SEQ_CANDIDATES = (
    MANNEQUIN_ROLL_SEQ,
    GASP_ROLL_SEQ,
)
# Slate: um unico callback; reload so troca a implementacao (evita handlers velhos quebrados)
_REGISTERED = False
_TICK_IMPL = []
_ASSET_CACHE: dict = {}


def _log(msg: str) -> None:
    unreal.log(f"[AMANDACONDA] {msg}")


def _load_asset(path: str):
    """Carrega asset SEM EditorAssetLibrary (que spam 'play mode' no PIE)."""
    if path in _ASSET_CACHE:
        return _ASSET_CACHE[path]
    obj = None
    name = path.rsplit("/", 1)[-1]
    candidates = (
        f"{path}.{name}",
        path,
    )
    for p in candidates:
        try:
            obj = unreal.load_object(None, p)
            if obj:
                break
        except Exception:
            pass
    if not obj:
        try:
            # API alternativa (game-safe em varias builds)
            obj = unreal.load_asset(path)
        except Exception:
            pass
    if not obj and get_pie_world() is None:
        # so no editor parado
        try:
            obj = unreal.EditorAssetLibrary.load_asset(path)
        except Exception:
            pass
    _ASSET_CACHE[path] = obj
    return obj


def preload_combat_assets() -> None:
    paths = [
        ATTACK_SEQ,
        ATTACK_SEQ_2,
        HEAVY_SEQ,
        HEAVY_MONTAGE,
        LAND_SEQ,
        GASP_ROLL_MONTAGE,
        "/Engine/BasicShapes/Cube",
    ]
    paths.extend(ROLL_SEQ_CANDIDATES)
    for p in paths:
        a = _load_asset(p)
        _log(f"preload {p}: {'ok' if a else 'FAIL'}")


def _anim_matches_mesh(seq, mesh) -> bool:
    """Evita tocar uma animacao em um skeleton incompatível."""
    if not seq or not mesh:
        return False
    try:
        source_skeleton = seq.get_skeleton()
    except Exception:
        try:
            source_skeleton = seq.get_editor_property("skeleton")
        except Exception:
            source_skeleton = None
    try:
        sk_mesh = mesh.get_skeletal_mesh_asset()
    except Exception:
        try:
            sk_mesh = mesh.get_editor_property("skeletal_mesh_asset")
        except Exception:
            sk_mesh = None
    try:
        target_skeleton = sk_mesh.get_skeleton() if sk_mesh else None
    except Exception:
        try:
            target_skeleton = sk_mesh.get_editor_property("skeleton") if sk_mesh else None
        except Exception:
            target_skeleton = None
    return bool(source_skeleton and target_skeleton and source_skeleton == target_skeleton)


def _resolve_roll_seq(pawn) -> str:
    """Escolhe o roll compatível com o skeleton do pawn."""
    try:
        mesh = pawn.get_component_by_class(unreal.SkeletalMeshComponent)
    except Exception:
        mesh = None
    for p in ROLL_SEQ_CANDIDATES:
        a = _load_asset(p)
        if isinstance(a, unreal.AnimSequence) and _anim_matches_mesh(a, mesh):
            return p
    return ""


def _v_len(v) -> float:
    """Comprimento de Vector (UE Python nao tem .size())."""
    try:
        return float(unreal.MathLibrary.v_size(v))
    except Exception:
        try:
            return float((v.x * v.x + v.y * v.y + v.z * v.z) ** 0.5)
        except Exception:
            return 0.0


def _v_len_sq(v) -> float:
    try:
        return float(unreal.MathLibrary.v_size_squared(v))
    except Exception:
        try:
            return float(v.x * v.x + v.y * v.y + v.z * v.z)
        except Exception:
            return 0.0


def _v_norm(v):
    try:
        return unreal.MathLibrary.normal(v, 0.0001)
    except Exception:
        n = _v_len(v)
        if n < 0.0001:
            return unreal.Vector(1.0, 0.0, 0.0)
        return unreal.Vector(v.x / n, v.y / n, v.z / n)


def _actor_hidden(actor) -> bool:
    """UE Python: StaticMeshActor nao tem is_hidden()."""
    if not actor:
        return True
    try:
        if hasattr(actor, "is_hidden_in_game") and callable(actor.is_hidden_in_game):
            return bool(actor.is_hidden_in_game())
    except Exception:
        pass
    try:
        return bool(actor.get_editor_property("b_hidden"))
    except Exception:
        pass
    try:
        st = STATE.dummy_ai.get(actor.get_name())
        if st and st.get("state") == "dead":
            return True
    except Exception:
        pass
    return False


# ---------------------------------------------------------------------------
# Estado global (HUD lê daqui)
# ---------------------------------------------------------------------------


class GameState:
    def __init__(self) -> None:
        self.hp = PLAYER_MAX_HP
        self.max_hp = PLAYER_MAX_HP
        self.vigor = MAX_VIGOR
        self.max_vigor = MAX_VIGOR
        self.vigor_delay = 0.0
        self.bytes_kb = 0
        self.arma = "Teclado"  # escola Físico
        self.escola = "Físico"
        self.rolling = False
        self.roll_t = 0.0
        self.invincible = False
        self.attacking = False
        self.cooldown = 0.0
        self.hit_timer = -1.0
        self.hit_consumed = False
        self.was_lmb = False
        self.was_face = False
        self.was_roll = False
        self.was_atk_key = False
        self.was_heavy = False
        self.was_lock = False
        self.charging = False  # legado (pesado agora e clique)
        self.charge_t = 0.0
        self.pending_damage = DANO_LEVE
        self.pending_radius = RAIO_HIT_UU
        self.lock_name = ""
        self.roll_dir = unreal.Vector(1.0, 0.0, 0.0)
        self.roll_mesh = None
        self.roll_mesh_rel = None
        self.roll_mesh_loc = None
        self.roll_use_anim = False
        self.roll_was_crouched = False
        self.dummy_hp: dict[str, float] = {}
        self.dummy_ai: dict[str, dict] = {}
        self.pie_ready = False
        self.dummies_spawned = False
        self.hud_set = False
        self.tick_accum = 0.0
        self.montage = None
        self.restore_anim_t = 0.0
        self.restore_mesh = None
        self.restore_anim_mode = None
        self.input_dbg_t = 0.0


STATE = GameState()


def get_pie_world():
    try:
        sub = unreal.get_editor_subsystem(unreal.UnrealEditorSubsystem)
        if sub:
            w = sub.get_game_world()
            if w:
                return w
    except Exception:
        pass
    try:
        return unreal.EditorLevelLibrary.get_game_world()
    except Exception:
        return None


def get_pc_pawn():
    world = get_pie_world()
    if not world:
        return None, None, None
    pc = unreal.GameplayStatics.get_player_controller(world, 0)
    pawn = unreal.GameplayStatics.get_player_pawn(world, 0)
    return world, pc, pawn


# ---------------------------------------------------------------------------
# HUD
# ---------------------------------------------------------------------------


def _hud_font():
    for path in (
        "/Engine/EngineFonts/Roboto",
        "/Engine/EngineFonts/RobotoDistanceField",
        "/Engine/EngineFonts/Faces/RobotoDistanceField",
    ):
        f = _load_asset(path)
        if f:
            return f
    return None


_HUD_FONT = None


def _font():
    global _HUD_FONT
    if _HUD_FONT is None:
        _HUD_FONT = _hud_font()
    return _HUD_FONT


@unreal.uclass()
class AAmandacondaHUD(unreal.HUD):
    """HUD canto superior esquerdo: vida, vigor, bytes, arma."""

    @unreal.ufunction(override=True)
    def receive_draw_hud(self, size_x: int, size_y: int):
        s = STATE
        x0 = 36.0
        y0 = 36.0
        bar_w = 220.0
        bar_h = 18.0
        font = _font()

        panel_h = 150.0
        if s.lock_name:
            panel_h += 28.0
        self.draw_rect(
            unreal.LinearColor(0.02, 0.05, 0.08, 0.55),
            x0 - 12.0,
            y0 - 12.0,
            bar_w + 80.0,
            panel_h,
        )

        def txt(text, color, x, y, scale=1.15):
            try:
                self.draw_text(text, color, x, y, font, scale, False)
            except Exception:
                try:
                    self.draw_text(text, color, x, y)
                except Exception:
                    pass

        txt("VIDA", unreal.LinearColor(0.95, 0.35, 0.35, 1.0), x0, y0)
        self.draw_rect(
            unreal.LinearColor(0.15, 0.05, 0.05, 0.9), x0, y0 + 22.0, bar_w, bar_h
        )
        hp_frac = max(0.0, min(1.0, s.hp / max(1.0, s.max_hp)))
        self.draw_rect(
            unreal.LinearColor(0.85, 0.15, 0.2, 1.0),
            x0,
            y0 + 22.0,
            bar_w * hp_frac,
            bar_h,
        )
        txt(
            f"{s.hp:.0f}/{s.max_hp:.0f}",
            unreal.LinearColor(1, 1, 1, 1),
            x0 + bar_w + 8.0,
            y0 + 20.0,
            1.0,
        )

        y1 = y0 + 52.0
        txt("VIGOR", unreal.LinearColor(0.35, 0.85, 0.55, 1.0), x0, y1)
        self.draw_rect(
            unreal.LinearColor(0.05, 0.12, 0.08, 0.9), x0, y1 + 22.0, bar_w, bar_h
        )
        vg_frac = max(0.0, min(1.0, s.vigor / max(1.0, s.max_vigor)))
        self.draw_rect(
            unreal.LinearColor(0.2, 0.9, 0.45, 1.0),
            x0,
            y1 + 22.0,
            bar_w * vg_frac,
            bar_h,
        )
        txt(
            f"{s.vigor:.0f}/{s.max_vigor:.0f}",
            unreal.LinearColor(1, 1, 1, 1),
            x0 + bar_w + 8.0,
            y1 + 20.0,
            1.0,
        )

        y2 = y1 + 52.0
        kb = s.bytes_kb
        bytes_txt = f"{kb} KB" if kb < 1024 else f"{kb / 1024.0:.1f} MB"
        txt(
            f"BYTES  {bytes_txt}",
            unreal.LinearColor(0.45, 0.85, 1.0, 1.0),
            x0,
            y2,
            1.2,
        )
        txt(
            f"ARMA   {s.arma}  ({s.escola})",
            unreal.LinearColor(1.0, 0.85, 0.35, 1.0),
            x0,
            y2 + 26.0,
            1.2,
        )
        y_flags = y2 + 54.0
        if s.lock_name:
            txt(
                f"LOCK  {s.lock_name}",
                unreal.LinearColor(1.0, 0.35, 0.35, 1.0),
                x0,
                y_flags,
                1.1,
            )
            y_flags += 26.0
        flags = []
        if s.rolling:
            flags.append("ROLL")
        if s.invincible:
            flags.append("IFRAME")
        if flags:
            txt(
                "  ".join(flags),
                unreal.LinearColor(0.4, 1.0, 0.5, 1.0),
                x0,
                y_flags,
                1.1,
            )


def ensure_hud(pc) -> None:
    if STATE.hud_set or not pc:
        return
    try:
        # ClientSetHUD(TSubclassOf<AHUD>)
        pc.client_set_hud(AAmandacondaHUD)
        STATE.hud_set = True
        _log("HUD AAmandacondaHUD ativo")
    except Exception as exc:
        try:
            pc.set_hud(AAmandacondaHUD)
            STATE.hud_set = True
            _log("HUD set_hud ok")
        except Exception as exc2:
            _log(f"HUD falhou: {exc} / {exc2}")


# ---------------------------------------------------------------------------
# Dummies no PIE
# ---------------------------------------------------------------------------


def _spawn_dummy_near(world, pawn, offset: unreal.Vector, label: str):
    if not world or not pawn:
        return None
    loc = pawn.get_actor_location() + offset
    loc.z = pawn.get_actor_location().z
    try:
        tf = unreal.Transform(
            loc,
            unreal.Rotator(0.0, 0.0, 0.0),
            unreal.Vector(1.0, 1.0, 1.0),
        )
        handling = getattr(
            unreal,
            "SpawnActorCollisionHandlingMethod",
            None,
        ) or getattr(unreal, "ESpawnActorCollisionHandlingMethod", None)
        always = handling.ALWAYS_SPAWN if handling else None
        if always is not None:
            actor = unreal.GameplayStatics.begin_deferred_actor_spawn_from_class(
                world,
                unreal.StaticMeshActor,
                tf,
                always,
            )
        else:
            actor = unreal.GameplayStatics.begin_deferred_actor_spawn_from_class(
                world,
                unreal.StaticMeshActor,
                tf,
            )
        if actor:
            unreal.GameplayStatics.finish_spawning_actor(actor, tf)
    except Exception as exc:
        _log(f"deferred spawn: {exc}")
        actor = None
        # NAO usar EditorLevelLibrary no PIE (gera LogUtils play mode)

    if not actor:
        return None
    try:
        actor.set_actor_label(label)
    except Exception:
        pass
    if not actor.actor_has_tag("Dummy"):
        actor.tags.append("Dummy")
    cube = _load_asset("/Engine/BasicShapes/Cube")
    mesh = actor.static_mesh_component
    if mesh and cube:
        mesh.set_static_mesh(cube)
        mesh.set_relative_scale3d(unreal.Vector(0.9, 0.9, 2.0))
        mesh.set_collision_profile_name("BlockAllDynamic")
        mesh.set_visibility(True, True)
        mesh.set_hidden_in_game(False)
    actor.set_actor_hidden_in_game(False)
    actor.set_actor_enable_collision(True)
    STATE.dummy_hp[actor.get_name()] = DUMMY_HP
    STATE.dummy_ai[actor.get_name()] = {"state": "idle", "t": 0.0, "cd": 0.8}
    _log(f"dummy PIE {label} @ {loc}")
    return actor


def ensure_pie_dummies(world, pawn) -> None:
    if STATE.dummies_spawned or not world or not pawn:
        return
    # se já existem dummies no mundo PIE, só registra
    existing = unreal.GameplayStatics.get_all_actors_with_tag(world, "Dummy")
    if existing and len(existing) >= 1:
        for a in existing:
            if a:
                STATE.dummy_hp.setdefault(a.get_name(), DUMMY_HP)
                STATE.dummy_ai.setdefault(
                    a.get_name(), {"state": "idle", "t": 0.0, "cd": 0.5}
                )
        STATE.dummies_spawned = True
        _log(f"dummies ja no PIE: {len(existing)}")
        return

    fwd = pawn.get_actor_forward_vector()
    right = pawn.get_actor_right_vector()
    _spawn_dummy_near(world, pawn, fwd * 350.0, "Dummy_PIE_01")
    _spawn_dummy_near(
        world, pawn, fwd * 350.0 + right * 140.0, "Dummy_PIE_02"
    )
    STATE.dummies_spawned = True


# ---------------------------------------------------------------------------
# Combate
# ---------------------------------------------------------------------------


def _spend_vigor(cost: float) -> bool:
    if STATE.vigor < cost:
        return False
    STATE.vigor -= cost
    STATE.vigor_delay = VIGOR_REGEN_DELAY
    return True


def _tick_vigor(dt: float) -> None:
    if STATE.vigor_delay > 0.0:
        STATE.vigor_delay = max(0.0, STATE.vigor_delay - dt)
        return
    if STATE.rolling or STATE.attacking:
        return
    STATE.vigor = min(MAX_VIGOR, STATE.vigor + VIGOR_REGEN * dt)


def _flatten_pawn(pawn) -> None:
    """Zera pitch/roll do capsule — evita ficar de cabeça pra baixo."""
    if not pawn:
        return
    try:
        r = pawn.get_actor_rotation()
        if abs(r.pitch) > 0.5 or abs(r.roll) > 0.5:
            pawn.set_actor_rotation(
                unreal.Rotator(roll=0.0, pitch=0.0, yaw=r.yaw), False
            )
    except Exception:
        pass


def _face_dir(pawn, direction) -> None:
    if not pawn or not direction:
        return
    try:
        d = unreal.Vector(direction.x, direction.y, 0.0)
        if _v_len_sq(d) < 0.01:
            return
        rot = unreal.MathLibrary.make_rot_from_x(d)
        pawn.set_actor_rotation(
            unreal.Rotator(roll=0.0, pitch=0.0, yaw=rot.yaw), False
        )
    except Exception:
        pass


def _roll_dir(pawn, pc):
    fwd = pawn.get_actor_forward_vector()
    right = pawn.get_actor_right_vector()
    x = y = 0.0
    # teclas fisicas (mesmo com Log focado)
    if _vk_down(0x57):  # W
        x += 1.0
    if _vk_down(0x53):  # S
        x -= 1.0
    if _vk_down(0x44):  # D
        y += 1.0
    if _vk_down(0x41):  # A
        y -= 1.0
    if abs(x) < 0.01 and abs(y) < 0.01 and pc:
        try:
            if pc.is_input_key_down(unreal.Key("W")):
                x += 1.0
            if pc.is_input_key_down(unreal.Key("S")):
                x -= 1.0
            if pc.is_input_key_down(unreal.Key("D")):
                y += 1.0
            if pc.is_input_key_down(unreal.Key("A")):
                y -= 1.0
        except Exception:
            pass
    d = fwd * x + right * y
    if _v_len_sq(d) < 0.01:
        d = fwd
    d.z = 0.0
    return _v_norm(d)


def try_roll(pawn, pc) -> None:
    if STATE.rolling or STATE.attacking:
        return
    if not _spend_vigor(ROLL_VIGOR):
        _log("roll sem vigor")
        return
    STATE.roll_dir = _roll_dir(pawn, pc)
    STATE.rolling = True
    STATE.roll_t = 0.0
    STATE.invincible = False
    STATE.roll_use_anim = False
    _flatten_pawn(pawn)
    _face_dir(pawn, STATE.roll_dir)

    mesh = None
    try:
        mesh = pawn.get_component_by_class(unreal.SkeletalMeshComponent)
    except Exception:
        mesh = None
    STATE.roll_mesh = mesh
    STATE.roll_mesh_rel = None
    STATE.roll_mesh_loc = None
    if mesh:
        try:
            STATE.roll_mesh_rel = mesh.get_relative_rotation()
        except Exception:
            STATE.roll_mesh_rel = unreal.Rotator(0.0, 0.0, 0.0)
        try:
            STATE.roll_mesh_loc = mesh.get_relative_location()
        except Exception:
            STATE.roll_mesh_loc = unreal.Vector(0.0, 0.0, 0.0)

    # agacha pra parecer cambalhota no chao
    STATE.roll_was_crouched = False
    try:
        if hasattr(pawn, "crouch"):
            pawn.crouch()
            STATE.roll_was_crouched = True
    except Exception:
        pass

    # O clipe GASP é tocado direto para não depender de um Slot do AnimBP doador.
    # O deslocamento fica no capsule e a animacao usa Force Root Lock.
    roll_seq = _resolve_roll_seq(pawn)
    if roll_seq:
        played = (
            _play_montage(pawn, GASP_ROLL_MONTAGE, rate=1.0)
            if roll_seq == GASP_ROLL_SEQ
            else False
        )
        if not played:
            played = _play_anim_seq(pawn, roll_seq, rate=1.0, force_single_node=True)
        STATE.roll_use_anim = played
        _log(f"ROLL anim={roll_seq} ok={played}")
    else:
        STATE.roll_use_anim = False
        _log("ROLL fallback procedural (skeleton sem roll compatível)")
    _log(f"ROLL esquiva vigor={STATE.vigor:.0f}")


def _play_montage(pawn, montage_path: str, rate: float = 1.0) -> bool:
    mesh = pawn.get_component_by_class(unreal.SkeletalMeshComponent)
    if not mesh:
        return False
    anim = mesh.get_anim_instance()
    if not anim:
        return False
    mont = _load_asset(montage_path)
    if not mont:
        return False
    try:
        dur = anim.montage_play(mont, rate)
        if dur and float(dur) > 0.0:
            _log(f"montage OK {montage_path} dur={float(dur):.2f} rate={rate}")
            return True
    except Exception as exc:
        _log(f"montage fail {montage_path}: {exc}")
    return False


def _play_anim_seq(
    pawn, seq_path: str, rate: float = 1.15, force_single_node: bool = False
) -> bool:
    """Toca ataque VISIVEL: slot/montage, senao Single Node forçado."""
    mesh = pawn.get_component_by_class(unreal.SkeletalMeshComponent)
    if not mesh:
        _log("anim: sem SkeletalMesh")
        return False

    seq = _load_asset(seq_path)
    if not isinstance(seq, unreal.AnimSequence):
        _log(f"anim: nao e AnimSequence ({seq_path})")
        return False
    if not _anim_matches_mesh(seq, mesh):
        _log(f"anim: skeleton incompatível ({seq_path})")
        return False

    anim = None if force_single_node else mesh.get_anim_instance()
    if anim:
        for slot in ("DefaultSlot", "FullBody", "UpperBody", "Action", "Default"):
            try:
                dynamic_montage = anim.play_slot_animation_as_dynamic_montage(
                    seq, slot, 0.05, 0.15, rate, 1
                )
                if dynamic_montage:
                    _log(f"anim OK dynamic montage slot={slot} rate={rate}")
                    return True
            except Exception as exc:
                _log(f"anim slot {slot}: {exc}")
    # Fallback: Single Node (sempre aparece o soco)
    try:
        try:
            STATE.restore_anim_mode = mesh.get_animation_mode()
        except Exception:
            STATE.restore_anim_mode = unreal.AnimationMode.ANIMATION_BLUEPRINT
        STATE.restore_mesh = mesh
        try:
            length = float(seq.get_editor_property("sequence_length") or 0.8)
        except Exception:
            length = 0.8
        # permite anim pesada bem lenta
        STATE.restore_anim_t = max(0.45, min(3.0, length / max(0.15, rate)))

        mesh.set_animation_mode(unreal.AnimationMode.ANIMATION_SINGLE_NODE)
        if hasattr(mesh, "play_animation"):
            mesh.play_animation(seq, False)
        elif hasattr(mesh, "set_animation"):
            mesh.set_animation(seq)
            if hasattr(mesh, "play"):
                mesh.play(True)
        try:
            mesh.set_play_rate(rate)
        except Exception:
            pass
        try:
            mesh.set_position(0.0, False)
        except Exception:
            pass
        _flatten_pawn(pawn)
        _log(f"anim SINGLE NODE restore={STATE.restore_anim_t:.2f}s rate={rate}")
        return True
    except Exception as exc:
        _log(f"anim single-node FALHOU: {exc}")
        return False


def _tick_restore_anim(dt: float) -> None:
    t = float(getattr(STATE, "restore_anim_t", 0.0) or 0.0)
    if t <= 0.0:
        return
    t -= dt
    STATE.restore_anim_t = t
    if t > 0.0:
        return
    mesh = getattr(STATE, "restore_mesh", None)
    mode = getattr(STATE, "restore_anim_mode", None)
    if mesh and mode is not None:
        try:
            if mode == unreal.AnimationMode.ANIMATION_SINGLE_NODE:
                mode = unreal.AnimationMode.ANIMATION_BLUEPRINT
            mesh.set_animation_mode(mode)
            _log("anim: voltou pro AnimBP")
        except Exception as exc:
            _log(f"restore anim mode: {exc}")
    STATE.restore_mesh = None
    # capsule de pe
    try:
        world, pc, pawn = get_pc_pawn()
        _flatten_pawn(pawn)
    except Exception:
        pass


def try_attack(pawn) -> None:
    _log("try_attack chamado")
    if STATE.attacking or STATE.rolling or STATE.cooldown > 0.0:
        _log(
            f"ataque bloqueado atk={STATE.attacking} roll={STATE.rolling} "
            f"cd={STATE.cooldown:.2f}"
        )
        return
    if not _spend_vigor(VIGOR_ATAQUE):
        _log("ataque sem vigor")
        return

    _flatten_pawn(pawn)
    try:
        fwd = pawn.get_actor_forward_vector()
        if hasattr(pawn, "launch_character"):
            pawn.launch_character(
                unreal.Vector(fwd.x * 280.0, fwd.y * 280.0, 10.0), True, True
            )
    except Exception:
        pass
    try:
        origin = pawn.get_actor_location() + pawn.get_actor_forward_vector() * 60.0
        origin.z += 50.0
        unreal.SystemLibrary.draw_debug_sphere(
            pawn,
            origin,
            45.0,
            12,
            unreal.LinearColor(1.0, 0.4, 0.05, 1.0),
            0.45,
            3.0,
        )
    except Exception:
        pass

    played = _play_anim_seq(pawn, ATTACK_SEQ, rate=1.2)
    if not played:
        _play_anim_seq(pawn, ATTACK_SEQ_2, rate=1.2)

    STATE.attacking = True
    STATE.hit_consumed = False
    STATE.hit_timer = HIT_DELAY
    STATE.cooldown = ATTACK_COOLDOWN
    STATE.pending_damage = DANO_LEVE
    STATE.pending_radius = RAIO_HIT_UU
    _log(f"ataque LEVE vigor={STATE.vigor:.0f} anim={played}")


def try_heavy(pawn) -> None:
    """Ataque pesado = clique, anim bem lenta."""
    if STATE.attacking or STATE.rolling or STATE.cooldown > 0.0:
        return
    if not _spend_vigor(HEAVY_VIGOR):
        _log("pesado sem vigor")
        return

    _flatten_pawn(pawn)
    try:
        fwd = pawn.get_actor_forward_vector()
        if hasattr(pawn, "launch_character"):
            pawn.launch_character(
                unreal.Vector(fwd.x * 220.0, fwd.y * 220.0, 6.0), True, True
            )
    except Exception:
        pass
    try:
        origin = pawn.get_actor_location() + pawn.get_actor_forward_vector() * 80.0
        origin.z += 50.0
        unreal.SystemLibrary.draw_debug_sphere(
            pawn,
            origin,
            55.0,
            14,
            unreal.LinearColor(1.0, 0.15, 0.8, 1.0),
            0.7,
            3.5,
        )
    except Exception:
        pass

    # Montage do template Combat em taxa bem baixa; fallback Attack_03 lento
    played = _play_montage(pawn, HEAVY_MONTAGE, rate=HEAVY_ANIM_RATE)
    if not played:
        played = _play_anim_seq(pawn, HEAVY_SEQ, rate=HEAVY_ANIM_RATE)
    if not played:
        _play_anim_seq(pawn, ATTACK_SEQ_2, rate=max(0.3, HEAVY_ANIM_RATE))

    STATE.attacking = True
    STATE.hit_consumed = False
    STATE.hit_timer = HEAVY_HIT_DELAY
    STATE.cooldown = HEAVY_COOLDOWN
    STATE.pending_damage = HEAVY_DANO
    STATE.pending_radius = HEAVY_ALCANCE_UU
    _flatten_pawn(pawn)
    _log(
        f"ataque PESADO LENTO dmg={HEAVY_DANO:.0f} rate={HEAVY_ANIM_RATE} "
        f"vigor={STATE.vigor:.0f} anim={played}"
    )


def toggle_lock_on(world, pawn) -> None:
    if STATE.lock_name:
        STATE.lock_name = ""
        _log("lock-on OFF")
        return
    if not world or not pawn:
        return
    ploc = pawn.get_actor_location()
    best = None
    best_d = LOCK_RANGE_UU
    for actor in unreal.GameplayStatics.get_all_actors_with_tag(world, "Dummy"):
        if not actor or _actor_hidden(actor):
            continue
        d = _v_len(actor.get_actor_location() - ploc)
        if d < best_d:
            best_d = d
            best = actor
    if best:
        STATE.lock_name = best.get_name()
        _log(f"lock-on → {STATE.lock_name} ({best_d:.0f}uu)")
    else:
        _log("lock-on: nenhum alvo")


def _tick_lock_on(world, pawn) -> None:
    if not STATE.lock_name or not pawn or not world:
        return
    target = None
    for actor in unreal.GameplayStatics.get_all_actors_with_tag(world, "Dummy"):
        if actor and actor.get_name() == STATE.lock_name and not _actor_hidden(actor):
            target = actor
            break
    if not target:
        STATE.lock_name = ""
        return
    try:
        rot = unreal.MathLibrary.find_look_at_rotation(
            pawn.get_actor_location(), target.get_actor_location()
        )
        # so yaw — nunca pitch/roll (evita deitar/inverter)
        pawn.set_actor_rotation(
            unreal.Rotator(roll=0.0, pitch=0.0, yaw=rot.yaw), False
        )
        tloc = target.get_actor_location()
        tloc.z += 120.0
        unreal.SystemLibrary.draw_debug_sphere(
            world,
            tloc,
            18.0,
            8,
            unreal.LinearColor(1.0, 0.2, 0.2, 1.0),
            0.0,
            2.0,
        )
    except Exception:
        pass


def do_hit(world, pawn) -> None:
    if STATE.hit_consumed:
        return
    STATE.hit_consumed = True
    dmg = float(getattr(STATE, "pending_damage", DANO_LEVE) or DANO_LEVE)
    radius = float(getattr(STATE, "pending_radius", RAIO_HIT_UU) or RAIO_HIT_UU)
    origin = pawn.get_actor_location() + pawn.get_actor_forward_vector() * (
        radius * 0.55
    )
    origin.z += 40.0
    max_d2 = (radius + 50.0) ** 2
    hit_any = False
    for actor in unreal.GameplayStatics.get_all_actors_with_tag(world, "Dummy"):
        if not actor or _actor_hidden(actor):
            continue
        if STATE.lock_name and actor.get_name() != STATE.lock_name:
            continue
        if _v_len_sq(actor.get_actor_location() - origin) > max_d2:
            continue
        key = actor.get_name()
        hp = STATE.dummy_hp.get(key, DUMMY_HP) - dmg
        STATE.dummy_hp[key] = hp
        try:
            actor.set_actor_scale3d(unreal.Vector(1.2, 1.2, 1.2))
        except Exception:
            pass
        hit_any = True
        _log(f"hit {key} -{dmg:.0f} → HP {hp:.0f}")
        if hp <= 0.0:
            actor.set_actor_hidden_in_game(True)
            actor.set_actor_enable_collision(False)
            STATE.bytes_kb += BYTES_POR_KILL
            STATE.dummy_hp[key] = DUMMY_HP
            if STATE.lock_name == key:
                STATE.lock_name = ""
            _log(f"dummy morto +{BYTES_POR_KILL} KB (total {STATE.bytes_kb})")
            STATE.dummy_ai[key] = {"state": "dead", "t": 2.0, "cd": 0.0}
        else:
            STATE.dummy_ai.setdefault(key, {"state": "idle", "t": 0.0, "cd": 0.0})
    unreal.SystemLibrary.draw_debug_sphere(
        world,
        origin,
        radius,
        12,
        unreal.LinearColor(1.0, 0.85, 0.1, 1.0)
        if hit_any
        else unreal.LinearColor(0.2, 0.8, 1.0, 1.0),
        0.35,
        1.5,
    )
    STATE.pending_damage = DANO_LEVE
    STATE.pending_radius = RAIO_HIT_UU


def _tick_roll(dt: float, pawn) -> None:
    if not STATE.rolling:
        STATE.invincible = False
        return
    STATE.roll_t += dt
    STATE.invincible = (
        ROLL_INV_START <= STATE.roll_t <= (ROLL_INV_START + ROLL_INV_DUR)
    )

    if pawn:
        _flatten_pawn(pawn)
        _face_dir(pawn, STATE.roll_dir)
        step = STATE.roll_dir * (ROLL_SPEED_UU * dt)
        try:
            loc = pawn.get_actor_location()
            new_loc = unreal.Vector(loc.x + step.x, loc.y + step.y, loc.z)
            pawn.set_actor_location(new_loc, True, False)
        except Exception:
            pass

        if STATE.invincible:
            tip = pawn.get_actor_location()
            tip.z += 70.0
            unreal.SystemLibrary.draw_debug_sphere(
                pawn,
                tip,
                26.0,
                8,
                unreal.LinearColor(0.2, 1.0, 0.3, 1.0),
                0.0,
                1.2,
            )

        # Cambalhota no chao: giro 360 + corpo desce no meio do roll
        if not STATE.roll_use_anim:
            mesh = STATE.roll_mesh
            base = STATE.roll_mesh_rel
            base_loc = STATE.roll_mesh_loc
            if mesh and base is not None:
                try:
                    t = min(1.0, STATE.roll_t / max(0.01, ROLL_DUR))
                    # ease suave no giro
                    ease = t * t * (3.0 - 2.0 * t)
                    spin = 360.0 * ease
                    mesh.set_relative_rotation(
                        unreal.Rotator(
                            roll=base.roll,
                            pitch=base.pitch + spin,
                            yaw=base.yaw,
                        )
                    )
                    if base_loc is not None:
                        # seno: desce no meio (contato com o chao)
                        dip = ROLL_MESH_DIP_UU * (math_sin_pi(t))
                        mesh.set_relative_location(
                            unreal.Vector(
                                base_loc.x, base_loc.y, base_loc.z - dip
                            )
                        )
                except Exception:
                    pass

    if STATE.roll_t >= ROLL_DUR:
        mesh = STATE.roll_mesh
        base = STATE.roll_mesh_rel
        base_loc = STATE.roll_mesh_loc
        if mesh:
            try:
                if base is not None:
                    mesh.set_relative_rotation(base)
                if base_loc is not None:
                    mesh.set_relative_location(base_loc)
            except Exception:
                pass
        try:
            if STATE.roll_was_crouched and hasattr(pawn, "uncrouch"):
                pawn.uncrouch()
        except Exception:
            pass
        # aterrissa
        try:
            if pawn and not STATE.roll_use_anim:
                _play_anim_seq(pawn, LAND_SEQ, rate=1.35)
        except Exception:
            pass
        STATE.roll_mesh = None
        STATE.roll_mesh_rel = None
        STATE.roll_mesh_loc = None
        STATE.roll_use_anim = False
        STATE.roll_was_crouched = False
        STATE.rolling = False
        STATE.invincible = False
        STATE.roll_t = 0.0
        _flatten_pawn(pawn)
        _log("ROLL fim")


def math_sin_pi(t: float) -> float:
    """sin(pi * t) sem import math (0→1→0)."""
    # approx via unreal se disponivel
    try:
        return float(unreal.MathLibrary.sin(3.14159265 * float(t)))
    except Exception:
        # parabola 4t(1-t) ~ mesma forma
        tt = max(0.0, min(1.0, float(t)))
        return 4.0 * tt * (1.0 - tt)


def _tick_dummy_ai(dt: float, world, pawn) -> None:
    if not pawn:
        return
    ploc = pawn.get_actor_location()
    for actor in unreal.GameplayStatics.get_all_actors_with_tag(world, "Dummy"):
        if not actor:
            continue
        key = actor.get_name()
        st = STATE.dummy_ai.setdefault(
            key, {"state": "idle", "t": 0.0, "cd": 0.5}
        )
        if st["state"] == "dead":
            st["t"] -= dt
            if st["t"] <= 0.0:
                actor.set_actor_hidden_in_game(False)
                actor.set_actor_enable_collision(True)
                actor.set_actor_scale3d(unreal.Vector(1.0, 1.0, 1.0))
                STATE.dummy_hp[key] = DUMMY_HP
                st["state"] = "idle"
                st["cd"] = 1.0
            continue
        if _actor_hidden(actor):
            continue
        dloc = actor.get_actor_location()
        dist = _v_len(ploc - dloc)
        if st["state"] == "idle":
            st["cd"] = max(0.0, st["cd"] - dt)
            if st["cd"] <= 0.0 and dist <= DUMMY_ALCANCE_UU:
                st["state"] = "windup"
                st["t"] = 0.0
        elif st["state"] == "windup":
            st["t"] += dt
            mid = dloc + unreal.Vector(0.0, 0.0, 80.0)
            unreal.SystemLibrary.draw_debug_sphere(
                world,
                mid,
                40.0 + st["t"] * 30.0,
                10,
                unreal.LinearColor(1.0, 0.9, 0.1, 1.0),
                0.0,
                2.0,
            )
            if st["t"] >= DUMMY_PREP:
                if dist <= DUMMY_ALCANCE_UU + 40.0:
                    if STATE.invincible:
                        _log(f"{key} bloqueado i-frame")
                        unreal.SystemLibrary.draw_debug_sphere(
                            world,
                            mid,
                            55.0,
                            10,
                            unreal.LinearColor(0.2, 1.0, 0.4, 1.0),
                            0.4,
                            2.0,
                        )
                    else:
                        STATE.hp = max(0.0, STATE.hp - DUMMY_DANO)
                        _log(f"{key} hit player → HP {STATE.hp:.0f}")
                        unreal.SystemLibrary.draw_debug_sphere(
                            world,
                            mid,
                            55.0,
                            10,
                            unreal.LinearColor(1.0, 0.15, 0.1, 1.0),
                            0.4,
                            2.0,
                        )
                        if STATE.hp <= 0.0:
                            STATE.hp = PLAYER_MAX_HP
                            _log("player morreu (treino) — HP reset")
                st["state"] = "recover"
                st["t"] = 0.0
        elif st["state"] == "recover":
            st["t"] += dt
            if st["t"] >= DUMMY_RECUP:
                st["state"] = "idle"
                st["cd"] = DUMMY_INTERVALO


def reset_pie_state() -> None:
    STATE.hp = PLAYER_MAX_HP
    STATE.vigor = MAX_VIGOR
    STATE.vigor_delay = 0.0
    STATE.rolling = False
    STATE.attacking = False
    STATE.invincible = False
    STATE.charging = False
    STATE.charge_t = 0.0
    STATE.lock_name = ""
    STATE.pending_damage = DANO_LEVE
    STATE.pending_radius = RAIO_HIT_UU
    STATE.roll_mesh = None
    STATE.roll_mesh_rel = None
    STATE.roll_mesh_loc = None
    STATE.roll_use_anim = False
    STATE.roll_was_crouched = False
    STATE.dummies_spawned = False
    STATE.hud_set = False
    STATE.pie_ready = False
    STATE.dummy_hp.clear()
    STATE.dummy_ai.clear()
    STATE.was_lmb = False
    STATE.was_face = False
    STATE.was_roll = False
    STATE.was_atk_key = False
    STATE.was_heavy = False
    STATE.was_lock = False


# ---------------------------------------------------------------------------
# Slate tick (coração do sistema)
# ---------------------------------------------------------------------------

_last_had_pie = False


def combat_slate_tick(_dt) -> bool:
    """Callback fixo; logica real em _TICK_IMPL (reload-safe)."""
    if _TICK_IMPL:
        try:
            return _TICK_IMPL[-1](_dt)
        except Exception as exc:
            _log(f"tick crash: {exc}")
            return True
    return True


def _vk_down(vk: int) -> bool:
    """Tecla fisica no Windows (funciona mesmo com Log focado)."""
    try:
        return bool(ctypes.windll.user32.GetAsyncKeyState(vk) & 0x8000)
    except Exception:
        return False


# Virtual-key codes
_VK_LBUTTON = 0x01
_VK_RBUTTON = 0x02
_VK_MBUTTON = 0x04
_VK_TAB = 0x09
_VK_E = 0x45
_VK_G = 0x47
_VK_R = 0x52
_VK_F = 0x46
_VK_V = 0x56
_VK_Q = 0x51
_VK_C = 0x43
_VK_LCONTROL = 0xA2
_VK_RCONTROL = 0xA3
_VK_CONTROL = 0x11


def _combat_tick_impl(_dt) -> bool:
    global _last_had_pie
    world, pc, pawn = get_pc_pawn()
    had = world is not None and pawn is not None
    if not had:
        if _last_had_pie:
            reset_pie_state()
            _log("PIE encerrado — estado reset")
        _last_had_pie = False
        return True
    if not _last_had_pie:
        reset_pie_state()
        _log("PIE iniciado — leve R/LMB | pesado E/RMB | lock Tab | roll Ctrl")
    _last_had_pie = True

    dt = float(_dt) if _dt and _dt > 0.0 else 1.0 / 30.0
    dt = min(0.05, max(0.001, dt))

    ensure_hud(pc)
    ensure_pie_dummies(world, pawn)
    _flatten_pawn(pawn)

    try:
        loc = pawn.get_actor_location() + unreal.Vector(0.0, 0.0, 130.0)
        kb = STATE.bytes_kb
        bt = f"{kb}KB" if kb < 1024 else f"{kb/1024:.1f}MB"
        lock = f" LOCK" if STATE.lock_name else ""
        roll = " ROLL" if STATE.rolling else ""
        unreal.SystemLibrary.draw_debug_string(
            world,
            loc,
            f"HP {STATE.hp:.0f}  VIG {STATE.vigor:.0f}  {bt}{lock}{roll}",
            None,
            unreal.LinearColor(0.9, 1.0, 0.75, 1.0),
            0.0,
        )
    except Exception:
        pass

    STATE.cooldown = max(0.0, STATE.cooldown - dt)
    _tick_vigor(dt)
    _tick_roll(dt, pawn)
    _tick_restore_anim(dt)
    _tick_lock_on(world, pawn)

    # Pesado: clique E ou RMB
    heavy_down = _vk_down(_VK_E) or _vk_down(_VK_RBUTTON)
    if heavy_down and not STATE.was_heavy:
        _log("INPUT ataque pesado")
        try_heavy(pawn)
    STATE.was_heavy = heavy_down

    # Lock-on: Tab / G / botao do meio
    lock_down = (
        _vk_down(_VK_TAB) or _vk_down(_VK_G) or _vk_down(_VK_MBUTTON)
    )
    if lock_down and not STATE.was_lock:
        toggle_lock_on(world, pawn)
    STATE.was_lock = lock_down

    # Leve: R/F/V/Q ou LMB
    lmb = _vk_down(_VK_LBUTTON)
    atk_key = (
        _vk_down(_VK_R)
        or _vk_down(_VK_F)
        or _vk_down(_VK_V)
        or _vk_down(_VK_Q)
    )
    pressed = (lmb and not STATE.was_lmb) or (atk_key and not STATE.was_atk_key)
    STATE.was_lmb = lmb
    STATE.was_atk_key = atk_key
    if pressed:
        _log("INPUT ataque leve")
        try_attack(pawn)

    roll_down = (
        _vk_down(_VK_C)
        or _vk_down(_VK_CONTROL)
        or _vk_down(_VK_LCONTROL)
        or _vk_down(_VK_RCONTROL)
    )
    if roll_down and not STATE.was_roll:
        try_roll(pawn, pc)
    STATE.was_roll = roll_down

    if STATE.hit_timer >= 0.0:
        STATE.hit_timer -= dt
        if STATE.hit_timer <= 0.0:
            STATE.hit_timer = -1.0
            if not STATE.hit_consumed:
                do_hit(world, pawn)
            STATE.attacking = False
            _flatten_pawn(pawn)

    try:
        _tick_dummy_ai(dt, world, pawn)
    except Exception as exc:
        _log(f"dummy AI erro (ignorado): {exc}")

    STATE.tick_accum += dt
    if STATE.tick_accum >= 10.0:
        STATE.tick_accum = 0.0
        lock_txt = STATE.lock_name or "-"
        _log(
            f"ok HP={STATE.hp:.0f} VIG={STATE.vigor:.0f} KB={STATE.bytes_kb} "
            f"lock={lock_txt}"
        )

    return True


def start_combat_driver() -> None:
    global _REGISTERED
    _TICK_IMPL.clear()
    _TICK_IMPL.append(_combat_tick_impl)
    try:
        preload_combat_assets()
    except Exception as exc:
        _log(f"preload: {exc}")
    if not _REGISTERED:
        try:
            unreal.register_slate_post_tick_callback(combat_slate_tick)
            _REGISTERED = True
            _log("CombatDriver ON — R leve | E pesado | Ctrl roll | Tab lock")
        except Exception as exc:
            _log(f"register driver: {exc}")
    else:
        _log("CombatDriver reload — R leve | E pesado | Ctrl roll | Tab lock")


def ensure_session_combat() -> None:
    start_combat_driver()
