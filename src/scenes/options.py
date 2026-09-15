from __future__ import annotations

import pygame

from .. import config, display, ui
from ..scene import Scene
from ..util import clamp


class Option:
    def __init__(self, label: str, key: str | None = None) -> None:
        self.label = label
        self.key = key

    def value_text(self, settings) -> str:
        return ""

    def adjust(self, settings, delta: int) -> bool:
        return False

    def activate(self, scene) -> bool:
        return False


class Toggle(Option):
    def value_text(self, settings) -> str:
        return "Sim" if settings[self.key] else "Nao"

    def adjust(self, settings, delta: int) -> bool:
        settings[self.key] = not settings[self.key]
        return True

    def activate(self, scene) -> bool:
        return self.adjust(scene.game.settings, 1)


class Choice(Option):
    def __init__(self, label: str, key: str, values: list, suffix: str = "") -> None:
        super().__init__(label, key)
        self.values = values
        self.suffix = suffix

    def value_text(self, settings) -> str:
        return f"{settings[self.key]}{self.suffix}"

    def adjust(self, settings, delta: int) -> bool:
        try:
            index = self.values.index(settings[self.key])
        except ValueError:
            index = 0
        index = int(clamp(index + delta, 0, len(self.values) - 1))
        settings[self.key] = self.values[index]
        return True


class WindowScale(Choice):
    """As escalas oferecidas sao so as que cabem no monitor, mais o automatico."""

    def __init__(self) -> None:
        self.limit = display.max_window_scale()
        super().__init__(
            "Escala da janela", "window_scale", [0, *range(1, self.limit + 1)]
        )

    def value_text(self, settings) -> str:
        value = int(settings[self.key])
        if value <= 0:
            return f"Auto ({self.limit}x)"
        return f"{value}x"


class Slider(Option):
    def __init__(self, label: str, key: str, step: float = 0.1) -> None:
        super().__init__(label, key)
        self.step = step

    def value_text(self, settings) -> str:
        return f"{round(settings[self.key] * 100):d}"

    def adjust(self, settings, delta: int) -> bool:
        settings[self.key] = round(clamp(settings[self.key] + delta * self.step, 0.0, 1.0), 2)
        return True


class Back(Option):
    def activate(self, scene) -> bool:
        scene.close()
        return False


class OptionsScene(Scene):
    def __init__(self, game) -> None:
        super().__init__(game)
        self.options: list[Option] = [
            Toggle("Tela cheia", "fullscreen"),
            WindowScale(),
            Slider("Volume da musica", "music_volume"),
            Slider("Volume dos efeitos", "sfx_volume"),
            Toggle("Mostrar depuracao", "show_debug"),
            Back("Voltar"),
        ]
        self.cursor = ui.MenuCursor(len(self.options))

    @property
    def draws_scene_below(self) -> bool:
        return True

    def update(self, dt: float) -> None:
        inp = self.game.input
        self.cursor.update(dt, inp.held("up"), inp.held("down"))

        option = self.options[self.cursor.index]

        delta = (1 if inp.pressed("right") else 0) - (1 if inp.pressed("left") else 0)
        if delta and option.adjust(self.game.settings, delta):
            self._apply(option)

        if inp.pressed("confirm"):
            if option.activate(self):
                self._apply(option)

        if inp.pressed("back"):
            self.close()

    def _apply(self, option: Option) -> None:
        if option.key in ("fullscreen", "window_scale"):
            self.game.apply_display_settings()
        elif option.key == "show_debug":
            self.game.show_debug = self.game.settings["show_debug"]

    def close(self) -> None:
        self.game.settings.save()
        self.game.pop_scene()

    def draw(self, surface: pygame.Surface) -> None:
        veil = pygame.Surface(surface.get_size())
        veil.fill((0, 0, 0))
        veil.set_alpha(190)
        surface.blit(veil, (0, 0))

        cx = config.INTERNAL_WIDTH // 2
        ui.draw_text(
            surface, self.game.font_small, "SISTEMA · PREFS", (cx, 22),
            config.COLOR_UI_TEXT_DIM, align="center",
        )
        ui.draw_text(
            surface, self.game.font_medium, "CONFIGURACOES", (cx, 38),
            config.COLOR_ACCENT, align="center",
        )

        left = 96
        right = config.INTERNAL_WIDTH - 96
        top = 78
        disabled = self.game.settings["fullscreen"]

        for i, option in enumerate(self.options):
            selected = i == self.cursor.index
            greyed = disabled and option.key == "window_scale"

            if greyed:
                color = (72, 70, 80)
            elif selected:
                color = config.COLOR_ACCENT
            else:
                color = config.COLOR_UI_TEXT_DIM

            y = top + i * 22
            ui.draw_text(surface, self.game.font_small, option.label, (left, y), color)

            value = option.value_text(self.game.settings)
            if value:
                arrows = f"< {value} >" if selected and not greyed else value
                ui.draw_text(surface, self.game.font_small, arrows, (right, y), color, align="right")

            if selected:
                ui.draw_text(surface, self.game.font_small, ">", (left - 12, y), color)

        desktop_w, desktop_h = self.game.desktop
        image_w, image_h = self.game.present_size
        ui.draw_text(
            surface, self.game.font_small,
            f"monitor {desktop_w}x{desktop_h}   "
            f"imagem {image_w}x{image_h}   {self.game.present_scale}x de 480x270",
            (cx, config.INTERNAL_HEIGHT - 44),
            config.COLOR_UI_TEXT_DIM, align="center",
        )

        ui.draw_text(
            surface, self.game.font_small,
            "setas para mudar   enter confirma   esc volta",
            (cx, config.INTERNAL_HEIGHT - 22),
            config.COLOR_UI_TEXT_DIM, align="center",
        )
