"! <p class="shorttext synchronized">ZCL_AB_V1_UT: bulk per-package work handler</p>
"! Implemented by the caller. process_package receives a REF TO a table slice with the
"! same line type as the key table passed to ZIF_AB_V1_UT_BULK~run_packaged.
"! For run_parallel the implementing class must be stateless (it is instantiated fresh
"! in each work process).
INTERFACE zif_ab_v1_ut_bulk_handler
  PUBLIC.

  METHODS process_package
    IMPORTING ir_keys           TYPE REF TO data
    RETURNING VALUE(rt_messages) TYPE bapiret2_t
    RAISING   zcx_ab_v1_ut.

ENDINTERFACE.
