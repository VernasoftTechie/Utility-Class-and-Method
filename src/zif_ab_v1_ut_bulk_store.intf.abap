"! <p class="shorttext synchronized">ZCL_AB_V1_UT: bulk checkpoint persistence</p>
"! Implemented by the caller (own DB table / SHM). ZCL_AB_V1_UT_BULK_STORE_MEM is the
"! in-memory default used when no store is supplied.
INTERFACE zif_ab_v1_ut_bulk_store
  PUBLIC.

  METHODS save
    IMPORTING iv_run_id     TYPE string
              iv_checkpoint TYPE string
              iv_processed  TYPE i
    RAISING   zcx_ab_v1_ut.

  METHODS load
    IMPORTING iv_run_id     TYPE string
    EXPORTING ev_checkpoint TYPE string
              ev_processed  TYPE i
              ev_found      TYPE abap_bool
    RAISING   zcx_ab_v1_ut.

  METHODS delete
    IMPORTING iv_run_id TYPE string
    RAISING   zcx_ab_v1_ut.

ENDINTERFACE.
