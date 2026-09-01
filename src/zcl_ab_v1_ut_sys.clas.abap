CLASS zcl_ab_v1_ut_sys DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ab_v1_ut_sys.
  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES: BEGIN OF ty_timer,
             handle TYPE string,
             timer  TYPE REF TO if_abap_runtime,
           END OF ty_timer.
    DATA mt_timers TYPE HASHED TABLE OF ty_timer WITH UNIQUE KEY handle.
ENDCLASS.



CLASS zcl_ab_v1_ut_sys IMPLEMENTATION.

  METHOD zif_ab_v1_ut_sys~system_info.
    rs-sysid  = sy-sysid.
    rs-client = sy-mandt.
    rs-host   = sy-host.

    SELECT SINGLE cccategory FROM t000 INTO @rs-client_role WHERE mandt = @sy-mandt.
    rs-is_production = xsdbool( rs-client_role = 'P' ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_sys~object_exists.
    DATA(lv_type) = to_upper( iv_type ).
    DATA(lv_name) = to_upper( iv_name ).

    IF lv_type = 'FUNC'.
      CALL FUNCTION 'FUNCTION_EXISTS'
        EXPORTING  funcname           = CONV rs38l-name( lv_name )
        EXCEPTIONS function_not_exist = 1
                   OTHERS             = 2.
      rv = xsdbool( sy-subrc = 0 ).
      RETURN.
    ENDIF.

    SELECT SINGLE @abap_true
      FROM tadir
      INTO @rv
      WHERE pgmid    = 'R3TR'
        AND object   = @lv_type
        AND obj_name = @lv_name.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_sys~timer_start.
    rv_handle = cl_system_uuid=>create_uuid_c32_static( ).
    INSERT VALUE #( handle = rv_handle
                    timer  = cl_abap_runtime=>create_hr_timer( ) ) INTO TABLE mt_timers.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_sys~timer_stop.
    CLEAR: ev_seconds, ev_cpu_ms.
    READ TABLE mt_timers INTO DATA(ls) WITH KEY handle = iv_handle.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    DATA(lv_us) = ls-timer->get_runtime( ).
    ev_seconds = lv_us / 1000000.
    ev_cpu_ms  = lv_us / 1000.
    DELETE mt_timers WHERE handle = iv_handle.
  ENDMETHOD.

ENDCLASS.
