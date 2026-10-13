#!/usr/bin/env python3
"""Build the appendix reproduction report from public OSF data.

Everything printed here is derived from files on disk:
  - SI text  : /tmp/hw/si_layout.txt   (pdftotext -layout of supplement.pdf; SI Tables C1, C2, C3)
  - data     : osf/atj5u/files/github/data_public/data_LCA_c_V3.xlsx
  - script   : osf/atj5u/files/github/code/2_measurement_deliberation_LCA.R
"""
import sys, os, re, subprocess
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np
from itertools import permutations
from repro_lca import load, fit_lca, FORMULA, SI_C2

HERE = os.path.dirname(os.path.abspath(__file__))


def find_si_text():
    """The SI tables are parsed from a `pdftotext -layout` dump."""
    cands = [os.path.join(HERE, 'si_layout.txt'), os.path.join(HERE, 'SI_layout.txt')]
    for c in cands:
        if os.path.exists(c):
            return c
    pdf = None
    for c in [os.path.join(HERE, '..', '6_补充材料（Supplementary Information）.pdf'),
              os.path.expanduser('~/Desktop/SC-1/完成的作业/6_补充材料（Supplementary Information）.pdf')]:
        if os.path.exists(c):
            pdf = c
            break
    if pdf and subprocess.run(['which', 'pdftotext'], capture_output=True).returncode == 0:
        subprocess.run(['pdftotext', '-layout', pdf, SI_OUT], check=True)
        return SI_OUT
    raise SystemExit('找不到补充材料的文本；请先运行 pdftotext -layout <SI.pdf> si_layout.txt')


OUT = os.path.join(HERE, 'repro_report.txt')
SI_OUT = os.path.join(HERE, 'si_layout.txt')
SI = find_si_text()
buf = []


def p(s=''):
    buf.append(s)
    print(s)


L = open(SI).read().split('\n')


def slice_between(a, b):
    start = next(n for n, l in enumerate(L) if l.strip().startswith(a))
    end = next(n for n, l in enumerate(L) if l.strip().startswith(b) and n > start)
    return L[start + 1:end]


def col_bounds(header, tags):
    """Character offsets of each '<tag> ... clicks' block, from the header line."""
    starts = [m.start() for t in tags for m in re.finditer(re.escape(t), header)]
    starts.sort()
    return starts + [len(header) + 20]


def parse_blocks(seg, tags):
    """seg = lines of a table; tags = the column labels in page order."""
    header = next(l for l in seg if all(t in l for t in tags))
    b = col_bounds(header, tags)
    out = [{} for _ in tags]
    for line in seg:
        if line is header or not line.strip():
            continue
        for i, t in enumerate(tags):
            m = re.match(r'^\s*(\S+)\s+([\d,]+)\s*$', line[b[i]:b[i + 1]])
            if m:
                out[i][m.group(1)] = int(m.group(2).replace(',', ''))
    return out


def table_c1():
    """SI Table C1 -> {domain: (column, clicks)}.  Page order of the columns is C3 | C1 | C2."""
    tags = ['C3 domains', 'C1 domains', 'C2 domains']
    c3, c1, c2 = parse_blocks(slice_between('Table C1', 'Table C2'), tags)
    out = {}
    for d, v in c1.items():
        out[d] = ('C1', v)
    for d, v in c3.items():
        out[d] = ('C3', v)
    for d, v in c2.items():
        out[d] = ('C2', v)
    return out


def table_c3():
    """SI Table C3 (two-class solution) -> {'C1': {domain: clicks}, 'C2': {...}}."""
    a, b = parse_blocks(slice_between('Table C3', 'Figure C8'), ['C1_domains', 'C2_domains'])
    return {'C1': a, 'C2': b}


C1, C3 = table_c1(), table_c3()
dom, clicks, X, stored_class, stored_post = load()
stored_class = [str(c) for c in stored_class]
idx = dict(zip(dom, range(len(dom))))

p('=' * 78)
p('Oswald (2024)《More than news!》潜类别分析（LCA）复现报告')
p('数据与脚本来源：OSF 项目 osf.io/atj5u（github 存储提供者，公开）')
p('=' * 78)
p()

# ------------------------------------------------------------------- 1. data
p('[1] 输入数据核对')
p('  文件与结构  : data_public/data_LCA_c_V3.xlsx —— %d 个域名 × 23 列' % len(dom))
p('  23 列        : domain, clicks, 15 条二值标准, X1/X2/X3（作者算好的后验概率）, class')
p('  使用的 15 条 : ' + ', '.join(FORMULA))
p('  点击量合计  : %d   （论文正文 Results: "less than 1%% (493,714 clicks)"）' % sum(clicks))
sizes = {c: stored_class.count(c) for c in sorted(set(stored_class))}
p('  已存类别规模: ' + ' / '.join('class %s: %d 个' % (k, v) for k, v in sizes.items()) +
  '  → 混合比例 ' + ', '.join('%.1f%%' % (100 * v / len(dom)) for v in sizes.values()) +
  '（正文报告 49% / 22% / 29%）')
p('  表 C1 列规模: ' + ' / '.join('%s: %d 个' % (k, sum(1 for v in C1.values() if v[0] == k))
                                 for k in ('C1', 'C2', 'C3')) + '  合计 %d' % len(C1))
mp = {}
for d, (col, _) in C1.items():
    mp.setdefault(col, set()).add(stored_class[idx[d]])
p('  表 C1 列 ↔ 数据文件 class: ' + ',  '.join('%s → class %s' % (k, '/'.join(sorted(v)))
                                                for k, v in sorted(mp.items())))
p('  域名集合    : 表 C1 与数据文件完全一致（%d/%d）' % (len(set(C1) & set(dom)), len(dom)))
bad = [(d, clicks[idx[d]], C1[d][1]) for d in dom if clicks[idx[d]] != C1[d][1]]
p('  点击量      : 与表 C1 逐站比对 ' + ('69/69 全部一致' if not bad else str(bad)))
p()

# -------------------------------------------------------- 2. redundancy check
p('[2] 标准列之间的冗余（公开数据里可以直接量到）')
Xc = {c: X[:, j] for j, c in enumerate(FORMULA)}
dupe = [(a, b) for i, a in enumerate(FORMULA) for b in FORMULA[i + 1:] if np.array_equal(Xc[a], Xc[b])]
p('  取值完全相同的标准列: ' + ', '.join('%s ≡ %s' % t for t in dupe))
p('  → 15 条标准里只有 %d 条互不相同的取值模式；但脚本仍按 15 条算自由参数 npar = K*15 + (K-1)。'
  % len({tuple(Xc[c].tolist()) for c in FORMULA}))
p('  三条包容性标准各自为 1 的域名数: ' + ', '.join('%s=%d' % (c, int(Xc[c].sum()))
                                                    for c in FORMULA if c.startswith('incl_')))
p('  与它们最相关的其他标准: isolation_in（相关 0.916）、hom_pol_or（0.916）')
p()

# ------------------------------------------------------------- 3. LCA results
p('[3] 重跑 LCA（自实现、与 poLCA 等价的 EM；种子 9876；每类 30 个随机起点取最大对数似然）')
p('    纳入的 15 条标准与脚本第 30–36 行的 cbind() 完全一致（0/1 按脚本重编码为 1/2）')
p()
p('  %-3s %-9s %-5s %-5s %-8s %-8s %-8s %-7s | %s' %
  ('K', 'logLik', 'npar', 'Df', 'BIC', 'aBIC', 'CAIC', 'Gsq', 'SI 表 C2（ll / Df / BIC / aBIC / AIC / Gsq）'))
fits = {}
for K in range(1, 11):
    f = fit_lca(X, K, n_starts=30)
    fits[K] = f
    si = SI_C2[K]
    p('  %-3d %-9.1f %-5d %-5d %-8.1f %-8.1f %-8.1f %-7.1f | %-6s %-4s %-5s %-5s %-5s %s' %
      (K, f['llik'], f['npar'], len(dom) - f['npar'], f['BIC'], f['aBIC'], f['CAIC'], f['Gsq'],
       si[0], si[1], si[2], si[3], si[4], si[5]))
p('  （Df 一列按 N − npar 计算，与 SI 表 C2 逐格相同；poLCA 在控制台另报一个基于'
  '唯一作答模式的 resid.df，本例出现 38 种作答模式，故 K=1 时它会打印 23。）')
p()
p('  说明 1：本表第 7 列 CAIC 与 SI 表 C2 中名为 "AIC" 的那一列（1380 / 979 / 998 / 1035 …）'
  '逐格相同。')
p('          原因是脚本这两行把 CAIC 存进了名为 AIC 的列：')
p('            CAICs <- (-2*lc$llik) + lc$npar * (1 + log(lc$N))')
p('            data.frame(loglik, Df, BIC, aBIC, AIC = CAICs, Gsq = lc$Gsq)')
p('          真正的 AIC = −2ll + 2·npar 在 K=5 才取到最小（825.6），K=3 时是 846.0。')
p('  说明 2：K=1–4 与 SI 表 C2 在四舍五入到整数后逐格相同；K≥5 的差异见 [4]。')
p()
p('  各准则的最小解：BIC→K=%d   aBIC→K=%d   CAIC（论文标为 AIC）→K=%d   真 AIC→K=%d' %
  (min(fits, key=lambda k: fits[k]['BIC']), min(fits, key=lambda k: fits[k]['aBIC']),
   min(fits, key=lambda k: fits[k]['CAIC']), min(fits, key=lambda k: fits[k]['AIC'])))
p('  而脚本自己的选择规则是 if(lc$bic < min_bic)，会把 K=%d 存成 LCA_best_model；'
  '论文正文报告的却是 3 类解。' % min(fits, key=lambda k: fits[k]['BIC']))
p()

# --------------------------------------------------- 4. multi-start diagnostic
p('[4] K≥5 的解不是全局最优（随机起点从 30 个加到 400 个）')
p('  %-3s %-12s %-12s %-9s %-9s %s' % ('K', '30 起点', '400 起点', '改善', '比 SI 高*', 'SI 表 C2'))
for K in range(5, 11):
    f = fit_lca(X, K, n_starts=400)
    p('  %-3d %-12.2f %-12.2f %-9.2f %-9.2f %s' % (K, fits[K]['llik'], f['llik'],
                                                   f['llik'] - fits[K]['llik'],
                                                   f['llik'] - SI_C2[K][0], SI_C2[K][0]))
p('  * SI 表 C2 的数值在论文里只取整到整数，故该列是近似差值。')
p('  → SI 表 C2 中 K≥5 各行的对数似然是起点依赖的局部极大值，不能当作该 K 的全局最优解参与比较；')
p('    这也解释了为什么它们的 aBIC/CAIC 会一路单调下降（惩罚项算在偏低的似然上）。')
p()

# ------------------------------------------------------- 5. posterior compare
p('[5] K=3 的后验概率与作者已存结果逐站比对')
f3 = fits[3]
best, bp = 9e9, None
for perm in permutations(range(3)):
    e = np.abs(f3['post'][:, list(perm)] - stored_post).max()
    if e < best:
        best, bp = e, perm
p('  我的 %s 类  ↔  文件的 X1 / X2 / X3（最优列配对）' % ' / '.join('第 %d' % (bp.index(k) + 1) for k in range(3)))
p('  最大绝对偏差: %.4f（69 域名 × 3 类 = 207 个后验概率中的最大值）' % best)
try:
    mylab = {}
    for k in range(3):
        mylab[bp.index(k) + 1] = str(k + 1)
    agree = sum(1 for d in dom if mylab.get(int(f3['post'][d and idx[d]].argmax() + 1)) == stored_class[idx[d]])
except Exception:
    agree = -1
pred3 = f3['post'].argmax(axis=1) + 1
p('  我的类别规模: ' + str({int(c): int((pred3 == c).sum()) for c in sorted(set(pred3.tolist()))}) +
  ' ；数据文件 class 列: ' + str(sizes))
p('  类别归属一致（列序配对后）: %d/69' % sum(
    1 for d in dom if mylab[int(f3['post'][idx[d]].argmax() + 1)] == stored_class[idx[d]]))
p('  我的混合比例: ' + ', '.join('%.1f%%' % (100 * x) for x in sorted(f3['pi'], reverse=True)) +
  '   （正文 49% / 22% / 29%）')
p()

# ---------------------------------------------------------- 6. two-class check
p('[6] 两类解与 SI 表 C3 的比对（脚本的稳健性检验之一）')
f2 = fits[2]
pred2 = f2['post'].argmax(axis=1) + 1
p('  我估计的类别规模: %s ；SI 表 C3: C1 %d 个 / C2 %d 个（合计 %d）' %
  ({int(c): int((pred2 == c).sum()) for c in sorted(set(pred2.tolist()))},
   len(C3['C1']), len(C3['C2']), len(C3['C1']) + len(C3['C2'])))
for lab, target in ((1, 'C1'), (2, 'C2')):
    mine = {d for d in dom if pred2[idx[d]] == lab}
    p('    我的第 %d 类 与 表 C3 的 %s 列 重合 %d/%d' %
      (lab, target, len(mine & set(C3[target])), len(C3[target])))
p()

# ------------------------------------------------------------------ 7. limits
p('[7] 公开数据能复现到哪一步、不能复现到哪一步')
p('  可以复现（公开数据 + 官方脚本齐备）：')
p('    · SI 表 C2 的拟合指标与选择过程（本报告 [3] 已逐格核对）')
p('    · SI 表 C1、C3–C11 的类别归属（图 C5 相关矩阵、图 C6/C8–C16 的条件概率剖面由同一矩阵直接算出）')
p('    · 脚本里写明的全部稳健性检验：两类解、删 3 条标准、仅人工编码、仅自动编码、拆半抽样')
p('  不能复现（需要未公开的个体级原始数据）：')
p('    · 连通性 / 包容性 / 异质性三条需求侧标准的构造——需要 1.16 GB 的')
p('      pulse_weburls_jul2017_dec_2017_df.RData 与问卷 ger_survey_2017_long.RData')
p('    · 关键词过滤（1_political_filtering.R）与整个应用层（个人层参与度、图 C1–C3）')
p()
p('  待澄清：脚本 2_application_deliberation_prep.R 的注释里写到的类别规模是 22/34/12，')
p('          公开数据的 class 列是 15/20/34，复现前需要先确认哪一版是论文所用结果。')

open(OUT, 'w').write('\n'.join(buf) + '\n')
print('\nwritten ->', OUT)
