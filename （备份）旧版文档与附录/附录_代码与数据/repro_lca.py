#!/usr/bin/env python3
"""
Reproduce the LCA of Oswald (2024) from the OSF-deposited data + script.

Input : data_public/data_LCA_c_V3.xlsx  (69 domains x 15 binary criteria, as public)
Ref   : SI Table C2 (fit indices, k=1..10), SI Table C1 (class membership), main text.
Method: replicates code/2_measurement_deliberation_LCA.R -- poLCA(f, K, nrep=30, maxiter=3000)
        with the 15-criterion formula from the script (com_mod + hom_vote2 excluded).
"""
import sys, math, itertools
sys.path.insert(0, '/tmp/hw')
import zipfile
import numpy as np
from xlsx_dump import shared_strings, sheets, read_rows


def logsumexp(a, axis=None):
    """scipy-free logsumexp."""
    m = np.max(a, axis=axis, keepdims=True)
    m = np.where(np.isfinite(m), m, 0.0)
    return np.squeeze(m, axis=axis) + np.log(np.sum(np.exp(a - m), axis=axis))

def find_xlsx(name='data_LCA_c_V3.xlsx'):
    """Locate the public input matrix: next to this script, in the copied OSF folder,
    or in 所选论文/osf/... (first hit wins)."""
    import os
    here = os.path.dirname(os.path.abspath(__file__))
    cands = [os.path.join(here, name),
             os.path.join(here, 'osf公开代码与数据', 'data_public', name),
             os.path.join(here, '..', 'osf公开代码与数据', 'data_public', name),
             os.path.expanduser('~/Desktop/SC-1/所选论文/osf/atj5u/files/github/data_public/' + name),
             '/Users/XR1312/Desktop/SC-1/所选论文/osf/atj5u/files/github/data_public/' + name]
    for c in cands:
        if os.path.exists(c):
            return c
    raise SystemExit('找不到 %s，请把它放在本脚本同目录下。已找过：\n  %s' % (name, '\n  '.join(cands)))


FORMULA = ['info_pol', 'info_loc', 'info_qual',
           'com_pr', 'com_rec',
           'par_par', 'par_actor', 'par_orga',
           'isolation_in', 'isolation_out',
           'incl_gender', 'incl_age', 'incl_educ',
           'hom_pol_or', 'hom_vote1']          # exactly the cbind() in the R script


def load():
    z = zipfile.ZipFile(find_xlsx('data_LCA_c_V3.xlsx'))
    ss = shared_strings(z)
    rows = read_rows(z, sheets(z)[0][1], ss)
    hdr, data = rows[0], [r for r in rows[1:] if r and r[0]]
    dom = [r[0] for r in data]
    clicks = [int(float(r[1])) for r in data]
    col = {c: i for i, c in enumerate(hdr)}
    X = np.array([[int(float(r[col[c]])) for c in FORMULA] for r in data], dtype=float)
    stored_class = [r[col['class']] for r in data]
    post = np.array([[float(r[col['X%d' % k]]) for k in (1, 2, 3)] for r in data])
    return dom, clicks, X, stored_class, post


def fit_lca(X, K, n_starts=30, max_iter=3000, tol=1e-5, seed=9876):
    """poLCA-style EM: nrep random starts, keep highest log-likelihood."""
    N, J = X.shape
    rng = np.random.default_rng(seed)
    best = None
    for s in range(n_starts):
        pi = rng.dirichlet(np.ones(K))
        probs = rng.uniform(0.3, 0.7, size=(K, J))
        ll_old = -np.inf
        for _ in range(max_iter):
            lp = np.log(pi)[None, :] + (X @ np.log(probs).T + (1 - X) @ np.log(1 - probs).T)
            ll = float(np.sum(logsumexp(lp, axis=1)))
            post = np.exp(lp - logsumexp(lp, axis=1)[:, None])
            pi = post.mean(axis=0)
            probs = (post.T @ X) / post.sum(axis=0)[:, None]
            probs = np.clip(probs, 1e-10, 1 - 1e-10)
            if abs(ll - ll_old) < tol:
                break
            ll_old = ll
        if best is None or ll > best[0]:
            best = (ll, pi.copy(), probs.copy(), post.copy())
    ll, pi, probs, post = best
    npar = K * J + (K - 1)
    Npat = len({tuple(r) for r in X.tolist()})               # unique response patterns
    resid_df = Npat - npar
    bic = -2 * ll + npar * math.log(N)
    abic = -2 * ll + npar * math.log((N + 2) / 24)
    caic = -2 * ll + npar * (1 + math.log(N))
    aic = -2 * ll + 2 * npar
    # Gsq over observed response patterns
    obs = {}
    for r in X:
        obs[tuple(r.astype(int))] = obs.get(tuple(r.astype(int)), 0) + 1
    Gsq = 0.0
    for pat, n_p in obs.items():
        logp = logsumexp(np.log(pi) + np.array(
            [np.sum(np.log(probs[k]) * np.array(pat) + np.log(1 - probs[k]) * (1 - np.array(pat)))
             for k in range(K)]))
        Gsq += 2 * n_p * math.log(n_p / (N * math.exp(logp)))
    return dict(K=K, llik=ll, npar=npar, resid_df=resid_df, Npat=Npat,
                BIC=bic, aBIC=abic, CAIC=caic, AIC=aic, Gsq=Gsq, pi=pi, post=post)


SI_C2 = {  # verbatim from SI Table C2 (rounded to integers there)
    1: (-651, 54, 1365, 1318, 1380, 833),
    2: (-408, 38, 948, 850, 979, 348),
    3: (-376, 22, 951, 803, 998, 283),
    4: (-353, 6, 972, 774, 1035, 237),
    5: (-337, -10, 1009, 760, 1088, 206),
    6: (-321, -26, 1045, 746, 1140, 174),
    7: (-312, -42, 1094, 744, 1205, 155),
    8: (-301, -58, 1139, 739, 1266, 133),
    9: (-295, -74, 1195, 744, 1338, 121),
    10: (-285, -90, 1244, 743, 1403, 102),
}

if __name__ == '__main__':
    dom, clicks, X, stored_class, post = load()
    print('data: %d domains x %d criteria; clicks total %d' % (X.shape[0], X.shape[1], sum(clicks)))
    print('stored class sizes:', {c: stored_class.count(c) for c in sorted(set(stored_class))})
    print()
    print('Df = N - npar (same as the SI table); the SI\'s column named "AIC" is compared against CAIC.')
    print('%-6s %-8s %-5s %-5s %-7s %-7s %-7s %-6s %-6s | %s' %
          ('K', 'llik', 'npar', 'Df', 'BIC', 'aBIC', 'CAIC', 'Gsq', 'Df_pat',
           'SI Table C2 (ll/Df/BIC/aBIC/AIC/Gsq)'))
    fits = {}
    for K in range(1, 11):
        f = fit_lca(X, K, n_starts=30)
        fits[K] = f
        si = SI_C2.get(K)
        print('%-6d %-8.1f %-5d %-5d %-7.1f %-7.1f %-7.1f %-6.1f %-6d | %s' %
              (K, f['llik'], f['npar'], len(dom) - f['npar'], f['BIC'], f['aBIC'], f['CAIC'],
               f['Gsq'], f['resid_df'],
               'll=%-5s Df=%-4s BIC=%-5s aBIC=%-5s AIC=%-5s Gsq=%s' % si))
    print()
    bics = {K: fits[K]['BIC'] for K in fits}
    print('BIC-minimum K = %d' % min(bics, key=bics.get))
    print('aBIC-minimum K = %d' % min(fits, key=lambda k: fits[k]['aBIC']))
    print('CAIC-minimum K = %d' % min(fits, key=lambda k: fits[k]['CAIC']))
    print('true AIC(-2ll+2npar) minimum K = %d' % min(fits, key=lambda k: fits[k]['AIC']))
    print()
    for K in (2, 3):
        f = fits[K]
        pred = f['post'].argmax(axis=1) + 1
        print('K=%d predicted class sizes: %s ; pi = %s' %
              (K, {int(c): int((pred == c).sum()) for c in sorted(set(pred.tolist()))},
               ', '.join('%.3f' % p for p in f['pi'])))
        agree = sum(1 for a, b in zip(pred, [int(c) for c in stored_class]) if a == b)
        print('   agreement with deposited class labels: %d/%d' % (agree, len(dom)))
