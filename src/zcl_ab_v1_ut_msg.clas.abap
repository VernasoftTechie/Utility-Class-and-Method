CLASS zcl_ab_v1_ut_msg DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ab_v1_ut_msg.
  PROTECTED SECTION.
  PRIVATE SECTION.
    CLASS-METHODS severity_rank
      IMPORTING iv_type        TYPE symsgty
      RETURNING VALUE(rv_rank) TYPE i.
ENDCLASS.



CLASS zcl_ab_v1_ut_msg IMPLEMENTATION.

  METHOD severity_rank.
    rv_rank = SWITCH i( iv_type
                        WHEN 'A' THEN 4
                        WHEN 'X' THEN 4
                        WHEN 'E' THEN 3
                        WHEN 'W' THEN 2
                        WHEN 'I' THEN 1
                        WHEN 'S' THEN 1
                        ELSE 0 ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_msg~t100_to_text.
    MESSAGE ID iv_msgid TYPE 'I' NUMBER iv_msgno
            WITH iv_v1 iv_v2 iv_v3 iv_v4
            INTO rv.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_msg~t100_to_bapiret.
    DATA lv_text TYPE string.
    MESSAGE ID iv_msgid TYPE 'I' NUMBER iv_msgno
            WITH iv_v1 iv_v2 iv_v3 iv_v4
            INTO lv_text.

    rs = VALUE bapiret2(
           type       = iv_type
           id         = iv_msgid
           number     = iv_msgno
           message    = lv_text
           message_v1 = iv_v1
           message_v2 = iv_v2
           message_v3 = iv_v3
           message_v4 = iv_v4 ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_msg~symsg_to_bapiret.
    rs = zif_ab_v1_ut_msg~t100_to_bapiret(
           iv_msgid = sy-msgid
           iv_msgno = sy-msgno
           iv_type  = sy-msgty
           iv_v1    = sy-msgv1
           iv_v2    = sy-msgv2
           iv_v3    = sy-msgv3
           iv_v4    = sy-msgv4 ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_msg~exception_to_text.
    DATA(lo_cx) = io_exception.
    DATA lt_parts TYPE string_table.

    WHILE lo_cx IS BOUND.
      DATA(lv_part) = COND string( WHEN iv_long = abap_true
                                   THEN lo_cx->get_longtext( )
                                   ELSE lo_cx->get_text( ) ).
      APPEND lv_part TO lt_parts.
      IF iv_with_chain = abap_false.
        EXIT.
      ENDIF.
      lo_cx = lo_cx->previous.
    ENDWHILE.

    rv = concat_lines_of( table = lt_parts sep = cl_abap_char_utilities=>newline ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_msg~bapiret_has_error.
    rv = xsdbool( line_exists( it_return[ type = 'E' ] )
              OR  line_exists( it_return[ type = 'A' ] )
              OR  line_exists( it_return[ type = 'X' ] ) ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_msg~bapiret_max_severity.
    DATA(lv_rank) = 0.
    LOOP AT it_return INTO DATA(ls).
      DATA(lv_r) = severity_rank( ls-type ).
      IF lv_r > lv_rank.
        lv_rank = lv_r.
        rv      = ls-type.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_msg~bapiret_filter.
    LOOP AT it_return INTO DATA(ls).
      IF iv_types CS ls-type.
        APPEND ls TO rt.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_msg~raise.
    RAISE EXCEPTION TYPE zcx_ab_v1_ut
      EXPORTING
        textid   = VALUE scx_t100key( msgid = iv_msgid
                                      msgno = iv_msgno
                                      attr1 = 'MV1'
                                      attr2 = 'MV2'
                                      attr3 = 'MV3'
                                      attr4 = 'MV4' )
        previous = io_previous
        mv1      = |{ iv_v1 }|
        mv2      = |{ iv_v2 }|
        mv3      = |{ iv_v3 }|
        mv4      = |{ iv_v4 }|.
  ENDMETHOD.

ENDCLASS.
