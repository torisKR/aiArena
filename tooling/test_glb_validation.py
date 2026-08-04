from __future__ import annotations

import json
import struct
import tempfile
import unittest
from pathlib import Path

from tooling.glb_validation import promote_validated_glb, summarize_glb


def make_glb(document: dict[str, object]) -> bytes:
    json_bytes = json.dumps(document, separators=(",", ":")).encode("utf-8")
    json_bytes += b" " * (-len(json_bytes) % 4)
    total_length = 12 + 8 + len(json_bytes)
    return b"".join(
        (
            struct.pack("<4sII", b"glTF", 2, total_length),
            struct.pack("<II", len(json_bytes), 0x4E4F534A),
            json_bytes,
        )
    )


class GlbValidationTest(unittest.TestCase):
    def test_valid_glb_returns_portable_receipt_fields(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            glb_path = Path(directory) / "scene.glb"
            glb_path.write_bytes(make_glb({"asset": {"version": "2.0"}}))

            receipt = summarize_glb(glb_path)

        self.assertEqual(receipt["byteLength"], 48)
        self.assertEqual(receipt["chunkCount"], 1)
        self.assertFalse(receipt["hasBinChunk"])
        self.assertRegex(receipt["sha256"], r"^[0-9a-f]{64}$")

    def test_invalid_glb_does_not_replace_existing_output(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            staging_path = Path(directory) / "scene.pending.glb"
            output_path = Path(directory) / "scene.glb"
            staging_path.write_bytes(b"not-a-glb")
            output_path.write_bytes(b"known-good-output")

            with self.assertRaisesRegex(ValueError, "shorter"):
                promote_validated_glb(staging_path, output_path)

            self.assertEqual(output_path.read_bytes(), b"known-good-output")
            self.assertTrue(staging_path.exists())

    def test_valid_glb_atomically_replaces_existing_output(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            staging_path = Path(directory) / "scene.pending.glb"
            output_path = Path(directory) / "scene.glb"
            valid_glb = make_glb({"asset": {"version": "2.0"}})
            staging_path.write_bytes(valid_glb)
            output_path.write_bytes(b"stale-output")

            receipt = promote_validated_glb(staging_path, output_path)

            self.assertEqual(output_path.read_bytes(), valid_glb)
            self.assertFalse(staging_path.exists())
            self.assertEqual(receipt["byteLength"], len(valid_glb))
