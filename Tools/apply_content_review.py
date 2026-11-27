# -*- coding: utf-8 -*-
"""Validate and apply reviewer-owned corrections to generated curriculum data."""
import csv
import datetime
import hashlib
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
        reader = csv.DictReader(file)
        rows = list(reader)
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
        raise ReviewError(f"{row.get('id', row.get('character', 'row'))}: invalid {field}") from error
    if not isinstance(value, list) or not all(isinstance(item, str) for item in value):
        raise ReviewError(f"{row.get('id', row.get('character', 'row'))}: {field} must be a string array")
    return value


def review_fields(entry, row):
    entry["review_status"] = row["review_status"]
    entry["reviewer"] = row.get("reviewer", "").strip()
    entry["reviewed_at"] = row.get("reviewed_at", "").strip()
    entry["review_notes"] = row.get("notes", "")


def apply_vocabulary():
    entries = []
    for level in (5, 4):
        entries.extend((f"Resources/Vocabulary/n{level}_vocab.json", word) for word in load_json(f"Resources/Vocabulary/n{level}_vocab.json"))
    rows = read_rows("vocabulary_review.csv", "id", [word["id"] for _, word in entries])
    by_path = {}
    for path, word in entries:
        row = rows[word["id"]]
        if row["review_status"] == "human_reviewed":
            word["kanji"] = row["kanji"]
            word["hiragana"] = row["hiragana"]
            word["katakana"] = row["katakana"]
            word["romaji"] = row["romaji"]
            word["english_meanings"] = array_value(row, "english_meanings_json")
            word["categories"] = array_value(row, "categories_json")
            word["example_sentences"] = array_value(row, "example_sentences_json")
            word["part_of_speech"] = row["part_of_speech"]
        review_fields(word, row)
        by_path.setdefault(path, []).append(word)
    for path, words in by_path.items():
        write_json(path, words)
    print(f"Applied review metadata to {len(entries)} vocabulary entries")


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


def apply_reading():
    entries = []
    for level in (5, 4):
        entries.extend((f"Resources/Reading/n{level}_reading.json", passage) for passage in load_json(f"Resources/Reading/n{level}_reading.json"))
    rows = read_rows("reading_review.csv", "id", [passage["id"] for _, passage in entries])
    by_path = {}
    for path, passage in entries:
        row = rows[passage["id"]]
        if row["review_status"] == "human_reviewed":
            try:
                passage["jlpt_level"] = int(row["jlpt_level"])
                passage["answer_index"] = int(row["answer_index"])
            except ValueError as error:
                raise ReviewError(f"{passage['id']}: JLPT level and answer index must be integers") from error
            passage["target_vocab_id"] = row["target_vocab_id"]
            passage["related_vocab_ids"] = array_value(row, "related_vocab_ids_json")
            passage["japanese_lines"] = array_value(row, "japanese_lines_json")
            passage["english_lines"] = array_value(row, "english_lines_json")
            passage["question"] = row["question"]
            passage["choices"] = array_value(row, "choices_json")
            passage["explanation"] = row["explanation"]
        review_fields(passage, row)
        by_path.setdefault(path, []).append(passage)
    for path, passages in by_path.items():
        write_json(path, passages)
    print(f"Applied review metadata to {len(entries)} reading passages")


def apply_audio():
    relative = "Resources/Audio/japanese_audio_manifest.json"
    manifest = load_json(relative)
    rows = read_rows("audio_review.csv", "id", [clip["id"] for clip in manifest])
    for clip in manifest:
        row = rows[clip["id"]]
        source_hash = hashlib.sha256(clip["source_text"].encode("utf-8")).hexdigest()
        if row["source_text"] != clip["source_text"] or row["source_hash"] != source_hash:
            raise ReviewError(f"{clip['id']}: audio review source/hash is stale; re-export the review workbook")
        if clip["source_hash"] != source_hash:
            raise ReviewError(f"{clip['id']}: manifest source hash is invalid")
        review_fields(clip, row)
    write_json(relative, manifest)
    print(f"Applied review metadata to {len(manifest)} audio clips")


def main():
    try:
        apply_vocabulary()
        apply_kanji()
        apply_reading()
        apply_audio()
    except ReviewError as error:
        raise SystemExit(f"Review application failed: {error}") from error


if __name__ == "__main__":
    main()
