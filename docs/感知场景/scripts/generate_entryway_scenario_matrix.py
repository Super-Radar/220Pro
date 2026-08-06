"""Generate the S0-S6 indoor-entryway scenario matrix."""

import matplotlib.pyplot as plt
from matplotlib.patches import Circle, Rectangle

from scientific_figure_style import COLORS, configure_style, save_figure


OUTPUT_STEM = "indoor-entryway-scenario-matrix"


def draw_base(ax: plt.Axes, title: str) -> None:
    """Draw the common symbolic corridor and reference lines."""
    ax.set_xlim(-1.25, 1.25)
    ax.set_ylim(-0.05, 4.15)
    ax.set_aspect("equal", adjustable="box")
    ax.plot([-1, -1], [0, 4], color=COLORS["ink"], linewidth=1.0)
    ax.plot([1, 1], [0, 4], color=COLORS["ink"], linewidth=1.0)
    ax.scatter([0], [0.2], marker="s", s=22, color=COLORS["ink"], zorder=5)
    ax.text(0.08, 0.19, "$O$", ha="left", va="center")
    ax.axhline(1.45, color=COLORS["recede"], linewidth=0.8, linestyle=(0, (4, 3)))
    ax.axhline(3.35, color=COLORS["muted"], linewidth=0.8, linestyle=(0, (2, 3)))
    ax.text(-0.94, 1.50, "$d_n$", color=COLORS["recede"], ha="left", va="bottom")
    ax.text(-0.94, 3.40, "$d_f$", color=COLORS["muted"], ha="left", va="bottom")
    ax.set_title(title, fontsize=9.5, pad=5)
    ax.set_xticks([])
    ax.set_yticks([])
    for spine in ax.spines.values():
        spine.set_visible(False)


def arrow(ax: plt.Axes, start, end, color: str) -> None:
    """Draw a consistent motion arrow."""
    ax.annotate(
        "",
        xy=end,
        xytext=start,
        arrowprops={"arrowstyle": "->", "color": color, "linewidth": 1.6},
    )


def target(ax: plt.Axes, xy, color: str = COLORS["ink"]) -> None:
    """Draw a target marker."""
    ax.add_patch(Circle(xy, 0.09, facecolor="white", edgecolor=color, linewidth=1.2))


def build_figure() -> plt.Figure:
    """Build seven controlled scenarios and one notation panel."""
    configure_style()
    fig, axes = plt.subplots(2, 4, figsize=(8.6, 6.7), constrained_layout=True)

    draw_base(axes[0, 0], "S0  空场基线")
    axes[0, 0].text(0, 2.35, r"$\varnothing$", fontsize=18, color=COLORS["muted"], ha="center")

    draw_base(axes[0, 1], "S1  靠近雷达")
    target(axes[0, 1], (0, 3.35), COLORS["approach"])
    arrow(axes[0, 1], (0, 3.12), (0, 0.95), COLORS["approach"])
    axes[0, 1].text(0.12, 2.25, r"$\dot r<0$", color=COLORS["approach"], ha="left")

    draw_base(axes[0, 2], "S2  远离雷达")
    target(axes[0, 2], (0, 0.95), COLORS["recede"])
    arrow(axes[0, 2], (0, 1.16), (0, 3.38), COLORS["recede"])
    axes[0, 2].text(0.12, 2.25, r"$\dot r>0$", color=COLORS["recede"], ha="left")

    draw_base(axes[0, 3], "S3  静止占用")
    axes[0, 3].add_patch(
        Rectangle(
            (-0.65, 2.05),
            1.3,
            0.55,
            fill=False,
            hatch="////",
            edgecolor=COLORS["stationary"],
            linewidth=0.9,
        )
    )
    target(axes[0, 3], (0, 2.32), COLORS["stationary"])
    axes[0, 3].text(0, 2.78, r"$\dot r\approx0$", color=COLORS["stationary"], ha="center")

    draw_base(axes[1, 0], "S4  停止后继续")
    target(axes[1, 0], (0, 3.45), COLORS["approach"])
    arrow(axes[1, 0], (0, 3.22), (0, 2.42), COLORS["approach"])
    axes[1, 0].plot([-0.16, 0.16], [2.24, 2.24], color=COLORS["stationary"], linewidth=2.2)
    axes[1, 0].text(0.2, 2.24, r"$\Delta t_s$", color=COLORS["stationary"], ha="left", va="center")
    arrow(axes[1, 0], (0, 2.05), (0, 0.92), COLORS["approach"])

    draw_base(axes[1, 1], "S5  横向经过")
    target(axes[1, 1], (-0.78, 2.3), COLORS["stationary"])
    arrow(axes[1, 1], (-0.62, 2.3), (0.78, 2.3), COLORS["stationary"])
    axes[1, 1].text(0, 2.55, "$x(t)$", color=COLORS["stationary"], ha="center")
    axes[1, 1].plot([0, 0], [0.2, 2.3], color=COLORS["grid"], linewidth=0.8, linestyle="--")

    draw_base(axes[1, 2], "S6  靠近后折返")
    target(axes[1, 2], (0, 3.5), COLORS["approach"])
    arrow(axes[1, 2], (-0.08, 3.25), (-0.08, 1.55), COLORS["approach"])
    target(axes[1, 2], (-0.08, 1.45), COLORS["ink"])
    arrow(axes[1, 2], (0.08, 1.55), (0.08, 3.18), COLORS["recede"])
    axes[1, 2].text(0.2, 1.42, "$t=t_r$", ha="left", va="center")

    ax = axes[1, 3]
    ax.axis("off")
    ax.set_title("符号约定", fontsize=9.5, pad=5)
    ax.text(
        0.02,
        0.88,
        "$O$：雷达相位中心\n"
        "$d_n$：近端参考线\n"
        "$d_f$：远端参考线\n"
        + r"$\dot r=\mathrm{d}r/\mathrm{d}t$"
        + "\n"
        + r"$\Delta t_s$：静止时段"
        + "\n"
        + "$t_r$：折返时刻",
        transform=ax.transAxes,
        ha="left",
        va="top",
        linespacing=1.7,
    )
    ax.text(
        0.02,
        0.12,
        "符号图，不表示实测视场或性能",
        transform=ax.transAxes,
        color=COLORS["muted"],
        ha="left",
        va="bottom",
        fontsize=8,
    )

    return fig


def main() -> None:
    """Generate PNG and SVG artifacts."""
    save_figure(build_figure(), __file__, OUTPUT_STEM)


if __name__ == "__main__":
    main()
