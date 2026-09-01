CLASS zcl_ab_v1_ut_conv DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ab_v1_ut_conv.
  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS last_day_of_month
      IMPORTING iv_year   TYPE i
                iv_month  TYPE i
      RETURNING VALUE(rv) TYPE d.
ENDCLASS.



CLASS zcl_ab_v1_ut_conv IMPLEMENTATION.

  METHOD last_day_of_month.
    DATA(lv_ny) = COND i( WHEN iv_month = 12 THEN iv_year + 1 ELSE iv_year ).
    DATA(lv_nm) = COND i( WHEN iv_month = 12 THEN 1 ELSE iv_month + 1 ).
    DATA(lv_first_next) = CONV d( |{ lv_ny WIDTH = 4 ALIGN = RIGHT PAD = '0' }| &&
                                 |{ lv_nm WIDTH = 2 ALIGN = RIGHT PAD = '0' }01| ).
    rv = lv_first_next - 1.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_conv~add_days.
    rv = iv_date + iv_days.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_conv~add_months.
    DATA: lv_y TYPE i,
          lv_m TYPE i,
          lv_d TYPE i.
    lv_y = iv_date+0(4).
    lv_m = iv_date+4(2).
    lv_d = iv_date+6(2).

    DATA(lv_tot) = ( lv_y * 12 ) + ( lv_m - 1 ) + iv_months.
    lv_y = lv_tot DIV 12.
    lv_m = ( lv_tot MOD 12 ) + 1.

    DATA(lv_ld)   = last_day_of_month( iv_year = lv_y iv_month = lv_m ).
    DATA(lv_last) = CONV i( lv_ld+6(2) ).
    IF lv_d > lv_last.
      lv_d = lv_last.
    ENDIF.

    rv = |{ lv_y WIDTH = 4 ALIGN = RIGHT PAD = '0' }| &&
         |{ lv_m WIDTH = 2 ALIGN = RIGHT PAD = '0' }| &&
         |{ lv_d WIDTH = 2 ALIGN = RIGHT PAD = '0' }|.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_conv~add_years.
    rv = zif_ab_v1_ut_conv~add_months( iv_date = iv_date iv_months = iv_years * 12 ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_conv~add_workdays.
    DATA: lv_factory TYPE scal-facdate,
          lv_ind     TYPE scal-indicator.

    CALL FUNCTION 'DATE_CONVERT_TO_FACTORYDATE'
      EXPORTING  date                       = iv_date
                 factory_calendar_id        = iv_calendar_id
      IMPORTING  factorydate                = lv_factory
                 workingday_indicator       = lv_ind
      EXCEPTIONS calendar_buffer_not_loadable = 1
                 date_after_range           = 2
                 date_before_range          = 3
                 date_invalid               = 4
                 factory_calendar_not_found = 5
                 OTHERS                     = 6.
    IF sy-subrc <> 0.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '020' iv_msgv1 = |{ iv_date }| iv_msgv2 = |calendar { iv_calendar_id }| ).
    ENDIF.

    lv_factory = lv_factory + iv_days.

    CALL FUNCTION 'FACTORYDATE_CONVERT_TO_DATE'
      EXPORTING  factorydate                = lv_factory
                 factory_calendar_id        = iv_calendar_id
      IMPORTING  date                       = rv
      EXCEPTIONS factorydate_after_range    = 1
                 factorydate_before_range   = 2
                 factory_calendar_not_found = 3
                 OTHERS                     = 4.
    IF sy-subrc <> 0.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '016' iv_msgv1 = |factorydate| iv_msgv2 = |{ lv_factory }| ).
    ENDIF.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_conv~is_workday.
    DATA: lv_factory TYPE scal-facdate,
          lv_ind     TYPE scal-indicator.

    CALL FUNCTION 'DATE_CONVERT_TO_FACTORYDATE'
      EXPORTING  date                 = iv_date
                 factory_calendar_id  = iv_calendar_id
      IMPORTING  factorydate          = lv_factory
                 workingday_indicator = lv_ind
      EXCEPTIONS OTHERS               = 1.
    IF sy-subrc <> 0.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '020' iv_msgv1 = |{ iv_date }| iv_msgv2 = |calendar { iv_calendar_id }| ).
    ENDIF.
    rv = xsdbool( lv_ind IS INITIAL ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_conv~days_between.
    rv = iv_to - iv_from.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_conv~months_between.
    DATA(lv_fy) = CONV i( iv_from+0(4) ).
    DATA(lv_fm) = CONV i( iv_from+4(2) ).
    DATA(lv_ty) = CONV i( iv_to+0(4) ).
    DATA(lv_tm) = CONV i( iv_to+4(2) ).
    rv = ( lv_ty * 12 + lv_tm ) - ( lv_fy * 12 + lv_fm ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_conv~years_between.
    rv = zif_ab_v1_ut_conv~months_between( iv_from = iv_from iv_to = iv_to ) DIV 12.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_conv~age.
    DATA(lv_on) = COND d( WHEN iv_on IS INITIAL THEN sy-datum ELSE iv_on ).
    rv = CONV i( lv_on+0(4) ) - CONV i( iv_dob+0(4) ).
    IF lv_on+4(4) < iv_dob+4(4).
      rv = rv - 1.
    ENDIF.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_conv~period_bounds.
    DATA(lv_y) = CONV i( iv_date+0(4) ).
    DATA(lv_m) = CONV i( iv_date+4(2) ).

    CASE to_upper( iv_kind ).
      WHEN zif_ab_v1_ut_conv~c_period-week.
        DATA lv_dow TYPE p.
        CALL FUNCTION 'DATE_COMPUTE_DAY'
          EXPORTING date = iv_date
          IMPORTING day  = lv_dow.
        ev_first = iv_date - ( lv_dow - 1 ).
        ev_last  = ev_first + 6.

      WHEN zif_ab_v1_ut_conv~c_period-month.
        ev_first = |{ iv_date+0(6) }01|.
        ev_last  = last_day_of_month( iv_year = lv_y iv_month = lv_m ).

      WHEN zif_ab_v1_ut_conv~c_period-quarter.
        DATA(lv_qm) = ( ( lv_m - 1 ) DIV 3 ) * 3 + 1.
        ev_first = |{ lv_y WIDTH = 4 ALIGN = RIGHT PAD = '0' }{ lv_qm WIDTH = 2 ALIGN = RIGHT PAD = '0' }01|.
        ev_last  = last_day_of_month( iv_year = lv_y iv_month = lv_qm + 2 ).

      WHEN zif_ab_v1_ut_conv~c_period-fyear.
        IF iv_fiscal_variant IS INITIAL.
          ev_first = |{ iv_date+0(4) }0101|.
          ev_last  = |{ iv_date+0(4) }1231|.
        ELSE.
          DATA: lv_gjahr TYPE bkpf-gjahr,
                lv_poper TYPE t009b-poper.
          CALL FUNCTION 'DATE_TO_PERIOD_CONVERT'
            EXPORTING  i_date               = iv_date
                       i_periv              = iv_fiscal_variant
            IMPORTING  e_buper              = lv_poper
                       e_gjahr              = lv_gjahr
            EXCEPTIONS input_false          = 1
                       t009_notfound        = 2
                       t009b_notfound       = 3
                       OTHERS               = 4.
          IF sy-subrc <> 0.
            zcx_ab_v1_ut=>raise_t100( iv_msgno = '008' iv_msgv1 = |fiscal variant { iv_fiscal_variant }| ).
          ENDIF.
          CALL FUNCTION 'FIRST_DAY_IN_PERIOD_GET'
            EXPORTING i_gjahr = lv_gjahr i_periv = iv_fiscal_variant i_poper = '001'
            IMPORTING e_date  = ev_first
            EXCEPTIONS OTHERS = 1.
          CALL FUNCTION 'LAST_DAY_IN_PERIOD_GET'
            EXPORTING i_gjahr = lv_gjahr i_periv = iv_fiscal_variant i_poper = '012'
            IMPORTING e_date  = ev_last
            EXCEPTIONS OTHERS = 1.
        ENDIF.

      WHEN OTHERS.
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '008' iv_msgv1 = iv_kind ).
    ENDCASE.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_conv~week_number.
    DATA lv_week TYPE scal-week.
    CALL FUNCTION 'DATE_GET_WEEK'
      EXPORTING  date         = iv_date
      IMPORTING  week         = lv_week
      EXCEPTIONS date_invalid = 1
                 OTHERS       = 2.
    rv = lv_week.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_conv~weekday.
    DATA lv_dow TYPE p.
    CALL FUNCTION 'DATE_COMPUTE_DAY'
      EXPORTING date = iv_date
      IMPORTING day  = lv_dow.
    rv = lv_dow.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_conv~tz_to_local.
    CONVERT TIME STAMP iv_timestamp TIME ZONE iv_tzone
      INTO DATE ev_date TIME ev_time.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_conv~tz_from_local.
    CONVERT DATE iv_date TIME iv_time
      INTO TIME STAMP rv TIME ZONE iv_tzone.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_conv~ts_split.
    DATA lv_short TYPE timestamp.
    lv_short = trunc( iv_ts ).
    CONVERT TIME STAMP lv_short TIME ZONE 'UTC   '
      INTO DATE ev_date TIME ev_time.
    ev_msec = ( iv_ts - trunc( iv_ts ) ) * 1000.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_conv~ts_merge.
    DATA lv_ts TYPE timestamp.
    CONVERT DATE iv_date TIME iv_time
      INTO TIME STAMP lv_ts TIME ZONE 'UTC   '.
    rv = lv_ts + ( iv_msec / 1000 ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_conv~convert_currency.
    CALL FUNCTION 'CONVERT_TO_LOCAL_CURRENCY'
      EXPORTING  date             = iv_date
                 foreign_amount   = iv_amount
                 foreign_currency = iv_from
                 local_currency   = iv_to
                 type_of_rate     = iv_rate_type
      IMPORTING  exchange_rate    = ev_rate
                 local_amount     = ev_amount
      EXCEPTIONS no_rate_found    = 1
                 overflow         = 2
                 no_factors_found = 3
                 no_spread_found  = 4
                 derived_2_times  = 5
                 OTHERS           = 6.
    IF sy-subrc <> 0.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '020' iv_msgv1 = |{ iv_from }| iv_msgv2 = |{ iv_to }| ).
    ENDIF.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_conv~convert_unit.
    CALL FUNCTION 'UNIT_CONVERSION_SIMPLE'
      EXPORTING  input                = iv_qty
                 unit_in              = iv_from
                 unit_out             = iv_to
      IMPORTING  output               = rv
      EXCEPTIONS conversion_not_found = 1
                 division_by_zero     = 2
                 input_invalid        = 3
                 output_invalid       = 4
                 overflow             = 5
                 type_invalid         = 6
                 units_missing        = 7
                 unit_in_not_found    = 8
                 unit_out_not_found   = 9
                 OTHERS               = 10.
    IF sy-subrc <> 0.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '020' iv_msgv1 = |{ iv_from }| iv_msgv2 = |{ iv_to }| ).
    ENDIF.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_conv~round.
    DATA(lv_mode) = SWITCH i( to_upper( iv_mode )
                              WHEN 'UP'   THEN cl_abap_math=>round_up
                              WHEN 'DOWN' THEN cl_abap_math=>round_down
                              ELSE cl_abap_math=>round_half_up ).
    rv = round( val = iv_value dec = iv_decimals mode = lv_mode ).
  ENDMETHOD.

ENDCLASS.
