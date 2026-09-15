"""Geometria solida da cena.

Provisorio: salas montadas na mao + gerador. Hub/arenas entram aqui.
"""

from __future__ import annotations

import pygame

from . import config


class Level:
    def __init__(
        self,
        solids: list[pygame.FRect],
        width: int,
        height: int,
        *,
        spawn: tuple[float, float] | None = None,
        safezone: pygame.FRect | None = None,
        spawns_inimigo: list[tuple[str, float]] | None = None,
        spawns_pendrive: list[float] | None = None,
        spawn_boneco: float | None = None,
        saida_hub: pygame.FRect | None = None,
    ) -> None:
        self.solids = solids
        self.width = width
        self.height = height
        self.spawn = pygame.Vector2(*(spawn or (80, height - 80)))
        self.safezone = safezone
        self.spawns_inimigo = spawns_inimigo or []
        self.spawns_pendrive = spawns_pendrive or []
        self.spawn_boneco = spawn_boneco
        self.saida_hub = saida_hub

    def chao_em(self, x: float, a_partir_de: float = 0.0) -> float:
        """Topo do primeiro solido abaixo de (x, a_partir_de)."""
        tops = [
            solid.top
            for solid in self.solids
            if solid.left <= x <= solid.right and solid.top >= a_partir_de
        ]
        return min(tops) if tops else float(self.height)

    def na_safezone(self, rect: pygame.FRect) -> bool:
        return self.safezone is not None and rect.colliderect(self.safezone)

    def na_saida_hub(self, rect: pygame.FRect) -> bool:
        return self.saida_hub is not None and rect.colliderect(self.saida_hub)

    def draw(self, surface: pygame.Surface, cam_x: float, cam_y: float) -> None:
        from . import visual

        if self.safezone is not None:
            r = pygame.Rect(
                round(self.safezone.x - cam_x),
                round(self.safezone.y - cam_y),
                round(self.safezone.width),
                round(self.safezone.height),
            )
            # Tint suave — a placa detalhada vem no play.
            veil = pygame.Surface((r.width, r.height), pygame.SRCALPHA)
            veil.fill((*config.COLOR_SAFEZONE, 90))
            surface.blit(veil, r.topleft)

        for solid in self.solids:
            r = pygame.Rect(
                round(solid.x - cam_x),
                round(solid.y - cam_y),
                round(solid.width),
                round(solid.height),
            )
            if r.right < 0 or r.left > surface.get_width():
                continue
            no_safe = self.safezone is not None and solid.colliderect(self.safezone)
            visual.plataforma(surface, r, safe=no_safe)


def test_room() -> Level:
    """Sala curta da semana 2 — mantida pra testes isolados de combate."""
    width, height = 960, 270
    floor_y = height - 32
    solids = [
        pygame.FRect(0, floor_y, width, 32),
        pygame.FRect(-8, 0, 8, height),
        pygame.FRect(width, 0, 8, height),
        pygame.FRect(180, floor_y - 44, 90, 10),
        pygame.FRect(330, floor_y - 86, 90, 10),
        pygame.FRect(520, floor_y - 48, 130, 10),
        pygame.FRect(700, floor_y - 24, 60, 24),
        pygame.FRect(790, floor_y - 72, 120, 10),
    ]
    return Level(solids, width, height)


def risk_room() -> Level:
    """Sala fixa de referencia. O jogo usa gen_mapa.gerar_risco() na PlayScene."""
    width, height = 1680, 270
    floor_y = height - 32
    safe_x = 1320

    solids = [
        pygame.FRect(0, floor_y, width, 32),
        pygame.FRect(-8, 0, 8, height),
        pygame.FRect(width, 0, 8, height),
        pygame.FRect(220, floor_y - 40, 80, 10),
        pygame.FRect(420, floor_y - 72, 90, 10),
        pygame.FRect(620, floor_y - 40, 100, 10),
        pygame.FRect(860, floor_y - 24, 50, 24),
        pygame.FRect(980, floor_y - 64, 110, 10),
        pygame.FRect(1180, floor_y - 40, 80, 10),
    ]

    safezone = pygame.FRect(safe_x, 0, width - safe_x, height)
    saida = pygame.FRect(width - 48, floor_y - 64, 40, 64)

    return Level(
        solids,
        width,
        height,
        spawn=(70, floor_y),
        safezone=safezone,
        spawns_inimigo=[
            ("chatana", 360),
            ("portara", 720),
            ("chatana", 1050),
        ],
        spawns_pendrive=[500, 1100],
        spawn_boneco=1480,
        saida_hub=saida,
    )


def arena_balarrals() -> Level:
    """Patio interno — arena aberta pro duelo espelho."""
    width, height = 720, 270
    floor_y = height - 32
    solids = [
        pygame.FRect(0, floor_y, width, 32),
        pygame.FRect(-8, 0, 8, height),
        pygame.FRect(width, 0, 8, height),
        pygame.FRect(200, floor_y - 48, 80, 10),
        pygame.FRect(440, floor_y - 48, 80, 10),
    ]
    return Level(
        solids,
        width,
        height,
        spawn=(100, floor_y),
    )
