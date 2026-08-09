"""Mede o que os numeros de data/balance.json realmente produzem.

Simula o jogador em passo fixo, sem abrir janela, e imprime altura de pulo,
tempo no ar e alcance. Serve para saber se o ajuste bateu no alvo sem precisar
sentir no olho, e para preencher docs/NUMEROS.md com valor medido.

    .venv\\Scripts\\python.exe tools\\medir_pulo.py
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import pygame  # noqa: E402

from src import config  # noqa: E402
from src.balance import Balance  # noqa: E402
from src.level import Level  # noqa: E402
from src.player import Player  # noqa: E402


class FakeInput:
    """Entrada roteirizada: o teste segura as teclas que quisermos."""

    def __init__(self, held: set[str]) -> None:
        self._held = held
        self._pressed: set[str] = set()
        self._released: set[str] = set()

    def press(self, action: str) -> None:
        self._pressed = {action}
        self._held.add(action)

    def release(self, action: str) -> None:
        self._released = {action}
        self._held.discard(action)

    def clear_edges(self) -> None:
        self._pressed = set()
        self._released = set()

    def held(self, action: str) -> bool:
        return action in self._held

    def pressed(self, action: str) -> bool:
        return action in self._pressed

    def released(self, action: str) -> bool:
        return action in self._released

    def axis_x(self) -> int:
        return int(self.held("right")) - int(self.held("left"))


def flat_ground() -> Level:
    """Chao liso e comprido: o teste mede o pulo, nao a sala de teste."""
    return Level([pygame.FRect(0, 200, 4000, 40)], 4000, 270)


def simulate(balance: Balance, hold: set[str], cut_after: float | None = None) -> dict:
    level = flat_ground()
    player = Player(balance, 60.0, 200.0)
    inp = FakeInput(set(hold))

    # Um instante no chao para a velocidade horizontal estabilizar antes do pulo.
    for _ in range(60):
        player.update(config.FIXED_DT, inp, level)
        inp.clear_edges()

    start_y, start_x = player.rect.bottom, player.rect.centerx
    inp.press("jump")

    peak = 0.0
    apex_time = 0.0
    airtime = 0.0
    for step in range(600):
        player.update(config.FIXED_DT, inp, level)
        inp.clear_edges()
        airtime += config.FIXED_DT

        height = start_y - player.rect.bottom
        if height > peak:
            peak, apex_time = height, airtime

        if cut_after is not None and abs(airtime - cut_after) < config.FIXED_DT / 2:
            inp.release("jump")

        if player.on_ground and step > 2:
            break

    return {
        "altura": peak,
        "tempo_ate_o_topo": apex_time,
        "tempo_no_ar": airtime,
        "alcance": abs(player.rect.centerx - start_x),
        "velocidade": abs(player.vel.x),
    }


def main() -> int:
    pygame.init()
    # Aceita outro arquivo no argumento para comparar dois ajustes lado a lado.
    balance = Balance(Path(sys.argv[1])) if len(sys.argv) > 1 else Balance()
    p = balance["player"]

    print(f"jogador {p['width']}x{p['height']} px\n")

    casos = [
        ("parado, pulo cheio", set(), None),
        ("parado, pulo curto", set(), 0.08),
        ("andando", {"right"}, None),
        ("correndo", {"right", "run"}, None),
    ]

    print(f"{'':22} {'altura':>8} {'topo':>7} {'no ar':>7} {'alcance':>8} {'vel':>6}")
    for label, hold, cut in casos:
        r = simulate(balance, hold, cut)
        print(
            f"{label:22} {r['altura']:7.1f}p {r['tempo_ate_o_topo']:6.2f}s "
            f"{r['tempo_no_ar']:6.2f}s {r['alcance']:7.1f}p {r['velocidade']:5.0f}"
        )

    full = simulate(balance, set(), None)
    print(f"\naltura do pulo em corpos do jogador: {full['altura'] / p['height']:.2f}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
