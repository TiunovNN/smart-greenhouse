#!/usr/bin/env python3
"""Validate cross-file greenhouse configuration invariants."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path
from typing import Any

import yaml


ROOT = Path(__file__).resolve().parents[2]

PROFILE_KEYS = {
    "irrigation_humidity_min": "input_number.greenhouse_irrigation_humidity_min",
    "irrigation_volume": "input_number.greenhouse_irrigation_volume",
    "vent_temp_open": "input_number.greenhouse_vent_temp_open",
    "vent_temp_full": "input_number.greenhouse_vent_temp_full",
    "vent_humidity_max": "input_number.greenhouse_vent_humidity_max",
    "soil_moisture_min": "input_number.greenhouse_soil_moisture_min",
}


def load_yaml(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return yaml.safe_load(handle)


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def assert_profile_defaults_match_automation() -> None:
    profiles_path = ROOT / "homeassistant" / "plant_profiles.yaml"
    automations_path = ROOT / "homeassistant" / "automations" / "greenhouse.yaml"

    profiles = load_yaml(profiles_path)["profiles"]
    automations = load_yaml(automations_path)

    apply_profile = next(
        (item for item in automations if item.get("id") == "greenhouse_apply_plant_profile"),
        None,
    )
    if apply_profile is None:
        fail("automation greenhouse_apply_plant_profile is missing")

    choices = apply_profile.get("actions", [])[0].get("choose", [])
    applied_by_label: dict[str, dict[str, float]] = {}

    for choice in choices:
        conditions = choice.get("conditions", [])
        selected_label = None
        for condition in conditions:
            if condition.get("entity_id") == "input_select.greenhouse_plant_profile":
                selected_label = condition.get("state")
                break
        if selected_label is None:
            continue

        values: dict[str, float] = {}
        for action in choice.get("sequence", []):
            if action.get("action") != "input_number.set_value":
                continue
            entity_id = action.get("target", {}).get("entity_id")
            value = action.get("data", {}).get("value")
            values[entity_id] = value
        applied_by_label[selected_label] = values

    for profile_name, profile in profiles.items():
        label = profile["label"]
        if label not in applied_by_label:
            fail(f"profile {profile_name!r} label {label!r} is not applied by automation")
        applied = applied_by_label[label]
        for profile_key, entity_id in PROFILE_KEYS.items():
            if entity_id not in applied:
                fail(f"{entity_id} is not set for profile {label!r}")
            expected = profile[profile_key]
            actual = applied[entity_id]
            if float(actual) != float(expected):
                fail(
                    f"profile drift for {label!r} {profile_key}: "
                    f"plant_profiles.yaml has {expected}, automation applies {actual}"
                )


def walk_yaml(value: Any, path: str = "") -> list[tuple[str, Any]]:
    items = [(path, value)]
    if isinstance(value, dict):
        for key, child in value.items():
            items.extend(walk_yaml(child, f"{path}.{key}" if path else str(key)))
    elif isinstance(value, list):
        for index, child in enumerate(value):
            items.extend(walk_yaml(child, f"{path}[{index}]"))
    return items


def assert_modern_homeassistant_syntax() -> None:
    for path in sorted((ROOT / "homeassistant").rglob("*.yaml")):
        data = load_yaml(path)
        for item_path, value in walk_yaml(data):
            if isinstance(value, dict) and "service" in value:
                fail(f"{path.relative_to(ROOT)} uses deprecated service: at {item_path}")
            if item_path.endswith(".triggers") or item_path == "triggers":
                triggers = value if isinstance(value, list) else []
                for index, trigger in enumerate(triggers):
                    if isinstance(trigger, dict) and "platform" in trigger:
                        fail(
                            f"{path.relative_to(ROOT)} uses deprecated trigger platform: "
                            f"at {item_path}[{index}]"
                        )


def assert_local_secrets_not_tracked() -> None:
    result = subprocess.run(
        ["git", "ls-files", "esphome/secrets.yaml", "homeassistant/secrets.yaml"],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )
    tracked = [line for line in result.stdout.splitlines() if line.strip()]
    if tracked:
        fail("local secrets file is tracked: " + ", ".join(tracked))


def main() -> None:
    assert_profile_defaults_match_automation()
    assert_modern_homeassistant_syntax()
    assert_local_secrets_not_tracked()
    print("Greenhouse config invariants OK")


if __name__ == "__main__":
    main()
