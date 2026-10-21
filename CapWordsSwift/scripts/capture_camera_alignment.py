#!/usr/bin/env python3
"""Capture the rendered camera controls against a UI-free reference surface."""
import os
from pathlib import Path
import subprocess
import time

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "docs/camera-alignment-validation"
DEVICE = os.environ["CAPWORDS_SIMULATOR_ID"]
APP = "cn.a2px.wordrove.dev.f89luflt5b.c9e48b12"
ENV = dict(os.environ)
ENV.setdefault("DEVELOPER_DIR", "/Volumes/homex/Applications/Xcode-beta.app/Contents/Developer")


def simctl(*args, check=True):
    return subprocess.run(["/usr/bin/xcrun", "simctl", *args], env=ENV, check=check,
                          capture_output=True, text=True)


def capture(name, *arguments):
    simctl("terminate", DEVICE, APP, check=False)
    simctl("launch", DEVICE, APP, "--uitesting", "--preview-camera", *arguments)
    time.sleep(2)
    simctl("io", DEVICE, "screenshot", str(OUTPUT / f"{name}.png"))


OUTPUT.mkdir(parents=True, exist_ok=True)
simctl("install", DEVICE, str(ROOT / ".build/Build/Products/Debug-iphonesimulator/CapWordsSwift.app"))
try:
    simctl("status_bar", DEVICE, "override", "--time", "15:01", "--dataNetwork", "wifi",
           "--wifiMode", "active", "--wifiBars", "3", "--batteryState", "discharging", "--batteryLevel", "60")
    capture("camera-reference", "--camera-layout-reference")
    capture("camera-demo")
finally:
    simctl("status_bar", DEVICE, "clear")

reference = Image.open(OUTPUT / "reference.jpeg").convert("RGB")
rendered = Image.open(OUTPUT / "camera-reference.png").convert("RGB").resize(reference.size, Image.Resampling.LANCZOS)
comparison = Image.new("RGB", (reference.width * 2 + 12, reference.height + 28), "#f5f5f5")
comparison.paste(reference, (0, 28))
comparison.paste(rendered, (reference.width + 12, 28))
draw = ImageDraw.Draw(comparison)
draw.text((8, 8), "Original", fill="black")
draw.text((reference.width + 20, 8), "Swift / Simulator", fill="black")
comparison.save(OUTPUT / "comparison.png")
print(f"Captured real simulator rendering: {OUTPUT}")
print("The background is a UI-free texture crop; system camera indicators require a physical device.")
