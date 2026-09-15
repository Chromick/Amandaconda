"""Arena de chefe — Balarrals primeiro; retry rapido na porta."""

from __future__ import annotations

import pygame

from .. import combat, config, level as level_mod, ui, visual
from ..bosses import Balarrals
from ..camera import Camera
from ..hud import Hud
from ..player import Player
from ..projectiles import VirusBall
from ..run_state import RunState
from ..scene import Scene


class BossFightScene(Scene):
    def __init__(
        self,
        game,
        player: Player,
        run: RunState,
        chefe_id: str = "balarrals",
    ) -> None:
        super().__init__(game)
        self.player = player
        self.run = run
        self.chefe_id = chefe_id
        self.level = level_mod.arena_balarrals()
        self.camera = Camera(game.balance)
        self.impacto = combat.Impacto(game.balance)
        self.hud = Hud()
        self.projecteis: list[VirusBall] = []
        self.morte = 0.0
        self.vitoria = 0.0
        self.mostrar_caixas = False
        self._respawn()
        self.camera.snap_to(
            self.player.rect.centerx, self.player.rect.centery, self.level
        )

    def _respawn(self) -> None:
        self.player.reviver(self.level.spawn.x, self.level.spawn.y)
        self.projecteis.clear()
        self.morte = 0.0
        cfg = self.game.balance["chefes"][self.chefe_id]
        self.boss = Balarrals(
            self.game.balance,
            self.level.width - 120,
            self.level.chao_em(self.level.width - 120),
        )
        self.retry = float(cfg.get("retry_delay", 1.2))

    def update(self, dt: float) -> None:
        inp = self.game.input

        if self.vitoria > 0.0:
            self.vitoria += dt
            if self.vitoria >= 2.0 or inp.pressed("confirm"):
                self.run.matou_chefe(self.chefe_id)
                from .hub import HubScene

                self.game.set_scene(HubScene(self.game, self.player, self.run))
            return

        if inp.pressed("pause"):
            from .pause import PauseScene

            self.game.push_scene(PauseScene(self.game))
            return

        if inp.pressed("heal"):
            self.mostrar_caixas = not self.mostrar_caixas

        if self.impacto.congelado(dt):
            return
        self.impacto.avancar(dt)

        self.player.update(dt, inp, self.level)
        self.projecteis.extend(self.player.projecteis_novos)
        self.boss.update(dt, self.player.rect.centerx, self.level)

        for bola in self.projecteis:
            bola.update(dt, self.level)
        self.projecteis = [b for b in self.projecteis if b.vivo]

        self._resolver_golpes()
        self._resolver_morte(dt)

        self.hud.update(dt, self.player.health, self.player.max_health)
        self.camera.update(
            dt,
            self.player.rect.centerx,
            self.player.rect.centery,
            self.player.facing,
            self.level,
        )

    def _resolver_golpes(self) -> None:
        if not self.boss.vivo:
            return

        caixa = self.player.caixa_de_acerto()
        if caixa and caixa.colliderect(self.boss.rect) and self.player.registrar_acerto(id(self.boss)):
            matou = self.boss.levar_dano(self.player.dano_atual(), self.player.rect.centerx)
            self.impacto.bater(matou)
            if matou:
                self.vitoria = 0.01

        for bola in self.projecteis:
            if not bola.vivo or id(self.boss) in bola.ja_acertou:
                continue
            if bola.rect.colliderect(self.boss.rect):
                bola.ja_acertou.add(id(self.boss))
                matou = self.boss.levar_dano(bola.dano, bola.rect.centerx)
                self.impacto.bater(matou)
                bola.vivo = False
                if matou:
                    self.vitoria = 0.01
                break

        caixa = self.boss.caixa_de_acerto()
        if caixa and caixa.colliderect(self.player.rect) and not self.boss.ja_acertou:
            if self.boss.fases and self.boss.fases.fase == combat.Fases.ACERTO:
                self.boss.ja_acertou = True
                if self.player.levar_dano(self.boss.dano_atual(), self.boss.rect.centerx):
                    self.hud.marcar_dano()
                    self.impacto.bater(not self.player.vivo)

    def _resolver_morte(self, dt: float) -> None:
        if self.player.vivo:
            self.morte = 0.0
            return
        self.morte += dt
        if self.morte >= self.retry:
            # Retry na porta da arena — bonus e Bytes ficam.
            self._respawn()
            self.hud.fantasma = 1.0

    def draw(self, surface: pygame.Surface) -> None:
        tremor_x, tremor_y = self.impacto.deslocamento()
        cam_x = self.camera.x + tremor_x
        cam_y = self.camera.y + tremor_y

        visual.fundo_patio(surface, cam_x)
        self.level.draw(surface, cam_x, cam_y)
        self.boss.draw(surface, cam_x, cam_y)
        for bola in self.projecteis:
            bola.draw(surface, cam_x, cam_y)
        self.player.draw(surface, cam_x, cam_y)

        self._barra_chefe(surface)
        self.hud.draw(surface, self.player, self.game.font_small)

        cfg = self.game.balance["chefes"][self.chefe_id]
        ui.draw_text(
            surface,
            self.game.font_small,
            cfg["nome"],
            (config.INTERNAL_WIDTH // 2, 8),
            tuple(cfg["cor"]),
            align="center",
        )

        if self.vitoria > 0.0:
            ui.draw_text(
                surface,
                self.game.font_medium,
                "BALARRALS CAIU",
                (config.INTERNAL_WIDTH // 2, 120),
                config.COLOR_ACCENT,
                align="center",
            )
            ui.draw_text(
                surface,
                self.game.font_small,
                "habilidade ESPELHO desbloqueada · enter hub",
                (config.INTERNAL_WIDTH // 2, 148),
                config.COLOR_UI_TEXT_DIM,
                align="center",
            )

        if not self.player.vivo:
            ui.draw_text(
                surface,
                self.game.font_small,
                "retry…",
                (config.INTERNAL_WIDTH // 2, 130),
                config.COLOR_DANO,
                align="center",
            )

    def _barra_chefe(self, surface: pygame.Surface) -> None:
        cfg = self.game.balance["chefes"][self.chefe_id]
        cor = tuple(cfg["cor"])
        w, h = 280, 6
        x = (config.INTERNAL_WIDTH - w) // 2
        y = 22
        frac = self.boss.vida / self.boss.vida_max if self.boss.vida_max else 0.0
        pygame.draw.rect(surface, config.COLOR_UI_SHADOW, (x - 1, y - 1, w + 2, h + 2))
        pygame.draw.rect(surface, config.COLOR_UI_PANEL, (x, y, w, h))
        pygame.draw.rect(surface, cor, (x, y, round(w * max(0.0, frac)), h))

    def debug_lines(self) -> list[str]:
        return [
            f"boss {self.chefe_id}  vida {self.boss.vida:.0f}/{self.boss.vida_max:.0f}",
            f"player {self.player.health:.0f}  bytes {self.player.bytes}",
        ]
