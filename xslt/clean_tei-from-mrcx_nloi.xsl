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
            <xsl:apply-templates mode="m_post-process" select="tei:biblStruct | tei:bibl">
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
            <xsl:apply-templates mode="m_post-process" select="@* | tei:title | tei:idno"/>
            <!-- pull in IDs -->
            <xsl:element name="idno">
                <xsl:attribute name="type" select="'record'"/>
                <xsl:attribute name="source" select="'https://www.nli.org.il/'"/>
                <xsl:value-of select="substring-after(following-sibling::tei:note[@type = 'holdings']/descendant::node()[@source][1]/@source, 'https://www.nli.org.il/he/journals/NNL-Journals')"/>
            </xsl:element>
            <xsl:apply-templates mode="m_post-process" select="tei:respStmt | tei:textLang | tei:imprint"/>
        </xsl:copy>
    </xsl:template>
    <!-- add subtitles from comments -->
    <xsl:template match="tei:monogr[not(tei:title[@type = 'sub'])]" mode="m_off">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@* | tei:title"/>
            <!-- pull in IDs -->
            <xsl:if test="following-sibling::tei:note[@type = 'comments']/descendant::tei:item[1][matches(., '^&quot;.+&quot;$')]">
                <xsl:element name="title">
                    <xsl:attribute name="level" select="'j'"/>
                    <xsl:attribute name="type" select="'sub'"/>
                    <xsl:value-of select="replace(following-sibling::tei:note[@type = 'comments']/descendant::tei:item[1], '^&quot;(.+)&quot;$', '$1')"/>
                </xsl:element>
            </xsl:if>
            <xsl:apply-templates mode="m_post-process" select="tei:idno | tei:respStmt | tei:textLang | tei:imprint"/>
        </xsl:copy>
    </xsl:template>
    <!-- holding information in comments :
        works, but
        results need to be written to holdings
        original source items should be deleted
    
    -->
    <xsl:template match="tei:item[ancestor::tei:note[@type = 'comments'][not(descendant::tei:listBibl)]][matches(., 'يوجد ف. المكتبة')]" mode="m_off" priority="10">
      <!--<xsl:template match="tei:biblStruct[ancestor::tei:note[@type = 'comments']][. = '']" mode="m_post-process">-->
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@* | node()"/>
        </xsl:copy>
        <xsl:variable name="v_classmark">
            <xsl:choose>
                <!-- indicator of classmark -->
                <xsl:when test="matches(., '\sحسب\s')">
                    <xsl:value-of select="replace(., '^.+حسب\s+(\d+.*?)\s*\(.+$', '$1')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>NA</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:message>
            <xsl:value-of select="$v_classmark"/>
        </xsl:message>
        <xsl:element name="listBibl">
            <xsl:for-each select="following-sibling::tei:item/text()">
                <xsl:for-each select="tokenize(., '؛')">
                    <xsl:analyze-string regex="^((\[*\d+\]*)،\s*)*(\[*\d{{4}}\]*.*)$" select="normalize-space(.)">
                        <xsl:matching-substring>
                            <xsl:element name="bibl">
                                <!-- classmark -->
                                <xsl:if test="$v_classmark != 'NA'">
                                    <xsl:element name="idno">
                                        <xsl:attribute name="type" select="'classmark'"/>
                                        <xsl:value-of select="$v_classmark"/>
                                    </xsl:element>
                                </xsl:if>
                                <xsl:element name="biblScope">
                                    <xsl:attribute name="unit" select="'volume'"/>
                                    <xsl:value-of select="regex-group(2)"/>
                                </xsl:element>
                                <xsl:element name="date">
                                    <xsl:value-of select="regex-group(3)"/>
                                </xsl:element>
                            </xsl:element>
                        </xsl:matching-substring>
                        <xsl:non-matching-substring>
                            <xsl:message terminate="no">
                                <xsl:value-of select="."/>
                            </xsl:message>                            
                        </xsl:non-matching-substring>
                    </xsl:analyze-string>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:element>
    </xsl:template>
    <!-- insert holdings from comments after the last listBibl in holdings -->
    <xsl:template match="tei:listBibl[ancestor::tei:note[@type = 'holdings'][preceding-sibling::tei:note[@type = 'comments']/descendant::tei:listBibl]][last()]" mode="m_post-process">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="m_post-process"/>
        </xsl:copy>
        <xsl:copy-of select="ancestor::tei:note[@type = 'holdings']/preceding-sibling::tei:note[@type = 'comments']/descendant::tei:listBibl"/>
    </xsl:template>
    <!-- remove all listBibl from comments -->
    <xsl:template match="tei:listBibl[ancestor::tei:note[@type = 'comments']]" mode="m_post-process" priority="10"/>
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
</xsl:stylesheet>
