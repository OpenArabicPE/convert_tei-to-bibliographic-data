<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns="http://www.loc.gov/mods/v3"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:oape="https://openarabicpe.github.io/ns"
    xpath-default-namespace="http://www.loc.gov/mods/v3">
    <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no" version="1.0"/>
    <!-- this reduces the complexity of <biblStruct> nodes for use in other applications, such as OpenRefine -->
    <xsl:include href="convert_tei-to-biblstruct_functions.xsl"/>
    
    <xsl:template match="/">
            <xsl:copy>
                <xsl:apply-templates mode="m_replicate"/>
            </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:biblStruct" mode="m_replicate" priority="10">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="m_simple"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
