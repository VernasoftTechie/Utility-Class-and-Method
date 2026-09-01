"! <p class="shorttext synchronized">ZCL_AB_V1_UT: string / type / conversion</p>
"! RAP-mode: all methods are Core (pure, side-effect free).
INTERFACE zif_ab_v1_ut_str
  PUBLIC.

  TYPES ty_notation TYPE c LENGTH 2.
  CONSTANTS:
    BEGIN OF c_notation,
      us  TYPE ty_notation VALUE 'US',   " 1,234.56
      eu  TYPE ty_notation VALUE 'EU',   " 1.234,56
      raw TYPE ty_notation VALUE 'RW',   " 1234.56
    END OF c_notation.
  CONSTANTS:
    BEGIN OF c_algo,
      md5    TYPE string VALUE 'MD5',
      sha1   TYPE string VALUE 'SHA1',
      sha256 TYPE string VALUE 'SHA256',
    END OF c_algo.
  CONSTANTS:
    BEGIN OF c_kind,
      email TYPE string VALUE 'EMAIL',
      phone TYPE string VALUE 'PHONE',
      iban  TYPE string VALUE 'IBAN',
      pan   TYPE string VALUE 'PAN',
      gstin TYPE string VALUE 'GSTIN',
    END OF c_kind.

  METHODS to_amount
    IMPORTING iv_text        TYPE string
              iv_currency    TYPE waers_curc OPTIONAL
              iv_notation    TYPE ty_notation DEFAULT c_notation-raw
    RETURNING VALUE(rv_amount) TYPE decfloat34
    RAISING   zcx_ab_v1_ut.

  METHODS from_amount
    IMPORTING iv_amount     TYPE numeric
              iv_currency   TYPE waers_curc OPTIONAL
              iv_notation   TYPE ty_notation DEFAULT c_notation-raw
    RETURNING VALUE(rv_text) TYPE string.

  METHODS to_quantity
    IMPORTING iv_text      TYPE string
              iv_unit      TYPE meins OPTIONAL
    RETURNING VALUE(rv_qty) TYPE decfloat34
    RAISING   zcx_ab_v1_ut.

  METHODS from_quantity
    IMPORTING iv_qty        TYPE numeric
              iv_unit       TYPE meins OPTIONAL
    RETURNING VALUE(rv_text) TYPE string.

  METHODS to_date
    IMPORTING iv_text       TYPE string
              iv_format     TYPE string OPTIONAL
    RETURNING VALUE(rv_date) TYPE d
    RAISING   zcx_ab_v1_ut.

  METHODS from_date
    IMPORTING iv_date       TYPE d
              iv_format     TYPE string OPTIONAL
    RETURNING VALUE(rv_text) TYPE string.

  METHODS to_time
    IMPORTING iv_text       TYPE string
    RETURNING VALUE(rv_time) TYPE t
    RAISING   zcx_ab_v1_ut.

  METHODS from_time
    IMPORTING iv_time          TYPE t
              iv_with_seconds  TYPE abap_bool DEFAULT abap_true
    RETURNING VALUE(rv_text)   TYPE string.

  METHODS alpha_in
    IMPORTING iv_value    TYPE clike
    RETURNING VALUE(rv)   TYPE string.

  METHODS alpha_out
    IMPORTING iv_value    TYPE clike
    RETURNING VALUE(rv)   TYPE string.

  METHODS pad
    IMPORTING iv_value  TYPE clike
              iv_len    TYPE i
              iv_char   TYPE c DEFAULT ' '
              iv_side   TYPE c DEFAULT 'L'
    RETURNING VALUE(rv) TYPE string.

  METHODS mask
    IMPORTING iv_value          TYPE clike
              iv_visible_prefix TYPE i DEFAULT 0
              iv_visible_suffix TYPE i DEFAULT 4
              iv_char           TYPE c DEFAULT '*'
    RETURNING VALUE(rv)         TYPE string.

  METHODS split
    IMPORTING iv_value  TYPE string
              iv_sep    TYPE string DEFAULT ','
              iv_trim   TYPE abap_bool DEFAULT abap_true
    RETURNING VALUE(rt) TYPE zif_ab_v1_ut_types=>ty_string_tab.

  METHODS join
    IMPORTING it_values TYPE zif_ab_v1_ut_types=>ty_string_tab
              iv_sep    TYPE string DEFAULT ','
    RETURNING VALUE(rv) TYPE string.

  METHODS to_camel
    IMPORTING iv_value  TYPE string
              iv_pascal TYPE abap_bool DEFAULT abap_false
    RETURNING VALUE(rv) TYPE string.

  METHODS to_snake
    IMPORTING iv_value  TYPE string
    RETURNING VALUE(rv) TYPE string.

  METHODS base64_encode
    IMPORTING iv_data   TYPE xstring
    RETURNING VALUE(rv) TYPE string.

  METHODS base64_decode
    IMPORTING iv_b64    TYPE string
    RETURNING VALUE(rv) TYPE xstring
    RAISING   zcx_ab_v1_ut.

  METHODS to_xstring
    IMPORTING iv_string   TYPE string
              iv_codepage TYPE cpcodepage OPTIONAL
    RETURNING VALUE(rv)   TYPE xstring
    RAISING   zcx_ab_v1_ut.

  METHODS from_xstring
    IMPORTING iv_xstring  TYPE xstring
              iv_codepage TYPE cpcodepage OPTIONAL
    RETURNING VALUE(rv)   TYPE string
    RAISING   zcx_ab_v1_ut.

  METHODS hash
    IMPORTING iv_data      TYPE string
              iv_algo      TYPE string DEFAULT c_algo-sha256
    RETURNING VALUE(rv_hex) TYPE string
    RAISING   zcx_ab_v1_ut.

  METHODS regex_match
    IMPORTING iv_value   TYPE string
              iv_pattern TYPE string
    RETURNING VALUE(rv)  TYPE abap_bool.

  METHODS regex_replace
    IMPORTING iv_value   TYPE string
              iv_pattern TYPE string
              iv_with    TYPE string
    RETURNING VALUE(rv)  TYPE string.

  METHODS regex_groups
    IMPORTING iv_value   TYPE string
              iv_pattern TYPE string
    RETURNING VALUE(rt)  TYPE zif_ab_v1_ut_types=>ty_string_tab.

  METHODS amount_in_words
    IMPORTING iv_amount   TYPE numeric
              iv_currency TYPE waers_curc
    RETURNING VALUE(rv)   TYPE string
    RAISING   zcx_ab_v1_ut.

  METHODS is_valid
    IMPORTING iv_value  TYPE string
              iv_kind   TYPE string
    RETURNING VALUE(rv) TYPE abap_bool.

ENDINTERFACE.
