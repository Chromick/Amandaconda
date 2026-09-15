"""Pecas compartilhadas do combate.

Tres ideias moram aqui:

**Caixa de acerto separada do desenho.** O alcance de um golpe e um retangulo
descrito em balance.json, nao o tamanho do sprite. Sem isso, ajustar alcance
viraria redesenhar arte, e a fase 2 herdaria numeros que nao significam nada.

**Pausa no acerto.** Ao conectar, o jogo inteiro congela por alguns centesimos.
E o truque mais barato que existe para um golpe parecer que pesa, e nenhum
jogo de pancadaria bom vive sem ele.

**Tranco de camera.** Pelo mesmo motivo, e pelo mesmo preco.
"""

from __future__ import annotations

import random

import pygame


class Fases:
    """Onde um golpe esta na propria duracao.

    Preparacao e o unico numero que o jogador realmente le. Janela de acerto e
    quando machuca. Recuperacao e a punicao por ter errado.
    """

    PREPARACAO = "preparacao"
    ACERTO = "acerto"
    RECUPERACAO = "recuperacao"
    FIM = "fim"

    def __init__(self, preparacao: float, acerto: float, recuperacao: float) -> None:
        self.preparacao = preparacao
        self.acerto = acerto
        self.recuperacao = recuperacao
        self.tempo = 0.0

    @property
    def total(self) -> float:
        return self.preparacao + self.acerto + self.recuperacao

    @property
    def fase(self) -> str:
        if self.tempo < self.preparacao:
            return self.PREPARACAO
        if self.tempo < self.preparacao + self.acerto:
            return self.ACERTO
        if self.tempo < self.total:
            return self.RECUPERACAO
        return self.FIM

    @property
    def acabou(self) -> bool:
        return self.tempo >= self.total

    @property
    def tempo_de_recuperacao(self) -> float:
        return max(0.0, self.tempo - self.preparacao - self.acerto)

    def avancar(self, dt: float) -> None:
        self.tempo += dt


def caixa_a_frente(corpo: pygame.FRect, facing: int, alcance: float, altura: float) -> pygame.FRect:
    """Retangulo colado no corpo, do lado para onde a pessoa esta virada."""
    x = corpo.right if facing >= 0 else corpo.left - alcance
    return pygame.FRect(x, corpo.centery - altura / 2, alcance, altura)


class Impacto:
    """Pausa no acerto e tranco de camera, compartilhados pela cena inteira.

    A pausa vale para todo mundo de uma vez: se so o alvo congelasse, o golpe
    pareceria escorregar. E ela nao pode congelar o desenho, so a simulacao.
    """

    def __init__(self, balance) -> None:
        self.balance = balance
        self.pausa = 0.0
        self.tranco = 0.0
        self.tranco_restante = 0.0

    def bater(self, matou: bool = False) -> None:
        cfg = self.balance["impacto"]
        self.pausa = max(
            self.pausa, cfg["pausa_ao_matar"] if matou else cfg["pausa_no_acerto"]
        )
        self.tranco = cfg["tranco"] * (2.0 if matou else 1.0)
        self.tranco_restante = cfg["tranco_duracao"]

    def congelado(self, dt: float) -> bool:
        """Consome o congelamento. Verdadeiro enquanto a simulacao deve parar."""
        if self.pausa <= 0.0:
            return False
        self.pausa -= dt
        return True

    def avancar(self, dt: float) -> None:
        self.tranco_restante = max(0.0, self.tranco_restante - dt)

    def deslocamento(self) -> tuple[int, int]:
        if self.tranco_restante <= 0.0:
            return (0, 0)
        cfg = self.balance["impacto"]
        forca = self.tranco * (self.tranco_restante / cfg["tranco_duracao"])
        return (
            round(random.uniform(-forca, forca)),
            round(random.uniform(-forca, forca)),
        )
