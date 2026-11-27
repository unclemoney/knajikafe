"""Apply English translations to index/vocab and index/grammar (json + csv)."""
import json, csv, sys

def load_seg(path):
    m = {}
    for line in open(path, encoding="utf-8"):
        line = line.strip()
        if line:
            o = json.loads(line)
            m[o["id"]] = o["text"]
    return m

def load_trans(path):
    m = {}
    for line in open(path, encoding="utf-8"):
        line = line.strip()
        if line:
            o = json.loads(line)
            m[o["id"]] = o["en"]
    return m

# ---- vocab ----
seg = load_seg("work/segments_vocab.jsonl")
tr = load_trans("work/trans_vocab.jsonl")
text2en = {}
conflicts = 0
for i, text in seg.items():
    en = tr[i]
    if text in text2en and text2en[text] != en:
        conflicts += 1
    text2en[text] = en
print("vocab text->en map:", len(text2en), "conflicts:", conflicts)

vocab = json.load(open("index/vocab.json", encoding="utf-8"))
miss = 0
for e in vocab:
    en = text2en.get(e["meaning"])
    if en is None:
        miss += 1
        e["meaning_en"] = ""
    else:
        e["meaning_en"] = en
print("vocab entries:", len(vocab), "missing translation:", miss)
json.dump(vocab, open("index/vocab.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)

fields = ["word","reading","origin","pitch","pos","meaning","meaning_en","jlpt","level","lesson","lessons","sections","occurrences","source"]
with open("index/vocab.csv", "w", encoding="utf-8-sig", newline="") as f:
    w = csv.DictWriter(f, fieldnames=fields, extrasaction="ignore")
    w.writeheader()
    w.writerows(vocab)

# ---- grammar ----
seg = load_seg("work/segments_grammar.jsonl")
tr = load_trans("work/trans_grammar.jsonl")
text2en = {seg[i]: tr[i] for i in seg}
gram = json.load(open("index/grammar.json", encoding="utf-8"))
miss_t = miss_c = 0
for e in gram:
    te = text2en.get(e["title"])
    ce = text2en.get(e["category"])
    if te is None: miss_t += 1
    if ce is None: miss_c += 1
    e["title_en"] = te or ""
    e["category_en"] = ce or ""
print("grammar entries:", len(gram), "missing title:", miss_t, "missing category:", miss_c)
json.dump(gram, open("index/grammar.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)

fields = ["level","lesson","number","title","title_en","category","category_en","kind","source"]
with open("index/grammar.csv", "w", encoding="utf-8-sig", newline="") as f:
    w = csv.DictWriter(f, fieldnames=fields, extrasaction="ignore")
    w.writeheader()
    w.writerows(gram)
print("done")
