"""Importa idle/animacao PixelLab pro canvas do jogo.

    .venv\\Scripts\\python.exe tools\\import_pixellab.py parado assets/imports/player_se/Idle/rotations/south-east.png
    .venv\\Scripts\\python.exe tools\\import_pixellab.py andando assets/imports/player_se/walk_se.gif
"""

from __future__ import annotations

import sys
from collections import deque
from pathlib import Path

import pygame
from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(RAIZ))

from tools.sprites import ler_paleta, ler_spec  # noqa: E402

CW_DEFAULT = 64
CH_DEFAULT = 48


def pil_to_surf(im: Image.Image) -> pygame.Surface:
    im = im.convert("RGBA")
    return pygame.image.frombytes(im.tobytes(), im.size, "RGBA")


def limpar_fundo(src: pygame.Surface) -> pygame.Surface:
    w, h = src.get_size()
    vis = [[False] * w for _ in range(h)]
    q: deque[tuple[int, int]] = deque()
    for x in range(w):
        q.append((x, 0))
        q.append((x, h - 1))
    for y in range(h):
        q.append((0, y))
        q.append((w - 1, y))
    src.lock()
    while q:
        x, y = q.popleft()
        if not (0 <= x < w and 0 <= y < h) or vis[y][x]:
            continue
        r, g, b, a = src.get_at((x, y))
        if a == 0 or (r + g + b) <= 18:
            vis[y][x] = True
            src.set_at((x, y), (0, 0, 0, 0))
            for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                q.append((nx, ny))
        else:
            vis[y][x] = True
    src.unlock()
    return src


def bbox(img: pygame.Surface) -> tuple[int, int, int, int]:
    w, h = img.get_size()
    xs, ys = [], []
    img.lock()
    for y in range(h):
        for x in range(w):
            if img.get_at((x, y))[3] >= 10:
                xs.append(x)
                ys.append(y)
    img.unlock()
    return min(xs), min(ys), max(xs) + 1, max(ys) + 1


def encaixar(crop: pygame.Surface, cw: int, ch: int) -> pygame.Surface:
    canvas = pygame.Surface((cw, ch), pygame.SRCALPHA)
    sw, sh = crop.get_size()
    scale = min((cw - 8) / sw, (ch - 8) / sh)
    nw, nh = max(1, int(sw * scale)), max(1, int(sh * scale))
    canvas.blit(pygame.transform.scale(crop, (nw, nh)), ((cw - nw) // 2, ch - nh))
    return canvas


def carregar_quadros(path: Path) -> list[pygame.Surface]:
    im = Image.open(path)
    n = getattr(im, "n_frames", 1)
    frames = []
    for i in range(n):
        if n > 1:
            im.seek(i)
        surf = limpar_fundo(pil_to_surf(im.copy()))
        x0, y0, x1, y1 = bbox(surf)
        frames.append(surf.subsurface(pygame.Rect(x0, y0, x1 - x0, y1 - y0)).copy())
    return frames


def near(c, cores, cache):
    if c not in cache:
        r, g, b = c
        cache[c] = min(cores, key=lambda p: (p[0] - r) ** 2 + (p[1] - g) ** 2 + (p[2] - b) ** 2)
    return cache[c]


def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__)
        return 2

    anim = sys.argv[1]
    entrada = Path(sys.argv[2])
    entidade = sys.argv[3] if len(sys.argv) > 3 else "player"

    pygame.init()
    pygame.display.set_mode((1, 1), pygame.HIDDEN)

    spec = ler_spec()[entidade]
    cw, ch = spec["canvas"]
    pedidos = spec["animacoes"][anim]["quadros"]

    brutos = carregar_quadros(entrada)
    if len(brutos) == 1 and pedidos > 1:
        brutos = brutos * pedidos
    elif len(brutos) > pedidos:
        # Pulo etc: pega frames espalhados.
        idxs = [round(i * (len(brutos) - 1) / (pedidos - 1)) for i in range(pedidos)]
        brutos = [brutos[i] for i in idxs]
    elif len(brutos) < pedidos:
        while len(brutos) < pedidos:
            brutos.append(brutos[-1])

    cores = [rgb for rgb, _ in ler_paleta()]
    cache: dict = {}
    sheet = pygame.Surface((cw * pedidos, ch), pygame.SRCALPHA)
    for i, crop in enumerate(brutos):
        sheet.blit(encaixar(crop, cw, ch), (i * cw, 0))

    final = pygame.Surface(sheet.get_size(), pygame.SRCALPHA)
    sheet.lock()
    final.lock()
    for y in range(ch):
        for x in range(cw * pedidos):
            r, g, b, a = sheet.get_at((x, y))
            if a < 128:
                continue
            final.set_at((x, y), (*near((r, g, b), cores, cache), 255))
    sheet.unlock()
    final.unlock()

    dest = RAIZ / "assets" / "sprites" / entidade / f"{anim}.png"
    dest.parent.mkdir(parents=True, exist_ok=True)
    pygame.image.save(final, str(dest))
    print(f"ok {dest.relative_to(RAIZ)}  {pedidos} quadros  {len(cache)} cores")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
