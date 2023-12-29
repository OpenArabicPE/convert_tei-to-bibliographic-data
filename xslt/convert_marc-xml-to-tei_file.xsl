<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0"  xmlns:marc="http://www.loc.gov/MARC21/slim"
    xmlns:oape="https://openarabicpe.github.io/ns" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <!-- This stylesheet takes MARC21 records in XML serialisation as input and generates TEI XML as output -->
    <!-- documentation of the MARC21 field codes can be found here: https://marc21.ca/M21/MARC-Field-Codes.html -->
    <xsl:import href="convert_marc-xml-to-tei_functions.xsl"/>
    <!-- output: everything is wrapped in a listBibl -->
    <xsl:template match="/">
        <xsl:result-document href="{$v_base-directory}metadata/{$v_file-name_input}.TEIP5.xml" method="xml">
            <TEI xmlns="http://www.tei-c.org/ns/1.0" xmlns:tei="http://www.tei-c.org/ns/1.0">
                <teiHeader xml:lang="en">
                    <fileDesc>
                        <titleStmt>
                            <title>Bibliographic data converted from MARX XML to TEI</title>
                            <xsl:copy-of select="$p_editor"/>
                        </titleStmt>
                        <publicationStmt>
                            <p>This file is, yet, unpublished</p>
                        </publicationStmt>
                        <sourceDesc>
                            <p>This file is a born-digital file and was generated by automatic conversion from the MARCXML file <ref target="{base-uri()}"><xsl:value-of select="$v_file-name_input"/></ref>.</p>
                        </sourceDesc>
                    </fileDesc>
                    <revisionDesc>
                        <change who="{$p_id-editor}" when="{$p_today-iso}">Created this file through automated conversion from MARCXML</change>
                    </revisionDesc>
                </teiHeader>
                <tei:standOff>
                    <listBibl>
                        <xsl:apply-templates select="descendant::marc:record" mode="m_marc-to-tei"/>
                    </listBibl>
                    <!-- list of holding organisations -->
                    <listOrg>
                        <xsl:variable name="v_holding-institutions">
                            <xsl:apply-templates select="descendant::marc:record" mode="m_get-holding-institutions"/>
                        </xsl:variable>
                        <xsl:for-each-group select="$v_holding-institutions/descendant-or-self::tei:idno[@type = 'isil']" group-by=".">
                           <xsl:apply-templates select="." mode="m_isil-to-tei"/>
                        </xsl:for-each-group>
                    </listOrg>
                    <!-- list of people mentioned -->
                    <listPerson>
                        <xsl:variable name="v_people">
                            <xsl:apply-templates select="descendant::marc:record" mode="m_get-people"/>
                        </xsl:variable>
                        <xsl:for-each-group select="$v_people/tei:person" group-by="tei:persName[1]">
                            <xsl:copy-of select="."/>
                        </xsl:for-each-group>
                    </listPerson>
                </tei:standOff>
            </TEI>
        </xsl:result-document>
    </xsl:template>
</xsl:stylesheet>
