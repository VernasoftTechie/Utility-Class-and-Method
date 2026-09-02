*&---------------------------------------------------------------------*
*& Report ZAB_V1_UT_DEMO_INT
*&---------------------------------------------------------------------*
*& Working demo of the v1.1.0 implementation toolkit areas of ZCL_AB_V1_UT:
*& HTTP / BULK / BAPI / CUTOVER / TRANSPORT. No SAP GUI control classes -
*& safe to run in the background. Side-effecting calls are gated by p_side.
*&---------------------------------------------------------------------*
REPORT zab_v1_ut_demo_int.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-b01.
PARAMETERS: p_area TYPE zab_v1_ut_area AS LISTBOX VISIBLE LENGTH 30 OBLIGATORY,
            p_all  AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-b02.
PARAMETERS: p_url  TYPE string LOWER CASE,
            p_pkg  TYPE devclass DEFAULT 'ZABAP_UTIL',
            p_trk  TYPE trkorr,
            p_par  AS CHECKBOX,
            p_side AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK b2.


CLASS lcl_cut_exec DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES zif_ab_v1_ut_cutover_exec.
ENDCLASS.

CLASS lcl_cut_exec IMPLEMENTATION.
  METHOD zif_ab_v1_ut_cutover_exec~run_task.
    IF iv_name CS 'FAIL'.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '032' iv_msgv1 = iv_name ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_demo DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS area_values RETURNING VALUE(rt) TYPE vrm_values.
    METHODS run IMPORTING iv_area TYPE zab_v1_ut_area.
  PRIVATE SECTION.
    METHODS w IMPORTING iv TYPE string.
    METHODS h IMPORTING iv TYPE string.
    METHODS demo_http      RAISING zcx_ab_v1_ut.
    METHODS demo_bulk      RAISING zcx_ab_v1_ut.
    METHODS demo_bapi      RAISING zcx_ab_v1_ut.
    METHODS demo_cutover   RAISING zcx_ab_v1_ut.
    METHODS demo_transport RAISING zcx_ab_v1_ut.
ENDCLASS.


CLASS lcl_demo IMPLEMENTATION.

  METHOD area_values.
    DATA(lt) = VALUE string_table( ( `HTTP` ) ( `BULK` ) ( `BAPI` ) ( `CUTOVER` ) ( `TRANSPORT` ) ).
    LOOP AT lt INTO DATA(lv).
      APPEND VALUE #( key = lv text = lv ) TO rt.
    ENDLOOP.
  ENDMETHOD.

  METHOD w.
    DATA(lv) = iv.
    WRITE / lv.
  ENDMETHOD.

  METHOD h.
    DATA(lv) = |=== { iv } ===|.
    SKIP.
    WRITE / lv.
    ULINE.
  ENDMETHOD.

  METHOD run.
    TRY.
        CASE iv_area.
          WHEN 'HTTP'.      demo_http( ).
          WHEN 'BULK'.      demo_bulk( ).
          WHEN 'BAPI'.      demo_bapi( ).
          WHEN 'CUTOVER'.   demo_cutover( ).
          WHEN 'TRANSPORT'. demo_transport( ).
          WHEN OTHERS.      w( |(no demo for area { iv_area })| ) ##NO_TEXT.
        ENDCASE.
      CATCH cx_root INTO DATA(lx).
        w( |ERROR: { lx->get_text( ) }| ) ##NO_TEXT.
    ENDTRY.
  ENDMETHOD.


  METHOD demo_http.
    h( `HTTP` ).
    DATA(lo) = zcl_ab_v1_ut=>http( ).

    lo->for_url( `https://example.com/api`
       )->with_header( iv_name = `Accept` iv_value = `application/json`
       )->with_retry( iv_max = 3 iv_backoff_ms = 500
       )->with_cache( iv_ttl_seconds = 60 ).
    w( `for_url + with_header + with_retry + with_cache -> configured` ) ##NO_TEXT.

    lo->set_auth_basic( iv_user = `u` iv_password = `p` ).
    lo->set_auth_bearer( iv_token = `tok` ).
    lo->set_oauth2_client_credentials( iv_token_url = `https://id/token`
                                       iv_client_id = `c` iv_client_secret = `s` ).
    w( `set_auth_basic / set_auth_bearer / set_oauth2_client_credentials -> configured` ) ##NO_TEXT.

    DATA(lv_filter) = lo->odata_filter( VALUE #( ( name = `Country` value = `eq:DE` )
                                                ( name = `Active`  value = `true` ) ) ).
    w( |odata_filter -> { lv_filter }| ) ##NO_TEXT.

    DATA(lt_q) = lo->odata_query( iv_filter = lv_filter iv_select = `Id,Name` iv_top = 20 ).
    LOOP AT lt_q INTO DATA(ls_q).
      w( |odata_query -> { ls_q-name }={ ls_q-value }| ) ##NO_TEXT.
    ENDLOOP.

    DATA(lv_env) = lo->soap_envelope( iv_body_xml = `<web:Ping/>` ).
    w( |soap_envelope -> { lv_env }| ) ##NO_TEXT.

    IF p_url IS NOT INITIAL.
      DATA(ls_resp) = zcl_ab_v1_ut=>http( )->for_url( p_url )->request(
                        iv_method = zif_ab_v1_ut_http=>c_method-get ).
      w( |request GET { p_url } -> HTTP { ls_resp-code } { ls_resp-reason }, { strlen( ls_resp-body ) } char(s)| ) ##NO_TEXT.
    ELSE.
      w( `request / get_json / post_json / paginate / download_binary / upload_multipart -> set p_url to exercise live` ) ##NO_TEXT.
    ENDIF.
  ENDMETHOD.


  METHOD demo_bulk.
    h( `BULK` ).

    DATA lt_keys TYPE STANDARD TABLE OF xubname.
    lt_keys = VALUE #( FOR i = 1 WHILE i <= 25 ( CONV xubname( |KEY{ i }| ) ) ).
    DATA lr TYPE REF TO data.
    GET REFERENCE OF lt_keys INTO lr.

    DATA(lo_h) = NEW zcl_ab_v1_ut_demo_bulk_h( ).

    DATA(ls_r) = zcl_ab_v1_ut=>bulk( )->run_packaged( ir_keys        = lr
                                                      iv_pkg_size    = 10
                                                      io_handler     = lo_h
                                                      iv_commit_each = abap_false ).
    w( |run_packaged -> { ls_r-status }, processed { ls_r-processed }/{ ls_r-total }, { lines( ls_r-messages ) } msg(s)| ) ##NO_TEXT.

    zcl_ab_v1_ut=>bulk( )->progress( iv_done = 25 iv_total = 25 iv_text = `demo` ).
    w( `progress -> indicator set` ) ##NO_TEXT.

    DATA(lo_store) = NEW zcl_ab_v1_ut_bulk_store_mem( ).
    lo_store->zif_ab_v1_ut_bulk_store~save( iv_run_id = `DEMO1` iv_checkpoint = `10` iv_processed = 10 ).
    DATA(ls_r2) = zcl_ab_v1_ut=>bulk( )->resume( iv_run_id      = `DEMO1`
                                                 ir_keys        = lr
                                                 io_store       = lo_store
                                                 io_handler     = lo_h
                                                 iv_pkg_size    = 10
                                                 iv_commit_each = abap_false ).
    w( |resume -> { ls_r2-status }, processed { ls_r2-processed }/{ ls_r2-total }| ) ##NO_TEXT.

    IF p_par = abap_true.
      DATA(ls_r3) = zcl_ab_v1_ut=>bulk( )->run_parallel( ir_keys          = lr
                                                         iv_pkg_size      = 10
                                                         iv_handler_class = CONV #( `ZCL_AB_V1_UT_DEMO_BULK_H` )
                                                         iv_max_tasks     = 2 ).
      w( |run_parallel -> { ls_r3-status }, processed { ls_r3-processed }, errors { ls_r3-errors }| ) ##NO_TEXT.
    ELSE.
      w( `run_parallel -> tick p_par to dispatch across work processes` ) ##NO_TEXT.
    ENDIF.
  ENDMETHOD.


  METHOD demo_bapi.
    h( `BAPI` ).
    DATA(lo_b) = zcl_ab_v1_ut=>bapi( ).

    DATA ls_info TYPE rfcsi.
    lo_b->call_by_name( EXPORTING iv_bapi   = CONV #( `RFC_SYSTEM_INFO` )
                        IMPORTING es_export = ls_info ).
    w( |call_by_name RFC_SYSTEM_INFO -> dest { ls_info-rfcdest }, sysid { ls_info-rfcsysid }| ) ##NO_TEXT.

    DATA lv_user TYPE xubname VALUE 'DDIC'.
    DATA lr_u TYPE REF TO data.
    GET REFERENCE OF lv_user INTO lr_u.
    DATA lr_ret TYPE REF TO data.
    CREATE DATA lr_ret TYPE bapiret2_t.
    DATA lt_pt TYPE abap_func_parmbind_tab.
    INSERT VALUE #( name = 'USERNAME' kind = abap_func_exporting value = lr_u ) INTO TABLE lt_pt.
    INSERT VALUE #( name = 'RETURN'   kind = abap_func_tables    value = lr_ret ) INTO TABLE lt_pt.
    DATA(lt_r) = lo_b->call( iv_bapi = CONV #( `BAPI_USER_EXISTENCE_CHECK` ) it_params = lt_pt ).
    w( |call BAPI_USER_EXISTENCE_CHECK(DDIC) -> { lines( lt_r ) } return line(s)| ) ##NO_TEXT.

    DATA lt_bdc TYPE STANDARD TABLE OF bdcdata.
    lo_b->bdc_dynpro( EXPORTING iv_program = `SAPMV45A` iv_dynpro = `0100` CHANGING ct_bdcdata = lt_bdc ).
    lo_b->bdc_field(  EXPORTING iv_name = `BDC_OKCODE` iv_value = `/00` CHANGING ct_bdcdata = lt_bdc ).
    w( |bdc_dynpro + bdc_field -> { lines( lt_bdc ) } BDCDATA row(s)| ) ##NO_TEXT.

    IF p_side = abap_true.
      TYPES: BEGIN OF ty_imp, username TYPE xubname, END OF ty_imp.
      DATA lt_imp TYPE STANDARD TABLE OF ty_imp.
      lt_imp = VALUE #( ( username = 'DDIC' ) ( username = 'SAP*' ) ).
      DATA lt_calls TYPE zif_ab_v1_ut_bapi=>ty_call_tab.
      LOOP AT lt_imp ASSIGNING FIELD-SYMBOL(<imp>).
        APPEND INITIAL LINE TO lt_calls ASSIGNING FIELD-SYMBOL(<c>).
        GET REFERENCE OF <imp> INTO <c>-import_ref.
      ENDLOOP.
      DATA(ls_m) = lo_b->mass( iv_bapi     = CONV #( `BAPI_USER_EXISTENCE_CHECK` )
                               it_calls    = lt_calls
                               iv_test_run = abap_true ).
      w( |mass -> total { ls_m-total }, committed { ls_m-committed }, failed { ls_m-failed }| ) ##NO_TEXT.
      lo_b->rollback( ).
      w( `rollback -> ok` ) ##NO_TEXT.
    ELSE.
      w( `mass / commit / rollback / bdc_run -> tick p_side` ) ##NO_TEXT.
    ENDIF.
  ENDMETHOD.


  METHOD demo_cutover.
    h( `CUTOVER` ).
    DATA(lo_c) = zcl_ab_v1_ut=>cutover( ).

    DATA(lt_f) = lo_c->readiness_check( iv_hours = 24 ).
    LOOP AT lt_f INTO DATA(ls_f).
      w( |readiness [{ ls_f-severity }] { ls_f-category }: { ls_f-text }| ) ##NO_TEXT.
    ENDLOOP.

    DATA(lo_exec) = NEW lcl_cut_exec( ).
    DATA(lt_ts) = lo_c->task_run( it_task_names = VALUE #( ( `PRECHECK` ) ( `MIGRATE` ) ( `POSTCHECK` ) )
                                  io_executor   = lo_exec ).
    LOOP AT lt_ts INTO DATA(ls_ts).
      w( |task { ls_ts-name } -> { ls_ts-status } ({ ls_ts-seconds } s)| ) ##NO_TEXT.
    ENDLOOP.

    DATA(lt_j) = lo_c->suspend_jobs( iv_report_only = abap_true ).
    w( |suspend_jobs (report-only) -> { lines( lt_j ) } released job(s)| ) ##NO_TEXT.

    IF p_side = abap_true.
      TRY.
          DATA(lt_locked) = lo_c->lock_users( it_except = VALUE #( ( CONV string( sy-uname ) ) ) ).
          w( |lock_users -> { lines( lt_locked ) } user(s) locked| ) ##NO_TEXT.
          lo_c->unlock_users( ).
          w( `unlock_users -> reversed` ) ##NO_TEXT.
        CATCH zcx_ab_v1_ut INTO DATA(lx1).
          w( |lock/unlock -> { lx1->get_text( ) }| ) ##NO_TEXT.
      ENDTRY.
      TRY.
          lo_c->suspend_jobs( iv_report_only = abap_false ).
        CATCH zcx_ab_v1_ut INTO DATA(lx2).
          w( |suspend_jobs (live) -> { lx2->get_text( ) }| ) ##NO_TEXT.
      ENDTRY.
      TRY.
          lo_c->release_jobs( ).
        CATCH zcx_ab_v1_ut INTO DATA(lx3).
          w( |release_jobs -> { lx3->get_text( ) }| ) ##NO_TEXT.
      ENDTRY.
    ELSE.
      w( `lock_users / unlock_users / live suspend_jobs / release_jobs -> tick p_side` ) ##NO_TEXT.
    ENDIF.
  ENDMETHOD.


  METHOD demo_transport.
    h( `TRANSPORT` ).
    DATA(lo_t) = zcl_ab_v1_ut=>transport( ).

    DATA lv_pkg TYPE devclass.
    lv_pkg = p_pkg.
    IF lv_pkg IS INITIAL.
      lv_pkg = 'ZABAP_UTIL'.
    ENDIF.

    TRY.
        lo_t->custom_code_inventory( EXPORTING iv_package = lv_pkg
                                     IMPORTING et_by_type = DATA(lt_bt)
                                               et_objects = DATA(lt_ob) ).
        w( |custom_code_inventory({ lv_pkg }) -> { lines( lt_ob ) } object(s)| ) ##NO_TEXT.
        LOOP AT lt_bt INTO DATA(ls_bt).
          w( |  { ls_bt-object } : { ls_bt-count }| ) ##NO_TEXT.
        ENDLOOP.
      CATCH zcx_ab_v1_ut INTO DATA(lxp).
        w( |custom_code_inventory -> { lxp->get_text( ) }| ) ##NO_TEXT.
    ENDTRY.

    DATA(lt_wu) = lo_t->where_used( iv_type = `TY` iv_name = `ZCL_AB_V1_UT` ).
    w( |where_used(ZCL_AB_V1_UT) -> { lines( lt_wu ) } using include(s)| ) ##NO_TEXT.

    DATA(lt_lock) = lo_t->locking_requests( iv_pgmid    = 'R3TR'
                                            iv_object   = 'CLAS'
                                            iv_obj_name = `ZCL_AB_V1_UT` ).
    w( |locking_requests(ZCL_AB_V1_UT) -> { lines( lt_lock ) } request(s)| ) ##NO_TEXT.

    IF p_trk IS NOT INITIAL.
      TRY.
          DATA(lt_or) = lo_t->objects_in_request( iv_trkorr = p_trk ).
          w( |objects_in_request({ p_trk }) -> { lines( lt_or ) } object(s)| ) ##NO_TEXT.
        CATCH zcx_ab_v1_ut INTO DATA(lxt).
          w( |objects_in_request -> { lxt->get_text( ) }| ) ##NO_TEXT.
      ENDTRY.
    ELSE.
      w( `objects_in_request -> supply p_trk to exercise` ) ##NO_TEXT.
    ENDIF.
  ENDMETHOD.

ENDCLASS.


DATA go_demo TYPE REF TO lcl_demo.

INITIALIZATION.
  go_demo = NEW lcl_demo( ).

AT SELECTION-SCREEN OUTPUT.
  DATA lt_vrm TYPE vrm_values.
  lt_vrm = lcl_demo=>area_values( ).
  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING id     = 'P_AREA'
              values = lt_vrm.

START-OF-SELECTION.
  IF p_all = abap_true.
    go_demo->run( CONV #( 'HTTP' ) ).
    go_demo->run( CONV #( 'BULK' ) ).
    go_demo->run( CONV #( 'BAPI' ) ).
    go_demo->run( CONV #( 'CUTOVER' ) ).
    go_demo->run( CONV #( 'TRANSPORT' ) ).
  ELSE.
    go_demo->run( p_area ).
  ENDIF.
