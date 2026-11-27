# -*- coding: utf-8 -*-
"""Extract unique segments needing Chinese->English translation.

Outputs:
  work/segments_vocab.jsonl    {"id", "text"}        - vocab meanings
  work/segments_grammar.jsonl  {"id", "text"}        - grammar titles + categories
  work/segments_md.jsonl       {"id", "text"}        - unique markdown lines
  work/md_line_map.json        {seg_id: [[file, lineno], ...]}
"""
import glob
import json
import os
import re

os.makedirs("work", exist_ok=True)

# strongly simplified-Chinese marker chars (not used in Japanese)
SIMPLIFIED = set(
    "语词汉课听们为么这还对虽后时现发经济简态释练题页张华说话请动续习"
    "关开买卖见龙书飞风马鸟鱼门应处岁线旧规认让诉论议记忆错误确实验证"
    "谁什怎您咱她它哪吗呢吧啦嘛喽呀啊嗯辆顿册番据按较越另其各某每全半"
    "变换增减弱增强坏难易危险安全长短高矮胖瘦松紧软硬尖钝平直斜歪正反侧"
    "替换代替补充满空浪费节省剩余缺欠足够不够超过剩余额外附加顺便顺带"
    "顺便随手随身随便随意随机随心约束束缚限制禁止允许批准同意拒绝接受"
    "放弃坚持继续暂停停止终止结束完成实现达成达到超过落后进步退步先进"
    "落后保守传统现代当代古代近代未来过去历史经历经验体验感受感觉知觉"
    "意识思维思考考虑想象幻想梦想理想现实实际情况事实真实虚假虚伪伪装"
    "假装假装冒牌货伪劣假冒伪造仿制复制拷贝抄袭剽窃借鉴参考参照按照依据"
    "根据基于鉴于由于关于对于至于涉及触及提到谈及谈论讨论议论评论评价"
    "评估估计估算预算决算计算算计谋划计划规划策划策略战略战术策略技巧"
    "技能技术艺术手艺工艺工序工程过程流程程序顺序次序秩序纪律规定规则"
    "规范标准准则标杆榜样模范模型模式样式款式形态形式格式版式印刷出版"
    "发行销售营销推广宣传广告传媒媒体新闻资讯信息消息情报谍报间谍侦探"
    "侦察调查考查考核考试测验测试试验实验实践实行执行履行职责责任义务"
    "权利权力权威威望威胁恐吓吓唬怕惧怕恐惧恐慌慌张张慌张失措措手不及"
    "措施举措行动举动举止态度作风风格风度气质品质品德道德伦理价值观念"
    "概念理念信念信仰信任信用信誉名誉名声声望声誉荣誉荣耀光辉辉煌灿烂"
    "绚烂多彩丰富丰盛丰厚深厚深浅浅薄肤浅深厚浓郁浓烈激烈猛烈强烈温柔"
    "柔和软弱脆弱薄弱单薄厚重笨重轻便灵活灵巧巧妙拙劣笨拙愚昧无知智慧"
    "聪明伶俐机智机敏敏锐敏捷迟钝迟缓缓慢迅速快速急速飞速奔跑奔驰驰骋"
    "纵横交错复杂繁琐简明扼要概括总结归纳演绎推理逻辑条理清晰明确明白"
    "清楚懂得了解明白理解领会领悟觉醒觉悟觉悟醒悟懊悔悔恨怨恨仇恨敌视"
    "友好友谊友爱情感情绪心境心情心态心理思想意识意志毅力气魄胆识胆量"
    "勇气英雄豪杰杰出优秀卓越超凡脱俗非凡平凡普通普遍通常经常时常时刻"
    "时机机遇机会缘分姻缘婚姻嫁娶喜庆欢乐愉快高兴兴奋激动感动感激感恩"
    "感谢感动抱歉道歉歉意愧疚惭愧羞耻耻辱羞辱侮辱欺负欺压压迫强制强迫"
    "逼迫威胁威吓威吓震慑恐惧恐怖恐慌惊慌惊讶诧异惊奇惊讶赞叹赞赏欣赏"
    "钦佩敬佩敬重尊重尊严庄严庄重严肃严厉严格严谨谨慎小心细心细致细腻"
    "粗糙粗略粗暴暴力暴戾残忍残酷冷酷冷漠淡漠淡然淡泊宁静安静平静镇定"
    "沉着冷静沉着沉稳稳重老练成熟老到老道熟练熟知熟悉熟识认识识别辨别"
    "鉴别鉴定欣赏鉴赏赏识赏赐奖励奖赏奖品奖状勋章徽章标志标记标签商标"
    "招牌牌匾横幅竖幅条幅标语口号码号令号召召唤呼唤呼喊喊叫叫喊叫嚷"
    "嚷嚷嘈杂喧闹吵闹麻烦烦扰打扰干扰干预干涉介入插手插足插嘴插话插叙"
    "叙述述说讲述描述描写描绘刻画塑造形象意象意境情境情景场景场合局面"
    "局势形势趋势趋向倾向偏向偏差差错差距差异区别区分划分分割分裂分化"
    "瓦解崩溃垮台倒闭破产清盘算账结算清算清理清除清扫打扫扫除驱除驱逐"
    "驱赶追赶追逐追求寻求寻找探索探究探讨研究钻研琢磨雕琢雕刻塑造铸造"
    "锻锻炼炼冶金冶炼提炼精炼精制制作制造创造创作创立创建建立建设建议"
    "提议提案提出提交递交呈递呈报汇报报告告辞告别辞别辞职辞退解雇解聘"
    "聘用雇用雇佣聘任委任任命罢免撤职撤换调动调任升迁降职降级提升提拔"
    "拔擢选拔推选选举抉择选择挑选挑剔剔除去粗取精去伪存真精益求精"
    "尽善尽美完美完善完备齐全齐备整齐全完整完备周密缜密严密精密精确准确"
    "确切确实确凿证据证词证言证供供述供词供认承认否认狡辩辩解辩护辩论"
    "争论争议争端争执纠纷纠葛纠缠缠绵绵延延续连续陆续继续持续持久永久"
    "永远永恒恒久悠久长远遥远近临近靠近靠拢接近亲密亲切亲昵密切紧密"
    "紧凑凑巧恰巧碰巧遭遇遭遇际遇遭遇遭遇遭受蒙受承受承担担负负担重负"
    "重压压力压迫压抑抑制抑制约束束缚捆绑绑缚缚束拘谨拘泥泥坑坑洼洼地"
    "地形地势地貌地质地层岩石矿石矿产矿藏矿山矿井矿工矿业采掘采挖开采"
    "挖掘发掘挖潜潜在潜藏潜伏隐藏隐匿隐瞒遮掩遮挡遮盖覆盖笼罩包围环绕"
    "缠绕盘绕围绕周遭周围周边边缘边际边境疆界疆域领土领海领空领域范围"
    "范畴畴类别类类似类似相似近似似乎好像犹如宛如仿佛若即若离若若隐现"
    "隐蔽掩蔽遮蔽荫蔽庇护保佑祝福祈福祈求恳求请求哀求央求乞求乞讨"
    "讨饭饭量饭量饭菜菜菜肴肴美味味道气味香气芳香芬芳馨香馥郁浓郁浓烈"
)


def needs_translation(line: str) -> bool:
    if not re.search(r"[一-鿿]", line):
        return False
    if any(c in SIMPLIFIED for c in line):
        return True
    if re.search(r"[，；“”！？]|——", line):
        return True
    if not re.search(r"[ぁ-ヿ]", line):
        return True  # kanji-only short line (headers etc.)
    return False


# ---- vocab meanings
vocab = json.load(open("index/vocab.json", encoding="utf-8"))
seen = {}
segs = []
for e in vocab:
    m = e["meaning"]
    if m and m not in seen:
        seen[m] = len(segs)
        segs.append({"id": seen[m], "text": m})
with open("work/segments_vocab.jsonl", "w", encoding="utf-8") as fh:
    for s in segs:
        fh.write(json.dumps(s, ensure_ascii=False) + "\n")
print("vocab unique meanings:", len(segs))

# ---- grammar titles + categories
grammar = json.load(open("index/grammar.json", encoding="utf-8"))
gseen = {}
gsegs = []
for g in grammar:
    for t in (g["title"], g["category"]):
        if t and t not in gseen and re.search(r"[一-鿿]", t):
            gseen[t] = len(gsegs)
            gsegs.append({"id": gseen[t], "text": t})
with open("work/segments_grammar.jsonl", "w", encoding="utf-8") as fh:
    for s in gsegs:
        fh.write(json.dumps(s, ensure_ascii=False) + "\n")
print("grammar unique title/category:", len(gsegs))

# ---- markdown lines
line_map = {}
mdsegs = []
for f in sorted(glob.glob("markdown/*/*.md")):
    if os.path.basename(f).startswith("_"):
        continue
    for i, line in enumerate(open(f, encoding="utf-8").read().split("\n")):
        s = line.strip()
        if not s or s.startswith(("#", ">", "<!--", "---")):
            continue
        if needs_translation(s) and s not in line_map:
            line_map[s] = len(mdsegs)
            mdsegs.append({"id": line_map[s], "text": s})
with open("work/segments_md.jsonl", "w", encoding="utf-8") as fh:
    for s in mdsegs:
        fh.write(json.dumps(s, ensure_ascii=False) + "\n")
# map: seg text -> occurrences
occ = {}
for f in sorted(glob.glob("markdown/*/*.md")):
    if os.path.basename(f).startswith("_"):
        continue
    for i, line in enumerate(open(f, encoding="utf-8").read().split("\n")):
        s = line.strip()
        if s in line_map:
            occ.setdefault(line_map[s], []).append([f, i])
with open("work/md_line_map.json", "w", encoding="utf-8") as fh:
    json.dump(occ, fh, ensure_ascii=False)
total_chars = sum(len(s["text"]) for s in mdsegs)
print("md unique lines:", len(mdsegs), "| total chars:", total_chars)
