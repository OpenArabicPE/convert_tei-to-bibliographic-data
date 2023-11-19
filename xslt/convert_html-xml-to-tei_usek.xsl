<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="xs" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:html="http://www.w3.org/1999/xhtml" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no"/>
    <!--<xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>-->
    <xsl:template match="/">
        <listBibl>
            <note>Conversion of <xsl:value-of select="count(descendant::html:div[@class = 'briefcitRow'])"/> <gi>html:div</gi> to <gi>tei:biblStruct</gi></note>
            <xsl:apply-templates select="descendant::html:div[@class = 'briefcitRow']"/>
        </listBibl>
    </xsl:template>
    <xsl:template match="html:div[@class = 'briefcitRow']">
        <biblStruct type="periodical" source="https://sierra.usek.edu.lb/">
            <monogr>
                <!-- title -->
                <xsl:apply-templates select="descendant::html:h2[@class = 'briefcitTitle']/html:a"/>
                <!-- IDs -->
                <xsl:apply-templates select="descendant::html:tr[@class = 'bibItemsEntry'][1]/html:td[2]"/>
                <xsl:apply-templates select="descendant::html:input[@name = 'save']"/>
                <xsl:apply-templates select="descendant::html:h2[@class = 'briefcitTitle']/html:a" mode="m_link"/>
                <!-- imprint -->
                <imprint>
                    <xsl:apply-templates select="descendant::html:div[@class = 'briefcitDetailMain']"/>
                </imprint>
            </monogr>
            <!-- holdings -->
            <xsl:apply-templates select="descendant::html:table[@class = 'bibItems']"/>
        </biblStruct>
    </xsl:template>
    <xsl:template match="html:table[@class = 'bibItems']">
        <note type="holdings">
            <list>
                <item>
                    <label><placeName>Jounieh</placeName>, <orgName ref="oape:org:567">USEK</orgName></label>
                    <ab>
                        <listBibl>
                            <xsl:apply-templates select="descendant::html:tr[@class = 'bibItemsEntry']"/>
                        </listBibl>
                    </ab>
                </item>
            </list>
        </note>
    </xsl:template>
    <xsl:template match="html:tr[@class = 'bibItemsEntry']">
        <bibl>
            <xsl:apply-templates select="html:td[2]"/>
            <xsl:apply-templates select="html:td[3]"/>
            <xsl:apply-templates select="html:td[6]"/>
        </bibl>
    </xsl:template>
    <xsl:template match="html:tr[@class = 'bibItemsEntry']/html:td[2]">
        <idno type="classmark"><xsl:value-of select="normalize-space(.)"/></idno>
    </xsl:template>
    <xsl:template match="html:tr[@class = 'bibItemsEntry']/html:td[3]">
        <biblScope><xsl:value-of select="normalize-space(.)"/></biblScope>
    </xsl:template>
    <xsl:template match="html:tr[@class = 'bibItemsEntry']/html:td[6]">
        <date><xsl:value-of select="normalize-space(.)"/></date>
    </xsl:template>
    <xsl:template match="html:div[@class = 'briefcitDetailMain']">
        <xsl:apply-templates select="descendant::text()[not(parent::html:a)]"/>
    </xsl:template>
    <xsl:template match="html:h2[@class = 'briefcitTitle']/html:a">
        <title level="j">
            <xsl:value-of select="."/>
        </title>
    </xsl:template>
    <xsl:template match="html:h2[@class = 'briefcitTitle']/html:a" mode="m_link">
        <idno type="url">
            <xsl:value-of select="@href"/>
        </idno>
    </xsl:template>
    <xsl:template match="html:input[@name = 'save']">
        <idno type="classmark">
            <xsl:value-of select="@value"/>
        </idno>
        <idno type="URI">
            <xsl:value-of select="concat('https://sierra.usek.edu.lb/record=', @value)"/>
        </idno>
    </xsl:template>
</xsl:stylesheet>
