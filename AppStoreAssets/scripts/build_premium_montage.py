#!/usr/bin/env python3
"""Build the localized multi-device Untilia App Store hero artwork."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


CANVAS = (1290, 2796)
ROOT = Path(__file__).resolve().parents[1]
DOWNLOADS = Path.home() / "Downloads"
BACKGROUND = ROOT / "source" / "premium-montage-background.png"
APP_ICON = (
    ROOT.parent
    / "Untilia"
    / "Assets.xcassets"
    / "AppIcon.appiconset"
    / "icone.png"
)
FONT_PATH = "/System/Library/Fonts/SFNSRounded.ttf"
OUTPUT = ROOT / "PremiumMontage-6.9"


@dataclass(frozen=True)
class LocaleArtwork:
    locale: str
    center: str
    left: str
    right: str
    headline: tuple[str, str]
    subtitle: str
    features: tuple[str, str, str]
    tagline: str


ARTWORKS = (
    LocaleArtwork(
        locale="fr",
        center="IMG_8237.PNG",
        left="IMG_8235.PNG",
        right="IMG_8236.PNG",
        headline=("Vos moments.", "Votre temps."),
        subtitle="Trois décomptes précis pour ce qui compte vraiment.",
        features=("3 DÉCOMPTES", "FUSEAUX HORAIRES", "100 % HORS LIGNE"),
        tagline="Le temps, à votre rythme.",
    ),
    LocaleArtwork(
        locale="en",
        center="IMG_8243.PNG",
        left="IMG_8241.PNG",
        right="IMG_8242.PNG",
        headline=("Your moments.", "Your time."),
        subtitle="Three precise countdowns for what matters most.",
        features=("3 COUNTDOWNS", "TIME ZONES", "FULLY OFFLINE"),
        tagline="Time, at your pace.",
    ),
)


def font(size: int, weight: int = 400) -> ImageFont.FreeTypeFont:
    selected = ImageFont.truetype(FONT_PATH, size=size)
    selected.set_variation_by_axes([400, weight])
    return selected


def fit(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    ratio = max(size[0] / image.width, size[1] / image.height)
    resized = image.resize(
        (round(image.width * ratio), round(image.height * ratio)),
        Image.Resampling.LANCZOS,
    )
    x = (resized.width - size[0]) // 2
    y = (resized.height - size[1]) // 2
    return resized.crop((x, y, x + size[0], y + size[1]))


def rounded_icon(size: int) -> Image.Image:
    icon = Image.open(APP_ICON).convert("RGB").resize((size, size), Image.Resampling.LANCZOS)
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size - 1, size - 1), radius=size // 4, fill=255)
    result = icon.convert("RGBA")
    result.putalpha(mask)
    return result


def phone(source_path: Path, screen_width: int) -> Image.Image:
    source = Image.open(source_path).convert("RGB")
    screen_height = round(source.height * screen_width / source.width)
    shell = 18 if screen_width < 500 else 22
    outer = Image.new(
        "RGBA", (screen_width + shell * 2, screen_height + shell * 2), (0, 0, 0, 0)
    )
    draw = ImageDraw.Draw(outer)
    outer_radius = round((screen_width + shell * 2) * 0.105)
    screen_radius = round(screen_width * 0.088)

    # Metallic edge and black ceramic body.
    draw.rounded_rectangle(
        (0, 0, outer.width - 1, outer.height - 1),
        radius=outer_radius,
        fill=(6, 7, 12, 255),
        outline=(194, 198, 214, 155),
        width=3,
    )
    draw.rounded_rectangle(
        (5, 5, outer.width - 6, outer.height - 6),
        radius=max(1, outer_radius - 5),
        outline=(65, 68, 82, 255),
        width=4,
    )

    screen = source.resize((screen_width, screen_height), Image.Resampling.LANCZOS).convert("RGBA")
    mask = Image.new("L", screen.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, screen.width - 1, screen.height - 1), radius=screen_radius, fill=255
    )
    screen.putalpha(mask)
    outer.alpha_composite(screen, (shell, shell))

    # Dynamic Island: deliberately restrained so the real UI remains dominant.
    island_w = round(screen_width * 0.29)
    island_h = round(screen_width * 0.073)
    island_x = (outer.width - island_w) // 2
    island_y = shell + round(screen_width * 0.025)
    draw.rounded_rectangle(
        (island_x, island_y, island_x + island_w, island_y + island_h),
        radius=island_h // 2,
        fill=(0, 0, 0, 255),
    )
    return outer


def place_with_shadow(
    canvas: Image.Image,
    device: Image.Image,
    position: tuple[int, int],
    angle: float = 0,
    shadow_opacity: int = 155,
) -> None:
    if angle:
        device = device.rotate(angle, resample=Image.Resampling.BICUBIC, expand=True)
    x, y = position
    # Build the shadow on the full canvas so Gaussian blur is never clipped at
    # the device bounds (which would otherwise create a visible rectangle).
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow_mask = Image.new("L", canvas.size, 0)
    shadow_mask.paste(device.getchannel("A"), (x + 8, y + 38))
    shadow_color = Image.new("RGBA", canvas.size, (0, 0, 0, shadow_opacity))
    shadow_color.putalpha(shadow_mask)
    shadow.alpha_composite(shadow_color)
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(34)))
    canvas.alpha_composite(device, (x, y))


def draw_globe(draw: ImageDraw.ImageDraw, center: tuple[int, int], radius: int, color) -> None:
    x, y = center
    box = (x - radius, y - radius, x + radius, y + radius)
    draw.ellipse(box, outline=color, width=4)
    draw.arc((x - radius // 2, y - radius, x + radius // 2, y + radius), 90, 270, fill=color, width=3)
    draw.arc((x - radius // 2, y - radius, x + radius // 2, y + radius), 270, 90, fill=color, width=3)
    draw.line((x - radius + 3, y, x + radius - 3, y), fill=color, width=3)
    draw.arc((x - radius, y - radius // 2, x + radius, y + radius // 2), 180, 360, fill=color, width=3)
    draw.arc((x - radius, y - radius // 2, x + radius, y + radius // 2), 0, 180, fill=color, width=3)


def draw_feature_icon(draw: ImageDraw.ImageDraw, kind: int, center: tuple[int, int], color) -> None:
    x, y = center
    if kind == 0:
        for offset_x, offset_y in ((-15, 10), (0, 0), (15, -10)):
            draw.rounded_rectangle(
                (x + offset_x - 22, y + offset_y - 16, x + offset_x + 22, y + offset_y + 16),
                radius=10,
                outline=color,
                width=4,
            )
    elif kind == 1:
        draw_globe(draw, center, 26, color)
    else:
        draw.ellipse((x - 29, y - 29, x + 29, y + 29), outline=color, width=4)
        draw.line((x - 13, y + 1, x - 3, y + 12, x + 16, y - 13), fill=color, width=6, joint="curve")


def render(artwork: LocaleArtwork) -> Path:
    background = fit(Image.open(BACKGROUND).convert("RGB"), CANVAS).convert("RGBA")

    # Calm top zone for marketing copy and a subtle bottom fade for feature chips.
    overlay = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    pixels = overlay.load()
    assert pixels is not None
    for y in range(CANVAS[1]):
        if y < 720:
            alpha = round(120 - 50 * (y / 720))
        elif y > 2150:
            alpha = round(50 + 100 * ((y - 2150) / (CANVAS[1] - 2150)))
        else:
            alpha = 40
        for x in range(CANVAS[0]):
            pixels[x, y] = (1, 3, 13, alpha)
    background.alpha_composite(overlay)

    draw = ImageDraw.Draw(background)
    margin = 92

    icon = rounded_icon(62)
    background.alpha_composite(icon, (margin, 84))
    tracking_font = font(28, 720)
    x = margin + 86
    for character in "UNTILIA":
        draw.text((x, 98), character, font=tracking_font, fill=(250, 250, 253, 244))
        box = draw.textbbox((x, 98), character, font=tracking_font)
        x = box[2] + 6

    headline_font = font(94, 790)
    draw.text((margin, 203), artwork.headline[0], font=headline_font, fill=(255, 255, 255, 255))
    draw.text((margin, 305), artwork.headline[1], font=headline_font, fill=(255, 255, 255, 255))
    draw.rounded_rectangle((margin, 434, margin + 92, 442), radius=4, fill=(255, 169, 77, 255))
    draw.text(
        (margin, 474),
        artwork.subtitle,
        font=font(36, 450),
        fill=(225, 226, 235, 230),
    )

    # Three-device composition. Side phones sit behind the central hero.
    left_phone = phone(DOWNLOADS / artwork.left, 420)
    right_phone = phone(DOWNLOADS / artwork.right, 420)
    center_phone = phone(DOWNLOADS / artwork.center, 620)
    place_with_shadow(background, left_phone, (-124, 905), angle=-9, shadow_opacity=125)
    place_with_shadow(background, right_phone, (960, 900), angle=9, shadow_opacity=125)
    place_with_shadow(background, center_phone, ((CANVAS[0] - center_phone.width) // 2, 654), shadow_opacity=190)

    # Feature glass rail.
    rail = Image.new("RGBA", (1110, 270), (0, 0, 0, 0))
    rail_draw = ImageDraw.Draw(rail)
    rail_draw.rounded_rectangle(
        (0, 0, rail.width - 1, rail.height - 1),
        radius=62,
        fill=(10, 12, 27, 190),
        outline=(255, 255, 255, 45),
        width=2,
    )
    accent_colors = ((212, 127, 255, 255), (72, 229, 200, 255), (255, 174, 82, 255))
    column_width = rail.width // 3
    for index, label in enumerate(artwork.features):
        center_x = index * column_width + column_width // 2
        draw_feature_icon(rail_draw, index, (center_x, 78), accent_colors[index])
        label_font = font(24, 690)
        label_box = rail_draw.textbbox((0, 0), label, font=label_font)
        rail_draw.text(
            (center_x - (label_box[2] - label_box[0]) // 2, 145),
            label,
            font=label_font,
            fill=(247, 247, 251, 245),
        )
        if index < 2:
            rail_draw.line(
                (column_width * (index + 1), 54, column_width * (index + 1), 214),
                fill=(255, 255, 255, 28),
                width=2,
            )
    background.alpha_composite(rail, ((CANVAS[0] - rail.width) // 2, 2265))

    tagline_font = font(30, 600)
    tagline_box = draw.textbbox((0, 0), artwork.tagline, font=tagline_font)
    draw.text(
        ((CANVAS[0] - (tagline_box[2] - tagline_box[0])) // 2, 2626),
        artwork.tagline,
        font=tagline_font,
        fill=(233, 232, 240, 198),
    )

    target_dir = OUTPUT / artwork.locale
    target_dir.mkdir(parents=True, exist_ok=True)
    output = target_dir / "01-premium-montage.png"
    background.convert("RGB").save(output, "PNG", optimize=True)
    return output


def main() -> None:
    outputs = [render(artwork) for artwork in ARTWORKS]
    for output in outputs:
        image = Image.open(output)
        assert image.size == CANVAS
        assert image.mode == "RGB"
        print(output)


if __name__ == "__main__":
    main()
