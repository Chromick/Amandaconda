from __future__ import annotations

import pygame

from . import config


def draw_text(
    surface: pygame.Surface,
    font: pygame.font.Font,
    text: str,
    pos: tuple[int, int],
    color: tuple[int, int, int],
    align: str = "left",
    shadow: bool = True,
) -> pygame.Rect:
    image = font.render(text, False, color)
    rect = image.get_rect()
    if align == "center":
        rect.midtop = pos
    elif align == "right":
        rect.topright = pos
    else:
        rect.topleft = pos

    if shadow:
        dark = font.render(text, False, config.COLOR_UI_SHADOW)
        surface.blit(dark, (rect.x + 1, rect.y + 1))
    surface.blit(image, rect)
    return rect


class MenuCursor:
    """Navegacao vertical com repeticao ao segurar a tecla."""

    REPEAT_DELAY = 0.35
    REPEAT_RATE = 0.09

    def __init__(self, count: int) -> None:
        self.count = count
        self.index = 0
        self._direction = 0
        # Comeca negativo: o tempo ate zero e o atraso antes da repeticao comecar.
        self._hold = 0.0

    def update(self, dt: float, up: bool, down: bool) -> None:
        direction = (1 if down else 0) - (1 if up else 0)

        if direction == 0:
            self._direction = 0
            self._hold = 0.0
            return

        if direction != self._direction:
            self._direction = direction
            self._hold = -self.REPEAT_DELAY
            self._step(direction)
            return

        self._hold += dt
        while self._hold >= self.REPEAT_RATE:
            self._hold -= self.REPEAT_RATE
            self._step(direction)

    def _step(self, delta: int) -> None:
        if self.count > 0:
            self.index = (self.index + delta) % self.count
