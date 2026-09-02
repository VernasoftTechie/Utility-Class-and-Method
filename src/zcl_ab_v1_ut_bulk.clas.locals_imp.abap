CLASS lcl_par IMPLEMENTATION.

  METHOD do.
    DATA lt_msg TYPE bapiret2_t.

    " rebuild the package table from its serialized JSON
    DATA lr_tab TYPE REF TO data.
    TRY.
        CREATE DATA lr_tab TYPE STANDARD TABLE OF (mv_line_name).
      CATCH cx_sy_create_data_error INTO DATA(lx_cd).
        lt_msg = VALUE #( ( type = 'E' message = lx_cd->get_text( ) ) ).
        p_out  = cl_abap_codepage=>convert_to( /ui2/cl_json=>serialize( lt_msg ) ).
        RETURN.
    ENDTRY.

    ASSIGN lr_tab->* TO FIELD-SYMBOL(<tab>).
    TRY.
        /ui2/cl_json=>deserialize( EXPORTING json = cl_abap_codepage=>convert_from( p_in )
                                   CHANGING  data = <tab> ).
      CATCH cx_root ##NO_HANDLER.
    ENDTRY.

    DATA lo_handler TYPE REF TO zif_ab_v1_ut_bulk_handler.
    TRY.
        CREATE OBJECT lo_handler TYPE (mv_handler_class).
        lt_msg = lo_handler->process_package( lr_tab ).
      CATCH cx_root INTO DATA(lx).
        lt_msg = VALUE #( ( type = 'E' message = lx->get_text( ) ) ).
    ENDTRY.

    p_out = cl_abap_codepage=>convert_to( /ui2/cl_json=>serialize( lt_msg ) ).
  ENDMETHOD.

ENDCLASS.
