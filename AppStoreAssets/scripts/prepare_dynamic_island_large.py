#!/usr/bin/env python3
"""Prepare the native iPhone 15 Pro Max upload set in App Store order."""

from __future__ import annotations

from pathlib import Path
from shutil import copyfile

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "AppStore-DynamicIsland-Large-1290x2796"
EXPECTED = (1290, 2796)


def prepare(locale: str) -> list[Path]:
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
        copyfile(source, target)
        with Image.open(target) as image:
            assert image.size == EXPECTED, (target, image.size)
            assert image.mode == "RGB", (target, image.mode)
        outputs.append(target)
    return outputs


def main() -> None:
    for output in prepare("fr") + prepare("en"):
        print(output)


if __name__ == "__main__":
    main()
