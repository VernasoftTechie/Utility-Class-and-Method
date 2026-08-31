CLASS zcx_ab_v1_ut DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_t100_message.

    CONSTANTS:
      "! Generic utility error - &1 &2 &3 &4
      BEGIN OF generic,
        msgid TYPE symsgid      VALUE 'ZAB_V1_UT',
        msgno TYPE symsgno      VALUE '001',
        attr1 TYPE scx_attrname VALUE 'MV1',
        attr2 TYPE scx_attrname VALUE 'MV2',
        attr3 TYPE scx_attrname VALUE 'MV3',
        attr4 TYPE scx_attrname VALUE 'MV4',
      END OF generic.

    DATA mv1      TYPE string   READ-ONLY.
    DATA mv2      TYPE string   READ-ONLY.
    DATA mv3      TYPE string   READ-ONLY.
    DATA mv4      TYPE string   READ-ONLY.
    DATA severity TYPE symsgty  READ-ONLY.

    METHODS constructor
      IMPORTING
        textid   LIKE if_t100_message=>t100key OPTIONAL
        previous LIKE previous                 OPTIONAL
        severity TYPE symsgty                  DEFAULT 'E'
        mv1      TYPE string                   OPTIONAL
        mv2      TYPE string                   OPTIONAL
        mv3      TYPE string                   OPTIONAL
        mv4      TYPE string                   OPTIONAL.

    "! Convenience raiser - builds the t100key from a message number and up to 4 params.
    CLASS-METHODS raise_t100
      IMPORTING
        iv_msgno    TYPE symsgno
        iv_msgv1    TYPE clike             OPTIONAL
        iv_msgv2    TYPE clike             OPTIONAL
        iv_msgv3    TYPE clike             OPTIONAL
        iv_msgv4    TYPE clike             OPTIONAL
        iv_severity TYPE symsgty           DEFAULT 'E'
        io_previous TYPE REF TO cx_root    OPTIONAL
      RAISING
        zcx_ab_v1_ut.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcx_ab_v1_ut IMPLEMENTATION.

  METHOD constructor.
    super->constructor( previous = previous ).
    me->mv1      = mv1.
    me->mv2      = mv2.
    me->mv3      = mv3.
    me->mv4      = mv4.
    me->severity = severity.

    CLEAR me->textid.
    IF textid IS INITIAL.
      if_t100_message~t100key = if_t100_message=>default_textid.
    ELSE.
      if_t100_message~t100key = textid.
    ENDIF.
  ENDMETHOD.


  METHOD raise_t100.
    DATA(ls_key) = VALUE scx_t100key( msgid = generic-msgid
                                      msgno = iv_msgno
                                      attr1 = generic-attr1
                                      attr2 = generic-attr2
                                      attr3 = generic-attr3
                                      attr4 = generic-attr4 ).

    RAISE EXCEPTION TYPE zcx_ab_v1_ut
      EXPORTING
        textid   = ls_key
        previous = io_previous
        severity = iv_severity
        mv1      = |{ iv_msgv1 }|
        mv2      = |{ iv_msgv2 }|
        mv3      = |{ iv_msgv3 }|
        mv4      = |{ iv_msgv4 }|.
  ENDMETHOD.

ENDCLASS.
