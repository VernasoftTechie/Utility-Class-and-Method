"! <p class="shorttext synchronized">ZCL_AB_V1_UT: system / environment</p>
"! RAP-mode: all methods are Core.
INTERFACE zif_ab_v1_ut_sys
  PUBLIC.

  TYPES:
    BEGIN OF ty_system,
      sysid          TYPE sy-sysid,
      client         TYPE sy-mandt,
      client_role    TYPE cccategory,
      install_number TYPE string,
      is_production  TYPE abap_bool,
      host           TYPE string,
    END OF ty_system.

  METHODS system_info
    RETURNING VALUE(rs) TYPE ty_system.

  METHODS object_exists
    IMPORTING iv_type   TYPE string
              iv_name   TYPE string
    RETURNING VALUE(rv) TYPE abap_bool.

  METHODS timer_start
    RETURNING VALUE(rv_handle) TYPE string.

  METHODS timer_stop
    IMPORTING iv_handle  TYPE string
    EXPORTING ev_seconds TYPE decfloat34
              ev_cpu_ms  TYPE decfloat34.

ENDINTERFACE.
