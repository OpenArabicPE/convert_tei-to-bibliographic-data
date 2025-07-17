<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output indent="yes" method="xml"/>
    <xsl:import href="post-process_tei-biblstruct_functions.xsl"/>
    <xsl:import href="../../../OpenArabicPE/tools/xslt/functions.xsl"/>
    <!--    <xsl:import href="../../../OpenArabicPE/authority-files/xslt/functions.xsl"/>-->
    <xsl:param name="p_source" select="'oape:org:60'"/>
    <!-- use @mode = 'm_off' to toggle templates off -->
    <!-- add templates specific to this particular input -->
    <!-- information to be removed as I do not further process it -->
    <xsl:template match="tei:biblStruct/@xml:lang | tei:monogr/@xml:lang | tei:imprint/@xml:lang" mode="m_post-process"/>
    <xsl:template match="tei:publisher[contains(., ':')]" mode="m_off">
        <!-- add pubPlace -->
        <pubPlace>
            <xsl:apply-templates mode="m_post-process" select="@*"/>
            <xsl:value-of select="replace(., '^(.*?)\s*:.*$', '$1')"/>
        </pubPlace>
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@*"/>
            <xsl:value-of select="replace(., '^(.*?)\s*:\s*(.*)$', '$2')"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:publisher[parent::tei:imprint/not(tei:pubPlace)]" mode="m_off">
        <pubPlace>
            <placeName>
                <xsl:apply-templates mode="m_post-process"/>
            </placeName>
        </pubPlace>
    </xsl:template>
    <xsl:template match="tei:publisher[not(element())][text()]" mode="m_off">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <orgName><xsl:value-of select="normalize-space(.)"/></orgName>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:publisher[. = '[اسم الناشر غير معروف]']" mode="m_off"/>
    <xsl:template match="tei:title[matches(., '^.+\[.+\]$')]" mode="m_off">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@*"/>
            <xsl:value-of select="replace(., '(\s*\[.+\])$', '')"/>
        </xsl:copy>
        <note type="temp">
            <xsl:value-of select="replace(., '^(.+\s)*\[(.+)\]$', '$2')"/>
        </note>
    </xsl:template>
    <!-- type and subtype based on a temporary note -->
    <xsl:template match="tei:biblStruct" mode="m_off">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@*"/>
            <xsl:if test="tei:monogr/tei:note[@type = 'temp'] = ('مجلة', 'جريدة')">
                <xsl:attribute name="type" select="'periodical'"/>
                <xsl:attribute name="subtype">
                    <xsl:choose>
                        <xsl:when test="tei:monogr/tei:note[@type = 'temp'] = ('مجلة')">
                            <xsl:text>journal</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>newspaper</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
            </xsl:if>
            <xsl:apply-templates mode="m_post-process"/>
        </xsl:copy>
    </xsl:template>
    <!-- remove the note -->
    <xsl:template match="tei:monogr/tei:note[@type = 'temp'][. = ('مجلة', 'جريدة')]" mode="m_off"/>
    
    <xsl:template match="@when | @notBefore | @notAfter" mode="m_off" priority="20">
        <xsl:attribute name="{name()}">
            <xsl:value-of select="oape:transpose-digits(., 'arabic', 'western')"/>
        </xsl:attribute>
    </xsl:template>
</xsl:stylesheet>
