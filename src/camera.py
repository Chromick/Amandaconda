from __future__ import annotations

from . import config
from .balance import Balance
from .level import Level
from .util import clamp


class Camera:
    def __init__(self, balance: Balance) -> None:
        self.balance = balance
        self.x = 0.0
        self.y = 0.0

    def snap_to(self, target_x: float, target_y: float, level: Level) -> None:
        self.x, self.y = self._clamped(target_x, target_y, level)

    def update(self, dt: float, target_x: float, target_y: float, facing: int, level: Level) -> None:
        c = self.balance["camera"]
        goal_x, goal_y = self._clamped(
            target_x + facing * c["look_ahead"], target_y + c["vertical_offset"], level
        )
        # Interpolacao exponencial: independente da taxa de quadros.
        t = 1.0 - pow(0.5, dt * c["follow_speed"])
        self.x += (goal_x - self.x) * t
        self.y += (goal_y - self.y) * t

    def _clamped(self, target_x: float, target_y: float, level: Level) -> tuple[float, float]:
        x = target_x - config.INTERNAL_WIDTH / 2
        y = target_y - config.INTERNAL_HEIGHT / 2
        x = clamp(x, 0.0, max(0.0, level.width - config.INTERNAL_WIDTH))
        y = clamp(y, 0.0, max(0.0, level.height - config.INTERNAL_HEIGHT))
        return x, y
