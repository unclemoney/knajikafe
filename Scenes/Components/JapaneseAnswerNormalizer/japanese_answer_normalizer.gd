extends RefCounted
class_name JapaneseAnswerNormalizer

const HALFWIDTH_KANA := {
	"ｦ": "ヲ", "ｱ": "ア", "ｲ": "イ", "ｳ": "ウ", "ｴ": "エ", "ｵ": "オ",
	"ｧ": "ァ", "ｨ": "ィ", "ｩ": "ゥ", "ｪ": "ェ", "ｫ": "ォ", "ｬ": "ャ", "ｭ": "ュ", "ｮ": "ョ", "ｯ": "ッ", "ｰ": "ー",
	"ｶ": "カ", "ｷ": "キ", "ｸ": "ク", "ｹ": "ケ", "ｺ": "コ", "ｻ": "サ", "ｼ": "シ", "ｽ": "ス", "ｾ": "セ", "ｿ": "ソ",
	"ﾀ": "タ", "ﾁ": "チ", "ﾂ": "ツ", "ﾃ": "テ", "ﾄ": "ト", "ﾅ": "ナ", "ﾆ": "ニ", "ﾇ": "ヌ", "ﾈ": "ネ", "ﾉ": "ノ",
	"ﾊ": "ハ", "ﾋ": "ヒ", "ﾌ": "フ", "ﾍ": "ヘ", "ﾎ": "ホ", "ﾏ": "マ", "ﾐ": "ミ", "ﾑ": "ム", "ﾒ": "メ", "ﾓ": "モ",
	"ﾔ": "ヤ", "ﾕ": "ユ", "ﾖ": "ヨ", "ﾗ": "ラ", "ﾘ": "リ", "ﾙ": "ル", "ﾚ": "レ", "ﾛ": "ロ", "ﾜ": "ワ", "ﾝ": "ン",
}

const HALFWIDTH_DAKUTEN := {
	"ｳ": "ゔ", "ｶ": "が", "ｷ": "ぎ", "ｸ": "ぐ", "ｹ": "げ", "ｺ": "ご",
	"ｻ": "ざ", "ｼ": "じ", "ｽ": "ず", "ｾ": "ぜ", "ｿ": "ぞ",
	"ﾀ": "だ", "ﾁ": "ぢ", "ﾂ": "づ", "ﾃ": "で", "ﾄ": "ど",
	"ﾊ": "ば", "ﾋ": "び", "ﾌ": "ぶ", "ﾍ": "べ", "ﾎ": "ぼ",
}
const HALFWIDTH_HANDAKUTEN := {"ﾊ": "ぱ", "ﾋ": "ぴ", "ﾌ": "ぷ", "ﾍ": "ぺ", "ﾎ": "ぽ"}


static func normalize(value: String) -> String:
	var text := value.strip_edges()
	var normalized := ""
	var i := 0
	while i < text.length():
		var character := text[i]
		if i + 1 < text.length() and text[i + 1] == "ﾞ" and HALFWIDTH_DAKUTEN.has(character):
			normalized += HALFWIDTH_DAKUTEN[character]
			i += 2
			continue
		if i + 1 < text.length() and text[i + 1] == "ﾟ" and HALFWIDTH_HANDAKUTEN.has(character):
			normalized += HALFWIDTH_HANDAKUTEN[character]
			i += 2
			continue
		if HALFWIDTH_KANA.has(character):
			character = HALFWIDTH_KANA[character]
		var code := character.unicode_at(0)
		if code >= 0xFF01 and code <= 0xFF5E:
			code -= 0xFEE0
			normalized += String.chr(code)
		elif code >= 0x30A1 and code <= 0x30F6:
			normalized += String.chr(code - 0x60)
		else:
			normalized += character
		i += 1
	return normalized


static func matches(word: VocabWord, answer: String) -> bool:
	var normalized := normalize(answer).to_lower()
	if normalized == "":
		return false
	for candidate in [word.hiragana, word.katakana, word.romaji]:
		if candidate != "" and normalized == normalize(candidate).to_lower():
			return true
	return false
