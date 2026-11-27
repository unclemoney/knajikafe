# -*- coding: utf-8 -*-
"""Validate professional curriculum, legacy supplements, kanji, and audio."""
import argparse
import hashlib
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class ContentValidator:
    def __init__(self, validate_audio=True):
        self.errors = []
        self.validate_audio = validate_audio
        self.counts = {}

    def check(self, condition, message):
        if not condition:
            self.errors.append(message)

    def load_json(self, relative):
        path = ROOT / relative
        if not path.is_file():
            self.errors.append(f"{relative}: missing file")
            return []
        data = path.read_bytes()
        self.check(not data.startswith(b"\xef\xbb\xbf"), f"{relative}: UTF-8 BOM is not allowed")
        try:
            value = json.loads(data.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as error:
            self.errors.append(f"{relative}: invalid UTF-8 JSON: {error}")
            return []
        return value

    def array(self, relative):
        value = self.load_json(relative)
        self.check(isinstance(value, list), f"{relative}: root must be an array")
        return value if isinstance(value, list) else []

    def resource_path(self, resource):
        if not isinstance(resource, str) or not resource.startswith("res://"):
            return None
        return ROOT / resource.removeprefix("res://")

    def unique_ids(self, entries, label):
        result = {}
        for index, entry in enumerate(entries):
            if not isinstance(entry, dict):
                self.errors.append(f"{label}[{index}]: must be an object")
                continue
            identity = entry.get("id", "")
            self.check(isinstance(identity, str) and identity, f"{label}[{index}]: missing ID")
            self.check(identity not in result, f"{label}[{index}]: duplicate ID {identity}")
            result[identity] = entry
        return result

    def validate_source(self, entry, lessons, context):
        lesson = entry.get("lesson")
        self.check(lesson in lessons, f"{context}: invalid lesson {lesson}")
        source = entry.get("source_file", "")
        path = ROOT / "markdown" / source
        self.check(path.is_file(), f"{context}: missing source {source}")
        self.check(isinstance(entry.get("source_line"), int) and entry["source_line"] > 0, f"{context}: invalid source line")
        self.check(isinstance(entry.get("source_page"), int) and entry["source_page"] > 0, f"{context}: invalid source page")

    def validate(self):
        lesson_entries = self.array("Resources/Curriculum/lessons.json")
        self.check(len(lesson_entries) == 45, f"Lessons: expected 45, got {len(lesson_entries)}")
        lesson_by_number = {}
        for index, lesson in enumerate(lesson_entries):
            context = f"lessons[{index}]"
            number = lesson.get("number")
            self.check(number == index + 1, f"{context}: lessons must be ordered 1–45")
            self.check(lesson.get("id") == f"lesson_{number:02d}", f"{context}: invalid lesson ID")
            lesson_by_number[number] = lesson
            source = ROOT / "markdown" / lesson.get("source_file", "")
            self.check(source.is_file(), f"{context}: missing source")
            if source.is_file():
                digest = hashlib.sha256(source.read_bytes()).hexdigest()
                self.check(lesson.get("source_hash") == digest, f"{context}: source hash mismatch")

        vocab_entries = self.array("Resources/Curriculum/vocabulary.json")
        self.check(len(vocab_entries) == 3503, f"Vocabulary: expected 3503, got {len(vocab_entries)}")
        vocab = self.unique_ids(vocab_entries, "vocabulary")
        identity_keys = set()
        for identity, word in vocab.items():
            context = f"vocabulary:{identity}"
            self.check(identity.startswith("v_") and len(identity) == 18, f"{context}: invalid stable ID")
            self.check(word.get("content_source") == "professional_lesson", f"{context}: wrong content source")
            for field in ("kanji", "hiragana", "katakana", "romaji", "part_of_speech", "stage", "source_word", "source_reading"):
                self.check(isinstance(word.get(field), str), f"{context}: {field} must be a string")
            display = word.get("kanji") or word.get("hiragana") or word.get("katakana")
            self.check(bool(display), f"{context}: missing display text")
            pair = (word.get("source_word"), word.get("source_reading"))
            self.check(pair not in identity_keys, f"{context}: duplicate source identity {pair}")
            identity_keys.add(pair)
            refs = word.get("lesson_ids", [])
            self.check(bool(refs) and all(ref in lesson_by_number for ref in refs), f"{context}: invalid lesson references")
            self.check(word.get("first_lesson") == min(refs) if refs else False, f"{context}: invalid first lesson")
            meanings = word.get("english_meanings", [])
            self.check(isinstance(meanings, list) and all(isinstance(value, str) and value.strip() for value in meanings), f"{context}: invalid meanings")
            self.check(bool(meanings) == bool(word.get("eligibility", {}).get("meaning")), f"{context}: meaning eligibility mismatch")
            for example in word.get("example_sentences", []):
                parts = example.split("|")
                self.check(len(parts) == 2 and all(part.strip() for part in parts), f"{context}: malformed example")
                if len(parts) == 2:
                    self.check(word["source_word"] in parts[0], f"{context}: example target missing")
            if word.get("romaji"):
                self.check(bool(word.get("hiragana") or word.get("katakana")), f"{context}: romaji without kana")
            reading = word.get("hiragana") or word.get("katakana")
            if reading and word.get("eligibility", {}).get("reading", False):
                import re
                self.check(bool(re.search(r"[ぁ-ゟ゠-ヿ]", reading)) and not re.search(r"[一-鿿0-9０-９]", reading), f"{context}: unusable runtime reading")

        grammar_entries = self.array("Resources/Curriculum/grammar.json")
        self.check(len(grammar_entries) == 401, f"Grammar: expected 401, got {len(grammar_entries)}")
        grammar = self.unique_ids(grammar_entries, "grammar")
        for identity, entry in grammar.items():
            context = f"grammar:{identity}"
            self.validate_source(entry, lesson_by_number, context)
            self.check(entry.get("kind") in {"语法", "表达扩展"}, f"{context}: invalid kind")
            self.check(entry.get("title", "").strip(), f"{context}: missing title")
            self.check(isinstance(entry.get("body_lines"), list) and entry["body_lines"], f"{context}: empty professional body")

        sentence_entries = self.array("Resources/Curriculum/sentences.json")
        sentences = self.unique_ids(sentence_entries, "sentences")
        for identity, sentence in sentences.items():
            context = f"sentences:{identity}"
            self.validate_source(sentence, lesson_by_number, context)
            self.check(sentence.get("japanese", "").strip() and sentence.get("english", "").strip(), f"{context}: incomplete sentence pair")
            self.check(all(word_id in vocab for word_id in sentence.get("vocab_ids", [])), f"{context}: invalid vocabulary link")
        for identity, entry in grammar.items():
            self.check(all(sentence_id in sentences for sentence_id in entry.get("sentence_ids", [])), f"grammar:{identity}: invalid sentence link")

        reading_entries = self.array("Resources/Curriculum/readings.json")
        readings = self.unique_ids(reading_entries, "readings")
        for identity, passage in readings.items():
            context = f"readings:{identity}"
            self.validate_source(passage, lesson_by_number, context)
            japanese = passage.get("japanese_lines", [])
            english = passage.get("english_lines", [])
            self.check(bool(japanese) and all(line.strip() for line in japanese), f"{context}: missing Japanese passage")
            self.check(not english or len(english) == len(japanese), f"{context}: translation line mismatch")
            self.check(all(word_id in vocab for word_id in passage.get("related_vocab_ids", [])), f"{context}: invalid related vocabulary")
            if passage.get("question"):
                self.check(len(passage.get("choices", [])) == 4 and 0 <= passage.get("answer_index", -1) < 4, f"{context}: invalid authored question")

        exercise_entries = self.array("Resources/Curriculum/exercises.json")
        exercises = self.unique_ids(exercise_entries, "exercises")
        for identity, exercise in exercises.items():
            context = f"exercises:{identity}"
            self.validate_source(exercise, lesson_by_number, context)
            self.check("______" in exercise.get("prompt", ""), f"{context}: missing explicit blank")
            choices = exercise.get("choices", [])
            self.check(len(choices) == 4 and len(set(choices)) == 4 and all(choice.strip() for choice in choices), f"{context}: four real choices required")
            self.check(0 <= exercise.get("answer_index", -1) < 4, f"{context}: invalid answer index")
            self.check(exercise.get("target_vocab_id") in vocab, f"{context}: invalid vocabulary target")

        legacy_map = self.load_json("Resources/Curriculum/legacy_id_map.json")
        self.check(isinstance(legacy_map, dict) and len(legacy_map) == 1500, "Legacy map: expected 1500 old IDs")
        cafe_words_list = self.array("Resources/Vocabulary/cafe_legacy_vocab.json")
        cafe_words = self.unique_ids(cafe_words_list, "cafe_legacy")
        self.check(len(cafe_words) == 20, f"Café legacy: expected 20 words, got {len(cafe_words)}")
        for old_id, mapping in legacy_map.items():
            target = mapping.get("target_id", "")
            match_type = mapping.get("match_type")
            if match_type == "exact":
                self.check(target in vocab, f"Legacy map:{old_id}: invalid exact target")
            elif match_type == "cafe_legacy":
                self.check(target == old_id and target in cafe_words, f"Legacy map:{old_id}: invalid café exemption")
            else:
                self.check(not target, f"Legacy map:{old_id}: unmatched IDs must not have targets")
        for identity, word in cafe_words.items():
            self.check(word.get("content_source") == "legacy_cafe", f"cafe_legacy:{identity}: wrong source")
            self.check(identity not in vocab, f"cafe_legacy:{identity}: leaked into official curriculum")

        self.validate_kanji()
        menu = self.array("Resources/Vocabulary/cafe_menu.json")
        self.check(len(menu) == 20, f"Menu: expected 20, got {len(menu)}")
        menu_ids = set()
        for index, item in enumerate(menu):
            context = f"menu[{index}]"
            word_id = item.get("vocab_id")
            self.check(word_id in cafe_words and word_id not in menu_ids, f"{context}: invalid/duplicate café word")
            menu_ids.add(word_id)
            self.check(item.get("order_clip") == f"order:{word_id}", f"{context}: invalid order clip")
            self.check(item.get("order_text", "").strip(), f"{context}: missing order text")
            texture = self.resource_path(item.get("texture"))
            self.check(texture is not None and texture.is_file(), f"{context}: missing texture")
            if texture is not None and texture.is_file():
                data = texture.read_bytes()
                self.check(data.startswith(b"\x89PNG\r\n\x1a\n") and len(data) >= 24, f"{context}: invalid PNG")
        self.check(menu_ids == set(cafe_words), "Menu and café legacy word IDs differ")

        if self.validate_audio:
            self.validate_speech(vocab, menu)
        self.counts = {
            "lessons": len(lesson_entries), "vocabulary": len(vocab), "grammar": len(grammar),
            "sentences": len(sentences), "readings": len(readings), "exercises": len(exercises),
            "cafe_legacy": len(cafe_words),
        }
        if self.errors:
            for error in self.errors:
                print("ERROR:", error)
            raise SystemExit(f"Content validation failed with {len(self.errors)} error(s)")
        print("Content validation passed:", json.dumps(self.counts, ensure_ascii=False))

    def validate_kanji(self):
        all_kanji = set()
        for level, expected in ((5, 100), (4, 200)):
            entries = self.array(f"Resources/Kanji/n{level}_kanji.json")
            self.check(len(entries) == expected, f"N{level} kanji: expected {expected}, got {len(entries)}")
            for index, entry in enumerate(entries):
                character = entry.get("character", "")
                self.check(len(character) == 1 and character not in all_kanji, f"n{level}_kanji[{index}]: invalid/duplicate character")
                all_kanji.add(character)
                self.check(entry.get("jlpt_level") == level, f"n{level}_kanji[{index}]: wrong level")
                self.check(entry.get("meanings") and entry.get("on_readings", []) + entry.get("kun_readings", []), f"n{level}_kanji[{index}]: incomplete entry")

    def validate_speech(self, vocab, menu):
        manifest = self.array("Resources/Audio/japanese_audio_manifest.json")
        by_id = self.unique_ids(manifest, "audio")
        expected = {"vocab:" + word_id for word_id, word in vocab.items() if word.get("eligibility", {}).get("reading", False)}
        expected.update(item["order_clip"] for item in menu)
        self.check(set(by_id) == expected, f"Audio: expected {len(expected)} current clips, got {len(by_id)}")
        for identity, clip in by_id.items():
            source_text = clip.get("source_text", "")
            digest = hashlib.sha256(source_text.encode("utf-8")).hexdigest()
            self.check(clip.get("source_hash") == digest, f"audio:{identity}: source hash mismatch")
            self.check(clip.get("status") == "ready", f"audio:{identity}: not ready")
            self.check(0.15 <= float(clip.get("duration", 0)) <= 10.0, f"audio:{identity}: invalid duration")
            audio = self.resource_path(clip.get("file"))
            self.check(audio is not None and audio.is_file() and audio.stat().st_size > 0, f"audio:{identity}: missing/empty audio")
        for word_id, word in vocab.items():
            identity = "vocab:" + word_id
            if identity in by_id:
                reading = word.get("hiragana") or word.get("katakana")
                self.check(by_id[identity].get("source_text") == reading, f"audio:{identity}: reading mismatch")
        for item in menu:
            clip = by_id.get(item["order_clip"], {})
            self.check(clip.get("source_text") == item.get("order_text"), f"audio:{item['order_clip']}: order mismatch")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--skip-audio", action="store_true")
    arguments = parser.parse_args()
    ContentValidator(validate_audio=not arguments.skip_audio).validate()
