"! <p class="shorttext synchronized">ZCL_AB_V1_UT: internal table / RTTI / dynamic data</p>
"! RAP-mode: all methods are Core.
INTERFACE zif_ab_v1_ut_tab
  PUBLIC.

  METHODS create_dynamic
    IMPORTING it_fields     TYPE zif_ab_v1_ut_types=>ty_nv_tab OPTIONAL
              iv_structure  TYPE string OPTIONAL
              io_type       TYPE REF TO cl_abap_datadescr OPTIONAL
    RETURNING VALUE(rr_table) TYPE REF TO data
    RAISING   zcx_ab_v1_ut.

  METHODS map_corresponding
    IMPORTING it_source  TYPE ANY TABLE
              it_mapping TYPE zif_ab_v1_ut_types=>ty_nv_tab
    CHANGING  ct_target  TYPE STANDARD TABLE
    RAISING   zcx_ab_v1_ut.

  METHODS aggregate
    IMPORTING it_data     TYPE ANY TABLE
              it_group_by TYPE zif_ab_v1_ut_types=>ty_string_tab
              it_measures TYPE zif_ab_v1_ut_types=>ty_nv_tab
    EXPORTING et_result   TYPE STANDARD TABLE
    RAISING   zcx_ab_v1_ut.

  METHODS sort_dynamic
    IMPORTING it_order_by TYPE zif_ab_v1_ut_types=>ty_nv_tab
    CHANGING  ct_data     TYPE STANDARD TABLE.

  METHODS distinct
    IMPORTING it_fields TYPE zif_ab_v1_ut_types=>ty_string_tab OPTIONAL
    CHANGING  ct_data   TYPE STANDARD TABLE.

  METHODS diff
    IMPORTING it_old        TYPE ANY TABLE
              it_new        TYPE ANY TABLE
              it_key_fields TYPE zif_ab_v1_ut_types=>ty_string_tab
    EXPORTING et_insert     TYPE STANDARD TABLE
              et_update     TYPE STANDARD TABLE
              et_delete     TYPE STANDARD TABLE
    RAISING   zcx_ab_v1_ut.

  METHODS to_ranges
    IMPORTING it_values TYPE ANY TABLE
              iv_sign   TYPE c DEFAULT 'I'
              iv_option TYPE c DEFAULT 'EQ'
    EXPORTING et_range  TYPE ANY TABLE.

  METHODS chunk
    IMPORTING it_data       TYPE ANY TABLE
              iv_size       TYPE i
    RETURNING VALUE(rr_chunks) TYPE REF TO data.

  METHODS pivot
    IMPORTING it_data       TYPE ANY TABLE
              iv_row_field  TYPE string
              iv_col_field  TYPE string
              iv_value_field TYPE string
    EXPORTING et_result     TYPE STANDARD TABLE
    RAISING   zcx_ab_v1_ut.

  METHODS fingerprint
    IMPORTING is_data   TYPE any
    RETURNING VALUE(rv) TYPE string.

  METHODS deep_equal
    IMPORTING ir_a      TYPE REF TO data
              ir_b      TYPE REF TO data
    RETURNING VALUE(rv) TYPE abap_bool.

ENDINTERFACE.
