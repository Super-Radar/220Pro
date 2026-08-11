"""Regenerate and validate the indoor-entryway scientific figures."""

from __future__ import annotations

import os
from pathlib import Path
import re
import struct
import subprocess
import sys
import xml.etree.ElementTree as ET


SCRIPT_DIR = Path(__file__).resolve().parent
DOCS_DIR = SCRIPT_DIR.parent
IMAGE_DIR = DOCS_DIR / "images"

FIGURES = {
    "generate_indoor_entryway_geometry.py": "indoor-entryway-test-geometry",
    "generate_entryway_scenario_matrix.py": "indoor-entryway-scenario-matrix",
    "generate_entryway_ideal_range_time.py": "indoor-entryway-ideal-range-time",
    "generate_entryway_multipath_geometry.py": "indoor-entryway-multipath-geometry",
}

LOCAL_RESOURCE_PATTERN = re.compile(r"\./(?:images|scripts|templates)/[^)\s]+")
PUBLIC_RESOURCE_PATTERN = re.compile(
    r"https://raw\.githubusercontent\.com/[^)\s]+"
)
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def regenerate_figures() -> None:
    """Run every figure generator with bytecode output disabled."""
    env = os.environ.copy()
    env["PYTHONDONTWRITEBYTECODE"] = "1"
    for script_name in FIGURES:
        command = [sys.executable, str(SCRIPT_DIR / script_name)]
        completed = subprocess.run(command, env=env, check=False)
        if completed.returncode != 0:
            raise RuntimeError(
                f"figure generator failed ({completed.returncode}): {script_name}"
            )
        print(f"OK  generated {script_name}")


def read_png_dimensions(path: Path) -> tuple[int, int]:
    """Read PNG dimensions directly from its IHDR chunk."""
    with path.open("rb") as stream:
        header = stream.read(24)
    if len(header) != 24 or header[:8] != PNG_SIGNATURE or header[12:16] != b"IHDR":
        raise ValueError(f"invalid PNG header: {path.name}")
    return struct.unpack(">II", header[16:24])


def validate_outputs() -> None:
    """Check that every declared PNG/SVG pair is present and parseable."""
    for output_stem in FIGURES.values():
        png_path = IMAGE_DIR / f"{output_stem}.png"
        svg_path = IMAGE_DIR / f"{output_stem}.svg"
        if not png_path.is_file() or not svg_path.is_file():
            raise FileNotFoundError(f"missing PNG/SVG pair: {output_stem}")

        width, height = read_png_dimensions(png_path)
        if width < 800 or height < 600:
            raise ValueError(
                f"unexpectedly small PNG ({width} x {height}): {png_path.name}"
            )

        root = ET.parse(svg_path).getroot()
        if not root.tag.endswith("svg"):
            raise ValueError(f"invalid SVG root: {svg_path.name}")
        svg_lines = svg_path.read_text(encoding="utf-8").splitlines()
        if any(line.endswith((" ", "\t")) for line in svg_lines):
            raise ValueError(f"SVG contains trailing whitespace: {svg_path.name}")

        print(f"OK  {png_path.name}: {width} x {height}; {svg_path.name}: parsed")


def find_scenario_document() -> Path:
    """Locate the entryway document without depending on a locale-specific path literal."""
    matches = []
    for path in DOCS_DIR.glob("*.md"):
        if "generate_entryway_scenario_matrix.py" in path.read_text(encoding="utf-8"):
            matches.append(path)
    if len(matches) != 1:
        raise RuntimeError(f"expected one entryway document, found {len(matches)}")
    return matches[0]


def validate_document_links() -> None:
    """Resolve local files referenced by relative or public document links."""
    document = find_scenario_document()
    text = document.read_text(encoding="utf-8")
    relative_resources = set(LOCAL_RESOURCE_PATTERN.findall(text))
    public_resources = set(PUBLIC_RESOURCE_PATTERN.findall(text))
    missing = [
        resource
        for resource in sorted(relative_resources)
        if not (DOCS_DIR / resource).is_file()
    ]
    if missing:
        formatted = "\n".join(f"  - {resource}" for resource in missing)
        raise FileNotFoundError(f"missing local document resources:\n{formatted}")
    if not relative_resources and not public_resources:
        raise ValueError("scenario document does not contain resource links")
    print(
        f"OK  {document.name}: {len(relative_resources)} local and "
        f"{len(public_resources)} public resources referenced"
    )


def main() -> int:
    try:
        regenerate_figures()
        validate_outputs()
        validate_document_links()
    except (OSError, RuntimeError, ValueError, ET.ParseError) as error:
        print(f"ERROR  {error}", file=sys.stderr)
        return 1
    print("PASS  indoor-entryway figures and links are reproducible")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
