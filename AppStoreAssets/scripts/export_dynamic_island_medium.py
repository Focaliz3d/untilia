#!/usr/bin/env python3
"""Export the Untilia App Store set for Apple's medium Dynamic Island well."""

from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
TARGET = (1206, 2622)
OUTPUT = ROOT / "AppStore-DynamicIsland-Medium-1206x2622"


def fit_crop(source: Image.Image) -> Image.Image:
    ratio = max(TARGET[0] / source.width, TARGET[1] / source.height)
    resized = source.resize(
        (round(source.width * ratio), round(source.height * ratio)),
        Image.Resampling.LANCZOS,
    )
    left = (resized.width - TARGET[0]) // 2
    top = (resized.height - TARGET[1]) // 2
    return resized.crop((left, top, left + TARGET[0], top + TARGET[1])).convert("RGB")


def export_locale(locale: str) -> list[Path]:
    sources = [
        ROOT / "PremiumMontage-6.9" / locale / "01-premium-montage.png",
        *sorted((ROOT / "AppStore-6.9" / locale).glob("*.png")),
    ]
    target_dir = OUTPUT / locale
    target_dir.mkdir(parents=True, exist_ok=True)

    outputs: list[Path] = []
    for index, source in enumerate(sources, start=1):
        slug = "premium-montage" if index == 1 else source.stem.split("-", 1)[-1]
        target = target_dir / f"{index:02d}-{slug}.png"
        with Image.open(source) as image:
            fit_crop(image.convert("RGB")).save(target, "PNG", optimize=True)
        outputs.append(target)
    return outputs


def main() -> None:
    outputs = export_locale("fr") + export_locale("en")
    for path in outputs:
        with Image.open(path) as image:
            assert image.size == TARGET, (path, image.size)
            assert image.mode == "RGB", (path, image.mode)
        print(path)


if __name__ == "__main__":
    main()
