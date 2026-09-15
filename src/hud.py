"""HUD terminal de lab — vida, vigor, escola e niveis de pendrive."""

from __future__ import annotations

import pygame

from . import config, ui

MARGEM = 6
PAINEL_X = 6
PAINEL_Y = 6
PAINEL_W = 168
PAINEL_H = 56
LINHA_H = 12
BARRA_H = 5
BARRA_W = 110
LABEL_W = 36


VELOCIDADE_FANTASMA = 55.0
ATRASO_FANTASMA = 0.45


class Hud:
    def __init__(self) -> None:
        self.fantasma = 1.0
        self.atraso = 0.0
        self._font: pygame.font.Font | None = None

    def bind_font(self, font: pygame.font.Font) -> None:
        self._font = font

    def update(self, dt: float, vida: float, vida_max: float) -> None:
        fracao = vida / vida_max if vida_max else 0.0
        if fracao > self.fantasma:
            self.fantasma = fracao
            return
        if fracao < self.fantasma:
            self.atraso = max(self.atraso, ATRASO_FANTASMA) if self.atraso <= 0 else self.atraso
        if self.atraso > 0.0:
            self.atraso -= dt
            return
        self.fantasma = max(fracao, self.fantasma - VELOCIDADE_FANTASMA / 100.0 * dt)

    def marcar_dano(self) -> None:
        self.atraso = ATRASO_FANTASMA

    def draw(self, surface: pygame.Surface, player, font: pygame.font.Font | None = None) -> None:
        fonte = font or self._font
        if fonte is None:
            return

        p = player.balance["player"]
        vida = player.health / player.max_health if player.max_health else 0.0
        vigor = player.stamina / p["max_stamina"]
        vida_n = max(0, int(round(player.health)))

        # Painel terminal: sombra + fundo + moldura petroleo.
        pygame.draw.rect(
            surface,
            config.COLOR_UI_SHADOW,
            (PAINEL_X - 1, PAINEL_Y - 1, PAINEL_W + 2, PAINEL_H + 2),
        )
        pygame.draw.rect(surface, config.COLOR_UI_PANEL, (PAINEL_X, PAINEL_Y, PAINEL_W, PAINEL_H))
        pygame.draw.rect(
            surface, config.COLOR_ACCENT_DEEP, (PAINEL_X, PAINEL_Y, PAINEL_W, PAINEL_H), 1
        )

        y = PAINEL_Y + 4
        self._linha_barra(
            surface, fonte, "VIDA", PAINEL_X + MARGEM, y, vida, config.COLOR_DANO, self.fantasma, vida_n
        )
        y += LINHA_H + 2
        self._linha_barra(
            surface, fonte, "VIGOR", PAINEL_X + MARGEM, y, vigor, config.COLOR_ACCENT_DEEP
        )
        y += LINHA_H + 4

        if player.arma == "teclado":
            escola, cor = "FISICO", config.COLOR_ACCENT
        else:
            escola, cor = "ESPECIAL", config.COLOR_VIRUS
        ui.draw_text(
            surface, fonte, f"ESC:{escola}", (PAINEL_X + MARGEM, y), cor, shadow=False
        )
        ui.draw_text(
            surface,
            fonte,
            f"F{player.nivel_fisico} E{player.nivel_especial}",
            (PAINEL_X + 78, y),
            config.COLOR_UI_TEXT_DIM,
            shadow=False,
        )
        ui.draw_text(
            surface,
            fonte,
            player.formatar_bytes(),
            (PAINEL_X + PAINEL_W - MARGEM, y),
            config.COLOR_ACCENT,
            align="right",
            shadow=False,
        )

    def _linha_barra(
        self,
        surface: pygame.Surface,
        font: pygame.font.Font,
        label: str,
        x: int,
        y: int,
        fracao: float,
        cor: tuple[int, int, int],
        fantasma: float | None = None,
        numero: int | None = None,
    ) -> None:
        ui.draw_text(surface, font, label, (x, y - 1), config.COLOR_UI_TEXT_DIM, shadow=False)
        bx = x + LABEL_W
        by = y + 3
        self._barra(surface, bx, by, BARRA_W, fracao, cor, fantasma)
        if numero is not None:
            ui.draw_text(
                surface,
                font,
                str(numero),
                (bx + BARRA_W + 4, y - 1),
                config.COLOR_UI_TEXT,
                shadow=False,
            )

    def _barra(
        self,
        surface: pygame.Surface,
        x: int,
        y: int,
        largura: int,
        fracao: float,
        cor: tuple[int, int, int],
        fantasma: float | None = None,
    ) -> None:
        pygame.draw.rect(surface, config.COLOR_UI_SHADOW, (x - 1, y - 1, largura + 2, BARRA_H + 2))
        pygame.draw.rect(surface, (30, 27, 36), (x, y, largura, BARRA_H))
        if fantasma is not None and fantasma > fracao:
            pygame.draw.rect(
                surface, config.COLOR_PREPARACAO, (x, y, round(largura * fantasma), BARRA_H)
            )
        pygame.draw.rect(surface, cor, (x, y, round(largura * max(0.0, fracao)), BARRA_H))
