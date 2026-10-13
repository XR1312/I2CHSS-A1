#!/usr/bin/env python3
"""Minimal stdlib-only .xlsx reader: dump sheet names, dims, header + sample rows."""
import sys, zipfile, re, xml.etree.ElementTree as ET

NS = {'m': 'http://schemas.openxmlformats.org/spreadsheetml/2006/main',
      'r': 'http://schemas.openxmlformats.org/officeDocument/2006/relationships'}


def col_idx(ref):
    m = re.match(r'([A-Z]+)', ref or '')
    if not m:
        return 0
    n = 0
    for ch in m.group(1):
        n = n * 26 + (ord(ch) - 64)
    return n - 1


def shared_strings(z):
    out = []
    try:
        root = ET.fromstring(z.read('xl/sharedStrings.xml'))
    except KeyError:
        return out
    for si in root.findall('m:si', NS):
        out.append(''.join(t.text or '' for t in si.iter('{%s}t' % NS['m'])))
    return out


def sheets(z):
    wb = ET.fromstring(z.read('xl/workbook.xml'))
    rels = ET.fromstring(z.read('xl/_rels/workbook.xml.rels'))
    rid2t = {rel.get('Id'): rel.get('Target') for rel in rels}
    out = []
    for s in wb.find('m:sheets', NS):
        rid = s.get('{%s}id' % NS['r'])
        tgt = rid2t.get(rid, '')
        if not tgt.startswith('xl/'):
            tgt = 'xl/' + tgt.lstrip('/')
        out.append((s.get('name'), tgt))
    return out


def read_rows(z, path, ss, max_rows=None):
    rows = []
    try:
        data = z.read(path)
    except KeyError:
        return rows
    root = ET.fromstring(data)
    for row in root.iter('{%s}row' % NS['m']):
        cells = {}
        for c in row.findall('m:c', NS):
            t = c.get('t')
            v = c.find('m:v', NS)
            isnode = c.find('m:is', NS)
            if t == 's' and v is not None:
                val = ss[int(v.text)]
            elif t == 'inlineStr' and isnode is not None:
                val = ''.join(x.text or '' for x in isnode.iter('{%s}t' % NS['m']))
            elif v is not None:
                val = v.text
            else:
                val = ''
            cells[col_idx(c.get('r'))] = val
        if cells:
            width = max(cells) + 1
            rows.append([cells.get(i, '') for i in range(width)])
        else:
            rows.append([])
        if max_rows and len(rows) >= max_rows:
            break
    return rows


def main():
    path = sys.argv[1]
    nrows = int(sys.argv[2]) if len(sys.argv) > 2 else 6
    z = zipfile.ZipFile(path)
    ss = shared_strings(z)
    for name, tgt in sheets(z):
        rows = read_rows(z, tgt, ss, max_rows=nrows)
        print('#' * 78)
        print('SHEET:', name, ' (showing %d rows)' % len(rows))
        for i, r in enumerate(rows):
            cells = [('' if c is None else str(c)) for c in r]
            while cells and cells[-1] == '':
                cells.pop()
            print('  r%-4d| %s' % (i + 1, ' | '.join(cells)))


if __name__ == '__main__':
    main()
