"! <p class="shorttext synchronized">ZCL_AB_V1_UT: transport / where-used / code inventory</p>
"! RAP-mode: all methods are Core (read-only repository / transport metadata).
"! See docs/08_implementation_toolkit.md and docs/00_engineering_log.md.
CLASS zcl_ab_v1_ut_transport DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ab_v1_ut_transport.
ENDCLASS.



CLASS zcl_ab_v1_ut_transport IMPLEMENTATION.

  METHOD zif_ab_v1_ut_transport~objects_in_request.
    SELECT SINGLE trkorr FROM e070 INTO @DATA(lv_hit) WHERE trkorr = @iv_trkorr.
    IF sy-subrc <> 0.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '034' iv_msgv1 = |{ iv_trkorr }| ) ##NO_TEXT.
    ENDIF.

    DATA lr_tr TYPE RANGE OF trkorr.
    lr_tr = VALUE #( ( sign = 'I' option = 'EQ' low = iv_trkorr ) ).

    SELECT trkorr FROM e070 WHERE strkorr = @iv_trkorr INTO TABLE @DATA(lt_sub).
    LOOP AT lt_sub INTO DATA(ls_sub).
      APPEND VALUE #( sign = 'I' option = 'EQ' low = ls_sub-trkorr ) TO lr_tr.
    ENDLOOP.

    SELECT pgmid, object, obj_name, lockflag AS lock
      FROM e071
      WHERE trkorr IN @lr_tr
        AND pgmid  IN ( 'R3TR', 'LIMU' )
      INTO CORRESPONDING FIELDS OF TABLE @rt.

    SORT rt BY pgmid object obj_name.
    DELETE ADJACENT DUPLICATES FROM rt COMPARING pgmid object obj_name.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_transport~where_used.
    DATA lv_name TYPE string.
    DATA lv_type TYPE string.
    lv_name = to_upper( iv_name ).
    lv_type = to_upper( iv_type ).

    DATA lt_incl TYPE STANDARD TABLE OF wbcrossgt-include.

    IF strlen( lv_type ) = 2.
      SELECT include FROM wbcrossgt
        WHERE otype = @lv_type AND name = @lv_name
        INTO TABLE @lt_incl.
    ELSE.
      SELECT include FROM wbcrossgt
        WHERE name = @lv_name
        INTO TABLE @lt_incl.
    ENDIF.

    IF sy-subrc <> 0 AND lt_incl IS INITIAL.
      " no global cross-reference index hit - not an error, just empty
      RETURN.
    ENDIF.

    SORT lt_incl.
    DELETE ADJACENT DUPLICATES FROM lt_incl.

    LOOP AT lt_incl INTO DATA(lv_incl).
      APPEND VALUE #( pgmid    = 'LIMU'
                      object   = 'REPS'
                      obj_name = lv_incl ) TO rt.
    ENDLOOP.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_transport~custom_code_inventory.
    SELECT SINGLE devclass FROM tdevc INTO @DATA(lv_dc) WHERE devclass = @iv_package.
    IF sy-subrc <> 0.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '019' iv_msgv1 = 'package' iv_msgv2 = |{ iv_package }| ) ##NO_TEXT.
    ENDIF.

    SELECT pgmid, object, obj_name
      FROM tadir
      WHERE devclass = @iv_package
        AND delflag  = @space
        AND ( obj_name LIKE 'Z%' OR obj_name LIKE 'Y%' )
      ORDER BY object, obj_name
      INTO CORRESPONDING FIELDS OF TABLE @et_objects.

    SELECT object, COUNT(*) AS count
      FROM tadir
      WHERE devclass = @iv_package
        AND delflag  = @space
        AND ( obj_name LIKE 'Z%' OR obj_name LIKE 'Y%' )
      GROUP BY object
      ORDER BY object
      INTO CORRESPONDING FIELDS OF TABLE @et_by_type.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_transport~locking_requests.
    DATA lv_obj_name TYPE e071-obj_name.
    lv_obj_name = iv_obj_name.

    SELECT e070~trkorr, e070~as4user, e070~trstatus
      FROM e071 AS o
      INNER JOIN e070 ON e070~trkorr = o~trkorr
      WHERE o~pgmid    = @iv_pgmid
        AND o~object   = @iv_object
        AND o~obj_name = @lv_obj_name
        AND o~lockflag = 'X'
        AND e070~trstatus IN ( 'D', 'L' )
      INTO TABLE @DATA(lt).

    SORT lt BY trkorr.
    DELETE ADJACENT DUPLICATES FROM lt COMPARING trkorr.

    LOOP AT lt INTO DATA(ls).
      APPEND |{ ls-trkorr } ({ ls-as4user })| TO rt.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
