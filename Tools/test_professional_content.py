# -*- coding: utf-8 -*-
import json
import unittest

import build_professional_content as professional


class ProfessionalContentTest(unittest.TestCase):
    def test_stable_ids_use_normalized_content_identity(self):
        first = professional.stable_id("v_", "学生", "がくせい")
        self.assertEqual(first, professional.stable_id("v_", "学 生", "がくせい"))
        self.assertNotEqual(first, professional.stable_id("v_", "学生", "がくせえ"))

    def test_romaji_uses_verified_kana_only(self):
        self.assertEqual(professional.to_romaji("がくせい"), "gakusei")
        self.assertEqual(professional.to_romaji("がっこう"), "gakkou")
        self.assertEqual(professional.to_romaji("せんせい"), "sensei")
        self.assertEqual(professional.to_romaji("コーヒー"), "koohii")
        self.assertEqual(professional.to_romaji("学生"), "")

    def test_blank_requires_explicit_japanese_spacing(self):
        self.assertEqual(professional.mark_blank("私は学生 です。"), "私は学生 ______ です。")
        self.assertEqual(professional.mark_blank("私は学生です。"), "")
        self.assertEqual(professional.mark_blank("A: 私は学生です。"), "")

    def test_reading_eligibility_rejects_extraction_fragments(self):
        self.assertEqual(professional.usable_reading("ドラマ", "电视"), "ドラマ")
        self.assertEqual(professional.usable_reading("きょうしつ", "２"), "きょうしつ")
        self.assertEqual(professional.usable_reading("学生", "がくせい"), "がくせい")
        self.assertEqual(professional.usable_reading("学生", "中国"), "")
        self.assertEqual(professional.usable_reading("アメリカ人", "Americaじん"), "Americaじん")

    def test_generated_corpus_reconciles_professional_indexes(self):
        outputs, report = professional.build()
        self.assertEqual(report["lesson_files"], 45)
        self.assertEqual(report["vocabulary"], 3503)
        self.assertEqual(report["grammar"], 401)
        self.assertEqual(report["legacy_cafe"], 20)
        self.assertEqual(len(outputs[professional.OUTPUT / "legacy_id_map.json"]), 1500)
        self.assertEqual(len(outputs[professional.LEGACY_VOCAB_OUTPUT]), 20)
        self.assertTrue(all("______" in item["prompt"] for item in outputs[professional.OUTPUT / "exercises.json"]))

    def test_generation_is_deterministic(self):
        first, _ = professional.build()
        second, _ = professional.build()
        self.assertEqual(first, second)

    def test_every_sentence_and_exercise_has_professional_provenance(self):
        outputs, _ = professional.build()
        for filename in ("grammar.json", "sentences.json", "readings.json", "exercises.json"):
            for entry in outputs[professional.OUTPUT / filename]:
                self.assertIn("source_file", entry)
                self.assertTrue((professional.MARKDOWN / entry["source_file"]).is_file())
                self.assertGreater(entry["source_line"], 0)

    def test_official_and_cafe_ids_do_not_overlap(self):
        outputs, _ = professional.build()
        official = {entry["id"] for entry in outputs[professional.OUTPUT / "vocabulary.json"]}
        cafe = {entry["id"] for entry in outputs[professional.LEGACY_VOCAB_OUTPUT]}
        self.assertFalse(official.intersection(cafe))


if __name__ == "__main__":
    unittest.main()
