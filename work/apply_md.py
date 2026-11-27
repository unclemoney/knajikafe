import json, os, sys

# Load segments (id -> original text) and translations (id -> en)
segs = {}
with open('work/segments_md2.jsonl', encoding='utf-8') as f:
    for line in f:
        line = line.strip()
        if line:
            o = json.loads(line)
            segs[o['id']] = o['text']

trans = {}
with open('work/trans_md.jsonl', encoding='utf-8') as f:
    for line in f:
        line = line.strip()
        if line:
            o = json.loads(line)
            trans[o['id']] = o['en']

with open('work/md2_line_map.json', encoding='utf-8') as f:
    line_map = json.load(f)  # str(id) -> [[file, lineno], ...]

# Group edits by file
edits = {}  # file -> {lineno: (id, en)}
missing_trans = []
for sid, text in segs.items():
    if sid not in trans:
        missing_trans.append(sid)
        continue
    en = trans[sid]
    for fpath, lineno in line_map.get(str(sid), []):
        edits.setdefault(fpath, {})[lineno] = (sid, en)

if missing_trans:
    print(f'WARNING: {len(missing_trans)} segments without translation: {missing_trans[:10]}')

total_replaced = 0
total_cleared = 0
mismatches = []

for fpath, file_edits in edits.items():
    with open(fpath, encoding='utf-8') as f:
        lines = f.readlines()
    for lineno, (sid, en) in file_edits.items():
        cur = lines[lineno - 1]
        stripped = cur.rstrip('\n').rstrip('\r')
        seg = segs[sid]
        # safety check: current line must still equal the original segment
        if stripped.strip() != seg.strip():
            mismatches.append((fpath, lineno, sid, seg[:60], stripped[:60]))
            continue
        if en == '':
            # clear content, keep the newline
            nl = '\n' if cur.endswith('\n') else ''
            lines[lineno - 1] = nl
            total_cleared += 1
        else:
            # preserve leading whitespace
            lead = stripped[:len(stripped) - len(stripped.lstrip())]
            nl = '\n' if cur.endswith('\n') else ''
            lines[lineno - 1] = lead + en + nl
            total_replaced += 1
    with open(fpath, 'w', encoding='utf-8') as f:
        f.writelines(lines)

print(f'files touched: {len(edits)}')
print(f'lines replaced: {total_replaced}, lines cleared: {total_cleared}')
print(f'mismatches (skipped): {len(mismatches)}')
for m in mismatches[:30]:
    print('  MISMATCH:', m)

with open('work/apply_report.json', 'w', encoding='utf-8') as f:
    json.dump({
        'files': len(edits),
        'replaced': total_replaced,
        'cleared': total_cleared,
        'mismatches': [list(m) for m in mismatches],
        'missing_translations': missing_trans,
    }, f, ensure_ascii=False, indent=1)
