"! <p class="shorttext synchronized">ZCL_AB_V1_UT: ALV / output (SAP GUI)</p>
"! RAP-mode: all methods are GUI. Implemented only by ZCL_AB_V1_UT_GUI.
"! Never callable from RAP. Fiori equivalent = CDS UI annotations.
INTERFACE zif_ab_v1_ut_alv
  PUBLIC.

  METHODS show
    IMPORTING iv_title   TYPE csequence OPTIONAL
              iv_variant TYPE slis_vari OPTIONAL
    CHANGING  ct_table   TYPE STANDARD TABLE
    RAISING   zcx_ab_v1_ut.

  METHODS show_dynamic
    IMPORTING ir_table  TYPE REF TO data
              iv_title  TYPE csequence OPTIONAL
    RAISING   zcx_ab_v1_ut.

  METHODS build_fieldcat
    IMPORTING io_table_type  TYPE REF TO cl_abap_tabledescr
    RETURNING VALUE(rt_fcat) TYPE lvc_t_fcat
    RAISING   zcx_ab_v1_ut.

ENDINTERFACE.
