"""Tests for the strict anti-hallucination reshuffle prompt and its item
formatting. These pin the non-negotiable wording and the placeholder
substitution (which must survive the literal JSON braces in the template)."""

from __future__ import annotations

from types import SimpleNamespace

from app.services import generation_service
from app.services.prompt_builder import PromptItem, build_reshuffle_prompt


def _detected(name, type_="furniture", *, fixed=False, structural=False):
    return SimpleNamespace(
        name=name, type=type_, fixed=fixed, structural=structural
    )


def test_reshuffle_prompt_forbids_new_furniture():
    prompt = build_reshuffle_prompt(items=[PromptItem("Sofa")], style="cozy")
    assert "DO NOT add any new furniture" in prompt


def test_reshuffle_prompt_keeps_same_viewpoint():
    prompt = build_reshuffle_prompt(items=[PromptItem("Sofa")], style="cozy")
    assert "same viewpoint" in prompt.lower()


def test_reshuffle_prompt_preserves_doors_and_windows():
    prompt = build_reshuffle_prompt(items=[PromptItem("Sofa")], style="cozy")
    assert "Preserve the same number of doors and windows" in prompt


def test_reshuffle_prompt_substitutes_style_and_items():
    prompt = build_reshuffle_prompt(
        items=[PromptItem("Sofa"), PromptItem("Coffee table")],
        style="Scandinavian",
    )
    # Placeholders are gone, values are in.
    assert "{style}" not in prompt
    assert "{items}" not in prompt
    assert "Scandinavian" in prompt
    assert "Sofa" in prompt
    assert "Coffee table" in prompt


def test_reshuffle_prompt_keeps_literal_json_braces_intact():
    # The embedded JSON example must survive substitution untouched — proof
    # that we are not using str.format (which would choke on those braces).
    prompt = build_reshuffle_prompt(items=[PromptItem("Sofa")], style="cozy")
    assert '"camera_view": "same_viewpoint_preserved"' in prompt
    assert '"no_new_items_added": true' in prompt


def test_reshuffle_prompt_separates_movable_fixed_structural():
    prompt = build_reshuffle_prompt(
        items=[
            PromptItem("Sofa"),
            PromptItem("TV stand", fixed=True),
            PromptItem("Window", structural=True),
            PromptItem("Door", structural=True),
        ],
        style="cozy",
    )
    assert "Movable items" in prompt
    assert "Fixed items" in prompt
    assert "Structural items" in prompt
    # Each name lands in the right bucket; structural items are presented as
    # "must remain", never as movable.
    structural_section = prompt.split("Structural items")[1]
    assert "Window" in structural_section
    assert "Door" in structural_section
    assert "must remain exactly where they are" in prompt


def test_reshuffle_prompt_default_style_when_missing():
    prompt = build_reshuffle_prompt(items=[PromptItem("Sofa")], style=None)
    assert "{style}" not in prompt
    assert "minimal" in prompt


def test_reshuffle_prompt_accepts_bare_names_as_movable():
    prompt = build_reshuffle_prompt(items=["Sofa", "Rug"], style="cozy")
    assert "Movable items" in prompt
    assert "Sofa" in prompt and "Rug" in prompt


def test_build_prompt_includes_fixed_and_structural_for_reshuffle_project():
    project = SimpleNamespace(
        mode="reshuffle",
        preference_set=SimpleNamespace(
            style="modern", primary_goal="more_space"
        ),
        detected_items=[
            _detected("Sofa"),
            _detected("Bookshelf", fixed=True),
            _detected("Window", "window", structural=True),
        ],
    )
    prompt = generation_service._build_prompt(project)

    assert "DO NOT add any new furniture" in prompt
    assert "Sofa" in prompt
    # Fixed + structural items are surfaced in their constraint sections.
    assert "Bookshelf" in prompt
    structural_section = prompt.split("Structural items")[1]
    assert "Window" in structural_section


def test_build_prompt_reshuffle_does_not_append_legacy_constraint_block():
    project = SimpleNamespace(
        mode="reshuffle",
        preference_set=SimpleNamespace(style="modern"),
        detected_items=[_detected("Sofa")],
    )
    prompt = generation_service._build_prompt(project)
    # The strict template replaces the old appended block entirely.
    assert "IMPORTANT CONSTRAINTS:" not in prompt
    assert prompt.rstrip().endswith(
        "preserving all structural elements exactly as they are."
    )
