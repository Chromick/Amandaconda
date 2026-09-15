"""Estado da playthrough — sobrevive entre risco, hub e chefes."""

from __future__ import annotations


CHEFES_HUB = ("balarrals", "luanevil", "renanligno")


class RunState:
    def __init__(self, escola: str = "teclado") -> None:
        self.escola = escola
        self.chefes_mortos: set[str] = set()
        self.patches_ativos: list[str] = []
        self.patches_comprados: set[str] = set()
        self.habilidade: str | None = None  # Caramelo / Eco / Espelho
        self.habilidades: set[str] = set()

    def matou_chefe(self, chefe: str) -> None:
        self.chefes_mortos.add(chefe)
        hab = {
            "balarrals": "espelho",
            "luanevil": "caramelo",
            "renanligno": "eco",
        }.get(chefe)
        if hab:
            self.habilidades.add(hab)
            if self.habilidade is None:
                self.habilidade = hab

    def porta_aberta(self, chefe: str) -> bool:
        return chefe not in self.chefes_mortos

    def tres_primeiros_mortos(self) -> bool:
        return all(c in self.chefes_mortos for c in CHEFES_HUB)
