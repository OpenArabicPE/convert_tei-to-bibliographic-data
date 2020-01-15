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
    1. **MODS XML**: This repository is part of OpenArabicPE, which deals with Arabic source files that come with many non-Gregorian dates. It utilises [XSLT from another repository](https://github.com/tillgrallert/xslt-calendar-conversion) for calendar conversion. One can decide to link to a local copy or use the following lin to include the online version: `<xsl:include href="https://tillgrallert.github.io/xslt-calendar-conversion/functions/date-functions.xsl"/>`.
        - [convert_tei-to-mods_functions.xsl](xslt/convert_tei-to-mods_functions.xsl): provides the function `oape:bibliography-tei-to-mods()` to convert a single `<tei:biblStruct>` to `<mods:mods>`
        - [convert_tei-to-mods_articles.xsl](xslt/convert_tei-to-mods_articles.xsl): chains the functions `oape:bibliography-tei-div-to-biblstruct()` and `oape:bibliography-tei-to-mods()` to generate one MODS XML file per `<tei:div>` as input.
        - [convert_tei-to-mods_issues.xsl](xslt/convert_tei-to-mods_issues.xsl): chains the functions `oape:bibliography-tei-div-to-biblstruct()` and `oape:bibliography-tei-to-mods()` to generate one MODS XML file per TEI XML file as input with `<mods:mods>` children for each `<tei:div>`.
    2. **BibTeX**:
        - [convert_tei-to-bibtex_functions.xsl](xslt/convert_tei-to-bibtex_functions.xsl): provides the function `oape:bibliography-tei-to-bibtex()` to convert a single `<tei:biblStruct>` to BibTeX
        - [convert_tei-to-bibtex_articles.xsl](xslt/convert_tei-to-bibtex_articles.xsl): chains the functions `oape:bibliography-tei-div-to-biblstruct()` and `oape:bibliography-tei-to-bibtex()` to generate one BibTeX file (`.bib`) per `<tei:div>` as input.
        - [convert_tei-to-bibtex_issues.xsl](xslt/convert_tei-to-bibtex_issues.xsl): chains the functions `oape:bibliography-tei-div-to-biblstruct()` and `oape:bibliography-tei-to-bibtex()` to generate one BibTeX file (`.bib`) per TEI XML file as input with one BibTeX child for each `<tei:div>`.
    3. CSV
    4. **YAML**: YAML would be of use for generating a static website from periodical editions, where each article is transformed to markdown with its own metadata block written in YAML in order to keep data and metadata together.
        - [convert_tei-to-yaml_functions.xsl](xslt/convert_tei-to-yaml_functions.xsl): provides the function `oape:bibliography-tei-to-yaml()` to convert a single `<tei:biblStruct>` to YAML
        - [convert_tei-to-yaml_issues.xsl](xslt/convert_tei-to-yaml_issues.xsl): chains the functions `oape:bibliography-tei-div-to-biblstruct()` and `oape:bibliography-tei-to-yaml()` to generate one YAML file (`.yml`) per TEI XML file as input with one YAML child for each `<tei:div>`.
    4. Zotero JSON: **to do**, first draft done
    4. TSS XML: **to do**

# `<tei:biblStruct>`: intermediary / exchange format

- To do:
    + make sure to use only one `<tei:biblStruct>` from the `<tei:sourceDesc>`
    + dereference private URI's pointing to authority files instead of relegating this to later conversions

# MODS

The [MODS (Metadata Object Description Schema) standard](http://www.loc.gov/standards/mods/) is expressed in XML and maintained by the [Network Development and MARC Standards Office](http://www.loc.gov/marc/ndmso.html) of the Library of Congress with input from users. Compared to BibTeX MODS has he advantage of being properly standardised, human and machine readable, and much better suited to include all the needed bibliographic information.

## MODS as intermediary format

MODS also serves as the intermediary format for the free [bibutils suite](https://sourceforge.net/projects/bibutils/) of conversions between bibliographic metadata formats (including BibTeX) which is under constant development and released under a GNU/GPL (General Public License). `Tei2Mods-issues.xsl` and `bibutils` provide a means to automatically generate a large number of bibliographic formats to suit the reference manager one is working with; e.g.:

- to generate EndNote (refer-format) one only needs the following terminal command: `$ xml2end MODS.xml > output_file.end`
- to generate BibTex: `$ xml2bib MODS.xml > output_file.bib`

## Compatibility with Zotero

Zotero has solid support for MODS import and export. However, there are a number of caveats one should be aware of:

1. Zotero has a limited number of "Item Types" with different fields ([documentation](https://www.zotero.org/support/kb/item_types_and_fields))

    |     Item Type     | Volume | Issue | Place | contributorType: editor |
    |-------------------|--------|-------|-------|-------------------------|
    | Journal Article   | y      | y     | n     | y                       |
    | Magazine Article  | y      | y     | n     | n                       |
    | Newspaper Article | n      | n     | y     | n                       |

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

# YAML

A basic conversion to YAML was built by mapping the `<tei:biblStruct>` input to fields using [this example](http://blog.martinfenner.org/2013/07/30/citeproc-yaml-for-bibliographies/), which basically mirrors [CSL JSON]() and should work with [Pandoc]() using the [pandoc-citeproc](https://github.com/jgm/pandoc-citeproc/blob/master/man/pandoc-citeproc.1.md) filter.

# Zotero JSON

The proprietary JSON to directly communicate with the Zotero database / servers through an API has a number of advantages:

- direct writing access to all fields
- full text can be written to notes to provide a simple full-text search

- procedure
    + It seems the easiest to query Zotero through the API
    + translate the resulting JSON with `json-to-xml()` and
    + reverse engineer the resulting XML,
    + which will then be translated to JSON using `xml-to-json()`

- oXygen has a built-in toolchain: JSON to XML and XML to JSON

## sample data
### JSON

```json
{
"data": {
    "DOI": "",
    "ISSN": "",
    "abstractNote": "",
    "accessDate": "",
    "archive": "",
    "archiveLocation": "",
    "callNumber": "",
    "collections": "9FLQJQ88",
    "creators": [
        {
            "creatorType": "editor",
            "firstName": "أنستاس ماري",
            "lastName": "الكرملي"
        },
        {
            "creatorType": "editor",
            "firstName": "كاظم",
            "lastName": "الدجيلي"
        }
    ],
    "date": "1913-11-01",
    "dateAdded": "2019-11-28T10:26:57Z",
    "dateModified": "2019-11-28T10:26:57Z",
    "extra": "",
    "issue": 4,
    "itemType": "journalArticle",
    "journalAbbreviation": "",
    "key": "ABTFWQ5G",
    "language": "",
    "libraryCatalog": "",
    "pages": "216-219",
    "publicationTitle": "لغة العرب: مجلة شهرية ادبية علمية تاريخية",
    "relations": "",
    "rights": "",
    "series": "",
    "seriesText": "",
    "seriesTitle": "",
    "shortTitle": "",
    "title": "باب المشارفة والانتقاد: ٧ - تاريخ الصحافة العربية",
    "url": "https://openarabicpe.github.io/journal_lughat-al-arab/tei/oclc_472450345-i_28.TEIP5.xml#div_11.d2e3751",
    "version": 3238,
    "volume": 3
},
"key": "ABTFWQ5G",
"library": {
    "id": 904125,
    "links": {
        "alternate": {
            "href": "https://www.zotero.org/groups/openarabicpe",
            "type": "text/html"
        }
    },
    "name": "OpenArabicPE",
    "type": "group"
},
"links": {
    "alternate": {
        "href": "https://www.zotero.org/groups/openarabicpe/items/ABTFWQ5G",
        "type": "text/html"
    },
    "self": {
        "href": "https://api.zotero.org/groups/904125/items/ABTFWQ5G",
        "type": "application/json"
    }
},
"meta": {
    "createdByUser": {
        "id": 2028652,
        "links": {
            "alternate": {
                "href": "https://www.zotero.org/till.grallert",
                "type": "text/html"
            }
        },
        "name": "Till Grallert",
        "username": "till.grallert"
    },
    "creatorSummary": "الكرملي and الدجيلي",
    "numChildren": 0,
    "parsedDate": "1913-11-01"
},
"version": 3238
}
```
### XML (conversion: oXygen)

```xml
<array>
    <key>ABTFWQ5G</key>
    <version>3238</version>
    <library>
        <type>group</type>
        <id>904125</id>
        <name>OpenArabicPE</name>
        <links>
            <alternate>
                <href>https://www.zotero.org/groups/openarabicpe</href>
                <type>text/html</type>
            </alternate>
        </links>
    </library>
    <links>
        <self>
            <href>https://api.zotero.org/groups/904125/items/ABTFWQ5G</href>
            <type>application/json</type>
        </self>
        <alternate>
            <href>https://www.zotero.org/groups/openarabicpe/items/ABTFWQ5G</href>
            <type>text/html</type>
        </alternate>
    </links>
    <meta>
        <createdByUser>
            <id>2028652</id>
            <username>till.grallert</username>
            <name>Till Grallert</name>
            <links>
                <alternate>
                    <href>https://www.zotero.org/till.grallert</href>
                    <type>text/html</type>
                </alternate>
            </links>
        </createdByUser>
        <creatorSummary>الكرملي and الدجيلي</creatorSummary>
        <parsedDate>1913-11-01</parsedDate>
        <numChildren>0</numChildren>
    </meta>
    <data>
        <key>ABTFWQ5G</key>
        <version>3238</version>
        <itemType>journalArticle</itemType>
        <title>باب المشارفة والانتقاد: ٧ - تاريخ الصحافة العربية</title>
        <creators>
            <creatorType>editor</creatorType>
            <firstName>أنستاس ماري</firstName>
            <lastName>الكرملي</lastName>
        </creators>
        <creators>
            <creatorType>editor</creatorType>
            <firstName>كاظم</firstName>
            <lastName>الدجيلي</lastName>
        </creators>
        <abstractNote></abstractNote>
        <publicationTitle>لغة العرب: مجلة شهرية ادبية علمية تاريخية</publicationTitle>
        <volume>3</volume>
        <issue>4</issue>
        <pages>216-219</pages>
        <date>1913-11-01</date>
        <series></series>
        <seriesTitle></seriesTitle>
        <seriesText></seriesText>
        <journalAbbreviation></journalAbbreviation>
        <language></language>
        <DOI></DOI>
        <ISSN></ISSN>
        <shortTitle></shortTitle>
        <url>https://openarabicpe.github.io/journal_lughat-al-arab/tei/oclc_472450345-i_28.TEIP5.xml#div_11.d2e3751</url>
        <accessDate></accessDate>
        <archive></archive>
        <archiveLocation></archiveLocation>
        <libraryCatalog></libraryCatalog>
        <callNumber></callNumber>
        <rights></rights>
        <extra></extra>
        <collections>9FLQJQ88</collections>
        <relations></relations>
        <dateAdded>2019-11-28T10:26:57Z</dateAdded>
        <dateModified>2019-11-28T10:26:57Z</dateModified>
    </data>
</array>
```