*"* use this source file for your ABAP unit test classes

CLASS ltc_db DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo TYPE REF TO zif_ab_v1_ut_db.
    METHODS setup.
    METHODS exists_true   FOR TESTING RAISING zcx_ab_v1_ut.
    METHODS exists_false  FOR TESTING RAISING zcx_ab_v1_ut.
    METHODS describe_tab  FOR TESTING RAISING zcx_ab_v1_ut.
    METHODS bad_entity    FOR TESTING.
    METHODS where_helper  FOR TESTING.
ENDCLASS.


CLASS ltc_db IMPLEMENTATION.

  METHOD setup.
    mo = NEW zcl_ab_v1_ut_db( ).
  ENDMETHOD.

  METHOD exists_true.
    cl_abap_unit_assert=>assert_true(
      mo->exists( iv_entity = 'T000'
                  it_keys   = VALUE #( ( name = 'MANDT' value = sy-mandt ) ) ) ).
  ENDMETHOD.

  METHOD exists_false.
    cl_abap_unit_assert=>assert_false(
      mo->exists( iv_entity = 'T000'
                  it_keys   = VALUE #( ( name = 'MANDT' value = 'ZZ9' ) ) ) ).
  ENDMETHOD.

  METHOD describe_tab.
    DATA(lr) = mo->describe( 'T000' ).
    ASSIGN lr->* TO FIELD-SYMBOL(<t>).
    cl_abap_unit_assert=>assert_true( xsdbool( lines( <t> ) > 0 ) ).
  ENDMETHOD.

  METHOD bad_entity.
    TRY.
        mo->exists( iv_entity = 'ZZ_NOT_A_TABLE_XYZ' it_keys = VALUE #( ) ).
        cl_abap_unit_assert=>fail( 'expected exception' ).
      CATCH zcx_ab_v1_ut.
    ENDTRY.
  ENDMETHOD.

  METHOD where_helper.
    DATA(lt) = mo->where_from_ranges( VALUE #( ( name = 'bukrs' value = '1000' )
                                               ( name = 'gjahr' value = '2026' ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( lt ) ).
    cl_abap_unit_assert=>assert_equals( exp = |BUKRS = '1000'| act = lt[ 1 ] ).
  ENDMETHOD.

ENDCLASS.
