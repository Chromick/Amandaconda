"""Desenho provisório com identidade.

Enquanto o sprite de verdade nao chega, ninguem deve parecer um retangulo
anonimo. Cada entidade tem silhueta propria, na paleta do jogo. Quando o
PNG existir, o Animator assume e estas funcoes deixam de ser chamadas.
"""

from __future__ import annotations

import math

import pygame

from . import config

N0 = (12, 10, 16)
N1 = (28, 25, 38)
N2 = (46, 43, 56)
N3 = (68, 63, 82)
N4 = (90, 86, 102)
N5 = (154, 148, 164)
PELE = (184, 127, 99)
PELE_LUZ = (224, 174, 140)
AMBAR = config.COLOR_ACCENT
AMBAR_DIM = (140, 100, 48)
PETROLEO = config.COLOR_ACCENT_DEEP
PETROLEO_LUZ = (56, 130, 126)
SANGUE = config.COLOR_DANO
VIRUS = config.COLOR_VIRUS
VIRUS_CORE = config.COLOR_VIRUS_CORE
PRATA = (124, 132, 148)
RUIVO = (196, 90, 42)


def fundo_faculdade(surface: pygame.Surface, cam_x: float, largura_mundo: int) -> None:
    """Corredor de faculdade à noite — gradiente, colunas, janelas, lampadas."""
    w, h = surface.get_size()
    # Ceu / parede profunda.
    for y in range(h):
        t = y / max(1, h - 1)
        if y < 40:
            r = int(10 + 8 * (y / 40))
            g = int(8 + 6 * (y / 40))
            b = int(18 + 10 * (y / 40))
        else:
            r = int(18 + (32 - 18) * t)
            g = int(16 + (28 - 16) * t)
            b = int(26 + (42 - 26) * t)
        pygame.draw.line(surface, (r, g, b), (0, y), (w, y))

    # Faixa de rodape (piso sugerido atras das plataformas).
    pygame.draw.rect(surface, N0, (0, h - 40, w, 40))
    pygame.draw.line(surface, N2, (0, h - 40), (w, h - 40))

    # Colunas / pilares do corredor (parallax).
    espaco = 96
    offset = int((-cam_x * 0.35) % espaco)
    for x in range(-espaco + offset, w + espaco, espaco):
        pygame.draw.rect(surface, N1, (x, 0, 12, h - 40))
        pygame.draw.line(surface, N2, (x + 12, 0), (x + 12, h - 40))
        pygame.draw.rect(surface, N0, (x - 2, h - 48, 16, 8))

    # Janelas escuras com brilho amber fraco (noite).
    janela_esp = 160
    joff = int((-cam_x * 0.2) % janela_esp)
    for x in range(-20 + joff, w + 40, janela_esp):
        pygame.draw.rect(surface, N0, (x, 48, 36, 44))
        pygame.draw.rect(surface, N2, (x, 48, 36, 44), 1)
        pygame.draw.line(surface, N1, (x + 18, 48), (x + 18, 92))
        pygame.draw.line(surface, N1, (x, 70), (x + 36, 70))
        # Reflexo amber de lampada.
        pygame.draw.rect(surface, (40, 32, 20), (x + 4, 52, 10, 8))

    # Teto + lampadas fluorescentes.
    pygame.draw.rect(surface, N1, (0, 0, w, 26))
    pygame.draw.line(surface, N3, (0, 26), (w, 26))
    for x in range(40 + int((-cam_x * 0.5) % 120), w, 120):
        pygame.draw.rect(surface, AMBAR_DIM, (x, 18, 28, 5))
        pygame.draw.rect(surface, AMBAR, (x + 2, 19, 24, 2))
        pygame.draw.rect(surface, N3, (x + 11, 14, 6, 4))
        # Cone de luz suave (retangulos).
        pygame.draw.rect(surface, (30, 26, 18), (x - 6, 26, 40, 3))

    # Quadro de avisos ocasional.
    aviso_esp = 220
    aoff = int((-cam_x * 0.25) % aviso_esp)
    for x in range(60 + aoff, w, aviso_esp):
        pygame.draw.rect(surface, (60, 48, 40), (x, 100, 22, 28))
        pygame.draw.rect(surface, AMBAR_DIM, (x + 2, 104, 18, 3))
        pygame.draw.rect(surface, PETROLEO, (x + 2, 110, 18, 3))
        pygame.draw.rect(surface, N3, (x + 2, 116, 18, 3))


def fundo_hub(surface: pygame.Surface, tempo: float) -> None:
    """Hall noturno — mais ceremonial que o corredor."""
    w, h = surface.get_size()
    for y in range(h):
        t = y / max(1, h - 1)
        r = int(14 + (22 - 14) * t)
        g = int(12 + (20 - 12) * t)
        b = int(24 + (36 - 24) * t)
        pygame.draw.line(surface, (r, g, b), (0, y), (w, y))

    # Piso com linhas.
    pygame.draw.rect(surface, N0, (0, h - 50, w, 50))
    pygame.draw.line(surface, PETROLEO, (0, h - 50), (w, h - 50))
    for x in range(0, w, 24):
        pygame.draw.line(surface, N1, (x, h - 50), (x, h), 1)

    # Arco / portal ao fundo.
    pygame.draw.rect(surface, N1, (w // 2 - 70, 70, 140, 100))
    pygame.draw.rect(surface, N0, (w // 2 - 60, 80, 120, 90))
    pygame.draw.rect(surface, PETROLEO, (w // 2 - 60, 80, 120, 90), 1)
    pulso = 0.5 + 0.5 * math.sin(tempo * 2)
    glow = (
        int(PETROLEO[0] * pulso),
        int(PETROLEO[1] * pulso),
        int(PETROLEO[2] * pulso),
    )
    pygame.draw.rect(surface, glow, (w // 2 - 50, 90, 100, 70), 1)

    # Lampadas laterais.
    for x in (40, w - 56):
        pygame.draw.rect(surface, N3, (x, 30, 16, 6))
        pygame.draw.rect(surface, AMBAR, (x + 2, 31, 12, 3))


def fundo_patio(surface: pygame.Surface, cam_x: float) -> None:
    """Arena Balarrals — luar, quase sem cor."""
    w, h = surface.get_size()
    for y in range(h):
        t = y / max(1, h - 1)
        v = int(18 + 22 * t)
        pygame.draw.line(surface, (v, v + 2, v + 8), (0, y), (w, y))
    # Lua.
    pygame.draw.circle(surface, (200, 205, 220), (w - 48, 36), 14)
    pygame.draw.circle(surface, (18, 20, 28), (w - 42, 32), 12)
    # Chao.
    pygame.draw.rect(surface, (22, 24, 30), (0, h - 36, w, 36))
    pygame.draw.line(surface, PRATA, (0, h - 36), (w, h - 36))
    # Grades / portao distante.
    off = int((-cam_x * 0.15) % 40)
    for x in range(-off, w + 40, 40):
        pygame.draw.line(surface, N2, (x, 60), (x, h - 36), 1)


def plataforma(
    surface: pygame.Surface,
    r: pygame.Rect,
    *,
    safe: bool = False,
) -> None:
    """Solido com espessura, borda e 'azulejo' de corredor."""
    if r.width <= 0 or r.height <= 0:
        return
    corpo = PETROLEO if safe else N2
    topo = PETROLEO_LUZ if safe else N4
    sombra = N0
    pygame.draw.rect(surface, sombra, (r.x + 1, r.y + 2, r.width, r.height))
    pygame.draw.rect(surface, corpo, r)
    # Topo caminhavel.
    pygame.draw.rect(surface, topo, (r.x, r.y, r.width, min(3, r.height)))
    # Juntas verticais tipo lajota.
    if r.width > 20 and r.height >= 8:
        for x in range(r.x + 8, r.right, 8):
            pygame.draw.line(surface, N1 if not safe else (20, 40, 40), (x, r.y + 3), (x, r.bottom - 1))
    # Borda inferior.
    if r.height > 4:
        pygame.draw.line(surface, N1, (r.x, r.bottom - 1), (r.right, r.bottom - 1))


def jogador(
    surface: pygame.Surface,
    r: pygame.Rect,
    facing: int,
    cor: tuple[int, int, int],
    arma: str,
    estado: str,
    fase: str | None,
    andando: bool,
    tempo: float,
) -> None:
    if r.height < 8:
        pygame.draw.rect(surface, cor, r)
        return

    bob = round(math.sin(tempo * 10) * 1.5) if andando else 0
    corpo = r.move(0, bob)
    cx = corpo.centerx

    pygame.draw.ellipse(surface, N1, (corpo.centerx - 8, corpo.bottom - 3, 16, 5))

    if andando:
        passo = math.sin(tempo * 12)
        pygame.draw.rect(surface, N2, (cx - 5, corpo.bottom - 14, 4, 14 + round(passo * 2)))
        pygame.draw.rect(surface, N2, (cx + 1, corpo.bottom - 14, 4, 14 - round(passo * 2)))
    else:
        pygame.draw.rect(surface, N2, (cx - 5, corpo.bottom - 14, 4, 14))
        pygame.draw.rect(surface, N2, (cx + 1, corpo.bottom - 14, 4, 14))

    pygame.draw.rect(surface, cor, (cx - 7, corpo.y + 10, 14, 18))
    pygame.draw.rect(surface, N2, (cx - 8, corpo.y + 10, 16, 3))

    pygame.draw.rect(surface, PELE, (cx - 5, corpo.y + 2, 10, 10))
    pygame.draw.rect(surface, N1, (cx - 5, corpo.y, 10, 4))
    olho_x = cx + (3 if facing >= 0 else -5)
    pygame.draw.rect(surface, N1, (olho_x, corpo.y + 5, 2, 3))

    if estado == "atacando":
        if arma == "virus":
            bola = (cx + (10 if facing >= 0 else -16), corpo.y + 16)
            pygame.draw.circle(surface, VIRUS, bola, 4)
            pygame.draw.circle(surface, VIRUS_CORE, bola, 2)
        else:
            kx = cx + (6 if facing >= 0 else -14)
            ky = corpo.y + 18
            pygame.draw.rect(surface, N3, (kx, ky, 10, 6))
            for i in range(3):
                pygame.draw.rect(
                    surface, AMBAR if fase == "acerto" else N5, (kx + 1 + i * 3, ky + 1, 2, 2)
                )
        if fase == "preparacao":
            pygame.draw.rect(surface, config.COLOR_PREPARACAO, (cx - 8, corpo.y + 9, 16, 2))


def chatana(
    surface: pygame.Surface,
    r: pygame.Rect,
    fase: str | None,
    tempo: float,
) -> None:
    """Webcam/caixa — oculos + cabelo preto com franja (feminino)."""
    cx, cy = r.centerx, r.centery
    pygame.draw.ellipse(surface, N0, (r.x + 2, r.bottom - 3, r.width - 4, 4))
    pygame.draw.rect(surface, N2, r)
    pygame.draw.rect(surface, N3, r.inflate(-4, -4))
    # Cabelo / franja no topo.
    pygame.draw.rect(surface, N1, (r.x + 1, r.y - 3, r.width - 2, 5))
    pygame.draw.rect(surface, N0, (r.x + 3, r.y - 1, 3, 4))
    pygame.draw.rect(surface, N0, (r.right - 6, r.y - 1, 3, 4))
    # Oculos.
    pygame.draw.rect(surface, N5, (cx - 6, cy - 3, 5, 4), 1)
    pygame.draw.rect(surface, N5, (cx + 1, cy - 3, 5, 4), 1)
    pygame.draw.line(surface, N5, (cx - 1, cy - 1), (cx + 1, cy - 1))
    # LED / "boca" falante.
    led = SANGUE if fase == "acerto" else AMBAR if fase == "preparacao" else VIRUS
    pygame.draw.rect(surface, led, (cx - 3, cy + 3, 6, 2))
    # Antenas.
    pygame.draw.line(surface, N5, (r.left + 2, r.top), (r.left - 2, r.top - 5), 1)
    pygame.draw.line(surface, N5, (r.right - 2, r.top), (r.right + 2, r.top - 5), 1)
    if fase in ("preparacao", "acerto"):
        pulso = 2 + int(abs(math.sin(tempo * 14)) * 2)
        pygame.draw.circle(
            surface,
            SANGUE if fase == "acerto" else config.COLOR_PREPARACAO,
            (cx, cy),
            r.width + pulso,
            1,
        )


def portara(
    surface: pygame.Surface,
    r: pygame.Rect,
    facing: int,
    fase: str | None,
) -> None:
    """Porta andando — cabelo ondulado + maca mordida."""
    pygame.draw.ellipse(surface, N0, (r.x + 4, r.bottom - 4, r.width - 8, 5))
    pygame.draw.rect(surface, N2, r)
    pygame.draw.rect(surface, N3, (r.x + 3, r.y + 4, r.width - 6, r.height - 8))
    # Cabelo preto ondulado no topo.
    for i, dx in enumerate((-6, -2, 2, 6, 10)):
        pygame.draw.rect(surface, N0, (r.centerx + dx, r.y - 2 + (i % 2), 4, 8))
    pygame.draw.rect(surface, PETROLEO, (r.x + 5, r.y + 10, r.width - 10, 10))
    # Cilios na janela.
    olho_x = r.right - 10 if facing >= 0 else r.left + 6
    cor_olho = SANGUE if fase == "acerto" else AMBAR if fase == "preparacao" else N5
    pygame.draw.rect(surface, cor_olho, (olho_x, r.centery - 2, 4, 5))
    pygame.draw.line(surface, N1, (olho_x, r.centery - 3), (olho_x - 2, r.centery - 5))
    pygame.draw.line(surface, N1, (olho_x + 3, r.centery - 3), (olho_x + 5, r.centery - 5))
    # Maca mordida (sticker).
    ax, ay = r.centerx - 3, r.y + 28
    pygame.draw.circle(surface, N5, (ax + 3, ay + 3), 4)
    pygame.draw.rect(surface, N3, (ax + 5, ay + 1, 3, 3))  # mordida
    pygame.draw.rect(surface, PETROLEO, (ax + 2, ay - 1, 2, 2))  # cabo
    # Pes.
    pygame.draw.rect(surface, N1, (r.left + 2, r.bottom - 4, 6, 4))
    pygame.draw.rect(surface, N1, (r.right - 8, r.bottom - 4, 6, 4))


def net_antena(
    surface: pygame.Surface,
    r: pygame.Rect,
    fase: str | None,
    tempo: float,
) -> None:
    """Antena parabolica com juba ruiva."""
    cx = r.centerx
    # Tripé.
    pygame.draw.line(surface, N3, (cx, r.bottom), (cx - 6, r.bottom - 10), 2)
    pygame.draw.line(surface, N3, (cx, r.bottom), (cx + 6, r.bottom - 10), 2)
    # Prato.
    pygame.draw.ellipse(surface, N2, (r.x, r.y + 8, r.width, r.height - 16))
    pygame.draw.ellipse(surface, PETROLEO, (r.x + 3, r.y + 12, r.width - 6, r.height - 24), 1)
    # Cabelo ruivo.
    for i in range(5):
        pygame.draw.rect(
            surface,
            RUIVO,
            (r.x + 2 + i * 4, r.y + 2 + (i % 3), 3, 10 + (i % 2) * 3),
        )
    led = SANGUE if fase == "acerto" else VIRUS
    pygame.draw.circle(surface, led, (cx, r.centery), 2)
    if fase:
        pygame.draw.circle(surface, led, (cx, r.centery), 6 + int(2 * abs(math.sin(tempo * 10))), 1)


def boneco(
    surface: pygame.Surface,
    r: pygame.Rect,
    facing: int,
    cor: tuple[int, int, int],
) -> None:
    pygame.draw.ellipse(surface, N0, (r.centerx - 8, r.bottom - 3, 16, 4))
    pygame.draw.rect(surface, cor, r)
    pygame.draw.rect(surface, N1, (r.centerx - 1, r.y + 12, 2, 16))
    pygame.draw.rect(surface, N1, (r.centerx - 6, r.y + 18, 12, 2))
    olho_x = r.right - 6 if facing >= 0 else r.left + 4
    pygame.draw.rect(surface, N1, (olho_x, r.y + 8, 3, 3))
    # Fita de treino.
    pygame.draw.rect(surface, AMBAR_DIM, (r.x + 2, r.y + 4, r.width - 4, 2))


def pendrive_chip(
    surface: pygame.Surface,
    r: pygame.Rect,
    cor: tuple[int, int, int],
    bob: int,
) -> None:
    """Fallback se o PNG do pendrive nao carregou."""
    body = r.move(0, bob)
    pygame.draw.rect(surface, N1, body.inflate(2, 2))
    pygame.draw.rect(surface, cor, body)
    pygame.draw.rect(surface, PETROLEO, (body.x + 2, body.y + 2, body.width - 4, 3))
    pygame.draw.rect(surface, VIRUS, (body.centerx - 2, body.y + 5, 3, 2))
    pygame.draw.rect(surface, N5, (body.centerx - 3, body.bottom - 1, 6, 3))
    pygame.draw.rect(surface, N3, (body.centerx - 2, body.bottom + 1, 4, 2))


def safezone_placa(
    surface: pygame.Surface,
    zona: pygame.Rect,
) -> None:
    if zona.width <= 0:
        return
    # Chao marcado.
    pygame.draw.rect(surface, (20, 40, 38), (zona.x, zona.bottom - 40, zona.width, 40))
    for x in range(zona.x, zona.right, 16):
        pygame.draw.line(surface, PETROLEO, (x, zona.bottom - 40), (x + 8, zona.bottom - 40))
    pygame.draw.rect(surface, PETROLEO, (zona.x, zona.bottom - 36, zona.width, 3))
    # Portao na entrada.
    pygame.draw.rect(surface, PETROLEO, (zona.x, zona.y + 36, 5, zona.height - 76))
    pygame.draw.rect(surface, PETROLEO_LUZ, (zona.x + 1, zona.y + 40, 3, 20))
    # Placa SAFE.
    pygame.draw.rect(surface, N1, (zona.x + 10, zona.y + 48, 36, 12))
    pygame.draw.rect(surface, PETROLEO, (zona.x + 10, zona.y + 48, 36, 12), 1)


def porta_hub(
    surface: pygame.Surface,
    r: pygame.Rect,
    tempo: float,
) -> None:
    """Porta luminosa no fim da safezone."""
    pulso = 0.6 + 0.4 * math.sin(tempo * 4)
    cor = (
        int(PETROLEO[0] * pulso + AMBAR[0] * (1 - pulso) * 0.3),
        int(PETROLEO[1] * pulso + AMBAR[1] * (1 - pulso) * 0.3),
        int(PETROLEO[2] * pulso),
    )
    pygame.draw.rect(surface, N0, r.inflate(4, 4))
    pygame.draw.rect(surface, cor, r, 2)
    pygame.draw.rect(surface, AMBAR, (r.centerx - 6, r.centery - 8, 12, 2))
    pygame.draw.rect(surface, AMBAR, (r.centerx - 1, r.centery - 8, 2, 16))
