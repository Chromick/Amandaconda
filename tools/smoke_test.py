"""Sobe o jogo sem tela e roda algumas cenas por alguns segundos simulados.

Nao substitui jogar, mas pega erro de importacao, de render e de troca de cena
antes de voce abrir a janela. Rodar com:

    .venv\\Scripts\\python.exe tools\\smoke_test.py
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

os.environ.setdefault("SDL_VIDEODRIVER", "dummy")
os.environ.setdefault("SDL_AUDIODRIVER", "dummy")

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from src import config  # noqa: E402
from src.game import Game  # noqa: E402
from src.scenes.intro import IntroScene  # noqa: E402
from src.scenes.loadout import LoadoutScene  # noqa: E402
from src.scenes.menu import MenuScene  # noqa: E402
from src.scenes.options import OptionsScene  # noqa: E402
from src.scenes.play import PlayScene  # noqa: E402

DRAW_EVERY = 10  # desenhar todo passo deixa o teste lento sem achar mais bug


def exercise(game: Game, scene, label: str, seconds: float = 3.0) -> None:
    game.set_scene(scene)
    game._flush_scene_changes()
    for step in range(int(seconds / config.FIXED_DT)):
        game.input.begin_tick()
        game.scenes[-1].update(config.FIXED_DT)
        game._flush_scene_changes()
        if step % DRAW_EVERY == 0:
            game._draw()
    print(f"  ok  {label}  ->  {type(game.scenes[-1]).__name__}")


def main() -> int:
    game = Game()
    print("smoke test")

    exercise(game, MenuScene(game), "menu")
    # Tempo suficiente para a abertura rolar inteira e passar sozinha para o jogo.
    exercise(game, IntroScene(game), "intro", seconds=90.0)
    exercise(game, LoadoutScene(game), "loadout", seconds=1.0)
    exercise(game, PlayScene(game, escola="teclado"), "play")

    game.push_scene(OptionsScene(game))
    game._flush_scene_changes()
    game._draw()
    game.pop_scene()
    game._flush_scene_changes()
    print("  ok  options")

    print("tudo passou")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
