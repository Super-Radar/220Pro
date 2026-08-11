"""Generate idealized range-time curves for the entryway scenarios."""

import matplotlib.pyplot as plt
import numpy as np

from scientific_figure_style import COLORS, configure_style, save_figure


OUTPUT_STEM = "indoor-entryway-ideal-range-time"


def style_axis(ax: plt.Axes, title: str) -> None:
    """Apply shared normalized axes and restrained grid styling."""
    ax.set_xlim(0, 1)
    ax.set_ylim(0.18, 1.05)
    ax.set_title(title, fontsize=9.5, pad=6)
    ax.set_xlabel(r"归一化时间 $t/T$")
    ax.set_ylabel(r"归一化距离 $r/d_f$")
    ax.grid(True, color=COLORS["grid"], linewidth=0.6)
    ax.spines[["top", "right"]].set_visible(False)


def build_figure() -> plt.Figure:
    """Build four idealized kinematic comparisons without measured values."""
    configure_style()
    t = np.linspace(0, 1, 401)
    fig, axes = plt.subplots(2, 2, figsize=(7.4, 5.8), constrained_layout=True)

    ax = axes[0, 0]
    style_axis(ax, "S1 / S2  径向靠近与远离")
    r_approach = 0.92 - 0.62 * t
    r_recede = 0.30 + 0.62 * t
    ax.plot(t, r_approach, color=COLORS["approach"], linewidth=1.8, label=r"靠近：$\dot r<0$")
    ax.plot(t, r_recede, color=COLORS["recede"], linewidth=1.8, label=r"远离：$\dot r>0$")
    ax.legend(frameon=False, loc="center right")

    ax = axes[0, 1]
    style_axis(ax, "S3 / S4  静止与停走转换")
    r_stationary = np.full_like(t, 0.68)
    r_stop = np.piecewise(
        t,
        [t < 0.34, (t >= 0.34) & (t <= 0.66), t > 0.66],
        [
            lambda x: 0.94 - 0.88 * x,
            lambda x: np.full_like(x, 0.64),
            lambda x: 0.64 - 0.82 * (x - 0.66),
        ],
    )
    ax.plot(t, r_stationary, color=COLORS["muted"], linewidth=1.2, linestyle="--", label=r"S3：$\dot r\approx0$")
    ax.plot(t, r_stop, color=COLORS["stationary"], linewidth=1.8, label="S4：停止后继续")
    ax.axvspan(0.34, 0.66, color=COLORS["stationary"], alpha=0.10)
    ax.text(0.50, 0.57, r"$\Delta t_s$", color=COLORS["stationary"], ha="center", va="top")
    ax.legend(frameon=False, loc="upper right")

    ax = axes[1, 0]
    style_axis(ax, "S5  横向经过")
    d_perp = 0.42
    lateral = np.sqrt(d_perp**2 + (1.20 * (t - 0.5)) ** 2)
    ax.plot(t, lateral, color=COLORS["stationary"], linewidth=1.8)
    ax.axvline(0.5, color=COLORS["muted"], linewidth=0.9, linestyle="--")
    ax.scatter([0.5], [d_perp], s=24, facecolor="white", edgecolor=COLORS["stationary"], zorder=4)
    ax.text(
        0.5,
        0.26,
        r"$r(t)=\sqrt{d_\perp^2+[v_x(t-t_c)]^2}$",
        color=COLORS["stationary"],
        ha="center",
    )

    ax = axes[1, 1]
    style_axis(ax, "S6  靠近后折返")
    t_return = 0.56
    r_turn = np.where(
        t <= t_return,
        0.94 - 1.02 * t,
        0.94 - 1.02 * t_return + 0.92 * (t - t_return),
    )
    before = t <= t_return
    after = t >= t_return
    ax.plot(t[before], r_turn[before], color=COLORS["approach"], linewidth=1.8)
    ax.plot(t[after], r_turn[after], color=COLORS["recede"], linewidth=1.8)
    ax.axvline(t_return, color=COLORS["muted"], linewidth=0.9, linestyle="--")
    ax.scatter([t_return], [r_turn[np.argmin(np.abs(t - t_return))]], s=26, facecolor="white", edgecolor=COLORS["ink"], zorder=4)
    ax.text(t_return + 0.03, 0.30, r"$t=t_r$", ha="left", va="center")
    ax.text(0.18, 0.80, r"$\dot r<0$", color=COLORS["approach"], ha="center")
    ax.text(0.80, 0.69, r"$\dot r>0$", color=COLORS["recede"], ha="center")

    fig.text(
        0.5,
        -0.015,
        "理想运动学示意；曲线不表示实测轨迹、雷达量程或检测性能",
        color=COLORS["muted"],
        ha="center",
        fontsize=8,
    )
    return fig


def main() -> None:
    """Generate PNG and SVG artifacts."""
    save_figure(build_figure(), __file__, OUTPUT_STEM)


if __name__ == "__main__":
    main()
