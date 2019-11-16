---
title: "Read me: convert_tei-to-bibliographic-data"
author: Till Grallert
date: 2019-11-16 23:58:52 +0200
---

This repository contains code to generate a variety of bibliographic metadata formats for `<tei:div>`s and `<tei:biblStruct>`s. Everything is built upon `<tei:biblStruct>` as an intermediate format:

1. Input: TEI XML files.
2. Generation of one `<tei:biblStruct>` for each `<tei:div type="item">`
3. Conversion of `<tei:biblStruct>` to:
    1. MODS XML
    2. BibTeX
    3. CSV: **to do**