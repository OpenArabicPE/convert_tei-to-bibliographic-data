<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
     xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
 xmlns:bib="http://purl.org/net/biblio#"
 xmlns:foaf="http://xmlns.com/foaf/0.1/"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:dcterms="http://purl.org/dc/terms/"
  xmlns:tei="http://www.tei-c.org/ns/1.0" 
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:oape="https://openarabicpe.github.io/ns"
 xmlns:marc="http://www.loc.gov/MARC21/slim"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="#all"
   xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    version="3.0">
    
    <xsl:output method="xml" indent="yes" omit-xml-declaration="no" encoding="UTF-8"/>
    
    <xsl:include href="functions.xsl"/>
    
    <xsl:param name="p_lang-1" select="'ar'"/>
    <xsl:param name="p_lang-2" select="'ar-Latn-x-ijmes'"/>
    
    <xsl:template match="/">
        <xsl:element name="listBibl">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <!-- pull approach -->
    <xsl:template match="marc:record">
        <xsl:element name="biblStruct">
            <!-- frequency -->
            <xsl:apply-templates select="marc:datafield[@tag = '310']/marc:subfield"/>
            <xsl:element name="monogr">
                <!-- titles -->
                <xsl:apply-templates select="marc:datafield[@tag = ('245', '246')]/marc:subfield"/>
                <!-- editors -->
                <xsl:apply-templates select="marc:datafield[@tag = '264']/marc:subfield[@code = 'b']"/>
                <!-- language -->
                <!-- IDs -->
                <xsl:element name="imprint">
                    <!-- full imprint in one field -->
                    <!-- problem: the publisher might be the editor in our understanding -->
                    <xsl:apply-templates select="marc:datafield[@tag = '264']/marc:subfield"/>
                </xsl:element>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    
    <!-- how to establish the level of a title or type of publication? -->
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
                    <xsl:apply-templates select="ancestor::marc:record/marc:datafield[@tag = '041']/marc:subfield[@code = 'a']" mode="m_plain-text"/>
                </xsl:when>
                <xsl:when test="ancestor::marc:record/marc:datafield[@tag = '101']/marc:subfield[@code = 'a']">
                    <xsl:apply-templates select="ancestor::marc:record/marc:datafield[@tag = '101']/marc:subfield[@code = 'a']" mode="m_plain-text"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$p_lang-1"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_lang-2" select="$p_lang-2"/>
        <xsl:choose>
            <!-- 008 - FIXED-LENGTH DATA ELEMENTS -\- General information (NR)  -->
            <!-- titles -->
            <!-- 222: duplicate of the title field -->
            <xsl:when test="$v_tag = ('245', '246')">
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
            <!-- imprint -->
            <xsl:when test="$v_tag = '264'">
                <xsl:choose>
                    <xsl:when test="$v_code = 'a'">
                        <xsl:element name="pubPlace">
                            <xsl:element name="placeName">
                                <xsl:value-of select="$v_content"/>
                            </xsl:element>
                        </xsl:element>
                    </xsl:when>
                    <!-- publisher/ editor of a periodical -->
                    <!-- I have currently no means to establish which one it is! -->
                    <xsl:when test="$v_code = 'b'">
                        <xsl:element name="publisher">
                            <!-- we should not assume an orgName as additional wrapper! -->
                                <xsl:value-of select="$v_content"/>
                        </xsl:element>
                    </xsl:when>
                    <xsl:when test="$v_code = 'c'">
                        <xsl:element name="date">
                                <xsl:value-of select="$v_content"/>
                        </xsl:element>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
            <!-- 100: contributor -->
            <!-- 100 - MAIN ENTRY-\-PERSONAL NAME (NR) -->
            <!-- 110 - MAIN ENTRY-\-CORPORATE NAME (NR)  -->
            <xsl:when test="$v_tag = '100'">
                <xsl:choose>
                    <xsl:when test="$v_code = '4' and $v_content = 'aut'">
                        <xsl:element name="author">
                            <xsl:apply-templates select="parent::marc:datafield/marc:subfield[@code = 'a']"/>
                        </xsl:element>
                    </xsl:when>
                    <!-- does the name field assume specific formating? I have seen "surname, forename(s)"  -->
                    <xsl:when test="$v_code = 'a'">
                        <xsl:element name="persName">
                            <xsl:value-of select="$v_content"/>
                        </xsl:element>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
            <!-- 300: format, such as microfilm etc. -->
            <!-- 310: frequency -->
            <xsl:when test="$v_tag = '310'">
                <!-- analyse string for controlled vocabulary -->
                <xsl:attribute name="oape:frequency">
                    <xsl:choose>
                        <xsl:when test="matches(., '(نصف .سبوعية|مرتين بال.سبوع|مرتين في ال.سبوع)')">
                            <xsl:text>biweekly</xsl:text>
                        </xsl:when>
                        <xsl:when test="matches(., '(نصف شهرية|مرتين بالشهر|مرتين في الشهر)')">
                            <xsl:text>fortnightly</xsl:text>
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
                </xsl:attribute>
            </xsl:when>
            <!-- 530: shelfmark -->
            <!-- 530 - ADDITIONAL PHYSICAL FORM AVAILABLE NOTE (R)  -->
            <!-- IDs -->
            <xsl:when test="$v_tag = '020'">
                <xsl:element name="idno">
                    <xsl:attribute name="type" select="'ISBN'"/>
                    <xsl:value-of select="$v_content"/>
                </xsl:element>
            </xsl:when>
            <xsl:when test="$v_tag = '022'">
                <xsl:element name="idno">
                    <xsl:attribute name="type" select="'ISSN'"/>
                    <xsl:value-of select="$v_content"/>
                </xsl:element>
            </xsl:when>
            <!-- 590: availability -->
            <!-- 866: extent of collection -->
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="codeLangue">
      <xsl:param name="code"/>
      <xsl:variable name="var">;aar=aa;abk=ab;afr=af;aka=ak;amh=am;ara=ar;arg=an;asm=as;ava=av;ave=ae;aym=ay;aze=az;bak=ba;bam=bm;bel=be;ben=bn;bis=bi;tib=bo;bos=bs;bre=br;bul=bg;cat=ca;cze=cs;cha=ch;che=ce;chu=cu;chv=cv;cor=kw;cos=co;cre=cr;wel=cy;dan=da;ger=de;div=dv;dzo=dz;gre=el;eng=en;epo=eo;est=et;baq=eu;ewe=ee;fao=fo;per=fa;fij=fj;fin=fi;fre=fr;fry=fy;ful=ff;gla=gd;gle=ga;glg=gl;glv=gv;grn=gn;guj=gu;hat=ht;hau=ha;=sh;heb=he;her=hz;hin=hi;hmo=ho;hrv=hr;hun=hu;arm=hy;ibo=ig;ido=io;iii=ii;iku=iu;ile=ie;ina=ia;ind=id;ipk=ik;ice=is;ita=it;jav=jv;jpn=ja;kal=kl;kan=kn;kas=ks;geo=ka;kau=kr;kaz=kk;khm=km;kik=ki;kin=rw;kir=ky;kom=kv;kon=kg;kor=ko;kua=kj;kur=ku;lao=lo;lat=la;lav=lv;lim=li;lin=ln;lit=lt;ltz=lb;lub=lu;lug=lg;mah=mh;mal=ml;mar=mr;mac=mk;mlg=mg;mlt=mt;mon=mn;mao=mi;may=ms;bur=my;nau=na;nav=nv;nbl=nr;nde=nd;ndo=ng;nep=ne;dut=nl;nno=nn;nob=nb;nor=no;nya=ny;oci=oc;oji=oj;ori=or;orm=om;oss=os;pan=pa;pli=pi;pol=pl;por=pt;pus=ps;que=qu;roh=rm;rum=ro;run=rn;rus=ru;sag=sg;san=sa;sin=si;slo=sk;slv=sl;sme=se;smo=sm;sna=sn;snd=sd;som=so;sot=st;spa=es;alb=sq;srd=sc;srp=sr;ssw=ss;sun=su;swa=sw;swe=sv;tah=ty;tam=ta;tat=tt;tel=te;tgk=tg;tgl=tl;tha=th;tir=ti;ton=to;tsn=tn;tso=ts;tuk=tk;tur=tr;twi=tw;uig=ug;ukr=uk;urd=ur;uzb=uz;ven=ve;vie=vi;vol=vo;wln=wa;wol=wo;xho=xh;yid=yi;yor=yo;zha=za;chi=zh;zul=zu</xsl:variable>
      <xsl:value-of select="substring-before(substring-after($var, concat(';', $code, '=')), ';')"/>
   </xsl:template>
</xsl:stylesheet>