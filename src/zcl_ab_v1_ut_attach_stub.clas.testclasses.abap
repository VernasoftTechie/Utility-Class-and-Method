*"* use this source file for your ABAP unit test classes

CLASS ltc_stub DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo TYPE REF TO zif_ab_v1_ut_attach.
    METHODS setup.
    METHODS teardown.
    METHODS guids           FOR TESTING.
    METHODS attach_list_get  FOR TESTING RAISING zcx_ab_v1_ut.
    METHODS get_unknown      FOR TESTING.
    METHODS solix_roundtrip  FOR TESTING.
ENDCLASS.


CLASS ltc_stub IMPLEMENTATION.

  METHOD setup.
    mo = NEW zcl_ab_v1_ut_attach_stub( ).
    zcl_ab_v1_ut_attach_stub=>reset( ).
  ENDMETHOD.

  METHOD teardown.
    zcl_ab_v1_ut_attach_stub=>reset( ).
  ENDMETHOD.

  METHOD guids.
    cl_abap_unit_assert=>assert_not_initial( mo->new_guid_x16( ) ).
    cl_abap_unit_assert=>assert_differs( exp = mo->new_guid_c32( ) act = mo->new_guid_c32( ) ).
    cl_abap_unit_assert=>assert_equals( exp = 22 act = strlen( mo->new_guid_c22( ) ) ).
  ENDMETHOD.

  METHOD attach_list_get.
    DATA lv_x TYPE xstring VALUE '48656C6C6F'.
    DATA(ls_key) = VALUE zif_ab_v1_ut_types=>ty_bo_key( objtype = 'ZTEST' objkey = 'K1' ).

    DATA(lv_id) = mo->attach( is_bo_key = ls_key iv_filename = 'a.pdf'
                              iv_mimetype = 'application/pdf' iv_content = lv_x ).

    DATA(lt) = mo->list( ls_key ).
    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( lt ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'a.pdf' act = lt[ 1 ]-filename ).
    cl_abap_unit_assert=>assert_equals( exp = 5 act = lt[ 1 ]-bytes ).
    cl_abap_unit_assert=>assert_equals( exp = lv_x act = mo->get( lv_id ) ).

    " different BO key -> not listed
    cl_abap_unit_assert=>assert_initial(
      lines( mo->list( VALUE #( objtype = 'ZTEST' objkey = 'K2' ) ) ) ).
  ENDMETHOD.

  METHOD get_unknown.
    TRY.
        mo->get( 'NOPE' ).
        cl_abap_unit_assert=>fail( 'expected exception' ).
      CATCH zcx_ab_v1_ut.
    ENDTRY.
  ENDMETHOD.

  METHOD solix_roundtrip.
    DATA lv_x TYPE xstring VALUE '00112233445566778899AABBCCDDEEFF'.
    DATA(lt) = mo->to_solix( lv_x ).
    cl_abap_unit_assert=>assert_equals( exp = lv_x
      act = mo->from_solix( it_solix = lt iv_length = xstrlen( lv_x ) ) ).
  ENDMETHOD.

ENDCLASS.
