# -*- coding: utf-8 -*-
"""Generate n5_vocab.json and n4_vocab.json with proper UTF-8 encoding.

JSON format avoids Godot's .tres reimport/resave behavior which strips
PackedStringArray values back to empty defaults."""
import os
import json

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


def generate_json(words, jlpt_level):
    """Generate a JSON-serializable list of word dictionaries."""
    result = []
    for w in words:
        wid, kanji, hiragana, katakana, romaji, meanings, categories, pos = w
        result.append({
            "id": wid,
            "kanji": kanji,
            "hiragana": hiragana,
            "katakana": katakana,
            "romaji": romaji,
            "english_meanings": meanings,
            "jlpt_level": jlpt_level,
            "categories": categories,
            "example_sentences": [],
            "part_of_speech": pos,
        })
    return result


def main():
    os.makedirs(VOCAB_DIR, exist_ok=True)

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
