"! <p class="shorttext synchronized">ZCL_AB_V1_UT: REST / OData / SOAP consumer</p>
"! RAP-mode: request / *_json / paginate / soap_call / download / upload are DEFER
"! (network side effect); the builders (odata_*, soap_envelope) are Core.
"! Engine: classic CL_HTTP_CLIENT (stable, universally available). Config is fluent.
INTERFACE zif_ab_v1_ut_http
  PUBLIC.

  TYPES:
    BEGIN OF ty_header,
      name  TYPE string,
      value TYPE string,
    END OF ty_header,
    ty_header_tab TYPE STANDARD TABLE OF ty_header WITH KEY name.
  TYPES:
    BEGIN OF ty_response,
      code    TYPE i,
      reason  TYPE string,
      body    TYPE string,
      body_x  TYPE xstring,
      headers TYPE ty_header_tab,
    END OF ty_response.

  CONSTANTS:
    BEGIN OF c_method,
      get    TYPE string VALUE 'GET',
      post   TYPE string VALUE 'POST',
      put    TYPE string VALUE 'PUT',
      patch  TYPE string VALUE 'PATCH',
      delete TYPE string VALUE 'DELETE',
    END OF c_method.

  "--- configuration (fluent) ------------------------------------------------
  METHODS for_url
    IMPORTING iv_url    TYPE csequence
    RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_http.

  METHODS for_destination
    IMPORTING iv_destination TYPE rfcdest
    RETURNING VALUE(ro)      TYPE REF TO zif_ab_v1_ut_http.

  METHODS set_auth_basic
    IMPORTING iv_user     TYPE csequence
              iv_password TYPE csequence
    RETURNING VALUE(ro)   TYPE REF TO zif_ab_v1_ut_http.

  METHODS set_auth_bearer
    IMPORTING iv_token  TYPE csequence
    RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_http.

  METHODS set_oauth2_client_credentials
    IMPORTING iv_token_url     TYPE csequence
              iv_client_id     TYPE csequence
              iv_client_secret TYPE csequence
              iv_scope         TYPE csequence OPTIONAL
    RETURNING VALUE(ro)        TYPE REF TO zif_ab_v1_ut_http.

  METHODS with_header
    IMPORTING iv_name   TYPE csequence
              iv_value  TYPE csequence
    RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_http.

  METHODS with_retry
    IMPORTING iv_max        TYPE i DEFAULT 3
              iv_backoff_ms TYPE i DEFAULT 500
              it_on_status  TYPE zif_ab_v1_ut_types=>ty_string_tab OPTIONAL
    RETURNING VALUE(ro)     TYPE REF TO zif_ab_v1_ut_http.

  METHODS with_cache
    IMPORTING iv_ttl_seconds TYPE i
    RETURNING VALUE(ro)      TYPE REF TO zif_ab_v1_ut_http.

  METHODS with_log
    IMPORTING io_log    TYPE REF TO zif_ab_v1_ut_log
    RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_http.

  "--- calls (DEFER) -------------------------------------------------------
  METHODS request
    IMPORTING iv_method TYPE csequence
              iv_path   TYPE csequence OPTIONAL
              iv_body   TYPE csequence OPTIONAL
              iv_body_x TYPE xstring OPTIONAL
              it_query  TYPE zif_ab_v1_ut_types=>ty_nv_tab OPTIONAL
    RETURNING VALUE(rs_response) TYPE ty_response
    RAISING   zcx_ab_v1_ut.

  METHODS get_json
    IMPORTING iv_path   TYPE csequence OPTIONAL
              it_query  TYPE zif_ab_v1_ut_types=>ty_nv_tab OPTIONAL
    EXPORTING es_result TYPE any
    RETURNING VALUE(rs_response) TYPE ty_response
    RAISING   zcx_ab_v1_ut.

  METHODS post_json
    IMPORTING iv_path   TYPE csequence OPTIONAL
              is_body   TYPE any
    EXPORTING es_result TYPE any
    RETURNING VALUE(rs_response) TYPE ty_response
    RAISING   zcx_ab_v1_ut.

  METHODS put_json
    IMPORTING iv_path   TYPE csequence OPTIONAL
              is_body   TYPE any
    EXPORTING es_result TYPE any
    RETURNING VALUE(rs_response) TYPE ty_response
    RAISING   zcx_ab_v1_ut.

  METHODS patch_json
    IMPORTING iv_path   TYPE csequence OPTIONAL
              is_body   TYPE any
    EXPORTING es_result TYPE any
    RETURNING VALUE(rs_response) TYPE ty_response
    RAISING   zcx_ab_v1_ut.

  METHODS delete_
    IMPORTING iv_path   TYPE csequence OPTIONAL
    RETURNING VALUE(rs_response) TYPE ty_response
    RAISING   zcx_ab_v1_ut.

  METHODS paginate
    IMPORTING iv_path     TYPE csequence
              it_query    TYPE zif_ab_v1_ut_types=>ty_nv_tab OPTIONAL
              iv_next_field TYPE csequence DEFAULT '@odata.nextLink'
              io_consumer TYPE REF TO zif_ab_v1_ut_http_page
    RAISING   zcx_ab_v1_ut.

  METHODS download_binary
    IMPORTING iv_path   TYPE csequence OPTIONAL
    RETURNING VALUE(rv) TYPE xstring
    RAISING   zcx_ab_v1_ut.

  METHODS upload_multipart
    IMPORTING iv_path   TYPE csequence OPTIONAL
              it_parts  TYPE zif_ab_v1_ut_types=>ty_nv_tab
    RETURNING VALUE(rs_response) TYPE ty_response
    RAISING   zcx_ab_v1_ut.

  "--- OData query builder (Core) ----------------------------------------
  METHODS odata_filter
    IMPORTING it_ranges TYPE zif_ab_v1_ut_types=>ty_nv_tab
    RETURNING VALUE(rv) TYPE string.

  METHODS odata_query
    IMPORTING iv_filter TYPE csequence OPTIONAL
              iv_select TYPE csequence OPTIONAL
              iv_expand TYPE csequence OPTIONAL
              iv_top    TYPE i DEFAULT 0
              iv_skip   TYPE i DEFAULT 0
    RETURNING VALUE(rt) TYPE zif_ab_v1_ut_types=>ty_nv_tab.

  "--- SOAP ------------------------------------------------------------
  METHODS soap_call
    IMPORTING iv_action      TYPE csequence
              iv_request_xml TYPE csequence
              iv_path        TYPE csequence OPTIONAL
    RETURNING VALUE(rv_response_xml) TYPE string
    RAISING   zcx_ab_v1_ut.

  METHODS soap_envelope
    IMPORTING iv_body_xml   TYPE csequence
              it_header_xml TYPE zif_ab_v1_ut_types=>ty_string_tab OPTIONAL
    RETURNING VALUE(rv)     TYPE string.

ENDINTERFACE.
