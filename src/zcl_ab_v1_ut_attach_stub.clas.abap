"! In-memory attachment adapter. Default for sandbox / unit tests.
CLASS zcl_ab_v1_ut_attach_stub DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ab_v1_ut_attach.
    CLASS-METHODS reset.
  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES: BEGIN OF ty_store,
             id         TYPE string,
             objtype    TYPE swo_objtyp,
             objkey     TYPE swo_typeid,
             filename   TYPE string,
             mimetype   TYPE string,
             content    TYPE xstring,
             created_by TYPE syuname,
             created_at TYPE timestampl,
           END OF ty_store.
    CLASS-DATA gt_store TYPE STANDARD TABLE OF ty_store WITH KEY id.
ENDCLASS.



CLASS zcl_ab_v1_ut_attach_stub IMPLEMENTATION.

  METHOD reset.
    CLEAR gt_store.
  ENDMETHOD.

  METHOD zif_ab_v1_ut_attach~new_guid_x16.
    rv = cl_system_uuid=>create_uuid_x16_static( ).
  ENDMETHOD.

  METHOD zif_ab_v1_ut_attach~new_guid_c32.
    rv = cl_system_uuid=>create_uuid_c32_static( ).
  ENDMETHOD.

  METHOD zif_ab_v1_ut_attach~new_guid_c22.
    rv = cl_system_uuid=>create_uuid_c22_static( ).
  ENDMETHOD.

  METHOD zif_ab_v1_ut_attach~attach.
    zcl_ab_v1_ut_phase=>assert_defer_allowed( 'attach' ).

    DATA lv_ts TYPE timestampl.
    GET TIME STAMP FIELD lv_ts.

    rv_id = zif_ab_v1_ut_attach~new_guid_c32( ).
    APPEND VALUE ty_store( id         = rv_id
                           objtype    = is_bo_key-objtype
                           objkey     = is_bo_key-objkey
                           filename   = iv_filename
                           mimetype   = iv_mimetype
                           content    = iv_content
                           created_by = sy-uname
                           created_at = lv_ts ) TO gt_store.
  ENDMETHOD.

  METHOD zif_ab_v1_ut_attach~list.
    LOOP AT gt_store INTO DATA(ls) WHERE objtype = is_bo_key-objtype
                                     AND objkey  = is_bo_key-objkey.
      APPEND VALUE #( id         = ls-id
                      filename   = ls-filename
                      mimetype   = ls-mimetype
                      bytes      = xstrlen( ls-content )
                      created_by = ls-created_by
                      created_at = ls-created_at ) TO rt.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_ab_v1_ut_attach~get.
    READ TABLE gt_store INTO DATA(ls) WITH KEY id = iv_id.
    IF sy-subrc <> 0.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '007' iv_msgv1 = |attachment { iv_id } not found| ).
    ENDIF.
    rv_content = ls-content.
  ENDMETHOD.

  METHOD zif_ab_v1_ut_attach~to_solix.
    rt = cl_bcs_convert=>xstring_to_solix( iv_content ).
  ENDMETHOD.

  METHOD zif_ab_v1_ut_attach~from_solix.
    rv = cl_bcs_convert=>solix_to_xstring( it_solix = it_solix iv_size = iv_length ).
  ENDMETHOD.

ENDCLASS.
