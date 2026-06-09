"""从前景 PNG 追踪矢量路径，输出纯白、略加粗的前景 SVG。"""
from __future__ import annotations

from pathlib import Path

import cv2
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "AppScope/resources/base/media/app_icon_foreground_source.png"
OUT_SVG = ROOT / "AppScope/resources/base/media/app_icon_foreground_src.svg"

# 形态学膨胀迭代次数，控制线条加粗程度
DILATE_ITERATIONS = 2
DILATE_KERNEL = 3


def contour_to_path(cnt: np.ndarray, eps: float = 0.8) -> str | None:
    approx = cv2.approxPolyDP(cnt, eps, True)
    if len(approx) < 3:
        return None
    pts = approx.reshape(-1, 2)
    parts = [f"M {pts[0][0]:.1f} {pts[0][1]:.1f}"]
    for x, y in pts[1:]:
        parts.append(f"L {x:.1f} {y:.1f}")
    parts.append("Z")
    return " ".join(parts)


def build_foreground_mask(rgb: np.ndarray) -> np.ndarray:
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    white = (r.astype(np.int16) + g.astype(np.int16) + b.astype(np.int16) > 500)
    mask = white.astype(np.uint8) * 255

    kernel = np.ones((DILATE_KERNEL, DILATE_KERNEL), np.uint8)
    if DILATE_ITERATIONS > 0:
        mask = cv2.dilate(mask, kernel, iterations=DILATE_ITERATIONS)
    mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel, iterations=1)
    return mask


def trace_paths(mask: np.ndarray) -> list[str]:
    contours, hierarchy = cv2.findContours(mask, cv2.RETR_CCOMP, cv2.CHAIN_APPROX_SIMPLE)
    h = hierarchy[0] if hierarchy is not None else []
    paths: list[str] = []

    for i, cnt in enumerate(contours):
        if cv2.contourArea(cnt) < 300:
            continue
        if h[i][3] != -1:
            continue

        d = contour_to_path(cnt, eps=0.8)
        if not d:
            continue

        child = h[i][2]
        while child != -1:
            if cv2.contourArea(contours[child]) >= 80:
                hole = contour_to_path(contours[child], eps=0.6)
                if hole:
                    d += " " + hole
            child = h[child][0]
        paths.append(d)

    return paths


def main() -> None:
    rgb = np.array(Image.open(SRC).convert("RGB"))
    mask = build_foreground_mask(rgb)
    paths = trace_paths(mask)

    path_tags = "\n".join(
        f'  <path fill="#FFFFFF" fill-rule="evenodd" d="{d}"/>'
        for d in paths
    )
    svg = (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        "<!-- 应用图标前景：纯白线条，透明底 -->\n"
        '<svg viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg">\n'
        f"{path_tags}\n"
        "</svg>\n"
    )
    OUT_SVG.write_text(svg, encoding="utf-8")
    print(f"Wrote {len(paths)} paths -> {OUT_SVG}")


if __name__ == "__main__":
    main()
