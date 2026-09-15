from __future__ import annotations

import random

import pygame

from .. import combat, config, gen_mapa, ui, visual
from ..camera import Camera
from ..dummy import Dummy
from ..enemies import Chatana, Portara
from ..hud import Hud
from .. import pickups
from ..pickups import Pendrive
from ..player import Player
from ..projectiles import VirusBall
from ..run_state import RunState
from ..scene import Scene
from ..vitrine import Figura, vitrine_fase1


class PlayScene(Scene):
    def __init__(
        self,
        game,
        escola: str = "teclado",
        *,
        player: Player | None = None,
        run: RunState | None = None,
    ) -> None:
        super().__init__(game)
        # Layout sorteado com regras de pulo; mesma sala no respawn da morte.
        self.level = gen_mapa.gerar_risco(game.balance.data)
        self.run = run or RunState(escola=escola)
        if player is None:
            self.player = Player(game.balance, self.level.spawn.x, self.level.spawn.y)
            self.player.escolher_escola(escola)
        else:
            self.player = player
            self.player.reviver(self.level.spawn.x, self.level.spawn.y)
        self.camera = Camera(game.balance)
        self.impacto = combat.Impacto(game.balance)
        self.hud = Hud()
        self.mostrar_caixas = False
        self.morte = 0.0
        self.na_safe = False
        self.aviso_safe = 0.0
        self.escolha_pendrive: Pendrive | None = None
        self.cursor_pendrive = 0

        self.inimigos: list = []
        self.pendrives: list[Pendrive] = []
        self.projecteis: list[VirusBall] = []
        self.dummy: Dummy | None = None
        self.figuras: list[Figura] = []
        self._montar_sala()

        self.camera.snap_to(
            self.player.rect.centerx, self.player.rect.centery, self.level
        )

    def _montar_sala(self) -> None:
        self.inimigos.clear()
        self.pendrives.clear()
        self.projecteis.clear()
        self.escolha_pendrive = None

        for tipo, x in self.level.spawns_inimigo:
            y = self.level.chao_em(x)
            if tipo == "chatana":
                self.inimigos.append(Chatana(self.game.balance, x, y - 40))
            elif tipo == "portara":
                self.inimigos.append(Portara(self.game.balance, x, y))

        for x in self.level.spawns_pendrive:
            self.pendrives.append(Pendrive(x, self.level.chao_em(x)))

        if self.level.spawn_boneco is not None:
            x = self.level.spawn_boneco
            self.dummy = Dummy(
                self.game.balance, x, self.level.chao_em(x, self.level.spawn.y)
            )
        else:
            self.dummy = None

        # Personagens com sprite ja importado — vitrine na safezone.
        chao = float(self.level.height - 32)
        if self.level.safezone is not None:
            x0 = self.level.safezone.x + 40
            self.figuras = vitrine_fase1(chao, x0=x0)
        else:
            self.figuras = []

    def update(self, dt: float) -> None:
        inp = self.game.input

        if self.escolha_pendrive is not None:
            self._atualizar_escolha_pendrive(inp)
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
        self.aviso_safe = max(0.0, self.aviso_safe - dt)

        self.player.update(dt, inp, self.level)
        self.projecteis.extend(self.player.projecteis_novos)

        alvo_x = self.player.rect.centerx
        for inimigo in self.inimigos:
            inimigo.update(dt, alvo_x, self.level)
        if self.dummy is not None:
            self.dummy.update(dt, alvo_x)

        for bola in self.projecteis:
            bola.update(dt, self.level)
        self.projecteis = [b for b in self.projecteis if b.vivo]

        for pendrive in self.pendrives:
            pendrive.update(dt)
            if pendrive.vivo and pendrive.rect.colliderect(self.player.rect):
                self.escolha_pendrive = pendrive
                self.cursor_pendrive = 0 if self.player.arma == "teclado" else 1
                break

        for fig in self.figuras:
            fig.update(dt)

        self._resolver_safezone()
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

    def _atualizar_escolha_pendrive(self, inp) -> None:
        if inp.pressed("left") or inp.pressed("up"):
            self.cursor_pendrive = 0
        if inp.pressed("right") or inp.pressed("down"):
            self.cursor_pendrive = 1
        if inp.pressed("confirm"):
            escola = "fisico" if self.cursor_pendrive == 0 else "especial"
            self.player.aplicar_pendrive(escola)
            self.escolha_pendrive.vivo = False
            self.escolha_pendrive = None
        if inp.pressed("back"):
            # Esc nao descarta o pendrive — so cancela se afastar? Melhor forcar escolha.
            pass

    def _dropar_bytes(self, alvo) -> None:
        """Comuns dropam Bytes; boneco de treino nao."""
        secao = getattr(alvo, "secao", None)
        tabela = self.game.balance.data.get("bytes", {})
        faixa = tabela.get(secao)
        if not faixa or len(faixa) < 2:
            return
        self.player.ganhar_bytes(random.randint(int(faixa[0]), int(faixa[1])))

    def _resolver_safezone(self) -> None:
        dentro = self.level.na_safezone(self.player.rect)
        if dentro and not self.na_safe:
            self.player.curar_completo()
            self.aviso_safe = 2.2
        self.na_safe = dentro

        # Porta no fim da safezone → hub (W/↑ ou Enter).
        if (
            dentro
            and self.level.na_saida_hub(self.player.rect)
            and (
                self.game.input.pressed("up")
                or self.game.input.pressed("confirm")
            )
        ):
            from .hub import HubScene

            self.game.set_scene(HubScene(self.game, self.player, self.run))

    def _resolver_golpes(self) -> None:
        alvos = [i for i in self.inimigos if i.vivo]
        if self.dummy is not None and self.dummy.vivo:
            alvos.append(self.dummy)

        caixa = self.player.caixa_de_acerto()
        if caixa:
            for alvo in alvos:
                if caixa.colliderect(alvo.rect) and self.player.registrar_acerto(id(alvo)):
                    matou = alvo.levar_dano(self.player.dano_atual(), self.player.rect.centerx)
                    self.impacto.bater(matou)
                    if matou:
                        self._dropar_bytes(alvo)

        for bola in self.projecteis:
            if not bola.vivo:
                continue
            for alvo in alvos:
                if id(alvo) in bola.ja_acertou:
                    continue
                if bola.rect.colliderect(alvo.rect):
                    bola.ja_acertou.add(id(alvo))
                    matou = alvo.levar_dano(bola.dano, bola.rect.centerx)
                    self.impacto.bater(matou)
                    if matou:
                        self._dropar_bytes(alvo)
                    bola.vivo = False
                    break

        for inimigo in self.inimigos:
            if not inimigo.vivo:
                continue
            caixa = inimigo.caixa_de_acerto()
            if caixa and caixa.colliderect(self.player.rect):
                # Marca o hit na hora: senão a janela longa da Chatana acerta
                # de novo no fim da invencibilidade do rolamento.
                inimigo.ja_acertou = True
                if self.player.levar_dano(inimigo.cfg["dano"], inimigo.rect.centerx):
                    self.hud.marcar_dano()
                    self.impacto.bater(not self.player.vivo)

        if self.dummy is not None:
            caixa = self.dummy.caixa_de_acerto()
            if caixa and caixa.colliderect(self.player.rect):
                self.dummy.ja_acertou = True
                dano = self.game.balance["boneco"]["dano"]
                if self.player.levar_dano(dano, self.dummy.rect.centerx):
                    self.hud.marcar_dano()
                    self.impacto.bater(not self.player.vivo)

    def _resolver_morte(self, dt: float) -> None:
        if self.player.vivo:
            self.morte = 0.0
            return
        self.morte += dt
        if self.morte >= 1.4:
            # Sala de risco: inimigos e pendrives nao pegos voltam; bonus fica.
            self.player.reviver(self.level.spawn.x, self.level.spawn.y)
            self._montar_sala()
            self.na_safe = False
            self.hud.fantasma = 1.0
            self.morte = 0.0

    def draw(self, surface: pygame.Surface) -> None:
        tremor_x, tremor_y = self.impacto.deslocamento()
        cam_x = self.camera.x + tremor_x
        cam_y = self.camera.y + tremor_y

        visual.fundo_faculdade(surface, cam_x, self.level.width)
        self.level.draw(surface, cam_x, cam_y)
        if self.level.safezone is not None:
            zona = pygame.Rect(
                round(self.level.safezone.x - cam_x),
                round(self.level.safezone.y - cam_y),
                round(self.level.safezone.width),
                round(self.level.safezone.height),
            )
            visual.safezone_placa(surface, zona)

        for pendrive in self.pendrives:
            pendrive.draw(surface, cam_x, cam_y, self.game.font_small)
        for fig in self.figuras:
            fig.draw(surface, cam_x, cam_y, self.game.font_small)
        for inimigo in self.inimigos:
            inimigo.draw(surface, cam_x, cam_y)
        if self.dummy is not None:
            self.dummy.draw(surface, cam_x, cam_y)
        for bola in self.projecteis:
            bola.draw(surface, cam_x, cam_y)
        self.player.draw(surface, cam_x, cam_y)

        if self.mostrar_caixas:
            self._desenhar_caixas(surface, cam_x, cam_y)

        if self.aviso_safe > 0.0:
            ui.draw_text(
                surface,
                self.game.font_medium,
                "[ SAFEZONE ]",
                (config.INTERNAL_WIDTH // 2, 36),
                config.COLOR_SAFEZONE_TOP,
                align="center",
            )
            ui.draw_text(
                surface,
                self.game.font_small,
                "cura cheia · vitrine dos chefes · W/enter → HUB",
                (config.INTERNAL_WIDTH // 2, 58),
                config.COLOR_UI_TEXT_DIM,
                align="center",
            )

        if self.na_safe and self.level.saida_hub is not None:
            porta = self.level.saida_hub
            pr = pygame.Rect(
                round(porta.x - cam_x),
                round(porta.y - cam_y),
                round(porta.width),
                round(porta.height),
            )
            visual.porta_hub(surface, pr, self.player.tempo_visual)
            ui.draw_text(
                surface,
                self.game.font_small,
                "HUB",
                (pr.centerx, pr.top - 12),
                config.COLOR_ACCENT,
                align="center",
                shadow=False,
            )

        self.hud.draw(surface, self.player, self.game.font_small)

        if self.escolha_pendrive is not None:
            pickups.desenhar_escolha(
                surface,
                self.game.font_medium,
                self.game.font_small,
                self.cursor_pendrive,
            )

    def _desenhar_caixas(self, surface: pygame.Surface, cam_x: float, cam_y: float) -> None:
        def contorno(caixa, cor):
            if caixa is None:
                return
            pygame.draw.rect(
                surface,
                cor,
                pygame.Rect(
                    round(caixa.x - cam_x),
                    round(caixa.y - cam_y),
                    round(caixa.width),
                    round(caixa.height),
                ),
                1,
            )

        contorno(self.player.rect, config.COLOR_CAIXA_CORPO)
        contorno(self.player.caixa_de_acerto(), config.COLOR_CAIXA_ACERTO)
        for inimigo in self.inimigos:
            if inimigo.vivo:
                contorno(inimigo.rect, config.COLOR_CAIXA_CORPO)
                contorno(inimigo.caixa_de_acerto(), config.COLOR_DANO)
        if self.dummy is not None and self.dummy.vivo:
            contorno(self.dummy.rect, config.COLOR_CAIXA_CORPO)
            contorno(self.dummy.caixa_de_acerto(), config.COLOR_DANO)

    def debug_lines(self) -> list[str]:
        p = self.player
        fase = p.fases.fase if p.fases else "-"
        vivos = sum(1 for i in self.inimigos if i.vivo)
        return [
            f"estado {p.estado} {fase}  escola {p.arma}",
            f"vida {p.health:5.1f}/{p.max_health:5.1f}  vigor {p.stamina:5.1f}",
            f"niveis F{p.nivel_fisico} E{p.nivel_especial}  mult {p.multiplicador_dano:.2f}  inimigos {vivos}",
            "J leve   L pesado   K rola   R caixas",
        ]
