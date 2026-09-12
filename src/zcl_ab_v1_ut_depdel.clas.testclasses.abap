*"* use this source file for your ABAP unit test classes

CLASS ltc_depdel DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo TYPE REF TO zif_ab_v1_ut_depdel.
    METHODS setup.
    METHODS refuses_standard_table  FOR TESTING.
    METHODS refuses_standard_dtel   FOR TESTING.
    METHODS refuses_unknown_table   FOR TESTING.
    METHODS refuses_unsupported_typ FOR TESTING.
    METHODS domain_is_a_leaf        FOR TESTING RAISING zcx_ab_v1_ut.
    METHODS tmp_table_runs          FOR TESTING RAISING zcx_ab_v1_ut.
ENDCLASS.


CLASS ltc_depdel IMPLEMENTATION.

  METHOD setup.
    mo = NEW zcl_ab_v1_ut_depdel( ).
  ENDMETHOD.

  METHOD refuses_standard_table.
    TRY.
        mo->ddic_dependencies( iv_object = 'TABL' iv_obj_name = CONV #( 'MARA' ) ).
        cl_abap_unit_assert=>fail( 'expected ZCX_AB_V1_UT for a standard-namespace table' ).
      CATCH zcx_ab_v1_ut ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

  METHOD refuses_standard_dtel.
    TRY.
        mo->ddic_dependencies( iv_object = 'DTEL' iv_obj_name = CONV #( 'MATNR' ) ).
        cl_abap_unit_assert=>fail( 'expected ZCX_AB_V1_UT for a standard-namespace data element' ).
      CATCH zcx_ab_v1_ut ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

  METHOD refuses_unknown_table.
    TRY.
        mo->ddic_dependencies( iv_object = 'TABL' iv_obj_name = CONV #( 'ZZ_NO_SUCH_TABLE_98765' ) ).
        cl_abap_unit_assert=>fail( 'expected ZCX_AB_V1_UT for an unknown table' ).
      CATCH zcx_ab_v1_ut ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

  METHOD refuses_unsupported_typ.
    TRY.
        mo->ddic_dependencies( iv_object = 'TTYP' iv_obj_name = CONV #( 'ZZ_NO_SUCH_TTYPE_98765' ) ).
        cl_abap_unit_assert=>fail( 'expected ZCX_AB_V1_UT - TTYP is not supported yet' ).
      CATCH zcx_ab_v1_ut ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

  METHOD domain_is_a_leaf.
    " ZAB_V1_UT_AREA is a real domain shipped by this repo - a safe, stable fixture
    DATA(lt) = mo->ddic_dependencies( iv_object = 'DOMA' iv_obj_name = CONV #( 'ZAB_V1_UT_AREA' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( lt ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'DOMA' act = lt[ 1 ]-object ).
  ENDMETHOD.

  METHOD tmp_table_runs.
    " ZAB_V1_UT_ADPT is a real table shipped by this repo - proves the TABL walk
    " does not dump and the root node is always present, regardless of field count
    DATA(lt) = mo->ddic_dependencies( iv_object = 'TABL' iv_obj_name = CONV #( 'ZAB_V1_UT_ADPT' ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( lines( lt ) >= 1 ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'TABL' act = lt[ 1 ]-object ).
    cl_abap_unit_assert=>assert_equals( exp = 'ZAB_V1_UT_ADPT' act = lt[ 1 ]-obj_name ).
  ENDMETHOD.

ENDCLASS.
