"! GOS attachment adapter (Generic Object Services). Uses CL_GOS_API.
"! Activate ZAB_V1_UT_ADPT area ATTACH -> ZCL_AB_V1_UT_ATTACH_GOS to make this the
"! adapter returned by the facade in QA / production.
CLASS zcl_ab_v1_ut_attach_gos DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ab_v1_ut_attach.
  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS api
      IMPORTING is_bo_key    TYPE zif_ab_v1_ut_types=>ty_bo_key
      RETURNING VALUE(ro_api) TYPE REF TO cl_gos_api
      RAISING   zcx_ab_v1_ut.
ENDCLASS.



CLASS zcl_ab_v1_ut_attach_gos IMPLEMENTATION.

  METHOD api.
    TRY.
        ro_api = cl_gos_api=>create_instance(
                   is_lpor = VALUE sibflporb( instid = is_bo_key-objkey
                                              typeid = is_bo_key-objtype
                                              catid  = 'BO' ) ).
      CATCH cx_gos_api INTO DATA(lx).
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '007' iv_msgv1 = lx->get_text( ) io_previous = lx ).
    ENDTRY.
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

    IF NEW zcl_ab_v1_ut_auth( )->zif_ab_v1_ut_auth~check(
         iv_object = iv_auth_object
         it_values = VALUE #( ( name = 'ACTVT' value = '01' ) ) ) = abap_false.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '002' iv_msgv1 = |{ iv_auth_object }| ).
    ENDIF.

    DATA(lv_ext) = to_upper( substring_after( val = iv_filename sub = '.' occ = -1 ) ).

    TRY.
        DATA(lo_api) = api( is_bo_key ).
        rv_id = lo_api->create_attachment(
                  iv_title          = CONV so_obj_des( iv_filename )
                  iv_file_extension = CONV saeanwdid( lv_ext )
                  iv_content        = iv_content ).
      CATCH cx_gos_api INTO DATA(lx).
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '007' iv_msgv1 = lx->get_text( ) io_previous = lx ).
    ENDTRY.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_attach~list.
    TRY.
        DATA(lo_api)  = api( is_bo_key ).
        DATA(lt_atts) = lo_api->get_attachment_list( ).
        LOOP AT lt_atts INTO DATA(ls).
          APPEND VALUE #( id         = ls-attachment_id
                          filename   = ls-file_name
                          mimetype   = ls-mime_type
                          bytes      = ls-file_size
                          created_by = ls-created_by
                          created_at = ls-created_at ) TO rt.
        ENDLOOP.
      CATCH cx_gos_api INTO DATA(lx).
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '007' iv_msgv1 = lx->get_text( ) io_previous = lx ).
    ENDTRY.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_attach~get.
    TRY.
        rv_content = cl_gos_api=>get_attachment_content( iv_attachment_id = CONV #( iv_id ) ).
      CATCH cx_gos_api INTO DATA(lx).
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '007' iv_msgv1 = lx->get_text( ) io_previous = lx ).
    ENDTRY.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_attach~to_solix.
    rt = cl_bcs_convert=>xstring_to_solix( iv_content ).
  ENDMETHOD.

  METHOD zif_ab_v1_ut_attach~from_solix.
    rv = cl_bcs_convert=>solix_to_xstring( it_solix = it_solix iv_size = iv_length ).
  ENDMETHOD.

ENDCLASS.
