<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output indent="yes" method="xml"/>
    <xsl:import href="post-process_tei-biblstruct_functions.xsl"/>
    <!-- use @mode = 'm_off' to toggle templates off -->
    <!-- add templates specific to this particular input -->
    <xsl:template match="tei:biblStruct" mode="m_off" priority="20">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="m_identity-transform"/>
            <!-- improve source information -->
            <xsl:attribute name="source">
                <xsl:choose>
                    <xsl:when test="@source = 'ICU'">
                        <xsl:text>wiki:Q7895259</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="@source"/>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:text> </xsl:text>
                <xsl:value-of select="tei:note[@type = 'holdings']/tei:list/tei:item/@source[starts-with(., $p_url-resolve-uchicago)]"/>
            </xsl:attribute>
            <xsl:apply-templates select="node()" mode="m_post-process"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
