"! <p class="shorttext synchronized">ZCL_AB_V1_UT: config / customizing</p>
"! RAP-mode: all methods are Core.
INTERFACE zif_ab_v1_ut_cfg
  PUBLIC.

  METHODS tvarv_value
    IMPORTING iv_name   TYPE rvari_vnam
    RETURNING VALUE(rv) TYPE string
    RAISING   zcx_ab_v1_ut.

  METHODS tvarv_range
    IMPORTING iv_name  TYPE rvari_vnam
    EXPORTING et_range TYPE STANDARD TABLE.

  METHODS is_feature_on
    IMPORTING iv_feature TYPE string
    RETURNING VALUE(rv)  TYPE abap_bool.

  METHODS read_config
    IMPORTING iv_table TYPE string
              it_keys  TYPE zif_ab_v1_ut_types=>ty_nv_tab OPTIONAL
    EXPORTING et_rows  TYPE STANDARD TABLE
    RAISING   zcx_ab_v1_ut.

  METHODS enum_values
    IMPORTING iv_domain TYPE domname
    RETURNING VALUE(rt) TYPE zif_ab_v1_ut_types=>ty_nv_tab
    RAISING   zcx_ab_v1_ut.

ENDINTERFACE.
