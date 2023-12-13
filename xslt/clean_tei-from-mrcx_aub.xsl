<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output indent="yes" method="xml"/>
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:biblStruct">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:if test="not(@type)">
                <xsl:attribute name="type" select="'periodical'"/>
            </xsl:if>
            <xsl:if test="not(@subtype) and descendant::tei:title[matches(., 'مجلة|جريدة')]">
                <xsl:attribute name="subtype">
                    <xsl:choose>
                        <xsl:when test="matches(., 'مجلة')">
                            <xsl:text>journal</xsl:text>
                        </xsl:when>
                        <xsl:when test="matches(., 'جريدة')">
                            <xsl:text>newspaper</xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </xsl:attribute>
            </xsl:if>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:item[not(tei:label)][ancestor::tei:note/@type = 'holdings']">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:element name="label">
                <xsl:element name="rs">
                    <xsl:attribute name="ref" select="'#hAUB'"/>
                    <xsl:attribute name="xml:lang" select="'en'"/>
                    <xsl:text>AUB</xsl:text>
                </xsl:element>
            </xsl:element>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="@xml:lang[. = 'und']">
        <xsl:attribute name="xml:lang" select="'ar'"/>
    </xsl:template>
    <xsl:template match="tei:monogr/tei:title">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:if test="not(@level )">
                <xsl:attribute name="level" select="'j'"/>
            </xsl:if>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:monogr[preceding-sibling::tei:analytic]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="preceding-sibling::tei:analytic/tei:title"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:analytic"/>
    <xsl:template match="text()[matches(., '^\[.+\]$')]">
        <xsl:element name="supplied">
            <xsl:attribute name="resp" select="'#aub'"/>
            <xsl:value-of select="replace(., '^\[(.+)\]$', '$1')"/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="tei:date[not(@when)]">
        <xsl:variable name="v_text">
            <xsl:value-of select="descendant-or-self::text()"/>
        </xsl:variable>
        <xsl:variable name="v_text" select="normalize-space($v_text)"/>
        <xsl:choose>
            <xsl:when test="matches($v_text, '^\d{4}-\d{4}$')">
                <xsl:copy>
                    <xsl:attribute name="type" select="'onset'"/>
                    <xsl:attribute name="when" select="replace($v_text, '(\d{4})-(\d{4})', '$1')"/>
                    <xsl:apply-templates/>
                </xsl:copy>
                <xsl:copy>
                    <xsl:attribute name="type" select="'terminus'"/>
                    <xsl:attribute name="when" select="replace($v_text, '(\d{4})-(\d{4})', '$2')"/>
                    <xsl:apply-templates/>
                </xsl:copy>
            </xsl:when>
            <xsl:when test="matches(., '^\d{4}-')">
                <xsl:copy>
                    <xsl:attribute name="type" select="'onset'"/>
                    <xsl:attribute name="when" select="replace($v_text, '^(\d{4})-.*$', '$1')"/>
                    <xsl:apply-templates/>
                </xsl:copy>
            </xsl:when>
            <xsl:when test="matches($v_text, '^\d{4}$')">
                <xsl:copy>
                    <xsl:attribute name="when" select="replace($v_text, '^(\d{4})$', '$1')"/>
                    <xsl:apply-templates/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates select="@* | node()"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>
