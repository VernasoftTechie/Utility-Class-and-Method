"! <p class="shorttext synchronized">ZCL_AB_V1_UT: bulk / packaged / parallel / restart runner</p>
"! RAP-mode: run_packaged / run_parallel / resume are DEFER (COMMIT WORK + parallel
"! dispatch); progress is Core (read-only feedback).
"! See docs/08_implementation_toolkit.md and docs/00_engineering_log.md.
CLASS zcl_ab_v1_ut_bulk DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ab_v1_ut_bulk.

  PRIVATE SECTION.
    "! Packaged loop shared by run_packaged and resume.
    METHODS execute
      IMPORTING ir_keys          TYPE REF TO data
                iv_pkg_size      TYPE i
                io_handler       TYPE REF TO zif_ab_v1_ut_bulk_handler
                iv_commit_each   TYPE abap_bool
                iv_run_id        TYPE string
                iv_max_seconds   TYPE i
                iv_start_from    TYPE i DEFAULT 1
                iv_processed0    TYPE i DEFAULT 0
                io_store         TYPE REF TO zif_ab_v1_ut_bulk_store OPTIONAL
      RETURNING VALUE(rs_result) TYPE zif_ab_v1_ut_bulk=>ty_result
      RAISING   zcx_ab_v1_ut.

    "! A fresh unique run id (UUID, or a timestamp fallback).
    METHODS new_run_id
      RETURNING VALUE(rv_run_id) TYPE string.

    "! Build a STANDARD TABLE type handle whose line type matches <keys>.
    METHODS package_type
      IMPORTING io_line_type      TYPE REF TO cl_abap_datadescr
      RETURNING VALUE(ro_tabtype) TYPE REF TO cl_abap_tabledescr
      RAISING   zcx_ab_v1_ut.

    "! Elapsed seconds between two timestamps (dump-safe).
    METHODS elapsed
      IMPORTING iv_from         TYPE timestamp
                iv_to           TYPE timestamp
      RETURNING VALUE(rv_secs)  TYPE decfloat34.
ENDCLASS.



CLASS zcl_ab_v1_ut_bulk IMPLEMENTATION.

  METHOD zif_ab_v1_ut_bulk~run_packaged.
    DATA lv_run_id TYPE string.
    IF iv_run_id IS NOT INITIAL.
      lv_run_id = iv_run_id.
    ELSE.
      lv_run_id = new_run_id( ).
    ENDIF.

    DATA lv_pkg TYPE i.
    lv_pkg = iv_pkg_size.
    IF lv_pkg < 1.
      lv_pkg = 1000.
    ENDIF.

    rs_result = execute( ir_keys        = ir_keys
                         iv_pkg_size    = lv_pkg
                         io_handler     = io_handler
                         iv_commit_each = iv_commit_each
                         iv_run_id      = lv_run_id
                         iv_max_seconds = iv_max_seconds
                         io_store       = io_store ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_bulk~resume.
    IF io_store IS NOT BOUND.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '027'
                                iv_msgv1 = |no checkpoint store supplied| ) ##NO_TEXT.
    ENDIF.

    DATA lv_run_id TYPE string.
    lv_run_id = iv_run_id.

    DATA lv_ckpt  TYPE string.
    DATA lv_done  TYPE i.
    DATA lv_found TYPE abap_bool.
    io_store->load( EXPORTING iv_run_id     = lv_run_id
                    IMPORTING ev_checkpoint = lv_ckpt
                              ev_processed  = lv_done
                              ev_found      = lv_found ).
    IF lv_found = abap_false.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '025'
                                iv_msgv1 = lv_run_id
                                iv_msgv2 = |no checkpoint found| ) ##NO_TEXT.
    ENDIF.

    DATA lv_pkg TYPE i.
    lv_pkg = iv_pkg_size.
    IF lv_pkg < 1.
      lv_pkg = 1000.
    ENDIF.

    rs_result = execute( ir_keys        = ir_keys
                         iv_pkg_size    = lv_pkg
                         io_handler     = io_handler
                         iv_commit_each = iv_commit_each
                         iv_run_id      = lv_run_id
                         iv_max_seconds = iv_max_seconds
                         iv_start_from  = lv_done + 1
                         iv_processed0  = lv_done
                         io_store       = io_store ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_bulk~run_parallel.
    FIELD-SYMBOLS <keys> TYPE STANDARD TABLE.

    IF ir_keys IS NOT BOUND.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '025'
                                iv_msgv1 = |parallel|
                                iv_msgv2 = |key reference is not bound| ) ##NO_TEXT.
    ENDIF.
    ASSIGN ir_keys->* TO <keys>.
    IF <keys> IS NOT ASSIGNED.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '025'
                                iv_msgv1 = |parallel|
                                iv_msgv2 = |keys must be a standard (index) table| ) ##NO_TEXT.
    ENDIF.

    DATA(lo_line) = CAST cl_abap_tabledescr(
        cl_abap_typedescr=>describe_by_data( <keys> ) )->get_table_line_type( ).

    DATA(lv_line_name) = lo_line->get_relative_name( ).
    IF lv_line_name IS INITIAL.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '017'
        iv_msgv1 = |parallel keys need a global / DDIC line type| ) ##NO_TEXT.
    ENDIF.

    DATA lv_pkg TYPE i.
    lv_pkg = iv_pkg_size.
    IF lv_pkg < 1.
      lv_pkg = 1000.
    ENDIF.

    DATA lv_total TYPE i.
    lv_total = lines( <keys> ).

    DATA(lo_pkg_type) = package_type( lo_line ).

    " --- serialize input packages ---
    DATA lt_in TYPE cl_abap_parallel=>t_in_tab.
    DATA lv_lo TYPE i.
    lv_lo = 1.
    WHILE lv_lo <= lv_total.
      DATA lv_hi TYPE i.
      lv_hi = lv_lo + lv_pkg - 1.
      IF lv_hi > lv_total.
        lv_hi = lv_total.
      ENDIF.

      DATA lr_pkg TYPE REF TO data.
      CREATE DATA lr_pkg TYPE HANDLE lo_pkg_type.
      ASSIGN lr_pkg->* TO FIELD-SYMBOL(<pkg>).

      DATA lv_i TYPE i.
      lv_i = lv_lo.
      WHILE lv_i <= lv_hi.
        APPEND <keys>[ lv_i ] TO <pkg>.
        lv_i = lv_i + 1.
      ENDWHILE.

      DATA lv_json TYPE string.
      lv_json = /ui2/cl_json=>serialize( data = <pkg> ).
      APPEND cl_abap_codepage=>convert_to( lv_json ) TO lt_in.

      lv_lo = lv_hi + 1.
    ENDWHILE.

    DATA lv_start_ts TYPE timestamp.
    GET TIME STAMP FIELD lv_start_ts.

    " --- dispatch across work processes ---
    DATA(lo_worker) = NEW lcl_par( ).
    lo_worker->mv_handler_class = iv_handler_class.
    lo_worker->mv_line_name     = lv_line_name.
    lo_worker->mv_context       = iv_context.

    DATA lv_tasks TYPE i.
    lv_tasks = iv_max_tasks.
    IF lv_tasks < 1.
      lv_tasks = 5.
    ENDIF.

    DATA lt_out TYPE cl_abap_parallel=>t_out_tab.
    TRY.
        lo_worker->run_inst( EXPORTING p_in_tab    = lt_in
                                       p_num_tasks = lv_tasks
                             IMPORTING p_out_tab   = lt_out ).
      CATCH cx_root INTO DATA(lx_par).
        zcx_ab_v1_ut=>raise_t100( iv_msgno    = '017'
                                  iv_msgv1    = lx_par->get_text( )
                                  io_previous = lx_par ).
    ENDTRY.

    " --- collect results ---
    DATA lv_end_ts TYPE timestamp.
    GET TIME STAMP FIELD lv_end_ts.

    rs_result-run_id    = |PAR{ lv_start_ts }|.
    rs_result-total     = lv_total.
    rs_result-processed = lv_total.
    rs_result-seconds   = elapsed( iv_from = lv_start_ts iv_to = lv_end_ts ).

    LOOP AT lt_out ASSIGNING FIELD-SYMBOL(<o>).
      IF <o>-result IS INITIAL.
        CONTINUE.
      ENDIF.
      DATA lt_m TYPE bapiret2_t.
      CLEAR lt_m.
      TRY.
          /ui2/cl_json=>deserialize(
            EXPORTING json = cl_abap_codepage=>convert_from( <o>-result )
            CHANGING  data = lt_m ).
        CATCH cx_root ##NO_HANDLER.
      ENDTRY.
      APPEND LINES OF lt_m TO rs_result-messages.
      IF    line_exists( lt_m[ type = 'E' ] )
         OR line_exists( lt_m[ type = 'A' ] )
         OR line_exists( lt_m[ type = 'X' ] ).
        rs_result-errors = rs_result-errors + 1.
      ENDIF.
    ENDLOOP.

    IF rs_result-errors = 0.
      rs_result-status = zif_ab_v1_ut_bulk=>c_status-complete.
    ELSE.
      rs_result-status = zif_ab_v1_ut_bulk=>c_status-failed.
    ENDIF.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_bulk~progress.
    DATA lv_text TYPE string.
    IF iv_text IS NOT INITIAL.
      lv_text = iv_text.
    ELSE.
      lv_text = |Bulk: { iv_done } / { iv_total }|.
    ENDIF.

    DATA lv_pct TYPE i.
    IF iv_total > 0.
      lv_pct = CONV decfloat34( iv_done ) * 100 / iv_total.
    ENDIF.

    DATA lv_ctext TYPE c LENGTH 200.
    lv_ctext = lv_text.

    CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
      EXPORTING
        percentage = lv_pct
        text       = lv_ctext.

    IF sy-batch = abap_true.
      MESSAGE lv_text TYPE 'I'.
    ENDIF.
  ENDMETHOD.


  METHOD execute.
    FIELD-SYMBOLS <keys> TYPE STANDARD TABLE.

    IF ir_keys IS NOT BOUND.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '025'
                                iv_msgv1 = iv_run_id
                                iv_msgv2 = |key reference is not bound| ) ##NO_TEXT.
    ENDIF.
    ASSIGN ir_keys->* TO <keys>.
    IF <keys> IS NOT ASSIGNED.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '025'
                                iv_msgv1 = iv_run_id
                                iv_msgv2 = |keys must be a standard (index) table| ) ##NO_TEXT.
    ENDIF.

    DATA(lo_line) = CAST cl_abap_tabledescr(
        cl_abap_typedescr=>describe_by_data( <keys> ) )->get_table_line_type( ).
    DATA(lo_pkg_type) = package_type( lo_line ).

    DATA lv_total TYPE i.
    lv_total = lines( <keys> ).

    rs_result-run_id    = iv_run_id.
    rs_result-total     = lv_total.
    rs_result-processed = iv_processed0.
    rs_result-status    = zif_ab_v1_ut_bulk=>c_status-incomplete.

    DATA lv_start_ts TYPE timestamp.
    GET TIME STAMP FIELD lv_start_ts.

    DATA lv_lo TYPE i.
    lv_lo = iv_start_from.
    IF lv_lo < 1.
      lv_lo = 1.
    ENDIF.

    WHILE lv_lo <= lv_total.
      DATA lv_hi TYPE i.
      lv_hi = lv_lo + iv_pkg_size - 1.
      IF lv_hi > lv_total.
        lv_hi = lv_total.
      ENDIF.

      DATA lr_pkg TYPE REF TO data.
      CREATE DATA lr_pkg TYPE HANDLE lo_pkg_type.
      ASSIGN lr_pkg->* TO FIELD-SYMBOL(<pkg>).

      DATA lv_i TYPE i.
      lv_i = lv_lo.
      WHILE lv_i <= lv_hi.
        APPEND <keys>[ lv_i ] TO <pkg>.
        lv_i = lv_i + 1.
      ENDWHILE.

      TRY.
          DATA(lt_msg) = io_handler->process_package( lr_pkg ).
          APPEND LINES OF lt_msg TO rs_result-messages.
          IF    line_exists( lt_msg[ type = 'E' ] )
             OR line_exists( lt_msg[ type = 'A' ] )
             OR line_exists( lt_msg[ type = 'X' ] ).
            rs_result-errors = rs_result-errors + 1.
          ENDIF.
        CATCH zcx_ab_v1_ut INTO DATA(lx_handler).
          rs_result-errors = rs_result-errors + 1.
          APPEND VALUE bapiret2( type       = 'E'
                                 id         = 'ZAB_V1_UT'
                                 number     = '026'
                                 message    = lx_handler->get_text( )
                                 message_v1 = |{ lv_lo }-{ lv_hi }| ) TO rs_result-messages.
      ENDTRY.

      rs_result-processed = lv_hi.

      IF iv_commit_each = abap_true.
        COMMIT WORK.
      ENDIF.

      zif_ab_v1_ut_bulk~progress( iv_done = lv_hi iv_total = lv_total ).

      lv_lo = lv_hi + 1.

      IF iv_max_seconds > 0 AND lv_lo <= lv_total.
        DATA lv_now_ts TYPE timestamp.
        GET TIME STAMP FIELD lv_now_ts.
        IF elapsed( iv_from = lv_start_ts iv_to = lv_now_ts ) >= iv_max_seconds.
          IF io_store IS BOUND.
            io_store->save( iv_run_id     = iv_run_id
                            iv_checkpoint = |{ lv_hi }|
                            iv_processed  = lv_hi ).
          ENDIF.
          rs_result-status       = zif_ab_v1_ut_bulk=>c_status-incomplete.
          rs_result-resume_token = iv_run_id.
          rs_result-seconds      = elapsed( iv_from = lv_start_ts iv_to = lv_now_ts ).
          RETURN.
        ENDIF.
      ENDIF.
    ENDWHILE.

    IF io_store IS BOUND.
      TRY.
          io_store->delete( iv_run_id ).
        CATCH zcx_ab_v1_ut ##NO_HANDLER.
      ENDTRY.
    ENDIF.

    DATA lv_end_ts TYPE timestamp.
    GET TIME STAMP FIELD lv_end_ts.
    rs_result-seconds = elapsed( iv_from = lv_start_ts iv_to = lv_end_ts ).
    rs_result-status  = zif_ab_v1_ut_bulk=>c_status-complete.
  ENDMETHOD.


  METHOD new_run_id.
    TRY.
        rv_run_id = cl_system_uuid=>create_uuid_c32_static( ).
      CATCH cx_uuid_error ##NO_HANDLER.
    ENDTRY.
    IF rv_run_id IS INITIAL.
      GET TIME STAMP FIELD DATA(lv_ts).
      rv_run_id = |BULK{ lv_ts }|.
    ENDIF.
  ENDMETHOD.


  METHOD package_type.
    TRY.
        ro_tabtype = cl_abap_tabledescr=>create(
          p_line_type  = io_line_type
          p_table_kind = cl_abap_tabledescr=>tablekind_std
          p_unique     = abap_false ).
      CATCH cx_sy_table_creation INTO DATA(lx).
        zcx_ab_v1_ut=>raise_t100( iv_msgno    = '025'
                                  iv_msgv1    = |package type|
                                  iv_msgv2    = lx->get_text( )
                                  io_previous = lx ).
    ENDTRY.
  ENDMETHOD.


  METHOD elapsed.
    TRY.
        rv_secs = cl_abap_tstmp=>subtract( tstmp1 = iv_to
                                           tstmp2 = iv_from ).
      CATCH cx_root ##NO_HANDLER.
        rv_secs = 0.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
