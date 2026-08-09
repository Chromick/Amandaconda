from __future__ import annotations

import pygame

from .. import config, level as level_mod
from ..camera import Camera
from ..player import Player
from ..scene import Scene


class PlayScene(Scene):
    def __init__(self, game) -> None:
        super().__init__(game)
        self.level = level_mod.test_room()
        self.player = Player(game.balance, self.level.spawn.x, self.level.spawn.y)
        self.camera = Camera(game.balance)
        self.camera.snap_to(
            self.player.rect.centerx, self.player.rect.centery, self.level
        )

    def update(self, dt: float) -> None:
        inp = self.game.input

        if inp.pressed("pause"):
            from .menu import MenuScene

            self.game.set_scene(MenuScene(self.game))
            return

        self.player.update(dt, inp, self.level)
        self.camera.update(
            dt,
            self.player.rect.centerx,
            self.player.rect.centery,
            self.player.facing,
            self.level,
        )

    def draw(self, surface: pygame.Surface) -> None:
        surface.fill(config.COLOR_BG)
        self.level.draw(surface, self.camera.x, self.camera.y)
        self.player.draw(surface, self.camera.x, self.camera.y)

    def debug_lines(self) -> list[str]:
        return [
            f"vel {self.player.vel.x:7.1f} {self.player.vel.y:7.1f}",
            f"chao {'sim' if self.player.on_ground else 'nao'}",
            f"vigor {self.player.stamina:5.1f}",
        ]
