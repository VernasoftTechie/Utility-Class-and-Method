CLASS zcl_ab_v1_ut_excel DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ab_v1_ut_excel.
  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS col_letter
      IMPORTING iv_col    TYPE i
      RETURNING VALUE(rv) TYPE string.

    METHODS write_grid
      IMPORTING it_data       TYPE ANY TABLE
                iv_header_only TYPE abap_bool DEFAULT abap_false
                it_col_texts  TYPE zif_ab_v1_ut_types=>ty_nv_tab OPTIONAL
      RETURNING VALUE(rv)     TYPE xstring
      RAISING   zcx_ab_v1_ut.
ENDCLASS.



CLASS zcl_ab_v1_ut_excel IMPLEMENTATION.

  METHOD col_letter.
    DATA(lv_n) = iv_col.
    WHILE lv_n > 0.
      DATA(lv_rem) = ( lv_n - 1 ) MOD 26.
      rv   = |{ to_upper( CONV string( sy-abcde+lv_rem(1) ) ) }{ rv }|.
      lv_n = ( lv_n - 1 ) DIV 26.
    ENDWHILE.
  ENDMETHOD.


  METHOD write_grid.
    DATA(lo_line) = CAST cl_abap_structdescr(
                      CAST cl_abap_tabledescr(
                        cl_abap_typedescr=>describe_by_data( it_data ) )->get_table_line_type( ) ).

    TRY.
        DATA(lo_doc)   = xco_cp_xlsx=>document->empty( ).
        DATA(lo_write) = lo_doc->write_access( ).
        DATA(lo_ws)    = lo_write->get_workbook( )->worksheet->at_position( 1 ).

        " header row
        DATA(lv_col) = 1.
        LOOP AT lo_line->components INTO DATA(ls_c).
          DATA(lv_text) = CONV string( ls_c-name ).
          READ TABLE it_col_texts INTO DATA(ls_t) WITH KEY name = CONV #( ls_c-name ).
          IF sy-subrc = 0.
            lv_text = ls_t-value.
          ENDIF.
          lo_ws->cell( xco_cp_xlsx=>coordinate->for_cell_reference(
                         CONV #( |{ col_letter( lv_col ) }1| ) )
             )->value->write_string( lv_text ).
          lv_col = lv_col + 1.
        ENDLOOP.

        IF iv_header_only = abap_false.
          DATA(lv_row) = 2.
          LOOP AT it_data ASSIGNING FIELD-SYMBOL(<row>).
            lv_col = 1.
            LOOP AT lo_line->components INTO ls_c.
              ASSIGN COMPONENT ls_c-name OF STRUCTURE <row> TO FIELD-SYMBOL(<f>).
              lo_ws->cell( xco_cp_xlsx=>coordinate->for_cell_reference(
                             CONV #( |{ col_letter( lv_col ) }{ lv_row }| ) )
                 )->value->write_string( |{ <f> }| ).
              lv_col = lv_col + 1.
            ENDLOOP.
            lv_row = lv_row + 1.
          ENDLOOP.
        ENDIF.

        rv = lo_doc->get_content( ).

      CATCH cx_root INTO DATA(lx).
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '003' iv_msgv1 = lx->get_text( ) io_previous = lx ).
    ENDTRY.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_excel~write.
    rv_xlsx = write_grid( it_data = it_data ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_excel~generate_template.
    DATA lr_tab TYPE REF TO data.
    TRY.
        DATA(lo_struct) = CAST cl_abap_structdescr(
                            cl_abap_typedescr=>describe_by_name( to_upper( iv_structure ) ) ).
        DATA(lo_tab) = cl_abap_tabledescr=>create( p_line_type = lo_struct ).
        CREATE DATA lr_tab TYPE HANDLE lo_tab.
      CATCH cx_root INTO DATA(lx).
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '019' iv_msgv1 = 'structure' iv_msgv2 = iv_structure io_previous = lx ).
    ENDTRY.

    ASSIGN lr_tab->* TO FIELD-SYMBOL(<tab>).
    rv_xlsx = write_grid( it_data = <tab> iv_header_only = abap_true it_col_texts = it_column_texts ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_excel~read.
    DATA(lo_tgt_line) = CAST cl_abap_structdescr(
                          CAST cl_abap_tabledescr(
                            cl_abap_typedescr=>describe_by_data( et_data ) )->get_table_line_type( ) ).

    TRY.
        DATA(lo_xl) = NEW cl_fdt_xl_spreadsheet( document_name = 'upload.xlsx'
                                                 xdocument     = iv_xlsx ).
        lo_xl->if_fdt_doc_spreadsheet~get_worksheet_names( IMPORTING worksheet_names = DATA(lt_ws) ).
        IF lt_ws IS INITIAL.
          zcx_ab_v1_ut=>raise_t100( iv_msgno = '003' iv_msgv1 = 'no worksheet' ).
        ENDIF.

        DATA(lv_ws) = COND string( WHEN iv_sheet IS NOT INITIAL THEN CONV string( iv_sheet ) ELSE lt_ws[ 1 ] ).
        DATA(lo_src) = lo_xl->if_fdt_doc_spreadsheet~get_itab_from_worksheet( lv_ws ).

      CATCH cx_root INTO DATA(lx).
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '003' iv_msgv1 = lx->get_text( ) io_previous = lx ).
    ENDTRY.

    ASSIGN lo_src->* TO FIELD-SYMBOL(<src>).
    DATA(lo_src_line) = CAST cl_abap_structdescr(
                          CAST cl_abap_tabledescr(
                            cl_abap_typedescr=>describe_by_data( <src> ) )->get_table_line_type( ) ).

    DATA lv_row_no TYPE i.
    LOOP AT <src> ASSIGNING FIELD-SYMBOL(<srow>).
      lv_row_no = sy-tabix.
      IF iv_max_rows > 0 AND lv_row_no > iv_max_rows.
        EXIT.
      ENDIF.

      APPEND INITIAL LINE TO et_data ASSIGNING FIELD-SYMBOL(<trow>).

      LOOP AT lo_src_line->components INTO DATA(ls_sc).
        " resolve target component: explicit mapping wins, else same name
        DATA lv_tgt TYPE string.
        READ TABLE it_mapping INTO DATA(ls_map) WITH KEY name = CONV #( ls_sc-name ).
        lv_tgt = COND #( WHEN sy-subrc = 0 THEN ls_map-value ELSE CONV string( ls_sc-name ) ).

        ASSIGN COMPONENT ls_sc-name OF STRUCTURE <srow> TO FIELD-SYMBOL(<sv>).
        CHECK sy-subrc = 0.
        ASSIGN COMPONENT to_upper( lv_tgt ) OF STRUCTURE <trow> TO FIELD-SYMBOL(<tv>).
        IF sy-subrc <> 0.
          IF NOT line_exists( et_unmapped[ table_line = CONV string( ls_sc-name ) ] ).
            APPEND CONV string( ls_sc-name ) TO et_unmapped.
          ENDIF.
          CONTINUE.
        ENDIF.

        TRY.
            <tv> = <sv>.
          CATCH cx_sy_conversion_error.
            APPEND VALUE #( row = lv_row_no column = CONV #( ls_sc-name ) reason = 'conversion error' ) TO et_errors.
        ENDTRY.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
