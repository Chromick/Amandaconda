"""Hall central — tres portas + Servidor de backup (Bytes → Patches)."""

from __future__ import annotations

import pygame

from .. import config, ui, visual
from ..player import Player
from ..run_state import RunState
from ..scene import Scene
from ..vitrine import Figura

PORTAS = [
    {"id": "balarrals", "nome": "PATIO", "chefe": "Balarrals", "cor": (124, 132, 148)},
    {"id": "luanevil", "nome": "BANDEJAO", "chefe": "LuanEvil", "cor": config.COLOR_ACCENT},
    {"id": "renanligno", "nome": "LAB", "chefe": "Renanligno", "cor": (47, 103, 150)},
]

# Preview visual no hall (quem ja tem arte).
VITRINE_HUB = [
    ("balarrals", "BALARRALS", 0.9, 70),
    ("luanevil", "LUANEVIL", 0.7, 160),
    ("marlombolico", "MARLOM", 0.75, 270),
    ("amandaconda", "AMANDA", 0.42, 380),
]


class HubScene(Scene):
    def __init__(self, game, player: Player, run: RunState) -> None:
        super().__init__(game)
        self.player = player
        self.run = run
        self.modo = "portas"  # portas | servidor
        self.cursor = ui.MenuCursor(len(PORTAS))
        self.cursor_srv = ui.MenuCursor(0)
        self.msg = ""
        self.msg_t = 0.0
        self.tempo = 0.0
        self.player.curar_completo()
        self._sync_servidor()
        chao = config.INTERNAL_HEIGHT - 50
        self.figuras: list[Figura] = []
        for entidade, label, escala, x in VITRINE_HUB:
            self.figuras.append(
                Figura(entidade, x, chao, label=label, facing=1, escala=escala, anim="auto")
            )

    def _sync_servidor(self) -> None:
        cat = self.game.balance.data.get("patches", {}).get("catalogo", [])
        self.catalogo = cat
        self.cursor_srv = ui.MenuCursor(len(cat))

    def update(self, dt: float) -> None:
        self.tempo += dt
        self.msg_t = max(0.0, self.msg_t - dt)
        for fig in self.figuras:
            fig.update(dt)
        inp = self.game.input

        if self.modo == "servidor":
            self._update_servidor(dt, inp)
            return

        if inp.pressed("pause") or inp.pressed("back"):
            from .pause import PauseScene

            self.game.push_scene(PauseScene(self.game))
            return

        self.cursor.update(dt, inp.held("left") or inp.held("up"), inp.held("right") or inp.held("down"))

        if inp.pressed("confirm"):
            self._abrir_porta(PORTAS[self.cursor.index]["id"])
        # Q / R abre servidor de backup
        if inp.pressed("switch_weapon") or inp.pressed("heal"):
            self.modo = "servidor"
            self._sync_servidor()

    def _update_servidor(self, dt: float, inp) -> None:
        self.cursor_srv.update(dt, inp.held("up"), inp.held("down"))
        if inp.pressed("back"):
            self.modo = "portas"
            return
        if inp.pressed("confirm") and self.catalogo:
            self._comprar(self.catalogo[self.cursor_srv.index])

    def _comprar(self, item: dict) -> None:
        pid = item["id"]
        custo = int(item["custo"])
        slots = int(self.game.balance["patches"]["slots"])
        if pid in self.run.patches_ativos:
            self.msg, self.msg_t = "patch ja ativo", 1.6
            return
        if len(self.run.patches_ativos) >= slots:
            self.msg, self.msg_t = "slots cheios", 1.6
            return
        if self.player.bytes < custo:
            self.msg, self.msg_t = "bytes insuficientes", 1.6
            return
        self.player.bytes -= custo
        self.run.patches_ativos.append(pid)
        self.run.patches_comprados.add(pid)
        self._aplicar_patch(item)
        self.msg, self.msg_t = f"ok {item['nome']}", 1.8

    def _aplicar_patch(self, item: dict) -> None:
        if "vigor_max" in item:
            p = self.player.balance["player"]
            # Ajuste em runtime no objeto player
            self.player.stamina = min(
                self.player.stamina + item["vigor_max"],
                p["max_stamina"] + item["vigor_max"],
            )
            self.player._vigor_bonus = getattr(self.player, "_vigor_bonus", 0) + item["vigor_max"]
        if "dano_mult" in item:
            self.player._patch_dano = getattr(self.player, "_patch_dano", 0.0) + float(item["dano_mult"])
        if "cura_safe_extra" in item:
            self.player.health = min(
                self.player.max_health,
                self.player.health + float(item["cura_safe_extra"]),
            )

    def _abrir_porta(self, chefe_id: str) -> None:
        if chefe_id in self.run.chefes_mortos:
            self.msg, self.msg_t = "porta trancada", 1.4
            return
        if chefe_id != "balarrals":
            self.msg, self.msg_t = "em breve", 1.6
            return
        from .boss_fight import BossFightScene

        self.game.set_scene(BossFightScene(self.game, self.player, self.run, "balarrals"))

    def draw(self, surface: pygame.Surface) -> None:
        visual.fundo_hub(surface, self.tempo)
        # Personagens com arte — fila no chao do hall.
        for fig in self.figuras:
            fig.draw(surface, 0, 0, self.game.font_small)

        cx = config.INTERNAL_WIDTH // 2

        ui.draw_text(
            surface, self.game.font_small, "HALL · CAMPUS NOITE",
            (cx, 16), config.COLOR_UI_TEXT_DIM, align="center",
        )
        ui.draw_text(
            surface, self.game.font_title, "HUB",
            (cx, 32), config.COLOR_ACCENT, align="center",
        )
        ui.draw_text(
            surface, self.game.font_small,
            f"{self.player.formatar_bytes()}  ·  F{self.player.nivel_fisico} E{self.player.nivel_especial}",
            (cx, 74), config.COLOR_UI_TEXT, align="center",
        )

        if self.modo == "servidor":
            self._draw_servidor(surface)
            return

        # Tres portas
        card_w, card_h = 120, 110
        gap = 14
        total = card_w * 3 + gap * 2
        left = (config.INTERNAL_WIDTH - total) // 2
        top = 100
        for i, porta in enumerate(PORTAS):
            x = left + i * (card_w + gap)
            morto = porta["id"] in self.run.chefes_mortos
            sel = i == self.cursor.index
            cor = config.COLOR_UI_TEXT_DIM if morto else (porta["cor"] if sel else config.COLOR_UI_TEXT_DIM)
            card = pygame.Rect(x, top, card_w, card_h)
            ui.draw_card(surface, card, selected=sel and not morto, accent=porta["cor"])
            ui.draw_text(
                surface, self.game.font_small, porta["nome"],
                (x + card_w // 2, top + 14), cor, align="center",
            )
            ui.draw_text(
                surface, self.game.font_medium, porta["chefe"],
                (x + card_w // 2, top + 40), cor, align="center",
            )
            status = "X" if morto else ("OK" if porta["id"] == "balarrals" else "...")
            ui.draw_text(
                surface, self.game.font_small, status,
                (x + card_w // 2, top + 78), cor, align="center",
            )

        ui.draw_text(
            surface, self.game.font_small,
            "enter porta  ·  Q/R servidor  ·  esc pausa",
            (cx, config.INTERNAL_HEIGHT - 18),
            config.COLOR_UI_TEXT_DIM, align="center",
        )
        if self.msg_t > 0:
            ui.draw_text(
                surface, self.game.font_small, self.msg,
                (cx, 88), config.COLOR_ACCENT, align="center",
            )

    def _draw_servidor(self, surface: pygame.Surface) -> None:
        cx = config.INTERNAL_WIDTH // 2
        ui.draw_text(
            surface, self.game.font_medium, "SERVIDOR DE BACKUP",
            (cx, 96), config.COLOR_VIRUS, align="center",
        )
        ui.draw_text(
            surface, self.game.font_small, "patches da playthrough · gasta Bytes",
            (cx, 118), config.COLOR_UI_TEXT_DIM, align="center",
        )

        top = 140
        for i, item in enumerate(self.catalogo):
            sel = i == self.cursor_srv.index
            ativo = item["id"] in self.run.patches_ativos
            cor = config.COLOR_VIRUS if ativo else (config.COLOR_ACCENT if sel else config.COLOR_UI_TEXT_DIM)
            y = top + i * 28
            marca = ">" if sel else " "
            flag = "[ON]" if ativo else f"{item['custo']}KB"
            ui.draw_text(
                surface, self.game.font_small,
                f"{marca} {item['nome']}  {flag}  — {item['texto']}",
                (40, y), cor,
            )

        ui.draw_text(
            surface, self.game.font_small, "enter compra  ·  esc volta",
            (cx, config.INTERNAL_HEIGHT - 18),
            config.COLOR_UI_TEXT_DIM, align="center",
        )
        if self.msg_t > 0:
            ui.draw_text(
                surface, self.game.font_small, self.msg,
                (cx, config.INTERNAL_HEIGHT - 36), config.COLOR_ACCENT, align="center",
            )
