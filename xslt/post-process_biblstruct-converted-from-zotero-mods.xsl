<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.tei-c.org/ns/1.0"  
    xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:zot="https://zotero.org"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="#all"
    version="3.0">
    <xsl:output method="xml" encoding="UTF-8" indent="yes" omit-xml-declaration="no" version="1.0"/>
    
    <!-- stylesheet to clean up <biblStruct> nodes generated from Zotero MODS export by automatic conversion -->
    
    <!-- identity transform -->
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tei:biblStruct">
        <xsl:variable name="v_lang" select="tei:monogr/tei:textLang/@mainLang"/>
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="xml:lang" select="$v_lang"/>
            <!-- problem: journal titles will have ended up in analytic -->
            <xsl:choose>
                <xsl:when test="tei:monogr[not(tei:title)] and tei:analytic/tei:title">
                    <xsl:message>
                        <xsl:text>the journal title ended up as article title</xsl:text>
                    </xsl:message>
                    <!-- reconstruct <monogr> -->
                    <monogr>
                        <!-- create new title -->
                        <xsl:apply-templates select="tei:analytic/tei:title"/>
                        <!-- reproduce existing <monogr> -->
                         <xsl:apply-templates select="tei:monogr/node()"/>
                    </monogr>
                    <!-- replicate potential notes -->
                    <xsl:apply-templates select="tei:note"/>
                </xsl:when>
                <!-- fallback: copy as is -->
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>
    
    <!--<xsl:template match="tei:title">
        <!-\- pre-process to establish the @level -\->
        <xsl:variable name="v_title-pre-processed">
            <xsl:apply-templates select="." mode="m_pre-process"/>
        </xsl:variable>
        <!-\- check if title contains ":". If so, split into two titles -\->
        <xsl:choose>
            <xsl:when test="contains(.,': ')">
                <!-\- main title -\->
                <xsl:copy>
                    <xsl:apply-templates select="@*"/>
                    <xsl:value-of select="replace(.,'(.+?):\s+.+$','$1')"/>
                </xsl:copy>
                <!-\- sub title -\->
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
    </xsl:template>-->
    
    <xsl:template match="tei:title[not(ancestor::tei:fileDesc)]" priority="10">
        <!-- establish the correct @level -->
        <xsl:copy>
                                <xsl:attribute name="level">
                                    <xsl:choose>
                                        <xsl:when test="ancestor::tei:biblStruct/@zot:genre ='journalArticle'">
                                            <xsl:value-of select="'j'"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="'m'"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:attribute>
                                <xsl:attribute name="xml:lang" select="ancestor::tei:biblStruct/tei:monogr/tei:textLang/@mainLang"/>
                                <xsl:value-of select="."/>
                            </xsl:copy>
    </xsl:template>
    
    <!-- add @xml:lang to all nodes -->
    <xsl:template match="node()[ancestor::tei:biblStruct][text()]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="xml:lang" select="ancestor::tei:biblStruct/tei:monogr/tei:textLang/@mainLang"/>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- add pubPlace based on tagList -->
    <xsl:template match="tei:imprint" priority="10">
         <xsl:copy>
            <xsl:apply-templates select="@*"/>
             <xsl:apply-templates select="tei:publisher"/>
             <xsl:apply-templates select="tei:pubPlace"/>
             <xsl:for-each select="ancestor::tei:biblStruct/tei:note[@type = 'tagList']/tei:list/tei:item[ matches(.,'place_.+$')]">
                 <pubPlace>
                     <placeName xml:lang="en">
                         <xsl:value-of select="replace(.,'place_','')"/>
                     </placeName>
                 </pubPlace>
             </xsl:for-each>
             <xsl:apply-templates select="tei:date"/>
         </xsl:copy>
    </xsl:template>
</xsl:stylesheet>