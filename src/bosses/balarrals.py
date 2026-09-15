"""Balarrals — espelho do jogador (moveset simples, sprite prata)."""

from __future__ import annotations

import pygame

from .. import combat, config, sprites, visual
from ..balance import Balance

LIVRE = "livre"
ATACANDO = "atacando"
ATINGIDO = "atingido"
MORTO = "morto"


class Balarrals:
    def __init__(self, balance: Balance, x: float, y: float) -> None:
        self.balance = balance
        self.cfg = balance["chefes"]["balarrals"]
        w, h = 18, 40
        self.rect = pygame.FRect(0, 0, w, h)
        self.rect.midbottom = (x, y)
        self.vida = float(self.cfg["vida"])
        self.vida_max = self.vida
        self.facing = -1
        self.estado = LIVRE
        self.fases: combat.Fases | None = None
        self.golpe = "leve"
        self.ja_acertou = False
        self.invencivel = 0.0
        self.travado = 0.0
        self.cd = 0.4
        self.vel = pygame.Vector2(0, 0)
        self.anim = sprites.Animator("balarrals")
        self.tempo = 0.0
        self.cor = tuple(self.cfg["cor"])

    @property
    def vivo(self) -> bool:
        return self.vida > 0.0

    def update(self, dt: float, alvo_x: float, level) -> None:
        if not self.vivo:
            self.estado = MORTO
            self.anim.play("parado")
            return

        self.tempo += dt
        self.invencivel = max(0.0, self.invencivel - dt)
        self.cd = max(0.0, self.cd - dt)
        self.facing = 1 if alvo_x >= self.rect.centerx else -1

        if self.estado == ATINGIDO:
            self.travado = max(0.0, self.travado - dt)
            self.vel.x *= max(0.0, 1.0 - 8.0 * dt)
            if self.travado <= 0.0:
                self.estado = LIVRE
        elif self.estado == ATACANDO:
            self._atualizar_ataque(dt)
        else:
            self._atualizar_livre(dt, alvo_x)

        # Gravidade + chao simples.
        p = self.balance["player"]
        self.vel.y = min(self.vel.y + p["gravity"] * dt, p["max_fall_speed"])
        self.rect.x += self.vel.x * dt
        self._empurrar_x(level)
        self.rect.y += self.vel.y * dt
        self._empurrar_y(level)

        self.anim.play("parado")
        self.anim.update(dt)

    def _atualizar_livre(self, dt: float, alvo_x: float) -> None:
        dist = alvo_x - self.rect.centerx
        vel = float(self.cfg["velocidade"])
        if abs(dist) > self.cfg["alcance_leve"] * 0.85:
            self.vel.x = vel if dist > 0 else -vel
        else:
            self.vel.x = 0.0
            if self.cd <= 0.0:
                self._iniciar_ataque("pesado" if abs(dist) < 20 and self.tempo % 3 > 2 else "leve")

    def _iniciar_ataque(self, golpe: str) -> None:
        self.estado = ATACANDO
        self.golpe = golpe
        self.ja_acertou = False
        if golpe == "pesado":
            self.fases = combat.Fases(
                self.cfg["preparacao_pesado"],
                self.cfg["acerto_pesado"],
                self.cfg["recuperacao_pesado"],
            )
        else:
            self.fases = combat.Fases(
                self.cfg["preparacao_leve"],
                self.cfg["acerto_leve"],
                self.cfg["recuperacao_leve"],
            )
        self.vel.x = self.facing * 40

    def _atualizar_ataque(self, dt: float) -> None:
        if self.fases is None:
            self.estado = LIVRE
            return
        self.fases.avancar(dt)
        self.vel.x *= max(0.0, 1.0 - 6.0 * dt)
        if self.fases.acabou:
            self.estado = LIVRE
            self.fases = None
            self.cd = float(self.cfg["intervalo_decisao"])

    def caixa_de_acerto(self) -> pygame.FRect | None:
        if self.estado != ATACANDO or self.fases is None:
            return None
        if self.fases.fase != combat.Fases.ACERTO:
            return None
        alc = self.cfg["alcance_pesado"] if self.golpe == "pesado" else self.cfg["alcance_leve"]
        h = 24
        x = self.rect.centerx if self.facing >= 0 else self.rect.centerx - alc
        return pygame.FRect(x, self.rect.centery - h / 2, alc, h)

    def levar_dano(self, quanto: float, de_onde_x: float) -> bool:
        if self.invencivel > 0.0 or not self.vivo:
            return False
        self.vida = max(0.0, self.vida - quanto)
        self.invencivel = 0.35
        if self.vida <= 0.0:
            self.estado = MORTO
            return True
        self.estado = ATINGIDO
        self.fases = None
        self.travado = 0.25
        self.vel.x = (-1 if de_onde_x > self.rect.centerx else 1) * 120
        return True

    def dano_atual(self) -> float:
        return float(self.cfg["dano_pesado"] if self.golpe == "pesado" else self.cfg["dano_leve"])

    def draw(self, surface: pygame.Surface, cam_x: float, cam_y: float) -> None:
        img = self.anim.image(self.facing)
        r = pygame.Rect(
            round(self.rect.x - cam_x),
            round(self.rect.y - cam_y),
            round(self.rect.width),
            round(self.rect.height),
        )
        if img is not None:
            dest = img.get_rect(midbottom=r.midbottom)
            surface.blit(img, dest)
        else:
            visual.jogador(
                surface,
                r,
                self.facing,
                self.cor,
                "teclado",
                self.estado,
                self.fases.fase if self.fases else None,
                abs(self.vel.x) > 20,
                self.tempo,
            )
        # Telegrafia: borda na preparacao.
        if (
            self.estado == ATACANDO
            and self.fases
            and self.fases.fase == combat.Fases.PREPARACAO
        ):
            pygame.draw.rect(surface, config.COLOR_PREPARACAO, r.inflate(4, 4), 1)

    def _empurrar_x(self, level) -> None:
        for solid in level.solids:
            if self.rect.colliderect(solid):
                if self.vel.x > 0:
                    self.rect.right = solid.left
                elif self.vel.x < 0:
                    self.rect.left = solid.right
                self.vel.x = 0.0

    def _empurrar_y(self, level) -> None:
        for solid in level.solids:
            if self.rect.colliderect(solid):
                if self.vel.y > 0:
                    self.rect.bottom = solid.top
                elif self.vel.y < 0:
                    self.rect.top = solid.bottom
                self.vel.y = 0.0
