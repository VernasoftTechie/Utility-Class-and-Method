CLASS zcl_ab_v1_ut_rap DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ab_v1_ut_rap.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_ab_v1_ut_rap IMPLEMENTATION.

  METHOD zif_ab_v1_ut_rap~new_cid.
    TRY.
        rv = cl_system_uuid=>create_uuid_c22_static( ).
      CATCH cx_uuid_error ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_rap~messages_to_bapiret.
    LOOP AT it_messages INTO DATA(lo_msg).
      CHECK lo_msg IS BOUND.

      DATA(ls_key) = lo_msg->if_t100_message~t100key.
      DATA lv_txt TYPE string.
      MESSAGE ID ls_key-msgid TYPE 'I' NUMBER ls_key-msgno
              WITH lo_msg->if_t100_dyn_msg~msgv1 lo_msg->if_t100_dyn_msg~msgv2
                   lo_msg->if_t100_dyn_msg~msgv3 lo_msg->if_t100_dyn_msg~msgv4
              INTO lv_txt.

      APPEND VALUE bapiret2(
        id         = ls_key-msgid
        number     = ls_key-msgno
        type       = SWITCH symsgty( lo_msg->m_severity
                       WHEN if_abap_behv_message=>severity-error       THEN 'E'
                       WHEN if_abap_behv_message=>severity-warning     THEN 'W'
                       WHEN if_abap_behv_message=>severity-success     THEN 'S'
                       WHEN if_abap_behv_message=>severity-information THEN 'I'
                       ELSE 'I' )
        message    = lv_txt
        message_v1 = lo_msg->if_t100_dyn_msg~msgv1
        message_v2 = lo_msg->if_t100_dyn_msg~msgv2
        message_v3 = lo_msg->if_t100_dyn_msg~msgv3
        message_v4 = lo_msg->if_t100_dyn_msg~msgv4 ) TO rt.
    ENDLOOP.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_rap~bapiret_to_text.
    LOOP AT it_return INTO DATA(ls).
      DATA(lv) = ls-message.
      IF lv IS INITIAL.
        MESSAGE ID ls-id TYPE 'I' NUMBER ls-number
                WITH ls-message_v1 ls-message_v2 ls-message_v3 ls-message_v4 INTO lv.
      ENDIF.
      APPEND |{ ls-type }: { lv }| TO rt.
    ENDLOOP.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_rap~corresponding_control.
    DATA(lo_c) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_data( is_control ) ).

    LOOP AT lo_c->components INTO DATA(ls_comp).
      ASSIGN COMPONENT ls_comp-name OF STRUCTURE is_control TO FIELD-SYMBOL(<ctrl>).
      CHECK sy-subrc = 0 AND <ctrl> IS NOT INITIAL.

      ASSIGN COMPONENT ls_comp-name OF STRUCTURE is_source TO FIELD-SYMBOL(<src>).
      CHECK sy-subrc = 0.
      ASSIGN COMPONENT ls_comp-name OF STRUCTURE cs_target TO FIELD-SYMBOL(<tgt>).
      CHECK sy-subrc = 0.

      TRY.
          <tgt> = <src>.
        CATCH cx_sy_conversion_error.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
