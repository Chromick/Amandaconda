"""Menu de pausa in-game — Esc nao joga no menu principal direto."""

from __future__ import annotations

import pygame

from .. import config, ui
from ..scene import Scene

ITENS = ("Continuar", "Configuracoes", "Menu principal")


class PauseScene(Scene):
    def __init__(self, game) -> None:
        super().__init__(game)
        self.cursor = ui.MenuCursor(len(ITENS))

    @property
    def draws_scene_below(self) -> bool:
        return True

    def update(self, dt: float) -> None:
        inp = self.game.input
        # Esc / P fecha a pausa (voltar ao jogo).
        if inp.pressed("pause") or inp.pressed("back"):
            self.game.pop_scene()
            return

        self.cursor.update(dt, inp.held("up"), inp.held("down"))
        if not inp.pressed("confirm"):
            return

        i = self.cursor.index
        if i == 0:
            self.game.pop_scene()
        elif i == 1:
            from .options import OptionsScene

            self.game.push_scene(OptionsScene(self.game))
        else:
            from .menu import MenuScene

            # set_scene limpa a pilha (play/hub/boss + pausa).
            self.game.set_scene(MenuScene(self.game))

    def draw(self, surface: pygame.Surface) -> None:
        veil = pygame.Surface(surface.get_size())
        veil.fill((0, 0, 0))
        veil.set_alpha(170)
        surface.blit(veil, (0, 0))

        cx = config.INTERNAL_WIDTH // 2
        ui.draw_text(
            surface, self.game.font_small, "SISTEMA · PAUSA",
            (cx, 56), config.COLOR_UI_TEXT_DIM, align="center",
        )
        ui.draw_text(
            surface, self.game.font_title, "PAUSA",
            (cx, 74), config.COLOR_ACCENT, align="center",
        )

        top = 130
        for i, label in enumerate(ITENS):
            sel = i == self.cursor.index
            cor = config.COLOR_ACCENT if sel else config.COLOR_UI_TEXT_DIM
            y = top + i * 26
            ui.draw_text(surface, self.game.font_medium, label, (cx, y), cor, align="center")
            if sel:
                ui.draw_text(
                    surface, self.game.font_medium, ">",
                    (cx - 70, y), cor, align="right",
                )

        ui.draw_text(
            surface, self.game.font_small, "esc continua  ·  enter confirma",
            (cx, config.INTERNAL_HEIGHT - 22),
            config.COLOR_UI_TEXT_DIM, align="center",
        )
