"""Generate an idealized indoor wall-multipath geometry figure."""

import matplotlib.pyplot as plt
import numpy as np
from matplotlib.lines import Line2D

from scientific_figure_style import COLORS, configure_style, save_figure


OUTPUT_STEM = "indoor-entryway-multipath-geometry"


def build_figure() -> plt.Figure:
    """Build a direct/reflected-path diagram using the image method."""
    configure_style()

    radar = np.array([0.0, 0.0])
    target = np.array([1.15, 2.75])
    wall_x = 3.0
    image_target = np.array([2 * wall_x - target[0], target[1]])
    fraction = wall_x / image_target[0]
    reflection = radar + fraction * (image_target - radar)

    direct_one_way = np.linalg.norm(target - radar)
    reflected_one_way = np.linalg.norm(reflection - radar) + np.linalg.norm(target - reflection)

    fig = plt.figure(figsize=(8.2, 4.5), constrained_layout=True)
    grid = fig.add_gridspec(1, 2, width_ratios=[1.6, 1.0])
    ax = fig.add_subplot(grid[0, 0])
    note = fig.add_subplot(grid[0, 1])

    ax.set_xlim(-0.55, 5.45)
    ax.set_ylim(-0.45, 3.75)
    ax.set_aspect("equal", adjustable="box")

    # Room boundary and the mirror-side virtual region.
    ax.plot([-0.25, wall_x], [-0.2, -0.2], color=COLORS["ink"], linewidth=1.2)
    ax.plot([wall_x, wall_x], [-0.2, 3.5], color=COLORS["ink"], linewidth=2.0)
    ax.axvspan(wall_x, 5.35, color="#f4f4f4", zorder=0)
    ax.text(wall_x + 0.08, 3.40, "墙体镜像侧", color=COLORS["muted"], ha="left", va="top")

    # Direct path and idealized reflected path.
    ax.plot(
        [radar[0], target[0]],
        [radar[1], target[1]],
        color=COLORS["recede"],
        linewidth=1.8,
        zorder=2,
    )
    ax.plot(
        [radar[0], reflection[0], target[0]],
        [radar[1], reflection[1], target[1]],
        color=COLORS["multipath"],
        linewidth=1.8,
        zorder=2,
    )
    ax.plot(
        [radar[0], image_target[0]],
        [radar[1], image_target[1]],
        color=COLORS["multipath"],
        linewidth=0.9,
        linestyle="--",
        alpha=0.75,
        zorder=1,
    )

    ax.scatter(*radar, marker="s", s=48, color=COLORS["ink"], zorder=5)
    ax.scatter(*target, s=58, facecolor="white", edgecolor=COLORS["recede"], linewidth=1.4, zorder=5)
    ax.scatter(*reflection, marker="D", s=32, facecolor="white", edgecolor=COLORS["multipath"], linewidth=1.2, zorder=5)
    ax.scatter(*image_target, s=58, facecolor="white", edgecolor=COLORS["multipath"], linewidth=1.4, linestyle="--", zorder=5)

    ax.text(radar[0] - 0.08, radar[1] - 0.16, "雷达 $O$", ha="right", va="top")
    ax.text(target[0] - 0.05, target[1] + 0.16, "真实目标 $P$", color=COLORS["recede"], ha="center")
    ax.text(reflection[0] + 0.10, reflection[1], "反射点 $W$", color=COLORS["multipath"], ha="left", va="center")
    ax.text(
        image_target[0],
        image_target[1] + 0.17,
        "镜像目标 $P'$\n（墙后表观位置）",
        color=COLORS["multipath"],
        ha="center",
        va="bottom",
    )

    ax.text(0.30, 1.55, r"$|OP|$", color=COLORS["recede"], rotation=67, ha="center")
    ax.text(1.45, 0.92, r"$|OW|$", color=COLORS["multipath"], rotation=30, ha="center")
    ax.text(2.15, 2.40, r"$|WP|$", color=COLORS["multipath"], rotation=-32, ha="center")

    legend = [
        Line2D([0], [0], color=COLORS["recede"], linewidth=1.8, label="直达路径"),
        Line2D([0], [0], color=COLORS["multipath"], linewidth=1.8, label="墙面反射路径"),
        Line2D([0], [0], color=COLORS["multipath"], linewidth=0.9, linestyle="--", label="镜像延长线"),
    ]
    ax.legend(handles=legend, frameon=False, loc="upper left")
    ax.set_xlabel("横向位置 $x$")
    ax.set_ylabel("纵向位置 $y$")
    ax.set_xticks([])
    ax.set_yticks([])
    ax.spines[["top", "right", "left", "bottom"]].set_visible(False)
    ax.set_title("一次墙面反射的镜像法几何", fontsize=10, pad=8)

    note.axis("off")
    note.set_title("路径长度与表观偏差", fontsize=10, pad=8)
    note.text(
        0.03,
        0.88,
        r"$L_d=2\,\|P-O\|$"
        + "\n\n"
        + r"$L_r=2\,(\|W-O\|+\|P-W\|)$"
        + "\n\n"
        + r"$R_d=L_d/2$"
        + "\n"
        + r"$R_r=L_r/2$"
        + "\n\n"
        + r"$\Delta R=R_r-R_d$"
        + "\n"
        + r"$\qquad=(L_r-L_d)/2>0$",
        transform=note.transAxes,
        ha="left",
        va="top",
        linespacing=1.35,
        fontsize=10,
    )
    note.text(
        0.03,
        0.34,
        "反射路径比直达路径更长，\n"
        "可能形成距离偏大的墙后点，\n"
        "或在连续帧中形成贴墙假轨迹。",
        transform=note.transAxes,
        color=COLORS["multipath"],
        ha="left",
        va="top",
        linespacing=1.55,
    )
    note.text(
        0.03,
        0.08,
        "理想一次反射模型；实际室内还可能存在\n地面、门框和多次反射。",
        transform=note.transAxes,
        color=COLORS["muted"],
        ha="left",
        va="bottom",
        fontsize=8,
        linespacing=1.4,
    )

    # Keep the computed values live so geometry edits cannot leave stale formulas.
    assert reflected_one_way > direct_one_way
    return fig


def main() -> None:
    """Generate PNG and SVG artifacts."""
    save_figure(build_figure(), __file__, OUTPUT_STEM)


if __name__ == "__main__":
    main()
