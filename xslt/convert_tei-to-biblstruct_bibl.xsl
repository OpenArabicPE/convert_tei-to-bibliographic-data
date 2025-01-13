<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:mods="http://www.loc.gov/mods/v3" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no" version="1.0"/>
    <!-- this stylesheet generates a TEI/XML bibliography from all <bibl> elements found in the text of a TEI/XML document -->
    <xsl:import href="../../../OpenArabicPE/authority-files/xslt/functions.xsl"/>
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
            <!-- transorm all references into biblStructs -->
            <xsl:variable name="v_bibls">
                <!-- bibl -->
                <!-- compile partial information -->
                <xsl:variable name="v_bibls-temp">
                    <xsl:for-each select="descendant::tei:text/tei:body/descendant::tei:bibl[not(ancestor::tei:biblStruct)][not(parent::tei:listBibl)]">
                        <xsl:copy-of select="oape:compile-next-prev(.)"/>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:apply-templates mode="m_bibl-to-biblStruct" select="$v_bibls-temp/descendant-or-self::tei:bibl"/>
                <!-- title -->
                <xsl:apply-templates mode="m_bibl-to-biblStruct" select="descendant::tei:text/tei:body/descendant::tei:title[not(ancestor::tei:biblStruct)][not(ancestor::tei:bibl)]"/>
                <!-- listBibl -->
                <xsl:apply-templates mode="m_bibl-to-biblStruct" select="descendant::tei:text/tei:body/descendant::tei:listBibl[not(ancestor::tei:biblStruct)]"/>
            </xsl:variable>
            <xsl:element name="standOff">
                <!-- already in authority file-->
                <xsl:element name="listBibl">
                    <xsl:element name="head">
                        <xsl:text>linked to authority file</xsl:text>
                    </xsl:element>
                    <xsl:for-each-group select="$v_bibls/descendant-or-self::tei:biblStruct[tei:monogr/tei:idno]" group-by=".">
                        <xsl:sort select="tei:monogr/tei:title[1]"/>
                        <xsl:apply-templates select="." mode="m_replicate"/>
                    </xsl:for-each-group>
                </xsl:element>
                <!-- new or not linked -->
                <xsl:element name="listBibl">
                    <xsl:element name="head">
                        <xsl:text>new or unlinked</xsl:text>
                    </xsl:element>
                    <xsl:for-each-group select="$v_bibls/descendant-or-self::tei:biblStruct[not(tei:monogr/tei:idno)]" group-by=".">
                        <xsl:sort select="tei:monogr/tei:title[1]"/>
                        <xsl:apply-templates select="." mode="m_replicate"/>
                    </xsl:for-each-group>
                </xsl:element>
                <!-- <xsl:element name="head">
                        <xsl:text>from </xsl:text>
                        <xsl:element name="gi">
                            <xsl:text>bibl</xsl:text>
                        </xsl:element>
                    </xsl:element>-->
                <!--                    <xsl:apply-templates mode="m_bibl-to-biblStruct" select="descendant::tei:text/tei:body/descendant::tei:bibl[not(ancestor::tei:biblStruct)][not(parent::tei:listBibl)]"/>-->
                <!--                </xsl:element>-->
                <!-- titles without bibl -->
                <!--  <xsl:element name="listBibl">
                     <xsl:element name="head">
                        <xsl:text>from </xsl:text>
                        <xsl:element name="gi">
                            <xsl:text>title</xsl:text>
                        </xsl:element>
                    </xsl:element>-->
                <!--                    <xsl:apply-templates mode="m_bibl-to-biblStruct" select="descendant::tei:text/tei:body/descendant::tei:title[not(ancestor::tei:biblStruct)][not(ancestor::tei:bibl)]"/>-->
                <!--</xsl:element>-->
                <!-- find listBibls -->
                <!--                    <xsl:apply-templates mode="m_bibl-to-biblStruct" select="descendant::tei:text/tei:body/descendant::tei:listBibl[not(ancestor::tei:biblStruct)]"/>-->
            </xsl:element>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:title[not(ancestor::tei:biblStruct)][not(ancestor::tei:bibl)]" mode="m_bibl-to-biblStruct">
        <xsl:variable name="v_bibl">
            <xsl:element name="bibl">
                <!-- point back to source -->
                <!--                <xsl:attribute name="source" select="concat($v_url-file, '#', @xml:id)"/>-->
                <xsl:copy-of select="."/>
            </xsl:element>
        </xsl:variable>
        <xsl:apply-templates select="$v_bibl/descendant-or-self::tei:bibl" mode="m_bibl-to-biblStruct"/>
    </xsl:template>
    <xsl:template match="tei:listBibl" mode="m_bibl-to-biblStruct">
        <!--<xsl:copy>
            <xsl:apply-templates mode="m_replicate" select="@*"/>-->
        <xsl:apply-templates select="tei:bibl" mode="m_bibl-to-biblStruct"/>
        <!--</xsl:copy>-->
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
