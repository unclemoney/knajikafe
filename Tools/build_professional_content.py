# -*- coding: utf-8 -*-
"""Build runtime curriculum data from the professional lesson materials."""
import argparse
import hashlib
import json
import re
import unicodedata
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MARKDOWN = ROOT / "markdown"
INDEX = ROOT / "index"
OUTPUT = ROOT / "Resources" / "Curriculum"
LEGACY_IDENTITY = ROOT / "Tools" / "content" / "legacy_vocab_identity.json"
LEGACY_MENU = ROOT / "Resources" / "Vocabulary" / "cafe_menu.json"
LEGACY_VOCAB_OUTPUT = ROOT / "Resources" / "Vocabulary" / "cafe_legacy_vocab.json"
LEVEL_ORDER = ["入门20讲", "初级上", "初级下", "中级上", "中级下", "高级"]
VOCAB_SECTIONS = {
    "vocabulary for conversation": "会话用单词",
    "vocabulary for grammar explanation": "语法解释用单词",
    "vocabulary for exercises": "习题用单词",
    "vocabulary for explanation": "解説用単語",
    "practice vocabulary": "練習用単語",
    "new vocabulary": "新出単語",
    "word examples": "词例",
}
GRAMMAR_SECTIONS = {"grammar notes": "语法", "expression expansion": "表达扩展"}
READING_SECTIONS = {"conversation", "main text"}
EXERCISE_SECTIONS = {"practice questions", "exercises"}
OTHER_SECTIONS = {
    "learning objectives", "listening practice", "practice questions", "exercises",
    "conversation", "main text", "background", "knowledge expansion",
}
JAPANESE_RE = re.compile(r"[ぁ-ゟ゠-ヿ一-鿿]")
KANA_ONLY_RE = re.compile(r"^[ぁ-ゟ゠-ヿー\s0-9０-９.%]+$")
NUMBER_RE = re.compile(r"^[（(]([0-9０-９]+)[）)]\s*(.*)$")
OPTION_RE = re.compile(r"(?<![A-Za-z])([a-z])[.．]\s*")
ANSWER_TOKEN_RE = re.compile(r"[（(]([0-9０-９]+)[）)]\s*([a-z])(?=\s|$)")
SENTENCE_RE = re.compile(r"^(.*?[。！？!?])\s*[／/]\s*(.+)$")


def dump_text(value):
    return json.dumps(value, ensure_ascii=False, indent=2) + "\n"


def content_hash(value):
    return hashlib.sha256(dump_text(value).encode("utf-8")).hexdigest()


def stable_id(prefix, *parts):
    identity = "\0".join(normalize_identity(part) for part in parts)
    return prefix + hashlib.sha256(identity.encode("utf-8")).hexdigest()[:16]


def normalize_identity(value):
    return re.sub(r"\s+", "", unicodedata.normalize("NFC", str(value or "")))


def lesson_number(path):
    match = re.search(r"第\s*(\d+)\s*课", path.name)
    return int(match.group(1)) if match else None


def source_lines(path):
    page = 0
    result = []
    for number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        stripped = raw.strip()
        page_match = re.match(r"<!-- Page (\d+) -->", stripped)
        if page_match:
            page = int(page_match.group(1))
            continue
        result.append({"text": stripped, "line": number, "page": page})
    return result


def section_name(text):
    normalized = re.sub(r"\s+", " ", text.strip()).lower()
    if normalized in VOCAB_SECTIONS or normalized in GRAMMAR_SECTIONS:
        return normalized
    if normalized in READING_SECTIONS or normalized in EXERCISE_SECTIONS:
        return normalized
    if normalized in OTHER_SECTIONS:
        return normalized
    return None


def segmented_lines(lines):
    section = "front matter"
    result = []
    for item in lines:
        text = item["text"]
        if not text or text == "---" or text.startswith("#") or text.startswith(">"):
            continue
        named = section_name(text)
        if named:
            section = named
            continue
        result.append({**item, "section": section})
    return result


def is_furigana_only(text):
    return bool(KANA_ONLY_RE.fullmatch(text)) and bool(re.search(r"[ぁ-ゟ゠-ヿ]", text))


def clean_body_line(text):
    if not text or text == "---" or is_furigana_only(text):
        return False
    return True


def extract_grammar(lines, lesson, stage, source):
    items = [item for item in lines if item["section"] in GRAMMAR_SECTIONS]
    headings = []
    for index, item in enumerate(items):
        match = re.match(r"^(\d+)[.．、]\s+(.+)$", item["text"])
        if match:
            headings.append((index, int(match.group(1)), match.group(2).strip(), item))
    grammar = []
    for position, (index, number, title, heading) in enumerate(headings):
        end = headings[position + 1][0] if position + 1 < len(headings) else len(items)
        body = [item for item in items[index + 1:end] if clean_body_line(item["text"])]
        kind = GRAMMAR_SECTIONS[heading["section"]]
        category_match = re.search(r"[<＜](.+?)[>＞]", title)
        category = category_match.group(1).strip() if category_match else ""
        grammar.append({
            "id": stable_id("g_", lesson, number, kind, normalize_identity(title)),
            "lesson": lesson,
            "stage": stage,
            "number": number,
            "kind": kind,
            "title": title,
            "category": category,
            "body_lines": [item["text"] for item in body],
            "sentence_ids": [],
            "source_file": source,
            "source_line": heading["line"],
            "source_end_line": body[-1]["line"] if body else heading["line"],
            "source_page": heading["page"],
        })
    return grammar


def extract_sentences(lines, lesson, stage, source):
    candidates = [item for item in lines if item["section"] in GRAMMAR_SECTIONS]
    sentences = []
    index = 0
    while index < len(candidates):
        item = candidates[index]
        match = SENTENCE_RE.match(item["text"])
        if not match or not JAPANESE_RE.search(match.group(1)):
            index += 1
            continue
        japanese = match.group(1).strip()
        english = match.group(2).strip()
        end_line = item["line"]
        while english.endswith("-") or not re.search(r"[.!?][\"’”)]?$", english):
            if index + 1 >= len(candidates):
                break
            continuation = candidates[index + 1]["text"]
            if not continuation or JAPANESE_RE.search(continuation) or section_name(continuation):
                break
            if re.match(r"^\d+[.．、]\s+", continuation):
                break
            index += 1
            end_line = candidates[index]["line"]
            if english.endswith("-") and continuation[:1].islower():
                english = english[:-1] + continuation
            else:
                english += " " + continuation
            english = english.strip()
        sentences.append({
            "id": stable_id("s_", lesson, item["line"], normalize_identity(japanese)),
            "lesson": lesson,
            "stage": stage,
            "japanese": japanese,
            "english": english,
            "section": item["section"],
            "vocab_ids": [],
            "source_file": source,
            "source_line": item["line"],
            "source_end_line": end_line,
            "source_page": item["page"],
        })
        index += 1
    return sentences


def extract_readings(lines, lesson, stage, source):
    readings = []
    for section in sorted(READING_SECTIONS):
        section_lines = [item for item in lines if item["section"] == section]
        japanese = []
        source_numbers = []
        first_page = 0
        for item in section_lines:
            text = item["text"]
            if not JAPANESE_RE.search(text) or is_furigana_only(text):
                continue
            if not japanese:
                first_page = item["page"]
            japanese.append(text)
            source_numbers.append(item["line"])
        if not japanese:
            continue
        readings.append({
            "id": stable_id("r_", lesson, section),
            "lesson": lesson,
            "stage": stage,
            "title": "Lesson %d · %s" % (lesson, section.title()),
            "section": section,
            "japanese_lines": japanese,
            "english_lines": [],
            "target_vocab_id": "",
            "related_vocab_ids": [],
            "question": "",
            "choices": [],
            "answer_index": -1,
            "explanation": "",
            "source_file": source,
            "source_line": source_numbers[0],
            "source_end_line": source_numbers[-1],
            "source_page": first_page,
        })
    return readings


def parse_answer_keys(path):
    keys = {}
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if JAPANESE_RE.search(line):
            continue
        matches = list(ANSWER_TOKEN_RE.finditer(line))
        if not matches:
            continue
        residue = ANSWER_TOKEN_RE.sub("", line).strip()
        if residue:
            continue
        for match in matches:
            number = int(unicodedata.normalize("NFKC", match.group(1)))
            keys[number] = match.group(2)
    return keys


def parse_options(text):
    matches = list(OPTION_RE.finditer(text))
    options = []
    for index, match in enumerate(matches):
        end = matches[index + 1].start() if index + 1 < len(matches) else len(text)
        value = text[match.end():end].strip()
        if value:
            options.append((match.group(1), value))
    return options


def mark_blank(prompt):
    normalized = re.sub(r"\s+", " ", prompt).strip()
    pattern = re.compile(r"(?<=[ぁ-ゟ゠-ヿ一-鿿：]) (?=[、。ぁ-ゟ゠-ヿ一-鿿])")
    marked, count = pattern.subn(" ______ ", normalized, count=1)
    return marked if count else ""


def extract_exercises(lines, answers, lesson, stage, source, exclusions):
    items = [item for item in lines if item["section"] in EXERCISE_SECTIONS]
    groups = []
    current = None
    group_name = ""
    for item in items:
        text = item["text"]
        if text in {"A", "B", "C"}:
            group_name = text
            current = None
            continue
        number_match = NUMBER_RE.match(text)
        if number_match:
            number = int(unicodedata.normalize("NFKC", number_match.group(1)))
            current = {
                "number": number, "group": group_name, "prompt_parts": [],
                "options": [], "line": item["line"], "page": item["page"],
            }
            groups.append(current)
            text = number_match.group(2)
        options = parse_options(text)
        if options:
            if current is not None:
                current["options"].extend(options)
            continue
        if current is not None and text and not is_furigana_only(text):
            current["prompt_parts"].append(text)
    exercises = []
    for group in groups:
        prompt = " ".join(group["prompt_parts"]).strip()
        options = sorted(group["options"], key=lambda option: option[0])
        answer = answers.get(group["number"])
        context = "Lesson %d %s(%d)" % (lesson, group["group"] or "exercise", group["number"])
        if group["group"] or len(options) != 4 or len({letter for letter, _ in options}) != 4:
            exclusions.append({"source": context, "reason": "unsupported_choice_bank"})
            continue
        if answer not in {"a", "b", "c", "d"}:
            exclusions.append({"source": context, "reason": "missing_unambiguous_answer_key"})
            continue
        blanked = mark_blank(prompt)
        if not blanked:
            exclusions.append({"source": context, "reason": "blank_position_not_explicit"})
            continue
        choices = [value for _, value in options]
        if len(set(choices)) != 4:
            exclusions.append({"source": context, "reason": "duplicate_choices"})
            continue
        exercises.append({
            "id": stable_id("x_", lesson, group["group"], group["number"], group["line"]),
            "lesson": lesson,
            "stage": stage,
            "group": group["group"],
            "number": group["number"],
            "prompt": blanked,
            "choices": choices,
            "answer_index": ord(answer) - ord("a"),
            "english": "",
            "target_vocab_id": "",
            "source_file": source,
            "source_line": group["line"],
            "source_page": group["page"],
        })
    return exercises


def contains_kanji(value):
    return bool(re.search(r"[一-鿿]", value))


def is_katakana(value):
    return bool(value) and all("ァ" <= char <= "ヿ" or char in "ー・ 　" for char in value)


def is_kana_only(value):
    return bool(value) and bool(re.fullmatch(r"[ぁ-ゟ゠-ヿー・\s]+", value))


def usable_reading(word, reading):
    value = (reading or "").strip()
    valid = bool(re.search(r"[ぁ-ゟ゠-ヿ]", value))
    valid = valid and not re.search(r"[一-鿿0-9０-９]", value)
    if valid:
        return value
    return word if is_kana_only(word) else ""


ROMAJI_BASE = {
    "あ": "a", "い": "i", "う": "u", "え": "e", "お": "o",
    "か": "ka", "き": "ki", "く": "ku", "け": "ke", "こ": "ko",
    "さ": "sa", "し": "shi", "す": "su", "せ": "se", "そ": "so",
    "た": "ta", "ち": "chi", "つ": "tsu", "て": "te", "と": "to",
    "な": "na", "に": "ni", "ぬ": "nu", "ね": "ne", "の": "no",
    "は": "ha", "ひ": "hi", "ふ": "fu", "へ": "he", "ほ": "ho",
    "ま": "ma", "み": "mi", "む": "mu", "め": "me", "も": "mo",
    "や": "ya", "ゆ": "yu", "よ": "yo", "ら": "ra", "り": "ri",
    "る": "ru", "れ": "re", "ろ": "ro", "わ": "wa", "を": "wo", "ん": "n",
    "が": "ga", "ぎ": "gi", "ぐ": "gu", "げ": "ge", "ご": "go",
    "ざ": "za", "じ": "ji", "ず": "zu", "ぜ": "ze", "ぞ": "zo",
    "だ": "da", "ぢ": "ji", "づ": "zu", "で": "de", "ど": "do",
    "ば": "ba", "び": "bi", "ぶ": "bu", "べ": "be", "ぼ": "bo",
    "ぱ": "pa", "ぴ": "pi", "ぷ": "pu", "ぺ": "pe", "ぽ": "po",
    "ぁ": "a", "ぃ": "i", "ぅ": "u", "ぇ": "e", "ぉ": "o",
    "ゃ": "ya", "ゅ": "yu", "ょ": "yo", "っ": "", "ゔ": "vu",
}
KATAKANA_TO_HIRAGANA = {chr(code): chr(code - 0x60) for code in range(0x30A1, 0x30F7)}


def to_romaji(reading):
    text = unicodedata.normalize("NFKC", reading or "")
    text = "".join(KATAKANA_TO_HIRAGANA.get(char, char) for char in text).lower()
    output = ""
    index = 0
    while index < len(text):
        char = text[index]
        if char == "っ":
            following = ""
            for next_char in text[index + 1:]:
                if next_char in ROMAJI_BASE and ROMAJI_BASE[next_char]:
                    following = ROMAJI_BASE[next_char]
                    break
            output += following[:1] if following and following[:1] not in {"a", "i", "u", "e", "o"} else ""
            index += 1
            continue
        if index + 1 < len(text) and text[index + 1] in {"ゃ", "ゅ", "ょ"}:
            combined = ROMAJI_BASE.get(char, "")
            if combined.endswith("i"):
                output += combined[:-1] + ROMAJI_BASE[text[index + 1]]
                index += 2
                continue
        if char == "ー":
            vowels = [value for value in output[-2:] if value in "aeiou"]
            output += vowels[-1] if vowels else ""
            index += 1
            continue
        converted = ROMAJI_BASE.get(char)
        if converted is None:
            if char in " 　-":
                output += char.replace("　", " ")
                index += 1
                continue
            return ""
        output += converted
        index += 1
    return output


def map_pos(raw):
    value = raw or ""
    if "形" in value:
        return "i-adjective" if "Ⅰ" in value or "I" in value else "na-adjective"
    if any(tag in value for tag in ["动", "自", "他"]):
        return "verb"
    if "副" in value:
        return "adverb"
    if any(tag in value for tag in ["感", "接"]):
        return "expression"
    if "名" in value or "代" in value or "专" in value:
        return "noun"
    return ""


def load_legacy_identities(menu_ids):
    if LEGACY_IDENTITY.exists():
        return json.loads(LEGACY_IDENTITY.read_text(encoding="utf-8"))
    identities = []
    for level in (5, 4):
        path = ROOT / "Resources" / "Vocabulary" / ("n%d_vocab.json" % level)
        for word in json.loads(path.read_text(encoding="utf-8")):
            display = word.get("kanji") or word.get("hiragana") or word.get("katakana")
            reading = word.get("hiragana") or word.get("katakana") or display
            identities.append({
                "id": word["id"], "word": display, "reading": reading,
                "cafe_legacy": word["id"] in menu_ids,
            })
    return sorted(identities, key=lambda item: item["id"])


def build():
    exclusions = []
    menu = json.loads(LEGACY_MENU.read_text(encoding="utf-8"))
    menu_ids = {item["vocab_id"] for item in menu}
    identities = load_legacy_identities(menu_ids)
    index_vocab = json.loads((INDEX / "vocab.json").read_text(encoding="utf-8"))
    lessons = []
    grammar = []
    sentences = []
    readings = []
    exercises = []
    lesson_files = sorted(MARKDOWN.glob("*/*精讲精练*.md"), key=lesson_number)
    answer_files = defaultdict(list)
    for path in MARKDOWN.glob("*/*.md"):
        if "精讲精练" in path.name:
            continue
        match = re.search(r"第\s*(\d+)\s*課", path.name)
        if match:
            answer_files[int(match.group(1))].append(path)
    for path in lesson_files:
        number = lesson_number(path)
        stage = path.parent.name
        source = path.relative_to(MARKDOWN).as_posix()
        raw_lines = source_lines(path)
        lines = segmented_lines(raw_lines)
        title_line = next((item["text"] for item in raw_lines if item["text"].startswith("# ")), "Lesson %d" % number)
        answers = {}
        for answer_path in sorted(answer_files.get(number, [])):
            answers.update(parse_answer_keys(answer_path))
        lessons.append({
            "id": "lesson_%02d" % number,
            "number": number,
            "stage": stage,
            "stage_order": LEVEL_ORDER.index(stage),
            "title": title_line.removeprefix("# "),
            "source_file": source,
            "source_hash": hashlib.sha256(path.read_bytes()).hexdigest(),
        })
        grammar.extend(extract_grammar(lines, number, stage, source))
        sentences.extend(extract_sentences(lines, number, stage, source))
        readings.extend(extract_readings(lines, number, stage, source))
        exercises.extend(extract_exercises(lines, answers, number, stage, source, exclusions))
    vocabulary = []
    pair_candidates = defaultdict(list)
    lesson_words = defaultdict(list)
    for entry in index_vocab:
        word = entry["word"].strip()
        source_reading = entry.get("reading", "").strip()
        reading = usable_reading(word, source_reading)
        word_id = stable_id("v_", normalize_identity(word), normalize_identity(source_reading))
        pair_candidates[(word, reading)].append(word_id)
        refs = [int(value) for value in re.findall(r"第(\d+)课", entry.get("lessons", ""))]
        if not refs:
            refs = [int(entry["lesson"])]
        refs = sorted(set(refs))
        lesson = min(refs)
        stage = entry["level"]
        katakana = reading if is_katakana(reading) else ""
        hiragana = reading if reading and not katakana else ""
        kanji = word if contains_kanji(word) else ""
        if not kanji and not reading:
            if is_katakana(word):
                katakana = word
            else:
                hiragana = word
        source_meaning = entry.get("meaning_en", "").strip()
        display_usable = bool(re.search(r"[ぁ-ゟ゠-ヿ]", word)) or bool(reading)
        meaning_usable = bool(source_meaning) and len(source_meaning) <= 260 and display_usable
        meanings = [source_meaning] if meaning_usable else []
        raw_pos_value = entry.get("pos", "")
        raw_pos = "、".join(str(value) for value in raw_pos_value) if isinstance(raw_pos_value, list) else str(raw_pos_value or "")
        sections = [value for value in entry.get("sections", "").split("、") if value]
        item = {
            "id": word_id,
            "kanji": kanji,
            "hiragana": hiragana,
            "katakana": katakana,
            "romaji": to_romaji(reading),
            "english_meanings": meanings,
            "jlpt_level": int(entry["jlpt"][1]) if entry.get("jlpt") else 0,
            "categories": [],
            "example_sentences": [],
            "part_of_speech": map_pos(raw_pos),
            "lesson_ids": refs,
            "first_lesson": lesson,
            "stage": stage,
            "source_sections": sections,
            "pitch": entry.get("pitch", ""),
            "origin": entry.get("origin", ""),
            "source_pos": raw_pos,
            "occurrences": int(entry.get("occurrences", 1)),
            "source_file": "%s/%s" % (stage, entry["source"]),
            "source_word": word,
            "source_reading": source_reading,
            "source_meaning": source_meaning,
            "content_source": "professional_lesson",
        }
        item["eligibility"] = {
            "meaning": meaning_usable,
            "reading": bool(reading),
            "japanese": display_usable,
            "examples": False,
        }
        vocabulary.append(item)
        for ref in refs:
            lesson_words[ref].append(item)
    pair_to_id = {pair: ids[0] for pair, ids in pair_candidates.items() if len(ids) == 1}
    words_by_id = {word["id"]: word for word in vocabulary}
    words_by_lesson = defaultdict(list)
    for word in vocabulary:
        for lesson in word["lesson_ids"]:
            words_by_lesson[lesson].append(word)
    for sentence in sentences:
        related = []
        for word in words_by_lesson[sentence["lesson"]]:
            if word["source_word"] and word["source_word"] in sentence["japanese"]:
                related.append(word["id"])
        sentence["vocab_ids"] = sorted(set(related))
        for word_id in related:
            word = words_by_id[word_id]
            pair = sentence["japanese"] + "|" + sentence["english"]
            if pair not in word["example_sentences"]:
                word["example_sentences"].append(pair)
            word["eligibility"]["examples"] = True
    for grammar_item in grammar:
        grammar_item["sentence_ids"] = [
            sentence["id"] for sentence in sentences
            if sentence["lesson"] == grammar_item["lesson"]
            and grammar_item["source_line"] <= sentence["source_line"] <= grammar_item["source_end_line"]
        ]
    for reading in readings:
        related = []
        for word in words_by_lesson[reading["lesson"]]:
            if any(word["source_word"] in line for line in reading["japanese_lines"]):
                related.append(word["id"])
        reading["related_vocab_ids"] = sorted(set(related))
        if related:
            reading["target_vocab_id"] = related[0]
    for exercise in exercises:
        candidates = []
        answer_text = exercise["choices"][exercise["answer_index"]]
        for word in words_by_lesson[exercise["lesson"]]:
            if word["source_word"] in exercise["prompt"] or word["source_word"] in answer_text:
                candidates.append(word)
        if candidates:
            candidates.sort(key=lambda word: (-len(word["source_word"]), word["id"]))
            exercise["target_vocab_id"] = candidates[0]["id"]
        else:
            exclusions.append({"source": exercise["id"], "reason": "no_professional_vocabulary_target"})
    exercises = [exercise for exercise in exercises if exercise["target_vocab_id"]]
    for lesson in lessons:
        number = lesson["number"]
        lesson["vocabulary_count"] = sum(number in word["lesson_ids"] for word in vocabulary)
        lesson["grammar_count"] = sum(item["lesson"] == number for item in grammar)
        lesson["sentence_count"] = sum(item["lesson"] == number for item in sentences)
        lesson["reading_count"] = sum(item["lesson"] == number for item in readings)
        lesson["exercise_count"] = sum(item["lesson"] == number for item in exercises)
    legacy_map = {}
    for identity in identities:
        if identity["cafe_legacy"]:
            legacy_map[identity["id"]] = {"target_id": identity["id"], "match_type": "cafe_legacy"}
            continue
        target = pair_to_id.get((identity["word"], identity["reading"]))
        if target:
            legacy_map[identity["id"]] = {"target_id": target, "match_type": "exact"}
        else:
            matches = [word for word in vocabulary if word["source_word"] == identity["word"]]
            legacy_map[identity["id"]] = {
                "target_id": "",
                "match_type": "ambiguous_match" if len(matches) > 1 else ("word_only" if matches else "no_professional_match"),
            }
    legacy_words = []
    old_by_id = {}
    if LEGACY_VOCAB_OUTPUT.exists():
        for word in json.loads(LEGACY_VOCAB_OUTPUT.read_text(encoding="utf-8")):
            old_by_id[word["id"]] = word
    else:
        for level in (5, 4):
            path = ROOT / "Resources" / "Vocabulary" / ("n%d_vocab.json" % level)
            for word in json.loads(path.read_text(encoding="utf-8")):
                old_by_id[word["id"]] = word
    for word_id in sorted(menu_ids):
        word = dict(old_by_id[word_id])
        word["content_source"] = "legacy_cafe"
        legacy_words.append(word)
    outputs = {
        OUTPUT / "lessons.json": lessons,
        OUTPUT / "vocabulary.json": vocabulary,
        OUTPUT / "grammar.json": grammar,
        OUTPUT / "sentences.json": sentences,
        OUTPUT / "readings.json": readings,
        OUTPUT / "exercises.json": exercises,
        OUTPUT / "legacy_id_map.json": legacy_map,
        LEGACY_VOCAB_OUTPUT: sorted(legacy_words, key=lambda word: word["id"]),
    }
    report = {
        "lesson_files": len(lesson_files),
        "vocabulary": len(vocabulary),
        "grammar": len(grammar),
        "sentences": len(sentences),
        "readings": len(readings),
        "exercises": len(exercises),
        "missing_english": sum(not word["english_meanings"] for word in vocabulary),
        "source_missing_english": sum(not word["source_meaning"] for word in vocabulary),
        "quarantined_meaning": sum(bool(word["source_meaning"]) and not word["english_meanings"] for word in vocabulary),
        "missing_reading": sum(not word["eligibility"]["reading"] for word in vocabulary),
        "display_only_headwords": sum(not word["eligibility"]["reading"] and bool(word["hiragana"] or word["katakana"]) for word in vocabulary),
        "source_missing_reading": sum(not word["source_reading"] for word in vocabulary),
        "legacy_exact": sum(item["match_type"] == "exact" for item in legacy_map.values()),
        "legacy_cafe": sum(item["match_type"] == "cafe_legacy" for item in legacy_map.values()),
        "legacy_unmatched": sum(not item["target_id"] for item in legacy_map.values()),
        "exclusions": exclusions,
        "runtime_hashes": {path.name: content_hash(value) for path, value in outputs.items()},
    }
    outputs[INDEX / "_professional_import_report.json"] = report
    return outputs, report


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    outputs, report = build()
    differences = []
    for path, value in outputs.items():
        expected = dump_text(value)
        if not path.exists() or path.read_text(encoding="utf-8") != expected:
            differences.append(str(path.relative_to(ROOT)))
    if args.check:
        if differences:
            raise SystemExit("Out-of-date professional content: " + ", ".join(differences))
    else:
        if not LEGACY_IDENTITY.exists():
            LEGACY_IDENTITY.parent.mkdir(parents=True, exist_ok=True)
            LEGACY_IDENTITY.write_text(dump_text(load_legacy_identities({item["vocab_id"] for item in json.loads(LEGACY_MENU.read_text(encoding="utf-8"))})), encoding="utf-8", newline="\n")
        for path, value in outputs.items():
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(dump_text(value), encoding="utf-8", newline="\n")
    summary = {key: value for key, value in report.items() if key not in {"exclusions", "runtime_hashes"}}
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    print("Exercise exclusions:", len(report["exclusions"]))
    if args.check:
        print("Professional content check passed.")
    elif differences:
        print("Written:", len(differences), "files")


if __name__ == "__main__":
    main()
