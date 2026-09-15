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


def wrap_text(font: pygame.font.Font, text: str, max_width: int) -> list[str]:
    """Quebra por palavra pra caber em max_width pixels (sem AA)."""
    words = text.split()
    if not words:
        return []
    lines: list[str] = []
    atual = words[0]
    for word in words[1:]:
        tentativa = f"{atual} {word}"
        if font.size(tentativa)[0] <= max_width:
            atual = tentativa
        else:
            lines.append(atual)
            atual = word
    lines.append(atual)
    return lines


def draw_card(
    surface: pygame.Surface,
    rect: pygame.Rect,
    *,
    selected: bool = False,
    accent: tuple[int, int, int] | None = None,
) -> None:
    """Chrome de crachá / formulário: painel + moldura (âmbar/petróleo se selecionado)."""
    accent = accent or config.COLOR_ACCENT
    pygame.draw.rect(surface, config.COLOR_UI_SHADOW, rect.inflate(2, 2))
    pygame.draw.rect(surface, config.COLOR_UI_PANEL, rect)
    # Faixa superior tipo crachá acadêmico.
    faixa = pygame.Rect(rect.x, rect.y, rect.w, 3)
    pygame.draw.rect(surface, config.COLOR_ACCENT_DEEP if not selected else accent, faixa)
    borda = accent if selected else config.COLOR_UI_PANEL_EDGE
    pygame.draw.rect(surface, borda, rect, 1)


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
