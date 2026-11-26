# -*- coding: utf-8 -*-
"""Generate and validate N5 Reading Shelf passages."""
import json
import os

ROOT = os.path.join(os.path.dirname(__file__), "..")
VOCAB_PATH = os.path.join(ROOT, "Resources", "Vocabulary", "n5_vocab.json")
OUTPUT_PATH = os.path.join(ROOT, "Resources", "Reading", "n5_reading.json")


def passage(pid, target, related, japanese, english, question, choices, answer, explanation):
    return {
        "id": pid,
        "jlpt_level": 5,
        "target_vocab_id": target,
        "related_vocab_ids": related,
        "japanese_lines": japanese,
        "english_lines": english,
        "question": question,
        "choices": choices,
        "answer_index": answer,
        "explanation": explanation,
    }


PASSAGES = [
    passage("read_001", "n5_091", ["n5_097"], ["今日は月曜日です。", "私は学校に行きます。"], ["Today is Monday.", "I will go to school."], "What will the speaker do today?", ["Go to school", "Stay home", "Go shopping", "Visit the hospital"], 0, "The second sentence says that the speaker will go to school."),
    passage("read_002", "n5_062", ["n5_012", "n5_020"], ["朝、私はお茶を飲みます。", "妹は牛乳を飲みます。"], ["In the morning, I drink tea.", "My younger sister drinks milk."], "What does the younger sister drink?", ["Tea", "Water", "Milk", "Coffee"], 2, "The second sentence says 妹は牛乳を飲みます: the younger sister drinks milk."),
    passage("read_003", "n5_097", ["n5_098", "n5_118"], ["私の学校は駅の前です。", "学校は大きいです。"], ["My school is in front of the station.", "The school is big."], "Where is the school?", ["Behind the station", "In front of the station", "Inside the station", "To the left of the station"], 1, "駅の前 means in front of the station."),
    passage("read_004", "n5_103", ["n5_105", "n5_041"], ["今日は天気が良いです。", "犬と公園を歩きます。"], ["The weather is good today.", "I walk in the park with my dog."], "Where does the speaker walk?", ["At school", "At the station", "In the park", "At the shop"], 2, "公園を歩きます means walks in the park."),
    passage("read_005", "n5_070", ["n5_014", "n5_019"], ["私は駅の店でパンを買います。", "妹は果物を買います。"], ["I buy bread at the station shop.", "My younger sister buys fruit."], "What does the speaker buy?", ["Fruit", "Bread", "Vegetables", "Fish"], 1, "The first sentence uses 私は and パンを買います: I buy bread."),
    passage("read_006", "n5_068", ["n5_101", "n5_038"], ["夜、図書館で本を読みます。", "この本は楽しいです。"], ["At night, I read a book at the library.", "This book is fun."], "Where does the speaker read?", ["At school", "At the library", "At home", "At the station"], 1, "図書館で means at the library."),
    passage("read_007", "n5_012", ["n5_051", "n5_011"], ["父は朝、お茶を飲みます。", "私は水を飲みます。"], ["My father drinks tea in the morning.", "I drink water."], "Who drinks tea?", ["The speaker", "The mother", "The father", "The younger sister"], 2, "父は朝、お茶を飲みます identifies the father as the tea drinker."),
    passage("read_008", "n5_111", ["n5_097", "n5_098"], ["私は毎朝、電車で学校に行きます。", "駅は家の前です。"], ["Every morning, I go to school by train.", "The station is in front of my house."], "How does the speaker go to school?", ["By bus", "By bicycle", "On foot", "By train"], 3, "電車で means by train."),
    passage("read_009", "n5_065", ["n5_109", "n5_096"], ["夜、空を見ます。", "月が大きいです。"], ["At night, I look at the sky.", "The moon is big."], "What does the speaker look at?", ["The sea", "The mountain", "The sky", "The station"], 2, "空を見ます means looks at the sky."),
    passage("read_010", "n5_035", ["n5_064", "n5_061"], ["友達は私の家に来ます。", "私たちはご飯を食べます。"], ["My friend comes to my house.", "We eat a meal."], "What do the speaker and friend do together?", ["Read a book", "Eat a meal", "Go to school", "Buy bread"], 1, "私たちはご飯を食べます means we eat a meal."),
    passage("read_011", "n5_105", ["n5_091", "n5_093"], ["昨日は雨でした。", "今日は天気が良いです。"], ["It rained yesterday.", "The weather is good today."], "How is the weather today?", ["Rainy", "Snowy", "Good", "Windy"], 2, "今日は天気が良いです means the weather is good today."),
    passage("read_012", "n5_113", ["n5_055", "n5_103"], ["弟は自転車で公園に行きます。", "私はバスで行きます。"], ["My younger brother goes to the park by bicycle.", "I go by bus."], "How does the younger brother go?", ["By bus", "By bicycle", "By train", "On foot"], 1, "弟は自転車で identifies the younger brother and bicycle."),
    passage("read_013", "n5_053", ["n5_037", "n5_098"], ["お兄さんは学生です。", "大学は駅の後ろです。"], ["My older brother is a student.", "The university is behind the station."], "What is the older brother?", ["A teacher", "A student", "A doctor", "A shop worker"], 1, "お兄さんは学生です directly says the older brother is a student."),
    passage("read_014", "n5_018", ["n5_052", "n5_016"], ["母は店で野菜を買います。", "父は魚を買います。"], ["My mother buys vegetables at the shop.", "My father buys fish."], "What does the mother buy?", ["Fish", "Fruit", "Vegetables", "Meat"], 2, "母は野菜を買います says the mother buys vegetables."),
    passage("read_015", "n5_101", ["n5_097", "n5_120"], ["図書館は学校の中です。", "私はそこで本を読みます。"], ["The library is inside the school.", "I read books there."], "Where is the library?", ["Behind the school", "In front of the school", "Inside the school", "To the right of the school"], 2, "学校の中 means inside the school."),
    passage("read_016", "n5_096", ["n5_038", "n5_095"], ["私は夜、家で本を読みます。", "朝は学校で読みます。"], ["At night, I read books at home.", "In the morning, I read at school."], "When does the speaker read at home?", ["In the morning", "At night", "Every afternoon", "On Monday"], 1, "夜、家で connects night with reading at home."),
    passage("read_017", "n5_114", ["n5_100", "n5_098"], ["銀行は駅の右です。", "病院は左です。"], ["The bank is to the right of the station.", "The hospital is to the left."], "Where is the bank?", ["To the left of the station", "Behind the station", "Inside the station", "To the right of the station"], 3, "駅の右 means to the right of the station."),
    passage("read_018", "n5_066", ["n5_036", "n5_037"], ["学生は先生に聞きます。", "先生は日本語で話します。"], ["The students ask the teacher.", "The teacher speaks in Japanese."], "Whom do the students ask?", ["Their friend", "The teacher", "Their mother", "The shopkeeper"], 1, "先生に聞きます means ask the teacher."),
    passage("read_019", "n5_063", ["n5_092", "n5_110"], ["明日、私は友達と海に行きます。", "電車で行きます。"], ["Tomorrow, I will go to the sea with a friend.", "We will go by train."], "Where will the speaker go tomorrow?", ["The mountain", "The sea", "The library", "The bank"], 1, "明日 and 海に行きます establish tomorrow and the sea."),
    passage("read_020", "n5_076", ["n5_051", "n5_013"], ["父は朝、ご飯を作ります。", "私はお茶を作ります。"], ["My father makes rice in the morning.", "I make tea."], "What does the father make?", ["Tea", "Bread", "Rice", "Fruit"], 2, "父はご飯を作ります says the father makes rice."),
    passage("read_021", "n5_040", ["n5_041", "n5_120"], ["猫は箱の中です。", "犬は机の下です。"], ["The cat is inside the box.", "The dog is under the desk."], "Where is the cat?", ["Under the desk", "On the box", "Inside the box", "Behind the desk"], 2, "猫は箱の中です means the cat is inside the box."),
    passage("read_022", "n5_098", ["n5_075", "n5_118"], ["駅は家の前です。", "私は歩いて駅に行きます。"], ["The station is in front of my house.", "I walk to the station."], "How does the speaker go to the station?", ["By train", "By bus", "On foot", "By bicycle"], 2, "歩いて means on foot."),
    passage("read_023", "n5_067", ["n5_056", "n5_038"], ["妹は手紙を書きます。", "私は本に名前を書きます。"], ["My younger sister writes a letter.", "I write my name in the book."], "What does the speaker write in the book?", ["A letter", "A name", "A date", "A story"], 1, "本に名前を書きます means writes a name in the book."),
    passage("read_024", "n5_106", ["n5_091", "n5_068"], ["今日は雨です。", "私は家で本を読みます。"], ["It is rainy today.", "I read a book at home."], "Why does the speaker stay home?", ["It is snowy", "It is rainy", "It is hot", "It is windy"], 1, "今日は雨です gives rain as the situation."),
    passage("read_025", "n5_089", ["n5_013", "n5_014"], ["この店のご飯はおいしいです。", "パンもおいしいです。"], ["This shop's rice dishes are delicious.", "The bread is delicious too."], "What is described as delicious?", ["Only tea", "Rice and bread", "Only fruit", "Fish and meat"], 1, "ご飯 and パンも together identify rice and bread."),
    passage("read_026", "n5_108", ["n5_103", "n5_091"], ["今日は風が強いです。", "公園には行きません。"], ["The wind is strong today.", "I will not go to the park."], "Why will the speaker not go to the park?", ["Strong wind", "Rain", "Snow", "Cold weather"], 0, "風が強いです means the wind is strong."),
    passage("read_027", "n5_104", ["n5_019", "n5_018"], ["このお店は駅の中です。", "果物と野菜を売っています。"], ["This shop is inside the station.", "It sells fruit and vegetables."], "What does the shop sell?", ["Bread and eggs", "Fish and meat", "Fruit and vegetables", "Books and letters"], 2, "果物と野菜を売っています means sells fruit and vegetables."),
    passage("read_028", "n5_095", ["n5_015", "n5_020"], ["私は朝、卵とパンを食べます。", "牛乳も飲みます。"], ["In the morning, I eat eggs and bread.", "I also drink milk."], "What does the speaker drink in the morning?", ["Tea", "Water", "Milk", "Coffee"], 2, "牛乳も飲みます means also drinks milk."),
    passage("read_029", "n5_119", ["n5_103", "n5_097"], ["公園は学校の後ろです。", "よく友達とそこで話します。"], ["The park is behind the school.", "I often talk with friends there."], "Where is the park?", ["In front of the school", "Inside the school", "Behind the school", "To the right of the school"], 2, "学校の後ろ means behind the school."),
    passage("read_030", "n5_120", ["n5_040", "n5_041"], ["猫は箱の中で寝ています。", "犬は箱の上です。"], ["The cat is sleeping inside the box.", "The dog is on top of the box."], "Where is the dog?", ["Inside the box", "Under the box", "Behind the box", "On top of the box"], 3, "犬は箱の上です places the dog on top of the box."),
]


def main():
    with open(VOCAB_PATH, encoding="utf-8") as file:
        vocab = {word["id"]: word for word in json.load(file)}
    if len(PASSAGES) != 30 or len({p["id"] for p in PASSAGES}) != 30:
        raise ValueError("Expected 30 unique passages")
    questions = set()
    for item in PASSAGES:
        if item["target_vocab_id"] not in vocab or item["jlpt_level"] != 5:
            raise ValueError(f"Invalid target in {item['id']}")
        if any(word_id not in vocab for word_id in item["related_vocab_ids"]):
            raise ValueError(f"Invalid related vocabulary in {item['id']}")
        if not item["japanese_lines"] or len(item["japanese_lines"]) != len(item["english_lines"]):
            raise ValueError(f"Line mismatch in {item['id']}")
        if len(item["choices"]) != 4 or len(set(item["choices"])) != 4 or not 0 <= item["answer_index"] < 4:
            raise ValueError(f"Invalid choices in {item['id']}")
        if not item["explanation"].strip() or item["question"] in questions:
            raise ValueError(f"Missing explanation or duplicate question in {item['id']}")
        questions.add(item["question"])
    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    with open(OUTPUT_PATH, "w", encoding="utf-8", newline="\n") as file:
        json.dump(PASSAGES, file, ensure_ascii=False, indent=2)
        file.write("\n")
    print(f"Written {OUTPUT_PATH} ({len(PASSAGES)} passages)")


if __name__ == "__main__":
    main()
