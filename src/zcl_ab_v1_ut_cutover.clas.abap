"! <p class="shorttext synchronized">ZCL_AB_V1_UT: cutover / go-live helpers</p>
"! RAP-mode: task_run / lock_users / unlock_users / suspend_jobs / release_jobs are
"! DEFER and each AUTHORITY-CHECKs first; readiness_check is Core (read-only).
"! See docs/08_implementation_toolkit.md and docs/00_engineering_log.md.
CLASS zcl_ab_v1_ut_cutover DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ab_v1_ut_cutover.

  PRIVATE SECTION.
    "! Users this instance locked, for a matching unlock_users in the same session.
    DATA mt_locked TYPE zif_ab_v1_ut_types=>ty_string_tab.

    METHODS future_released_jobs
      RETURNING VALUE(rt_jobs) TYPE zif_ab_v1_ut_types=>ty_string_tab.

    METHODS add_finding
      IMPORTING iv_category TYPE string
                iv_sev      TYPE symsgty
                iv_count    TYPE i
                iv_text     TYPE string
      CHANGING  ct_findings TYPE zif_ab_v1_ut_cutover=>ty_finding_tab.

    METHODS deny
      IMPORTING iv_op TYPE string
      RAISING   zcx_ab_v1_ut.

    METHODS commit_now.
ENDCLASS.



CLASS zcl_ab_v1_ut_cutover IMPLEMENTATION.

  METHOD zif_ab_v1_ut_cutover~task_run.
    LOOP AT it_task_names INTO DATA(lv_name).
      DATA(lv_idx) = sy-tabix.

      DATA ls_st TYPE zif_ab_v1_ut_cutover=>ty_task_status.
      CLEAR ls_st.
      ls_st-name   = lv_name.
      ls_st-status = zif_ab_v1_ut_cutover=>c_status-running.
      GET TIME STAMP FIELD ls_st-started.

      TRY.
          io_executor->run_task( iv_name = lv_name ).
          ls_st-status = zif_ab_v1_ut_cutover=>c_status-done.
        CATCH zcx_ab_v1_ut INTO DATA(lx).
          ls_st-status  = zif_ab_v1_ut_cutover=>c_status-error.
          ls_st-message = lx->get_text( ).
      ENDTRY.

      GET TIME STAMP FIELD ls_st-finished.
      TRY.
          ls_st-seconds = cl_abap_tstmp=>subtract(
            tstmp1 = CONV timestamp( ls_st-finished )
            tstmp2 = CONV timestamp( ls_st-started ) ).
        CATCH cx_root ##NO_HANDLER.
      ENDTRY.
      APPEND ls_st TO rt_status.

      IF ls_st-status = zif_ab_v1_ut_cutover=>c_status-error
         AND iv_stop_on_error = abap_true.
        DATA(lv_next) = lv_idx + 1.
        LOOP AT it_task_names INTO DATA(lv_rest) FROM lv_next.
          APPEND VALUE #( name   = lv_rest
                          status = zif_ab_v1_ut_cutover=>c_status-skipped ) TO rt_status.
        ENDLOOP.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_cutover~readiness_check.
    DATA lv_days TYPE i.
    lv_days = iv_hours / 24.
    IF lv_days < 1.
      lv_days = 1.
    ENDIF.
    DATA(lv_from_date) = CONV d( sy-datum - lv_days ).

    " 1. pending update records (SM13)
    SELECT COUNT(*) FROM vbhdr INTO @DATA(lv_upd).
    IF lv_upd > 0.
      add_finding( EXPORTING iv_category = 'UPDATE' iv_sev = 'W' iv_count = lv_upd
                             iv_text = |{ lv_upd } pending update record(s) (SM13)|
                   CHANGING  ct_findings = rt_findings ).
    ENDIF.

    " 2. jobs aborted in the window
    SELECT COUNT(*) FROM tbtco INTO @DATA(lv_abort)
      WHERE status = 'A' AND strtdate >= @lv_from_date.
    IF lv_abort > 0.
      add_finding( EXPORTING iv_category = 'JOB_ABORTED' iv_sev = 'E' iv_count = lv_abort
                             iv_text = |{ lv_abort } job(s) aborted since { lv_from_date DATE = USER }|
                   CHANGING  ct_findings = rt_findings ).
    ENDIF.

    " 3. jobs currently running
    SELECT COUNT(*) FROM tbtco INTO @DATA(lv_run) WHERE status = 'R'.
    IF lv_run > 0.
      add_finding( EXPORTING iv_category = 'JOB_RUNNING' iv_sev = 'W' iv_count = lv_run
                             iv_text = |{ lv_run } job(s) still running|
                   CHANGING  ct_findings = rt_findings ).
    ENDIF.

    " 4. released jobs due from now on
    DATA(lt_future) = future_released_jobs( ).
    IF lines( lt_future ) > 0.
      add_finding( EXPORTING iv_category = 'JOB_RELEASED' iv_sev = 'I' iv_count = lines( lt_future )
                             iv_text = |{ lines( lt_future ) } released job(s) due from now|
                   CHANGING  ct_findings = rt_findings ).
    ENDIF.

    " 5. batch-input sessions open or in error (SM35)
    SELECT COUNT(*) FROM apqi INTO @DATA(lv_bi)
      WHERE datatyp = 'BDC' AND qstate IN ( ' ', 'E' ).
    IF lv_bi > 0.
      add_finding( EXPORTING iv_category = 'BATCH_INPUT' iv_sev = 'W' iv_count = lv_bi
                             iv_text = |{ lv_bi } batch-input session(s) open or in error (SM35)|
                   CHANGING  ct_findings = rt_findings ).
    ENDIF.

    " 6. RFC destinations
    LOOP AT it_rfc_dests INTO DATA(lv_d).
      DATA lv_dest TYPE rfcdest.
      lv_dest = lv_d.
      CALL FUNCTION 'RFC_PING'
        DESTINATION lv_dest
        EXCEPTIONS system_failure = 1 communication_failure = 2 OTHERS = 3.
      IF sy-subrc <> 0.
        add_finding( EXPORTING iv_category = 'RFC_DEST' iv_sev = 'E' iv_count = 1
                               iv_text = |RFC destination { lv_dest } not reachable (rc { sy-subrc })|
                     CHANGING  ct_findings = rt_findings ).
      ENDIF.
    ENDLOOP.

    IF rt_findings IS INITIAL.
      add_finding( EXPORTING iv_category = 'READY' iv_sev = 'S' iv_count = 0
                             iv_text = |No blocking findings|
                   CHANGING  ct_findings = rt_findings ).
    ENDIF.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_cutover~lock_users.
    AUTHORITY-CHECK OBJECT 'S_USER_GRP' ID 'ACTVT' FIELD '05' ID 'CLASS' DUMMY.
    IF sy-subrc <> 0.
      deny( |lock users| ).
    ENDIF.

    SELECT bname FROM usr02 WHERE ustyp = 'A' INTO TABLE @DATA(lt_u).

    LOOP AT lt_u INTO DATA(ls_u).
      IF ls_u-bname = sy-uname OR ls_u-bname = 'DDIC' OR ls_u-bname = 'SAP*'.
        CONTINUE.
      ENDIF.
      IF line_exists( it_except[ table_line = CONV string( ls_u-bname ) ] ).
        CONTINUE.
      ENDIF.

      DATA lt_ret TYPE bapiret2_t.
      CLEAR lt_ret.
      CALL FUNCTION 'BAPI_USER_LOCK'
        EXPORTING username = ls_u-bname
        TABLES    return   = lt_ret.
      IF     NOT line_exists( lt_ret[ type = 'E' ] )
         AND NOT line_exists( lt_ret[ type = 'A' ] ).
        APPEND CONV string( ls_u-bname ) TO rt_locked.
        APPEND CONV string( ls_u-bname ) TO mt_locked.
      ENDIF.
    ENDLOOP.

    IF rt_locked IS NOT INITIAL.
      commit_now( ).
    ENDIF.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_cutover~unlock_users.
    AUTHORITY-CHECK OBJECT 'S_USER_GRP' ID 'ACTVT' FIELD '05' ID 'CLASS' DUMMY.
    IF sy-subrc <> 0.
      deny( |unlock users| ).
    ENDIF.

    IF mt_locked IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT mt_locked INTO DATA(lv_u).
      DATA lv_name TYPE xubname.
      lv_name = lv_u.
      DATA lt_ret TYPE bapiret2_t.
      CLEAR lt_ret.
      CALL FUNCTION 'BAPI_USER_UNLOCK'
        EXPORTING username = lv_name
        TABLES    return   = lt_ret.
    ENDLOOP.

    commit_now( ).
    CLEAR mt_locked.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_cutover~suspend_jobs.
    AUTHORITY-CHECK OBJECT 'S_BTCH_ADM' ID 'BTCADMIN' FIELD 'Y'.
    IF sy-subrc <> 0.
      deny( |suspend jobs| ).
    ENDIF.

    rt_jobs = future_released_jobs( ).

    IF iv_report_only = abap_false.
      " Changing released -> scheduled reliably needs a landscape-specific scheduler
      " API. This build reports the list; action it via SM37 / your scheduler.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '032'
        iv_msgv1 = |suspend_jobs|
        iv_msgv2 = |{ lines( rt_jobs ) } released job(s) listed; live suspend not enabled| ) ##NO_TEXT.
    ENDIF.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_cutover~release_jobs.
    AUTHORITY-CHECK OBJECT 'S_BTCH_ADM' ID 'BTCADMIN' FIELD 'Y'.
    IF sy-subrc <> 0.
      deny( |release jobs| ).
    ENDIF.

    zcx_ab_v1_ut=>raise_t100( iv_msgno = '032'
      iv_msgv1 = |release_jobs|
      iv_msgv2 = |live job release not enabled - use SM37 / your scheduler| ) ##NO_TEXT.
  ENDMETHOD.


  METHOD future_released_jobs.
    SELECT jobname, sdlstrtdt, sdlstrttm FROM tbtco
      WHERE status = 'S'
        AND ( sdlstrtdt > @sy-datum
           OR ( sdlstrtdt = @sy-datum AND sdlstrttm >= @sy-uzeit ) )
      ORDER BY sdlstrtdt, sdlstrttm
      INTO TABLE @DATA(lt_j).

    LOOP AT lt_j INTO DATA(ls_j).
      APPEND |{ ls_j-jobname } @ { ls_j-sdlstrtdt DATE = USER } { ls_j-sdlstrttm TIME = USER }|
             TO rt_jobs.
    ENDLOOP.
  ENDMETHOD.


  METHOD add_finding.
    APPEND VALUE #( category = iv_category
                    severity = iv_sev
                    count    = iv_count
                    text     = iv_text ) TO ct_findings.
  ENDMETHOD.


  METHOD deny.
    zcx_ab_v1_ut=>raise_t100( iv_msgno = '033' iv_msgv1 = iv_op ) ##NO_TEXT.
  ENDMETHOD.


  METHOD commit_now.
    TRY.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING wait = abap_true.
      CATCH cx_root ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
