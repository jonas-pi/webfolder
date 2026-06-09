"""从完整应用图标 PNG 中去除白色前景，仅保留蓝色渐变背景。"""
from __future__ import annotations

from pathlib import Path

import cv2
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "AppScope/resources/base/media/app_icon_source.png"
OUT_BG = ROOT / "AppScope/resources/base/media/background.png"
ENTRY_BG = ROOT / "entry/src/main/resources/base/media/background.png"


def is_foreground_white(rgb: np.ndarray) -> np.ndarray:
    r, g, b = rgb[:, :, 0].astype(np.int16), rgb[:, :, 1].astype(np.int16), rgb[:, :, 2].astype(np.int16)
    bright = r + g + b > 600
    neutral = (np.abs(r - g) < 50) & (np.abs(g - b) < 50)
    return bright & neutral


def is_blue_background(rgb: np.ndarray) -> np.ndarray:
    r, g, b = rgb[:, :, 0].astype(np.int16), rgb[:, :, 1].astype(np.int16), rgb[:, :, 2].astype(np.int16)
    return (b > r + 12) & (b > g + 3) & (b > 70)


def build_icon_mask(rgb: np.ndarray) -> np.ndarray:
    blue = is_blue_background(rgb)
    white = is_foreground_white(rgb)
    icon = blue | white
    kernel = np.ones((7, 7), np.uint8)
    icon = cv2.morphologyEx(icon.astype(np.uint8) * 255, cv2.MORPH_CLOSE, kernel, iterations=4)
    icon = cv2.morphologyEx(icon, cv2.MORPH_OPEN, kernel, iterations=2)
    return icon > 0


def luminance(rgb: np.ndarray) -> np.ndarray:
    return 0.299 * rgb[:, 0] + 0.587 * rgb[:, 1] + 0.114 * rgb[:, 2]


def sample_vertical_gradient(rgb: np.ndarray, icon_mask: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    blue_only = icon_mask & is_blue_background(rgb) & ~is_foreground_white(rgb)
    ys, xs = np.where(blue_only)
    if len(ys) == 0:
        return np.array([58, 182, 252], dtype=np.float32), np.array([9, 69, 179], dtype=np.float32)

    colors = rgb[ys, xs].astype(np.float32)
    lum = luminance(colors)
    h = rgb.shape[0]

    top_idx = ys < h * 0.25
    bottom_idx = ys > h * 0.75

    top_colors = colors[top_idx]
    bottom_colors = colors[bottom_idx]
    top_lum = lum[top_idx]
    bottom_lum = lum[bottom_idx]

    if len(top_colors):
        n = max(1, int(len(top_colors) * 0.35))
        top = np.median(top_colors[np.argsort(top_lum)[-n:]], axis=0)
    else:
        top = np.median(colors, axis=0)

    if len(bottom_colors):
        n = max(1, int(len(bottom_colors) * 0.35))
        bottom = np.median(bottom_colors[np.argsort(bottom_lum)[:n]], axis=0)
    else:
        bottom = np.median(colors, axis=0)

    return top, bottom


def render_gradient(size: int, top: np.ndarray, bottom: np.ndarray) -> np.ndarray:
    t = np.linspace(0.0, 1.0, size, dtype=np.float32)[:, None]
    grad = top[None, :] * (1.0 - t) + bottom[None, :] * t
    grad = np.broadcast_to(grad[:, None, :], (size, size, 3)).copy()
    return np.clip(grad, 0, 255).astype(np.uint8)


def main() -> None:
    rgb = np.array(Image.open(SRC).convert("RGB"))
    icon_mask = build_icon_mask(rgb)
    top, bottom = sample_vertical_gradient(rgb, icon_mask)
    out = render_gradient(rgb.shape[0], top, bottom)

    for path in (OUT_BG, ENTRY_BG):
        path.parent.mkdir(parents=True, exist_ok=True)
        Image.fromarray(out).save(path)
        print(f"Wrote {path}")
    print(f"gradient top={top.astype(int).tolist()} bottom={bottom.astype(int).tolist()}")


if __name__ == "__main__":
    main()
