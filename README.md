---
title: "Read me: convert_tei-to-bibliographic-data"
author: Till Grallert
date: 2019-11-26
ORCID: orcid.org/0000-0002-5739-8094
---

This repository contains code to generate a variety of bibliographic metadata formats for `<tei:div>`s and `<tei:biblStruct>`s. Everything is built upon `<tei:biblStruct>` as an intermediate format and XPath functions. The XSLT is split into basic stylesheets for  functions (file name: `...-functions.xsl`) and stylesheets applying these functions. Note that the functions make use of the `oape` namespace, which is mapped to `xmlns:oape="https://openarabicpe.github.io/ns"`.

1. Input: TEI XML files[^2]
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
    4. Zotero JSON: **to do**
    4. TSS XML: **to do**

# MODS

The [MODS (Metadata Object Description Schema) standard](http://www.loc.gov/standards/mods/) is expressed in XML and maintained by the [Network Development and MARC Standards Office](http://www.loc.gov/marc/ndmso.html) of the Library of Congress with input from users. Compared to BibTeX MODS has he advantage of being properly standardised, human and machine readable, and much better suited to include all the needed bibliographic information.

## MODS as intermediary format

MODS also serves as the intermediary format for the free [bibutils suite](https://sourceforge.net/projects/bibutils/) of conversions between bibliographic metadata formats (including BibTeX) which is under constant development and released under a GNU/GPL (General Public License). `Tei2Mods-issues.xsl` and `bibutils` provide a means to automatically generate a large number of bibliographic formats to suit the reference manager one is working with; e.g.:

- to generate EndNote (refer-format) one only needs the following terminal command: `$ xml2end MODS.xml > output_file.end`
- to generate BibTex: `$ xml2bib MODS.xml > output_file.bib`

## Compatibility with Zotero

Zotero has solid support for MODS import and export. However, there are a number of caveats one should be aware of:

1. Zotero has a limited number of "Item Types" with different fields ([documentation](https://www.zotero.org/support/kb/item_types_and_fields))

    |     Item Type     | Volume | Issue | Place |
    |-------------------|--------|-------|-------|
    | Journal Article   | y      | y     | n     |
    | Magazine Article  | y      | y     | n     |
    | Newspaper Article | n      | n     | y     |

    - Changing the "Item Type" **deletes** fields and their contents
        + there is the option to [use the "extra" field](https://www.zotero.org/support/kb/item_types_and_fields#citing_fields_from_extra) for piping missing information to CSL output but this seems to be a very inellegant work-around to me.
    - Bibliographic data of `<genre authority="local">journal</genre><genre authority="marcgt">journal</genre>` is mapped to "Journal Article" and the journal title will end up as article title with the journal title empty.
2. Zotero does not support multi-language MODS. If information is present in more than one language, i.e. `<title xml:lang="ar">الجنان</title><title xml:lang="ar-Latn-x-ijmes">al-Jinān</title>`, Zotero will always pick the first entry.
3. Zotero does not support non-Gregorian calendars or date ranges.

# BibTeX

<!-- Added reference to principles of minimal computing etc.  -->
[BibTeX](http://www.bibtex.org/Format/) is a plain text format which has been around for more than 30 years and which is widely supported by reference managers. Thus it seems to be a safe bet to preserve and exchange minimal bibliographic data.

There are, however, a number of problems with the format:

- The format and thus the tools implementing it aren't really strict.
- The [format description](http://www.bibtex.org/Format/) is fairly short and since development of BibTeX stalled between 1988 and 2010, it is most definitely not the most current or detailed when it comes to bibliographic metadata descriptions.[^1]
- Only basic information can be included:
    + information on publication dates is commonly limited to year and month only
    + periodicals are not perceived as having different editions or print-runs
    + non-Gregorian calendars cannot be added.

[^1]:[Wikipedia](https://en.wikipedia.org/wiki/BibTeX) has a better description than the official website.
[^2]: Preferably validating against the [OpenArabicPE schema](https://github.com/OpenArabicPE/OpenArabicPE_ODD). All conversion functions work with any `<tei:div>` as input but concrete implementation of conversions is dependent on `@type` attribute values.

# Zotero JSON

The proprietary JSON to directly communicate with the Zotero database / servers through an API has a number of advantages:

- direct writing access to all fields
- full text can be written to notes to provide a simple full-text search