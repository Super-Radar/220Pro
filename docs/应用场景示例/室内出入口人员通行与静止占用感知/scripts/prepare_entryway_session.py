"""Create a new indoor-entryway capture session from the CSV templates."""

from __future__ import annotations

import argparse
import csv
from io import StringIO
from pathlib import Path
import re
import sys


SCRIPT_DIR = Path(__file__).resolve().parent
TEMPLATE_DIR = SCRIPT_DIR.parent / "templates"
SITE_TEMPLATE = TEMPLATE_DIR / "indoor-entryway-site.csv"
CAPTURE_TEMPLATE = TEMPLATE_DIR / "indoor-entryway-captures.csv"

OUTPUT_NAMES = {
    "site": "site.csv",
    "captures": "captures.csv",
    "readme": "README.txt",
}

ENVIRONMENT_ID_PATTERN = re.compile(r"[A-Za-z0-9][A-Za-z0-9._-]{0,63}")


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Create a non-overwriting S0-S6 indoor-entryway capture session."
    )
    parser.add_argument(
        "--output",
        type=Path,
        required=True,
        help="new or empty directory that will receive the session files",
    )
    parser.add_argument(
        "--environment-id",
        default="E01",
        help="shared environment identifier (default: E01)",
    )
    return parser.parse_args()


def validate_environment_id(value: str) -> str:
    if not ENVIRONMENT_ID_PATTERN.fullmatch(value):
        raise ValueError(
            "environment_id must contain 1-64 letters, digits, dots, underscores, "
            "or hyphens, and must start with a letter or digit"
        )
    return value


def read_template(path: Path) -> tuple[list[str], list[dict[str, str]]]:
    with path.open(encoding="utf-8", newline="") as stream:
        reader = csv.DictReader(stream)
        if not reader.fieldnames or "environment_id" not in reader.fieldnames:
            raise ValueError(f"template has no environment_id column: {path.name}")
        rows = list(reader)
    if not rows:
        raise ValueError(f"template contains no records: {path.name}")
    if any(None in row or None in row.values() for row in rows):
        raise ValueError(f"template contains a malformed row: {path.name}")
    return reader.fieldnames, rows


def render_csv(
    fieldnames: list[str], rows: list[dict[str, str]], environment_id: str
) -> str:
    output = StringIO(newline="")
    writer = csv.DictWriter(output, fieldnames=fieldnames, lineterminator="\n")
    writer.writeheader()
    for row in rows:
        updated = row.copy()
        updated["environment_id"] = environment_id
        writer.writerow(updated)
    return output.getvalue()


def render_readme(environment_id: str) -> str:
    return (
        "CTSAI-A100 indoor-entryway capture session\n"
        f"environment_id: {environment_id}\n\n"
        "1. Measure the site and fill site.csv.\n"
        "2. Keep raw radar files outside the documentation repository.\n"
        "3. Fill one captures.csv row for every continuous recording.\n"
        "4. Use relative paths and anonymous participant identifiers.\n"
        "5. Complete privacy_checked only after reviewing files for identifiers.\n\n"
        "These files are blank recording forms, not measured radar results.\n"
    )


def prepare_output_directory(path: Path) -> Path:
    output_dir = path.expanduser().resolve()
    if output_dir.exists():
        if not output_dir.is_dir():
            raise ValueError(f"output path is not a directory: {output_dir}")
        if any(output_dir.iterdir()):
            raise ValueError(f"output directory is not empty: {output_dir}")
    else:
        output_dir.mkdir(parents=True)
    return output_dir


def write_exclusive(path: Path, content: str) -> None:
    with path.open("x", encoding="utf-8", newline="") as stream:
        stream.write(content)


def create_session(output: Path, environment_id: str) -> Path:
    site_fields, site_rows = read_template(SITE_TEMPLATE)
    capture_fields, capture_rows = read_template(CAPTURE_TEMPLATE)

    source_site_ids = {row["environment_id"] for row in site_rows}
    source_capture_ids = {row["environment_id"] for row in capture_rows}
    if len(source_site_ids) != 1 or source_capture_ids != source_site_ids:
        raise ValueError("source templates do not share one environment_id")

    content = {
        OUTPUT_NAMES["site"]: render_csv(site_fields, site_rows, environment_id),
        OUTPUT_NAMES["captures"]: render_csv(
            capture_fields, capture_rows, environment_id
        ),
        OUTPUT_NAMES["readme"]: render_readme(environment_id),
    }

    output_dir = prepare_output_directory(output)
    for name, text in content.items():
        write_exclusive(output_dir / name, text)
    return output_dir


def main() -> int:
    arguments = parse_arguments()
    try:
        environment_id = validate_environment_id(arguments.environment_id)
        output_dir = create_session(arguments.output, environment_id)
    except (OSError, ValueError) as error:
        print(f"ERROR  {error}", file=sys.stderr)
        return 1

    print(f"PASS  created entryway capture session: {output_dir}")
    for name in OUTPUT_NAMES.values():
        print(f"  {name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
