"! <p class="shorttext synchronized">ZCL_AB_V1_UT: DDIC dependency discovery for deletion</p>
"! Called directly - never through the facade ZCL_AB_V1_UT. See docs/10_dependency_deletion_scope.md.
CLASS zcl_ab_v1_ut_depdel DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ab_v1_ut_depdel.

  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS is_customer_object
      IMPORTING iv_obj_name    TYPE sobj_name
      RETURNING VALUE(rv_flag) TYPE abap_bool.

    METHODS add_table_deps
      IMPORTING iv_obj_name TYPE sobj_name
                iv_level    TYPE i
      CHANGING  ct          TYPE zif_ab_v1_ut_depdel=>ty_node_tab.

    METHODS add_dtel_deps
      IMPORTING iv_obj_name    TYPE sobj_name
                iv_level       TYPE i
                iv_parent_obj  TYPE trobjtype
                iv_parent_name TYPE sobj_name
                iv_via_field   TYPE fieldname
      CHANGING  ct             TYPE zif_ab_v1_ut_depdel=>ty_node_tab.
ENDCLASS.



CLASS zcl_ab_v1_ut_depdel IMPLEMENTATION.

  METHOD is_customer_object.
    DATA(lv_name) = to_upper( iv_obj_name ).
    IF strlen( lv_name ) = 0.
      rv_flag = abap_false.
      RETURN.
    ENDIF.
    rv_flag = xsdbool( lv_name(1) = 'Z' OR lv_name(1) = 'Y' ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_depdel~ddic_dependencies.
    DATA lv_object   TYPE trobjtype.
    DATA lv_obj_name TYPE sobj_name.
    lv_object   = to_upper( iv_object ).
    lv_obj_name = to_upper( iv_obj_name ).

    IF is_customer_object( lv_obj_name ) = abap_false.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '019'
                                 iv_msgv1 = 'refused - not customer namespace (Z/Y)'
                                 iv_msgv2 = lv_obj_name ) ##NO_TEXT.
    ENDIF.

    CASE lv_object.
      WHEN 'TABL'.
        SELECT SINGLE tabname FROM dd02l INTO @DATA(lv_tabname)
          WHERE tabname = @lv_obj_name AND as4local = 'A'.
        IF sy-subrc <> 0.
          zcx_ab_v1_ut=>raise_t100( iv_msgno = '019' iv_msgv1 = 'table/structure' iv_msgv2 = lv_obj_name ) ##NO_TEXT.
        ENDIF.

      WHEN 'DTEL'.
        SELECT SINGLE rollname FROM dd04l INTO @DATA(lv_roll)
          WHERE rollname = @lv_obj_name AND as4local = 'A'.
        IF sy-subrc <> 0.
          zcx_ab_v1_ut=>raise_t100( iv_msgno = '019' iv_msgv1 = 'data element' iv_msgv2 = lv_obj_name ) ##NO_TEXT.
        ENDIF.

      WHEN 'DOMA'.
        SELECT SINGLE domname FROM dd01l INTO @DATA(lv_dom)
          WHERE domname = @lv_obj_name AND as4local = 'A'.
        IF sy-subrc <> 0.
          zcx_ab_v1_ut=>raise_t100( iv_msgno = '019' iv_msgv1 = 'domain' iv_msgv2 = lv_obj_name ) ##NO_TEXT.
        ENDIF.

      WHEN OTHERS.
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '019'
                                   iv_msgv1 = 'object type not supported yet (TABL/DTEL/DOMA only)'
                                   iv_msgv2 = lv_object ) ##NO_TEXT.
    ENDCASE.

    APPEND VALUE #( object      = lv_object
                    obj_name    = lv_obj_name
                    level       = 0
                    is_customer = abap_true ) TO rt.

    CASE lv_object.
      WHEN 'TABL'.
        add_table_deps( EXPORTING iv_obj_name = lv_obj_name
                                   iv_level    = 1
                         CHANGING  ct          = rt ).
      WHEN 'DTEL'.
        add_dtel_deps( EXPORTING iv_obj_name    = lv_obj_name
                                  iv_level       = 1
                                  iv_parent_obj  = lv_object
                                  iv_parent_name = lv_obj_name
                                  iv_via_field   = space
                        CHANGING  ct             = rt ).
      WHEN OTHERS.
        " DOMA is a leaf - nothing further to walk
    ENDCASE.
  ENDMETHOD.


  METHOD add_table_deps.
    SELECT fieldname, rollname FROM dd03l
      WHERE tabname   = @iv_obj_name
        AND as4local  = 'A'
        AND rollname <> @space
      INTO TABLE @DATA(lt_fld).

    DATA lv_dtel TYPE sobj_name.
    LOOP AT lt_fld INTO DATA(ls_fld).
      lv_dtel = to_upper( ls_fld-rollname ).
      IF NOT line_exists( ct[ object = 'DTEL' obj_name = lv_dtel ] ).
        APPEND VALUE #( object        = 'DTEL'
                        obj_name      = lv_dtel
                        level         = iv_level
                        parent_object = 'TABL'
                        parent_name   = iv_obj_name
                        via_field     = ls_fld-fieldname
                        is_customer   = is_customer_object( lv_dtel ) ) TO ct.

        add_dtel_deps( EXPORTING iv_obj_name    = lv_dtel
                                  iv_level       = iv_level + 1
                                  iv_parent_obj  = 'DTEL'
                                  iv_parent_name = lv_dtel
                                  iv_via_field   = space
                        CHANGING  ct             = ct ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD add_dtel_deps.
    SELECT SINGLE domname FROM dd04l INTO @DATA(lv_domname)
      WHERE rollname = @iv_obj_name AND as4local = 'A'.
    IF sy-subrc <> 0 OR lv_domname IS INITIAL.
      RETURN. " built-in-type data element - no domain dependency
    ENDIF.

    DATA lv_dom TYPE sobj_name.
    lv_dom = to_upper( lv_domname ).
    IF NOT line_exists( ct[ object = 'DOMA' obj_name = lv_dom ] ).
      APPEND VALUE #( object        = 'DOMA'
                      obj_name      = lv_dom
                      level         = iv_level
                      parent_object = iv_parent_obj
                      parent_name   = iv_parent_name
                      via_field     = iv_via_field
                      is_customer   = is_customer_object( lv_dom ) ) TO ct.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
