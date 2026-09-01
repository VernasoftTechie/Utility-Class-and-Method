*"* use this source file for your ABAP unit test classes

CLASS ltc_msg DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo TYPE REF TO zif_ab_v1_ut_msg.
    METHODS setup.
    METHODS t100_text        FOR TESTING.
    METHODS bapiret_helpers  FOR TESTING.
    METHODS raise_ok         FOR TESTING.
    METHODS exc_text         FOR TESTING.
ENDCLASS.


CLASS ltc_msg IMPLEMENTATION.

  METHOD setup.
    mo = NEW zcl_ab_v1_ut_msg( ).
  ENDMETHOD.

  METHOD t100_text.
    cl_abap_unit_assert=>assert_equals(
      exp = 'Operation SAVE not allowed in RAP phase 1'
      act = mo->t100_to_text( iv_msgid = 'ZAB_V1_UT' iv_msgno = '013' iv_v1 = 'SAVE' iv_v2 = '1' ) ).
  ENDMETHOD.

  METHOD bapiret_helpers.
    DATA(lt) = VALUE bapiret2_t(
      ( type = 'S' id = 'ZAB_V1_UT' number = '001' )
      ( type = 'W' id = 'ZAB_V1_UT' number = '001' )
      ( type = 'E' id = 'ZAB_V1_UT' number = '002' ) ).

    cl_abap_unit_assert=>assert_true(  mo->bapiret_has_error( lt ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'E' act = mo->bapiret_max_severity( lt ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( mo->bapiret_filter( it_return = lt iv_types = 'E' ) ) ).
    cl_abap_unit_assert=>assert_false( mo->bapiret_has_error(
      VALUE bapiret2_t( ( type = 'S' ) ( type = 'I' ) ) ) ).
  ENDMETHOD.

  METHOD raise_ok.
    TRY.
        mo->raise( iv_msgno = '002' iv_v1 = 'S_DEVELOP' ).
        cl_abap_unit_assert=>fail( 'expected exception' ).
      CATCH zcx_ab_v1_ut INTO DATA(lx).
        cl_abap_unit_assert=>assert_char_cp( exp = '*S_DEVELOP*' act = lx->get_text( ) ).
    ENDTRY.
  ENDMETHOD.

  METHOD exc_text.
    DATA lx TYPE REF TO zcx_ab_v1_ut.
    TRY.
        mo->raise( iv_msgno = '001' iv_v1 = 'boom' ).
      CATCH zcx_ab_v1_ut INTO lx.
    ENDTRY.
    cl_abap_unit_assert=>assert_char_cp(
      exp = '*boom*'
      act = mo->exception_to_text( io_exception = lx ) ).
  ENDMETHOD.

ENDCLASS.
