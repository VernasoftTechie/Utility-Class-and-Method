*"* use this source file for your ABAP unit test classes

CLASS ltc_file DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_row,
             id   TYPE string,
             name TYPE string,
           END OF ty_row,
           tt_row TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.

    DATA mo TYPE REF TO zif_ab_v1_ut_file.

    METHODS setup.
    METHODS mime            FOR TESTING.
    METHODS zip_roundtrip   FOR TESTING RAISING zcx_ab_v1_ut.
    METHODS csv_roundtrip   FOR TESTING RAISING zcx_ab_v1_ut.
ENDCLASS.


CLASS ltc_file IMPLEMENTATION.

  METHOD setup.
    mo = NEW zcl_ab_v1_ut_file( ).
  ENDMETHOD.

  METHOD mime.
    cl_abap_unit_assert=>assert_equals( exp = 'application/pdf' act = mo->mime_type( 'report.pdf' ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      act = mo->mime_type( 'Data.XLSX' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'application/octet-stream' act = mo->mime_type( 'noext' ) ).
  ENDMETHOD.

  METHOD zip_roundtrip.
    DATA: lv_x1 TYPE xstring VALUE '48656C6C6F',
          lv_x2 TYPE xstring VALUE '576F726C64'.
    DATA(lv_c1) = cl_web_http_utility=>encode_x_base64( lv_x1 ).
    DATA(lv_c2) = cl_web_http_utility=>encode_x_base64( lv_x2 ).
    DATA(lv_zip) = mo->zip( VALUE #( ( name = 'a.txt' value = lv_c1 )
                                     ( name = 'b.txt' value = lv_c2 ) ) ).
    cl_abap_unit_assert=>assert_not_initial( lv_zip ).

    DATA(lt_back) = mo->unzip( lv_zip ).
    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( lt_back ) ).
    cl_abap_unit_assert=>assert_equals( exp = lv_c1 act = lt_back[ name = 'a.txt' ]-value ).
  ENDMETHOD.

  METHOD csv_roundtrip.
    DATA(lt) = VALUE tt_row( ( id = '1' name = 'Ann' ) ( id = '2' name = 'Bob' ) ).
    DATA(lv_csv) = mo->csv_build( it_table = lt iv_sep = ';' ).

    DATA lt_back TYPE tt_row.
    mo->csv_parse( EXPORTING iv_content = lv_csv iv_sep = ';' iv_header = abap_true
                   IMPORTING et_table   = lt_back ).
    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( lt_back ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'Ann' act = lt_back[ 1 ]-name ).
    cl_abap_unit_assert=>assert_equals( exp = '2'   act = lt_back[ 2 ]-id ).
  ENDMETHOD.

ENDCLASS.
