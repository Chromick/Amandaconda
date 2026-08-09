"""Carrega as folhas de sprite descritas em data/sprites.json.

Tudo aqui e tolerante a arte que ainda nao existe. Enquanto o desenho nao
chega, quem pergunta por um quadro recebe None e desenha o retangulo de
sempre. E o que permite trocar a arte peca por peca, sem parar o jogo e sem
um unico "if" espalhado pelo codigo.

Convencoes, iguais as de docs/ARTE.md:
  - a base do canvas e o chao, o corpo fica centrado na largura
  - tudo e desenhado virado para a direita; o espelho e feito aqui, uma vez
"""

from __future__ import annotations

import json
from pathlib import Path

import pygame

RAIZ = Path(__file__).resolve().parent.parent
SPEC_PATH = RAIZ / "data" / "sprites.json"
SPRITES_DIR = RAIZ / "assets" / "sprites"

DURACAO_MINIMA = 0.01


class Animation:
    def __init__(self, direita: list[pygame.Surface], duracao: float) -> None:
        self.direita = direita
        self.esquerda = [pygame.transform.flip(f, True, False) for f in direita]
        self.duracao = max(duracao, DURACAO_MINIMA)

    def __len__(self) -> int:
        return len(self.direita)

    def quadro(self, indice: int, facing: int) -> pygame.Surface:
        lado = self.direita if facing >= 0 else self.esquerda
        return lado[indice % len(lado)]


class SpriteSet:
    """As animacoes de uma entidade que ja tem arquivo em disco."""

    def __init__(self, nome: str, spec: dict) -> None:
        self.nome = nome
        self.canvas = tuple(spec["canvas"])
        self.animacoes: dict[str, Animation] = {}

        for anim, info in spec.get("animacoes", {}).items():
            caminho = SPRITES_DIR / nome / f"{anim}.png"
            if not caminho.exists():
                continue
            folha = pygame.image.load(str(caminho)).convert_alpha()
            quadros = self._fatiar(folha, info["quadros"])
            if quadros:
                self.animacoes[anim] = Animation(quadros, info["duracao"])

    def _fatiar(self, folha: pygame.Surface, pedidos: int) -> list[pygame.Surface]:
        largura, altura = self.canvas
        # Nunca fatia alem do que a folha tem, mesmo que o json prometa mais.
        cabem = min(pedidos, folha.get_width() // largura)
        return [
            folha.subsurface(pygame.Rect(i * largura, 0, largura, altura)).copy()
            for i in range(cabem)
        ]

    def get(self, nome: str) -> Animation | None:
        """Cai para 'parado', e depois para qualquer uma, se a pedida faltar.

        Assim o jogador desenhado andando ja aparece em pe, correndo e caindo,
        em vez de sumir toda vez que muda de estado.
        """
        if nome in self.animacoes:
            return self.animacoes[nome]
        if "parado" in self.animacoes:
            return self.animacoes["parado"]
        return next(iter(self.animacoes.values()), None)


class Animator:
    """Guarda o nome da entidade, nao a folha.

    E isso que faz o F5 funcionar para arte: quando as folhas sao recarregadas,
    todo animador em jogo se reaponta sozinho no quadro seguinte, sem ninguem
    precisar recriar o jogador.
    """

    def __init__(self, entidade: str) -> None:
        self.entidade = entidade
        self.nome: str | None = None
        self.atual: Animation | None = None
        self.geracao = -1
        self.indice = 0
        self.tempo = 0.0

    def _sincronizar(self) -> None:
        if self.geracao == _geracao:
            return
        self.geracao = _geracao
        conjunto = get(self.entidade)
        self.atual = conjunto.get(self.nome) if conjunto and self.nome else None
        self.indice = 0
        self.tempo = 0.0

    def play(self, nome: str) -> None:
        self._sincronizar()
        if nome == self.nome:
            return
        self.nome = nome
        proxima = get(self.entidade)
        proxima = proxima.get(nome) if proxima else None
        if proxima is not self.atual:
            self.atual = proxima
            self.indice = 0
            self.tempo = 0.0

    def travar_quadro(self, indice: int) -> None:
        """Para animacoes que escolhem o quadro pelo estado, nao pelo relogio."""
        if self.atual:
            self.indice = indice % len(self.atual)
            self.tempo = 0.0

    def update(self, dt: float) -> None:
        if not self.atual:
            return
        self.tempo += dt
        while self.tempo >= self.atual.duracao:
            self.tempo -= self.atual.duracao
            self.indice = (self.indice + 1) % len(self.atual)

    def image(self, facing: int) -> pygame.Surface | None:
        if not self.atual:
            return None
        return self.atual.quadro(self.indice, facing)


_conjuntos: dict[str, SpriteSet] = {}
_geracao = 0


def carregar() -> None:
    """Le a especificacao e carrega o que existir. Precisa do video iniciado."""
    global _geracao
    _conjuntos.clear()
    _geracao += 1
    try:
        with SPEC_PATH.open(encoding="utf-8") as f:
            spec = json.load(f)
    except (OSError, json.JSONDecodeError):
        return

    for nome, dados in spec.items():
        if nome.startswith("_") or "animacoes" not in dados:
            continue
        conjunto = SpriteSet(nome, dados)
        if conjunto.animacoes:
            _conjuntos[nome] = conjunto


def get(nome: str) -> SpriteSet | None:
    return _conjuntos.get(nome)


def resumo() -> str:
    if not _conjuntos:
        return "sprites: nenhum, usando retangulos"
    partes = [f"{n}:{len(c.animacoes)}" for n, c in _conjuntos.items()]
    return "sprites: " + " ".join(partes)
