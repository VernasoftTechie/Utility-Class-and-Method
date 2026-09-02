"! <p class="shorttext synchronized">ZCL_AB_V1_UT: packaged / parallel / restart runner</p>
"! RAP-mode: run_* are DEFER (commit + jobs). resume / progress are Core.
INTERFACE zif_ab_v1_ut_bulk
  PUBLIC.

  CONSTANTS:
    BEGIN OF c_status,
      complete   TYPE string VALUE 'COMPLETE',
      incomplete TYPE string VALUE 'INCOMPLETE',
      failed     TYPE string VALUE 'FAILED',
    END OF c_status.

  TYPES:
    BEGIN OF ty_result,
      run_id       TYPE string,
      status       TYPE string,
      total        TYPE i,
      processed    TYPE i,
      errors       TYPE i,
      resume_token TYPE string,
      messages     TYPE bapiret2_t,
      seconds      TYPE decfloat34,
    END OF ty_result.

  "! DEFER. Chunk ir_keys by iv_pkg_size; io_handler processes each package;
  "! commit after each when iv_commit_each = abap_true. With io_store +
  "! iv_max_seconds, saves a checkpoint and returns status = INCOMPLETE +
  "! resume_token when the time budget is exceeded.
  METHODS run_packaged
    IMPORTING ir_keys        TYPE REF TO data
              iv_pkg_size    TYPE i DEFAULT 1000
              io_handler     TYPE REF TO zif_ab_v1_ut_bulk_handler
              iv_commit_each TYPE abap_bool DEFAULT abap_true
              iv_run_id      TYPE csequence OPTIONAL
              io_store       TYPE REF TO zif_ab_v1_ut_bulk_store OPTIONAL
              iv_max_seconds TYPE i DEFAULT 0
    RETURNING VALUE(rs_result) TYPE ty_result
    RAISING   zcx_ab_v1_ut.

  "! DEFER. Parallel dispatch via CL_ABAP_PARALLEL. iv_handler_class is
  "! instantiated fresh per work process; iv_context is a serialized xstring
  "! handed to every instance (via the RAP-mode-safe context hook).
  METHODS run_parallel
    IMPORTING ir_keys          TYPE REF TO data
              iv_pkg_size      TYPE i DEFAULT 1000
              iv_handler_class TYPE seoclsname
              iv_context       TYPE xstring OPTIONAL
              iv_max_tasks     TYPE i DEFAULT 5
              iv_server_group  TYPE rzlli_apcl OPTIONAL
    RETURNING VALUE(rs_result) TYPE ty_result
    RAISING   zcx_ab_v1_ut.

  "! Resume a previously INCOMPLETE run from its checkpoint.
  METHODS resume
    IMPORTING iv_run_id      TYPE csequence
              ir_keys        TYPE REF TO data
              io_store       TYPE REF TO zif_ab_v1_ut_bulk_store
              io_handler     TYPE REF TO zif_ab_v1_ut_bulk_handler
              iv_pkg_size    TYPE i DEFAULT 1000
              iv_commit_each TYPE abap_bool DEFAULT abap_true
              iv_max_seconds TYPE i DEFAULT 0
    RETURNING VALUE(rs_result) TYPE ty_result
    RAISING   zcx_ab_v1_ut.

  "! Foreground progress bar + a batch job-log line.
  METHODS progress
    IMPORTING iv_done  TYPE i
              iv_total TYPE i
              iv_text  TYPE csequence OPTIONAL.

ENDINTERFACE.
