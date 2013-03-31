<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:FM="http://www.filemaker.com/fmpxmlresult"
  exclude-result-prefixes="FM">

  <!-- Transform FMPXMLRESULT into fmresultset -->

  <!-- Key to group fields by their table -->
  <xsl:key name="field-by-table" match="FM:FIELD" 
    use="substring-before(@NAME, '::')" />

  <!-- Fields, grouped by table (i.e. first field from each table) --> 
  <xsl:variable name="first-table-field" select="/FM:FMPXMLRESULT 
      /FM:METADATA /FM:FIELD[ count( . | key( 'field-by-table', 
      substring-before(@NAME, '::') )[1]) = 1 ]" />

  <xsl:template match="/">
    <xsl:for-each select="FM:FMPXMLRESULT">
      <fmresultset xmlns="http://www.filemaker.com/xml/fmresultset" 
          version="1.0">
        <error code="{ERRORCODE}" />
        <xsl:for-each select="FM:PRODUCT">
          <product name="{@NAME}" version="{@VERSION}" build="{@BUILD}" />
        </xsl:for-each>
        <xsl:for-each select="FM:DATABASE">
          <datasource database="{@NAME}" 
              table="N/A" layout="{@LAYOUT}" total-count="{@RECORDS}" 
              date-format="{@DATEFORMAT}" time-format="{@TIMEFORMAT}" 
              timestamp-format="{@DATEFORMAT} {@TIMEFORMAT}" />
        </xsl:for-each>
        <xsl:for-each select="FM:METADATA">
          <metadata>
            <!-- Output fields, grouping them by table (Muenchian) -->
            <xsl:for-each select="$first-table-field">
              <xsl:variable name="table" 
                  select="substring-before( @NAME, '::' )" />
              <xsl:variable name="table-fields" 
                  select="key( 'field-by-table', $table )" />
              <xsl:choose>
                <xsl:when test="not(string($table))">
                  <!-- Base table -->
                  <xsl:for-each select="$table-fields">
                    <xsl:call-template name="field-definition" />
                  </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                  <!-- Related table -->
                  <relatedset-definition table="{$table}">
                    <xsl:for-each select="$table-fields">
                      <xsl:call-template name="field-definition" />
                    </xsl:for-each>
                  </relatedset-definition>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each>
          </metadata>
        </xsl:for-each>
        <xsl:for-each select="FM:RESULTSET">
          <resultset count="{@FOUND}">
            <xsl:for-each select="FM:ROW">
              <record record-id="{@RECORDID}" mod-id="{@MODID}">
                <xsl:variable name="row" select="." />
                <!-- Output data grouping by table; similar to fields -->
                <xsl:for-each select="$first-table-field">
                  <xsl:variable name="table" 
                      select="substring-before(@NAME, '::')" />
                  <xsl:variable name="table-fields" 
                      select="key( 'field-by-table', $table)" />
                  <xsl:choose>
                    <xsl:when test="not(string($table))">
                      <!-- Base table; FM:DATA are repetitions -->
                      <xsl:for-each select="$table-fields">
                        <xsl:variable name="col" select="count( 
                            preceding-sibling::FM:FIELD ) + 1" />
                        <field name="{@NAME}">
                          <xsl:for-each select="$row/FM:COL[$col]/FM:DATA">
                            <data>
                              <xsl:value-of select="." />
                            </data>
                          </xsl:for-each>
                        </field>
                      </xsl:for-each>
                    </xsl:when>
                    <xsl:otherwise>
                      <!-- Related field; FM:DATA are records -->
                      <xsl:variable name="my-col" select="count( 
                          preceding-sibling::FM:FIELD ) + 1" />
                      <xsl:variable name="my-col-data" 
                          select="$row/FM:COL[$my-col]/FM:DATA" />
                      <relatedset table="{$table}" 
                            count="{count($my-col-data)}">
                        <xsl:for-each select="$my-col-data">
                          <xsl:variable name="my-row" select="position()" />
                          <record record-id="{position()}">
                            <xsl:for-each select="$table-fields">
                              <xsl:variable name="col" select="count( 
                                  preceding-sibling::FM:FIELD ) + 1" />
                              <field name="{@NAME}">
                                <data>
                                  <xsl:value-of select="$row /FM:COL[$col] 
                                      /FM:DATA[$my-row]" />
                                </data>
                              </field>
                            </xsl:for-each>
                          </record>
                        </xsl:for-each>
                      </relatedset>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:for-each>
              </record>
            </xsl:for-each>
          </resultset>
        </xsl:for-each>
      </fmresultset>
    </xsl:for-each>
  </xsl:template>

  <!-- Convert current FM:FIELD into field-definition -->
  <xsl:template name="field-definition">
    <field-definition xmlns="http://www.filemaker.com/xml/fmresultset" 
        name="{@NAME}" max-repeat="{@MAXREPEAT}"
        result="{translate(@TYPE, $UC, $lc)}" type="normal" 
        auto-enter="no" four-digit-year="no" time-of-day="no" 
        numeric-only="no" global="no">
      <xsl:attribute name="not-empty">
        <xsl:choose>
          <xsl:when test="@EMPTYOK = 'YES'">no</xsl:when>
          <xsl:otherwise>yes</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
    </field-definition>
  </xsl:template>

  <!-- U&lc variables -->
  <xsl:variable name="UC" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" /> 
  <xsl:variable name="lc" select="'abcdefghijklmnopqrstuvwxyz'" /> 

</xsl:stylesheet>
