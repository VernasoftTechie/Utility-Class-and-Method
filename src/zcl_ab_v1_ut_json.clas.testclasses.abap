*"* use this source file for your ABAP unit test classes

CLASS ltc_json DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_addr,
             city TYPE string,
             zip  TYPE string,
           END OF ty_addr.
    TYPES: BEGIN OF ty_p,
             first_name TYPE string,
             age        TYPE i,
             address    TYPE ty_addr,
           END OF ty_p.
    TYPES: BEGIN OF ty_t,
             a TYPE i,
             b TYPE STANDARD TABLE OF i WITH EMPTY KEY,
             c TYPE string,
           END OF ty_t.

    DATA mo TYPE REF TO zif_ab_v1_ut_json.

    METHODS setup.
    METHODS roundtrip       FOR TESTING RAISING zcx_ab_v1_ut.
    METHODS camel_case      FOR TESTING RAISING zcx_ab_v1_ut.
    METHODS pretty_valid    FOR TESTING RAISING zcx_ab_v1_ut.
    METHODS describe_struct FOR TESTING RAISING zcx_ab_v1_ut.
    METHODS xml_roundtrip   FOR TESTING RAISING zcx_ab_v1_ut.
ENDCLASS.


CLASS ltc_json IMPLEMENTATION.

  METHOD setup.
    mo = NEW zcl_ab_v1_ut_json( ).
  ENDMETHOD.

  METHOD roundtrip.
    DATA(ls) = VALUE ty_p( first_name = 'Ann' age = 30
                           address = VALUE #( city = 'NYC' zip = '10001' ) ).
    DATA(lv_json) = mo->serialize( ls ).
    DATA ls2 TYPE ty_p.
    mo->deserialize( EXPORTING iv_json = lv_json CHANGING ca_data = ls2 ).
    cl_abap_unit_assert=>assert_equals( exp = ls act = ls2 ).
  ENDMETHOD.

  METHOD camel_case.
    DATA(ls) = VALUE ty_p( first_name = 'Ann' age = 30 ).
    DATA(lv_json) = mo->serialize( iv_data = ls iv_camel_case = abap_true ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_json CS '"firstName"' ) ).

    DATA ls2 TYPE ty_p.
    mo->deserialize( EXPORTING iv_json = lv_json iv_camel_case = abap_true CHANGING ca_data = ls2 ).
    cl_abap_unit_assert=>assert_equals( exp = 'Ann' act = ls2-first_name ).
  ENDMETHOD.

  METHOD pretty_valid.
    DATA(lv_c) = `{"a":1,"b":[2,3],"c":"x,y"}`.
    DATA(lv_p) = mo->pretty( lv_c ).

    cl_abap_unit_assert=>assert_true( xsdbool( lv_p CS cl_abap_char_utilities=>newline ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv_p CS '"x,y"' ) ).

    DATA ls_t TYPE ty_t.
    mo->deserialize( EXPORTING iv_json = lv_p CHANGING ca_data = ls_t ).
    cl_abap_unit_assert=>assert_equals( exp = 1     act = ls_t-a ).
    cl_abap_unit_assert=>assert_equals( exp = 'x,y' act = ls_t-c ).
    cl_abap_unit_assert=>assert_equals( exp = 2     act = lines( ls_t-b ) ).
  ENDMETHOD.

  METHOD describe_struct.
    DATA ls TYPE ty_p.
    DATA(lv) = mo->describe( iv_data = ls ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv CS '"first_name"' ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv CS '"address"' ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lv CS '"kind": "elementary"' ) ).
  ENDMETHOD.

  METHOD xml_roundtrip.
    DATA(ls) = VALUE ty_p( first_name = 'Ann' age = 30 ).
    DATA(lv_x) = mo->xml_serialize( ls ).
    DATA ls2 TYPE ty_p.
    mo->xml_deserialize( EXPORTING iv_xml = lv_x CHANGING ca_data = ls2 ).
    cl_abap_unit_assert=>assert_equals( exp = ls act = ls2 ).
  ENDMETHOD.

ENDCLASS.
