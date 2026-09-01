"! <p class="shorttext synchronized">ZCL_AB_V1_UT: SAP GUI utilities</p>
"! SAP GUI only - ALV display + presentation-server file dialogs. Never call this
"! from RAP behaviour code; there is no dependency from ZCL_AB_V1_UT to this class.
"! Raises ZAB_V1_UT/011 when no SAP GUI is attached (e.g. background).
CLASS zcl_ab_v1_ut_gui DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    INTERFACES zif_ab_v1_ut_alv.

    CLASS-METHODS alv
      RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_alv.

    CLASS-METHODS ensure_gui
      RAISING zcx_ab_v1_ut.

    CLASS-METHODS pick_file
      IMPORTING iv_title      TYPE string OPTIONAL
                iv_filter     TYPE string DEFAULT '(*.*)|*.*'
      RETURNING VALUE(rv_path) TYPE string
      RAISING   zcx_ab_v1_ut.

    CLASS-METHODS upload_file
      IMPORTING iv_path          TYPE string
      RETURNING VALUE(rv_content) TYPE xstring
      RAISING   zcx_ab_v1_ut.

    CLASS-METHODS download_file
      IMPORTING iv_path    TYPE string
                iv_content TYPE xstring
      RAISING   zcx_ab_v1_ut.

  PRIVATE SECTION.
    CLASS-DATA go_alv TYPE REF TO zif_ab_v1_ut_alv.
ENDCLASS.



CLASS zcl_ab_v1_ut_gui IMPLEMENTATION.

  METHOD alv.
    IF go_alv IS NOT BOUND.
      go_alv = NEW zcl_ab_v1_ut_gui( ).
    ENDIF.
    ro = go_alv.
  ENDMETHOD.


  METHOD ensure_gui.
    IF sy-batch = abap_true.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '011' ).
    ENDIF.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_alv~show.
    ensure_gui( ).
    TRY.
        cl_salv_table=>factory( IMPORTING r_salv_table = DATA(lo)
                                CHANGING  t_table      = ct_table ).
        lo->get_functions( )->set_all( ).
        IF iv_title IS NOT INITIAL.
          lo->get_display_settings( )->set_list_header( CONV lvc_title( iv_title ) ).
        ENDIF.
        IF iv_variant IS NOT INITIAL.
          lo->get_layout( )->set_key( VALUE #( report = sy-cprog ) ).
          lo->get_layout( )->set_save_restriction( if_salv_c_layout=>restrict_none ).
          lo->get_layout( )->set_initial_layout( iv_variant ).
        ENDIF.
        lo->display( ).
      CATCH cx_salv_error INTO DATA(lx).
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '001' iv_msgv1 = lx->get_text( ) io_previous = lx ).
    ENDTRY.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_alv~show_dynamic.
    ensure_gui( ).
    ASSIGN ir_table->* TO FIELD-SYMBOL(<tab>).
    IF <tab> IS NOT ASSIGNED.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '001' iv_msgv1 = 'show_dynamic: no table' ).
    ENDIF.

    TRY.
        cl_salv_table=>factory( IMPORTING r_salv_table = DATA(lo)
                                CHANGING  t_table      = <tab> ).
        lo->get_functions( )->set_all( ).
        IF iv_title IS NOT INITIAL.
          lo->get_display_settings( )->set_list_header( CONV lvc_title( iv_title ) ).
        ENDIF.
        lo->display( ).
      CATCH cx_salv_error INTO DATA(lx).
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '001' iv_msgv1 = lx->get_text( ) io_previous = lx ).
    ENDTRY.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_alv~build_fieldcat.
    DATA lr TYPE REF TO data.
    CREATE DATA lr TYPE HANDLE io_table_type.
    ASSIGN lr->* TO FIELD-SYMBOL(<tab>).

    TRY.
        cl_salv_table=>factory( IMPORTING r_salv_table = DATA(lo)
                                CHANGING  t_table      = <tab> ).
        rt_fcat = cl_salv_controller_metadata=>get_lvc_fieldcatalog(
                    r_columns      = lo->get_columns( )
                    r_aggregations = lo->get_aggregations( ) ).
      CATCH cx_salv_error INTO DATA(lx).
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '001' iv_msgv1 = lx->get_text( ) io_previous = lx ).
    ENDTRY.
  ENDMETHOD.


  METHOD pick_file.
    ensure_gui( ).
    DATA: lt_files TYPE filetable,
          lv_rc    TYPE i,
          lv_act   TYPE i.
    cl_gui_frontend_services=>file_open_dialog(
      EXPORTING window_title = CONV #( iv_title )
                file_filter  = CONV #( iv_filter )
      CHANGING  file_table   = lt_files
                rc           = lv_rc
                user_action  = lv_act
      EXCEPTIONS OTHERS      = 1 ).
    IF sy-subrc <> 0 OR lv_act <> cl_gui_frontend_services=>action_ok OR lt_files IS INITIAL.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '015' iv_msgv1 = 'file dialog cancelled' ).
    ENDIF.
    rv_path = lt_files[ 1 ]-filename.
  ENDMETHOD.


  METHOD upload_file.
    ensure_gui( ).
    DATA: lt_bin TYPE solix_tab,
          lv_len TYPE i.
    cl_gui_frontend_services=>gui_upload(
      EXPORTING filename   = CONV string( iv_path )
                filetype   = 'BIN'
      IMPORTING filelength = lv_len
      CHANGING  data_tab   = lt_bin
      EXCEPTIONS OTHERS    = 1 ).
    IF sy-subrc <> 0.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '015' iv_msgv1 = iv_path ).
    ENDIF.
    rv_content = cl_bcs_convert=>solix_to_xstring( it_solix = lt_bin iv_size = lv_len ).
  ENDMETHOD.


  METHOD download_file.
    ensure_gui( ).
    DATA(lt_bin) = cl_bcs_convert=>xstring_to_solix( iv_content ).
    cl_gui_frontend_services=>gui_download(
      EXPORTING bin_filesize = xstrlen( iv_content )
                filename     = CONV string( iv_path )
                filetype     = 'BIN'
      CHANGING  data_tab     = lt_bin
      EXCEPTIONS OTHERS      = 1 ).
    IF sy-subrc <> 0.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '015' iv_msgv1 = iv_path ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
