"! <p class="shorttext synchronized">ZCL_AB_V1_UT: cutover / go-live helpers</p>
"! RAP-mode: task_run / lock_users / unlock_users / suspend_jobs / release_jobs are
"! DEFER and each AUTHORITY-CHECKs first; readiness_check is Core (read-only).
INTERFACE zif_ab_v1_ut_cutover
  PUBLIC.

  CONSTANTS:
    BEGIN OF c_status,
      pending TYPE string VALUE 'PENDING',
      running TYPE string VALUE 'RUNNING',
      done    TYPE string VALUE 'DONE',
      error   TYPE string VALUE 'ERROR',
      skipped TYPE string VALUE 'SKIPPED',
    END OF c_status.

  TYPES:
    BEGIN OF ty_task_status,
      name     TYPE string,
      status   TYPE string,
      started  TYPE timestampl,
      finished TYPE timestampl,
      seconds  TYPE decfloat34,
      message  TYPE string,
    END OF ty_task_status,
    ty_task_status_tab TYPE STANDARD TABLE OF ty_task_status WITH KEY name.
  TYPES:
    BEGIN OF ty_finding,
      category TYPE string,
      severity TYPE symsgty,
      count    TYPE i,
      text     TYPE string,
    END OF ty_finding,
    ty_finding_tab TYPE STANDARD TABLE OF ty_finding WITH EMPTY KEY.

  METHODS task_run
    IMPORTING it_task_names    TYPE zif_ab_v1_ut_types=>ty_string_tab
              io_executor      TYPE REF TO zif_ab_v1_ut_cutover_exec
              iv_stop_on_error TYPE abap_bool DEFAULT abap_true
    RETURNING VALUE(rt_status) TYPE ty_task_status_tab
    RAISING   zcx_ab_v1_ut.

  METHODS readiness_check
    IMPORTING iv_hours     TYPE i DEFAULT 24
              it_rfc_dests TYPE zif_ab_v1_ut_types=>ty_string_tab OPTIONAL
    RETURNING VALUE(rt_findings) TYPE ty_finding_tab.

  METHODS lock_users
    IMPORTING it_except TYPE zif_ab_v1_ut_types=>ty_string_tab OPTIONAL
    RETURNING VALUE(rt_locked) TYPE zif_ab_v1_ut_types=>ty_string_tab
    RAISING   zcx_ab_v1_ut.

  METHODS unlock_users
    RAISING zcx_ab_v1_ut.

  METHODS suspend_jobs
    IMPORTING iv_report_only  TYPE abap_bool DEFAULT abap_true
    RETURNING VALUE(rt_jobs)  TYPE zif_ab_v1_ut_types=>ty_string_tab
    RAISING   zcx_ab_v1_ut.

  METHODS release_jobs
    RAISING zcx_ab_v1_ut.

ENDINTERFACE.
