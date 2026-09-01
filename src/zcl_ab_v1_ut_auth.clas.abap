CLASS zcl_ab_v1_ut_auth DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ab_v1_ut_auth.
  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS nth
      IMPORTING it        TYPE zif_ab_v1_ut_types=>ty_nv_tab
                iv_i      TYPE i
      RETURNING VALUE(rs) TYPE zif_ab_v1_ut_types=>ty_nv.
ENDCLASS.



CLASS zcl_ab_v1_ut_auth IMPLEMENTATION.

  METHOD nth.
    READ TABLE it INTO rs INDEX iv_i.
    IF sy-subrc <> 0.
      CLEAR rs.
    ENDIF.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_auth~check.
    DATA(lt)  = it_values.
    DATA(l1)  = nth( it = lt iv_i = 1 ).
    DATA(l2)  = nth( it = lt iv_i = 2 ).
    DATA(l3)  = nth( it = lt iv_i = 3 ).
    DATA(l4)  = nth( it = lt iv_i = 4 ).
    DATA(l5)  = nth( it = lt iv_i = 5 ).
    DATA(l6)  = nth( it = lt iv_i = 6 ).
    DATA(l7)  = nth( it = lt iv_i = 7 ).
    DATA(l8)  = nth( it = lt iv_i = 8 ).
    DATA(l9)  = nth( it = lt iv_i = 9 ).
    DATA(l10) = nth( it = lt iv_i = 10 ).

    CALL FUNCTION 'AUTHORITY_CHECK'
      EXPORTING  user            = iv_user
                 object          = iv_object
                 field1          = l1-name   value1  = l1-value
                 field2          = l2-name   value2  = l2-value
                 field3          = l3-name   value3  = l3-value
                 field4          = l4-name   value4  = l4-value
                 field5          = l5-name   value5  = l5-value
                 field6          = l6-name   value6  = l6-value
                 field7          = l7-name   value7  = l7-value
                 field8          = l8-name   value8  = l8-value
                 field9          = l9-name   value9  = l9-value
                 field10         = l10-name  value10 = l10-value
      EXCEPTIONS user_dont_exist = 1
                 not_authorized  = 2
                 indx_error      = 3
                 OTHERS          = 4.

    rv_authorized = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_auth~check_or_raise.
    IF zif_ab_v1_ut_auth~check( iv_object = iv_object
                                it_values = it_values
                                iv_user   = iv_user ) = abap_false.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '002' iv_msgv1 = |{ iv_object }| ).
    ENDIF.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_auth~user_has_role.
    SELECT SINGLE @abap_true
      FROM agr_users
      INTO @rv
      WHERE uname    = @iv_user
        AND agr_name = @iv_role
        AND from_dat <= @iv_on
        AND to_dat   >= @iv_on.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_auth~is_user_valid.
    SELECT SINGLE bname, uflag, gltgv, gltgb
      FROM usr02
      INTO @DATA(ls)
      WHERE bname = @iv_user.
    IF sy-subrc <> 0.
      rv = abap_false.
      RETURN.
    ENDIF.

    rv = xsdbool( ls-uflag = 0
              AND ( ls-gltgv IS INITIAL OR ls-gltgv <= sy-datum )
              AND ( ls-gltgb IS INITIAL OR ls-gltgb >= sy-datum ) ).
  ENDMETHOD.

ENDCLASS.
