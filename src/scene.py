"""Base de cena.

O jogo e uma pilha de cenas. Empilhar mantem a de baixo viva (usado por
configuracoes sobre o menu, e depois por pausa sobre o jogo); trocar substitui.
"""

from __future__ import annotations

from typing import TYPE_CHECKING

import pygame

if TYPE_CHECKING:
    from .game import Game


class Scene:
    def __init__(self, game: "Game") -> None:
        self.game = game

    def on_enter(self) -> None: ...

    def on_exit(self) -> None: ...

    def handle_event(self, event: pygame.event.Event) -> None: ...

    def update(self, dt: float) -> None: ...

    def draw(self, surface: pygame.Surface) -> None: ...

    def debug_lines(self) -> list[str]:
        return []

    @property
    def draws_scene_below(self) -> bool:
        """Se True, a cena de baixo na pilha e desenhada antes desta."""
        return False
