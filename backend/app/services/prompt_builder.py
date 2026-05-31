from __future__ import annotations

from pathlib import Path

PROMPT_VERSION = "v1"

_BASE = Path(__file__).resolve().parent.parent / "prompts"


def _load(name: str) -> str:
    path = _BASE / name
    if not path.exists():
        return ""
    return path.read_text(encoding="utf-8")


def build_reshuffle_prompt(*, items: list[str], style: str | None) -> str:
    template = _load("reshuffle_preview_prompt.txt")
    item_lines = "\n".join(f"- {name}" for name in items)
    return template.format(items=item_lines, style=style or "minimal")


def build_redesign_prompt(*, items: list[str], style: str | None) -> str:
    template = _load("redesign_preview_prompt.txt")
    item_lines = "\n".join(f"- {name}" for name in items)
    return template.format(items=item_lines, style=style or "warm modern")
