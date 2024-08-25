<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:mods="http://www.loc.gov/mods/v3" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no" version="1.0"/>
    <!-- this stylesheet generates a TEI/XML bibliography from all <bibl> elements found in the text of a TEI/XML document -->
    <xsl:import href="convert_tei-to-biblstruct_functions.xsl"/>
    <!-- all parameters and variables are set in convert_tei-to-mods_functions.xsl -->
    <xsl:template match="/">
        <xsl:result-document href="{$v_base-directory}{$p_output-folder}{$v_file-name_input}-bibl_biblStruct.TEIP5.xml">
            <xsl:copy>
                <xsl:apply-templates mode="m_bibl-to-biblStruct"/>
            </xsl:copy>
        </xsl:result-document>
    </xsl:template>
    <xsl:template match="tei:TEI" mode="m_bibl-to-biblStruct">
        <xsl:copy>
            <xsl:apply-templates mode="m_replicate" select="@*"/>
            <xsl:apply-templates mode="m_basic" select="tei:teiHeader"/>
            <xsl:element name="standOff">
                <xsl:element name="listBibl">
                    <xsl:apply-templates mode="m_bibl-to-biblStruct" select="descendant::tei:text/tei:body/descendant::tei:bibl[not(parent::tei:listBibl)]"/>
                </xsl:element>
                <xsl:apply-templates mode="m_bibl-to-biblStruct" select="descendant::tei:text/tei:body/descendant::tei:listBibl"/>
            </xsl:element>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:listBibl" mode="m_bibl-to-biblStruct">
        <xsl:copy>
            <xsl:apply-templates mode="m_replicate" select="@*"/>
            <xsl:apply-templates select="tei:bibl" mode="m_bibl-to-biblStruct"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:teiHeader" mode="m_basic">
        <teiHeader>
            <fileDesc>
                <titleStmt>
                    <title>Bibliographic data for <xsl:value-of select="$v_file-name_input"/></title>
                </titleStmt>
                <publicationStmt>
                    <p>This bibliographic data is in the public domain.</p>
                </publicationStmt>
                <xsl:apply-templates mode="m_replicate" select="tei:fileDesc/tei:sourceDesc"/>
            </fileDesc>
        </teiHeader>
    </xsl:template>
</xsl:stylesheet>
