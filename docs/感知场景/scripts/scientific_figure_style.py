"""Shared deterministic style and export helpers for entryway figures."""

from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt


COLORS = {
    "ink": "#202020",
    "muted": "#666666",
    "grid": "#d7d7d7",
    "approach": "#b14d32",
    "recede": "#2f6f9f",
    "stationary": "#7a5a96",
    "multipath": "#c27a22",
}


def configure_style() -> None:
    """Apply the restrained publication style shared by all scene figures."""
    plt.rcParams.update(
        {
            "font.family": "sans-serif",
            "font.sans-serif": ["Microsoft YaHei", "SimHei", "DejaVu Sans"],
            "font.size": 8.5,
            "axes.linewidth": 0.8,
            "axes.unicode_minus": False,
            "mathtext.fontset": "dejavusans",
            "svg.fonttype": "path",
            "svg.hashsalt": "ctsai-a100-entryway-scientific",
        }
    )


def save_figure(fig: plt.Figure, script_file: str, output_stem: str) -> None:
    """Write matching deterministic PNG and SVG files beside the scene docs."""
    output_dir = Path(script_file).resolve().parents[1] / "images"
    output_dir.mkdir(parents=True, exist_ok=True)
    fig.savefig(
        output_dir / f"{output_stem}.png",
        dpi=300,
        bbox_inches="tight",
        facecolor="white",
        metadata={"Software": "Matplotlib"},
    )
    svg_path = output_dir / f"{output_stem}.svg"
    fig.savefig(
        svg_path,
        bbox_inches="tight",
        facecolor="white",
        metadata={"Date": None, "Creator": "Matplotlib"},
    )
    plt.close(fig)

    normalized_svg = "\n".join(
        line.rstrip() for line in svg_path.read_text(encoding="utf-8").splitlines()
    )
    svg_path.write_text(f"{normalized_svg}\n", encoding="utf-8", newline="\n")
