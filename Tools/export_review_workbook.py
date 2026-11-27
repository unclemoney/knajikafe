# -*- coding: utf-8 -*-
"""Export reviewer-editable CSV files without discarding existing review work."""
import csv
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REVIEW_DIR = ROOT / "Tools" / "content" / "review"
DRAFT = "draft_pending_human_review"
STATUSES = {DRAFT, "needs_correction", "human_reviewed"}

VOCAB_FIELDS = [
    "id", "review_status", "reviewer", "reviewed_at", "kanji", "hiragana", "katakana", "romaji",
    "english_meanings_json", "categories_json", "example_sentences_json", "part_of_speech", "notes",
]
KANJI_FIELDS = [
    "character", "review_status", "reviewer", "reviewed_at", "meanings_json", "on_readings_json",
    "kun_readings_json", "stroke_count", "jlpt_level", "radical", "components_json", "source_level", "notes",
]
READING_FIELDS = [
    "id", "review_status", "reviewer", "reviewed_at", "jlpt_level", "target_vocab_id", "related_vocab_ids_json",
    "japanese_lines_json", "english_lines_json", "question", "choices_json", "answer_index", "explanation", "notes",
]
AUDIO_FIELDS = ["id", "review_status", "reviewer", "reviewed_at", "source_text", "source_hash", "playback_path", "notes"]


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


def export_vocab():
    rows = []
    for level in (5, 4):
        filename = f"Resources/Vocabulary/n{level}_vocab.json"
        existing = load_existing(REVIEW_DIR / "vocabulary_review.csv", "id")
        for word in load_json(filename):
            row = {field: "" for field in VOCAB_FIELDS}
            row.update(metadata(word))
            row.update({
                "id": word["id"], "kanji": word.get("kanji", ""), "hiragana": word.get("hiragana", ""),
                "katakana": word.get("katakana", ""), "romaji": word.get("romaji", ""),
                "english_meanings_json": json.dumps(word.get("english_meanings", []), ensure_ascii=False),
                "categories_json": json.dumps(word.get("categories", []), ensure_ascii=False),
                "example_sentences_json": json.dumps(word.get("example_sentences", []), ensure_ascii=False),
                "part_of_speech": word.get("part_of_speech", ""),
            })
            rows.append(preserved(existing, word["id"], row))
    write_csv("vocabulary_review.csv", VOCAB_FIELDS, rows)


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


def export_reading():
    existing = load_existing(REVIEW_DIR / "reading_review.csv", "id")
    rows = []
    for level in (5, 4):
        for passage in load_json(f"Resources/Reading/n{level}_reading.json"):
            row = {field: "" for field in READING_FIELDS}
            row.update(metadata(passage))
            row.update({
                "id": passage["id"], "jlpt_level": str(passage.get("jlpt_level", level)),
                "target_vocab_id": passage.get("target_vocab_id", ""),
                "related_vocab_ids_json": json.dumps(passage.get("related_vocab_ids", []), ensure_ascii=False),
                "japanese_lines_json": json.dumps(passage.get("japanese_lines", []), ensure_ascii=False),
                "english_lines_json": json.dumps(passage.get("english_lines", []), ensure_ascii=False),
                "question": passage.get("question", ""),
                "choices_json": json.dumps(passage.get("choices", []), ensure_ascii=False),
                "answer_index": str(passage.get("answer_index", 0)), "explanation": passage.get("explanation", ""),
            })
            rows.append(preserved(existing, passage["id"], row))
    write_csv("reading_review.csv", READING_FIELDS, rows)


def export_audio():
    path = REVIEW_DIR / "audio_review.csv"
    existing = load_existing(path, "id")
    rows = []
    for clip in load_json("Resources/Audio/japanese_audio_manifest.json"):
        source_hash = hashlib.sha256(clip["source_text"].encode("utf-8")).hexdigest()
        row = {field: "" for field in AUDIO_FIELDS}
        row.update(metadata(clip))
        row.update({
            "id": clip["id"], "source_text": clip["source_text"], "source_hash": source_hash,
            "playback_path": clip["file"].removeprefix("res://"),
        })
        previous = existing.get(clip["id"])
        if previous:
            row.update({field: previous.get(field, "") for field in ("review_status", "reviewer", "reviewed_at", "notes")})
            if previous.get("source_hash") != source_hash:
                row["review_status"] = DRAFT
                row["reviewer"] = ""
                row["reviewed_at"] = ""
                row["notes"] = "Source hash changed; pronunciation re-review required."
        rows.append(row)
    write_csv("audio_review.csv", AUDIO_FIELDS, rows)


def main():
    export_vocab()
    export_kanji()
    export_reading()
    export_audio()


if __name__ == "__main__":
    main()
