<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:mods="http://www.loc.gov/mods/v3" 
    xmlns="http://www.loc.gov/mods/v3"  
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:oape="https://openarabicpe.github.io/ns"
    xpath-default-namespace="http://www.loc.gov/mods/v3"
    exclude-result-prefixes="#all"
    version="3.0">
    <xsl:output method="xml" encoding="UTF-8" indent="yes" omit-xml-declaration="no" version="1.0"/>
<!-- this stylesheet translates <tei:biblStruct>s to  <mods:mods> -->
    
    <!-- date conversion functions -->
    <xsl:include href="https://tillgrallert.github.io/xslt-calendar-conversion/functions/date-functions.xsl"/>
    <!-- <xsl:include href="../../../xslt-calendar-conversion/date-functions.xsl"/> -->

    <xsl:variable name="vgFileId" select="substring-before(tokenize(base-uri(),'/')[last()],'.TEIP5')"/>
    <!-- this needs to be adopted to work with any periodical and not just al-Muqtabas -->
    <xsl:variable name="v_schema" select="'http://www.loc.gov/standards/mods/mods-3-7.xsd'"/>

    <!-- the MODS output -->
    <xsl:function name="oape:bibliography-tei-to-mods">
        <!-- input is a bibl or biblStruct -->
        <xsl:param name="p_input"/>
        <!-- output language -->
        <xsl:param name="p_lang"/>
        <!-- missing bits: absent from biblStruct
            - licence
            - date last accessed
            - edition
        -->
        <!-- variables -->
        <xsl:variable name="v_originInfo">
            <originInfo>
                <!-- information on the edition: it would be weird to mix data of the original source and the digital edition -->
                <!--<edition xml:lang="en">
                    <xsl:variable name="v_plain">
                        <xsl:apply-templates select="$p_edition" mode="m_plain-text"/>
                    </xsl:variable>
                    <xsl:value-of select="normalize-space($v_plain)"/>
                </edition>-->
                <place>
                    <xsl:apply-templates select="$p_input/descendant::tei:pubPlace/tei:placeName[@xml:lang = $p_lang]" mode="m_tei-to-mods"/>
                </place>
                <xsl:apply-templates select="$p_input/descendant::tei:publisher" mode="m_tei-to-mods"/>
                <dateIssued>
                    <xsl:if test="$p_input/descendant::tei:date/@when!=''">
                        <xsl:attribute name="encoding" select="'w3cdtf'"/>
                        <xsl:value-of select="$p_input/descendant::tei:date[@when][1]/@when"/>
                    </xsl:if>
                </dateIssued>
                <!-- add hijri dates -->
                <xsl:if test="$p_input/descendant::tei:date/@calendar='#cal_islamic'">
                    <!-- v3.7 added @calendar (xs:string) -->
                    <dateOther calendar="islamic">
                        <xsl:value-of select="$p_input/descendant::tei:date[@calendar = '#cal_islamic']/@when-custom"/>
                    </dateOther>
                    <!-- this still needs work -->
                    <dateOther>
                        <xsl:value-of select="$p_input/descendant::tei:date[@calendar = '#cal_islamic']/@when-custom"/>
                        <!-- provide Gregorian dates in brackets behind the Islamic date -->
                        <xsl:text> [</xsl:text>
                        <xsl:choose>
                            <xsl:when test="$p_input/descendant::tei:date[@calendar = '#cal_islamic'][@when-custom]/@when">
                                <xsl:value-of select="$p_input/descendant::tei:date[@calendar = '#cal_islamic'][@when-custom]/@when"/>
                            </xsl:when>
                            <xsl:when test="$p_input/descendant::tei:date[@calendar = '#cal_islamic'][@when-custom]">
                                <xsl:analyze-string select="$p_input/descendant::tei:date[@calendar = '#cal_islamic'][@when-custom]/@when-custom" regex="(\d{{4}})$|(\d{{4}}-\d{{2}}-\d{{2}})$">
                                    <xsl:matching-substring>
                                        <xsl:if test="regex-group(1)">
                                             <xsl:value-of select="oape:date-convert-islamic-year-to-gregorian(regex-group(1))"/>
                                        </xsl:if>
                                        <xsl:if test="regex-group(2)">
                                            <xsl:value-of select="oape:date-convert-calendars(regex-group(2), '#cal_islamic', '#cal_gregorian')"/>
                                        </xsl:if>
                                    </xsl:matching-substring>
                                    <xsl:non-matching-substring>
                                        <xsl:value-of select="$p_input/descendant::tei:date[@calendar = '#cal_islamic']/@when-custom"/>
                                    </xsl:non-matching-substring>
                                </xsl:analyze-string>
                            </xsl:when>
                        </xsl:choose>
                        <xsl:text>]</xsl:text>
                    </dateOther>
                </xsl:if>
                <!-- add julian dates -->
                <xsl:if test="$p_input/descendant::tei:date/@calendar='#cal_julian'">
                    <!-- v3.7 added @calendar (xs:string) -->
                    <dateOther calendar="julian">
                        <xsl:value-of select="$p_input/descendant::tei:date[@calendar = '#cal_julian']/@when-custom"/>
                    </dateOther>
                    <!-- this still needs work -->
                    <dateOther>
                        <xsl:value-of select="$p_input/descendant::tei:date[@calendar = '#cal_julian']/@when-custom"/>
                        <!-- add regularised Gregorian date -->
                        <xsl:text> [</xsl:text>
                        <xsl:choose>
                            <!-- test if Gregorian date is already available in the source -->
                            <xsl:when test="$p_input/descendant::tei:date[@calendar = '#cal_julian'][@when-custom]/@when">
                                <xsl:value-of select="$p_input/descendant::tei:date[@calendar = '#cal_julian'][@when-custom]/@when"/>
                            </xsl:when>
                            <!-- generate normalised date -->
                            <xsl:when test="$p_input/descendant::tei:date[@calendar = '#cal_julian'][@when-custom]">
                                <xsl:analyze-string select="$p_input/descendant::tei:date[@calendar = '#cal_julian'][@when-custom]/@when-custom" regex="(\d{{4}})$|(\d{{4}}-\d{{2}}-\d{{2}})$">
                                    <xsl:matching-substring>
                                        <xsl:if test="regex-group(1)">
                                            <xsl:value-of select="regex-group(1)"/>
                                        </xsl:if>
                                        <xsl:if test="regex-group(2)">
                                            <xsl:value-of select="oape:date-convert-calendars(regex-group(2), '#cal_julian', '#cal_gregorian')"/>
                                        </xsl:if>
                                    </xsl:matching-substring>
                                    <xsl:non-matching-substring>
                                        <xsl:value-of select="$p_input/descendant::tei:date[@calendar = '#cal_julian']/@when-custom"/>
                                    </xsl:non-matching-substring>
                                </xsl:analyze-string>
                            </xsl:when>
                        </xsl:choose>
                        <xsl:text>]</xsl:text>
                    </dateOther>
                </xsl:if>
                    <!-- add mali dates -->
                <xsl:if test="$p_input/descendant::tei:date/@calendar='#cal_ottomanfiscal'">
                    <!-- v3.7 added @calendar (xs:string) -->
                    <dateOther calendar="ottoman-fiscal">
                        <xsl:value-of select="$p_input/descendant::tei:date[@calendar = '#cal_ottomanfiscal']/@when-custom"/>
                    </dateOther>
                    <!-- this still needs work -->
                    <dateOther>
                        <xsl:value-of select="$p_input/descendant::tei:date[@calendar = '#cal_ottomanfiscal']/@when-custom"/>
                        <!-- add regularised Gregorian date -->
                        <xsl:text> [</xsl:text>
                        <xsl:choose>
                            <!-- test if Gregorian date is already available in the source -->
                            <xsl:when test="$p_input/descendant::tei:date[@calendar = '#cal_ottomanfiscal'][@when-custom]/@when">
                                <xsl:value-of select="$p_input/descendant::tei:date[@calendar = '#cal_ottomanfiscal'][@when-custom]/@when"/>
                            </xsl:when>
                            <!-- generate normalised date -->
                            <xsl:when test="$p_input/descendant::tei:date[@calendar = '#cal_ottomanfiscal'][@when-custom]">
                                <xsl:analyze-string select="$p_input/descendant::tei:date[@calendar = '#cal_ottomanfiscal'][@when-custom]/@when-custom" regex="(\d{{4}})$|(\d{{4}}-\d{{2}}-\d{{2}})$">
                                    <xsl:matching-substring>
                                        <xsl:if test="regex-group(1)">
                                            <xsl:value-of select="oape:date-convert-ottoman-fiscal-year-to-gregorian(regex-group(1))"/>
                                        </xsl:if>
                                        <xsl:if test="regex-group(2)">
                                            <xsl:value-of select="oape:date-convert-calendars(regex-group(2), '#cal_ottomanfiscal', '#cal_gregorian')"/>
                                        </xsl:if>
                                    </xsl:matching-substring>
                                    <xsl:non-matching-substring>
                                        <xsl:value-of select="$p_input/descendant::tei:date[@calendar = '#cal_julian']/@when-custom"/>
                                    </xsl:non-matching-substring>
                                </xsl:analyze-string>
                            </xsl:when>
                        </xsl:choose>
                        <xsl:text>]</xsl:text>
                    </dateOther>
                </xsl:if>
                <issuance>
                    <xsl:choose>
                        <xsl:when test="$p_input/descendant::tei:title[@level=('a','j')]">                        
                            <xsl:text>continuing</xsl:text>
                        </xsl:when>
                        <xsl:when test="$p_input/descendant::tei:title[@level='m']">
                            <xsl:text>monographic</xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </issuance>
            </originInfo>
        </xsl:variable>
        <xsl:variable name="v_part">
            <part>
                <xsl:apply-templates select="$p_input/descendant::tei:biblScope" mode="m_tei-to-mods"/>
            </part>
        </xsl:variable>
        <xsl:variable name="v_editor">
            <!-- pull in information on editor -->
            <xsl:apply-templates select="$p_input/descendant::tei:editor/tei:persName[@xml:lang = $p_lang]" mode="m_tei-to-mods"/>
        </xsl:variable>
        <!-- construct output -->
        <mods>
            <!-- what is this ID? -->
                <xsl:if test="$vgFileId !='' and $p_input/@xml:id !=''">
                    <xsl:attribute name="ID">
                        <xsl:value-of select="concat($vgFileId,'-',$p_input/@xml:id,'-mods')"/>
                    </xsl:attribute>
                </xsl:if>
            <titleInfo>
                    <xsl:choose>
                        <xsl:when test="$p_input/descendant::tei:title[@level='a']">
                            <xsl:apply-templates select="$p_input/descendant::tei:title[@level='a']" mode="m_tei-to-mods"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="$p_input/descendant::tei:title[not(@level='a')]" mode="m_tei-to-mods"/>
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
                <xsl:when test="$p_input/descendant::tei:title[@level='a']">                        
                    <genre authority="local" xml:lang="en">journalArticle</genre>
                    <genre authority="marcgt" xml:lang="en">article</genre>
                </xsl:when>
                <xsl:when test="$p_input/descendant::tei:title[@level='m']">
                    <genre authority="local">book</genre>
                    <genre authority="marcgt">book</genre>
                </xsl:when>
                <xsl:when test="$p_input/descendant::tei:title[@level='j']">
                    <genre authority="local">periodical</genre>
                    <genre authority="marcgt">periodical</genre>
                </xsl:when>
            </xsl:choose>
            <!-- for each author -->
            <xsl:apply-templates select="$p_input/descendant::tei:author/tei:persName" mode="m_tei-to-mods"/>
           
            <xsl:choose>
                <xsl:when test="$p_input/descendant::tei:title[@level='a']">
            <relatedItem type="host">
                <titleInfo>
                   <xsl:apply-templates select="$p_input/descendant::tei:title[@xml:lang=$p_lang][not(@level='a')]" mode="m_tei-to-mods"/>
                </titleInfo>
                <genre authority="marcgt">journal</genre>
                <xsl:copy-of select="$v_editor"/>
                <xsl:copy-of select="$v_originInfo"/>
                <xsl:copy-of select="$v_part"/>
                <!-- IDs: but not URL -->
                <xsl:apply-templates select="$p_input/descendant::tei:idno[not(@type='url')]" mode="m_tei-to-mods"/>
            </relatedItem>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="$v_editor"/>
                    <xsl:copy-of select="$v_originInfo"/>
                    <xsl:copy-of select="$v_part"/>
                </xsl:otherwise>
            </xsl:choose>
            <accessCondition>
<!--                <xsl:value-of select="$p_url-licence"/>-->
            </accessCondition>
            <xsl:if test="$p_input/descendant::tei:idno[@type='url']">
                <!-- MODS allows for more than one URL! -->
                <location>
                    <xsl:for-each select="$p_input/descendant::tei:idno[@type='url']">
                    <!--<url dateLastAccessed="{$p_date-accessed}" usage="primary display">-->
                    <url usage="primary display">
                        <xsl:value-of select="."/>
                    </url>
                    </xsl:for-each>
                </location>
            </xsl:if>
            <!-- language information -->
            <xsl:choose>
                <xsl:when test="$p_input/descendant::tei:textLang">
                    <xsl:apply-templates select="$p_input/descendant::tei:textLang" mode="m_tei-to-mods"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="v_lang">
                        <tei:textLang><xsl:value-of select="$p_lang"/></tei:textLang>
                    </xsl:variable>
                    <xsl:apply-templates select="$v_lang/tei:textLang" mode="m_tei-to-mods"/>
                </xsl:otherwise>
            </xsl:choose>
        </mods>
    </xsl:function>

    <!-- plain text output: beware that heavily marked up nodes will have most whitespace omitted -->
    <xsl:template match="text()" mode="m_plain-text">
<!--        <xsl:value-of select="normalize-space(replace(.,'(\w)[\s|\n]+','$1 '))"/>-->
        <xsl:text> </xsl:text>
        <xsl:value-of select="normalize-space(.)"/>
        <xsl:text> </xsl:text>
    </xsl:template>
    <!-- replace any line, column or page break with a single whitespace -->
    <xsl:template match="tei:lb | tei:cb | tei:pb" mode="m_plain-text">
        <xsl:text> </xsl:text>
    </xsl:template>
    <!-- if editors made any interventions, use the text found in the analogue original -->
    <xsl:template match="tei:choice[tei:orig]" mode="m_plain-text">
        <xsl:apply-templates select="tei:orig" mode="m_plain-text"/>
    </xsl:template>
    <!-- prevent notes in div/head from producing output -->
    <xsl:template match="tei:head/tei:note" mode="m_plain-text" priority="100"/>

    <!-- transform TEI names to MODS -->
    <xsl:template match="tei:surname | tei:persName" mode="m_tei-to-mods">
        <namePart type="family" xml:lang="{@xml:lang}">
            <xsl:variable name="v_plain">
                <xsl:apply-templates select="." mode="m_plain-text"/>
            </xsl:variable>
            <xsl:value-of select="normalize-space($v_plain)"/>
        </namePart>
    </xsl:template>
    <xsl:template match="tei:forename" mode="m_tei-to-mods">
        <namePart type="given" xml:lang="{@xml:lang}">
            <xsl:variable name="v_plain">
                <xsl:apply-templates select="." mode="m_plain-text"/>
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
    
    
    <xsl:template match="tei:publisher/tei:orgName | tei:publisher/tei:persName" mode="m_tei-to-mods">
        <!-- tei:publisher can have a variety of child nodes, which are completely ignored by this template -->
            <publisher xml:lang="{@xml:lang}">
                <xsl:variable name="v_plain">
                    <xsl:apply-templates select="." mode="m_plain-text"/>
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
        <placeTerm type="text" xml:lang="{@xml:lang}">
            <!-- add references to authority files  -->
            <xsl:apply-templates select="." mode="m_authority"/>
            <xsl:variable name="v_plain">
                <xsl:apply-templates select="." mode="m_plain-text"/>
            </xsl:variable>
            <xsl:value-of select="normalize-space($v_plain)"/>
        </placeTerm>
    </xsl:template>
    
    <xsl:template match="tei:persName | tei:orgName | tei:editor | tei:author" mode="m_authority">
            <xsl:if test="@ref!=''">
                <xsl:choose>
                    <!-- note that MODS seemingly supports only one authority file -->
                    <xsl:when test="matches(@ref, 'viaf:\d+')">
                        <xsl:attribute name="authority" select="'viaf'"/>
                        <!-- it is arguably better to directly dereference VIAF IDs -->
                        <xsl:attribute name="valueURI" select="replace(@ref,'.*viaf:(\d+).*','https://viaf.org/viaf/$1')"/>
                    </xsl:when>
                    <xsl:when test="matches(@ref, 'oape:pers:\d+')">
                        <xsl:attribute name="authority" select="'oape'"/>
                        <!-- OpenArabicPE IDs do not resolve -->
                        <xsl:attribute name="valueURI" select="replace(@ref,'.*(oape:pers:\d+).*','$1')"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:if>
    </xsl:template>
    
    <xsl:template match="tei:placeName" mode="m_authority">
        <xsl:if test="@ref!=''">
             <xsl:choose>
                    <!-- note that MODS seemingly supports only one authority file -->
                    <xsl:when test="matches(@ref, 'geon:\d+')">
                        <xsl:attribute name="authority" select="'geonames'"/>
                        <!-- it is arguably better to directly dereference VIAF IDs -->
                        <xsl:attribute name="valueURI" select="replace(@ref,'.*geon:(\d+).*','https://www.geonames.org/$1')"/>
                    </xsl:when>
                    <xsl:when test="matches(@ref, 'oape:place:\d+')">
                        <xsl:attribute name="authority" select="'oape'"/>
                        <!-- OpenArabicPE IDs do not resolve -->
                        <xsl:attribute name="valueURI" select="replace(@ref,'.*(oape:place:\d+).*','$1')"/>
                    </xsl:when>
                </xsl:choose>
        </xsl:if>
    </xsl:template>
    
    <!-- IDs -->
    <xsl:template match="tei:idno" mode="m_tei-to-mods">
        <identifier type="{@type}">
            <xsl:variable name="v_plain">
                <xsl:apply-templates select="." mode="m_plain-text"/>
            </xsl:variable>
            <xsl:value-of select="normalize-space($v_plain)"/>
        </identifier>
    </xsl:template>
    
    <!-- source languages -->
    <xsl:template match="tei:textLang" mode="m_tei-to-mods">
        <language>
            <languageTerm type="code" authorityURI="http://www.iana.org/assignments/language-subtag-registry/language-subtag-registry">
                <xsl:value-of select="."/>
            </languageTerm>
        </language>
    </xsl:template>
    
    <!-- titles -->
    <xsl:template match="tei:title" mode="m_tei-to-mods">
        <xsl:choose>
            <xsl:when test="@type='sub'">
                <subTitle lang="{@xml:lang}">
                    <xsl:variable name="v_plain">
                        <xsl:apply-templates select="." mode="m_plain-text"/>
                    </xsl:variable>
                    <xsl:value-of select="normalize-space($v_plain)"/>
                </subTitle>
            </xsl:when>
            <xsl:otherwise>
                <title xml:lang="{@xml:lang}">
                    <xsl:variable name="v_plain">
                        <xsl:apply-templates select="." mode="m_plain-text"/>
                    </xsl:variable>
                    <xsl:value-of select="normalize-space($v_plain)"/>
                </title>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- volume, issue, pages -->
    <xsl:template match="tei:biblScope[@unit=('volume' , 'issue')]" mode="m_tei-to-mods">
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
                </xsl:choose>
            </number>
        </detail>
    </xsl:template>
    <xsl:template match="tei:biblScope[@unit=('page')]" mode="m_tei-to-mods">
        <extent unit="pages">
                        <start>
                            <xsl:value-of select="@from"/>
                        </start>
                        <end>
                            <xsl:value-of select="@to"/>
                        </end>
                    </extent>
    </xsl:template>
    
    <!-- contributors -->
    <xsl:template match="tei:editor/tei:persName | tei:author/tei:persName" mode="m_tei-to-mods" priority="10">
                    <name type="personal" xml:lang="{@xml:lang}">
                        <!-- add references to authority files -->
                        <xsl:choose>
                            <xsl:when test="matches(parent::tei:editor/@ref, 'viaf:\d+')">
                                <xsl:apply-templates select="parent::tei:editor" mode="m_authority"/>
                            </xsl:when>
                            <!--<xsl:when test="matches(@ref, 'viaf:\d+')">
                                <xsl:apply-templates select="." mode="m_authority"/>
                            </xsl:when>-->
                            <xsl:otherwise>
                                <xsl:apply-templates select="." mode="m_authority"/>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:choose>
                            <xsl:when test="tei:surname">
                                <xsl:apply-templates select="tei:surname" mode="m_tei-to-mods"/>
                                <xsl:apply-templates select="tei:forename" mode="m_tei-to-mods"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- what should happen if there is neither surname nor forename? -->
                                <!-- there should still be a wrapper node -->
                                <namePart>
                                    <xsl:apply-templates select="self::tei:persName" mode="m_plain-text"/>
                                </namePart>
                            </xsl:otherwise>
                        </xsl:choose>
                        <role>
                            <roleTerm authority="marcrelator" type="code">
                                <xsl:choose>
                                    <xsl:when test="parent::tei:editor">
                                        <xsl:text>edt</xsl:text>
                                    </xsl:when>
                                    <xsl:when test="parent::tei:author">
                                        <xsl:text>aut</xsl:text>
                                    </xsl:when>
                                </xsl:choose>
                            </roleTerm>
                        </role>
                    </name>
                </xsl:template>

</xsl:stylesheet>
