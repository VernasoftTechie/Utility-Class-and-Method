*"* use this source file for your ABAP unit test classes

CLASS ltc_transport DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo TYPE REF TO zif_ab_v1_ut_transport.
    METHODS setup.
    METHODS inventory_tmp        FOR TESTING RAISING zcx_ab_v1_ut.
    METHODS inventory_bad_pkg    FOR TESTING.
    METHODS request_not_found    FOR TESTING.
    METHODS locking_empty        FOR TESTING.
    METHODS where_used_runs      FOR TESTING RAISING zcx_ab_v1_ut.
ENDCLASS.


CLASS ltc_transport IMPLEMENTATION.

  METHOD setup.
    mo = NEW zcl_ab_v1_ut_transport( ).
  ENDMETHOD.

  METHOD inventory_tmp.
    mo->custom_code_inventory( EXPORTING iv_package = CONV #( '$TMP' )
                              IMPORTING et_by_type = DATA(lt_type)
                                        et_objects = DATA(lt_obj) ).
    " $TMP exists -> no exception; contents are environment-specific
    cl_abap_unit_assert=>assert_true( xsdbool( lines( lt_obj ) >= lines( lt_type ) ) ).
  ENDMETHOD.

  METHOD inventory_bad_pkg.
    TRY.
        mo->custom_code_inventory( EXPORTING iv_package = CONV #( 'ZZ_NO_PKG_98765' )
                                  IMPORTING et_by_type = DATA(lt_type)
                                            et_objects = DATA(lt_obj) ).
        cl_abap_unit_assert=>fail( 'expected ZCX_AB_V1_UT for unknown package' ).
      CATCH zcx_ab_v1_ut ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

  METHOD request_not_found.
    TRY.
        mo->objects_in_request( iv_trkorr = CONV #( 'ZZZK900099' ) ).
        cl_abap_unit_assert=>fail( 'expected ZCX_AB_V1_UT for unknown request' ).
      CATCH zcx_ab_v1_ut ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

  METHOD locking_empty.
    DATA(lt) = mo->locking_requests( iv_pgmid    = 'R3TR'
                                     iv_object   = 'CLAS'
                                     iv_obj_name = 'ZZ_NO_SUCH_CLASS_98765' ).
    cl_abap_unit_assert=>assert_initial( act = lt ).
  ENDMETHOD.

  METHOD where_used_runs.
    " exercises the WBCROSSGT read path; result depends on the cross-reference index,
    " the assertion only proves it did not dump
    DATA(lt) = mo->where_used( iv_type = 'TY' iv_name = 'IF_T100_MESSAGE' ).
    cl_abap_unit_assert=>assert_true( xsdbool( lines( lt ) >= 0 ) ).
  ENDMETHOD.

ENDCLASS.
