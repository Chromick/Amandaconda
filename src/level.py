"""Geometria solida da cena.

Provisorio: uma sala de teste montada na mao. Vira dado carregado de arquivo
quando as arenas de chefe comecarem, na semana 3.
"""

from __future__ import annotations

import pygame

from . import config


class Level:
    def __init__(self, solids: list[pygame.FRect], width: int, height: int) -> None:
        self.solids = solids
        self.width = width
        self.height = height
        self.spawn = pygame.Vector2(80, height - 80)

    def draw(self, surface: pygame.Surface, cam_x: float, cam_y: float) -> None:
        for solid in self.solids:
            r = pygame.Rect(
                round(solid.x - cam_x),
                round(solid.y - cam_y),
                round(solid.width),
                round(solid.height),
            )
            if r.right < 0 or r.left > surface.get_width():
                continue
            pygame.draw.rect(surface, config.COLOR_SOLID, r)
            pygame.draw.rect(surface, config.COLOR_SOLID_TOP, (r.x, r.y, r.width, 2))


def test_room() -> Level:
    width, height = 960, 270
    floor_y = height - 32

    solids = [
        pygame.FRect(0, floor_y, width, 32),
        pygame.FRect(-8, 0, 8, height),
        pygame.FRect(width, 0, 8, height),
        # Alturas casadas com o arco do pulo medido em tools/medir_pulo.py:
        # nenhum degrau passa de ~48 px, que e o pulo cheio com folga.
        pygame.FRect(180, floor_y - 44, 90, 10),
        pygame.FRect(330, floor_y - 86, 90, 10),
        pygame.FRect(520, floor_y - 48, 130, 10),
        pygame.FRect(700, floor_y - 24, 60, 24),
        pygame.FRect(790, floor_y - 72, 120, 10),
    ]
    return Level(solids, width, height)
