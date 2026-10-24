#!/usr/bin/env python3
"""Build localized 6.9-inch App Store screenshots for Untilia.

The source captures remain unmodified. The script adds only a deterministic
marketing header, background treatment, and a rounded presentation frame.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw, ImageFilter, ImageFont


CANVAS = (1290, 2796)
ROOT = Path(__file__).resolve().parents[1]
DOWNLOADS = Path.home() / "Downloads"
OUTPUT = ROOT / "AppStore-6.9"
FONT_PATH = Path("/System/Library/Fonts/SFNSRounded.ttf")
APP_ICON = (
    ROOT.parent
    / "Untilia"
    / "Assets.xcassets"
    / "AppIcon.appiconset"
    / "icone.png"
)


@dataclass(frozen=True)
class Slide:
    source: str
    slug: str
    headline: str
    subtitle: str
    accent: tuple[int, int, int]


SLIDES: dict[str, tuple[Slide, ...]] = {
    "fr": (
        Slide(
            "IMG_8237.PNG",
            "le-temps-a-votre-rythme",
            "Le temps, à votre rythme.",
            "Gardez chaque moment important en vue.",
            (255, 168, 77),
        ),
        Slide(
            "IMG_8236.PNG",
            "trois-decomptes",
            "Trois décomptes. Une vue claire.",
            "Passez de l’un à l’autre d’un simple geste.",
            (65, 226, 190),
        ),
        Slide(
            "IMG_8238.PNG",
            "chaque-detail",
            "Chaque détail, à votre mesure.",
            "Dates, heures et fuseaux horaires, réglés avec précision.",
            (255, 157, 70),
        ),
        Slide(
            "IMG_8235.PNG",
            "avant-et-apres",
            "Avant. Après. Toujours visible.",
            "Temps restant ou écoulé, sans compte ni suivi.",
            (202, 111, 255),
        ),
    ),
    "en": (
        Slide(
            "IMG_8243.PNG",
            "time-at-your-pace",
            "Time, at your pace.",
            "Keep every meaningful moment in view.",
            (255, 168, 77),
        ),
        Slide(
            "IMG_8242.PNG",
            "three-countdowns",
            "Three countdowns. One clear view.",
            "Move between them with a simple swipe.",
            (65, 226, 190),
        ),
        Slide(
            "IMG_8241.PNG",
            "before-and-after",
            "Before. After. Always in view.",
            "See time remaining or time elapsed at a glance.",
            (202, 111, 255),
        ),
        Slide(
            "IMG_8244.PNG",
            "easy-from-first-tap",
            "Easy from the first tap.",
            "Clear, built-in guidance whenever you need it.",
            (255, 157, 70),
        ),
    ),
}


def font(size: int, weight: int = 400) -> ImageFont.FreeTypeFont:
    result = ImageFont.truetype(str(FONT_PATH), size=size)
    result.set_variation_by_axes([400, weight])
    return result


def add_vertical_gradient(
    image: Image.Image,
    top: tuple[int, int, int, int],
    bottom: tuple[int, int, int, int],
) -> None:
    gradient = Image.new("RGBA", image.size)
    pixels = gradient.load()
    assert pixels is not None
    height = image.height - 1
    for y in range(image.height):
        t = y / height
        color = tuple(round(a + (b - a) * t) for a, b in zip(top, bottom))
        for x in range(image.width):
            pixels[x, y] = color
    image.alpha_composite(gradient)


def add_radial_glow(
    image: Image.Image,
    center: tuple[int, int],
    radius: int,
    color: tuple[int, int, int],
    opacity: int,
) -> None:
    glow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(glow)
    for r in range(radius, 0, -8):
        strength = (1 - r / radius) ** 1.7
        alpha = round(opacity * strength)
        x, y = center
        draw.ellipse((x - r, y - r, x + r, y + r), fill=(*color, alpha))
    image.alpha_composite(glow.filter(ImageFilter.GaussianBlur(28)))


def fit_background(source: Image.Image) -> Image.Image:
    ratio = max(CANVAS[0] / source.width, CANVAS[1] / source.height)
    resized = source.resize(
        (round(source.width * ratio), round(source.height * ratio)),
        Image.Resampling.LANCZOS,
    )
    left = (resized.width - CANVAS[0]) // 2
    top = (resized.height - CANVAS[1]) // 2
    return resized.crop((left, top, left + CANVAS[0], top + CANVAS[1]))


def wrap_text(
    draw: ImageDraw.ImageDraw,
    text: str,
    selected_font: ImageFont.FreeTypeFont,
    width: int,
) -> list[str]:
    words = text.split()
    lines: list[str] = []
    current = ""
    for word in words:
        candidate = f"{current} {word}".strip()
        bounds = draw.textbbox((0, 0), candidate, font=selected_font)
        if bounds[2] <= width or not current:
            current = candidate
        else:
            lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines


def draw_tracking_text(
    draw: ImageDraw.ImageDraw,
    xy: tuple[int, int],
    text: str,
    selected_font: ImageFont.FreeTypeFont,
    fill: tuple[int, int, int, int],
    tracking: int,
) -> None:
    x, y = xy
    for char in text:
        draw.text((x, y), char, font=selected_font, fill=fill)
        bounds = draw.textbbox((x, y), char, font=selected_font)
        x = bounds[2] + tracking


def rounded_capture(source: Image.Image, width: int = 1040) -> Image.Image:
    height = round(source.height * width / source.width)
    capture = source.resize((width, height), Image.Resampling.LANCZOS).convert("RGBA")
    mask = Image.new("L", capture.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, capture.width - 1, capture.height - 1), radius=72, fill=255
    )
    capture.putalpha(mask)

    border = Image.new("RGBA", capture.size, (0, 0, 0, 0))
    ImageDraw.Draw(border).rounded_rectangle(
        (1, 1, capture.width - 2, capture.height - 2),
        radius=72,
        outline=(255, 255, 255, 45),
        width=2,
    )
    capture.alpha_composite(border)
    return capture


def render_slide(slide: Slide, index: int, total: int, locale: str) -> Path:
    source_path = DOWNLOADS / slide.source
    source = Image.open(source_path).convert("RGB")

    background = fit_background(source).filter(ImageFilter.GaussianBlur(62)).convert("RGBA")
    add_vertical_gradient(background, (4, 5, 17, 242), (4, 5, 17, 190))
    add_radial_glow(background, (1030, 300), 500, slide.accent, 74)

    draw = ImageDraw.Draw(background)
    margin = 116

    # Compact brand signature.
    icon_size = 58
    icon = Image.open(APP_ICON).convert("RGB").resize(
        (icon_size, icon_size), Image.Resampling.LANCZOS
    )
    icon_mask = Image.new("L", (icon_size, icon_size), 0)
    ImageDraw.Draw(icon_mask).rounded_rectangle(
        (0, 0, icon_size - 1, icon_size - 1), radius=17, fill=255
    )
    icon_rgba = icon.convert("RGBA")
    icon_rgba.putalpha(icon_mask)
    background.alpha_composite(icon_rgba, (margin, 86))
    draw_tracking_text(
        draw,
        (margin + 78, 96),
        "UNTILIA",
        font(27, 700),
        (245, 245, 250, 235),
        5,
    )

    count_text = f"{index:02d}  /  {total:02d}"
    count_font = font(24, 600)
    count_box = draw.textbbox((0, 0), count_text, font=count_font)
    draw.text(
        (CANVAS[0] - margin - (count_box[2] - count_box[0]), 101),
        count_text,
        font=count_font,
        fill=(222, 220, 231, 145),
    )

    # Accent rule and marketing copy.
    draw.rounded_rectangle((margin, 190, margin + 76, 198), radius=4, fill=(*slide.accent, 255))
    headline_font = font(78, 760)
    headline_lines = wrap_text(draw, slide.headline, headline_font, CANVAS[0] - 2 * margin)
    y = 226
    for line in headline_lines:
        draw.text((margin, y), line, font=headline_font, fill=(255, 255, 255, 255))
        y += 88

    subtitle_font = font(36, 430)
    y += 18
    for line in wrap_text(draw, slide.subtitle, subtitle_font, CANVAS[0] - 2 * margin):
        draw.text((margin, y), line, font=subtitle_font, fill=(220, 219, 229, 220))
        y += 48

    # Main product capture.
    capture = rounded_capture(source)
    capture_x = (CANVAS[0] - capture.width) // 2
    capture_y = 620
    shadow = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle(
        (
            capture_x - 18,
            capture_y + 16,
            capture_x + capture.width + 18,
            capture_y + capture.height + 48,
        ),
        radius=92,
        fill=(0, 0, 0, 170),
    )
    background.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(40)))
    background.alpha_composite(capture, (capture_x, capture_y))

    locale_dir = OUTPUT / locale
    locale_dir.mkdir(parents=True, exist_ok=True)
    output_path = locale_dir / f"{index:02d}-{slide.slug}.png"
    background.convert("RGB").save(output_path, "PNG", optimize=True)
    return output_path


def build_contact_sheet(paths: Iterable[Path], locale: str) -> Path:
    paths = list(paths)
    thumb_width = 322
    thumb_height = round(CANVAS[1] * thumb_width / CANVAS[0])
    gap = 28
    label_height = 72
    width = gap + len(paths) * (thumb_width + gap)
    height = gap + label_height + thumb_height + gap
    sheet = Image.new("RGB", (width, height), (10, 10, 22))
    draw = ImageDraw.Draw(sheet)
    title = "UNTILIA — FRANÇAIS" if locale == "fr" else "UNTILIA — ENGLISH"
    draw.text((gap, 22), title, font=font(30, 700), fill=(248, 248, 252))
    for position, path in enumerate(paths):
        thumb = Image.open(path).convert("RGB").resize(
            (thumb_width, thumb_height), Image.Resampling.LANCZOS
        )
        sheet.paste(thumb, (gap + position * (thumb_width + gap), gap + label_height))
    output_path = OUTPUT / f"overview-{locale}.jpg"
    sheet.save(output_path, "JPEG", quality=92, optimize=True)
    return output_path


def validate(paths: Iterable[Path]) -> None:
    for path in paths:
        image = Image.open(path)
        if image.size != CANVAS:
            raise ValueError(f"Unexpected size for {path}: {image.size}")
        if image.mode != "RGB":
            raise ValueError(f"Unexpected mode for {path}: {image.mode}")


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for locale, slides in SLIDES.items():
        paths = [
            render_slide(slide, index, len(slides), locale)
            for index, slide in enumerate(slides, start=1)
        ]
        validate(paths)
        build_contact_sheet(paths, locale)
        for path in paths:
            print(path)


if __name__ == "__main__":
    main()
