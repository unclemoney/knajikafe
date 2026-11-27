# Final cleanup: rejoin exploded vocab entries, fill empty glosses, fix remaining
# Chinese glosses, translate etymology tags. Line numbers are pre-edit; per-file
# operations are applied bottom-up so numbering stays valid during the edit.
import pathlib

OPS = {
 "markdown/中级上/3.梁爽老师日语精讲精练：第27课.md": [
   ("block", 74, 75, ["continuous", "6 どんどん① 〔副〕"],
    ["6 どんどん① 〔副〕 continuously; (of things) proceeding smoothly N4"]),
 ],
 "markdown/中级下/1.梁爽老师日语精讲精练：第33课.md": [
   ("block", 77, 81, ["千と千尋の神隠し", "Spirited Away", "せんとちひろのかみかくし", "Hayao Miyazaki)", "①＋⓪＋③"],
    ["8 千と千尋の神隠し（せんとちひろのかみかくし）①＋⓪＋③ 〔专〕 Spirited Away (Japanese animated film directed by Hayao Miyazaki)"]),
   ("block", 84, 86, ["a scene (of a film), one", "11 ワンシーン", "(counter for) shots; scenes"],
    ["11 ワンシーン（one scene）③ 〔名〕 a scene (of a film); one shot/scene"]),
   ("block", 99, 100, ["for some reason", "22 なんだか① 〔副〕"],
    ["22 なんだか① 〔副〕 for some reason; somehow; involuntarily N1"]),
 ],
 "markdown/中级下/11.梁爽老师日语精讲精练：第38课.md": [
   ("block", 166, 168, ["(with negative) no matter how", "40 到底", "(with negative) ...at all"],
    ["40 到底（とうてい）⓪ 〔副〕 (with negative) no matter how...; ...at all N1"]),
 ],
 "markdown/中级下/13.梁爽老师日语精讲精练：第39课.md": [
   ("block", 195, 196, ["actual results; achievements", "56 実績"],
    ["56 実績（じっせき）⓪ 〔名〕 actual results; achievements N3"]),
   ("block", 225, 226, ["honorific form", "1 いらっしゃる④"],
    ["1 いらっしゃる④ 〔自Ⅰ〕 honorific form of “行く・来る・いる” N4"]),
   ("block", 230, 231, ["honorific form", "4 召し上がる"],
    ["4 召し上がる（めしあがる）⓪④ 〔他Ⅰ〕 honorific form of “食べる・飲む” N4"]),
   ("block", 276, 279, ["しゅう", "job-hunting", "45 就活", "しょくかつどう"],
    ["45 就活（しゅうかつ）⓪ 〔名〕 job-hunting activities of graduating students (abbreviation of “就職活動”)"]),
 ],
 "markdown/中级下/3.梁爽老师日语精讲精练：第34课.md": [
   ("block", 129, 131, ["Natsume Soseki", "18 夏目漱石", "ry figure)"],
    ["18 夏目漱石（なつめそうせき）④ 〔专〕 Natsume Soseki (Japanese literary figure)"]),
   ("block", 132, 134, ["スズメの戸締り", "19 〔专〕", "⓪＋② film)"],
    ["19 スズメの戸締り（すずめのとじまり）⓪＋② 〔专〕 Suzume (Japanese animated film)"]),
   ("block", 135, 137, ["Shinkai Makoto", "20 新海誠", "film director)"],
    ["20 新海誠（しんかいまこと）①＋⓪ 〔专〕 Shinkai Makoto (Japanese animated film director)"]),
   ("block", 460, 462, ["(student slang) social gathering; tea", "17 コンパ①", "party"],
    ["17 コンパ① 〔名〕 (student slang) social gathering; tea party"]),
 ],
 "markdown/中级下/5.梁爽老师日语精讲精练：第35课.md": [
   ("block", 90, 92, ["(followed by a negative)", "7 別に", "ably"],
    ["7 別に（べつに）⓪ 〔副〕 (followed by a negative) particularly; remarkably"]),
 ],
 "markdown/中级下/7.梁爽老师日语精讲精练：第36课.md": [
   ("block", 93, 95, ["to sound out", "6 打診", "tude)"],
    ["6 打診（だしん）⓪ 〔名、他Ⅲ〕 to sound out (the other person's thoughts and attitude) N1"]),
 ],
 "markdown/初级上/1.梁爽老师日语精讲精练：第5课.md": [
   ("sub", 87, "（含敬意）人 N5", "person (respectful) N5"),
   ("block", 83, 85, ["came", "21 来ました", "the polite past form of a verb"],
    ["21 来ました（きました）② ［自Ⅲ］ came (“-ました” is the polite past form of a verb) N5"]),
   ("block", 115, 117, ["for teachers, doctors, lawyers", "9 先生", "honorific title for a specialist"],
    ["9 先生（せんせい）③ ［名］ honorific title for specialists (teachers, doctors, lawyers, etc.) N5"]),
 ],
 "markdown/初级上/13.梁爽老师日语精讲精练：第10课.md": [
   ("sub", 71, "[副] 一定 N4", "[副] by all means; certainly N4"),
   ("block", 405, 407, ["Tokyo Skytree", "16 スカイツリー", "(broadcasting) tower"],
    ["16 スカイツリー（sky tree）⑤ [固名] Tokyo Skytree (freestanding broadcasting tower)"]),
 ],
 "markdown/初级上/17.梁爽老师日语精讲精练：第11课.md": [
   ("sub", 62, "想要 N5", "to want N5"),
   ("sub", 80, "(model = 型号)", "(= model; type)"),
   ("sub", 344, " (also: working adult, as opposed to a student)", ""),
   ("block", 345, 347, ["working adult; member of society", "4 社会人", "(a person who has entered society"],
    ["4 社会人（しゃかいじん）② [名] working adult; member of society (a person who has entered society and started working, as opposed to a student)"]),
 ],
 "markdown/初级上/21.梁爽老师日语精讲精练：第13课.md": [
   ("block", 113, 115, ["slowly; gradually;", "21 そろそろ", "soon; almost"],
    ["21 そろそろ① [副] slowly; gradually; soon; almost N4"]),
 ],
 "markdown/初级上/23.梁爽老师日语精讲精练：第14课.md": [
   ("block", 401, 402, ["barely; forcibly", "8 無理"],
    ["8 無理（むり）① [名、形Ⅱ] unreasonable; impossible; forced N3"]),
 ],
 "markdown/初级上/5.梁爽老师日语精讲精练：第7课.md": [
   ("block", 83, 85, ["for males younger than oneself", "21 -君（くん）", "-kun (suffix for"],
    ["21 -君（くん） [接尾] -kun (suffix for names of boys/younger men) N4"]),
 ],
 "markdown/初级上/9.梁爽老师日语精讲精练：第9课.md": [
   ("block", 64, 65, ["attached after a name as an intimate", "1 –ちゃん [接尾] N4"],
    ["1 –ちゃん [接尾] -chan (attached after a name as an intimate form of address) N4"]),
   ("block", 94, 96, ["um... (used mid-speech", "22 ええと⓪", "(used during a brief pause"],
    ["22 ええと⓪ [感] um... (used mid-speech, during a brief pause or while thinking) N5"]),
   ("sub", 100, "（一起做……）", "(doing ... together)"),
   ("sub", 382, "漂亮的 N5", "pretty; beautiful N5"),
 ],
 "markdown/初级下/13.梁爽老师日语精讲精练：第23课.md": [
   ("block", 91, 93, ["economic; (newspaper) econo-", "24 経済面", "mics section"],
    ["24 経済面（けいざいめん）③ 〔名〕 economic; (newspaper) economics section"]),
 ],
 "markdown/初级下/3.梁爽老师日语精讲精练：第18课.md": [
   ("sub", 101, "桔子 N4", "mandarin orange N4"),
   ("sub", 102, "（日式）拉面 N3", "ramen (Japanese-style) N3"),
 ],
 "markdown/初级下/17.梁爽老师日语精讲精练：第25课.md": [
   ("block", 86, 88, ["30 カルチャーショック（culture", "〔名〕 culture shock N2", "shock）⑤"],
    ["30 カルチャーショック（culture shock）⑤ 〔名〕 culture shock N2"]),
   ("block", 111, 113, ["laundry to be washed or already", "19 洗濯物", "clothes; laundry items"],
    ["19 洗濯物（せんたくもの）⓪ 〔名〕 laundry; clothes to be washed or already washed"]),
   ("block", 286, 288, ["annual traditional festive ev-", "1 年中行事", "ents"],
    ["1 年中行事（ねんじゅうぎょうじ）⑤ 〔名〕 annual traditional festive events"]),
   ("block", 305, 307, ["(followed by negation) almost; nearly", "16 めったに", "(not) ... (negation marker)"],
    ["16 めったに（【滅多に】）① 〔副〕 (used with negation) rarely; hardly ever N3"]),
   ("block", 310, 312, ["friendship; (interpersonal)", "19 仲（なか）", "relationship"],
    ["19 仲（なか）① 〔名〕 friendship; (interpersonal) relationship N3"]),
 ],
 "markdown/高级/1.梁爽老师日语精讲精练：第40课.md": [
   ("block", 216, 217, ["honorific of", "50 越す"],
    ["50 越す（こす）⓪ 〔自Ⅰ〕 (prefixed with “お”) honorific of “行く・来る”"]),
   ("block", 222, 224, ["to sit; to rest a part of one's body", "54 かける②", "on something"],
    ["54 かける② 〔他Ⅱ〕 to sit; to rest a part of one's body on something"]),
   ("block", 296, 297, ["Yamanote Line (a JR railway line in Japan)", "46 山手線"],
    ["46 山手線（やまのてせん）⓪ 〔名〕 Yamanote Line (a JR railway line in Japan)"]),
 ],
 "markdown/高级/3.梁爽老师日语精讲精练：第41课.md": [
   ("block", 101, 102, ["non-verbal (communication)", "4 非言語"],
    ["4 非言語（ひげんご）② 〔名〕 non-verbal (communication) such as facial expressions and gestures"]),
   ("block", 104, 106, ["to commute (by vehicle)", "5 通じる", "to let through"],
    ["5 通じる（つうじる）⓪ 〔自他Ⅱ〕 to commute (by vehicle); to be well versed in; to let through; to pass (a bill, etc.)"]),
   ("block", 112, 114, ["to accompany; indicates that both", "11 同士", "same kind of relationship"],
    ["11 同士（どうし）① 〔名、接尾〕 to accompany; indicates that both parties have the same kind of relationship"]),
   ("block", 131, 133, ["... kind of (method, means,", "26 -通り", "etc.)"],
    ["26 -通り（とおり） 〔接尾〕 ... kind of (method, means, etc.)"]),
   ("block", 324, 326, ["elderly people (generally those 65", "134 高齢者", "and older)"],
    ["134 高齢者（こうれいしゃ）③ 〔名〕 elderly people (generally those 65 and older)"]),
   ("block", 354, 356, ["an indispensable thing; an accesso-", "159 付き物", "ry"],
    ["159 付き物（つきもの）② 〔名〕 an indispensable thing; an accessory"]),
 ],
 "markdown/高级/7.梁爽老师日语精讲精练：第43课.md": [
   ("block", 461, 463, ["to drive into; to be absorbed in", "56 打ち込む", "(the target); to break into"],
    ["56 打ち込む (うちこむ) ③ 〔他Ⅰ〕 to drive into; to be absorbed in; to hit (the target); to break into"]),
   ("block", 531, 533, ["エスプレッソ（【意】", "118 〔名〕 espresso coffee", "espresso）④"],
    ["118 エスプレッソ（[Italian] espresso）④ 〔名〕 espresso coffee"]),
 ],
 "markdown/高级/8.梁爽老师日语精讲精练：第44课.md": [
   ("block", 553, 555, ["(Buddhism) the realm beyond", "10 彼岸", "Higan-e"],
    ["10 彼岸（ひがん）⓪ 〔名〕 (Buddhism) the realm beyond life and death; enlightenment; Higan-e (equinox Buddhist service)"]),
   ("block", 583, 585, ["a Japanese confection; Domyoji (located in", "35 道明寺", "Fujiidera, Osaka Prefecture)"],
    ["35 道明寺（どうみょうじ）⓪① 〔名、专〕 a Japanese confection; Domyoji (located in Fujiidera, Osaka Prefecture)"]),
   ("block", 607, 609, ["Saigyo (from the late Heian", "54 西行", "Kamakura period, a poet-monk)"],
    ["54 西行（さいぎょう）① 〔专〕 Saigyo (poet-monk from the late Heian to the early Kamakura period)"]),
 ],
 "markdown/高级/9.梁爽老师日语精讲精练：第45课.md": [
   ("sub", 303, "6 広大（こうだい）⓪ 〔形Ⅱ〕", "6 広大（こうだい）⓪ 〔形Ⅱ〕 vast; extensive"),
 ],
 "markdown/入门20讲/4.梁爽老师日语精讲精练：第4课.md": [
   ("block", 58, 59, ["チ ー ズ バ ー ガ ー", "burger）④"],
    ["3 チーズバーガー（cheeseburger）④ 〔名〕 cheeseburger"]),
 ],
}

ETYMOLOGY = {"【法】": "[French]", "【荷】": "[Dutch]", "【德】": "[German]",
             "【意】": "[Italian]", "【葡】": "[Portuguese]", "【芬】": "[Finnish]"}

ok, fail = 0, []
for f, ops in OPS.items():
    p = pathlib.Path(f)
    lines = p.read_text(encoding="utf-8").splitlines(keepends=True)
    # apply bottom-up
    for op in sorted(ops, key=lambda o: -o[1]):
        if op[0] == "sub":
            _, ln, old, new = op
            cur = lines[ln-1].rstrip("\n")
            if old in cur:
                lines[ln-1] = lines[ln-1].replace(old, new, 1)
                ok += 1
            else:
                fail.append((f, ln, old, cur[:100]))
        else:
            _, start, end, subs, newlines = op
            seg = [lines[i].rstrip("\n") for i in range(start-1, end)]
            if all(s in seg[k] for k, s in enumerate(subs)):
                lines[start-1:end] = [nl + "\n" for nl in newlines]
                ok += 1
            else:
                fail.append((f, start, str(subs), " || ".join(seg)[:150]))
    p.write_text("".join(lines), encoding="utf-8")

# etymology tags, global (after block ops so the espresso line is already rebuilt)
etym_count = 0
for p in pathlib.Path("markdown").rglob("*.md"):
    if p.name == "_conversion_report.md":
        continue
    t = p.read_text(encoding="utf-8")
    orig = t
    for old, new in ETYMOLOGY.items():
        etym_count += t.count(old)
        t = t.replace(old, new)
    if t != orig:
        p.write_text(t, encoding="utf-8")

print(f"ops applied: {ok}, failed: {len(fail)}, etymology tags replaced: {etym_count}")
for f, ln, want, cur in fail:
    print(f"FAILED {f}:{ln} wanted {cur!r} <- {ln}")
