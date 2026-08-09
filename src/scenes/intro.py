"""Abertura em rolagem.

O texto vem de data/intro.txt para poder ser reescrito sem tocar no codigo.
Velocidade e espacamentos vem de balance.json, secao "intro".
"""

from __future__ import annotations

from pathlib import Path

import pygame

from .. import config, ui
from ..scene import Scene

INTRO_PATH = Path(__file__).resolve().parent.parent.parent / "data" / "intro.txt"

PLAIN, EMPHASIS, TITLE, BLANK = "plain", "emphasis", "title", "blank"


def load_lines() -> list[tuple[str, str]]:
    try:
        raw = INTRO_PATH.read_text(encoding="utf-8").splitlines()
    except OSError:
        return [(TITLE, "AMANDACONDA")]

    lines: list[tuple[str, str]] = []
    for line in raw:
        stripped = line.strip()
        if stripped.startswith("#"):
            continue
        if not stripped:
            lines.append((BLANK, ""))
        elif stripped.startswith("="):
            lines.append((TITLE, stripped[1:].strip()))
        elif stripped.startswith(">"):
            lines.append((EMPHASIS, stripped[1:].strip()))
        else:
            lines.append((PLAIN, stripped))

    while lines and lines[0][0] == BLANK:
        lines.pop(0)
    while lines and lines[-1][0] == BLANK:
        lines.pop()
    return lines


def build_edge_fade() -> pygame.Surface:
    """Escurece as bordas para o texto entrar e sair suave.

    A faixa de baixo termina opaca: a dica de teclas fica ali e nao pode
    disputar espaco com o texto que ainda esta subindo.
    """
    width, height = config.INTERNAL_WIDTH, config.INTERNAL_HEIGHT
    fade = pygame.Surface((width, height), pygame.SRCALPHA)
    top_band, bottom_band, bottom_solid = 46, 64, 20

    for i in range(top_band):
        alpha = int(255 * (1 - i / top_band) ** 1.6)
        pygame.draw.line(fade, (*config.COLOR_BG, alpha), (0, i), (width, i))

    for i in range(bottom_band):
        y = height - 1 - i
        ramp = min(1.0, max(0.0, (i - bottom_solid) / (bottom_band - bottom_solid)))
        alpha = int(255 * (1 - ramp) ** 1.6)
        pygame.draw.line(fade, (*config.COLOR_BG, alpha), (0, y), (width, y))

    return fade


class IntroScene(Scene):
    def __init__(self, game) -> None:
        super().__init__(game)
        self.lines = load_lines()
        self.fade = build_edge_fade()
        self.offset = 0.0
        self.elapsed = 0.0
        self.hold = 0.0
        self._layout: dict = {}
        self.content = self._render_content()

    def _render_content(self) -> pygame.Surface:
        cfg = self.game.balance["intro"]
        self._layout = dict(cfg)
        fonts = {
            PLAIN: self.game.font_small,
            EMPHASIS: self.game.font_medium,
            TITLE: self.game.font_title,
        }
        colors = {
            PLAIN: config.COLOR_UI_TEXT,
            EMPHASIS: config.COLOR_ACCENT,
            TITLE: config.COLOR_ACCENT,
        }
        heights = {
            PLAIN: cfg["line_height"],
            EMPHASIS: cfg["emphasis_line_height"],
            TITLE: cfg["title_line_height"],
            BLANK: cfg["blank_line_height"],
        }

        positions: list[tuple[int, str, str]] = []
        y = 0
        for kind, text in self.lines:
            positions.append((y, kind, text))
            y += heights[kind]

        self.last_line_y = positions[-1][0] if positions else 0

        surface = pygame.Surface((config.INTERNAL_WIDTH, max(1, y)), pygame.SRCALPHA)
        cx = config.INTERNAL_WIDTH // 2
        for line_y, kind, text in positions:
            if kind == BLANK:
                continue
            ui.draw_text(surface, fonts[kind], text, (cx, line_y), colors[kind], align="center")
        return surface

    @property
    def _stop_offset(self) -> float:
        """Para com a ultima linha um pouco acima do centro, em vez de deixar
        o titulo sair pelo topo."""
        return config.INTERNAL_HEIGHT + self.last_line_y - config.INTERNAL_HEIGHT * 0.42

    def update(self, dt: float) -> None:
        cfg = self.game.balance["intro"]
        inp = self.game.input
        self.elapsed += dt

        # F5 recarrega o balance; redesenha o texto se o espacamento mudou.
        if cfg != self._layout:
            self.content = self._render_content()

        if inp.pressed("back"):
            self._start_game()
            return

        if self.offset < self._stop_offset:
            speed = cfg["scroll_speed"]
            if inp.held("confirm"):
                speed *= cfg["fast_forward_multiplier"]
            self.offset = min(self.offset + speed * dt, self._stop_offset)
        else:
            self.hold += dt
            if self.hold >= cfg["hold_at_end"] or inp.pressed("confirm"):
                self._start_game()

    def _start_game(self) -> None:
        from .play import PlayScene

        self.game.set_scene(PlayScene(self.game))

    def draw(self, surface: pygame.Surface) -> None:
        surface.fill(config.COLOR_BG)
        surface.blit(self.content, (0, round(config.INTERNAL_HEIGHT - self.offset)))
        surface.blit(self.fade, (0, 0))

        if self.elapsed >= self.game.balance["intro"]["hint_delay"]:
            ui.draw_text(
                surface,
                self.game.font_small,
                "enter acelera   esc pula",
                (config.INTERNAL_WIDTH // 2, config.INTERNAL_HEIGHT - 14),
                config.COLOR_UI_TEXT_DIM,
                align="center",
            )
