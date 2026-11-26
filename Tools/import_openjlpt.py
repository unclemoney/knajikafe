# -*- coding: utf-8 -*-
"""Import licensed OpenJLPT and supplemental sources into KanjiKafe content modules."""
import csv
import gzip
import json
import os
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Tools" / "content" / "source"
OUT = ROOT / "Tools" / "content"
TARGET_WORDS = {"n5": 800, "n4": 700}
TARGET_KANJI = 200


def load_json(path):
    with open(path, encoding="utf-8") as file:
        return json.load(file)


def write_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as file:
        json.dump(data, file, ensure_ascii=False, indent=2)
        file.write("\n")


def pos_type(source_pos, expression, meaning):
    tags = set(source_pos)
    if tags & {"v1", "v2", "v3", "v4", "v5", "v5u", "v5k", "v5s", "v5r", "v5m", "v5n", "v5t", "v5z", "vi", "vt", "vk"}:
        return "verb"
    if "adj-i" in tags:
        return "i-adjective"
    if "adj-na" in tags or "adj-no" in tags:
        return "na-adjective"
    if "adv" in tags:
        return "adverb"
    if "exp" in tags or "int" in tags:
        return "expression"
    if tags & {"n", "n-adv", "n-suf", "n-pref"}:
        return "noun"
    if expression.endswith("る"):
        return "verb"
    if expression.endswith("い"):
        return "i-adjective"
    if meaning.startswith("to "):
        return "verb"
    return "noun"


def categories_for(word, pos, meaning):
    text = (word + " " + meaning).lower()
    categories = []
    keyword_groups = {
        "food": ["food", "rice", "bread", "meat", "fish", "egg", "fruit", "vegetable", "tea", "coffee", "milk", "water", "meal", "eat", "drink"],
        "people": ["person", "people", "man", "woman", "father", "mother", "brother", "sister", "family", "friend", "teacher", "student"],
        "school": ["school", "teacher", "student", "study", "class", "lesson", "education", "exam", "book", "read", "write"],
        "transport": ["train", "bus", "car", "station", "bicycle", "travel", "airport", "ticket"],
        "time": ["day", "week", "month", "year", "morning", "night", "today", "tomorrow", "yesterday", "hour", "minute", "time"],
        "nature": ["mountain", "river", "sea", "sky", "rain", "snow", "wind", "flower", "tree", "nature"],
        "weather": ["weather", "rain", "snow", "wind", "hot", "cold", "temperature"],
        "body": ["body", "head", "hand", "foot", "eye", "ear", "mouth", "health", "doctor", "hospital", "pain"],
        "places": ["station", "school", "hospital", "bank", "library", "park", "shop", "store", "office", "house", "home", "country", "city", "town"],
        "objects": ["book", "letter", "ticket", "money", "thing", "object", "bag", "computer", "phone", "pen", "paper", "key"],
        "work": ["work", "job", "company", "office", "business", "meeting", "employee"],
    }
    for category, keywords in keyword_groups.items():
        if any(keyword in text for keyword in keywords):
            categories.append(category)
    if pos == "verb":
        categories.append("verbs")
    elif pos in ["i-adjective", "na-adjective"]:
        categories.append("adjectives")
    elif pos == "adverb":
        categories.append("adverbs")
    if not categories:
        categories.append("common")
    return categories


def example_for(entry):
    for example in entry.get("examples", []):
        if entry["word"] in example["ja"]:
            return example["ja"] + "|" + example["en"]
    return ""


def fallback_example(word, pos, meaning):
    primary = meaning.split(";")[0]
    if pos == "verb":
        english = primary[3:] if primary.startswith("to ") else primary
        return f"私は{word}。|I {english}."
    if pos in ["i-adjective", "na-adjective"]:
        return f"それは{word}です。|It is {primary}."
    if pos == "expression":
        return f"{word}と言います。|I say \"{word}\"."
    return f"これは{word}です。|This is {primary}."


def build_words(level):
    current = load_json(ROOT / "Resources" / "Vocabulary" / f"{level}_vocab.json")
    original_count = 120 if level == "n5" else 100
    current = current[:original_count]
    existing_displays = {entry["kanji"] for entry in current}
    records = []
    sources = load_json(SOURCE / f"{level}_vocab.json")
    source_by_display = {source["word"]: source for source in sources}
    for entry in current:
        if not entry.get("example_sentences"):
            source = source_by_display.get(entry["kanji"])
            if source:
                example = example_for(source)
                if example:
                    entry["example_sentences"] = [example]
            if not entry.get("example_sentences"):
                entry["example_sentences"] = [fallback_example(entry["kanji"], entry.get("part_of_speech", "noun"), entry["english_meanings"][0])]
        records.append(entry)
    seen = set(existing_displays)
    next_id = len(records) + 1
    for source in sources:
        display = source["word"]
        if display in seen:
            continue
        meanings = source["meanings"]
        pos = pos_type(source.get("pos", []), display, meanings[0])
        record = make_word(level, next_id, display, source["reading"], source["romaji"], meanings, source.get("pos", []), pos)
        record["example_sentences"] = [example_for(source)] if example_for(source) else [fallback_example(display, pos, meanings[0])]
        records.append(record)
        seen.add(display)
        next_id += 1
    with open(SOURCE / f"supplement_{level}.csv", encoding="utf-8") as file:
        supplemental = list(csv.DictReader(file))
    for source in supplemental:
        display = source["expression"]
        if display in seen:
            continue
        meanings = [source["meaning"]]
        pos = pos_type([], display, meanings[0])
        record = make_word(level, next_id, display, source["reading"], "", meanings, [], pos)
        record["example_sentences"] = [fallback_example(display, pos, meanings[0])]
        records.append(record)
        seen.add(display)
        next_id += 1
        if len(records) >= TARGET_WORDS[level]:
            break
    if level == "n5":
        from content.manual_n5_supplement import N5_SUPPLEMENT
        for display, reading, meanings, pos, example in N5_SUPPLEMENT:
            if display in seen or len(records) >= TARGET_WORDS[level]:
                continue
            record = make_word(level, next_id, display, reading, reading, meanings, [], pos)
            record["example_sentences"] = [example]
            records.append(record)
            seen.add(display)
            next_id += 1
    if len(records) < TARGET_WORDS[level]:
        supplemental_all = load_json(SOURCE / "supplement_vocab.json")
        needed = {word for word, info_list in supplemental_all.items() if any(info.get("level") == int(level[1]) for info in info_list) and word not in seen}
        dictionary = read_jmdict(needed)
        for display in sorted(needed):
            if len(records) >= TARGET_WORDS[level]:
                break
            source = dictionary.get(display)
            if source is None:
                continue
            meanings = source["meanings"]
            pos = pos_type(source.get("pos", []), display, meanings[0])
            record = make_word(level, next_id, display, source["reading"], source["romaji"], meanings, source.get("pos", []), pos)
            record["example_sentences"] = [fallback_example(display, pos, meanings[0])]
            records.append(record)
            seen.add(display)
            next_id += 1
    if len(records) != TARGET_WORDS[level]:
        raise ValueError(f"{level} vocabulary target mismatch: {len(records)}")
    if level == "n4":
        from content.menu import N4_MENU_WORDS
        for index, (display, reading, meanings, example) in enumerate(N4_MENU_WORDS):
            record = make_word(level, next_id - 10 + index, display, reading, reading, meanings, [], "noun")
            record["categories"] = ["food", "cafe"]
            record["example_sentences"] = [example]
            records[-10 + index] = record
    return records


def make_word(level, number, display, reading, romaji, meanings, source_pos, pos):
    if not romaji:
        romaji = reading
    return {
        "id": f"{level}_{number:03d}",
        "kanji": display,
        "hiragana": reading,
        "katakana": reading if reading and all(ord(c) >= 0x30A0 for c in reading) else "",
        "romaji": romaji,
        "english_meanings": meanings,
        "jlpt_level": int(level[1]),
        "categories": categories_for(display, pos, meanings[0]),
        "example_sentences": [],
        "part_of_speech": pos,
        "review_status": "draft_pending_human_review",
        "source_pos": source_pos,
    }


def read_jmdict(needed):
    path = Path(os.environ.get("JMDICT_PATH", "C:/Users/danie/AppData/Local/Temp/JMdict_e.gz"))
    if not path.exists():
        raise FileNotFoundError("Set JMDICT_PATH to a downloaded JMdict_e.gz")
    result = {}
    with gzip.open(path, "rb") as file:
        for event, element in ET.iterparse(file, events=("end",)):
            if event == "end" and element.tag == "entry":
                keys = [keb.text for keb in element.findall("keb")] + [reb.text for reb in element.findall("reb")]
                matches = needed.intersection(keys)
                if matches:
                    display = sorted(matches)[0]
                    if display not in result:
                        result[display] = {
                            "word": display,
                            "reading": element.findtext("reb") or display,
                            "romaji": element.findtext("reb") or display,
                            "meanings": [gloss.text for gloss in element.findall("gloss") if gloss.text],
                            "pos": [pos.text for pos in element.findall("pos")],
                        }
                element.clear()
    return result


def read_kanjidic():
    path = Path(os.environ.get("KANJIDIC2_PATH", "C:/Users/danie/AppData/Local/Temp/kanjidic2.xml.gz"))
    if not path.exists():
        raise FileNotFoundError("Set KANJIDIC2_PATH to a downloaded kanjidic2.xml.gz")
    result = {}
    with gzip.open(path, "rb") as file:
        for event, element in ET.iterparse(file, events=("end",)):
            if event == "end" and element.tag == "character":
                literal = element.findtext("literal")
                result[literal] = {
                    "meanings": [m.text for m in element.findall(".//meaning") if m.text and not m.text.startswith("(")],
                    "on": [r.text for r in element.findall(".//reading[@r_type='ja_on']")],
                    "kun": [r.text for r in element.findall(".//reading[@r_type='ja_kun']")],
                    "strokes": int(element.findtext(".//stroke_count") or 1),
                    "radical": element.findtext(".//radical") or "",
                }
                element.clear()
    return result


def build_kanji():
    open_kanji = load_json(SOURCE / "n4_kanji.json")
    n5_kanji = load_json(ROOT / "Resources" / "Kanji" / "n5_kanji.json")
    records = []
    seen = {entry["character"] for entry in n5_kanji}
    for source in open_kanji:
        if source["character"] in seen:
            continue
        seen.add(source["character"])
        records.append({
            "character": source["character"],
            "meanings": source["meanings"],
            "on_readings": source["onyomi"],
            "kun_readings": source["kunyomi"],
            "stroke_count": source["strokes"],
            "jlpt_level": 4,
            "radical": source["radical"],
            "components": [],
            "review_status": "draft_pending_human_review",
            "source_level": 4,
        })
    supplement = load_json(SOURCE / "supplement_kanji.json")
    bridge = [entry for entry in supplement if entry["jlpt"] == "N3" and entry["kanji"] not in seen]
    bridge.sort(key=lambda entry: entry.get("frequency", 99999))
    dic = read_kanjidic()
    for source in bridge[:TARGET_KANJI - len(records)]:
        char = source["kanji"]
        data = dic.get(char, {})
        records.append({
            "character": char,
            "meanings": data.get("meanings", ["unknown"]),
            "on_readings": data.get("on", []),
            "kun_readings": data.get("kun", []),
            "stroke_count": data.get("strokes", source.get("strokes") or 1),
            "jlpt_level": 4,
            "radical": data.get("radical", ""),
            "components": [],
            "review_status": "draft_pending_human_review",
            "source_level": 3,
        })
    if len(records) != TARGET_KANJI:
        raise ValueError(f"N4 kanji target mismatch: {len(records)}")
    return records


def write_module(path, variable, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(f"# -*- coding: utf-8 -*-\n{variable} = {repr(data)}\n", encoding="utf-8", newline="\n")


def main():
    write_module(OUT / "n5_words.py", "WORDS", build_words("n5"))
    write_module(OUT / "n4_words.py", "WORDS", build_words("n4"))
    write_module(OUT / "n4_kanji.py", "KANJI", build_kanji())
    print("Imported N5/N4 vocabulary and N4 kanji with draft review status")


if __name__ == "__main__":
    main()
