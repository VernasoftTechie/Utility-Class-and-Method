"! <p class="shorttext synchronized">ZCL_AB_V1_UT: RAP-native helpers</p>
"! RAP-mode: all methods are Core. Small helpers for behaviour implementations.
"! Populating FAILED / REPORTED tables is BO-specific and stays inline in the BO;
"! this interface only provides the type conversions and generic copies.
INTERFACE zif_ab_v1_ut_rap
  PUBLIC.

  TYPES tt_behv_msg TYPE STANDARD TABLE OF REF TO if_abap_behv_message WITH EMPTY KEY.

  "! Fresh content ID for a RAP create (%cid).
  METHODS new_cid
    RETURNING VALUE(rv) TYPE string.

  "! RAP behaviour messages -> BAPIRET2 table.
  METHODS messages_to_bapiret
    IMPORTING it_messages TYPE tt_behv_msg
    RETURNING VALUE(rt)   TYPE bapiret2_t.

  "! BAPIRET2 table -> plain text lines.
  METHODS bapiret_to_text
    IMPORTING it_return TYPE bapiret2_t
    RETURNING VALUE(rt) TYPE zif_ab_v1_ut_types=>ty_string_tab.

  "! Copy from is_source into cs_target only the components whose flag in
  "! is_control is set (RAP %control pattern). Components are matched by name.
  METHODS corresponding_control
    IMPORTING is_source  TYPE any
              is_control TYPE any
    CHANGING  cs_target  TYPE any.

ENDINTERFACE.
