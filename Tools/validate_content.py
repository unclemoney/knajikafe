# -*- coding: utf-8 -*-
"""Validate KanjiKafe curriculum, reading, menu, art, and audio references."""
import argparse
import hashlib
import json
import struct
from pathlib import Path

from apply_content_review import DRAFT, STATUSES, ReviewError, read_rows

ROOT = Path(__file__).resolve().parents[1]


class ContentValidator:
    def __init__(self, require_reviewed=False):
        self.errors = []
        self.require_reviewed = require_reviewed

    def check(self, condition, message):
        if not condition:
            self.errors.append(message)

    def load_json(self, relative):
        path = ROOT / relative
        data = path.read_bytes()
        self.check(not data.startswith(b"\xef\xbb\xbf"), f"{relative}: UTF-8 BOM is not allowed")
        try:
            text = data.decode("utf-8")
            value = json.loads(text)
        except (UnicodeDecodeError, json.JSONDecodeError) as error:
            self.errors.append(f"{relative}: invalid UTF-8 JSON: {error}")
            return []
        self.check(isinstance(value, list), f"{relative}: root must be an array")
        return value if isinstance(value, list) else []

    def resource_path(self, resource):
        if not isinstance(resource, str) or not resource.startswith("res://"):
            return None
        return ROOT / resource.removeprefix("res://")

    def validate(self):
        vocab = {}
        for level, expected in ((5, 800), (4, 700)):
            label = f"n{level}"
            entries = self.load_json(f"Resources/Vocabulary/{label}_vocab.json")
            self.check(len(entries) == expected, f"{label}: expected {expected} words, got {len(entries)}")
            ids = set()
            displays = set()
            original_count = 120 if level == 5 else 100
            for index, word in enumerate(entries):
                context = f"{label}[{index}]"
                if not isinstance(word, dict):
                    self.errors.append(f"{context}: must be an object")
                    continue
                expected_id = f"{label}_{index + 1:03d}"
                word_id = word.get("id")
                self.check(word_id == expected_id, f"{context}: expected ID {expected_id}, got {word_id}")
                self.check(word_id not in ids, f"{context}: duplicate ID {word_id}")
                ids.add(word_id)
                self.check(word.get("jlpt_level") == level, f"{context}: wrong JLPT level")
                for field in ("kanji", "hiragana", "katakana", "romaji", "part_of_speech"):
                    self.check(isinstance(word.get(field), str), f"{context}: {field} must be a string")
                display = word.get("kanji") or word.get("hiragana") or word.get("katakana")
                self.check(bool(display), f"{context}: missing Japanese display text")
                self.check(display not in displays, f"{context}: duplicate display text {display}")
                displays.add(display)
                for field in ("english_meanings", "categories", "example_sentences"):
                    self.check(isinstance(word.get(field), list) and word[field], f"{context}: {field} must be non-empty")
                    self.check(all(isinstance(item, str) and item.strip() for item in word.get(field, [])), f"{context}: invalid {field} values")
                for example in word.get("example_sentences", []):
                    parts = example.split("|")
                    self.check(len(parts) == 2 and all(part.strip() for part in parts), f"{context}: malformed example {example}")
                    if len(parts) == 2:
                        self.check(display in parts[0], f"{context}: example does not contain {display}")
                if index >= original_count:
                    self.check(word.get("review_status") in STATUSES, f"{context}: invalid imported-word review status")
            vocab.update({word["id"]: word for word in entries if isinstance(word, dict) and "id" in word})

        all_kanji = set()
        kanji_by_character = {}
        for level, expected in ((5, 100), (4, 200)):
            entries = self.load_json(f"Resources/Kanji/n{level}_kanji.json")
            self.check(len(entries) == expected, f"N{level}: expected {expected} kanji, got {len(entries)}")
            level_seen = set()
            for index, entry in enumerate(entries):
                context = f"n{level}_kanji[{index}]"
                if not isinstance(entry, dict):
                    self.errors.append(f"{context}: must be an object")
                    continue
                character = entry.get("character")
                self.check(isinstance(character, str) and len(character) == 1, f"{context}: invalid character")
                self.check(character not in level_seen, f"{context}: duplicate within level")
                self.check(character not in all_kanji, f"{context}: duplicate across N5/N4: {character}")
                level_seen.add(character)
                all_kanji.add(character)
                kanji_by_character[character] = entry
                self.check(entry.get("jlpt_level") == level, f"{context}: wrong JLPT level")
                self.check(isinstance(entry.get("stroke_count"), int) and entry["stroke_count"] > 0, f"{context}: invalid stroke count")
                for field in ("meanings", "components"):
                    self.check(isinstance(entry.get(field), list), f"{context}: {field} must be an array")
                self.check(bool(entry.get("meanings")), f"{context}: meanings are required")
                readings = entry.get("on_readings", []) + entry.get("kun_readings", [])
                self.check(bool(readings) and all(isinstance(item, str) and item.strip() for item in readings), f"{context}: readings are required")
                if level == 4:
                    self.check(entry.get("review_status") in STATUSES, f"{context}: invalid N4 kanji review status")
                    self.check(entry.get("source_level") in (3, 4), f"{context}: invalid source level")

        passage_ids = set()
        passages_by_id = {}
        for level in (5, 4):
            passages = self.load_json(f"Resources/Reading/n{level}_reading.json")
            self.check(len(passages) == 30, f"N{level}: expected 30 passages, got {len(passages)}")
            for index, passage in enumerate(passages):
                context = f"n{level}_reading[{index}]"
                if not isinstance(passage, dict):
                    self.errors.append(f"{context}: must be an object")
                    continue
                passage_id = passage.get("id")
                self.check(isinstance(passage_id, str) and passage_id and passage_id not in passage_ids, f"{context}: duplicate/missing ID")
                passage_ids.add(passage_id)
                passages_by_id[passage_id] = passage
                self.check(passage.get("jlpt_level") == level, f"{context}: wrong JLPT level")
                target = passage.get("target_vocab_id")
                self.check(target in vocab and vocab[target].get("jlpt_level") == level, f"{context}: invalid target {target}")
                self.check(all(word_id in vocab for word_id in passage.get("related_vocab_ids", [])), f"{context}: invalid related vocabulary")
                japanese = passage.get("japanese_lines", [])
                english = passage.get("english_lines", [])
                self.check(bool(japanese) and len(japanese) == len(english), f"{context}: Japanese/English line mismatch")
                self.check(all(isinstance(line, str) and line.strip() for line in japanese + english), f"{context}: empty passage line")
                choices = passage.get("choices", [])
                self.check(len(choices) == 4 and len(set(choices)) == 4, f"{context}: four unique choices required")
                self.check(isinstance(passage.get("answer_index"), int) and 0 <= passage["answer_index"] < 4, f"{context}: invalid answer index")
                self.check(isinstance(passage.get("question"), str) and passage["question"].strip(), f"{context}: question required")
                self.check(isinstance(passage.get("explanation"), str) and passage["explanation"].strip(), f"{context}: explanation required")

        menu = self.load_json("Resources/Vocabulary/cafe_menu.json")
        self.check(len(menu) == 20, f"Menu: expected 20 entries, got {len(menu)}")
        menu_ids = set()
        for index, item in enumerate(menu):
            context = f"menu[{index}]"
            word_id = item.get("vocab_id")
            self.check(word_id in vocab and word_id not in menu_ids, f"{context}: invalid/duplicate vocabulary ID")
            menu_ids.add(word_id)
            if word_id in vocab:
                word = vocab[word_id]
                reading = word.get("hiragana") or word.get("katakana") or word.get("kanji")
                self.check(any("\u3040" <= character <= "\u30ff" for character in reading), f"{context}: speech reading must be Japanese kana, not romaji")
            self.check(isinstance(item.get("label"), str) and item["label"].strip(), f"{context}: label required")
            self.check(isinstance(item.get("order_text"), str) and item["order_text"].strip(), f"{context}: order text required")
            self.check(item.get("order_clip") == f"order:{word_id}", f"{context}: invalid order clip ID")
            texture = self.resource_path(item.get("texture"))
            self.check(texture is not None and texture.is_file(), f"{context}: missing texture")
            if texture is not None and texture.is_file():
                data = texture.read_bytes()
                valid_png = data.startswith(b"\x89PNG\r\n\x1a\n") and len(data) >= 24
                self.check(valid_png, f"{context}: invalid PNG")
                if valid_png:
                    width, height = struct.unpack(">II", data[16:24])
                    self.check(width > 0 and height > 0, f"{context}: empty texture")

        manifest = self.load_json("Resources/Audio/japanese_audio_manifest.json")
        self.check(len(manifest) == 1520, f"Audio: expected 1520 entries, got {len(manifest)}")
        by_id = {}
        for index, clip in enumerate(manifest):
            context = f"audio[{index}]"
            clip_id = clip.get("id")
            self.check(clip_id not in by_id, f"{context}: duplicate ID {clip_id}")
            by_id[clip_id] = clip
            self.check(clip.get("status") == "ready", f"{context}: not ready")
            source_text = clip.get("source_text", "")
            source_hash = hashlib.sha256(source_text.encode("utf-8")).hexdigest()
            self.check(clip.get("source_hash") == source_hash, f"{context}: source hash mismatch")
            self.check(0.15 <= float(clip.get("duration", 0)) <= 10.0, f"{context}: invalid duration")
            audio = self.resource_path(clip.get("file"))
            self.check(audio is not None and audio.is_file() and audio.stat().st_size > 0, f"{context}: missing/empty audio")
        expected_audio = {f"vocab:{word_id}" for word_id in vocab}
        expected_audio.update(f"order:{word_id}" for word_id in menu_ids)
        self.check(set(by_id) == expected_audio, "Audio: manifest IDs do not match 1500 words plus 20 orders")
        for word_id, word in vocab.items():
            clip = by_id.get(f"vocab:{word_id}", {})
            reading = word.get("hiragana") or word.get("katakana") or word.get("kanji")
            self.check(clip.get("source_text") == reading, f"Audio: source text mismatch for {word_id}")
        for item in menu:
            clip = by_id.get(item.get("order_clip"), {})
            self.check(clip.get("source_text") == item.get("order_text"), f"Audio: order source mismatch for {item.get('vocab_id')}")

        self._validate_review_rows("vocabulary_review.csv", "id", vocab)
        self._validate_review_rows("kanji_review.csv", "character", kanji_by_character)
        self._validate_review_rows("reading_review.csv", "id", passages_by_id)
        self._validate_review_rows("audio_review.csv", "id", by_id)

        if self.errors:
            for error in self.errors:
                print("ERROR:", error)
            raise SystemExit(f"Content validation failed with {len(self.errors)} error(s)")
        print("Content validation passed: 800 N5 words, 700 N4 words, 100 N5 + 200 N4 unique kanji, 60 passages, 20 menu textures, 1520 audio clips.")


    def _validate_review_rows(self, filename, key, entries):
        try:
            rows = read_rows(filename, key, list(entries))
        except ReviewError as error:
            self.errors.append(str(error))
            return
        pending = 0
        for identity, row in rows.items():
            entry = entries[identity]
            self.check(entry.get("review_status", DRAFT) == row["review_status"], f"{filename}:{identity}: review status differs from applied content")
            if row["review_status"] != "human_reviewed":
                pending += 1
        if self.require_reviewed and pending:
            self.errors.append(f"{filename}: {pending} entries still require qualified review or correction")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--require-reviewed", action="store_true")
    arguments = parser.parse_args()
    ContentValidator(require_reviewed=arguments.require_reviewed).validate()
