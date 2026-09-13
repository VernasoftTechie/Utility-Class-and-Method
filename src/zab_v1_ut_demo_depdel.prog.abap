*&---------------------------------------------------------------------*
*& Report ZAB_V1_UT_DEMO_DEPDEL
*&---------------------------------------------------------------------*
*& Working demo of ZCL_AB_V1_UT_DEPDEL (Phase 1, increment 1a): prints the
*& DDIC composition tree (Table/Structure -> Data Elements -> Domains) for
*& one customer object. Read-only - no delete methods exist yet.
*& Called directly, never through the facade ZCL_AB_V1_UT.
*& See docs/10_dependency_deletion_scope.md.
*&---------------------------------------------------------------------*
REPORT zab_v1_ut_demo_depdel.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-b01.
PARAMETERS: p_otype TYPE trobjtype DEFAULT 'TABL' OBLIGATORY,
            p_oname TYPE sobj_name OBLIGATORY.
SELECTION-SCREEN END OF BLOCK b1.


CLASS lcl_demo DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS run IMPORTING iv_object   TYPE trobjtype
                          iv_obj_name TYPE sobj_name.
  PRIVATE SECTION.
    METHODS w IMPORTING iv TYPE string.
ENDCLASS.


CLASS lcl_demo IMPLEMENTATION.

  METHOD w.
    DATA(lv) = iv.
    WRITE / lv.
  ENDMETHOD.

  METHOD run.
    DATA(lo) = NEW zcl_ab_v1_ut_depdel( ).

    TRY.
        DATA(lt) = lo->zif_ab_v1_ut_depdel~ddic_dependencies( iv_object = iv_object iv_obj_name = iv_obj_name ).

        w( |ddic_dependencies( { iv_object } { iv_obj_name } ) -> { lines( lt ) } node(s)| ) ##NO_TEXT.
        SKIP.

        LOOP AT lt INTO DATA(ls).
          DATA(lv_indent) = repeat( val = `  ` occ = ls-level ).
          DATA(lv_flag)   = COND string( WHEN ls-is_customer = abap_true THEN `Z/Y` ELSE `std` ).
          DATA(lv_line)   = |{ lv_indent }{ ls-object } { ls-obj_name } [{ lv_flag }]| ##NO_TEXT.
          IF ls-via_field IS NOT INITIAL.
            lv_line = |{ lv_line } (via field { ls-via_field })| ##NO_TEXT.
          ENDIF.
          w( lv_line ).
        ENDLOOP.

      CATCH zcx_ab_v1_ut INTO DATA(lx).
        w( |ERROR: { lx->get_text( ) }| ) ##NO_TEXT.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


START-OF-SELECTION.
  NEW lcl_demo( )->run( iv_object = p_otype iv_obj_name = p_oname ).
