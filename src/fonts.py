"""Tipografia pixel embutida (VT323 / OFL) — sem AA, canvas 480x270."""

from __future__ import annotations

from pathlib import Path

import pygame

RAIZ = Path(__file__).resolve().parent.parent
FONT_PATH = RAIZ / "assets" / "fonts" / "pixel.ttf"

# Tamanhos no canvas interno. VT323 fica legivel nesses valores.
SIZE_SMALL = 14
SIZE_MEDIUM = 22
SIZE_TITLE = 40


class Fonts:
    __slots__ = ("small", "medium", "title")

    def __init__(self) -> None:
        if FONT_PATH.exists():
            self.small = pygame.font.Font(str(FONT_PATH), SIZE_SMALL)
            self.medium = pygame.font.Font(str(FONT_PATH), SIZE_MEDIUM)
            self.title = pygame.font.Font(str(FONT_PATH), SIZE_TITLE)
        else:
            # Fallback raro: build sem o TTF ainda roda.
            self.small = pygame.font.Font(None, SIZE_SMALL)
            self.medium = pygame.font.Font(None, SIZE_MEDIUM)
            self.title = pygame.font.Font(None, SIZE_TITLE)


def carregar() -> Fonts:
    return Fonts()
