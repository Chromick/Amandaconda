"""Projeteis do jogador — hoje so a bola de virus.

O golpe a distancia nao usa caixa colada no corpo: ele nasce no acerto do
ataque e vive sozinho ate bater, expirar ou quicar demais.
"""

from __future__ import annotations

import pygame

from . import config


class VirusBall:
    def __init__(
        self,
        x: float,
        y: float,
        facing: int,
        dano: float,
        cfg: dict,
    ) -> None:
        self.raio = float(cfg["raio"])
        self.rect = pygame.FRect(0, 0, self.raio * 2, self.raio * 2)
        self.rect.center = (x, y)
        self.vel = pygame.Vector2(facing * cfg["velocidade"], -40.0)
        self.gravidade = float(cfg["gravidade"])
        self.quique = float(cfg["quique"])
        self.vida = float(cfg["tempo_de_vida"])
        self.dano = dano
        self.vivo = True
        self.ja_acertou: set[int] = set()

    def update(self, dt: float, level) -> None:
        if not self.vivo:
            return
        self.vida -= dt
        if self.vida <= 0.0:
            self.vivo = False
            return

        self.vel.y += self.gravidade * dt
        self.rect.x += self.vel.x * dt
        self._bater_solidos(level, horizontal=True)
        self.rect.y += self.vel.y * dt
        self._bater_solidos(level, horizontal=False)

    def _bater_solidos(self, level, horizontal: bool) -> None:
        for solid in level.solids:
            if not self.rect.colliderect(solid):
                continue
            if horizontal:
                if self.vel.x > 0:
                    self.rect.right = solid.left
                else:
                    self.rect.left = solid.right
                self.vel.x *= -self.quique
            else:
                if self.vel.y > 0:
                    self.rect.bottom = solid.top
                else:
                    self.rect.top = solid.bottom
                self.vel.y *= -self.quique
                # Quique fraco demais: morre no chao em vez de tremer pra sempre.
                if abs(self.vel.y) < 30:
                    self.vivo = False

    def draw(self, surface: pygame.Surface, cam_x: float, cam_y: float) -> None:
        if not self.vivo:
            return
        centro = (
            round(self.rect.centerx - cam_x),
            round(self.rect.centery - cam_y),
        )
        raio = round(self.raio)
        # Brilho externo barato: dois aneis pra ler como "coisa viva".
        pygame.draw.circle(surface, config.COLOR_VIRUS_CORE, centro, raio + 2, 1)
        pygame.draw.circle(surface, config.COLOR_VIRUS, centro, raio)
        pygame.draw.circle(surface, config.COLOR_VIRUS_CORE, centro, max(2, round(raio * 0.45)))
        pygame.draw.circle(surface, config.COLOR_UI_TEXT, (centro[0] - 1, centro[1] - 1), 1)
