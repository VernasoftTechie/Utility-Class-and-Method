*"* use this source file for your ABAP unit test classes

CLASS ltc_facade DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS teardown.
    METHODS accessors_are_singletons FOR TESTING.
    METHODS injection_and_reset       FOR TESTING.
    METHODS phase_roundtrip           FOR TESTING.
    METHODS no_gui_dependencies       FOR TESTING.
ENDCLASS.


CLASS ltc_facade IMPLEMENTATION.

  METHOD teardown.
    zcl_ab_v1_ut=>reset( ).
  ENDMETHOD.

  METHOD accessors_are_singletons.
    cl_abap_unit_assert=>assert_bound( zcl_ab_v1_ut=>str( ) ).
    cl_abap_unit_assert=>assert_equals( exp = zcl_ab_v1_ut=>str( )  act = zcl_ab_v1_ut=>str( ) ).
    cl_abap_unit_assert=>assert_equals( exp = zcl_ab_v1_ut=>json( ) act = zcl_ab_v1_ut=>json( ) ).
    cl_abap_unit_assert=>assert_equals( exp = zcl_ab_v1_ut=>conv( ) act = zcl_ab_v1_ut=>conv( ) ).
    cl_abap_unit_assert=>assert_bound( zcl_ab_v1_ut=>attach( ) ).
    cl_abap_unit_assert=>assert_bound( zcl_ab_v1_ut=>tab( ) ).
    cl_abap_unit_assert=>assert_bound( zcl_ab_v1_ut=>msg( ) ).
    cl_abap_unit_assert=>assert_bound( zcl_ab_v1_ut=>sys( ) ).
    cl_abap_unit_assert=>assert_bound( zcl_ab_v1_ut=>rap( ) ).
  ENDMETHOD.

  METHOD injection_and_reset.
    DATA(lo_double) = CAST zif_ab_v1_ut_str( cl_abap_testdouble=>create( 'ZIF_AB_V1_UT_STR' ) ).
    zcl_ab_v1_ut=>set_str( lo_double ).
    cl_abap_unit_assert=>assert_equals( exp = lo_double act = zcl_ab_v1_ut=>str( ) ).

    zcl_ab_v1_ut=>reset( ).
    cl_abap_unit_assert=>assert_differs( exp = lo_double act = zcl_ab_v1_ut=>str( ) ).
  ENDMETHOD.

  METHOD phase_roundtrip.
    zcl_ab_v1_ut=>set_phase( zif_ab_v1_ut_types=>c_phase-late_save ).
    cl_abap_unit_assert=>assert_equals( exp = zif_ab_v1_ut_types=>c_phase-late_save
                                        act = zcl_ab_v1_ut=>phase( ) ).
    zcl_ab_v1_ut=>reset( ).
    cl_abap_unit_assert=>assert_equals( exp = zif_ab_v1_ut_types=>c_phase-unknown
                                        act = zcl_ab_v1_ut=>phase( ) ).
  ENDMETHOD.

  METHOD no_gui_dependencies.
    " The facade and every headless impl must not reference SAP GUI / SALV classes.
    " (where-used index WBCROSSGT; ZCL_AB_V1_UT_GUI is deliberately excluded.)
    SELECT DISTINCT name FROM wbcrossgt
      INTO TABLE @DATA(lt_hits)
      WHERE include LIKE 'ZCL_AB_V1_UT%'
        AND include NOT LIKE 'ZCL_AB_V1_UT_GUI%'
        AND ( name LIKE 'CL_GUI%' OR name LIKE 'CL_SALV%' ).

    DATA lt_names TYPE string_table.
    LOOP AT lt_hits INTO DATA(ls_hit).
      APPEND |{ ls_hit-name }| TO lt_names.
    ENDLOOP.

    cl_abap_unit_assert=>assert_initial(
      act = lines( lt_hits )
      msg = |headless classes reference SAP GUI: { concat_lines_of( table = lt_names sep = `,` ) }| ).
  ENDMETHOD.

ENDCLASS.
