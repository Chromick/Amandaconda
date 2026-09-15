"""Escolha de escola: Fisico (teclado) ou Especial (poder).

Uma tela so, depois do enredo. Na fase 1 a escolha trava a arma da run.
"""

from __future__ import annotations

import pygame

from .. import config, ui
from ..scene import Scene

FISICO = "teclado"
ESPECIAL = "virus"

OPCOES = [
    {
        "id": FISICO,
        "titulo": "FISICO",
        "arma": "Teclado",
        "texto": "Perto. Combo curto. Mais vida no pendrive.",
        "cor": config.COLOR_ACCENT,
        "codigo": "MAT-01",
    },
    {
        "id": ESPECIAL,
        "titulo": "ESPECIAL",
        "arma": "Poder",
        "texto": "Longe. Bola de virus. Mais dano no pendrive.",
        "cor": config.COLOR_VIRUS,
        "codigo": "MAT-02",
    },
]


class LoadoutScene(Scene):
    def __init__(self, game) -> None:
        super().__init__(game)
        self.cursor = ui.MenuCursor(len(OPCOES))

    def update(self, dt: float) -> None:
        inp = self.game.input
        self.cursor.update(dt, inp.held("left") or inp.held("up"), inp.held("right") or inp.held("down"))

        if inp.pressed("confirm"):
            self._confirmar(OPCOES[self.cursor.index]["id"])
        if inp.pressed("back"):
            from .menu import MenuScene

            self.game.set_scene(MenuScene(self.game))

    def _confirmar(self, escola: str) -> None:
        from ..run_state import RunState
        from .play import PlayScene

        run = RunState(escola=escola)
        self.game.set_scene(PlayScene(self.game, escola=escola, run=run))

    def draw(self, surface: pygame.Surface) -> None:
        surface.fill(config.COLOR_BG)
        cx = config.INTERNAL_WIDTH // 2

        ui.draw_text(
            surface, self.game.font_small, "UNIV · LABORATORIO DOIS · MATRICULA",
            (cx, 22), config.COLOR_UI_TEXT_DIM, align="center",
        )
        ui.draw_text(
            surface, self.game.font_title, "PEGUE UMA",
            (cx, 40), config.COLOR_ACCENT, align="center",
        )
        ui.draw_text(
            surface, self.game.font_small, "voce usa so essa na run",
            (cx, 84), config.COLOR_UI_TEXT_DIM, align="center",
        )

        card_w, card_h = 178, 118
        gap = 16
        total = card_w * 2 + gap
        left = (config.INTERNAL_WIDTH - total) // 2
        top = 100
        texto_max = card_w - 20

        for i, op in enumerate(OPCOES):
            x = left + i * (card_w + gap)
            selected = i == self.cursor.index
            cor = op["cor"] if selected else config.COLOR_UI_TEXT_DIM
            card = pygame.Rect(x, top, card_w, card_h)
            ui.draw_card(surface, card, selected=selected, accent=op["cor"])

            ui.draw_text(
                surface, self.game.font_small, op["codigo"],
                (x + 8, top + 8), config.COLOR_UI_TEXT_DIM, shadow=False,
            )
            ui.draw_text(
                surface, self.game.font_medium, op["titulo"],
                (x + card_w // 2, top + 22), cor, align="center",
            )
            ui.draw_text(
                surface, self.game.font_small, op["arma"],
                (x + card_w // 2, top + 44), config.COLOR_UI_TEXT, align="center",
            )
            linhas = ui.wrap_text(self.game.font_small, op["texto"], texto_max)
            for j, linha in enumerate(linhas[:3]):
                ui.draw_text(
                    surface, self.game.font_small, linha,
                    (x + card_w // 2, top + 64 + j * 14),
                    config.COLOR_UI_TEXT_DIM, align="center",
                )

        ui.draw_text(
            surface, self.game.font_small,
            "A/D ou setas · enter confirma · esc menu",
            (cx, config.INTERNAL_HEIGHT - 18),
            config.COLOR_UI_TEXT_DIM, align="center",
        )
