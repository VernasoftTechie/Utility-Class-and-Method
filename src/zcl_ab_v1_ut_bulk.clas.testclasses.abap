*"* use this source file for your ABAP unit test classes

"! Test handler: records every key it is handed; optionally emits an error message.
CLASS ltc_handler DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES zif_ab_v1_ut_bulk_handler.
    DATA mt_seen TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    DATA mv_fail TYPE abap_bool.
ENDCLASS.

CLASS ltc_handler IMPLEMENTATION.
  METHOD zif_ab_v1_ut_bulk_handler~process_package.
    FIELD-SYMBOLS <t> TYPE STANDARD TABLE.
    ASSIGN ir_keys->* TO <t>.
    LOOP AT <t> ASSIGNING FIELD-SYMBOL(<k>).
      APPEND <k> TO mt_seen.
    ENDLOOP.
    IF mv_fail = abap_true.
      rt_messages = VALUE #( ( type = 'E' id = 'ZAB_V1_UT' number = '001' message = 'forced failure' ) ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.


CLASS ltc_bulk DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo     TYPE REF TO zif_ab_v1_ut_bulk.
    DATA mt_keys TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    DATA mr_keys TYPE REF TO data.

    METHODS setup.
    METHODS packaged_all        FOR TESTING RAISING zcx_ab_v1_ut.
    METHODS packaged_errors     FOR TESTING RAISING zcx_ab_v1_ut.
    METHODS resume_from_ckpt    FOR TESTING RAISING zcx_ab_v1_ut.
    METHODS store_roundtrip     FOR TESTING RAISING zcx_ab_v1_ut.
    METHODS invalid_keys        FOR TESTING.
ENDCLASS.


CLASS ltc_bulk IMPLEMENTATION.

  METHOD setup.
    zcl_ab_v1_ut_bulk_store_mem=>reset( ).
    mo = NEW zcl_ab_v1_ut_bulk( ).
    mt_keys = VALUE #( FOR j = 1 WHILE j <= 10 ( j ) ).
    GET REFERENCE OF mt_keys INTO mr_keys.
  ENDMETHOD.

  METHOD packaged_all.
    DATA(lo_h) = NEW ltc_handler( ).
    DATA(ls) = mo->run_packaged( ir_keys        = mr_keys
                                 iv_pkg_size    = 3
                                 io_handler     = lo_h
                                 iv_commit_each = abap_false ).

    cl_abap_unit_assert=>assert_equals( exp = 10 act = ls-total ).
    cl_abap_unit_assert=>assert_equals( exp = 10 act = ls-processed ).
    cl_abap_unit_assert=>assert_equals( exp = 0  act = ls-errors ).
    cl_abap_unit_assert=>assert_equals( exp = zif_ab_v1_ut_bulk=>c_status-complete act = ls-status ).

    SORT lo_h->mt_seen.
    cl_abap_unit_assert=>assert_equals( exp = 10 act = lines( lo_h->mt_seen ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1  act = lo_h->mt_seen[ 1 ] ).
    cl_abap_unit_assert=>assert_equals( exp = 10 act = lo_h->mt_seen[ 10 ] ).
  ENDMETHOD.

  METHOD packaged_errors.
    DATA(lo_h) = NEW ltc_handler( ).
    lo_h->mv_fail = abap_true.
    DATA(ls) = mo->run_packaged( ir_keys        = mr_keys
                                 iv_pkg_size    = 5
                                 io_handler     = lo_h
                                 iv_commit_each = abap_false ).

    cl_abap_unit_assert=>assert_equals( exp = 2 act = ls-errors ).
    cl_abap_unit_assert=>assert_equals( exp = 10 act = ls-processed ).
    cl_abap_unit_assert=>assert_equals( exp = zif_ab_v1_ut_bulk=>c_status-complete act = ls-status ).
  ENDMETHOD.

  METHOD resume_from_ckpt.
    DATA(lo_store) = NEW zcl_ab_v1_ut_bulk_store_mem( ).
    lo_store->zif_ab_v1_ut_bulk_store~save( iv_run_id     = 'R1'
                                            iv_checkpoint = '6'
                                            iv_processed  = 6 ).

    DATA(lo_h) = NEW ltc_handler( ).
    DATA(ls) = mo->resume( iv_run_id      = 'R1'
                           ir_keys        = mr_keys
                           io_store       = lo_store
                           io_handler     = lo_h
                           iv_pkg_size    = 3
                           iv_commit_each = abap_false ).

    cl_abap_unit_assert=>assert_equals( exp = zif_ab_v1_ut_bulk=>c_status-complete act = ls-status ).
    cl_abap_unit_assert=>assert_equals( exp = 10 act = ls-processed ).

    SORT lo_h->mt_seen.
    cl_abap_unit_assert=>assert_equals( exp = 4 act = lines( lo_h->mt_seen ) ).
    cl_abap_unit_assert=>assert_equals( exp = 7 act = lo_h->mt_seen[ 1 ] ).
    cl_abap_unit_assert=>assert_equals( exp = 10 act = lo_h->mt_seen[ 4 ] ).

    " checkpoint cleared after a completed resume
    DATA lv_found TYPE abap_bool.
    lo_store->zif_ab_v1_ut_bulk_store~load( EXPORTING iv_run_id = 'R1'
                                            IMPORTING ev_found  = lv_found ).
    cl_abap_unit_assert=>assert_equals( exp = abap_false act = lv_found ).
  ENDMETHOD.

  METHOD store_roundtrip.
    DATA(lo) = NEW zcl_ab_v1_ut_bulk_store_mem( ).
    lo->zif_ab_v1_ut_bulk_store~save( iv_run_id = 'X' iv_checkpoint = 'C7' iv_processed = 7 ).

    DATA lv_ckpt  TYPE string.
    DATA lv_done  TYPE i.
    DATA lv_found TYPE abap_bool.
    lo->zif_ab_v1_ut_bulk_store~load( EXPORTING iv_run_id     = 'X'
                                      IMPORTING ev_checkpoint = lv_ckpt
                                                ev_processed  = lv_done
                                                ev_found      = lv_found ).
    cl_abap_unit_assert=>assert_equals( exp = abap_true act = lv_found ).
    cl_abap_unit_assert=>assert_equals( exp = 'C7'      act = lv_ckpt ).
    cl_abap_unit_assert=>assert_equals( exp = 7         act = lv_done ).

    lo->zif_ab_v1_ut_bulk_store~delete( iv_run_id = 'X' ).
    lo->zif_ab_v1_ut_bulk_store~load( EXPORTING iv_run_id = 'X'
                                      IMPORTING ev_found  = lv_found ).
    cl_abap_unit_assert=>assert_equals( exp = abap_false act = lv_found ).
  ENDMETHOD.

  METHOD invalid_keys.
    DATA lr_bad TYPE REF TO data.
    DATA lv_str TYPE string.
    GET REFERENCE OF lv_str INTO lr_bad.

    DATA(lo_h) = NEW ltc_handler( ).
    TRY.
        mo->run_packaged( ir_keys        = lr_bad
                          iv_pkg_size    = 3
                          io_handler     = lo_h
                          iv_commit_each = abap_false ).
        cl_abap_unit_assert=>fail( 'expected ZCX_AB_V1_UT for non-table keys' ).
      CATCH zcx_ab_v1_ut ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
