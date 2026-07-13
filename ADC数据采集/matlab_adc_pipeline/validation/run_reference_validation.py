"""Independent NumPy reference validation for the CTSAI-A100 MATLAB demo."""

from __future__ import annotations

import csv
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

C = 299_792_458.0
CANVAS = (1100, 650)

PROFILES = {
    "near": dict(marker="f1", bandwidth=750e6, ramp=104.65e-6,
                 period=108.5e-6, chirps=128, packed=1024, nfft=2048),
    "far": dict(marker="f0", bandwidth=300e6, ramp=43e-6,
                period=48e-6, chirps=256, packed=512, nfft=1024),
}


def load_adc(files: list[Path], packed: int, chirps: int) -> np.ndarray:
    channels = []
    expected = packed * chirps
    for path in files:
        values = np.loadtxt(path, delimiter=",").reshape(-1)
        values = values[np.isfinite(values)]
        if values.size == expected + 1:
            values = values[1:]
        if values.size != expected:
            raise ValueError(f"{path.name}: {values.size} values, expected {expected}")
        words = values.astype(np.uint32)
        high = (words >> 16).astype(np.uint16).view(np.int16)
        low = (words & 65535).astype(np.uint16).view(np.int16)
        unpacked = np.empty(expected * 2, dtype=np.float64)
        unpacked[0::2] = high
        unpacked[1::2] = low
        channels.append(unpacked.reshape((packed * 2, chirps), order="F"))
    adc = np.stack(channels, axis=2)
    return adc - adc.mean(axis=0, keepdims=True)


def cfar(power: np.ndarray, training=(8, 6), guard=(2, 2), pfa=1e-4) -> np.ndarray:
    tr, td = training
    gr, gd = guard
    kernel = np.ones((2*(tr+gr)+1, 2*(td+gd)+1))
    kernel[tr:tr+2*gr+1, td:td+2*gd+1] = 0
    count = kernel.sum()
    padded = np.pad(power, ((tr+gr, tr+gr), (td+gd, td+gd)), mode="constant")
    noise = np.zeros_like(power)
    for r, d in np.argwhere(kernel):
        noise += padded[r:r+power.shape[0], d:d+power.shape[1]]
    noise /= count
    alpha = count * (pfa ** (-1/count) - 1)
    mask = power > alpha * noise
    local = np.ones_like(mask)
    for dr in (-1, 0, 1):
        for dd in (-1, 0, 1):
            if dr or dd:
                local &= power >= np.roll(power, (dr, dd), axis=(0, 1))
    mask &= local
    border_r, border_d = tr + gr, td + gd
    mask[:border_r] = mask[-border_r:] = False
    mask[:, :border_d] = mask[:, -border_d:] = False
    return mask


def heatmap_image(values: np.ndarray, title: str, cells=None) -> Image.Image:
    lo, hi = np.percentile(values, (1, 99.5))
    norm = np.clip((values-lo)/(hi-lo+1e-12), 0, 1)
    red = np.clip(1.5-abs(4*norm-3), 0, 1)
    green = np.clip(1.5-abs(4*norm-2), 0, 1)
    blue = np.clip(1.5-abs(4*norm-1), 0, 1)
    rgb = (255*np.stack((red, green, blue), axis=2)).astype(np.uint8)
    plot = Image.fromarray(np.flipud(rgb)).resize((1000, 540), Image.Resampling.BILINEAR)
    canvas = Image.new("RGB", CANVAS, "white")
    canvas.paste(plot, (70, 70))
    draw = ImageDraw.Draw(canvas)
    draw.text((70, 25), title, fill="black")
    draw.text((450, 625), "Doppler / velocity bins", fill="black")
    draw.text((5, 320), "Range bins", fill="black")
    if cells:
        rows, cols = values.shape
        for r, d in cells:
            x = 70 + int(d/(cols-1)*1000)
            y = 70 + int((rows-1-r)/(rows-1)*540)
            draw.ellipse((x-5, y-5, x+5, y+5), outline="red", width=2)
    return canvas


def line_image(x: np.ndarray, y: np.ndarray, title: str) -> Image.Image:
    canvas = Image.new("RGB", CANVAS, "white")
    draw = ImageDraw.Draw(canvas)
    draw.text((70, 25), title, fill="black")
    draw.rectangle((70, 70, 1070, 610), outline="black")
    ymin, ymax = np.percentile(y, (1, 99.5))
    points = [(70+int(i/(len(x)-1)*1000), 610-int(np.clip((v-ymin)/(ymax-ymin+1e-12),0,1)*540))
              for i, v in enumerate(y)]
    draw.line(points, fill=(20, 80, 180), width=2)
    draw.text((470, 625), "Range", fill="black")
    return canvas


def polar_image(rows: list[tuple], title: str) -> Image.Image:
    canvas = Image.new("RGB", CANVAS, "white")
    draw = ImageDraw.Draw(canvas)
    cx, cy, radius = 550, 340, 270
    draw.text((70, 25), title, fill="black")
    for frac in (0.25, 0.5, 0.75, 1.0):
        rr = int(radius*frac)
        draw.ellipse((cx-rr, cy-rr, cx+rr, cy+rr), outline=(180,180,180))
    max_range = max((row[0] for row in rows), default=1.0)
    for rng, _, angle, _ in rows:
        rr = radius*rng/max_range
        theta = np.radians(angle-90)
        x, y = cx+rr*np.cos(theta), cy+rr*np.sin(theta)
        draw.ellipse((x-5, y-5, x+5, y+5), fill="red")
    return canvas


def save_results(name: str, cfg: dict, files: list[Path], output: Path) -> None:
    adc = load_adc(files, cfg["packed"], cfg["chirps"])
    range_fft = np.fft.fft(adc * np.hanning(adc.shape[0])[:, None, None],
                           cfg["nfft"], axis=0)[:cfg["nfft"]//2]
    range_fft -= range_fft.mean(axis=1, keepdims=True)
    rd = np.fft.fftshift(np.fft.fft(
        range_fft * np.hanning(cfg["chirps"])[None, :, None],
        cfg["chirps"], axis=1), axes=1)
    power = np.mean(np.abs(rd)**2, axis=2)
    power_db = 10*np.log10(power + np.finfo(float).eps)
    slope = cfg["bandwidth"] / cfg["ramp"]
    range_bin = C*25e6/(2*slope*cfg["nfft"])
    velocity_bin = (C/76.3e9)/(2*cfg["chirps"]*cfg["period"])
    ranges = np.arange(power.shape[0])*range_bin
    velocities = (np.arange(cfg["chirps"])-cfg["chirps"]//2)*velocity_bin
    power[(ranges < 0.5) | (ranges > 0.9*ranges[-1])] = 0
    mask = cfar(power)
    cells = np.argwhere(mask)
    cells = sorted(cells, key=lambda x: power_db[tuple(x)], reverse=True)[:32]

    output.mkdir(parents=True, exist_ok=True)
    rows = []
    for r, d in cells:
        spectrum = np.abs(np.fft.fftshift(np.fft.fft(rd[r, d, :], 128)))
        spatial = (np.argmax(spectrum)-64)/128
        angle = np.degrees(np.arcsin(np.clip(spatial/0.5, -1, 1)))
        rows.append((ranges[r], velocities[d], angle, power_db[r, d]))
    with (output/"detections.csv").open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(("range_m", "velocity_mps", "angle_deg", "power_db"))
        writer.writerows(rows)

    line_image(ranges, 20*np.log10(np.abs(range_fft[:, 0, 0])+1e-12),
               f"CTSAI-A100 {name} reference range spectrum").save(output/"01_range_spectrum.png")
    heatmap_image(power_db, f"CTSAI-A100 {name} reference Range-Doppler map").save(
        output/"02_range_doppler_map.png")
    heatmap_image(power_db, f"CTSAI-A100 {name} reference CA-CFAR detections", cells).save(
        output/"03_cfar_detections.png")
    polar_image(rows, f"CTSAI-A100 {name} reference angle and range").save(
        output/"04_angle_range.png")

    summary = (f"profile={name}\nadc_shape={adc.shape}\nrd_shape={rd.shape}\n"
               f"finite={np.isfinite(power_db).all()}\ndetections={len(rows)}\n")
    (output/"validation.txt").write_text(summary, encoding="utf-8")
    print(summary, end="")


def main() -> None:
    validation_dir = Path(__file__).resolve().parent
    repo = validation_dir.parents[2]
    data_dir = repo/"ADC数据采集"/"示例adc数据和结果"
    all_files = list(data_dir.glob("*.txt"))
    for name, cfg in PROFILES.items():
        files = sorted(p for p in all_files if f"_{cfg['marker']}_" in p.name)
        if len(files) != 4:
            raise FileNotFoundError(f"{name}: expected four files, found {len(files)}")
        save_results(name, cfg, files, validation_dir/"results"/name)


if __name__ == "__main__":
    main()
