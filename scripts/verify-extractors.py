#!/usr/bin/env python3
"""Run the extractor regression checks against a Debug build. Pass xcodebuild's -derivedDataPath directory."""
import argparse
import platform
import plistlib
from pathlib import Path
import shutil
import subprocess
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("derived_data", type=Path)
args = parser.parse_args()
build = args.derived_data.resolve() / "Build"
products = build / "Products/Debug"
objects = build / f"Intermediates.noindex/FinderHover.build/Debug/FinderHover.build/Objects-normal/{platform.machine()}"
linked_objects = sorted(p for p in objects.glob("*.o") if p.name != "FinderHoverApp.o")
if not linked_objects or not (products / "FinderHover.swiftmodule").exists():
    parser.error("Build FinderHover in Debug for this Mac before running the checks.")

with tempfile.TemporaryDirectory(prefix="finderhover-extractor-checks-") as temp:
    contents = Path(temp) / "ExtractorChecks.app/Contents"
    (contents / "MacOS").mkdir(parents=True)
    executable = contents / "MacOS/ExtractorChecks"
    shutil.copytree(products / "FinderHover.app/Contents/Resources", contents / "Resources")
    (contents / "Info.plist").write_bytes(plistlib.dumps({
        "CFBundleIdentifier": "dev.koukeneko.FinderHover.ExtractorChecks",
        "CFBundleName": "ExtractorChecks",
        "CFBundleExecutable": "ExtractorChecks",
        "CFBundleDevelopmentRegion": "en",
        "CFBundlePackageType": "APPL",
    }))
    subprocess.run([
        "xcrun", "swiftc", "-parse-as-library", "-I", str(products),
        str(Path(__file__).with_suffix(".swift")),
        *(str(p) for p in linked_objects), "-o", str(executable),
    ], check=True)
    subprocess.run([str(executable)], check=True)
