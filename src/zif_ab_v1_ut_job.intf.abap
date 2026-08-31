"! <p class="shorttext synchronized">ZCL_AB_V1_UT: parallel / background</p>
"! RAP-mode: run_parallel spawn is Core, result collation is DEFER;
"! schedule_job / trigger_bgpf are DEFER (after commit).
INTERFACE zif_ab_v1_ut_job
  PUBLIC.

  METHODS run_parallel
    IMPORTING iv_handler_class TYPE string
              ir_packages      TYPE REF TO data
              iv_max_tasks     TYPE i DEFAULT 5
              iv_server_group  TYPE rzlli_apcl OPTIONAL
    EXPORTING et_messages      TYPE bapiret2_t
    RAISING   zcx_ab_v1_ut.

  "! DEFER
  METHODS schedule_job
    IMPORTING iv_job_name          TYPE btcjob
              iv_report            TYPE sy-repid
              iv_variant           TYPE raldb_vari OPTIONAL
              iv_start_immediately TYPE abap_bool DEFAULT abap_true
    RETURNING VALUE(rv_jobcount)   TYPE btcjobcnt
    RAISING   zcx_ab_v1_ut.

  "! DEFER
  METHODS trigger_bgpf
    IMPORTING iv_key TYPE string
    RAISING   zcx_ab_v1_ut.

ENDINTERFACE.
