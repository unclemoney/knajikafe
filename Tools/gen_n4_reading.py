# -*- coding: utf-8 -*-
"""Generate and validate N4 Reading Shelf passages."""
import json
import os
from gen_reading import passage

ROOT = os.path.join(os.path.dirname(__file__), "..")
VOCAB_PATH = os.path.join(ROOT, "Resources", "Vocabulary", "n4_vocab.json")
OUTPUT_PATH = os.path.join(ROOT, "Resources", "Reading", "n4_reading.json")


def main():
    passages = [
        passage("read_n4_001", "n4_001", ["n4_009"], ["来月、会社で新しい仕事を始めます。", "今の仕事も大切ですが、新しい経験を楽しみにしています。"], ["Next month, I will start a new job at my company.", "My current job is important too, but I am looking forward to the new experience."], "What is the speaker looking forward to?", ["A new experience", "A long vacation", "Leaving the company", "A cheaper apartment"], 0, "新しい経験を楽しみにしています means looking forward to the new experience."),
        passage("read_n4_002", "n4_002", ["n4_003"], ["この本は日本の文化と関係があります。", "その本を読んで、日本の歴史にも興味を持ちました。"], ["This book is related to Japanese culture.", "After reading it, I also became interested in Japanese history."], "What did the speaker become interested in?", ["Japanese history", "Japanese food", "Japanese trains", "Japanese schools"], 0, "日本の歴史にも興味を持ちました means became interested in Japanese history."),
        passage("read_n4_003", "n4_003", ["n4_002"], ["遅れた理由は、電車が止まっていたことです。", "駅の人に聞いて、次の電車を待ちました。"], ["The reason I was late is that the train had stopped.", "I asked a station worker and waited for the next train."], "Why was the speaker late?", ["The weather", "The train stopped", "They forgot the time", "They missed the bus"], 1, "電車が止まっていたことです says the train had stopped."),
        passage("read_n4_004", "n4_004", ["n4_002"], ["「漢字」は中国から来た文字です。", "その意味を知って、漢字を勉強する人が増えています。"], ["The word 漢字 comes from Chinese characters.", "More people are learning kanji after understanding its meaning."], "What is mentioned about 漢字?", ["Its meaning", "Its price", "Its color", "Its location"], 0, "その意味を知って means after understanding its meaning."),
        passage("read_n4_005", "n4_005", ["n4_002"], ["私は写真に興味があります。", "週末は山や川の写真を撮ります。"], ["I am interested in photography.", "On weekends, I take photos of mountains and rivers."], "What does the speaker photograph?", ["Cafes", "Mountains and rivers", "Trains", "Cats"], 1, "山や川の写真を撮ります says photos of mountains and rivers."),
        passage("read_n4_006", "n4_006", ["n4_009"], ["今日は寒いので、コートを着ました。", "家の中は暖かく、気持ちがいいです。"], ["Because it is cold today, I wore a coat.", "Inside the house is warm and comfortable."], "How is the inside of the house?", ["Cold", "Warm and comfortable", "Noisy", "Dark"], 1, "家の中は暖かく、気持ちがいいです describes a warm comfortable home."),
        passage("read_n4_007", "n4_007", ["n4_009"], ["友達と来週の日曜日に会う約束をしました。", "駅の前の喫茶店で話す予定です。"], ["I promised to meet my friend next Sunday.", "We plan to talk at the café in front of the station."], "Where will they meet?", ["At school", "At the station café", "At the library", "At home"], 1, "駅の前の喫茶店 is the café in front of the station."),
        passage("read_n4_008", "n4_008", ["n4_009"], ["明日は雨かもしれません。", "傘と長靴を準備しておきます。"], ["It may rain tomorrow.", "I will prepare an umbrella and rain boots."], "What will the speaker prepare?", ["A ticket", "An umbrella and boots", "A meal", "A camera"], 1, "傘と長靴を準備しておきます means prepare an umbrella and rain boots."),
        passage("read_n4_009", "n4_009", ["n4_007"], ["旅行の予定は、来月の三日です。", "姉と京都へ行きます。"], ["The trip is planned for the third of next month.", "I will go to Kyoto with my older sister."], "When is the trip?", ["Next Sunday", "Next month on the third", "Tomorrow", "Last month"], 1, "来月の三日です means the third of next month."),
        passage("read_n4_010", "n4_010", ["n4_095"], ["朝、コーヒーを飲むのが私の習慣です。", "そのあと、ニュースを読みます。"], ["Drinking coffee in the morning is my habit.", "After that, I read the news."], "What does the speaker do after coffee?", ["Reads the news", "Goes running", "Calls a friend", "Makes breakfast"], 0, "そのあと、ニュースを読みます says they read the news afterward."),
        passage("read_n4_011", "n4_011", ["n4_012"], ["秋の文化祭で、学生たちは日本の歌を歌います。", "その歌は、日本の四季を表しています。"], ["At the autumn culture festival, students sing a Japanese song.", "The song expresses Japan's four seasons."], "What does the song express?", ["The four seasons", "School history", "Family memories", "City traffic"], 0, "日本の四季を表しています means it expresses Japan's four seasons."),
        passage("read_n4_012", "n4_012", ["n4_011"], ["この古い建物は、百年前にできました。", "町の歴史を知るために、毎年学生が見学に来ます。"], ["This old building was built one hundred years ago.", "Students come every year to learn about the town's history."], "Why do students visit the building?", ["To study history", "To buy books", "To eat lunch", "To take exams"], 0, "町の歴史を知るために means to learn about the town's history."),
        passage("read_n4_013", "n4_013", ["n4_006"], ["将来、日本語の先生になりたいです。", "そのために、毎日勉強を続けています。"], ["In the future, I want to become a Japanese teacher.", "For that reason, I keep studying every day."], "What is the speaker's goal?", ["To become a teacher", "To become a doctor", "To become a driver", "To become a chef"], 0, "日本語の先生になりたいです says the speaker wants to become a Japanese teacher."),
        passage("read_n4_014", "n4_014", ["n4_009"], ["最近、弟はよく料理をします。", "昨日は、家族にカレーを作ってくれました。"], ["Recently, my younger brother often cooks.", "Yesterday, he made curry for our family."], "What did the brother make?", ["Ramen", "Curry", "Sushi", "Cake"], 1, "家族にカレーを作ってくれました means he made curry for the family."),
        passage("read_n4_015", "n4_015", ["n4_016"], ["このアプリは地図を見るのに便利です。", "電車の時間もすぐにわかります。"], ["This app is convenient for looking at maps.", "It also shows train times right away."], "What can the app show quickly?", ["Train times", "Weather forecasts", "Restaurant menus", "News articles"], 0, "電車の時間もすぐにわかります means train times are shown right away."),
        passage("read_n4_016", "n4_016", ["n4_015"], ["自転車がないと、駅まで不便です。", "そのため、明日はバスを使います。"], ["Without a bicycle, getting to the station is inconvenient.", "So tomorrow I will use the bus."], "How will the speaker travel tomorrow?", ["By bicycle", "By bus", "By train", "On foot"], 1, "そのため、明日はバスを使います says the speaker will use the bus tomorrow."),
        passage("read_n4_017", "n4_017", ["n4_008"], ["来週の発表のために、資料が必要です。", "先生にもらって、夜に読みます。"], ["I need the documents for next week's presentation.", "I will get them from the teacher and read them at night."], "Why does the speaker need the documents?", ["For a presentation", "For a trip", "For a meal", "For a game"], 0, "来週の発表のために means for next week's presentation."),
        passage("read_n4_018", "n4_018", ["n4_007"], ["今日は特別な日です。", "家族と初めてのレストランへ行きます。"], ["Today is a special day.", "I am going to a new restaurant with my family."], "What is special about today?", ["It is a family celebration", "It is a normal workday", "It is a rainy day", "It is a school holiday"], 0, "今日は特別な日です says it is a special day for the family."),
        passage("read_n4_019", "n4_019", ["n4_017"], ["この問題は簡単に見えますが、答えは難しいです。", "もう一度考えてみましょう。"], ["This problem looks easy, but the answer is difficult.", "I'll think about it once more."], "What is difficult?", ["The answer", "The question", "The class", "The book"], 0, "答えは難しいです says the answer is difficult."),
        passage("read_n4_020", "n4_020", ["n4_019"], ["この計画は複雑で、説明に時間がかかります。", "先生に聞いてから、決めます。"], ["This plan is complicated and takes time to explain.", "I will decide after asking the teacher."], "What will the speaker do before deciding?", ["Ask the teacher", "Go home", "Buy a book", "Call a friend"], 0, "先生に聞いてから、決めます says decide after asking the teacher."),
        passage("read_n4_021", "n4_021", ["n4_007"], ["先生はいつも丁寧に説明してくれます。", "私たちは質問しやすいです。"], ["The teacher always explains things politely.", "It is easy for us to ask questions."], "Why is it easy to ask questions?", ["The teacher explains politely", "The questions are short", "The class is small", "The answers are easy"], 0, "丁寧に説明してくれます means the teacher explains politely."),
        passage("read_n4_022", "n4_022", ["n4_021"], ["今日の映画は残念ながら、あまり面白くありませんでした。", "次の映画には期待しています。"], ["Unfortunately, today's movie was not very interesting.", "I am looking forward to the next movie."], "How does the speaker feel about the next movie?", ["Hopeful", "Bored", "Angry", "Worried"], 0, "次の映画には期待しています means looking forward to the next movie."),
        passage("read_n4_023", "n4_023", ["n4_022"], ["週末の公園は、花がたくさんあって素晴らしいです。", "写真をたくさん撮りたいです。"], ["The park on the weekend has many flowers and is wonderful.", "I want to take many photos."], "What does the speaker want to do?", ["Take photos", "Go swimming", "Buy flowers", "Read a book"], 0, "写真をたくさん撮りたいです means wants to take many photos."),
        passage("read_n4_024", "n4_024", ["n4_009"], ["友達に本を届けました。", "駅の近くにある本屋さんで買った本です。"], ["I delivered a book to my friend.", "It is a book I bought at the bookstore near the station."], "What did the speaker deliver?", ["A letter", "A book", "A meal", "A ticket"], 1, "友達に本を届けました means delivered a book to a friend."),
        passage("read_n4_025", "n4_025", ["n4_024"], ["荷物が届く日は、金曜日です。", "木曜日には家にいるつもりです。"], ["The package will arrive on Friday.", "I plan to be home on Thursday."], "When will the package arrive?", ["Thursday", "Friday", "Saturday", "Monday"], 1, "荷物が届く日は、金曜日です says the package arrives Friday."),
        passage("read_n4_026", "n4_026", ["n4_027"], ["勉強を続けるのは難しいですが、毎日少しずつやっています。", "最近は漢字も覚えられてきました。"], ["Continuing to study is difficult, but I do a little every day.", "Recently, I have started remembering more kanji."], "What is improving?", ["Kanji knowledge", "Cooking skill", "Driving skill", "Typing speed"], 0, "最近は漢字も覚えられてきました means remembering more kanji."),
        passage("read_n4_027", "n4_026", ["n4_028"], ["来週から仕事のやり方を変えます。", "もっと効率が良くなると思います。"], ["Starting next week, I will change how I work.", "I think it will become more efficient."], "What does the speaker expect to improve?", ["Efficiency", "Salary", "Travel time", "Weather"], 0, "もっと効率が良くなると思います means expects better efficiency."),
        passage("read_n4_028", "n4_027", ["n4_029"], ["日本語と英語を比べると、文の順番が違います。", "その違いを学ぶのは面白いです。"], ["Comparing Japanese and English, the sentence order is different.", "Learning that difference is interesting."], "What does the speaker compare?", ["Two languages", "Two cities", "Two books", "Two jobs"], 0, "日本語と英語を比べると means comparing Japanese and English."),
        passage("read_n4_029", "n4_028", ["n4_030"], ["明日のクラスで、好きな日本の歌を選びます。", "その歌をみんなで歌います。"], ["In tomorrow's class, I will choose a Japanese song I like.", "We will sing that song together."], "What will the class do with the song?", ["Sing it", "Translate it", "Write it", "Draw it"], 0, "その歌をみんなで歌います means sing the song together."),
        passage("read_n4_030", "n4_029", ["n4_031"], ["来週の試験の日時を、先生と確認して決めます。", "その後、友達にも知らせます。"], ["I will confirm the exam date with the teacher and decide.", "After that, I will tell my friends."], "Who will be told afterward?", ["The teacher", "The friends", "The family", "The station staff"], 1, "その後、友達にも知らせます means telling friends afterward."),
    ]
    for item in passages:
        item["jlpt_level"] = 4
    with open(VOCAB_PATH, encoding="utf-8") as file:
        vocab = {word["id"]: word for word in json.load(file)}
    if len(passages) != 30 or len({p["id"] for p in passages}) != 30:
        raise ValueError("Expected 30 unique N4 passages")
    questions = set()
    for item in passages:
        if item["target_vocab_id"] not in vocab or item["jlpt_level"] != 4:
            raise ValueError(f"Invalid target in {item['id']}")
        if any(word_id not in vocab for word_id in item["related_vocab_ids"]):
            raise ValueError(f"Invalid related vocabulary in {item['id']}")
        if len(item["japanese_lines"]) != len(item["english_lines"]):
            raise ValueError(f"Line mismatch in {item['id']}")
        if len(item["choices"]) != 4 or len(set(item["choices"])) != 4 or not 0 <= item["answer_index"] < 4:
            raise ValueError(f"Invalid choices in {item['id']}")
        if not item["explanation"].strip() or item["question"] in questions:
            raise ValueError(f"Missing explanation or duplicate question in {item['id']}")
        questions.add(item["question"])
    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    with open(OUTPUT_PATH, "w", encoding="utf-8", newline="\n") as file:
        json.dump(passages, file, ensure_ascii=False, indent=2)
        file.write("\n")
    print(f"Written {OUTPUT_PATH} ({len(passages)} passages)")


if __name__ == "__main__":
    main()
