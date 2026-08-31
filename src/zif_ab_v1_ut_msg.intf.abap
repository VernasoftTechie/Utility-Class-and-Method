"! <p class="shorttext synchronized">ZCL_AB_V1_UT: messages / exceptions</p>
"! RAP-mode: all methods are Core. Never issues MESSAGE to screen.
INTERFACE zif_ab_v1_ut_msg
  PUBLIC.

  METHODS t100_to_text
    IMPORTING iv_msgid  TYPE symsgid
              iv_msgno  TYPE symsgno
              iv_v1     TYPE clike OPTIONAL
              iv_v2     TYPE clike OPTIONAL
              iv_v3     TYPE clike OPTIONAL
              iv_v4     TYPE clike OPTIONAL
    RETURNING VALUE(rv) TYPE string.

  METHODS t100_to_bapiret
    IMPORTING iv_msgid  TYPE symsgid
              iv_msgno  TYPE symsgno
              iv_type   TYPE symsgty DEFAULT 'E'
              iv_v1     TYPE clike OPTIONAL
              iv_v2     TYPE clike OPTIONAL
              iv_v3     TYPE clike OPTIONAL
              iv_v4     TYPE clike OPTIONAL
    RETURNING VALUE(rs) TYPE bapiret2.

  METHODS exception_to_text
    IMPORTING io_exception  TYPE REF TO cx_root
              iv_long       TYPE abap_bool DEFAULT abap_false
              iv_with_chain TYPE abap_bool DEFAULT abap_true
    RETURNING VALUE(rv)     TYPE string.

  METHODS bapiret_has_error
    IMPORTING it_return TYPE bapiret2_t
    RETURNING VALUE(rv) TYPE abap_bool.

  METHODS bapiret_max_severity
    IMPORTING it_return TYPE bapiret2_t
    RETURNING VALUE(rv) TYPE symsgty.

  METHODS bapiret_filter
    IMPORTING it_return TYPE bapiret2_t
              iv_types  TYPE string DEFAULT 'EAX'
    RETURNING VALUE(rt) TYPE bapiret2_t.

  METHODS raise
    IMPORTING iv_msgid    TYPE symsgid DEFAULT 'ZAB_V1_UT'
              iv_msgno    TYPE symsgno
              iv_v1       TYPE clike OPTIONAL
              iv_v2       TYPE clike OPTIONAL
              iv_v3       TYPE clike OPTIONAL
              iv_v4       TYPE clike OPTIONAL
              io_previous TYPE REF TO cx_root OPTIONAL
    RAISING   zcx_ab_v1_ut.

  METHODS to_reported
    IMPORTING it_return TYPE bapiret2_t
              is_key    TYPE any
    CHANGING  reported  TYPE any.

  METHODS to_failed
    IMPORTING is_key   TYPE any
    CHANGING  failed   TYPE any.

ENDINTERFACE.
