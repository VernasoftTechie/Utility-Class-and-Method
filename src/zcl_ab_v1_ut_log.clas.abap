CLASS zcl_ab_v1_ut_log DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ab_v1_ut_log.
  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA mv_handle TYPE balloghndl.
    DATA mt_msgs   TYPE bapiret2_t.

    METHODS add_bal
      IMPORTING is_ret TYPE bapiret2.
ENDCLASS.



CLASS zcl_ab_v1_ut_log IMPLEMENTATION.

  METHOD add_bal.
    CHECK mv_handle IS NOT INITIAL.
    DATA(ls_msg) = VALUE bal_s_msg( msgty = is_ret-type
                                    msgid = is_ret-id
                                    msgno = is_ret-number
                                    msgv1 = is_ret-message_v1
                                    msgv2 = is_ret-message_v2
                                    msgv3 = is_ret-message_v3
                                    msgv4 = is_ret-message_v4 ).
    CALL FUNCTION 'BAL_LOG_MSG_ADD'
      EXPORTING  i_log_handle     = mv_handle
                 i_s_msg          = ls_msg
      EXCEPTIONS OTHERS           = 0.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_log~create.
    DATA(lo) = NEW zcl_ab_v1_ut_log( ).

    " Only touch BAL when the SLG0 object really exists - otherwise keep a
    " memory-only log (messages still collected in mt_msgs).
    SELECT SINGLE object FROM balobj INTO @DATA(lv_obj) WHERE object = @iv_object.
    IF sy-subrc = 0.
      DATA(ls_log) = VALUE bal_s_log( object    = iv_object
                                      subobject = iv_subobject
                                      extnumber = iv_extnumber
                                      aluser    = sy-uname
                                      alprog    = sy-cprog ).
      CALL FUNCTION 'BAL_LOG_CREATE'
        EXPORTING  i_s_log      = ls_log
        IMPORTING  e_log_handle = lo->mv_handle
        EXCEPTIONS OTHERS       = 0.
      IF sy-subrc <> 0.
        CLEAR lo->mv_handle.
      ENDIF.
    ENDIF.

    ro_log = lo.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_log~add_symsg.
    DATA(ls_ret) = VALUE bapiret2( type = sy-msgty id = sy-msgid number = sy-msgno
                                   message_v1 = sy-msgv1 message_v2 = sy-msgv2
                                   message_v3 = sy-msgv3 message_v4 = sy-msgv4 ).
    MESSAGE ID sy-msgid TYPE 'I' NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO ls_ret-message.
    APPEND ls_ret TO mt_msgs.
    add_bal( ls_ret ).
    ro_log = me.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_log~add_t100.
    DATA lv_text TYPE string.
    MESSAGE ID iv_msgid TYPE 'I' NUMBER iv_msgno
            WITH iv_v1 iv_v2 iv_v3 iv_v4 INTO lv_text.
    DATA(ls_ret) = VALUE bapiret2( type = iv_type id = iv_msgid number = iv_msgno
                                   message    = lv_text
                                   message_v1 = iv_v1 message_v2 = iv_v2
                                   message_v3 = iv_v3 message_v4 = iv_v4 ).
    APPEND ls_ret TO mt_msgs.
    add_bal( ls_ret ).
    ro_log = me.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_log~add_bapiret.
    LOOP AT it_return INTO DATA(ls).
      APPEND ls TO mt_msgs.
      add_bal( ls ).
    ENDLOOP.
    ro_log = me.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_log~add_exception.
    DATA(lo) = io_exception.
    WHILE lo IS BOUND.
      DATA(lv_text) = lo->get_text( ).
      DATA(ls_ret) = VALUE bapiret2( type = iv_type id = 'ZAB_V1_UT' number = '001'
                                     message = lv_text message_v1 = lv_text ).
      APPEND ls_ret TO mt_msgs.
      add_bal( ls_ret ).
      lo = lo->previous.
    ENDWHILE.
    ro_log = me.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_log~save.
    zcl_ab_v1_ut_phase=>assert_defer_allowed( 'save' ).

    CHECK mv_handle IS NOT INITIAL.

    DATA(lt_handles) = VALUE bal_t_logh( ( mv_handle ) ).

    IF iv_commit = abap_true.
      " independent save + commit on a secondary DB connection - no COMMIT WORK here
      CALL FUNCTION 'BAL_DB_SAVE'
        EXPORTING  i_t_log_handle       = lt_handles
                   i_2th_connection     = abap_true
                   i_2th_connect_commit = abap_true
        EXCEPTIONS OTHERS               = 4.
    ELSE.
      " save into the caller's LUW; caller / RAP runtime commits
      CALL FUNCTION 'BAL_DB_SAVE'
        EXPORTING  i_t_log_handle = lt_handles
        EXCEPTIONS OTHERS         = 4.
    ENDIF.

    IF sy-subrc <> 0.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '009' iv_msgv1 = |BAL_DB_SAVE rc={ sy-subrc }| ) ##NO_TEXT.
    ENDIF.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_log~display.
    CHECK mv_handle IS NOT INITIAL.
    DATA(lt_handles) = VALUE bal_t_logh( ( mv_handle ) ).
    CALL FUNCTION 'BAL_DSP_LOG_DISPLAY'
      EXPORTING  i_t_log_handle = lt_handles
      EXCEPTIONS OTHERS         = 0.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_log~handle.
    rv = mv_handle.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_log~to_bapiret.
    rt = mt_msgs.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_log~to_string.
    DATA(lv_sep) = iv_sep.
    IF lv_sep IS INITIAL.
      lv_sep = cl_abap_char_utilities=>newline.
    ENDIF.

    DATA lt_lines TYPE string_table.
    LOOP AT mt_msgs INTO DATA(ls).
      DATA(lv) = ls-message.
      IF lv IS INITIAL.
        MESSAGE ID ls-id TYPE 'I' NUMBER ls-number
                WITH ls-message_v1 ls-message_v2 ls-message_v3 ls-message_v4 INTO lv.
      ENDIF.
      APPEND |{ ls-type }: { lv }| TO lt_lines.
    ENDLOOP.
    rv = concat_lines_of( table = lt_lines sep = lv_sep ).
  ENDMETHOD.

ENDCLASS.
