"""Read-only IPA inspection; preserves only selected resources and observed metadata.

Run from the repository root:
    python3 CapWordsSwift/docs/library-2.0.11-evidence/inspect_resources.py CapWords_2.0.11.ipa
"""
import hashlib
import json
import plistlib
import struct
import sys
import zipfile
from pathlib import Path

ipa = Path(sys.argv[1]).resolve()
out = Path(__file__).resolve().parent
digest = lambda value: hashlib.sha256(value).hexdigest()
prefix = "Payload/SnapWords.app/"
with zipfile.ZipFile(ipa) as archive:
    info_bytes = archive.read(prefix + "Info.plist")
    info = plistlib.loads(info_bytes)
    binary = archive.read(prefix + info["CFBundleExecutable"])
    local_bytes = archive.read(prefix + "zh-Hans.lproj/Localizable.strings")
    local = plistlib.loads(local_bytes)
    pag = archive.read(prefix + "sticker_empty.pag")
    assert binary[:4] == b"\xcf\xfa\xed\xfe", "Expected thin little-endian Mach-O 64"
    count = struct.unpack_from("<I", binary, 16)[0]
    at = 32
    encryption = []
    for _ in range(count):
        cmd, length = struct.unpack_from("<II", binary, at)
        if cmd == 0x2C:
            offset, size, cryptid = struct.unpack_from("<III", binary, at + 8)
            encryption.append({"command": "LC_ENCRYPTION_INFO_64", "command_offset": at,
                               "cryptoff": offset, "cryptsize": size, "cryptid": cryptid})
        assert length >= 8 and at + length <= len(binary)
        at += length
    key = "Nothing snapped yet! What's around you?"
    data = {
        "authority": "shipped-artifact; offline parser; no target execution",
        "ipa": {"name": ipa.name, "sha256": digest(ipa.read_bytes())},
        "bundle": {k: info.get(k) for k in ["CFBundleShortVersionString", "CFBundleVersion",
                                          "CFBundleIdentifier", "MinimumOSVersion"]},
        "binary": {"member": prefix + info["CFBundleExecutable"], "sha256": digest(binary),
                   "encryption_commands": encryption,
                   "first_text_bytes_hex": binary[0x4000:0x4040].hex()},
        "localization": {"member": prefix + "zh-Hans.lproj/Localizable.strings",
                         "sha256": digest(local_bytes), "key": key, "value": local[key]},
        "eye_animation_candidate": {"member": prefix + "sticker_empty.pag", "bytes": len(pag),
                                    "sha256": digest(pag), "header_hex": pag[:8].hex(),
                                    "binding": "unverified; filename is a lead, not a callsite"},
        "asset_catalog": {"member": prefix + "Assets.car",
                          "bytes": archive.getinfo(prefix + "Assets.car").file_size},
        "limitations": ["Encrypted executable cannot establish UI call sites, animation timing or haptic parameters.",
                        "PAG resource was not rendered; identity does not establish on-screen binding.",
                        "This script does not decrypt or execute code."]
    }
    (out / "sticker_empty.pag").write_bytes(pag)
    (out / "offline-resource-evidence.json").write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(data, ensure_ascii=False, indent=2))
