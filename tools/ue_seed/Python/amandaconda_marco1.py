"""
AMANDACONDA — Marco 2: ataque leve + vigor + rolamento (i-frames) + dummy que rebate.

Números da fase 1 (data/balance.json):
  - ataque leve: dano 12, vigor 16, alcance ~90 uu
  - rolamento: 0.42s, i-frames 0.05–0.31, vigor 25
  - vigor: max 100, regen 40/s após delay 0.7s
  - boneco: vida 200, rebate 18, prep 0.55
"""

from __future__ import annotations

import unreal

# --- Balance (NUMEROS / balance.json) ---
DANO_LEVE = 12.0
VIGOR_ATAQUE = 16.0
ALCANCE_UU = 90.0
RAIO_HIT_UU = 55.0
DUMMY_HP = 200.0
HIT_DELAY = 0.22  # janela de acerto se o AnimNotify falhar
ATTACK_COOLDOWN = 0.45

MAX_VIGOR = 100.0
VIGOR_REGEN = 40.0
VIGOR_REGEN_DELAY = 0.7

ROLL_DUR = 0.42
ROLL_INV_START = 0.05
ROLL_INV_DUR = 0.26
ROLL_VIGOR = 25.0
ROLL_SPEED_UU = 780.0  # balance 260 px/s → UU pragmático

PLAYER_MAX_HP = 100.0
DUMMY_DANO = 18.0
DUMMY_ALCANCE_UU = 160.0
DUMMY_INTERVALO = 2.6
DUMMY_PREP = 0.55
DUMMY_RECUP = 0.6

ATTACK_SEQ = "/Game/Characters/Mannequins/Anims/Unarmed/Attack/MM_Attack_01"
MONTAGE_PATH = "/Game/Amandaconda/Combat/AM_Attack_01"
IA_ATTACK_PATH = "/Game/Input/Actions/IA_Attack"
IMC_PATH = "/Game/Input/IMC_Default"
CHAR_BP = "/Game/ThirdPerson/Blueprints/BP_ThirdPersonCharacter"
LEVEL_PATH = "/Game/ThirdPerson/Lvl_ThirdPerson"


def _log(msg: str) -> None:
    unreal.log(f"[AMANDACONDA] {msg}")


def _ensure_dir(path: str) -> None:
    if not unreal.EditorAssetLibrary.does_directory_exist(path):
        unreal.EditorAssetLibrary.make_directory(path)


# --- Helpers testáveis (Marco 2) ---


def vigor_after_spend(vigor: float, cost: float) -> float | None:
    """Retorna novo vigor ou None se não der pra gastar."""
    if vigor < cost:
        return None
    return vigor - cost


def vigor_regen_step(
    vigor: float, delay: float, delta: float, busy: bool
) -> tuple[float, float]:
    """Aplica delay/regen de um frame. Retorna (vigor, delay)."""
    if delay > 0.0:
        return vigor, max(0.0, delay - delta)
    if busy:
        return vigor, 0.0
    return min(MAX_VIGOR, vigor + VIGOR_REGEN * delta), 0.0


def iframe_active(roll_t: float) -> bool:
    return ROLL_INV_START <= roll_t <= (ROLL_INV_START + ROLL_INV_DUR)


# ---------------------------------------------------------------------------
# Gameplay classes (PIE)
# ---------------------------------------------------------------------------


@unreal.uclass()
class AN_HitWindow(unreal.AnimNotify):
    """AnimNotify da janela de hit — chama MeleeCombatComponent.do_hit_trace."""

    @unreal.ufunction(override=True)
    def received_notify(self, mesh_comp, animation, event_reference):
        owner = mesh_comp.get_owner() if mesh_comp else None
        if not owner:
            return False
        comp = owner.get_component_by_class(MeleeCombatComponent)
        if comp:
            comp.do_hit_trace()
        return True


@unreal.uclass()
class MeleeCombatComponent(unreal.ActorComponent):
    """Ataque leve: input → montage → hit window → sphere overlap."""

    attack_montage = unreal.uproperty(unreal.AnimMontage)
    is_attacking = unreal.uproperty(bool)
    hit_consumed = unreal.uproperty(bool)

    def _init_defaults(self):
        if not hasattr(self, "_ready"):
            self.is_attacking = False
            self.hit_consumed = False
            self._cooldown = 0.0
            self._hit_timer = -1.0
            self._was_lmb = False
            self._ready = True

    @unreal.ufunction(override=True)
    def receive_begin_play(self):
        self._init_defaults()
        if not self.attack_montage:
            self.attack_montage = unreal.EditorAssetLibrary.load_asset(MONTAGE_PATH)
        _log(f"MeleeCombat no {self.get_owner().get_name()}")

    @unreal.ufunction(override=True)
    def receive_tick(self, delta_seconds: float):
        self._init_defaults()
        self._cooldown = max(0.0, self._cooldown - delta_seconds)

        if self._hit_timer >= 0.0:
            self._hit_timer -= delta_seconds
            if self._hit_timer <= 0.0:
                self._hit_timer = -1.0
                if not self.hit_consumed:
                    self.do_hit_trace()

        owner = self.get_owner()
        if not owner:
            return
        pc = unreal.GameplayStatics.get_player_controller(owner, 0)
        if not pc:
            return

        # Input direto (LMB / gamepad X) — não depende de nós de Blueprint.
        lmb = bool(pc.is_input_key_down(unreal.Key("LeftMouseButton")))
        face = bool(pc.is_input_key_down(unreal.Key("Gamepad_FaceButton_Left")))
        pressed = (lmb and not self._was_lmb) or (face and not getattr(self, "_was_face", False))
        self._was_lmb = lmb
        self._was_face = face
        if pressed:
            self.try_attack()

    @unreal.ufunction(ret=None)
    def try_attack(self):
        """Fallback se o component estiver no pawn; o caminho principal é ACombatBootstrap."""
        self._init_defaults()
        if self.is_attacking or self._cooldown > 0.0:
            return
        owner = self.get_owner()
        if not owner:
            return
        mesh = owner.get_component_by_class(unreal.SkeletalMeshComponent)
        if not mesh:
            return
        anim = mesh.get_anim_instance()
        if not anim:
            return

        montage = self.attack_montage
        if not montage:
            seq = unreal.EditorAssetLibrary.load_asset(ATTACK_SEQ)
            if isinstance(seq, unreal.AnimSequence):
                anim.play_slot_animation_as_dynamic_montage(
                    seq, "DefaultSlot", 0.1, 0.15, 1.0, 1
                )
                self.is_attacking = True
                self.hit_consumed = False
                self._hit_timer = HIT_DELAY
                self._cooldown = ATTACK_COOLDOWN
                _log("ataque (dynamic montage)")
            return

        duration = anim.montage_play(montage, 1.0)
        if duration > 0.0:
            self.is_attacking = True
            self.hit_consumed = False
            self._hit_timer = HIT_DELAY
            self._cooldown = ATTACK_COOLDOWN
            _log(f"ataque montage {duration:.2f}s")
            unreal.SystemLibrary.set_timer(
                self, "end_attack", max(0.2, duration * 0.95), False
            )

    @unreal.ufunction(ret=None)
    def end_attack(self):
        self.is_attacking = False
        self._hit_timer = -1.0

    @unreal.ufunction(ret=None)
    def do_hit_trace(self):
        self._init_defaults()
        if self.hit_consumed:
            return
        self.hit_consumed = True

        owner = self.get_owner()
        if not owner:
            return

        origin = owner.get_actor_location() + owner.get_actor_forward_vector() * (
            ALCANCE_UU * 0.55
        )
        origin.z += 40.0
        max_dist_sq = (RAIO_HIT_UU + 40.0) * (RAIO_HIT_UU + 40.0)

        hit_any = False
        # Tag Dummy = confiável (overlap por ObjectType varia no template).
        dummies = unreal.GameplayStatics.get_all_actors_with_tag(owner, "Dummy")
        for actor in dummies:
            if not actor or actor is owner:
                continue
            delta = actor.get_actor_location() - origin
            if delta.size_squared() > max_dist_sq:
                continue
            unreal.GameplayStatics.apply_damage(
                actor,
                DANO_LEVE,
                unreal.GameplayStatics.get_player_controller(owner, 0),
                owner,
                unreal.DamageType,
            )
            hit_any = True
            _log(f"hit {actor.get_name()} por {DANO_LEVE}")

        unreal.SystemLibrary.draw_debug_sphere(
            owner,
            origin,
            RAIO_HIT_UU,
            12,
            unreal.LinearColor(1.0, 0.85, 0.1, 1.0)
            if hit_any
            else unreal.LinearColor(0.2, 0.8, 1.0, 1.0),
            0.35,
            1.5,
        )


def _register_component(owner, comp_class, name: str):
    """Cria e registra um ActorComponent em runtime/PIE (sem add_component_by_class)."""
    existing = owner.get_component_by_class(comp_class)
    if existing:
        return existing
    comp = unreal.new_object(comp_class, owner, name)
    if hasattr(comp, "register_component"):
        comp.register_component()
    try:
        owner.add_instance_component(comp)
    except Exception:
        pass
    return comp


@unreal.uclass()
class ADummyTarget(unreal.StaticMeshActor):
    """Boneco de treino — cubo com vida 200 (números da fase 1)."""

    max_hp = unreal.uproperty(float)
    hp = unreal.uproperty(float)

    @unreal.ufunction(override=True)
    def receive_begin_play(self):
        if not self.actor_has_tag("Dummy"):
            self.tags.append("Dummy")
        if not self.max_hp:
            self.max_hp = DUMMY_HP
        self.hp = self.max_hp
        self._flash_t = 0.0

        mesh = self.static_mesh_component
        cube = unreal.EditorAssetLibrary.load_asset("/Engine/BasicShapes/Cube")
        if mesh and cube:
            mesh.set_static_mesh(cube)
            mesh.set_relative_scale3d(unreal.Vector(0.7, 0.7, 1.6))
            mesh.set_collision_profile_name("BlockAllDynamic")
            mesh.set_generate_overlap_events(True)
        _log(f"ADummyTarget pronto HP={self.hp}")

    @unreal.ufunction(override=True)
    def receive_tick(self, delta_seconds: float):
        if getattr(self, "_flash_t", 0.0) > 0.0:
            self._flash_t -= delta_seconds
            if self._flash_t <= 0.0:
                self.set_actor_scale3d(unreal.Vector(1.0, 1.0, 1.0))

    @unreal.ufunction(override=True)
    def receive_any_damage(
        self, damage, damage_type, instigated_by, damage_causer
    ):
        if not self.max_hp:
            self.max_hp = DUMMY_HP
        self.hp = max(0.0, float(self.hp) - float(damage))
        self._flash_t = 0.12
        self.set_actor_scale3d(unreal.Vector(1.15, 1.15, 1.15))
        _log(f"Dummy tomou {damage:.0f} → HP {self.hp:.0f}/{self.max_hp:.0f}")
        if self.hp <= 0.0:
            _log("Dummy morto — respawn em 2s")
            unreal.SystemLibrary.set_timer(self, "respawn_dummy", 2.0, False)
            self.set_actor_hidden_in_game(True)
            self.set_actor_enable_collision(False)

    @unreal.ufunction(ret=None)
    def respawn_dummy(self):
        self.hp = self.max_hp or DUMMY_HP
        self.set_actor_hidden_in_game(False)
        self.set_actor_enable_collision(True)
        self.set_actor_scale3d(unreal.Vector(1.0, 1.0, 1.0))
        _log("Dummy reviveu")


@unreal.uclass()
class ACombatBootstrap(unreal.Actor):
    """Marco 2 PIE: ataque + vigor + roll/i-frames + dummy que rebate."""

    @unreal.ufunction(override=True)
    def receive_begin_play(self):
        # Actor Python NÃO ticka sem isso — sem tick = sem ataque / dummy AI.
        try:
            self.set_actor_tick_enabled(True)
            tick = self.primary_actor_tick
            tick.can_ever_tick = True
            tick.start_with_tick_enabled = True
            self.primary_actor_tick = tick
        except Exception as exc:
            _log(f"tick enable: {exc}")
        self._cooldown = 0.0
        self._hit_timer = -1.0
        self._attacking = False
        self._hit_consumed = False
        self._was_lmb = False
        self._was_face = False
        self._was_roll = False
        try:
            self._montage = unreal.EditorAssetLibrary.load_asset(MONTAGE_PATH)
        except Exception:
            self._montage = None
        self._hp = {}
        self._vigor = MAX_VIGOR
        self._vigor_delay = 0.0
        self._rolling = False
        self._roll_t = 0.0
        self._invincible = False
        self._player_hp = PLAYER_MAX_HP
        self._dummy_ai = {}  # name -> {state, t, cd}
        self._hud_accum = 0.0
        self._tick_log_t = 0.0
        _log("CombatBootstrap Marco2 ativo (vigor + roll + dummy AI) TICK ON")

    def _spend_vigor(self, cost: float) -> bool:
        vigor = float(getattr(self, "_vigor", MAX_VIGOR))
        nxt = vigor_after_spend(vigor, cost)
        if nxt is None:
            return False
        self._vigor = nxt
        self._vigor_delay = VIGOR_REGEN_DELAY
        return True

    def _tick_vigor(self, delta: float) -> None:
        busy = bool(
            getattr(self, "_rolling", False) or getattr(self, "_attacking", False)
        )
        self._vigor, self._vigor_delay = vigor_regen_step(
            float(getattr(self, "_vigor", MAX_VIGOR)),
            float(getattr(self, "_vigor_delay", 0.0)),
            delta,
            busy,
        )

    def _roll_direction(self, pawn, pc):
        fwd = pawn.get_actor_forward_vector()
        right = pawn.get_actor_right_vector()
        x = 0.0
        y = 0.0
        if pc:
            if pc.is_input_key_down(unreal.Key("W")):
                x += 1.0
            if pc.is_input_key_down(unreal.Key("S")):
                x -= 1.0
            if pc.is_input_key_down(unreal.Key("D")):
                y += 1.0
            if pc.is_input_key_down(unreal.Key("A")):
                y -= 1.0
            # analógico esquerdo (aprox. eixos do gamepad)
            try:
                ax = float(pc.get_input_analog_key_state(unreal.Key("Gamepad_LeftX")))
                ay = float(pc.get_input_analog_key_state(unreal.Key("Gamepad_LeftY")))
                if abs(ax) > 0.2 or abs(ay) > 0.2:
                    y = ax
                    x = ay
            except Exception:
                pass
        direction = fwd * x + right * y
        if direction.size_squared() < 0.01:
            direction = fwd
        direction.z = 0.0
        direction.normalize()
        return direction

    def _is_invincible(self) -> bool:
        return bool(getattr(self, "_invincible", False))

    @unreal.ufunction(override=True)
    def receive_tick(self, delta_seconds: float):
        self._tick_log_t = float(getattr(self, "_tick_log_t", 0.0)) + delta_seconds
        if self._tick_log_t >= 2.0:
            self._tick_log_t = 0.0
            _log(
                f"tick ok vigor={float(getattr(self, '_vigor', 0)):.0f} "
                f"hp={float(getattr(self, '_player_hp', 0)):.0f}"
            )
        self._cooldown = max(0.0, getattr(self, "_cooldown", 0.0) - delta_seconds)
        self._tick_vigor(delta_seconds)
        self._tick_roll(delta_seconds)
        self._tick_dummy_ai(delta_seconds)
        self._tick_debug_hud(delta_seconds)

        if getattr(self, "_hit_timer", -1.0) >= 0.0:
            self._hit_timer -= delta_seconds
            if self._hit_timer <= 0.0:
                self._hit_timer = -1.0
                if not getattr(self, "_hit_consumed", False):
                    self._do_hit()

        pc = unreal.GameplayStatics.get_player_controller(self, 0)
        if not pc:
            return

        lmb = bool(pc.is_input_key_down(unreal.Key("LeftMouseButton")))
        face = bool(pc.is_input_key_down(unreal.Key("Gamepad_FaceButton_Left")))
        pressed = (lmb and not getattr(self, "_was_lmb", False)) or (
            face and not getattr(self, "_was_face", False)
        )
        self._was_lmb = lmb
        self._was_face = face
        if pressed:
            self._try_attack()

        roll_down = (
            bool(pc.is_input_key_down(unreal.Key("LeftControl")))
            or bool(pc.is_input_key_down(unreal.Key("C")))
            or bool(pc.is_input_key_down(unreal.Key("Gamepad_FaceButton_Right")))
        )
        roll_pressed = roll_down and not getattr(self, "_was_roll", False)
        self._was_roll = roll_down
        if roll_pressed:
            self._try_roll()

    def _tick_roll(self, delta: float) -> None:
        if not getattr(self, "_rolling", False):
            self._invincible = False
            return
        self._roll_t = float(getattr(self, "_roll_t", 0.0)) + delta
        t = self._roll_t
        self._invincible = iframe_active(t)

        pawn = unreal.GameplayStatics.get_player_pawn(self, 0)
        if pawn and hasattr(self, "_roll_dir"):
            # mantém impulso horizontal durante o roll
            try:
                move = pawn.get_component_by_class(unreal.CharacterMovementComponent)
                if move:
                    d = self._roll_dir
                    vel = move.velocity
                    move.velocity = unreal.Vector(
                        d.x * ROLL_SPEED_UU, d.y * ROLL_SPEED_UU, vel.z
                    )
            except Exception:
                pass
            if self._invincible:
                loc = pawn.get_actor_location()
                loc.z += 90.0
                unreal.SystemLibrary.draw_debug_sphere(
                    self,
                    loc,
                    28.0,
                    8,
                    unreal.LinearColor(0.2, 1.0, 0.3, 1.0),
                    0.0,
                    1.2,
                )

        if t >= ROLL_DUR:
            self._rolling = False
            self._invincible = False
            self._roll_t = 0.0
            _log("roll fim")

    @unreal.ufunction(ret=None)
    def _try_roll(self):
        if getattr(self, "_rolling", False) or getattr(self, "_attacking", False):
            return
        if not self._spend_vigor(ROLL_VIGOR):
            _log("roll bloqueado — sem vigor")
            return
        pawn = unreal.GameplayStatics.get_player_pawn(self, 0)
        pc = unreal.GameplayStatics.get_player_controller(self, 0)
        if not pawn:
            return
        direction = self._roll_direction(pawn, pc)
        self._roll_dir = direction
        self._rolling = True
        self._roll_t = 0.0
        self._invincible = False
        launch = unreal.Vector(
            direction.x * ROLL_SPEED_UU,
            direction.y * ROLL_SPEED_UU,
            80.0,
        )
        try:
            if hasattr(pawn, "launch_character"):
                pawn.launch_character(launch, True, True)
            else:
                move = pawn.get_component_by_class(unreal.CharacterMovementComponent)
                if move:
                    move.velocity = launch
        except Exception as exc:
            _log(f"launch roll: {exc}")
        _log(f"ROLL vigor={self._vigor:.0f}")

    @unreal.ufunction(ret=None)
    def _try_attack(self):
        if getattr(self, "_attacking", False) or getattr(self, "_rolling", False):
            return
        if getattr(self, "_cooldown", 0.0) > 0.0:
            return
        if not self._spend_vigor(VIGOR_ATAQUE):
            _log("ataque bloqueado — sem vigor")
            return
        pawn = unreal.GameplayStatics.get_player_pawn(self, 0)
        if not pawn:
            return
        mesh = pawn.get_component_by_class(unreal.SkeletalMeshComponent)
        if not mesh:
            return
        anim = mesh.get_anim_instance()
        if not anim:
            return

        montage = getattr(self, "_montage", None)
        played = False
        if montage:
            duration = anim.montage_play(montage, 1.0)
            played = duration > 0.0
            if played:
                unreal.SystemLibrary.set_timer(
                    self, "_end_attack", max(0.2, duration * 0.95), False
                )
        if not played:
            seq = unreal.EditorAssetLibrary.load_asset(ATTACK_SEQ)
            if isinstance(seq, unreal.AnimSequence):
                anim.play_slot_animation_as_dynamic_montage(
                    seq, "DefaultSlot", 0.1, 0.15, 1.0, 1
                )
                played = True
                unreal.SystemLibrary.set_timer(self, "_end_attack", 0.8, False)
        if not played:
            # devolve vigor se anim falhou
            self._vigor = min(MAX_VIGOR, self._vigor + VIGOR_ATAQUE)
            return
        self._attacking = True
        self._hit_consumed = False
        self._hit_timer = HIT_DELAY
        self._cooldown = ATTACK_COOLDOWN
        _log(f"ataque vigor={self._vigor:.0f}")

    @unreal.ufunction(ret=None)
    def _end_attack(self):
        self._attacking = False
        self._hit_timer = -1.0

    @unreal.ufunction(ret=None)
    def _do_hit(self):
        if getattr(self, "_hit_consumed", False):
            return
        self._hit_consumed = True
        if not hasattr(self, "_hp"):
            self._hp = {}
        pawn = unreal.GameplayStatics.get_player_pawn(self, 0)
        if not pawn:
            return
        origin = pawn.get_actor_location() + pawn.get_actor_forward_vector() * (
            ALCANCE_UU * 0.55
        )
        origin.z += 40.0
        max_dist_sq = (RAIO_HIT_UU + 40.0) * (RAIO_HIT_UU + 40.0)
        hit_any = False
        for actor in unreal.GameplayStatics.get_all_actors_with_tag(self, "Dummy"):
            if not actor or actor.is_hidden():
                continue
            if (actor.get_actor_location() - origin).size_squared() > max_dist_sq:
                continue
            key = actor.get_name()
            if isinstance(actor, ADummyTarget):
                unreal.GameplayStatics.apply_damage(
                    actor,
                    DANO_LEVE,
                    unreal.GameplayStatics.get_player_controller(self, 0),
                    pawn,
                    unreal.DamageType,
                )
            else:
                hp = self._hp.get(key, DUMMY_HP) - DANO_LEVE
                self._hp[key] = hp
                actor.set_actor_scale3d(unreal.Vector(1.15, 1.15, 1.15))
                _log(f"hit {key} por {DANO_LEVE} → HP {hp:.0f}/{DUMMY_HP:.0f}")
                if hp <= 0.0:
                    actor.set_actor_hidden_in_game(True)
                    actor.set_actor_enable_collision(False)
                    self._hp[key] = DUMMY_HP
                    unreal.SystemLibrary.set_timer(
                        self, "_respawn_hidden_dummies", 2.0, False
                    )
                else:
                    unreal.SystemLibrary.set_timer(self, "_reset_scales", 0.12, False)
            hit_any = True
            _log(f"hit {actor.get_name()} por {DANO_LEVE}")
        unreal.SystemLibrary.draw_debug_sphere(
            self,
            origin,
            RAIO_HIT_UU,
            12,
            unreal.LinearColor(1.0, 0.85, 0.1, 1.0)
            if hit_any
            else unreal.LinearColor(0.2, 0.8, 1.0, 1.0),
            0.35,
            1.5,
        )

    def _tick_dummy_ai(self, delta: float) -> None:
        pawn = unreal.GameplayStatics.get_player_pawn(self, 0)
        if not pawn:
            return
        if not hasattr(self, "_dummy_ai"):
            self._dummy_ai = {}
        player_loc = pawn.get_actor_location()
        for actor in unreal.GameplayStatics.get_all_actors_with_tag(self, "Dummy"):
            if not actor or actor.is_hidden():
                continue
            key = actor.get_name()
            st = self._dummy_ai.get(key)
            if not st:
                st = {"state": "idle", "t": 0.0, "cd": 0.5}
                self._dummy_ai[key] = st

            dloc = actor.get_actor_location()
            dist = (player_loc - dloc).size()
            state = st["state"]

            if state == "idle":
                st["cd"] = max(0.0, st["cd"] - delta)
                if st["cd"] <= 0.0 and dist <= DUMMY_ALCANCE_UU:
                    st["state"] = "windup"
                    st["t"] = 0.0
                    _log(f"{key} windup")
            elif state == "windup":
                st["t"] += delta
                # telegrafia amarela
                mid = dloc + unreal.Vector(0.0, 0.0, 80.0)
                unreal.SystemLibrary.draw_debug_sphere(
                    self,
                    mid,
                    40.0 + st["t"] * 30.0,
                    10,
                    unreal.LinearColor(1.0, 0.9, 0.1, 1.0),
                    0.0,
                    2.0,
                )
                if st["t"] >= DUMMY_PREP:
                    self._dummy_try_hit(actor, pawn)
                    st["state"] = "recover"
                    st["t"] = 0.0
            elif state == "recover":
                st["t"] += delta
                if st["t"] >= DUMMY_RECUP:
                    st["state"] = "idle"
                    st["cd"] = DUMMY_INTERVALO

    def _dummy_try_hit(self, dummy, pawn) -> None:
        dloc = dummy.get_actor_location()
        ploc = pawn.get_actor_location()
        if (ploc - dloc).size() > DUMMY_ALCANCE_UU + 40.0:
            _log(f"{dummy.get_name()} errou (longe)")
            return
        mid = dloc + unreal.Vector(0.0, 0.0, 80.0)
        if self._is_invincible():
            unreal.SystemLibrary.draw_debug_sphere(
                self,
                mid,
                55.0,
                10,
                unreal.LinearColor(0.2, 1.0, 0.4, 1.0),
                0.5,
                2.5,
            )
            _log(f"{dummy.get_name()} golpe BLOQUEADO por i-frame")
            return
        self._player_hp = max(
            0.0, float(getattr(self, "_player_hp", PLAYER_MAX_HP)) - DUMMY_DANO
        )
        unreal.SystemLibrary.draw_debug_sphere(
            self,
            mid,
            55.0,
            10,
            unreal.LinearColor(1.0, 0.15, 0.1, 1.0),
            0.5,
            2.5,
        )
        # feedback: tranco leve no pawn
        try:
            away = ploc - dloc
            away.z = 0.0
            if away.size_squared() > 1.0:
                away.normalize()
                if hasattr(pawn, "launch_character"):
                    pawn.launch_character(
                        unreal.Vector(away.x * 280.0, away.y * 280.0, 120.0),
                        True,
                        True,
                    )
        except Exception:
            pass
        _log(
            f"{dummy.get_name()} acertou {DUMMY_DANO:.0f} → "
            f"player HP {self._player_hp:.0f}/{PLAYER_MAX_HP:.0f}"
        )
        if self._player_hp <= 0.0:
            self._player_hp = PLAYER_MAX_HP
            _log("player morreu no treino — HP reset (retry)")

    def _tick_debug_hud(self, delta: float) -> None:
        self._hud_accum = float(getattr(self, "_hud_accum", 0.0)) + delta
        pawn = unreal.GameplayStatics.get_player_pawn(self, 0)
        if not pawn:
            return
        loc = pawn.get_actor_location() + unreal.Vector(0.0, 0.0, 120.0)
        iframe = "IFRAME" if self._is_invincible() else ""
        roll = "ROLL" if getattr(self, "_rolling", False) else ""
        text = (
            f"VIGOR {float(getattr(self, '_vigor', 0)):.0f}/{MAX_VIGOR:.0f}  "
            f"HP {float(getattr(self, '_player_hp', 0)):.0f}  {roll} {iframe}"
        )
        try:
            unreal.SystemLibrary.draw_debug_string(
                self,
                loc,
                text,
                None,
                unreal.LinearColor(0.85, 1.0, 0.7, 1.0),
                0.0,
            )
        except Exception:
            # fallback: log a cada ~1s
            if self._hud_accum >= 1.0:
                self._hud_accum = 0.0
                _log(text)

    @unreal.ufunction(ret=None)
    def _reset_scales(self):
        for actor in unreal.GameplayStatics.get_all_actors_with_tag(self, "Dummy"):
            if actor and not actor.is_hidden():
                actor.set_actor_scale3d(unreal.Vector(1.0, 1.0, 1.0))

    @unreal.ufunction(ret=None)
    def _respawn_hidden_dummies(self):
        for actor in unreal.GameplayStatics.get_all_actors_with_tag(self, "Dummy"):
            if not actor:
                continue
            actor.set_actor_hidden_in_game(False)
            actor.set_actor_enable_collision(True)
            actor.set_actor_scale3d(unreal.Vector(1.0, 1.0, 1.0))
            if hasattr(self, "_hp"):
                self._hp[actor.get_name()] = DUMMY_HP
            if hasattr(self, "_dummy_ai") and actor.get_name() in self._dummy_ai:
                self._dummy_ai[actor.get_name()] = {
                    "state": "idle",
                    "t": 0.0,
                    "cd": 1.0,
                }
        _log("dummies reviveram")


# ---------------------------------------------------------------------------
# Editor setup
# ---------------------------------------------------------------------------


def ensure_folders() -> None:
    for path in (
        "/Game/Amandaconda",
        "/Game/Amandaconda/Player",
        "/Game/Amandaconda/Combat",
        "/Game/Amandaconda/Maps",
    ):
        _ensure_dir(path)
    _log("pastas ok")


def ensure_input_action():
    if unreal.EditorAssetLibrary.does_asset_exist(IA_ATTACK_PATH):
        return unreal.EditorAssetLibrary.load_asset(IA_ATTACK_PATH)

    action = None
    try:
        factory = unreal.InputAction_Factory()
        asset_tools = unreal.AssetToolsHelpers.get_asset_tools()
        action = asset_tools.create_asset(
            "IA_Attack", "/Game/Input/Actions", None, factory
        )
        if action:
            action.set_editor_property(
                "value_type", unreal.InputActionValueType.BOOLEAN
            )
            unreal.EditorAssetLibrary.save_loaded_asset(action)
            _log("IA_Attack criado (InputAction_Factory)")
            return action
    except Exception as exc:
        _log(f"InputAction_Factory falhou ({exc}) — duplicando IA_Jump")

    src = "/Game/Input/Actions/IA_Jump"
    if not unreal.EditorAssetLibrary.does_asset_exist(src):
        _log("ERRO: IA_Jump não encontrado pra duplicar")
        return None
    action = unreal.EditorAssetLibrary.duplicate_asset(src, IA_ATTACK_PATH)
    if not action:
        _log("ERRO: não duplicou IA_Attack")
        return None
    unreal.EditorAssetLibrary.save_asset(IA_ATTACK_PATH)
    _log("IA_Attack criado (cópia de IA_Jump)")
    return unreal.EditorAssetLibrary.load_asset(IA_ATTACK_PATH)


def ensure_imc_mapping(action) -> None:
    imc = unreal.EditorAssetLibrary.load_asset(IMC_PATH)
    if not imc or not action:
        _log("IMC/action ausente — skip mapping")
        return

    try:
        mappings = unreal.Array(unreal.EnhancedActionKeyMapping)
        for existing in imc.mappings:
            mappings.append(existing)
            if existing.action == action:
                _log("IA_Attack já está no IMC_Default")
                return
        for key_name in ("LeftMouseButton", "Gamepad_FaceButton_Left"):
            mapping = unreal.EnhancedActionKeyMapping()
            mapping.set_editor_property("action", action)
            mapping.set_editor_property("key", unreal.Key(key_name))
            mappings.append(mapping)
        # API UE5.8: map_key se existir
        if hasattr(imc, "map_key"):
            for key_name in ("LeftMouseButton", "Gamepad_FaceButton_Left"):
                imc.map_key(action, unreal.Key(key_name))
            unreal.EditorAssetLibrary.save_loaded_asset(imc)
            _log("IA_Attack mapeado via map_key")
            return
        imc.mappings = mappings
        unreal.EditorAssetLibrary.save_loaded_asset(imc)
        _log("IA_Attack mapeado no IMC_Default (LMB + FaceLeft)")
    except Exception as exc:
        _log(f"IMC mapping skip ({exc}) — ataque usa LMB direto no Bootstrap")


def ensure_attack_montage():
    if unreal.EditorAssetLibrary.does_asset_exist(MONTAGE_PATH):
        return unreal.EditorAssetLibrary.load_asset(MONTAGE_PATH)

    seq = unreal.EditorAssetLibrary.load_asset(ATTACK_SEQ)
    if not seq:
        _log(f"ERRO: animação não encontrada {ATTACK_SEQ}")
        return None

    montage = None
    try:
        factory = unreal.AnimMontageFactory()
        factory.set_editor_property("source_animation", seq)
        skel = None
        if hasattr(seq, "get_skeleton"):
            skel = seq.get_skeleton()
        elif hasattr(seq, "skeleton"):
            skel = seq.get_editor_property("skeleton")
        if skel:
            factory.set_editor_property("target_skeleton", skel)
        asset_tools = unreal.AssetToolsHelpers.get_asset_tools()
        montage = asset_tools.create_asset(
            "AM_Attack_01", "/Game/Amandaconda/Combat", None, factory
        )
    except Exception as exc:
        _log(f"AnimMontageFactory falhou ({exc})")

    if not montage:
        # Fallback: asset vazio + referência da sequência no combate via dynamic montage
        _log("AM_Attack_01 opcional — combate usa dynamic montage de MM_Attack_01")
        return None

    try:
        length = seq.get_editor_property("sequence_length")
        trigger = float(length) * 0.35 if length else 0.25
        notify_obj = AN_HitWindow()
        notifies = list(montage.get_editor_property("notifies") or [])
        evt = unreal.AnimNotifyEvent()
        evt.set_editor_property("trigger_time_offset", trigger)
        evt.set_editor_property("notify", notify_obj)
        evt.set_editor_property("notify_name", "HitWindow")
        notifies.append(evt)
        montage.set_editor_property("notifies", notifies)
        _log(f"notify HitWindow @ {trigger:.2f}s")
    except Exception as exc:
        _log(f"notify opcional falhou ({exc}) — usando timer HIT_DELAY")

    unreal.EditorAssetLibrary.save_loaded_asset(montage)
    _log("AM_Attack_01 criado")
    return montage


def _spawn_unique(actor_class, location: unreal.Vector, label: str):
    world_actors = unreal.EditorLevelLibrary.get_all_level_actors()
    for a in world_actors:
        if a and a.get_actor_label() == label:
            _log(f"já existe {label}")
            return a
    actor = unreal.EditorLevelLibrary.spawn_actor_from_class(actor_class, location)
    if actor:
        actor.set_actor_label(label)
        actor.set_folder_path("Amandaconda")
        try:
            actor.set_actor_location(location, False, False)
        except Exception:
            pass
    return actor


def _mark_transient(actor) -> None:
    """Python uclass não pode ir pro .uasset do mapa.

    NÃO marcar b_is_editor_preview_actor — isso impede o actor de ir pro PIE.
    """
    if not actor:
        return
    try:
        actor.set_flags(unreal.ObjectFlags.RF_TRANSIENT)
    except Exception:
        pass
    try:
        actor.set_actor_tick_enabled(True)
    except Exception:
        pass


def destroy_unsavable_python_actors() -> int:
    """Remove ACombatBootstrap / ADummyTarget do nível antes de salvar."""
    removed = 0
    for actor in list(unreal.EditorLevelLibrary.get_all_level_actors()):
        if not actor:
            continue
        label = actor.get_actor_label() or ""
        is_py = isinstance(actor, (ACombatBootstrap, ADummyTarget))
        if is_py or label == "CombatBootstrap" or label.startswith("ACombatBootstrap"):
            try:
                actor.destroy_actor()
                removed += 1
            except Exception:
                try:
                    unreal.EditorLevelLibrary.destroy_actor(actor)
                    removed += 1
                except Exception:
                    pass
    if removed:
        _log(f"removidos {removed} actors Python (unsavable)")
    return removed


def _paint_dummy_orange(actor) -> None:
    """Cor bem visível no dummy (laranja)."""
    try:
        mesh = actor.static_mesh_component
        if not mesh:
            return
        mat = unreal.EditorAssetLibrary.load_asset(
            "/Engine/BasicShapes/BasicShapeMaterial"
        )
        if mat:
            mesh.set_material(0, mat)
        # escala alta + movimento pra cima do chão
        mesh.set_relative_scale3d(unreal.Vector(0.9, 0.9, 2.0))
    except Exception as exc:
        _log(f"paint dummy: {exc}")


def place_persistent_dummies(save: bool = True) -> None:
    """Só StaticMeshActor — estes podem salvar no mapa. Perto do spawn do jogador."""
    if not unreal.EditorAssetLibrary.does_asset_exist(LEVEL_PATH):
        _log(f"nível não encontrado: {LEVEL_PATH}")
        return

    # Nunca deixe Bootstrap no pacote do nível.
    destroy_unsavable_python_actors()

    # Remove dummies antigos (longe / sem mesh) e recria na frente do spawn.
    for actor in list(unreal.EditorLevelLibrary.get_all_level_actors()):
        if not actor:
            continue
        label = actor.get_actor_label() or ""
        if label in ("Dummy_01", "Dummy_02") or actor.actor_has_tag("Dummy"):
            try:
                actor.destroy_actor()
            except Exception:
                try:
                    unreal.EditorLevelLibrary.destroy_actor(actor)
                except Exception:
                    pass

    cube = unreal.EditorAssetLibrary.load_asset("/Engine/BasicShapes/Cube")
    # Na frente do mannequin do template Third Person (plataforma verde).
    d1 = _spawn_unique(
        unreal.StaticMeshActor, unreal.Vector(0.0, 350.0, 100.0), "Dummy_01"
    )
    d2 = _spawn_unique(
        unreal.StaticMeshActor, unreal.Vector(120.0, 350.0, 100.0), "Dummy_02"
    )
    for actor in (d1, d2):
        if not actor:
            continue
        if not actor.actor_has_tag("Dummy"):
            actor.tags.append("Dummy")
        mesh = actor.static_mesh_component
        if cube and mesh:
            mesh.set_static_mesh(cube)
            mesh.set_collision_profile_name("BlockAllDynamic")
            mesh.set_visibility(True, True)
            mesh.set_hidden_in_game(False)
        actor.set_actor_hidden_in_game(False)
        actor.set_actor_enable_collision(True)
        _paint_dummy_orange(actor)
        try:
            actor.set_actor_location(
                actor.get_actor_location(), False, False
            )
        except Exception:
            pass

    if save:
        unreal.EditorLevelLibrary.save_current_level()
        try:
            unreal.EditorLoadingAndSavingUtils.save_dirty_packages(True, True)
        except Exception:
            pass
    _log(f"dummies na frente do spawn: {bool(d1 and d2)}")


def spawn_combat_bootstrap() -> None:
    """Bootstrap só em memória (RF_TRANSIENT) — nunca salvar o mapa com ele."""
    for actor in unreal.EditorLevelLibrary.get_all_level_actors():
        if actor and (
            isinstance(actor, ACombatBootstrap)
            or actor.get_actor_label() == "CombatBootstrap"
        ):
            _mark_transient(actor)
            _log("CombatBootstrap já na sessão")
            return
    boot = unreal.EditorLevelLibrary.spawn_actor_from_class(
        ACombatBootstrap, unreal.Vector(0.0, 0.0, 80.0)
    )
    if boot:
        boot.set_actor_label("CombatBootstrap")
        boot.set_folder_path("Amandaconda")
        _mark_transient(boot)
        _log("CombatBootstrap spawn (transient)")


def place_level_actors() -> None:
    """Compat: dummies no mapa + bootstrap só na sessão."""
    place_persistent_dummies(save=True)
    spawn_combat_bootstrap()


def ensure_session_combat() -> None:
    """Garante dummies + bootstrap na sessão (sem salvar bootstrap)."""
    try:
        world = unreal.EditorLevelLibrary.get_editor_world()
        if not world:
            return
    except Exception:
        return
    place_persistent_dummies(save=False)
    spawn_combat_bootstrap()


def fix_unsavable_save_warning() -> None:
    """Roda no Output Log se aparecer o aviso de ACombatBootstrap transient."""
    destroy_unsavable_python_actors()
    place_persistent_dummies(save=True)
    spawn_combat_bootstrap()
    _log("mapa limpo — pode salvar sem o aviso")


def duplicate_character_to_game_folder() -> None:
    dest = "/Game/Amandaconda/Player/BP_Player"
    if unreal.EditorAssetLibrary.does_asset_exist(dest):
        _log("BP_Player já existe")
        return
    if unreal.EditorAssetLibrary.does_asset_exist(CHAR_BP):
        unreal.EditorAssetLibrary.duplicate_asset(CHAR_BP, dest)
        _log("BP_Player duplicado (cópia do ThirdPerson)")


def wait_for_project_assets(timeout_sec: float = 120.0) -> bool:
    """ExecutePythonScript pode rodar antes do Asset Registry indexar o /Game."""
    registry = unreal.AssetRegistryHelpers.get_asset_registry()
    try:
        registry.search_all_assets(True)
    except Exception:
        pass
    try:
        if hasattr(registry, "wait_for_completion"):
            registry.wait_for_completion()
    except Exception:
        pass

    import time

    deadline = time.time() + timeout_sec
    while time.time() < deadline:
        if unreal.EditorAssetLibrary.does_asset_exist(LEVEL_PATH) and (
            unreal.EditorAssetLibrary.does_asset_exist(ATTACK_SEQ)
            or unreal.EditorAssetLibrary.does_asset_exist(IMC_PATH)
        ):
            _log("Asset Registry pronto")
            return True
        try:
            registry.search_all_assets(True)
        except Exception:
            pass
        time.sleep(0.5)
    _log("AVISO: timeout esperando assets do projeto")
    return unreal.EditorAssetLibrary.does_asset_exist(LEVEL_PATH)


def load_game_level() -> None:
    if not unreal.EditorAssetLibrary.does_asset_exist(LEVEL_PATH):
        _log(f"nível não encontrado: {LEVEL_PATH}")
        return
    try:
        world = unreal.EditorLevelLibrary.get_editor_world()
        if world and "Lvl_ThirdPerson" in str(world.get_path_name()):
            _log("nível já carregado")
            return
    except Exception:
        pass
    try:
        unreal.EditorLoadingAndSavingUtils.load_map(LEVEL_PATH)
        _log("nível carregado")
    except Exception:
        try:
            unreal.EditorLevelLibrary.load_level(LEVEL_PATH)
            _log("nível carregado (EditorLevelLibrary)")
        except Exception as exc:
            _log(f"load level falhou: {exc}")


def setup_marco1() -> None:
    """Setup compartilhado Marco 1/2 (assets + dummies + bootstrap)."""
    _log("=== setup Marco 2 início ===")
    wait_for_project_assets()
    ensure_folders()
    load_game_level()
    try:
        action = ensure_input_action()
        ensure_imc_mapping(action)
    except Exception as exc:
        _log(f"input falhou: {exc}")
    try:
        ensure_attack_montage()
    except Exception as exc:
        _log(f"montage falhou: {exc}")
    try:
        duplicate_character_to_game_folder()
    except Exception as exc:
        _log(f"BP_Player falhou: {exc}")
    try:
        place_persistent_dummies(save=True)
    except Exception as exc:
        _log(f"place actors falhou: {exc}")
    try:
        # Bootstrap fora do save — só depois do nível gravado.
        destroy_unsavable_python_actors()
        unreal.EditorAssetLibrary.save_directory("/Game/Amandaconda", True, True)
        unreal.EditorAssetLibrary.save_directory("/Game/Input", True, True)
        unreal.EditorLevelLibrary.save_current_level()
    except Exception as exc:
        _log(f"save falhou: {exc}")
    spawn_combat_bootstrap()
    _log(
        "=== setup Marco 2 OK — Play: LMB ataque | Ctrl/C/B roll | "
        "vigor + dummy rebate ==="
    )


def setup_marco2() -> None:
    setup_marco1()


def verify_marco1() -> bool:
    ok = True
    for path in (
        "/Game/Amandaconda/Combat",
        IA_ATTACK_PATH,
    ):
        exists = unreal.EditorAssetLibrary.does_directory_exist(
            path
        ) or unreal.EditorAssetLibrary.does_asset_exist(path)
        _log(f"check {path}: {exists}")
        ok = ok and exists
    # Montage é opcional — dynamic montage cobre o fallback.
    montage_ok = unreal.EditorAssetLibrary.does_asset_exist(MONTAGE_PATH)
    _log(f"check montage (opcional): {montage_ok}")
    seq_ok = unreal.EditorAssetLibrary.does_asset_exist(ATTACK_SEQ)
    _log(f"check attack seq: {seq_ok}")
    ok = ok and seq_ok
    labels = {a.get_actor_label() for a in unreal.EditorLevelLibrary.get_all_level_actors()}
    for need in ("Dummy_01", "Dummy_02"):
        present = need in labels
        _log(f"check actor {need}: {present}")
        ok = ok and present
    spawn_combat_bootstrap()
    return ok


# Execução direta (ExecutePythonScript)
if __name__ == "__main__":
    setup_marco1()
    verify_marco1()
