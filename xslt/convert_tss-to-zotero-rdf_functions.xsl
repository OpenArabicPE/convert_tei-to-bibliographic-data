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
    
    <!-- debugging -->
    <xsl:template match="/">
        <rdf:RDF>
           <xsl:apply-templates select="descendant::tss:reference" mode="m_tss-to-zotero-rdf"/>
        </rdf:RDF>
    </xsl:template>
    
    <xsl:template match="tss:reference" mode="m_tss-to-zotero-rdf">
         <xsl:copy-of select="oape:bibliography-tss-to-zotero-rdf(.)"/>
    </xsl:template>
    
     <!-- fields not yet covered 
        + volume
        + issue 
        + pages
        + Date read
        + attachments
        + notes
        + some IDs: ISBN
        + series title
        + series number
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
        <xsl:variable name="v_reference-is-section" select="if($tss_reference/descendant::tss:characteristic[@name = 'articleTitle']!='') then(true()) else(false())"/>
        <!-- output -->
        <xsl:element name="bib:{$v_reference-type-bib}">
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
                            <xsl:when test="$v_reference-type-bib = 'BookSection'">
                                <bib:Book>
                                    <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'publicationTitle']" mode="m_tss-to-zotero-rdf"/>
                                </bib:Book>
                            </xsl:when>
                            <xsl:when test="$v_reference-type-bib = 'Article'">
                                <bib:Periodical>
                                    <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'volume']" mode="m_tss-to-zotero-rdf"/>
                <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'issue']" mode="m_tss-to-zotero-rdf"/>
                                    <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'publicationTitle']" mode="m_tss-to-zotero-rdf"/>
                                </bib:Periodical>
                            </xsl:when>
                            <!-- fallback: book -->
                            <xsl:otherwise>
                                <bib:Book>
                                    <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'publicationTitle']" mode="m_tss-to-zotero-rdf"/>
                                </bib:Book>
                            </xsl:otherwise>
                        </xsl:choose>
                    </dcterms:isPartOf>
                    <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'articleTitle']" mode="m_tss-to-zotero-rdf"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'publicationTitle']" mode="m_tss-to-zotero-rdf"/>
                </xsl:otherwise>
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
                <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'UUID']" mode="m_extra-field"/>
                <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'DOI']" mode="m_extra-field"/>
                <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Citation identifier']" mode="m_extra-field"/>
            </dc:description>
            <!-- language -->
             <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'language']" mode="m_tss-to-zotero-rdf"/>
            <!-- abstract -->
            <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'abstractText']" mode="m_tss-to-zotero-rdf"/>
        </xsl:element>
        <xsl:apply-templates select="$tss_reference/descendant::tss:note" mode="m_tss-to-zotero-rdf"/>
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
        <xsl:value-of select="concat('uuid',':',.,$v_new-line)"/>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'DOI']" mode="m_extra-field">
        <xsl:value-of select="concat('doi',':',.,$v_new-line)"/>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'Citation identifier']" mode="m_extra-field">
        <xsl:value-of select="concat('SenteCitationID',':',.,$v_new-line)"/>
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
    <xsl:template match="tss:characteristic[@name = ('publicationTitle', 'articleTitle')]" mode="m_tss-to-zotero-rdf">
        <dc:title><xsl:apply-templates/></dc:title>
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
        <prism:volume><xsl:value-of select="."/></prism:volume>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'issue']" mode="m_tss-to-zotero-rdf">
        <prism:number><xsl:value-of select="."/></prism:number>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'pages']" mode="m_tss-to-zotero-rdf">
        <bib:pages><xsl:value-of select="."/></bib:pages>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'language']" mode="m_tss-to-zotero-rdf">
        <z:language><xsl:value-of select="."/></z:language>
    </xsl:template>
    
    <xsl:template match="tss:characteristic[@name = 'abstractText']" mode="m_tss-to-zotero-rdf">
        <dcterms:abstract><xsl:apply-templates mode="m_mark-up"/></dcterms:abstract>
    </xsl:template>
    
    <!-- information for locating physical artefact -->
    <xsl:template match="tss:characteristic[@name = 'Repository']" mode="m_tss-to-zotero-rdf">
        <z:archive><xsl:value-of select="."/></z:archive>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'Standort']" mode="m_tss-to-zotero-rdf">
        <z:libraryCatalog><xsl:value-of select="."/></z:libraryCatalog>
    </xsl:template>
    
    <xsl:template match="tss:characteristic[@name = ('Signatur', 'call-num')]" mode="m_tss-to-zotero-rdf">
        <dc:subject>
           <dcterms:LCC><rdf:value><xsl:value-of select="."/></rdf:value></dcterms:LCC>
        </dc:subject>
    </xsl:template>
    
    <xsl:template match="tss:note" mode="m_tss-to-zotero-rdf">
        <bib:Memo>
            <!-- each note needs an ID -->
            <xsl:attribute name="rdf:about" select="concat('#',@xml:id)"/>
            <rdf:value>
                <xsl:copy-of select="oape:bibliography-tss-note-to-html(.)"/>
            </rdf:value>
        </bib:Memo>
    </xsl:template>
    
    <!-- HTML mark-up inside abstracts and notes? -->
    
    <!-- map reference types -->
    <xsl:variable name="v_reference-types">
        <tei:listNym>
            <tei:nym>
                <tei:form n="tss">Archival Book Chapter</tei:form>
                <tei:form n="zotero">bookSection</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib">BookSection</tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Archival File</tei:form>
                <tei:form n="zotero"></tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib"></tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Archival Journal Entry</tei:form>
                <tei:form n="zotero"></tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib"></tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Archival Letter</tei:form>
                <tei:form n="zotero">letter</tei:form>
                <tei:form n="marcgt">letter</tei:form>
                <tei:form n="bib">Letter</tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Archival Material</tei:form>
                <tei:form n="zotero"></tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib"></tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Archival Periodical</tei:form>
                <tei:form n="zotero"></tei:form>
                <tei:form n="marcgt">periodical</tei:form>
                <tei:form n="bib"></tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Archival Periodical Article</tei:form>
                <tei:form n="zotero">magazineArticle</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib">Article</tei:form>
                <tei:form n="biblatex">article</tei:form>
                <tei:form n="csl">article-magazine</tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Bill</tei:form>
                <tei:form n="zotero">Bill</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib"></tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Book</tei:form>
                <tei:form n="zotero">book</tei:form>
                <tei:form n="marcgt">book</tei:form>
                <tei:form n="bib">Book</tei:form>
                <tei:form n="biblatex">mvbook</tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Book Chapter</tei:form>
                <tei:form n="zotero">bookSection</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib">BookSection</tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Computer Software</tei:form>
                <tei:form n="zotero">Computer Programme</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib"></tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Edited Book</tei:form>
                <tei:form n="zotero">book</tei:form>
                <tei:form n="marcgt">book</tei:form>
                <tei:form n="bib">Book</tei:form>
                <tei:form n="biblatex">mvbook</tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Electronic Citation</tei:form>
                <tei:form n="zotero"></tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib"></tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Journal Article</tei:form>
                <tei:form n="zotero">Journal Article</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib">Article</tei:form>
                <tei:form n="biblatex">article</tei:form>
                <tei:form n="csl">article-journal</tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Manuscript</tei:form>
                <tei:form n="zotero"></tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib"></tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Maps</tei:form>
                <tei:form n="zotero">Map</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib"></tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Motion Picture</tei:form>
                <tei:form n="zotero"></tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib"></tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Newspaper Article</tei:form>
                <tei:form n="zotero">Newspaper Article</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib">Article</tei:form>
                <tei:form n="biblatex">article</tei:form>
                <tei:form n="csl">article-newspaper</tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Other</tei:form>
                <tei:form n="zotero"></tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib"></tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Photograph</tei:form>
                <tei:form n="zotero"></tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib"></tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Web Page</tei:form>
                <tei:form n="zotero">Web Page</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib"></tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
        </tei:listNym>
    </xsl:variable>
    
</xsl:stylesheet>