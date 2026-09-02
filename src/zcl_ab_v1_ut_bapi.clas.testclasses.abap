*"* use this source file for your ABAP unit test classes

CLASS ltc_bapi DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo TYPE REF TO zif_ab_v1_ut_bapi.
    METHODS setup.
    METHODS bdc_builders     FOR TESTING.
    METHODS unknown_bapi     FOR TESTING.
    METHODS unknown_tcode    FOR TESTING.
    METHODS call_by_name_ro  FOR TESTING RAISING zcx_ab_v1_ut.
ENDCLASS.


CLASS ltc_bapi IMPLEMENTATION.

  METHOD setup.
    mo = NEW zcl_ab_v1_ut_bapi( ).
  ENDMETHOD.

  METHOD bdc_builders.
    DATA lt_bdc TYPE STANDARD TABLE OF bdcdata.
    mo->bdc_dynpro( EXPORTING iv_program = 'SAPMV45A' iv_dynpro = '0100'
                    CHANGING  ct_bdcdata = lt_bdc ).
    mo->bdc_field( EXPORTING iv_name = 'VBAK-AUART' iv_value = 'OR'
                   CHANGING  ct_bdcdata = lt_bdc ).
    mo->bdc_field( EXPORTING iv_name = 'BDC_OKCODE' iv_value = '/00'
                   CHANGING  ct_bdcdata = lt_bdc ).

    cl_abap_unit_assert=>assert_equals( exp = 3 act = lines( lt_bdc ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'SAPMV45A' act = lt_bdc[ 1 ]-program ).
    cl_abap_unit_assert=>assert_equals( exp = 'X'        act = lt_bdc[ 1 ]-dynbegin ).
    cl_abap_unit_assert=>assert_equals( exp = 'VBAK-AUART' act = lt_bdc[ 2 ]-fnam ).
    cl_abap_unit_assert=>assert_equals( exp = 'OR'          act = lt_bdc[ 2 ]-fval ).
  ENDMETHOD.

  METHOD unknown_bapi.
    TRY.
        mo->call( iv_bapi = CONV #( 'ZZ_NO_SUCH_FM_98765' ) it_params = VALUE #( ) ).
        cl_abap_unit_assert=>fail( 'expected ZCX_AB_V1_UT for unknown FM' ).
      CATCH zcx_ab_v1_ut ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

  METHOD unknown_tcode.
    DATA lt_e TYPE STANDARD TABLE OF bdcdata.
    TRY.
        mo->bdc_run( iv_tcode = CONV #( 'ZZZZ9' ) it_bdcdata = lt_e ).
        cl_abap_unit_assert=>fail( 'expected ZCX_AB_V1_UT for unknown tcode' ).
      CATCH zcx_ab_v1_ut ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

  METHOD call_by_name_ro.
    " RFC_SYSTEM_INFO: no imports, one EXPORTING structure - read only, always present.
    DATA ls_info TYPE rfcsi.
    mo->call_by_name( EXPORTING iv_bapi   = CONV #( 'RFC_SYSTEM_INFO' )
                      IMPORTING es_export = ls_info ).
    cl_abap_unit_assert=>assert_not_initial( act = ls_info-rfcdest ).
  ENDMETHOD.

ENDCLASS.
