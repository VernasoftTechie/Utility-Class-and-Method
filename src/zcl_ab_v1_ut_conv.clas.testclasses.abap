*"* use this source file for your ABAP unit test classes

CLASS ltc_conv DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo TYPE REF TO zif_ab_v1_ut_conv.
    METHODS setup.
    METHODS add_days_t       FOR TESTING.
    METHODS add_months_clamp FOR TESTING.
    METHODS add_years_t      FOR TESTING.
    METHODS diffs            FOR TESTING.
    METHODS age_t            FOR TESTING.
    METHODS period_month     FOR TESTING RAISING zcx_ab_v1_ut.
    METHODS period_quarter   FOR TESTING RAISING zcx_ab_v1_ut.
    METHODS weekday_range    FOR TESTING.
    METHODS round_modes      FOR TESTING.
    METHODS ts_roundtrip     FOR TESTING.
    METHODS workdays_opt     FOR TESTING.
ENDCLASS.


CLASS ltc_conv IMPLEMENTATION.

  METHOD setup.
    mo = NEW zcl_ab_v1_ut_conv( ).
  ENDMETHOD.

  METHOD add_days_t.
    cl_abap_unit_assert=>assert_equals( exp = CONV d( '20260131' )
                                        act = mo->add_days( iv_date = '20260101' iv_days = 30 ) ).
  ENDMETHOD.

  METHOD add_months_clamp.
    cl_abap_unit_assert=>assert_equals( exp = CONV d( '20260228' )
                                        act = mo->add_months( iv_date = '20260131' iv_months = 1 ) ).
    cl_abap_unit_assert=>assert_equals( exp = CONV d( '20251231' )
                                        act = mo->add_months( iv_date = '20260131' iv_months = -1 ) ).
  ENDMETHOD.

  METHOD add_years_t.
    cl_abap_unit_assert=>assert_equals( exp = CONV d( '20290115' )
                                        act = mo->add_years( iv_date = '20260115' iv_years = 3 ) ).
  ENDMETHOD.

  METHOD diffs.
    cl_abap_unit_assert=>assert_equals( exp = 30 act = mo->days_between( iv_from = '20260101' iv_to = '20260131' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 3  act = mo->months_between( iv_from = '20260101' iv_to = '20260401' ) ).
  ENDMETHOD.

  METHOD age_t.
    cl_abap_unit_assert=>assert_equals( exp = 25 act = mo->age( iv_dob = '20000901' iv_on = '20260831' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 26 act = mo->age( iv_dob = '20000901' iv_on = '20260901' ) ).
  ENDMETHOD.

  METHOD period_month.
    mo->period_bounds( EXPORTING iv_date = '20260215' iv_kind = 'MONTH'
                       IMPORTING ev_first = DATA(lv_f) ev_last = DATA(lv_l) ).
    cl_abap_unit_assert=>assert_equals( exp = CONV d( '20260201' ) act = lv_f ).
    cl_abap_unit_assert=>assert_equals( exp = CONV d( '20260228' ) act = lv_l ).
  ENDMETHOD.

  METHOD period_quarter.
    mo->period_bounds( EXPORTING iv_date = '20260815' iv_kind = 'QUARTER'
                       IMPORTING ev_first = DATA(lv_f) ev_last = DATA(lv_l) ).
    cl_abap_unit_assert=>assert_equals( exp = CONV d( '20260701' ) act = lv_f ).
    cl_abap_unit_assert=>assert_equals( exp = CONV d( '20260930' ) act = lv_l ).
  ENDMETHOD.

  METHOD weekday_range.
    DATA(lv_wd) = mo->weekday( '20260831' ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_wd >= 1 AND lv_wd <= 7 ) ).
  ENDMETHOD.

  METHOD round_modes.
    cl_abap_unit_assert=>assert_equals( exp = CONV decfloat34( '2.35' )
      act = mo->round( iv_value = CONV decfloat34( '2.345' ) iv_decimals = 2 ) ).
    cl_abap_unit_assert=>assert_equals( exp = CONV decfloat34( '2.34' )
      act = mo->round( iv_value = CONV decfloat34( '2.349' ) iv_decimals = 2 iv_mode = 'DOWN' ) ).
  ENDMETHOD.

  METHOD ts_roundtrip.
    DATA lv_ts TYPE timestampl VALUE '20260831123045.5000000'.
    mo->ts_split( EXPORTING iv_ts = lv_ts IMPORTING ev_date = DATA(lv_d) ev_time = DATA(lv_t) ev_msec = DATA(lv_ms) ).
    cl_abap_unit_assert=>assert_equals( exp = CONV d( '20260831' ) act = lv_d ).
    cl_abap_unit_assert=>assert_equals( exp = CONV t( '123045' ) act = lv_t ).
  ENDMETHOD.

  METHOD workdays_opt.
    " Factory calendar may not exist in every system - tolerate that.
    TRY.
        DATA(lv_res) = mo->add_workdays( iv_date = '20260828' iv_days = 1 iv_calendar_id = 'DE' ).
        cl_abap_unit_assert=>assert_true( xsdbool( lv_res > '20260828' ) ).
      CATCH zcx_ab_v1_ut.
        " calendar 'DE' not maintained - acceptable, nothing to assert
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
