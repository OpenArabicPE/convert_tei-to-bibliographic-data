<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output indent="yes" method="xml"/>
    <xsl:import href="post-process_tei-biblstruct_functions.xsl"/>
    <xsl:param name="p_source" select="'oape:org:60'"/>
    <!-- use @mode = 'm_off' to toggle templates off -->
    <!-- add templates specific to this particular input -->
    <!-- switch off post processing for notes -->
    <xsl:template match="tei:note" mode="m_off">
        <xsl:copy-of select="."/>
    </xsl:template>
    <!-- postprocessing specific to KOHA -->
    <xsl:template match="tei:forename/text()" mode="m_post-process">
        <xsl:value-of select="replace(., '(\s*\.)$', '')"/>
    </xsl:template>
    <xsl:template match="tei:textLang[parent::tei:monogr/tei:title[contains(., 'سالنامه')]]" mode="m_post-process">
        <xsl:copy>
            <xsl:attribute name="mainLang" select="'ota'"/>
            <xsl:apply-templates mode="m_post-process"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:title[contains(., 'سالنامه')]" mode="m_post-process">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@*"/>
            <xsl:attribute name="xml:lang" select="'ota'"/>
            <xsl:apply-templates mode="m_post-process"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:title[matches(., '^.+\[.+\]$')]" mode="m_off">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@*"/>
            <xsl:value-of select="replace(., '(\s*\[.+\])$', '')"/>
        </xsl:copy>
        <note type="temp">
            <xsl:value-of select="replace(., '^(.+\s)*\[(.+)\]$', '$2')"/>
        </note>
    </xsl:template>
    <!-- remove existing holding information and add information directly from MARCXML source -->
    <xsl:template match="tei:note[@type = 'holdings']" mode="m_off">
        <!-- get MARCXML from source -->
        <xsl:variable name="v_url-catalogue" select="concat($v_koha-url-record-web, parent::tei:biblStruct/tei:monogr/tei:idno[@type = 'biblio_id'])"/>
        <xsl:variable name="v_marc" select="document(concat($v_koha-url-record-marcxml, parent::tei:biblStruct/tei:monogr/tei:idno[@type = 'biblio_id']))"/>
        <!-- get the summary of holding information -->
        <xsl:apply-templates mode="m_notes" select="$v_marc//marc:datafield[@tag = '362']">
            <xsl:with-param name="p_record" select="$v_marc/descendant-or-self::marc:record"/>
            <xsl:with-param name="p_catalogue" select="'koha'"/>
            <xsl:with-param name="p_url-catalogue" select="$v_url-catalogue"/>
        </xsl:apply-templates>
        <!-- get detailed holdings for item of this work -->
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="m_post-process"/>
        </xsl:copy>
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
    <xsl:template match="@when | @notBefore | @notAfter" mode="m_post-process" priority="20">
        <xsl:attribute name="{name()}">
            <xsl:value-of select="oape:transpose-digits(., 'arabic', 'western')"/>
        </xsl:attribute>
    </xsl:template>
    <xsl:function name="oape:transpose-digits">
        <xsl:param name="p_input"/>
        <xsl:param name="p_from"/>
        <xsl:param name="p_to"/>
        <xsl:variable name="v_digits-arabic" select="'٠١٢٣٤٥٦٧٨٩'"/>
        <xsl:variable name="v_digits-persian" select="'٠١٢٣۴۵۶٧٨٩'"/>
        <xsl:variable name="v_digits-urdu" select="'۰۱۲۳۴۵۶۷۸۹'"/>
        <xsl:variable name="v_digits-western" select="'0123456789'"/>
        <xsl:variable name="v_from">
            <xsl:choose>
                <xsl:when test="$p_from = 'arabic'">
                    <xsl:value-of select="$v_digits-arabic"/>
                </xsl:when>
                <xsl:when test="$p_from = 'persian'">
                    <xsl:value-of select="$v_digits-persian"/>
                </xsl:when>
                <xsl:when test="$p_from = 'urdu'">
                    <xsl:value-of select="$v_digits-urdu"/>
                </xsl:when>
                <xsl:when test="$p_from = 'western'">
                    <xsl:value-of select="$v_digits-western"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message terminate="yes">
                        <xsl:text>Value for $p_from not available</xsl:text>
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_to">
            <xsl:choose>
                <xsl:when test="$p_to = 'arabic'">
                    <xsl:value-of select="$v_digits-arabic"/>
                </xsl:when>
                <xsl:when test="$p_to = 'persian'">
                    <xsl:value-of select="$v_digits-persian"/>
                </xsl:when>
                <xsl:when test="$p_to = 'urdu'">
                    <xsl:value-of select="$v_digits-urdu"/>
                </xsl:when>
                <xsl:when test="$p_to = 'western'">
                    <xsl:value-of select="$v_digits-western"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message terminate="yes">
                        <xsl:text>Value for $p_to not available</xsl:text>
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="translate($p_input, $v_from, $v_to)"/>
    </xsl:function>
</xsl:stylesheet>
