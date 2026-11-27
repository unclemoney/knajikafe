# Patch the 52 leftover vocab lines found in the final scan-2 sweep.
# Each entry: (file, line_no, old_gloss, new_gloss). Line-anchored with verification.
import json, pathlib

FIXES = [
    ("markdown/中级上/13.梁爽老师日语精讲精练：第32课.md", 97, "完全", "completely"),
    ("markdown/中级上/3.梁爽老师日语精讲精练：第27课.md", 80, "好好地", "properly; carefully"),
    ("markdown/中级下/1.梁爽老师日语精讲精练：第33课.md", 134, "任性", "selfishness; willful"),
    ("markdown/中级下/11.梁爽老师日语精讲精练：第38课.md", 86, "演示", "demonstration"),
    ("markdown/中级下/5.梁爽老师日语精讲精练：第35课.md", 93, "特意、故意", "deliberately; going out of one's way"),
    ("markdown/入门20讲/4.梁爽老师日语精讲精练：第4课.md", 27, "慢慢地", "slowly; leisurely"),
    ("markdown/入门20讲/4.梁爽老师日语精讲精练：第4课.md", 28, "稍微", "a little; a bit"),
    ("markdown/入门20讲/4.梁爽老师日语精讲精练：第4课.md", 116, "花蛤", "asari clam; short-neck clam"),
    ("markdown/入门20讲/4.梁爽老师日语精讲精练：第4课.md", 117, "清淡的", "light (taste); plain"),
    ("markdown/入门20讲/4.梁爽老师日语精讲精练：第4课.md", 128, "〔助〕 各", "〔助〕 each; apiece"),
    ("markdown/初级上/1.梁爽老师日语精讲精练：第5课.md", 74, "我 N5", "I; me N5"),
    ("markdown/初级上/1.梁爽老师日语精讲精练：第5课.md", 76, "那么 N5", "well then; so N5"),
    ("markdown/初级上/1.梁爽老师日语精讲精练：第5课.md", 114, "不 N5", "no N5"),
    ("markdown/初级上/1.梁爽老师日语精讲精练：第5课.md", 118, "哪位 N5", "who (polite) N5"),
    ("markdown/初级上/1.梁爽老师日语精讲精练：第5课.md", 122, "什么 N5", "what N5"),
    ("markdown/初级上/1.梁爽老师日语精讲精练：第5课.md", 126, "意大利person", "Italian (person)"),
    ("markdown/初级上/1.梁爽老师日语精讲精练：第5课.md", 384, "朋友 N5", "friend N5"),
    ("markdown/初级上/1.梁爽老师日语精讲精练：第5课.md", 395, "高中生 N4", "high school student N4"),
    ("markdown/初级上/1.梁爽老师日语精讲精练：第5课.md", 396, "男孩子 N5", "boy N5"),
    ("markdown/初级上/1.梁爽老师日语精讲精练：第5课.md", 397, "哥哥 N5", "older brother N5"),
    ("markdown/初级上/17.梁爽老师日语精讲精练：第11课.md", 71, "如何 N5", "how; in what way (polite) N5"),
    ("markdown/初级上/17.梁爽老师日语精讲精练：第11课.md", 75, "左右 N5", "about; approximately N5"),
    ("markdown/初级上/17.梁爽老师日语精讲精练：第11课.md", 84, "最 N5", "the most N5"),
    ("markdown/初级上/19.梁爽老师日语精讲精练：第12课.md", 89, "明白 N5", "to understand N5"),
    ("markdown/初级上/21.梁爽老师日语精讲精练：第13课.md", 71, "打工 N4", "part-time job N4"),
    ("markdown/初级上/23.梁爽老师日语精讲精练：第14课.md", 78, "不行 N4", "no good; not allowed N4"),
    ("markdown/初级上/23.梁爽老师日语精讲精练：第14课.md", 114, "[他Ⅲ] 做 N5", "[他Ⅲ] to do N5"),
    ("markdown/初级上/25.梁爽老师日语精讲精练：第15课.md", 73, "首先 N4", "first of all N4"),
    ("markdown/初级上/3.梁爽老师日语精讲精练：第6课.md", 65, "公寓 N5", "apartment N5"),
    ("markdown/初级上/3.梁爽老师日语精讲精练：第6课.md", 71, "便利店 N3", "convenience store N3"),
    ("markdown/初级上/3.梁爽老师日语精讲精练：第6课.md", 85, "慢慢地 N5", "slowly; leisurely N5"),
    ("markdown/初级上/3.梁爽老师日语精讲精练：第6课.md", 91, "特意、故意 N1", "deliberately; going out of one's way N1"),
    ("markdown/初级上/3.梁爽老师日语精讲精练：第6课.md", 101, "面包 N5", "bread N5"),
    ("markdown/初级上/3.梁爽老师日语精讲精练：第6课.md", 353, "非常 N5", "very (much) N5"),
    ("markdown/初级上/5.梁爽老师日语精讲精练：第7课.md", 82, "而且", "and; moreover"),
    ("markdown/初级上/7.梁爽老师日语精讲精练：第8课.md", 90, "[他Ⅰ] 做 N4", "[他Ⅰ] to do (honorific) N4"),
    ("markdown/初级上/9.梁爽老师日语精讲精练：第9课.md", 88, "非常 N5", "very N5"),
    ("markdown/初级上/9.梁爽老师日语精讲精练：第9课.md", 90, "那么 N4", "so; that much N4"),
    ("markdown/初级上/9.梁爽老师日语精讲精练：第9课.md", 91, "但是 N5", "but N5"),
    ("markdown/初级上/9.梁爽老师日语精讲精练：第9课.md", 111, "好 N5", "good N5"),
    ("markdown/初级上/9.梁爽老师日语精讲精练：第9课.md", 123, "了不起的 N4", "amazing; remarkable N4"),
    ("markdown/初级上/9.梁爽老师日语精讲精练：第9课.md", 124, "都 N5", "all; everyone N5"),
    ("markdown/初级下/1.梁爽老师日语精讲精练：第17课.md", 122, "其他 N5", "other N5"),
    ("markdown/初级下/13.梁爽老师日语精讲精练：第23课.md", 105, "卡拉ok N4", "karaoke N4"),
    ("markdown/初级下/3.梁爽老师日语精讲精练：第18课.md", 318, "前天 N5", "the day before yesterday N5"),
    ("markdown/初级下/5.梁爽老师日语精讲精练：第19课.md", 78, "打算 N4", "intention; plan N4"),
    ("markdown/初级下/5.梁爽老师日语精讲精练：第19课.md", 84, "一定 N4", "surely; certainly N4"),
    ("markdown/初级下/5.梁爽老师日语精讲精练：第19课.md", 86, "喂 N5", "hello (on the phone) N5"),
    ("markdown/初级下/9.梁爽老师日语精讲精练：第21课.md", 85, "塑料瓶 N3", "plastic bottle; PET bottle N3"),
    ("markdown/高级/1.梁爽老师日语精讲精练：第40课.md", 173, "但是 N5", "but; however N5"),
    ("markdown/高级/7.梁爽老师日语精讲精练：第43课.md", 418, "改行", "changing jobs; career change"),
    ("markdown/高级/7.梁爽老师日语精讲精练：第43课.md", 561, "〔名〕 腰", "〔名〕 waist; lower back"),
]

applied, failed = [], []
by_file = {}
for f, ln, old, new in FIXES:
    by_file.setdefault(f, []).append((ln, old, new))

for f, items in by_file.items():
    p = pathlib.Path(f)
    lines = p.read_text(encoding="utf-8").splitlines(keepends=True)
    for ln, old, new in items:
        idx = ln - 1
        cur = lines[idx].rstrip("\n")
        if old in cur:
            lines[idx] = lines[idx].replace(old, new, 1)
            applied.append((f, ln, old, new))
        else:
            failed.append((f, ln, old, cur))
    p.write_text("".join(lines), encoding="utf-8")

print(f"applied: {len(applied)}/{len(FIXES)}")
for f, ln, old, cur in failed:
    print(f"FAILED {f}:{ln} wanted {old!r} in line: {cur[:120]!r}")
