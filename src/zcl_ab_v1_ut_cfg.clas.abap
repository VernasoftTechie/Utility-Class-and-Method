CLASS zcl_ab_v1_ut_cfg DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ab_v1_ut_cfg.
  PROTECTED SECTION.
  PRIVATE SECTION.
    CONSTANTS c_true_values TYPE string VALUE 'X|TRUE|1|ON|YES|J'.
ENDCLASS.



CLASS zcl_ab_v1_ut_cfg IMPLEMENTATION.

  METHOD zif_ab_v1_ut_cfg~tvarv_value.
    SELECT SINGLE low FROM tvarvc
      INTO @rv
      WHERE name = @iv_name
        AND type = 'P'.
    IF sy-subrc <> 0.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '018' iv_msgv1 = |{ iv_name }| ).
    ENDIF.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_cfg~tvarv_range.
    SELECT sign, opti, low, high FROM tvarvc
      WHERE name = @iv_name
        AND type = 'S'
      ORDER BY numb
      INTO TABLE @DATA(lt).

    LOOP AT lt INTO DATA(ls).
      APPEND INITIAL LINE TO et_range ASSIGNING FIELD-SYMBOL(<r>).
      ASSIGN COMPONENT 'SIGN'   OF STRUCTURE <r> TO FIELD-SYMBOL(<f>).
      IF sy-subrc = 0.
        <f> = ls-sign.
      ENDIF.
      ASSIGN COMPONENT 'OPTION' OF STRUCTURE <r> TO <f>.
      IF sy-subrc = 0.
        <f> = ls-opti.
      ENDIF.
      ASSIGN COMPONENT 'LOW'    OF STRUCTURE <r> TO <f>.
      IF sy-subrc = 0.
        <f> = ls-low.
      ENDIF.
      ASSIGN COMPONENT 'HIGH'   OF STRUCTURE <r> TO <f>.
      IF sy-subrc = 0.
        <f> = ls-high.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_cfg~is_feature_on.
    TRY.
        DATA(lv) = to_upper( zif_ab_v1_ut_cfg~tvarv_value( CONV #( iv_feature ) ) ).
        rv = xsdbool( |{ c_true_values }| CS lv AND lv IS NOT INITIAL ).
      CATCH zcx_ab_v1_ut.
        rv = abap_false.
    ENDTRY.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_cfg~read_config.
    DATA lv_where TYPE string.
    LOOP AT it_keys INTO DATA(ls_k).
      DATA(lv_val) = replace( val = ls_k-value sub = `'` with = `''` occ = 0 ).
      lv_where = COND #( WHEN lv_where IS INITIAL
                         THEN |{ to_upper( ls_k-name ) } = '{ lv_val }'|
                         ELSE |{ lv_where } AND { to_upper( ls_k-name ) } = '{ lv_val }'| ).
    ENDLOOP.

    TRY.
        IF lv_where IS INITIAL.
          SELECT * FROM (iv_table) INTO CORRESPONDING FIELDS OF TABLE @et_rows.
        ELSE.
          SELECT * FROM (iv_table) WHERE (lv_where) INTO CORRESPONDING FIELDS OF TABLE @et_rows.
        ENDIF.
      CATCH cx_sy_dynamic_osql_error INTO DATA(lx).
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '019' iv_msgv1 = 'table' iv_msgv2 = |{ iv_table }| io_previous = lx ).
    ENDTRY.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_cfg~enum_values.
    SELECT domvalue_l AS name, ddtext AS value
      FROM dd07v
      WHERE domname    = @iv_domain
        AND ddlanguage = @sy-langu
      ORDER BY valpos
      INTO TABLE @DATA(lt).

    IF lt IS INITIAL.
      SELECT domvalue_l AS name, ddtext AS value
        FROM dd07v
        WHERE domname    = @iv_domain
          AND ddlanguage = 'E'
        ORDER BY valpos
        INTO TABLE @lt.
    ENDIF.

    IF lt IS INITIAL.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '019' iv_msgv1 = 'domain' iv_msgv2 = |{ iv_domain }| ).
    ENDIF.

    rt = VALUE #( FOR ls IN lt ( name = ls-name value = ls-value ) ).
  ENDMETHOD.

ENDCLASS.
