<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:mods="http://www.loc.gov/mods/v3" xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:zot="https://zotero.org" xmlns:cpc="http://copac.ac.uk/schemas/mods-copac/v1"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no" version="1.0"/>
    
    <!-- to do
        - split elements containing "/" (some titles
        - hyphens in most notes
    -->
    
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- frequency -->
    <xsl:template match="tei:biblStruct[not(@oape:frequency)][descendant::tei:item[@type = 'f']]">
        <xsl:copy>
            <xsl:attribute name="oape:frequency">
                <xsl:choose>
                    <xsl:when test="descendant::tei:item[@type = 'f'] = 'W'">
                        <xsl:text>weekly</xsl:text>
                    </xsl:when>
                    <xsl:when test="descendant::tei:item[@type = 'f'] = 'D'">
                        <xsl:text>daily</xsl:text>
                    </xsl:when>
                    <xsl:when test="descendant::tei:item[@type = 'f'] = 'TW'">
                        <xsl:text>biweekly</xsl:text>
                    </xsl:when>
                    <xsl:when test="descendant::tei:item[@type = 'f'] = ('BW', 'TM')">
                        <xsl:text>fortnightly</xsl:text>
                    </xsl:when>
                    <xsl:when test="descendant::tei:item[@type = 'f'] = 'M'">
                        <xsl:text>monthly</xsl:text>
                    </xsl:when>
                </xsl:choose>
            </xsl:attribute>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <!--  split elements containing "/" -->
    <xsl:variable name="v_string-split" select="'/'"/>
    <xsl:template match="tei:title[matches(., $v_string-split)]" priority="10">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:value-of select="normalize-space(substring-before(., $v_string-split))"/>
        </xsl:copy>
         <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:value-of select="normalize-space(substring-after(., $v_string-split))"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:editor[not(tei:persName)]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <persName>
                <xsl:apply-templates/>
            </persName>
        </xsl:copy>
    </xsl:template>
    <!--<xsl:template match="tei:note[@type = 'sources']">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <list>
                <!-\- how to group references? -\->
                <xsl:for-each-group select="tei:ref" group-by="substring(., 1, 3)">
                <item>
                    <xsl:apply-templates select="current-group()"/>
                </item>
            </xsl:for-each-group></list>
        </xsl:copy>
    </xsl:template>-->
    <!--<xsl:template match="tei:bibl[.//tei:ref = 'HTU']">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
            <!-\- add holding -\->
            <note type="holdings">
                <list>
                    <item>
                        <label><placeName>Istanbul</placeName>, <orgName>HTU</orgName></label>
                    </item>
                </list>
            </note>
        </xsl:copy>
    </xsl:template>-->
    
    <xsl:template match="tei:title[not(@xml:lang)]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:if test="count(parent::tei:bibl//tei:textLang) = 1">
                <xsl:variable name="v_lang" select="parent::tei:bibl//tei:textLang/@mainLang"/>
                <xsl:attribute name="xml:lang">
                    <xsl:choose>
                        <xsl:when test="$v_lang = 'ar'">
                            <xsl:text>ar-Latn-EN</xsl:text>
                        </xsl:when>
                        <xsl:when test="$v_lang = 'ota'">
                            <xsl:text>ota-Latn-TR</xsl:text>
                        </xsl:when>
                        <xsl:when test="$v_lang = 'he'">
                            <xsl:text>he-Latn-EN</xsl:text>
                        </xsl:when>
                        <xsl:when test="$v_lang = 'fa'">
                            <xsl:text>fa-Latn-EN</xsl:text>
                        </xsl:when>
                        <xsl:when test="$v_lang = 'gr'">
                            <xsl:text>gr-Latn-EN</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$v_lang"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
            </xsl:if>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    
    <!-- type of date -->
    <xsl:template match="tei:date[not(@type)][contains(., '(')]">
        <xsl:variable name="v_type" select="lower-case(replace(., '^.+\(\s*(\w+.*)\).*$', '$1'))"/>
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:choose>
                <xsl:when test="$v_type = 'publication'">
                    <!-- this indicates that Baykal checked a physical copy -->
                    <xsl:attribute name="type" select="'official'"/>
                    <xsl:attribute name="cert">
                    <xsl:choose>
                        <xsl:when test="ancestor::tei:bibl/tei:note[@type = 'sources']//tei:rs = 'HTU'">
                            <xsl:value-of select="'high'"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="'low'"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    </xsl:attribute>
                </xsl:when>
            </xsl:choose>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    <!-- dates -->
    <xsl:template match="tei:date" priority="10">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:if test="matches(., '^\s*\d{1,2}/\d{4}')">
                <xsl:variable name="v_year" select="replace(., '^\s*(\d{1,2})/(\d{4})\s.+$', '$2')"/>
                <xsl:variable name="v_month" select="number(replace(., '^\s*(\d{1,2})/(\d{4})\s.+$', '$1'))"/>
                <xsl:variable name="v_day">
                    <xsl:choose>
                        <xsl:when test="$v_month = (1,3,5,7,8,10,12)">
                            <xsl:value-of select="31"/>
                        </xsl:when>
                        <xsl:when test="$v_month = 2">
                            <xsl:value-of select="28"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="30"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="v_month" select="format-number($v_month, '00')"/>
                <xsl:attribute name="notBefore" select="concat($v_year, '-', $v_month, '-01')"/>
                <xsl:attribute name="notAfter" select="concat($v_year, '-', $v_month, '-', $v_day)"/>
            </xsl:if>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    <!-- remove non-ISO dates -->
    <xsl:template match="@notAfter | @notBefore">
       <xsl:if test="matches(., '^\d{4}-\d{2}-\d{2}$')">
           <xsl:copy/>
       </xsl:if>
    </xsl:template>
    
    <!-- wrap all constituent parts in ref -->
    <!--<xsl:template match="tei:note[@type = 'sources']/text()[matches(., '^\s*,\s+\w+')]">
        <xsl:analyze-string select="." regex="^(\s*,\s+)(\w+.*?)(,*\s*)$">
            <xsl:matching-substring>
                <xsl:value-of select="regex-group(1)"/>
                <ref>
                    <xsl:value-of select="regex-group(2)"/>
                </ref>
                <xsl:value-of select="regex-group(3)"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:value-of select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:template>-->
    
    <!-- split textLang -->
    <!--<xsl:template match="tei:textLang[contains(., ',')]">
        <xsl:for-each select="tokenize(., ',')">
            <textLang>
                <xsl:value-of select="normalize-space(.)"/>
            </textLang>
        </xsl:for-each>
    </xsl:template>-->
    <!--<xsl:template match="tei:textLang[string-length(text()) = 2]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="mainLang" select="lower-case(.)"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>-->
    
    
    <!--<xsl:template match="tei:date/tei:date">
        <xsl:value-of select="."/>
    </xsl:template>-->
    <!--<xsl:template match="tei:note[@type = ('ps', 'o')]/text() | tei:placeName/text() | tei:bibl/text()">
        <xsl:value-of select="replace(., '(\w)-(\w)', '$1$2')"/>
    </xsl:template>-->
    <!-- compile notes -->
    <!--<xsl:template match="tei:note[@type = 'sources']">
         <xsl:copy>
            <xsl:attribute name="type" select="'comments'"/>
            <list>
                <xsl:apply-templates select="parent::tei:bibl//tei:note[not(@type = 'sources')]" mode="m_note-to-item"/>
            </list>
        </xsl:copy>
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template mode="m_note-to-item" match="tei:note">
        <item>
            <xsl:apply-templates select="@* | node()"/>
        </item>
    </xsl:template>
    <xsl:template match="tei:note[not(@type = 'sources')]"/>-->
</xsl:stylesheet>