"""Inimigos comuns da sala de risco.

Retangulos por enquanto — a maquina de estados e o que importa. Chatana
incomoda a distancia; Portara e um muro lento. Os dois ensinam a misturar
esquiva e as duas armas.
"""

from __future__ import annotations

import pygame

from . import combat, config, visual
from .balance import Balance


class Inimigo:
    def __init__(self, balance: Balance, secao: str, x: float, y: float) -> None:
        self.balance = balance
        self.secao = secao
        cfg = balance[secao]
        self.rect = pygame.FRect(0, 0, cfg["width"], cfg["height"])
        self.rect.midbottom = (x, y)
        self.inicio = (x, y)
        self.vida_max = float(cfg["vida"])
        self.vida = self.vida_max
        self.espera = float(cfg.get("intervalo", 1.5))
        self.fases: combat.Fases | None = None
        self.piscada = 0.0
        self.recuo = 0.0
        self.facing = -1
        self.ja_acertou = False
        self.tempo_visual = 0.0

    @property
    def vivo(self) -> bool:
        return self.vida > 0.0

    @property
    def cfg(self) -> dict:
        return self.balance[self.secao]

    def update(self, dt: float, alvo_x: float, level) -> None:
        if not self.vivo:
            return
        self.tempo_visual += dt
        self.piscada = max(0.0, self.piscada - dt)
        self.facing = 1 if alvo_x >= self.rect.centerx else -1

        if self.recuo:
            self.rect.x += self.recuo * dt
            self._empurrar_solidos(level)
            self.recuo -= self.recuo * min(1.0, 8.0 * dt)
            if abs(self.recuo) < 2.0:
                self.recuo = 0.0

        self._comportamento(dt, alvo_x, level)

    def _comportamento(self, dt: float, alvo_x: float, level) -> None:
        raise NotImplementedError

    def _comecar_golpe(self) -> None:
        c = self.cfg
        self.fases = combat.Fases(c["preparacao"], c["acerto"], c["recuperacao"])
        self.ja_acertou = False

    def _avancar_golpe(self, dt: float) -> None:
        if self.fases is None:
            return
        self.fases.avancar(dt)
        if self.fases.acabou:
            self.fases = None
            self.espera = float(self.cfg["intervalo"])

    def caixa_de_acerto(self) -> pygame.FRect | None:
        return None

    def levar_dano(self, quanto: float, de_onde_x: float) -> bool:
        self.vida = max(0.0, self.vida - quanto)
        self.piscada = self.balance["impacto"]["piscada"]
        empurrao = self.balance["impacto"]["empurrao_no_alvo"]
        self.recuo = empurrao * (1 if de_onde_x < self.rect.centerx else -1)
        if not self.vivo:
            self.fases = None
            return True
        return False

    def reviver(self) -> None:
        self.vida = self.vida_max
        self.rect.midbottom = self.inicio
        self.espera = float(self.cfg["intervalo"])
        self.fases = None
        self.recuo = 0.0

    def _empurrar_solidos(self, level) -> None:
        for solid in level.solids:
            if not self.rect.colliderect(solid):
                continue
            if self.recuo > 0:
                self.rect.right = solid.left
            else:
                self.rect.left = solid.right

    def draw(self, surface: pygame.Surface, cam_x: float, cam_y: float) -> None:
        if not self.vivo:
            return
        r = pygame.Rect(
            round(self.rect.x - cam_x),
            round(self.rect.y - cam_y),
            round(self.rect.width),
            round(self.rect.height),
        )
        cor = self._cor()
        pygame.draw.rect(surface, cor, r)
        self._barra(surface, r)

    def _cor(self) -> tuple[int, int, int]:
        if self.piscada > 0.0:
            return config.COLOR_UI_TEXT
        if self.fases is not None:
            if self.fases.fase == combat.Fases.PREPARACAO:
                return config.COLOR_PREPARACAO
            if self.fases.fase == combat.Fases.ACERTO:
                return config.COLOR_DANO
        return config.COLOR_INIMIGO

    def _barra(self, surface: pygame.Surface, r: pygame.Rect) -> None:
        largura = max(16, r.width + 6)
        x = r.centerx - largura // 2
        y = r.top - 6
        pygame.draw.rect(surface, config.COLOR_UI_SHADOW, (x, y, largura, 2))
        pygame.draw.rect(
            surface, config.COLOR_DANO, (x, y, round(largura * self.vida / self.vida_max), 2)
        )


class Chatana(Inimigo):
    """Fica no lugar e grita: dano em area quando a 'sirene' dispara."""

    def __init__(self, balance: Balance, x: float, y: float) -> None:
        super().__init__(balance, "chatana", x, y)

    def _comportamento(self, dt: float, alvo_x: float, level) -> None:
        if self.fases is None:
            self.espera -= dt
            if self.espera <= 0.0:
                self._comecar_golpe()
            return
        self._avancar_golpe(dt)

    def caixa_de_acerto(self) -> pygame.FRect | None:
        if self.fases is None or self.fases.fase != combat.Fases.ACERTO:
            return None
        if self.ja_acertou:
            return None
        raio = self.cfg["raio"]
        return pygame.FRect(
            self.rect.centerx - raio,
            self.rect.centery - raio,
            raio * 2,
            raio * 2,
        )

    def draw(self, surface: pygame.Surface, cam_x: float, cam_y: float) -> None:
        if not self.vivo:
            return
        r = pygame.Rect(
            round(self.rect.x - cam_x),
            round(self.rect.y - cam_y),
            round(self.rect.width),
            round(self.rect.height),
        )
        fase = self.fases.fase if self.fases else None
        if self.piscada > 0.0:
            pygame.draw.rect(surface, config.COLOR_UI_TEXT, r)
        else:
            visual.chatana(surface, r, fase, self.tempo_visual)
        self._barra(surface, r)


class Portara(Inimigo):
    """Anda devagar ate voce e esmurra. Muro com pernas."""

    def __init__(self, balance: Balance, x: float, y: float) -> None:
        super().__init__(balance, "portara", x, y)

    def _comportamento(self, dt: float, alvo_x: float, level) -> None:
        if self.fases is not None:
            self._avancar_golpe(dt)
            return

        dist = abs(alvo_x - self.rect.centerx)
        if dist > self.cfg["alcance"] * 0.85:
            passo = self.facing * self.cfg["velocidade"] * dt
            self.rect.x += passo
            self._empurrar_solidos(level)
        else:
            self.espera -= dt
            if self.espera <= 0.0:
                self._comecar_golpe()

    def caixa_de_acerto(self) -> pygame.FRect | None:
        if self.fases is None or self.fases.fase != combat.Fases.ACERTO:
            return None
        if self.ja_acertou:
            return None
        c = self.cfg
        return combat.caixa_a_frente(self.rect, self.facing, c["alcance"], c["altura"])

    def draw(self, surface: pygame.Surface, cam_x: float, cam_y: float) -> None:
        if not self.vivo:
            return
        r = pygame.Rect(
            round(self.rect.x - cam_x),
            round(self.rect.y - cam_y),
            round(self.rect.width),
            round(self.rect.height),
        )
        fase = self.fases.fase if self.fases else None
        if self.piscada > 0.0:
            pygame.draw.rect(surface, config.COLOR_UI_TEXT, r)
        else:
            visual.portara(surface, r, self.facing, fase)
        self._barra(surface, r)
