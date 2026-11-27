# -*- coding: utf-8 -*-
"""Batch-convert KanjiKafe study PDFs to Markdown.

Output: markdown/<subfolder>/<name>.md, mirroring `Source Material/`.
Also writes markdown/_conversion_report.json with per-file diagnostics.
"""
import json
import logging
import os
import re
import sys
import unicodedata
import warnings

import pdfplumber

logging.getLogger("pdfminer").setLevel(logging.ERROR)
warnings.filterwarnings("ignore")

SRC = "Source Material"
DST = "markdown"

# Lines that are just running-header garbage: 5+ consecutive chars from the
# ASCII punctuation band (! through / or : through @), e.g. !"#$%&'()*+,-./
GARBLED_LINE = re.compile(r"[!-/]{5,}|[:-@]{5,}|[\\-`]{5,}|[{-~]{5,}")

# A line counts as meaningful if it contains at least one CJK / kana /
# fullwidth / Latin letter / numeral-form character.
MEANINGFUL = re.compile(
    "[぀-ヿ㐀-䶿一-鿿豈-﫿＀-￯"
    "A-Za-zÀ-ɏ⅐-↏①-⓿]"
)


def is_noise_line(stripped: str) -> bool:
    """Header-garbage fragments and bare page numbers: digits/punct only."""
    if not stripped:
        return False
    return not MEANINGFUL.search(stripped)


def is_suspicious(ch: str) -> bool:
    """Heuristic: char is outside the set expected in Japanese/Chinese study text."""
    cp = ord(ch)
    if ch in "\n\t ":
        return False
    if 0x20 <= cp <= 0x7E:  # ASCII printable
        return False
    if 0x4E00 <= cp <= 0x9FFF or 0x3400 <= cp <= 0x4DBF or 0xF900 <= cp <= 0xFAFF:
        return False  # CJK
    if 0x3040 <= cp <= 0x30FF:
        return False  # kana
    if 0x3000 <= cp <= 0x303F or 0xFF00 <= cp <= 0xFFEF:
        return False  # CJK punctuation / fullwidth
    if 0x00A0 <= cp <= 0x024F:
        return False  # Latin-1 / extended
    if 0x2000 <= cp <= 0x206F:
        return False  # general punctuation
    if 0x2150 <= cp <= 0x2BFF:
        return False  # number forms (ⅠⅡⅢ①), arrows, math, misc symbols, dingbats
    if 0x2E80 <= cp <= 0x2FDF:
        return False  # CJK radicals supplement
    if cp in (0x00D7, 0x00F7, 0x2026, 0x203B, 0x25CB, 0x25CF, 0x2605, 0x266A):
        return False
    return True


def normalize_radicals(text: str) -> str:
    """Map Kangxi radicals (U+2E80-2FDF) and CJK compat ideographs (U+F900-FAFF)
    to their standard unified-ideograph forms; leave everything else untouched."""
    out = []
    for ch in text:
        cp = ord(ch)
        if 0x2E80 <= cp <= 0x2FDF or 0xF900 <= cp <= 0xFAFF:
            out.append(unicodedata.normalize("NFKC", ch))
        else:
            out.append(ch)
    return "".join(out)


def clean_page_text(text: str):
    """Return (cleaned_text, removed_garbled_lines_count)."""
    text = normalize_radicals(text)
    out_lines = []
    removed = 0
    for line in text.split("\n"):
        stripped = line.rstrip()
        if GARBLED_LINE.search(stripped) or is_noise_line(stripped):
            removed += 1
            continue
        out_lines.append(stripped)
    # collapse 3+ blank lines to 1
    cleaned = re.sub(r"\n[ \t]*\n[ \t]*\n+", "\n\n", "\n".join(out_lines))
    return cleaned.strip("\n"), removed


def convert_pdf(src_path: str):
    """Extract text per page. Returns (pages, diagnostics)."""
    pages = []
    diag = {
        "pages": 0,
        "chars": 0,
        "low_text_pages": [],
        "image_pages": [],
        "garbled_header_pages": 0,
        "suspicious_chars": 0,
        "suspicious_sample": "",
        "errors": [],
    }
    suspicious_seen = []
    with pdfplumber.open(src_path) as pdf:
        diag["pages"] = len(pdf.pages)
        for i, page in enumerate(pdf.pages, start=1):
            try:
                text = page.extract_text() or ""
            except Exception as e:  # noqa: BLE001
                diag["errors"].append(f"page {i}: {e}")
                text = ""
            cleaned, removed = clean_page_text(text)
            if removed:
                diag["garbled_header_pages"] += 1
            plain_len = len(re.sub(r"\s", "", cleaned))
            if plain_len < 20:
                diag["low_text_pages"].append(i)
                try:
                    if len(page.images) > 0:
                        diag["image_pages"].append(i)
                except Exception:  # noqa: BLE001
                    pass
            susp = [c for c in cleaned if is_suspicious(c)]
            if susp:
                diag["suspicious_chars"] += len(susp)
                for c in susp:
                    if c not in suspicious_seen:
                        suspicious_seen.append(c)
            diag["chars"] += len(cleaned)
            pages.append((i, cleaned))
    diag["suspicious_sample"] = "".join(suspicious_seen[:30])
    return pages, diag


def main():
    report = {}
    failures = []
    pdfs = []
    for root, _dirs, files in os.walk(SRC):
        for f in sorted(files):
            if f.lower().endswith(".pdf"):
                pdfs.append(os.path.join(root, f))
    pdfs.sort()
    total = len(pdfs)
    for idx, src_path in enumerate(pdfs, start=1):
        rel = os.path.relpath(src_path, SRC)
        out_path = os.path.join(DST, os.path.splitext(rel)[0] + ".md")
        os.makedirs(os.path.dirname(out_path), exist_ok=True)
        title = os.path.splitext(os.path.basename(src_path))[0]
        try:
            pages, diag = convert_pdf(src_path)
        except Exception as e:  # noqa: BLE001
            failures.append({"file": rel, "error": str(e)})
            report[rel] = {"status": "failed", "error": str(e)}
            print(f"[{idx}/{total}] FAIL {rel}: {e}", flush=True)
            continue

        notes = []
        if diag["image_pages"]:
            notes.append("含疑似扫描图片页（文本层为空）")
        if diag["suspicious_chars"]:
            notes.append("部分字符无法正确解码（乱码），多为中文字符/符号")
        status = "ok" if not notes else "ok-with-notes"

        lines = [
            f"# {title}",
            "",
            f"> 来源文件：`{rel}`（共 {diag['pages']} 页）",
        ]
        if notes:
            lines.append(f"> 转换备注：{'；'.join(notes)}")
        lines += ["", "---", ""]
        for pno, text in pages:
            lines.append(f"<!-- 第 {pno} 页 -->")
            lines.append("")
            lines.append(text)
            lines.append("")
        with open(out_path, "w", encoding="utf-8") as fh:
            fh.write("\n".join(lines))

        report[rel] = {"status": status, **diag}
        print(
            f"[{idx}/{total}] {status} {rel} "
            f"(pages={diag['pages']}, chars={diag['chars']}, susp={diag['suspicious_chars']})",
            flush=True,
        )

    os.makedirs(DST, exist_ok=True)
    with open(os.path.join(DST, "_conversion_report.json"), "w", encoding="utf-8") as fh:
        json.dump(report, fh, ensure_ascii=False, indent=2)
    print(f"\nDone. {total - len(failures)}/{total} converted, {len(failures)} failed.")


if __name__ == "__main__":
    sys.exit(main())
