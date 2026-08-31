"! <p class="shorttext synchronized">ZCL_AB_V1_UT: dynamic database access</p>
"! RAP-mode: exists / read_single / describe / where_from_ranges are Core;
"! read (dynamic SELECT) is GATED - reports &amp; migration tooling only, not RAP BO logic.
INTERFACE zif_ab_v1_ut_db
  PUBLIC.

  "! GATED. Dynamic SELECT. Table &amp; field names are validated against DDIC before use.
  METHODS read
    IMPORTING iv_entity     TYPE string
              it_columns    TYPE zif_ab_v1_ut_types=>ty_string_tab OPTIONAL
              it_where      TYPE zif_ab_v1_ut_types=>ty_string_tab OPTIONAL
              it_order_by   TYPE zif_ab_v1_ut_types=>ty_string_tab OPTIONAL
              iv_up_to      TYPE i DEFAULT 0
    RETURNING VALUE(rr_result) TYPE REF TO data
    RAISING   zcx_ab_v1_ut.

  METHODS exists
    IMPORTING iv_entity TYPE string
              it_keys   TYPE zif_ab_v1_ut_types=>ty_key_tab
    RETURNING VALUE(rv) TYPE abap_bool
    RAISING   zcx_ab_v1_ut.

  METHODS read_single
    IMPORTING iv_entity TYPE string
              it_keys   TYPE zif_ab_v1_ut_types=>ty_key_tab
    EXPORTING es_row    TYPE any
    RAISING   zcx_ab_v1_ut.

  METHODS describe
    IMPORTING iv_entity      TYPE string
    RETURNING VALUE(rr_meta) TYPE REF TO data
    RAISING   zcx_ab_v1_ut.

  METHODS where_from_ranges
    IMPORTING it_ranges TYPE zif_ab_v1_ut_types=>ty_nv_tab
    RETURNING VALUE(rt) TYPE zif_ab_v1_ut_types=>ty_string_tab.

ENDINTERFACE.
