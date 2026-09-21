"""Artifact regression: R8 must retain Room's reflectively called constructor.

Usage: python3 tooling/test_release_room_constructor.py app-release.aab --dexdump PATH
This checks the shipped DEX, not source rules or debug output.
"""
import argparse
import pathlib
import re
import subprocess
import tempfile
import zipfile


def verify(bundle, dexdump):
    descriptor = "Landroidx/work/impl/WorkDatabase_Impl;"
    found = False
    with zipfile.ZipFile(bundle) as archive, tempfile.TemporaryDirectory() as tmp:
        for name in archive.namelist():
            if not name.startswith("base/dex/") or not name.endswith(".dex"):
                continue
            dex = pathlib.Path(tmp) / pathlib.Path(name).name
            dex.write_bytes(archive.read(name))
            text = subprocess.check_output([dexdump, str(dex)]).decode(errors="replace")
            for block in text.split("Class #"):
                if f"Class descriptor  : '{descriptor}'" not in block:
                    continue
                found = True
                assert re.search(
                    r"name\s+: '<init>'\s+type\s+: '\(\)V'\s+access\s+:.*PUBLIC",
                    block,
                ), "WorkDatabase_Impl public no-arg constructor removed by R8; Room startup will crash"
    assert found, "WorkDatabase_Impl missing from shipped DEX"
    print("PASS: shipped WorkDatabase_Impl retains public no-arg constructor")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("bundle")
    parser.add_argument("--dexdump", required=True)
    args = parser.parse_args()
    verify(args.bundle, args.dexdump)
