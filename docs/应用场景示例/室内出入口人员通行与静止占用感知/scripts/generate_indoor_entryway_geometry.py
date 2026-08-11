"""Generate the symbolic geometry figure for the indoor entryway experiment."""

from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.patches import Arc, Rectangle


OUTPUT_STEM = "indoor-entryway-test-geometry"


def configure_style() -> None:
    """Use a restrained, publication-oriented Matplotlib style."""
    plt.rcParams.update(
        {
            "font.family": "sans-serif",
            "font.sans-serif": ["Microsoft YaHei", "SimHei", "DejaVu Sans"],
            "font.size": 9,
            "axes.linewidth": 0.8,
            "axes.unicode_minus": False,
            "mathtext.fontset": "dejavusans",
            "svg.fonttype": "path",
            "svg.hashsalt": "ctsai-a100-entryway",
        }
    )


def build_figure() -> plt.Figure:
    """Build a symbolic top-view geometry without inventing field dimensions."""
    configure_style()

    # Normalized drawing coordinates. Axis ticks use symbolic dimensions so
    # these layout values are not interpreted as unmeasured field data.
    corridor_width = 3.2
    door_width = 1.4
    near_distance = 2.0
    far_distance = 4.0

    fig, ax = plt.subplots(figsize=(6.8, 4.6), constrained_layout=True)
    ax.set_xlim(-2.0, 2.0)
    ax.set_ylim(-0.38, 4.65)
    ax.set_aspect("equal", adjustable="box")

    # Corridor boundaries and the wall segment containing the doorway.
    wall_color = "#202020"
    ax.plot(
        [-corridor_width / 2, -corridor_width / 2],
        [0, 4.45],
        color=wall_color,
        linewidth=1.2,
    )
    ax.plot(
        [corridor_width / 2, corridor_width / 2],
        [0, 4.45],
        color=wall_color,
        linewidth=1.2,
    )
    ax.plot(
        [-corridor_width / 2, -door_width / 2],
        [0, 0],
        color=wall_color,
        linewidth=2.0,
    )
    ax.plot(
        [door_width / 2, corridor_width / 2],
        [0, 0],
        color=wall_color,
        linewidth=2.0,
    )

    # Coordinate origin and sensor orientation.
    ax.scatter([0], [0.16], marker="s", s=52, color="#202020", zorder=5)
    ax.annotate(
        "CTSAI-A100\n$O=(0,0)$",
        xy=(0, 0.16),
        xytext=(0.22, 0.33),
        ha="left",
        va="center",
        arrowprops={"arrowstyle": "-", "color": "#202020", "linewidth": 0.8},
    )
    ax.annotate(
        "",
        xy=(0, 1.02),
        xytext=(0, 0.28),
        arrowprops={"arrowstyle": "->", "color": "#202020", "linewidth": 1.0},
    )
    ax.text(-0.08, 0.82, "$+y$", ha="right", va="center")

    # Reference lines. Only d_n has a preliminary measured value.
    ax.axhline(
        near_distance,
        xmin=0.10,
        xmax=0.90,
        color="#2f6f9f",
        linewidth=1.1,
        linestyle=(0, (5, 3)),
    )
    ax.axhline(
        far_distance,
        xmin=0.10,
        xmax=0.90,
        color="#666666",
        linewidth=1.0,
        linestyle=(0, (3, 3)),
    )
    ax.text(
        -1.48,
        near_distance + 0.08,
        "$y=d_n$  （近端，$d_n\\approx2\\,\\mathrm{m}$）",
        color="#2f6f9f",
        ha="left",
        va="bottom",
    )
    ax.text(
        -1.48,
        far_distance + 0.08,
        "$y=d_f$  （远端，待测）",
        color="#4f4f4f",
        ha="left",
        va="bottom",
    )

    # Symbolic stationary observation interval.
    stationary = Rectangle(
        (-0.72, 2.38),
        1.44,
        0.52,
        fill=False,
        hatch="////",
        edgecolor="#777777",
        linewidth=0.9,
    )
    ax.add_patch(stationary)
    ax.text(0, 2.64, "静止观察区", ha="center", va="center")

    # Motion vectors and their radial-velocity signs.
    ax.annotate(
        "",
        xy=(-0.43, 3.65),
        xytext=(-0.43, 1.15),
        arrowprops={"arrowstyle": "->", "color": "#2f6f9f", "linewidth": 1.4},
    )
    ax.text(-0.53, 3.22, "远离", color="#2f6f9f", ha="right", va="center")
    ax.text(-0.53, 3.03, "$v_r>0$", color="#2f6f9f", ha="right", va="center")

    ax.annotate(
        "",
        xy=(0.43, 1.15),
        xytext=(0.43, 3.65),
        arrowprops={"arrowstyle": "->", "color": "#b14d32", "linewidth": 1.4},
    )
    ax.text(0.53, 1.37, "靠近", color="#b14d32", ha="left", va="center")
    ax.text(0.53, 1.18, "$v_r<0$", color="#b14d32", ha="left", va="center")

    # Door opening and symbolic width dimensions.
    ax.annotate(
        "",
        xy=(-door_width / 2, -0.16),
        xytext=(door_width / 2, -0.16),
        arrowprops={"arrowstyle": "<->", "color": "#202020", "linewidth": 0.8},
    )
    ax.text(0, -0.28, "$W_d$（门宽，待测）", ha="center", va="top")

    ax.annotate(
        "",
        xy=(-corridor_width / 2, 4.35),
        xytext=(corridor_width / 2, 4.35),
        arrowprops={"arrowstyle": "<->", "color": "#202020", "linewidth": 0.8},
    )
    ax.text(0, 4.43, "$W_c$（走廊宽度，待测）", ha="center", va="bottom")

    # A small angle marker communicates that sensor orientation must be logged.
    ax.add_patch(
        Arc(
            (0, 0.16),
            0.60,
            0.60,
            theta1=63,
            theta2=117,
            color="#777777",
            linewidth=0.8,
        )
    )
    ax.text(0.20, 0.56, "$\\theta$", color="#555555", ha="left", va="center")

    ax.set_xticks(
        [-corridor_width / 2, 0, corridor_width / 2],
        ["$-W_c/2$", "$0$", "$W_c/2$"],
    )
    ax.set_yticks(
        [0, near_distance, far_distance],
        ["$0$", "$d_n$", "$d_f$"],
    )
    ax.set_xlabel("横向位置 $x$")
    ax.set_ylabel("纵向距离 $y$")
    ax.set_title("室内出入口测试几何模型", pad=9, fontsize=10)
    ax.grid(False)
    ax.spines[["top", "right"]].set_visible(False)

    return fig


def main() -> None:
    """Write matching PNG and SVG outputs next to the scene documentation."""
    output_dir = Path(__file__).resolve().parents[1] / "images"
    output_dir.mkdir(parents=True, exist_ok=True)
    fig = build_figure()
    fig.savefig(
        output_dir / f"{OUTPUT_STEM}.png",
        dpi=300,
        bbox_inches="tight",
        facecolor="white",
        metadata={"Software": "Matplotlib"},
    )
    svg_path = output_dir / f"{OUTPUT_STEM}.svg"
    fig.savefig(
        svg_path,
        bbox_inches="tight",
        facecolor="white",
        metadata={"Date": None, "Creator": "Matplotlib"},
    )
    plt.close(fig)

    # Matplotlib writes trailing spaces in multi-line SVG path definitions.
    # Normalize them so the generated artifact passes `git diff --check`.
    normalized_svg = "\n".join(
        line.rstrip() for line in svg_path.read_text(encoding="utf-8").splitlines()
    )
    svg_path.write_text(f"{normalized_svg}\n", encoding="utf-8", newline="\n")


if __name__ == "__main__":
    main()
