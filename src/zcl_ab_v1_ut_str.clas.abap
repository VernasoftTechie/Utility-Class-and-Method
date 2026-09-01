CLASS zcl_ab_v1_ut_str DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ab_v1_ut_str.
  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS normalize_number
      IMPORTING iv_text     TYPE string
                iv_notation TYPE zif_ab_v1_ut_str=>ty_notation
      RETURNING VALUE(rv)   TYPE string
      RAISING   zcx_ab_v1_ut.
    METHODS group_thousands
      IMPORTING iv_value  TYPE string
                iv_sep    TYPE c
      RETURNING VALUE(rv) TYPE string.
ENDCLASS.



CLASS zcl_ab_v1_ut_str IMPLEMENTATION.

  METHOD normalize_number.
    DATA(lv_txt) = condense( replace( val = iv_text sub = ` ` with = `` occ = 0 ) ).
    DATA lv_sign TYPE string.

    " trailing / leading minus, or parentheses
    IF lv_txt CS '-' OR lv_txt CS '(' .
      lv_sign = '-'.
    ENDIF.
    lv_txt = replace( val = lv_txt pcre = `[()\-+]` with = `` occ = 0 ).

    CASE iv_notation.
      WHEN zif_ab_v1_ut_str=>c_notation-eu.
        lv_txt = replace( val = lv_txt sub = `.` with = `` occ = 0 ).
        lv_txt = replace( val = lv_txt sub = `,` with = `.` occ = 0 ).
      WHEN zif_ab_v1_ut_str=>c_notation-us.
        lv_txt = replace( val = lv_txt sub = `,` with = `` occ = 0 ).
      WHEN OTHERS.
        lv_txt = replace( val = lv_txt sub = `,` with = `` occ = 0 ).
    ENDCASE.

    IF lv_txt IS INITIAL OR NOT matches( val = lv_txt pcre = `^\d*(\.\d+)?$` ).
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '008' iv_msgv1 = iv_text ).
    ENDIF.

    rv = |{ lv_sign }{ lv_txt }|.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_str~to_amount.
    DATA(lv_norm) = normalize_number( iv_text = iv_text iv_notation = iv_notation ).
    TRY.
        rv_amount = CONV decfloat34( lv_norm ).
      CATCH cx_sy_conversion_error INTO DATA(lx).
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '008' iv_msgv1 = iv_text io_previous = lx ).
    ENDTRY.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_str~from_amount.
    DATA(lv_dec) = 2.
    IF iv_currency IS NOT INITIAL.
      SELECT SINGLE currdec FROM tcurx INTO @lv_dec WHERE currkey = @iv_currency.
      IF sy-subrc <> 0.
        lv_dec = 2.
      ENDIF.
    ENDIF.

    DATA(lv_raw) = |{ CONV decfloat34( iv_amount ) DECIMALS = lv_dec SIGN = LEFT }|.
    lv_raw = condense( lv_raw ).
    " lv_raw uses '.' as decimal separator, no grouping
    SPLIT lv_raw AT '.' INTO DATA(lv_int) DATA(lv_frac).

    CASE iv_notation.
      WHEN zif_ab_v1_ut_str=>c_notation-eu.
        rv_text = COND #( WHEN lv_frac IS INITIAL THEN lv_int ELSE |{ lv_int },{ lv_frac }| ).
        rv_text = group_thousands( iv_value = rv_text iv_sep = '.' ).
      WHEN zif_ab_v1_ut_str=>c_notation-us.
        rv_text = COND #( WHEN lv_frac IS INITIAL THEN lv_int ELSE |{ lv_int }.{ lv_frac }| ).
        rv_text = group_thousands( iv_value = rv_text iv_sep = ',' ).
      WHEN OTHERS.
        rv_text = lv_raw.
    ENDCASE.
  ENDMETHOD.


  METHOD group_thousands.
    " helper: group the integer part of "123456,78" / "123456.78" style strings
    DATA lv_dec_sep TYPE c LENGTH 1.
    lv_dec_sep = COND #( WHEN iv_sep = '.' THEN ',' ELSE '.' ).

    SPLIT iv_value AT lv_dec_sep INTO DATA(lv_int) DATA(lv_frac).
    DATA(lv_neg) = xsdbool( lv_int CS '-' ).
    lv_int = replace( val = lv_int sub = '-' with = '' occ = 0 ).

    DATA lv_out TYPE string.
    DATA(lv_len) = strlen( lv_int ).
    DATA(lv_i)   = lv_len.
    DATA(lv_cnt) = 0.
    WHILE lv_i > 0.
      lv_i = lv_i - 1.
      lv_out = |{ lv_int+lv_i(1) }{ lv_out }|.
      lv_cnt = lv_cnt + 1.
      IF lv_cnt = 3 AND lv_i > 0.
        lv_out = |{ iv_sep }{ lv_out }|.
        lv_cnt = 0.
      ENDIF.
    ENDWHILE.

    rv = COND #( WHEN lv_frac IS INITIAL THEN lv_out ELSE |{ lv_out }{ lv_dec_sep }{ lv_frac }| ).
    IF lv_neg = abap_true.
      rv = |-{ rv }|.
    ENDIF.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_str~to_quantity.
    DATA(lv_norm) = normalize_number( iv_text = iv_text iv_notation = zif_ab_v1_ut_str=>c_notation-raw ).
    TRY.
        rv_qty = CONV decfloat34( lv_norm ).
      CATCH cx_sy_conversion_error INTO DATA(lx).
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '008' iv_msgv1 = iv_text io_previous = lx ).
    ENDTRY.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_str~from_quantity.
    rv_text = |{ CONV decfloat34( iv_qty ) DECIMALS = 3 }|.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_str~to_date.
    DATA lv_d TYPE d.
    DATA(lv_in) = condense( iv_text ).

    IF matches( val = lv_in pcre = `^\d{4}-\d{2}-\d{2}` ).
      lv_d = |{ lv_in+0(4) }{ lv_in+5(2) }{ lv_in+8(2) }|.
    ELSEIF matches( val = lv_in pcre = `^\d{2}[./-]\d{2}[./-]\d{4}$` ).
      lv_d = |{ lv_in+6(4) }{ lv_in+3(2) }{ lv_in+0(2) }|.
    ELSEIF matches( val = lv_in pcre = `^\d{8}$` ).
      lv_d = lv_in.
    ELSE.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '008' iv_msgv1 = iv_text ).
    ENDIF.

    CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
      EXPORTING  date                     = lv_d
      EXCEPTIONS plausibility_check_failed = 1
                 OTHERS                    = 2.
    IF sy-subrc <> 0.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '008' iv_msgv1 = iv_text ).
    ENDIF.
    rv_date = lv_d.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_str~from_date.
    IF iv_format IS INITIAL.
      rv_text = |{ iv_date DATE = USER }|.
    ELSEIF iv_format = 'ISO'.
      rv_text = |{ iv_date+0(4) }-{ iv_date+4(2) }-{ iv_date+6(2) }|.
    ELSE.
      rv_text = |{ iv_date DATE = ENVIRONMENT }|.
    ENDIF.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_str~to_time.
    DATA(lv_in) = replace( val = condense( iv_text ) pcre = `[:\.]` with = `` occ = 0 ).
    IF strlen( lv_in ) = 4.
      lv_in = |{ lv_in }00|.
    ENDIF.
    IF NOT matches( val = lv_in pcre = `^\d{6}$` ).
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '008' iv_msgv1 = iv_text ).
    ENDIF.
    rv_time = lv_in.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_str~from_time.
    rv_text = COND #( WHEN iv_with_seconds = abap_true
                      THEN |{ iv_time+0(2) }:{ iv_time+2(2) }:{ iv_time+4(2) }|
                      ELSE |{ iv_time+0(2) }:{ iv_time+2(2) }| ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_str~alpha_in.
    rv = |{ iv_value ALPHA = IN }|.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_str~alpha_out.
    rv = |{ iv_value ALPHA = OUT }|.
    rv = condense( rv ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_str~pad.
    DATA(lv_val) = |{ iv_value }|.
    IF strlen( lv_val ) >= iv_len.
      rv = lv_val.
      RETURN.
    ENDIF.
    DATA(lv_fill) = repeat( val = iv_char occ = iv_len - strlen( lv_val ) ).
    rv = COND #( WHEN iv_side = 'R' THEN |{ lv_val }{ lv_fill }| ELSE |{ lv_fill }{ lv_val }| ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_str~mask.
    DATA(lv_val) = |{ iv_value }|.
    DATA(lv_len) = strlen( lv_val ).
    IF lv_len <= iv_visible_prefix + iv_visible_suffix.
      rv = lv_val.
      RETURN.
    ENDIF.
    DATA(lv_hidden) = lv_len - iv_visible_prefix - iv_visible_suffix.
    rv = |{ lv_val+0(iv_visible_prefix) }{ repeat( val = iv_char occ = lv_hidden ) }| &&
         |{ substring( val = lv_val off = lv_len - iv_visible_suffix len = iv_visible_suffix ) }|.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_str~split.
    SPLIT iv_value AT iv_sep INTO TABLE DATA(lt).
    LOOP AT lt INTO DATA(lv).
      APPEND COND #( WHEN iv_trim = abap_true THEN condense( lv ) ELSE lv ) TO rt.
    ENDLOOP.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_str~join.
    rv = concat_lines_of( table = it_values sep = iv_sep ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_str~to_camel.
    SPLIT to_lower( iv_value ) AT `_` INTO TABLE DATA(lt).
    LOOP AT lt INTO DATA(lv) FROM 2.
      lv = |{ to_upper( lv+0(1) ) }{ lv+1 }|.
      MODIFY lt FROM lv.
    ENDLOOP.
    rv = concat_lines_of( table = lt ).
    IF iv_pascal = abap_true AND rv IS NOT INITIAL.
      rv = |{ to_upper( rv+0(1) ) }{ rv+1 }|.
    ENDIF.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_str~to_snake.
    DATA(lv) = replace( val = iv_value pcre = `([a-z0-9])([A-Z])` with = `$1_$2` occ = 0 ).
    rv = to_lower( lv ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_str~base64_encode.
    rv = cl_web_http_utility=>encode_x_base64( iv_data ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_str~base64_decode.
    rv = cl_web_http_utility=>decode_x_base64( iv_b64 ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_str~to_xstring.
    TRY.
        DATA(lo) = COND #( WHEN iv_codepage IS INITIAL
                           THEN cl_abap_conv_codepage=>create_out( )
                           ELSE cl_abap_conv_codepage=>create_out( codepage = iv_codepage ) ).
        rv = lo->convert( iv_string ).
      CATCH cx_root INTO DATA(lx).
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '020' iv_msgv1 = 'string' iv_msgv2 = 'xstring' io_previous = lx ).
    ENDTRY.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_str~from_xstring.
    TRY.
        DATA(lo) = COND #( WHEN iv_codepage IS INITIAL
                           THEN cl_abap_conv_codepage=>create_in( )
                           ELSE cl_abap_conv_codepage=>create_in( codepage = iv_codepage ) ).
        rv = lo->convert( iv_xstring ).
      CATCH cx_root INTO DATA(lx).
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '020' iv_msgv1 = 'xstring' iv_msgv2 = 'string' io_previous = lx ).
    ENDTRY.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_str~hash.
    TRY.
        DATA(lv_x) = zif_ab_v1_ut_str~to_xstring( iv_data ).
        DATA lv_hash TYPE string.
        cl_abap_message_digest=>calculate_hash_for_raw(
          EXPORTING if_algorithm  = CONV #( iv_algo )
                    if_data       = lv_x
          IMPORTING ef_hashstring = lv_hash ).
        rv_hex = to_lower( lv_hash ).
      CATCH cx_abap_message_digest INTO DATA(lx).
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '020' iv_msgv1 = iv_algo iv_msgv2 = 'hash' io_previous = lx ).
    ENDTRY.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_str~regex_match.
    rv = xsdbool( matches( val = iv_value pcre = iv_pattern ) ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_str~regex_replace.
    rv = replace( val = iv_value pcre = iv_pattern with = iv_with occ = 0 ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_str~regex_groups.
    FIND FIRST OCCURRENCE OF PCRE iv_pattern IN iv_value RESULTS DATA(ls_res).
    LOOP AT ls_res-submatches INTO DATA(ls_sub).
      IF ls_sub-offset >= 0 AND ls_sub-length >= 0.
        APPEND substring( val = iv_value off = ls_sub-offset len = ls_sub-length ) TO rt.
      ELSE.
        APPEND `` TO rt.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_str~amount_in_words.
    DATA lv_word TYPE spell.
    DATA lv_amt  TYPE p LENGTH 15 DECIMALS 2.
    lv_amt = iv_amount.
    CALL FUNCTION 'SPELL_AMOUNT'
      EXPORTING amount    = lv_amt
                currency  = iv_currency
                language  = sy-langu
      IMPORTING in_words  = lv_word
      EXCEPTIONS not_found = 1 too_large = 2 OTHERS = 3.
    IF sy-subrc <> 0.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '020' iv_msgv1 = 'amount' iv_msgv2 = 'words' ).
    ENDIF.
    rv = condense( |{ lv_word-word } { lv_word-decword }| ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_str~is_valid.
    DATA lv_pattern TYPE string.
    CASE to_upper( iv_kind ).
      WHEN zif_ab_v1_ut_str=>c_kind-email.
        lv_pattern = `^[\w.+-]+@[\w-]+\.[\w.-]+$`.
      WHEN zif_ab_v1_ut_str=>c_kind-phone.
        lv_pattern = `^\+?[0-9 ()-]{6,20}$`.
      WHEN zif_ab_v1_ut_str=>c_kind-iban.
        lv_pattern = `^[A-Z]{2}[0-9]{2}[A-Z0-9]{11,30}$`.
      WHEN zif_ab_v1_ut_str=>c_kind-pan.
        lv_pattern = `^[A-Z]{5}[0-9]{4}[A-Z]$`.
      WHEN zif_ab_v1_ut_str=>c_kind-gstin.
        lv_pattern = `^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][0-9A-Z]{3}$`.
      WHEN OTHERS.
        rv = abap_false.
        RETURN.
    ENDCASE.
    rv = xsdbool( matches( val = to_upper( condense( iv_value ) ) pcre = lv_pattern ) ).
  ENDMETHOD.

ENDCLASS.
