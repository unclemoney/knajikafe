# Fix slash-lines: replace Chinese tail after ／ with English translation of the
# Japanese sentence; where the tail was wrapped and its continuation already sits
# translated on the next line, merge and delete that continuation line.
# Applied bottom-up per file. Verification: tail after last ／ must match.
import pathlib

# (file, line_no, old_tail_stripped, new_tail, next_line_stripped_to_delete_or_None)
F = [
# ---- 中级上 26课 ----
("markdown/中级上/1.梁爽老师日语精讲精练：第26课.md", 193, "小child; kid",
 "They played, opening and closing the door over and over.",
 "They played, opening and closing the door over and over."),
("markdown/中级上/1.梁爽老师日语精讲精练：第26课.md", 332, "嗯", "Yeah.", None),
# ---- 中级上 31课 ----
("markdown/中级上/11.梁爽老师日语精讲精练：第31课.md", 200, "既然",
 "Since you're living in Japan, you'd better be able to speak some Japanese.",
 "Since you're living in Japan, you'd better be able to speak some Japanese."),
("markdown/中级上/11.梁爽老师日语精讲精练：第31课.md", 211, "不使用五",
 "Don't use the 5-point rating scale; replace it with questions that are easier to answer.",
 "Don't lower the evaluation bar; replace them with questions that are easier to answer."),
("markdown/中级上/11.梁爽老师日语精讲精练：第31课.md", 234, "你要是知道",
 "If you knew that, I wish you had told me earlier.",
 "If that was the case, you should have told me earlier."),
("markdown/中级上/11.梁爽老师日语精讲精练：第31课.md", 263, "把",
 "When I enlarged the text display on my phone, it became easier to read.",
 "Enlarging the phone's font makes it easier to read."),
("markdown/中级上/11.梁爽老师日语精讲精练：第31课.md", 280, "全都是多亏佐藤你教我。",
 "It's all thanks to you, Sato, for teaching me.", None),
# ---- 中级上 32课 ----
("markdown/中级上/13.梁爽老师日语精讲精练：第32课.md", 200, "我很",
 "I wanted to get some exercise, so I bought a pair of running shoes.", None),
("markdown/中级上/13.梁爽老师日语精讲精练：第32课.md", 258, "我把credit card",
 "I lost my credit card, and now I'm in trouble.",
 "I lost it, and now I'm in trouble."),
("markdown/中级上/13.梁爽老师日语精讲精练：第32课.md", 289, "1天都不休息地拼命工作。",
 "(He) works incredibly hard without taking a single day off.", None),
# ---- 中级上 27课 ----
("markdown/中级上/3.梁爽老师日语精讲精练：第27课.md", 228, "想去一次日本。",
 "I want to go to Japan at least once.", None),
# ---- 中级上 28课 ----
("markdown/中级上/5.梁爽老师日语精讲精练：第28课.md", 250, "知道了。", "Got it.", None),
("markdown/中级上/5.梁爽老师日语精讲精练：第28课.md", 252, "已",
 "It's already covered in scratches, but because it's so precious to me, I can't throw it away.",
 "It's already full of scratches, but because it's so precious to me, I can't bring myself to throw it away."),
("markdown/中级上/5.梁爽老师日语精讲精练：第28课.md", 311, "最好不要喝太thick; dense; strong (flavor)",
 "It's best not to drink coffee that's too strong.", "coffee."),
# ---- 中级上 29课 ----
("markdown/中级上/7.梁爽老师日语精讲精练：第29课.md", 250, "我作",
 "As a husband, and as a father, I will continue to cherish this family.", None),
("markdown/中级上/7.梁爽老师日语精讲精练：第29课.md", 277, "要是想取",
 "If you want to get good grades, you mustn't slack off on your studies.",
 "If you want good grades, you mustn't slack off on your studies."),
# ---- 中级上 30课 ----
("markdown/中级上/9.梁爽老师日语精讲精练：第30课.md", 182, "要是女孩子的",
 "If it's a girl, I want to name her “Yuko”.",
 "If it's a girl, I want to name her \"Yuko\"."),
("markdown/中级上/9.梁爽老师日语精讲精练：第30课.md", 222, "不",
 "If stairs are difficult for you, please use this elevator.",
 "If stairs are inconvenient, please use this elevator."),
# ---- 中级下 33课 ----
("markdown/中级下/1.梁爽老师日语精讲精练：第33课.md", 239, "能",
 "Few people can speak Japanese as fluently as Li.",
 "Few people can speak Japanese as fluently as Li."),
("markdown/中级下/1.梁爽老师日语精讲精练：第33课.md", 266, "只要他",
 "As long as he is by my side, I can feel at ease.",
 "As long as you're by my side, I can feel at ease."),
# ---- 中级下 38课 ----
("markdown/中级下/11.梁爽老师日语精讲精练：第38课.md", 285, "\"尽力\" means, literally,",
 "“尽力” means, literally, “to exert one's strength to the fullest”.",
 "\"to exert one's strength to the fullest\"."),
("markdown/中级下/11.梁爽老师日语精讲精练：第38课.md", 346, "我怕狗。", "I'm afraid of dogs.", None),
("markdown/中级下/11.梁爽老师日语精讲精练：第38课.md", 348, "那孩子怕狗。", "That child is scared of dogs.", None),
("markdown/中级下/11.梁爽老师日语精讲精练：第38课.md", 402, "好想去一次南美啊。",
 "I want to go to South America at least once.", None),
# ---- 中级下 39课 ----
("markdown/中级下/13.梁爽老师日语精讲精练：第39课.md", 381, "（我的名字）叫李由",
 "(My name) is Li Yuka.", None),
("markdown/中级下/13.梁爽老师日语精讲精练：第39课.md", 532, "希望明天不要下雨。",
 "I hope it doesn't rain tomorrow.", None),
# ---- 中级下 34课 ----
("markdown/中级下/3.梁爽老师日语精讲精练：第34课.md", 248, "（我）",
 "(I) was asked all sorts of things by a friend about job hunting.",
 "I was asked by a friend about all sorts of things regarding employment."),
("markdown/中级下/3.梁爽老师日语精讲精练：第34课.md", 261, "我叫了我妹妹。",
 "I called my younger sister.", None),
("markdown/中级下/3.梁爽老师日语精讲精练：第34课.md", 277, "特意留的蛋糕被",
 "The cake I had saved was eaten by my younger sister.",
 "was eaten by my younger sister."),
("markdown/中级下/3.梁爽老师日语精讲精练：第34课.md", 301, "昨晚隔壁",
 "Last night, the neighbor's child kept crying, so I didn't sleep well.",
 "the child kept crying, so I didn't sleep well."),
("markdown/中级下/3.梁爽老师日语精讲精练：第34课.md", 356, "明",
 "Whether I can take tomorrow's club activity off — who should I ask?",
 "whether I can take tomorrow's club activity off — who should I ask?"),
("markdown/中级下/3.梁爽老师日语精讲精练：第34课.md", 363, "即使不",
 "Even if my parents don't approve, I will do what I want to do.",
 "even if my parents don't approve, I will do what I want to do."),
# ---- 中级下 35课 ----
("markdown/中级下/5.梁爽老师日语精讲精练：第35课.md", 257, "（我）",
 "My heart is weak, so please don't scare me.",
 "my heart is weak, so please don't scare me."),
("markdown/中级下/5.梁爽老师日语精讲精练：第35课.md", 276, "普",
 "An ordinary office worker can't possibly afford a luxury apartment.",
 "an ordinary office worker can't possibly afford a luxury apartment."),
# ---- 中级下 36课 ----
("markdown/中级下/7.梁爽老师日语精讲精练：第36课.md", 152, "（我）",
 "It's not that I can't cook. I just don't have time to cook.",
 "It's not that I can't cook. I just don't have time to cook."),
("markdown/中级下/7.梁爽老师日语精讲精练：第36课.md", 175, "大家都在to hit; to strike; to fight",
 "Everyone has their umbrella up, so it should still be raining.",
 "umbrellas, so it should still be raining."),
("markdown/中级下/7.梁爽老师日语精讲精练：第36课.md", 214, "在",
 "When it comes to dieting, I think what matters is having a strong will.",
 "when it comes to dieting, I think what matters is having a strong will."),
# ---- 中级下 37课 ----
("markdown/中级下/9.梁爽老师日语精讲精练：第37课.md", 333, "和boyfriend",
 "After repeated quarrels with my boyfriend, I ended up breaking up with him.", None),
("markdown/中级下/9.梁爽老师日语精讲精练：第37课.md", 395, "突然看",
 "When I suddenly looked outside — before I knew it, it had started raining.",
 "and looked outside — before I knew it, it had started raining."),
# ---- 初级上 5课 ----
("markdown/初级上/1.梁爽老师日语精讲精练：第5课.md", 139, "我是山田。", "I'm Yamada.", None),
("markdown/初级上/1.梁爽老师日语精讲精练：第5课.md", 143, "中村是日本人。", "Nakamura is Japanese.", None),
("markdown/初级上/1.梁爽老师日语精讲精练：第5课.md", 181, "是那位。", "It's that person over there.", None),
("markdown/初级上/1.梁爽老师日语精讲精练：第5课.md", 265, "我就是李由加。", "I'm Li Yuka.", None),
("markdown/初级上/1.梁爽老师日语精讲精练：第5课.md", 285, "（他）是佐藤。", "(He) is Sato.", None),
("markdown/初级上/1.梁爽老师日语精讲精练：第5课.md", 297, "是的。", "Yes, that's right.", None),
("markdown/初级上/1.梁爽老师日语精讲精练：第5课.md", 321, "我是〇〇。", "I'm ____.", None),
("markdown/初级上/1.梁爽老师日语精讲精练：第5课.md", 323, "我叫〇〇。", "My name is ____. (humble)", None),
("markdown/初级上/1.梁爽老师日语精讲精练：第5课.md", 371, "乔治是日本人。", "George is Japanese.", None),
# ---- 初级上 10课 ----
("markdown/初级上/13.梁爽老师日语精讲精练：第10课.md", 326, "好啊。", "Sounds good.", None),
("markdown/初级上/13.梁爽老师日语精讲精练：第10课.md", 344, "不好意思。我不太方",
 "Sorry. It's a bit... Next time, let's definitely go together.",
 "convenient. Next time for sure (let's go together)."),
("markdown/初级上/13.梁爽老师日语精讲精练：第10课.md", 385, "是啊。", "That's right.", None),
# ---- 初级上 12课 ----
("markdown/初级上/19.梁爽老师日语精讲精练：第12课.md", 284, "完全OK。", "Totally OK.", None),
("markdown/初级上/19.梁爽老师日语精讲精练：第12课.md", 297, "真不愧是",
 "As expected of three stars. The food is tasty and beautifully presented. The service is good too.",
 "Three stars. The food is tasty and beautifully presented. The service is good too."),
# ---- 初级上 13课 ----
("markdown/初级上/21.梁爽老师日语精讲精练：第13课.md", 152, "有。", "Yes.", None),
("markdown/初级上/21.梁爽老师日语精讲精练：第13课.md", 193, "我就是。", "Yes, that's me.", None),
("markdown/初级上/21.梁爽老师日语精讲精练：第13课.md", 287, "好。", "Sure.", None),
("markdown/初级上/21.梁爽老师日语精讲精练：第13课.md", 301, "慢走。", "See you later.", None),
# ---- 初级上 14课 ----
("markdown/初级上/23.梁爽老师日语精讲精练：第14课.md", 221, "13 日有中",
 "On the 13th, there's Nakamura's birthday party.", None),
("markdown/初级上/23.梁爽老师日语精讲精练：第14课.md", 293, "差不多回去吧。", "Let's head back soon.", None),
("markdown/初级上/23.梁爽老师日语精讲精练：第14课.md", 301, "好啊。", "Sounds good.", None),
# ---- 初级上 15课 ----
("markdown/初级上/25.梁爽老师日语精讲精练：第15课.md", 135, "（我）often; frequently",
 "I often send emails, but I don't write letters much.",
 "I send emails, but I don't write letters much."),
("markdown/初级上/25.梁爽老师日语精讲精练：第15课.md", 247, "明天就是",
 "The performance is tomorrow. We won't be ready in time.",
 "It's the real performance soon. We won't have time to prepare."),
# ---- 初级上 16课 ----
("markdown/初级上/27.梁爽老师日语精讲精练：第16课.md", 130, "昨天去中村家玩了。",
 "Yesterday I went to Nakamura's place to hang out.", None),
("markdown/初级上/27.梁爽老师日语精讲精练：第16课.md", 132, "出去散散步吧。",
 "Shall we go out for a walk?", None),
("markdown/初级上/27.梁爽老师日语精讲精练：第16课.md", 240, "在日本富士山是最高",
 "In Japan, Mt. Fuji is the highest, right?", "right?"),
("markdown/初级上/27.梁爽老师日语精讲精练：第16课.md", 242, "是啊。", "That's right.", None),
# ---- 初级上 6课 ----
("markdown/初级上/3.梁爽老师日语精讲精练：第6课.md", 293, "辛苦啦。",
 "Thanks for your hard work.", None),
("markdown/初级上/3.梁爽老师日语精讲精练：第6课.md", 300, "辛苦啦。",
 "Thanks for your hard work.", None),
# ---- 初级上 7课 ----
("markdown/初级上/5.梁爽老师日语精讲精练：第7课.md", 218, "地震不只一次。",
 "It won't be just one earthquake.", None),
("markdown/初级上/5.梁爽老师日语精讲精练：第7课.md", 244, "是的。", "Yes, that's right.", None),
("markdown/初级上/5.梁爽老师日语精讲精练：第7课.md", 309, "嗯。", "Yeah.", None),
("markdown/初级上/5.梁爽老师日语精讲精练：第7课.md", 317, "我家有三口人。",
 "I have a family of three.", None),
("markdown/初级上/5.梁爽老师日语精讲精练：第7课.md", 321, "我家有三口人。",
 "My family has three people.", None),
# ---- 初级上 8课 ----
("markdown/初级上/7.梁爽老师日语精讲精练：第8课.md", 141, "我要啤酒。", "A beer, please.", None),
("markdown/初级上/7.梁爽老师日语精讲精练：第8课.md", 184, "我要小杯的。", "A small (size), please.", None),
("markdown/初级上/7.梁爽老师日语精讲精练：第8课.md", 186, "我要小杯的咖啡。", "A small coffee, please.", None),
("markdown/初级上/7.梁爽老师日语精讲精练：第8课.md", 222, "咖啡您要什么cup; glass; counter for cups",
 "What size would you like for your hot coffee?", "would you like?"),
("markdown/初级上/7.梁爽老师日语精讲精练：第8课.md", 295, "我要啤酒。", "A beer, please.", None),
("markdown/初级上/7.梁爽老师日语精讲精练：第8课.md", 315, "好的。", "Certainly.", None),
("markdown/初级上/7.梁爽老师日语精讲精练：第8课.md", 321, "（我要）刷卡。", "I'll pay by card.", None),
("markdown/初级上/7.梁爽老师日语精讲精练：第8课.md", 327, "找您110日元。", "Here is your 10 yen change.", None),
("markdown/初级上/7.梁爽老师日语精讲精练：第8课.md", 333, "好好休息哦。", "Please get some good rest.", None),
("markdown/初级上/7.梁爽老师日语精讲精练：第8课.md", 334, "好的。", "Got it.", None),
("markdown/初级上/7.梁爽老师日语精讲精练：第8课.md", 336, "明天也拜托你啦。", "I'm counting on you tomorrow too.", None),
("markdown/初级上/7.梁爽老师日语精讲精练：第8课.md", 343, "我刷卡。", "I'll pay by card.", None),
("markdown/初级上/7.梁爽老师日语精讲精练：第8课.md", 345, "好的。", "Certainly.", None),
("markdown/初级上/7.梁爽老师日语精讲精练：第8课.md", 354, "是的。", "Yes, that's right.", None),
("markdown/初级上/7.梁爽老师日语精讲精练：第8课.md", 356, "790日元。", "That's 790 yen.", None),
# ---- 初级上 9课 ----
("markdown/初级上/9.梁爽老师日语精讲精练：第9课.md", 202, "好冷啊。", "It's cold, isn't it?", None),
("markdown/初级上/9.梁爽老师日语精讲精练：第9课.md", 222, "很有意思。", "It's really interesting.", None),
("markdown/初级上/9.梁爽老师日语精讲精练：第9课.md", 226, "都是托中村的福呢。",
 "It's all thanks to Nakamura.", None),
("markdown/初级上/9.梁爽老师日语精讲精练：第9课.md", 329, "托中村小姐的福呢。",
 "It's all thanks to you, Nakamura. Thank you for everything.",
 "Thank you for all your help."),
("markdown/初级上/9.梁爽老师日语精讲精练：第9课.md", 353, "好啊。", "Sounds good.", None),
# ---- 初级下 22课 ----
("markdown/初级下/11.梁爽老师日语精讲精练：第22课.md", 132, "去朋友家",
 "When we went to a friend's place to hang out, everyone made dumplings together.",
 "when (we) went to hang out, everyone made dumplings together."),
# ---- 初级下 23课 ----
("markdown/初级下/13.梁爽老师日语精讲精练：第23课.md", 288, "《海",
 "“One Piece” is popular not only in Japan but overseas as well.",
 "One Piece is popular not only in Japan but overseas as well."),
# ---- 初级下 24课 ----
("markdown/初级下/15.梁爽老师日语精讲精练：第24课.md", 149, "我不能吃辣的。",
 "I don't eat spicy food.", None),
("markdown/初级下/15.梁爽老师日语精讲精练：第24课.md", 151, "我不能吃辣的。",
 "I can't eat spicy food.", None),
("markdown/初级下/15.梁爽老师日语精讲精练：第24课.md", 158, "我不能吃辣。",
 "I can't eat spicy food.", None),
("markdown/初级下/15.梁爽老师日语精讲精练：第24课.md", 246, "要不要一起去吃牛",
 "Shall we go out for steak or something together?", "(fragment) Row?"),
("markdown/初级下/15.梁爽老师日语精讲精练：第24课.md", 263, "要",
 "I have a lot to do, so I'd like someone to help me.",
 "there is a lot to do, and I hope someone can help me."),
("markdown/初级下/15.梁爽老师日语精讲精练：第24课.md", 304, "中村好像有男朋友了。",
 "It seems Nakamura has got a boyfriend.", None),
("markdown/初级下/15.梁爽老师日语精讲精练：第24课.md", 321, "他",
 "He said he'd be a little late and told us to start without him.",
 "He said he'd be a little late and told us to start without him."),
# ---- 初级下 25课 ----
("markdown/初级下/17.梁爽老师日语精讲精练：第25课.md", 143, "信任很重要。", "Trust is important.", None),
("markdown/初级下/17.梁爽老师日语精讲精练：第25课.md", 227, "好像",
 "It seems to be about time, so let's call it a day.",
 "It's about time, so let's call it a day."),
("markdown/初级下/17.梁爽老师日语精讲精练：第25课.md", 241, "中",
 "Nakamura is kind, and to Li, she is like an older sister.",
 "Nakamura is kind, and to Xiao Li she is like an older sister."),
# ---- 初级下 18课 ----
("markdown/初级下/3.梁爽老师日语精讲精练：第18课.md", 156, "她送了我非常漂亮的手帕。",
 "She gave me a very beautiful handkerchief.", None),
("markdown/初级下/3.梁爽老师日语精讲精练：第18课.md", 182, "想吃好吃的。",
 "I want to eat something delicious.", None),
("markdown/初级下/3.梁爽老师日语精讲精练：第18课.md", 233, "我要啤酒。", "I'll have a beer.", None),
("markdown/初级下/3.梁爽老师日语精讲精练：第18课.md", 235, "我不知",
 "I didn't know which color was best, so I got one of each color.",
 "I didn't know which color was best, so I chose one of each color."),
("markdown/初级下/3.梁爽老师日语精讲精练：第18课.md", 240, "我想",
 "I want ramen. Let's have ramen.", "Ramen. Let's have ramen."),
# ---- 初级下 19课 ----
("markdown/初级下/5.梁爽老师日语精讲精练：第19课.md", 240, "今天辛苦啦。",
 "Thanks for your hard work today. Please get some good rest.",
 "Please get some good rest."),
# ---- 初级下 20课 ----
("markdown/初级下/7.梁爽老师日语精讲精练：第20课.md", 148, "天黑了。", "It's gotten dark outside.", None),
("markdown/初级下/7.梁爽老师日语精讲精练：第20课.md", 150, "玻璃窗破了。", "The glass window is broken.", None),
("markdown/初级下/7.梁爽老师日语精讲精练：第20课.md", 152, "我哥哥已婚。", "My older brother is married.", None),
("markdown/初级下/7.梁爽老师日语精讲精练：第20课.md", 219, "我哥哥想做that",
 "My older brother wants to become the chef of that restaurant.",
 "chef of that restaurant."),
("markdown/初级下/7.梁爽老师日语精讲精练：第20课.md", 228, "乔治to want",
 "George wants Murakami Natsuki's autograph.",
 "Murakami Natsuki's autograph."),
("markdown/初级下/7.梁爽老师日语精讲精练：第20课.md", 244, "今晚的星星可以看得很清楚。",
 "The stars are clearly visible tonight.", None),
# ---- 初级下 21课 ----
("markdown/初级下/9.梁爽老师日语精讲精练：第21课.md", 142, "可以的。", "Sure, go ahead.", None),
("markdown/初级下/9.梁爽老师日语精讲精练：第21课.md", 169, "小朋友不可以晚上在",
 "Children must not play outside until late at night.",
 "(must not) play outside until late."),
("markdown/初级下/9.梁爽老师日语精讲精练：第21课.md", 186, "在",
 "In Japan, seatbelts must be fastened even in the back seat.",
 "In Japan, seatbelts must be fastened even in the back seat of a car."),
("markdown/初级下/9.梁爽老师日语精讲精练：第21课.md", 199, "因",
 "Since I've finished writing the report, I can present it to everyone tomorrow.", None),
("markdown/初级下/9.梁爽老师日语精讲精练：第21课.md", 212, "日本的小朋友plural suffix for people; ...-tachi",
 "Japanese children write compositions using only hiragana.",
 "Write the composition using only hiragana."),
("markdown/初级下/9.梁爽老师日语精讲精练：第21课.md", 232, "可以。", "I'm fine, thanks.", None),
# ---- 高级 40课 ----
("markdown/高级/1.梁爽老师日语精讲精练：第40课.md", 512, "如",
 "If you want to experience an atmosphere unique to Japan, Kyoto is recommended.",
 "If you want to experience an atmosphere unique to Japan, Kyoto is a good choice."),
("markdown/高级/1.梁爽老师日语精讲精练：第40课.md", 524, "按照政府的",
 "In line with the government's policy, (we) are striving to conserve energy.",
 "... policy, (we) will work hard to conserve energy."),
]

by_file = {}
for f, ln, old, new, nxt in F:
    by_file.setdefault(f, []).append((ln, old, new, nxt))

ok, fail = 0, []
for f, ops in by_file.items():
    p = pathlib.Path(f)
    lines = p.read_text(encoding="utf-8").splitlines(keepends=True)
    for ln, old, new, nxt in sorted(ops, key=lambda o: -o[0]):
        cur = lines[ln-1].rstrip("\n")
        if "／" not in cur:
            fail.append((f, ln, old, "no ／: " + cur[:80])); continue
        head, tail = cur.rsplit("／", 1)
        if tail.strip() != old:
            fail.append((f, ln, old, "tail=" + tail.strip()[:80])); continue
        new_line = head + "／" + new + "\n"
        if nxt is not None:
            if lines[ln].strip() == nxt.strip():
                lines[ln-1:ln+1] = [new_line]
            else:
                fail.append((f, ln, old, "next=" + lines[ln].strip()[:80])); continue
        else:
            lines[ln-1] = new_line
        ok += 1
    p.write_text("".join(lines), encoding="utf-8")

print(f"applied: {ok}/{len(F)}, failed: {len(fail)}")
for f, ln, old, why in fail:
    print(f"FAILED {f}:{ln} [{old}] -> {why}")
