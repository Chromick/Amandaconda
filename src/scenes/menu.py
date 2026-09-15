from __future__ import annotations

import math
from pathlib import Path

import pygame

from .. import config, ui
from ..scene import Scene

BG_PATH = Path(__file__).resolve().parent.parent.parent / "assets" / "ui" / "menu-bg.png"


def load_background() -> pygame.Surface:
    size = (config.INTERNAL_WIDTH, config.INTERNAL_HEIGHT)
    try:
        image = pygame.image.load(BG_PATH).convert()
    except (pygame.error, FileNotFoundError):
        surface = pygame.Surface(size)
        surface.fill(config.COLOR_BG)
        return surface

    surface = pygame.transform.smoothscale(image, size)
    veil = pygame.Surface(size)
    veil.fill((0, 0, 0))
    veil.set_alpha(config.MENU_BG_DARKEN)
    surface.blit(veil, (0, 0))
    return surface


class MenuScene(Scene):
    ITEMS = ("Iniciar", "Configuracoes", "Sair")

    def __init__(self, game) -> None:
        super().__init__(game)
        self.background = load_background()
        self.cursor = ui.MenuCursor(len(self.ITEMS))
        self.time = 0.0

    def update(self, dt: float) -> None:
        self.time += dt
        inp = self.game.input
        self.cursor.update(dt, inp.held("up"), inp.held("down"))

        if inp.pressed("confirm"):
            self._activate(self.cursor.index)

    def _activate(self, index: int) -> None:
        if index == 0:
            from .intro import IntroScene

            self.game.set_scene(IntroScene(self.game))
        elif index == 1:
            from .options import OptionsScene

            self.game.push_scene(OptionsScene(self.game))
        else:
            self.game.quit()

    def draw(self, surface: pygame.Surface) -> None:
        surface.blit(self.background, (0, 0))

        cx = config.INTERNAL_WIDTH // 2
        ui.draw_text(
            surface, self.game.font_title, "AMANDACONDA", (cx + 2, 38),
            config.COLOR_ACCENT_DEEP, align="center", shadow=False,
        )
        ui.draw_text(
            surface, self.game.font_title, "AMANDACONDA", (cx, 36),
            config.COLOR_ACCENT, align="center",
        )
        ui.draw_text(
            surface, self.game.font_small, "> nao existe saida_", (cx, 78),
            config.COLOR_UI_TEXT_DIM, align="center",
        )

        top = 150
        for i, label in enumerate(self.ITEMS):
            selected = i == self.cursor.index
            color = config.COLOR_ACCENT if selected else config.COLOR_UI_TEXT_DIM
            y = top + i * 24
            ui.draw_text(surface, self.game.font_medium, label, (cx, y), color, align="center")

            if selected:
                pulse = 2 + int(1.5 * (1 + math.sin(self.time * 6)))
                rect = self.game.font_medium.render(label, False, color).get_rect(midtop=(cx, y))
                ui.draw_text(
                    surface, self.game.font_medium, ">", (rect.left - 8 - pulse, y),
                    color, align="right",
                )
