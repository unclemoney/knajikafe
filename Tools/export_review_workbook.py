# -*- coding: utf-8 -*-
"""Export the separate kanji review CSV without discarding existing review work."""
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REVIEW_DIR = ROOT / "Tools" / "content" / "review"
DRAFT = "draft_pending_human_review"
STATUSES = {DRAFT, "needs_correction", "human_reviewed"}
KANJI_FIELDS = [
    "character", "review_status", "reviewer", "reviewed_at", "meanings_json", "on_readings_json",
    "kun_readings_json", "stroke_count", "jlpt_level", "radical", "components_json", "source_level", "notes",
]


def load_json(relative):
    return json.loads((ROOT / relative).read_text(encoding="utf-8"))


def load_existing(path, key):
    if not path.exists():
        return {}
    with path.open(encoding="utf-8-sig", newline="") as file:
        return {row[key]: row for row in csv.DictReader(file)}


def write_csv(filename, fields, rows):
    REVIEW_DIR.mkdir(parents=True, exist_ok=True)
    path = REVIEW_DIR / filename
    with path.open("w", encoding="utf-8-sig", newline="") as file:
        writer = csv.DictWriter(file, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)
    print(f"Exported {len(rows)} rows to {path.relative_to(ROOT)}")


def metadata(entry):
    status = entry.get("review_status", DRAFT)
    if status not in STATUSES:
        status = DRAFT
    return {"review_status": status, "reviewer": entry.get("reviewer", ""), "reviewed_at": entry.get("reviewed_at", ""), "notes": entry.get("notes", "")}


def preserved(existing, key, new_row):
    previous = existing.get(key)
    if previous and previous.get("review_status") in {"needs_correction", "human_reviewed"}:
        return previous
    if previous:
        new_row.update({field: previous.get(field, "") for field in ("review_status", "reviewer", "reviewed_at", "notes")})
    return new_row


def export_kanji():
    existing = load_existing(REVIEW_DIR / "kanji_review.csv", "character")
    rows = []
    for level in (5, 4):
        for entry in load_json(f"Resources/Kanji/n{level}_kanji.json"):
            row = {field: "" for field in KANJI_FIELDS}
            row.update(metadata(entry))
            row.update({
                "character": entry["character"],
                "meanings_json": json.dumps(entry.get("meanings", []), ensure_ascii=False),
                "on_readings_json": json.dumps(entry.get("on_readings", []), ensure_ascii=False),
                "kun_readings_json": json.dumps(entry.get("kun_readings", []), ensure_ascii=False),
                "stroke_count": str(entry.get("stroke_count", 1)), "jlpt_level": str(entry.get("jlpt_level", level)),
                "radical": entry.get("radical", ""),
                "components_json": json.dumps(entry.get("components", []), ensure_ascii=False),
                "source_level": str(entry.get("source_level", level)),
            })
            rows.append(preserved(existing, entry["character"], row))
    write_csv("kanji_review.csv", KANJI_FIELDS, rows)


def main():
    export_kanji()


if __name__ == "__main__":
    main()
