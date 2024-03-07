<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:mods="http://www.loc.gov/mods/v3" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no" version="1.0"/>
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:rs[not(@ref)]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:choose>
                <xsl:when test="matches(., 'Ṭ', 'i')">
                    <xsl:attribute name="ref" select="'#agt'"/>
                </xsl:when>
                <xsl:when test="matches(., '\+!', 'i')">
                    <xsl:attribute name="ref" select="'#aghart2'"/>
                </xsl:when>
                <xsl:when test="matches(., '\+', 'i')">
                    <xsl:attribute name="ref" select="'#aghart1'"/>
                </xsl:when>
                <xsl:when test="matches(., 'ʿAbd', 'i')">
                    <xsl:attribute name="ref" select="'#abd2'"/>
                </xsl:when>
                <!-- Philip Sadgrove -->
                <xsl:when test="matches(., 'S', 'i')">
                    <xsl:attribute name="ref" select="'#ags'"/>
                </xsl:when>
                <!-- Stacy Fahrenholdt -->
                <xsl:when test="matches(., 'SF', 'i')">
                    <xsl:attribute name="ref" select="'#aSF'"/>
                </xsl:when>
                <xsl:when test="matches(., 'M-K', 'i')">
                    <xsl:attribute name="ref" select="'#aMK'"/>
                </xsl:when>
                <xsl:when test="matches(., 'RC', 'i')">
                    <xsl:attribute name="ref" select="'#aRC'"/>
                </xsl:when>
            </xsl:choose>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:rs/@ref">
        <xsl:copy>
            <xsl:message>
                <xsl:value-of select="."/>
            </xsl:message>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>