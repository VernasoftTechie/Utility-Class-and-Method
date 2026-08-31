"! <p class="shorttext synchronized">ZCL_AB_V1_UT: spreadsheet (xlsx)</p>
"! RAP-mode: all methods are Core (operate on XSTRING, no GUI). Engine: xco_cp_xlsx.
INTERFACE zif_ab_v1_ut_excel
  PUBLIC.

  TYPES:
    BEGIN OF ty_options,
      sheet_name  TYPE string,
      header_bold TYPE abap_bool,
      auto_filter TYPE abap_bool,
      freeze_row  TYPE i,
      freeze_col  TYPE i,
    END OF ty_options.
  TYPES:
    BEGIN OF ty_error,
      row    TYPE i,
      column TYPE string,
      reason TYPE string,
    END OF ty_error.
  TYPES ty_error_tab TYPE STANDARD TABLE OF ty_error WITH EMPTY KEY.

  METHODS read
    IMPORTING iv_xlsx      TYPE xstring
              it_mapping   TYPE zif_ab_v1_ut_types=>ty_nv_tab OPTIONAL
              iv_sheet     TYPE string OPTIONAL
              iv_max_rows  TYPE i DEFAULT 0
    EXPORTING et_data      TYPE STANDARD TABLE
              et_errors    TYPE ty_error_tab
              et_unmapped  TYPE zif_ab_v1_ut_types=>ty_string_tab
    RAISING   zcx_ab_v1_ut.

  METHODS write
    IMPORTING it_data       TYPE ANY TABLE
              is_options    TYPE ty_options OPTIONAL
    RETURNING VALUE(rv_xlsx) TYPE xstring
    RAISING   zcx_ab_v1_ut.

  METHODS write_multi
    IMPORTING it_sheets     TYPE zif_ab_v1_ut_types=>ty_nv_tab
    RETURNING VALUE(rv_xlsx) TYPE xstring
    RAISING   zcx_ab_v1_ut.

  METHODS generate_template
    IMPORTING iv_structure    TYPE string
              it_column_texts TYPE zif_ab_v1_ut_types=>ty_nv_tab OPTIONAL
    RETURNING VALUE(rv_xlsx)  TYPE xstring
    RAISING   zcx_ab_v1_ut.

ENDINTERFACE.
