"! <p class="shorttext synchronized">ZCL_AB_V1_UT: number ranges</p>
"! RAP-mode: next / next_bulk are DEFER (RAP early/late numbering only); status is Core.
"! API: released cl_numberrange_runtime.
INTERFACE zif_ab_v1_ut_num
  PUBLIC.

  "! DEFER
  METHODS next
    IMPORTING iv_object      TYPE nrobj
              iv_interval    TYPE nrnr
              iv_subobject   TYPE nrsobj OPTIONAL
              iv_toyear      TYPE nryear OPTIONAL
    RETURNING VALUE(rv_number) TYPE string
    RAISING   zcx_ab_v1_ut.

  "! DEFER
  METHODS next_bulk
    IMPORTING iv_object       TYPE nrobj
              iv_interval     TYPE nrnr
              iv_count        TYPE i
              iv_subobject    TYPE nrsobj OPTIONAL
    RETURNING VALUE(rt_numbers) TYPE zif_ab_v1_ut_types=>ty_string_tab
    RAISING   zcx_ab_v1_ut.

  METHODS status
    IMPORTING iv_object     TYPE nrobj
              iv_interval   TYPE nrnr
    EXPORTING ev_current    TYPE string
              ev_percentage TYPE decfloat34
    RAISING   zcx_ab_v1_ut.

ENDINTERFACE.
