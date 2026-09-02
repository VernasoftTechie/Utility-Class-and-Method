*"* use this source file for your ABAP unit test classes

CLASS ltc_cfg DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo TYPE REF TO zif_ab_v1_ut_cfg.
    METHODS setup.
    METHODS enum_area       FOR TESTING RAISING zcx_ab_v1_ut.
    METHODS tvarv_missing   FOR TESTING.
    METHODS feature_off     FOR TESTING.
ENDCLASS.


CLASS ltc_cfg IMPLEMENTATION.

  METHOD setup.
    mo = NEW zcl_ab_v1_ut_cfg( ).
  ENDMETHOD.

  METHOD enum_area.
    " domain carries the 18 v1.0 areas + the 5 v1.1 toolkit areas
    DATA(lt) = mo->enum_values( 'ZAB_V1_UT_AREA' ).
    cl_abap_unit_assert=>assert_true( xsdbool( lines( lt ) >= 18 ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( lt[ name = 'JSON' ] ) ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( lt[ name = 'HTTP' ] ) ) ).
  ENDMETHOD.

  METHOD tvarv_missing.
    TRY.
        mo->tvarv_value( 'ZZ_AB_V1_UT_NO_SUCH_VAR' ).
        cl_abap_unit_assert=>fail( 'expected exception' ).
      CATCH zcx_ab_v1_ut.
    ENDTRY.
  ENDMETHOD.

  METHOD feature_off.
    cl_abap_unit_assert=>assert_false( mo->is_feature_on( 'ZZ_AB_V1_UT_NO_SUCH_FEATURE' ) ).
  ENDMETHOD.

ENDCLASS.
