<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:premis="http://www.loc.gov/premis/v3" xmlns:schema="http://schema.org/" xmlns:mhs="https://zeticon.mediahaven.com/metadata/22.1/mhs/" xmlns:mh="https://zeticon.mediahaven.com/metadata/22.1/mh/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" exclude-result-prefixes="dc premis dcterms xsi schema" version="1.1">
    <xsl:output version="1.0" encoding="UTF-8" standalone="yes" indent="yes" />
    <xsl:param name="cp_name" />
    <xsl:param name="cp_id" />
    <xsl:param name="sp_name" />
    <xsl:param name="pid" />
    <xsl:param name="original_filename" />
    <xsl:param name="md5" />
    <xsl:template match="premis:object">
        <mhs:Sidecar xmlns:mhs="https://zeticon.mediahaven.com/metadata/22.1/mhs/" xmlns:mh="https://zeticon.mediahaven.com/metadata/22.1/mh/" version="22.1">
            <!-- Descriptive -->
            <xsl:element name="mhs:Descriptive">
                <!-- Title -->
                <xsl:apply-templates select="dcterms:title[not(@xsi:type)]" />
                <!-- Description -->
                <xsl:apply-templates select="dcterms:description" />
            </xsl:element>
            <!-- Dynamic-->
            <xsl:element name="mhs:Dynamic">
                <!-- CP (NAME)) -->
                <xsl:element name="CP">
                    <xsl:value-of select="$cp_name" />
                </xsl:element>
                <!-- CP ID -->
                <xsl:element name="CP_id">
                    <xsl:value-of select="$cp_id" />
                </xsl:element>
                <!-- SP name -->
                <xsl:element name="sp_name">
                    <xsl:value-of select="$sp_name" />
                </xsl:element>
                <!-- PID -->
                <xsl:element name="PID">
                    <xsl:value-of select="$pid" />
                </xsl:element>
                <!-- md5 -->
                <xsl:element name="md5">
                    <xsl:value-of select="$md5" />
                </xsl:element>
                <!-- PID -->
                <!-- <xsl:apply-templates select="dcterms:identifier" /> -->
                <!-- local ID -->
                <xsl:apply-templates select="premis:objectIdentifier/premis:objectIdentifierType[text() = 'local_id']" />
                <!-- Other IDs -->
                <xsl:element name="dc_identifier_localids">
                    <xsl:apply-templates select="premis:objectIdentifier/premis:objectIdentifierType[not(text() = 'local_id')]" />
                    <xsl:element name="bestandsnaam">
                        <xsl:value-of select="$original_filename" />
                    </xsl:element>
                </xsl:element>
                <!-- Created -->
                <xsl:apply-templates select="dcterms:created" />
                <!-- Issued -->
                <xsl:apply-templates select="dcterms:issued" />
                <!-- Types -->
                <xsl:element name="dc_types">
                    <xsl:apply-templates select="schema:genre" />
                </xsl:element>
                <!-- Coverages -->
                <xsl:element name="dc_coverages">
                    <xsl:apply-templates select="dcterms:temporal" />
                    <xsl:apply-templates select="dcterms:spatial" />
                </xsl:element>
                <!-- Subjects/Trefwoorden -->
                <xsl:element name="dc_subjects">
                    <xsl:apply-templates select="dcterms:subject" />
                </xsl:element>
                <!-- Licenses -->
                <xsl:element name="dc_rights_licenses">
                    <xsl:apply-templates select="dcterms:license" />
                </xsl:element>
                <!-- Rights comment -->
                <xsl:apply-templates select="dcterms:rights" />
                <!-- Rights credit -->
                <xsl:apply-templates select="schema:creditText" />
                <!-- Rights owner - Auteur-->
                <xsl:element name="dc_rights_rightsOwners">
                    <xsl:apply-templates select="dcterms:rightsHolder[@schema:roleName='auteursrechthouder']" />
                </xsl:element>
                <!-- Rights holder - License-->
                <xsl:element name="dc_rights_rightsHolders">
                    <xsl:apply-templates select="dcterms:rightsHolder[@schema:roleName='licentiehouder']" />
                </xsl:element>
                <!-- Relations -->
                <xsl:element name="dc_relations">
                    <xsl:apply-templates select="dcterms:hasPart[@xsi:type='premis:intellectualEntity']" />
                    <xsl:apply-templates select="dcterms:isPartOf[@xsi:type='premis:intellectualEntity']" />
                    <xsl:apply-templates select="dcterms:relation[@xsi:type='premis:intellectualEntity']" />
                </xsl:element>
                <!-- Publishers -->
                <xsl:element name="dc_publishers">
                    <xsl:apply-templates select="dcterms:publisher" />
                </xsl:element>
                <!-- Languages -->
                <xsl:element name="dc_languages">
                    <xsl:apply-templates select="dcterms:language" />
                </xsl:element>
                <!-- Contributors -->
                <xsl:element name="dc_contributors">
                    <xsl:apply-templates select="dcterms:contributor" />
                </xsl:element>
                <!-- Creators -->
                <xsl:element name="dc_creators">
                    <xsl:apply-templates select="dcterms:creator" />
                </xsl:element>
                <!-- Description -->
                <xsl:apply-templates select="dcterms:abstract" />
                <!-- Description caption/ondertitels -->
                <xsl:apply-templates select="schema:caption" />
                <!-- Description transcript -->
                <xsl:apply-templates select="schema:transcript" />
                <!-- Titles -->
                <xsl:element name="dc_titles">
                    <xsl:apply-templates select="dcterms:isPartOf[@xsi:type='schema:Episode']/dcterms:title" />
                    <xsl:apply-templates select="dcterms:alternative" />
                    <xsl:apply-templates select="dcterms:isPartOf[@xsi:type='schema:ArchiveComponent']/dcterms:title" />
                    <xsl:apply-templates select="dcterms:isPartOf[@xsi:type='schema:ArchiveComponent']/dcterms:hasPart[@xsi:type='schema:ArchiveComponent']/dcterms:title" />
                    <xsl:apply-templates select="dcterms:title[@xsi:type='meemoo:RegistrationTitle']" />
                    <xsl:apply-templates select="dcterms:isPartOf[@xsi:type='schema:BroadcastEvent']/dcterms:title" />
                    <xsl:apply-templates select="dcterms:isPartOf[@xsi:type='schema:CreativeWorkSeason']/dcterms:title" />
                    <xsl:apply-templates select="dcterms:isPartOf[@xsi:type='schema:CreativeWorkSeason']/schema:seasonNumber" />
                    <xsl:apply-templates select="dcterms:isPartOf[@xsi:type='schema:CreativeWorkSeries']/dcterms:title" />
                    <xsl:apply-templates select="dcterms:isPartOf[@xsi:type='schema:CreativeWorkSeries']/dcterms:hasPart[@xsi:type='schema:CreativeWorkSeries']/dcterms:title" />
                    <xsl:apply-templates select="dcterms:isPartOf[@xsi:type='schema:CreativeWorkSeries']/dcterms:identifier" />
                </xsl:element>
                <!-- dc_description_programme -->
                <xsl:apply-templates select="dcterms:isPartOf[@xsi:type='schema:BroadcastEvent']/dcterms:description" />
            </xsl:element>
        </mhs:Sidecar>
    </xsl:template>
    <!-- Descriptive -->
    <!-- Title -->
    <xsl:template match="dcterms:title">
        <xsl:element name="mh:Title">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <!-- Description -->
    <xsl:template match="dcterms:description">
        <xsl:element name="mh:Description">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <!-- Dynamic-->
    <!-- PID -->
    <xsl:template match="dcterms:identifier">
        <xsl:element name="PID">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <!-- local ID -->
    <xsl:template match="premis:objectIdentifier/premis:objectIdentifierType[text() = 'local_id']">
        <xsl:element name="dc_identifier_localid">
            <xsl:value-of select="../premis:objectIdentifierValue/text()" />
        </xsl:element>
    </xsl:template>
    <!-- Other IDs -->
    <xsl:template match="premis:objectIdentifier/premis:objectIdentifierType[not(text() = 'local_id')]">
        <xsl:element name="{../premis:objectIdentifierType/text()}">
            <xsl:value-of select="../premis:objectIdentifierValue/text()" />
        </xsl:element>
    </xsl:template>
    <!-- Created -->
    <xsl:template match="dcterms:created">
        <xsl:element name="dcterms_created">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <!-- Issued -->
    <xsl:template match="dcterms:issued">
        <xsl:element name="dcterms_issued">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <!-- Types -->
    <xsl:template match="schema:genre">
        <xsl:element name="multiselect">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <!-- Coverages - temporal -->
    <xsl:template match="dcterms:temporal">
        <xsl:element name="tijd">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <!-- Coverages - spatial -->
    <xsl:template match="dcterms:spatial">
        <xsl:element name="ruimte">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <!-- Subjects/Trefwoorden -->
    <xsl:template match="dcterms:subject">
        <xsl:element name="Trefwoord">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <!-- Licenses -->
    <xsl:template match="dcterms:license">
        <xsl:element name="multiselect">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <!-- Rights comment -->
    <xsl:template match="dcterms:rights">
        <xsl:element name="dc_rights_comment">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <!-- Rights credit -->
    <xsl:template match="schema:creditText">
        <xsl:element name="dc_rights_credit">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <!-- Rights owner - Auteur-->
    <xsl:template match="dcterms:rightsHolder[@schema:roleName='auteursrechthouder']">
        <xsl:element name="Auteursrechthouder">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <!-- Rights holder - License-->
    <xsl:template match="dcterms:rightsHolder[@schema:roleName='licentiehouder']">
        <xsl:element name="Licentiehouder">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <!-- Relations -->
    <xsl:template match="dcterms:hasPart[@xsi:type='premis:intellectualEntity']">
        <xsl:element name="bevat">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:isPartOf[@xsi:type='premis:intellectualEntity']">
        <xsl:element name="is_deel_van">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:relation[@xsi:type='premis:intellectualEntity']">
        <xsl:element name="is_verwant_aan">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <!-- Publishers -->
    <xsl:template match="dcterms:publisher[@schema:roleName='distributeur']">
        <xsl:element name="Distributeur">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:publisher[@schema:roleName='exposant']">
        <xsl:element name="Exposant">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:publisher[@schema:roleName='persagentschap']">
        <xsl:element name="Persagentschap">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:publisher[not(@schema:roleName)]">
        <xsl:element name="Publisher">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <!-- Languages -->
    <xsl:template match="dcterms:language">
        <xsl:element name="multiselect">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <!-- Contributors -->
    <xsl:template match="dcterms:contributor[@schema:roleName='adviseur']">
        <xsl:element name="Adviseur">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:contributor[@schema:roleName='arrangeur']">
        <xsl:element name="Arrangeur">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:contributor[@schema:roleName='artistiek_directeur']">
        <xsl:element name="ArtistiekDirecteur">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:contributor[@schema:roleName='assistent']">
        <xsl:element name="Assistent">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:contributor[@schema:roleName='auteur']">
        <xsl:element name="Auteur">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:contributor[@schema:roleName='belichting']">
        <xsl:element name="Belichting">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:contributor[not(@schema:roleName)]">
        <xsl:element name="Bijdrager">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:contributor[@schema:roleName='cameraman']">
        <xsl:element name="Cameraman">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:contributor[@schema:roleName='coproducer']">
        <xsl:element name="Co-producer">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:contributor[@schema:roleName='commentator']">
        <xsl:element name="Commentator">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:contributor[@schema:roleName='componist']">
        <xsl:element name="Componist">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:contributor[@schema:roleName='decorontwerper']">
        <xsl:element name="Decorontwerper">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:contributor[@schema:roleName='dirigent']">
        <xsl:element name="Dirigent">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:contributor[@schema:roleName='fotografie']">
        <xsl:element name="Fotografie">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:contributor[@schema:roleName='geluid']">
        <xsl:element name="Geluid">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:contributor[@schema:roleName='kostuumontwerper']">
        <xsl:element name="Kostuumontwerper">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:contributor[@schema:roleName='kunstenaar']">
        <xsl:element name="Kunstenaar">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:contributor[@schema:roleName='make-up']">
        <xsl:element name="Make-up">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:contributor[@schema:roleName='muzikant']">
        <xsl:element name="Muzikant">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:contributor[@schema:roleName='nieuwsanker']">
        <xsl:element name="Nieuwsanker">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:contributor[@schema:roleName='omroeper']">
        <xsl:element name="Omroeper">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:contributor[@schema:roleName='onderzoeker']">
        <xsl:element name="Onderzoeker">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:contributor[@schema:roleName='postproductie']">
        <xsl:element name="Post-productie">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:contributor[@schema:roleName='producer']">
        <xsl:element name="Producer">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:contributor[@schema:roleName='reporter']">
        <xsl:element name="Reporter">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:contributor[@schema:roleName='scenarist']">
        <xsl:element name="Scenarist">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:contributor[@schema:roleName='soundtrack']">
        <xsl:element name="Soundtrack">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:contributor[@schema:roleName='sponsor']">
        <xsl:element name="Sponsor">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:contributor[@schema:roleName='technisch_adviseur']">
        <xsl:element name="Technischadviseur">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:contributor[@schema:roleName='uitvoerder']">
        <xsl:element name="Uitvoerder">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:contributor[@schema:roleName='vertaler']">
        <xsl:element name="Vertaler">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:contributor[@schema:roleName='verteller']">
        <xsl:element name="Verteller">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <!-- Creators -->
    <xsl:template match="dcterms:creator[@schema:roleName='acteur']">
        <xsl:element name="Acteur">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:creator[@schema:roleName='archiefvormer']">
        <xsl:element name="Archiefvormer">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:creator[@schema:roleName='auteur']">
        <xsl:element name="Auteur">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:creator[@schema:roleName='cast']">
        <xsl:element name="Cast">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:creator[@schema:roleName='choreograaf']">
        <xsl:element name="Choreograaf">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:creator[@schema:roleName='cineast']">
        <xsl:element name="Cineast">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:creator[@schema:roleName='componist']">
        <xsl:element name="Componist">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:creator[@schema:roleName='danser']">
        <xsl:element name="Danser">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:creator[@schema:roleName='documentairemaker']">
        <xsl:element name="Documentairemaker">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:creator[@schema:roleName='fotograaf']">
        <xsl:element name="Fotograaf">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:creator[@schema:roleName='interviewer']">
        <xsl:element name="Interviewer">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:creator[@schema:roleName='kunstenaar']">
        <xsl:element name="Kunstenaar">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:creator[not(@schema:roleName)]">
        <xsl:element name="Maker">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:creator[@schema:roleName='muzikant']">
        <xsl:element name="Muzikant">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:creator[@schema:roleName='opdrachtgever']">
        <xsl:element name="Opdrachtgever">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:creator[@schema:roleName='performer']">
        <xsl:element name="Performer">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:creator[@schema:roleName='producer']">
        <xsl:element name="Producer">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:creator[@schema:roleName='productiehuis']">
        <xsl:element name="Productiehuis">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:creator[@schema:roleName='regisseur']">
        <xsl:element name="Regisseur">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:creator[@schema:roleName='schrijver']">
        <xsl:element name="Schrijver">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <!-- Description -->
    <xsl:template match="dcterms:abstract">
        <xsl:element name="dc_description_lang">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <!-- Description caption/ondertitels -->
    <xsl:template match="schema:caption">
        <xsl:element name="dc_description_ondertitels">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <!-- Description transcript -->
    <xsl:template match="schema:transcript">
        <xsl:element name="dc_description_transcriptie">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <!-- Titles -->
    <xsl:template match="dcterms:isPartOf[@xsi:type='schema:Episode']/dcterms:title">
        <xsl:element name="aflevering">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:alternative">
        <xsl:element name="alternatief">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:isPartOf[@xsi:type='schema:ArchiveComponent']/dcterms:title">
        <xsl:element name="archief">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:isPartOf[@xsi:type='schema:ArchiveComponent']/dcterms:hasPart[@xsi:type='schema:ArchiveComponent']/dcterms:title">
        <xsl:element name="deelarchief">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:title[@xsi:type='meemoo:RegistrationTitle']">
        <xsl:element name="registratie">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:isPartOf[@xsi:type='schema:BroadcastEvent']/dcterms:title">
        <xsl:element name="programma">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:isPartOf[@xsi:type='schema:CreativeWorkSeason']/dcterms:title">
        <xsl:element name="seizoen">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:isPartOf[@xsi:type='schema:CreativeWorkSeason']/schema:seasonNumber">
        <xsl:element name="seizoennummer">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:isPartOf[@xsi:type='schema:CreativeWorkSeries']/dcterms:title">
        <xsl:element name="reeks">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:isPartOf[@xsi:type='schema:CreativeWorkSeries']/dcterms:hasPart[@xsi:type='schema:CreativeWorkSeries']/dcterms:title">
        <xsl:element name="deelreeks">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <xsl:template match="dcterms:isPartOf[@xsi:type='schema:CreativeWorkSeries']/dcterms:identifier">
        <xsl:element name="serienummer">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
    <!-- dc_description_programme -->
    <xsl:template match="dcterms:isPartOf[@xsi:type='schema:BroadcastEvent']/dcterms:description">
        <xsl:element name="dc_description_programme">
            <xsl:value-of select="text()" />
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>