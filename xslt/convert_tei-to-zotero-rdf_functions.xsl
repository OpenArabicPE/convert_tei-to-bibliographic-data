<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
     xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
 xmlns:z="http://www.zotero.org/namespaces/export#"
 xmlns:bib="http://purl.org/net/biblio#"
 xmlns:foaf="http://xmlns.com/foaf/0.1/"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:dcterms="http://purl.org/dc/terms/"
  xmlns:vcard="http://nwalsh.com/rdf/vCard#"
  xmlns:tss="http://www.thirdstreetsoftware.com/SenteXML-1.0" 
  xmlns:tei="http://www.tei-c.org/ns/1.0" 
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:prism="http://prismstandard.org/namespaces/1.2/basic/"
  xmlns:link="http://purl.org/rss/1.0/modules/link/"
  xmlns:oape="https://openarabicpe.github.io/ns"
    version="3.0">
    
    <xsl:output method="xml" indent="yes" omit-xml-declaration="no" encoding="UTF-8"/>
    
    
    <!-- this stylesheet translates <tei:biblStruct> to Zotero RDF -->
    <!-- to do:
          - remove whitespace from subtitles
          - improve short titles
          - add full-text notes
    -->
    
    <xsl:param name="p_length-short-title" select="5"/>
    <xsl:param name="p_full-text-note" select="false()"/>
    <xsl:variable name="v_new-line" select="'&#x0A;'"/>
    <xsl:variable name="v_separator-key-value" select="': '"/>
    <xsl:variable name="v_cite-key-whitespace-replacement" select="'+'"/>
    <xsl:variable name="vgFileId" select="substring-before(tokenize(base-uri(),'/')[last()],'.TEIP5')"/>
    
    <xsl:function name="oape:bibliography-tei-to-zotero-rdf">
        <xsl:param name="tei_biblstruct"/>
        <xsl:param name="p_lang"/>
        <!-- check reference type, since the first child after the root depends on it -->
        <!-- this can be based on the structure of the biblStruct -->
        <xsl:variable name="v_reference-type-bib" select="'Article'"/>
        <xsl:variable name="v_reference-type-zotero" select="'journalArticle'"/>
        <xsl:variable name="v_reference-is-section" select="if($tei_biblstruct/tei:analytic) then(true()) else(false())"/>
<!--        <xsl:variable name="v_reference-is-part-of-series" select="if($tss_reference/descendant::tss:characteristic[@name = 'Series'] != '') then(true()) else(false())"/>-->
        <!--<xsl:variable name="v_series">
            <dcterms:isPartOf>
                    <bib:Series>
                        <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Series']" mode="m_tei-to-zotero-rdf"/>
                        <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Series number']" mode="m_tei-to-zotero-rdf"/>
                    </bib:Series>
                </dcterms:isPartOf>
        </xsl:variable>-->
        <!-- output -->
        <xsl:element name="bib:{$v_reference-type-bib}">
            <!-- add an ID -->
            <xsl:attribute name="rdf:about" select="concat('#',$tei_biblstruct/tei:analytic/tei:idno[@type = 'BibTeX'])"/>
            <!-- itemType -->
            <z:itemType>
                <xsl:value-of select="$v_reference-type-zotero"/>
            </z:itemType>
            <!-- titles -->
            <xsl:choose>
                <!-- check if the reference is part of a larger work (i.e. a chapter, article) -->
                <xsl:when test="$v_reference-is-section = true()">
                    <dcterms:isPartOf>
                        <xsl:choose>
                            <!-- book chapters -->
                            <xsl:when test="$v_reference-type-bib = 'BookSection'">
                                <bib:Book>
                                    <!-- check if reference is part of a series -->
                                    <!--<xsl:if test="$v_reference-is-part-of-series = true()">
                                        <xsl:copy-of select="$v_series"/>
                                    </xsl:if>-->
                                    <xsl:apply-templates select="$tei_biblstruct/tei:monogr/tei:title[@xml:lang = $p_lang]" mode="m_tei-to-zotero-rdf"/>
                                </bib:Book>
                            </xsl:when>
                            <!-- periodical articles -->
                            <xsl:when test="$v_reference-type-bib = 'Article'">
                                <bib:Periodical>
                                    <xsl:apply-templates select="$tei_biblstruct/tei:monogr/tei:biblScope[@unit = 'volume']" mode="m_tei-to-zotero-rdf"/>
                                    <xsl:apply-templates select="$tei_biblstruct/tei:monogr/tei:biblScope[@unit = 'issue']" mode="m_tei-to-zotero-rdf"/>
                                    <xsl:apply-templates select="$tei_biblstruct/tei:monogr/tei:title[@xml:lang = $p_lang]" mode="m_tei-to-zotero-rdf"/>
                                </bib:Periodical>
                            </xsl:when>
                            <!-- maps: it seems that the articleTitle should be mapped to Series -->
                            <xsl:when test="$v_reference-type-zotero = 'map'"/>
                            <!-- fallback: book -->
                            <xsl:otherwise>
                                <bib:Book>
                                    <!-- check if reference is part of a series -->
                                    <!--<xsl:if test="$v_reference-is-part-of-series = true()">
                                        <xsl:copy-of select="$v_series"/>
                                    </xsl:if>-->
                                    <xsl:apply-templates select="$tei_biblstruct/tei:monogr/tei:title[@xml:lang = $p_lang]" mode="m_tei-to-zotero-rdf"/>
                                </bib:Book>
                            </xsl:otherwise>
                        </xsl:choose>
                    </dcterms:isPartOf>
                    <!-- check if an item is part of a series -->
                    <xsl:apply-templates select="$tei_biblstruct/tei:analytic/tei:title[@level = 'a'][@xml:lang = $p_lang]" mode="m_tei-to-zotero-rdf"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- check if reference is part of a series -->
                    <!--<xsl:if test="$v_reference-is-part-of-series = true()">
                        <xsl:copy-of select="$v_series"/>
                    </xsl:if>-->
                    <xsl:apply-templates select="$tei_biblstruct/tei:monogr/tei:title[@xml:lang = $p_lang]" mode="m_tei-to-zotero-rdf"/>
                </xsl:otherwise>
            </xsl:choose>
            <!-- short titles -->
            <xsl:choose>
                <!-- fake code -->
                <xsl:when test=" 1 = 2"/>
                <!--<xsl:when test="$tss_reference/descendant::tss:characteristic[@name = 'Short Titel']">
                    <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Short Titel']" mode="m_tei-to-zotero-rdf"/>
                </xsl:when>
                <xsl:when test="$tss_reference/descendant::tss:characteristic[@name = 'Shortened title']">
                    <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Shortened title']" mode="m_tei-to-zotero-rdf"/>
                </xsl:when>-->
                <!-- fallback: create a short title -->
                <xsl:otherwise>
                    <xsl:variable name="v_title-temp" select="if($v_reference-is-section = true()) then($tei_biblstruct/tei:analytic/tei:title[@level = 'a'][@xml:lang = $p_lang]) else($tei_biblstruct/tei:monogr/tei:title[@xml:lang = $p_lang])"/>
                    <xsl:analyze-string select="normalize-space($v_title-temp)" regex="^(.+?)([:|\.|\?])(.+)$">
                        <xsl:matching-substring>
                            <z:shortTitle><xsl:value-of select="normalize-space(regex-group(1))"/></z:shortTitle>
                        </xsl:matching-substring>
                        <xsl:non-matching-substring>
                            <z:shortTitle>
                            <xsl:for-each select="tokenize(normalize-space($v_title-temp),'\s+')">
                                <xsl:if test="position() &lt;= $p_length-short-title">
                                    <xsl:if test="position() gt 1">
                                        <xsl:text> </xsl:text>
                                    </xsl:if>
                                    <xsl:value-of select="."/>
                                </xsl:if>
                            </xsl:for-each>
                            </z:shortTitle>
                        </xsl:non-matching-substring>
                    </xsl:analyze-string>
                </xsl:otherwise>
            </xsl:choose>
            <!-- contributors: authors, editors etc. -->
            <xsl:if test="$tei_biblstruct/descendant::tei:author">
                <bib:authors>
                    <rdf:Seq>
                        <xsl:apply-templates select="$tei_biblstruct/descendant::tei:author/node()[@xml:lang = $p_lang]" mode="m_tei-to-zotero-rdf"/>
                    </rdf:Seq>
                </bib:authors>
            </xsl:if>
            <xsl:if test="$tei_biblstruct/descendant::tei:editor">
                <bib:editors>
                    <rdf:Seq>
                        <xsl:apply-templates select="$tei_biblstruct/descendant::tei:editor/node()[@xml:lang = $p_lang]" mode="m_tei-to-zotero-rdf"/>
                    </rdf:Seq>
                </bib:editors>
            </xsl:if>
        <xsl:if test="$tei_biblstruct/descendant::tei:respStmt">
                <bib:contributors>
                    <rdf:Seq>
                            <xsl:apply-templates select="$tei_biblstruct/descendant::tei:respStmt/node()[not(self::tei:resp)][@xml:lang = $p_lang]" mode="m_tei-to-zotero-rdf"/>
                    </rdf:Seq>
                </bib:contributors>
            </xsl:if>
<!--            <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Recipient']" mode="m_tei-to-zotero-rdf"/>-->
            <!-- publisher: name, location -->
             <dc:publisher>
            <foaf:Organization>
                <vcard:adr>
                    <vcard:Address>
                       <vcard:locality><xsl:value-of select="$tei_biblstruct/tei:monogr/tei:imprint/tei:pubPlace/tei:placeName[@xml:lang = $p_lang]"/></vcard:locality>
                    </vcard:Address>
                </vcard:adr>
                <foaf:name><xsl:value-of select="$tei_biblstruct/tei:monogr/tei:imprint/tei:publisher/node()[@xml:lang = $p_lang]"/></foaf:name>
            </foaf:Organization>
        </dc:publisher>
            <!-- links to notes -->
            <xsl:if test="$p_full-text-note = true()">
                <dcterms:isReferencedBy rdf:resource="{concat('#',$tei_biblstruct/descendant::tei:idno[@type = 'BibTeX'],'-text')}"/>
            </xsl:if>
        <!-- IDs / URLs -->
        <xsl:apply-templates select="$tei_biblstruct/tei:analytic/tei:idno[@type = 'url']" mode="m_tei-to-zotero-rdf"/>
            <!-- Identitifiers -->
            <!-- edition -->
<!--            <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Edition']" mode="m_tei-to-zotero-rdf"/>-->
            <!-- volume, issue: depends on work not being a chapter or article -->
            <xsl:if test="$v_reference-is-section = false()">
                <xsl:apply-templates select="$tei_biblstruct/tei:monogr/tei:biblScope[@unit = 'volume']" mode="m_tei-to-zotero-rdf"/>
                <xsl:apply-templates select="$tei_biblstruct/tei:monogr/tei:biblScope[@unit = 'issue']" mode="m_tei-to-zotero-rdf"/>
            </xsl:if>
                <xsl:apply-templates select="$tei_biblstruct/tei:monogr/tei:biblScope[@unit = 'page']" mode="m_tei-to-zotero-rdf"/>
            <!-- dates -->
            <xsl:apply-templates select="$tei_biblstruct/tei:monogr/tei:imprint/tei:date" mode="m_tei-to-zotero-rdf"/>
            <!-- extra field: map all sorts of custom fields -->
            <dc:description>
                <xsl:apply-templates select="$tei_biblstruct/tei:analytic/tei:idno[@type = 'BibTeX']" mode="m_extra-field"/>
                <xsl:apply-templates select="$tei_biblstruct/tei:monogr/tei:imprint/tei:date[@datingMethod = '#cal_ottomanfiscal']" mode="m_extra-field"/>
                <xsl:apply-templates select="$tei_biblstruct/tei:monogr/tei:imprint/tei:date[@datingMethod = '#cal_islamic']" mode="m_extra-field"/>
                <xsl:apply-templates select="$tei_biblstruct/tei:monogr/tei:imprint/tei:date[@datingMethod = '#cal_julian']" mode="m_extra-field"/>
                <xsl:apply-templates select="$tei_biblstruct/tei:monogr/tei:idno[@type = 'DOI']" mode="m_extra-field"/>
                <xsl:apply-templates select="$tei_biblstruct/tei:monogr/tei:idno[@type = 'ISBN']" mode="m_extra-field"/>
                <xsl:apply-templates select="$tei_biblstruct/tei:monogr/tei:idno[@type = 'OCLC']" mode="m_extra-field"/>
                <xsl:apply-templates select="$tei_biblstruct/tei:monogr/tei:idno[@type = 'zenodo']" mode="m_extra-field"/>
                <!-- support for multiple languages? -->
                <!--<xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Original publication year']" mode="m_extra-field"/>
                <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Orig.Title']" mode="m_extra-field"/>
                <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Translated title']" mode="m_extra-field"/>-->
<!--                <xsl:apply-templates select="$tei_biblstruct/tei:monogr/tei:biblScope[@unit = 'issue']" mode="m_extra-field"/>-->
                <!-- make this dependent on the reference type: letter etc. -->
                <xsl:apply-templates select="$tei_biblstruct/tei:monogr/tei:imprint/tei:pubPlace/tei:placeName[@xml:lang = $p_lang]" mode="m_extra-field"/>
                <xsl:apply-templates select="$tei_biblstruct/tei:monogr/tei:imprint/tei:publisher/node()[@xml:lang = $p_lang]" mode="m_extra-field"/>
<!--                <xsl:apply-templates select="$tei_biblstruct/tei:monogr/tei:biblScope[@unit = 'volume']" mode="m_extra-field"/>-->
            </dc:description>
            <!-- language -->
             <xsl:apply-templates select="$tei_biblstruct/tei:monogr/tei:textLang" mode="m_tei-to-zotero-rdf"/>
            <!-- ISBN, ISSN etc. -->
            <xsl:apply-templates select="$tei_biblstruct/tei:monogr/tei:idno[@type = 'ISBN']" mode="m_tei-to-zotero-rdf"/>
        </xsl:element>
        <!-- notes -->
        <xsl:if test="$p_full-text-note = true()">
            <xsl:copy-of select="oape:bibliography-full-text-to-note($tei_biblstruct)"/>
        </xsl:if>
    </xsl:function>
    
    <!-- plain text -->
    <xsl:template match="text()">
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:template>
    
    <!-- extra field -->
    <!-- if used with Better BibTeX, one can set the citation key in the extra field -->
    <xsl:template match="tei:idno[@type = 'BibTeX']" mode="m_extra-field">
        <xsl:if test=".!=''">
            <xsl:value-of select="concat('Citation Key', $v_separator-key-value, .,$v_new-line)"/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tei:idno[@type = 'DOI']" mode="m_extra-field">
        <xsl:if test=".!=''">
            <xsl:value-of select="concat('doi', $v_separator-key-value,.,$v_new-line)"/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tei:idno[@type = 'ISBN']" mode="m_extra-field">
        <xsl:if test=".!=''">
            <xsl:value-of select="concat('isbn', $v_separator-key-value,.,$v_new-line)"/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tei:idno[@type = 'ISBN']" mode="m_tei-to-zotero-rdf">
        <dc:identifier><xsl:value-of select="concat('ISBN ', .)"/></dc:identifier>
    </xsl:template>
    <xsl:template match="tei:idno[@type = 'OCLC']" mode="m_extra-field">
        <xsl:if test=".!=''">
            <xsl:value-of select="concat('oclc', $v_separator-key-value,.,$v_new-line)"/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tei:idno[@type = 'zenodo']" mode="m_extra-field">
        <xsl:if test=".!=''">
            <xsl:value-of select="concat('zenodo', $v_separator-key-value,.,$v_new-line)"/>
        </xsl:if>
    </xsl:template>
    
   
    <xsl:template match="tei:date" mode="m_extra-field">
        <!-- try to establish the calendar -->
        <!-- content -->
        <xsl:text>date_</xsl:text>
        <xsl:choose>
            <xsl:when test="@datingMethod = '#cal_julian'">
                <xsl:text>rumi</xsl:text>
            </xsl:when>
            <xsl:when test="@datingMethod = '#cal_ottomanfiscal'">
                <xsl:text>mali</xsl:text>
            </xsl:when>
            <xsl:when test="@datingMethod = '#cal_islamic'">
                <xsl:text>hijri</xsl:text>
            </xsl:when>
        </xsl:choose>
        <xsl:value-of select="concat($v_separator-key-value, @when-custom, $v_new-line)"/>
    </xsl:template>
     <xsl:template match="tei:biblScope" mode="m_extra-field">
        <xsl:variable name="v_value">
             <xsl:choose>
             <xsl:when test="@from = @to">
                 <xsl:value-of select="@from"/>
             </xsl:when>
             <xsl:otherwise>
                 <xsl:value-of select="concat(@from, '-', @to)"/>
             </xsl:otherwise>
         </xsl:choose>
        </xsl:variable>
         <xsl:value-of select="concat(@unit, $v_separator-key-value, $v_value, $v_new-line)"/>
    </xsl:template>
    <xsl:template match="tei:placeName" mode="m_extra-field">
        <xsl:if test=".!=''">
            <xsl:value-of select="concat('place', $v_separator-key-value,.,$v_new-line)"/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tei:publisher/node()" mode="m_extra-field">
        <xsl:if test=".!=''">
            <xsl:value-of select="concat('publisher', $v_separator-key-value,.,$v_new-line)"/>
        </xsl:if>
    </xsl:template>
    
    <!-- contributors -->
    <xsl:template match="tei:persName" mode="m_tei-to-zotero-rdf">
        <rdf:li>
            <foaf:Person>
                <xsl:apply-templates select="tei:surname" mode="m_tei-to-zotero-rdf"/>
                <xsl:apply-templates select="tei:forename" mode="m_tei-to-zotero-rdf"/>
            </foaf:Person>
        </rdf:li>
    </xsl:template>
    <xsl:template match="tei:surname" mode="m_tei-to-zotero-rdf">
        <foaf:surname><xsl:apply-templates/></foaf:surname>
    </xsl:template>
    <xsl:template match="tei:forename" mode="m_tei-to-zotero-rdf">
        <foaf:givenName><xsl:apply-templates/></foaf:givenName>
    </xsl:template>
    
   <!-- choice -->
    <xsl:template match="tei:choice">
        <xsl:choose>
            <xsl:when test="tei:abbr and tei:expan">
                <xsl:apply-templates select="tei:expan"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
   
    
    <!-- titles -->
    <xsl:template match="tei:title" mode="m_tei-to-zotero-rdf">
        <xsl:if test=".!=''">
            <dc:title><xsl:apply-templates/></dc:title>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = ('Short Titel', 'Shortened title')]" mode="m_tei-to-zotero-rdf">
        <xsl:if test=".!=''">
            <z:shortTitle><xsl:apply-templates/></z:shortTitle>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = ('Series number')]" mode="m_tei-to-zotero-rdf">
        <xsl:if test=".!=''">
            <dc:identifier><xsl:apply-templates/></dc:identifier>
        </xsl:if>
    </xsl:template>
       <!-- transform dates -->
    <xsl:template match="tei:date" mode="m_tei-to-zotero-rdf">
        <xsl:variable name="v_date">
            <xsl:choose>
                <xsl:when test="@when">
                    <xsl:value-of select="@when"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>
                        <xsl:text>Date note has no @when attribute</xsl:text>
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
                <dc:date><xsl:value-of select="$v_date"/></dc:date>
    </xsl:template>
    <xsl:template match="tei:idno[@type = 'url']" mode="m_tei-to-zotero-rdf">
        <dc:identifier>
            <dcterms:URI>
                <rdf:value><xsl:value-of select="."/></rdf:value>
            </dcterms:URI>
        </dc:identifier>
    </xsl:template>
    <!--<xsl:template match="tss:characteristic[@name = 'Edition']" mode="m_tei-to-zotero-rdf">
        <prism:edition><xsl:value-of select="."/></prism:edition>
    </xsl:template>-->
    <!--<xsl:template match="tss:characteristic[@name = 'Number of volumes']" mode="m_tei-to-zotero-rdf">
        <z:numberOfVolumes><xsl:value-of select="."/></z:numberOfVolumes>
    </xsl:template>-->
    <xsl:template match="tei:biblScope" mode="m_tei-to-zotero-rdf">
        <xsl:variable name="v_value">
             <xsl:choose>
             <xsl:when test="@from = @to">
                 <xsl:value-of select="@from"/>
             </xsl:when>
             <xsl:otherwise>
                 <xsl:value-of select="concat(@from, '-', @to)"/>
             </xsl:otherwise>
         </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="@unit = 'volume'">
                <prism:volume><xsl:value-of select="$v_value"/></prism:volume>
            </xsl:when>
            <xsl:when test="@unit = 'issue'">
                <prism:number><xsl:value-of select="$v_value"/></prism:number>
            </xsl:when>
            <xsl:when test="@unit = 'page'">
                <bib:pages><xsl:value-of select="$v_value"/></bib:pages>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tei:textLang" mode="m_tei-to-zotero-rdf">
            <z:language><xsl:value-of select="@mainLang"/></z:language>
    </xsl:template>
   
    
    <!-- call-numbers -->
    <xsl:template match="tss:characteristic[@name = ('Signatur', 'call-num')]" mode="m_tei-to-zotero-rdf">
        <xsl:if test=".!=''">
        <xsl:choose>
            <!-- for archival reference the call-number should be mapped to location in archive -->
            <xsl:when test="ancestor::tss:reference/tss:publicationType/@name = ('Archival File', 'Archival Material', 'Archival Letter')">
                <dc:coverage>
                    <xsl:apply-templates/>
                </dc:coverage>
            </xsl:when>
            <xsl:otherwise>
                <dc:subject>
                    <dcterms:LCC>
                        <rdf:value>
                            <xsl:apply-templates/>
                        </rdf:value>
                    </dcterms:LCC>
                </dc:subject>
            </xsl:otherwise>
        </xsl:choose>
        </xsl:if>
    </xsl:template>
    
    <!-- full-text notes -->
    <xsl:function name="oape:bibliography-full-text-to-note">
        <xsl:param name="tei_biblstruct"/>
        <!-- notes -->
        <bib:Memo rdf:about="{concat('#',$tei_biblstruct/descendant::tei:idno[@type = 'BibTeX'],'-text')}">
            <rdf:value>
                <!-- full-text that needs to be pulled out of the biblStruct or pulled from the URL of the article -->
            </rdf:value>
        </bib:Memo>
    </xsl:function>

    
</xsl:stylesheet>