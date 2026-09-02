"! <p class="shorttext synchronized">ZCL_AB_V1_UT: demo bulk handler (ZAB_V1_UT_DEMO_INT)</p>
"! Stateless per-package handler used by the BULK demo (run_packaged / run_parallel).
"! Returns one success message per package; no side effects.
CLASS zcl_ab_v1_ut_demo_bulk_h DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ab_v1_ut_bulk_handler.
ENDCLASS.



CLASS zcl_ab_v1_ut_demo_bulk_h IMPLEMENTATION.

  METHOD zif_ab_v1_ut_bulk_handler~process_package.
    FIELD-SYMBOLS <t> TYPE STANDARD TABLE.
    ASSIGN ir_keys->* TO <t>.

    DATA lv_n TYPE i.
    IF <t> IS ASSIGNED.
      lv_n = lines( <t> ).
    ENDIF.

    rt_messages = VALUE #( ( type       = 'S'
                             id         = 'ZAB_V1_UT'
                             number     = '001'
                             message    = |demo handler processed { lv_n } key(s)|
                             message_v1 = |{ lv_n }| ) ).
  ENDMETHOD.

ENDCLASS.
