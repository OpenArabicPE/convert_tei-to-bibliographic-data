<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns="http://www.loc.gov/mods/v3" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xpath-default-namespace="http://www.loc.gov/mods/v3">
    <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no" version="1.0"/>
    <!-- this reduces the complexity of <biblStruct> nodes for use in other applications, such as OpenRefine -->
    <!-- the resulting dataset can also be used for all the linking purposes in our OpenArabicPE, Jarāʾid and Sihafa contexts, as it keeps the relevant information and simplifies everything with a focus on machine-actionability, while removing unnecessary notes -->
    <xsl:import href="convert_tei-to-biblstruct_functions.xsl"/>
    <xsl:template match="/">
        <xsl:result-document href="{$v_url-base}/{$v_file-name_input}_simple.TEIP5.xml">
            <xsl:copy>
                <xsl:apply-templates mode="m_replicate"/>
            </xsl:copy>
        </xsl:result-document>
    </xsl:template>
    <xsl:template match="tei:biblStruct" mode="m_replicate" priority="10">
        <xsl:copy>
            <xsl:apply-templates mode="m_simple" select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:revisionDesc" mode="m_replicate" priority="10">
        <xsl:copy>
            <xsl:element name="change">
                <xsl:attribute name="when" select="$p_today-iso"/>
                <xsl:attribute name="who" select="$p_id-editor"/>
                <xsl:attribute name="xml:id" select="$p_id-change"/>
                <xsl:attribute name="xml:lang" select="'en'"/>
                <xsl:text>Created this file through automated conversion from </xsl:text>
                <xsl:value-of select="$v_url-file"/>
            </xsl:element>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
