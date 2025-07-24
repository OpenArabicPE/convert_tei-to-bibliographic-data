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
    
    <!-- sort by ID  -->
    <xsl:template match="tei:listBibl" mode="m_off" priority="10">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@* | tei:head"/>
            <xsl:apply-templates select="tei:biblStruct | tei:bibl" mode="m_post-process">
                <xsl:sort select="descendant::tei:idno[@type = 'record'][1]"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    <!-- remove biblStruct without holdings -->
    <xsl:template match="tei:biblStruct[not(tei:note[@type = 'holdings'])]" mode="m_off" priority="20"/>
    <!-- remove duplicate IDs -->
    <xsl:template match="tei:monogr/tei:idno[. = preceding-sibling::tei:idno]" mode="m_off"/>
    <!-- add missing IDs -->
    <xsl:template match="tei:monogr[not(tei:idno[@type = 'record'])]" mode="m_off">
        <xsl:copy>
            <xsl:apply-templates select="@* | tei:title |tei:idno" mode="m_post-process"/>
            <!-- pull in IDs -->
            <xsl:element name="idno">
                <xsl:attribute name="type" select="'record'"/>
                <xsl:attribute name="source" select="'https://www.nli.org.il/'"/>
                <xsl:value-of select="substring-after(following-sibling::tei:note[@type = 'holdings']/descendant::node()[@source][1]/@source, 'https://www.nli.org.il/he/journals/NNL-Journals')"/>
            </xsl:element>
            <xsl:apply-templates select="tei:respStmt | tei:textLang | tei:imprint" mode="m_post-process"/>
        </xsl:copy>
    </xsl:template>
    <!-- add subtitles from comments -->
    <xsl:template match="tei:monogr[not(tei:title[@type = 'sub'])]" mode="m_off">
        <xsl:copy>
            <xsl:apply-templates select="@* | tei:title" mode="m_post-process"/>
            <!-- pull in IDs -->
            <xsl:if test="following-sibling::tei:note[@type = 'comments']/descendant::tei:item[1][matches(., '^&quot;.+&quot;$')]">
                <xsl:element name="title">
                    <xsl:attribute name="level" select="'j'"/>
                    <xsl:attribute name="type" select="'sub'"/>
                    <xsl:value-of select="replace(following-sibling::tei:note[@type = 'comments']/descendant::tei:item[1], '^&quot;(.+)&quot;$', '$1')"/>
                </xsl:element>
            </xsl:if>
            <xsl:apply-templates select="tei:idno | tei:respStmt | tei:textLang | tei:imprint" mode="m_post-process"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- postprocessing specific to KOHA -->
    <xsl:template match="tei:forename/text()" mode="m_off">
        <xsl:value-of select="replace(., '(\s*\.)$', '')"/>
    </xsl:template>
    <xsl:template match="tei:textLang[parent::tei:monogr/tei:title[contains(., 'سالنامه')]]" mode="m_off">
        <xsl:copy>
            <xsl:attribute name="mainLang" select="'ota'"/>
            <xsl:apply-templates mode="m_post-process"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:title[contains(., 'سالنامه')]" mode="m_off">
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
</xsl:stylesheet>
