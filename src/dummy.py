"""Boneco de treino da semana 2.

Ele nao anda e nao persegue. Faz uma coisa so: um golpe lento, num intervalo
fixo, com uma preparacao longa e bem visivel.

Podia ser totalmente passivo, e o plano dizia "boneco parado". Mas janela de
invencibilidade nao se ajusta contra um alvo que nao ataca — e preciso ter de
que ser invencivel. Este unico golpe e o minimo para que o rolamento possa ser
regulado, e ja e o esqueleto do que vira maquina de estados de chefe na
semana 3.
"""

from __future__ import annotations

import pygame

from . import combat, config, visual
from .balance import Balance


class Dummy:
    def __init__(self, balance: Balance, x: float, y: float) -> None:
        self.balance = balance
        b = balance["boneco"]
        self.rect = pygame.FRect(0, 0, b["width"], b["height"])
        self.rect.midbottom = (x, y)
        self.inicio = (x, y)

        self.vida_max = float(b["vida"])
        self.vida = self.vida_max
        self.espera = b["intervalo_do_golpe"]
        self.fases: combat.Fases | None = None
        self.piscada = 0.0
        self.recuo = 0.0
        self.morto_ha = 0.0
        self.ja_acertou = False

    @property
    def vivo(self) -> bool:
        return self.vida > 0.0

    @property
    def facing(self) -> int:
        return self._facing

    def update(self, dt: float, alvo_x: float) -> None:
        b = self.balance["boneco"]
        self.piscada = max(0.0, self.piscada - dt)

        if not self.vivo:
            self.morto_ha += dt
            if self.morto_ha >= b["renascer_em"]:
                self.reviver()
            return

        self._facing = 1 if alvo_x >= self.rect.centerx else -1

        # O empurrao do golpe recebido some sozinho: e reacao, nao movimento.
        if self.recuo:
            self.rect.x += self.recuo * dt
            self.recuo -= self.recuo * min(1.0, 8.0 * dt)
            if abs(self.recuo) < 2.0:
                self.recuo = 0.0

        if not b["revida"]:
            return

        if self.fases is None:
            self.espera -= dt
            if self.espera <= 0.0:
                self.fases = combat.Fases(
                    b["preparacao"], b["acerto"], b["recuperacao"]
                )
                self.ja_acertou = False
            return

        self.fases.avancar(dt)
        if self.fases.acabou:
            self.fases = None
            self.espera = b["intervalo_do_golpe"]

    @property
    def atacando_agora(self) -> bool:
        return self.fases is not None and self.fases.fase == combat.Fases.ACERTO

    def caixa_de_acerto(self) -> pygame.FRect | None:
        if not self.atacando_agora or self.ja_acertou:
            return None
        b = self.balance["boneco"]
        return combat.caixa_a_frente(
            self.rect, self._facing, b["alcance"], b["altura"]
        )

    def levar_dano(self, quanto: float, de_onde_x: float) -> bool:
        """Devolve verdadeiro se este golpe matou."""
        self.vida = max(0.0, self.vida - quanto)
        self.piscada = self.balance["impacto"]["piscada"]
        empurrao = self.balance["impacto"]["empurrao_no_alvo"]
        self.recuo = empurrao * (1 if de_onde_x < self.rect.centerx else -1)
        if not self.vivo:
            self.morto_ha = 0.0
            self.fases = None
            return True
        return False

    def reviver(self) -> None:
        self.vida = self.vida_max
        self.rect.midbottom = self.inicio
        self.espera = self.balance["boneco"]["intervalo_do_golpe"]
        self.fases = None
        self.recuo = 0.0

    _facing = -1

    def draw(self, surface: pygame.Surface, cam_x: float, cam_y: float) -> None:
        if not self.vivo:
            return

        r = pygame.Rect(
            round(self.rect.x - cam_x),
            round(self.rect.y - cam_y),
            round(self.rect.width),
            round(self.rect.height),
        )

        cor = config.COLOR_INIMIGO
        if self.piscada > 0.0:
            cor = config.COLOR_UI_TEXT
        elif self.fases is not None:
            if self.fases.fase == combat.Fases.PREPARACAO:
                cor = config.COLOR_PREPARACAO
            elif self.fases.fase == combat.Fases.ACERTO:
                cor = config.COLOR_DANO
        visual.boneco(surface, r, self._facing, cor)

        self._barra_de_vida(surface, r)
        self._marca_de_preparacao(surface, r)

    def _barra_de_vida(self, surface: pygame.Surface, r: pygame.Rect) -> None:
        largura = r.width + 10
        x = r.centerx - largura // 2
        y = r.top - 7
        pygame.draw.rect(surface, config.COLOR_UI_SHADOW, (x, y, largura, 3))
        cheio = round(largura * (self.vida / self.vida_max))
        pygame.draw.rect(surface, config.COLOR_DANO, (x, y, cheio, 3))

    def _marca_de_preparacao(self, surface: pygame.Surface, r: pygame.Rect) -> None:
        """Barra que enche durante a preparacao.

        Provisorio: na semana 3 quem avisa e a animacao do chefe. Ate la, isso
        e o que permite julgar se a preparacao esta longa o bastante.
        """
        if self.fases is None or self.fases.fase != combat.Fases.PREPARACAO:
            return
        progresso = self.fases.tempo / self.fases.preparacao
        largura = r.width + 10
        x = r.centerx - largura // 2
        pygame.draw.rect(surface, config.COLOR_UI_SHADOW, (x, r.top - 13, largura, 3))
        pygame.draw.rect(
            surface,
            config.COLOR_PREPARACAO,
            (x, r.top - 13, round(largura * progresso), 3),
        )
