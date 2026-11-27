import json, re, os

# --- load vocab index: word -> meaning_en ---
vocab = json.load(open('index/vocab.json', encoding='utf-8'))
by_word = {}
for e in vocab:
    by_word.setdefault(e['word'], e['meaning_en'])

han = re.compile(r'[一-鿿]')

# vocab line: optional number, headword, （reading）, optional pitch, POS bracket(s), gloss, optional JLPT tag
vpat = re.compile(
    r'^(?P<num>\s*\d+\s+)?(?P<head>[〜〜\-\uff0d]?\S+?)（(?P<read>[^）]+)）(?P<pitch>[⓪①②③④⑤⑥⑦⑧⑨⑩0-9]*)\s*'
    r'(?P<pos>(?:[〔\[][^〕\]]*[〕\]]\s*)+)(?P<gloss>.*?)(?P<jlpt>\s+N[1-5]?)?\s*$')

MANUAL = [
    ('markdown/中级上/3.梁爽老师日语精讲精练：第27课.md',
     '① 日本の伝統文化を理解するために、茶道を習いました。／为了理解day; sun',
     '① 日本の伝統文化を理解するために、茶道を習いました。／'),
    ('markdown/中级上/5.梁爽老师日语精讲精练：第28课.md',
     '① 明日出かけるので、車を充電しておいてください。／因为明天要to go out; to leave; to come out',
     "① 明日出かけるので、車を充電しておいてください。／Because I'm going out tomorrow,"),
    ('markdown/中级上/7.梁爽老师日语精讲精练：第29课.md',
     '8. N として ＜作为＞',
     '8. N として ＜as; in the capacity of＞'),
    ('markdown/初级上/9.梁爽老师日语精讲精练：第9课.md',
     '15 どうして① [副] 为什么 N5',
     '15 どうして① [副] why N5'),
    ('markdown/初级上/9.梁爽老师日语精讲精练：第9课.md',
     'B：そうですね。今日は雪ですから。／是啊。因为今天有雪。',
     "B：そうですね。今日は雪ですから。／That's right. Because it's snowing today."),
    ('markdown/初级下/1.梁爽老师日语精讲精练：第17课.md',
     '简体：スマホでウェブサイトを閲覧する。／Browse websites on a phone.',
     'Plain form: スマホでウェブサイトを閲覧する。／Browse websites on a phone.'),
    ('markdown/初级下/1.梁爽老师日语精讲精练：第17课.md',
     '简体：よく徹夜する。／Often stay up all night.',
     'Plain form: よく徹夜する。／Often stay up all night.'),
    ('markdown/初级下/1.梁爽老师日语精讲精练：第17课.md',
     '③ 台風の影響で、香港へのフライトはキャンセルになりました。／由于',
     '③ 台風の影響で、香港へのフライトはキャンセルになりました。／'),
    ('markdown/初级下/1.梁爽老师日语精讲精练：第17课.md',
     '9. N や N など ＜列举＞',
     '9. N や N など ＜enumeration; listing＞'),
    ('markdown/初级下/17.梁爽老师日语精讲精练：第25课.md',
     'まるで⓪ 〔副词〕 as if; just like N4',
     'まるで⓪ 〔副〕 as if; just like N4'),
    ('markdown/初级下/9.梁爽老师日语精讲精练：第21课.md',
     '−用（よう） 〔接尾〕 用于…的 N4',
     '−用（よう） 〔接尾〕 used for ... N4'),
]

manual_done = []
vocab_fixed = 0
unresolved = []
headings = []

files = []
for root, dirs, fns in os.walk('markdown'):
    for fn in fns:
        if fn.endswith('.md') and not fn.startswith('_'):
            files.append(os.path.join(root, fn))

manual_map = {}
for f, old, new in MANUAL:
    manual_map.setdefault(f.replace('/', os.sep), []).append((old, new))

for path in files:
    with open(path, encoding='utf-8') as f:
        lines = f.readlines()
    changed = False
    for i, line in enumerate(lines):
        s = line.rstrip('\n')
        st = s.strip()
        # manual fixes
        for old, new in manual_map.get(path, []):
            if st == old:
                lines[i] = s[:len(s) - len(s.lstrip())] + new + '\n'
                manual_done.append((path, old[:40]))
                changed_line = True
                break
        else:
            changed_line = False
        if changed_line:
            changed = True
            continue
        # heading leftovers: ＜...＞ containing Han
        if st and '＜' in st and '＞' in st and han.search(st):
            headings.append((path, i + 1, st[:100]))
        # vocab gloss fix
        m = vpat.match(st)
        if m and m.group('gloss') and han.search(m.group('gloss')):
            gloss = m.group('gloss')
            head = m.group('head').lstrip('〜〜-\uff0d')
            en = by_word.get(head) or by_word.get(m.group('head'))
            if en:
                newgloss = en
                rebuilt = (m.group('num') or '') + m.group('head') + '（' + m.group('read') + '）' + m.group('pitch') + ' ' \
                          + m.group('pos') + newgloss + (m.group('jlpt') or '')
                lead = s[:len(s) - len(s.lstrip())]
                lines[i] = lead + rebuilt + '\n'
                vocab_fixed += 1
                changed = True
            else:
                unresolved.append((path, i + 1, st[:100]))
    if changed:
        with open(path, 'w', encoding='utf-8') as f:
            f.writelines(lines)

print('manual fixes applied:', len(manual_done), '/', len(MANUAL))
for d in manual_done:
    print('  OK', d)
missing_manual = [m for m in MANUAL if not any(d[1] == m[1][:40] for d in manual_done)]
for m in missing_manual:
    print('  NOT FOUND:', m[0], '|', m[1][:60])
print('vocab glosses fixed:', vocab_fixed)
print('unresolved vocab lines:', len(unresolved))
for u in unresolved[:60]:
    print('  UNRESOLVED:', u)
print('heading lines with Han in <>:', len(headings))
for h in headings[:30]:
    print('  HEADING:', h)
