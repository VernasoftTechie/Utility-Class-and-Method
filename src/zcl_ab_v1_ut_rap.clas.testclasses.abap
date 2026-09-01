*"* use this source file for your ABAP unit test classes

CLASS ltc_rap DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_s,
             a TYPE i,
             b TYPE string,
             c TYPE i,
           END OF ty_s.
    TYPES: BEGIN OF ty_ctrl,
             a TYPE abap_bool,
             b TYPE abap_bool,
             c TYPE abap_bool,
           END OF ty_ctrl.

    DATA mo TYPE REF TO zif_ab_v1_ut_rap.

    METHODS setup.
    METHODS cid_unique     FOR TESTING.
    METHODS ret_to_text    FOR TESTING.
    METHODS control_copy   FOR TESTING.
ENDCLASS.


CLASS ltc_rap IMPLEMENTATION.

  METHOD setup.
    mo = NEW zcl_ab_v1_ut_rap( ).
  ENDMETHOD.

  METHOD cid_unique.
    DATA(lv1) = mo->new_cid( ).
    DATA(lv2) = mo->new_cid( ).
    cl_abap_unit_assert=>assert_not_initial( lv1 ).
    cl_abap_unit_assert=>assert_differs( exp = lv1 act = lv2 ).
  ENDMETHOD.

  METHOD ret_to_text.
    DATA(lt) = mo->bapiret_to_text( VALUE #(
      ( type = 'E' id = 'ZAB_V1_UT' number = '001' message = 'boom' )
      ( type = 'S' id = 'ZAB_V1_UT' number = '001' message = 'ok' ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( lt ) ).
    cl_abap_unit_assert=>assert_char_cp( exp = 'E: boom*' act = lt[ 1 ] ).
  ENDMETHOD.

  METHOD control_copy.
    DATA(ls_src)  = VALUE ty_s( a = 1 b = 'x' c = 9 ).
    DATA(ls_ctrl) = VALUE ty_ctrl( a = abap_true b = abap_true c = abap_false ).
    DATA ls_tgt TYPE ty_s.

    mo->corresponding_control( EXPORTING is_source = ls_src is_control = ls_ctrl
                               CHANGING  cs_target = ls_tgt ).

    cl_abap_unit_assert=>assert_equals( exp = 1   act = ls_tgt-a ).
    cl_abap_unit_assert=>assert_equals( exp = 'x' act = ls_tgt-b ).
    cl_abap_unit_assert=>assert_equals( exp = 0   act = ls_tgt-c ).
  ENDMETHOD.

ENDCLASS.
