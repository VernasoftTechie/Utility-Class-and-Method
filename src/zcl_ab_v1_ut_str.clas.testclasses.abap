*"* use this source file for your ABAP unit test classes

CLASS ltc_str DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo TYPE REF TO zif_ab_v1_ut_str.

    METHODS setup.
    METHODS to_amount_eu       FOR TESTING RAISING zcx_ab_v1_ut.
    METHODS to_amount_us       FOR TESTING RAISING zcx_ab_v1_ut.
    METHODS to_amount_bad      FOR TESTING.
    METHODS amount_roundtrip   FOR TESTING.
    METHODS to_date_formats    FOR TESTING RAISING zcx_ab_v1_ut.
    METHODS to_date_bad        FOR TESTING.
    METHODS alpha              FOR TESTING.
    METHODS snake_camel        FOR TESTING.
    METHODS base64_roundtrip   FOR TESTING RAISING zcx_ab_v1_ut.
    METHODS hash_sha256        FOR TESTING RAISING zcx_ab_v1_ut.
    METHODS regex_grp          FOR TESTING.
    METHODS validators         FOR TESTING.
    METHODS mask_pan           FOR TESTING.
ENDCLASS.


CLASS ltc_str IMPLEMENTATION.

  METHOD setup.
    mo = NEW zcl_ab_v1_ut_str( ).
  ENDMETHOD.

  METHOD to_amount_eu.
    cl_abap_unit_assert=>assert_equals(
      exp = CONV decfloat34( '1234.56' )
      act = mo->to_amount( iv_text = '1.234,56' iv_notation = zif_ab_v1_ut_str=>c_notation-eu ) ).
  ENDMETHOD.

  METHOD to_amount_us.
    cl_abap_unit_assert=>assert_equals(
      exp = CONV decfloat34( '1234.56' )
      act = mo->to_amount( iv_text = '1,234.56' iv_notation = zif_ab_v1_ut_str=>c_notation-us ) ).
  ENDMETHOD.

  METHOD to_amount_bad.
    TRY.
        mo->to_amount( iv_text = 'abc' ).
        cl_abap_unit_assert=>fail( 'expected exception' ).
      CATCH zcx_ab_v1_ut.
    ENDTRY.
  ENDMETHOD.

  METHOD amount_roundtrip.
    DATA(lv_txt) = mo->from_amount( iv_amount   = CONV decfloat34( '1234.50' )
                                    iv_currency = 'EUR'
                                    iv_notation = zif_ab_v1_ut_str=>c_notation-eu ).
    cl_abap_unit_assert=>assert_equals( exp = '1.234,50' act = lv_txt ).
  ENDMETHOD.

  METHOD to_date_formats.
    cl_abap_unit_assert=>assert_equals( exp = CONV d( '20261231' ) act = mo->to_date( '31.12.2026' ) ).
    cl_abap_unit_assert=>assert_equals( exp = CONV d( '20261231' ) act = mo->to_date( '2026-12-31' ) ).
    cl_abap_unit_assert=>assert_equals( exp = CONV d( '20261231' ) act = mo->to_date( '20261231' ) ).
  ENDMETHOD.

  METHOD to_date_bad.
    TRY.
        mo->to_date( '2026-13-45' ).
        cl_abap_unit_assert=>fail( 'expected exception' ).
      CATCH zcx_ab_v1_ut.
    ENDTRY.
  ENDMETHOD.

  METHOD alpha.
    cl_abap_unit_assert=>assert_equals( exp = '0000004711' act = mo->alpha_in( '4711' ) ).
    cl_abap_unit_assert=>assert_equals( exp = '4711'       act = mo->alpha_out( '0000004711' ) ).
  ENDMETHOD.

  METHOD snake_camel.
    cl_abap_unit_assert=>assert_equals( exp = 'sales_order_item' act = mo->to_snake( 'SalesOrderItem' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'SalesOrderItem'
                                        act = mo->to_camel( iv_value = 'sales_order_item' iv_pascal = abap_true ) ).
  ENDMETHOD.

  METHOD base64_roundtrip.
    DATA(lv_x) = mo->to_xstring( 'Hello' ).
    cl_abap_unit_assert=>assert_equals(
      exp = lv_x
      act = mo->base64_decode( mo->base64_encode( lv_x ) ) ).
  ENDMETHOD.

  METHOD hash_sha256.
    cl_abap_unit_assert=>assert_equals(
      exp = 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad'
      act = mo->hash( iv_data = 'abc' iv_algo = zif_ab_v1_ut_str=>c_algo-sha256 ) ).
  ENDMETHOD.

  METHOD regex_grp.
    DATA(lt) = mo->regex_groups( iv_value = '2026-08-31' iv_pattern = '(\d{4})-(\d{2})-(\d{2})' ).
    cl_abap_unit_assert=>assert_equals( exp = 3 act = lines( lt ) ).
    cl_abap_unit_assert=>assert_equals( exp = '2026' act = lt[ 1 ] ).
    cl_abap_unit_assert=>assert_equals( exp = '31'   act = lt[ 3 ] ).
  ENDMETHOD.

  METHOD validators.
    cl_abap_unit_assert=>assert_true(  mo->is_valid( iv_value = 'a@b.com' iv_kind = zif_ab_v1_ut_str=>c_kind-email ) ).
    cl_abap_unit_assert=>assert_false( mo->is_valid( iv_value = 'nope'    iv_kind = zif_ab_v1_ut_str=>c_kind-email ) ).
  ENDMETHOD.

  METHOD mask_pan.
    cl_abap_unit_assert=>assert_equals(
      exp = '************1111'
      act = mo->mask( iv_value = '4111111111111111' iv_visible_suffix = 4 ) ).
  ENDMETHOD.

ENDCLASS.
