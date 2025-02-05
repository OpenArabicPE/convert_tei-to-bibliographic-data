<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output indent="yes" method="xml"/>
    <xsl:import href="post-process_tei-biblstruct_functions.xsl"/>
    <xsl:param name="p_source" select="'oape:org:10'"/>
    <!-- use @mode = 'm_off' to toggle templates off -->
    <!-- add templates specific to this particular input -->
    <xsl:template match="tei:date[@type = 'acquisition'][year-from-date(@when) lt 1931]/@type" mode="m_off" priority="10">
        <xsl:attribute name="type" select="'official'"/>
    </xsl:template>
    <xsl:template mode="m_off" match="tei:bibl[tei:date[@type = 'acquisition']]/tei:date[not(@type)]" priority="15">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@*"/>
            <xsl:attribute name="type" select="'official'"/>
            <xsl:apply-templates mode="m_post-process"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:date[not(@type)][parent::tei:bibl/ancestor::tei:note[@type = 'holdings']][not(parent::tei:bibl/tei:date[@type = 'official'])][number(substring(@when, 1, 4)) lt 1931]" mode="m_off" priority="10">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@*"/>
            <xsl:attribute name="type" select="'official'"/>
            <xsl:apply-templates mode="m_post-process"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:listBibl[not(descendant::tei:bibl[@type = 'holdings'])]/tei:bibl[@type = 'copy'][1]" mode="m_off" priority="20">
        <xsl:variable name="v_bibls">
            <xsl:apply-templates mode="m_identity-transform" select="."/>
            <xsl:apply-templates mode="m_identity-transform" select="following-sibling::tei:bibl[@type = 'copy']"/>
        </xsl:variable>
        <bibl type="holdings" resp="#xslt">
            <!-- IDs -->
            <xsl:apply-templates mode="m_identity-transform" select="ancestor::tei:biblStruct/tei:monogr/tei:idno[@source = current()/@source]"/>
            <xsl:apply-templates mode="m_identity-transform" select="ancestor::tei:biblStruct/tei:monogr/tei:idno[@source = $p_source]"/>
            <!-- scope -->
            <xsl:choose>
                <!-- as issue counting usually restarts every year, it doesn't make sense to provide min and max issue numbers -->
                <xsl:when test="$v_bibls/descendant::tei:biblScope[@unit = 'volume']">
                    <biblScope unit="volume">
                        <xsl:attribute name="from" select="min($v_bibls/descendant::tei:biblScope[@unit = 'volume']/@from)"/>
                        <xsl:attribute name="to" select="max($v_bibls/descendant::tei:biblScope[@unit = 'volume']/@to)"/>
                    </biblScope>
                </xsl:when>
                <xsl:when test="$v_bibls/descendant::tei:biblScope[@unit = 'issue']">
                    <biblScope unit="issue">
                        <xsl:attribute name="from" select="min($v_bibls/descendant::tei:biblScope[@unit = 'issue']/@from)"/>
                        <xsl:attribute name="to" select="max($v_bibls/descendant::tei:biblScope[@unit = 'issue']/@to)"/>
                    </biblScope>
                </xsl:when>
            </xsl:choose>
            <!-- add dates -->
            <xsl:if test="$v_bibls/descendant::tei:date[@when]">
                <date type="onset">
                    <xsl:attribute name="when" select="oape:dates-get-maxima($v_bibls/descendant::tei:date[@when], 'onset')"/>
                </date>
                <date type="terminus">
                    <xsl:attribute name="when" select="oape:dates-get-maxima($v_bibls/descendant::tei:date[@when], 'terminus')"/>
                </date>
            </xsl:if>
        </bibl>
        <!-- reproduce the original -->
        <xsl:apply-templates mode="m_identity-transform" select="."/>
    </xsl:template>
    <!-- clean persNames -->
    <xsl:template match="tei:forename[ancestor::tei:respStmt]" mode="m_post-process" priority="20">
        <surname>
            <xsl:apply-templates mode="m_post-process" select="@* | node()"/>
        </surname>
    </xsl:template>
    <xsl:template match="tei:surname[ancestor::tei:respStmt]" mode="m_post-process" priority="20">
        <forename>
            <xsl:apply-templates mode="m_post-process" select="@* | node()"/>
        </forename>
    </xsl:template>
    <xsl:template match="tei:bibl[ancestor::tei:note[@type = 'holdings']][descendant::tei:date[@type = 'official']]" mode="m_off" priority="10">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@*"/>
            <xsl:attribute name="type" select="'copy'"/>
            <xsl:apply-templates mode="m_post-process"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:date[not(@when)][matches(., '^.+ - .+$')]" mode="m_off" priority="10">
        <xsl:copy>
            <xsl:apply-templates mode="m_identity-transform" select="@*"/>
            <xsl:attribute name="type" select="'onset'"/>
            <xsl:apply-templates mode="m_post-process" select="substring-before(., ' -')"/>
        </xsl:copy>
        <xsl:copy>
            <xsl:apply-templates mode="m_identity-transform" select="@*"/>
            <xsl:attribute name="type" select="'terminus'"/>
            <xsl:apply-templates mode="m_post-process" select="substring-after(., ' -')"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:idno[@type = 'url'][starts-with(., '/search?/')]" mode="m_off"/>
    <xsl:template match="tei:biblScope[not(@unit)]" mode="m_off"/>
    <xsl:template match="tei:idno[@type = 'URI']" mode="m_off">
        <xsl:copy>
            <xsl:attribute name="type" select="'url'"/>
            <xsl:attribute name="subtype" select="'permalink'"/>
            <xsl:apply-templates mode="m_post-process"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
