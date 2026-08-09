"""Descoberta da tela e escolha do modo de video.

O jogo desenha sempre em 480x270 e depois amplia por um numero inteiro. Quem
decide esse numero e a resolucao real do monitor, entao ela precisa ser
descoberta certa. Ver enable_dpi_awareness para o porque de "certa" dar
trabalho no Windows.
"""

from __future__ import annotations

import ctypes
import sys

import pygame

from . import config

# Espaco que a barra de titulo e a barra de tarefas roubam. Sem essa folga, a
# maior janela "que cabe" nasce com a parte de baixo atras da barra de tarefas.
WINDOW_MARGIN_Y = 110

FALLBACK_SIZE = (config.INTERNAL_WIDTH * 3, config.INTERNAL_HEIGHT * 3)


DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 = -4
PROCESS_PER_MONITOR_DPI_AWARE = 2
S_OK = 0


def enable_dpi_awareness() -> bool:
    """Faz o Windows entregar a resolucao real do monitor, nao a encolhida.

    Com a escala do sistema em 150%, um monitor 1920x1080 e anunciado como
    1280x720 para quem nao declara entender DPI. O jogo desenharia em 1280x720
    e o Windows esticaria para 1920x1080 por cima, borrando justamente a arte
    que existe para ser vista pixel a pixel.

    As tres chamadas sao a mesma coisa em versoes diferentes do Windows, da
    mais nova para a mais velha. Nenhuma delas levanta excecao quando falha,
    so devolve falso, entao o retorno tem que ser conferido na mao.

    Precisa rodar antes de pygame.init().
    """
    if sys.platform != "win32":
        return False

    user32 = ctypes.windll.user32

    try:
        fn = user32.SetProcessDpiAwarenessContext
        # O parametro e um ponteiro. Sem declarar isso, o -4 viaja como inteiro
        # de 32 bits, chega como handle invalido e a chamada falha calada.
        fn.argtypes = [ctypes.c_void_p]
        fn.restype = ctypes.c_bool
        if fn(ctypes.c_void_p(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2)):
            return True
    except (AttributeError, OSError, ValueError):
        pass

    try:
        if ctypes.windll.shcore.SetProcessDpiAwareness(PROCESS_PER_MONITOR_DPI_AWARE) == S_OK:
            return True
    except (AttributeError, OSError):
        pass

    try:
        return bool(user32.SetProcessDPIAware())
    except (AttributeError, OSError):
        return False


def desktop_size() -> tuple[int, int]:
    """Resolucao do monitor onde o jogo vai abrir."""
    try:
        sizes = pygame.display.get_desktop_sizes()
    except pygame.error:
        return FALLBACK_SIZE
    return sizes[0] if sizes else FALLBACK_SIZE


def fit_scale(width: int, height: int) -> int:
    """Maior ampliacao inteira que cabe na area dada.

    Inteira de proposito: 2.5x borraria a arte. O que sobra vira barra preta.
    """
    return max(
        1,
        min(width // config.INTERNAL_WIDTH, height // config.INTERNAL_HEIGHT),
    )


def max_window_scale() -> int:
    """Maior escala de janela que cabe na tela sem passar por baixo da barra."""
    width, height = desktop_size()
    return fit_scale(width, height - WINDOW_MARGIN_Y)


def resolve_window_scale(stored: int) -> int:
    """Zero em settings.json significa 'descubra sozinho'.

    Qualquer valor guardado tambem e limitado ao que cabe: um settings.json
    trazido de outra maquina nao pode abrir uma janela maior que o monitor.
    """
    limit = max_window_scale()
    if stored <= 0:
        return limit
    return max(1, min(int(stored), limit))
