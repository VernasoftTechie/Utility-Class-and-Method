"! <p class="shorttext synchronized">ZCL_AB_V1_UT: utility framework facade</p>
"! Single entry point for the headless utility areas. Each accessor returns a
"! lazily-created singleton implementing the area interface. SAP GUI utilities
"! (ALV, presentation-server files) are NOT reachable here - call ZCL_AB_V1_UT_GUI
"! directly from classic reports.
CLASS zcl_ab_v1_ut DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.

    "--- area accessors (lazy singleton) ------------------------------------
    CLASS-METHODS str    RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_str.
    CLASS-METHODS conv   RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_conv.
    CLASS-METHODS tab    RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_tab.
    CLASS-METHODS db     RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_db.
    CLASS-METHODS file   RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_file.
    CLASS-METHODS excel  RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_excel.
    CLASS-METHODS json   RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_json.
    CLASS-METHODS log    RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_log.
    CLASS-METHODS msg    RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_msg.
    CLASS-METHODS auth   RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_auth.
    CLASS-METHODS num    RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_num.
    CLASS-METHODS mail   RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_mail.
    CLASS-METHODS attach RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_attach.
    CLASS-METHODS sys    RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_sys.
    CLASS-METHODS cfg    RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_cfg.
    CLASS-METHODS rap    RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_rap.
    CLASS-METHODS job    RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_job.

    "--- RAP phase context (drives the Defer guard) ------------------------
    CLASS-METHODS set_phase IMPORTING iv_phase TYPE zif_ab_v1_ut_types=>ty_phase.
    CLASS-METHODS phase     RETURNING VALUE(rv) TYPE zif_ab_v1_ut_types=>ty_phase.

    "--- test seams (ABAP Unit only) -------------------------------------
    CLASS-METHODS set_str    IMPORTING io TYPE REF TO zif_ab_v1_ut_str.
    CLASS-METHODS set_conv   IMPORTING io TYPE REF TO zif_ab_v1_ut_conv.
    CLASS-METHODS set_tab    IMPORTING io TYPE REF TO zif_ab_v1_ut_tab.
    CLASS-METHODS set_db     IMPORTING io TYPE REF TO zif_ab_v1_ut_db.
    CLASS-METHODS set_file   IMPORTING io TYPE REF TO zif_ab_v1_ut_file.
    CLASS-METHODS set_excel  IMPORTING io TYPE REF TO zif_ab_v1_ut_excel.
    CLASS-METHODS set_json   IMPORTING io TYPE REF TO zif_ab_v1_ut_json.
    CLASS-METHODS set_log    IMPORTING io TYPE REF TO zif_ab_v1_ut_log.
    CLASS-METHODS set_msg    IMPORTING io TYPE REF TO zif_ab_v1_ut_msg.
    CLASS-METHODS set_auth   IMPORTING io TYPE REF TO zif_ab_v1_ut_auth.
    CLASS-METHODS set_num    IMPORTING io TYPE REF TO zif_ab_v1_ut_num.
    CLASS-METHODS set_mail   IMPORTING io TYPE REF TO zif_ab_v1_ut_mail.
    CLASS-METHODS set_attach IMPORTING io TYPE REF TO zif_ab_v1_ut_attach.
    CLASS-METHODS set_sys    IMPORTING io TYPE REF TO zif_ab_v1_ut_sys.
    CLASS-METHODS set_cfg    IMPORTING io TYPE REF TO zif_ab_v1_ut_cfg.
    CLASS-METHODS set_rap    IMPORTING io TYPE REF TO zif_ab_v1_ut_rap.
    CLASS-METHODS set_job    IMPORTING io TYPE REF TO zif_ab_v1_ut_job.
    CLASS-METHODS reset.

  PRIVATE SECTION.
    CLASS-DATA:
      go_str    TYPE REF TO zif_ab_v1_ut_str,
      go_conv   TYPE REF TO zif_ab_v1_ut_conv,
      go_tab    TYPE REF TO zif_ab_v1_ut_tab,
      go_db     TYPE REF TO zif_ab_v1_ut_db,
      go_file   TYPE REF TO zif_ab_v1_ut_file,
      go_excel  TYPE REF TO zif_ab_v1_ut_excel,
      go_json   TYPE REF TO zif_ab_v1_ut_json,
      go_log    TYPE REF TO zif_ab_v1_ut_log,
      go_msg    TYPE REF TO zif_ab_v1_ut_msg,
      go_auth   TYPE REF TO zif_ab_v1_ut_auth,
      go_num    TYPE REF TO zif_ab_v1_ut_num,
      go_mail   TYPE REF TO zif_ab_v1_ut_mail,
      go_attach TYPE REF TO zif_ab_v1_ut_attach,
      go_sys    TYPE REF TO zif_ab_v1_ut_sys,
      go_cfg    TYPE REF TO zif_ab_v1_ut_cfg,
      go_rap    TYPE REF TO zif_ab_v1_ut_rap,
      go_job    TYPE REF TO zif_ab_v1_ut_job.

    CLASS-METHODS resolve_attach RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_attach.
ENDCLASS.



CLASS zcl_ab_v1_ut IMPLEMENTATION.

  METHOD str.
    IF go_str IS NOT BOUND.
      go_str = NEW zcl_ab_v1_ut_str( ).
    ENDIF.
    ro = go_str.
  ENDMETHOD.

  METHOD conv.
    IF go_conv IS NOT BOUND.
      go_conv = NEW zcl_ab_v1_ut_conv( ).
    ENDIF.
    ro = go_conv.
  ENDMETHOD.

  METHOD tab.
    IF go_tab IS NOT BOUND.
      go_tab = NEW zcl_ab_v1_ut_tab( ).
    ENDIF.
    ro = go_tab.
  ENDMETHOD.

  METHOD db.
    IF go_db IS NOT BOUND.
      go_db = NEW zcl_ab_v1_ut_db( ).
    ENDIF.
    ro = go_db.
  ENDMETHOD.

  METHOD file.
    IF go_file IS NOT BOUND.
      go_file = NEW zcl_ab_v1_ut_file( ).
    ENDIF.
    ro = go_file.
  ENDMETHOD.

  METHOD excel.
    IF go_excel IS NOT BOUND.
      go_excel = NEW zcl_ab_v1_ut_excel( ).
    ENDIF.
    ro = go_excel.
  ENDMETHOD.

  METHOD json.
    IF go_json IS NOT BOUND.
      go_json = NEW zcl_ab_v1_ut_json( ).
    ENDIF.
    ro = go_json.
  ENDMETHOD.

  METHOD log.
    IF go_log IS NOT BOUND.
      go_log = NEW zcl_ab_v1_ut_log( ).
    ENDIF.
    ro = go_log.
  ENDMETHOD.

  METHOD msg.
    IF go_msg IS NOT BOUND.
      go_msg = NEW zcl_ab_v1_ut_msg( ).
    ENDIF.
    ro = go_msg.
  ENDMETHOD.

  METHOD auth.
    IF go_auth IS NOT BOUND.
      go_auth = NEW zcl_ab_v1_ut_auth( ).
    ENDIF.
    ro = go_auth.
  ENDMETHOD.

  METHOD num.
    IF go_num IS NOT BOUND.
      go_num = NEW zcl_ab_v1_ut_num( ).
    ENDIF.
    ro = go_num.
  ENDMETHOD.

  METHOD mail.
    IF go_mail IS NOT BOUND.
      go_mail = NEW zcl_ab_v1_ut_mail( ).
    ENDIF.
    ro = go_mail.
  ENDMETHOD.

  METHOD attach.
    IF go_attach IS NOT BOUND.
      go_attach = resolve_attach( ).
    ENDIF.
    ro = go_attach.
  ENDMETHOD.

  METHOD sys.
    IF go_sys IS NOT BOUND.
      go_sys = NEW zcl_ab_v1_ut_sys( ).
    ENDIF.
    ro = go_sys.
  ENDMETHOD.

  METHOD cfg.
    IF go_cfg IS NOT BOUND.
      go_cfg = NEW zcl_ab_v1_ut_cfg( ).
    ENDIF.
    ro = go_cfg.
  ENDMETHOD.

  METHOD rap.
    IF go_rap IS NOT BOUND.
      go_rap = NEW zcl_ab_v1_ut_rap( ).
    ENDIF.
    ro = go_rap.
  ENDMETHOD.

  METHOD job.
    IF go_job IS NOT BOUND.
      go_job = NEW zcl_ab_v1_ut_job( ).
    ENDIF.
    ro = go_job.
  ENDMETHOD.


  METHOD resolve_attach.
    SELECT SINGLE adapter_class FROM zab_v1_ut_adpt
      INTO @DATA(lv_class)
      WHERE area      = 'ATTACH'
        AND is_active = @abap_true.

    IF sy-subrc = 0 AND lv_class IS NOT INITIAL.
      TRY.
          DATA lo TYPE REF TO object.
          CREATE OBJECT lo TYPE (lv_class).
          ro ?= lo.
          RETURN.
        CATCH cx_sy_create_object_error cx_sy_move_cast_error.
      ENDTRY.
    ENDIF.

    ro = NEW zcl_ab_v1_ut_attach_stub( ).
  ENDMETHOD.


  METHOD set_phase.
    zcl_ab_v1_ut_phase=>set( iv_phase ).
  ENDMETHOD.

  METHOD phase.
    rv = zcl_ab_v1_ut_phase=>get( ).
  ENDMETHOD.


  METHOD set_str.    go_str    = io. ENDMETHOD.
  METHOD set_conv.   go_conv   = io. ENDMETHOD.
  METHOD set_tab.    go_tab    = io. ENDMETHOD.
  METHOD set_db.     go_db     = io. ENDMETHOD.
  METHOD set_file.   go_file   = io. ENDMETHOD.
  METHOD set_excel.  go_excel  = io. ENDMETHOD.
  METHOD set_json.   go_json   = io. ENDMETHOD.
  METHOD set_log.    go_log    = io. ENDMETHOD.
  METHOD set_msg.    go_msg    = io. ENDMETHOD.
  METHOD set_auth.   go_auth   = io. ENDMETHOD.
  METHOD set_num.    go_num    = io. ENDMETHOD.
  METHOD set_mail.   go_mail   = io. ENDMETHOD.
  METHOD set_attach. go_attach = io. ENDMETHOD.
  METHOD set_sys.    go_sys    = io. ENDMETHOD.
  METHOD set_cfg.    go_cfg    = io. ENDMETHOD.
  METHOD set_rap.    go_rap    = io. ENDMETHOD.
  METHOD set_job.    go_job    = io. ENDMETHOD.

  METHOD reset.
    CLEAR: go_str, go_conv, go_tab, go_db, go_file, go_excel, go_json, go_log,
           go_msg, go_auth, go_num, go_mail, go_attach, go_sys, go_cfg, go_rap, go_job.
    zcl_ab_v1_ut_phase=>set( zif_ab_v1_ut_types=>c_phase-unknown ).
  ENDMETHOD.

ENDCLASS.
