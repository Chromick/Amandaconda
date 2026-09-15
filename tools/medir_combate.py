"""Mede o que os numeros de combate realmente produzem.

Simula o jogador batendo num boneco, em passo fixo e sem abrir janela, e
imprime os valores que vao para docs/NUMEROS.md: duracao de cada golpe, dano,
custo de vigor, quantos golpes cabem num folego e onde exatamente comeca e
acaba a invencibilidade do rolamento.

    .venv\\Scripts\\python.exe tools\\medir_combate.py
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import pygame  # noqa: E402

from src import config  # noqa: E402
from src.balance import Balance  # noqa: E402
from src.dummy import Dummy  # noqa: E402
from src.level import Level  # noqa: E402
from src.player import LIVRE, Player  # noqa: E402

CHAO_Y = 200.0


class Roteiro:
    """Entrada controlada passo a passo pelo teste."""

    def __init__(self) -> None:
        self._held: set[str] = set()
        self._pressed: set[str] = set()
        self._released: set[str] = set()

    def press(self, acao: str) -> None:
        self._pressed.add(acao)
        self._held.add(acao)

    def release(self, acao: str) -> None:
        self._released.add(acao)
        self._held.discard(acao)

    def tick(self) -> None:
        self._pressed.clear()
        self._released.clear()

    def held(self, a: str) -> bool:
        return a in self._held

    def pressed(self, a: str) -> bool:
        return a in self._pressed

    def released(self, a: str) -> bool:
        return a in self._released

    def axis_x(self) -> int:
        return int(self.held("right")) - int(self.held("left"))


def cenario(balance: Balance, distancia: float = 24.0):
    level = Level([pygame.FRect(0, CHAO_Y, 4000, 40)], 4000, 270)
    player = Player(balance, 100.0, CHAO_Y)
    dummy = Dummy(balance, 100.0 + distancia, CHAO_Y)
    inp = Roteiro()
    for _ in range(30):  # assenta no chao
        player.update(config.FIXED_DT, inp, level)
        inp.tick()
    return level, player, dummy, inp


def golpe_isolado(balance: Balance, acao: str, segurar: float = 0.0) -> dict:
    level, player, dummy, inp = cenario(balance)
    vida_antes = dummy.vida
    vigor_antes = player.stamina
    vigor_gasto = None

    inp.press(acao)
    tempo = 0.0
    preparacao = ativo = 0.0
    for passo in range(300):
        if tempo >= segurar:
            inp.release(acao)
        player.update(config.FIXED_DT, inp, level)
        inp.tick()

        # O custo tem que ser lido no instante do gasto: medir no fim daria o
        # saldo depois da regeneracao, que e outra coisa.
        if vigor_gasto is None and player.estado != LIVRE:
            vigor_gasto = vigor_antes - player.stamina

        if player.fases:
            fase = player.fases.fase
            if fase == "preparacao":
                preparacao += config.FIXED_DT
            elif fase == "acerto":
                ativo += config.FIXED_DT

        caixa = player.caixa_de_acerto()
        if caixa and caixa.colliderect(dummy.rect) and player.registrar_acerto(id(dummy)):
            dummy.levar_dano(player.dano_atual(), player.rect.centerx)

        tempo += config.FIXED_DT
        if passo > 2 and player.estado == LIVRE:
            break

    return {
        "duracao": tempo,
        "preparacao": preparacao,
        "acerto": ativo,
        "dano": vida_antes - dummy.vida,
        "vigor": vigor_gasto or 0.0,
    }


def combo(balance: Balance) -> dict:
    """Encadeia ataques leves pedindo o proximo durante a recuperacao."""
    level, player, dummy, inp = cenario(balance)
    vida_antes = dummy.vida
    golpes = 0
    tempo = 0.0

    inp.press("attack")
    for _ in range(600):
        player.update(config.FIXED_DT, inp, level)
        inp.tick()

        caixa = player.caixa_de_acerto()
        if caixa and caixa.colliderect(dummy.rect) and player.registrar_acerto(id(dummy)):
            dummy.levar_dano(player.dano_atual(), player.rect.centerx)
            golpes += 1
            inp.press("attack")  # pede o proximo assim que este conecta

        tempo += config.FIXED_DT
        if player.estado == LIVRE and golpes:
            break

    return {"golpes": golpes, "dano": vida_antes - dummy.vida, "duracao": tempo}


def _protegido_em(balance: Balance, instante: float) -> bool:
    """Rola do zero, para no instante pedido e leva um golpe de verdade.

    Uma simulacao nova por sondagem, em vez de bater no mesmo jogador varias
    vezes: apanhar muda o estado dele, e um teste que estraga o que mede nao
    mede nada.
    """
    level, player, _, inp = cenario(balance)
    inp.press("roll")
    tempo = 0.0
    while tempo < instante:
        player.update(config.FIXED_DT, inp, level)
        inp.tick()
        tempo += config.FIXED_DT

    antes = player.health
    player.levar_dano(1.0, player.rect.centerx + 50)
    return player.health >= antes


def rolamento(balance: Balance) -> dict:
    level, player, _, inp = cenario(balance)
    x0 = player.rect.centerx
    vigor_antes = player.stamina
    vigor_gasto = None

    inp.press("roll")
    tempo = 0.0
    for passo in range(300):
        player.update(config.FIXED_DT, inp, level)
        inp.tick()
        if vigor_gasto is None and player.estado != LIVRE:
            vigor_gasto = vigor_antes - player.stamina
        tempo += config.FIXED_DT
        if passo > 2 and player.estado == LIVRE:
            break

    protegidos = [
        t * config.FIXED_DT
        for t in range(int(tempo / config.FIXED_DT) + 1)
        if _protegido_em(balance, t * config.FIXED_DT)
    ]

    return {
        "duracao": tempo,
        "inv_inicio": protegidos[0] if protegidos else 0.0,
        "inv_fim": protegidos[-1] if protegidos else 0.0,
        "inv_duracao": len(protegidos) * config.FIXED_DT,
        "distancia": abs(player.rect.centerx - x0),
        "vigor": vigor_gasto or 0.0,
    }


def folego(balance: Balance) -> int:
    """Quantos ataques leves cabem antes do vigor acabar."""
    level, player, _, inp = cenario(balance)
    golpes = 0
    for _ in range(1200):
        if player.estado == LIVRE:
            vigor_antes = player.stamina
            inp.press("attack")
            player.update(config.FIXED_DT, inp, level)
            inp.tick()
            if player.stamina < vigor_antes:
                golpes += 1
            elif player.estado == LIVRE:
                break
        else:
            player.update(config.FIXED_DT, inp, level)
            inp.tick()
    return golpes


def main() -> int:
    pygame.init()
    balance = Balance()

    print(f"{'':18} {'total':>7} {'prep':>7} {'acerto':>7} {'dano':>6} {'vigor':>6}")
    for rotulo, acao, segurar in [
        ("ataque leve", "attack", 0.0),
        ("pesado rapido", "heavy", 0.0),
        ("pesado carregado", "heavy", 0.9),
    ]:
        r = golpe_isolado(balance, acao, segurar)
        print(
            f"{rotulo:18} {r['duracao']:6.2f}s {r['preparacao']:6.2f}s "
            f"{r['acerto']:6.2f}s {r['dano']:5.0f} {r['vigor']:5.0f}"
        )

    c = combo(balance)
    print(f"\ncombo leve: {c['golpes']} golpes, {c['dano']:.0f} de dano em {c['duracao']:.2f}s")
    print(f"ataques leves seguidos ate o vigor acabar: {folego(balance)}")

    r = rolamento(balance)
    print(
        f"\nrolamento: {r['duracao']:.2f}s, avanca {r['distancia']:.0f}p, "
        f"custa {r['vigor']:.0f} de vigor"
    )
    print(
        f"invencivel de {r['inv_inicio']:.2f}s a {r['inv_fim']:.2f}s "
        f"({r['inv_duracao']:.2f}s de janela)"
    )

    b = balance["boneco"]
    print(
        f"\ngolpe do boneco: {b['preparacao']:.2f}s de preparacao para "
        f"{b['acerto']:.2f}s de acerto"
    )
    sobra = r["inv_duracao"] - b["acerto"]
    print(f"folga do rolamento contra ele: {sobra:+.2f}s")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
