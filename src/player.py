"""Jogador: movimento, pulo e combate.

A regra que organiza tudo: **um estado por vez.** Atacando nao se rola,
rolando nao se ataca, apanhando nao se faz nada. Num soulslike o compromisso
com a acao escolhida e o que torna o combate justo — se desse para cancelar
qualquer coisa a qualquer momento, nao existiria risco em atacar, e sem risco
nao existe o genero.

O que suaviza esse compromisso e o buffer: o input apertado durante a
recuperacao nao e jogado fora, e executado assim que der. Sem ele o jogo
parece que ignora comando; com ele, parece que entende a intencao.
"""

from __future__ import annotations

import pygame

from . import combat, config, sprites, visual
from .balance import Balance
from .input import Input
from .level import Level
from .projectiles import VirusBall
from .util import approach, clamp

TECLADO = "teclado"
VIRUS = "virus"

LIVRE = "livre"
ATACANDO = "atacando"
ROLANDO = "rolando"
ATINGIDO = "atingido"
MORTO = "morto"


class Player:
    def __init__(self, balance: Balance, x: float, y: float) -> None:
        self.balance = balance
        p = balance["player"]

        self.rect = pygame.FRect(x, y, p["width"], p["height"])
        self.rect.midbottom = (x, y)
        self.vel = pygame.Vector2(0.0, 0.0)

        self.on_ground = False
        self.facing = 1
        self.coyote = 0.0
        self.jump_buffer = 0.0
        self.stamina = float(p["max_stamina"])
        self.stamina_idle = 0.0
        self.vida_base = float(p["max_health"])
        self.health = self.vida_base

        # Escola vem da tela de loadout. Sem escola = desarmado (nao ataca).
        inicial = p.get("arma_inicial")
        self.arma = inicial if inicial in (TECLADO, VIRUS) else TECLADO
        self.escola_escolhida = inicial in (TECLADO, VIRUS)
        self.nivel_fisico = 0
        self.nivel_especial = 0
        self.bytes = 0  # recurso da playthrough; HUD em KB
        self._patch_dano = 0.0
        self._vigor_bonus = 0

        self.estado = LIVRE
        self.fases: combat.Fases | None = None
        self.golpe = "ataque_leve"
        self.combo = 0
        self.encadear = False
        self.carga = 0.0
        self.ja_acertou: set[int] = set()
        self.ja_disparou = False
        self.invencivel = 0.0
        self.travado = 0.0
        self.buffer: dict[str, float] = {}
        self.projecteis_novos: list[VirusBall] = []
        self.tempo_visual = 0.0

        self.anim = sprites.Animator("player")

    @property
    def max_health(self) -> float:
        pd = self.balance["pendrives"]
        return (
            self.vida_base
            + self.nivel_fisico * pd["fisico"]["vida_por_nivel"]
            + self.nivel_especial * pd["especial"]["vida_por_nivel"]
        )

    @property
    def multiplicador_dano(self) -> float:
        """So a escola da arma ativa escala o dano — off-color nao ajuda a matar."""
        pd = self.balance["pendrives"]
        if self.arma == TECLADO:
            taxa = pd["fisico"]["dano_por_nivel"]
            nivel = self.nivel_fisico
        else:
            taxa = pd["especial"]["dano_por_nivel"]
            nivel = self.nivel_especial
        return (1.0 + taxa) ** nivel * (1.0 + self._patch_dano)

    def escolher_escola(self, escola: str) -> None:
        if escola not in (TECLADO, VIRUS):
            return
        self.arma = escola
        self.escola_escolhida = True

    def golpe_cfg(self, golpe: str | None = None) -> dict:
        nome = golpe or self.golpe
        return self.balance["player"]["armas"][self.arma][nome]

    # --- consultas que a cena faz ---

    @property
    def vivo(self) -> bool:
        return self.estado != MORTO

    @property
    def atacando_agora(self) -> bool:
        return (
            self.estado == ATACANDO
            and self.fases is not None
            and self.fases.fase == combat.Fases.ACERTO
        )

    def caixa_de_acerto(self) -> pygame.FRect | None:
        # Virus machuca pelo projetil, nao por caixa no corpo.
        if self.arma != TECLADO or not self.atacando_agora:
            return None
        g = self.golpe_cfg()
        return combat.caixa_a_frente(self.rect, self.facing, g["alcance"], g["altura"])

    def dano_atual(self) -> float:
        g = self.golpe_cfg()
        if self.golpe == "ataque_pesado" and self.carga >= g.get("carga_maxima", 0):
            base = g["dano_carregado"]
        else:
            base = g["dano"]
        return base * self.multiplicador_dano

    def registrar_acerto(self, alvo_id: int) -> bool:
        """Um golpe machuca cada alvo uma vez so, por mais que a caixa encoste."""
        if alvo_id in self.ja_acertou:
            return False
        self.ja_acertou.add(alvo_id)
        return True

    # --- laco ---

    def update(self, dt: float, inp: Input, level: Level) -> None:
        p = self.balance["player"]
        self._sync_size(p)
        self.projecteis_novos.clear()

        self.invencivel = max(0.0, self.invencivel - dt)
        self._guardar_intencao(dt, inp, p)

        if self.estado == MORTO:
            self._frear(dt, p["ground_friction"])
        elif self.estado == ATINGIDO:
            self._atualizar_atingido(dt, p)
        elif self.estado == ROLANDO:
            self._atualizar_rolamento(dt, p)
        elif self.estado == ATACANDO:
            self._atualizar_ataque(dt, inp, p)
        else:
            self._atualizar_livre(dt, inp, p)

        self.vel.y = min(self.vel.y + p["gravity"] * dt, p["max_fall_speed"])
        self._move_x(self.vel.x * dt, level)
        self._move_y(self.vel.y * dt, level)

        self._update_stamina(dt, p)
        self.tempo_visual += dt
        self._update_animation(dt)

    # --- intencao guardada ---

    def _guardar_intencao(self, dt: float, inp: Input, p: dict) -> None:
        for acao in ("attack", "heavy", "roll", "switch_weapon"):
            if inp.pressed(acao):
                self.buffer[acao] = p["buffer_de_acao"]
            elif acao in self.buffer:
                self.buffer[acao] -= dt
                if self.buffer[acao] <= 0.0:
                    del self.buffer[acao]

    def _consumir(self, acao: str) -> bool:
        if acao in self.buffer:
            del self.buffer[acao]
            return True
        return False

    # --- estados ---

    def _atualizar_livre(self, dt: float, inp: Input, p: dict) -> None:
        self._update_horizontal(dt, inp, p)
        self._update_jump(dt, inp, p)

        # Rolamento so no chao; leve/pesado tambem no ar (pulo).
        if self.on_ground and self._consumir("roll") and self._iniciar_rolamento(p):
            return
        if self._consumir("heavy") and self._iniciar_ataque("ataque_pesado", p):
            return
        if self._consumir("attack") and self._iniciar_ataque("ataque_leve", p):
            return

    def _iniciar_rolamento(self, p: dict) -> bool:
        r = p["rolamento"]
        if not self.spend_stamina(r["vigor"]):
            return False
        self.estado = ROLANDO
        self.fases = combat.Fases(r["duracao"], 0.0, 0.0)
        self.vel.x = self.facing * r["velocidade"]
        return True

    def _atualizar_rolamento(self, dt: float, p: dict) -> None:
        if self.fases is None:  # estado sem fases nao existe: volta em vez de quebrar
            self._voltar_para_livre()
            return

        r = p["rolamento"]
        self.fases.avancar(dt)

        inicio = r["inv_inicio"]
        if inicio <= self.fases.tempo < inicio + r["inv_duracao"]:
            self.invencivel = max(self.invencivel, dt * 2)

        # Freia no fim do rolamento para nao deslizar ate parar sozinho.
        if self.fases.tempo > r["duracao"] * 0.6:
            self._frear(dt, r["atrito_final"])

        if self.fases.acabou:
            self._voltar_para_livre()

    def _iniciar_ataque(self, golpe: str, p: dict) -> bool:
        g = self.golpe_cfg(golpe)
        if not self.spend_stamina(g["vigor"]):
            return False

        self.estado = ATACANDO
        self.golpe = golpe
        self.carga = 0.0
        self.ja_acertou.clear()
        self.ja_disparou = False
        self.encadear = False
        if golpe == "ataque_leve" and self.arma == TECLADO:
            self.combo = self.combo + 1
        else:
            self.combo = 0
        self.fases = combat.Fases(g["preparacao"], g["acerto"], g["recuperacao"])
        self.vel.x = self.facing * g.get("avanco", 0)
        return True

    def _atualizar_ataque(self, dt: float, inp: Input, p: dict) -> None:
        if self.fases is None:
            self._voltar_para_livre()
            return

        g = self.golpe_cfg()

        # Pesado segurado: a preparacao estica ate a carga maxima.
        if (
            self.golpe == "ataque_pesado"
            and self.fases.fase == combat.Fases.PREPARACAO
            and inp.held("heavy")
            and self.carga < g.get("carga_maxima", 0)
        ):
            self.carga += dt
            self._frear(dt, p["atrito_travado"])
            return

        fase_antes = self.fases.fase
        self.fases.avancar(dt)
        self._frear(dt, p["atrito_travado"])

        if (
            self.arma == VIRUS
            and not self.ja_disparou
            and self.fases.fase == combat.Fases.ACERTO
            and fase_antes != combat.Fases.ACERTO
        ):
            self._disparar_virus(g)

        # Encadeamento so no teclado: virus e tiro a tiro.
        if (
            self.arma == TECLADO
            and self.golpe == "ataque_leve"
            and self.fases.fase in (combat.Fases.ACERTO, combat.Fases.RECUPERACAO)
        ):
            if self._consumir("attack") and self.combo < g["golpes_no_combo"]:
                self.encadear = True

        if not self.fases.acabou:
            return

        if self.encadear and self._iniciar_ataque("ataque_leve", p):
            return
        if self.on_ground and self._consumir("roll") and self._iniciar_rolamento(p):
            return
        self.combo = 0
        self._voltar_para_livre()

    def _disparar_virus(self, g: dict) -> None:
        self.ja_disparou = True
        origem_x = self.rect.centerx + self.facing * 12
        origem_y = self.rect.centery - 4
        self.projecteis_novos.append(
            VirusBall(origem_x, origem_y, self.facing, self.dano_atual(), g)
        )

    def aplicar_pendrive(self, escola: str) -> None:
        """escola: 'fisico' | 'especial' — o fork do pergaminho dual."""
        antes = self.max_health
        if escola == "fisico":
            self.nivel_fisico += 1
        elif escola == "especial":
            self.nivel_especial += 1
        else:
            return
        ganho = self.max_health - antes
        self.health = min(self.max_health, self.health + max(0.0, ganho))

    def curar_completo(self) -> None:
        self.health = self.max_health
        p = self.balance["player"]
        self.stamina = self._stamina_max(p)

    def ganhar_bytes(self, quantidade: int) -> None:
        self.bytes = max(0, self.bytes + max(0, int(quantidade)))

    def formatar_bytes(self) -> str:
        """Ex.: 48 KB · 1.5 MB"""
        n = self.bytes
        if n >= 1024:
            return f"{n / 1024:.1f} MB"
        return f"{n} KB"

    def _atualizar_atingido(self, dt: float, p: dict) -> None:
        self.travado = max(0.0, self.travado - dt)
        self._frear(dt, p["ground_friction"])
        if self.travado <= 0.0:
            self._voltar_para_livre()

    def _voltar_para_livre(self) -> None:
        self.estado = LIVRE
        self.fases = None
        self.encadear = False
        self.carga = 0.0

    # --- dano ---

    def levar_dano(self, quanto: float, de_onde_x: float) -> bool:
        if self.invencivel > 0.0 or self.estado == MORTO:
            return False

        d = self.balance["player"]["dano_recebido"]
        self.health = max(0.0, self.health - quanto)
        self.invencivel = d["invencibilidade"]
        self.combo = 0

        if self.health <= 0.0:
            self.estado = MORTO
            self.fases = None
            return True

        self.estado = ATINGIDO
        self.fases = None
        self.travado = d["travado"]
        recuo = -1 if de_onde_x > self.rect.centerx else 1
        self.vel.x = recuo * d["empurrao"]
        return True

    def reviver(self, x: float, y: float) -> None:
        p = self.balance["player"]
        self.rect.midbottom = (x, y)
        self.vel.update(0.0, 0.0)
        # Pendrives ja aplicados ficam: so a vida volta cheia no novo teto.
        self.health = self.max_health
        self.stamina = float(p["max_stamina"])
        self.invencivel = 0.0
        self.travado = 0.0
        self.combo = 0
        self.buffer.clear()
        self.projecteis_novos.clear()
        self._voltar_para_livre()

    # --- fisica ---

    def _frear(self, dt: float, atrito: float) -> None:
        self.vel.x = approach(self.vel.x, 0.0, atrito * dt)

    def _sync_size(self, p: dict) -> None:
        """Permite ajustar o tamanho do jogador com o jogo rodando (F5)."""
        if self.rect.width == p["width"] and self.rect.height == p["height"]:
            return
        bottom, centerx = self.rect.bottom, self.rect.centerx
        self.rect.width = p["width"]
        self.rect.height = p["height"]
        self.rect.bottom = bottom
        self.rect.centerx = centerx

    def _update_horizontal(self, dt: float, inp: Input, p: dict) -> None:
        direction = inp.axis_x()
        speed = p["run_speed"] if inp.held("run") else p["walk_speed"]

        if direction != 0:
            self.facing = direction
            accel = p["ground_accel"] if self.on_ground else p["air_accel"]
            self.vel.x = approach(self.vel.x, direction * speed, accel * dt)
        else:
            friction = p["ground_friction"] if self.on_ground else p["air_friction"]
            self.vel.x = approach(self.vel.x, 0.0, friction * dt)

    def _update_jump(self, dt: float, inp: Input, p: dict) -> None:
        # Coyote time: aceita o pulo por um instante depois de sair da borda.
        # Buffer: aceita o pulo apertado um instante antes de tocar o chao.
        # Sem esses dois, o pulo parece que "nao registrou" e a culpa cai no jogo.
        self.coyote = p["coyote_time"] if self.on_ground else max(0.0, self.coyote - dt)

        if inp.pressed("jump"):
            self.jump_buffer = p["jump_buffer"]
        else:
            self.jump_buffer = max(0.0, self.jump_buffer - dt)

        if self.jump_buffer > 0.0 and self.coyote > 0.0:
            self.vel.y = -p["jump_velocity"]
            self.jump_buffer = 0.0
            self.coyote = 0.0
            self.on_ground = False

        # Altura variavel: soltar cedo corta a subida.
        if inp.released("jump") and self.vel.y < 0.0:
            self.vel.y *= p["jump_cut_multiplier"]

    def _stamina_max(self, p: dict) -> float:
        return float(p["max_stamina"]) + self._vigor_bonus

    def _update_stamina(self, dt: float, p: dict) -> None:
        self.stamina_idle += dt
        if self.stamina_idle >= p["stamina_regen_delay"]:
            self.stamina = clamp(
                self.stamina + p["stamina_regen"] * dt, 0.0, self._stamina_max(p)
            )

    def spend_stamina(self, amount: float) -> bool:
        if self.stamina < amount:
            return False
        self.stamina -= amount
        self.stamina_idle = 0.0
        return True

    def _move_x(self, dx: float, level: Level) -> None:
        if dx == 0.0:
            return
        self.rect.x += dx
        for solid in level.solids:
            if not self.rect.colliderect(solid):
                continue
            if dx > 0.0:
                self.rect.right = solid.left
            else:
                self.rect.left = solid.right
            self.vel.x = 0.0

    def _move_y(self, dy: float, level: Level) -> None:
        self.on_ground = False
        self.rect.y += dy
        for solid in level.solids:
            if not self.rect.colliderect(solid):
                continue
            if dy > 0.0:
                self.rect.bottom = solid.top
                self.on_ground = True
            else:
                self.rect.top = solid.bottom
            self.vel.y = 0.0

    # --- desenho ---

    def _update_animation(self, dt: float) -> None:
        if self.estado == MORTO:
            self.anim.play("morte")
            self.anim.update(dt)
            return
        if self.estado == ATINGIDO:
            self.anim.play("dano")
            return
        if self.estado == ROLANDO:
            self.anim.play("rolando")
            self.anim.update(dt)
            return
        if self.estado == ATACANDO:
            # Especial usa o throw; Físico usa o golpe (leve/pesado).
            self.anim.play("lancar" if self.arma == VIRUS else self.golpe)
            self.anim.update(dt)
            return

        if not self.on_ground:
            self.anim.play("no_ar")
            # No ar o quadro vem do movimento, nao do relogio: subindo e caindo
            # sao dois desenhos, e alternar entre eles no tempo ficaria errado.
            self.anim.travar_quadro(0 if self.vel.y < 0.0 else 1)
            return

        andando = abs(self.vel.x) > 5.0
        self.anim.play("andando" if andando else "parado")
        self.anim.update(dt)

    def _cor_atual(self) -> tuple[int, int, int]:
        if self.estado == MORTO:
            return config.COLOR_UI_TEXT_DIM
        if self.estado == ROLANDO and self.invencivel > 0.0:
            return config.COLOR_ACCENT_DEEP
        if self.estado == ATINGIDO:
            return config.COLOR_DANO
        if self.estado == ATACANDO and self.fases:
            if self.fases.fase == combat.Fases.PREPARACAO:
                return config.COLOR_PREPARACAO
            if self.fases.fase == combat.Fases.ACERTO:
                return config.COLOR_ACCENT
        return config.COLOR_PLAYER

    def draw(self, surface: pygame.Surface, cam_x: float, cam_y: float) -> None:
        # Piscar durante a invencibilidade depois do dano, mas nao durante o
        # rolamento: la a invencibilidade e esperada e piscar so polui.
        if self.estado not in (ROLANDO, MORTO) and self.invencivel > 0.0:
            if int(self.invencivel * 20) % 2 == 0:
                return

        image = self.anim.image(self.facing)
        if image is not None:
            # Base do sprite no chao, corpo centrado: a mesma regra de ARTE.md.
            rect = image.get_rect()
            rect.midbottom = (
                round(self.rect.centerx - cam_x),
                round(self.rect.bottom - cam_y),
            )
            surface.blit(image, rect)
            return

        r = pygame.Rect(
            round(self.rect.x - cam_x),
            round(self.rect.y - cam_y),
            round(self.rect.width),
            round(self.rect.height),
        )
        if self.estado == MORTO:
            r.height = max(4, r.height // 4)
            r.bottom = round(self.rect.bottom - cam_y)
            pygame.draw.rect(surface, self._cor_atual(), r)
            return

        fase = self.fases.fase if self.fases else None
        visual.jogador(
            surface,
            r,
            self.facing,
            self._cor_atual(),
            self.arma,
            self.estado,
            fase,
            self.on_ground and abs(self.vel.x) > 5.0,
            self.tempo_visual,
        )
