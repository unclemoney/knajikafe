# -*- coding: utf-8 -*-
"""Validate and apply reviewer-owned corrections to the separate kanji dataset."""
import csv
import datetime
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REVIEW_DIR = ROOT / "Tools" / "content" / "review"
DRAFT = "draft_pending_human_review"
STATUSES = {DRAFT, "needs_correction", "human_reviewed"}


class ReviewError(ValueError):
    pass


def load_json(relative):
    return json.loads((ROOT / relative).read_text(encoding="utf-8"))


def write_json(relative, value):
    path = ROOT / relative
    with path.open("w", encoding="utf-8", newline="\n") as file:
        json.dump(value, file, ensure_ascii=False, indent=2)
        file.write("\n")


def read_rows(filename, key, expected_ids):
    path = REVIEW_DIR / filename
    if not path.exists():
        raise ReviewError(f"Missing review file: {path}")
    with path.open(encoding="utf-8-sig", newline="") as file:
        rows = list(csv.DictReader(file))
    result = {}
    for index, row in enumerate(rows, start=2):
        identity = row.get(key, "")
        if not identity or identity in result:
            raise ReviewError(f"{filename}:{index}: missing or duplicate {key}")
        status = row.get("review_status", DRAFT)
        if status not in STATUSES:
            raise ReviewError(f"{filename}:{index}: invalid review status {status}")
        if status == "human_reviewed":
            if not row.get("reviewer", "").strip() or not row.get("reviewed_at", "").strip():
                raise ReviewError(f"{filename}:{index}: approval requires reviewer and reviewed_at")
            try:
                datetime.date.fromisoformat(row["reviewed_at"])
            except ValueError as error:
                raise ReviewError(f"{filename}:{index}: reviewed_at must be YYYY-MM-DD") from error
        result[identity] = row
    if set(result) != set(expected_ids):
        missing = sorted(set(expected_ids) - set(result))
        extra = sorted(set(result) - set(expected_ids))
        raise ReviewError(f"{filename}: ID mismatch; missing={missing[:5]}, extra={extra[:5]}")
    return result


def array_value(row, field):
    try:
        value = json.loads(row[field])
    except (KeyError, json.JSONDecodeError) as error:
        raise ReviewError(f"{row.get('character', 'row')}: invalid {field}") from error
    if not isinstance(value, list) or not all(isinstance(item, str) for item in value):
        raise ReviewError(f"{row.get('character', 'row')}: {field} must be a string array")
    return value


def review_fields(entry, row):
    entry["review_status"] = row["review_status"]
    entry["reviewer"] = row.get("reviewer", "").strip()
    entry["reviewed_at"] = row.get("reviewed_at", "").strip()
    entry["review_notes"] = row.get("notes", "")


def apply_kanji():
    entries = []
    for level in (5, 4):
        entries.extend((f"Resources/Kanji/n{level}_kanji.json", entry) for entry in load_json(f"Resources/Kanji/n{level}_kanji.json"))
    rows = read_rows("kanji_review.csv", "character", [entry["character"] for _, entry in entries])
    by_path = {}
    for path, entry in entries:
        row = rows[entry["character"]]
        if row["review_status"] == "human_reviewed":
            entry["meanings"] = array_value(row, "meanings_json")
            entry["on_readings"] = array_value(row, "on_readings_json")
            entry["kun_readings"] = array_value(row, "kun_readings_json")
            try:
                entry["stroke_count"] = int(row["stroke_count"])
                entry["jlpt_level"] = int(row["jlpt_level"])
                entry["source_level"] = int(row["source_level"])
            except ValueError as error:
                raise ReviewError(f"{entry['character']}: stroke/JLPT/source levels must be integers") from error
            entry["radical"] = row["radical"]
            entry["components"] = array_value(row, "components_json")
        review_fields(entry, row)
        by_path.setdefault(path, []).append(entry)
    for path, kanji in by_path.items():
        write_json(path, kanji)
    print(f"Applied review metadata to {len(entries)} kanji entries")


def main():
    try:
        apply_kanji()
    except ReviewError as error:
        raise SystemExit(f"Review application failed: {error}") from error


if __name__ == "__main__":
    main()
