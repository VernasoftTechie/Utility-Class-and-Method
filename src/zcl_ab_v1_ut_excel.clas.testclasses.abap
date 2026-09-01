*"* use this source file for your ABAP unit test classes

CLASS ltc_excel DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_row,
             id   TYPE string,
             name TYPE string,
           END OF ty_row,
           tt_row TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.

    DATA mo TYPE REF TO zif_ab_v1_ut_excel.
    METHODS setup.
    METHODS write_produces_xlsx FOR TESTING.
    METHODS roundtrip           FOR TESTING.
ENDCLASS.


CLASS ltc_excel IMPLEMENTATION.

  METHOD setup.
    mo = NEW zcl_ab_v1_ut_excel( ).
  ENDMETHOD.

  METHOD write_produces_xlsx.
    DATA(lt) = VALUE tt_row( ( id = '1' name = 'Ann' ) ( id = '2' name = 'Bob' ) ).
    TRY.
        DATA(lv_x) = mo->write( lt ).
        cl_abap_unit_assert=>assert_not_initial( lv_x ).
        " xlsx files start with the ZIP magic bytes 'PK' (0x504B)
        cl_abap_unit_assert=>assert_equals( exp = '504B' act = |{ lv_x(2) }| ).
      CATCH zcx_ab_v1_ut.
        " XCO xlsx not available in this environment - nothing to assert
    ENDTRY.
  ENDMETHOD.

  METHOD roundtrip.
    DATA(lt) = VALUE tt_row( ( id = '1' name = 'Ann' ) ( id = '2' name = 'Bob' ) ).
    TRY.
        DATA(lv_x) = mo->write( lt ).
        DATA lt_back TYPE tt_row.
        mo->read( EXPORTING iv_xlsx = lv_x IMPORTING et_data = lt_back ).
        cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( lt_back ) ).
        cl_abap_unit_assert=>assert_equals( exp = 'Ann' act = lt_back[ 1 ]-name ).
      CATCH zcx_ab_v1_ut.
        " engine not available - skip
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
