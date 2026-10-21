#!/usr/bin/env python3
"""核验 REA 的目标身份，并提取启动复习的 Swift 元数据与中文资源。"""
import hashlib
import importlib.util
import json
from pathlib import Path
import plistlib
import re
import zipfile

root = Path(__file__).resolve().parents[2]
out = root / "CapWordsSwift/docs/review-prompt-evidence"
out.mkdir(parents=True, exist_ok=True)
ipa = root / "cap.ipa"
binary = root / "capwords-analysis/evidence/ipa/SnapWords"


def save(name, value):
    (out / name).write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n")


def digest(data):
    return hashlib.sha256(data).hexdigest()


artifact = json.loads((out / "rea-artifact.json").read_text())["data"]
macho = json.loads((out / "rea-macho-verified.json").read_text())["data"]
assert digest(ipa.read_bytes()) == artifact["subject"]["digest"]["sha256"]
assert digest(binary.read_bytes()) == macho["subject"]["digest"]["sha256"]
with zipfile.ZipFile(ipa) as archive:
    assert archive.read("Payload/SnapWords.app/SnapWords") == binary.read_bytes()
    info = plistlib.loads(archive.read("Payload/SnapWords.app/Info.plist"))
    localization = plistlib.loads(archive.read("Payload/SnapWords.app/zh-Hans.lproj/Localizable.strings"))
save("identity.json", {
    "ipa_sha256": digest(ipa.read_bytes()),
    "binary_sha256": digest(binary.read_bytes()),
    "bundle_id": info.get("CFBundleIdentifier"),
    "version": info.get("CFBundleShortVersionString"),
    "build": info.get("CFBundleVersion"),
    "artifact_evidence_id": artifact["evidence_id"],
    "macho_evidence_id": macho["evidence_id"],
    "binary_matches_ipa_member": True,
})
save("review-localization.json", {
    key: value for key, value in localization.items()
    if any(term in key.lower() for term in ["review", "good morning", "good afternoon", "good evening"])
    and len(key) < 160
})

spec = importlib.util.spec_from_file_location("startup", root / "capwords-analysis/analyze_startup.py")
startup = importlib.util.module_from_spec(spec)
spec.loader.exec_module(startup)
startup.O = out
startup.metadata(re.compile("FlashCardReview|FlashCardPreview|FlashCardViewController"), "review-")

native = macho["normalized_result"]
imports = native["imports"]
dependencies = native["dependencies"]
save("native-summary.json", {
    "evidence_id": macho["evidence_id"],
    "architecture": native["selected_architecture"],
    "import_count": imports["total"],
    "imports_exhaustive": imports["exhaustive"],
    "framework_dependencies": [
        item["path"] for item in dependencies["items"]
        if any(name in item["path"] for name in ["UIKit", "SwiftUI", "CoreData", "AVFoundation", "Foundation"])
    ],
    "encryption_commands": [
        item for item in native["load_commands"]["items"] if "ENCRYPTION" in item["kind"]
    ],
    "limitations": macho["limitations"],
})
print("IPA 身份、Mach-O 来源、Swift 类型和中文复习资源已核验。")
