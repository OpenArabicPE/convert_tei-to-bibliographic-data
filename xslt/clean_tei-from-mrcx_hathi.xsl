<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output indent="yes" method="xml"/>
    
    
    <!-- use @mode = 'm_off' to toggle templates off -->
    
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- this is expensive -->
    <xsl:template match="text()">
        <xsl:value-of select="normalize-unicode(., 'NFKC')"/>
    </xsl:template>
    
    <!-- the sorting instruction is expensive  -->
    <xsl:template match="tei:listBibl">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="tei:biblStruct">
                <xsl:sort select="tei:monogr/tei:title[1]"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
    <!-- remove erroneous automated transcriptions -->
    <xsl:template match="element()[@xml:lang = 'ar'][@resp = '#xslt']" mode="m_off"/>
    <xsl:template match="tei:title[@ref][@resp = '#xslt']">
        <xsl:copy>
            <xsl:apply-templates select="@xml:lang | @level | @type | @change"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    
    <!-- remove all orgs which are already part of the organizationography -->
    <xsl:template match="tei:org[parent::tei:listOrg][tei:orgName[@ref]]" mode="m_off"/>
    <!-- dates-->
    
    <xsl:template match="tei:date[matches(@when, '\d{4}-\d{1}-\d{1}$')]" priority="12">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="when">
                <xsl:analyze-string select="@when" regex="(\d{{4}}-)(\d{{1}})-(\d{{1}})$">
                    <xsl:matching-substring>
                        <xsl:value-of select="concat(regex-group(1),'0', regex-group(2), '-0', regex-group(3))"/>
                    </xsl:matching-substring>
                </xsl:analyze-string>
            </xsl:attribute>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:date[matches(@when, '\d{4}-\d{1}-\d{2}')]" priority="12">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="when">
                <xsl:analyze-string select="@when" regex="(\d{{4}}-)(\d{{1}})(-\d{{2}})$">
                    <xsl:matching-substring>
                        <xsl:value-of select="concat(regex-group(1),'0', regex-group(2), regex-group(3))"/>
                    </xsl:matching-substring>
                </xsl:analyze-string>
            </xsl:attribute>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:date[matches(@when, '\d{4}-\d{2}-\d{1}$')]" priority="12">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="when">
                <xsl:analyze-string select="@when" regex="(\d{{4}}-\d{{2}}-)(\d{{1}})$">
                    <xsl:matching-substring>
                        <xsl:value-of select="concat(regex-group(1),'0', regex-group(2))"/>
                    </xsl:matching-substring>
                </xsl:analyze-string>
            </xsl:attribute>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tei:date" priority="10" >
        <xsl:copy>
            <xsl:apply-templates select="@type"/>
            <xsl:choose>
                <xsl:when test="matches(@when, '^\d{4}$') and (number(@when) &lt; 1450)">
                    <xsl:attribute name="calendar" select="'#cal_islamic'"/>
                    <xsl:attribute name="datingMethod" select="'#cal_islamic'"/>
                    <xsl:attribute name="when-custom" select="@when"/>
                </xsl:when>
                <xsl:when test="matches(@when, '^\d{4}$') and (number(@when) &gt; 2050)">
                    <xsl:attribute name="calendar" select="'#cal_jewish'"/>
                    <xsl:attribute name="datingMethod" select="'#cal_jewish'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="@*"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- this template only needs to run once -->
    <xsl:template match="tei:date[not(@when)][not(@calendar = '#cal_islamic')]" priority="11">
        <xsl:variable name="v_text">
            <xsl:value-of select="descendant-or-self::text()"/>
        </xsl:variable>
        <xsl:variable name="v_text" select="normalize-space($v_text)"/>
        <xsl:choose>
            <xsl:when test="matches($v_text, '^\d{4}-\d{4}$')">
                <xsl:copy>
                    <xsl:apply-templates select="@*"/>
                    <xsl:attribute name="type" select="'onset'"/>
                    <xsl:attribute name="when" select="replace($v_text, '(\d{4})-(\d{4})', '$1')"/>
                    <xsl:apply-templates/>
                </xsl:copy>
                <xsl:copy>
                    <xsl:apply-templates select="@*"/>
                    <xsl:attribute name="type" select="'terminus'"/>
                    <xsl:attribute name="when" select="replace($v_text, '(\d{4})-(\d{4})', '$2')"/>
                    <xsl:apply-templates/>
                </xsl:copy>
            </xsl:when>
            <xsl:when test="matches(., '^\d{4}-')">
                <xsl:copy>
                    <xsl:apply-templates select="@*"/>
                    <xsl:attribute name="type" select="'onset'"/>
                    <xsl:attribute name="when" select="replace($v_text, '^(\d{4})-.*$', '$1')"/>
                    <xsl:apply-templates/>
                </xsl:copy>
            </xsl:when>
            <xsl:when test="matches($v_text, '^\d{4}$')">
                <xsl:copy>
                    <xsl:apply-templates select="@*"/>
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
    <!-- titles ending in = -->
    <xsl:template match="tei:title[ends-with(., '=')][following-sibling::tei:title[@type = 'sub']]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:value-of select="replace(., '\s*=$', '')"/>
        </xsl:copy>
    </xsl:template>
     <xsl:template match="tei:title[@type = 'sub'][preceding-sibling::tei:title[ends-with(., '=')]]">
        <xsl:copy>
            <xsl:apply-templates select="@level | @xml:lang"/>
            <xsl:apply-templates/>
        </xsl:copy>
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
    <xsl:template match="tei:publisher[not(tei:orgName)]" mode="m_off">
        <xsl:copy>
            <xsl:element name="orgName">
                <xsl:apply-templates/>
            </xsl:element>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
