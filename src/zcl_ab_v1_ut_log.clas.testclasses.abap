*"* use this source file for your ABAP unit test classes

CLASS ltc_log DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo TYPE REF TO zif_ab_v1_ut_log.
    METHODS setup.
    METHODS collect_msgs   FOR TESTING RAISING zcx_ab_v1_ut.
    METHODS from_exception  FOR TESTING RAISING zcx_ab_v1_ut.
    METHODS as_string       FOR TESTING RAISING zcx_ab_v1_ut.
ENDCLASS.


CLASS ltc_log IMPLEMENTATION.

  METHOD setup.
    mo = NEW zcl_ab_v1_ut_log( ).
  ENDMETHOD.

  METHOD collect_msgs.
    DATA(lo) = mo->create( iv_subobject = 'GENERAL' ).
    lo->add_t100( iv_msgid = 'ZAB_V1_UT' iv_msgno = '001' iv_v1 = 'one' ).
    lo->add_t100( iv_msgid = 'ZAB_V1_UT' iv_msgno = '001' iv_v1 = 'two' ).
    lo->add_bapiret( VALUE #( ( type = 'W' id = 'ZAB_V1_UT' number = '001' message_v1 = 'three' ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = 3 act = lines( lo->to_bapiret( ) ) ).
  ENDMETHOD.

  METHOD from_exception.
    DATA(lo) = mo->create( ).
    TRY.
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '005' iv_msgv1 = 'boom' ).
      CATCH zcx_ab_v1_ut INTO DATA(lx).
        lo->add_exception( lx ).
    ENDTRY.
    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( lo->to_bapiret( ) ) ).
  ENDMETHOD.

  METHOD as_string.
    DATA(lo) = mo->create( ).
    lo->add_t100( iv_msgid = 'ZAB_V1_UT' iv_msgno = '001' iv_v1 = 'hello' ).
    cl_abap_unit_assert=>assert_char_cp( exp = '*hello*' act = lo->to_string( ) ).
  ENDMETHOD.

ENDCLASS.
