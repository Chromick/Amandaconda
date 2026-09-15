"""Pendrive no chao — pergaminho dual do Dead Cells.

Nao aplica sozinho: a cena abre a escolha Fisico vs Especial.
"""

from __future__ import annotations

import math

import pygame

from . import config, sprites, ui, visual


class Pendrive:
    def __init__(self, x: float, y: float) -> None:
        self.rect = pygame.FRect(0, 0, 14, 10)
        self.rect.midbottom = (x, y)
        self.vivo = True
        self.tempo = 0.0
        self.anim = sprites.Animator("pendrive")

    def update(self, dt: float) -> None:
        self.tempo += dt
        self.anim.play("parado")
        self.anim.update(dt)

    def draw(
        self,
        surface: pygame.Surface,
        cam_x: float,
        cam_y: float,
        font: pygame.font.Font,
    ) -> None:
        if not self.vivo:
            return
        bob = round(1.5 * math.sin(self.tempo * 4))
        r = pygame.Rect(
            round(self.rect.x - cam_x),
            round(self.rect.y - cam_y + bob),
            round(self.rect.width),
            round(self.rect.height),
        )
        quadro = self.anim.image(1)
        if quadro is not None:
            # Ancora: base do canvas no chao (midbottom do hitbox).
            dest = quadro.get_rect(midbottom=(r.centerx, r.bottom))
            surface.blit(quadro, dest)
            label_y = dest.top - 10
        else:
            visual.pendrive_chip(surface, r.move(0, -bob), config.COLOR_ACCENT, bob)
            label_y = r.top - 12
        ui.draw_text(
            surface,
            font,
            "PENDRIVE",
            (r.centerx, label_y),
            config.COLOR_ACCENT,
            align="center",
            shadow=True,
        )


def desenhar_escolha(
    surface: pygame.Surface,
    font_m: pygame.font.Font,
    font_s: pygame.font.Font,
    cursor: int,
) -> None:
    """Overlay do fork: Fisico (mais vida) vs Especial (mais dano)."""
    veil = pygame.Surface(surface.get_size())
    veil.fill((0, 0, 0))
    veil.set_alpha(180)
    surface.blit(veil, (0, 0))

    cx = config.INTERNAL_WIDTH // 2
    ui.draw_text(surface, font_s, "ARQUIVO · USB", (cx, 58), config.COLOR_UI_TEXT_DIM, align="center")
    ui.draw_text(surface, font_m, "PENDRIVE", (cx, 74), config.COLOR_ACCENT, align="center")
    ui.draw_text(
        surface, font_s, "escolha uma melhoria",
        (cx, 96), config.COLOR_UI_TEXT_DIM, align="center",
    )

    opcoes = [
        ("FISICO", "MAT-F", "+8% dano teclado", "+18 vida", config.COLOR_ACCENT),
        ("ESPECIAL", "MAT-E", "+15% dano poder", "+8 vida", config.COLOR_VIRUS),
    ]
    card_w, card_h = 168, 86
    gap = 14
    total = card_w * 2 + gap
    left = (config.INTERNAL_WIDTH - total) // 2
    top = 118

    for i, (titulo, codigo, linha1, linha2, cor) in enumerate(opcoes):
        x = left + i * (card_w + gap)
        sel = i == cursor
        card = pygame.Rect(x, top, card_w, card_h)
        ui.draw_card(surface, card, selected=sel, accent=cor)
        ui.draw_text(
            surface, font_s, codigo,
            (x + 8, top + 8), config.COLOR_UI_TEXT_DIM, shadow=False,
        )
        ui.draw_text(
            surface, font_m, titulo,
            (x + card_w // 2, top + 22), cor if sel else config.COLOR_UI_TEXT_DIM, align="center",
        )
        ui.draw_text(
            surface, font_s, linha1,
            (x + card_w // 2, top + 46), config.COLOR_UI_TEXT, align="center",
        )
        ui.draw_text(
            surface, font_s, linha2,
            (x + card_w // 2, top + 60), config.COLOR_UI_TEXT_DIM, align="center",
        )

    ui.draw_text(
        surface, font_s, "A/D · enter confirma",
        (cx, config.INTERNAL_HEIGHT - 28), config.COLOR_UI_TEXT_DIM, align="center",
    )
