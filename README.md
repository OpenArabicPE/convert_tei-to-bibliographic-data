---
title: "Read me: convert_tei-to-bibliographic-data"
author: Till Grallert
date: 2024-11-22
ORCID: orcid.org/0000-0002-5739-8094
lang: en
---

This repository contains XSLT stylesheets

1. to generate `<tei:biblStruct>`s for TEI/XML files and their fragments, such as individual `<tei:div>` nodes, which, in the case of our periodical editions contain the text of individual articles;
2. to convert between multiple bibliographic XML formats, among them MODS/XML, MARCXML, BibTeX, and Zotero RDF.

Everything is built upon `<tei:biblStruct>` as an intermediate format and XPath functions. The XSLT is split into basic stylesheets for  functions (file name: `...-functions.xsl`) and stylesheets applying these functions. Note that the functions make use of the `oape` namespace, which is mapped to `xmlns:oape="https://openarabicpe.github.io/ns"`.

# XSLT stylesheets
## Generate `<tei:biblStruct>` as intermediary format

Output of the stylesheets is always is a self-contained TEI/XML file with all bibliographic data from the input written to `tei:TEI/tei:standOff`. 

### from TEI/XML

- [convert_tei-to-biblstruct_functions.xsl](xslt/convert_tei-to-biblstruct_functions.xsl): provides the necessary function to construct a `<tei:biblStruct>` for a `<tei:div>` using information from the TEI/XML file's `<sourceDesc>`, and the `<tei:div>` itself as `oape:bibliography-tei-div-to-biblstruct()`.
- [convert_tei-to-biblstruct_articles.xsl](xslt/convert_tei-to-biblstruct_articles.xsl): applies the conversion to `<tei:div type="item">`
- [convert_tei-to-biblstruct_fileDesc.xsl](xslt/convert_tei-to-biblstruct_fileDesc.xsl): applies conversions to `<tei:fileDesc>` and constructs a `<tei:biblStruct>` with the metadata for a given TEI/XML file.

### from MARCXML

These were developed and tested for the conversion of library catalogue data for mostly Arabic periodicals

- [convert_marc-xml-to-tei_functions.xsl](xslt/convert_marc-xml-to-tei_functions.xsl): provides the necessary function to construct a `<tei:biblStruct>` for a `<marc:record>`.
    - This conversion relies on other repositories for the conversion of ISIL RDF to TEI/XML.
- [convert_marc-xml-to-tei_file.xsl](xslt/convert_marc-xml-to-tei_file.xsl): applies conversions to `<tei:fileDesc>` and constructs a lists of 
    + `<tei:biblStruct>`: for each bibliographic item
    + `<tei:person>`: for each editor
    + `<tei:org>`: for each holding institution

### from MODS/XML

- [convert_mods-to-tei_functions.xsl](xslt/convert_mods-to-tei_functions.xsl): provides the function `oape:bibliography-mods-to-tei()` to construct a `<tei:biblStruct>` from a `<mods:mods>`.
- [convert_mods-to-tei_file.xsl](xslt/convert_mods-to-tei_file.xsl): applies conversions to `<mods:mods>` and constructs a lists of 
    + `<tei:biblStruct>`: for each bibliographic item
    + `<tei:org>`: for each holding institution

### from RDF/XML

These were developed and tested for the conversion of library catalogue data for mostly Arabic periodicals

- [convert_rdf-to-tei_functions.xsl](xslt/convert_rdf-to-tei_functions.xsl): provides the necessary function to construct a `<tei:biblStruct>` for a `<rdf:Description>`. Conversion is done in two steps: first to an unstructured `<tei:bibl>` and then to `<tei:biblStruct>`.
- [convert_rdf-to-tei_file.xsl](xslt/convert_rdf-to-tei_file.xsl): applies conversions to `<rdf:Description>` and constructs a lists of `<tei:biblStruct>`. 

## Convert `<tei:biblStruct>` to other formats

All stylesheets use TEI/XML files or fragments[^2] as input.

[^2]: Preferably validating against the [OpenArabicPE schema](https://github.com/OpenArabicPE/OpenArabicPE_ODD). All conversion functions work with any `<tei:div>` as input but concrete implementation of conversions is dependent on `@type` attribute values.

### to BibTeX

- [convert_tei-to-bibtex_functions.xsl](xslt/convert_tei-to-bibtex_functions.xsl): provides the function `oape:bibliography-tei-to-bibtex()` to convert a single `<tei:biblStruct>` to BibTeX
- [convert_tei-to-bibtex_articles.xsl](xslt/convert_tei-to-bibtex_articles.xsl): chains the functions `oape:bibliography-tei-div-to-biblstruct()` and `oape:bibliography-tei-to-bibtex()` to generate one BibTeX file (`.bib`) per `<tei:div>` as input.
- [convert_tei-to-bibtex_issues.xsl](xslt/convert_tei-to-bibtex_issues.xsl): chains the functions `oape:bibliography-tei-div-to-biblstruct()` and `oape:bibliography-tei-to-bibtex()` to generate one BibTeX file (`.bib`) per TEI XML file as input with one BibTeX child for each `<tei:div>`.

### to CSV
### to MODS/XML

The conversions utilise [XSLT from another repository](https://github.com/tillgrallert/xslt-calendar-conversion) for calendar conversions. One can decide to link to a local copy or use the following link to include the online version: `<xsl:include href="https://tillgrallert.github.io/xslt-calendar-conversion/functions/date-functions.xsl"/>`.

- [convert_tei-to-mods_functions.xsl](xslt/convert_tei-to-mods_functions.xsl): provides the function `oape:bibliography-tei-to-mods()` to convert a single `<tei:biblStruct>` to `<mods:mods>`
- [convert_tei-to-mods_articles.xsl](xslt/convert_tei-to-mods_articles.xsl): chains the functions `oape:bibliography-tei-div-to-biblstruct()` and `oape:bibliography-tei-to-mods()` to generate one MODS XML file per `<tei:div>` as input.
- [convert_tei-to-mods_issues.xsl](xslt/convert_tei-to-mods_issues.xsl): chains the functions `oape:bibliography-tei-div-to-biblstruct()` and `oape:bibliography-tei-to-mods()` to generate one MODS XML file per TEI XML file as input with `<mods:mods>` children for each `<tei:div>`.
- [convert_tei-to-mods_fileDesc.xsl](xslt/convert_tei-to-mods_fileDesc.xsl): chains the conversions from `<tei:fileDesc>` to `<tei:biblStruct>` to `<mods:mods>` to generate the metadata for a given TEI/XML file.

### to custom Wikidata XML

Developed to push bibliographic data for Arabic and Ottoman periodicals to Wikidata. A preprint describing the data model can found [here](https://zenodo.org/records/14112648). Ouput is a custom XML serialisation for import into OpenRefine.

- [convert_tei-to-wikidata-import_functions.xsl](xsl/convert_tei-to-wikidata-import_functions.xsl): provides the necessary functions to convert `<tei:biblStruct>`, `<tei:person>`, and `<tei:org>` to a Wikidata data model.
- [convert_tei-to-wikidata-import_file.xsl](xsl/convert_tei-to-wikidata-import_file.xsl): applies the functions to input TEI/XML files.

### to YAML

YAML would be of use for generating a static website from periodical editions, where each article is transformed to markdown with its own metadata block written in YAML in order to keep data and metadata together.

- [convert_tei-to-yaml_functions.xsl](xslt/convert_tei-to-yaml_functions.xsl): provides the function `oape:bibliography-tei-to-yaml()` to convert a single `<tei:biblStruct>` to YAML
- [convert_tei-to-yaml_issues.xsl](xslt/convert_tei-to-yaml_issues.xsl): chains the functions `oape:bibliography-tei-div-to-biblstruct()` and `oape:bibliography-tei-to-yaml()` to generate one YAML file (`.yml`) per TEI XML file as input with one YAML child for each `<tei:div>`.

### to Zotero RDF

Zotero RDF is a proprietary RDF and serialised as XML, which allows lossless import into Zotero and moving data between Zotero libraries

- [convert_tei-to-zotero-rdf_functions.xsl](xslt/convert_tei-to-zotero-rdf_functions.xsl): provides the function `oape:bibliography-tei-to-zotero-rdf()` to convert a single `<tei:biblStruct>` to `<bib:{reference-type}>`
- [convert_tei-to-zotero-rdf_articles.xsl](xslt/convert_tei-to-zotero-rdf_articles.xsl): chains the functions `oape:bibliography-tei-div-to-biblstruct()` and `oape:bibliography-tei-to-zotero-rdf()` to generate one Zotero RDF file per `<tei:div>` as input.
- [convert_tei-to-zotero-rdf_issues.xsl](xslt/convert_tei-to-zotero-rdf_issues.xsl): chains the functions `oape:bibliography-tei-div-to-biblstruct()` and `oape:bibliography-tei-to-zotero-rdf()` to generate one Zotero RDF file per TEI XML file as input with `<bib:{reference-type}>` children for each `<tei:div>`.


# `<tei:biblStruct>`: intermediary / exchange format

- To do:
    + dereference private URI's pointing to authority files instead of relegating this to later conversions

The intermediary/exchange format between all the supported serialisations of bibliographic metadata is a TEI `<biblStruct>` element.

## example

```xml
<biblStruct>
   <analytic>
      <title level="a" xml:lang="ar">حكم وخواطر</title>
      <author>
         <persName ref="viaf:73935498 jaraid:pers:1690 oape:pers:242 wiki:Q2474371" xml:lang="ar">
            <forename xml:lang="ar">شكيب</forename>
            <surname xml:lang="ar">ارسلان</surname>
         </persName>
      </author>
      <idno type="url">https://github.com/OpenArabicPE/journal_al-muqtabas/blob/master/tei/oclc_4770057679-i_14.TEIP5.xml#div_6.d1e1249</idno>
      <idno type="url">https://OpenArabicPE.github.io/journal_al-muqtabas/tei/oclc_4770057679-i_14.TEIP5.xml#div_6.d1e1249</idno>
      <idno type="BibTeX">oclc_4770057679-i_14-div_6.d1e1249</idno>
   </analytic>
   <monogr>
      <title level="j" xml:lang="ar">المقتبس</title>
      <title level="j" type="sub" xml:lang="ar">مجلة أدبية علمية اجتماعية تصدر ب
         <placeName xml:lang="ar">القاهرة</placeName>
         في غرة كل شهر عربي</title>
      <title level="j" xml:lang="ar-Latn-x-ijmes">al-Muqtabas</title>
      <title level="j" type="sub" xml:lang="ar-Latn-x-ijmes">Majalla adabiyya ʿilmiyya ijtimāʿiyya tuṣadir bi-l-Qāhira fī gharrat kull shahr ʿarabī</title>
      <title level="j" xml:lang="fr">Al-Moktabas</title>
      <title level="j" type="sub" xml:lang="fr">Revue mensuelle, littéraire, scientifique &amp; Sociologique</title>
      <idno type="OCLC" xml:lang="en">4770057679</idno>
      <idno type="OCLC" xml:lang="en">79440195</idno>
      <idno type="aucr" xml:lang="en">07201136864</idno>
      <idno type="shamela" xml:lang="en">26523</idno>
      <idno type="zenodo" xml:lang="en">45922152</idno>
      <idno type="URI">oclc_4770057679-i_14</idno>
      <textLang mainLang="ar"/>
      <editor ref="viaf:32272677" xml:lang="en">
         <persName ref="viaf:32272677 oape:pers:878 wiki:Q3123742" xml:lang="ar">
            <forename xml:lang="ar">محمد</forename>
            <surname xml:lang="ar">كرد علي</surname>
         </persName>
         <persName ref="viaf:32272677 oape:pers:878 wiki:Q3123742" xml:lang="ar-Latn-x-ijmes">
            <forename xml:lang="ar-Latn-x-ijmes">Muḥammad</forename>
            <surname xml:lang="ar-Latn-x-ijmes">Kurd ʿAlī</surname>
         </persName>
      </editor>
      <imprint xml:lang="en">
         <publisher xml:lang="en">
            <orgName xml:lang="ar">مطبعة الظاهر</orgName>
            <orgName xml:lang="ar-Latn-x-ijmes">Maṭbaʿa al-Ẓāhir</orgName>
         </publisher>
         <publisher xml:lang="en">
            <orgName xml:lang="ar">المطبعة العمومية</orgName>
            <orgName xml:lang="ar-Latn-x-ijmes">al-Maṭbaʿa al-ʿUmūmiyya</orgName>
         </publisher>
         <pubPlace xml:lang="en">
            <placeName ref="oape:place:226 geon:360630" xml:lang="ar">القاهرة</placeName>
            <placeName ref="oape:place:226 geon:360630" xml:lang="ar-Latn-x-ijmes">al-Qāhira</placeName>
            <placeName ref="oape:place:226 geon:360630" xml:lang="fr">Caire</placeName>
            <placeName ref="oape:place:226 geon:360630" xml:lang="en">Cairo</placeName>
         </pubPlace>
         <date calendar="#cal_gregorian" datingMethod="#cal_gregorian" type="official" when="1907-03-16" xml:lang="ar-Latn-x-ijmes">16 March 1907</date>
         <date calendar="#cal_islamic" datingMethod="#cal_islamic" type="computed" when="1907-03-16" when-custom="1325-02-01" xml:lang="ar-Latn-x-ijmes">1 Ṣafār 1325</date>
      </imprint>
      <biblScope from="2" to="2" unit="volume" xml:lang="en"/>
      <biblScope from="2" to="2" unit="issue" xml:lang="en"/>
      <biblScope from="78" to="82" unit="page">78-82</biblScope>
   </monogr>
</biblStruct>
```

# MODS

The [MODS (Metadata Object Description Schema) standard](http://www.loc.gov/standards/mods/) is expressed in XML and maintained by the [Network Development and MARC Standards Office](http://www.loc.gov/marc/ndmso.html) of the Library of Congress with input from users. Compared to BibTeX MODS has he advantage of being properly standardised, human and machine readable, and much better suited to include all the needed bibliographic information.

## example

```xml
<mods>
  <titleInfo>
     <title xml:lang="ar">حكم وخواطر</title>
  </titleInfo>
  <typeOfResource>text</typeOfResource>
  <genre authority="local" xml:lang="en">journalArticle</genre>
  <genre authority="marcgt" xml:lang="en">article</genre>
  <name type="personal" xml:lang="ar" valueURI="https://viaf.org/viaf/73935498">
     <namePart type="family" xml:lang="ar">ارسلان</namePart>
     <namePart type="given" xml:lang="ar">شكيب</namePart>
     <role>
        <roleTerm authority="marcrelator" type="code">aut</roleTerm>
     </role>
  </name>
  <relatedItem type="host">
     <titleInfo>
        <title xml:lang="ar">المقتبس</title>
        <subTitle xml:lang="ar">مجلة أدبية علمية اجتماعية تصدر بالقاهرة في غرة كل شهر عربي</subTitle>
     </titleInfo>
     <genre authority="marcgt">journal</genre>
     <name type="personal" xml:lang="ar" valueURI="https://viaf.org/viaf/32272677">
        <namePart type="family" xml:lang="ar">كرد علي</namePart>
        <namePart type="given" xml:lang="ar">محمد</namePart>
        <role>
           <roleTerm authority="marcrelator" type="code">edt</roleTerm>
        </role>
     </name>
     <originInfo>
        <place>
           <placeTerm type="text" xml:lang="ar"valueURI="https://www.geonames.org/360630">القاهرة</placeTerm>
        </place>
        <publisher xml:lang="ar">مطبعة الظاهر</publisher>
        <publisher xml:lang="ar-Latn-x-ijmes">Maṭbaʿa al-Ẓāhir</publisher>
        <publisher xml:lang="ar">المطبعة العمومية</publisher>
        <publisher xml:lang="ar-Latn-x-ijmes">al-Maṭbaʿa al-ʿUmūmiyya</publisher>
        <dateIssued encoding="w3cdtf">1907-03-16</dateIssued>
        <dateOther calendar="islamic">1325-02-01</dateOther>
        <dateOther>1325-02-01 [1907-03-16]</dateOther>
        <issuance>continuing</issuance>
     </originInfo>
     <part>
        <detail type="volume">
           <number>2</number>
        </detail>
        <detail type="issue">
           <number>2</number>
        </detail>
        <extent unit="pages">
           <start>78</start>
           <end>82</end>
        </extent>
     </part>
     <identifier type="BibTeX">oclc_4770057679-i_14-div_6.d1e1249</identifier>
     <identifier type="OCLC">4770057679</identifier>
     <identifier type="OCLC">79440195</identifier>
     <identifier type="aucr">07201136864</identifier>
     <identifier type="shamela">26523</identifier>
     <identifier type="zenodo">45922152</identifier>
     <identifier type="URI">oclc_4770057679-i_14</identifier>
  </relatedItem>
  <accessCondition>http://creativecommons.org/licenses/by-sa/4.0/</accessCondition>
  <location>
     <url usage="primary display">https://github.com/OpenArabicPE/journal_al-muqtabas/blob/master/tei/oclc_4770057679-i_14.TEIP5.xml#div_6.d1e1249</url>
     <url usage="primary display">https://OpenArabicPE.github.io/journal_al-muqtabas/tei/oclc_4770057679-i_14.TEIP5.xml#div_6.d1e1249</url>
  </location>
  <language>
     <languageTerm type="code" authorityURI="http://www.iana.org/assignments/language-subtag-registry/language-subtag-registry">ar</languageTerm>
  </language>
</mods>
```

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


## example

```bibtex
@ARTICLE{oclc_4770057679-i_14-div_6.d1e1249, 
author = {ارسلان, شكيب}, 
editor = {كرد علي, محمد}, 
title = {حكم وخواطر}, 
journal = {المقتبس: مجلة أدبية علمية اجتماعية تصدر بالقاهرة في غرة كل شهر عربي}, 
volume = {2}, 
number = {2}, 
pages = {78-82}, 
publisher = {مطبعة الظاهر}, 
publisher = {المطبعة العمومية}, 
address = {القاهرة}, 
language = {ar}, 
day = {16}, 
month = {3}, 
year = {1907}, 
url = {https://github.com/OpenArabicPE/journal_al-muqtabas/blob/master/tei/oclc_4770057679-i_14.TEIP5.xml#div_6.d1e1249}, 
annote = {digital TEI edition, 2021}, 
}
```

# YAML

A basic conversion to YAML was built by mapping the `<tei:biblStruct>` input to fields using [this example](http://blog.martinfenner.org/2013/07/30/citeproc-yaml-for-bibliographies/), which basically mirrors [CSL JSON]() and should work with [Pandoc]() using the [pandoc-citeproc](https://github.com/jgm/pandoc-citeproc/blob/master/man/pandoc-citeproc.1.md) filter.

## example

```yaml
- id: 'oclc_4770057679-i_14-div_6.d1e1249'
  title: ' حكم وخواطر'
  container-title: 'المقتبس: مجلة أدبية علمية اجتماعية تصدر بالقاهرةفي غرة كل شهر عربي'
  volume: '2'
  issue: '2'
  page: '78-82'
  URL: 
  - 'https://github.com/OpenArabicPE/journal_al-muqtabas/blob/master/tei/oclc_4770057679-i_14.TEIP5.xml#div_6.d1e1249'
  - 'https://OpenArabicPE.github.io/journal_al-muqtabas/tei/oclc_4770057679-i_14.TEIP5.xml#div_6.d1e1249'
  OCLC: 
  - '4770057679'
  - '79440195'
  author: 
  - family: 'ارسلان'
    given: 'شكيب'

  editor: 
  - family: 'كرد علي'
    given: 'محمد'

  language: ar
  type: 
  issued: '1907-03-16'
```

# Zotero RDF

- full conversion pipelines have been implemented
- In order to generate stable cite keys, we make use of Better BibTeX and write our identifiers to the 'Citation Key: ' line in the extra field. Note that this line is deleted when dragging and dropping references between libraries or groups. Therefore, we also added a 'BibTeX: ' line with the same content to the extra field

## example

```xml
<bib:Article rdf:about="#oclc_4770057679-i_14-div_6.d1e1249">
   <z:itemType>magazineArticle</z:itemType>
   <dcterms:isPartOf>
      <bib:Periodical>
         <prism:volume>2</prism:volume>
         <prism:number>2</prism:number>
         <dc:title>المقتبس: مجلة أدبية علمية اجتماعية تصدر بالقاهرة في غرة كل شهر عربي</dc:title>
      </bib:Periodical>
   </dcterms:isPartOf>
   <dc:title>حكم وخواطر</dc:title>
   <z:shortTitle>حكم وخواطر</z:shortTitle>
   <bib:authors>
      <rdf:Seq>
         <rdf:li>
            <foaf:Person>
               <foaf:surname>ارسلان</foaf:surname>
               <foaf:givenName>شكيب</foaf:givenName>
            </foaf:Person>
         </rdf:li>
      </rdf:Seq>
   </bib:authors>
   <bib:editors>
      <rdf:Seq>
         <rdf:li>
            <foaf:Person>
               <foaf:surname>كرد علي</foaf:surname>
               <foaf:givenName>محمد</foaf:givenName>
            </foaf:Person>
         </rdf:li>
      </rdf:Seq>
   </bib:editors>
   <dc:publisher>
      <foaf:Organization>
         <vcard:adr>
            <vcard:Address>
               <vcard:locality>القاهرة</vcard:locality>
            </vcard:Address>
         </vcard:adr>
         <foaf:name>مطبعة الظاهر المطبعة العمومية</foaf:name>
      </foaf:Organization>
   </dc:publisher>
   <dc:identifier>
      <dcterms:URI>
         <rdf:value>https://github.com/OpenArabicPE/journal_al-muqtabas/blob/master/tei/oclc_4770057679-i_14.TEIP5.xml#div_6.d1e1249</rdf:value>
      </dcterms:URI>
   </dc:identifier>
   <dc:identifier>
      <dcterms:URI>
         <rdf:value>https://OpenArabicPE.github.io/journal_al-muqtabas/tei/oclc_4770057679-i_14.TEIP5.xml#div_6.d1e1249</rdf:value>
      </dcterms:URI>
   </dc:identifier>
   <bib:pages>78-82</bib:pages>
   <dc:date>1907-03-16</dc:date>
   <dc:date>1907-03-16</dc:date>
   <dc:description>Citation Key: oclc_4770057679-i_14-div_6.d1e1249
BibTeX Cite Key: oclc_4770057679-i_14-div_6.d1e1249
date_hijri: 1325-02-01
oclc: 4770057679
zenodo: 45922152
place: القاهرة
publisher: مطبعة الظاهر
publisher: المطبعة العمومية
</dc:description>
   <z:language>ar</z:language>
</bib:Article>
```

# Zotero JSON: not implemented

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

# Sente XML

My primary interest is in moving reference data from Sente to Zotero. For this, we need a custom transformation from Sente XML to something Zotero can import. While I am most familiar with MODS, it seems that CSL JSON is the more complete format (quite a few fields are missing from the MODS im- and export).