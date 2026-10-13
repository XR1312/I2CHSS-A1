#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
LCA 复现方案的可行性验证（pipeline smoke test）
------------------------------------------------
用途：证明"69 个网站 × 15 条二值标准 → 潜类别分析（EM 算法）"这条技术路线在本机可跑通。
注意：本脚本使用的是【合成数据】（按论文报告的 34/15/20 类别规模与混合比例 49%/22%/29%
构造），得到的数字仅用于验证代码与流程，不代表对 Oswald (2024) 真实数据的复现结果。

输出：/tmp/hw/out/smoke_*.png  与  /tmp/hw/out/smoke_results.txt
"""
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

rng = np.random.default_rng(20240425)

# ---------------------------------------------------------------
# 1. 构造合成数据：3 个潜类别，15 条二值指标，类别规模按 34/15/20
# ---------------------------------------------------------------
K_TRUE = 3
N_IND = 15
SIZES = [34, 15, 20]              # 与 SI 表 C1 的 class1/class2/class3 一致
MIX_TRUE = np.array(SIZES) / sum(SIZES)   # 49.3% / 21.7% / 29.0%

# 三个类别的"标准满足概率"（供方 8 条 + 需方 7 条，仅示意，不代表论文估计值）
PROFILE = np.array([
    [0.75] * 8 + [0.80] * 7,      # class 1: 主流枢纽 —— 连接性强、信息/沟通一般
    [0.90] * 4 + [0.85] * 4 + [0.35] * 7,   # class 2: 优质信息提供者 —— 供方强、需方弱
    [0.30] * 8 + [0.45] * 7,      # class 3: 小众论坛 —— 参与/沟通相对强、连接性弱
])

z_true = np.repeat(np.arange(K_TRUE), SIZES)
X = np.zeros((len(z_true), N_IND), dtype=int)
for i, k in enumerate(z_true):
    X[i] = rng.binomial(1, PROFILE[k])

# ---------------------------------------------------------------
# 2. 二值 LCA：EM 算法（与 R 的 poLCA 同类模型，此处自实现以保证可复现）
# ---------------------------------------------------------------
def logsumexp(a, axis):
    m = np.max(a, axis=axis, keepdims=True)
    return (m + np.log(np.sum(np.exp(a - m), axis=axis, keepdims=True))).squeeze(axis)

def fit_lca(X, K, n_starts=30, max_iter=500, tol=1e-7, seed=1):
    """返回 (loglik, pi, probs, post) —— pi: 类别比例; probs: K×J 条件满足概率; post: N×K 后验"""
    N, J = X.shape
    best = None
    for s in range(n_starts):
        r = np.random.default_rng(seed + s)
        pi = r.dirichlet(np.ones(K))
        probs = r.uniform(0.25, 0.75, size=(K, J))
        ll_old = -np.inf
        for _ in range(max_iter):
            # E 步
            lp = np.log(pi)[None, :] + (X @ np.log(probs).T
                                        + (1 - X) @ np.log(1 - probs).T)
            ll = float(np.sum(logsumexp(lp, axis=1)))
            post = np.exp(lp - logsumexp(lp, axis=1)[:, None])
            # M 步
            nk = post.sum(axis=0)
            pi = nk / N
            probs = (post.T @ X + 1e-6) / (nk[:, None] + 2e-6)
            if abs(ll - ll_old) < tol:
                break
            ll_old = ll
        # 计算参数个数：K-1 个混合比例 + K*J 个条件概率（poLCA 的 df 反映的是自由度差，此处按常规口径）
        df = (K - 1) + K * J
        bic = -2 * ll + df * np.log(N)
        abic = -2 * ll + df * np.log((N + 2) / 24)
        if best is None or ll > best[0]:
            best = (ll, bic, abic, pi, probs, post)
    return best

print("=" * 62)
print("LCA 流程可行性验证（合成数据，非论文结果复现）")
print("=" * 62)
rows = []
models = {}
for K in range(1, 7):
    ll, bic, abic, pi, probs, post = fit_lca(X, K)
    models[K] = (pi, probs, post)
    rows.append((K, ll, bic, abic))
    print(f"K={K}  logLik={ll:9.3f}  BIC={bic:9.3f}  aBIC={abic:9.3f}")

bic_best = min(rows, key=lambda r: r[2])[0]
abic_best = min(rows, key=lambda r: r[3])[0]
print(f"\n合成数据上 BIC 最小解：K={bic_best}；aBIC 最小解：K={abic_best}")
print("真实类别规模：34 / 15 / 20，混合比例：49.3% / 21.7% / 29.0%")

# 用 K=3 的估计结果与真值比较
pi3, probs3, post3 = models[3]
order = np.argsort(-pi3)
print("\nK=3 估计的类别规模（按估计比例排序）：",
      [int(round(p * len(z_true))) for p in pi3[order]])
print("K=3 估计的混合比例：", np.round(pi3[order] * 100, 1), "%")

# 分类一致性（匈牙利式按比例匹配的简易版本：按估计类别规模降序 vs 真实规模降序）
est_z = post3.argmax(axis=1)
est_sorted = np.argsort(-np.bincount(est_z, minlength=3))
true_sorted = np.argsort(-np.array(SIZES))
remap = {e: t for e, t in zip(est_sorted, true_sorted)}
est_mapped = np.array([remap[e] for e in est_z])
acc = float((est_mapped == z_true).mean())
print(f"K=3 时与真实类别的吻合率（accuracy）：{acc:.3f}")

# ---------------------------------------------------------------
# 3. 出图：BIC/aBIC 曲线 + 类别条件概率剖面
# ---------------------------------------------------------------
Ks = [r[0] for r in rows]
fig, ax = plt.subplots(1, 2, figsize=(11, 4))
ax[0].plot(Ks, [r[2] for r in rows], "o-", label="BIC")
ax[0].plot(Ks, [r[3] for r in rows], "s--", label="aBIC")
ax[0].set_xlabel("number of latent classes (K)")
ax[0].set_ylabel("information criterion")
ax[0].set_title("Model fit comparison (synthetic data)")
ax[0].legend()
ax[0].grid(alpha=0.3)

for k in range(3):
    ax[1].plot(range(1, N_IND + 1), probs3[k], "o-", label=f"est. class {k+1}")
ax[1].set_xlabel("binary criterion (1-8 supply, 9-15 demand)")
ax[1].set_ylabel("conditional probability")
ax[1].set_title("Class-conditional response profiles (K=3)")
ax[1].legend(fontsize=8)
ax[1].grid(alpha=0.3)
fig.tight_layout()
import os
os.makedirs("/tmp/hw/out", exist_ok=True)
fig.savefig("/tmp/hw/out/smoke_lca.png", dpi=150)
print("\n图已保存：/tmp/hw/out/smoke_lca.png")

# ---------------------------------------------------------------
# 4. 灵敏度分析：类别可分性 × 样本量的作用
#    （回答"69 个观测做 15 指标 LCA 是否足够"这一可行性问题）
# ---------------------------------------------------------------
def make_data(sep, seed):
    r = np.random.default_rng(seed)
    prof = np.clip(np.array([
        [0.5 + sep] * 8 + [0.5 + sep] * 7,
        [0.5 + sep] * 8 + [0.5 - sep] * 7,
        [0.5 - sep] * 8 + [0.5 + sep * 0.5] * 7,
    ]), 0.02, 0.98)
    z = np.repeat(np.arange(3), SIZES)
    Xx = np.zeros((len(z), N_IND), dtype=int)
    for i, kk in enumerate(z):
        Xx[i] = r.binomial(1, prof[kk])
    return Xx, z

print("\n灵敏度分析（每格 20 次重复）")
print(f"{'可分性':<10}{'BIC选K=2比例':>14}{'BIC选K=3比例':>14}{'K=3吻合率':>12}")
for sep in (0.15, 0.25, 0.35):
    n2 = n3 = 0
    accs = []
    for rep in range(20):
        Xx, zz = make_data(sep, 1000 + rep)
        fits = {K: fit_lca(Xx, K, n_starts=15, seed=rep + 1) for K in (2, 3, 4)}
        kb = min(fits, key=lambda K: fits[K][1])   # BIC 最小
        n2 += (kb == 2)
        n3 += (kb == 3)
        p = fits[3][5]
        e = p.argmax(axis=1)
        es = np.argsort(-np.bincount(e, minlength=3))
        ts = np.argsort(-np.array(SIZES))
        mp = {a: b for a, b in zip(es, ts)}
        accs.append(float((np.array([mp[x] for x in e]) == zz).mean()))
    print(f"{sep:<10}{n2/20:>14.2f}{n3/20:>14.2f}{np.mean(accs):>12.3f}")
