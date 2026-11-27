"""Patch vocab-list lines in markdown: replace trailing Chinese gloss with English.

A line is patched when its stripped form ENDS WITH a known (translated) meaning
string. Longest meanings win. Pure-fragment meanings (starting with '(fragment)')
are not used for patching. Logs unpatched Chinese lines for the prose pass.
"""
import json, re, os, glob, sys

def load(path):
    m = {}
    for line in open(path, encoding="utf-8"):
        line = line.strip()
        if line:
            o = json.loads(line)
            m[o["id"]] = o
    return m

seg = load("work/segments_vocab.jsonl")
tr = load("work/trans_vocab.jsonl")

pairs = []
for i, o in seg.items():
    en = tr[i]["en"]
    if en.startswith("(fragment)"):
        continue
    pairs.append((o["text"], en))
pairs.sort(key=lambda p: -len(p[0]))

# index meanings by last character for speed
by_last = {}
for t, en in pairs:
    by_last.setdefault(t[-1], []).append((t, en))

has_cn = re.compile(r"[一-鿿]")
ENTRY_HINT = re.compile(r"〔|【|⓪|①|②|③|④|⑤|（[^）]*）")

patched = 0
unpatched = []
files = sorted(glob.glob("markdown/**/*.md", recursive=True))
for path in files:
    with open(path, encoding="utf-8") as f:
        lines = f.read().split("\n")
    changed = False
    for ln, line in enumerate(lines, 1):
        s = line.rstrip()
        if not s or not has_cn.search(s):
            continue
        cand = by_last.get(s[-1], [])
        for t, en in cand:
            if s.endswith(t):
                # safety: short glosses need an entry-shaped line
                if len(t) <= 2 and not ENTRY_HINT.search(s):
                    continue
                lines[ln - 1] = s[: -len(t)] + en
                patched += 1
                changed = True
                break
        else:
            unpatched.append((path, ln, s))
    if changed:
        with open(path, "w", encoding="utf-8") as f:
            f.write("\n".join(lines))

print("files scanned:", len(files), "lines patched:", patched)
print("chinese lines left:", len(unpatched))
with open("work/unpatched_lines.json", "w", encoding="utf-8") as f:
    json.dump(unpatched, f, ensure_ascii=False, indent=0)
