"! <p class="shorttext synchronized">ZCL_AB_V1_UT: background job scheduling</p>
"! RAP-mode: schedule_job is DEFER (call after COMMIT / from a late save phase);
"! is_finished is Core. Parallel processing: use CL_ABAP_PARALLEL directly.
INTERFACE zif_ab_v1_ut_job
  PUBLIC.

  TYPES:
    BEGIN OF ty_job,
      name  TYPE btcjob,
      count TYPE btcjobcnt,
    END OF ty_job.

  "! DEFER. Opens a job, submits the report (optionally with a variant) and closes it.
  METHODS schedule_job
    IMPORTING iv_job_name          TYPE btcjob
              iv_report            TYPE sy-repid
              iv_variant           TYPE raldb_vari OPTIONAL
              iv_start_immediately TYPE abap_bool DEFAULT abap_true
              iv_target_server     TYPE btcsrvname OPTIONAL
    RETURNING VALUE(rs_job)        TYPE ty_job
    RAISING   zcx_ab_v1_ut.

  "! Core. abap_true once the job has finished (status F) or was aborted (status A).
  METHODS is_finished
    IMPORTING is_job    TYPE ty_job
    RETURNING VALUE(rv) TYPE abap_bool.

ENDINTERFACE.
