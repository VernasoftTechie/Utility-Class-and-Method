"! <p class="shorttext synchronized">ZCL_AB_V1_UT: application log (BAL)</p>
"! RAP-mode: create / add_* / to_* are Core; save is DEFER (own LUW); display is GUI.
"! API: released cl_bali_* OO Application Log.
INTERFACE zif_ab_v1_ut_log
  PUBLIC.

  METHODS create
    IMPORTING iv_object    TYPE balobj_d DEFAULT 'ZAB_V1_UT'
              iv_subobject TYPE balsubobj DEFAULT 'GENERAL'
              iv_extnumber TYPE balnrext OPTIONAL
              iv_in_memory TYPE abap_bool DEFAULT abap_true
    RETURNING VALUE(ro_log) TYPE REF TO zif_ab_v1_ut_log
    RAISING   zcx_ab_v1_ut.

  METHODS add_symsg
    RETURNING VALUE(ro_log) TYPE REF TO zif_ab_v1_ut_log.

  METHODS add_t100
    IMPORTING iv_msgid TYPE symsgid
              iv_msgno TYPE symsgno
              iv_type  TYPE symsgty DEFAULT 'E'
              iv_v1    TYPE clike OPTIONAL
              iv_v2    TYPE clike OPTIONAL
              iv_v3    TYPE clike OPTIONAL
              iv_v4    TYPE clike OPTIONAL
    RETURNING VALUE(ro_log) TYPE REF TO zif_ab_v1_ut_log.

  METHODS add_bapiret
    IMPORTING it_return    TYPE bapiret2_t
    RETURNING VALUE(ro_log) TYPE REF TO zif_ab_v1_ut_log.

  METHODS add_exception
    IMPORTING io_exception TYPE REF TO cx_root
              iv_type      TYPE symsgty DEFAULT 'E'
    RETURNING VALUE(ro_log) TYPE REF TO zif_ab_v1_ut_log.

  "! DEFER - requires late_save / after_commit phase in RAP.
  METHODS save
    IMPORTING iv_commit TYPE abap_bool DEFAULT abap_false
    RAISING   zcx_ab_v1_ut.

  "! GUI
  METHODS display
    RAISING zcx_ab_v1_ut.

  METHODS handle
    RETURNING VALUE(rv) TYPE balloghndl.

  METHODS to_bapiret
    RETURNING VALUE(rt) TYPE bapiret2_t.

  "! @parameter iv_sep | line separator; defaults to newline when not supplied
  METHODS to_string
    IMPORTING iv_sep    TYPE string OPTIONAL
    RETURNING VALUE(rv) TYPE string.

ENDINTERFACE.
