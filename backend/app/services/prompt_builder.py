from __future__ import annotations

from collections.abc import Sequence
from dataclasses import dataclass
from pathlib import Path

PROMPT_VERSION = "v2"

_BASE = Path(__file__).resolve().parent.parent / "prompts"


@dataclass(frozen=True)
class PromptItem:
    """A detected room item with the status the prompt needs to honour."""

    name: str
    fixed: bool = False
    structural: bool = False

    @property
    def movable(self) -> bool:
        return not self.fixed and not self.structural


def _load(name: str) -> str:
    path = _BASE / name
    if not path.exists():
        return ""
    return path.read_text(encoding="utf-8")


def _safe_substitute(template: str, values: dict[str, str]) -> str:
    """Replace only the known ``{key}`` placeholders.

    The reshuffle template embeds a literal JSON example full of ``{`` / ``}``
    braces, so ``str.format`` cannot be used (it would treat that JSON as format
    fields and raise). This replaces exact ``{key}`` tokens and leaves every
    other brace untouched.
    """
    out = template
    for key, value in values.items():
        out = out.replace("{" + key + "}", value)
    return out


def _bullets(names: Sequence[str]) -> str:
    return "\n".join(f"- {name}" for name in names)


def _coerce_items(items: Sequence[PromptItem | str]) -> list[PromptItem]:
    """Accept either rich PromptItems or bare names (treated as movable)."""
    return [
        item if isinstance(item, PromptItem) else PromptItem(name=str(item))
        for item in items
    ]


def _format_item_sections(items: Sequence[PromptItem]) -> str:
    """Group items by status so the prompt passes specific names + statuses
    (never a vague "furniture" blob) and is explicit about what may move."""
    movable = [i.name for i in items if i.movable]
    fixed = [i.name for i in items if i.fixed and not i.structural]
    structural = [i.name for i in items if i.structural]

    sections: list[str] = []
    if movable:
        sections.append(
            "Movable items (may be repositioned or rotated):\n" + _bullets(movable)
        )
    if fixed:
        sections.append(
            "Fixed items (must remain exactly where they are):\n" + _bullets(fixed)
        )
    if structural:
        sections.append(
            "Structural items — doors, windows, walls, built-ins "
            "(must remain exactly where they are):\n" + _bullets(structural)
        )
    if not sections:
        return "- (no items detected)"
    return "\n\n".join(sections)


def build_reshuffle_prompt(
    *,
    items: Sequence[PromptItem | str],
    style: str | None,
    primary_goal: str | None = None,
    room_type: str | None = None,
) -> str:
    """Build the strict, anti-hallucination reshuffle prompt.

    ``items`` may be ``PromptItem`` instances (preferred — carries fixed /
    structural status) or plain name strings (treated as movable). Structural
    items are always presented as fixed unless explicitly marked movable.
    """
    template = _load("reshuffle_preview_prompt.txt")
    coerced = _coerce_items(items)
    movable = [i.name for i in coerced if i.movable]
    fixed = [i.name for i in coerced if i.fixed and not i.structural]
    structural = [i.name for i in coerced if i.structural]

    # Only {style} and {items} appear in the template today; the rest are
    # provided so the template can adopt them later without code changes.
    values = {
        "style": style or "minimal",
        "items": _format_item_sections(coerced),
        "movable_items": _bullets(movable) or "- (none)",
        "fixed_items": _bullets(fixed) or "- (none)",
        "structural_elements": _bullets(structural) or "- (none)",
        "primary_goal": primary_goal or "",
        "room_type": room_type or "",
    }
    return _safe_substitute(template, values)


def build_redesign_prompt(*, items: list[str], style: str | None) -> str:
    template = _load("redesign_preview_prompt.txt")
    item_lines = "\n".join(f"- {name}" for name in items)
    return template.format(items=item_lines, style=style or "warm modern")
