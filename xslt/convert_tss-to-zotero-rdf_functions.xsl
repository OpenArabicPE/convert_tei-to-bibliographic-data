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
  xmlns:tss="http://www.thirdstreetsoftware.com/SenteXML-1.0" xmlns:tei="http://www.tei-c.org/ns/1.0" 
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:prism="http://prismstandard.org/namespaces/1.2/basic/"
  xmlns:oape="https://openarabicpe.github.io/ns"
    version="3.0">
    
    <xsl:output method="xml" indent="yes" omit-xml-declaration="no" encoding="UTF-8"/>
    
        <!-- date conversion functions -->
<!--    <xsl:include href="https://tillgrallert.github.io/xslt-calendar-conversion/functions/date-functions.xsl"/>-->
     <xsl:include href="../../../xslt-calendar-conversion/functions/date-functions.xsl"/> 
    <xsl:include href="convert_tss_functions.xsl"/>
    <xsl:variable name="v_new-line" select="'&#x0A;'"/>
    <xsl:variable name="v_separator-key-value" select="': '"/>
    <xsl:variable name="v_cite-key-whitespace-replacement" select="'+'"/>
    
    <!-- to do
        - the abstract field is correctly mapped but it should probably be replicated as a note with the tag abstract
        - due to the dependence of fields on the item type in Zotero, everything should also be replicated to the extra field.
        - a lot of information should also be mapped to tags, to make use of the tag cloud (and set of the dearly missing browsing feature)
        - due to Sente's file naming restrictions, I had to use the volume field for issue numbers and vice versa. this should be fixed.
    -->
    
     <!-- fields not yet covered 
        + Date read
        + Original publication year
        + attachments
        + some IDs: ISBN
    -->
    
    <!-- undecided mappings:
        + Archival File -> manuscript
        + Archival Journal Entry
        + Archival Material -> manuscript
        + Archival Periodical
        + Photo
    -->
    
    <xsl:function name="oape:bibliography-tss-to-zotero-rdf">
        <xsl:param name="tss_reference"/>
        <!-- check reference type, since the first child after the root depends on it -->
        <xsl:variable name="v_reference-type">
            <xsl:variable name="v_temp" select="lower-case($tss_reference/tss:publicationType/@name)"/>
            <xsl:choose>
                <xsl:when test="$v_reference-types/descendant::tei:form[@n = 'tss'][lower-case(.) = $v_temp]">
                    <xsl:copy-of select="$v_reference-types/descendant::tei:form[@n = 'tss'][lower-case(.) = $v_temp]/parent::tei:nym"/>
                </xsl:when>
                <!-- fallback: -->
                <xsl:otherwise>
                    <xsl:message terminate="yes">
                        <xsl:text>reference type not found</xsl:text>
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_reference-type-bib">
            <xsl:choose>
                    <xsl:when test="$v_reference-type/tei:nym/tei:form[@n = 'bib']!=''">
                        <xsl:value-of select="$v_reference-type/tei:nym/tei:form[@n = 'bib']"/>
                    </xsl:when>
                    <!-- fallback: must be a valid item type for import into Zotero -->
                    <xsl:otherwise>
                        <xsl:text>Book</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_reference-type-zotero">
            <xsl:choose>
                    <xsl:when test="$v_reference-type/tei:nym/tei:form[@n = 'zotero']!=''">
                        <xsl:value-of select="$v_reference-type/tei:nym/tei:form[@n = 'zotero']"/>
                    </xsl:when>
                    <!-- fallback: must be a valid item type for import into Zotero -->
                    <xsl:otherwise>
                        <xsl:text>book</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_reference-type-sente" select="$v_reference-type/tei:nym/tei:form[@n = 'tss']"/>
        <xsl:variable name="v_reference-is-section" select="if($tss_reference/descendant::tss:characteristic[@name = 'articleTitle'] != '') then(true()) else(false())"/>
        <xsl:variable name="v_reference-is-part-of-series" select="if($tss_reference/descendant::tss:characteristic[@name = 'Series'] != '') then(true()) else(false())"/>
        <xsl:variable name="v_series">
            <dcterms:isPartOf>
                    <bib:Series>
                        <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Series']" mode="m_tss-to-zotero-rdf"/>
                        <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Series number']" mode="m_tss-to-zotero-rdf"/>
                    </bib:Series>
                </dcterms:isPartOf>
        </xsl:variable>
        <!-- output -->
        <xsl:element name="bib:{$v_reference-type-bib}">
            <!-- add an ID -->
            <xsl:attribute name="rdf:about" select="concat('#',$tss_reference/descendant::tss:characteristic[@name = 'UUID'])"/>
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
                                    <xsl:if test="$v_reference-is-part-of-series = true()">
                                        <xsl:copy-of select="$v_series"/>
                                    </xsl:if>
                                    <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'publicationTitle']" mode="m_tss-to-zotero-rdf"/>
                                </bib:Book>
                            </xsl:when>
                            <!-- periodical articles -->
                            <xsl:when test="$v_reference-type-bib = 'Article'">
                                <bib:Periodical>
                                    <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'volume']" mode="m_tss-to-zotero-rdf"/>
                <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'issue']" mode="m_tss-to-zotero-rdf"/>
                                    <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'publicationTitle']" mode="m_tss-to-zotero-rdf"/>
                                </bib:Periodical>
                            </xsl:when>
                            <!-- maps: it seems that the articleTitle should be mapped to Series -->
                            <xsl:when test="$v_reference-type-zotero = 'map'"/>
                            <!-- fallback: book -->
                            <xsl:otherwise>
                                <bib:Book>
                                    <!-- check if reference is part of a series -->
                                    <xsl:if test="$v_reference-is-part-of-series = true()">
                                        <xsl:copy-of select="$v_series"/>
                                    </xsl:if>
                                    <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'publicationTitle']" mode="m_tss-to-zotero-rdf"/>
                                </bib:Book>
                            </xsl:otherwise>
                        </xsl:choose>
                    </dcterms:isPartOf>
                    <!-- check if an item is part of a series -->
                    <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'articleTitle']" mode="m_tss-to-zotero-rdf"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- check if reference is part of a series -->
                    <xsl:if test="$v_reference-is-part-of-series = true()">
                        <xsl:copy-of select="$v_series"/>
                    </xsl:if>
                    <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'publicationTitle']" mode="m_tss-to-zotero-rdf"/>
                </xsl:otherwise>
            </xsl:choose>
            <!-- short titles -->
            <xsl:choose>
                <xsl:when test="$tss_reference/descendant::tss:characteristic[@name = 'Short Titel']">
                    <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Short Titel']" mode="m_tss-to-zotero-rdf"/>
                </xsl:when>
                <xsl:when test="$tss_reference/descendant::tss:characteristic[@name = 'Shortened title']">
                    <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Shortened title']" mode="m_tss-to-zotero-rdf"/>
                </xsl:when>
            </xsl:choose>
            <!-- contributors: authors, editors etc. -->
            <xsl:apply-templates select="$tss_reference/descendant::tss:authors" mode="m_tss-to-zotero-rdf"/>
            <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Recipient']" mode="m_tss-to-zotero-rdf"/>
            <!-- publisher: name, location -->
        <xsl:copy-of select="oape:bibliography-tss-to-zotero-rdf-publisher($tss_reference)"/>
            <!-- link to notes -->
            <xsl:for-each select="$tss_reference/descendant::tss:note">
                <dcterms:isReferencedBy rdf:resource="{concat('#',@xml:id)}"/>
            </xsl:for-each>
            <xsl:if test="$tss_reference/descendant::tss:characteristic[@name = 'abstractText'] !=''">
                <dcterms:isReferencedBy rdf:resource="{concat('#',$tss_reference/descendant::tss:characteristic[@name = 'UUID'],'-abstract')}"/>
            </xsl:if>
        <!-- tags, keywords etc. -->
        <xsl:apply-templates select="$tss_reference/descendant::tss:keyword" mode="m_tss-to-zotero-rdf"/>
        <!-- URLs -->
        <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'URL']" mode="m_tss-to-zotero-rdf"/>
            <!-- Identitifiers -->
            <!-- edition -->
            <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Edition']" mode="m_tss-to-zotero-rdf"/>
            <!-- volume, issue: depends on work not being a chapter or article -->
            <xsl:if test="$v_reference-is-section = false()">
                <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'volume']" mode="m_tss-to-zotero-rdf"/>
                <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'issue']" mode="m_tss-to-zotero-rdf"/>
            </xsl:if>
                <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'pages']" mode="m_tss-to-zotero-rdf"/>
            <!-- dates -->
            <xsl:apply-templates select="$tss_reference/descendant::tss:date[@type = 'Publication']" mode="m_tss-to-zotero-rdf"/>
            <!-- Archive, repository -->
            <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Repository']" mode="m_tss-to-zotero-rdf"/>
            <!-- Library catalogue, Standort -->
            <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Standort']" mode="m_tss-to-zotero-rdf"/>
            <!-- call number -->
            <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Signatur']" mode="m_tss-to-zotero-rdf"/>
            <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'call-num']" mode="m_tss-to-zotero-rdf"/>
            <!-- extra field: map all sorts of custom fields -->
            <dc:description>
                <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Citation identifier']" mode="m_extra-field"/>
                <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Date Rumi']" mode="m_extra-field"/>
                <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Date Hijri']" mode="m_extra-field"/>
                <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'DOI']" mode="m_extra-field"/>
                <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'OCLCID']" mode="m_extra-field"/>
                <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'issue']" mode="m_extra-field"/>
                <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'UUID']" mode="m_extra-field"/>
                <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'volume']" mode="m_extra-field"/>
            </dc:description>
            <!-- language -->
             <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'language']" mode="m_tss-to-zotero-rdf"/>
            <!-- abstract -->
            <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'abstractText']" mode="m_tss-to-zotero-rdf"/>
            <!-- add <z:type> for archival material -->
            <xsl:if test="$v_reference-type-sente = 'Archival File'">
                <xsl:element name="z:type">
                    <xsl:text>file</xsl:text>
                </xsl:element>
            </xsl:if>
        </xsl:element>
        <!-- notes -->
        <xsl:apply-templates select="$tss_reference/descendant::tss:note" mode="m_tss-to-zotero-rdf"/>
        <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'abstractText']" mode="m_construct-note"/>
    </xsl:function>
    
    <xsl:function name="oape:bibliography-tss-to-zotero-rdf-publisher">
        <!-- expects tss:reference -->
        <xsl:param name="tss_reference"/>
    <dc:publisher>
            <foaf:Organization>
                <vcard:adr>
                    <vcard:Address>
                       <vcard:locality><xsl:value-of select="$tss_reference/descendant::tss:characteristic[@name = 'publicationCountry']"/></vcard:locality>
                    </vcard:Address>
                </vcard:adr>
                <foaf:name><xsl:value-of select="$tss_reference/descendant::tss:characteristic[@name = 'publisher']"/></foaf:name>
            </foaf:Organization>
        </dc:publisher>
    </xsl:function>
    
    <!-- extra field -->
    <xsl:template match="tss:characteristic[@name = 'UUID']" mode="m_extra-field">
        <xsl:value-of select="concat('uuid', $v_separator-key-value,.,$v_new-line)"/>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'DOI']" mode="m_extra-field">
        <xsl:if test=".!=''">
            <xsl:value-of select="concat('doi', $v_separator-key-value,.,$v_new-line)"/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'OCLCID']" mode="m_extra-field">
        <xsl:if test=".!=''">
            <xsl:value-of select="concat('oclc', $v_separator-key-value,.,$v_new-line)"/>
        </xsl:if>
    </xsl:template>
    <!-- if used with Better BibTeX, one can set the citation key in the extra field -->
    <xsl:template match="tss:characteristic[@name = 'Citation identifier']" mode="m_extra-field">
        <xsl:if test=".!=''">
            <xsl:value-of select="concat('Citation Key', $v_separator-key-value, replace(.,'\s+', $v_cite-key-whitespace-replacement),$v_new-line)"/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'Date Rumi']" mode="m_extra-field">
        <!-- try to establish the calendar -->
        <xsl:variable name="v_calendar-guessed" select="oape:date-establish-calendar(.)"/>
        <xsl:variable name="v_calendar">
            <xsl:choose>
                <xsl:when test="$v_calendar-guessed != ''">
                    <xsl:value-of select="$v_calendar-guessed"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>#cal_julian</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_date-normalised" select="oape:date-normalise-input(.,'ar-Latn-x-sente', $v_calendar)"/>
        <!--<xsl:message>
            <xsl:value-of select="$v_date-normalised"/>
        </xsl:message>-->
        <!-- content -->
        <xsl:text>date_</xsl:text>
        <xsl:choose>
            <xsl:when test="$v_calendar = '#cal_julian'">
                <xsl:text>rumi</xsl:text>
            </xsl:when>
            <xsl:when test="$v_calendar = '#cal_ottomanfiscal'">
                <xsl:text>mali</xsl:text>
            </xsl:when>
        </xsl:choose>
        <xsl:value-of select="concat($v_separator-key-value, $v_date-normalised, $v_new-line)"/>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'Date Hijri']" mode="m_extra-field">
        <xsl:variable name="v_date-normalised" select="oape:date-normalise-input(.,'ar-Latn-x-sente','#cal_islamic')"/>
        <xsl:text>date_hijri</xsl:text>
        <xsl:value-of select="concat($v_separator-key-value, $v_date-normalised, $v_new-line)"/>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'issue']" mode="m_extra-field">
        <xsl:if test=".!=''">
            <xsl:choose>
                 <xsl:when test="oape:bibliography-tss-switch-volume-and-issue(ancestor::tss:reference) = false()">
                     <xsl:text>issue</xsl:text>
                 </xsl:when>
                 <xsl:otherwise>
                     <xsl:text>volume</xsl:text>
                 </xsl:otherwise>
             </xsl:choose>
            <xsl:value-of select="concat($v_separator-key-value,.,$v_new-line)"/>
        </xsl:if>
    </xsl:template>
     <xsl:template match="tss:characteristic[@name = 'volume']" mode="m_extra-field">
         <xsl:if test=".!=''">
             <xsl:choose>
                 <xsl:when test="oape:bibliography-tss-switch-volume-and-issue(ancestor::tss:reference) = true()">
                     <xsl:text>issue</xsl:text>
                 </xsl:when>
                 <xsl:otherwise>
                     <xsl:text>volume</xsl:text>
                 </xsl:otherwise>
             </xsl:choose>
             <xsl:value-of select="concat($v_separator-key-value,.,$v_new-line)"/>
         </xsl:if>
    </xsl:template>
    
    <!-- contributors -->
    <xsl:template match="tss:authors" mode="m_tss-to-zotero-rdf">
        <!-- is the sequence of roles relevant?! -->
            <xsl:if test="tss:author/@role = 'Author'">
                <bib:authors>
                    <rdf:Seq>
                            <xsl:apply-templates select="tss:author[@role = 'Author']" mode="m_tss-to-zotero-rdf"/>
                    </rdf:Seq>
                </bib:authors>
            </xsl:if>
            <xsl:if test="tss:author/@role = 'Editor'">
                <bib:editors>
                    <rdf:Seq>
                            <xsl:apply-templates select="tss:author[@role = 'Editor']" mode="m_tss-to-zotero-rdf"/>
                    </rdf:Seq>
                </bib:editors>
            </xsl:if>
            <xsl:if test="tss:author/@role = 'Translator'">
                <z:translators>
                    <rdf:Seq>
                            <xsl:apply-templates select="tss:author[@role = 'Translator']" mode="m_tss-to-zotero-rdf"/>
                    </rdf:Seq>
                </z:translators>
            </xsl:if>
        <xsl:if test="tss:author/@role = 'Contributor'">
                <bib:contributors>
                    <rdf:Seq>
                            <xsl:apply-templates select="tss:author[@role = 'Contributor']" mode="m_tss-to-zotero-rdf"/>
                    </rdf:Seq>
                </bib:contributors>
            </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'Recipient']" mode="m_tss-to-zotero-rdf">
        <z:recipients>
                    <rdf:Seq>
                        <rdf:li>
                            <foaf:Person>
                                <foaf:surname><xsl:apply-templates/></foaf:surname>
                            </foaf:Person>
                        </rdf:li>
                    </rdf:Seq>
                </z:recipients>
    </xsl:template>
    
    <xsl:template match="tss:author" mode="m_tss-to-zotero-rdf">
        <rdf:li>
        <foaf:Person>
            <xsl:apply-templates select="tss:surname" mode="m_tss-to-zotero-rdf"/>
            <xsl:apply-templates select="tss:forenames" mode="m_tss-to-zotero-rdf"/>
        </foaf:Person>
        </rdf:li>
    </xsl:template>
    <xsl:template match="tss:surname" mode="m_tss-to-zotero-rdf">
        <foaf:surname><xsl:apply-templates/></foaf:surname>
    </xsl:template>
    <xsl:template match="tss:forenames" mode="m_tss-to-zotero-rdf">
        <foaf:givenName><xsl:apply-templates/></foaf:givenName>
    </xsl:template>
    <xsl:template match="tss:keyword" mode="m_tss-to-zotero-rdf">
        <dc:subject>
            <xsl:apply-templates/>
        </dc:subject>
    </xsl:template>
    
    <!-- titles -->
    <xsl:template match="tss:characteristic[@name = ('publicationTitle', 'articleTitle', 'Series')]" mode="m_tss-to-zotero-rdf">
        <xsl:if test=".!=''">
            <dc:title><xsl:apply-templates/></dc:title>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = ('Short Titel', 'Shortened title')]" mode="m_tss-to-zotero-rdf">
        <xsl:if test=".!=''">
            <z:shortTitle><xsl:apply-templates/></z:shortTitle>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = ('Series number')]" mode="m_tss-to-zotero-rdf">
        <xsl:if test=".!=''">
            <dc:identifier><xsl:apply-templates/></dc:identifier>
        </xsl:if>
    </xsl:template>
       <!-- transform dates -->
    <xsl:template match="tss:date" mode="m_tss-to-zotero-rdf">
        <xsl:variable name="v_year" select="if(@year!='') then(format-number(@year,'0000')) else()"/>
        <xsl:variable name="v_month" select="if(@month!='') then(format-number(@month,'00')) else('xx')"/>
        <xsl:variable name="v_day" select="if(@day!='') then(format-number(@day,'00')) else('xx')"/>
        <dc:date>
            <xsl:value-of select="if(@year!='') then(format-number(@year,'0000')) else()"/>
            <xsl:if test="@month!=''">
                <xsl:text>-</xsl:text>
                <xsl:value-of select="format-number(@month,'00')"/>
            </xsl:if>
            <xsl:if test="@day!=''">
                <xsl:text>-</xsl:text>
                <xsl:value-of select="format-number(@day,'00')"/>
            </xsl:if>
        </dc:date>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'URL']" mode="m_tss-to-zotero-rdf">
        <dc:identifier>
            <dcterms:URI>
                <rdf:value><xsl:value-of select="."/></rdf:value>
            </dcterms:URI>
        </dc:identifier>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'Edition']" mode="m_tss-to-zotero-rdf">
        <prism:edition><xsl:value-of select="."/></prism:edition>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'volume']" mode="m_tss-to-zotero-rdf">
        <xsl:if test=".!=''">
            <xsl:choose>
                 <xsl:when test="oape:bibliography-tss-switch-volume-and-issue(ancestor::tss:reference) = true()">
                    <prism:number><xsl:value-of select="."/></prism:number>
                 </xsl:when>
                 <xsl:otherwise>
                     <prism:volume><xsl:value-of select="."/></prism:volume>
                 </xsl:otherwise>
             </xsl:choose>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'issue']" mode="m_tss-to-zotero-rdf">
        <xsl:if test=".!=''">
            <xsl:choose>
                 <xsl:when test="oape:bibliography-tss-switch-volume-and-issue(ancestor::tss:reference) = false()">
                    <prism:number><xsl:value-of select="."/></prism:number>
                 </xsl:when>
                 <xsl:otherwise>
                     <prism:volume><xsl:value-of select="."/></prism:volume>
                 </xsl:otherwise>
             </xsl:choose>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'pages']" mode="m_tss-to-zotero-rdf">
        <xsl:if test=".!=''">
            <bib:pages><xsl:value-of select="."/></bib:pages>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'language']" mode="m_tss-to-zotero-rdf">
        <xsl:if test=".!=''">
            <z:language><xsl:value-of select="."/></z:language>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="tss:characteristic[@name = 'abstractText']" mode="m_tss-to-zotero-rdf">
        <xsl:if test=".!=''">
            <dcterms:abstract>
                <xsl:apply-templates/>
<!--                <xsl:apply-templates mode="m_mark-up"/>-->
            </dcterms:abstract>
        </xsl:if>
    </xsl:template>
    
    <!-- information for locating physical artefact -->
    <xsl:template match="tss:characteristic[@name = 'Repository']" mode="m_tss-to-zotero-rdf">
        <xsl:if test=".!=''">
            <z:archive><xsl:value-of select="."/></z:archive>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'Standort']" mode="m_tss-to-zotero-rdf">
        <xsl:if test=".!=''">
            <z:libraryCatalog><xsl:value-of select="."/></z:libraryCatalog>
        </xsl:if>
    </xsl:template>
    
    <!-- call-numbers -->
    <xsl:template match="tss:characteristic[@name = ('Signatur', 'call-num')]" mode="m_tss-to-zotero-rdf">
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
    
    <!-- notes -->
    <xsl:template match="tss:note" mode="m_tss-to-zotero-rdf">
        <bib:Memo>
            <!-- each note needs an ID -->
            <xsl:attribute name="rdf:about" select="concat('#',@xml:id)"/>
            <rdf:value>
                <xsl:copy-of select="oape:bibliography-tss-note-to-html(.)"/>
            </rdf:value>
        </bib:Memo>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'abstractText']" mode="m_construct-note">
        <xsl:if test=".!=''">
            <bib:Memo>
            <!-- each note needs an ID: use UUID -->
                <xsl:attribute name="rdf:about" select="concat('#',parent::tss:characteristics/tss:characteristic[@name = 'UUID'],'-abstract')"/>
                <rdf:value>
                    <![CDATA[<h1>]]><xsl:text># abstract</xsl:text><![CDATA[</h1>]]>
                    <xsl:apply-templates mode="m_mark-up"/>
                </rdf:value>
            </bib:Memo>
        </xsl:if>
    </xsl:template>
    
    <!-- HTML mark-up inside abstracts and notes? -->
    <xsl:template match="html:*" mode="m_tss-to-zotero-rdf"/>
    <xsl:template match="html:*" mode="m_mark-up">
         <xsl:value-of select="'&lt;'" disable-output-escaping="no"/>
         <xsl:value-of select="replace(name(),'html:','')"/>
        <xsl:value-of select="'&gt;'" disable-output-escaping="no"/>
        <xsl:apply-templates mode="m_mark-up"/>
        <xsl:value-of select="'&lt;/'" disable-output-escaping="no"/>
         <xsl:value-of select="replace(name(),'html:','')"/>
        <xsl:value-of select="'&gt;'" disable-output-escaping="no"/>
    </xsl:template>
    
</xsl:stylesheet>