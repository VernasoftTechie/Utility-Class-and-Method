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

    METHODS xesc
      IMPORTING iv        TYPE string
      RETURNING VALUE(rv) TYPE string.

    METHODS write_grid
      IMPORTING it_data        TYPE ANY TABLE
                iv_header_only TYPE abap_bool DEFAULT abap_false
                it_col_texts   TYPE zif_ab_v1_ut_types=>ty_nv_tab OPTIONAL
      RETURNING VALUE(rv)      TYPE xstring
      RAISING   zcx_ab_v1_ut.
ENDCLASS.



CLASS zcl_ab_v1_ut_excel IMPLEMENTATION.

  METHOD col_letter.
    DATA(lv_n) = iv_col.
    WHILE lv_n > 0.
      DATA(lv_rem) = ( lv_n - 1 ) MOD 26.
      rv   = |{ sy-abcde+lv_rem(1) }{ rv }|.
      lv_n = ( lv_n - 1 ) DIV 26.
    ENDWHILE.
  ENDMETHOD.


  METHOD xesc.
    rv = iv.
    rv = replace( val = rv sub = '&' with = '&amp;'  occ = 0 ).
    rv = replace( val = rv sub = '<' with = '&lt;'   occ = 0 ).
    rv = replace( val = rv sub = '>' with = '&gt;'   occ = 0 ).
    rv = replace( val = rv sub = '"' with = '&quot;' occ = 0 ).
  ENDMETHOD.


  METHOD write_grid.
    DATA(lo_line) = CAST cl_abap_structdescr(
                      CAST cl_abap_tabledescr(
                        cl_abap_typedescr=>describe_by_data( it_data ) )->get_table_line_type( ) ).

    " ---- build worksheet rows (inline strings) --------------------------------
    DATA lv_rows TYPE string.

    DATA(lv_col) = 1.
    DATA lv_cells TYPE string.
    LOOP AT lo_line->components INTO DATA(ls_c).
      DATA(lv_text) = CONV string( ls_c-name ).
      READ TABLE it_col_texts INTO DATA(ls_t) WITH KEY name = CONV #( ls_c-name ).
      IF sy-subrc = 0.
        lv_text = ls_t-value.
      ENDIF.
      lv_cells = lv_cells &&
        |<c r="{ col_letter( lv_col ) }1" t="inlineStr"><is><t>{ xesc( lv_text ) }</t></is></c>|.
      lv_col = lv_col + 1.
    ENDLOOP.
    lv_rows = |<row r="1">{ lv_cells }</row>|.

    IF iv_header_only = abap_false.
      DATA(lv_r) = 2.
      LOOP AT it_data ASSIGNING FIELD-SYMBOL(<row>).
        CLEAR lv_cells.
        lv_col = 1.
        LOOP AT lo_line->components INTO ls_c.
          ASSIGN COMPONENT ls_c-name OF STRUCTURE <row> TO FIELD-SYMBOL(<f>).
          lv_cells = lv_cells &&
            |<c r="{ col_letter( lv_col ) }{ lv_r }" t="inlineStr"><is><t>{ xesc( |{ <f> }| ) }</t></is></c>|.
          lv_col = lv_col + 1.
        ENDLOOP.
        lv_rows = lv_rows && |<row r="{ lv_r }">{ lv_cells }</row>|.
        lv_r = lv_r + 1.
      ENDLOOP.
    ENDIF.

    DATA(lv_sheet) =
      |<?xml version="1.0" encoding="UTF-8" standalone="yes"?>| &&
      |<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">| &&
      |<sheetData>{ lv_rows }</sheetData></worksheet>|.

    DATA(lv_ct) =
      |<?xml version="1.0" encoding="UTF-8" standalone="yes"?>| &&
      |<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">| &&
      |<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>| &&
      |<Default Extension="xml" ContentType="application/xml"/>| &&
      |<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>| &&
      |<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>| &&
      |</Types>|.

    DATA(lv_rels) =
      |<?xml version="1.0" encoding="UTF-8" standalone="yes"?>| &&
      |<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">| &&
      |<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>| &&
      |</Relationships>|.

    DATA(lv_wb) =
      |<?xml version="1.0" encoding="UTF-8" standalone="yes"?>| &&
      |<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" | &&
      |xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">| &&
      |<sheets><sheet name="Sheet1" sheetId="1" r:id="rId1"/></sheets></workbook>|.

    DATA(lv_wbrels) =
      |<?xml version="1.0" encoding="UTF-8" standalone="yes"?>| &&
      |<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">| &&
      |<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>| &&
      |</Relationships>|.

    TRY.
        DATA(lo_zip) = NEW cl_abap_zip( ).
        lo_zip->add( name = `[Content_Types].xml`        content = cl_abap_codepage=>convert_to( lv_ct ) ).
        lo_zip->add( name = `_rels/.rels`                content = cl_abap_codepage=>convert_to( lv_rels ) ).
        lo_zip->add( name = `xl/workbook.xml`            content = cl_abap_codepage=>convert_to( lv_wb ) ).
        lo_zip->add( name = `xl/_rels/workbook.xml.rels` content = cl_abap_codepage=>convert_to( lv_wbrels ) ).
        lo_zip->add( name = `xl/worksheets/sheet1.xml`   content = cl_abap_codepage=>convert_to( lv_sheet ) ).
        rv = lo_zip->save( ).
      CATCH cx_root INTO DATA(lx).
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '003' iv_msgv1 = lx->get_text( ) io_previous = lx ) ##NO_TEXT.
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
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '019' iv_msgv1 = 'structure' iv_msgv2 = iv_structure io_previous = lx ) ##NO_TEXT.
    ENDTRY.

    ASSIGN lr_tab->* TO FIELD-SYMBOL(<tab>).
    rv_xlsx = write_grid( it_data = <tab> iv_header_only = abap_true it_col_texts = it_column_texts ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_excel~read.
    TRY.
        DATA(lo_xl) = NEW cl_fdt_xl_spreadsheet( document_name = 'upload.xlsx'
                                                 xdocument     = iv_xlsx ).
        lo_xl->if_fdt_doc_spreadsheet~get_worksheet_names( IMPORTING worksheet_names = DATA(lt_ws) ).
        IF lt_ws IS INITIAL.
          zcx_ab_v1_ut=>raise_t100( iv_msgno = '003' iv_msgv1 = 'no worksheet' ) ##NO_TEXT.
        ENDIF.

        DATA lv_ws TYPE string.
        IF iv_sheet IS NOT INITIAL.
          lv_ws = iv_sheet.
        ELSE.
          lv_ws = lt_ws[ 1 ].
        ENDIF.
        DATA(lo_src) = lo_xl->if_fdt_doc_spreadsheet~get_itab_from_worksheet( lv_ws ).

      CATCH cx_root INTO DATA(lx).
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '003' iv_msgv1 = lx->get_text( ) io_previous = lx ) ##NO_TEXT.
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
        DATA lv_tgt TYPE string.
        READ TABLE it_mapping INTO DATA(ls_map) WITH KEY name = CONV #( ls_sc-name ).
        IF sy-subrc = 0.
          lv_tgt = ls_map-value.
        ELSE.
          lv_tgt = ls_sc-name.
        ENDIF.

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
            APPEND VALUE #( row = lv_row_no column = CONV #( ls_sc-name ) reason = 'conversion error' ) TO et_errors ##NO_TEXT.
        ENDTRY.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
