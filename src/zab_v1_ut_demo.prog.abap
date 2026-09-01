*&---------------------------------------------------------------------*
*& Report ZAB_V1_UT_DEMO
*&---------------------------------------------------------------------*
*& Smoke test / demo for the headless (Core + Defer) areas of ZCL_AB_V1_UT.
*& Uses no SAP GUI control classes - safe to run in background.
*&---------------------------------------------------------------------*
REPORT zab_v1_ut_demo.

PARAMETERS: p_area TYPE zab_v1_ut_area AS LISTBOX VISIBLE LENGTH 25 DEFAULT 'STR',
            p_all  AS CHECKBOX,
            p_cmt  AS CHECKBOX,           " allow COMMIT / save side effects
            p_send AS CHECKBOX,           " actually send the demo mail
            p_rcpt TYPE string LOWER CASE.

CLASS lcl_demo DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS run IMPORTING iv_area TYPE zab_v1_ut_area.
  PRIVATE SECTION.
    TYPES: BEGIN OF ty_line,
             id     TYPE i,
             name   TYPE string,
             amount TYPE p LENGTH 13 DECIMALS 2,
           END OF ty_line.

    METHODS w IMPORTING iv TYPE string.
    METHODS h IMPORTING iv TYPE string.

    METHODS demo_str    RAISING zcx_ab_v1_ut.
    METHODS demo_conv   RAISING zcx_ab_v1_ut.
    METHODS demo_tab    RAISING zcx_ab_v1_ut.
    METHODS demo_db     RAISING zcx_ab_v1_ut.
    METHODS demo_file   RAISING zcx_ab_v1_ut.
    METHODS demo_json   RAISING zcx_ab_v1_ut.
    METHODS demo_log    RAISING zcx_ab_v1_ut.
    METHODS demo_msg    RAISING zcx_ab_v1_ut.
    METHODS demo_auth.
    METHODS demo_num    RAISING zcx_ab_v1_ut.
    METHODS demo_mail   RAISING zcx_ab_v1_ut.
    METHODS demo_attach RAISING zcx_ab_v1_ut.
    METHODS demo_sys.
    METHODS demo_cfg    RAISING zcx_ab_v1_ut.
    METHODS demo_rap.
    METHODS demo_job.
ENDCLASS.

CLASS lcl_demo IMPLEMENTATION.

  METHOD w.
    WRITE / iv.
  ENDMETHOD.

  METHOD h.
    SKIP.
    WRITE / |=== { iv } ===|.
    ULINE.
  ENDMETHOD.

  METHOD run.
    TRY.
        CASE iv_area.
          WHEN 'STR'.    demo_str( ).
          WHEN 'CONV'.   demo_conv( ).
          WHEN 'TAB'.    demo_tab( ).
          WHEN 'DB'.     demo_db( ).
          WHEN 'FILE'.   demo_file( ).
          WHEN 'JSON'.   demo_json( ).
          WHEN 'LOG'.    demo_log( ).
          WHEN 'MSG'.    demo_msg( ).
          WHEN 'AUTH'.   demo_auth( ).
          WHEN 'NUM'.    demo_num( ).
          WHEN 'MAIL'.   demo_mail( ).
          WHEN 'ATTACH'. demo_attach( ).
          WHEN 'SYS'.    demo_sys( ).
          WHEN 'CFG'.    demo_cfg( ).
          WHEN 'RAP'.    demo_rap( ).
          WHEN 'JOB'.    demo_job( ).
          WHEN OTHERS.   w( |(no demo for area { iv_area })| ).
        ENDCASE.
      CATCH cx_root INTO DATA(lx).
        w( |ERROR: { lx->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD demo_str.
    h( `STR` ).
    DATA(o) = zcl_ab_v1_ut=>str( ).
    w( |to_amount('1.234,56' EU) = { o->to_amount( iv_text = '1.234,56' iv_notation = zif_ab_v1_ut_str=>c_notation-eu ) }| ).
    w( |from_amount(1234.5 EUR EU) = { o->from_amount( iv_amount = CONV decfloat34( '1234.5' ) iv_currency = 'EUR' iv_notation = zif_ab_v1_ut_str=>c_notation-eu ) }| ).
    w( |alpha_in('4711') = { o->alpha_in( '4711' ) }| ).
    w( |sha256('abc') = { o->hash( iv_data = 'abc' iv_algo = zif_ab_v1_ut_str=>c_algo-sha256 ) }| ).
    w( |is_valid email a@b.com = { o->is_valid( iv_value = 'a@b.com' iv_kind = zif_ab_v1_ut_str=>c_kind-email ) }| ).
    w( |amount_in_words(105.25 USD) = { o->amount_in_words( iv_amount = CONV decfloat34( '105.25' ) iv_currency = 'USD' ) }| ).
  ENDMETHOD.

  METHOD demo_conv.
    h( `CONV` ).
    DATA(o) = zcl_ab_v1_ut=>conv( ).
    DATA(today) = cl_abap_context_info=>get_system_date( ).
    w( |add_months(today, 1) = { o->add_months( iv_date = today iv_months = 1 ) }| ).
    o->period_bounds( EXPORTING iv_date = today iv_kind = zif_ab_v1_ut_conv=>c_period-quarter
                      IMPORTING ev_first = DATA(f) ev_last = DATA(l) ).
    w( |quarter bounds = { f } .. { l }| ).
    w( |round(2.345, 2) = { o->round( iv_value = CONV decfloat34( '2.345' ) iv_decimals = 2 ) }| ).
  ENDMETHOD.

  METHOD demo_tab.
    h( `TAB` ).
    DATA lt_old TYPE STANDARD TABLE OF ty_line WITH EMPTY KEY.
    DATA lt_new LIKE lt_old.
    DATA lt_i   LIKE lt_old.
    DATA lt_u   LIKE lt_old.
    DATA lt_d   LIKE lt_old.
    lt_old = VALUE #( ( id = 1 name = 'A' ) ( id = 2 name = 'B' ) ).
    lt_new = VALUE #( ( id = 2 name = 'B2' ) ( id = 3 name = 'C' ) ).
    zcl_ab_v1_ut=>tab( )->diff( EXPORTING it_old = lt_old it_new = lt_new it_key_fields = VALUE #( ( `ID` ) )
                               IMPORTING et_insert = lt_i et_update = lt_u et_delete = lt_d ).
    w( |diff: insert={ lines( lt_i ) } update={ lines( lt_u ) } delete={ lines( lt_d ) }| ).
  ENDMETHOD.

  METHOD demo_db.
    h( `DB` ).
    DATA(exists) = zcl_ab_v1_ut=>db( )->exists( iv_entity = 'ZAB_V1_UT_ADPT'
                                                it_keys   = VALUE #( ( name = 'AREA' value = 'ATTACH' ) ) ).
    w( |ZAB_V1_UT_ADPT has an active ATTACH row = { exists }| ).
  ENDMETHOD.

  METHOD demo_file.
    h( `FILE` ).
    w( |mime_type('x.pdf') = { zcl_ab_v1_ut=>file( )->mime_type( 'x.pdf' ) }| ).
    DATA lt TYPE STANDARD TABLE OF ty_line WITH EMPTY KEY.
    lt = VALUE #( ( id = 1 name = 'A' amount = '10.00' ) ( id = 2 name = 'B' amount = '20.00' ) ).
    DATA(csv) = zcl_ab_v1_ut=>file( )->csv_build( it_table = lt iv_sep = ';' ).
    w( |csv header = { substring_before( val = csv sub = cl_abap_char_utilities=>newline ) }| ).
  ENDMETHOD.

  METHOD demo_json.
    h( `JSON` ).
    DATA(ls) = VALUE ty_line( id = 1 name = 'Ann' amount = '99.90' ).
    w( zcl_ab_v1_ut=>json( )->serialize( iv_data = ls iv_camel_case = abap_true iv_pretty = abap_true ) ).
  ENDMETHOD.

  METHOD demo_log.
    h( `LOG` ).
    DATA(lo) = zcl_ab_v1_ut=>log( )->create( iv_subobject = 'GENERAL' ).
    lo->add_t100( iv_msgid = 'ZAB_V1_UT' iv_msgno = '001' iv_type = 'I' iv_v1 = 'demo' ).
    lo->add_t100( iv_msgid = 'ZAB_V1_UT' iv_msgno = '001' iv_type = 'W' iv_v1 = 'warn' ).
    w( lo->to_string( ) ).
    IF p_cmt = abap_true.
      zcl_ab_v1_ut=>set_phase( zif_ab_v1_ut_types=>c_phase-unknown ).
      lo->save( iv_commit = abap_true ).
      w( `saved (see SLG1, object ZAB_V1_UT)` ).
    ENDIF.
  ENDMETHOD.

  METHOD demo_msg.
    h( `MSG` ).
    w( zcl_ab_v1_ut=>msg( )->t100_to_text( iv_msgid = 'ZAB_V1_UT' iv_msgno = '013' iv_v1 = 'SAVE' iv_v2 = '1' ) ).
    DATA(lt) = VALUE bapiret2_t( ( type = 'S' ) ( type = 'W' ) ( type = 'E' ) ).
    w( |max severity of S/W/E = { zcl_ab_v1_ut=>msg( )->bapiret_max_severity( lt ) }| ).
  ENDMETHOD.

  METHOD demo_auth.
    h( `AUTH` ).
    w( |check S_TCODE/SE38 = { zcl_ab_v1_ut=>auth( )->check( iv_object = 'S_TCODE'
             it_values = VALUE #( ( name = 'TCD' value = 'SE38' ) ) ) }| ).
    w( |is_user_valid({ sy-uname }) = { zcl_ab_v1_ut=>auth( )->is_user_valid( sy-uname ) }| ).
  ENDMETHOD.

  METHOD demo_num.
    h( `NUM` ).
    zcl_ab_v1_ut=>set_phase( zif_ab_v1_ut_types=>c_phase-unknown ).
    DO 3 TIMES.
      w( |next ZAB_V1_UT/01 = { zcl_ab_v1_ut=>num( )->next( iv_object = 'ZAB_V1_UT' iv_interval = '01' ) }| ).
    ENDDO.
  ENDMETHOD.

  METHOD demo_mail.
    h( `MAIL` ).
    DATA(body) = zcl_ab_v1_ut=>mail( )->build_html_body(
                   iv_title      = 'ZCL_AB_V1_UT demo'
                   it_paragraphs = VALUE #( ( `This is a demo mail.` ) ) ).
    w( |html body length = { strlen( body ) }| ).
    IF p_send = abap_true AND p_rcpt IS NOT INITIAL.
      zcl_ab_v1_ut=>set_phase( zif_ab_v1_ut_types=>c_phase-unknown ).
      DATA(id) = zcl_ab_v1_ut=>mail( )->send( VALUE #(
        recipients       = VALUE #( ( p_rcpt ) )
        subject          = 'ZCL_AB_V1_UT demo'
        body_html        = body
        send_immediately = abap_true
        commit_work      = abap_true ) ).
      w( |sent, request = { id }| ).
    ENDIF.
  ENDMETHOD.

  METHOD demo_attach.
    h( `ATTACH` ).
    DATA(o) = zcl_ab_v1_ut=>attach( ).
    w( |new_guid_c32 = { o->new_guid_c32( ) }| ).
    zcl_ab_v1_ut=>set_phase( zif_ab_v1_ut_types=>c_phase-unknown ).
    DATA lv_x TYPE xstring VALUE '48656C6C6F'.
    DATA(aid) = o->attach( is_bo_key   = VALUE #( objtype = 'ZDEMO' objkey = 'K1' )
                           iv_filename = 'demo.txt' iv_mimetype = 'text/plain' iv_content = lv_x ).
    w( |attached id = { aid }| ).
    w( |list count = { lines( o->list( VALUE #( objtype = 'ZDEMO' objkey = 'K1' ) ) ) }| ).
  ENDMETHOD.

  METHOD demo_sys.
    h( `SYS` ).
    DATA(si) = zcl_ab_v1_ut=>sys( )->system_info( ).
    w( |sysid={ si-sysid } client={ si-client } role={ si-client_role } prod={ si-is_production }| ).
    w( |class ZCL_AB_V1_UT exists = { zcl_ab_v1_ut=>sys( )->object_exists( iv_type = 'CLAS' iv_name = 'ZCL_AB_V1_UT' ) }| ).
  ENDMETHOD.

  METHOD demo_cfg.
    h( `CFG` ).
    w( |ZAB_V1_UT_AREA has { lines( zcl_ab_v1_ut=>cfg( )->enum_values( 'ZAB_V1_UT_AREA' ) ) } values| ).
  ENDMETHOD.

  METHOD demo_rap.
    h( `RAP` ).
    w( |new_cid = { zcl_ab_v1_ut=>rap( )->new_cid( ) }| ).
  ENDMETHOD.

  METHOD demo_job.
    h( `JOB` ).
    w( |is_finished(unknown job) = { zcl_ab_v1_ut=>job( )->is_finished( VALUE #( name = 'ZZ_NO_JOB' count = '00000000' ) ) }| ).
  ENDMETHOD.

ENDCLASS.

START-OF-SELECTION.
  DATA(go) = NEW lcl_demo( ).
  IF p_all = abap_true.
    SELECT domvalue_l FROM dd07l
      WHERE domname = 'ZAB_V1_UT_AREA' AND as4local = 'A'
      ORDER BY valpos
      INTO @DATA(lv_val).
      IF lv_val <> 'ALV'.
        go->run( CONV #( lv_val ) ).
      ENDIF.
    ENDSELECT.
  ELSE.
    go->run( p_area ).
  ENDIF.
