<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:mods="http://www.loc.gov/mods/v3" 
    xmlns="http://www.tei-c.org/ns/1.0"  
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:zot="https://zotero.org"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="#all"
    version="3.0">
    <xsl:output method="xml" encoding="UTF-8" indent="yes" omit-xml-declaration="no" version="1.0"/>
    <!-- this stylesheet translates <mods:mods> to <tei:biblStruct> -->
    
    <!-- debugging -->
   <!-- <xsl:template match="/">
        <xsl:apply-templates select="descendant::mods:mods" mode="m_mods-to-tei"/>
    </xsl:template>
    <xsl:template match="mods:mods" mode="m_mods-to-tei">
        <xsl:copy-of select="oape:bibliography-mods-to-tei(.)"/>
    </xsl:template>-->
    
    <!-- funtion -->
    <xsl:function name="oape:bibliography-mods-to-tei">
        <!-- input is a mods -->
        <xsl:param name="p_input"/>
        <!-- test for correct input -->
        <xsl:choose>
            <xsl:when test="$p_input/self::mods:mods">
                <!-- construct output -->
                <biblStruct>
                    <xsl:attribute name="zot:genre" select="$p_input/mods:genre[@authority = 'local']"/>
                    <!-- the article: analytic -->
                    <analytic>
                        <xsl:apply-templates select="$p_input/mods:titleInfo" mode="m_mods-to-tei"/>
                        <xsl:apply-templates select="$p_input/mods:name" mode="m_mods-to-tei"/>
                         <xsl:apply-templates select="$p_input/mods:location" mode="m_mods-to-tei"/>
                    </analytic>
                    <!-- the host item: monogr -->
                    <xsl:apply-templates select="$p_input/mods:relatedItem" mode="m_mods-to-tei"/>
                    <!-- notes -->
                    <xsl:if test="$p_input/descendant::mods:subject">
                        <note type="tagList">
                            <list>
                                <xsl:for-each select="$p_input/descendant::mods:subject/mods:topic">
                                    <item><xsl:apply-templates select="." mode="m_plain-text"/></item>
                                </xsl:for-each>
                            </list>
                        </note>
                    </xsl:if>
                </biblStruct>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>
                    <xsl:text>$p_input is not a &lt;mods:mods&gt; note.</xsl:text>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- URLs -->
    <xsl:template match="mods:location" mode="m_mods-to-tei">
        <xsl:apply-templates mode="m_mods-to-tei"/>
    </xsl:template>
    <xsl:template match="mods:url" mode="m_mods-to-tei">
        <idno type="url">
            <xsl:value-of select="."/>
        </idno>
    </xsl:template>
    
    <!-- monogr -->
    <xsl:template match="mods:relatedItem[@type = 'host']" mode="m_mods-to-tei">
        <!-- output -->
        <monogr>
            <!-- titles -->
            <xsl:apply-templates select="mods:titleInfo" mode="m_mods-to-tei"/>
            <!-- contributors -->
            <xsl:apply-templates select="mods:name" mode="m_mods-to-tei"/>
            <!-- identifiers -->
            <xsl:apply-templates select="mods:identifier" mode="m_mods-to-tei"/>
            <!-- language -->
            <xsl:apply-templates select="parent::mods:mods/mods:language" mode="m_mods-to-tei"/>
            <!-- imprint -->
            <xsl:apply-templates select="mods:originInfo" mode="m_mods-to-tei"/>
            <!-- volume, issue, pages -->
             <xsl:apply-templates select="mods:part" mode="m_mods-to-tei"/>
        </monogr>
    </xsl:template>
    
    <xsl:template match="mods:language" mode="m_mods-to-tei">
        <xsl:apply-templates mode="m_mods-to-tei"/>
    </xsl:template>
    <xsl:template match="mods:languageTerm" mode="m_mods-to-tei">
        <textLang mainLang="{.}"/>
    </xsl:template>
    
    <!-- identifiers -->
    <xsl:template match="mods:identifier" mode="m_mods-to-tei">
        <idno type="{@type}">
            <xsl:apply-templates select="." mode="m_plain-text"/>
        </idno>
    </xsl:template>
    
    <!-- imprint -->
    <xsl:template match="mods:originInfo" mode="m_mods-to-tei">
        <imprint>
            <xsl:apply-templates select="mods:place" mode="m_mods-to-tei"/>
            <xsl:apply-templates select="mods:publisher" mode="m_mods-to-tei"/>
            <xsl:apply-templates select="mods:dateIssued" mode="m_mods-to-tei"/>
        </imprint>
    </xsl:template>
    
    <!-- volume, issue, pages -->
    <xsl:template match="mods:part" mode="m_mods-to-tei">
        <xsl:apply-templates mode="m_mods-to-tei"/>
    </xsl:template>
    <xsl:template match="mods:detail" mode="m_mods-to-tei">
        <biblScope unit="{@type}" from="{mods:number}" to="{mods:number}"/>
    </xsl:template>
    <xsl:template match="mods:extent" mode="m_mods-to-tei">
        <biblScope>
            <xsl:attribute name="unit">
                <xsl:choose>
                    <xsl:when test="@unit = 'pages'">
                        <xsl:text>page</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="@unit"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <xsl:if test="mods:start">
                <xsl:attribute name="from" select="mods:start"/>
            </xsl:if>
            <xsl:if test="mods:end">
                <xsl:attribute name="to" select="mods:end"/>
            </xsl:if>
        </biblScope>
    </xsl:template>
    <!-- imprint -->
    <xsl:template match="mods:place" mode="m_mods-to-tei">
        <pubPlace>
            <xsl:apply-templates select="mods:placeTerm" mode="m_mods-to-tei"/>
        </pubPlace>
    </xsl:template>
    <xsl:template match="mods:publisher" mode="m_mods-to-tei">
        <publisher>
            <xsl:apply-templates select="@xml:lang"/>
            <!-- publishers are commonly organisations. Since this information is not present in MODS, we can only assume it -->
            <orgName>
                <xsl:apply-templates select="." mode="m_plain-text"/>
            </orgName>
        </publisher>
    </xsl:template>
    <xsl:template match="mods:dateIssued" mode="m_mods-to-tei">
        <date>
            <xsl:choose>
                <xsl:when test="matches(.,'\d{4}-\d{2}-\d{2}')">
                    <xsl:attribute name="when" select="."/>
                </xsl:when>
                <xsl:when test="matches(.,'\d{4}$')">
                    <xsl:attribute name="when" select="."/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>
                        <xsl:text>The date "</xsl:text><xsl:value-of select="."/><xsl:text>" has the wrong format.</xsl:text>
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </date>
    </xsl:template>
    
    <!-- titles -->
    <xsl:template match="mods:titleInfo" mode="m_mods-to-tei">
        <xsl:variable name="v_title-pre-processed">
            <xsl:apply-templates select="mods:title" mode="m_mods-to-tei"/>
        </xsl:variable>
        <!-- to account for potential errors in splitting of titles and subtitles m_process is applied -->
        <xsl:apply-templates select="$v_title-pre-processed/descendant-or-self::tei:title" mode="m_process"/>
    </xsl:template>
    <!-- establish the correct value for @level -->
    <xsl:template match="mods:title" mode="m_mods-to-tei">
        <xsl:element name="title">
            <xsl:apply-templates select="@xml:lang"/>
            <xsl:attribute name="level">
                <xsl:choose>
                    <xsl:when test="parent::mods:titleInfo/parent::mods:mods">
                        <xsl:value-of select="'a'"/>
                    </xsl:when>
                    <xsl:when test="parent::mods:titleInfo/parent::mods:relatedItem">
                        <xsl:choose>
                            <xsl:when test="ancestor::mods:mods/mods:genre = 'journalArticle'">
                                <xsl:value-of select="'j'"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="'m'"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                </xsl:choose>
            </xsl:attribute>
            <xsl:apply-templates select="." mode="m_plain-text"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:title" mode="m_process">
        <!-- check if title contains ":". If so, split into two titles -->
        <xsl:choose>
            <xsl:when test="contains(.,': ')">
                <!-- main title -->
                <xsl:copy>
                    <xsl:apply-templates select="@*"/>
                    <xsl:value-of select="replace(.,'(.+?):\s+.+$','$1')"/>
                </xsl:copy>
                <!-- sub title -->
                <xsl:copy>
                    <xsl:apply-templates select="@*"/>
                    <xsl:attribute name="type" select="'sub'"/>
                    <xsl:value-of select="replace(.,'.+?:\s+(.+)$','$1')"/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- identity transform -->
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- sub titles -->
    <xsl:template match="mods:subTitle" mode="m_mods-to-tei">
        <title type="sub">
            <xsl:apply-templates select="@xml:lang"/>
            <xsl:apply-templates select="." mode="m_plain-text"/>
        </title>
    </xsl:template>
    <!-- persons, places, names -->
    <xsl:template match="mods:name[@type = 'personal']" mode="m_mods-to-tei">
        <xsl:choose>
            <xsl:when test="mods:role/mods:roleTerm[@authority='marcrelator'] = 'edt'">
                <editor>
                    <xsl:apply-templates select="@xml:lang"/>
                    <xsl:apply-templates select="." mode="m_name"/>
                </editor>
            </xsl:when>
            <xsl:when test="mods:role/mods:roleTerm[@authority='marcrelator'] = 'aut'">
                <author>
                    <xsl:apply-templates select="@xml:lang"/>
                    <xsl:apply-templates select="." mode="m_name"/>
                </author>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="mods:name" mode="m_name">
        <persName>
            <xsl:apply-templates select="@valueURI | @xml:lang"/>
            <xsl:apply-templates select="mods:namePart" mode="m_mods-to-tei"/>
        </persName>
    </xsl:template>
    <xsl:template match="mods:namePart" mode="m_mods-to-tei">
        <xsl:choose>
            <xsl:when test="@type = 'family'">
                <surname>
                    <xsl:apply-templates select="@xml:lang"/>
                    <xsl:apply-templates select="." mode="m_plain-text"/>
                </surname>
            </xsl:when>
            <xsl:when test="@type = 'given'">
                <forename>
                    <xsl:apply-templates select="@xml:lang"/>
                    <xsl:apply-templates select="." mode="m_plain-text"/>
                </forename>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="m_plain-text"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
 <xsl:template match="mods:placeTerm" mode="m_mods-to-tei">
        <placeName>
            <xsl:apply-templates select="@valueURI | @xml:lang"/>
           <xsl:apply-templates select="." mode="m_plain-text"/>
        </placeName>
    </xsl:template>
    
    <!-- attributes -->
    <xsl:template match="@xml:lang">
        <xsl:copy/>
    </xsl:template>
    <xsl:template match="@valueURI">
        <xsl:attribute name="ref" select="."/>
    </xsl:template>
    <!-- plain text output: beware that heavily marked up nodes will have most whitespace omitted -->
    <xsl:template match="text()" mode="m_plain-text">
<!--        <xsl:value-of select="normalize-space(replace(.,'(\w)[\s|\n]+','$1 '))"/>-->
<!--        <xsl:text> </xsl:text>-->
        <xsl:value-of select="normalize-space(.)"/>
<!--        <xsl:text> </xsl:text>-->
    </xsl:template>
</xsl:stylesheet>