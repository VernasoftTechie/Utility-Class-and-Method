CLASS zcl_ab_v1_ut_file DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ab_v1_ut_file.
  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS resolve_path
      IMPORTING iv_logical TYPE fileintern
                iv_path    TYPE string
      RETURNING VALUE(rv)  TYPE string
      RAISING   zcx_ab_v1_ut.

    METHODS guard_dataset
      IMPORTING iv_path     TYPE string
                iv_activity TYPE activ_auth
      RAISING   zcx_ab_v1_ut.
ENDCLASS.



CLASS zcl_ab_v1_ut_file IMPLEMENTATION.

  METHOD resolve_path.
    IF iv_logical IS NOT INITIAL.
      rv = zif_ab_v1_ut_file~resolve_logical( iv_logical ).
    ELSE.
      rv = iv_path.
    ENDIF.

    IF rv IS INITIAL OR rv CS '..' OR rv CA cl_abap_char_utilities=>minchar.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '015' iv_msgv1 = rv ).
    ENDIF.
  ENDMETHOD.


  METHOD guard_dataset.
    AUTHORITY-CHECK OBJECT 'S_DATASET'
      ID 'PROGRAM'  FIELD sy-cprog
      ID 'ACTVT'    FIELD iv_activity
      ID 'FILENAME' FIELD iv_path.
    IF sy-subrc <> 0.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '015' iv_msgv1 = iv_path ).
    ENDIF.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_file~resolve_logical.
    DATA: l1 TYPE zif_ab_v1_ut_types=>ty_nv,
          l2 TYPE zif_ab_v1_ut_types=>ty_nv,
          l3 TYPE zif_ab_v1_ut_types=>ty_nv.
    READ TABLE iv_params INTO l1 INDEX 1.
    READ TABLE iv_params INTO l2 INDEX 2.
    READ TABLE iv_params INTO l3 INDEX 3.

    CALL FUNCTION 'FILE_GET_NAME'
      EXPORTING  logical_filename = iv_logical_name
                 parameter_1      = l1-value
                 parameter_2      = l2-value
                 parameter_3      = l3-value
      IMPORTING  file_name        = DATA(lv_name)
      EXCEPTIONS file_not_found   = 1
                 OTHERS           = 2.
    IF sy-subrc <> 0.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '015' iv_msgv1 = |{ iv_logical_name }| ).
    ENDIF.
    rv_path = lv_name.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_file~mime_type.
    DATA(lv_ext) = to_lower( substring_after( val = iv_filename sub = '.' occ = -1 ) ).
    rv = SWITCH string( lv_ext
      WHEN 'pdf'  THEN 'application/pdf'
      WHEN 'xlsx' THEN 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      WHEN 'xls'  THEN 'application/vnd.ms-excel'
      WHEN 'docx' THEN 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
      WHEN 'csv'  THEN 'text/csv'
      WHEN 'txt'  THEN 'text/plain'
      WHEN 'xml'  THEN 'application/xml'
      WHEN 'json' THEN 'application/json'
      WHEN 'zip'  THEN 'application/zip'
      WHEN 'png'  THEN 'image/png'
      WHEN 'jpg' OR 'jpeg' THEN 'image/jpeg'
      WHEN 'gif'  THEN 'image/gif'
      WHEN 'html' OR 'htm' THEN 'text/html'
      ELSE 'application/octet-stream' ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_file~zip.
    DATA(lo_zip) = NEW cl_abap_zip( ).
    LOOP AT it_files INTO DATA(ls).
      lo_zip->add( name    = CONV string( ls-name )
                   content = cl_web_http_utility=>decode_x_base64( ls-value ) ).
    ENDLOOP.
    rv_zip = lo_zip->save( ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_file~unzip.
    DATA(lo_zip) = NEW cl_abap_zip( ).
    lo_zip->load( EXPORTING zip = iv_zip EXCEPTIONS OTHERS = 1 ).
    IF sy-subrc <> 0.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '001' iv_msgv1 = 'unzip failed' ).
    ENDIF.

    LOOP AT lo_zip->files INTO DATA(ls_f).
      lo_zip->get( EXPORTING name = ls_f-name IMPORTING content = DATA(lv_x) EXCEPTIONS OTHERS = 1 ).
      IF sy-subrc = 0.
        APPEND VALUE #( name = ls_f-name value = cl_web_http_utility=>encode_x_base64( lv_x ) ) TO rt_files.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_file~csv_parse.
    DATA lt_lines TYPE string_table.
    SPLIT iv_content AT cl_abap_char_utilities=>newline INTO TABLE lt_lines.
    DELETE lt_lines WHERE table_line IS INITIAL.
    IF lt_lines IS INITIAL.
      RETURN.
    ENDIF.

    DATA lt_cols TYPE string_table.
    IF iv_header = abap_true.
      SPLIT lt_lines[ 1 ] AT iv_sep INTO TABLE lt_cols.
      DELETE lt_lines INDEX 1.
    ENDIF.

    LOOP AT lt_lines INTO DATA(lv_line).
      SPLIT lv_line AT iv_sep INTO TABLE DATA(lt_vals).
      APPEND INITIAL LINE TO et_table ASSIGNING FIELD-SYMBOL(<row>).

      LOOP AT lt_vals INTO DATA(lv_val).
        DATA(lv_idx) = sy-tabix.
        FIELD-SYMBOLS <f> TYPE any.
        IF iv_header = abap_true AND lv_idx <= lines( lt_cols ).
          ASSIGN COMPONENT to_upper( condense( lt_cols[ lv_idx ] ) ) OF STRUCTURE <row> TO <f>.
        ELSE.
          ASSIGN COMPONENT lv_idx OF STRUCTURE <row> TO <f>.
        ENDIF.
        IF sy-subrc = 0.
          TRY.
              <f> = condense( replace( val = lv_val sub = '"' with = `` occ = 0 ) ).
            CATCH cx_sy_conversion_error.
          ENDTRY.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_file~csv_build.
    DATA(lo_line) = CAST cl_abap_structdescr(
                      CAST cl_abap_tabledescr(
                        cl_abap_typedescr=>describe_by_data( it_table ) )->get_table_line_type( ) ).

    DATA lt_out TYPE string_table.

    IF iv_header = abap_true.
      DATA lt_h TYPE string_table.
      LOOP AT lo_line->components INTO DATA(ls_c).
        APPEND to_lower( ls_c-name ) TO lt_h.
      ENDLOOP.
      APPEND concat_lines_of( table = lt_h sep = CONV string( iv_sep ) ) TO lt_out.
    ENDIF.

    LOOP AT it_table ASSIGNING FIELD-SYMBOL(<row>).
      DATA lt_v TYPE string_table.
      CLEAR lt_v.
      LOOP AT lo_line->components INTO ls_c.
        ASSIGN COMPONENT ls_c-name OF STRUCTURE <row> TO FIELD-SYMBOL(<f>).
        APPEND |{ <f> }| TO lt_v.
      ENDLOOP.
      APPEND concat_lines_of( table = lt_v sep = CONV string( iv_sep ) ) TO lt_out.
    ENDLOOP.

    rv = concat_lines_of( table = lt_out sep = cl_abap_char_utilities=>newline ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_file~as_read.
    DATA(lv_path) = resolve_path( iv_logical = iv_logical_name iv_path = iv_path ).
    guard_dataset( iv_path = lv_path iv_activity = '33' ).

    OPEN DATASET lv_path FOR INPUT IN BINARY MODE.
    IF sy-subrc <> 0.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '015' iv_msgv1 = lv_path ).
    ENDIF.

    DATA: lv_chunk TYPE xstring,
          lv_len   TYPE i.
    DO.
      READ DATASET lv_path INTO lv_chunk MAXIMUM LENGTH 65536 ACTUAL LENGTH lv_len.
      DATA(lv_subrc) = sy-subrc.
      IF lv_len > 0.
        CONCATENATE rv_content lv_chunk(lv_len) INTO rv_content IN BYTE MODE.
      ENDIF.
      IF lv_subrc <> 0.
        EXIT.
      ENDIF.
    ENDDO.
    CLOSE DATASET lv_path.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_file~as_write.
    DATA(lv_path) = resolve_path( iv_logical = iv_logical_name iv_path = iv_path ).
    guard_dataset( iv_path = lv_path iv_activity = '34' ).

    IF iv_append = abap_true.
      OPEN DATASET lv_path FOR APPENDING IN BINARY MODE.
    ELSE.
      OPEN DATASET lv_path FOR OUTPUT IN BINARY MODE.
    ENDIF.
    IF sy-subrc <> 0.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '015' iv_msgv1 = lv_path ).
    ENDIF.

    TRANSFER iv_content TO lv_path.
    CLOSE DATASET lv_path.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_file~as_delete.
    guard_dataset( iv_path = iv_path iv_activity = '06' ).
    DELETE DATASET iv_path.
    IF sy-subrc <> 0.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '015' iv_msgv1 = iv_path ).
    ENDIF.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_file~as_exists.
    OPEN DATASET iv_path FOR INPUT IN BINARY MODE.
    IF sy-subrc = 0.
      rv = abap_true.
      CLOSE DATASET iv_path.
    ENDIF.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_file~as_list_dir.
    guard_dataset( iv_path = iv_dir iv_activity = '33' ).

    DATA lt_files TYPE STANDARD TABLE OF salfldir.
    CALL FUNCTION 'RZL_READ_DIR_LOCAL'
      EXPORTING  name           = iv_dir
      TABLES     file_tbl       = lt_files
      EXCEPTIONS argument_error = 1
                 not_found      = 2
                 OTHERS         = 3.
    IF sy-subrc <> 0.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '015' iv_msgv1 = iv_dir ).
    ENDIF.

    rt = VALUE #( FOR ls IN lt_files ( CONV string( ls-name ) ) ).
  ENDMETHOD.

ENDCLASS.
