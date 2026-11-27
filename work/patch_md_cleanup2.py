# Final rejoin pass #2: split POS brackets, two-line entries, stray tags,
# and the last 6 bracketless Chinese glosses. Bottom-up per file.
import pathlib

OPS = {
 "markdown/初级上/1.梁爽老师日语精讲精练：第5课.md": [
   ("sub", 70, "拜托 N5", "please (a request); I'm counting on you N5"),
   ("sub", 78, "早上好 N5", "good morning N5"),
   ("block", 395, 397, ["東京大学", "19 ［专］", "⑤"],
    ["19 東京大学（とうきょうだいがく）⑤ ［专］ The University of Tokyo"]),
 ],
 "markdown/初级上/21.梁爽老师日语精讲精练：第13课.md": [
   ("sub", 78, "我走了 N3", "I'm off; see you later (said when leaving home) N3"),
 ],
 "markdown/初级上/3.梁爽老师日语精讲精练：第6课.md": [
   ("sub", 344, "恭喜", "congratulations"),
 ],
 "markdown/初级上/7.梁爽老师日语精讲精练：第8课.md": [
   ("sub", 87, "遵命 N2", "certainly; very well (deferential) N2"),
 ],
 "markdown/高级/1.梁爽老师日语精讲精练：第40课.md": [
   ("sub", 204, "在意", "to be on one's mind; to be bothered by"),
 ],
 "markdown/中级下/1.梁爽老师日语精讲精练：第33课.md": [
   ("block", 86, 88, ["Acorns and the Wildcat", "17 〔专〕", "（どんぐりとやまねこ）①＋⓪"],
    ["17 どんぐりと山猫（どんぐりとやまねこ）①＋⓪ 〔专〕 Acorns and the Wildcat (a fairy tale by Miyazawa Kenji)"]),
   ("block", 142, 144, ["ちびまる子ちゃん", "25 〔专〕", "（ちびまるこちゃん）③"],
    ["25 ちびまる子ちゃん（ちびまるこちゃん）③ 〔专〕 Chibi Maruko-chan (Japanese anime character)"]),
 ],
 "markdown/中级上/1.梁爽老师日语精讲精练：第26课.md": [
   ("block", 111, 113, ["〔名、形Ⅱ、自", "14 寝坊", "Ⅲ〕"],
    ["14 寝坊（ねぼう）⓪ 〔名、形Ⅱ、自Ⅲ〕 oversleeping N4"]),
   ("block", 360, 362, ["〔名、形Ⅱ、", "18 退屈", "自Ⅲ〕"],
    ["18 退屈（たいくつ）⓪ 〔名、形Ⅱ、自Ⅲ〕 boring; boredom N2"]),
 ],
 "markdown/高级/3.梁爽老师日语精讲精练：第41课.md": [
   ("block", 96, 98, ["コミュニケーション能力（のうりょ", "1 〔名〕", "く）⑧"],
    ["1 コミュニケーション能力（のうりょく）⑧ 〔名〕 communication ability; capability"]),
   ("block", 220, 222, ["〔名、自Ⅲ、", "50 由来", "副〕"],
    ["50 由来（ゆらい）⓪ 〔名、自Ⅲ、副〕 origin; derivation"]),
 ],
 "markdown/初级下/17.梁爽老师日语精讲精练：第25课.md": [
   ("block", 285, 287, ["〔名、自", "4 転職", "Ⅲ〕"],
    ["4 転職（てんしょく）⓪ 〔名、自Ⅲ〕 job change; changing jobs N2"]),
 ],
 "markdown/初级上/9.梁爽老师日语精讲精练：第9课.md": [
   ("block", 376, 378, ["[名、自", "13 勉強", "他Ⅲ]"],
    ["13 勉強（べんきょう）⓪ [名、自他Ⅲ] study; studying N5"]),
   ("block", 372, 374, ["[名、形", "11 便利", "Ⅱ]"],
    ["11 便利（べんり）① [名、形Ⅱ] convenient; handy N5"]),
   ("block", 369, 371, ["[名、自", "10 買い物", "Ⅲ]"],
    ["10 買い物（かいもの）⓪ [名、自Ⅲ] shopping N5"]),
   ("block", 76, 77, ["生活（せいかつ）", "N4"],
    ["生活（せいかつ）⓪ [名] life; living N4"]),
   ("block", 74, 75, ["6 留学", "N4"],
    ["6 留学（りゅうがく）⓪ [名] studying abroad N4"]),
 ],
 "markdown/初级上/17.梁爽老师日语精讲精练：第11课.md": [
   ("block", 100, 101, ["記念（きねん）", "N3"],
    ["記念（きねん）⓪ [名、他Ⅲ] commemoration; souvenir; memory N3"]),
   ("block", 82, 83, ["モデル(model)", "N5"],
    ["モデル(model) ①⓪ [名] model N5"]),
   ("block", 80, 81, ["19 最新", "N3"],
    ["19 最新（さいしん）⓪ [名] latest model (= model; type) N3"]),
 ],
 "markdown/中级下/13.梁爽老师日语精讲精练：第39课.md": [
   ("block", 168, 170, ["少子高齢化", "44 〔名〕", "①＋⓪"],
    ["44 少子高齢化（しょうしこうれいか）①＋⓪ 〔名〕 declining birthrate and aging population"]),
 ],
 "markdown/中级下/3.梁爽老师日语精讲精练：第34课.md": [
   ("block", 84, 86, ["コミュニケーション", "6 〔名、Ⅲ〕", "（communication）④"],
    ["6 コミュニケーション（communication）④ 〔名、Ⅲ〕 exchange; communication N3"]),
 ],
 "markdown/中级下/5.梁爽老师日语精讲精练：第35课.md": [
   ("block", 137, 139, ["サラリーマン", "10 〔名〕", "③"],
    ["10 サラリーマン（from \"salaried man\"）③ 〔名〕 office worker; salaryman N5"]),
 ],
 "markdown/中级下/9.梁爽老师日语精讲精练：第37课.md": [
   ("block", 108, 109, ["コラボ（collaborationの略）①", "17 〔名〕"],
    ["17 コラボ（collaborationの略）① 〔名〕 collaboration"]),
 ],
 "markdown/高级/7.梁爽老师日语精讲精练：第43课.md": [
   ("block", 565, 567, ["何でもかんでも", "151 〔副〕", "でも) ⑤"],
    ["151 何でもかんでも (なんでもかんでも) ⑤ 〔副〕 no matter what; however; in whatever way"]),
 ],
 "markdown/初级上/25.梁爽老师日语精讲精练：第15课.md": [
   ("block", 82, 84, ["グローバリゼーション", "17 [名]", "（globalization）⑥"],
    ["17 グローバリゼーション（globalization）⑥ [名] globalization"]),
 ],
 "markdown/初级上/27.梁爽老师日语精讲精练：第16课.md": [
   ("block", 296, 297, ["アイス（ice）①", "3 [名]"],
    ["3 アイス（ice）① [名] ice; ice cream"]),
 ],
 "markdown/初级下/1.梁爽老师日语精讲精练：第17课.md": [
   ("block", 109, 111, ["SNS（ソーシャル・ネットワーク・サービス", "12 [名]", "の略）（social network service (SNS)"],
    ["12 SNS（ソーシャル・ネットワーク・サービスの略） [名] social network; social network service (SNS)"]),
   ("block", 106, 107, ["10 ときどき", "N5"],
    ["10 ときどき【時々】⓪ [副] sometimes; occasionally N5"]),
 ],
}

ok, fail = 0, []
for f, ops in OPS.items():
    p = pathlib.Path(f)
    lines = p.read_text(encoding="utf-8").splitlines(keepends=True)
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

print(f"ops applied: {ok}, failed: {len(fail)}")
for f, ln, want, cur in fail:
    print(f"FAILED {f}:{ln} wanted {want!r} got {cur!r}")
