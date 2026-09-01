CLASS zcl_ab_v1_ut_mail DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ab_v1_ut_mail.
  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS esc
      IMPORTING iv_in     TYPE string
      RETURNING VALUE(rv) TYPE string.
ENDCLASS.



CLASS zcl_ab_v1_ut_mail IMPLEMENTATION.

  METHOD esc.
    rv = iv_in.
    rv = replace( val = rv sub = '&' with = '&amp;'  occ = 0 ).
    rv = replace( val = rv sub = '<' with = '&lt;'   occ = 0 ).
    rv = replace( val = rv sub = '>' with = '&gt;'   occ = 0 ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_mail~build_html_body.
    DATA lt TYPE string_table.
    APPEND |<html><head><meta charset="utf-8"><title>{ esc( iv_title ) }</title></head><body>| TO lt.
    APPEND |<h2>{ esc( iv_title ) }</h2>| TO lt.

    LOOP AT it_paragraphs INTO DATA(lv_p).
      APPEND |<p>{ esc( lv_p ) }</p>| TO lt.
    ENDLOOP.

    IF it_table IS SUPPLIED.
      DATA(lo_line) = CAST cl_abap_structdescr(
                        CAST cl_abap_tabledescr(
                          cl_abap_typedescr=>describe_by_data( it_table ) )->get_table_line_type( ) ).
      APPEND `<table border="1" cellpadding="4" cellspacing="0"><thead><tr>` TO lt.
      LOOP AT lo_line->components INTO DATA(ls_c).
        APPEND |<th>{ esc( CONV #( ls_c-name ) ) }</th>| TO lt.
      ENDLOOP.
      APPEND `</tr></thead><tbody>` TO lt.

      LOOP AT it_table ASSIGNING FIELD-SYMBOL(<row>).
        APPEND `<tr>` TO lt.
        LOOP AT lo_line->components INTO ls_c.
          ASSIGN COMPONENT ls_c-name OF STRUCTURE <row> TO FIELD-SYMBOL(<f>).
          APPEND |<td>{ esc( |{ <f> }| ) }</td>| TO lt.
        ENDLOOP.
        APPEND `</tr>` TO lt.
      ENDLOOP.
      APPEND `</tbody></table>` TO lt.
    ENDIF.

    APPEND `</body></html>` TO lt.
    rv_html = concat_lines_of( table = lt ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_mail~send.
    zcl_ab_v1_ut_phase=>assert_defer_allowed( 'send' ).

    IF is_mail-recipients IS INITIAL.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '006' iv_msgv1 = 'no recipients' ).
    ENDIF.

    TRY.
        DATA(lo_send) = cl_bcs=>create_persistent( ).

        DATA(lv_html) = COND string( WHEN is_mail-body_html IS NOT INITIAL
                                     THEN is_mail-body_html
                                     ELSE |<html><body><pre>{ is_mail-body_text }</pre></body></html>| ).

        DATA(lo_doc) = cl_document_bcs=>create_document(
          i_type    = 'HTM'
          i_text    = cl_bcs_convert=>string_to_soli( lv_html )
          i_subject = CONV so_obj_des( is_mail-subject ) ).

        LOOP AT is_mail-attachments INTO DATA(ls_att).
          DATA(lv_ext) = to_upper( substring_after( val = ls_att-filename sub = '.' occ = -1 ) ).
          lo_doc->add_attachment(
            i_attachment_type    = CONV soodk-objtp( lv_ext )
            i_attachment_subject = CONV sood-objdes( ls_att-filename )
            i_att_content_hex    = cl_bcs_convert=>xstring_to_solix( ls_att-content ) ).
        ENDLOOP.

        lo_send->set_document( lo_doc ).

        IF is_mail-sender IS NOT INITIAL.
          lo_send->set_sender( cl_cam_address_bcs=>create_internet_address( CONV adr6-smtp_addr( is_mail-sender ) ) ).
        ENDIF.

        LOOP AT is_mail-recipients INTO DATA(lv_to).
          lo_send->add_recipient( i_recipient = cl_cam_address_bcs=>create_internet_address( CONV adr6-smtp_addr( lv_to ) ) ).
        ENDLOOP.
        LOOP AT is_mail-cc INTO DATA(lv_cc).
          lo_send->add_recipient( i_recipient = cl_cam_address_bcs=>create_internet_address( CONV adr6-smtp_addr( lv_cc ) )
                                  i_copy      = abap_true ).
        ENDLOOP.
        LOOP AT is_mail-bcc INTO DATA(lv_bcc).
          lo_send->add_recipient( i_recipient  = cl_cam_address_bcs=>create_internet_address( CONV adr6-smtp_addr( lv_bcc ) )
                                  i_blind_copy = abap_true ).
        ENDLOOP.

        IF is_mail-send_immediately = abap_true.
          lo_send->set_send_immediately( abap_true ).
        ENDIF.

        DATA(lv_ok) = lo_send->send( i_with_error_screen = abap_false ).
        IF lv_ok = abap_false.
          zcx_ab_v1_ut=>raise_t100( iv_msgno = '006' iv_msgv1 = 'BCS send returned false' ).
        ENDIF.

        rv_send_request_id = |BCS-{ sy-datum }-{ sy-uzeit }|.

      CATCH cx_bcs INTO DATA(lx).
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '006' iv_msgv1 = lx->get_text( ) io_previous = lx ).
    ENDTRY.

    " sanctioned COMMIT: only when the caller explicitly asks (classic/report use);
    " RAP callers leave commit_work unset and let the LUW / saver commit.
    IF is_mail-commit_work = abap_true.
      COMMIT WORK.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
