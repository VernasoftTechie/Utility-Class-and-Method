*"* use this source file for your ABAP unit test classes

CLASS ltc_num DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo TYPE REF TO zif_ab_v1_ut_num.
    METHODS setup.
    METHODS next_increasing FOR TESTING.
ENDCLASS.


CLASS ltc_num IMPLEMENTATION.

  METHOD setup.
    mo = NEW zcl_ab_v1_ut_num( ).
  ENDMETHOD.

  METHOD next_increasing.
    " Needs SNRO object ZAB_V1_UT interval 01 - tolerate its absence.
    TRY.
        DATA(lv1) = mo->next( iv_object = 'ZAB_V1_UT' iv_interval = '01' ).
        DATA(lv2) = mo->next( iv_object = 'ZAB_V1_UT' iv_interval = '01' ).
        cl_abap_unit_assert=>assert_true( xsdbool( CONV decfloat34( lv2 ) > CONV decfloat34( lv1 ) ) ).
      CATCH zcx_ab_v1_ut.
        " number range object not set up in this system - nothing to assert
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
