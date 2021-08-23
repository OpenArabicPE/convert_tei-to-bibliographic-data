<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns:bib="http://purl.org/net/biblio#" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/"
    xmlns:foaf="http://xmlns.com/foaf/0.1/" xmlns:html="http://www.w3.org/1999/xhtml" xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <!-- This stylesheet takes MARC21 records in XML serialisation as input and generates TEI XML as output -->
    <!-- documentation of the MARC21 field codes can be found here: https://marc21.ca/M21/MARC-Field-Codes.html -->
    <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no"/>
    <xsl:include href="functions.xsl"/>
    
    <!-- these parameters are placeholders until I established a way of pulling language information from the source -->
    <xsl:param name="p_lang-1" select="'ar'"/>
    <xsl:param name="p_lang-2" select="'ar-Latn-x-ijmes'"/>
    
    <!-- output: everything is wrapped in a listBibl -->
    <xsl:template match="/">
        <xsl:element name="listBibl">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <!-- individual records: pull approach -->
    <xsl:template match="marc:record">
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
        <xsl:element name="biblStruct">
            <!-- frequency -->
            <xsl:apply-templates select="marc:datafield[@tag = '310']/marc:subfield"/>
            <xsl:if test="$v_analytic = true()">
                <xsl:element name="analytic">
                    <!-- titles: 245, 246 -->
                    <xsl:apply-templates select="marc:datafield[@tag = ('245', '246')]/marc:subfield[@code = ('a', 'b')]"/>
                    <!-- main contributors -->
                    <xsl:apply-templates select="marc:datafield[@tag = ('100', '101')]/marc:subfield[@code = '4']"/>
                    <!-- IDs -->
                    <xsl:apply-templates select="marc:datafield[@tag = ('024')]/marc:subfield"/>
                </xsl:element>
            </xsl:if>
            <xsl:element name="monogr">
                <xsl:if test="$v_analytic = true()">
                    <xsl:apply-templates select="marc:datafield[@tag = '773']/marc:subfield[@code = ('a', 't')]"/>
                </xsl:if>
                <xsl:if test="$v_analytic = false()">
                    <!-- titles: 245, 246 -->
                    <xsl:apply-templates select="marc:datafield[@tag = ('245', '246')]/marc:subfield[@code = ('a', 'b')]"/>
                    <!-- main contributors -->
                    <xsl:apply-templates select="marc:datafield[@tag = ('100', '101')]/marc:subfield[@code = '4']"/>
                </xsl:if>
                
                <!-- editors: 264 shouldn't have been used for the editor -->
                <!--<xsl:apply-templates select="marc:datafield[@tag = '264']/marc:subfield[@code = 'b']"/>-->
                <!-- language -->
                <!-- IDs -->
                <xsl:apply-templates select="marc:datafield[@tag = ('020', '022')]/marc:subfield"/>
                <xsl:if test="$v_analytic = false()">
                    <xsl:apply-templates select="marc:datafield[@tag = ('024')]/marc:subfield"/>
                </xsl:if>
                <!-- imprint -->
                <xsl:element name="imprint">
                    <!-- full imprint in one field -->
                    <!-- problem: the publisher might be the editor in our understanding -->
                    <xsl:apply-templates select="marc:datafield[@tag = '264']/marc:subfield"/>
                    <xsl:if test="$v_analytic = true()">
                        <xsl:apply-templates select="marc:datafield[@tag = '773']/marc:subfield[@code = 'd']"/>
                    </xsl:if>
                </xsl:element>
                <!-- name/number of sections of a work -->
                <xsl:apply-templates select="marc:datafield[@tag = ('245', '246')]/marc:subfield[@code = ('n')]"/>
                <xsl:apply-templates select="marc:datafield[@tag = '936']/marc:subfield[@code = ('d', 'e')]"/>
            </xsl:element>
            <xsl:if test="$v_analytic = true()">
                <xsl:apply-templates select="marc:datafield[@tag = '936']/marc:subfield[@code = ('h')]"/>
            </xsl:if>
        </xsl:element>
    </xsl:template>
    
    <!-- one template to convert marc:subfields into TEI -->
    <xsl:template match="marc:subfield">
        <xsl:variable name="v_tag" select="parent::marc:datafield/@tag"/>
        <xsl:variable name="v_code" select="@code"/>
        <xsl:variable name="v_ind1" select="parent::marc:datafield/@ind1"/>
        <xsl:variable name="v_ind2" select="parent::marc:datafield/@ind2"/>
        <!-- text fields can have trailing punctuation, which should be removed -->
        <xsl:variable name="v_content">
            <xsl:value-of select="oape:strings_trim-punctuation-marks(.)"/>
            <!--            <xsl:apply-templates mode="m_plain-text"/>-->
        </xsl:variable>
        <!-- languages: can potentially depend on local data or parameters -->
        <!-- language information can be found in 041/a and 101/a -->
        <xsl:variable name="v_lang-1">
            <xsl:choose>
                <xsl:when test="ancestor::marc:record/marc:datafield[@tag = '041']/marc:subfield[@code = 'a']">
                    <xsl:apply-templates mode="m_plain-text" select="ancestor::marc:record/marc:datafield[@tag = '041']/marc:subfield[@code = 'a']"/>
                </xsl:when>
                <xsl:when test="ancestor::marc:record/marc:datafield[@tag = '101']/marc:subfield[@code = 'a']">
                    <xsl:apply-templates mode="m_plain-text" select="ancestor::marc:record/marc:datafield[@tag = '101']/marc:subfield[@code = 'a']"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$p_lang-1"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_lang-2" select="$p_lang-2"/>
        <xsl:choose>
            <!-- code "0": IDs from authority files -->
            <xsl:when test="$v_code = '0' and $v_tag = ('100', '689', '700')">
                <xsl:variable name="v_auth" select="replace($v_content, '^\((.+)\).+$', '$1')"/>
                <xsl:variable name="v_id" select="replace($v_content, '^\(.+\)(.+)$', '$1')"/>
                <xsl:choose>
                    <!-- GND -->
                    <xsl:when test="$v_auth = 'DE-588'">
                        <xsl:value-of select="concat('gnd:', $v_id)"/>
                    </xsl:when>
                    <!--<xsl:otherwise>
                            <xsl:value-of select="$v_content"/>
                        </xsl:otherwise>-->
                </xsl:choose>
                <xsl:if test="following-sibling::marc:subfield[@code = '0']">
                    <xsl:text> </xsl:text>
                </xsl:if>
            </xsl:when>
            <!-- 008 - FIXED-LENGTH DATA ELEMENTS -\- General information (NR)  -->
            <!-- IDs -->
            <xsl:when test="$v_tag = ('020', '022', '024') and $v_code = 'a'">
                <xsl:element name="idno">
                    <xsl:attribute name="type">
                        <xsl:choose>
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
            <!-- 100: contributor -->
            <!-- 100 - MAIN ENTRY-\-PERSONAL NAME (NR) -->
            <!-- 110 - MAIN ENTRY-\-CORPORATE NAME (NR)  -->
            <xsl:when test="$v_tag = '100'">
                <xsl:choose>
                    <xsl:when test="$v_code = '4' and $v_content = 'aut'">
                        <xsl:element name="author">
                            <!-- content -->
                            <xsl:apply-templates select="parent::marc:datafield/marc:subfield[@code = 'a']"/>
                        </xsl:element>
                    </xsl:when>
                    <!-- does the name field assume specific formating? I have seen "surname, forename(s)"  -->
                    <xsl:when test="$v_code = 'a'">
                        <xsl:element name="persName">
                            <!-- ID -->
                            <xsl:if test="parent::marc:datafield/marc:subfield[@code = '0']">
                                <xsl:attribute name="ref">
                                    <xsl:apply-templates select="parent::marc:datafield/marc:subfield[@code = '0']"/>
                                </xsl:attribute>
                            </xsl:if>
                            <!-- content -->
                            <xsl:value-of select="$v_content"/>
                        </xsl:element>
                    </xsl:when>
                    <!-- code "d": life-dates -->
                </xsl:choose>
            </xsl:when>
            <!-- titles 
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
                            <xsl:attribute name="xml:lang">
                                <xsl:choose>
                                    <xsl:when test="$v_tag = '245'">
                                        <xsl:value-of select="$v_lang-1"/>
                                    </xsl:when>
                                    <xsl:when test="$v_tag = '246'">
                                        <xsl:value-of select="$v_lang-2"/>
                                    </xsl:when>
                                    <!-- fallback? -->
                                </xsl:choose>
                            </xsl:attribute>
                            <!-- content -->
                            <xsl:value-of select="$v_content"/>
                        </xsl:element>
                    </xsl:when>
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
            <xsl:when test="$v_tag = '264'">
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
                            <xsl:value-of select="$v_content"/>
                        </xsl:element>
                    </xsl:when>
                    <!-- $c - Date of production, publication, distribution, manufacture, or copyright notice (R)  -->
                    <xsl:when test="$v_code = 'c'">
                        <xsl:element name="date">
                            <xsl:if test="matches($v_content, '^\d{4}$')">
                                <xsl:attribute name="when" select="$v_content"/>
                            </xsl:if>
                            <xsl:value-of select="$v_content"/>
                        </xsl:element>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
            <!-- 490: series statement -->
            <!-- 250: edition statement      -->
            <!-- 300: format, such as microfilm etc. -->
            <!-- 310: frequency -->
            <xsl:when test="$v_tag = '310'">
                <!-- analyse string for controlled vocabulary -->
                <xsl:variable name="v_frequency">
                    <xsl:choose>
                        <xsl:when test="matches(., '(نصف .سبوعية|مرتين بال.سبوع|مرتين في ال.سبوع)')">
                            <xsl:text>biweekly</xsl:text>
                        </xsl:when>
                        <xsl:when test="matches(., '(نصف شهرية|مرتين بالشهر|مرتين في الشهر|كل .سبوعين مرة)')">
                            <xsl:text>fortnightly</xsl:text>
                        </xsl:when>
                        <xsl:when test="matches(., '(.ربع مرات في السنة|كل ثلاثة .شهر)')">
                            <xsl:text>quarterly</xsl:text>
                        </xsl:when>
                        <xsl:when test="matches(., '^سنوية$')">
                            <xsl:text>anually</xsl:text>
                        </xsl:when>
                        <xsl:when test="matches(., '(شهرية|مرة في الشهر)')">
                            <xsl:text>monthly</xsl:text>
                        </xsl:when>
                        <xsl:when test="matches(., '^.سبوعية$')">
                            <xsl:text>weekly</xsl:text>
                        </xsl:when>
                        <xsl:when test="matches(., '^يومية$')">
                            <xsl:text>daily</xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </xsl:variable>
                <xsl:if test="$v_frequency != ''">
                    <xsl:attribute name="oape:frequency" select="$v_frequency"/>
                </xsl:if>
            </xsl:when>
            <!-- 530: shelfmark -->
            <!-- 530 - ADDITIONAL PHYSICAL FORM AVAILABLE NOTE (R)  -->
            <!-- 590: availability -->
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
            <!-- 936: -->
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
                            <xsl:if test="matches($v_content, '^\d+$')">
                                <xsl:attribute name="from" select="$v_content"/>
                                <xsl:attribute name="to" select="$v_content"/>
                            </xsl:if>
                            <xsl:if test="matches($v_content, '^\d+\-\d+$')">
                                <xsl:attribute name="from" select="substring-before($v_content, '-')"/>
                                <xsl:attribute name="to" select="substring-after($v_content, '-')"/>
                            </xsl:if>
                            <!-- content -->
                            <xsl:value-of select="$v_content"/>
                        </xsl:element>
                    </xsl:when>
                    <!-- date -->
                    <!-- date of publication -->
                    <xsl:when test="$v_code = 'j'">
                        <xsl:element name="date">
                            <xsl:if test="matches($v_content, '^\d{4}$')">
                                <xsl:attribute name="when" select="$v_content"/>
                            </xsl:if>
                            <xsl:value-of select="$v_content"/>
                        </xsl:element>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <xsl:template name="codeLangue">
        <xsl:param name="code"/>
        <xsl:variable name="var"
            >;aar=aa;abk=ab;afr=af;aka=ak;amh=am;ara=ar;arg=an;asm=as;ava=av;ave=ae;aym=ay;aze=az;bak=ba;bam=bm;bel=be;ben=bn;bis=bi;tib=bo;bos=bs;bre=br;bul=bg;cat=ca;cze=cs;cha=ch;che=ce;chu=cu;chv=cv;cor=kw;cos=co;cre=cr;wel=cy;dan=da;ger=de;div=dv;dzo=dz;gre=el;eng=en;epo=eo;est=et;baq=eu;ewe=ee;fao=fo;per=fa;fij=fj;fin=fi;fre=fr;fry=fy;ful=ff;gla=gd;gle=ga;glg=gl;glv=gv;grn=gn;guj=gu;hat=ht;hau=ha;=sh;heb=he;her=hz;hin=hi;hmo=ho;hrv=hr;hun=hu;arm=hy;ibo=ig;ido=io;iii=ii;iku=iu;ile=ie;ina=ia;ind=id;ipk=ik;ice=is;ita=it;jav=jv;jpn=ja;kal=kl;kan=kn;kas=ks;geo=ka;kau=kr;kaz=kk;khm=km;kik=ki;kin=rw;kir=ky;kom=kv;kon=kg;kor=ko;kua=kj;kur=ku;lao=lo;lat=la;lav=lv;lim=li;lin=ln;lit=lt;ltz=lb;lub=lu;lug=lg;mah=mh;mal=ml;mar=mr;mac=mk;mlg=mg;mlt=mt;mon=mn;mao=mi;may=ms;bur=my;nau=na;nav=nv;nbl=nr;nde=nd;ndo=ng;nep=ne;dut=nl;nno=nn;nob=nb;nor=no;nya=ny;oci=oc;oji=oj;ori=or;orm=om;oss=os;pan=pa;pli=pi;pol=pl;por=pt;pus=ps;que=qu;roh=rm;rum=ro;run=rn;rus=ru;sag=sg;san=sa;sin=si;slo=sk;slv=sl;sme=se;smo=sm;sna=sn;snd=sd;som=so;sot=st;spa=es;alb=sq;srd=sc;srp=sr;ssw=ss;sun=su;swa=sw;swe=sv;tah=ty;tam=ta;tat=tt;tel=te;tgk=tg;tgl=tl;tha=th;tir=ti;ton=to;tsn=tn;tso=ts;tuk=tk;tur=tr;twi=tw;uig=ug;ukr=uk;urd=ur;uzb=uz;ven=ve;vie=vi;vol=vo;wln=wa;wol=wo;xho=xh;yid=yi;yor=yo;zha=za;chi=zh;zul=zu</xsl:variable>
        <xsl:value-of select="substring-before(substring-after($var, concat(';', $code, '=')), ';')"/>
    </xsl:template>
</xsl:stylesheet>
