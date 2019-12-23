<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:oape="https://openarabicpe.github.io/ns"
    xpath-default-namespace="http://www.loc.gov/mods/v3"
    exclude-result-prefixes="#all"
    version="3.0">
    <xsl:output method="xml" encoding="UTF-8" indent="yes" omit-xml-declaration="no"/>
<!-- this stylesheet translates <tei:biblStruct>s to  <mods:mods> -->
    
    <xsl:template match="/">
        <array>
        <xsl:apply-templates select="descendant::tei:biblStruct"/>
        </array>
    </xsl:template>
    <xsl:template match="tei:biblStruct">
        <xsl:param name="p_lang" select="'ar'"/>
        <array>
            <!-- scaffolding -->
            <data>
                <!-- key can only be  populated by Zotero -->
                <!-- this key can be searched using Zotero's GUI even though it is never shown to the user -->
                <!-- we might be able to use one of our IDs here, namely our BibTeX key on the article level -->
            <key>
                <xsl:value-of select="tei:analytic/tei:idno[@type='BibTeX']"/>
            </key>
                <!-- version can only be  populated by Zotero -->
            <version></version>
                <!-- item type can be guessed -->
            <itemType>journalArticle</itemType>
                <!-- title: article or chapter title -->
            <title>
                <xsl:value-of select="normalize-space(tei:analytic/tei:title[@xml:lang = $p_lang])"/>
            </title>
                <!-- contributors: editors, authors -->
                <xsl:apply-templates select="tei:analytic/tei:author" mode="m_tei-to-zotero">
                    <xsl:with-param name="p_lang" select="$p_lang"/>
                </xsl:apply-templates>
                <xsl:apply-templates select="tei:monogr/tei:author" mode="m_tei-to-zotero">
                    <xsl:with-param name="p_lang" select="$p_lang"/>
                </xsl:apply-templates>
                <xsl:apply-templates select="tei:monogr/tei:editor" mode="m_tei-to-zotero">
                    <xsl:with-param name="p_lang" select="$p_lang"/>
                </xsl:apply-templates>
            <abstractNote></abstractNote>
            <publicationTitle>
                <!-- there should not be more than one title per language -->
                <xsl:value-of select="normalize-space(tei:monogr/tei:title[not(@type = 'sub')][@xml:lang = $p_lang][1])"/>
                <xsl:if test="tei:monogr/tei:title[@type = 'sub'][@xml:lang = $p_lang]">
                    <xsl:text>: </xsl:text>
                    <xsl:value-of select="normalize-space(tei:monogr/tei:title[@type = 'sub'][@xml:lang = $p_lang][1])"/>
                </xsl:if>
            </publicationTitle>
                <!-- volume, issue, pages -->
                <xsl:apply-templates select="tei:monogr/tei:biblScope" mode="m_tei-to-zotero"/>
                <!-- date -->
            <date><xsl:value-of select="tei:monogr/tei:imprint[1]/tei:date[@when][1]/@when"/></date>
            <series></series>
            <seriesTitle></seriesTitle>
            <seriesText></seriesText>
            <journalAbbreviation></journalAbbreviation>
            <language>
                <xsl:choose>
                    <xsl:when test="tei:monogr/tei:textLang/@mainLang">
                        <xsl:value-of select="tei:monogr/tei:textLang/@mainLang"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$p_lang"/>
                    </xsl:otherwise>
                </xsl:choose>
            </language>
            <DOI></DOI>
            <ISSN></ISSN>
            <shortTitle></shortTitle>
                <!-- URL -->
            <url><xsl:value-of select="tei:analytic/tei:idno[@type='url'][1]"/></url>
            <accessDate></accessDate>
            <archive></archive>
            <archiveLocation></archiveLocation>
            <libraryCatalog></libraryCatalog>
            <callNumber></callNumber>
            <rights></rights>
            <extra></extra>
                <!-- collections can only be populated by Zotero -->
            <collections></collections>
            <relations></relations>
                <!-- dateAdded can only be populated by Zotero -->
            <dateAdded></dateAdded>
                <!-- date modified: timestamp of the current conversion -->
            <dateModified>
                <xsl:value-of select="current-dateTime()"/>
            </dateModified>
        </data>
        </array>
    </xsl:template>
    
    <xsl:template match="tei:author | tei:editor" mode="m_tei-to-zotero">
        <xsl:param name="p_lang" select="'ar'"/>
        <creators>
                <creatorType>
                    <xsl:if test="self::tei:author">
                        <xsl:text>author</xsl:text>
                    </xsl:if>
                    <xsl:if test="self::tei:editor">
                        <xsl:text>editor</xsl:text>
                    </xsl:if>
                </creatorType>
                <xsl:apply-templates select="tei:persName[@xml:lang = $p_lang]" mode="m_tei-to-zotero"/>
            </creators>
    </xsl:template>
    <xsl:template match="tei:persName" mode="m_tei-to-zotero">
        <xsl:apply-templates select="tei:surname" mode="m_tei-to-zotero"/>
        <xsl:apply-templates select="tei:forename" mode="m_tei-to-zotero"/>
    </xsl:template>
    <xsl:template match="tei:surname" mode="m_tei-to-zotero">
        <lastName>
            <xsl:value-of select="."/>
        </lastName>
    </xsl:template>
    <xsl:template match="tei:forename" mode="m_tei-to-zotero">
        <firstName>
            <xsl:value-of select="."/>
        </firstName>
    </xsl:template>
    <xsl:template match="tei:biblScope" mode="m_tei-to-zotero">
        <xsl:choose>
            <xsl:when test="@unit='volume'">
                <volume>
                    <xsl:apply-templates select="." mode="m_bibl-range"/>
                </volume>
            </xsl:when>
            <xsl:when test="@unit='issue'">
                <issue>
                    <xsl:apply-templates select="." mode="m_bibl-range"/>
                </issue>
            </xsl:when>
            <xsl:when test="@unit='page'">
                <pages>
                    <xsl:apply-templates select="." mode="m_bibl-range"/>
                </pages>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tei:biblScope" mode="m_bibl-range">
        <xsl:choose>
            <xsl:when test="@from = @to">
                <xsl:value-of select="@from"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="@from"/>
                <xsl:text>-</xsl:text>
                <xsl:value-of select="@to"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
