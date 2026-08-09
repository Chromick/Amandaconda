"""Jogador: movimento, pulo e colisao.

Semana 1 do plano. Combate entra na semana 2.
"""

from __future__ import annotations

import pygame

from . import config, sprites
from .balance import Balance
from .input import Input
from .level import Level
from .util import approach, clamp


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
        self.health = float(p["max_health"])

        self.anim = sprites.Animator("player")

    def update(self, dt: float, inp: Input, level: Level) -> None:
        p = self.balance["player"]
        self._sync_size(p)

        self._update_horizontal(dt, inp, p)
        self._update_jump(dt, inp, p)

        self.vel.y = min(self.vel.y + p["gravity"] * dt, p["max_fall_speed"])

        self._move_x(self.vel.x * dt, level)
        self._move_y(self.vel.y * dt, level)

        self._update_stamina(dt, p)
        self._update_animation(dt)

    def _update_animation(self, dt: float) -> None:
        if not self.on_ground:
            self.anim.play("no_ar")
            # No ar o quadro vem do movimento, nao do relogio: subindo e caindo
            # sao dois desenhos, e alternar entre eles no tempo ficaria errado.
            self.anim.travar_quadro(0 if self.vel.y < 0.0 else 1)
            return

        andando = abs(self.vel.x) > 5.0
        self.anim.play("andando" if andando else "parado")
        self.anim.update(dt)

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

    def _update_stamina(self, dt: float, p: dict) -> None:
        self.stamina_idle += dt
        if self.stamina_idle >= p["stamina_regen_delay"]:
            self.stamina = clamp(
                self.stamina + p["stamina_regen"] * dt, 0.0, p["max_stamina"]
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

    def draw(self, surface: pygame.Surface, cam_x: float, cam_y: float) -> None:
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
        pygame.draw.rect(surface, config.COLOR_PLAYER, r)

        eye_x = r.right - 5 if self.facing > 0 else r.left + 3
        pygame.draw.rect(surface, config.COLOR_BG, (eye_x, r.y + 7, 2, 4))
