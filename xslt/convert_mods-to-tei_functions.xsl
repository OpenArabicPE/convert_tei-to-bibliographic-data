<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:mods="http://www.loc.gov/mods/v3" xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:zot="https://zotero.org" xmlns:cpc="http://copac.ac.uk/schemas/mods-copac/v1"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no" version="1.0"/>
    <xsl:import href="functions.xsl"/>
    <xsl:import href="../../oxygen-project/OpenArabicPE_parameters.xsl"/>
    <!-- this stylesheet translates <mods:mods> to <tei:biblStruct> -->
    <!-- to do
        - [x] normalise language codes
        - [x] editors
        - [ ] date ranges are wrongly parsed
        - [ ] relatedItem frequently carries OCLC IDs (OCoLC)
        - [ ] check nonSort and the lack of trailing white space
    -->
    <!-- debugging -->
    <!-- <xsl:template match="/">
        <xsl:apply-templates select="descendant::mods:mods" mode="m_mods-to-tei"/>
    </xsl:template>
    <xsl:template match="mods:mods" mode="m_mods-to-tei">
        <xsl:copy-of select="oape:bibliography-mods-to-tei(.)"/>
    </xsl:template>-->
    <!-- funtion -->
    <xsl:function name="oape:bibliography-mods-to-tei">
        <!-- input is a mods -->
        <xsl:param as="node()" name="p_input"/>
        <!-- test for correct input -->
        <xsl:choose>
            <xsl:when test="$p_input/self::mods:mods">
                <!-- establish the type of input resource -->
                <xsl:variable name="v_type-publication">
                    <xsl:choose>
                        <xsl:when test="$p_input/mods:originInfo/mods:issuance = 'serial'">
                            <xsl:text>serial</xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="v_originInfo">
                    <mods:originInfo>
                        <xsl:apply-templates select="$p_input/mods:originInfo/element()"/>
                    </mods:originInfo>
                </xsl:variable>
                <!-- construct output -->
                <xsl:choose>
                    <xsl:when test="$v_type-publication = 'serial'">
                        <biblStruct type="periodical">
                            <!-- frequency -->
                            <xsl:apply-templates mode="m_mods-to-tei" select="$v_originInfo//mods:frequency"/>
                            <monogr>
                                <!-- titles -->
                                <xsl:apply-templates mode="m_mods-to-tei" select="$p_input/mods:titleInfo"/>
                                <xsl:apply-templates mode="m_mods-to-tei" select="$p_input/mods:extension/cpc:nonLatin/mods:titleInfo"/>
                                <xsl:apply-templates mode="m_mods-to-tei" select="$p_input/mods:language"/>
                                <!-- IDs -->
                                <xsl:apply-templates mode="m_mods-to-tei" select="$p_input/mods:recordInfo"/>
                                <xsl:apply-templates mode="m_mods-to-tei" select="$p_input/mods:identifier"/>
                                <!-- url -->
                                <xsl:apply-templates mode="m_mods-to-tei" select="$p_input/mods:location[mods:url]"/>
                                <xsl:apply-templates mode="m_mods-to-tei" select="$p_input/mods:name"/>
                                <xsl:apply-templates mode="m_mods-to-tei" select="$p_input/mods:extension/cpc:nonLatin/mods:name"/>
                                <!-- imprint -->
                                <xsl:apply-templates mode="m_mods-to-tei" select="$v_originInfo"/>
                            </monogr>
                            <!-- notes -->
                            <xsl:apply-templates mode="m_mods-to-tei" select="$p_input/mods:note"/>
                            <xsl:if test="$p_input/mods:extension//mods:mods">
                                <note type="holdings">
                                    <list>
                                        <xsl:apply-templates mode="m_holdings" select="$p_input/mods:extension//mods:mods"/>
                                    </list>
                                </note>
                            </xsl:if>
                        </biblStruct>
                    </xsl:when>
                    <!-- old code -->
                    <xsl:otherwise>
                        <biblStruct>
                            <xsl:attribute name="zot:genre" select="$p_input/mods:genre[@authority = 'local']"/>
                            <!-- the article: analytic -->
                            <analytic>
                                <xsl:apply-templates mode="m_mods-to-tei" select="$p_input/mods:titleInfo"/>
                                <xsl:apply-templates mode="m_mods-to-tei" select="$p_input/mods:name"/>
                                <xsl:apply-templates mode="m_mods-to-tei" select="$p_input/mods:location"/>
                            </analytic>
                            <!-- the host item: monogr -->
                            <xsl:apply-templates mode="m_mods-to-tei" select="$p_input/mods:relatedItem"/>
                            <!-- notes -->
                            <xsl:if test="$p_input/descendant::mods:subject">
                                <note type="tagList">
                                    <list>
                                        <xsl:for-each select="$p_input/descendant::mods:subject/mods:topic">
                                            <item>
                                                <xsl:apply-templates mode="m_plain-text" select="."/>
                                            </item>
                                        </xsl:for-each>
                                    </list>
                                </note>
                            </xsl:if>
                        </biblStruct>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>
                    <xsl:text>$p_input is not a &lt;mods:mods&gt; note.</xsl:text>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <!-- URLs -->
    <xsl:template match="mods:location" mode="m_mods-to-tei">
        <xsl:apply-templates mode="m_mods-to-tei"/>
    </xsl:template>
    <xsl:template match="mods:url" mode="m_mods-to-tei">
        <idno type="url">
            <xsl:value-of select="."/>
        </idno>
    </xsl:template>
    <!-- monogr -->
    <xsl:template match="mods:relatedItem[@type = 'host']" mode="m_mods-to-tei">
        <!-- output -->
        <monogr>
            <!-- titles -->
            <xsl:apply-templates mode="m_mods-to-tei" select="mods:titleInfo"/>
            <!-- contributors -->
            <xsl:apply-templates mode="m_mods-to-tei" select="mods:name"/>
            <!-- identifiers -->
            <xsl:apply-templates mode="m_mods-to-tei" select="mods:identifier"/>
            <!-- language -->
            <xsl:apply-templates mode="m_mods-to-tei" select="parent::mods:mods/mods:language"/>
            <!-- imprint -->
            <xsl:apply-templates mode="m_mods-to-tei" select="mods:originInfo"/>
            <!-- volume, issue, pages -->
            <xsl:apply-templates mode="m_mods-to-tei" select="mods:part"/>
        </monogr>
    </xsl:template>
    <xsl:template match="mods:language" mode="m_mods-to-tei">
        <xsl:choose>
            <xsl:when test="mods:languageTerm[@authority = 'iso639-2b']">
                <xsl:apply-templates mode="m_mods-to-tei" select="mods:languageTerm[@authority = 'iso639-2b']"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates mode="m_mods-to-tei"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="mods:languageTerm" mode="m_mods-to-tei">
        <textLang>
            <xsl:attribute name="mainLang">
                <xsl:choose>
                    <xsl:when test="@authority = 'iso639-2b'">
                        <xsl:value-of select="oape:string-convert-lang-codes(.)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="."/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
        </textLang>
    </xsl:template>
    <!-- identifiers -->
    <xsl:template match="mods:identifier" mode="m_mods-to-tei">
        <idno type="{@type}">
            <xsl:apply-templates mode="m_plain-text" select="."/>
        </idno>
    </xsl:template>
    <!-- imprint -->
    <xsl:template match="mods:originInfo" mode="m_mods-to-tei">
        <imprint>
            <xsl:apply-templates mode="m_mods-to-tei" select="mods:place"/>
            <xsl:apply-templates mode="m_mods-to-tei" select="mods:publisher"/>
            <xsl:apply-templates mode="m_mods-to-tei" select="mods:dateIssued"/>
        </imprint>
    </xsl:template>
    <!-- volume, issue, pages -->
    <xsl:template match="mods:part" mode="m_mods-to-tei">
        <xsl:apply-templates mode="m_mods-to-tei"/>
    </xsl:template>
    <xsl:template match="mods:detail" mode="m_mods-to-tei">
        <biblScope from="{mods:number}" to="{mods:number}" unit="{@type}"/>
    </xsl:template>
    <xsl:template match="mods:extent" mode="m_mods-to-tei">
        <biblScope>
            <xsl:attribute name="unit">
                <xsl:choose>
                    <xsl:when test="@unit = 'pages'">
                        <xsl:text>page</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="@unit"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <xsl:if test="mods:start">
                <xsl:attribute name="from" select="mods:start"/>
            </xsl:if>
            <xsl:if test="mods:end">
                <xsl:attribute name="to" select="mods:end"/>
            </xsl:if>
        </biblScope>
    </xsl:template>
    <!-- imprint -->
    <xsl:template match="mods:place" mode="m_mods-to-tei">
        <pubPlace>
            <xsl:apply-templates mode="m_mods-to-tei" select="mods:placeTerm"/>
        </pubPlace>
    </xsl:template>
    <xsl:template match="mods:publisher" mode="m_mods-to-tei">
        <publisher>
            <xsl:apply-templates select="@xml:lang"/>
            <!-- publishers are commonly organisations. Since this information is not present in MODS, we can only assume it -->
            <orgName>
                <xsl:apply-templates mode="m_plain-text" select="."/>
            </orgName>
        </publisher>
    </xsl:template>
    <xsl:template match="mods:dateIssued" mode="m_mods-to-tei">
        <date>
            <xsl:if test="@point">
                <xsl:attribute name="type">
                    <xsl:choose>
                        <xsl:when test="@point = 'start'">
                            <xsl:text>onset</xsl:text>
                        </xsl:when>
                        <xsl:when test="@point = 'stop'">
                            <xsl:text>terminus</xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </xsl:attribute>
            </xsl:if>
            <!-- we leave parsing of dates to the post-processing step -->
            <!--<xsl:choose>
                <xsl:when test="matches(., '\d{4}-\d{2}-\d{2}')">
                    <xsl:attribute name="when" select="."/>
                </xsl:when>
                <xsl:when test="matches(., '\d{4}$')">
                    <xsl:attribute name="when" select="."/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>
                        <xsl:text>WARNING: The date "</xsl:text>
                        <xsl:value-of select="."/>
                        <xsl:text>" has the wrong format for automated parsing.</xsl:text>
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>-->
            <xsl:apply-templates mode="m_plain-text"/>
        </date>
    </xsl:template>
    <!-- titles -->
    <xsl:template match="mods:titleInfo" mode="m_mods-to-tei">
        <xsl:variable name="v_title-pre-processed">
            <xsl:apply-templates mode="m_mods-to-tei" select="mods:title"/>
        </xsl:variable>
        <!-- to account for potential errors in splitting of titles and subtitles m_process is applied -->
        <xsl:apply-templates mode="m_process" select="$v_title-pre-processed/descendant-or-self::tei:title"/>
        <xsl:apply-templates mode="m_mods-to-tei" select="mods:subTitle"/>
    </xsl:template>
    <!-- establish the correct value for @level -->
    <xsl:template match="mods:title" mode="m_mods-to-tei">
        <xsl:element name="title">
            <xsl:apply-templates select="@xml:lang"/>
            <xsl:attribute name="level">
                <xsl:choose>
                    <xsl:when test="parent::mods:titleInfo/parent::mods:mods">
                        <xsl:value-of select="'a'"/>
                    </xsl:when>
                    <xsl:when test="parent::mods:titleInfo/parent::mods:relatedItem">
                        <xsl:choose>
                            <xsl:when test="ancestor::mods:mods/mods:genre = 'journalArticle'">
                                <xsl:value-of select="'j'"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="'m'"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                </xsl:choose>
            </xsl:attribute>
            <xsl:apply-templates mode="m_plain-text" select="."/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="tei:title" mode="m_process">
        <!-- check if title contains ":". If so, split into two titles -->
        <xsl:choose>
            <xsl:when test="contains(., ': ')">
                <!-- main title -->
                <xsl:copy>
                    <xsl:apply-templates select="@*"/>
                    <xsl:value-of select="replace(., '(.+?):\s+.+$', '$1')"/>
                </xsl:copy>
                <!-- sub title -->
                <xsl:copy>
                    <xsl:apply-templates select="@*"/>
                    <xsl:attribute name="type" select="'sub'"/>
                    <xsl:value-of select="replace(., '.+?:\s+(.+)$', '$1')"/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- identity transform -->
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <!-- sub titles -->
    <xsl:template match="mods:subTitle" mode="m_mods-to-tei">
        <title type="sub">
            <xsl:apply-templates select="@xml:lang"/>
            <xsl:apply-templates mode="m_plain-text" select="."/>
        </title>
    </xsl:template>
    <!-- persons, places, names -->
    <xsl:template match="mods:name[@type = 'personal']" mode="m_mods-to-tei">
        <xsl:choose>
            <xsl:when test="mods:role/mods:roleTerm[@authority = 'marcrelator'] = 'edt'">
                <editor>
                    <xsl:apply-templates select="@xml:lang"/>
                    <xsl:apply-templates mode="m_name" select="."/>
                </editor>
            </xsl:when>
            <xsl:when test="mods:role/mods:roleTerm[@authority = 'marcrelator'] = 'aut'">
                <author>
                    <xsl:apply-templates select="@xml:lang"/>
                    <xsl:apply-templates mode="m_name" select="."/>
                </author>
            </xsl:when>
            <xsl:when test="mods:role/mods:roleTerm = 'creator'">
                <author>
                    <xsl:apply-templates select="@xml:lang"/>
                    <xsl:apply-templates mode="m_name" select="."/>
                </author>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="mods:name[@type = 'corporate']" mode="m_mods-to-tei">
        <editor>
            <orgName>
                <xsl:apply-templates select="@valueURI | @xml:lang"/>
                <xsl:apply-templates mode="m_mods-to-tei" select="mods:namePart"/>
            </orgName>
        </editor>
    </xsl:template>
    <!-- omit all other types of names from output -->
    <xsl:template match="mods:name" mode="m_mods-to-tei"/>
    <xsl:template match="mods:name" mode="m_name">
        <persName>
            <xsl:apply-templates select="@valueURI | @xml:lang"/>
            <xsl:apply-templates mode="m_mods-to-tei" select="mods:namePart"/>
        </persName>
    </xsl:template>
    <xsl:template match="mods:namePart" mode="m_mods-to-tei">
        <xsl:choose>
            <xsl:when test="@type = 'family'">
                <surname>
                    <xsl:apply-templates select="@xml:lang"/>
                    <xsl:apply-templates mode="m_plain-text" select="."/>
                </surname>
            </xsl:when>
            <xsl:when test="@type = 'given'">
                <forename>
                    <xsl:apply-templates select="@xml:lang"/>
                    <xsl:apply-templates mode="m_plain-text" select="."/>
                </forename>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates mode="m_plain-text" select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="mods:placeTerm" mode="m_mods-to-tei">
        <xsl:choose>
            <xsl:when test="@authority = 'marccountry'">
                <country>
                    <xsl:apply-templates mode="m_plain-text" select="."/>
                </country>
            </xsl:when>
            <xsl:otherwise>
                <placeName>
                    <xsl:apply-templates select="@valueURI | @xml:lang"/>
                    <xsl:apply-templates mode="m_plain-text" select="."/>
                </placeName>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="mods:frequency" mode="m_mods-to-tei">
        <xsl:attribute name="oape:frequency" select="."/>
    </xsl:template>
    <xsl:template match="mods:recordInfo" mode="m_mods-to-tei">
        <xsl:apply-templates mode="m_mods-to-tei" select="mods:recordIdentifier"/>
    </xsl:template>
    <xsl:template match="mods:recordIdentifier" mode="m_mods-to-tei">
        <idno>
            <xsl:if test="@source">
                <xsl:attribute name="type" select="@source"/>
            </xsl:if>
            <xsl:apply-templates mode="m_plain-text" select="."/>
        </idno>
    </xsl:template>
    <xsl:template match="mods:note" mode="m_mods-to-tei">
        <note>
            <xsl:attribute name="type" select="'comments'"/>
            <xsl:apply-templates mode="m_mods-to-tei"/>
        </note>
    </xsl:template>
    <!-- holdings -->
    <xsl:template match="mods:mods" mode="m_holdings">
        <item>
            <!-- institution -->
            <label>
                <xsl:apply-templates mode="m_mods-to-tei" select="mods:location/mods:physicalLocation"/>
            </label>
            <listBibl>
                <bibl>
                    <!-- IDs -->
                    <xsl:apply-templates mode="m_mods-to-tei" select="mods:recordInfo"/>
                    <xsl:apply-templates mode="m_mods-to-tei" select="mods:identifier"/>
                    <!-- extent of holdings -->
                    <xsl:apply-templates mode="m_mods-to-tei" select="mods:location/mods:holdingSimple/mods:copyInformation"/>
                </bibl>
            </listBibl>
            <!-- format -->
            <note type="format">
                <xsl:apply-templates mode="m_mods-to-tei" select="mods:physicalDescription/mods:form[@authority = 'marcform']"/>
            </note>
        </item>
    </xsl:template>
    <xsl:template match="mods:physicalLocation" mode="m_mods-to-tei">
        <orgName>
            <xsl:apply-templates mode="m_plain-text" select="."/>
        </orgName>
    </xsl:template>
    <xsl:template match="mods:physicalLocation[@authority = 'UkMaC']" mode="m_mods-to-tei"/>
    <xsl:template match="mods:copyInformation" mode="m_mods-to-tei">
        <xsl:apply-templates mode="m_mods-to-tei" select="mods:shelfLocator | mods:enumerationAndChronology"/>
    </xsl:template>
    <xsl:template match="mods:shelfLocator" mode="m_mods-to-tei">
        <idno type="classmark">
            <xsl:apply-templates mode="m_plain-text" select="."/>
        </idno>
    </xsl:template>
    <xsl:template match="mods:enumerationAndChronology" mode="m_mods-to-tei">
        <biblScope>
            <xsl:apply-templates mode="m_plain-text" select="."/>
        </biblScope>
    </xsl:template>
    <!-- attributes -->
    <xsl:template match="@xml:lang">
        <xsl:copy/>
    </xsl:template>
    <xsl:template match="@valueURI">
        <xsl:attribute name="ref" select="."/>
    </xsl:template>
    <!-- plain text output: beware that heavily marked up nodes will have most whitespace omitted -->
    <xsl:template match="text()" mode="m_plain-text">
        <!--        <xsl:value-of select="normalize-space(replace(.,'(\w)[\s|\n]+','$1 '))"/>-->
        <!--        <xsl:text> </xsl:text>-->
        <xsl:value-of select="normalize-space(.)"/>
        <!--        <xsl:text> </xsl:text>-->
    </xsl:template>
    <!-- holding institutions -->
    <xsl:template mode="m_get-holding-institutions" match="mods:mods">
        <org>
            <xsl:apply-templates mode="m_get-holding-institutions" select="mods:location"/>
            <xsl:if test="mods:recordInfo/mods:recordIdentifier[@source = 'UkMaC']">
                <xsl:apply-templates mode="m_get-holding-institutions" select="mods:recordInfo/mods:recordIdentifier[not(@source = 'UkMaC')]"/>
            </xsl:if>
        </org>
    </xsl:template>
    <xsl:template mode="m_get-holding-institutions" match="mods:location">
        <xsl:apply-templates mode="m_get-holding-institutions" select="mods:physicalLocation"/>
    </xsl:template>
    <xsl:template mode="m_get-holding-institutions" match="mods:physicalLocation">
        <orgName><xsl:apply-templates select="." mode="m_plain-text"/></orgName>
    </xsl:template>
    <xsl:template mode="m_get-holding-institutions" match="mods:physicalLocation[@authority = 'UkMaC']">
        <idno type="{@authority}">
            <xsl:apply-templates mode="m_plain-text" select="."/>
        </idno>
    </xsl:template>
    <xsl:template mode="m_get-holding-institutions" match="mods:recordIdentifier">
        <idno type="isil">
            <xsl:if test="parent::mods:recordInfo/mods:recordIdentifier[not(@source = 'UkMaC')]">
                <xsl:value-of select="concat('GB-', @source)"/>
            </xsl:if>
        </idno>
    </xsl:template>
</xsl:stylesheet>
