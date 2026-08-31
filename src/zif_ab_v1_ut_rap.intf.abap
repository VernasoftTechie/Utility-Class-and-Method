"! <p class="shorttext synchronized">ZCL_AB_V1_UT: RAP-native helpers</p>
"! RAP-mode: all methods are Core. Helpers for behaviour implementations.
INTERFACE zif_ab_v1_ut_rap
  PUBLIC.

  METHODS read_entity
    IMPORTING iv_entity   TYPE string
              it_keys     TYPE ANY TABLE
    EXPORTING et_result   TYPE STANDARD TABLE
              et_messages TYPE bapiret2_t
    RAISING   zcx_ab_v1_ut.

  METHODS modify_entity
    IMPORTING iv_entity    TYPE string
              it_instances TYPE ANY TABLE
              iv_operation TYPE string DEFAULT 'UPDATE'
    EXPORTING et_messages  TYPE bapiret2_t
    RAISING   zcx_ab_v1_ut.

  METHODS new_cid
    RETURNING VALUE(rv) TYPE string.

  METHODS failed_add
    IMPORTING is_key        TYPE any
              iv_fail_cause TYPE i DEFAULT 0
    CHANGING  failed        TYPE any.

  METHODS reported_add
    IMPORTING is_key     TYPE any
              io_message TYPE REF TO if_abap_behv_message
    CHANGING  reported   TYPE any.

  METHODS auth_to_failed
    IMPORTING iv_authorized TYPE abap_bool
              is_key        TYPE any
              iv_object     TYPE xuobject
    CHANGING  failed        TYPE any
              reported      TYPE any.

  METHODS reported_to_bapiret
    IMPORTING it_reported TYPE ANY TABLE
    RETURNING VALUE(rt)   TYPE bapiret2_t.

  METHODS corresponding_control
    IMPORTING is_source  TYPE any
              is_control TYPE any
    CHANGING  cs_target  TYPE any.

ENDINTERFACE.
