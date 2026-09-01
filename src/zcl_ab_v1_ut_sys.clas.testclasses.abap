*"* use this source file for your ABAP unit test classes

CLASS ltc_sys DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo TYPE REF TO zif_ab_v1_ut_sys.
    METHODS setup.
    METHODS info          FOR TESTING.
    METHODS exists_tabl    FOR TESTING.
    METHODS exists_clas    FOR TESTING.
    METHODS exists_missing FOR TESTING.
    METHODS timer          FOR TESTING.
ENDCLASS.


CLASS ltc_sys IMPLEMENTATION.

  METHOD setup.
    mo = NEW zcl_ab_v1_ut_sys( ).
  ENDMETHOD.

  METHOD info.
    DATA(ls) = mo->system_info( ).
    cl_abap_unit_assert=>assert_equals( exp = sy-sysid act = ls-sysid ).
    cl_abap_unit_assert=>assert_equals( exp = sy-mandt act = ls-client ).
  ENDMETHOD.

  METHOD exists_tabl.
    cl_abap_unit_assert=>assert_true( mo->object_exists( iv_type = 'TABL' iv_name = 'T000' ) ).
  ENDMETHOD.

  METHOD exists_clas.
    cl_abap_unit_assert=>assert_true( mo->object_exists( iv_type = 'CLAS' iv_name = 'ZCL_AB_V1_UT_STR' ) ).
  ENDMETHOD.

  METHOD exists_missing.
    cl_abap_unit_assert=>assert_false( mo->object_exists( iv_type = 'TABL' iv_name = 'ZZ_NO_SUCH_TABLE_XyZ' ) ).
  ENDMETHOD.

  METHOD timer.
    DATA(lv_h) = mo->timer_start( ).
    DATA lv_dummy TYPE i.
    DO 1000 TIMES.
      lv_dummy = lv_dummy + sy-index.
    ENDDO.
    mo->timer_stop( EXPORTING iv_handle = lv_h IMPORTING ev_seconds = DATA(lv_sec) ev_cpu_ms = DATA(lv_ms) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_sec >= 0 ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_ms >= 0 ) ).
  ENDMETHOD.

ENDCLASS.
