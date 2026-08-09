"""Preferencias do jogador, persistidas em data/settings.json.

Separado de balance.json de proposito: balance e ajuste de design do jogo,
settings e escolha de quem esta jogando. Os dois nunca se misturam.
"""

from __future__ import annotations

import json
from pathlib import Path

SETTINGS_PATH = Path(__file__).resolve().parent.parent / "data" / "settings.json"

DEFAULTS: dict = {
    # Zero: a maior escala que couber na tela detectada. Ver src/display.py.
    "window_scale": 0,
    "fullscreen": False,
    "music_volume": 0.7,
    "sfx_volume": 0.8,
    "show_debug": False,
}


class Settings:
    def __init__(self, path: Path = SETTINGS_PATH) -> None:
        self.path = path
        self.data = dict(DEFAULTS)
        self.load()

    def load(self) -> None:
        try:
            with self.path.open(encoding="utf-8") as f:
                stored = json.load(f)
        except (OSError, json.JSONDecodeError):
            return
        for key in DEFAULTS:
            if key in stored:
                self.data[key] = stored[key]

    def save(self) -> None:
        try:
            self.path.parent.mkdir(parents=True, exist_ok=True)
            with self.path.open("w", encoding="utf-8") as f:
                json.dump(self.data, f, indent=2, ensure_ascii=False)
                f.write("\n")
        except OSError:
            pass

    def __getitem__(self, key: str):
        return self.data[key]

    def __setitem__(self, key: str, value) -> None:
        self.data[key] = value
