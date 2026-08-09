"""Ferramentas de arte: paleta, conferencia e ajuste de sprites.

    .venv\\Scripts\\python.exe tools\\sprites.py paleta
    .venv\\Scripts\\python.exe tools\\sprites.py validar
    .venv\\Scripts\\python.exe tools\\sprites.py validar player parado
    .venv\\Scripts\\python.exe tools\\sprites.py ajustar entrada.png player andando

O validador existe para voce nao descobrir que um sprite esta errado depois de
desenhar os quarenta. Ele confere as tres coisas que quebram o jogo em
silencio: tamanho fora do combinado, cor fora da paleta, e borda suavizada.

O ajustador resolve as mesmas tres coisas automaticamente, para quando a arte
vier de fora: de um gerador de IA, de um pacote gratuito ou de outro programa.
Ele reduz para o tamanho certo, joga cada pixel na cor mais proxima da paleta e
corta a transparencia parcial. Entra imagem qualquer, sai sprite do jogo.
"""

from __future__ import annotations

import json
import sys
from collections import Counter
from pathlib import Path

import pygame

RAIZ = Path(__file__).resolve().parent.parent
PALETA = RAIZ / "docs" / "arte" / "paleta.gpl"
SPEC = RAIZ / "data" / "sprites.json"
SPRITES = RAIZ / "assets" / "sprites"
AMOSTRA = RAIZ / "docs" / "arte" / "paleta.png"


def ler_paleta() -> list[tuple[tuple[int, int, int], str]]:
    cores = []
    for linha in PALETA.read_text(encoding="utf-8").splitlines():
        if not linha.strip() or linha.startswith("#"):
            continue
        if linha[0].isalpha():  # cabecalho GIMP Palette / Name / Columns
            continue
        partes = linha.split("\t")
        rgb = tuple(int(v) for v in partes[0].split())
        nome = partes[1].strip() if len(partes) > 1 else ""
        if len(rgb) == 3:
            cores.append((rgb, nome))
    return cores


def ler_spec() -> dict:
    with SPEC.open(encoding="utf-8") as f:
        return json.load(f)


# --- amostra ---


def gerar_amostra() -> None:
    cores = ler_paleta()
    # Largura do quadro dita pelo rotulo mais comprido, nao pela cor.
    quadro, colunas, margem, rotulo = 56, 8, 12, 22
    linhas = (len(cores) + colunas - 1) // colunas

    largura = margem * 2 + colunas * quadro
    altura = margem * 2 + linhas * (quadro + rotulo)

    pygame.init()
    surface = pygame.Surface((largura, altura))
    surface.fill((16, 14, 20))
    fonte = pygame.font.Font(None, 13)

    for i, (rgb, nome) in enumerate(cores):
        col, lin = i % colunas, i // colunas
        x = margem + col * quadro
        y = margem + lin * (quadro + rotulo)
        pygame.draw.rect(surface, rgb, (x, y, quadro - 2, quadro - 2))

        for j, parte in enumerate(nome.split(" ")[:2]):
            texto = fonte.render(parte, False, (140, 136, 148))
            surface.blit(texto, (x, y + quadro - 1 + j * 9))

    pygame.image.save(surface, str(AMOSTRA))
    print(f"{len(cores)} cores -> {AMOSTRA.relative_to(RAIZ)}")


# --- validacao ---


def validar_arquivo(caminho: Path, canvas: list[int], quadros: int, paleta: set) -> list[str]:
    erros = []
    try:
        img = pygame.image.load(str(caminho)).convert_alpha()
    except pygame.error as exc:
        return [f"nao abriu: {exc}"]

    largura, altura = img.get_size()
    esperado = (canvas[0] * quadros, canvas[1])
    if (largura, altura) != esperado:
        erros.append(
            f"tamanho {largura}x{altura}, esperado {esperado[0]}x{esperado[1]} "
            f"({quadros} quadros de {canvas[0]}x{canvas[1]})"
        )

    fora = set()
    meio_transparente = 0
    img.lock()
    for y in range(altura):
        for x in range(largura):
            r, g, b, a = img.get_at((x, y))
            if a == 0:
                continue
            if a < 255:
                meio_transparente += 1
                continue
            if (r, g, b) not in paleta:
                fora.add((r, g, b))
    img.unlock()

    if fora:
        amostra = ", ".join(f"#{r:02X}{g:02X}{b:02X}" for r, g, b in list(fora)[:6])
        resto = f" e mais {len(fora) - 6}" if len(fora) > 6 else ""
        erros.append(f"{len(fora)} cores fora da paleta: {amostra}{resto}")

    if meio_transparente:
        erros.append(
            f"{meio_transparente} pixels meio transparentes "
            "(anti-aliasing ligado, desenhe com o lapis sem suavizacao)"
        )

    return erros


def validar(entidade: str | None, animacao: str | None) -> int:
    pygame.init()
    pygame.display.set_mode((1, 1), pygame.HIDDEN)

    paleta = {rgb for rgb, _ in ler_paleta()}
    spec = ler_spec()

    total = falhas = faltando = 0
    quadros_totais = quadros_prontos = 0
    for nome, dados in spec.items():
        if nome.startswith("_") or (entidade and nome != entidade):
            continue
        if "espelha" in dados:
            print(f"{nome}: recolorir a folha de {dados['espelha']}, sem arquivo proprio")
            continue

        for anim, info in dados["animacoes"].items():
            if animacao and anim != animacao:
                continue
            total += 1
            quadros_totais += info["quadros"]
            caminho = SPRITES / nome / f"{anim}.png"
            if not caminho.exists():
                faltando += 1
                continue
            quadros_prontos += info["quadros"]

            erros = validar_arquivo(caminho, dados["canvas"], info["quadros"], paleta)
            if erros:
                falhas += 1
                print(f"\n[X] {nome}/{anim}.png")
                for erro in erros:
                    print(f"    {erro}")
            else:
                print(f"[ok] {nome}/{anim}.png")

    desenhados = total - faltando
    print(
        f"\n{desenhados} de {total} animacoes desenhadas "
        f"({quadros_prontos} de {quadros_totais} quadros), {falhas} com problema"
    )
    return 1 if falhas else 0


# --- ajuste de arte vinda de fora ---

ALPHA_CORTE = 128


def _mais_proxima(cor: tuple[int, int, int], paleta: list, cache: dict) -> tuple:
    achada = cache.get(cor)
    if achada is None:
        r, g, b = cor
        achada = min(paleta, key=lambda p: (p[0] - r) ** 2 + (p[1] - g) ** 2 + (p[2] - b) ** 2)
        cache[cor] = achada
    return achada


# Tolerancia ao redor da cor de fundo, em distancia euclidiana de RGB. Baixa de
# proposito: absorve o ruido do gerador sem comer o contorno preto do desenho,
# que costuma estar perto do fundo escuro deste jogo.
TOLERANCIA_FUNDO = 10


def _cor_de_fundo(img: pygame.Surface) -> tuple[int, int, int] | None:
    """A cor que domina a moldura da imagem, se e que existe uma."""
    largura, altura = img.get_size()
    borda = Counter()
    img.lock()
    for x in range(largura):
        borda[img.get_at((x, 0))[:3]] += 1
        borda[img.get_at((x, altura - 1))[:3]] += 1
    for y in range(altura):
        borda[img.get_at((0, y))[:3]] += 1
        borda[img.get_at((largura - 1, y))[:3]] += 1
    img.unlock()

    candidata = borda.most_common(1)[0][0]
    perto = sum(
        n for cor, n in borda.items() if _distancia(cor, candidata) <= TOLERANCIA_FUNDO
    )
    # Menos de 70% da moldura parecida: provavelmente e cenario, nao fundo.
    return candidata if perto / sum(borda.values()) >= 0.7 else None


def _distancia(a, b) -> float:
    return ((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2 + (a[2] - b[2]) ** 2) ** 0.5


def _recortar_fundo(img: pygame.Surface, fundo: tuple[int, int, int]) -> int:
    largura, altura = img.get_size()
    apagados = 0
    img.lock()
    for y in range(altura):
        for x in range(largura):
            cor = img.get_at((x, y))
            if cor[3] and _distancia(cor[:3], fundo) <= TOLERANCIA_FUNDO:
                img.set_at((x, y), (0, 0, 0, 0))
                apagados += 1
    img.unlock()
    return apagados


def ajustar(entrada: Path, entidade: str, animacao: str) -> int:
    pygame.init()
    pygame.display.set_mode((1, 1), pygame.HIDDEN)

    spec = ler_spec()
    if entidade not in spec or "animacoes" not in spec[entidade]:
        print(f"'{entidade}' nao esta em data/sprites.json")
        return 2
    dados = spec[entidade]
    if animacao not in dados["animacoes"]:
        disponiveis = ", ".join(dados["animacoes"])
        print(f"'{animacao}' nao existe em {entidade}. Tem: {disponiveis}")
        return 2

    canvas = dados["canvas"]
    quadros = dados["animacoes"][animacao]["quadros"]
    alvo = (canvas[0] * quadros, canvas[1])

    origem = pygame.image.load(str(entrada)).convert_alpha()
    print(f"entrada {origem.get_width()}x{origem.get_height()} -> {alvo[0]}x{alvo[1]}")

    fundo = _cor_de_fundo(origem)
    if fundo:
        apagados = _recortar_fundo(origem, fundo)
        print(
            f"fundo #{fundo[0]:02X}{fundo[1]:02X}{fundo[2]:02X} recortado, "
            f"{apagados} pixels viraram transparentes"
        )

    # Media de area na reducao e depois encaixe na paleta. Reduzir por vizinho
    # mais proximo perderia tracos finos que a media preserva como tom, e o
    # encaixe na paleta devolve o resultado para pixel art dura.
    reduzida = pygame.transform.smoothscale(origem, alvo)

    paleta = [rgb for rgb, _ in ler_paleta()]
    cache: dict = {}
    saida = pygame.Surface(alvo, pygame.SRCALPHA)

    reduzida.lock()
    saida.lock()
    for y in range(alvo[1]):
        for x in range(alvo[0]):
            r, g, b, a = reduzida.get_at((x, y))
            if a < ALPHA_CORTE:
                continue
            saida.set_at((x, y), (*_mais_proxima((r, g, b), paleta, cache), 255))
    reduzida.unlock()
    saida.unlock()

    destino = SPRITES / entidade / f"{animacao}.png"
    destino.parent.mkdir(parents=True, exist_ok=True)
    pygame.image.save(saida, str(destino))
    print(f"{len(cache)} cores encaixadas na paleta -> {destino.relative_to(RAIZ)}")
    return 0


def main() -> int:
    comando = sys.argv[1] if len(sys.argv) > 1 else "paleta"
    if comando == "paleta":
        gerar_amostra()
        return 0
    if comando == "validar":
        return validar(
            sys.argv[2] if len(sys.argv) > 2 else None,
            sys.argv[3] if len(sys.argv) > 3 else None,
        )
    if comando == "ajustar":
        if len(sys.argv) < 5:
            print("uso: sprites.py ajustar <arquivo> <entidade> <animacao>")
            return 2
        return ajustar(Path(sys.argv[2]), sys.argv[3], sys.argv[4])
    print(__doc__)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
