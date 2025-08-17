<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.loc.gov/mods/v3" xmlns:cc="http://web.resource.org/cc/" xmlns:mods="http://www.loc.gov/mods/v3"
    xmlns:oape="https://openarabicpe.github.io/ns" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xpath-default-namespace="http://www.loc.gov/mods/v3">
    <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no" version="1.0"/>
    <!-- this stylesheet translates <tei:biblStruct>s to  <mods:mods> -->
    <!-- date conversion functions -->
    <xsl:import href="https://tillgrallert.github.io/xslt-calendar-conversion/functions/date-functions.xsl"/>
    <!--     <xsl:include href="../../../xslt-calendar-conversion/date-functions.xsl"/> -->
    <xsl:import href="convert_tei-to-biblstruct_functions.xsl"/>
    <!-- this needs to be adopted to work with any periodical and not just al-Muqtabas -->
    <xsl:variable name="v_schema" select="'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/mods-3-8.xsd'"/>
    <!-- the MODS output -->
    <xsl:function name="oape:bibliography-tei-to-mods">
        <!-- input is a bibl or biblStruct -->
        <xsl:param name="p_input"/>
        <!-- output language -->
        <xsl:param name="p_lang"/>
        <!-- missing bits: absent from biblStruct
            - date last accessed
            - edition
        -->
        <!-- input variables -->
        <xsl:variable name="v_biblStruct">
            <xsl:choose>
                <xsl:when test="$p_input/local-name() = 'bibl'">
                    <xsl:apply-templates mode="m_bibl-to-biblStruct" select="$p_input"/>
                </xsl:when>
                <xsl:when test="$p_input/local-name() = 'biblStruct'">
                    <xsl:apply-templates mode="m_copy-from-source" select="$p_input"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>
                        <xsl:text>Input is neither bibl nor biblStruct</xsl:text>
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_analytic" select="$v_biblStruct/tei:biblStruct/tei:analytic"/>
        <xsl:variable name="v_monogr" select="$v_biblStruct/tei:biblStruct/tei:monogr"/>
        <xsl:variable name="v_imprint" select="$v_monogr/tei:imprint"/>
        <!-- output variables -->
        <xsl:variable name="v_originInfo">
            <originInfo>
                <!-- information on the edition: it would be weird to mix data of the original source and the digital edition -->
                <!--<edition xml:lang="en">
                    <xsl:variable name="v_plain">
                        <xsl:apply-templates select="$p_edition" mode="m_plain-text"/>
                    </xsl:variable>
                    <xsl:value-of select="normalize-space($v_plain)"/>
                </edition>-->
                <xsl:if test="$v_imprint/tei:pubPlace">
                    <place>
                        <xsl:choose>
                            <xsl:when test="$v_imprint/tei:pubPlace/tei:placeName[@xml:lang = $p_lang]">
                                <xsl:apply-templates mode="m_tei-to-mods" select="$v_imprint/tei:pubPlace/tei:placeName[@xml:lang = $p_lang]"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates mode="m_tei-to-mods" select="$v_imprint/tei:pubPlace/tei:placeName[1]"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </place>
                </xsl:if>
                <xsl:choose>
                    <xsl:when test="$v_imprint/tei:publisher/child::node()[@xml:lang = $p_lang]">
                        <xsl:apply-templates mode="m_tei-to-mods" select="$v_imprint/tei:publisher/child::node()[@xml:lang = $p_lang]"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates mode="m_tei-to-mods" select="$v_imprint/tei:publisher"/>
                    </xsl:otherwise>
                </xsl:choose>
                <!-- date on analytic -->
                <xsl:if test="$v_analytic/tei:date">
                    <xsl:apply-templates mode="m_tei-to-mods" select="$v_analytic/tei:date"/>
                </xsl:if>
                <!-- dates -->
                <xsl:choose>
                    <xsl:when test="$v_imprint/tei:date/@when != ''">
                        <xsl:apply-templates mode="m_tei-to-mods" select="$v_imprint/tei:date[@when][1]"/>
                    </xsl:when>
                    <xsl:when test="$v_imprint/tei:date[@from]">
                        <xsl:apply-templates mode="m_tei-to-mods" select="$v_imprint/tei:date[@from][1]"/>
                    </xsl:when>
                </xsl:choose>
                <!-- add hijri dates -->
                <xsl:if test="$v_imprint/tei:date/@calendar = '#cal_islamic'">
                    <!-- v3.7 added @calendar (xs:string) -->
                    <dateOther calendar="islamic">
                        <xsl:value-of select="$v_imprint/tei:date[@calendar = '#cal_islamic']/@when-custom"/>
                    </dateOther>
                    <!-- this still needs work -->
                    <dateOther>
                        <xsl:value-of select="$v_imprint/tei:date[@calendar = '#cal_islamic']/@when-custom"/>
                        <!-- provide Gregorian dates in brackets behind the Islamic date -->
                        <xsl:text> [</xsl:text>
                        <xsl:choose>
                            <xsl:when test="$v_imprint/tei:date[@calendar = '#cal_islamic'][@when-custom]/@when">
                                <xsl:value-of select="$v_imprint/tei:date[@calendar = '#cal_islamic'][@when-custom]/@when"/>
                            </xsl:when>
                            <xsl:when test="$v_imprint/tei:date[@calendar = '#cal_islamic'][@when-custom]">
                                <xsl:analyze-string regex="(\d{{4}})$|(\d{{4}}-\d{{2}}-\d{{2}})$" select="$v_imprint/tei:date[@calendar = '#cal_islamic'][@when-custom][1]/@when-custom">
                                    <xsl:matching-substring>
                                        <xsl:if test="regex-group(1)">
                                            <xsl:value-of select="oape:date-convert-islamic-year-to-gregorian(regex-group(1))"/>
                                        </xsl:if>
                                        <xsl:if test="regex-group(2)">
                                            <xsl:value-of select="oape:date-convert-calendars(regex-group(2), '#cal_islamic', '#cal_gregorian')"/>
                                        </xsl:if>
                                    </xsl:matching-substring>
                                    <xsl:non-matching-substring>
                                        <xsl:value-of select="$v_imprint/tei:date[@calendar = '#cal_islamic']/@when-custom"/>
                                    </xsl:non-matching-substring>
                                </xsl:analyze-string>
                            </xsl:when>
                        </xsl:choose>
                        <xsl:text>]</xsl:text>
                    </dateOther>
                </xsl:if>
                <!-- add julian dates -->
                <xsl:if test="$v_imprint/tei:date/@calendar = '#cal_julian'">
                    <!-- v3.7 added @calendar (xs:string) -->
                    <dateOther calendar="julian">
                        <xsl:value-of select="$v_imprint/tei:date[@calendar = '#cal_julian']/@when-custom"/>
                    </dateOther>
                    <!-- this still needs work -->
                    <dateOther>
                        <xsl:value-of select="$v_imprint/tei:date[@calendar = '#cal_julian']/@when-custom"/>
                        <!-- add regularised Gregorian date -->
                        <xsl:text> [</xsl:text>
                        <xsl:choose>
                            <!-- test if Gregorian date is already available in the source -->
                            <xsl:when test="$v_imprint/tei:date[@calendar = '#cal_julian'][@when-custom]/@when">
                                <xsl:value-of select="$v_imprint/tei:date[@calendar = '#cal_julian'][@when-custom]/@when"/>
                            </xsl:when>
                            <!-- generate normalised date -->
                            <xsl:when test="$v_imprint/tei:date[@calendar = '#cal_julian'][@when-custom]">
                                <xsl:analyze-string regex="(\d{{4}})$|(\d{{4}}-\d{{2}}-\d{{2}})$" select="$v_imprint/tei:date[@calendar = '#cal_julian'][@when-custom]/@when-custom">
                                    <xsl:matching-substring>
                                        <xsl:if test="regex-group(1)">
                                            <xsl:value-of select="regex-group(1)"/>
                                        </xsl:if>
                                        <xsl:if test="regex-group(2)">
                                            <xsl:value-of select="oape:date-convert-calendars(regex-group(2), '#cal_julian', '#cal_gregorian')"/>
                                        </xsl:if>
                                    </xsl:matching-substring>
                                    <xsl:non-matching-substring>
                                        <xsl:value-of select="$v_imprint/tei:date[@calendar = '#cal_julian']/@when-custom"/>
                                    </xsl:non-matching-substring>
                                </xsl:analyze-string>
                            </xsl:when>
                        </xsl:choose>
                        <xsl:text>]</xsl:text>
                    </dateOther>
                </xsl:if>
                <!-- add mali dates -->
                <xsl:if test="$v_imprint/tei:date/@calendar = '#cal_ottomanfiscal'">
                    <!-- v3.7 added @calendar (xs:string) -->
                    <dateOther calendar="ottoman-fiscal">
                        <xsl:value-of select="$v_imprint/tei:date[@calendar = '#cal_ottomanfiscal']/@when-custom"/>
                    </dateOther>
                    <!-- this still needs work -->
                    <dateOther>
                        <xsl:value-of select="$v_imprint/tei:date[@calendar = '#cal_ottomanfiscal']/@when-custom"/>
                        <!-- add regularised Gregorian date -->
                        <xsl:text> [</xsl:text>
                        <xsl:choose>
                            <!-- test if Gregorian date is already available in the source -->
                            <xsl:when test="$v_imprint/tei:date[@calendar = '#cal_ottomanfiscal'][@when-custom]/@when">
                                <xsl:value-of select="$v_imprint/tei:date[@calendar = '#cal_ottomanfiscal'][@when-custom]/@when"/>
                            </xsl:when>
                            <!-- generate normalised date -->
                            <xsl:when test="$v_imprint/tei:date[@calendar = '#cal_ottomanfiscal'][@when-custom]">
                                <xsl:analyze-string regex="(\d{{4}})$|(\d{{4}}-\d{{2}}-\d{{2}})$" select="$v_imprint/tei:date[@calendar = '#cal_ottomanfiscal'][@when-custom]/@when-custom">
                                    <xsl:matching-substring>
                                        <xsl:if test="regex-group(1)">
                                            <xsl:value-of select="oape:date-convert-ottoman-fiscal-year-to-gregorian(regex-group(1))"/>
                                        </xsl:if>
                                        <xsl:if test="regex-group(2)">
                                            <xsl:value-of select="oape:date-convert-calendars(regex-group(2), '#cal_ottomanfiscal', '#cal_gregorian')"/>
                                        </xsl:if>
                                    </xsl:matching-substring>
                                    <xsl:non-matching-substring>
                                        <xsl:value-of select="$v_imprint/tei:date[@calendar = '#cal_julian']/@when-custom"/>
                                    </xsl:non-matching-substring>
                                </xsl:analyze-string>
                            </xsl:when>
                        </xsl:choose>
                        <xsl:text>]</xsl:text>
                    </dateOther>
                </xsl:if>
                <issuance>
                    <xsl:choose>
                        <xsl:when test="$v_monogr/tei:title[@level = 'm']">
                            <xsl:text>monographic</xsl:text>
                        </xsl:when>
                        <xsl:when test="$v_analytic/tei:title[@level = 'a'] | $v_monogr/tei:title[@level = 'j']">
                            <xsl:text>continuing</xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </issuance>
            </originInfo>
        </xsl:variable>
        <xsl:variable name="v_part">
            <part>
                <xsl:apply-templates mode="m_tei-to-mods" select="$v_monogr/tei:biblScope"/>
            </part>
        </xsl:variable>
        <xsl:variable name="v_editor">
            <!-- pull in information on editor -->
            <!--            <xsl:apply-templates mode="m_tei-to-mods" select="$v_monogr/tei:editor/tei:persName[@xml:lang = $p_lang]"/>-->
            <xsl:apply-templates mode="m_tei-to-mods" select="$v_monogr/tei:editor"/>
        </xsl:variable>
        <!-- construct output -->
        <mods>
            <!-- what is this ID? -->
            <!-- The variable is declared in parameters.xsl, which is always loaded together with the current XSLT -->
            <xsl:if test="$v_id-file != '' and $v_biblStruct/tei:biblStruct/@xml:id != ''">
                <xsl:attribute name="ID">
                    <xsl:value-of select="concat($v_id-file, '-', $v_biblStruct/tei:biblStruct/@xml:id, '-mods')"/>
                </xsl:attribute>
            </xsl:if>
            <titleInfo>
                <xsl:choose>
                    <!-- test for analytical titles in target language -->
                    <xsl:when test="$v_analytic/tei:title[@level = 'a'][@xml:lang = $p_lang]">
                        <xsl:apply-templates mode="m_tei-to-mods" select="$v_analytic/tei:title[@level = 'a'][@xml:lang = $p_lang]"/>
                    </xsl:when>
                    <!-- test for analytical titles in any language -->
                    <xsl:when test="$v_analytic/tei:title[@level = 'a']">
                        <xsl:apply-templates mode="m_tei-to-mods" select="$v_analytic/tei:title[@level = 'a']"/>
                    </xsl:when>
                    <!-- test for other titles in target language -->
                    <xsl:when test="$v_biblStruct/descendant::tei:title[not(@level = 'a')][@xml:lang = $p_lang]">
                        <xsl:apply-templates mode="m_tei-to-mods" select="$v_biblStruct/descendant::tei:title[@xml:lang = $p_lang][not(@level = 'a')]"/>
                    </xsl:when>
                    <!-- fall back: other title in any language -->
                    <xsl:otherwise>
                        <xsl:apply-templates mode="m_tei-to-mods" select="$v_biblStruct/descendant::tei:title[not(@level = 'a')]"/>
                    </xsl:otherwise>
                </xsl:choose>
            </titleInfo>
            <!--<mods:titleInfo>
                <mods:title type="abbreviated">
                    <xsl:value-of select="$vShortTitle"/>
                </mods:title>
            </mods:titleInfo>-->
            <typeOfResource>
                <xsl:text>text</xsl:text>
            </typeOfResource>
            <xsl:choose>
                <xsl:when test="$v_analytic/tei:title[@level = 'a'] and $v_biblStruct/tei:biblStruct/tei:note[@type = 'tagList']/tei:list[@type = 'category']/tei:item[matches(text(), 'vortrag', 'i')]">
                    <genre authority="local" xml:lang="en">presentation</genre>
                    <!--                    <genre authority="marcgt" xml:lang="en">article</genre>-->
                </xsl:when>
                <xsl:when test="$v_analytic/tei:title[@level = 'a'] and $v_monogr/tei:title[@level = 'j']">
                    <genre authority="local" xml:lang="en">journalArticle</genre>
                    <genre authority="marcgt" xml:lang="en">article</genre>
                </xsl:when>
                <xsl:when test="$v_analytic/tei:title[@level = 'a'] and $v_monogr/tei:title[@level = 'm']">
                    <genre authority="local" xml:lang="en">bookSection</genre>
                </xsl:when>
                <!-- fallback to journal article -->
                <xsl:when test="$v_analytic/tei:title[@level = 'a']">
                    <genre authority="local" xml:lang="en">journalArticle</genre>
                    <genre authority="marcgt" xml:lang="en">article</genre>
                </xsl:when>
                <xsl:when test="$v_monogr/tei:title[@level = 'm']">
                    <genre authority="local">book</genre>
                    <genre authority="marcgt">book</genre>
                </xsl:when>
                <xsl:when test="$v_monogr/tei:title[@level = 'j']">
                    <genre authority="local">periodical</genre>
                    <genre authority="marcgt">periodical</genre>
                </xsl:when>
            </xsl:choose>
            <!-- for each author -->
            <xsl:apply-templates mode="m_tei-to-mods" select="$v_biblStruct/descendant::tei:author"/>
            <xsl:apply-templates mode="m_tei-to-mods" select="$v_biblStruct/descendant::tei:respStmt[descendant::tei:persName]"/>
            <xsl:choose>
                <xsl:when test="$v_analytic/tei:title[@level = 'a']">
                    <relatedItem type="host">
                        <titleInfo>
                            <xsl:choose>
                                <!-- test for monogr titles in target language -->
                                <xsl:when test="$v_monogr/tei:title[@xml:lang = $p_lang]">
                                    <xsl:apply-templates mode="m_tei-to-mods" select="$v_monogr/tei:title[@xml:lang = $p_lang]"/>
                                </xsl:when>
                                <!-- fallback: monogr titles in any language -->
                                <xsl:otherwise>
                                    <xsl:apply-templates mode="m_tei-to-mods" select="$v_monogr/tei:title"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </titleInfo>
                        <genre authority="marcgt">
                            <xsl:choose>
                                <xsl:when test="$v_monogr/tei:title[@level = 'j']">
                                    <xsl:text>journal</xsl:text>
                                </xsl:when>
                                <xsl:when test="$v_monogr/tei:title[@level = 'm']">
                                    <xsl:text>book</xsl:text>
                                </xsl:when>
                            </xsl:choose>
                        </genre>
                        <xsl:copy-of select="$v_editor"/>
                        <xsl:copy-of select="$v_originInfo"/>
                        <xsl:copy-of select="$v_part"/>
                        <!-- IDs: but not URL -->
                        <xsl:apply-templates mode="m_tei-to-mods" select="$v_monogr/tei:idno[not(@type = 'url')]"/>
                    </relatedItem>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="$v_editor"/>
                    <xsl:copy-of select="$v_originInfo"/>
                    <xsl:copy-of select="$v_part"/>
                    <!-- IDs -->
                    <xsl:apply-templates mode="m_tei-to-mods" select="$v_biblStruct/descendant::tei:idno[not(ancestor::tei:note)]"/>
                </xsl:otherwise>
            </xsl:choose>
            <!-- availability / license -->
            <xsl:choose>
                <xsl:when test="$v_biblStruct/descendant::tei:availability">
                    <xsl:apply-templates mode="m_tei-to-mods" select="$v_biblStruct/descendant::tei:availability"/>
                </xsl:when>
                <xsl:when test="$p_add-license">
                    <accessCondition>
                        <xsl:attribute name="valueURI" select="$v_license-url"/>
                        <xsl:value-of select="$v_license"/>
                    </accessCondition>
                </xsl:when>
            </xsl:choose>
            <!-- IDs -->
            <xsl:apply-templates mode="m_tei-to-mods" select="$v_analytic/tei:idno[not(@type = 'url')][not(@type = 'URI')]"/>
            <!-- URLs -->
            <!-- MODS allows for more than one URL! -->
            <xsl:apply-templates mode="m_tei-to-mods" select="$v_biblStruct/descendant::tei:idno[@type = ('url', 'URI')][not(ancestor::tei:note)]"/>
            <!-- if no URL provided, use the local URL of the input file -->
            <xsl:if test="not($v_biblStruct/descendant::tei:idno[@type = ('url', 'URI')][not(ancestor::tei:note)])">
                <xsl:message>
                    <xsl:text>TEI contains no URL, using local path instead</xsl:text>
                </xsl:message>
                <location>
                    <url>
                        <xsl:attribute name="dateLastAccessed" select="$p_today-iso"/>
                        <xsl:value-of select="concat($v_file-name_input, '.xml')"/>
                    </url>
                </location>
            </xsl:if>
            <!--<url dateLastAccessed="{$p_date-accessed}" usage="primary display">-->
            <!-- language information -->
            <xsl:choose>
                <xsl:when test="$v_biblStruct/descendant::tei:textLang">
                    <xsl:apply-templates mode="m_tei-to-mods" select="$v_biblStruct/descendant::tei:textLang"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- why did I decide to create a textLang element from a parameter? -->
                    <!-- <xsl:variable name="v_lang">
                        <tei:textLang>
                            <xsl:attribute name="mainLang" select="$p_lang"/>
                            <xsl:value-of select="$p_lang"/>
                        </tei:textLang>
                    </xsl:variable>
                    <xsl:apply-templates mode="m_tei-to-mods" select="$v_lang/tei:textLang"/>--> </xsl:otherwise>
            </xsl:choose>
            <!-- notes, tags etc. -->
            <xsl:apply-templates mode="m_tei-to-mods" select="$v_biblStruct/tei:biblStruct//tei:note"/>
        </mods>
    </xsl:function>
    <!-- transform TEI names to MODS -->
    <xsl:template match="tei:persName" mode="m_tei-to-mods">
        <xsl:choose>
            <xsl:when test="$p_mods-simple-persnames = true()">
                <!-- For many applications, it makes sense to provide one simple string -->
                <namePart>
                    <xsl:variable name="v_plain">
                        <xsl:choose>
                            <!-- account for ZfDG's weird nesting of another <name> element inside <persName -->
                            <xsl:when test="descendant::tei:surname">
                                <xsl:apply-templates mode="m_plain-text" select="descendant::tei:forename"/>
                                <xsl:text> </xsl:text>
                                <xsl:apply-templates mode="m_plain-text" select="descendant::tei:surname"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates mode="m_plain-text" select="."/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:value-of select="normalize-space($v_plain)"/>
                </namePart>
            </xsl:when>
            <!-- account for ZfDG's weird nesting of another <name> element inside <persName -->
            <xsl:when test="descendant::tei:surname">
                <xsl:apply-templates mode="m_tei-to-mods" select="descendant::tei:surname"/>
                <xsl:apply-templates mode="m_tei-to-mods" select="descendant::tei:forename"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- what should happen if there is neither surname nor forename? -->
                <!-- there should still be a wrapper node -->
                <namePart>
                    <xsl:variable name="v_plain">
                        <xsl:apply-templates mode="m_plain-text" select="."/>
                    </xsl:variable>
                    <xsl:value-of select="normalize-space($v_plain)"/>
                </namePart>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tei:surname" mode="m_tei-to-mods">
        <namePart type="family">
            <xsl:copy-of select="oape:get-xml-lang(.)"/>
            <xsl:variable name="v_plain">
                <xsl:apply-templates mode="m_plain-text" select="."/>
            </xsl:variable>
            <xsl:value-of select="normalize-space($v_plain)"/>
        </namePart>
    </xsl:template>
    <xsl:template match="tei:forename" mode="m_tei-to-mods">
        <namePart type="given">
            <xsl:copy-of select="oape:get-xml-lang(.)"/>
            <xsl:variable name="v_plain">
                <xsl:apply-templates mode="m_plain-text" select="."/>
            </xsl:variable>
            <xsl:value-of select="normalize-space($v_plain)"/>
        </namePart>
    </xsl:template>
    <!--    <xsl:template match="tei:persName" mode="m_tei-to-mods">
        <xsl:param name="p_lang"/>
        <namePart type="family" xml:lang="{$p_lang}">
            <xsl:value-of select="."/>
        </namePart>
    </xsl:template>-->
    <xsl:template match="tei:publisher | tei:publisher/tei:orgName | tei:publisher/tei:persName" mode="m_tei-to-mods">
        <!-- tei:publisher can have a variety of child nodes, which are completely ignored by this template -->
        <publisher>
            <xsl:copy-of select="oape:get-xml-lang(.)"/>
            <xsl:variable name="v_plain">
                <xsl:apply-templates mode="m_plain-text" select="."/>
            </xsl:variable>
            <xsl:value-of select="normalize-space($v_plain)"/>
        </publisher>
    </xsl:template>
    <!--<xsl:template match="tei:pubPlace" mode="m_tei-to-mods">
        <place>
            <xsl:apply-templates mode="m_tei-to-mods"/>
        </place>
    </xsl:template>-->
    <xsl:template match="tei:placeName" mode="m_tei-to-mods">
        <placeTerm type="text">
            <xsl:copy-of select="oape:get-xml-lang(.)"/>
            <!-- add references to authority files  -->
            <xsl:apply-templates mode="m_authority" select="."/>
            <xsl:variable name="v_plain">
                <xsl:apply-templates mode="m_plain-text" select="."/>
            </xsl:variable>
            <xsl:value-of select="normalize-space($v_plain)"/>
        </placeTerm>
    </xsl:template>
    <xsl:template match="tei:persName | tei:orgName | tei:editor | tei:author | tei:placeName" mode="m_authority">
        <xsl:if test="@ref != ''">
            <xsl:choose>
                <!-- note that MODS seemingly supports only one authority file -->
                <xsl:when test="matches(@ref, 'viaf:\d+')">
                    <!-- @authority is a controlled list with the values: marcgac, marccountry, iso3166 -->
                    <!--                        <xsl:attribute name="authority" select="'viaf'"/>-->
                    <!-- it is arguably better to directly dereference VIAF IDs -->
                    <xsl:attribute name="valueURI" select="replace(@ref, '.*viaf:(\d+).*', 'https://viaf.org/viaf/$1')"/>
                </xsl:when>
                <xsl:when test="matches(@ref, 'geon:\d+')">
                    <!--                        <xsl:attribute name="authority" select="'geonames'"/>-->
                    <xsl:attribute name="valueURI" select="replace(@ref, '.*geon:(\d+).*', 'https://www.geonames.org/$1')"/>
                </xsl:when>
                <xsl:when test="matches(@ref, 'wiki:Q\d+')">
                    <xsl:attribute name="valueURI" select="replace(@ref, '.*wiki:(Q\d+).*', 'https://www.wikidata.org/wiki/$1')"/>
                </xsl:when>
                <xsl:when test="matches(@ref, 'oape:pers:\d+')">
                    <!--                        <xsl:attribute name="authority" select="'oape'"/>-->
                    <!-- OpenArabicPE IDs do not resolve -->
                    <xsl:attribute name="valueURI" select="replace(@ref, '.*(oape:pers:\d+).*', '$1')"/>
                </xsl:when>
                <xsl:when test="matches(@ref, 'oape:place:\d+')">
                    <!--                        <xsl:attribute name="authority" select="'oape'"/>-->
                    <!-- OpenArabicPE IDs do not resolve -->
                    <xsl:attribute name="valueURI" select="replace(@ref, '.*(oape:place:\d+).*', '$1')"/>
                </xsl:when>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    <!-- IDs -->
    <xsl:template match="tei:idno" mode="m_tei-to-mods">
        <xsl:variable name="v_name">
            <xsl:choose>
                <xsl:when test="parent::tei:author | parent::tei:editor | parent::tei:persName">
                    <xsl:text>nameIdentifier</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>identifier</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:element name="{$v_name}">
            <!-- according to https://www.loc.gov/standards/sourcelist/standard-identifier.html identifiers are in lower case -->
            <xsl:attribute name="type" select="lower-case(@type)">
                <!-- <xsl:choose>
                    <xsl:when test="@type = ('doi', 'gnd', 'orcid')">
                        <xsl:value-of select="upper-case(@type)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="@type"/>
                    </xsl:otherwise>
                </xsl:choose>--> </xsl:attribute>
            <xsl:variable name="v_plain">
                <xsl:apply-templates mode="m_plain-text" select="."/>
            </xsl:variable>
            <xsl:value-of select="normalize-space($v_plain)"/>
        </xsl:element>
    </xsl:template>
    <!--<xsl:template match="tei:idno[parent::tei:author or parent::tei:editor]" mode="m_tei-to-mods">
        <nameIdentifier type="{@type}">
            <xsl:variable name="v_plain">
                <xsl:apply-templates mode="m_plain-text" select="."/>
            </xsl:variable>
            <xsl:value-of select="normalize-space($v_plain)"/>
        </nameIdentifier>
    </xsl:template>-->
    <xsl:template match="tei:idno[@type = 'classmark'][ancestor::tei:note[@type = 'holdings']]" mode="m_tei-to-mods">
        <location>
            <!-- the actual location of the physical copy -->
            <physicalLocation>
                <xsl:choose>
                    <xsl:when test="ancestor::tei:item[1]/tei:label/tei:orgName">
                        <xsl:variable name="v_org" select="ancestor::tei:item[1]/tei:label/tei:orgName"/>
                        <xsl:choose>
                            <xsl:when test="matches($v_org/@ref, 'isil:')">
                                <xsl:attribute name="authority" select="'isil'"/>
                                <xsl:value-of select="replace($v_org/@ref, '^.*isil:([^\s]+).*$', '$1')"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates mode="m_plain-text" select="$v_org"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="@source">
                        <xsl:apply-templates mode="m_plain-text" select="@source"/>
                    </xsl:when>
                </xsl:choose>
            </physicalLocation>
            <shelfLocator>
                <xsl:apply-templates mode="m_plain-text" select="text()"/>
            </shelfLocator>
            <!-- url for this resource -->
            <url>
                <xsl:choose>
                    <xsl:when test="@source = 'hathi'">
                        <xsl:value-of select="concat('https://hdl.handle.net/2027/', .)"/>
                    </xsl:when>
                </xsl:choose>
            </url>
        </location>
    </xsl:template>
    <xsl:template match="tei:idno[@type = ('url', 'URI')]" mode="m_tei-to-mods">
        <location>
            <url>
                <!-- add @usage at least for our own URLs -->
                <xsl:if test="matches(., 'http.+openarabicpe')">
                    <xsl:attribute name="usage">
                        <xsl:choose>
                            <xsl:when test="matches(., 'github.com')">
                                <xsl:value-of select="'primary'"/>
                            </xsl:when>
                            <xsl:when test="matches(., 'github.io')">
                                <xsl:value-of select="'primary display'"/>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:attribute>
                    <xsl:attribute name="dateLastAccessed" select="$p_today-iso"/>
                </xsl:if>
                <xsl:value-of select="."/>
            </url>
        </location>
    </xsl:template>
    <!-- this is invalid encoding according to the specs, even though Zotero handles it this way -->
    <!--<xsl:template match="tei:idno[@type = 'classmark']" mode="m_tei-to-mods">
        <classification>
            <xsl:apply-templates mode="m_plain-text" select="text()"/>
        </classification>
    </xsl:template>-->
    <!--<xsl:template match="tei:idno[@type = ('url', 'URI')]" mode="m_tei-to-mods">
        <location>
            <url usage="primary display">
                <xsl:apply-templates mode="m_plain-text" select="text()"/>
            </url>
            <xsl:apply-templates mode="m_tei-to-mods" select="following-sibling::tei:idno[@type = ('url', 'URI')]"/>
        </location>
    </xsl:template>
    <xsl:template match="tei:idno[@type = ('url', 'URI')][preceding-sibling::tei:idno[@type = ('url', 'URI')]]" mode="m_tei-to-mods">
        <url usage="primary display">
            <xsl:apply-templates mode="m_plain-text" select="text()"/>
        </url>
    </xsl:template>-->
    <!-- dates -->
    <xsl:template match="tei:date" mode="m_tei-to-mods">
        <dateIssued>
            <xsl:choose>
                <xsl:when test="@when != ''">
                    <xsl:attribute name="encoding" select="'w3cdtf'"/>
                    <xsl:value-of select="@when"/>
                </xsl:when>
                <xsl:when test="@from">
                    <xsl:attribute name="encoding" select="'w3cdtf'"/>
                    <xsl:value-of select="@from"/>
                </xsl:when>
            </xsl:choose>
        </dateIssued>
    </xsl:template>
    <!-- source languages -->
    <xsl:template match="tei:textLang" mode="m_tei-to-mods">
        <language>
            <languageTerm authorityURI="http://www.iana.org/assignments/language-subtag-registry/language-subtag-registry" type="code">
                <xsl:value-of select="@mainLang"/>
            </languageTerm>
        </language>
    </xsl:template>
    <!-- titles -->
    <xsl:template match="tei:title" mode="m_tei-to-mods">
        <xsl:choose>
            <xsl:when test="@type = 'sub'">
                <subTitle>
                    <xsl:copy-of select="oape:get-xml-lang(.)"/>
                    <xsl:variable name="v_plain">
                        <xsl:apply-templates mode="m_plain-text" select="."/>
                    </xsl:variable>
                    <xsl:value-of select="normalize-space($v_plain)"/>
                </subTitle>
            </xsl:when>
            <xsl:otherwise>
                <title>
                    <xsl:copy-of select="oape:get-xml-lang(.)"/>
                    <xsl:variable name="v_plain">
                        <xsl:apply-templates mode="m_plain-text" select="."/>
                    </xsl:variable>
                    <xsl:value-of select="normalize-space($v_plain)"/>
                </title>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- volume, issue, pages -->
    <xsl:template match="tei:biblScope[@unit = ('volume', 'issue')]" mode="m_tei-to-mods">
        <detail type="{@unit}">
            <number>
                <xsl:choose>
                    <!-- check for correct encoding of volume information -->
                    <xsl:when test="@from = @to">
                        <xsl:value-of select="@from"/>
                    </xsl:when>
                    <!-- check for ranges -->
                    <xsl:when test="@from != @to">
                        <xsl:value-of select="@from"/>
                        <!-- probably an en-dash is the better option here -->
                        <xsl:text>/</xsl:text>
                        <xsl:value-of select="@to"/>
                    </xsl:when>
                    <!-- fallback: erroneous encoding of volume information with @n -->
                    <xsl:when test="@n">
                        <xsl:value-of select="@n"/>
                    </xsl:when>
                    <!-- fallback: no information in attributes -->
                    <xsl:otherwise>
                        <xsl:value-of select="."/>
                    </xsl:otherwise>
                </xsl:choose>
            </number>
        </detail>
    </xsl:template>
    <xsl:template match="tei:biblScope[@unit = ('page')]" mode="m_tei-to-mods">
        <extent unit="pages">
            <start>
                <xsl:value-of select="@from"/>
            </start>
            <end>
                <xsl:value-of select="@to"/>
            </end>
        </extent>
    </xsl:template>
    <!-- remove output for unsupported units etc. -->
    <xsl:template match="tei:biblScope" mode="m_tei-to-mods"/>
    <!-- contributors -->
    <xsl:template match="tei:editor | tei:author | tei:respStmt[descendant::tei:persName]" mode="m_tei-to-mods" priority="10">
        <name type="personal">
            <!--<xsl:copy-of select="oape:get-xml-lang(.)"/>-->
            <!-- add references to authority files -->
            <xsl:choose>
                <xsl:when test="matches(@ref, 'viaf:\d+')">
                    <xsl:apply-templates mode="m_authority" select="."/>
                </xsl:when>
                <xsl:when test="tei:persName[@ref]">
                    <xsl:apply-templates mode="m_authority" select="tei:persName[@ref][1]"/>
                </xsl:when>
            </xsl:choose>
            <!-- sometimes the contents are not wrapped in persName -->
            <xsl:choose>
                <xsl:when test="tei:persName">
                    <xsl:apply-templates mode="m_tei-to-mods" select="tei:persName"/>
                </xsl:when>
                <xsl:when test="tei:name">
                    <xsl:apply-templates mode="m_tei-to-mods" select="tei:name"/>
                </xsl:when>
                <!-- tag abuse from ZfDG -->
                <xsl:when test="tei:resp/tei:persName">
                    <xsl:apply-templates mode="m_tei-to-mods" select="tei:resp/tei:persName"/>
                </xsl:when>
                <xsl:otherwise>
                    <namePart>
                        <xsl:variable name="v_plain">
                            <xsl:apply-templates mode="m_plain-text" select="."/>
                        </xsl:variable>
                        <xsl:value-of select="normalize-space($v_plain)"/>
                    </namePart>
                </xsl:otherwise>
            </xsl:choose>
            <!-- affiliations, IDs -->
            <xsl:apply-templates mode="m_tei-to-mods" select="tei:idno"/>
            <xsl:apply-templates mode="m_tei-to-mods" select="tei:affiliation"/>
            <!-- tag abuse from ZfDG -->
            <xsl:apply-templates mode="m_tei-to-mods" select="tei:orgName"/>
            <xsl:apply-templates mode="m_tei-to-mods" select="tei:persName/tei:idno | tei:resp/tei:persName/tei:idno"/>
            <xsl:apply-templates mode="m_tei-to-mods" select="tei:persName/tei:affiliation | tei:resp/tei:persName/tei:affiliation"/>
            <role>
                <roleTerm authority="marcrelator" type="code">
                    <xsl:choose>
                        <xsl:when test="local-name() = 'editor'">
                            <xsl:text>edt</xsl:text>
                        </xsl:when>
                        <xsl:when test="local-name() = 'author'">
                            <xsl:text>aut</xsl:text>
                        </xsl:when>
                        <!--<xsl:when test="tei:resp/@ref[matches(., 'https*://id.loc.gov/vocabulary/relators')]">
                            <xsl:value-of select="replace(tei:resp/@ref, '^https*://id.loc.gov/vocabulary/relators/', '')"/>
                        </xsl:when>-->
                    </xsl:choose>
                </roleTerm>
            </role>
            <xsl:apply-templates mode="m_tei-to-mods" select="tei:resp"/>
        </name>
    </xsl:template>
    <xsl:template match="tei:resp" mode="m_tei-to-mods">
        <role>
            <xsl:choose>
                <xsl:when test="@ref[matches(., 'https*://id.loc.gov/vocabulary/relators')]">
                    <roleTerm authority="marcrelator" type="code">
                        <xsl:value-of select="replace(@ref, '^https*://id.loc.gov/vocabulary/relators/', '')"/>
                    </roleTerm>
                </xsl:when>
                <xsl:when test="@ref[matches(., 'credit.niso.org/contributor-roles/')]">
                    <roleTerm authority="https://credit.niso.org/contributor-roles/">
                        <xsl:attribute name="type" select="replace(@ref, '^https*://credit.niso.org/contributor-roles/', '')"/>
                        <xsl:value-of select="replace(@ref, '^https*://credit.niso.org/contributor-roles/', '')"/>
                    </roleTerm>
                </xsl:when>
            </xsl:choose>
        </role>
    </xsl:template>
    <xsl:template match="tei:availability" mode="m_tei-to-mods">
        <accessCondition>
            <xsl:choose>
                <xsl:when test="cc:License/@rdf:about">
                    <xsl:attribute name="valueURI" select="cc:License/@rdf:about"/>
                </xsl:when>
            </xsl:choose>
        </accessCondition>
    </xsl:template>
    <xsl:template match="tei:affiliation | tei:respStmt/tei:orgName" mode="m_tei-to-mods">
        <affiliation>
            <xsl:copy-of select="oape:get-xml-lang(.)"/>
            <xsl:variable name="v_plain">
                <xsl:apply-templates mode="m_plain-text" select="."/>
            </xsl:variable>
            <xsl:value-of select="normalize-space($v_plain)"/>
        </affiliation>
    </xsl:template>
    <!-- notes -->
    <!-- supressed -->
    <xsl:template match="tei:note" mode="m_tei-to-mods"/>
    <!-- supported -->
    <xsl:template match="tei:note[@type = 'tagList']" mode="m_tei-to-mods">
        <xsl:for-each select="tei:list">
            <subject>
                <xsl:attribute name="authority" select="@source"/>
                <xsl:apply-templates mode="m_tei-to-mods" select="tei:item"/>
            </subject>
        </xsl:for-each>
    </xsl:template>
    <xsl:template match="tei:item[ancestor::tei:note[@type = 'tagList']]" mode="m_tei-to-mods">
        <xsl:choose>
            <xsl:when test="@n = 'topics'">
                <topic>
                    <xsl:value-of select="tei:label"/>
                </topic>
            </xsl:when>
            <xsl:when test="@n = ('category', 'subcategory')">
                <!-- values specific to DHConvalidator -->
                <genre>
                    <xsl:value-of select="tei:label"/>
                </genre>
            </xsl:when>
            <xsl:otherwise>
                <topic>
                    <xsl:if test="@source">
                        <xsl:attribute name="authority" select="@source"/>
                    </xsl:if>
                    <xsl:if test="tei:idno">
                        <xsl:attribute name="valueURI">
                            <xsl:if test="tei:idno/@type = 'gnd'">
                                <xsl:value-of select="concat($v_url-gnd-resolve, tei:idno)"/>
                            </xsl:if>
                        </xsl:attribute>
                    </xsl:if>
                    <xsl:value-of select="tei:label"/>
                </topic>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
