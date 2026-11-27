import os

# (file path, line number, old text, new text)
FIXES = [
    # --- grammar headings: translate Chinese tag in <> ---
    ('markdown/中级上/1.梁爽老师日语精讲精练：第26课.md', 203, '3. 〜たり〜たりする ＜示例：たり−２＞', '3. 〜たり〜たりする ＜example: tari-2＞'),
    ('markdown/中级上/1.梁爽老师日语精讲精练：第26课.md', 241, '5. V るように＜目的＞', '5. V るように＜purpose＞'),
    ('markdown/中级上/13.梁爽老师日语精讲精练：第32课.md', 241, '5. って ＜引用＞', '5. って ＜quotation＞'),
    ('markdown/中级上/13.梁爽老师日语精讲精练：第32课.md', 268, '7. 〜ため（に）＜原因＞', '7. 〜ため（に）＜cause; reason＞'),
    ('markdown/中级上/3.梁爽老师日语精讲精练：第27课.md', 236, '8. ために＜目的＞', '8. ために＜purpose＞'),
    ('markdown/中级上/5.梁爽老师日语精讲精练：第28课.md', 195, '4. N まで ＜程度＞', '4. N まで ＜degree＞'),
    ('markdown/中级上/5.梁爽老师日语精讲精练：第28课.md', 210, '5. 〜のに ＜逆接＞', '5. 〜のに ＜contrast＞'),
    ('markdown/中级上/7.梁爽老师日语精讲精练：第29课.md', 269, '10. 〜ことだ＜忠告＞', '10. 〜ことだ＜advice; warning＞'),
    ('markdown/中级上/9.梁爽老师日语精讲精练：第30课.md', 139, '1. 〜て、〜 ＜原因＞', '1. 〜て、〜 ＜cause; reason＞'),
    ('markdown/中级上/9.梁爽老师日语精讲精练：第30课.md', 286, '8. V てみせる＜演示＞', '8. V てみせる＜demonstration＞'),
    ('markdown/中级下/1.梁爽老师日语精讲精练：第33课.md', 227, '3. N みたいだ ＜示例、比喻＞', '3. N みたいだ ＜example; metaphor＞'),
    ('markdown/中级下/1.梁爽老师日语精讲精练：第33课.md', 245, '4. N のような・N のように ＜示例＞', '4. N のような・N のように ＜example＞'),
    ('markdown/中级下/1.梁爽老师日语精讲精练：第33课.md', 263, '5. 〜かぎり、〜＜限定＞', '5. 〜かぎり、〜＜limitation＞'),
    ('markdown/中级下/11.梁爽老师日语精讲精练：第38课.md', 260, '4. 〜くらい ＜程度＞', '4. 〜くらい ＜degree＞'),
    ('markdown/中级下/13.梁爽老师日语精讲精练：第39课.md', 528, '8. V る/V ないよう（に）＜祈盼＞', '8. V る/V ないよう（に）＜wish; hope＞'),
    ('markdown/中级下/3.梁爽老师日语精讲精练：第34课.md', 411, '10. V るものではない ＜忠告＞', '10. V るものではない ＜advice; warning＞'),
    ('markdown/中级下/3.梁爽老师日语精讲精练：第34课.md', 425, '11. V るには ＜目的＞', '11. V るには ＜purpose＞'),
    ('markdown/中级下/7.梁爽老师日语精讲精练：第36课.md', 149, '1. わけではない ＜部分否定＞', '1. わけではない ＜partial negation＞'),
    ('markdown/中级下/9.梁爽老师日语精讲精练：第37课.md', 399, '9. 上（に） ＜加之＞', '9. 上（に） ＜in addition＞'),
    ('markdown/初级上/13.梁爽老师日语精讲精练：第10课.md', 258, '6. N とか ＜举例＞', '6. N とか ＜examples＞'),
    ('markdown/初级上/17.梁爽老师日语精讲精练：第11课.md', 205, '5. 句子 が、句子 。 ＜逆接＞', '5. 句子 が、句子 。 ＜contrast＞'),
    ('markdown/初级上/27.梁爽老师日语精讲精练：第16课.md', 178, '5. ため ＜目的＞', '5. ため ＜purpose＞'),
    ('markdown/初级上/3.梁爽老师日语精讲精练：第6课.md', 159, '2. Ｎも ＜也＞', '2. Ｎも ＜also＞'),
    ('markdown/初级上/3.梁爽老师日语精讲精练：第6课.md', 168, '3. N と ＜和＞', '3. N と ＜and＞'),
    ('markdown/初级上/5.梁爽老师日语精讲精练：第7课.md', 212, '5. だけ ＜限定＞', '5. だけ ＜limitation＞'),
    ('markdown/初级下/13.梁爽老师日语精讲精练：第23课.md', 159, '3. 〜と言う ＜引用＞', '3. 〜と言う ＜quotation＞'),
    ('markdown/初级下/13.梁爽老师日语精讲精练：第23课.md', 267, '7. N しか V ない ＜限定＞', '7. N しか V ない ＜limitation＞'),
    ('markdown/初级下/15.梁爽老师日语精讲精练：第24课.md', 232, '4. N でも＜示例＞', '4. N でも＜example＞'),
    ('markdown/初级下/15.梁爽老师日语精讲精练：第24课.md', 283, '7. 〜みたいだ＜推測＞', '7. 〜みたいだ＜conjecture＞'),
    ('markdown/初级下/17.梁爽老师日语精讲精练：第25课.md', 151, '3. 〜からだ。＜原因、理由＞', '3. 〜からだ。＜cause; reason＞'),
    ('markdown/初级下/17.梁爽老师日语精讲精练：第25课.md', 219, '7. 〜ようだ。＜推測＞', '7. 〜ようだ。＜conjecture＞'),
    ('markdown/初级下/17.梁爽老师日语精讲精练：第25课.md', 238, '8. N のようだ。 ＜比喻＞', '8. N のようだ。 ＜metaphor＞'),
    ('markdown/初级下/5.梁爽老师日语精讲精练：第19课.md', 252, '6. 〜つもりだ。 ＜打算＞', '6. 〜つもりだ。 ＜intention; plan＞'),
    ('markdown/初级下/7.梁爽老师日语精讲精练：第20课.md', 183, '5. V る前（に） ＜在…之前＞', '5. V る前（に） ＜before ...＞'),
    ('markdown/初级下/9.梁爽老师日语精讲精练：第21课.md', 151, '3. V なくてもいい ＜非必要＞', '3. V なくてもいい ＜not necessary＞'),
    ('markdown/初级下/9.梁爽老师日语精讲精练：第21课.md', 165, '4. V てはいけない ＜禁止＞', '4. V てはいけない ＜prohibition＞'),
    ('markdown/高级/1.梁爽老师日语精讲精练：第40课.md', 377, '2. お/ご〜になる ＜尊他＞', '2. お/ご〜になる ＜honorific (respectful)＞'),
    # --- vocab lines not resolvable via index ---
    ('markdown/中级下/13.梁爽老师日语精讲精练：第39课.md', 274, '43 あくび（【欠伸】）① 〔名〕 呵欠 N2', '43 あくび（【欠伸】）① 〔名〕 yawn N2'),
    ('markdown/入门20讲/1.梁爽老师日语精讲精练：第1课.md', 71, '3 キス（kiss）① 〔名〕 吻', '3 キス（kiss）① 〔名〕 kiss'),
    ('markdown/入门20讲/1.梁爽老师日语精讲精练：第1课.md', 78, '7 カカオ（cacao）① 〔名〕 可可豆', '7 カカオ（cacao）① 〔名〕 cacao; cocoa bean'),
    ('markdown/入门20讲/1.梁爽老师日语精讲精练：第1课.md', 79, '8 サウナ（【芬】sauna）① 〔名〕 桑拿', '8 サウナ（【芬】sauna）① 〔名〕 sauna'),
    ('markdown/入门20讲/2.梁爽老师日语精讲精练：第2课.md', 71, '1 ハイテク（high-tech）⓪ 〔名〕 高technology; tech', '1 ハイテク（high-tech）⓪ 〔名〕 high technology; high-tech'),
    ('markdown/入门20讲/2.梁爽老师日语精讲精练：第2课.md', 81, '8 ミルク（milk）① 〔名〕 牛奶', '8 ミルク（milk）① 〔名〕 milk'),
    ('markdown/入门20讲/2.梁爽老师日语精讲精练：第2课.md', 105, '2 インク（ink）⓪① 〔名〕 墨water', '2 インク（ink）⓪① 〔名〕 ink'),
    ('markdown/入门20讲/4.梁爽老师日语精讲精练：第4课.md', 32, '11 コップ（【荷】kop）⓪ 〔名〕 杯子', '11 コップ（【荷】kop）⓪ 〔名〕 cup; glass'),
    ('markdown/入门20讲/4.梁爽老师日语精讲精练：第4课.md', 107, '作家（さっか）⓪ 〔名〕 作家', '作家（さっか）⓪ 〔名〕 writer; author'),
    ('markdown/入门20讲/4.梁爽老师日语精讲精练：第4课.md', 112, '六（ろく）② 〔名〕 六', '六（ろく）② 〔名〕 six'),
    ('markdown/入门20讲/4.梁爽老师日语精讲精练：第4课.md', 115, 'マッチ（match）① 〔名〕 火柴', 'マッチ（match）① 〔名〕 match (for lighting a fire)'),
    ('markdown/入门20讲/4.梁爽老师日语精讲精练：第4课.md', 125, '高校（こうこう）⓪ 〔名〕 高中', '高校（こうこう）⓪ 〔名〕 high school'),
    ('markdown/入门20讲/4.梁爽老师日语精讲精练：第4课.md', 135, 'カレー（curry）⓪ 〔名〕 咖喱', 'カレー（curry）⓪ 〔名〕 curry'),
    ('markdown/初级上/25.梁爽老师日语精讲精练：第15课.md', 108, '13 〔スターバックス④（Starbucks） [名] 星巴克', '13 〔スターバックス④（Starbucks） [名] Starbucks'),
    ('markdown/初级上/27.梁爽老师日语精讲精练：第16课.md', 293, '1 〔スーパーマーケット⑤（supermarket） [名] 超市 N4', '1 〔スーパーマーケット⑤（supermarket） [名] supermarket N4'),
]

ok, bad = 0, []
by_file = {}
for f, ln, old, new in FIXES:
    by_file.setdefault(f.replace('/', os.sep), []).append((ln, old, new))

for path, items in by_file.items():
    with open(path, encoding='utf-8') as f:
        lines = f.readlines()
    changed = False
    for ln, old, new in items:
        cur = lines[ln - 1].rstrip('\n').strip()
        if cur == old:
            lead = lines[ln - 1][:len(lines[ln - 1]) - len(lines[ln - 1].lstrip())]
            lines[ln - 1] = lead + new + '\n'
            ok += 1
            changed = True
        else:
            bad.append((path, ln, old[:60], cur[:60]))
    if changed:
        with open(path, 'w', encoding='utf-8') as f:
            f.writelines(lines)

print('applied:', ok, '/', len(FIXES))
for b in bad:
    print('MISMATCH:', bad and b)
