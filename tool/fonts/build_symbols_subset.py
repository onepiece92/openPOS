#!/usr/bin/env python3
"""Rebuilds assets/fonts/OpenPOSSymbols-{Regular,Bold}.ttf.

DEV-ONLY. The app never runs this, and neither does `flutter build`: the two
TTFs are committed and bundled as plain local assets. Run it by hand, with
fontTools in a scratch virtualenv OUTSIDE the repo, only when the subset's
code points or metrics need to change:

    python3 -m venv /tmp/fontvenv && /tmp/fontvenv/bin/pip install fonttools
    /tmp/fontvenv/bin/python tool/fonts/build_symbols_subset.py \
        --noto-sans DIR --noto-bengali DIR --noto-thai DIR

Each DIR holds the source family's Regular and Bold TTFs ("unhinted/ttf" in
the release zip). Sources (SIL OFL 1.1, no Reserved Font Name), from the
official notofonts GitHub releases:

    Noto Sans          v2.015  notofonts/latin-greek-cyrillic  NotoSans-v2.015
    Noto Sans Bengali  v3.011  notofonts/bengali               NotoSansBengali-v3.011
    Noto Sans Thai     v2.002  notofonts/thai                  NotoSansThai-v2.002

What it does, per weight:
  1. Subsets each source to its code points (below), dropping hinting and
     layout tables.
  2. Merges the three into one font named "OpenPOS Symbols".
  3. Copies JetBrains Mono's vertical metrics (hhea ascender, descender and
     lineGap; OS/2 typo and win ascent/descent; USE_TYPO_METRICS), scaling
     to its unitsPerEm first if they differ, so a receipt line with ₹ is no
     taller than one with $.

Keep assets/fonts/OFL.txt's copyright lines in step with SOURCES.
"""

import argparse
import os
import sys

from fontTools import subset
from fontTools.merge import Merger
from fontTools.misc.timeTools import timestampFromString
from fontTools.ttLib import TTFont
from fontTools.ttLib.scaleUpem import scale_upem

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
FONTS = os.path.join(REPO, 'assets', 'fonts')

# The currency symbols JetBrains Mono lacks, by source.
NOTO_SANS_SYMBOLS = [
    0x20A6,  # ₦ naira
    0x20A8,  # ₨ rupee sign (PKR, LKR)
    0x20A9,  # ₩ won
    0x20B1,  # ₱ peso
    0x20B5,  # ₵ cedi
    0x20B9,  # ₹ Indian rupee
]
BENGALI_SYMBOLS = [0x09F3]  # ৳ taka
THAI_SYMBOLS = [0x0E3F]  # ฿ baht

# What sits next to a symbol in an amount, so a fallback run keeps one
# design: space, ASCII punctuation and digits, nbsp, thin and narrow nbsp,
# minus. Letters stay in JetBrains Mono.
COMMON = (
    list(range(0x20, 0x41))  # space ! " ... 0-9 ... @
    + list(range(0x5B, 0x61))  # [ \ ] ^ _ `
    + list(range(0x7B, 0x7F))  # { | } ~
    + [0x00A0, 0x2009, 0x202F, 0x2212]
)

SOURCES = [
    # (argument, file prefix, code points)
    ('noto_sans', 'NotoSans', COMMON + NOTO_SANS_SYMBOLS),
    ('noto_bengali', 'NotoSansBengali', BENGALI_SYMBOLS),
    ('noto_thai', 'NotoSansThai', THAI_SYMBOLS),
]

# The sources' own copyright lines (name ID 0), as in assets/fonts/OFL.txt.
COPYRIGHT = (
    'Copyright 2022 The Noto Project Authors '
    '(https://github.com/notofonts/latin-greek-cyrillic). '
    'Copyright 2025 The Noto Project Authors '
    '(https://github.com/notofonts/bengali). '
    'Copyright 2022 The Noto Project Authors '
    '(https://github.com/notofonts/thai). '
    'Subset and renamed for openPOS.'
)
LICENSE = (
    'This Font Software is licensed under the SIL Open Font License, '
    'Version 1.1. This license is available with a FAQ at: '
    'https://scripts.sil.org/OFL'
)
VERSION = 1.001
# Fixed timestamps keep the output byte-identical between runs.
TIMESTAMP = timestampFromString('Thu Nov 26 00:00:00 2026')


def subset_font(path, codepoints):
    font = TTFont(path)
    opts = subset.Options()
    opts.layout_features = []
    opts.drop_tables += ['GSUB', 'GPOS', 'GDEF', 'STAT', 'meta', 'DSIG']
    opts.hinting = False
    opts.notdef_outline = True
    opts.name_IDs = []
    opts.glyph_names = True
    sub = subset.Subsetter(opts)
    sub.populate(unicodes=codepoints)
    sub.subset(font)
    return font


def copy_vertical_metrics(font, mono):
    upem = mono['head'].unitsPerEm
    if font['head'].unitsPerEm != upem:
        scale_upem(font, upem)
    src_hhea, dst_hhea = mono['hhea'], font['hhea']
    dst_hhea.ascent = src_hhea.ascent
    dst_hhea.descent = src_hhea.descent
    dst_hhea.lineGap = src_hhea.lineGap
    src, dst = mono['OS/2'], font['OS/2']
    dst.sTypoAscender = src.sTypoAscender
    dst.sTypoDescender = src.sTypoDescender
    dst.sTypoLineGap = src.sTypoLineGap
    dst.usWinAscent = src.usWinAscent
    dst.usWinDescent = src.usWinDescent
    use_typo = 1 << 7
    dst.fsSelection = (dst.fsSelection & ~use_typo) | (src.fsSelection & use_typo)


def set_names(font, style):
    name = font['name']
    name.names = []
    for name_id, value in [
        (0, COPYRIGHT),
        (1, 'OpenPOS Symbols'),
        (2, style),
        (3, f'openPOS:OpenPOSSymbols-{style}'),
        (4, f'OpenPOS Symbols {style}'),
        (5, f'Version {VERSION:.3f}'),
        (6, f'OpenPOSSymbols-{style}'),
        (13, LICENSE),
        (14, 'https://scripts.sil.org/OFL'),
    ]:
        name.setName(value, name_id, 3, 1, 0x409)


def build(style, dirs):
    parts = []
    for arg, prefix, codepoints in SOURCES:
        path = os.path.join(dirs[arg], f'{prefix}-{style}.ttf')
        part = subset_font(path, codepoints)
        tmp = os.path.join(dirs['tmp'], f'{prefix}-{style}.subset.ttf')
        part.save(tmp)
        parts.append(tmp)
    font = Merger().merge(parts)

    mono = TTFont(os.path.join(FONTS, f'JetBrainsMono-{style}.ttf'))
    copy_vertical_metrics(font, mono)
    set_names(font, style)

    head = font['head']
    head.fontRevision = VERSION
    head.created = head.modified = TIMESTAMP
    font['post'].formatType = 2.0

    out = os.path.join(FONTS, f'OpenPOSSymbols-{style}.ttf')
    font.recalcTimestamp = False
    font.save(out)

    got = set(TTFont(out).getBestCmap())
    want = set(cp for _, _, cps in SOURCES for cp in cps)
    if got != want:
        sys.exit(f'{out}: cmap differs, missing {sorted(want - got)}')
    print(f'{out}: {len(got)} code points, {os.path.getsize(out)} bytes')


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--noto-sans', required=True)
    ap.add_argument('--noto-bengali', required=True)
    ap.add_argument('--noto-thai', required=True)
    ap.add_argument('--tmp', default=os.environ.get('TMPDIR', '/tmp'))
    args = vars(ap.parse_args())
    for style in ('Regular', 'Bold'):
        build(style, args)


if __name__ == '__main__':
    main()
