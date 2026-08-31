"! <p class="shorttext synchronized">ZCL_AB_V1_UT: attachments / GOS / DMS</p>
"! RAP-mode: new_guid_* / list / get / *_solix are Core; attach is DEFER.
"! Adapter chosen from ZAB_V1_UT_ADPT (AREA = 'ATTACH').
INTERFACE zif_ab_v1_ut_attach
  PUBLIC.

  TYPES:
    BEGIN OF ty_item,
      id         TYPE string,
      filename   TYPE string,
      mimetype   TYPE string,
      bytes      TYPE i,
      created_by TYPE syuname,
      created_at TYPE timestampl,
    END OF ty_item.
  TYPES ty_item_tab TYPE STANDARD TABLE OF ty_item WITH KEY id.

  METHODS new_guid_x16 RETURNING VALUE(rv) TYPE sysuuid_x16.
  METHODS new_guid_c32 RETURNING VALUE(rv) TYPE sysuuid_c32.
  METHODS new_guid_c22 RETURNING VALUE(rv) TYPE sysuuid_c22.

  METHODS list
    IMPORTING is_bo_key TYPE zif_ab_v1_ut_types=>ty_bo_key
    RETURNING VALUE(rt) TYPE ty_item_tab
    RAISING   zcx_ab_v1_ut.

  METHODS get
    IMPORTING iv_id            TYPE string
    RETURNING VALUE(rv_content) TYPE xstring
    RAISING   zcx_ab_v1_ut.

  "! DEFER
  METHODS attach
    IMPORTING is_bo_key      TYPE zif_ab_v1_ut_types=>ty_bo_key
              iv_filename    TYPE string
              iv_mimetype    TYPE string
              iv_content     TYPE xstring
              iv_auth_object TYPE xuobject DEFAULT 'S_GOS_GOS'
    RETURNING VALUE(rv_id)   TYPE string
    RAISING   zcx_ab_v1_ut.

  METHODS to_solix
    IMPORTING iv_content TYPE xstring
    RETURNING VALUE(rt)  TYPE solix_tab.

  METHODS from_solix
    IMPORTING it_solix  TYPE solix_tab
              iv_length TYPE i
    RETURNING VALUE(rv) TYPE xstring.

ENDINTERFACE.
