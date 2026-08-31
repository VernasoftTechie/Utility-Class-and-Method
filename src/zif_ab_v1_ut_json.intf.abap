"! <p class="shorttext synchronized">ZCL_AB_V1_UT: JSON / XML serialization</p>
"! RAP-mode: all methods are Core.
INTERFACE zif_ab_v1_ut_json
  PUBLIC.

  METHODS serialize
    IMPORTING iv_data        TYPE any
              iv_pretty      TYPE abap_bool DEFAULT abap_false
              iv_camel_case  TYPE abap_bool DEFAULT abap_false
              iv_keep_initial TYPE abap_bool DEFAULT abap_true
    RETURNING VALUE(rv_json) TYPE string
    RAISING   zcx_ab_v1_ut.

  METHODS deserialize
    IMPORTING iv_json       TYPE string
              iv_camel_case TYPE abap_bool DEFAULT abap_false
    CHANGING  ca_data       TYPE any
    RAISING   zcx_ab_v1_ut.

  METHODS pretty
    IMPORTING iv_json   TYPE string
    RETURNING VALUE(rv) TYPE string
    RAISING   zcx_ab_v1_ut.

  METHODS path_get
    IMPORTING iv_json   TYPE string
              iv_path   TYPE string
    RETURNING VALUE(rv) TYPE string
    RAISING   zcx_ab_v1_ut.

  METHODS path_set
    IMPORTING iv_json   TYPE string
              iv_path   TYPE string
              iv_value  TYPE string
    RETURNING VALUE(rv) TYPE string
    RAISING   zcx_ab_v1_ut.

  METHODS describe
    IMPORTING io_type         TYPE REF TO cl_abap_typedescr OPTIONAL
              iv_data         TYPE any OPTIONAL
    RETURNING VALUE(rv_schema) TYPE string
    RAISING   zcx_ab_v1_ut.

  METHODS to_xml
    IMPORTING iv_json   TYPE string
    RETURNING VALUE(rv) TYPE string
    RAISING   zcx_ab_v1_ut.

  METHODS from_xml
    IMPORTING iv_xml    TYPE string
    RETURNING VALUE(rv) TYPE string
    RAISING   zcx_ab_v1_ut.

  METHODS xml_serialize
    IMPORTING iv_data   TYPE any
    RETURNING VALUE(rv) TYPE xstring
    RAISING   zcx_ab_v1_ut.

  METHODS xml_deserialize
    IMPORTING iv_xml  TYPE xstring
    CHANGING  ca_data TYPE any
    RAISING   zcx_ab_v1_ut.

ENDINTERFACE.
