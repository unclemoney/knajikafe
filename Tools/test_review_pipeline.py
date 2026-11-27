# -*- coding: utf-8 -*-
"""Focused tests for review metadata, correction persistence, and audio invalidation."""
import csv
import hashlib
import json
import tempfile
import unittest
from pathlib import Path

import apply_content_review as apply_review
import export_review_workbook as export_review


class ReviewPipelineTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(dir=Path(__file__).parent)
        self.root = Path(self.temp.name)
        self.review_dir = self.root / "Tools" / "content" / "review"
        self.review_dir.mkdir(parents=True)
        self.old_roots = (apply_review.ROOT, export_review.ROOT)
        self.old_review_dirs = (apply_review.REVIEW_DIR, export_review.REVIEW_DIR)
        apply_review.ROOT = self.root
        export_review.ROOT = self.root
        apply_review.REVIEW_DIR = self.review_dir
        export_review.REVIEW_DIR = self.review_dir

    def tearDown(self):
        apply_review.ROOT, export_review.ROOT = self.old_roots
        apply_review.REVIEW_DIR, export_review.REVIEW_DIR = self.old_review_dirs
        self.temp.cleanup()

    def write_json(self, relative, value):
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(value, ensure_ascii=False), encoding="utf-8")

    def write_csv(self, filename, fields, rows):
        with (self.review_dir / filename).open("w", encoding="utf-8-sig", newline="") as file:
            writer = csv.DictWriter(file, fieldnames=fields)
            writer.writeheader()
            writer.writerows(rows)

    def word(self, word_id, meaning):
        return {
            "id": word_id, "kanji": "猫", "hiragana": "ねこ", "katakana": "ネコ", "romaji": "neko",
            "english_meanings": [meaning], "jlpt_level": int(word_id[1]), "categories": ["animals"],
            "example_sentences": ["猫です。|It is a cat."], "part_of_speech": "noun",
        }

    def review_row(self, word_id, status="human_reviewed"):
        row = {field: "" for field in export_review.VOCAB_FIELDS}
        row.update({
            "id": word_id, "review_status": status, "reviewer": "Qualified Reviewer", "reviewed_at": "2026-11-27",
            "kanji": "猫", "hiragana": "ねこ", "katakana": "ネコ", "romaji": "neko",
            "english_meanings_json": '["cat (reviewed)"]', "categories_json": '["animals"]',
            "example_sentences_json": '["猫です。|It is a cat."]', "part_of_speech": "noun",
        })
        return row

    def test_vocabulary_correction_survives_regeneration(self):
        for level in (5, 4):
            self.write_json(f"Resources/Vocabulary/n{level}_vocab.json", [self.word(f"n{level}_001", "cat")])
        rows = [self.review_row("n5_001"), self.review_row("n4_001", "draft_pending_human_review")]
        self.write_csv("vocabulary_review.csv", export_review.VOCAB_FIELDS, rows)
        apply_review.apply_vocabulary()
        corrected = json.loads((self.root / "Resources/Vocabulary/n5_vocab.json").read_text(encoding="utf-8"))[0]
        self.assertEqual(corrected["english_meanings"], ["cat (reviewed)"])
        self.assertEqual(corrected["review_status"], "human_reviewed")
        self.write_json("Resources/Vocabulary/n5_vocab.json", [self.word("n5_001", "cat")])
        apply_review.apply_vocabulary()
        regenerated = json.loads((self.root / "Resources/Vocabulary/n5_vocab.json").read_text(encoding="utf-8"))[0]
        self.assertEqual(regenerated["english_meanings"], ["cat (reviewed)"])

    def test_approval_requires_reviewer_metadata(self):
        rows = {"n5_001": self.review_row("n5_001")}
        rows["n5_001"]["reviewer"] = ""
        with self.assertRaises(apply_review.ReviewError):
            self._validate_rows(rows)

    def _validate_rows(self, rows):
        self.write_csv("vocabulary_review.csv", export_review.VOCAB_FIELDS, rows.values())
        return apply_review.read_rows("vocabulary_review.csv", "id", list(rows))

    def test_audio_hash_change_invalidates_approval(self):
        source_text = "ねこ"
        old_hash = hashlib.sha256("いぬ".encode("utf-8")).hexdigest()
        self.write_json("Resources/Audio/japanese_audio_manifest.json", [{
            "id": "vocab:n5_001", "source_text": source_text, "source_hash": hashlib.sha256(source_text.encode("utf-8")).hexdigest(),
            "file": "res://Audio/Japanese/Vocabulary/n5_001.ogg", "review_status": "human_reviewed",
        }])
        row = {field: "" for field in export_review.AUDIO_FIELDS}
        row.update({
            "id": "vocab:n5_001", "review_status": "human_reviewed", "reviewer": "Qualified Reviewer",
            "reviewed_at": "2026-11-27", "source_text": "いぬ", "source_hash": old_hash,
            "playback_path": "Audio/Japanese/Vocabulary/n5_001.ogg",
        })
        self.write_csv("audio_review.csv", export_review.AUDIO_FIELDS, [row])
        export_review.export_audio()
        with (self.review_dir / "audio_review.csv").open(encoding="utf-8-sig", newline="") as file:
            exported = list(csv.DictReader(file))[0]
        self.assertEqual(exported["review_status"], "draft_pending_human_review")
        self.assertEqual(exported["reviewer"], "")
        self.assertIn("re-review", exported["notes"])


if __name__ == "__main__":
    unittest.main()
