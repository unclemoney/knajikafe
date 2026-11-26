# -*- coding: utf-8 -*-
"""Generate n5_vocab.json and n4_vocab.json with proper UTF-8 encoding.

JSON format avoids Godot's .tres reimport/resave behavior which strips
PackedStringArray values back to empty defaults."""
import os
import json
import sys

sys.path.insert(0, os.path.dirname(__file__))
from content.n5_words import WORDS as N5_WORDS
from content.n4_words import WORDS as N4_WORDS

VOCAB_DIR = os.path.join(os.path.dirname(__file__), "..", "Resources", "Vocabulary")

# ═══════════════════════════════════════════════════════════════════════
# N5 Vocabulary (120 words)
# ═══════════════════════════════════════════════════════════════════════
N5_WORDS = [
    # --- Greetings & Expressions (001-010) ---
    ("n5_001", "こんにちは", "こんにちは", "", "konnichiwa", ["hello", "good afternoon"], ["greetings"], "expression"),
    ("n5_002", "ありがとう", "ありがとう", "", "arigatou", ["thank you"], ["greetings"], "expression"),
    ("n5_003", "すみません", "すみません", "", "sumimasen", ["excuse me", "sorry"], ["greetings"], "expression"),
    ("n5_004", "おはよう", "おはよう", "", "ohayou", ["good morning"], ["greetings"], "expression"),
    ("n5_005", "さようなら", "さようなら", "", "sayounara", ["goodbye"], ["greetings"], "expression"),
    ("n5_006", "おやすみなさい", "おやすみなさい", "", "oyasuminasai", ["good night"], ["greetings"], "expression"),
    ("n5_007", "いただきます", "いただきます", "", "itadakimasu", ["bon appetit", "let's eat"], ["greetings", "food"], "expression"),
    ("n5_008", "ごちそうさま", "ごちそうさま", "", "gochisousama", ["thank you for the meal"], ["greetings", "food"], "expression"),
    ("n5_009", "はい", "はい", "", "hai", ["yes"], ["greetings"], "expression"),
    ("n5_010", "いいえ", "いいえ", "", "iie", ["no"], ["greetings"], "expression"),
    # --- Food & Drink (011-020) ---
    ("n5_011", "水", "みず", "", "mizu", ["water"], ["food", "cafe"], "noun"),
    ("n5_012", "お茶", "おちゃ", "", "ocha", ["tea", "green tea"], ["food", "cafe"], "noun"),
    ("n5_013", "ご飯", "ごはん", "", "gohan", ["rice", "meal"], ["food"], "noun"),
    ("n5_014", "パン", "", "パン", "pan", ["bread"], ["food", "cafe"], "noun"),
    ("n5_015", "卵", "たまご", "", "tamago", ["egg"], ["food"], "noun"),
    ("n5_016", "魚", "さかな", "", "sakana", ["fish"], ["food"], "noun"),
    ("n5_017", "肉", "にく", "", "niku", ["meat"], ["food"], "noun"),
    ("n5_018", "野菜", "やさい", "", "yasai", ["vegetables"], ["food"], "noun"),
    ("n5_019", "果物", "くだもの", "", "kudamono", ["fruit"], ["food"], "noun"),
    ("n5_020", "牛乳", "ぎゅうにゅう", "", "gyuunyuu", ["milk"], ["food", "cafe"], "noun"),
    # --- Numbers & Time (021-030) ---
    ("n5_021", "一", "いち", "", "ichi", ["one"], ["numbers"], "number"),
    ("n5_022", "二", "に", "", "ni", ["two"], ["numbers"], "number"),
    ("n5_023", "三", "さん", "", "san", ["three"], ["numbers"], "number"),
    ("n5_024", "四", "よん", "", "yon", ["four"], ["numbers"], "number"),
    ("n5_025", "五", "ご", "", "go", ["five"], ["numbers"], "number"),
    ("n5_026", "六", "ろく", "", "roku", ["six"], ["numbers"], "number"),
    ("n5_027", "七", "なな", "", "nana", ["seven"], ["numbers"], "number"),
    ("n5_028", "八", "はち", "", "hachi", ["eight"], ["numbers"], "number"),
    ("n5_029", "九", "きゅう", "", "kyuu", ["nine"], ["numbers"], "number"),
    ("n5_030", "十", "じゅう", "", "juu", ["ten"], ["numbers"], "number"),
    # --- Basic nouns (031-050) ---
    ("n5_031", "人", "ひと", "", "hito", ["person", "people"], ["people"], "noun"),
    ("n5_032", "男", "おとこ", "", "otoko", ["man", "male"], ["people"], "noun"),
    ("n5_033", "女", "おんな", "", "onna", ["woman", "female"], ["people"], "noun"),
    ("n5_034", "子供", "こども", "", "kodomo", ["child", "children"], ["people"], "noun"),
    ("n5_035", "友達", "ともだち", "", "tomodachi", ["friend"], ["people"], "noun"),
    ("n5_036", "先生", "せんせい", "", "sensei", ["teacher", "doctor"], ["people", "school"], "noun"),
    ("n5_037", "学生", "がくせい", "", "gakusei", ["student"], ["people", "school"], "noun"),
    ("n5_038", "本", "ほん", "", "hon", ["book"], ["objects"], "noun"),
    ("n5_039", "車", "くるま", "", "kuruma", ["car"], ["transport"], "noun"),
    ("n5_040", "猫", "ねこ", "", "neko", ["cat"], ["animals", "cafe"], "noun"),
    ("n5_041", "犬", "いぬ", "", "inu", ["dog"], ["animals"], "noun"),
    ("n5_042", "花", "はな", "", "hana", ["flower"], ["nature"], "noun"),
    ("n5_043", "山", "やま", "", "yama", ["mountain"], ["nature"], "noun"),
    ("n5_044", "川", "かわ", "", "kawa", ["river"], ["nature"], "noun"),
    ("n5_045", "目", "め", "", "me", ["eye"], ["body"], "noun"),
    ("n5_046", "手", "て", "", "te", ["hand"], ["body"], "noun"),
    ("n5_047", "足", "あし", "", "ashi", ["foot", "leg"], ["body"], "noun"),
    ("n5_048", "口", "くち", "", "kuchi", ["mouth"], ["body"], "noun"),
    ("n5_049", "耳", "みみ", "", "mimi", ["ear"], ["body"], "noun"),
    ("n5_050", "頭", "あたま", "", "atama", ["head"], ["body"], "noun"),
    # --- People & Family (051-060) ---
    ("n5_051", "お父さん", "おとうさん", "", "otousan", ["father", "dad"], ["people", "family"], "noun"),
    ("n5_052", "お母さん", "おかあさん", "", "okaasan", ["mother", "mom"], ["people", "family"], "noun"),
    ("n5_053", "お兄さん", "おにいさん", "", "oniisan", ["older brother"], ["people", "family"], "noun"),
    ("n5_054", "お姉さん", "おねえさん", "", "oneesan", ["older sister"], ["people", "family"], "noun"),
    ("n5_055", "弟", "おとうと", "", "otouto", ["younger brother"], ["people", "family"], "noun"),
    ("n5_056", "妹", "いもうと", "", "imouto", ["younger sister"], ["people", "family"], "noun"),
    ("n5_057", "家族", "かぞく", "", "kazoku", ["family"], ["people", "family"], "noun"),
    ("n5_058", "奥さん", "おくさん", "", "okusan", ["wife"], ["people", "family"], "noun"),
    ("n5_059", "主人", "しゅじん", "", "shujin", ["husband"], ["people", "family"], "noun"),
    ("n5_060", "赤ちゃん", "あかちゃん", "", "akachan", ["baby"], ["people", "family"], "noun"),
    # --- Common Verbs (061-076) ---
    ("n5_061", "食べる", "たべる", "", "taberu", ["to eat"], ["verbs", "food"], "verb"),
    ("n5_062", "飲む", "のむ", "", "nomu", ["to drink"], ["verbs", "food"], "verb"),
    ("n5_063", "行く", "いく", "", "iku", ["to go"], ["verbs"], "verb"),
    ("n5_064", "来る", "くる", "", "kuru", ["to come"], ["verbs"], "verb"),
    ("n5_065", "見る", "みる", "", "miru", ["to see", "to look", "to watch"], ["verbs"], "verb"),
    ("n5_066", "聞く", "きく", "", "kiku", ["to hear", "to listen", "to ask"], ["verbs"], "verb"),
    ("n5_067", "書く", "かく", "", "kaku", ["to write"], ["verbs", "school"], "verb"),
    ("n5_068", "読む", "よむ", "", "yomu", ["to read"], ["verbs", "school"], "verb"),
    ("n5_069", "話す", "はなす", "", "hanasu", ["to speak", "to talk"], ["verbs"], "verb"),
    ("n5_070", "買う", "かう", "", "kau", ["to buy"], ["verbs"], "verb"),
    ("n5_071", "待つ", "まつ", "", "matsu", ["to wait"], ["verbs"], "verb"),
    ("n5_072", "立つ", "たつ", "", "tatsu", ["to stand"], ["verbs"], "verb"),
    ("n5_073", "座る", "すわる", "", "suwaru", ["to sit"], ["verbs"], "verb"),
    ("n5_074", "走る", "はしる", "", "hashiru", ["to run"], ["verbs"], "verb"),
    ("n5_075", "歩く", "あるく", "", "aruku", ["to walk"], ["verbs"], "verb"),
    ("n5_076", "作る", "つくる", "", "tsukuru", ["to make", "to create"], ["verbs"], "verb"),
    # --- Adjectives (077-090) ---
    ("n5_077", "大きい", "おおきい", "", "ookii", ["big", "large"], ["adjectives"], "i-adjective"),
    ("n5_078", "小さい", "ちいさい", "", "chiisai", ["small", "little"], ["adjectives"], "i-adjective"),
    ("n5_079", "新しい", "あたらしい", "", "atarashii", ["new"], ["adjectives"], "i-adjective"),
    ("n5_080", "古い", "ふるい", "", "furui", ["old (things)"], ["adjectives"], "i-adjective"),
    ("n5_081", "高い", "たかい", "", "takai", ["expensive", "tall", "high"], ["adjectives"], "i-adjective"),
    ("n5_082", "安い", "やすい", "", "yasui", ["cheap", "inexpensive"], ["adjectives"], "i-adjective"),
    ("n5_083", "長い", "ながい", "", "nagai", ["long"], ["adjectives"], "i-adjective"),
    ("n5_084", "短い", "みじかい", "", "mijikai", ["short (length)"], ["adjectives"], "i-adjective"),
    ("n5_085", "良い", "いい", "", "ii", ["good"], ["adjectives"], "i-adjective"),
    ("n5_086", "悪い", "わるい", "", "warui", ["bad"], ["adjectives"], "i-adjective"),
    ("n5_087", "暑い", "あつい", "", "atsui", ["hot (weather)"], ["adjectives", "weather"], "i-adjective"),
    ("n5_088", "寒い", "さむい", "", "samui", ["cold (weather)"], ["adjectives", "weather"], "i-adjective"),
    ("n5_089", "おいしい", "おいしい", "", "oishii", ["delicious", "tasty"], ["adjectives", "food"], "i-adjective"),
    ("n5_090", "楽しい", "たのしい", "", "tanoshii", ["fun", "enjoyable"], ["adjectives"], "i-adjective"),
    # --- Time words (091-096) ---
    ("n5_091", "今日", "きょう", "", "kyou", ["today"], ["time"], "noun"),
    ("n5_092", "明日", "あした", "", "ashita", ["tomorrow"], ["time"], "noun"),
    ("n5_093", "昨日", "きのう", "", "kinou", ["yesterday"], ["time"], "noun"),
    ("n5_094", "今", "いま", "", "ima", ["now"], ["time"], "noun"),
    ("n5_095", "朝", "あさ", "", "asa", ["morning"], ["time"], "noun"),
    ("n5_096", "夜", "よる", "", "yoru", ["night", "evening"], ["time"], "noun"),
    # --- Places (097-104) ---
    ("n5_097", "学校", "がっこう", "", "gakkou", ["school"], ["places", "school"], "noun"),
    ("n5_098", "駅", "えき", "", "eki", ["station"], ["places", "transport"], "noun"),
    ("n5_099", "病院", "びょういん", "", "byouin", ["hospital"], ["places"], "noun"),
    ("n5_100", "銀行", "ぎんこう", "", "ginkou", ["bank"], ["places"], "noun"),
    ("n5_101", "図書館", "としょかん", "", "toshokan", ["library"], ["places", "school"], "noun"),
    ("n5_102", "郵便局", "ゆうびんきょく", "", "yuubinkyoku", ["post office"], ["places"], "noun"),
    ("n5_103", "公園", "こうえん", "", "kouen", ["park"], ["places", "nature"], "noun"),
    ("n5_104", "お店", "おみせ", "", "omise", ["shop", "store"], ["places"], "noun"),
    # --- Nature & Weather (105-110) ---
    ("n5_105", "天気", "てんき", "", "tenki", ["weather"], ["nature", "weather"], "noun"),
    ("n5_106", "雨", "あめ", "", "ame", ["rain"], ["nature", "weather"], "noun"),
    ("n5_107", "雪", "ゆき", "", "yuki", ["snow"], ["nature", "weather"], "noun"),
    ("n5_108", "風", "かぜ", "", "kaze", ["wind"], ["nature", "weather"], "noun"),
    ("n5_109", "空", "そら", "", "sora", ["sky"], ["nature"], "noun"),
    ("n5_110", "海", "うみ", "", "umi", ["sea", "ocean"], ["nature"], "noun"),
    # --- Transport & Directions (111-120) ---
    ("n5_111", "電車", "でんしゃ", "", "densha", ["train"], ["transport"], "noun"),
    ("n5_112", "バス", "", "バス", "basu", ["bus"], ["transport"], "noun"),
    ("n5_113", "自転車", "じてんしゃ", "", "jitensha", ["bicycle"], ["transport"], "noun"),
    ("n5_114", "右", "みぎ", "", "migi", ["right"], ["directions"], "noun"),
    ("n5_115", "左", "ひだり", "", "hidari", ["left"], ["directions"], "noun"),
    ("n5_116", "上", "うえ", "", "ue", ["up", "above"], ["directions"], "noun"),
    ("n5_117", "下", "した", "", "shita", ["down", "below"], ["directions"], "noun"),
    ("n5_118", "前", "まえ", "", "mae", ["front", "before"], ["directions"], "noun"),
    ("n5_119", "後ろ", "うしろ", "", "ushiro", ["behind", "back"], ["directions"], "noun"),
    ("n5_120", "中", "なか", "", "naka", ["inside", "middle"], ["directions"], "noun"),
]

# ═══════════════════════════════════════════════════════════════════════
# N4 Vocabulary (100 words)
# ═══════════════════════════════════════════════════════════════════════
N4_WORDS = [
    # --- Abstract nouns (001-012) ---
    ("n4_001", "経験", "けいけん", "", "keiken", ["experience"], ["abstract"], "noun"),
    ("n4_002", "関係", "かんけい", "", "kankei", ["relationship", "connection"], ["abstract"], "noun"),
    ("n4_003", "理由", "りゆう", "", "riyuu", ["reason"], ["abstract"], "noun"),
    ("n4_004", "意味", "いみ", "", "imi", ["meaning"], ["abstract"], "noun"),
    ("n4_005", "興味", "きょうみ", "", "kyoumi", ["interest"], ["abstract"], "noun"),
    ("n4_006", "気持ち", "きもち", "", "kimochi", ["feeling", "mood"], ["abstract"], "noun"),
    ("n4_007", "約束", "やくそく", "", "yakusoku", ["promise", "appointment"], ["abstract"], "noun"),
    ("n4_008", "準備", "じゅんび", "", "junbi", ["preparation"], ["abstract"], "noun"),
    ("n4_009", "予定", "よてい", "", "yotei", ["plan", "schedule"], ["abstract"], "noun"),
    ("n4_010", "習慣", "しゅうかん", "", "shuukan", ["habit", "custom"], ["abstract"], "noun"),
    ("n4_011", "文化", "ぶんか", "", "bunka", ["culture"], ["abstract"], "noun"),
    ("n4_012", "歴史", "れきし", "", "rekishi", ["history"], ["abstract"], "noun"),
    # --- Time (013-014) ---
    ("n4_013", "将来", "しょうらい", "", "shourai", ["future"], ["time"], "noun"),
    ("n4_014", "最近", "さいきん", "", "saikin", ["recently", "lately"], ["time"], "adverb"),
    # --- Adjectives (015-023) ---
    ("n4_015", "便利", "べんり", "", "benri", ["convenient", "useful"], ["adjectives"], "na-adjective"),
    ("n4_016", "不便", "ふべん", "", "fuben", ["inconvenient"], ["adjectives"], "na-adjective"),
    ("n4_017", "必要", "ひつよう", "", "hitsuyou", ["necessary", "needed"], ["adjectives"], "na-adjective"),
    ("n4_018", "特別", "とくべつ", "", "tokubetsu", ["special"], ["adjectives"], "na-adjective"),
    ("n4_019", "簡単", "かんたん", "", "kantan", ["easy", "simple"], ["adjectives"], "na-adjective"),
    ("n4_020", "複雑", "ふくざつ", "", "fukuzatsu", ["complicated", "complex"], ["adjectives"], "na-adjective"),
    ("n4_021", "丁寧", "ていねい", "", "teinei", ["polite", "careful"], ["adjectives"], "na-adjective"),
    ("n4_022", "残念", "ざんねん", "", "zannen", ["regrettable", "unfortunate"], ["adjectives"], "na-adjective"),
    ("n4_023", "素晴らしい", "すばらしい", "", "subarashii", ["wonderful", "magnificent"], ["adjectives"], "i-adjective"),
    # --- Verbs (024-040) ---
    ("n4_024", "届ける", "とどける", "", "todokeru", ["to deliver"], ["verbs"], "verb"),
    ("n4_025", "届く", "とどく", "", "todoku", ["to arrive", "to reach"], ["verbs"], "verb"),
    ("n4_026", "伝える", "つたえる", "", "tsutaeru", ["to convey", "to tell"], ["verbs"], "verb"),
    ("n4_027", "集める", "あつめる", "", "atsumeru", ["to collect", "to gather"], ["verbs"], "verb"),
    ("n4_028", "集まる", "あつまる", "", "atsumaru", ["to gather", "to assemble"], ["verbs"], "verb"),
    ("n4_029", "変える", "かえる", "", "kaeru", ["to change (something)"], ["verbs"], "verb"),
    ("n4_030", "変わる", "かわる", "", "kawaru", ["to change (itself)"], ["verbs"], "verb"),
    ("n4_031", "決める", "きめる", "", "kimeru", ["to decide"], ["verbs"], "verb"),
    ("n4_032", "決まる", "きまる", "", "kimaru", ["to be decided"], ["verbs"], "verb"),
    ("n4_033", "比べる", "くらべる", "", "kuraberu", ["to compare"], ["verbs"], "verb"),
    ("n4_034", "続ける", "つづける", "", "tsuzukeru", ["to continue"], ["verbs"], "verb"),
    ("n4_035", "続く", "つづく", "", "tsuzuku", ["to continue (itself)"], ["verbs"], "verb"),
    ("n4_036", "調べる", "しらべる", "", "shiraberu", ["to investigate", "to look up"], ["verbs"], "verb"),
    ("n4_037", "見つける", "みつける", "", "mitsukeru", ["to find", "to discover"], ["verbs"], "verb"),
    ("n4_038", "見つかる", "みつかる", "", "mitsukaru", ["to be found"], ["verbs"], "verb"),
    ("n4_039", "間に合う", "まにあう", "", "maniau", ["to be in time"], ["verbs"], "verb"),
    ("n4_040", "足りる", "たりる", "", "tariru", ["to be enough", "to suffice"], ["verbs"], "verb"),
    # --- Abstract nouns continued (041-050) ---
    ("n4_041", "努力", "どりょく", "", "doryoku", ["effort"], ["abstract"], "noun"),
    ("n4_042", "成功", "せいこう", "", "seikou", ["success"], ["abstract"], "noun"),
    ("n4_043", "失敗", "しっぱい", "", "shippai", ["failure", "mistake"], ["abstract"], "noun"),
    ("n4_044", "注意", "ちゅうい", "", "chuui", ["caution", "attention"], ["abstract"], "noun"),
    ("n4_045", "説明", "せつめい", "", "setsumei", ["explanation"], ["abstract"], "noun"),
    ("n4_046", "連絡", "れんらく", "", "renraku", ["contact", "communication"], ["abstract"], "noun"),
    ("n4_047", "紹介", "しょうかい", "", "shoukai", ["introduction"], ["abstract"], "noun"),
    ("n4_048", "挨拶", "あいさつ", "", "aisatsu", ["greeting"], ["abstract"], "noun"),
    ("n4_049", "相談", "そうだん", "", "soudan", ["consultation", "discussion"], ["abstract"], "noun"),
    ("n4_050", "計画", "けいかく", "", "keikaku", ["plan", "project"], ["abstract"], "noun"),
    # --- Nature & transport (051-065) ---
    ("n4_051", "季節", "きせつ", "", "kisetsu", ["season"], ["nature"], "noun"),
    ("n4_052", "景色", "けしき", "", "keshiki", ["scenery", "landscape"], ["nature"], "noun"),
    ("n4_053", "地震", "じしん", "", "jishin", ["earthquake"], ["nature"], "noun"),
    ("n4_054", "台風", "たいふう", "", "taifuu", ["typhoon"], ["nature", "weather"], "noun"),
    ("n4_055", "島", "しま", "", "shima", ["island"], ["nature"], "noun"),
    ("n4_056", "教室", "きょうしつ", "", "kyoushitsu", ["classroom"], ["school", "places"], "noun"),
    ("n4_057", "試験", "しけん", "", "shiken", ["exam", "test"], ["school"], "noun"),
    ("n4_058", "授業", "じゅぎょう", "", "jugyou", ["class", "lesson"], ["school"], "noun"),
    ("n4_059", "宿題", "しゅくだい", "", "shukudai", ["homework"], ["school"], "noun"),
    ("n4_060", "卒業", "そつぎょう", "", "sotsugyou", ["graduation"], ["school"], "noun"),
    ("n4_061", "交通", "こうつう", "", "koutsuu", ["traffic", "transportation"], ["transport"], "noun"),
    ("n4_062", "飛行機", "ひこうき", "", "hikouki", ["airplane"], ["transport"], "noun"),
    ("n4_063", "空港", "くうこう", "", "kuukou", ["airport"], ["transport", "places"], "noun"),
    ("n4_064", "道", "みち", "", "michi", ["road", "way", "path"], ["transport"], "noun"),
    ("n4_065", "信号", "しんごう", "", "shingou", ["traffic light", "signal"], ["transport"], "noun"),
    # --- Abstract nouns continued (066-080) ---
    ("n4_066", "社会", "しゃかい", "", "shakai", ["society"], ["abstract"], "noun"),
    ("n4_067", "政治", "せいじ", "", "seiji", ["politics"], ["abstract"], "noun"),
    ("n4_068", "経済", "けいざい", "", "keizai", ["economy"], ["abstract"], "noun"),
    ("n4_069", "技術", "ぎじゅつ", "", "gijutsu", ["technology", "skill"], ["abstract"], "noun"),
    ("n4_070", "産業", "さんぎょう", "", "sangyou", ["industry"], ["abstract"], "noun"),
    ("n4_071", "環境", "かんきょう", "", "kankyou", ["environment"], ["abstract", "nature"], "noun"),
    ("n4_072", "安全", "あんぜん", "", "anzen", ["safety", "security"], ["abstract"], "na-adjective"),
    ("n4_073", "危険", "きけん", "", "kiken", ["danger", "risk"], ["abstract"], "na-adjective"),
    ("n4_074", "自由", "じゆう", "", "jiyuu", ["freedom", "liberty"], ["abstract"], "na-adjective"),
    ("n4_075", "平和", "へいわ", "", "heiwa", ["peace"], ["abstract"], "noun"),
    ("n4_076", "問題", "もんだい", "", "mondai", ["problem", "question"], ["abstract", "school"], "noun"),
    ("n4_077", "答え", "こたえ", "", "kotae", ["answer"], ["abstract", "school"], "noun"),
    ("n4_078", "意見", "いけん", "", "iken", ["opinion"], ["abstract"], "noun"),
    ("n4_079", "賛成", "さんせい", "", "sansei", ["agreement", "approval"], ["abstract"], "noun"),
    ("n4_080", "反対", "はんたい", "", "hantai", ["opposition", "opposite"], ["abstract"], "noun"),
    # --- More adjectives (081-091) ---
    ("n4_081", "正確", "せいかく", "", "seikaku", ["accurate", "precise"], ["adjectives"], "na-adjective"),
    ("n4_082", "適当", "てきとう", "", "tekitou", ["suitable", "appropriate"], ["adjectives"], "na-adjective"),
    ("n4_083", "珍しい", "めずらしい", "", "mezurashii", ["rare", "unusual"], ["adjectives"], "i-adjective"),
    ("n4_084", "厳しい", "きびしい", "", "kibishii", ["strict", "severe"], ["adjectives"], "i-adjective"),
    ("n4_085", "優しい", "やさしい", "", "yasashii", ["kind", "gentle"], ["adjectives"], "i-adjective"),
    ("n4_086", "恥ずかしい", "はずかしい", "", "hazukashii", ["embarrassing", "shy"], ["adjectives"], "i-adjective"),
    ("n4_087", "懐かしい", "なつかしい", "", "natsukashii", ["nostalgic"], ["adjectives"], "i-adjective"),
    ("n4_088", "悔しい", "くやしい", "", "kuyashii", ["regrettable", "frustrating"], ["adjectives"], "i-adjective"),
    ("n4_089", "嬉しい", "うれしい", "", "ureshii", ["happy", "glad"], ["adjectives"], "i-adjective"),
    ("n4_090", "悲しい", "かなしい", "", "kanashii", ["sad"], ["adjectives"], "i-adjective"),
    ("n4_091", "寂しい", "さびしい", "", "sabishii", ["lonely"], ["adjectives"], "i-adjective"),
    # --- Common nouns (092-100) ---
    ("n4_092", "会議", "かいぎ", "", "kaigi", ["meeting", "conference"], ["common"], "noun"),
    ("n4_093", "受付", "うけつけ", "", "uketsuke", ["reception", "front desk"], ["common", "places"], "noun"),
    ("n4_094", "席", "せき", "", "seki", ["seat"], ["common"], "noun"),
    ("n4_095", "お祭り", "おまつり", "", "omatsuri", ["festival"], ["common"], "noun"),
    ("n4_096", "神社", "じんじゃ", "", "jinja", ["shrine"], ["places"], "noun"),
    ("n4_097", "お寺", "おてら", "", "otera", ["temple"], ["places"], "noun"),
    ("n4_098", "文法", "ぶんぽう", "", "bunpou", ["grammar"], ["language", "school"], "noun"),
    ("n4_099", "漢字", "かんじ", "", "kanji", ["kanji", "Chinese characters"], ["language", "school"], "noun"),
    ("n4_100", "発音", "はつおん", "", "hatsuon", ["pronunciation"], ["language"], "noun"),
]


N5_EXAMPLES = {
    "n5_001": ["こんにちは、田中さん。|Hello, Tanaka."],
    "n5_002": ["ありがとう、先生。|Thank you, teacher."],
    "n5_003": ["すみません、駅はどこですか。|Excuse me, where is the station?"],
    "n5_004": ["おはよう、お母さん。|Good morning, Mom."],
    "n5_005": ["さようなら、また明日。|Goodbye, see you tomorrow."],
    "n5_006": ["おやすみなさい、お父さん。|Good night, Dad."],
    "n5_007": ["ご飯をいただきます。|Thank you for the meal; let's eat."],
    "n5_008": ["ごちそうさま、お母さん。|Thank you for the meal, Mom."],
    "n5_009": ["はい、学生です。|Yes, I am a student."],
    "n5_010": ["いいえ、先生ではありません。|No, I am not a teacher."],
    "n5_011": ["私は水を飲む。|I drink water."],
    "n5_012": ["私はお茶を飲む。|I drink tea."],
    "n5_013": ["私はご飯を食べる。|I eat rice."],
    "n5_014": ["私はパンを買う。|I buy bread."],
    "n5_015": ["私は卵を食べる。|I eat an egg."],
    "n5_016": ["私は魚を食べる。|I eat fish."],
    "n5_017": ["私は肉を食べる。|I eat meat."],
    "n5_018": ["私は野菜を食べる。|I eat vegetables."],
    "n5_019": ["私は果物を買う。|I buy fruit."],
    "n5_020": ["私は牛乳を飲む。|I drink milk."],
    "n5_021": ["一つを買う。|I buy one."],
    "n5_022": ["二つを買う。|I buy two."],
    "n5_023": ["三つを買う。|I buy three."],
    "n5_024": ["四つを買う。|I buy four."],
    "n5_025": ["五つを買う。|I buy five."],
    "n5_026": ["六つを買う。|I buy six."],
    "n5_027": ["七つを買う。|I buy seven."],
    "n5_028": ["八つを買う。|I buy eight."],
    "n5_029": ["九つを買う。|I buy nine."],
    "n5_030": ["十個を買う。|I buy ten."],
    "n5_031": ["あの人は先生です。|That person is a teacher."],
    "n5_032": ["あの男の人は学生です。|That man is a student."],
    "n5_033": ["あの女の人は先生です。|That woman is a teacher."],
    "n5_034": ["子供は公園にいる。|The child is in the park."],
    "n5_035": ["友達と話す。|I talk with a friend."],
    "n5_036": ["先生は学校にいる。|The teacher is at school."],
    "n5_037": ["学生は本を読む。|The student reads a book."],
    "n5_038": ["私は本を読む。|I read a book."],
    "n5_039": ["車で駅に行く。|I go to the station by car."],
    "n5_040": ["猫は私の友達です。|The cat is my friend."],
    "n5_041": ["犬は公園にいる。|The dog is in the park."],
    "n5_042": ["花を買う。|I buy a flower."],
    "n5_043": ["私は山を見る。|I look at the mountain."],
    "n5_044": ["川は山の前です。|The river is in front of the mountain."],
    "n5_045": ["目を閉じます。|I close my eyes."],
    "n5_046": ["手を上げます。|I raise my hand."],
    "n5_047": ["足が痛いです。|My foot hurts."],
    "n5_048": ["口を開けます。|I open my mouth."],
    "n5_049": ["耳が大きい。|My ears are big."],
    "n5_050": ["頭が痛いです。|My head hurts."],
    "n5_051": ["お父さんは会社員です。|My father is a company employee."],
    "n5_052": ["お母さんは先生です。|My mother is a teacher."],
    "n5_053": ["お兄さんは学生です。|My older brother is a student."],
    "n5_054": ["お姉さんは会社員です。|My older sister is a company employee."],
    "n5_055": ["弟は学生です。|My younger brother is a student."],
    "n5_056": ["妹は学生です。|My younger sister is a student."],
    "n5_057": ["私の家族です。|This is my family."],
    "n5_058": ["彼の奥さんは先生です。|His wife is a teacher."],
    "n5_059": ["主人は会社員です。|My husband is a company employee."],
    "n5_060": ["赤ちゃんは夜寝ます。|The baby sleeps at night."],
    "n5_061": ["私は卵を食べる。|I eat an egg."],
    "n5_062": ["私は水を飲む。|I drink water."],
    "n5_063": ["私は学校に行く。|I go to school."],
    "n5_064": ["友達が家に来る。|My friend comes to my house."],
    "n5_065": ["私は山を見る。|I look at the mountain."],
    "n5_066": ["私は先生に聞く。|I ask the teacher."],
    "n5_067": ["私は本に書く。|I write in the book."],
    "n5_068": ["私は本を読む。|I read a book."],
    "n5_069": ["私は友達と話す。|I talk with my friend."],
    "n5_070": ["私はパンを買う。|I buy bread."],
    "n5_071": ["私は駅で待つ。|I wait at the station."],
    "n5_072": ["私は先生の前に立つ。|I stand in front of the teacher."],
    "n5_073": ["私は椅子に座る。|I sit on the chair."],
    "n5_074": ["私は公園を走る。|I run through the park."],
    "n5_075": ["私は駅まで歩く。|I walk to the station."],
    "n5_076": ["私はご飯を作る。|I make a meal."],
    "n5_077": ["この本は大きい。|This book is big."],
    "n5_078": ["この猫は小さい。|This cat is small."],
    "n5_079": ["これは新しい本です。|This is a new book."],
    "n5_080": ["これは古い車です。|This is an old car."],
    "n5_081": ["この車は高い。|This car is expensive."],
    "n5_082": ["このパンは安い。|This bread is cheap."],
    "n5_083": ["この川は長い。|This river is long."],
    "n5_084": ["これは短い本です。|This is a short book."],
    "n5_085": ["この店は良い。|This shop is good."],
    "n5_086": ["それは悪い本です。|That is a bad book."],
    "n5_087": ["今日は暑い。|Today is hot."],
    "n5_088": ["今日は寒い。|Today is cold."],
    "n5_089": ["このご飯はおいしい。|This meal is delicious."],
    "n5_090": ["このゲームは楽しい。|This game is fun."],
    "n5_091": ["今日は暑い。|Today is hot."],
    "n5_092": ["明日は学校に行く。|I will go to school tomorrow."],
    "n5_093": ["昨日は雨でした。|It rained yesterday."],
    "n5_094": ["今は朝です。|It is morning now."],
    "n5_095": ["朝は寒い。|Mornings are cold."],
    "n5_096": ["夜は静かです。|Nights are quiet."],
    "n5_097": ["学校は大きい。|The school is big."],
    "n5_098": ["駅はここです。|The station is here."],
    "n5_099": ["病院はあそこです。|The hospital is over there."],
    "n5_100": ["銀行は駅の前です。|The bank is in front of the station."],
    "n5_101": ["図書館で本を読む。|I read a book at the library."],
    "n5_102": ["郵便局は駅の右です。|The post office is to the right of the station."],
    "n5_103": ["公園は広いです。|The park is spacious."],
    "n5_104": ["このお店は大きい。|This shop is big."],
    "n5_105": ["今日は天気が良い。|The weather is good today."],
    "n5_106": ["今日は雨です。|It is rainy today."],
    "n5_107": ["雪は白いです。|Snow is white."],
    "n5_108": ["風が強いです。|The wind is strong."],
    "n5_109": ["私は空を見る。|I look at the sky."],
    "n5_110": ["海は大きい。|The sea is big."],
    "n5_111": ["電車で学校に行く。|I go to school by train."],
    "n5_112": ["バスで駅に行く。|I go to the station by bus."],
    "n5_113": ["自転車で公園に行く。|I go to the park by bicycle."],
    "n5_114": ["右に曲がります。|I turn right."],
    "n5_115": ["左に曲がります。|I turn left."],
    "n5_116": ["本は机の上です。|The book is on the desk."],
    "n5_117": ["猫は机の下です。|The cat is under the desk."],
    "n5_118": ["銀行は駅の前です。|The bank is in front of the station."],
    "n5_119": ["公園は学校の後ろです。|The park is behind the school."],
    "n5_120": ["猫は箱の中です。|The cat is inside the box."],
}


from content.n5_words import WORDS as N5_WORDS
from content.n4_words import WORDS as N4_WORDS


def validate_examples(words):
    for word in words:
        examples = word["example_sentences"]
        display = word["kanji"] or word["hiragana"] or word["katakana"]
        if not examples:
            raise ValueError(f"Missing example for {word['id']}")
        for example in examples:
            parts = example.split("|")
            if len(parts) != 2 or not parts[0].strip() or not parts[1].strip():
                raise ValueError(f"Malformed example for {word['id']}: {example}")
            if display not in parts[0]:
                raise ValueError(f"Example for {word['id']} does not contain {display}")


def generate_json(words, jlpt_level):
    """Return validated source records for runtime JSON."""
    return words


def main():
    os.makedirs(VOCAB_DIR, exist_ok=True)
    validate_examples(N5_WORDS)
    validate_examples(N4_WORDS)

    # Generate N5
    n5_data = generate_json(N5_WORDS, 5)
    n5_path = os.path.join(VOCAB_DIR, "n5_vocab.json")
    with open(n5_path, "w", encoding="utf-8", newline="\n") as f:
        json.dump(n5_data, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print(f"Written {n5_path} ({len(N5_WORDS)} words)")

    # Generate N4
    n4_data = generate_json(N4_WORDS, 4)
    n4_path = os.path.join(VOCAB_DIR, "n4_vocab.json")
    with open(n4_path, "w", encoding="utf-8", newline="\n") as f:
        json.dump(n4_data, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print(f"Written {n4_path} ({len(N4_WORDS)} words)")


if __name__ == "__main__":
    main()
