"! <p class="shorttext synchronized">ZCL_AB_V1_UT: BAPI / BDC mass executor</p>
"! RAP-mode: call / call_by_name / mass / commit / rollback / bdc_run are DEFER;
"! bdc_dynpro / bdc_field are Core builders.
"! See docs/08_implementation_toolkit.md and docs/00_engineering_log.md.
CLASS zcl_ab_v1_ut_bapi DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ab_v1_ut_bapi.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_param,
        parameter TYPE fupararef-parameter,
        paramtype TYPE fupararef-paramtype,
      END OF ty_param,
      ty_param_tab TYPE STANDARD TABLE OF ty_param WITH EMPTY KEY,
      ty_hold_tab  TYPE STANDARD TABLE OF REF TO data WITH EMPTY KEY.

    "! Raise 028 unless the function module exists.
    METHODS ensure_exists
      IMPORTING iv_bapi TYPE tfdir-funcname
      RAISING   zcx_ab_v1_ut.

    "! Active FM interface from FUPARAREF (name + kind only - no FM-signature guessing).
    METHODS interface_of
      IMPORTING iv_bapi         TYPE tfdir-funcname
      RETURNING VALUE(rt_param) TYPE ty_param_tab
      RAISING   zcx_ab_v1_ut.

    "! Build a parmbind table: EXPORTING/CHANGING from ir_import components + test flag,
    "! TABLES from ir_tables components, plus an auto-bound RETURN receiver.
    METHODS build_parmbind
      IMPORTING it_param    TYPE ty_param_tab
                ir_import   TYPE REF TO data OPTIONAL
                ir_tables   TYPE REF TO data OPTIONAL
                iv_test_run TYPE abap_bool DEFAULT abap_false
      EXPORTING et_ptab     TYPE abap_func_parmbind_tab
                et_hold     TYPE ty_hold_tab.

    "! RETURN param (table or structure) from a parmbind table -> bapiret2_t.
    METHODS harvest_return
      IMPORTING it_ptab         TYPE abap_func_parmbind_tab
      RETURNING VALUE(rt_return) TYPE bapiret2_t.

    METHODS has_error
      IMPORTING it_ret        TYPE bapiret2_t
      RETURNING VALUE(rv_err) TYPE abap_bool.

    "! Field-wise copy of any RETURN-style line into a bapiret2 line (dynamic, house style).
    METHODS copy_ret_line
      IMPORTING is_any TYPE any
      CHANGING  cs_b2  TYPE bapiret2.

    "! Dynamic CALL FUNCTION with a parmbind table + OTHERS catch-all.
    METHODS raw_call
      IMPORTING iv_bapi TYPE tfdir-funcname
      CHANGING  ct_ptab TYPE abap_func_parmbind_tab
      RAISING   zcx_ab_v1_ut.

    METHODS is_test_param
      IMPORTING iv_name       TYPE csequence
      RETURNING VALUE(rv_yes) TYPE abap_bool.
ENDCLASS.



CLASS zcl_ab_v1_ut_bapi IMPLEMENTATION.

  METHOD zif_ab_v1_ut_bapi~call.
    ensure_exists( iv_bapi ).
    DATA(lt_ptab) = it_params.
    raw_call( EXPORTING iv_bapi = iv_bapi CHANGING ct_ptab = lt_ptab ).
    rt_return = harvest_return( lt_ptab ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_bapi~call_by_name.
    ensure_exists( iv_bapi ).
    DATA(lt_param) = interface_of( iv_bapi ).

    DATA lr_import TYPE REF TO data.
    IF is_import IS SUPPLIED.
      GET REFERENCE OF is_import INTO lr_import.
    ENDIF.

    DATA lt_ptab TYPE abap_func_parmbind_tab.
    DATA lt_hold TYPE ty_hold_tab.
    build_parmbind( EXPORTING it_param    = lt_param
                              ir_import   = lr_import
                              iv_test_run = iv_test_run
                    IMPORTING et_ptab     = lt_ptab
                              et_hold     = lt_hold ).

    " explicit TABLES binds from it_tables ( name -> REF TO table )
    LOOP AT it_tables INTO DATA(ls_nv).
      IF ls_nv-ref IS NOT BOUND.
        CONTINUE.
      ENDIF.
      DATA(lv_tname) = CONV abap_parmname( to_upper( ls_nv-name ) ).
      READ TABLE lt_param TRANSPORTING NO FIELDS
        WITH KEY parameter = lv_tname paramtype = 'T'.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      DELETE lt_ptab WHERE name = lv_tname.
      INSERT VALUE #( name  = lv_tname
                      kind  = abap_func_tables
                      value = ls_nv-ref ) INTO TABLE lt_ptab.
    ENDLOOP.

    " optional: capture the first FM EXPORTING param into es_export
    DATA lr_exp TYPE REF TO data.
    DATA lv_exp_name TYPE abap_parmname.
    IF es_export IS SUPPLIED.
      LOOP AT lt_param INTO DATA(ls_e) WHERE paramtype = 'E'.
        IF ls_e-parameter = 'RETURN'.
          CONTINUE.
        ENDIF.
        lv_exp_name = ls_e-parameter.
        CREATE DATA lr_exp LIKE es_export.
        INSERT VALUE #( name = lv_exp_name kind = abap_func_importing value = lr_exp )
               INTO TABLE lt_ptab.
        EXIT.
      ENDLOOP.
    ENDIF.

    raw_call( EXPORTING iv_bapi = iv_bapi CHANGING ct_ptab = lt_ptab ).

    rt_return = harvest_return( lt_ptab ).

    IF lr_exp IS BOUND.
      ASSIGN lr_exp->* TO FIELD-SYMBOL(<ev>).
      IF <ev> IS ASSIGNED.
        es_export = <ev>.
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_bapi~mass.
    ensure_exists( iv_bapi ).
    DATA(lt_param) = interface_of( iv_bapi ).

    rs_result-total = lines( it_calls ).

    DATA lv_ok_since_commit TYPE i.

    LOOP AT it_calls INTO DATA(ls_call).
      DATA(lv_idx) = sy-tabix.

      DATA lt_ptab TYPE abap_func_parmbind_tab.
      DATA lt_hold TYPE ty_hold_tab.
      build_parmbind( EXPORTING it_param    = lt_param
                                ir_import   = ls_call-import_ref
                                ir_tables   = ls_call-tables_ref
                                iv_test_run = iv_test_run
                      IMPORTING et_ptab     = lt_ptab
                                et_hold     = lt_hold ).

      DATA lt_ret TYPE bapiret2_t.
      CLEAR lt_ret.
      TRY.
          raw_call( EXPORTING iv_bapi = iv_bapi CHANGING ct_ptab = lt_ptab ).
          lt_ret = harvest_return( lt_ptab ).
        CATCH zcx_ab_v1_ut INTO DATA(lx).
          lt_ret = VALUE #( ( type = 'E' id = 'ZAB_V1_UT' number = '030'
                              message = lx->get_text( ) ) ).
      ENDTRY.

      IF has_error( lt_ret ) = abap_true.
        rs_result-failed = rs_result-failed + 1.
        LOOP AT lt_ret ASSIGNING FIELD-SYMBOL(<r>) WHERE type CA 'EAX'.
          <r>-message_v4 = |{ lv_idx }|.
          APPEND <r> TO rs_result-errors.
        ENDLOOP.

        IF iv_stop_on_error = abap_true.
          IF iv_test_run = abap_false.
            TRY.
                CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
              CATCH cx_root ##NO_HANDLER.
            ENDTRY.
          ENDIF.
          zcx_ab_v1_ut=>raise_t100( iv_msgno = '030'
                                    iv_msgv1 = |{ lv_idx }|
                                    iv_msgv2 = |stopped on error| ) ##NO_TEXT.
        ENDIF.

      ELSEIF iv_test_run = abap_false.
        lv_ok_since_commit = lv_ok_since_commit + 1.
        IF iv_commit_every > 0 AND lv_ok_since_commit >= iv_commit_every.
          TRY.
              CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
                EXPORTING wait = abap_true.
            CATCH cx_root ##NO_HANDLER.
          ENDTRY.
          rs_result-committed = rs_result-committed + lv_ok_since_commit.
          lv_ok_since_commit = 0.
        ENDIF.
      ENDIF.
    ENDLOOP.

    IF iv_test_run = abap_false AND lv_ok_since_commit > 0.
      TRY.
          CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
            EXPORTING wait = abap_true.
        CATCH cx_root ##NO_HANDLER.
      ENDTRY.
      rs_result-committed = rs_result-committed + lv_ok_since_commit.
    ENDIF.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_bapi~commit.
    DATA lv_wait TYPE bapita-wait.
    lv_wait = iv_wait.
    TRY.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING wait = lv_wait.
      CATCH cx_root INTO DATA(lx).
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '030' iv_msgv1 = 'commit'
                                  iv_msgv2 = lx->get_text( ) io_previous = lx ).
    ENDTRY.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_bapi~rollback.
    TRY.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      CATCH cx_root INTO DATA(lx).
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '030' iv_msgv1 = 'rollback'
                                  iv_msgv2 = lx->get_text( ) io_previous = lx ).
    ENDTRY.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_bapi~bdc_run.
    SELECT SINGLE tcode FROM tstc INTO @DATA(lv_t) WHERE tcode = @iv_tcode.
    IF sy-subrc <> 0.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '031' iv_msgv1 = |{ iv_tcode }|
                                iv_msgv2 = |transaction not found| ) ##NO_TEXT.
    ENDIF.

    DATA lt_msg  TYPE STANDARD TABLE OF bdcmsgcoll.
    DATA lv_mode TYPE ctu_params-dismode.
    DATA lv_upd  TYPE ctu_params-updmode.
    lv_mode = iv_mode.
    lv_upd  = iv_update.

    CALL TRANSACTION iv_tcode
         WITH AUTHORITY-CHECK
         USING         it_bdcdata
         MODE          lv_mode
         UPDATE        lv_upd
         MESSAGES INTO lt_msg.

    LOOP AT lt_msg INTO DATA(ls_m).
      DATA ls_ret TYPE bapiret2.
      CLEAR ls_ret.
      ls_ret-type       = ls_m-msgtyp.
      ls_ret-id         = ls_m-msgid.
      ls_ret-number     = ls_m-msgnr.
      ls_ret-message_v1 = ls_m-msgv1.
      ls_ret-message_v2 = ls_m-msgv2.
      ls_ret-message_v3 = ls_m-msgv3.
      ls_ret-message_v4 = ls_m-msgv4.
      IF ls_m-msgid IS NOT INITIAL AND ls_m-msgnr IS NOT INITIAL.
        MESSAGE ID ls_m-msgid TYPE 'I' NUMBER ls_m-msgnr
                WITH ls_m-msgv1 ls_m-msgv2 ls_m-msgv3 ls_m-msgv4
                INTO ls_ret-message.
      ENDIF.
      APPEND ls_ret TO rt_return.
    ENDLOOP.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_bapi~bdc_dynpro.
    FIELD-SYMBOLS <f> TYPE any.
    APPEND INITIAL LINE TO ct_bdcdata ASSIGNING FIELD-SYMBOL(<l>).
    ASSIGN COMPONENT 'PROGRAM'  OF STRUCTURE <l> TO <f>. IF sy-subrc = 0. <f> = iv_program. ENDIF.
    ASSIGN COMPONENT 'DYNPRO'   OF STRUCTURE <l> TO <f>. IF sy-subrc = 0. <f> = iv_dynpro. ENDIF.
    ASSIGN COMPONENT 'DYNBEGIN' OF STRUCTURE <l> TO <f>. IF sy-subrc = 0. <f> = 'X'. ENDIF.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_bapi~bdc_field.
    FIELD-SYMBOLS <f> TYPE any.
    APPEND INITIAL LINE TO ct_bdcdata ASSIGNING FIELD-SYMBOL(<l>).
    ASSIGN COMPONENT 'FNAM' OF STRUCTURE <l> TO <f>. IF sy-subrc = 0. <f> = iv_name. ENDIF.
    ASSIGN COMPONENT 'FVAL' OF STRUCTURE <l> TO <f>. IF sy-subrc = 0. <f> = iv_value. ENDIF.
  ENDMETHOD.


  METHOD ensure_exists.
    SELECT SINGLE funcname FROM tfdir INTO @DATA(lv_f) WHERE funcname = @iv_bapi.
    IF sy-subrc <> 0.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '028' iv_msgv1 = |{ iv_bapi }| ) ##NO_TEXT.
    ENDIF.
  ENDMETHOD.


  METHOD interface_of.
    SELECT parameter, paramtype
      FROM fupararef
      WHERE funcname = @iv_bapi
        AND r3state  = 'A'
      INTO CORRESPONDING FIELDS OF TABLE @rt_param.
    IF sy-subrc <> 0.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '028' iv_msgv1 = |{ iv_bapi }|
                                iv_msgv2 = |no active interface| ) ##NO_TEXT.
    ENDIF.
  ENDMETHOD.


  METHOD build_parmbind.
    CLEAR: et_ptab, et_hold.

    FIELD-SYMBOLS <imp> TYPE any.
    IF ir_import IS BOUND.
      ASSIGN ir_import->* TO <imp>.
    ENDIF.
    FIELD-SYMBOLS <tabs> TYPE any.
    IF ir_tables IS BOUND.
      ASSIGN ir_tables->* TO <tabs>.
    ENDIF.

    LOOP AT it_param INTO DATA(ls_p).
      DATA lr_val TYPE REF TO data.
      CLEAR lr_val.

      CASE ls_p-paramtype.

        WHEN 'I' OR 'C'.
          IF is_test_param( ls_p-parameter ) = abap_true.
            CREATE DATA lr_val TYPE c LENGTH 1.
            ASSIGN lr_val->* TO FIELD-SYMBOL(<tv>).
            IF iv_test_run = abap_true.
              <tv> = 'X'.
            ENDIF.
          ELSEIF <imp> IS ASSIGNED.
            ASSIGN COMPONENT ls_p-parameter OF STRUCTURE <imp> TO FIELD-SYMBOL(<c>).
            IF sy-subrc = 0.
              CREATE DATA lr_val LIKE <c>.
              ASSIGN lr_val->* TO FIELD-SYMBOL(<cv>).
              <cv> = <c>.
            ENDIF.
          ENDIF.

          IF lr_val IS BOUND.
            APPEND lr_val TO et_hold.
            DATA lv_kind TYPE abap_func_parmbind-kind.
            IF ls_p-paramtype = 'C'.
              lv_kind = abap_func_changing.
            ELSE.
              lv_kind = abap_func_exporting.
            ENDIF.
            INSERT VALUE #( name = CONV abap_parmname( ls_p-parameter )
                            kind = lv_kind
                            value = lr_val ) INTO TABLE et_ptab.
          ENDIF.

        WHEN 'T'.
          IF <tabs> IS ASSIGNED.
            ASSIGN COMPONENT ls_p-parameter OF STRUCTURE <tabs> TO FIELD-SYMBOL(<ct>).
            IF sy-subrc = 0.
              GET REFERENCE OF <ct> INTO lr_val.
            ENDIF.
          ENDIF.
          IF lr_val IS BOUND.
            INSERT VALUE #( name = CONV abap_parmname( ls_p-parameter )
                            kind = abap_func_tables
                            value = lr_val ) INTO TABLE et_ptab.
          ENDIF.

        WHEN OTHERS.
          " 'E' captured in call_by_name; 'X' via EXCEPTION-TABLE OTHERS
      ENDCASE.
    ENDLOOP.

    " ensure a RETURN receiver is bound
    READ TABLE et_ptab TRANSPORTING NO FIELDS WITH KEY name = 'RETURN'.
    IF sy-subrc <> 0.
      READ TABLE it_param INTO DATA(ls_ret) WITH KEY parameter = 'RETURN'.
      IF sy-subrc = 0.
        DATA lr_ret TYPE REF TO data.
        IF ls_ret-paramtype = 'T'.
          CREATE DATA lr_ret TYPE bapiret2_t.
          APPEND lr_ret TO et_hold.
          INSERT VALUE #( name = 'RETURN' kind = abap_func_tables value = lr_ret )
                 INTO TABLE et_ptab.
        ELSEIF ls_ret-paramtype = 'E'.
          CREATE DATA lr_ret TYPE bapiret2.
          APPEND lr_ret TO et_hold.
          INSERT VALUE #( name = 'RETURN' kind = abap_func_importing value = lr_ret )
                 INTO TABLE et_ptab.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD raw_call.
    DATA lt_exc TYPE abap_func_excpbind_tab.
    lt_exc = VALUE #( ( name = 'OTHERS' value = 1 ) ).

    TRY.
        CALL FUNCTION iv_bapi
          PARAMETER-TABLE ct_ptab
          EXCEPTION-TABLE lt_exc.
      CATCH cx_root INTO DATA(lx).
        zcx_ab_v1_ut=>raise_t100( iv_msgno    = '029'
                                  iv_msgv1    = |{ iv_bapi }|
                                  iv_msgv2    = lx->get_text( )
                                  io_previous = lx ).
    ENDTRY.

    IF sy-subrc <> 0.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '029'
                                iv_msgv1 = |{ iv_bapi }|
                                iv_msgv2 = |classic exception raised (subrc { sy-subrc })| ) ##NO_TEXT.
    ENDIF.
  ENDMETHOD.


  METHOD harvest_return.
    READ TABLE it_ptab INTO DATA(ls) WITH KEY name = 'RETURN'.
    IF sy-subrc <> 0 OR ls-value IS NOT BOUND.
      RETURN.
    ENDIF.

    FIELD-SYMBOLS <data> TYPE any.
    ASSIGN ls-value->* TO <data>.
    IF <data> IS NOT ASSIGNED.
      RETURN.
    ENDIF.

    DATA(lo_type) = cl_abap_typedescr=>describe_by_data( <data> ).

    IF lo_type->kind = cl_abap_typedescr=>kind_table.
      FIELD-SYMBOLS <tab> TYPE ANY TABLE.
      ASSIGN ls-value->* TO <tab>.
      LOOP AT <tab> ASSIGNING FIELD-SYMBOL(<row>).
        APPEND INITIAL LINE TO rt_return ASSIGNING FIELD-SYMBOL(<b>).
        copy_ret_line( EXPORTING is_any = <row> CHANGING cs_b2 = <b> ).
      ENDLOOP.
    ELSEIF lo_type->kind = cl_abap_typedescr=>kind_struct.
      APPEND INITIAL LINE TO rt_return ASSIGNING FIELD-SYMBOL(<b2>).
      copy_ret_line( EXPORTING is_any = <data> CHANGING cs_b2 = <b2> ).
    ENDIF.
  ENDMETHOD.


  METHOD copy_ret_line.
    DATA lt_f TYPE STANDARD TABLE OF string.
    SPLIT `TYPE ID NUMBER MESSAGE LOG_NO LOG_MSG_NO MESSAGE_V1 MESSAGE_V2 MESSAGE_V3 MESSAGE_V4 PARAMETER ROW FIELD SYSTEM`
      AT ` ` INTO TABLE lt_f.
    LOOP AT lt_f INTO DATA(lv_f).
      ASSIGN COMPONENT lv_f OF STRUCTURE is_any TO FIELD-SYMBOL(<s>).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      ASSIGN COMPONENT lv_f OF STRUCTURE cs_b2 TO FIELD-SYMBOL(<t>).
      IF sy-subrc = 0.
        <t> = <s>.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD has_error.
    IF    line_exists( it_ret[ type = 'E' ] )
       OR line_exists( it_ret[ type = 'A' ] )
       OR line_exists( it_ret[ type = 'X' ] ).
      rv_err = abap_true.
    ENDIF.
  ENDMETHOD.


  METHOD is_test_param.
    CASE to_upper( iv_name ).
      WHEN 'TEST' OR 'TESTRUN' OR 'TEST_RUN' OR 'TESTMODE'
        OR 'SIMULATE' OR 'SIMULATION' OR 'I_TESTRUN' OR 'TESTMODUS'.
        rv_yes = abap_true.
    ENDCASE.
  ENDMETHOD.

ENDCLASS.
