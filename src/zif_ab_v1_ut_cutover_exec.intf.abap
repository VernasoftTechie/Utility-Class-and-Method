"! <p class="shorttext synchronized">ZCL_AB_V1_UT: cutover task executor</p>
"! Implemented by the caller. ZIF_AB_V1_UT_CUTOVER~task_run calls run_task per task name.
INTERFACE zif_ab_v1_ut_cutover_exec
  PUBLIC.

  METHODS run_task
    IMPORTING iv_name TYPE string
    RAISING   zcx_ab_v1_ut.

ENDINTERFACE.
