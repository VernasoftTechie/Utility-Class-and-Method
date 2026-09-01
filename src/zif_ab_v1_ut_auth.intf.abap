"! <p class="shorttext synchronized">ZCL_AB_V1_UT: authorization</p>
"! RAP-mode: all methods are Core. The single sanctioned AUTHORITY-CHECK wrapper.
INTERFACE zif_ab_v1_ut_auth
  PUBLIC.

  METHODS check
    IMPORTING iv_object          TYPE xuobject
              it_values          TYPE zif_ab_v1_ut_types=>ty_nv_tab
              iv_user            TYPE syuname DEFAULT sy-uname
    RETURNING VALUE(rv_authorized) TYPE abap_bool.

  METHODS check_or_raise
    IMPORTING iv_object TYPE xuobject
              it_values TYPE zif_ab_v1_ut_types=>ty_nv_tab
              iv_user   TYPE syuname DEFAULT sy-uname
    RAISING   zcx_ab_v1_ut.

  METHODS user_has_role
    IMPORTING iv_user   TYPE syuname
              iv_role   TYPE agr_name
              iv_on     TYPE d DEFAULT sy-datum
    RETURNING VALUE(rv) TYPE abap_bool.

  METHODS is_user_valid
    IMPORTING iv_user   TYPE syuname
    RETURNING VALUE(rv) TYPE abap_bool.

ENDINTERFACE.
