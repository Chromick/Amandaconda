"""Entrada por acao, nao por tecla.

O resto do jogo nunca pergunta "a tecla D esta pressionada", pergunta "a acao
andar_direita esta ativa". Isso permite remapear e adicionar controle depois
sem tocar na logica.
"""

from __future__ import annotations

import pygame

BINDINGS: dict[str, tuple[int, ...]] = {
    "left": (pygame.K_a, pygame.K_LEFT),
    "right": (pygame.K_d, pygame.K_RIGHT),
    "up": (pygame.K_w, pygame.K_UP),
    "down": (pygame.K_s, pygame.K_DOWN),
    "jump": (pygame.K_SPACE,),
    "run": (pygame.K_LSHIFT, pygame.K_RSHIFT),
    "roll": (pygame.K_LCTRL, pygame.K_k),
    "attack": (pygame.K_j,),
    "heavy": (pygame.K_l,),
    "heal": (pygame.K_r,),
    "confirm": (pygame.K_RETURN, pygame.K_KP_ENTER, pygame.K_SPACE),
    "back": (pygame.K_ESCAPE, pygame.K_BACKSPACE),
    "pause": (pygame.K_ESCAPE, pygame.K_p),
}

_KEY_TO_ACTIONS: dict[int, list[str]] = {}
for _action, _keys in BINDINGS.items():
    for _key in _keys:
        _KEY_TO_ACTIONS.setdefault(_key, []).append(_action)


class Input:
    def __init__(self) -> None:
        self._held: set[str] = set()
        self._pending_pressed: set[str] = set()
        self._pending_released: set[str] = set()
        self._pressed: set[str] = set()
        self._released: set[str] = set()

    def handle_event(self, event: pygame.event.Event) -> None:
        if event.type == pygame.KEYDOWN:
            for action in _KEY_TO_ACTIONS.get(event.key, ()):
                self._held.add(action)
                self._pending_pressed.add(action)
        elif event.type == pygame.KEYUP:
            for action in _KEY_TO_ACTIONS.get(event.key, ()):
                self._held.discard(action)
                self._pending_released.add(action)

    def begin_tick(self) -> None:
        """Um toque pertence a exatamente um passo de simulacao.

        Como o desenho roda mais rapido que os 60 Hz da logica, os toques ficam
        acumulados ate um passo consumi-los. Sem isso, apertar e soltar entre
        dois passos perderia o input.
        """
        self._pressed = self._pending_pressed
        self._released = self._pending_released
        self._pending_pressed = set()
        self._pending_released = set()

    def held(self, action: str) -> bool:
        return action in self._held

    def pressed(self, action: str) -> bool:
        return action in self._pressed

    def released(self, action: str) -> bool:
        return action in self._released

    def axis_x(self) -> int:
        return int(self.held("right")) - int(self.held("left"))
