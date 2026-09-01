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
    DATA(lt) = mo->enum_values( 'ZAB_V1_UT_AREA' ).
    cl_abap_unit_assert=>assert_equals( exp = 18 act = lines( lt ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( lt[ name = 'JSON' ] ) ) ).
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
