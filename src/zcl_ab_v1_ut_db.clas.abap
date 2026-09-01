CLASS zcl_ab_v1_ut_db DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ab_v1_ut_db.
  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS validated_entity
      IMPORTING iv_entity TYPE clike
      RETURNING VALUE(rv) TYPE string
      RAISING   zcx_ab_v1_ut.

    METHODS keys_to_where
      IMPORTING iv_entity TYPE clike
                it_keys   TYPE zif_ab_v1_ut_types=>ty_key_tab
      RETURNING VALUE(rt) TYPE string_table
      RAISING   zcx_ab_v1_ut.
ENDCLASS.



CLASS zcl_ab_v1_ut_db IMPLEMENTATION.

  METHOD validated_entity.
    TRY.
        rv = cl_abap_dyn_prg=>check_table_or_view_name_str( val = to_upper( iv_entity ) ).
      CATCH cx_root INTO DATA(lx).
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '019' iv_msgv1 = 'entity' iv_msgv2 = iv_entity io_previous = lx ) ##NO_TEXT.
    ENDTRY.
  ENDMETHOD.


  METHOD keys_to_where.
    DATA lo_type TYPE REF TO cl_abap_typedescr.
    TRY.
        lo_type = cl_abap_typedescr=>describe_by_name( CONV string( iv_entity ) ).
      CATCH cx_root INTO DATA(lx).
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '019' iv_msgv1 = 'entity' iv_msgv2 = iv_entity io_previous = lx ) ##NO_TEXT.
    ENDTRY.

    DATA(lo_struct) = CAST cl_abap_structdescr( lo_type ).

    LOOP AT it_keys INTO DATA(ls_k).
      DATA(lv_field) = to_upper( ls_k-name ).
      IF NOT line_exists( lo_struct->components[ name = lv_field ] ).
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '014' iv_msgv1 = |unknown field { lv_field }| ) ##NO_TEXT.
      ENDIF.
      DATA(lv_val) = replace( val = ls_k-value sub = `'` with = `''` occ = 0 ).
      APPEND |{ lv_field } = '{ lv_val }'| TO rt.
    ENDLOOP.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_db~read.
    DATA(lv_entity) = validated_entity( iv_entity ).

    DATA lt_cols TYPE string_table.
    IF it_columns IS INITIAL.
      lt_cols = VALUE #( ( `*` ) ).
    ELSE.
      lt_cols = it_columns.
    ENDIF.

    LOOP AT it_where INTO DATA(lv_w).
      IF lv_w CS ';' OR lv_w CS '--'.
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '014' iv_msgv1 = 'illegal WHERE token' ) ##NO_TEXT.
      ENDIF.
    ENDLOOP.

    DATA lt_where TYPE string_table.
    lt_where = it_where.
    DATA lt_order TYPE string_table.
    lt_order = it_order_by.

    DATA lr TYPE REF TO data.
    TRY.
        CREATE DATA lr TYPE STANDARD TABLE OF (lv_entity).
        ASSIGN lr->* TO FIELD-SYMBOL(<tab>).

        IF lt_order IS INITIAL.
          SELECT (lt_cols) FROM (lv_entity) WHERE (lt_where)
            INTO CORRESPONDING FIELDS OF TABLE @<tab>
            UP TO @iv_up_to ROWS.
        ELSE.
          SELECT (lt_cols) FROM (lv_entity) WHERE (lt_where) ORDER BY (lt_order)
            INTO CORRESPONDING FIELDS OF TABLE @<tab>
            UP TO @iv_up_to ROWS.
        ENDIF.

        rr_result = lr.

      CATCH cx_sy_dynamic_osql_error cx_sy_open_sql_db INTO DATA(lx).
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '014' iv_msgv1 = lx->get_text( ) io_previous = lx ).
    ENDTRY.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_db~exists.
    DATA(lv_entity) = validated_entity( iv_entity ).
    DATA(lt_where)  = keys_to_where( iv_entity = lv_entity it_keys = it_keys ).

    TRY.
        SELECT SINGLE @abap_true FROM (lv_entity) WHERE (lt_where) INTO @rv.
      CATCH cx_sy_dynamic_osql_error cx_sy_open_sql_db INTO DATA(lx).
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '014' iv_msgv1 = lx->get_text( ) io_previous = lx ).
    ENDTRY.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_db~read_single.
    DATA(lv_entity) = validated_entity( iv_entity ).
    DATA(lt_where)  = keys_to_where( iv_entity = lv_entity it_keys = it_keys ).

    TRY.
        SELECT SINGLE * FROM (lv_entity) WHERE (lt_where)
          INTO CORRESPONDING FIELDS OF @es_row.
      CATCH cx_sy_dynamic_osql_error cx_sy_open_sql_db INTO DATA(lx).
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '014' iv_msgv1 = lx->get_text( ) io_previous = lx ).
    ENDTRY.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_db~describe.
    TYPES: BEGIN OF ty_meta,
             position  TYPE i,
             field     TYPE string,
             type_kind TYPE abap_typekind,
             length    TYPE i,
             decimals  TYPE i,
           END OF ty_meta.

    DATA lo_type TYPE REF TO cl_abap_typedescr.
    TRY.
        lo_type = cl_abap_typedescr=>describe_by_name( validated_entity( iv_entity ) ).
      CATCH cx_root INTO DATA(lx).
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '019' iv_msgv1 = 'entity' iv_msgv2 = iv_entity io_previous = lx ) ##NO_TEXT.
    ENDTRY.

    DATA(lo_struct) = CAST cl_abap_structdescr( lo_type ).

    DATA lt_meta TYPE STANDARD TABLE OF ty_meta WITH EMPTY KEY.
    DATA(lv_pos) = 0.
    LOOP AT lo_struct->components INTO DATA(ls_c).
      lv_pos = lv_pos + 1.
      APPEND VALUE #( position  = lv_pos
                      field     = ls_c-name
                      type_kind = ls_c-type_kind
                      length    = ls_c-length
                      decimals  = ls_c-decimals ) TO lt_meta.
    ENDLOOP.

    DATA lr TYPE REF TO data.
    CREATE DATA lr TYPE STANDARD TABLE OF ty_meta.
    ASSIGN lr->* TO FIELD-SYMBOL(<t>).
    <t> = lt_meta.
    rr_meta = lr.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_db~where_from_ranges.
    LOOP AT it_ranges INTO DATA(ls).
      DATA(lv_val) = replace( val = ls-value sub = `'` with = `''` occ = 0 ).
      APPEND |{ to_upper( ls-name ) } = '{ lv_val }'| TO rt.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
