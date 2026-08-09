from __future__ import annotations

import pygame

from . import config, display, sprites, ui
from .balance import Balance
from .input import Input
from .scene import Scene
from .settings import Settings


class Game:
    def __init__(self) -> None:
        display.enable_dpi_awareness()  # antes do init: depois nao tem efeito
        pygame.init()
        pygame.display.set_caption(config.TITLE)

        self.settings = Settings()
        self.balance = Balance()
        self.input = Input()
        self.clock = pygame.time.Clock()

        self.surface = pygame.Surface((config.INTERNAL_WIDTH, config.INTERNAL_HEIGHT))
        self.window: pygame.Surface | None = None
        self.desktop = (0, 0)
        self.window_scale = 1
        self.present_scale = 1
        self._present_rect = pygame.Rect(0, 0, 0, 0)
        self._present_buffer: pygame.Surface | None = None
        self.apply_display_settings()

        sprites.carregar()

        self.font_small = pygame.font.Font(None, 15)
        self.font_medium = pygame.font.Font(None, 22)
        self.font_title = pygame.font.Font(None, 52)

        self.show_debug = bool(self.settings["show_debug"])
        self.running = True

        self.scenes: list[Scene] = []
        self._pending: list[tuple[str, Scene | None]] = []

        from .scenes.menu import MenuScene

        self.set_scene(MenuScene(self))
        self._flush_scene_changes()

    # --- ciclo de vida das cenas ---

    def set_scene(self, scene: Scene) -> None:
        self._pending.append(("set", scene))

    def push_scene(self, scene: Scene) -> None:
        self._pending.append(("push", scene))

    def pop_scene(self) -> None:
        self._pending.append(("pop", None))

    def quit(self) -> None:
        self.running = False

    def _flush_scene_changes(self) -> None:
        """Trocas de cena so acontecem entre passos, nunca no meio de um."""
        while self._pending:
            action, scene = self._pending.pop(0)
            if action == "set":
                while self.scenes:
                    self.scenes.pop().on_exit()
                self.scenes.append(scene)
                scene.on_enter()
            elif action == "push":
                self.scenes.append(scene)
                scene.on_enter()
            elif action == "pop" and self.scenes:
                self.scenes.pop().on_exit()

    # --- video ---

    def apply_display_settings(self) -> None:
        self.desktop = display.desktop_size()
        self.window_scale = display.resolve_window_scale(self.settings["window_scale"])

        if self.settings["fullscreen"]:
            # Tamanho zero pede tela cheia sem troca de modo de video: abre
            # instantaneo, alterna de janela sem piscar, e ja vem na resolucao
            # do monitor.
            self.window = pygame.display.set_mode((0, 0), pygame.FULLSCREEN, vsync=1)
        else:
            size = (
                config.INTERNAL_WIDTH * self.window_scale,
                config.INTERNAL_HEIGHT * self.window_scale,
            )
            self.window = pygame.display.set_mode(size, vsync=1)

        window_w, window_h = self.window.get_size()
        factor = display.fit_scale(window_w, window_h)
        width = config.INTERNAL_WIDTH * factor
        height = config.INTERNAL_HEIGHT * factor

        self.present_scale = factor
        self._present_rect = pygame.Rect(
            (window_w - width) // 2, (window_h - height) // 2, width, height
        )
        self._present_buffer = pygame.Surface((width, height))

    @property
    def present_size(self) -> tuple[int, int]:
        """Tamanho real da imagem na tela, ja sem as barras pretas."""
        return self._present_rect.size

    # --- laco principal ---

    def run(self) -> None:
        accumulator = 0.0
        while self.running:
            frame_time = min(
                self.clock.tick(config.RENDER_FPS_CAP) / 1000.0, config.MAX_FRAME_TIME
            )
            accumulator += frame_time

            self._handle_events()

            while accumulator >= config.FIXED_DT:
                self.input.begin_tick()
                if self.scenes:
                    self.scenes[-1].update(config.FIXED_DT)
                accumulator -= config.FIXED_DT

            self._flush_scene_changes()
            self._draw()

        pygame.quit()

    def _handle_events(self) -> None:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                self.running = False
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_F5:
                    self.balance.reload()
                    sprites.carregar()
                elif event.key == pygame.K_F1:
                    self.show_debug = not self.show_debug
                    self.settings["show_debug"] = self.show_debug
                elif event.key == pygame.K_F11:
                    self.settings["fullscreen"] = not self.settings["fullscreen"]
                    self.apply_display_settings()
            self.input.handle_event(event)

    def _draw(self) -> None:
        self.surface.fill(config.COLOR_BG)

        first = len(self.scenes) - 1
        while first > 0 and self.scenes[first].draws_scene_below:
            first -= 1
        for scene in self.scenes[first:]:
            scene.draw(self.surface)

        if self.show_debug:
            self._draw_debug()

        self._present()

    def _draw_debug(self) -> None:
        lines = [f"fps {self.clock.get_fps():5.1f}"]
        if self.scenes:
            lines += self.scenes[-1].debug_lines()
        lines.append(sprites.resumo())
        lines.append("F5 recarrega   F1 debug   F11 tela cheia")

        y = 4
        for text in lines:
            ui.draw_text(self.surface, self.font_small, text, (5, y), config.COLOR_DEBUG)
            y += 11

        if self.balance.error:
            ui.draw_text(
                self.surface, self.font_small,
                "balance.json invalido, usando valores anteriores",
                (5, y), config.COLOR_DEBUG_WARN,
            )

    def _present(self) -> None:
        if self._present_rect.size == self.window.get_size():
            pygame.transform.scale(self.surface, self._present_rect.size, self.window)
        else:
            pygame.transform.scale(
                self.surface, self._present_rect.size, self._present_buffer
            )
            self.window.fill((0, 0, 0))
            self.window.blit(self._present_buffer, self._present_rect)
        pygame.display.flip()
