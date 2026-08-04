#!/usr/bin/env python3
from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parent
LOCALES = ("en", "ko", "ja", "zh")
EXPECTED_TITLES = {
    "en": "Tokenfront: Orbital Signal War",
    "ko": "Tokenfront: 궤도 신호전",
    "ja": "Tokenfront: 軌道信号戦",
    "zh": "Tokenfront：轨道信号战",
}
NO_ACCOUNT = {
    "en": "No account required",
    "ko": "계정이 필요 없고",
    "ja": "アカウント不要",
    "zh": "无需账户",
}


def field(text: str, name: str) -> str:
    match = re.search(rf"^{re.escape(name)}: (.+)$", text, re.MULTILINE)
    if not match:
        raise AssertionError(f"missing {name}")
    return match.group(1)


def main() -> int:
    lines = ["Play listing validation (Unicode code-point counts)"]
    for locale in LOCALES:
        path = ROOT / f"store-listing-{locale}.md"
        text = path.read_text(encoding="utf-8")
        title = field(text, "Title")
        short = field(text, "Short description")
        full_match = re.search(
            r"^Full description:\n(?P<body>.*?)(?:\n\nRelease notes:)",
            text,
            re.MULTILINE | re.DOTALL,
        )
        if not full_match:
            raise AssertionError(f"missing Full description body: {path}")
        full = full_match.group("body").strip()
        notes_match = re.search(r"^Release notes:\n(?P<notes>.*)$", text, re.MULTILINE | re.DOTALL)
        if not notes_match:
            raise AssertionError(f"missing Release notes: {path}")
        notes = notes_match.group("notes").strip()
        assert title == EXPECTED_TITLES[locale], (locale, title)
        assert len(title) <= 30, (locale, "title", len(title))
        assert len(short) <= 80, (locale, "short", len(short))
        assert len(full) <= 4000, (locale, "full", len(full))
        assert len(notes) <= 500, (locale, "release notes", len(notes))
        assert "4,000" in full and "1,000" in full, locale
        assert NO_ACCOUNT[locale] in full, locale
        assert "online multiplayer" not in full.lower(), locale
        lines.append(
            f"{locale}: title={len(title)}, short={len(short)}, "
            f"full={len(full)}, release_notes={len(notes)}"
        )
    metadata = (ROOT / "store-metadata.md").read_text(encoding="utf-8")
    alt_texts = re.findall(r"^[1-5]\. (.+)$", metadata, re.MULTILINE)
    assert len(alt_texts) == 5, ("screenshot alt text count", len(alt_texts))
    assert all(len(value) <= 140 for value in alt_texts), (
        "screenshot alt text exceeds 140 characters",
        [len(value) for value in alt_texts],
    )
    lines.append(
        "screenshot_alt_text=" + ",".join(str(len(value)) for value in alt_texts)
    )
    lines.append("PASS: all four locales satisfy 30/80/4000 listing limits and consistency checks")
    print("\n".join(lines))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AssertionError, OSError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        raise SystemExit(1)
