<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:tss="http://www.thirdstreetsoftware.com/SenteXML-1.0"
    xmlns:mods="http://www.loc.gov/mods/v3" 
    xmlns="http://www.loc.gov/mods/v3"  
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:oape="https://openarabicpe.github.io/ns"
    xpath-default-namespace="http://www.loc.gov/mods/v3"
    exclude-result-prefixes="#all"
    version="3.0">
    <xsl:output method="xml" encoding="UTF-8" indent="yes" omit-xml-declaration="no" version="1.0"/>
<!-- this stylesheet translates <tss:reference>s to  <mods:mods> -->
    
    <!-- date conversion functions -->
<!--    <xsl:include href="https://tillgrallert.github.io/xslt-calendar-conversion/functions/date-functions.xsl"/>-->
     <xsl:include href="../../../xslt-calendar-conversion/functions/date-functions.xsl"/>
    <xsl:include href="convert_tss_functions.xsl"/>

    <xsl:variable name="vgFileId" select="substring-before(tokenize(base-uri(),'/')[last()],'.TSS')"/>
    <!-- this needs to be adopted to work with any periodical and not just al-Muqtabas -->
    <xsl:variable name="v_schema" select="'http://www.loc.gov/standards/mods/mods-3-7.xsd'"/>
    <xsl:variable name="v_license" select="'http://creativecommons.org/licenses/by-sa/4.0/'"/>
    
    <!-- debugging -->
    <xsl:template match="/">
        <modsCollection xmlns="http://www.loc.gov/mods/v3"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xsi:schemaLocation="http://www.loc.gov/standards/mods/mods-3-7.xsd">
            <xsl:apply-templates select="descendant::tss:reference"/>
        </modsCollection>
    </xsl:template>
    <xsl:template match="tss:reference">
        <xsl:copy-of select="oape:bibliography-tss-to-mods(.,'en')"/>
    </xsl:template>
    
    <!-- fields not yet covered 
        + Repository: Zotero has a field called "Archive" but it is not included in the MODS output
        + Date read
        + attachments
    -->
    
    <!-- date fields in <originInfo> change their name based on the <genre> value -->

    <!-- the MODS output -->
    <xsl:function name="oape:bibliography-tss-to-mods">
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
        <xsl:variable name="v_date-publication" select="$p_input/tss:dates/tss:date[@type = 'Publication']"/>
        <xsl:variable name="v_reference-type" select="lower-case($p_input/tss:publicationType/@name)"/>
        <!-- check if the reference is for a section of a work (i.e. article, chapter )-->
        <xsl:variable name="v_reference-is-section" select="if($p_input/descendant::tss:characteristic[@name = 'articleTitle']!='') then(true()) else(false())"/>
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
                    <xsl:apply-templates select="$p_input/descendant::tss:characteristic[@name = 'publicationCountry']" mode="m_tss-to-mods"/>
                </place>
                <xsl:apply-templates select="$p_input/descendant::tss:characteristic[@name = 'publisher']" mode="m_tss-to-mods"/>
                <!-- dates -->
                <xsl:choose>
                    <xsl:when test="$v_reference-type = ('archival letter')">
                        <dateCreated>
                            <xsl:apply-templates select="$v_date-publication" mode="m_tss-to-mods"/>
                        </dateCreated>
                    </xsl:when>
                    <xsl:when test="$v_reference-type = ('archival book','book')">
                        <copyrightDate>
                            <xsl:apply-templates select="$v_date-publication" mode="m_tss-to-mods"/>
                        </copyrightDate>
                    </xsl:when>
                    <xsl:otherwise>
                        <dateIssued>
                            <xsl:apply-templates select="$v_date-publication" mode="m_tss-to-mods"/>
                        </dateIssued>
                    </xsl:otherwise>
                </xsl:choose>
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
                                <xsl:analyze-string select="$p_input/descendant::tei:date[@calendar = '#cal_islamic'][@when-custom][1]/@when-custom" regex="(\d{{4}})$|(\d{{4}}-\d{{2}}-\d{{2}})$">
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
                <!-- select issuance based on reference type -->
                <issuance>
                    <xsl:choose>
                        <!-- find periodicals, which were continuously published -->
                        <xsl:when test="$v_reference-type = ('archival periodical', 'archival periodical article', 'journal article', 'newspaper article')">                        
                            <xsl:text>continuing</xsl:text>
                        </xsl:when>
                        <!-- fallback: monographic -->
                        <xsl:otherwise>
                            <xsl:text>monographic</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </issuance>
            </originInfo>
        </xsl:variable>
        <!-- information on volume, issue, pages -->
        <xsl:variable name="v_part">
            <part>
                <xsl:apply-templates select="$p_input/descendant::tss:characteristic[@name = 'volume']" mode="m_tss-to-mods"/>
                <xsl:apply-templates select="$p_input/descendant::tss:characteristic[@name = 'issue']" mode="m_tss-to-mods"/>
                <xsl:apply-templates select="$p_input/descendant::tss:characteristic[@name = 'pages']" mode="m_tss-to-mods"/>
            </part>
        </xsl:variable>
        
        <xsl:variable name="v_related-item">
            <xsl:apply-templates select="$p_input/descendant::tss:author[@role = 'Editor']" mode="m_tss-to-mods"/>
            <xsl:apply-templates select="$p_input/descendant::tss:characteristic[@name = 'Recipient']" mode="m_tss-to-mods"/>
            <!-- further contributors -->
            
                <xsl:copy-of select="$v_originInfo"/>
                <xsl:copy-of select="$v_part"/>
                <!-- IDs: but not URL -->
                <xsl:apply-templates select="$p_input/descendant::tss:characteristic[@name = ('UUID', 'OCLCID', 'DOI', 'ISBN', 'Citation identifier', 'bibTeXKey', 'RIS reference number')]" mode="m_tss-to-mods"/>
                <xsl:apply-templates select="$p_input/descendant::tss:characteristic[@name = ('Signatur', 'call-num')]" mode="m_tss-to-mods"/>
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
                        <!-- test for analytical titles in any language -->
                        <xsl:when test="$v_reference-is-section = true()">
                            <xsl:apply-templates select="$p_input/descendant::tss:characteristic[@name = 'articleTitle']" mode="m_tss-to-mods"/>
                        </xsl:when>
                        <!-- fall back: other title in any language -->
                        <xsl:otherwise>
                            <xsl:apply-templates select="$p_input/descendant::tss:characteristic[@name = 'publicationTitle']" mode="m_tss-to-mods"/>
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
            <!-- establish the genre: map Sente publicationType to MODS genre -->
            <xsl:apply-templates select="$p_input/tss:publicationType" mode="m_tss-to-mods"/>
            <!-- for each author -->
            <xsl:apply-templates select="$p_input/descendant::tss:author[@role = 'Author']" mode="m_tss-to-mods"/>
           
            <xsl:choose>
                <!-- check if the reference relates to a part of a work (i.e. article, chapter etc.) -->
                <xsl:when test="$v_reference-is-section = true()">
                    <xsl:if test="$p_debug = true()">
                        <xsl:message>
                        <xsl:text>analytic</xsl:text>
                    </xsl:message>
                    </xsl:if>
            <relatedItem type="host">
                <titleInfo>
                     <xsl:apply-templates select="$p_input/descendant::tss:characteristic[@name = 'publicationTitle']" mode="m_tss-to-mods"/>
                </titleInfo>
                <!-- establish genre of the host -->
                <genre authority="marcgt">journal</genre>
                <xsl:copy-of select="$v_related-item"/>
            </relatedItem>
                </xsl:when>
                <!-- the following should generate output for full works only -->
                <xsl:otherwise>
                    <xsl:if test="$p_debug = true()">
                    <xsl:message>
                        <xsl:text>monogr</xsl:text>
                    </xsl:message>
                    </xsl:if>
                    <xsl:copy-of select="$v_related-item"/>
                </xsl:otherwise>
            </xsl:choose>
            <!-- I am not sure that licences are part of the Sente output -->
           <!-- <accessCondition>
                <!-\- for the time being I use a fixed variable -\->
                <xsl:value-of select="$v_license"/>
            </accessCondition>-->
            <xsl:if test="$p_input/descendant::tss:characteristic[@name = 'URL']">
                <!-- MODS allows for more than one URL! -->
                <location>
                    <xsl:for-each select="$p_input/descendant::tss:characteristic[@name = 'URL']">
                    <!--<url dateLastAccessed="{$p_date-accessed}" usage="primary display">-->
                        <url usage="primary display">
                            <xsl:value-of select="."/>
                        </url>
                    </xsl:for-each>
                </location>
            </xsl:if>
            <!-- abstract -->
            <xsl:apply-templates select="$p_input/descendant::tss:characteristic[@name = 'abstractText']" mode="m_tss-to-mods"/>
            <!-- notes -->
            <xsl:apply-templates select="$p_input/descendant::tss:note" mode="m_tss-to-mods"/>
            <!-- keywords and tags -->
            <xsl:apply-templates select="$p_input/descendant::tss:keyword" mode="m_tss-to-mods"/>
            <!-- language information -->
            <xsl:apply-templates select="$p_input/descendant::tss:characteristic[@name = 'language']" mode="m_tss-to-mods"/>
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
    
    <xsl:template match="tss:characteristic[@name = 'abstractText']" mode="m_tss-to-mods">
        <abstract>
            <xsl:apply-templates/>
        </abstract>
    </xsl:template>
    
    <xsl:template match="tss:keyword" mode="m_tss-to-mods">
        <subject>
            <topic>
                <xsl:apply-templates/>
            </topic>
        </subject>
    </xsl:template>
    
    <!-- map publication Types -->
    <xsl:template match="tss:publicationType" mode="m_tss-to-mods">
        <xsl:choose>
                <!-- establish the genre: map Sente publicationType to MODS genre -->
            <xsl:when test="@name = ('Archival Letter')">
                    <genre authority="local">letter</genre>
                    <genre authority="marcgt">letter</genre>
                </xsl:when>
                <xsl:when test="@name = ('Archival Periodical')">
                    <genre authority="local">periodical</genre>
                    <genre authority="marcgt">periodical</genre>
                </xsl:when>
            <xsl:when test="@name = ('Archival Periodical Article')">
                    <genre authority="local">magazineArticle</genre>
<!--                    <genre authority="marcgt">periodical</genre>-->
                </xsl:when>
            <xsl:when test="@name = ('Book')">
                    <genre authority="local">book</genre>
                    <genre authority="marcgt">book</genre>
                </xsl:when>
            <xsl:when test="@name = ('Journal Article')">                        
                    <genre authority="local" xml:lang="en">journalArticle</genre>
                    <genre authority="marcgt" xml:lang="en">article</genre>
                </xsl:when>
            <xsl:when test="@name = ('Newspaper Article')">
                    <genre authority="local">newspaperArticle</genre>
<!--                    <genre authority="marcgt">periodical</genre>-->
                </xsl:when>
            </xsl:choose>
    </xsl:template>

    <!-- transform dates -->
    <xsl:template match="tss:date" mode="m_tss-to-mods">
        <xsl:variable name="v_year" select="if(@year!='') then(format-number(@year,'0000')) else()"/>
        <xsl:variable name="v_month" select="if(@month!='') then(format-number(@month,'00')) else('xx')"/>
        <xsl:variable name="v_day" select="if(@day!='') then(format-number(@day,'00')) else('xx')"/>
        <xsl:variable name="v_date" select="concat($v_year, '-', $v_month, '-', $v_day)"/>
        <xsl:choose>
                        <xsl:when test="matches($v_date, '\d{4}-\d{2}-\d{2}')">
                            <xsl:attribute name="encoding" select="'w3cdtf'"/>
                            <xsl:value-of select="$v_date"/>
                        </xsl:when>
            <xsl:when test="matches($v_date,'^\d{4}-xx-xx')">
                <xsl:attribute name="encoding" select="'w3cdtf'"/>
                <xsl:value-of select="$v_year"/>
            </xsl:when>
                        <!-- fallback -->
            <xsl:otherwise>
                <xsl:value-of select="$v_date"/>
            </xsl:otherwise>
                    </xsl:choose>
                
    </xsl:template>
    
    <!-- contributors -->
    <xsl:template match="tss:author" mode="m_tss-to-mods" priority="10">
                    <name type="personal">
                        <xsl:choose>
                            <xsl:when test="tss:surname and tss:forenames">
                                <xsl:apply-templates select="tss:surname" mode="m_tss-to-mods"/>
                                <xsl:apply-templates select="tss:forenames" mode="m_tss-to-mods"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- what should happen if there is neither surname nor forename? -->
                                <!-- there should still be a wrapper node -->
                                    <xsl:apply-templates select="tss:surname" mode="m_tss-to-mods"/>
                            </xsl:otherwise>
                        </xsl:choose>
                        <role>
                            <roleTerm authority="marcrelator" type="code">
                                <xsl:choose>
                                    <xsl:when test="@role = 'Editor'">
                                        <xsl:text>edt</xsl:text>
                                    </xsl:when>
                                    <xsl:when test="@role = 'Author'">
                                        <xsl:text>aut</xsl:text>
                                    </xsl:when>
                                </xsl:choose>
                            </roleTerm>
                        </role>
                    </name>
                </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'Recipient']" mode="m_tss-to-mods" priority="10">
                    <name type="personal">
                        <namePart type="family">
                            <xsl:value-of select="."/>
                        </namePart>
                        <role>
                            <roleTerm authority="marcrelator" type="code">
                                        <xsl:text>cbt</xsl:text>
                            </roleTerm>
                        </role>
                    </name>
                </xsl:template>

    <!-- transform TEI names to MODS -->
    <xsl:template match="tss:surname" mode="m_tss-to-mods">
        <namePart type="family">
            <xsl:variable name="v_plain">
                <xsl:apply-templates select="." mode="m_plain-text"/>
            </xsl:variable>
            <xsl:value-of select="normalize-space($v_plain)"/>
        </namePart>
    </xsl:template>
    <xsl:template match="tss:forenames" mode="m_tss-to-mods">
        <namePart type="given">
            <xsl:variable name="v_plain">
                <xsl:apply-templates select="." mode="m_plain-text"/>
            </xsl:variable>
            <xsl:value-of select="normalize-space($v_plain)"/>
        </namePart>
    </xsl:template>
<!--    <xsl:template match="tei:persName" mode="m_tss-to-mods">
        <xsl:param name="p_lang"/>
        <namePart type="family" xml:lang="{$p_lang}">
            <xsl:value-of select="."/>
        </namePart>
    </xsl:template>-->
    
    
    <xsl:template match="tss:characteristic[@name = 'publisher']" mode="m_tss-to-mods">
        <!-- tei:publisher can have a variety of child nodes, which are completely ignored by this template -->
            <publisher>
                <xsl:variable name="v_plain">
                    <xsl:apply-templates select="." mode="m_plain-text"/>
                </xsl:variable>
                <xsl:value-of select="normalize-space($v_plain)"/>
            </publisher>
    </xsl:template>
    
    <!--<xsl:template match="tei:pubPlace" mode="m_tss-to-mods">
        <place>
            <xsl:apply-templates mode="m_tss-to-mods"/>
        </place>
    </xsl:template>-->
    
    <xsl:template match="tss:characteristic[@name = 'publicationCountry']" mode="m_tss-to-mods">
        <placeTerm type="text">
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
    
    <xsl:template match="tss:characteristic[@name = 'publicationCountry']" mode="m_authority">
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
    <xsl:template match="tss:characteristic[@name = ('UUID', 'OCLCID', 'DOI', 'ISBN', 'Citation identifier', 'bibTeXKey', 'RIS reference number')]" mode="m_tss-to-mods">
        <xsl:if test=".!=''">
            <identifier>
            <xsl:attribute name="type">
                <xsl:choose>
                    <xsl:when test="@name = 'OCLCID'">
                        <xsl:value-of select="'OCLC'"/>
                    </xsl:when>
                   <!-- <xsl:when test="@name = 'DOI'">
                        <xsl:value-of select="'DOI'"/>
                    </xsl:when>
                    <xsl:when test="@name = 'ISBN'">
                        <xsl:value-of select="'ISBN'"/>
                    </xsl:when>-->
                    <xsl:when test="@name = 'Citation identifier'">
                        <xsl:value-of select="'SenteCitationID'"/>
                    </xsl:when>
                    <!-- fallback: replicate -->
                    <xsl:otherwise>
                        <xsl:value-of select="replace(@name,' ','-')"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <xsl:variable name="v_plain">
                <xsl:apply-templates select="." mode="m_plain-text"/>
            </xsl:variable>
            <xsl:value-of select="normalize-space($v_plain)"/>
        </identifier>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="tss:characteristic[@name = ('Signatur', 'call-num')]" mode="m_tss-to-mods">
        <classification>
            <xsl:value-of select="."/>
        </classification>
    </xsl:template>
    
    <!-- source languages -->
    <xsl:template match="tss:characteristic[@name = 'language']" mode="m_tss-to-mods">
        <language>
            <!--<languageTerm type="code" authorityURI="http://www.iana.org/assignments/language-subtag-registry/language-subtag-registry">
                <xsl:value-of select="@mainLang"/>
            </languageTerm>-->
            <languageTerm type="text">
                <xsl:value-of select="."/>
            </languageTerm>
        </language>
    </xsl:template>
    
    <!-- titles -->
    <xsl:template match="tss:characteristic[@name = ('publicationTitle', 'articleTitle')]" mode="m_tss-to-mods">
        <!-- check if the title contains a subtitle divided by ':' -->
        <xsl:choose>
            <xsl:when test="matches(.,'.+:.+')">
                <title>
                    <xsl:variable name="v_plain">
                        <xsl:apply-templates select="replace(.,'^(.+):.+$','$1')" mode="m_plain-text"/>
                    </xsl:variable>
                    <xsl:value-of select="normalize-space($v_plain)"/>
                </title>
                <subTitle>
                    <xsl:variable name="v_plain">
                        <xsl:apply-templates select="replace(.,'^.+:(.+)$','$1')" mode="m_plain-text"/>
                    </xsl:variable>
                    <xsl:value-of select="normalize-space($v_plain)"/>
                </subTitle>
            </xsl:when>
            <xsl:otherwise>
                <title>
                    <xsl:variable name="v_plain">
                        <xsl:apply-templates select="." mode="m_plain-text"/>
                    </xsl:variable>
                    <xsl:value-of select="normalize-space($v_plain)"/>
                </title>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- volume, issue, pages -->
    <xsl:template match="tss:characteristic[@name = ('volume', 'issue')]" mode="m_tss-to-mods">
        <xsl:if test=".!=''">
        <xsl:variable name="v_onset" select="replace(.,'(\d+)-*\d*','$1')"/>
        <xsl:variable name="v_terminus" select="replace(.,'\d+-(\d+)','$1')"/>
        <detail type="{@name}">
            <number>
                <xsl:choose>
                    <!-- check for correct encoding of volume information -->
                    <xsl:when test="$v_onset = $v_terminus">
                        <xsl:value-of select="$v_onset"/>
                    </xsl:when>
                    <!-- check for ranges -->
                    <xsl:when test="$v_onset != $v_terminus">
                        <xsl:value-of select="$v_onset"/>
                        <!-- probably an en-dash is the better option here -->
                        <xsl:text>-</xsl:text>
                        <xsl:value-of select="$v_terminus"/>
                    </xsl:when>
                    <!-- fallback: replicate content -->
                    <xsl:otherwise>
                        <xsl:value-of select="."/>
                    </xsl:otherwise>
                </xsl:choose>
            </number>
        </detail>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'pages']" mode="m_tss-to-mods">
        <xsl:variable name="v_onset" select="replace(.,'(\d+)-*\d*','$1')"/>
        <xsl:variable name="v_terminus" select="replace(.,'\d+-(\d+)','$1')"/>
        <extent unit="pages">
                        <start>
                            <xsl:value-of select="$v_onset"/>
                        </start>
                        <end>
                            <xsl:value-of select="$v_terminus"/>
                        </end>
                    </extent>
    </xsl:template>
    
    <!-- notes -->
    <xsl:template match="tss:note" mode="m_tss-to-mods">
        <note>
            <xsl:copy-of select="oape:bibliography-tss-note-to-html(.)"/>
        </note>
    </xsl:template>
</xsl:stylesheet>
