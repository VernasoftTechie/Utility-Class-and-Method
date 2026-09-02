*"* use this source file for your ABAP unit test classes

CLASS ltc_exec DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES zif_ab_v1_ut_cutover_exec.
    DATA mt_ran TYPE STANDARD TABLE OF string WITH EMPTY KEY.
ENDCLASS.

CLASS ltc_exec IMPLEMENTATION.
  METHOD zif_ab_v1_ut_cutover_exec~run_task.
    IF iv_name CS 'FAIL'.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '032' iv_msgv1 = iv_name ).
    ENDIF.
    APPEND iv_name TO mt_ran.
  ENDMETHOD.
ENDCLASS.


CLASS ltc_cutover DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo TYPE REF TO zif_ab_v1_ut_cutover.
    METHODS setup.
    METHODS tasks_all_ok      FOR TESTING RAISING zcx_ab_v1_ut.
    METHODS tasks_stop_error  FOR TESTING RAISING zcx_ab_v1_ut.
    METHODS readiness_runs    FOR TESTING.
ENDCLASS.


CLASS ltc_cutover IMPLEMENTATION.

  METHOD setup.
    mo = NEW zcl_ab_v1_ut_cutover( ).
  ENDMETHOD.

  METHOD tasks_all_ok.
    DATA(lo_exec) = NEW ltc_exec( ).
    DATA(lt) = mo->task_run( it_task_names = VALUE #( ( `LOCK` ) ( `STOP_JOBS` ) ( `SNAP` ) )
                             io_executor   = lo_exec ).

    cl_abap_unit_assert=>assert_equals( exp = 3 act = lines( lt ) ).
    LOOP AT lt INTO DATA(ls).
      cl_abap_unit_assert=>assert_equals( exp = zif_ab_v1_ut_cutover=>c_status-done act = ls-status ).
    ENDLOOP.
    cl_abap_unit_assert=>assert_equals( exp = 3 act = lines( lo_exec->mt_ran ) ).
  ENDMETHOD.

  METHOD tasks_stop_error.
    DATA(lo_exec) = NEW ltc_exec( ).
    DATA(lt) = mo->task_run( it_task_names    = VALUE #( ( `STEP1` ) ( `STEP2_FAIL` ) ( `STEP3` ) )
                             io_executor      = lo_exec
                             iv_stop_on_error = abap_true ).

    cl_abap_unit_assert=>assert_equals( exp = 3 act = lines( lt ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_ab_v1_ut_cutover=>c_status-done    act = lt[ 1 ]-status ).
    cl_abap_unit_assert=>assert_equals( exp = zif_ab_v1_ut_cutover=>c_status-error   act = lt[ 2 ]-status ).
    cl_abap_unit_assert=>assert_equals( exp = zif_ab_v1_ut_cutover=>c_status-skipped act = lt[ 3 ]-status ).
    cl_abap_unit_assert=>assert_not_initial( act = lt[ 2 ]-message ).
  ENDMETHOD.

  METHOD readiness_runs.
    " read-only, no RFC destinations -> never raises, always returns >= 1 finding
    DATA(lt) = mo->readiness_check( ).
    cl_abap_unit_assert=>assert_true( xsdbool( lines( lt ) >= 1 ) ).
  ENDMETHOD.

ENDCLASS.
