# -*- coding: utf-8 -*-
"""Focused tests for the separate kanji review workflow."""
import csv
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

    def kanji(self, character, level, meaning="cat"):
        return {
            "character": character, "meanings": [meaning], "on_readings": ["ネコ"], "kun_readings": ["ねこ"],
            "stroke_count": 3, "jlpt_level": level, "radical": "猫", "components": [], "source_level": level,
        }

    def review_row(self, character, level, status="human_reviewed"):
        row = {field: "" for field in export_review.KANJI_FIELDS}
        row.update({
            "character": character, "review_status": status, "reviewer": "Qualified Reviewer", "reviewed_at": "2026-11-27",
            "meanings_json": '["cat (reviewed)"]', "on_readings_json": '["ネコ"]', "kun_readings_json": '["ねこ"]',
            "stroke_count": "3", "jlpt_level": str(level), "source_level": str(level), "radical": "猫", "components_json": "[]",
        })
        return row

    def write_kanji_and_reviews(self):
        for level, character in ((5, "猫"), (4, "犬")):
            self.write_json(f"Resources/Kanji/n{level}_kanji.json", [self.kanji(character, level)])
        self.write_csv("kanji_review.csv", export_review.KANJI_FIELDS, [self.review_row("猫", 5), self.review_row("犬", 4, apply_review.DRAFT)])

    def test_kanji_correction_survives_regeneration(self):
        self.write_kanji_and_reviews()
        apply_review.apply_kanji()
        corrected = json.loads((self.root / "Resources/Kanji/n5_kanji.json").read_text(encoding="utf-8"))[0]
        self.assertEqual(corrected["meanings"], ["cat (reviewed)"])
        self.assertEqual(corrected["review_status"], "human_reviewed")
        self.write_json("Resources/Kanji/n5_kanji.json", [self.kanji("猫", 5)])
        apply_review.apply_kanji()
        regenerated = json.loads((self.root / "Resources/Kanji/n5_kanji.json").read_text(encoding="utf-8"))[0]
        self.assertEqual(regenerated["meanings"], ["cat (reviewed)"])

    def test_approval_requires_reviewer_metadata(self):
        row = self.review_row("猫", 5)
        row["reviewer"] = ""
        self.write_csv("kanji_review.csv", export_review.KANJI_FIELDS, [row])
        with self.assertRaises(apply_review.ReviewError):
            apply_review.read_rows("kanji_review.csv", "character", ["猫"])

    def test_kanji_export_preserves_existing_approval(self):
        self.write_kanji_and_reviews()
        export_review.export_kanji()
        with (self.review_dir / "kanji_review.csv").open(encoding="utf-8-sig", newline="") as file:
            rows = {row["character"]: row for row in csv.DictReader(file)}
        self.assertEqual(rows["猫"]["review_status"], "human_reviewed")
        self.assertEqual(rows["猫"]["reviewer"], "Qualified Reviewer")


if __name__ == "__main__":
    unittest.main()
