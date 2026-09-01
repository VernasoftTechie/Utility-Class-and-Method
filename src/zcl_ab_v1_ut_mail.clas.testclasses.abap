*"* use this source file for your ABAP unit test classes

CLASS ltc_mail DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_row,
             col1 TYPE string,
             col2 TYPE string,
           END OF ty_row,
           tt_row TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.

    DATA mo TYPE REF TO zif_ab_v1_ut_mail.
    METHODS setup.
    METHODS html_title     FOR TESTING.
    METHODS html_table     FOR TESTING.
    METHODS html_escaped   FOR TESTING.
ENDCLASS.


CLASS ltc_mail IMPLEMENTATION.

  METHOD setup.
    mo = NEW zcl_ab_v1_ut_mail( ).
  ENDMETHOD.

  METHOD html_title.
    DATA(lv) = mo->build_html_body( iv_title = 'Report'
                                    it_paragraphs = VALUE #( ( `line one` ) ( `line two` ) ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv CS '<h2>Report</h2>' ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv CS '<p>line one</p>' ) ).
  ENDMETHOD.

  METHOD html_table.
    DATA(lt) = VALUE tt_row( ( col1 = 'a' col2 = 'b' ) ( col1 = 'c' col2 = 'd' ) ).
    DATA(lv) = mo->build_html_body( iv_title = 'T' it_table = lt ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv CS '<table' ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv CS '<td>a</td>' ) ).
  ENDMETHOD.

  METHOD html_escaped.
    DATA(lv) = mo->build_html_body( iv_title = 'A & B <x>' ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv CS 'A &amp; B &lt;x&gt;' ) ).
  ENDMETHOD.

ENDCLASS.
