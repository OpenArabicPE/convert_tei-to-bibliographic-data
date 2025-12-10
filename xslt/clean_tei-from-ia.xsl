<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output indent="yes" method="xml"/>
    <xsl:import href="post-process_tei-biblstruct_functions.xsl"/>
    <xsl:param name="p_source" select="'oape:org:440'"/>
    <!-- remove nested bibls and dates -->
    <xsl:template match="tei:note/tei:bibl | tei:date/tei:date" mode="m_post-process" priority="100">
        <xsl:text> </xsl:text>
        <xsl:apply-templates mode="m_post-process"/>
        <xsl:text> </xsl:text>
    </xsl:template>
    <xsl:template mode="m_post-process" match="tei:title[@ref = 'NA'][preceding-sibling::tei:note[@type = 'title']/tei:title]"/>
    <!-- group -->
    
    
    <!-- titles ending in dates -->
    <xsl:template match="tei:note[@type = 'title'][not(child::element())][matches(., '^(.*?\D)((\d{4})\s*-\s*)?(\d{4})$')]" mode="m_post-process">
        <xsl:analyze-string regex="^(.*?\D)((\d{{4}})\s*-\s*)?(\d{{4}})$" select=".">
            <xsl:matching-substring>
                <xsl:variable name="v_content" select="regex-group(1)"/>
                <xsl:variable name="v_onset" select="regex-group(3)"/>
                <xsl:variable name="v_terminus" select="regex-group(4)"/>
                <!-- title -->
                <xsl:element name="note">
                    <xsl:attribute name="type" select="'title'"/>
                    <xsl:value-of select="normalize-space($v_content)"/>
                    <xsl:text> </xsl:text>
                    <!-- dates -->
                    <xsl:choose>
                        <xsl:when test="$v_onset != '' and $v_terminus != ''">
                            <xsl:element name="date">
                                <xsl:attribute name="type" select="'onset'"/>
                                <xsl:value-of select="$v_onset"/>
                            </xsl:element>
                            <xsl:element name="date">
                                <xsl:attribute name="type" select="'terminus'"/>
                                <xsl:value-of select="$v_terminus"/>
                            </xsl:element>
                        </xsl:when>
                        <xsl:when test="$v_terminus != ''">
                            <xsl:element name="date">
                                <xsl:value-of select="$v_terminus"/>
                            </xsl:element>
                        </xsl:when>
                    </xsl:choose>
                </xsl:element>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:copy-of select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:template>
    <!-- initial steps -->
    <xsl:template match="tei:idno" mode="m_off">
        <xsl:copy>
            <!-- add attributes -->
            <xsl:choose>
                <xsl:when test="not(preceding-sibling::tei:idno)">
                    <xsl:attribute name="type" select="'classmark'"/>
                    <xsl:attribute name="source" select="$p_source"/>
                </xsl:when>
                <xsl:when test="matches(., '^ark:')">
                    <xsl:attribute name="type" select="'ARK'"/>
                </xsl:when>
            </xsl:choose>
            <xsl:apply-templates mode="m_post-process"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:dateAdded" mode="m_post-process">
        <xsl:element name="date">
            <xsl:attribute name="type" select="'acquisition'"/>
            <xsl:apply-templates mode="m_post-process"/>
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>
