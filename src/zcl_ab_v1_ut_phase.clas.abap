"! <p class="shorttext synchronized">ZCL_AB_V1_UT: RAP phase holder</p>
"! Holds the current RAP execution-phase hint. Set it from a behaviour saver
"! (e.g. save_modified) so that Defer-tagged utility methods can refuse when
"! called too early. Classic reports / jobs leave it at 'unknown' (Defer allowed).
CLASS zcl_ab_v1_ut_phase DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    CLASS-METHODS set
      IMPORTING iv_phase TYPE zif_ab_v1_ut_types=>ty_phase.

    CLASS-METHODS get
      RETURNING VALUE(rv) TYPE zif_ab_v1_ut_types=>ty_phase.

    "! Raises ZAB_V1_UT/013 when a Defer operation is invoked in a RAP
    "! interaction / early-save phase.
    CLASS-METHODS assert_defer_allowed
      IMPORTING iv_op TYPE string
      RAISING   zcx_ab_v1_ut.

  PRIVATE SECTION.
    CLASS-DATA gv_phase TYPE zif_ab_v1_ut_types=>ty_phase.
ENDCLASS.



CLASS zcl_ab_v1_ut_phase IMPLEMENTATION.

  METHOD set.
    gv_phase = iv_phase.
  ENDMETHOD.

  METHOD get.
    rv = gv_phase.
  ENDMETHOD.

  METHOD assert_defer_allowed.
    IF gv_phase <> zif_ab_v1_ut_types=>c_phase-unknown
   AND gv_phase <  zif_ab_v1_ut_types=>c_phase-late_save.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '013'
                                iv_msgv1 = iv_op
                                iv_msgv2 = |{ gv_phase }| ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
