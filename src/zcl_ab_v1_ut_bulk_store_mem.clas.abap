"! In-memory bulk checkpoint store. Session lifetime. Default when no store is passed.
CLASS zcl_ab_v1_ut_bulk_store_mem DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ab_v1_ut_bulk_store.
    CLASS-METHODS reset.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_row,
             run_id     TYPE string,
             checkpoint TYPE string,
             processed  TYPE i,
           END OF ty_row.
    CLASS-DATA gt_store TYPE HASHED TABLE OF ty_row WITH UNIQUE KEY run_id.
ENDCLASS.



CLASS zcl_ab_v1_ut_bulk_store_mem IMPLEMENTATION.

  METHOD reset.
    CLEAR gt_store.
  ENDMETHOD.

  METHOD zif_ab_v1_ut_bulk_store~save.
    DELETE gt_store WHERE run_id = iv_run_id.
    INSERT VALUE #( run_id     = iv_run_id
                    checkpoint = iv_checkpoint
                    processed  = iv_processed ) INTO TABLE gt_store.
  ENDMETHOD.

  METHOD zif_ab_v1_ut_bulk_store~load.
    CLEAR: ev_checkpoint, ev_processed, ev_found.
    READ TABLE gt_store INTO DATA(ls) WITH KEY run_id = iv_run_id.
    IF sy-subrc = 0.
      ev_checkpoint = ls-checkpoint.
      ev_processed  = ls-processed.
      ev_found      = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD zif_ab_v1_ut_bulk_store~delete.
    DELETE gt_store WHERE run_id = iv_run_id.
  ENDMETHOD.

ENDCLASS.
