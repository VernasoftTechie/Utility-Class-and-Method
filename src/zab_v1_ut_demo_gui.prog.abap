*&---------------------------------------------------------------------*
*& Report ZAB_V1_UT_DEMO_GUI
*&---------------------------------------------------------------------*
*& Demo for ZCL_AB_V1_UT_GUI (SAP GUI only): static ALV, dynamic ALV,
*& field-catalog generation and presentation-server file up/download.
*& Requires a SAP GUI session - raises ZAB_V1_UT/011 in background.
*&---------------------------------------------------------------------*
REPORT zab_v1_ut_demo_gui.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-b01.
PARAMETERS: p_alv  RADIOBUTTON GROUP g1 DEFAULT 'X',
            p_dyn  RADIOBUTTON GROUP g1,
            p_fcat RADIOBUTTON GROUP g1,
            p_file RADIOBUTTON GROUP g1.
SELECTION-SCREEN END OF BLOCK b1.

TYPES: BEGIN OF ty_row,
         carrid   TYPE c LENGTH 3,
         connid   TYPE n LENGTH 4,
         cityfrom TYPE c LENGTH 20,
         cityto   TYPE c LENGTH 20,
       END OF ty_row.

START-OF-SELECTION.

  DATA lt TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.
  lt = VALUE #( ( carrid = 'AA' connid = '0017' cityfrom = 'NEW YORK'  cityto = 'SAN FRANCISCO' )
                ( carrid = 'LH' connid = '0400' cityfrom = 'FRANKFURT' cityto = 'NEW YORK' )
                ( carrid = 'SQ' connid = '0002' cityfrom = 'SINGAPORE' cityto = 'FRANKFURT' ) ).

  TRY.
      CASE abap_true.
        WHEN p_alv.
          zcl_ab_v1_ut_gui=>alv( )->show( EXPORTING iv_title = TEXT-t01
                                          CHANGING  ct_table = lt ).

        WHEN p_dyn.
          DATA lr TYPE REF TO data.
          GET REFERENCE OF lt INTO lr.
          zcl_ab_v1_ut_gui=>alv( )->show_dynamic( ir_table = lr iv_title = TEXT-t02 ).

        WHEN p_fcat.
          DATA(lo_tt)   = CAST cl_abap_tabledescr( cl_abap_typedescr=>describe_by_data( lt ) ).
          DATA(lt_fcat) = zcl_ab_v1_ut_gui=>alv( )->build_fieldcat( lo_tt ).
          LOOP AT lt_fcat INTO DATA(ls_f).
            WRITE: / ls_f-fieldname, ls_f-inttype, ls_f-outputlen.
          ENDLOOP.

        WHEN p_file.
          DATA(lv_path) = zcl_ab_v1_ut_gui=>pick_file( iv_title = TEXT-t03 ).
          DATA(lv_x)    = zcl_ab_v1_ut_gui=>upload_file( lv_path ).
          DATA(lv_l1)   = |picked { lv_path } ({ xstrlen( lv_x ) } bytes)| ##NO_TEXT.
          WRITE / lv_l1.
          zcl_ab_v1_ut_gui=>download_file( iv_path    = |{ lv_path }.copy|
                                           iv_content = lv_x ).
          DATA(lv_l2)   = |written back to { lv_path }.copy|        ##NO_TEXT.
          WRITE / lv_l2.
      ENDCASE.

    CATCH zcx_ab_v1_ut INTO DATA(lx).
      MESSAGE lx->get_text( ) TYPE 'I'.
  ENDTRY.
