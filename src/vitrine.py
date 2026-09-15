"""Figuras decorativas — mostra sprites ja importados sem combate."""

from __future__ import annotations

import pygame

from . import sprites, ui


class Figura:
    def __init__(
        self,
        entidade: str,
        x: float,
        y: float,
        *,
        label: str = "",
        facing: int = -1,
        escala: float = 1.0,
        anim: str = "parado",
    ) -> None:
        self.entidade = entidade
        self.x = x
        self.y = y
        self.label = label or entidade.upper()
        self.facing = facing
        self.escala = escala
        self.anim_nome = anim
        self.anim = sprites.Animator(entidade)
        self.anim.play(anim)
        self.tempo = 0.0

    def update(self, dt: float) -> None:
        self.tempo += dt
        # Prefere andando se existir; senao parado.
        conj = sprites.get(self.entidade)
        if conj and "andando" in conj.animacoes and self.anim_nome == "auto":
            self.anim.play("andando")
        else:
            self.anim.play(self.anim_nome if self.anim_nome != "auto" else "parado")
        self.anim.update(dt)

    def draw(
        self,
        surface: pygame.Surface,
        cam_x: float,
        cam_y: float,
        font: pygame.font.Font | None = None,
    ) -> None:
        img = self.anim.image(self.facing)
        if img is None:
            return
        if self.escala != 1.0:
            w = max(1, int(img.get_width() * self.escala))
            h = max(1, int(img.get_height() * self.escala))
            img = pygame.transform.scale(img, (w, h))
        dest = img.get_rect(
            midbottom=(round(self.x - cam_x), round(self.y - cam_y))
        )
        surface.blit(img, dest)
        if font is not None and self.label:
            ui.draw_text(
                surface,
                font,
                self.label,
                (dest.centerx, dest.top - 12),
                (200, 194, 184),
                align="center",
                shadow=True,
            )


def vitrine_fase1(chao_y: float, x0: float = 1380.0) -> list[Figura]:
    """Bosses/personagens com arte — fila na safezone pra ver in-game."""
    # Espacamento generoso: Amanda e larga.
    itens = [
        ("balarrals", "BALARRALS", 1.0, "parado"),
        ("luanevil", "LUANEVIL", 0.85, "parado"),
        ("marlombolico", "MARLOM", 0.9, "parado"),
        ("amandaconda", "AMANDA", 0.55, "auto"),
    ]
    figs: list[Figura] = []
    x = x0
    for entidade, label, escala, anim in itens:
        conj = sprites.get(entidade)
        if conj is None:
            continue
        figs.append(
            Figura(
                entidade,
                x,
                chao_y,
                label=label,
                facing=-1,
                escala=escala,
                anim=anim,
            )
        )
        # Amanda precisa de mais espaco.
        x += 90 if entidade != "amandaconda" else 120
    return figs
