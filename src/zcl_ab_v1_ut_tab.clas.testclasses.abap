*"* use this source file for your ABAP unit test classes

CLASS ltc_tab DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_row,
             id   TYPE i,
             name TYPE string,
           END OF ty_row,
           tt_row TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.
    TYPES: BEGIN OF ty_amt,
             grp TYPE string,
             val TYPE decfloat34,
             cnt TYPE i,
           END OF ty_amt,
           tt_amt TYPE STANDARD TABLE OF ty_amt WITH EMPTY KEY.
    TYPES tt_i TYPE STANDARD TABLE OF i WITH EMPTY KEY.

    DATA mo TYPE REF TO zif_ab_v1_ut_tab.

    METHODS setup.
    METHODS create_dyn        FOR TESTING RAISING zcx_ab_v1_ut.
    METHODS diff_ins_upd_del  FOR TESTING RAISING zcx_ab_v1_ut.
    METHODS ranges_build      FOR TESTING.
    METHODS chunk_split       FOR TESTING.
    METHODS distinct_all      FOR TESTING.
    METHODS fingerprint_t     FOR TESTING.
    METHODS deep_equal_t      FOR TESTING.
    METHODS aggregate_sum     FOR TESTING RAISING zcx_ab_v1_ut.
ENDCLASS.


CLASS ltc_tab IMPLEMENTATION.

  METHOD setup.
    mo = NEW zcl_ab_v1_ut_tab( ).
  ENDMETHOD.

  METHOD create_dyn.
    DATA(lr) = mo->create_dynamic( iv_structure = 'T000' ).
    cl_abap_unit_assert=>assert_bound( lr ).
    DATA(lo) = cl_abap_typedescr=>describe_by_data_ref( lr ).
    cl_abap_unit_assert=>assert_equals( exp = cl_abap_typedescr=>typekind_table act = lo->type_kind ).
  ENDMETHOD.

  METHOD diff_ins_upd_del.
    DATA(lt_old) = VALUE tt_row( ( id = 1 name = 'a' ) ( id = 2 name = 'b' ) ( id = 3 name = 'c' ) ).
    DATA(lt_new) = VALUE tt_row( ( id = 1 name = 'a' ) ( id = 2 name = 'B' ) ( id = 4 name = 'd' ) ).
    DATA: lt_ins TYPE tt_row,
          lt_upd TYPE tt_row,
          lt_del TYPE tt_row.

    mo->diff( EXPORTING it_old = lt_old it_new = lt_new it_key_fields = VALUE #( ( `ID` ) )
              IMPORTING et_insert = lt_ins et_update = lt_upd et_delete = lt_del ).

    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( lt_ins ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( lt_upd ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( lt_del ) ).
    cl_abap_unit_assert=>assert_equals( exp = 4 act = lt_ins[ 1 ]-id ).
    cl_abap_unit_assert=>assert_equals( exp = 2 act = lt_upd[ 1 ]-id ).
    cl_abap_unit_assert=>assert_equals( exp = 3 act = lt_del[ 1 ]-id ).
  ENDMETHOD.

  METHOD ranges_build.
    DATA(lt_vals) = VALUE tt_i( ( 10 ) ( 20 ) ).
    DATA lt_rng TYPE RANGE OF i.
    mo->to_ranges( EXPORTING it_values = lt_vals IMPORTING et_range = lt_rng ).
    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( lt_rng ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'I'  act = lt_rng[ 1 ]-sign ).
    cl_abap_unit_assert=>assert_equals( exp = 'EQ' act = lt_rng[ 1 ]-option ).
    cl_abap_unit_assert=>assert_equals( exp = 10  act = lt_rng[ 1 ]-low ).
  ENDMETHOD.

  METHOD chunk_split.
    DATA lt10 TYPE tt_row.
    DO 10 TIMES.
      APPEND VALUE #( id = sy-index ) TO lt10.
    ENDDO.
    DATA(lr) = mo->chunk( it_data = lt10 iv_size = 4 ).
    FIELD-SYMBOLS <chunks> TYPE STANDARD TABLE.
    ASSIGN lr->* TO <chunks>.
    cl_abap_unit_assert=>assert_equals( exp = 3 act = lines( <chunks> ) ).
  ENDMETHOD.

  METHOD distinct_all.
    DATA(lt) = VALUE tt_row( ( id = 1 name = 'a' ) ( id = 1 name = 'a' ) ( id = 2 name = 'b' ) ).
    mo->distinct( CHANGING ct_data = lt ).
    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( lt ) ).
  ENDMETHOD.

  METHOD fingerprint_t.
    DATA(ls_a) = VALUE ty_row( id = 1 name = 'x' ).
    DATA(ls_b) = VALUE ty_row( id = 1 name = 'x' ).
    DATA(ls_c) = VALUE ty_row( id = 1 name = 'y' ).
    cl_abap_unit_assert=>assert_equals( exp = mo->fingerprint( ls_a ) act = mo->fingerprint( ls_b ) ).
    cl_abap_unit_assert=>assert_differs( exp = mo->fingerprint( ls_a ) act = mo->fingerprint( ls_c ) ).
  ENDMETHOD.

  METHOD deep_equal_t.
    DATA(ls_a) = VALUE ty_row( id = 1 name = 'x' ).
    DATA(ls_b) = VALUE ty_row( id = 1 name = 'x' ).
    DATA(ls_c) = VALUE ty_row( id = 2 name = 'x' ).
    cl_abap_unit_assert=>assert_true(  mo->deep_equal( ir_a = REF #( ls_a ) ir_b = REF #( ls_b ) ) ).
    cl_abap_unit_assert=>assert_false( mo->deep_equal( ir_a = REF #( ls_a ) ir_b = REF #( ls_c ) ) ).
  ENDMETHOD.

  METHOD aggregate_sum.
    DATA(lt_src) = VALUE tt_amt( ( grp = 'A' val = 10 ) ( grp = 'A' val = 5 ) ( grp = 'B' val = 3 ) ).
    DATA lt_res TYPE tt_amt.
    mo->aggregate( EXPORTING it_data     = lt_src
                             it_group_by = VALUE #( ( `GRP` ) )
                             it_measures = VALUE #( ( name = `VAL` value = `SUM` ) ( name = `CNT` value = `COUNT` ) )
                   IMPORTING et_result   = lt_res ).
    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( lt_res ) ).
    DATA(ls_a) = lt_res[ grp = 'A' ].
    cl_abap_unit_assert=>assert_equals( exp = CONV decfloat34( '15' ) act = ls_a-val ).
    cl_abap_unit_assert=>assert_equals( exp = 2 act = ls_a-cnt ).
  ENDMETHOD.

ENDCLASS.
