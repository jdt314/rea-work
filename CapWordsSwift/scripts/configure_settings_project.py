"""Regenerate settings and WidgetKit targets from the canonical project spec."""
from pathlib import Path
import shutil
import subprocess

root = Path(__file__).resolve().parents[1]
executable = shutil.which("xcodegen")
if executable is None:
    raise SystemExit("xcodegen is required to generate CapWordsSwift.xcodeproj")
subprocess.run([executable, "generate", "--spec", str(root / "project.yml"),
                "--project", str(root)], check=True)
