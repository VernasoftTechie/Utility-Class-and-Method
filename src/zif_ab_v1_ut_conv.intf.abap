"! <p class="shorttext synchronized">ZCL_AB_V1_UT: date / time / number / currency / unit</p>
"! RAP-mode: all methods are Core.
INTERFACE zif_ab_v1_ut_conv
  PUBLIC.

  CONSTANTS:
    BEGIN OF c_period,
      week    TYPE string VALUE 'WEEK',
      month   TYPE string VALUE 'MONTH',
      quarter TYPE string VALUE 'QUARTER',
      fyear   TYPE string VALUE 'FYEAR',
    END OF c_period.
  CONSTANTS:
    BEGIN OF c_round,
      commercial TYPE string VALUE 'COMMERCIAL',
      up         TYPE string VALUE 'UP',
      down       TYPE string VALUE 'DOWN',
    END OF c_round.

  METHODS add_days
    IMPORTING iv_date TYPE d iv_days TYPE i
    RETURNING VALUE(rv) TYPE d.

  METHODS add_months
    IMPORTING iv_date TYPE d iv_months TYPE i
    RETURNING VALUE(rv) TYPE d.

  METHODS add_years
    IMPORTING iv_date TYPE d iv_years TYPE i
    RETURNING VALUE(rv) TYPE d.

  METHODS add_workdays
    IMPORTING iv_date        TYPE d
              iv_days        TYPE i
              iv_calendar_id TYPE scal-fcalid
    RETURNING VALUE(rv)      TYPE d
    RAISING   zcx_ab_v1_ut.

  METHODS is_workday
    IMPORTING iv_date        TYPE d
              iv_calendar_id TYPE scal-fcalid
    RETURNING VALUE(rv)      TYPE abap_bool
    RAISING   zcx_ab_v1_ut.

  METHODS days_between
    IMPORTING iv_from TYPE d iv_to TYPE d
    RETURNING VALUE(rv) TYPE i.

  METHODS months_between
    IMPORTING iv_from TYPE d iv_to TYPE d
    RETURNING VALUE(rv) TYPE i.

  METHODS years_between
    IMPORTING iv_from TYPE d iv_to TYPE d
    RETURNING VALUE(rv) TYPE i.

  METHODS age
    IMPORTING iv_dob TYPE d iv_on TYPE d OPTIONAL
    RETURNING VALUE(rv) TYPE i.

  METHODS period_bounds
    IMPORTING iv_date           TYPE d
              iv_kind           TYPE string
              iv_fiscal_variant TYPE periv OPTIONAL
    EXPORTING ev_first          TYPE d
              ev_last           TYPE d
    RAISING   zcx_ab_v1_ut.

  METHODS week_number
    IMPORTING iv_date   TYPE d
    RETURNING VALUE(rv) TYPE kweek.

  METHODS weekday
    IMPORTING iv_date   TYPE d
    RETURNING VALUE(rv) TYPE i.

  METHODS tz_to_local
    IMPORTING iv_timestamp TYPE timestampl
              iv_tzone     TYPE ttzz-tzone
    EXPORTING ev_date      TYPE d
              ev_time      TYPE t.

  METHODS tz_from_local
    IMPORTING iv_date   TYPE d
              iv_time   TYPE t
              iv_tzone  TYPE ttzz-tzone
    RETURNING VALUE(rv) TYPE timestampl.

  METHODS ts_split
    IMPORTING iv_ts   TYPE timestampl
    EXPORTING ev_date TYPE d
              ev_time TYPE t
              ev_msec TYPE i.

  METHODS ts_merge
    IMPORTING iv_date   TYPE d
              iv_time   TYPE t
              iv_msec   TYPE i DEFAULT 0
    RETURNING VALUE(rv) TYPE timestampl.

  METHODS convert_currency
    IMPORTING iv_amount    TYPE numeric
              iv_from      TYPE waers
              iv_to        TYPE waers
              iv_date      TYPE d DEFAULT sy-datum
              iv_rate_type TYPE kurst DEFAULT 'M'
    EXPORTING ev_amount    TYPE decfloat34
              ev_rate      TYPE f
    RAISING   zcx_ab_v1_ut.

  METHODS convert_unit
    IMPORTING iv_qty      TYPE numeric
              iv_from     TYPE meins
              iv_to       TYPE meins
              iv_material TYPE matnr OPTIONAL
    RETURNING VALUE(rv)   TYPE decfloat34
    RAISING   zcx_ab_v1_ut.

  METHODS round
    IMPORTING iv_value    TYPE numeric
              iv_decimals TYPE i DEFAULT 2
              iv_mode     TYPE string DEFAULT c_round-commercial
    RETURNING VALUE(rv)   TYPE decfloat34.

ENDINTERFACE.
