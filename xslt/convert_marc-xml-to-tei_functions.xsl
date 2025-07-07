<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <!-- This stylesheet takes MARC21 records in XML serialisation as input and generates TEI XML as output -->
    <!-- documentation of the MARC21 field codes can be found here: https://marc21.ca/M21/MARC-Field-Codes.html -->
    <!-- to do:
        - urgent: establish the level of a title in monogr
        - there is a difference between record and item level but they appear to be mixed in the MARC XML
        - figure out IDs from the AUB source
            + according to https://libcat.aub.edu.lb there are
            + [x] Call Number
                - the call number "Mic-NA:000452" from the MARC XML needs to be converted to "Mic-NA:0452" for searching the catalogue
            + Class Number
            + NLM Call Number
            + Standard Number
            + [x] record number: it seems that one has to reliably strip the last digit from the number found in the MARC XML
                - https://libcat.aub.edu.lb/record=b1281806
                - <marc:datafield ind1="0" ind2="8" tag="776"><marc:subfield code="w">(LEAUB)b12818069</marc:subfield></marc:datafield>
                - <marc:datafield ind1=" " ind2=" " tag="907">
            <marc:subfield code="a">.b12818069</marc:subfield></marc:datafield>
         - ZDB
            + use field 515 for establishing frequency
            + [x] decomposed UTF-8: changed into composed UTF-8 upon writing the output file
        - HathiTrust
            + [x] uses a LOT of non-nummeric tags, which supposedly are custom extensions of MARC
            + [x] uses field 974 for holding information on individual items/ copies
    -->
    <!--    <xsl:import href="parameters.xsl"/>-->
    <xsl:import href="functions.xsl"/>
    <xsl:import href="../../authority-files/xslt/convert_isil-rdf-to-tei_functions.xsl"/>
    <xsl:import href="../../authority-files/xslt/functions.xsl"/>
    <!--<xsl:param name="p_koha-catalogue" select="'https://librarycatalog.usj.edu.lb/cgi-bin/koha/opac-detail.pl?biblionumber='"/>-->
    <xsl:param name="p_koha-url-base" select="'https://librarycatalog.usj.edu.lb/cgi-bin/'"/>
    <xsl:variable name="v_koha-url-record-web" select="concat($p_koha-url-base, 'koha/opac-detail.pl?biblionumber=')"/>
    <xsl:variable name="v_koha-url-record-marcxml" select="concat($p_koha-url-base,'koha/opac-export.pl?op=export&amp;format=marcxml&amp;bib=')"/>
    <xsl:param name="p_koha-org-id" select="'oape:org:10'"/>
    <!-- these parameters are placeholders until I established a way of pulling language information from the source -->
    <xsl:param name="p_lang-1" select="'ar'"/>
    <xsl:param name="p_lang-2" select="'ar-Latn-x-ijmes'"/>
    <!-- individual records: pull approach -->
    <xsl:template match="marc:record" mode="m_marc-to-tei">
        <xsl:variable name="v_analytic">
            <xsl:choose>
                <xsl:when test="marc:datafield[@tag = '773']/marc:subfield[@code = ('i', 'a', 't')]">
                    <xsl:value-of select="true()"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="false()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!--<xsl:variable name="v_id-record">
            <xsl:apply-templates select="marc:datafield[@tag = ('016')][@ind1 = '7']/marc:subfield[@code = 'a']"/>
        </xsl:variable>-->
        <xsl:variable name="v_id-record">
            <xsl:copy-of select="oape:query-marcx(., 'id')"/>
        </xsl:variable>
        <xsl:variable name="v_catalogue" select="oape:query-marcx(., 'catalogue')"/>
        <xsl:variable name="v_url-catalogue" select="oape:query-marcx(., 'url_record-in-catalogue')"/>
        <!-- variable to potentially pull a record from another URL based on the input record -->
        <xsl:variable name="v_record">
            <xsl:choose>
                <!-- this test will cause to load ZDB data for Hathitrust data sets: $v_id-record/tei:idno/@type = 'zdb'  -->
                <xsl:when test="$v_catalogue = 'zdb'">
                    <xsl:variable name="v_url-record" select="concat($v_url-server-zdb-ld, $v_id-record/tei:idno[@type = 'zdb'][1], '.plus-1.mrcx')"/>
                    <xsl:copy-of select="doc($v_url-record)/descendant-or-self::marc:record"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_biblStruct">
            <xsl:element name="biblStruct">
                <!-- frequency -->
                <xsl:apply-templates select="$v_record//marc:datafield[@tag = '310']/marc:subfield"/>
                <!-- @type, @subtype -->
                <xsl:apply-templates select="$v_record//marc:datafield[@tag = '655'][@ind2 = '7']/marc:subfield"/>
                <xsl:if test="$v_analytic = true()">
                    <xsl:element name="analytic">
                        <!-- titles: 245, 246. 246 can contain a plethora of alternative, related etc. titles and should not be used at this stage -->
                        <xsl:apply-templates select="$v_record//marc:datafield[@tag = ('245')]/marc:subfield[@code = ('a', 'b')]"/>
                        <!-- main contributors -->
                        <xsl:apply-templates select="$v_record//marc:datafield[@tag = ('100', '101')]/marc:subfield[@code = '4']"/>
                        <!-- text lang -->
                        <xsl:apply-templates select="$v_record//marc:datafield[@tag = '041']/marc:subfield[@code = 'a'][1]"/>
                        <!-- IDs -->
                        <xsl:apply-templates select="$v_record//marc:datafield[@tag = ('024')]/marc:subfield"/>
                    </xsl:element>
                </xsl:if>
                <xsl:element name="monogr">
                    <xsl:if test="$v_analytic = true()">
                        <xsl:apply-templates select="$v_record//marc:datafield[@tag = '773']/marc:subfield[@code = ('a', 't')]"/>
                    </xsl:if>
                    <xsl:if test="$v_analytic = false()">
                        <!-- titles: 245, 246. 246 can contain a plethora of alternative, related etc. titles and should not be used at this stage -->
                        <xsl:apply-templates select="$v_record//marc:datafield[@tag = ('245')]/marc:subfield[@code = ('a', 'b')]"/>
                        <xsl:apply-templates select="$v_record//marc:datafield[@tag = ('246')][@ind1 = '3'][@ind2 = '3']/marc:subfield[@code = 'a']"/>
                    </xsl:if>
                    <!-- IDs -->
                    <xsl:apply-templates select="$v_record//marc:datafield[@tag = ('010', '019', '020', '022', '035', '856')]/marc:subfield"/>
                    <xsl:apply-templates select="$v_record//marc:datafield[@tag = ('084')]/marc:subfield[@code = 'a']"/>
                    <xsl:apply-templates select="$v_record//marc:datafield[@tag = ('016')][@ind1 = '7']/marc:subfield[@code = 'a']"/>
                    <!-- USJ/ KOHA -->
                    <xsl:apply-templates select="$v_record//marc:datafield[@tag = ('090')]/marc:subfield[@code = 'b']"/>
                    <xsl:apply-templates select="$v_record//marc:datafield[@tag = ('999')]/marc:subfield[@code = 'c']"/>
                    <!-- Hathi: non-nummeric Marc tags -->
                    <xsl:apply-templates select="$v_record//marc:datafield[@tag = ('CID')]/marc:subfield[@code = 'a']"/>
                    <!-- NLoI -->
                    <xsl:apply-templates select="$v_record//marc:datafield[@tag = 'AVA']/marc:subfield[@code = '0']"/>
                    <!-- AUB record number at 776? Nope! this refers to related publications -->
                    <!--<xsl:apply-templates select="$v_record//marc:datafield[@tag = '776'][@ind2 = '8']/marc:subfield[@code = 'w']"/>-->
                    <xsl:if test="$v_analytic = false()">
                        <xsl:apply-templates select="$v_record//marc:datafield[@tag = ('024')]/marc:subfield"/>
                    </xsl:if>
                    <xsl:if test="$v_analytic = false()">
                        <!-- main contributors: editors or authors -->
                        <xsl:apply-templates select="$v_record//marc:datafield[@tag = ('100', '101')]/marc:subfield[@code = '4']"/>
                        <xsl:apply-templates select="$v_record//marc:datafield[@tag = ('100', '101')]/marc:subfield[@code = 'a']"/>
                        <xsl:choose>
                            <xsl:when test="$v_record//marc:datafield[@tag = '700']/marc:subfield[@code = '4']">
                                <xsl:apply-templates select="$v_record//marc:datafield[@tag = '700']/marc:subfield[@code = '4']"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates select="$v_record//marc:datafield[@tag = '700']/marc:subfield[@code = 'a']"/>
                            </xsl:otherwise>
                        </xsl:choose>
                        <!-- text lang -->
                        <xsl:choose>
                            <xsl:when test="$v_record//marc:datafield[@tag = '041']/marc:subfield[@code = 'a']">
                                <xsl:apply-templates select="$v_record//marc:datafield[@tag = '041']/marc:subfield[@code = 'a'][1]"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:element name="textLang">
                                    <xsl:attribute name="mainLang">
                                        <xsl:value-of select="oape:string-convert-lang-codes(substring($v_record//marc:controlfield[@tag = '008'], 36, 3), 'iso639-2', 'bcp47')"/>
                                    </xsl:attribute>
                                </xsl:element>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:if>
                    <!-- editors: 264 shouldn't have been used for the editor -->
                    <!--<xsl:apply-templates select="$v_record//marc:datafield[@tag = '264']/marc:subfield[@code = 'b']"/>-->
                    <!-- imprint -->
                    <xsl:element name="imprint">
                        <!-- full imprint in one field -->
                        <!-- Hathi uses 260 for publication place -->
                        <!-- problem: the publisher might be the editor in our understanding -->
                        <xsl:apply-templates select="$v_record//marc:datafield[@tag = ('260', '264')]/marc:subfield"/>
                        <xsl:if test="$v_analytic = true()">
                            <xsl:apply-templates select="$v_record//marc:datafield[@tag = '773']/marc:subfield[@code = 'd']"/>
                        </xsl:if>
                        <!-- normalized dates -->
                        <xsl:apply-templates select="$v_record//marc:datafield[@tag = '363']/marc:subfield[@code = 'i']"/>
                    </xsl:element>
                    <!-- name/number of sections of a work (biblScope) -->
                    <xsl:apply-templates select="$v_record//marc:datafield[@tag = ('245', '246')]/marc:subfield[@code = ('n')]"/>
                    <xsl:apply-templates select="$v_record//marc:datafield[@tag = '936']/marc:subfield[@code = ('d', 'e', 'h')]"/>
                    <xsl:apply-templates select="$v_record//marc:datafield[@tag = '300']/marc:subfield[@code = ('a')]"/>
                </xsl:element>
                <!-- notes -->
                <!-- the infamous field 500: notes -->
                <xsl:apply-templates select="$v_record//marc:datafield[@tag = '500'][1]/marc:subfield"/>
                <!-- general holding information -->
                <!-- AUB holdings -->
                <xsl:apply-templates mode="m_notes" select="$v_record//marc:datafield[@tag = '866'][@ind2 = '1']/marc:subfield[@code = 'a']"/>
                <!-- holdings in ZDB record served over SRU: has been replaced -->
                <xsl:if test="$v_catalogue = 'zdb'">
                    <xsl:apply-templates mode="m_notes" select="$v_record//marc:datafield[@tag = '362'][@ind1 = '0']/marc:subfield[@code = 'a']"/>
                </xsl:if>
                <!-- KOHA / USJ -->
                <xsl:apply-templates mode="m_notes" select="$v_record//marc:datafield[@tag = '362']">
                    <xsl:with-param name="p_record" select="$v_record"/>
                    <xsl:with-param name="p_catalogue" select="$v_catalogue"/>
                    <xsl:with-param name="p_url-catalogue" select="$v_url-catalogue"/>
                </xsl:apply-templates>
                <!-- Hathi: holding information -->
                <!--<xsl:apply-templates mode="m_notes" select="$v_record//marc:datafield[@tag = 'HOL']">
                <xsl:with-param name="p_id-record" select="$v_id-record"/>
            </xsl:apply-templates>-->
                <!-- detailed holding information: one entry per physical or digital item -->
                <!-- ZDB holding information -->
                <xsl:apply-templates mode="m_notes" select="$v_record//marc:datafield[@tag = '924'][1]">
                    <xsl:with-param name="p_id-record" select="$v_id-record"/>
                </xsl:apply-templates>
                <!-- Hathi: digitised items -->
                <!-- USJ holding information: KOHA library systems -->
                <xsl:if test="$v_record//marc:datafield[@tag = ('974', '952')]">
                    <xsl:element name="note">
                        <xsl:attribute name="type" select="'holdings'"/>
                        <xsl:element name="list">
                            <xsl:choose>
                                <xsl:when test="$v_catalogue = 'koha'">
                                    <xsl:element name="item">
                                        <xsl:attribute name="source" select="$v_url-catalogue"/>
                                        <xsl:element name="label">
                                            <!-- one can retrieve information on the holding information based on 952$a -->
                                            <xsl:variable name="v_orgName">
                                                <!-- we currently only look for the first holding -->
                                                <xsl:apply-templates select="$v_record//marc:datafield[@tag = '952'][1]/marc:subfield[@code = 'a']"/>
                                            </xsl:variable>
                                            <xsl:variable name="v_org" select="oape:get-entity-from-authority-file($v_orgName//tei:orgName, $p_local-authority, $v_organizationography)"/>
                                            <!-- location -->
                                            <xsl:copy-of select="oape:query-org($v_org/self::tei:org, 'location-tei', 'en', $p_local-authority)"/>
                                            <xsl:text>, </xsl:text>
                                            <!-- institution -->
                                            <xsl:element name="orgName">
                                                <xsl:attribute name="ref" select="oape:query-organizationography($v_org//tei:orgName[1], $v_organizationography, $p_local-authority, 'tei-ref', '')"/>
                                                <xsl:value-of select="oape:query-org($v_org/self::tei:org, 'name', 'en', $p_local-authority)"/>
                                            </xsl:element>
                                        </xsl:element>
                                        <xsl:element name="listBibl">
                                            <xsl:apply-templates mode="m_notes" select="$v_record//marc:datafield[@tag = '952']"/>
                                        </xsl:element>
                                    </xsl:element>
                                </xsl:when>
                                <xsl:when test="$v_catalogue = 'hathi'">
                                    <!-- group by holding institution -->
                                    <xsl:for-each-group group-by="marc:subfield[@code = 'b']" select="$v_record//marc:datafield[@tag = '974']">
                                        <xsl:element name="item">
                                            <xsl:attribute name="source" select="$v_url-catalogue"/>
                                            <xsl:element name="label">
                                                <xsl:apply-templates select="current-group()[1]/marc:subfield[@code = 'b']"/>
                                            </xsl:element>
                                            <xsl:element name="listBibl">
                                                <xsl:attribute name="source" select="$v_url-catalogue"/>
                                                <!-- machine-readible holding information for each item -->
                                                <xsl:apply-templates mode="m_notes" select="current-group()"/>
                                            </xsl:element>
                                        </xsl:element>
                                    </xsl:for-each-group>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:message terminate="yes">
                                        <xsl:text>WARNING: could not establish the catalogue / library system for </xsl:text>
                                        <xsl:value-of select="$v_catalogue"/>
                                    </xsl:message>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:element>
                    </xsl:element>
                </xsl:if>
            </xsl:element>
        </xsl:variable>
        <xsl:apply-templates mode="m_postprocess" select="$v_biblStruct/descendant-or-self::tei:biblStruct"/>
    </xsl:template>
    <!-- one template to convert marc:subfields into TEI -->
    <xsl:template match="marc:subfield">
        <xsl:variable name="v_tag" select="parent::marc:datafield/@tag"/>
        <xsl:variable name="v_code" select="@code"/>
        <xsl:variable name="v_ind1" select="parent::marc:datafield/@ind1"/>
        <xsl:variable name="v_ind2" select="parent::marc:datafield/@ind2"/>
        <!-- text fields can have trailing punctuation, which should be removed -->
        <xsl:variable name="v_content">
            <xsl:value-of select="normalize-space(oape:strings_trim-punctuation-marks(normalize-unicode(., 'NFKC')))"/>
        </xsl:variable>
        <!-- languages: can potentially depend on local data or parameters
            - these should be the languages of the catalogue entry, NOT the described item
            - language information for the original item can be found in 041/a and 101/a 
            - language of cataloging is found in 040/b
            - if 041/1 is Arabic and 040/b is German, we can probably assume that all Latin-script titles conform to DMG  
        -->
        <xsl:variable name="v_lang-item">
            <xsl:choose>
                <xsl:when test="ancestor::marc:record/marc:datafield[@tag = '041']/marc:subfield[@code = 'a']">
                    <xsl:value-of select="oape:string-convert-lang-codes(ancestor::marc:record/marc:datafield[@tag = '041']/marc:subfield[@code = 'a'][1], 'iso639-2', 'bcp47')"/>
                </xsl:when>
                <!-- language code at 36 -->
                <xsl:when test="substring(ancestor::marc:record[1]/marc:controlfield[@tag = '008'], 36, 3) != '   '">
                    <xsl:value-of select="oape:string-convert-lang-codes(substring(ancestor::marc:record[1]/marc:controlfield[@tag = '008'], 36, 3), 'iso639-2', 'bcp47')"/>
                </xsl:when>
                <!-- fallback: undefined -->
                <xsl:otherwise>
                    <xsl:value-of select="'und'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_lang-catalogue">
            <xsl:choose>
                <xsl:when test="ancestor::marc:record/marc:datafield[@tag = '040']/marc:subfield[@code = 'b']">
                    <xsl:value-of select="oape:string-convert-lang-codes(ancestor::marc:record/marc:datafield[@tag = '040']/marc:subfield[@code = 'b'][1], 'iso639-2', 'bcp47')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'und'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_lang-entry">
            <xsl:choose>
                <xsl:when test="$v_lang-item = 'ar'">
                    <xsl:choose>
                        <xsl:when test="$v_lang-catalogue = 'de'">
                            <xsl:value-of select="'ar-Latn-x-dmg'"/>
                        </xsl:when>
                        <xsl:when test="$v_lang-catalogue = 'en'">
                            <xsl:value-of select="'ar-Latn-x-ijmes'"/>
                        </xsl:when>
                        <!-- 'und' is the most precise fallback, but one might want to change it to 'ar' for my use cases -->
                        <xsl:otherwise>
                            <xsl:value-of select="'und'"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$v_lang-item"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- transformation -->
        <xsl:choose>
            <!-- code "0": IDs from authority files -->
            <xsl:when test="$v_code = '0' and $v_tag = ('100', '689', '700')">
                <xsl:call-template name="t_normalize-authority-id">
                    <xsl:with-param name="p_input" select="$v_content"/>
                </xsl:call-template>
                <xsl:if test="following-sibling::marc:subfield[@code = '0']">
                    <xsl:text> </xsl:text>
                </xsl:if>
            </xsl:when>
            <!-- controlfield with tag 008 - FIXED-LENGTH DATA ELEMENTS -\- General information (NR)  -->
            <!-- IDs -->
            <!-- 016 - NATIONAL BIBLIOGRAPHIC AGENCY CONTROL NUMBER -->
            <xsl:when test="$v_tag = '016' and $v_ind1 = '7' and $v_code = 'a'">
                <xsl:variable name="v_auth-id" select="parent::marc:datafield/marc:subfield[@code = '2']"/>
                <xsl:variable name="v_auth">
                    <xsl:choose>
                        <xsl:when test="$v_auth-id = 'DE-600'">
                            <xsl:text>zdb</xsl:text>
                        </xsl:when>
                        <!-- even though   DE-101 is the GND, these IDs cannot be found in the GND catalogue-->
                        <xsl:otherwise>
                            <xsl:text>NA</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:if test="$v_auth != 'NA'">
                    <xsl:element name="idno">
                        <xsl:attribute name="type" select="$v_auth"/>
                        <xsl:value-of select="$v_content"/>
                    </xsl:element>
                </xsl:if>
            </xsl:when>
            <xsl:when test="$v_tag = ('010', '020', '022', '024') and $v_code = 'a'">
                <xsl:element name="idno">
                    <xsl:attribute name="type">
                        <xsl:choose>
                            <xsl:when test="$v_tag = '010'">
                                <xsl:text>LCCN</xsl:text>
                            </xsl:when>
                            <xsl:when test="$v_tag = '020'">
                                <xsl:text>ISBN</xsl:text>
                            </xsl:when>
                            <xsl:when test="$v_tag = '022'">
                                <xsl:text>ISSN</xsl:text>
                            </xsl:when>
                            <!--  -->
                            <xsl:when test="$v_tag = '024' and $v_ind1 = '7'">
                                <xsl:value-of select="parent::marc:datafield/marc:subfield[@code = '2']"/>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:attribute>
                    <xsl:value-of select="$v_content"/>
                </xsl:element>
            </xsl:when>
            <xsl:when test="($v_tag = ('019', '035') and $v_code = 'a') or ($v_tag = ('775', '776') and $v_ind2 = '8' and $v_code = 'w')">
                <xsl:variable name="v_temp">
                    <xsl:call-template name="t_normalize-authority-id">
                        <xsl:with-param name="p_input" select="$v_content"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:if test="contains($v_temp, ':')">
                    <xsl:element name="idno">
                        <xsl:attribute name="type">
                            <xsl:choose>
                                <xsl:when test="starts-with($v_temp, 'oclc:')">
                                    <xsl:text>OCLC</xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="substring-before($v_temp, ':')"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:attribute>
                        <xsl:value-of select="substring-after($v_temp, ':')"/>
                    </xsl:element>
                </xsl:if>
            </xsl:when>
            <!-- Hathi IDs -->
            <xsl:when test="$v_tag = 'CID' and $v_code = 'a'">
                <xsl:element name="idno">
                    <xsl:attribute name="type" select="'ht_bib_key'"/>
                    <xsl:value-of select="$v_content"/>
                </xsl:element>
            </xsl:when>
            <!-- IDS in KOHA systems -->
            <xsl:when test="$v_tag = '090' and $v_code = 'b'">
                <xsl:element name="idno">
                    <xsl:attribute name="type" select="'classmark'"/>
                    <!-- provide some source information -->
                    <xsl:attribute name="source" select="$p_koha-org-id"/>
                    <xsl:value-of select="$v_content"/>
                </xsl:element>
            </xsl:when>
            <xsl:when test="$v_tag = '999' and $v_code = 'c'">
                <xsl:element name="idno">
                    <xsl:attribute name="type" select="'biblio_id'"/>
                    <!-- provide some source information -->
                    <xsl:attribute name="source" select="$p_koha-org-id"/>
                    <xsl:value-of select="$v_content"/>
                </xsl:element>
                <xsl:element name="idno">
                    <xsl:attribute name="type" select="'url'"/>
                    <xsl:attribute name="subtype" select="'MARCXML'"/>
                    <!-- provide some source information -->
                    <xsl:attribute name="source" select="$p_koha-org-id"/>
                    <xsl:value-of select="concat($v_koha-url-record-marcxml, $v_content)"/>
                </xsl:element>
            </xsl:when>
            <!-- 082 - DEWEY DECIMAL CALL NUMBER (R) -->
            <xsl:when test="$v_tag = '082'">
                <!--
              - First indicator - Type of edition
	0 - Full edition
	1 - Abridged edition
	7 - Other edition specified in subfield $2 
              - Second indicator - Source of call number 
	# - No information provided
	0 - Assigned by LC
	4 - Assigned by agency other than LC 
              - Subfield codes 
	+ $a - Classification number (NR) 
	+ $b - Item number (NR) 
	+ $d - Volumes/dates to which call number applies (NR) 
	+ $2 - Edition information (NR) 
	+ $5 - Institution to which field applies (R) 
	+ $6 - Linkage (NR) 
	+ $8 - Field link and sequence number (R)
                --> </xsl:when>
            <!-- 084: other classification number -->
            <xsl:when test="$v_tag = '084' and $v_code = 'a'">
                <xsl:element name="idno">
                    <xsl:attribute name="type">
                        <xsl:apply-templates select="parent::marc:datafield/marc:subfield[@code = '2']"/>
                    </xsl:attribute>
                    <xsl:value-of select="$v_content"/>
                </xsl:element>
            </xsl:when>
            <!-- this could be used to normalize the source of IDs -->
            <xsl:when test="$v_tag = '084' and $v_code = '2'">
                <xsl:value-of select="$v_content"/>
            </xsl:when>
            <xsl:when test="$v_tag = ('856') and $v_code = 'u'">
                <xsl:element name="idno">
                    <xsl:attribute name="type" select="'url'"/>
                    <xsl:value-of select="$v_content"/>
                </xsl:element>
            </xsl:when>
            <!-- 040: cataloging source
                - $a - Original cataloging agency (NR)
                - $b - Language of cataloging (NR)
                - $c - Transcribing agency (NR)
                - $d - Modifying agency (R)
                - $e - Description conventions (R) 
            -->
            <!-- 041: language code -->
            <xsl:when test="$v_tag = '041'">
                <xsl:choose>
                    <xsl:when test="$v_code = 'a' and preceding-sibling::marc:subfield[@code = 'a']">
                        <xsl:attribute name="otherLangs" select="oape:string-convert-lang-codes($v_content, 'iso639-2', 'bcp47')"/>
                    </xsl:when>
                    <xsl:when test="$v_code = 'a'">
                        <xsl:element name="textLang">
                            <xsl:attribute name="mainLang" select="oape:string-convert-lang-codes($v_content, 'iso639-2', 'bcp47')"/>
                            <xsl:apply-templates select="following-sibling::marc:subfield[@code = 'a']"/>
                        </xsl:element>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
            <!-- 100: contributor -->
            <!-- 100 - MAIN ENTRY-\-PERSONAL NAME (NR) -->
            <!-- 110 - MAIN ENTRY-\-CORPORATE NAME (NR)  -->
            <!-- 700: added entry, personal name: https://www.loc.gov/marc/bibliographic/bd700.html -->
            <xsl:when test="$v_tag = ('100', '700')">
                <xsl:choose>
                    <!-- code 4 is not as ubiquotous as I thought -->
                    <xsl:when test="$v_code = '4'">
                        <xsl:choose>
                            <xsl:when test="$v_content = 'aut'">
                                <xsl:element name="author">
                                    <!-- name -->
                                    <xsl:apply-templates select="parent::marc:datafield/marc:subfield[@code = 'a']"/>
                                </xsl:element>
                            </xsl:when>
                            <xsl:when test="$v_content = 'edt'">
                                <xsl:element name="editor">
                                    <!-- name -->
                                    <xsl:apply-templates select="parent::marc:datafield/marc:subfield[@code = 'a']"/>
                                </xsl:element>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:element name="respStmt">
                                    <xsl:element name="resp">
                                        <xsl:value-of select="$v_content"/>
                                    </xsl:element>
                                    <!-- name -->
                                    <xsl:apply-templates select="parent::marc:datafield/marc:subfield[@code = 'a']"/>
                                </xsl:element>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <!-- does the name field assume specific formating? I have seen "surname, forename(s)"  -->
                    <xsl:when test="$v_code = 'a'">
                        <xsl:variable name="v_persName">
                            <xsl:element name="persName">
                                <!-- ID -->
                                <xsl:if test="parent::marc:datafield/marc:subfield[@code = '0']">
                                    <xsl:attribute name="ref">
                                        <xsl:apply-templates select="parent::marc:datafield/marc:subfield[@code = '0']"/>
                                    </xsl:attribute>
                                </xsl:if>
                                <!-- language -->
                                <xsl:attribute name="xml:lang">
                                    <xsl:choose>
                                        <xsl:when test="$v_lang-item = 'ar'">
                                            <xsl:value-of select="$v_lang-entry"/>
                                        </xsl:when>
                                        <!-- fallback: undefined, Latin script -->
                                        <xsl:otherwise>
                                            <xsl:value-of select="$v_lang-item"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:attribute>
                                <!-- content -->
                                <xsl:value-of select="$v_content"/>
                            </xsl:element>
                        </xsl:variable>
                        <xsl:choose>
                            <xsl:when test="parent::marc:datafield/marc:subfield[@code = '4']">
                                <xsl:copy-of select="$v_persName"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:element name="respStmt">
                                    <xsl:element name="resp">
                                        <xsl:attribute name="xml:lang" select="'en'"/>
                                        <xsl:text>rel</xsl:text>
                                    </xsl:element>
                                    <xsl:copy-of select="$v_persName"/>
                                </xsl:element>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <!-- code "d": life-dates -->
                    <xsl:when test="$v_code = 'd'">
                        <xsl:choose>
                            <xsl:when test="matches($v_content, '^\d{4}\s*-\s*\d{4}$')">
                                <xsl:element name="birth">
                                    <xsl:attribute name="when" select="replace($v_content, '^(\d{4})\s*-\s*(\d{4})$', '$1')"/>
                                </xsl:element>
                                <xsl:element name="death">
                                    <xsl:attribute name="when" select="replace($v_content, '^(\d{4})\s*-\s*(\d{4})$', '$2')"/>
                                </xsl:element>
                            </xsl:when>
                            <xsl:when test="matches($v_content, '^\d{4}\s*-.*$')">
                                <xsl:element name="birth">
                                    <xsl:attribute name="when" select="replace($v_content, '^(\d{4})\s*-.*$', '$1')"/>
                                </xsl:element>
                            </xsl:when>
                            <xsl:when test="matches($v_content, '^.*-\s*\d{4}$')">
                                <xsl:element name="death">
                                    <xsl:attribute name="when" select="replace($v_content, '^.*-\s*(\d{4})$', '$1')"/>
                                </xsl:element>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:element name="event">
                                    <xsl:value-of select="$v_content"/>
                                </xsl:element>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
            <!-- titles 
                - 240: uniform title
                - 241: romanized title
                - 242: translation of title by cataloging agency
                - 243: collective uniform title
                - 245: title statement
                - 246: varying form of title
            -->
            <!-- 222: duplicate of the title field -->
            <xsl:when test="$v_tag = ('241', '242', '243', '245', '246')">
                <xsl:choose>
                    <xsl:when test="$v_code = ('a', 'b')">
                        <xsl:element name="title">
                            <xsl:if test="$v_code = 'b'">
                                <xsl:attribute name="type" select="'sub'"/>
                            </xsl:if>
                            <xsl:if test="$v_tag = '246' and $v_ind1 = '3' and $v_ind2 = '3'">
                                <xsl:attribute name="type" select="'alt'"/>
                            </xsl:if>
                            <xsl:choose>
                                <xsl:when test="$v_tag = '245'">
                                    <xsl:attribute name="xml:lang">
                                        <xsl:value-of select="$v_lang-entry"/>
                                    </xsl:attribute>
                                </xsl:when>
                                <!-- AUB uses 246 for entries in IJMES transcription -->
                                <!--<xsl:when test="$v_tag = '246'">
                                        <xsl:value-of select=""/>
                                    </xsl:when>-->
                                <!-- fallback? -->
                            </xsl:choose>
                            <!-- content -->
                            <xsl:value-of select="$v_content"/>
                        </xsl:element>
                    </xsl:when>
                    <!-- Statement of responsibility, etc. -->
                    <xsl:when test="$v_code = 'c'">
                        <!-- this can provide information on editors, translators etc. if they are part of the title.
                            I see currently no easy way to split that into the necessary components of <respStmt> --> </xsl:when>
                    <!-- Number of part/section of a work -->
                    <xsl:when test="$v_code = ('n', 'p')">
                        <xsl:element name="biblScope">
                            <!-- the content isn't machine-readable per se -->
                            <xsl:value-of select="$v_content"/>
                        </xsl:element>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
            <!-- imprint -->
            <!-- 264 - PRODUCTION, PUBLICATION, DISTRIBUTION, MANUFACTURE, AND COPYRIGHT NOTICE (R) -->
            <!-- some of the information is mirrored in 936, 776 -->
            <xsl:when test="$v_tag = ('260', '264')">
                <!-- 	First indicator - Sequence of statements
                        # - Not applicable/No information provided/Earliest; 2 - Intervening; 3 - Current/latest
                    Second indicator - Function of entity
                        0 - Production; 1 - Publication; 2 - Distribution; 3 - Manufacture; 4 - Copyright notice date 
                -->
                <xsl:choose>
                    <!-- $a - Place of production, publication, distribution, manufacture (R)  -->
                    <xsl:when test="$v_code = 'a'">
                        <xsl:element name="pubPlace">
                            <xsl:element name="placeName">
                                <xsl:value-of select="$v_content"/>
                            </xsl:element>
                        </xsl:element>
                    </xsl:when>
                    <!-- $b - Name of producer, publisher, distributor, manufacturer (R)  -->
                    <!-- publisher/ editor of a periodical -->
                    <!-- I have currently no means to establish which one it is! -->
                    <xsl:when test="$v_code = 'b'">
                        <xsl:element name="publisher">
                            <!-- we should not assume an orgName as additional wrapper! -->
                            <xsl:element name="orgName">
                                <xsl:value-of select="$v_content"/>
                            </xsl:element>
                        </xsl:element>
                    </xsl:when>
                    <!-- $c - Date of production, publication, distribution, manufacture, or copyright notice (R)  -->
                    <xsl:when test="$v_code = 'c'">
                        <xsl:element name="date">
                            <xsl:value-of select="$v_content"/>
                        </xsl:element>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
            <!-- 362: holding information -->
            <xsl:when test="$v_tag = '362' and $v_code = 'a'">
                <xsl:element name="biblScope">
                    <xsl:value-of select="$v_content"/>
                </xsl:element>
            </xsl:when>
            <!-- 363: NORMALIZED DATE AND SEQUENTIAL DESIGNATION  -->
            <xsl:when test="$v_tag = '363' and $v_code = 'i'">
                <xsl:element name="date">
                    <xsl:choose>
                        <xsl:when test="$v_ind1 = '0'">
                            <xsl:attribute name="type" select="'onset'"/>
                        </xsl:when>
                        <xsl:when test="$v_ind1 = '1'">
                            <xsl:attribute name="type" select="'terminus'"/>
                        </xsl:when>
                    </xsl:choose>
                    <!-- machine-readible dates -->
                    <xsl:choose>
                        <xsl:when test="parent::marc:datafield[marc:subfield/@code = 'j'][marc:subfield/@code = 'k']">
                            <xsl:attribute name="when" select="concat(., '-', parent::marc:datafield/marc:subfield[@code = 'j'], '-', parent::marc:datafield/marc:subfield[@code = 'k'])"/>
                        </xsl:when>
                    </xsl:choose>
                    <!-- content -->
                    <xsl:value-of select="$v_content"/>
                </xsl:element>
            </xsl:when>
            <!-- 490: series statement -->
            <!-- 250: edition statement      -->
            <!-- 300: format, such as microfilm etc. can be read as biblscope -->
            <xsl:when test="$v_tag = '300' and $v_code = 'a'">
                <xsl:choose>
                    <xsl:when test="matches($v_content, '\d+ مجلدات')">
                        <xsl:element name="biblScope">
                            <xsl:attribute name="unit" select="'volume'"/>
                            <!-- not sure if we can assume that "6 volumes" implies 1-6 -->
                            <xsl:value-of select="$v_content"/>
                        </xsl:element>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
            <!-- 310: frequency -->
            <xsl:when test="$v_tag = '310'">
                <!-- analyse string for controlled vocabulary -->
                <xsl:variable name="v_frequency">
                    <xsl:choose>
                        <xsl:when test="matches($v_content, '(نصف .سبوعية|مرتين بال.سبوع|مرتين في ال.سبوع)')">
                            <xsl:text>biweekly</xsl:text>
                        </xsl:when>
                        <xsl:when test="matches($v_content, '(نصف شهرية|مرتين بالشهر|مرتين في الشهر|كل .سبوعين مرة)')">
                            <xsl:text>fortnightly</xsl:text>
                        </xsl:when>
                        <xsl:when test="matches($v_content, '(.ربع مرات في السنة|كل ثلاثة .شهر)')">
                            <xsl:text>quarterly</xsl:text>
                        </xsl:when>
                        <xsl:when test="matches($v_content, '^سنوية$')">
                            <xsl:text>anually</xsl:text>
                        </xsl:when>
                        <xsl:when test="matches($v_content, '(شهرية|مرة في الشهر)')">
                            <xsl:text>monthly</xsl:text>
                        </xsl:when>
                        <xsl:when test="matches($v_content, '^.سبوعية$')">
                            <xsl:text>weekly</xsl:text>
                        </xsl:when>
                        <xsl:when test="matches($v_content, '^يومية$')">
                            <xsl:text>daily</xsl:text>
                        </xsl:when>
                        <!-- ZDB does not use 310 -->
                        <!-- hathi uses plain English, which we can utilise -->
                        <xsl:when test="$v_lang-catalogue = 'und'">
                            <xsl:value-of select="$v_content"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:variable>
                <xsl:if test="$v_frequency != ''">
                    <xsl:attribute name="oape:frequency" select="$v_frequency"/>
                </xsl:if>
            </xsl:when>
            <!-- 5xx: notes -->
            <xsl:when test="$v_tag = '500'">
                <xsl:choose>
                    <xsl:when test="parent::marc:datafield[not(preceding-sibling::marc:datafield[@tag = '500'])]">
                        <xsl:element name="note">
                            <xsl:attribute name="type" select="'comments'"/>
                            <xsl:element name="list">
                                <xsl:element name="item">
                                    <xsl:value-of select="$v_content"/>
                                </xsl:element>
                                <xsl:for-each select="parent::marc:datafield/following-sibling::marc:datafield[@tag = '500']">
                                    <xsl:apply-templates select="marc:subfield"/>
                                </xsl:for-each>
                            </xsl:element>
                        </xsl:element>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:element name="item">
                            <xsl:value-of select="$v_content"/>
                        </xsl:element>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- 530: shelfmark -->
            <!-- 530 - ADDITIONAL PHYSICAL FORM AVAILABLE NOTE (R)  -->
            <!-- 541 acquisition history -->
            <!-- 590: availability -->
            <!-- 655 - INDEX TERM-GENRE/FORM -->
            <xsl:when test="$v_tag = '655' and $v_code = '0'">
                <xsl:choose>
                    <xsl:when test="$v_content = 'https://d-nb.info/gnd/4067510-5'">
                        <xsl:attribute name="type" select="'periodical'"/>
                        <xsl:attribute name="subtype" select="'newspaper'"/>
                    </xsl:when>
                    <xsl:when test="$v_content = 'https://d-nb.info/gnd/4067488-5'">
                        <xsl:attribute name="type" select="'periodical'"/>
                        <xsl:attribute name="subtype" select="'journal'"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
            <!-- 773: host item entry -->
            <xsl:when test="$v_tag = '773'">
                <xsl:choose>
                    <xsl:when test="$v_code = ('a', 't')">
                        <xsl:element name="title">
                            <xsl:value-of select="$v_content"/>
                        </xsl:element>
                    </xsl:when>
                    <xsl:when test="$v_code = 'd'">
                        <xsl:analyze-string regex="^(.*),\s*(.*),\s*(.*)$" select="$v_content">
                            <xsl:matching-substring>
                                <xsl:element name="pubPlace">
                                    <xsl:element name="placeName">
                                        <xsl:value-of select="regex-group(1)"/>
                                    </xsl:element>
                                </xsl:element>
                                <xsl:element name="publisher">
                                    <xsl:value-of select="regex-group(2)"/>
                                </xsl:element>
                                <xsl:element name="date">
                                    <xsl:value-of select="regex-group(3)"/>
                                </xsl:element>
                            </xsl:matching-substring>
                        </xsl:analyze-string>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
            <!-- 866: extent of collection -->
            <!-- at least at AUB, this is treated like a freeform field and should probably be translated into a note -->
            <!-- 924: holdings referenced in ZDB and Hathi, even though this is not called for Hathi holding data. -->
            <xsl:when test="$v_tag = '924'">
                <xsl:choose>
                    <xsl:when test="$v_code = ('q', 'v')">
                        <xsl:element name="date">
                            <xsl:attribute name="type">
                                <xsl:choose>
                                    <xsl:when test="$v_code = 'q'">
                                        <xsl:text>onset</xsl:text>
                                    </xsl:when>
                                    <xsl:when test="$v_code = 'v'">
                                        <xsl:text>terminus</xsl:text>
                                    </xsl:when>
                                </xsl:choose>
                            </xsl:attribute>
                            <xsl:value-of select="$v_content"/>
                        </xsl:element>
                    </xsl:when>
                    <xsl:when test="$v_code = 'g'">
                        <xsl:variable name="v_id-isil" select="parent::marc:datafield/marc:subfield[@code = 'b']"/>
                        <xsl:element name="idno">
                            <xsl:attribute name="type" select="'classmark'"/>
                            <xsl:attribute name="subtype" select="$v_id-isil"/>
                            <xsl:attribute name="source" select="concat('http://ld.zdb-services.de/data/organisations/', $v_id-isil, '.rdf')"/>
                            <xsl:value-of select="$v_content"/>
                        </xsl:element>
                    </xsl:when>
                    <!-- free-form field with comments on holdings -->
                    <xsl:when test="$v_code = 'z'">
                        <xsl:element name="biblScope">
                            <!-- in the case of ZDB, the conte is freeform and would need a lot of heuristics to actually parse in structured form. This can be relegated to postprocessing -->
                            <xsl:value-of select="$v_content"/>
                        </xsl:element>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
            <!-- holdings in KOHA system / USJ -->
            <!-- documentation is here: https://wiki.koha-community.org/wiki/Holdings_data_fields_(9xx)#MARC21_Holding_field_.28952.29 -->
            <xsl:when test="$v_tag = '952'">
                <xsl:choose>
                    <!-- Date acquired! But it seems at least USJ is using it for the publication date. Another probability is that they bought items upon their publication-->
                    <xsl:when test="$v_code = 'd'">
                        <xsl:element name="date">
                            <xsl:attribute name="type" select="'acquisition'"/>
                            <xsl:value-of select="$v_content"/>
                        </xsl:element>
                    </xsl:when>
                    <!-- Volume and issue information for serial items. -->
                    <xsl:when test="$v_code = 'h'">
                        <xsl:element name="biblScope">
                            <xsl:value-of select="$v_content"/>
                        </xsl:element>
                    </xsl:when>
                    <xsl:when test="$v_code = ('o', 'p')">
                        <xsl:element name="idno">
                            <xsl:attribute name="type">
                                <xsl:choose>
                                    <!-- Koha full call number -->
                                    <xsl:when test="$v_code = 'o'">
                                        <xsl:value-of select="'classmark'"/>
                                    </xsl:when>
                                    <!-- barcode -->
                                    <xsl:when test="$v_code = 'p'">
                                        <xsl:value-of select="'barcode'"/>
                                    </xsl:when>
                                </xsl:choose>
                            </xsl:attribute>
                            <xsl:value-of select="$v_content"/>
                        </xsl:element>
                    </xsl:when>
                    <!-- lost status -->
                    <xsl:when test="$v_code = '1' and $v_content = (1, 3, 4)">
                        <xsl:element name="note">
                            <xsl:text>item is lost or missing</xsl:text>
                        </xsl:element>
                    </xsl:when>
                    <!-- damaged status -->
                    <xsl:when test="$v_code = '4' and $v_content = 1">
                        <xsl:element name="note">
                            <xsl:text>item is damaged</xsl:text>
                        </xsl:element>
                    </xsl:when>
                    <xsl:when test="$v_code = ('a', 'b')">
                        <xsl:element name="orgName">
                            <xsl:value-of select="$v_content"/>
                        </xsl:element>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$v_tag = '974'">
                <xsl:choose>
                    <xsl:when test="$v_code = 'b'">
                        <xsl:variable name="v_orgName">
                            <xsl:element name="orgName">
                                <xsl:attribute name="ref" select="concat('hathi:', $v_content)"/>
                                <xsl:value-of select="$v_content"/>
                            </xsl:element>
                        </xsl:variable>
                        <xsl:if test="$p_debug = true()">
                            <xsl:message>
                                <xsl:text>$v_orgName: </xsl:text>
                                <xsl:copy-of select="$v_orgName"/>
                            </xsl:message>
                        </xsl:if>
                        <xsl:variable name="v_placeName"
                            select="oape:query-organizationography($v_orgName/descendant-or-self::tei:orgName, $v_organizationography, $p_local-authority, 'location-tei', 'en')"/>
                        <xsl:if test="$p_debug = true()">
                            <xsl:message>
                                <xsl:text>$v_placeName: </xsl:text>
                                <xsl:copy-of select="$v_placeName"/>
                            </xsl:message>
                        </xsl:if>
                        <xsl:copy-of select="$v_placeName"/>
                        <xsl:text>, </xsl:text>
                        <xsl:element name="orgName">
                            <!--<xsl:attribute name="ref" select="concat('hathi:', $v_content)"/>-->
                            <xsl:attribute name="ref" select="oape:query-organizationography($v_orgName/descendant-or-self::tei:orgName, $v_organizationography, $p_local-authority, 'tei-ref', '')"/>
                            <xsl:value-of select="oape:query-organizationography($v_orgName/descendant-or-self::tei:orgName, $v_organizationography, $p_local-authority, 'name', 'en')"/>
                        </xsl:element>
                    </xsl:when>
                    <xsl:when test="$v_code = 'u'">
                        <xsl:element name="idno">
                            <xsl:attribute name="type" select="'classmark'"/>
                            <xsl:attribute name="source" select="'oape:org:417'"/>
                            <xsl:value-of select="$v_content"/>
                        </xsl:element>
                        <xsl:element name="idno">
                            <xsl:attribute name="type" select="'URI'"/>
                            <xsl:attribute name="subtype" select="'self'"/>
                            <xsl:value-of select="concat('https://hdl.handle.net/2027/', $v_content)"/>
                        </xsl:element>
                    </xsl:when>
                    <xsl:when test="$v_code = 'y'">
                        <xsl:element name="date">
                            <xsl:if test="matches($v_content, '^\d{4}$')">
                                <xsl:attribute name="when" select="$v_content"/>
                            </xsl:if>
                            <xsl:value-of select="$v_content"/>
                        </xsl:element>
                    </xsl:when>
                    <xsl:when test="$v_code = 'z'">
                        <xsl:element name="biblScope">
                            <xsl:value-of select="$v_content"/>
                        </xsl:element>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
            <!-- 936: -->
            <!-- probably move some heuristics to post-processing -->
            <xsl:when test="($v_tag = '936') and ($v_ind1 = 'u') and ($v_ind2 = 'w')">
                <xsl:choose>
                    <xsl:when test="$v_code = ('d', 'e', 'h')">
                        <xsl:element name="biblScope">
                            <xsl:attribute name="unit">
                                <xsl:choose>
                                    <xsl:when test="$v_code = 'd'">
                                        <xsl:text>volume</xsl:text>
                                    </xsl:when>
                                    <xsl:when test="$v_code = 'e'">
                                        <xsl:text>issue</xsl:text>
                                    </xsl:when>
                                    <xsl:when test="$v_code = 'h'">
                                        <xsl:text>page</xsl:text>
                                    </xsl:when>
                                </xsl:choose>
                            </xsl:attribute>
                            <!-- content -->
                            <xsl:value-of select="$v_content"/>
                        </xsl:element>
                    </xsl:when>
                    <!-- date -->
                    <!-- date of publication -->
                    <xsl:when test="$v_code = 'j'">
                        <xsl:element name="date">
                            <xsl:value-of select="$v_content"/>
                        </xsl:element>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <!-- when and from where is this called? -->
    <xsl:template match="marc:datafield[@tag = ('924')]" mode="m_notes">
        <xsl:param name="p_id-record"/>
        <xsl:element name="note">
            <xsl:attribute name="type" select="'holdings'"/>
            <xsl:element name="list">
                <!-- initial item -->
                <xsl:apply-templates mode="m_notes" select="marc:subfield[@code = 'b']">
                    <xsl:with-param name="p_id-record" select="$p_id-record"/>
                </xsl:apply-templates>
                <!-- following items -->
                <xsl:apply-templates mode="m_notes" select="following-sibling::marc:datafield[@tag = '924']/marc:subfield[@code = 'b']">
                    <xsl:with-param name="p_id-record" select="$p_id-record"/>
                </xsl:apply-templates>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    <!-- this has beeen changed to group Hathi holdings by institution -->
    <xsl:template match="marc:datafield[@tag = ('974')]" mode="m_notes" priority="2">
        <xsl:apply-templates mode="m_notes" select="marc:subfield[@code = 'b']"/>
    </xsl:template>
    <xsl:template match="marc:datafield[@tag = ('952')]" mode="m_notes">
        <xsl:element name="bibl">
            <!-- dates -->
            <xsl:apply-templates select="marc:subfield[@code = 'd']"/>
            <!-- classmark -->
            <xsl:apply-templates select="marc:subfield[@code = 'o']"/>
            <xsl:apply-templates select="marc:subfield[@code = 'p']"/>
            <!-- extent of holding -->
            <xsl:apply-templates select="marc:subfield[@code = 'h']"/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="marc:datafield[@tag = ('362')]" mode="m_notes">
        <xsl:param name="p_record"/>
        <xsl:param name="p_catalogue"/>
        <xsl:param name="p_url-catalogue"/>
        <xsl:element name="note">
            <xsl:attribute name="type" select="'holdings'"/>
            <xsl:element name="list">
                <xsl:choose>
                    <xsl:when test="$p_catalogue = 'koha'">
                        <xsl:variable name="v_id-record" select="$p_record//marc:datafield[@tag = '999']/marc:subfield[@code = 'c']/text()"/>
                        <xsl:element name="item">
                            <xsl:attribute name="source" select="concat($v_koha-url-record-web, $v_id-record)"/>
                            <xsl:element name="label">
                                <!-- one can retrieve information on the holding information based on 952$a -->
                                <xsl:variable name="v_orgName">
                                    <!-- we currently only look for the first holding -->
                                    <xsl:apply-templates select="$p_record//marc:datafield[@tag = '952'][1]/marc:subfield[@code = 'a']"/>
                                </xsl:variable>
                                <xsl:variable name="v_org" select="oape:get-entity-from-authority-file($v_orgName//tei:orgName, $p_local-authority, $v_organizationography)"/>
                                <!-- location -->
                                <xsl:copy-of select="oape:query-org($v_org/self::tei:org, 'location-tei', 'en', $p_local-authority)"/>
                                <xsl:text>, </xsl:text>
                                <!-- institution -->
                                <xsl:element name="orgName">
                                    <xsl:attribute name="ref" select="oape:query-organizationography($v_org//tei:orgName[1], $v_organizationography, $p_local-authority, 'tei-ref', '')"/>
                                    <xsl:value-of select="oape:query-org($v_org/self::tei:org, 'name', 'en', $p_local-authority)"/>
                                </xsl:element>
                            </xsl:element>
                            <xsl:element name="listBibl">
                                <xsl:element name="bibl">
                                    <xsl:apply-templates select="marc:subfield[@code = 'a']"/>
                                    <xsl:element name="idno">
                                        <xsl:attribute name="source" select="$p_koha-org-id"/>
                                        <xsl:attribute name="type" select="'biblio_id'"/>
                                        <xsl:value-of select="$v_id-record"/>
                                    </xsl:element>
                                    <xsl:element name="idno">
                                        <xsl:attribute name="type" select="'url'"/>
                                        <xsl:value-of select="concat($v_koha-url-record-web, $v_id-record)"/>
                                    </xsl:element>
                                    <xsl:element name="idno">
                                        <xsl:attribute name="type" select="'url'"/>
                                        <xsl:attribute name="subtype" select="'MARCXML'"/>
                                        <xsl:value-of select="concat($v_koha-url-record-marcxml, $v_id-record)"/>
                                    </xsl:element>
                                </xsl:element>
                            </xsl:element>
                        </xsl:element>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message terminate="no">
                            <xsl:text>WARNING: not implemented for this catalogue / library system: </xsl:text>
                            <xsl:value-of select="$p_catalogue"/>
                        </xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    <!-- it is not really clear why this isn't called on its parent datafield -->
    <xsl:template match="marc:subfield" mode="m_notes">
        <xsl:param name="p_id-record">
            <xsl:copy-of select="oape:query-marcx(ancestor::marc:record[1], 'id')"/>
        </xsl:param>
        <xsl:variable name="v_catalogue" select="oape:query-marcx(ancestor::marc:record[1], 'catalogue')"/>
        <xsl:variable name="v_url-catalogue" select="oape:query-marcx(ancestor::marc:record[1], 'url_record-in-catalogue')"/>
        <xsl:choose>
            <!-- AUB catalogue -->
            <xsl:when test="$v_catalogue = 'aub'">
                <xsl:element name="note">
                    <xsl:attribute name="type" select="'holdings'"/>
                    <xsl:element name="list">
                        <xsl:element name="item">
                            <xsl:element name="label">
                                <xsl:attribute name="xml:lang" select="'en'"/>
                                <xsl:element name="placeName">
                                    <xsl:text>Beirut</xsl:text>
                                </xsl:element>
                                <xsl:text>, </xsl:text>
                                <xsl:element name="orgName">
                                    <xsl:attribute name="ref" select="'#hAUB'"/>
                                    <xsl:text>AUB</xsl:text>
                                </xsl:element>
                            </xsl:element>
                            <!-- this should NOT be converted to listBibl as it does not yield structured information -->
                            <xsl:element name="ab">
                                <xsl:attribute name="xml:lang">
                                    <xsl:choose>
                                        <xsl:when test="$p_id-record/tei:idno/@type = 'LEAUB'">
                                            <xsl:text>ar</xsl:text>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:text>und-Latn</xsl:text>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:attribute>
                                <!-- the actual holding information is to be found in plain text, that is not currently parsed into something more structured  -->
                                <xsl:apply-templates mode="m_plain-text"/>
                            </xsl:element>
                            <!-- remove this redundant information on the source of the information -->
                            <!--<xsl:if test="$v_url-catalogue != 'NA'">
                                <xsl:element name="ab">
                                    <xsl:attribute name="xml:lang" select="'en'"/>
                                    <xsl:element name="ref">
                                        <xsl:attribute name="target" select="$v_url-catalogue"/>
                                        <xsl:text>catalogue</xsl:text>
                                    </xsl:element>
                                </xsl:element>
                            </xsl:if>-->
                        </xsl:element>
                    </xsl:element>
                </xsl:element>
            </xsl:when>
            <xsl:when test="$v_catalogue = 'zdb'">
                <!-- we can pull information on holding informations from the ISIL number -->
                <xsl:variable name="v_id-isil" select="parent::marc:datafield/marc:subfield[@code = 'b']"/>
                <xsl:variable name="v_org">
                    <xsl:apply-templates mode="m_isil-to-tei" select="doc(concat('http://ld.zdb-services.de/data/organisations/', $v_id-isil, '.rdf'))/descendant::rdf:Description"/>
                </xsl:variable>
                <xsl:element name="item">
                    <xsl:attribute name="source" select="$v_url-catalogue"/>
                    <xsl:element name="label">
                        <!-- location -->
                        <xsl:copy-of select="oape:query-org($v_org/descendant-or-self::tei:org, 'location-tei', 'en', $p_local-authority)"/>
                        <xsl:text>, </xsl:text>
                        <!-- institution -->
                        <xsl:element name="orgName">
                            <xsl:attribute name="ref"
                                select="oape:query-organizationography($v_org/descendant::tei:orgName[@type = 'short'][1], $v_organizationography, $p_local-authority, 'tei-ref', '')"/>
                            <xsl:value-of select="oape:query-org($v_org/descendant-or-self::tei:org, 'name', 'en', $p_local-authority)"/>
                        </xsl:element>
                    </xsl:element>
                    <!-- machine readible holding information -->
                    <xsl:element name="listBibl">
                        <xsl:element name="bibl">
                            <xsl:attribute name="source" select="concat('#', $v_catalogue)"/>
                            <!-- classmark -->
                            <xsl:apply-templates select="parent::marc:datafield/marc:subfield[@code = 'g']"/>
                            <!-- holding: dates -->
                            <xsl:apply-templates select="parent::marc:datafield/marc:subfield[@code = 'q']"/>
                            <xsl:apply-templates select="parent::marc:datafield/marc:subfield[@code = 'v']"/>
                            <!-- create a note inside the bibl for information on the extent of holdings. Despite its highly unstructured form, I'll write the information to a biblScope element -->
                            <!-- in HathiTrust this information is more structured -->
                            <xsl:apply-templates select="parent::marc:datafield/marc:subfield[@code = 'z']"/>
                        </xsl:element>
                    </xsl:element>
                    <!-- source information -->
                    <!-- this is already encoded in the @source attribute on the parent node -->
                </xsl:element>
            </xsl:when>
            <!-- I think this is actually called! -->
            <xsl:when test="$v_catalogue = 'hathi'">
                <!-- machine readible holding information -->
                <xsl:element name="bibl">
                    <xsl:attribute name="source" select="'oape:org:417'"/>
                    <!-- latest rights change: "d" -->
                    <!-- copyright: "p"  -->
                    <!-- classmark -->
                    <xsl:apply-templates select="parent::marc:datafield/marc:subfield[@code = 'u']"/>
                    <!-- holding: dates -->
                    <xsl:apply-templates select="parent::marc:datafield/marc:subfield[@code = 'y']"/>
                    <!-- biblscope -->
                    <xsl:apply-templates select="parent::marc:datafield/marc:subfield[@code = 'z']"/>
                </xsl:element>
            </xsl:when>
            <!-- fallback? -->
            <xsl:otherwise> </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="marc:record" mode="m_get-holding-institutions">
        <xsl:variable name="v_id-record">
            <xsl:apply-templates select="marc:datafield[@tag = ('016')][@ind1 = '7']/marc:subfield[@code = 'a']"/>
        </xsl:variable>
        <!-- variable to potentially pull a record from another URL based on the input record -->
        <xsl:variable name="v_record">
            <xsl:choose>
                <xsl:when test="$v_id-record/tei:idno/@type = 'zdb'">
                    <xsl:variable name="v_url-record" select="concat($v_url-server-zdb-ld, $v_id-record/tei:idno[@type = 'zdb'], '.plus-1.mrcx')"/>
                    <xsl:copy-of select="doc($v_url-record)/descendant-or-self::marc:record"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- content -->
        <xsl:apply-templates mode="m_get-holding-institutions" select="$v_record/descendant::marc:datafield[@tag = '924']/marc:subfield[@code = 'b']"/>
    </xsl:template>
    <xsl:template match="marc:record" mode="m_get-people">
        <xsl:apply-templates mode="m_get-people" select="marc:datafield[@tag = '100']"/>
    </xsl:template>
    <xsl:template match="marc:datafield" mode="m_get-people">
        <xsl:element name="person">
            <xsl:element name="persName">
                <xsl:apply-templates select="marc:subfield[@code = 'a']/text()"/>
            </xsl:element>
            <!-- dates -->
            <xsl:apply-templates select="marc:subfield[@code = 'd']"/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="marc:datafield[@tag = '924']/marc:subfield[@code = 'b']" mode="m_get-holding-institutions">
        <xsl:element name="idno">
            <xsl:attribute name="type" select="'isil'"/>
            <xsl:value-of select="."/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="tei:idno[@type = 'isil']" mode="m_isil-to-tei">
        <xsl:apply-templates mode="m_isil-to-tei" select="doc(concat('http://ld.zdb-services.de/data/organisations/', ., '.rdf'))/rdf:RDF/rdf:Description"/>
    </xsl:template>
    <xsl:template name="t_normalize-authority-id">
        <xsl:param as="xs:string" name="p_input"/>
        <xsl:variable name="v_error-message">
            <xsl:text>Couldn't establish the pattern of authority and ID in </xsl:text>
            <xsl:value-of select="$p_input"/>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="matches($p_input, '^\(.+\).+$')">
                <xsl:variable name="v_auth" select="replace($p_input, '^\((.+)\).+$', '$1')"/>
                <xsl:variable name="v_id" select="replace($p_input, '^\(.+\)(.+)$', '$1')"/>
                <xsl:choose>
                    <!-- GND -->
                    <xsl:when test="$v_auth = 'DE-588'">
                        <xsl:value-of select="concat('gnd:', $v_id)"/>
                    </xsl:when>
                    <xsl:when test="$v_auth = 'DE-599'">
                        <xsl:value-of select="concat('zdb:', $v_id)"/>
                    </xsl:when>
                    <xsl:when test="$v_auth = 'DE-600'">
                        <xsl:value-of select="concat('zdb:', $v_id)"/>
                    </xsl:when>
                    <!-- worldcat -->
                    <xsl:when test="$v_auth = 'OCoLC'">
                        <xsl:value-of select="concat('oclc:', $v_id)"/>
                    </xsl:when>
                    <xsl:when test="$v_auth = 'LEAUB'">
                        <xsl:value-of select="concat($v_auth, ':', $v_id)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message>
                            <xsl:value-of select="$v_error-message"/>
                        </xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="matches($p_input, '^(\D+)(\d+)\s*$')">
                <xsl:variable name="v_auth" select="replace($p_input, '^(\D+)(\d+)\s*$', '$1')"/>
                <xsl:variable name="v_id" select="replace($p_input, '^(\D+)(\d+)\s*$', '$2')"/>
                <xsl:choose>
                    <xsl:when test="$v_auth = 'ocn'">
                        <xsl:value-of select="concat('oclc:', $v_id)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message>
                            <xsl:value-of select="$v_error-message"/>
                        </xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>
                    <xsl:value-of select="$v_error-message"/>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- 
        this function allows to query a given MARC XML file for various bits of information.
        currently, only the query for holding information is implemented
    -->
    <xsl:function name="oape:query-marcx">
        <xsl:param as="node()" name="p_marcx-record"/>
        <xsl:param as="xs:string" name="p_output-mode"/>
        <xsl:variable name="v_record" select="$p_marcx-record"/>
        <xsl:choose>
            <xsl:when test="$p_output-mode = 'holdings'">
                <!-- zdb holdings -->
                <xsl:variable name="v_id-record">
                    <xsl:apply-templates select="$v_record//marc:datafield[@tag = ('016')][@ind1 = '7']/marc:subfield[@code = 'a']"/>
                </xsl:variable>
                <xsl:apply-templates mode="m_notes" select="$v_record//marc:datafield[@tag = '924'][1]">
                    <xsl:with-param name="p_id-record" select="$v_id-record"/>
                </xsl:apply-templates>
                <!-- Hathi: holding information -->
                <!--<xsl:apply-templates mode="m_notes" select="$v_record//marc:datafield[@tag = 'HOL']">
                <xsl:with-param name="p_id-record" select="$v_id-record"/>
            </xsl:apply-templates>-->
                <!-- Hathi: digitised items -->
                <xsl:if test="$v_record//marc:datafield[@tag = '974']">
                    <xsl:variable name="v_id-record">
                        <!-- returns an <tei:idno> element -->
                        <xsl:apply-templates select="$v_record//marc:datafield[@tag = 'CID']/marc:subfield[@code = 'a']"/>
                    </xsl:variable>
                    <xsl:element name="note">
                        <xsl:attribute name="type" select="'holdings'"/>
                        <xsl:element name="list">
                            <!-- group by holding institution -->
                            <xsl:for-each-group group-by="marc:subfield[@code = 'b']" select="$v_record//marc:datafield[@tag = '974']">
                                <xsl:element name="item">
                                    <xsl:attribute name="source" select="concat('https://catalog.hathitrust.org/Record/', $v_id-record/tei:idno[@type = 'ht_bib_key'])"/>
                                    <xsl:element name="label">
                                        <xsl:apply-templates select="current-group()[1]/marc:subfield[@code = 'b']"/>
                                    </xsl:element>
                                    <!-- this should be converted to listBibl -->
                                    <xsl:element name="listBibl">
                                        <!-- machine-readible holding information -->
                                        <xsl:apply-templates mode="m_notes" select="current-group()"/>
                                    </xsl:element>
                                </xsl:element>
                            </xsl:for-each-group>
                        </xsl:element>
                    </xsl:element>
                </xsl:if>
            </xsl:when>
            <!-- output:  <tei:idno> nodes -->
            <xsl:when test="$p_output-mode = ('id_record', 'id')">
                <!-- for other catalogues field 776 is seemingly used for related publications
                check field 775 -->
                <xsl:apply-templates select="$p_marcx-record//marc:datafield[@tag = ('016')][@ind1 = '7']/marc:subfield[@code = 'a']"/>
                <xsl:apply-templates select="$p_marcx-record//marc:datafield[@tag = '776'][@ind2 = '8']/marc:subfield[@code = 'w']"/>
                <xsl:apply-templates select="$p_marcx-record//marc:datafield[@tag = '775'][@ind2 = '8']/marc:subfield[@code = 'w']"/>
                <xsl:apply-templates select="$p_marcx-record//marc:datafield[@tag = 'CID']/marc:subfield[@code = 'a']"/>
                <xsl:apply-templates select="$p_marcx-record//marc:datafield[@tag = '999']/marc:subfield[@code = 'c']"/>
                <!-- NLoI -->
                <xsl:apply-templates select="$p_marcx-record//marc:datafield[@tag = 'AVA']/marc:subfield[@code = '0']"/>
            </xsl:when>
            <!-- output: string -->
            <xsl:when test="$p_output-mode = 'catalogue'">
                <xsl:variable name="v_id-record">
                    <xsl:copy-of select="oape:query-marcx($p_marcx-record, 'id')"/>
                </xsl:variable>
                <xsl:choose>
                    <!-- the sequence of these tests matters -->
                    <xsl:when test="$v_id-record/tei:idno/@type = 'LEAUB'">
                        <xsl:text>aub</xsl:text>
                    </xsl:when>
                    <xsl:when test="$v_id-record/tei:idno/@type = 'ht_bib_key'">
                        <xsl:text>hathi</xsl:text>
                    </xsl:when>
                    <xsl:when test="$v_id-record/tei:idno/@type = 'zdb'">
                        <xsl:text>zdb</xsl:text>
                    </xsl:when>
                    <xsl:when test="$v_id-record/tei:idno/@type = 'biblio_id'">
                        <xsl:text>koha</xsl:text>
                    </xsl:when>
                    <xsl:when test="$v_id-record/tei:idno[@source]/@type = 'record'">
                        <xsl:value-of select="$v_id-record/tei:idno[@type = 'record']/@source"/>
                    </xsl:when>
                    <!-- the only other catalogue I have converted is HathiTrust. This needs to be replaced with a proper test -->
                    <xsl:otherwise>
                        <xsl:text>hathi</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'url_record-in-catalogue'">
                <xsl:variable name="v_id-record">
                    <xsl:copy-of select="oape:query-marcx($p_marcx-record, 'id')"/>
                </xsl:variable>
                <xsl:variable name="v_catalogue">
                    <xsl:value-of select="oape:query-marcx($p_marcx-record, 'catalogue')"/>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="$v_catalogue = 'aub'">
                        <xsl:value-of
                            select="concat('https://libcat.aub.edu.lb/record=', substring($v_id-record/tei:idno[@type = 'LEAUB'][1], 1, string-length($v_id-record/tei:idno[@type = 'LEAUB'][1]) - 1))"
                        />
                    </xsl:when>
                    <xsl:when test="$v_catalogue = 'zdb'">
                        <xsl:value-of select="concat('https://ld.zdb-services.de/resource/', $v_id-record/tei:idno[@type = 'zdb'][1])"/>
                    </xsl:when>
                    <xsl:when test="$v_catalogue = 'hathi'">
                        <xsl:value-of select="concat('https://catalog.hathitrust.org/Record/', $v_id-record/tei:idno[@type = 'ht_bib_key'])"/>
                    </xsl:when>
                    <xsl:when test="$v_catalogue = 'koha'">
                        <xsl:value-of select="concat($v_koha-url-record-web, $v_id-record/tei:idno[@type = 'biblio_id'])"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>NA</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- fallback -->
            <xsl:otherwise>
                <xsl:message>
                    <xsl:text>Unkown output mode: </xsl:text>
                    <xsl:value-of select="$p_output-mode"/>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <!-- template to add adequate namespace to marc records -->
    <xsl:template match="element()" mode="m_marc-add-ns">
        <xsl:element name="{local-name()}" namespace="http://www.loc.gov/MARC21/slim">
            <xsl:apply-templates mode="m_identity-transform" select="@*"/>
            <xsl:apply-templates mode="m_marc-add-ns" select="node()"/>
        </xsl:element>
    </xsl:template>
    <!-- do some post processing of TEI nodes -->
    <xsl:template match="node()[self::tei:*] | @*[parent::tei:*]" mode="m_postprocess">
        <xsl:copy>
            <xsl:apply-templates mode="m_postprocess" select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:title[not(@level)]" mode="m_postprocess" priority="2">
        <xsl:copy>
            <xsl:apply-templates mode="m_postprocess" select="@*"/>
            <xsl:if test="ancestor::tei:biblStruct/@type">
                <xsl:attribute name="level">
                    <xsl:choose>
                        <xsl:when test="ancestor::tei:biblStruct/@type = 'periodical'">
                            <xsl:value-of select="'j'"/>
                        </xsl:when>
                        <xsl:when test="ancestor::tei:biblStruct/@type = 'book'">
                            <xsl:value-of select="'m'"/>
                        </xsl:when>
                        <!-- fallback: x -->
                        <xsl:otherwise>
                            <xsl:value-of select="'x'"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
            </xsl:if>
            <xsl:apply-templates mode="m_postprocess"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:listBibl[ancestor::tei:note/@type = 'holdings']" mode="m_postprocess" priority="2">
        <xsl:copy>
            <xsl:apply-templates mode="m_postprocess" select="@*"/>
            <xsl:apply-templates mode="m_postprocess" select="node()">
                <xsl:sort select="tei:bibl/descendant::tei:biblScope[@unit = 'volume'][1]/@from"/>
                <xsl:sort select="tei:bibl/descendant::tei:biblScope[@unit = 'issue'][1]/@from"/>
                <xsl:sort select="tei:bibl/descendant::tei:date[@when][1]/@when"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:biblScope" mode="m_postprocess" priority="2">
        <xsl:choose>
            <!-- the field holds unstructured content. Trying to find machine-actionable data could be relegated to another step of processing -->
            <!-- 1. element needs to be split into multiple biblScope -->
            <!-- volume and issue  -->
            <!-- 1:1-48  -->
            <xsl:when test="matches(., '\d+:\d+-\d+')">
                <xsl:copy>
                    <xsl:apply-templates mode="m_identity-transform" select="@*"/>
                    <xsl:attribute name="unit">
                        <xsl:value-of select="'volume'"/>
                    </xsl:attribute>
                    <xsl:attribute name="from">
                        <xsl:value-of select="replace(., '^.*(\d+):\d+-\d+.*$', '$1')"/>
                    </xsl:attribute>
                    <xsl:attribute name="to">
                        <xsl:value-of select="replace(., '^.*(\d+):\d+-\d+.*$', '$1')"/>
                    </xsl:attribute>
                    <xsl:apply-templates mode="m_identity-transform"/>
                </xsl:copy>
                <xsl:copy>
                    <xsl:apply-templates mode="m_identity-transform" select="@*"/>
                    <xsl:attribute name="unit">
                        <xsl:value-of select="'issue'"/>
                    </xsl:attribute>
                    <xsl:attribute name="from">
                        <xsl:value-of select="replace(., '^.*\d+:(\d+)-\d+.*$', '$1')"/>
                    </xsl:attribute>
                    <xsl:attribute name="to">
                        <xsl:value-of select="replace(., '^.*\d+:\d+-(\d+).*$', '$1')"/>
                    </xsl:attribute>
                    <xsl:apply-templates mode="m_identity-transform"/>
                </xsl:copy>
            </xsl:when>
            <!-- 2. element does NOT need to be split -->
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates mode="m_identity-transform" select="@*"/>
                    <xsl:choose>
                        <xsl:when test="matches(., '^no\.\s*(\d+)-?(\d+)?.*$')">
                            <xsl:attribute name="unit" select="'issue'"/>
                            <xsl:attribute name="from" select="replace(., '^no\.\s*(\d+)-?(\d+)?.*$', '$1')"/>
                            <xsl:attribute name="to">
                                <xsl:choose>
                                    <xsl:when test="matches(., '^no\.\s*(\d+)-(\d+).*$')">
                                        <xsl:value-of select="replace(., '^no\.\s*(\d+)-(\d+).*$', '$2')"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="replace(., '^no\.\s*(\d+)-?(\d+)?.*$', '$1')"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:attribute>
                        </xsl:when>
                        <!-- volume information -->
                        <xsl:when test="matches(., '^v\.\s*(\d+)-?(\d+)?.*$')">
                            <xsl:attribute name="unit" select="'volume'"/>
                            <xsl:attribute name="from" select="replace(., '^v\.\s*(\d+)-?(\d+)?.*$', '$1')"/>
                            <xsl:attribute name="to">
                                <xsl:choose>
                                    <xsl:when test="matches(., '^v\.\s*(\d+)-(\d+).*$')">
                                        <xsl:value-of select="replace(., '^v\.\s*(\d+)-(\d+).*$', '$2')"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="replace(., '^v\.\s*(\d+)-?(\d+)?.*$', '$1')"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:attribute>
                        </xsl:when>
                        <xsl:when test="matches(., 'vol\.\s*\d+')">
                            <xsl:attribute name="unit" select="'volume'"/>
                            <xsl:attribute name="from">
                                <xsl:value-of select="replace(., '^.*vol\.\s*(\d+).*$', '$1')"/>
                            </xsl:attribute>
                            <xsl:attribute name="to">
                                <xsl:choose>
                                    <xsl:when test="matches(., '\d+\s*-\s*\d+')">
                                        <xsl:value-of select="replace(., '^.*\d+\s*-\s*(\d+).*$', '$1')"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="replace(., '^.*vol\.\s*(\d+).*$', '$1')"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:attribute>
                        </xsl:when>
                        <xsl:when test="matches(., '^\d+$')">
                            <xsl:attribute name="from" select="."/>
                            <xsl:attribute name="to" select="."/>
                        </xsl:when>
                        <xsl:when test="matches(., '^\d+\-\d+$')">
                            <xsl:attribute name="from" select="substring-before(., '-')"/>
                            <xsl:attribute name="to" select="substring-after(., '-')"/>
                        </xsl:when>
                    </xsl:choose>
                    <!-- content -->
                    <xsl:apply-templates mode="m_postprocess"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- I think thus should be left to an additional step of post processing -->
    <!--<xsl:template match="tei:date" mode="m_postprocess" priority="2">
        <xsl:copy-of select="oape:date-add-attributes(., $p_id-change)"/>
    </xsl:template>-->
    <xsl:function name="oape:strings_trim-punctuation-marks">
        <xsl:param as="xs:string" name="p_input"/>
        <xsl:variable name="v_punctuation" select="'[,،\.:;\?!\-–—_/]'"/>
        <xsl:analyze-string regex="^{$v_punctuation}*\s*(.+)\s*{$v_punctuation}$" select="$p_input">
            <xsl:matching-substring>
                <xsl:value-of select="normalize-space(regex-group(1))"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:value-of select="normalize-space(.)"/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
</xsl:stylesheet>
