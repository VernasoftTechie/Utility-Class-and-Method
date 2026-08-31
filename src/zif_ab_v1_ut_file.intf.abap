"! <p class="shorttext synchronized">ZCL_AB_V1_UT: file services</p>
"! RAP-mode: resolve_logical / mime_type / zip / unzip / csv_* are Core;
"! as_* (application-server OPEN DATASET) are GATED - S_DATASET check + path validation.
"! Presentation-server file dialogs live on ZCL_AB_V1_UT_GUI (GUI only).
INTERFACE zif_ab_v1_ut_file
  PUBLIC.

  CONSTANTS:
    BEGIN OF c_mode,
      text   TYPE string VALUE 'TEXT',
      binary TYPE string VALUE 'BIN',
    END OF c_mode.

  METHODS resolve_logical
    IMPORTING iv_logical_name TYPE fileintern
              iv_params       TYPE zif_ab_v1_ut_types=>ty_nv_tab OPTIONAL
    RETURNING VALUE(rv_path)  TYPE string
    RAISING   zcx_ab_v1_ut.

  METHODS mime_type
    IMPORTING iv_filename TYPE string
              iv_content  TYPE xstring OPTIONAL
    RETURNING VALUE(rv)   TYPE string.

  METHODS zip
    IMPORTING it_files     TYPE zif_ab_v1_ut_types=>ty_nv_tab
    RETURNING VALUE(rv_zip) TYPE xstring
    RAISING   zcx_ab_v1_ut.

  METHODS unzip
    IMPORTING iv_zip         TYPE xstring
    RETURNING VALUE(rt_files) TYPE zif_ab_v1_ut_types=>ty_nv_tab
    RAISING   zcx_ab_v1_ut.

  METHODS csv_parse
    IMPORTING iv_content TYPE string
              iv_sep     TYPE c DEFAULT ','
              iv_header  TYPE abap_bool DEFAULT abap_true
    EXPORTING et_table   TYPE STANDARD TABLE
    RAISING   zcx_ab_v1_ut.

  METHODS csv_build
    IMPORTING it_table  TYPE ANY TABLE
              iv_sep    TYPE c DEFAULT ','
              iv_header TYPE abap_bool DEFAULT abap_true
    RETURNING VALUE(rv) TYPE string.

  "! GATED
  METHODS as_read
    IMPORTING iv_logical_name TYPE fileintern OPTIONAL
              iv_path         TYPE string OPTIONAL
              iv_mode         TYPE string DEFAULT c_mode-binary
    RETURNING VALUE(rv_content) TYPE xstring
    RAISING   zcx_ab_v1_ut.

  "! GATED
  METHODS as_write
    IMPORTING iv_logical_name TYPE fileintern OPTIONAL
              iv_path         TYPE string OPTIONAL
              iv_content      TYPE xstring
              iv_append       TYPE abap_bool DEFAULT abap_false
              iv_mode         TYPE string DEFAULT c_mode-binary
    RAISING   zcx_ab_v1_ut.

  "! GATED
  METHODS as_delete
    IMPORTING iv_path TYPE string
    RAISING   zcx_ab_v1_ut.

  "! GATED
  METHODS as_exists
    IMPORTING iv_path   TYPE string
    RETURNING VALUE(rv) TYPE abap_bool.

  "! GATED
  METHODS as_list_dir
    IMPORTING iv_dir    TYPE string
    RETURNING VALUE(rt) TYPE zif_ab_v1_ut_types=>ty_string_tab
    RAISING   zcx_ab_v1_ut.

ENDINTERFACE.
