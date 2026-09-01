"! GOS attachment adapter (Generic Object Services).
"!
"! v1.0.0: the GOS calls (create / list / read) are NOT wired, because the
"! concrete GOS API differs per S/4 release and per customer archive setup.
"! GUID generation and binary/SOLIX conversion are fully functional.
"!
"! To activate real GOS: implement attach / list / get below against your
"! system's GOS API (CL_GOS_API on S/4 1909+, or the classic GOS_* / SO_*
"! function modules) and set ZAB_V1_UT_ADPT area ATTACH -> this class active.
"! Until then leave the STUB adapter active.
CLASS zcl_ab_v1_ut_attach_gos DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ab_v1_ut_attach.
  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS not_wired
      IMPORTING iv_op TYPE string
      RAISING   zcx_ab_v1_ut.
ENDCLASS.



CLASS zcl_ab_v1_ut_attach_gos IMPLEMENTATION.

  METHOD not_wired.
    zcx_ab_v1_ut=>raise_t100(
      iv_msgno = '007'
      iv_msgv1 = |GOS adapter operation '{ iv_op }' is not wired - implement it for your system| ) ##NO_TEXT.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_attach~new_guid_x16.
    TRY.
        rv = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

  METHOD zif_ab_v1_ut_attach~new_guid_c32.
    TRY.
        rv = cl_system_uuid=>create_uuid_c32_static( ).
      CATCH cx_uuid_error ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

  METHOD zif_ab_v1_ut_attach~new_guid_c22.
    TRY.
        rv = cl_system_uuid=>create_uuid_c22_static( ).
      CATCH cx_uuid_error ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_attach~attach.
    zcl_ab_v1_ut_phase=>assert_defer_allowed( 'attach' ).
    not_wired( 'attach' ) ##NO_TEXT.
  ENDMETHOD.

  METHOD zif_ab_v1_ut_attach~list.
    not_wired( 'list' ) ##NO_TEXT.
  ENDMETHOD.

  METHOD zif_ab_v1_ut_attach~get.
    not_wired( 'get' ) ##NO_TEXT.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_attach~to_solix.
    rt = cl_bcs_convert=>xstring_to_solix( iv_content ).
  ENDMETHOD.

  METHOD zif_ab_v1_ut_attach~from_solix.
    rv = cl_bcs_convert=>solix_to_xstring( it_solix = it_solix iv_size = iv_length ).
  ENDMETHOD.

ENDCLASS.
