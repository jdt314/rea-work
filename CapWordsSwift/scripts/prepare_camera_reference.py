#!/usr/bin/env python3
"""Build simulator-only sample photos from a UI-free crop of the supplied reference."""
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "App/Resources/Assets.xcassets"


def prepare_camera_assets():
    reference = Image.open(ROOT / "docs/camera-alignment-validation/reference.jpeg").convert("RGB")
    # This interior patch contains only the table, with no date, guides or buttons.
    surface = reference.crop((50, 175, 233, 400)).resize((402, 874), Image.Resampling.LANCZOS)
    sample = surface.convert("RGBA")
    donut = Image.open(ASSETS / "sample-donut.imageset/sample-donut.png").convert("RGBA")
    donut.thumbnail((330, 260), Image.Resampling.LANCZOS)
    sample.alpha_composite(donut, ((402 - donut.width) // 2, 410 - donut.height // 2))
    for name, image in [("camera-reference-surface", surface), ("demo-camera", sample.convert("RGB"))]:
        folder = ASSETS / f"{name}.imageset"
        folder.mkdir(parents=True, exist_ok=True)
        image.save(folder / f"{name}.png")
        (folder / "Contents.json").write_text(json.dumps({
            "images": [{"filename": f"{name}.png", "idiom": "universal"}],
            "info": {"author": "xcode", "version": 1},
        }, indent=2) + "\n")


if __name__ == "__main__":
    prepare_camera_assets()
