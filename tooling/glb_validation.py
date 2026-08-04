from __future__ import annotations

import hashlib
import json
import os
import struct
from pathlib import Path
from typing import Any


_HEADER = struct.Struct("<4sII")
_CHUNK_HEADER = struct.Struct("<II")
_GLB_MAGIC = b"glTF"
_GLB_VERSION = 2
_JSON_CHUNK_TYPE = 0x4E4F534A
_BIN_CHUNK_TYPE = 0x004E4942


def summarize_glb(path: str | Path) -> dict[str, Any]:
    glb_path = Path(path)
    data = glb_path.read_bytes()
    if len(data) < _HEADER.size:
        raise ValueError("GLB is shorter than its 12-byte header")

    magic, version, declared_length = _HEADER.unpack_from(data)
    if magic != _GLB_MAGIC:
        raise ValueError("GLB header magic is not glTF")
    if version != _GLB_VERSION:
        raise ValueError(f"GLB version must be 2, got {version}")
    if declared_length != len(data):
        raise ValueError(
            "GLB declared length does not match file length "
            f"({declared_length} != {len(data)})"
        )

    offset = _HEADER.size
    chunks: list[tuple[int, bytes]] = []
    while offset < len(data):
        if len(data) - offset < _CHUNK_HEADER.size:
            raise ValueError("GLB has a truncated chunk header")
        chunk_length, chunk_type = _CHUNK_HEADER.unpack_from(data, offset)
        offset += _CHUNK_HEADER.size
        if chunk_length % 4:
            raise ValueError("GLB chunk length is not 4-byte aligned")
        end = offset + chunk_length
        if end > len(data):
            raise ValueError("GLB chunk extends beyond the declared file length")
        chunks.append((chunk_type, data[offset:end]))
        offset = end

    if not chunks or chunks[0][0] != _JSON_CHUNK_TYPE:
        raise ValueError("GLB must start with a JSON chunk")
    if any(chunk_type not in (_JSON_CHUNK_TYPE, _BIN_CHUNK_TYPE) for chunk_type, _ in chunks):
        raise ValueError("GLB contains an unsupported chunk type")
    if sum(chunk_type == _JSON_CHUNK_TYPE for chunk_type, _ in chunks) != 1:
        raise ValueError("GLB must contain exactly one JSON chunk")
    if sum(chunk_type == _BIN_CHUNK_TYPE for chunk_type, _ in chunks) > 1:
        raise ValueError("GLB must not contain more than one BIN chunk")

    try:
        document = json.loads(chunks[0][1].decode("utf-8").rstrip(" \t\r\n\x00"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise ValueError(f"GLB JSON chunk is invalid: {exc}") from exc
    asset = document.get("asset") if isinstance(document, dict) else None
    if not isinstance(asset, dict) or asset.get("version") != "2.0":
        raise ValueError("GLB JSON asset.version must be '2.0'")

    return {
        "byteLength": len(data),
        "sha256": hashlib.sha256(data).hexdigest(),
        "chunkCount": len(chunks),
        "hasBinChunk": any(chunk_type == _BIN_CHUNK_TYPE for chunk_type, _ in chunks),
    }


def promote_validated_glb(
    staging_path: str | Path,
    output_path: str | Path,
) -> dict[str, Any]:
    receipt = summarize_glb(staging_path)
    os.replace(staging_path, output_path)
    return receipt
