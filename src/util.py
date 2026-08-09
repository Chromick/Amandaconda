from __future__ import annotations


def approach(current: float, target: float, delta: float) -> float:
    """Move current na direcao de target sem nunca passar dele."""
    if current < target:
        return min(current + delta, target)
    return max(current - delta, target)


def clamp(value: float, low: float, high: float) -> float:
    return max(low, min(high, value))
