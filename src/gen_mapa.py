"""Gerador de sala de risco (estilo Dead Cells, com regras de salto).

Nao e run roguelike: cada entrada na PlayScene sorteia um layout valido.
Chao continuo (Portara anda no piso); plataformas flutuantes so onde o
jogador alcanca com o pulo do balance.json.
"""

from __future__ import annotations

import random
from dataclasses import dataclass

import pygame

from .level import Level


@dataclass(frozen=True)
class AlcancePulo:
    """Limites derivados da fisica do jogador (com folga de seguranca)."""

    altura_max: float
    gap_max: float
    step_up_max: float


def alcance_do_player(p: dict) -> AlcancePulo:
    g = float(p["gravity"])
    v = float(p["jump_velocity"])
    # H = v^2 / (2g). Folga ~85% porque cut de pulo / atraso do jogador.
    altura = (v * v) / (2.0 * g)
    # Tempo no ar aproximado (subida+descida) * run_speed, folga 75%.
    t_ar = 2.0 * v / g
    gap = float(p["run_speed"]) * t_ar * 0.75
    return AlcancePulo(
        altura_max=altura * 0.9,
        gap_max=gap,
        step_up_max=min(altura * 0.85, 52.0),
    )


def _alcancavel(a: pygame.FRect, b: pygame.FRect, alcance: AlcancePulo) -> bool:
    """Da plataforma A da pra cair/pular na B?"""
    # Distancia horizontal entre bordas mais proximas.
    if a.right < b.left:
        gap = b.left - a.right
    elif b.right < a.left:
        gap = a.left - b.right
    else:
        gap = 0.0
    dy = a.top - b.top  # positivo = B mais alta
    if gap > alcance.gap_max:
        return False
    if dy > alcance.step_up_max:
        return False
    # Queda livre: qualquer altura pra baixo ok se gap ok.
    if dy < -alcance.altura_max * 1.5:
        # Queda muito grande ainda e ok se houver chao — mas entre plats, evita.
        return gap <= alcance.gap_max * 0.5
    return True


def _bfs_alcance(
    plataformas: list[pygame.FRect],
    inicio: int,
    alcance: AlcancePulo,
) -> set[int]:
    vist: set[int] = set()
    fila = [inicio]
    while fila:
        i = fila.pop(0)
        if i in vist:
            continue
        vist.add(i)
        for j, outra in enumerate(plataformas):
            if j in vist:
                continue
            if _alcancavel(plataformas[i], outra, alcance):
                fila.append(j)
    return vist


def gerar_risco(balance: dict, rng: random.Random | None = None) -> Level:
    """Monta Level com plataformas aleatorias + spawns validos."""
    rng = rng or random.Random()
    cfg = balance["mapa_risco"]
    p = balance["player"]
    alcance = alcance_do_player(p)

    width = int(cfg["largura"])
    height = int(cfg["altura"])
    floor_y = height - 32
    safe_w = int(cfg["safe_largura"])
    safe_x = width - safe_w
    risco_esq = float(cfg["margem_inicio"])
    risco_dir = float(safe_x - cfg["margem_safe"])

    # Clamp de regras pelo pulo real.
    esp_min = float(cfg["espaco_x_min"])
    esp_max = min(float(cfg["espaco_x_max"]), alcance.gap_max)
    dy_min = float(cfg["delta_y_min"])
    dy_max = min(float(cfg["delta_y_max"]), alcance.step_up_max)
    h_max = min(float(cfg["altura_max_do_chao"]), alcance.altura_max)

    solids: list[pygame.FRect] = [
        pygame.FRect(0, floor_y, width, 32),
        pygame.FRect(-8, 0, 8, height),
        pygame.FRect(width, 0, 8, height),
    ]

    # Plataforma-index 0 = faixa do chao na zona de risco (pra BFS).
    chao_risco = pygame.FRect(risco_esq, floor_y, max(40.0, risco_dir - risco_esq), 10)
    plats: list[pygame.FRect] = [chao_risco]

    n = rng.randint(int(cfg["plataformas_min"]), int(cfg["plataformas_max"]))
    cursor_x = risco_esq + 40
    cursor_y = floor_y - dy_min

    for _ in range(n * 3):  # tentativas extras se rejeitar
        if len(plats) - 1 >= n:
            break
        if cursor_x >= risco_dir - 40:
            break

        w = rng.uniform(float(cfg["largura_plat_min"]), float(cfg["largura_plat_max"]))
        gap = rng.uniform(esp_min, esp_max)
        # Alterna subir/descer pra nao empilhar so pra cima.
        if rng.random() < 0.55:
            dy = rng.uniform(dy_min, dy_max)
        else:
            dy = -rng.uniform(dy_min, dy_max)

        top = cursor_y - dy
        top = max(floor_y - h_max, min(floor_y - 18, top))
        x = cursor_x + gap
        if x + w > risco_dir:
            continue

        plat = pygame.FRect(x, top, w, 10)
        # Tem que ser alcancavel de alguma plat ja colocada (inclui chao).
        if not any(_alcancavel(antiga, plat, alcance) for antiga in plats):
            continue

        plats.append(plat)
        solids.append(plat)
        cursor_x = plat.right
        cursor_y = plat.top

    # Garante conectividade a partir do chao; remove ilhas.
    ok = _bfs_alcance(plats, 0, alcance)
    solids = [solids[0], solids[1], solids[2]] + [
        plats[i] for i in range(1, len(plats)) if i in ok
    ]
    plats = [plats[i] for i in sorted(ok)]

    # Spawns.
    tops_plat = [plats[i] for i in range(1, len(plats))]  # sem o chao fantasma
    spawns_inimigo: list[tuple[str, float]] = []
    for tipo, onde in cfg["inimigos"]:
        if onde == "chao" or not tops_plat:
            x = rng.uniform(risco_esq + 80, risco_dir - 40)
        else:
            plat = rng.choice(tops_plat)
            x = rng.uniform(plat.left + 12, plat.right - 12)
        spawns_inimigo.append((tipo, float(x)))

    spawns_pendrive: list[float] = []
    candidatos = tops_plat[:] if tops_plat else [chao_risco]
    rng.shuffle(candidatos)
    for plat in candidatos[: int(cfg["pendrives"])]:
        spawns_pendrive.append(float((plat.left + plat.right) * 0.5))

    # Se faltou pendrive (poucas plats), completa no chao.
    while len(spawns_pendrive) < int(cfg["pendrives"]):
        spawns_pendrive.append(rng.uniform(risco_esq + 100, risco_dir - 60))

    saida = pygame.FRect(width - 52, floor_y - 72, 44, 72)
    return Level(
        solids,
        width,
        height,
        spawn=(70, floor_y),
        safezone=pygame.FRect(safe_x, 0, safe_w, height),
        spawns_inimigo=spawns_inimigo,
        spawns_pendrive=spawns_pendrive,
        spawn_boneco=safe_x + safe_w * 0.45,
        saida_hub=saida,
    )
