"! <p class="shorttext synchronized">ZCL_AB_V1_UT: HTTP pagination page consumer</p>
"! Implemented by the caller; ZIF_AB_V1_UT_HTTP~paginate calls on_page once per page.
INTERFACE zif_ab_v1_ut_http_page
  PUBLIC.

  METHODS on_page
    IMPORTING iv_body    TYPE string
              iv_page_no TYPE i
    EXPORTING ev_stop    TYPE abap_bool
    RAISING   zcx_ab_v1_ut.

ENDINTERFACE.
