<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" 
    xmlns:tei="http://www.tei-c.org/ns/1.0" 
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:vcard="http://nwalsh.com/rdf/vCard#" 
    xmlns:foaf="http://xmlns.com/foaf/0.1/" 
    xmlns:z="http://www.zotero.org/namespaces/export#"
    xmlns:dcterms="http://purl.org/dc/terms/" 
    xmlns:bib="http://purl.org/net/biblio#" 
    xmlns:link="http://purl.org/rss/1.0/modules/link/"
    xmlns:prism="http://prismstandard.org/namespaces/1.2/basic/" 
    exclude-result-prefixes="xs rdf tei dc vcard foaf z dcterms bib link prism"
    >
    
    <xsl:output method="xml" escape-uri-attributes="yes" indent="yes"/>
    
<!--    this stylesheet is based on code from https://github.com/paregorios/Zotero-RDF-to-TEI-XML, which was last edited in 2011 -->
    
    <xsl:template match="/rdf:RDF">
        <listBibl>
            <xsl:apply-templates/>
        </listBibl>
    </xsl:template>
    
    <xsl:template match="bib:Memo"/>
    
    <xsl:template match="bib:Book">
        <xsl:variable name="cl-id">
            <xsl:choose>
                <xsl:when test="contains(@rdf:about, '#')">clzx-<xsl:value-of select="substring-after(@rdf:about, '#item_')"/></xsl:when>
                <xsl:otherwise>clza-<xsl:value-of select="count(preceding-sibling::*)+1"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:element name="bibl">
            <xsl:attribute name="id"><xsl:value-of select="$cl-id"/></xsl:attribute>
            <xsl:attribute name="type">book</xsl:attribute>
            <title level="m" type="main">
                <xsl:value-of select="dc:title"/>
            </title>
            <title level="m" type="short">
                <xsl:value-of select="z:shortTitle"/>
            </title>
            <xsl:apply-templates select="bib:authors | bib:editors"/>
            <xsl:apply-templates select="dc:publisher/foaf:Organization"/>
            <date>
                <xsl:choose>
                    <xsl:when test="contains(dc:date, '-')">
                        <xsl:value-of select="substring-before(dc:date, '-')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="dc:date"/>
                    </xsl:otherwise>
                </xsl:choose>
            </date>
            <xsl:apply-templates select="bib:pages"/>
            <idno type="checklist"><xsl:value-of select="$cl-id"/></idno>
            <xsl:apply-templates select="dc:identifier"/>
            <xsl:for-each select="dcterms:isPartOf">
                <xsl:apply-templates select="bib:Series"/>
            </xsl:for-each>
            <xsl:apply-templates select="prism:volume"/>
            <xsl:apply-templates select="dc:subject"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="rdf:li">
        <!-- aiieeeee -->
    </xsl:template>
    
    <xsl:template match="bib:Article"/>
    
    <xsl:template match="bib:Journal"/>
    
    <xsl:template match="bib:Document"/>
    
    <xsl:template match="bib:BookSection"/>
    
    <xsl:template match="bib:ConferenceProceedings">
        <bibl>
            <xsl:apply-templates/>
        </bibl>
    </xsl:template>
    
    <xsl:template match="rdf:Description">
        <xsl:choose>
            <xsl:when test="z:itemType = 'conferencePaper'">
                <biblStruct>
                    <analytic>
                        <title>
                            <xsl:value-of select="dc:title"/>
                        </title>
                        <xsl:apply-templates select="bib:authors"/>
                        
                    </analytic>
                </biblStruct>
            </xsl:when>
            <!-- add outputs for other kinds of objects you collect -->
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="bib:authors | bib:editors">
        <xsl:for-each select="rdf:Seq/rdf:li">
            <xsl:element name="{substring-before(local-name(../..),'s')}">
                <xsl:attribute name="n"><xsl:value-of select="count(preceding-sibling::rdf:li)+1"/></xsl:attribute>
                <xsl:apply-templates select="foaf:Person"/>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>
        
    <xsl:template match="foaf:Organization[parent::dc:publisher]">
        <xsl:for-each select="vcard:adr/vcard:Address/vcard:locality">
            <pubPlace>
                <xsl:value-of select="."/>
            </pubPlace>
        </xsl:for-each>
        <xsl:for-each select="foaf:name">
            <publisher>
                <orgName>
                    <xsl:apply-templates/>
                </orgName>
            </publisher>
        </xsl:for-each>
    </xsl:template> 
    
    <xsl:template match="bib:pages">
        <note type="pageCount"><xsl:value-of select="."/></note>
    </xsl:template>
    
    <xsl:template match="bib:Series">
        <series>
            <xsl:for-each select="dc:title">
                <title level="s"><xsl:value-of select="."/></title>
            </xsl:for-each>
            <xsl:choose>
                <xsl:when test="dc:identifier">
                    <biblScope type="volume"><xsl:value-of select="dc:identifier"/></biblScope>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:for-each select="../../prism:volume">
                        <biblScope type="volume"><xsl:value-of select="."/></biblScope>
                    </xsl:for-each>
                </xsl:otherwise>
            </xsl:choose>
        </series>
    </xsl:template>
    
    <xsl:template match="dc:date">
        <date>
            <xsl:choose>
                <xsl:when test="matches(., '^\d{4}-\d{2}-\d{2}')">
                    <xsl:attribute name="when" select="."/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </date>
    </xsl:template>
   <xsl:template match="dc:identifier[contains(., 'ISBN')]">
        <idno type="ISBN"><xsl:value-of select="normalize-space(substring-after(., 'ISBN'))"/></idno>
    </xsl:template>
    
    <xsl:template match="dc:identifier[dcterms:URI]">
        <xsl:for-each select="tokenize(dcterms:URI/rdf:value, ',')">
            <xsl:variable name="saneuri"><xsl:value-of select="normalize-space(.)"/></xsl:variable>
            <idno type="URI">
                <xsl:value-of select="normalize-space($saneuri)"/>
            </idno>
        </xsl:for-each>
    </xsl:template>
    
        <xsl:template match="dc:subject">
        <note type="subject"><xsl:value-of select="."/></note>
    </xsl:template>
    <xsl:template match="dc:title">
        <title>
            <!-- find a way to establish the level of a title -->
            <xsl:apply-templates/>
        </title>
    </xsl:template>
    
    <xsl:template match="dcterms:abstract"/>
    
    <xsl:template match="foaf:Person">
        <persName>
            <xsl:apply-templates/>
        </persName>
    </xsl:template>
    <xsl:template match="foaf:surname">
        <surname>
            <xsl:apply-templates/>
        </surname>
    </xsl:template>
    <xsl:template match="foaf:givenName">
        <forename>
            <xsl:apply-templates/>
        </forename>
    </xsl:template>
    
    <xsl:template match="prism:volume">
        <xsl:if test="../dcterms:isPartOf/bib:Series[dc:identifier]">
            <xsl:comment>check for missing "virtual" series information</xsl:comment>
            <xsl:message>possible missing "virtual" series information for short title <xsl:value-of select="ancestor::bib:Book/z:shortTitle"/></xsl:message>
            <biblScope type="volume"><xsl:value-of select="."/></biblScope>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="z:Attachment"/>
       <xsl:template match="z:Collection"/>
    <xsl:template match="z:language">
        <textLang>
            <xsl:apply-templates/>
        </textLang>
    </xsl:template>
    <xsl:template match="z:meetingName">
        <title level="s">
            <xsl:apply-templates/>
        </title>
    </xsl:template>
        <xsl:template match="z:presenters">
        <xsl:for-each select="descendant::foaf:Person">
            <!-- full conversion -->
            <respStmt>
                <resp>Presenter</resp>
                <xsl:apply-templates select="."/>
            </respStmt>
            <!-- maybe add an author element for easier conversion into other formats -->
            <author>
                <xsl:apply-templates select="."/>
            </author>
        </xsl:for-each>
    </xsl:template>
    <xsl:template match="z:shortTitle">
        <title type="short">
            <xsl:apply-templates/>
        </title>
    </xsl:template>
    
</xsl:stylesheet>