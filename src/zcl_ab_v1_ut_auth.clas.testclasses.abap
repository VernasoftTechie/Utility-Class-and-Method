*"* use this source file for your ABAP unit test classes

CLASS ltc_auth DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo TYPE REF TO zif_ab_v1_ut_auth.
    METHODS setup.
    METHODS check_returns_bool FOR TESTING.
    METHODS current_user_valid FOR TESTING.
    METHODS unknown_user_invalid FOR TESTING.
ENDCLASS.


CLASS ltc_auth IMPLEMENTATION.

  METHOD setup.
    mo = NEW zcl_ab_v1_ut_auth( ).
  ENDMETHOD.

  METHOD check_returns_bool.
    " must not dump; result is a boolean either way
    DATA(lv) = mo->check( iv_object = 'S_TCODE'
                          it_values = VALUE #( ( name = 'TCD' value = 'SU3' ) ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv = abap_true OR lv = abap_false ) ).
  ENDMETHOD.

  METHOD current_user_valid.
    cl_abap_unit_assert=>assert_true( mo->is_user_valid( sy-uname ) ).
  ENDMETHOD.

  METHOD unknown_user_invalid.
    cl_abap_unit_assert=>assert_false( mo->is_user_valid( 'ZZ_NO_SUCH_USER' ) ).
  ENDMETHOD.

ENDCLASS.
