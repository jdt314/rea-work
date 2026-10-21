#!/usr/bin/env python3
"""Record DEBUG rendering checkpoints. This does not generate touch gestures."""
import os
from pathlib import Path
import signal
import subprocess
import sys
import time

scene = sys.argv[1] if len(sys.argv) > 1 else "empty"
if scene not in {"empty", "populated"}:
    raise SystemExit("Usage: capture_camera_pull.py [empty|populated]")
device = os.environ["CAPWORDS_SIMULATOR_ID"]
env = os.environ.copy()
env.setdefault("DEVELOPER_DIR", "/Volumes/homex/Applications/Xcode-beta.app/Contents/Developer")
output = Path(__file__).resolve().parents[1] / "docs/camera-pull-validation" / scene
output.mkdir(parents=True, exist_ok=True)
app = "cn.a2px.wordrove.dev.f89luflt5b.c9e48b12"


def simctl(*args, check=True):
    return subprocess.run(["xcrun", "simctl", *args], env=env, check=check)


simctl("terminate", device, app, check=False)
recording = subprocess.Popen(
    ["xcrun", "simctl", "io", device, "recordVideo", "--codec=h264", "--force", str(output / "motion.mp4")],
    env=env,
)
try:
    time.sleep(0.5)
    seeds = ["--seed-library-history"] if scene == "empty" else ["--seed-library", "--single-today"]
    simctl("launch", device, app, "--uitesting", "--preview-library", "--preview-camera-motion", *seeds)
    start = time.monotonic()
    for seconds, name in [(1.4, "library"), (4.0, "partial"), (5.5, "camera"), (8.0, "returned")]:
        time.sleep(max(0, start + seconds - time.monotonic()))
        simctl("io", device, "screenshot", str(output / f"{name}.png"))
finally:
    recording.send_signal(signal.SIGINT)
    recording.wait(timeout=15)
print(f"Programmatic rendering sample (not touch verification): {output}")
