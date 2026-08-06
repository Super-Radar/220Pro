"""Validate the distributed indoor-entryway CSV templates."""

from __future__ import annotations

from collections import Counter
import csv
from pathlib import Path
import sys


SCRIPT_DIR = Path(__file__).resolve().parent
TEMPLATE_DIR = SCRIPT_DIR.parent / "templates"
SITE_PATH = TEMPLATE_DIR / "indoor-entryway-site.csv"
CAPTURE_PATH = TEMPLATE_DIR / "indoor-entryway-captures.csv"

SITE_FIELDS = [
    "environment_id",
    "capture_date",
    "location_type",
    "radar_model",
    "radar_alias",
    "radar_height_m",
    "radar_yaw_deg",
    "radar_pitch_deg",
    "near_distance_m",
    "far_distance_m",
    "corridor_width_m",
    "doorway_width_m",
    "mount_description",
    "background_reflectors",
    "radartools_version",
    "notes",
]

CAPTURE_FIELDS = [
    "record_id",
    "environment_id",
    "scene_id",
    "repeat_index",
    "participant_id",
    "target_count",
    "action_label",
    "start_time",
    "duration_s",
    "reference_distance_m",
    "stop_duration_s",
    "data_types",
    "radar_config_file",
    "data_file",
    "ground_truth_file",
    "privacy_checked",
    "notes",
]

ACTION_BY_SCENE = {
    "S0": "empty",
    "S1": "approach",
    "S2": "recede",
    "S3": "stationary",
    "S4": "stop_continue",
    "S5": "lateral_pass",
    "S6": "turn_back",
}

UNMEASURED_CAPTURE_FIELDS = [
    "participant_id",
    "start_time",
    "duration_s",
    "reference_distance_m",
    "stop_duration_s",
    "data_types",
    "radar_config_file",
    "data_file",
    "ground_truth_file",
    "privacy_checked",
    "notes",
]


def read_csv(path: Path, expected_fields: list[str]) -> list[dict[str, str]]:
    """Read one UTF-8 CSV file and require its exact published schema."""
    with path.open(encoding="utf-8", newline="") as stream:
        reader = csv.DictReader(stream)
        if reader.fieldnames != expected_fields:
            raise ValueError(f"unexpected header: {path.name}")
        rows = list(reader)
    if any(None in row or None in row.values() for row in rows):
        raise ValueError(f"malformed row: {path.name}")
    return rows


def validate_site_template() -> set[str]:
    """Validate the single blank environment record distributed with the docs."""
    rows = read_csv(SITE_PATH, SITE_FIELDS)
    if len(rows) != 1 or rows[0]["environment_id"] != "E01":
        raise ValueError("site template must contain the E01 placeholder row")
    measured_fields = {
        "capture_date",
        "radar_alias",
        "radar_height_m",
        "radar_yaw_deg",
        "radar_pitch_deg",
        "near_distance_m",
        "far_distance_m",
        "corridor_width_m",
        "doorway_width_m",
        "mount_description",
        "background_reflectors",
        "radartools_version",
        "notes",
    }
    if any(rows[0][field] for field in measured_fields):
        raise ValueError("site template contains values that should be measured on site")
    print("OK  site template: E01 placeholder; measured fields blank")
    return {row["environment_id"] for row in rows}


def validate_capture_template(environment_ids: set[str]) -> None:
    """Validate scenario coverage, keys, labels, and blank capture fields."""
    rows = read_csv(CAPTURE_PATH, CAPTURE_FIELDS)
    if len(rows) != 21:
        raise ValueError(f"expected 21 capture rows, found {len(rows)}")
    if len({row["record_id"] for row in rows}) != len(rows):
        raise ValueError("record_id values must be unique")
    if not {row["environment_id"] for row in rows} <= environment_ids:
        raise ValueError("capture template references an unknown environment_id")

    counts = Counter(row["scene_id"] for row in rows)
    if counts != Counter({scene_id: 3 for scene_id in ACTION_BY_SCENE}):
        raise ValueError("each S0-S6 scene must have exactly three repetitions")

    for row in rows:
        scene_id = row["scene_id"]
        if row["action_label"] != ACTION_BY_SCENE[scene_id]:
            raise ValueError(f"action_label does not match {scene_id}")
        expected_count = "0" if scene_id == "S0" else "1"
        if row["target_count"] != expected_count:
            raise ValueError(f"target_count does not match {scene_id}")
        expected_id = f"{scene_id}-R{int(row['repeat_index']):02d}"
        if row["record_id"] != expected_id:
            raise ValueError(f"record_id does not match scene/repeat: {row['record_id']}")
        if any(row[field] for field in UNMEASURED_CAPTURE_FIELDS):
            raise ValueError(f"unmeasured fields must be blank: {row['record_id']}")

    print("OK  capture template: 21 unique rows; S0-S6 x 3; measurements blank")


def main() -> int:
    try:
        environment_ids = validate_site_template()
        validate_capture_template(environment_ids)
    except (OSError, ValueError) as error:
        print(f"ERROR  {error}", file=sys.stderr)
        return 1
    print("PASS  indoor-entryway CSV templates are structurally valid")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
