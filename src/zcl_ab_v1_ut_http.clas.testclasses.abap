*"* use this source file for your ABAP unit test classes

CLASS ltc_http DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo TYPE REF TO zif_ab_v1_ut_http.
    METHODS setup.
    METHODS fluent_returns_self FOR TESTING.
    METHODS odata_filter_t      FOR TESTING.
    METHODS odata_query_t       FOR TESTING.
    METHODS soap_envelope_t     FOR TESTING.
ENDCLASS.


CLASS ltc_http IMPLEMENTATION.

  METHOD setup.
    mo = NEW zcl_ab_v1_ut_http( ).
  ENDMETHOD.

  METHOD fluent_returns_self.
    DATA(lo) = mo->for_url( 'https://example.com' )->with_header( iv_name = 'X-Test' iv_value = '1'
                     )->with_retry( iv_max = 2 ).
    cl_abap_unit_assert=>assert_true( xsdbool( lo = mo ) ).
  ENDMETHOD.

  METHOD odata_filter_t.
    DATA(lv) = mo->odata_filter( VALUE #( ( name = 'Bukrs'  value = 'eq:1000' )
                                          ( name = 'Gjahr'  value = '2026' ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = |bukrs eq '1000' and gjahr eq '2026'| act = lv ).
  ENDMETHOD.

  METHOD odata_query_t.
    DATA(lt) = mo->odata_query( iv_filter = |name eq 'x'| iv_top = 50 iv_select = 'Id,Name' ).
    cl_abap_unit_assert=>assert_equals( exp = |name eq 'x'| act = lt[ name = '$filter' ]-value ).
    cl_abap_unit_assert=>assert_equals( exp = '50'          act = lt[ name = '$top' ]-value ).
    cl_abap_unit_assert=>assert_equals( exp = 'Id,Name'     act = lt[ name = '$select' ]-value ).
  ENDMETHOD.

  METHOD soap_envelope_t.
    DATA(lv) = mo->soap_envelope( iv_body_xml = |<web:Ping/>| ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv CS '<soapenv:Envelope' ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv CS '<soapenv:Body><web:Ping/></soapenv:Body>' ) ).
  ENDMETHOD.

ENDCLASS.
