---
title: "Read me: convert_tei-to-bibliographic-data"
author: Till Grallert
date: 2019-11-26
---

This repository contains code to generate a variety of bibliographic metadata formats for `<tei:div>`s and `<tei:biblStruct>`s. Everything is built upon `<tei:biblStruct>` as an intermediate format and XPath functions. XSLT is split into basic stylesheets for  functions `...-functions.xsl` and stylesheets applying these functions. Note that the functions make use of the `oape` namespace, which is mapped to `xmlns:oape="https://openarabicpe.github.io/ns"`.

1. Input: TEI XML files.
2. Generate `<tei:biblStruct>`
    - [convert_tei-to-biblstruct_functions.xsl](xslt/convert_tei-to-biblstruct_functions.xsl): provides the necessary function to construct a `<tei:biblStruct>` for a `<tei:div>` using information from the TEI file's `<sourceDesc>` and the `<tei:div>` itself as `oape:bibliography-tei-div-to-biblstruct()`.
    - [convert_tei-to-biblstruct_articles.xsl](xslt/convert_tei-to-biblstruct_articles.xsl): applies the conversion to `<tei:div type="item">`
3. Convert `<tei:biblStruct>` to:
    1. MODS XML: This repository is part of OpenArabicPE, which deals with Arabic source files that come with many non-Gregorian dates. It utilises [XSLT from another repository](https://github.com/tillgrallert/xslt-calendar-conversion) for calendar conversion. One can decide to link to a local copy or use the following lineto include the online version: `<xsl:include href="https://tillgrallert.github.io/xslt-calendar-conversion/functions/date-functions.xsl"/>`.
        - [convert_tei-to-mods_functions.xsl](xslt/convert_tei-to-mods_functions.xsl): provides the function `oape:bibliography-tei-to-mods()` to convert a single `<tei:biblStruct>` to `<mods:mods>`
        - [convert_tei-to-mods_articles.xsl](xslt/convert_tei-to-mods_articles.xsl): chains the functions `oape:bibliography-tei-div-to-biblstruct()` and `oape:bibliography-tei-to-mods()` to generate one MODS XML file per `<tei:div>` as input.
        - [convert_tei-to-mods_issues.xsl](xslt/convert_tei-to-mods_issues.xsl): chains the functions `oape:bibliography-tei-div-to-biblstruct()` and `oape:bibliography-tei-to-mods()` to generate one MODS XML file per TEI XML file as input with `<mods:mods>` children for each `<tei:div>`.
    2. BibTeX
    3. CSV
    4. TSS XML: **to do**