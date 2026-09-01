"! <p class="shorttext synchronized">ZCL_AB_V1_UT: email / notification</p>
"! RAP-mode: build_html_body is Core; send / raise_workflow_event are DEFER
"! (call with commit = abap_false from a late save phase). API: cl_bcs.
INTERFACE zif_ab_v1_ut_mail
  PUBLIC.

  TYPES:
    BEGIN OF ty_attachment,
      filename TYPE string,
      mimetype TYPE string,
      content  TYPE xstring,
    END OF ty_attachment.
  TYPES ty_attachment_tab TYPE STANDARD TABLE OF ty_attachment WITH EMPTY KEY.
  TYPES:
    BEGIN OF ty_mail,
      sender           TYPE string,
      recipients       TYPE zif_ab_v1_ut_types=>ty_string_tab,
      cc               TYPE zif_ab_v1_ut_types=>ty_string_tab,
      bcc              TYPE zif_ab_v1_ut_types=>ty_string_tab,
      subject          TYPE string,
      body_html        TYPE string,
      body_text        TYPE string,
      attachments      TYPE ty_attachment_tab,
      importance       TYPE c LENGTH 1,
      send_immediately TYPE abap_bool,
      request_status   TYPE abap_bool,
      commit_work      TYPE abap_bool,
    END OF ty_mail.

  "! DEFER
  METHODS send
    IMPORTING is_mail TYPE ty_mail
    RETURNING VALUE(rv_send_request_id) TYPE string
    RAISING   zcx_ab_v1_ut.

  METHODS build_html_body
    IMPORTING iv_title      TYPE string
              it_paragraphs TYPE zif_ab_v1_ut_types=>ty_string_tab OPTIONAL
              it_table      TYPE ANY TABLE OPTIONAL
    RETURNING VALUE(rv_html) TYPE string.

  "! DEFER
  METHODS raise_workflow_event
    IMPORTING iv_event     TYPE string
              is_container TYPE any OPTIONAL
    RAISING   zcx_ab_v1_ut.

ENDINTERFACE.
