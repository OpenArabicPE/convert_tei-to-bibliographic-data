<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns="http://www.loc.gov/mods/v3"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:oape="https://openarabicpe.github.io/ns"
    xpath-default-namespace="http://www.loc.gov/mods/v3">
    <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no" version="1.0"/>
    <!-- this stylesheet generates a TEI/XML bibliography from all <bibl> elements found in the text of a TEI/XML document -->
    <xsl:include href="convert_tei-to-biblstruct_functions.xsl"/>
    
    <!-- all parameters and variables are set in convert_tei-to-mods_functions.xsl -->
    <xsl:template match="/">
        <xsl:result-document href="{$v_base-directory}metadata/{$v_file-name_input}-bibl_biblStruct.TEIP5.xml">
            <xsl:copy>
                <xsl:element name="TEI">
                    <xsl:apply-templates mode="m_basic" select="tei:TEI/tei:teiHeader"/>
                    <xsl:element name="standOff">
                        <xsl:element name="listBibl">
                            <xsl:apply-templates select="descendant::tei:text/tei:body/descendant::tei:bibl" mode="m_bibl-to-biblStruct"/>
                        </xsl:element>
                    </xsl:element>
                </xsl:element>
            </xsl:copy>
        </xsl:result-document>
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
                <xsl:apply-templates select="tei:fileDesc/tei:sourceDesc" mode="m_replicate"/>
            </fileDesc>
        </teiHeader>
    </xsl:template>
</xsl:stylesheet>
