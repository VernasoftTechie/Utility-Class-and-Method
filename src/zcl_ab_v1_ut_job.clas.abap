CLASS zcl_ab_v1_ut_job DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ab_v1_ut_job.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_ab_v1_ut_job IMPLEMENTATION.

  METHOD zif_ab_v1_ut_job~schedule_job.
    zcl_ab_v1_ut_phase=>assert_defer_allowed( 'schedule_job' ).

    DATA lv_count TYPE btcjobcnt.
    CALL FUNCTION 'JOB_OPEN'
      EXPORTING  jobname          = iv_job_name
      IMPORTING  jobcount         = lv_count
      EXCEPTIONS cant_create_job  = 1
                 invalid_job_data = 2
                 jobname_missing  = 3
                 OTHERS           = 4.
    IF sy-subrc <> 0.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '001' iv_msgv1 = |JOB_OPEN rc={ sy-subrc }| ).
    ENDIF.

    IF iv_variant IS NOT INITIAL.
      SUBMIT (iv_report) VIA JOB iv_job_name NUMBER lv_count
             USING SELECTION-SET iv_variant
             AND RETURN.
    ELSE.
      SUBMIT (iv_report) VIA JOB iv_job_name NUMBER lv_count
             AND RETURN.
    ENDIF.
    IF sy-subrc <> 0.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '001' iv_msgv1 = |SUBMIT { iv_report } rc={ sy-subrc }| ).
    ENDIF.

    CALL FUNCTION 'JOB_CLOSE'
      EXPORTING  jobcount             = lv_count
                 jobname              = iv_job_name
                 strtimmed            = iv_start_immediately
                 targetserver         = iv_target_server
      EXCEPTIONS cant_start_immediate = 1
                 invalid_startdate    = 2
                 jobname_missing      = 3
                 job_close_failed     = 4
                 job_nosteps          = 5
                 job_notex            = 6
                 lock_failed          = 7
                 OTHERS               = 8.
    IF sy-subrc <> 0.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '001' iv_msgv1 = |JOB_CLOSE rc={ sy-subrc }| ).
    ENDIF.

    rs_job = VALUE #( name = iv_job_name count = lv_count ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_job~is_finished.
    SELECT SINGLE status FROM tbtco
      INTO @DATA(lv_status)
      WHERE jobname  = @is_job-name
        AND jobcount = @is_job-count.
    rv = xsdbool( lv_status = 'F' OR lv_status = 'A' ).
  ENDMETHOD.

ENDCLASS.
