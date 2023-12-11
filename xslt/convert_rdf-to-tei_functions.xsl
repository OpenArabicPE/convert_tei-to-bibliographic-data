<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/"
    xmlns:foaf="http://xmlns.com/foaf/0.1/" xmlns:link="http://purl.org/rss/1.0/modules/link/" xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:prism="http://prismstandard.org/namespaces/1.2/basic/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:vcard="http://nwalsh.com/rdf/vCard#" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:z="http://www.zotero.org/namespaces/export#">
    <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no"/>
    <xsl:include href="functions.xsl"/>
    <!-- this stylesheet translates RDF to <tei:biblStruct> -->
    <!-- to do:
         
    -->
    <!--<xsl:template match="rdf:RDF">
        <xsl:element name="TEI">
            <xsl:copy-of select="$v_teiHeader"/>
            <xsl:element name="standOff">
                
            </xsl:element>
        </xsl:element>
    </xsl:template>-->
    <xsl:template match="rdf:Description">
        <!-- start with conversion to unstructured <bibl> -->
        <xsl:variable name="v_bibl">
            <bibl>
                <xsl:apply-templates/>
            </bibl>
        </xsl:variable>
        <xsl:apply-templates mode="m_bibl-to-biblStruct" select="$v_bibl"/>
    </xsl:template>
    <xsl:template match="dc:title">
        <xsl:element name="title">
            <xsl:if test="parent::element()/dc:type = 'journal'">
                <xsl:attribute name="level" select="'j'"/>
            </xsl:if>
            <xsl:apply-templates mode="m_plain-text" select="."/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="dc:language">
        <xsl:element name="textLang">
            <xsl:attribute name="mainLang" select="."/>
        </xsl:element>
    </xsl:template>
    <!-- imprint -->
    <xsl:template match="dc:publisher">
        <xsl:element name="publisher">
            <xsl:apply-templates mode="m_plain-text" select="."/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="dc:date">
        <xsl:choose>
            <xsl:when test=". = '99990101'"/>
            <xsl:otherwise>
                <xsl:element name="date">
                    <xsl:attribute name="when" select="replace(., '(\d{4})(\d{2})(\d{2})', '$1-$2-$3')"/>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- we leave parsing of these dates to a post-processing step -->
    <xsl:template match="dc:non_standard_date">
        <xsl:element name="date">
            <xsl:apply-templates mode="m_plain-text" select="."/>
        </xsl:element>
    </xsl:template>
    <!--  IDs -->
    <xsl:template match="dc:identifier | dc:recordid | dc:isbn">
        <xsl:element name="idno">
            <xsl:attribute name="source" select="replace(parent::element()/@rdf:about, '^(https*://.*?/).*$', '$1')"/>
            <xsl:attribute name="type">
                <xsl:choose>
                    <xsl:when test="self::dc:recordid">
                        <xsl:text>record</xsl:text>
                    </xsl:when>
                    <xsl:when test="self::dc:identifier">
                        <xsl:text>classmark</xsl:text>
                    </xsl:when>
                    <xsl:when test="self::dc:isbn">
                        <xsl:text>ISBN</xsl:text>
                    </xsl:when>
                </xsl:choose>
            </xsl:attribute>
            <xsl:apply-templates mode="m_plain-text" select="."/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="dc:linkToMarc">
        <xsl:element name="idno">
            <xsl:attribute name="source" select="replace(parent::element()/@rdf:about, '^(https*://.*?/).*$', '$1')"/>
            <xsl:attribute name="type" select="'url'"/>
            <xsl:apply-templates mode="m_plain-text" select="@rdf:resource"/>
        </xsl:element>
    </xsl:template>
    <!-- omit non-converted elements -->
    <xsl:template match="dc:*">
        <xsl:message>
            <xsl:value-of select="name()"/>
        </xsl:message>
    </xsl:template>
    <!-- the teiHeader -->
    <xsl:variable name="v_teiHeader">
        <teiHeader>
            <fileDesc>
                <titleStmt>
                    <title>Title</title>
                </titleStmt>
                <publicationStmt>
                    <p>Publication Information</p>
                </publicationStmt>
                <sourceDesc>
                    <p>This file has been created by automatic conversion from <ref><xsl:value-of select="$v_url-file"/></ref>.</p>
                </sourceDesc>
            </fileDesc>
        </teiHeader>
    </xsl:variable>
</xsl:stylesheet>
