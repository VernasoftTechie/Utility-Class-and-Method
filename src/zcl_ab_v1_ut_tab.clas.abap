CLASS zcl_ab_v1_ut_tab DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ab_v1_ut_tab.
  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES tt_dref TYPE STANDARD TABLE OF REF TO data WITH EMPTY KEY.

    METHODS key_of
      IMPORTING is_row    TYPE any
                it_fields TYPE zif_ab_v1_ut_types=>ty_string_tab
      RETURNING VALUE(rv) TYPE string.
ENDCLASS.



CLASS zcl_ab_v1_ut_tab IMPLEMENTATION.

  METHOD key_of.
    LOOP AT it_fields INTO DATA(lv_f).
      ASSIGN COMPONENT to_upper( lv_f ) OF STRUCTURE is_row TO FIELD-SYMBOL(<v>).
      IF sy-subrc = 0.
        rv = |{ rv }{ <v> }#|.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_tab~create_dynamic.
    DATA lo_line TYPE REF TO cl_abap_datadescr.

    TRY.
        IF io_type IS BOUND.
          lo_line = io_type.
        ELSEIF iv_structure IS NOT INITIAL.
          lo_line ?= cl_abap_typedescr=>describe_by_name( to_upper( iv_structure ) ).
        ELSEIF it_fields IS NOT INITIAL.
          DATA lt_comp TYPE cl_abap_structdescr=>component_table.
          LOOP AT it_fields INTO DATA(ls_f).
            INSERT VALUE #( name = to_upper( ls_f-name )
                            type = CAST cl_abap_datadescr(
                                     cl_abap_typedescr=>describe_by_name( to_upper( ls_f-value ) ) ) )
                   INTO TABLE lt_comp.
          ENDLOOP.
          lo_line = cl_abap_structdescr=>create( lt_comp ).
        ELSE.
          zcx_ab_v1_ut=>raise_t100( iv_msgno = '001' iv_msgv1 = 'create_dynamic' iv_msgv2 = 'no type given' ).
        ENDIF.

        DATA(lo_tab) = cl_abap_tabledescr=>create( p_line_type = lo_line ).
        CREATE DATA rr_table TYPE HANDLE lo_tab.

      CATCH cx_root INTO DATA(lx).
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '019' iv_msgv1 = 'type' iv_msgv2 = iv_structure io_previous = lx ).
    ENDTRY.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_tab~map_corresponding.
    LOOP AT it_source ASSIGNING FIELD-SYMBOL(<src>).
      APPEND INITIAL LINE TO ct_target ASSIGNING FIELD-SYMBOL(<tgt>).
      LOOP AT it_mapping INTO DATA(ls_m).
        ASSIGN COMPONENT to_upper( ls_m-name ) OF STRUCTURE <src> TO FIELD-SYMBOL(<sf>).
        CHECK sy-subrc = 0.
        ASSIGN COMPONENT to_upper( ls_m-value ) OF STRUCTURE <tgt> TO FIELD-SYMBOL(<tf>).
        CHECK sy-subrc = 0.
        TRY.
            <tf> = <sf>.
          CATCH cx_sy_conversion_error.
            " incompatible field - leave target initial
        ENDTRY.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_tab~aggregate.
    FIELD-SYMBOLS <res> TYPE any.

    LOOP AT it_data ASSIGNING FIELD-SYMBOL(<row>).
      DATA(lv_key) = key_of( is_row = <row> it_fields = it_group_by ).

      " locate / create the result row for this group
      DATA(lv_found) = abap_false.
      LOOP AT et_result ASSIGNING <res>.
        IF key_of( is_row = <res> it_fields = it_group_by ) = lv_key.
          lv_found = abap_true.
          EXIT.
        ENDIF.
      ENDLOOP.
      IF lv_found = abap_false.
        APPEND INITIAL LINE TO et_result ASSIGNING <res>.
        LOOP AT it_group_by INTO DATA(lv_g).
          ASSIGN COMPONENT to_upper( lv_g ) OF STRUCTURE <row> TO FIELD-SYMBOL(<gs>).
          CHECK sy-subrc = 0.
          ASSIGN COMPONENT to_upper( lv_g ) OF STRUCTURE <res> TO FIELD-SYMBOL(<gt>).
          CHECK sy-subrc = 0.
          <gt> = <gs>.
        ENDLOOP.
      ENDIF.

      LOOP AT it_measures INTO DATA(ls_meas).
        ASSIGN COMPONENT to_upper( ls_meas-name ) OF STRUCTURE <res> TO FIELD-SYMBOL(<mv>).
        CHECK sy-subrc = 0.
        ASSIGN COMPONENT to_upper( ls_meas-name ) OF STRUCTURE <row> TO FIELD-SYMBOL(<sv>).
        CASE to_upper( ls_meas-value ).
          WHEN 'SUM'.
            IF sy-subrc = 0.
              <mv> = <mv> + <sv>.
            ENDIF.
          WHEN 'COUNT'.
            <mv> = <mv> + 1.
          WHEN 'MIN'.
            IF sy-subrc = 0 AND ( <mv> IS INITIAL OR <sv> < <mv> ).
              <mv> = <sv>.
            ENDIF.
          WHEN 'MAX'.
            IF sy-subrc = 0 AND <sv> > <mv>.
              <mv> = <sv>.
            ENDIF.
        ENDCASE.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_tab~sort_dynamic.
    DATA lt_sort TYPE abap_sortorder_tab.
    LOOP AT it_order_by INTO DATA(ls_o).
      APPEND VALUE #( name       = to_upper( ls_o-name )
                      descending = xsdbool( to_upper( ls_o-value ) = 'DESC' ) ) TO lt_sort.
    ENDLOOP.
    IF lt_sort IS NOT INITIAL.
      SORT ct_data BY (lt_sort).
    ENDIF.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_tab~distinct.
    IF it_fields IS INITIAL.
      SORT ct_data.
      DELETE ADJACENT DUPLICATES FROM ct_data COMPARING ALL FIELDS.
    ELSE.
      DATA lt_sort TYPE abap_sortorder_tab.
      LOOP AT it_fields INTO DATA(lv_f).
        APPEND VALUE #( name = to_upper( lv_f ) ) TO lt_sort.
      ENDLOOP.
      SORT ct_data BY (lt_sort).
      DELETE ADJACENT DUPLICATES FROM ct_data COMPARING (it_fields).
    ENDIF.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_tab~diff.
    DATA: lt_okeys TYPE STANDARD TABLE OF string,
          lt_nkeys TYPE STANDARD TABLE OF string.

    LOOP AT it_old ASSIGNING FIELD-SYMBOL(<o>).
      APPEND key_of( is_row = <o> it_fields = it_key_fields ) TO lt_okeys.
    ENDLOOP.
    LOOP AT it_new ASSIGNING FIELD-SYMBOL(<n>).
      APPEND key_of( is_row = <n> it_fields = it_key_fields ) TO lt_nkeys.
    ENDLOOP.

    LOOP AT it_new ASSIGNING <n>.
      DATA(lv_ni) = sy-tabix.
      DATA(lv_k)  = lt_nkeys[ lv_ni ].
      READ TABLE lt_okeys WITH KEY table_line = lv_k TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        APPEND <n> TO et_insert.
      ELSE.
        READ TABLE it_old INDEX sy-tabix ASSIGNING <o>.
        IF sy-subrc = 0 AND <o> <> <n>.
          APPEND <n> TO et_update.
        ENDIF.
      ENDIF.
    ENDLOOP.

    LOOP AT it_old ASSIGNING <o>.
      DATA(lv_k2) = lt_okeys[ sy-tabix ].
      READ TABLE lt_nkeys WITH KEY table_line = lv_k2 TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        APPEND <o> TO et_delete.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_tab~to_ranges.
    LOOP AT it_values ASSIGNING FIELD-SYMBOL(<v>).
      APPEND INITIAL LINE TO et_range ASSIGNING FIELD-SYMBOL(<r>).
      ASSIGN COMPONENT 'SIGN'   OF STRUCTURE <r> TO FIELD-SYMBOL(<s>).
      IF sy-subrc = 0.
        <s> = iv_sign.
      ENDIF.
      ASSIGN COMPONENT 'OPTION' OF STRUCTURE <r> TO FIELD-SYMBOL(<opt>).
      IF sy-subrc = 0.
        <opt> = iv_option.
      ENDIF.
      ASSIGN COMPONENT 'LOW'    OF STRUCTURE <r> TO FIELD-SYMBOL(<low>).
      IF sy-subrc = 0.
        <low> = <v>.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_tab~chunk.
    DATA lr_result TYPE REF TO data.
    CREATE DATA lr_result TYPE tt_dref.
    ASSIGN lr_result->* TO FIELD-SYMBOL(<result>).

    DATA(lo_line) = CAST cl_abap_tabledescr(
                      cl_abap_typedescr=>describe_by_data( it_data ) )->get_table_line_type( ).
    DATA(lo_tab)  = cl_abap_tabledescr=>create( p_line_type = lo_line ).

    DATA lr_chunk TYPE REF TO data.
    FIELD-SYMBOLS <chunk> TYPE STANDARD TABLE.

    LOOP AT it_data ASSIGNING FIELD-SYMBOL(<row>).
      IF lr_chunk IS NOT BOUND OR lines( <chunk> ) >= iv_size.
        CREATE DATA lr_chunk TYPE HANDLE lo_tab.
        ASSIGN lr_chunk->* TO <chunk>.
        INSERT lr_chunk INTO TABLE <result>.
      ENDIF.
      INSERT <row> INTO TABLE <chunk>.
    ENDLOOP.

    rr_chunks = lr_result.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_tab~fingerprint.
    DATA lv_xml TYPE xstring.
    CALL TRANSFORMATION id SOURCE data = is_data RESULT XML lv_xml.
    cl_abap_message_digest=>calculate_hash_for_raw(
      EXPORTING if_algorithm  = 'SHA256'
                if_data       = lv_xml
      IMPORTING ef_hashstring = DATA(lv_hash) ).
    rv = to_lower( lv_hash ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_tab~deep_equal.
    ASSIGN ir_a->* TO FIELD-SYMBOL(<a>).
    ASSIGN ir_b->* TO FIELD-SYMBOL(<b>).
    IF <a> IS NOT ASSIGNED OR <b> IS NOT ASSIGNED.
      rv = abap_false.
      RETURN.
    ENDIF.

    IF cl_abap_typedescr=>describe_by_data( <a> )->absolute_name
     <> cl_abap_typedescr=>describe_by_data( <b> )->absolute_name.
      rv = abap_false.
      RETURN.
    ENDIF.

    rv = xsdbool( <a> = <b> ).
  ENDMETHOD.

ENDCLASS.
