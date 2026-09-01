*"* use this source file for your ABAP unit test classes

CLASS ltc_job DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo TYPE REF TO zif_ab_v1_ut_job.
    METHODS setup.
    METHODS unknown_job_not_finished FOR TESTING.
ENDCLASS.


CLASS ltc_job IMPLEMENTATION.

  METHOD setup.
    mo = NEW zcl_ab_v1_ut_job( ).
  ENDMETHOD.

  METHOD unknown_job_not_finished.
    cl_abap_unit_assert=>assert_false(
      mo->is_finished( VALUE #( name = 'ZZ_AB_V1_UT_NO_JOB' count = '00000000' ) ) ).
  ENDMETHOD.

ENDCLASS.
