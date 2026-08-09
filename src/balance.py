"""Carrega os valores de balanceamento de data/balance.json.

Regra do projeto: nenhum numero ajustavel pode estar escrito no meio do codigo.
Isso mantem o ajuste rapido durante a fase 1 e transforma a migracao para a
fase 2 em transcrever uma tabela. Ver docs/NUMEROS.md.
"""

from __future__ import annotations

import json
from pathlib import Path

BALANCE_PATH = Path(__file__).resolve().parent.parent / "data" / "balance.json"


class Balance:
    def __init__(self, path: Path = BALANCE_PATH) -> None:
        self.path = path
        self.data: dict = {}
        self.error: str | None = None
        self.reload()

    def reload(self) -> bool:
        """Recarrega em tempo de execucao. Mantem os valores antigos se o arquivo
        estiver quebrado, para nao derrubar o jogo no meio de um teste."""
        try:
            with self.path.open(encoding="utf-8") as f:
                self.data = json.load(f)
            self.error = None
            return True
        except (OSError, json.JSONDecodeError) as exc:
            self.error = str(exc)
            return False

    def __getitem__(self, section: str) -> dict:
        return self.data[section]
