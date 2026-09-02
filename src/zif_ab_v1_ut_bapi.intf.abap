"! <p class="shorttext synchronized">ZCL_AB_V1_UT: BAPI / BDC mass executor</p>
"! RAP-mode: call / call_by_name / mass / commit / rollback / bdc_run are DEFER;
"! bdc_dynpro / bdc_field are Core builders.
INTERFACE zif_ab_v1_ut_bapi
  PUBLIC.

  TYPES:
    BEGIN OF ty_call,
      import_ref TYPE REF TO data,
      tables_ref TYPE REF TO data,
    END OF ty_call,
    ty_call_tab TYPE STANDARD TABLE OF ty_call WITH EMPTY KEY.
  TYPES:
    BEGIN OF ty_named_ref,
      name TYPE string,
      ref  TYPE REF TO data,
    END OF ty_named_ref,
    ty_named_ref_tab TYPE STANDARD TABLE OF ty_named_ref WITH KEY name.
  TYPES:
    BEGIN OF ty_mass_result,
      total     TYPE i,
      committed TYPE i,
      failed    TYPE i,
      errors    TYPE bapiret2_t,
    END OF ty_mass_result.

  "! DEFER. Low level - full control via an RFC-style parameter table.
  METHODS call
    IMPORTING iv_bapi   TYPE tfdir-funcname
              it_params TYPE abap_func_parmbind_tab
    RETURNING VALUE(rt_return) TYPE bapiret2_t
    RAISING   zcx_ab_v1_ut.

  "! DEFER. High level - auto-bind by parameter name (FM interface introspection).
  "! is_import components map to IMPORTING params; it_tables ( name -> table ref )
  "! map to TABLES params (incl. RETURN). TESTRUN set from iv_test_run when present.
  METHODS call_by_name
    IMPORTING iv_bapi     TYPE tfdir-funcname
              is_import   TYPE any OPTIONAL
              it_tables   TYPE ty_named_ref_tab OPTIONAL
              iv_test_run TYPE abap_bool DEFAULT abap_false
    EXPORTING es_export   TYPE any
    RETURNING VALUE(rt_return) TYPE bapiret2_t
    RAISING   zcx_ab_v1_ut.

  "! DEFER. N calls, BAPI_TRANSACTION_COMMIT every iv_commit_every.
  METHODS mass
    IMPORTING iv_bapi          TYPE tfdir-funcname
              it_calls         TYPE ty_call_tab
              iv_commit_every  TYPE i DEFAULT 100
              iv_stop_on_error TYPE abap_bool DEFAULT abap_false
              iv_test_run      TYPE abap_bool DEFAULT abap_false
    RETURNING VALUE(rs_result) TYPE ty_mass_result
    RAISING   zcx_ab_v1_ut.

  METHODS commit
    IMPORTING iv_wait TYPE abap_bool DEFAULT abap_true
    RAISING   zcx_ab_v1_ut.

  METHODS rollback
    RAISING zcx_ab_v1_ut.

  "! DEFER. Classic batch input - CALL TRANSACTION ... USING ... MESSAGES INTO.
  METHODS bdc_run
    IMPORTING iv_tcode   TYPE tcode
              it_bdcdata TYPE STANDARD TABLE
              iv_mode    TYPE c DEFAULT 'N'
              iv_update  TYPE c DEFAULT 'S'
    RETURNING VALUE(rt_return) TYPE bapiret2_t
    RAISING   zcx_ab_v1_ut.

  METHODS bdc_dynpro
    IMPORTING iv_program TYPE csequence
              iv_dynpro  TYPE csequence
    CHANGING  ct_bdcdata TYPE STANDARD TABLE.

  METHODS bdc_field
    IMPORTING iv_name    TYPE csequence
              iv_value   TYPE csequence
    CHANGING  ct_bdcdata TYPE STANDARD TABLE.

ENDINTERFACE.
