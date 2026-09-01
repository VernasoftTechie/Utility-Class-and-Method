CLASS zcl_ab_v1_ut_json DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ab_v1_ut_json.
  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS describe_node
      IMPORTING io_descr  TYPE REF TO cl_abap_typedescr
      RETURNING VALUE(rv) TYPE string.
ENDCLASS.



CLASS zcl_ab_v1_ut_json IMPLEMENTATION.

  METHOD zif_ab_v1_ut_json~serialize.
    rv_json = /ui2/cl_json=>serialize(
                data        = iv_data
                compress    = xsdbool( iv_keep_initial = abap_false )
                pretty_name = COND #( WHEN iv_camel_case = abap_true
                                      THEN /ui2/cl_json=>pretty_mode-camel_case
                                      ELSE /ui2/cl_json=>pretty_mode-none ) ).
    IF iv_pretty = abap_true.
      rv_json = zif_ab_v1_ut_json~pretty( rv_json ).
    ENDIF.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_json~deserialize.
    /ui2/cl_json=>deserialize(
      EXPORTING json        = iv_json
                pretty_name = COND #( WHEN iv_camel_case = abap_true
                                      THEN /ui2/cl_json=>pretty_mode-camel_case
                                      ELSE /ui2/cl_json=>pretty_mode-none )
      CHANGING  data        = ca_data ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_json~pretty.
    CONSTANTS c_step TYPE i VALUE 2.
    DATA: lv_indent TYPE i,
          lv_in_str TYPE abap_bool,
          lv_esc    TYPE abap_bool,
          lv_out    TYPE string.

    DATA(lv_len) = strlen( iv_json ).
    DATA(lv_i)   = 0.

    WHILE lv_i < lv_len.
      DATA(lv_c) = iv_json+lv_i(1).

      IF lv_in_str = abap_true.
        lv_out = lv_out && lv_c.
        IF lv_esc = abap_true.
          lv_esc = abap_false.
        ELSEIF lv_c = '\'.
          lv_esc = abap_true.
        ELSEIF lv_c = '"'.
          lv_in_str = abap_false.
        ENDIF.
      ELSE.
        CASE lv_c.
          WHEN '"'.
            lv_in_str = abap_true.
            lv_out = lv_out && lv_c.
          WHEN '{' OR '['.
            lv_indent = lv_indent + c_step.
            lv_out = lv_out && lv_c && cl_abap_char_utilities=>newline && repeat( val = ` ` occ = lv_indent ).
          WHEN '}' OR ']'.
            lv_indent = nmax( val1 = lv_indent - c_step val2 = 0 ).
            lv_out = lv_out && cl_abap_char_utilities=>newline && repeat( val = ` ` occ = lv_indent ) && lv_c.
          WHEN ','.
            lv_out = lv_out && lv_c && cl_abap_char_utilities=>newline && repeat( val = ` ` occ = lv_indent ).
          WHEN ':'.
            lv_out = lv_out && lv_c && ` `.
          WHEN ` ` OR cl_abap_char_utilities=>horizontal_tab OR cl_abap_char_utilities=>newline.
            " drop existing formatting whitespace outside strings
          WHEN OTHERS.
            lv_out = lv_out && lv_c.
        ENDCASE.
      ENDIF.

      lv_i = lv_i + 1.
    ENDWHILE.

    rv = lv_out.
  ENDMETHOD.


  METHOD describe_node.
    CASE io_descr->kind.
      WHEN cl_abap_typedescr=>kind_struct.
        DATA(lo_s) = CAST cl_abap_structdescr( io_descr ).
        DATA lt_parts TYPE string_table.
        LOOP AT lo_s->components INTO DATA(ls_c).
          APPEND |"{ to_lower( ls_c-name ) }": { describe_node( lo_s->get_component_type( ls_c-name ) ) }|
                 TO lt_parts.
        ENDLOOP.
        rv = |\{ { concat_lines_of( table = lt_parts sep = `, ` ) } \}|.

      WHEN cl_abap_typedescr=>kind_table.
        DATA(lo_t) = CAST cl_abap_tabledescr( io_descr ).
        rv = |\{ "kind": "table", "line": { describe_node( lo_t->get_table_line_type( ) ) } \}|.

      WHEN cl_abap_typedescr=>kind_ref.
        rv = `{ "kind": "ref" }`.

      WHEN OTHERS.
        DATA(lo_e) = CAST cl_abap_elemdescr( io_descr ).
        rv = |\{ "kind": "elementary", "typeKind": "{ lo_e->type_kind }", | &&
             |"length": { lo_e->length }, "decimals": { lo_e->decimals } \}|.
    ENDCASE.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_json~describe.
    DATA lo TYPE REF TO cl_abap_typedescr.
    IF io_type IS BOUND.
      lo = io_type.
    ELSE.
      lo = cl_abap_typedescr=>describe_by_data( iv_data ).
    ENDIF.
    rv_schema = describe_node( lo ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_json~xml_serialize.
    TRY.
        CALL TRANSFORMATION id
             SOURCE data = iv_data
             RESULT XML rv.
      CATCH cx_transformation_error INTO DATA(lx).
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '005' iv_msgv1 = lx->get_text( ) io_previous = lx ).
    ENDTRY.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_json~xml_deserialize.
    TRY.
        CALL TRANSFORMATION id
             SOURCE XML iv_xml
             RESULT data = ca_data.
      CATCH cx_transformation_error INTO DATA(lx).
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '005' iv_msgv1 = lx->get_text( ) io_previous = lx ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
