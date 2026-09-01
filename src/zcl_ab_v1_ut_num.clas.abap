CLASS zcl_ab_v1_ut_num DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ab_v1_ut_num.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_ab_v1_ut_num IMPLEMENTATION.

  METHOD zif_ab_v1_ut_num~next.
    zcl_ab_v1_ut_phase=>assert_defer_allowed( 'next' ).

    TRY.
        cl_numberrange_runtime=>number_get(
          EXPORTING nr_range_nr = iv_interval
                    object      = iv_object
                    subobject   = iv_subobject
                    toyear      = iv_toyear
                    quantity    = 1
          IMPORTING number      = DATA(lv_num) ).
        rv_number = condense( lv_num ).
      CATCH cx_number_ranges INTO DATA(lx).
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '016' iv_msgv1 = |{ iv_object }|
                                  iv_msgv2 = lx->get_text( ) io_previous = lx ).
    ENDTRY.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_num~next_bulk.
    zcl_ab_v1_ut_phase=>assert_defer_allowed( 'next_bulk' ).

    TRY.
        cl_numberrange_runtime=>number_get(
          EXPORTING nr_range_nr       = iv_interval
                    object            = iv_object
                    subobject         = iv_subobject
                    quantity          = CONV nrquan( iv_count )
          IMPORTING number            = DATA(lv_last)
                    returned_quantity = DATA(lv_qty) ).

        DATA(lv_start) = CONV decfloat34( lv_last ) - lv_qty + 1.
        DO lv_qty TIMES.
          APPEND condense( |{ lv_start + sy-index - 1 }| ) TO rt_numbers.
        ENDDO.
      CATCH cx_number_ranges INTO DATA(lx).
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '016' iv_msgv1 = |{ iv_object }|
                                  iv_msgv2 = lx->get_text( ) io_previous = lx ).
    ENDTRY.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_num~status.
    DATA ls_int TYPE inriv.
    CALL FUNCTION 'NUMBER_GET_INFO'
      EXPORTING  object            = iv_object
                 nr_range_nr       = iv_interval
      IMPORTING  interval          = ls_int
      EXCEPTIONS interval_not_found = 1
                 object_not_found   = 2
                 OTHERS             = 3.
    IF sy-subrc <> 0.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '016' iv_msgv1 = |{ iv_object }| iv_msgv2 = |status rc={ sy-subrc }| ).
    ENDIF.

    ev_current = condense( |{ ls_int-nrlevel }| ).

    DATA(lv_from) = CONV decfloat34( ls_int-fromnumber ).
    DATA(lv_to)   = CONV decfloat34( ls_int-tonumber ).
    DATA(lv_lvl)  = CONV decfloat34( ls_int-nrlevel ).
    IF lv_to - lv_from > 0.
      ev_percentage = ( lv_lvl - lv_from ) / ( lv_to - lv_from ) * 100.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
