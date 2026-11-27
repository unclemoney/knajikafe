# PDF → Markdown Conversion Report

Converted: 2026-11-27 | Source: `Source Material/` (88 PDFs) | Output: `markdown/`

## Overall result

- **88 / 88 files converted successfully, no failures** — about 359,000 characters extracted.
- 84 files fully normal; 4 files carry a note (only because they contain a blank QR-code page, see below).
- All body text decoded successfully; no garbled characters remain.
- Chinese explanations have been translated into English; all Japanese is preserved verbatim.

## Output structure

Each PDF maps to one `.md` file of the same name; the folder hierarchy mirrors the source:

- `入门20讲/` (Lessons 1–4 lectures + L1–L4 answers)
- `初级上/` (Lessons 5–16)
- `初级下/` (Lessons 17–25)
- `中级上/` (Lessons 26–32)
- `中级下/` (Lessons 33–39)
- `高级/` (Lessons 40–45)

In-file format: title + source annotation + body text in page order (`<!-- Page N -->` comments mark page boundaries; invisible when rendered).

## Known limitations (content itself is intact; inherent to the PDF text layer)

1. **Header garbage cleaned**: the original PDF page headers ("梁爽老师日语精讲精练：0-N1 第 N 课") used a font without a proper encoding mapping, so the text layer was garbage symbols; those lines were removed as noise. This duplicates the file name / H1 title, so nothing was lost.
2. **Furigana (reading aids) placement**: kanji readings in the lecture slides are preserved in two ways — either inline between characters (e.g. 「長は谷せ川がわ」), or on separate lines above the kanji (advanced-level texts). This is inherent to the PDF text layer; if you want the readings separated for study use, further processing is possible.
3. **Tables expanded to line-by-line text**: vocabulary tables, adjective four-quadrant exercises, etc. are laid out line by line; row/column alignment was not kept as Markdown tables, but all cell content is complete.
4. **Images not carried over**: QR codes and decorative illustrations in the slides were not converted (Markdown is plain text).

## The 4 files with notes (no content loss)

Each of the following files contains one blank QR-code-only page ("扫码听课"); each was visually inspected page by page to confirm it contains no body text:

| File | Blank page |
|---|---|
| 初级上/1.梁爽老师日语精讲精练：第5课 | Page 2 |
| 初级上/3.梁爽老师日语精讲精练：第6课 | Page 2 |
| 初级上/23.梁爽老师日语精讲精练：第14课 | Page 15 |
| 初级下/5.梁爽老师日语精讲精练：第19课 | Page 2 |

## Fixes applied during conversion

- Kangxi radical characters (e.g. ⾳⼦⾊, U+2F00 block) were normalized to standard kanji (音子色）.
- Answer files with unusually small extraction volume (Lessons 21 and 26 answers) were visually inspected page by page; the originals are indeed short multiple-choice answers — content is complete.

Detailed per-file data: see `_conversion_report.json`.
