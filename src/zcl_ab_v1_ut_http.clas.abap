CLASS zcl_ab_v1_ut_http DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_ab_v1_ut_http.

  PROTECTED SECTION.
    "! The single place that talks to the network. A test subclass redefines this.
    METHODS raw_send
      IMPORTING iv_method  TYPE csequence
                iv_path    TYPE csequence
                iv_body    TYPE csequence
                iv_body_x  TYPE xstring
                iv_ctype   TYPE csequence
      RETURNING VALUE(rs)  TYPE zif_ab_v1_ut_http=>ty_response
      RAISING   zcx_ab_v1_ut.

  PRIVATE SECTION.
    DATA: mv_url           TYPE string,
          mv_dest          TYPE rfcdest,
          mt_headers       TYPE zif_ab_v1_ut_http=>ty_header_tab,
          mv_auth_hdr      TYPE string,
          mv_retry_max     TYPE i,
          mv_retry_backoff TYPE i,
          mt_retry_status  TYPE zif_ab_v1_ut_types=>ty_string_tab,
          mo_log           TYPE REF TO zif_ab_v1_ut_log.

    DATA: BEGIN OF ms_oauth,
            token_url     TYPE string,
            client_id     TYPE string,
            client_secret TYPE string,
            scope         TYPE string,
          END OF ms_oauth.
    DATA: mv_token     TYPE string,
          mv_token_exp TYPE timestamp.

    METHODS reset.
    METHODS ensure_token
      RAISING zcx_ab_v1_ut.
    METHODS build_path
      IMPORTING iv_path   TYPE csequence
                it_query  TYPE zif_ab_v1_ut_types=>ty_nv_tab
      RETURNING VALUE(rv) TYPE string.
    METHODS send_with_policy
      IMPORTING iv_method TYPE csequence
                iv_path   TYPE csequence
                iv_body   TYPE csequence
                iv_body_x TYPE xstring
                iv_ctype  TYPE csequence
      RETURNING VALUE(rs) TYPE zif_ab_v1_ut_http=>ty_response
      RAISING   zcx_ab_v1_ut.

    METHODS json_next_link
      IMPORTING iv_body   TYPE string
                iv_field  TYPE csequence
      RETURNING VALUE(rv) TYPE string.
ENDCLASS.



CLASS zcl_ab_v1_ut_http IMPLEMENTATION.

  METHOD reset.
    CLEAR: mv_url, mv_dest, mt_headers, mv_auth_hdr, mv_retry_max, mv_retry_backoff,
           mt_retry_status, mo_log, ms_oauth, mv_token, mv_token_exp.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_http~for_url.
    reset( ).
    mv_url = iv_url.
    ro = me.
  ENDMETHOD.

  METHOD zif_ab_v1_ut_http~for_destination.
    reset( ).
    mv_dest = iv_destination.
    ro = me.
  ENDMETHOD.

  METHOD zif_ab_v1_ut_http~set_auth_basic.
    mv_auth_hdr = |Basic { cl_http_utility=>encode_base64( |{ iv_user }:{ iv_password }| ) }|.
    ro = me.
  ENDMETHOD.

  METHOD zif_ab_v1_ut_http~set_auth_bearer.
    mv_auth_hdr = |Bearer { iv_token }|.
    ro = me.
  ENDMETHOD.

  METHOD zif_ab_v1_ut_http~set_oauth2_client_credentials.
    ms_oauth-token_url     = iv_token_url.
    ms_oauth-client_id     = iv_client_id.
    ms_oauth-client_secret = iv_client_secret.
    ms_oauth-scope         = iv_scope.
    ro = me.
  ENDMETHOD.

  METHOD zif_ab_v1_ut_http~with_header.
    INSERT VALUE #( name = iv_name value = iv_value ) INTO TABLE mt_headers.
    ro = me.
  ENDMETHOD.

  METHOD zif_ab_v1_ut_http~with_retry.
    mv_retry_max     = iv_max.
    mv_retry_backoff = iv_backoff_ms.
    IF it_on_status IS SUPPLIED AND it_on_status IS NOT INITIAL.
      mt_retry_status = it_on_status.
    ELSE.
      mt_retry_status = VALUE #( ( `429` ) ( `500` ) ( `502` ) ( `503` ) ( `504` ) ).
    ENDIF.
    ro = me.
  ENDMETHOD.

  METHOD zif_ab_v1_ut_http~with_cache.
    " reserved for a future in-memory GET cache; no-op keeps the fluent API stable
    ro = me.
  ENDMETHOD.

  METHOD zif_ab_v1_ut_http~with_log.
    mo_log = io_log.
    ro = me.
  ENDMETHOD.


  METHOD build_path.
    DATA lv_q TYPE string.
    LOOP AT it_query INTO DATA(ls).
      DATA(lv_pair) = |{ escape( val = ls-name  format = cl_abap_format=>e_uri_full ) }=| &&
                      |{ escape( val = ls-value format = cl_abap_format=>e_uri_full ) }|.
      IF lv_q IS INITIAL.
        lv_q = lv_pair.
      ELSE.
        lv_q = |{ lv_q }&{ lv_pair }|.
      ENDIF.
    ENDLOOP.

    rv = iv_path.
    IF lv_q IS NOT INITIAL.
      IF rv CS '?'.
        rv = |{ rv }&{ lv_q }|.
      ELSE.
        rv = |{ rv }?{ lv_q }|.
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD ensure_token.
    IF ms_oauth-token_url IS INITIAL.
      RETURN.
    ENDIF.

    DATA lv_now TYPE timestamp.
    GET TIME STAMP FIELD lv_now.
    IF mv_token IS NOT INITIAL AND mv_token_exp > lv_now.
      RETURN.
    ENDIF.

    DATA(lv_body) = |grant_type=client_credentials| &&
                    |&client_id={ escape( val = ms_oauth-client_id format = cl_abap_format=>e_uri_full ) }| &&
                    |&client_secret={ escape( val = ms_oauth-client_secret format = cl_abap_format=>e_uri_full ) }|.
    IF ms_oauth-scope IS NOT INITIAL.
      lv_body = |{ lv_body }&scope={ escape( val = ms_oauth-scope format = cl_abap_format=>e_uri_full ) }|.
    ENDIF.

    " temporarily retarget to the token URL
    DATA(lv_url)  = mv_url.
    DATA(lv_dest) = mv_dest.
    DATA(lv_auth) = mv_auth_hdr.
    CLEAR: mv_dest, mv_auth_hdr.
    mv_url = ms_oauth-token_url.

    DATA(ls_resp) = raw_send( iv_method = 'POST' iv_path = `` iv_body = lv_body
                              iv_body_x = `` iv_ctype = 'application/x-www-form-urlencoded' ).

    mv_url = lv_url.
    mv_dest = lv_dest.
    mv_auth_hdr = lv_auth.

    IF ls_resp-code >= 400.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '023' iv_msgv1 = ls_resp-body ).
    ENDIF.

    TYPES: BEGIN OF ty_tok,
             access_token TYPE string,
             expires_in   TYPE i,
           END OF ty_tok.
    DATA ls_tok TYPE ty_tok.
    TRY.
        /ui2/cl_json=>deserialize( EXPORTING json = ls_resp-body CHANGING data = ls_tok ).
      CATCH cx_root INTO DATA(lx).
        zcx_ab_v1_ut=>raise_t100( iv_msgno = '023' iv_msgv1 = lx->get_text( ) io_previous = lx ).
    ENDTRY.

    IF ls_tok-access_token IS INITIAL.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '023' iv_msgv1 = 'no access_token in response' ) ##NO_TEXT.
    ENDIF.

    mv_token    = ls_tok-access_token.
    mv_auth_hdr = |Bearer { mv_token }|.

    DATA(lv_ttl) = COND i( WHEN ls_tok-expires_in > 60 THEN ls_tok-expires_in - 30 ELSE 60 ).
    mv_token_exp = cl_abap_tstmp=>add( tstmp = lv_now secs = CONV #( lv_ttl ) ).
  ENDMETHOD.


  METHOD raw_send.
    DATA lo_client TYPE REF TO if_http_client.

    IF mv_dest IS NOT INITIAL.
      cl_http_client=>create_by_destination(
        EXPORTING  destination              = mv_dest
        IMPORTING  client                   = lo_client
        EXCEPTIONS argument_not_found       = 1
                   destination_not_found    = 2
                   destination_no_authority = 3
                   plugin_not_active        = 4
                   internal_error           = 5
                   OTHERS                   = 6 ).
    ELSE.
      cl_http_client=>create_by_url(
        EXPORTING  url                = |{ mv_url }{ iv_path }|
        IMPORTING  client             = lo_client
        EXCEPTIONS argument_not_found = 1
                   plugin_not_active  = 2
                   internal_error     = 3
                   OTHERS             = 4 ).
    ENDIF.

    IF sy-subrc <> 0 OR lo_client IS NOT BOUND.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '022' iv_msgv1 = |client create rc={ sy-subrc }| ) ##NO_TEXT.
    ENDIF.

    lo_client->propertytype_logon_popup = if_http_client=>co_disabled.

    lo_client->request->set_method( CONV #( iv_method ) ).
    IF mv_dest IS NOT INITIAL AND iv_path IS NOT INITIAL.
      cl_http_utility=>set_request_uri( request = lo_client->request uri = CONV #( iv_path ) ).
    ENDIF.

    LOOP AT mt_headers INTO DATA(ls_h).
      lo_client->request->set_header_field( name = CONV #( ls_h-name ) value = CONV #( ls_h-value ) ).
    ENDLOOP.
    IF mv_auth_hdr IS NOT INITIAL.
      lo_client->request->set_header_field( name = 'Authorization' value = mv_auth_hdr ).
    ENDIF.
    IF iv_ctype IS NOT INITIAL.
      lo_client->request->set_content_type( CONV #( iv_ctype ) ).
    ENDIF.

    IF iv_body_x IS NOT INITIAL.
      lo_client->request->set_data( iv_body_x ).
    ELSEIF iv_body IS NOT INITIAL.
      lo_client->request->set_cdata( CONV #( iv_body ) ).
    ENDIF.

    lo_client->send(
      EXCEPTIONS http_communication_failure = 1
                 http_invalid_state         = 2
                 http_processing_failed     = 3
                 http_invalid_timeout       = 4
                 OTHERS                     = 5 ).
    IF sy-subrc = 0.
      lo_client->receive(
        EXCEPTIONS http_communication_failure = 1
                   http_invalid_state         = 2
                   http_processing_failed     = 3
                   OTHERS                     = 4 ).
    ENDIF.

    IF sy-subrc <> 0.
      lo_client->get_last_error( IMPORTING message = DATA(lv_err) ).
      lo_client->close( EXCEPTIONS OTHERS = 0 ).
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '022' iv_msgv1 = lv_err ).
    ENDIF.

    lo_client->response->get_status( IMPORTING code = rs-code reason = rs-reason ).
    rs-body   = lo_client->response->get_cdata( ).
    rs-body_x = lo_client->response->get_data( ).

    DATA lt_hf TYPE tihttpnvp.
    lo_client->response->get_header_fields( CHANGING fields = lt_hf ).
    LOOP AT lt_hf INTO DATA(ls_hf).
      APPEND VALUE #( name = ls_hf-name value = ls_hf-value ) TO rs-headers.
    ENDLOOP.

    lo_client->close( EXCEPTIONS OTHERS = 0 ).
  ENDMETHOD.


  METHOD send_with_policy.
    ensure_token( ).

    DATA(lv_attempt) = 0.
    DO.
      lv_attempt = lv_attempt + 1.
      rs = raw_send( iv_method = iv_method iv_path = iv_path iv_body = iv_body
                     iv_body_x = iv_body_x iv_ctype = iv_ctype ).

      IF mo_log IS BOUND.
        mo_log->add_t100( iv_msgid = 'ZAB_V1_UT' iv_msgno = '021' iv_type = 'I'
                          iv_v1 = iv_method iv_v2 = iv_path iv_v3 = |{ rs-code }| ).
      ENDIF.

      IF rs-code < 400.
        RETURN.
      ENDIF.

      IF rs-code = 401 AND ms_oauth-token_url IS NOT INITIAL AND lv_attempt = 1.
        CLEAR mv_token.
        ensure_token( ).
        CONTINUE.
      ENDIF.

      IF lv_attempt <= mv_retry_max
     AND line_exists( mt_retry_status[ table_line = |{ rs-code }| ] ).
        DATA lv_wait TYPE p LENGTH 8 DECIMALS 3.
        lv_wait = ( mv_retry_backoff * lv_attempt ) / 1000.
        IF lv_wait > 0.
          WAIT UP TO lv_wait SECONDS.
        ENDIF.
        CONTINUE.
      ENDIF.

      zcx_ab_v1_ut=>raise_t100( iv_msgno = '021' iv_msgv1 = iv_method
                                iv_msgv2 = iv_path iv_msgv3 = |{ rs-code }| ).
    ENDDO.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_http~request.
    DATA lv_ctype TYPE string.
    IF iv_body IS NOT INITIAL.
      lv_ctype = 'application/json'.
    ENDIF.
    rs_response = send_with_policy(
      iv_method = iv_method
      iv_path   = build_path( iv_path = iv_path it_query = it_query )
      iv_body   = iv_body
      iv_body_x = iv_body_x
      iv_ctype  = lv_ctype ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_http~get_json.
    rs_response = send_with_policy(
      iv_method = 'GET'
      iv_path   = build_path( iv_path = iv_path it_query = it_query )
      iv_body   = `` iv_body_x = `` iv_ctype = `` ).
    IF rs_response-body IS NOT INITIAL.
      TRY.
          /ui2/cl_json=>deserialize( EXPORTING json = rs_response-body CHANGING data = es_result ).
        CATCH cx_root INTO DATA(lx).
          zcx_ab_v1_ut=>raise_t100( iv_msgno = '005' iv_msgv1 = lx->get_text( ) io_previous = lx ).
      ENDTRY.
    ENDIF.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_http~post_json.
    DATA(lv_body) = /ui2/cl_json=>serialize( data = is_body compress = abap_true ).
    rs_response = send_with_policy( iv_method = 'POST' iv_path = iv_path
                                    iv_body = lv_body iv_body_x = `` iv_ctype = 'application/json' ).
    IF rs_response-body IS NOT INITIAL.
      TRY.
          /ui2/cl_json=>deserialize( EXPORTING json = rs_response-body CHANGING data = es_result ).
        CATCH cx_root ##NO_HANDLER.
      ENDTRY.
    ENDIF.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_http~put_json.
    DATA(lv_body) = /ui2/cl_json=>serialize( data = is_body compress = abap_true ).
    rs_response = send_with_policy( iv_method = 'PUT' iv_path = iv_path
                                    iv_body = lv_body iv_body_x = `` iv_ctype = 'application/json' ).
    IF rs_response-body IS NOT INITIAL.
      TRY.
          /ui2/cl_json=>deserialize( EXPORTING json = rs_response-body CHANGING data = es_result ).
        CATCH cx_root ##NO_HANDLER.
      ENDTRY.
    ENDIF.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_http~patch_json.
    DATA(lv_body) = /ui2/cl_json=>serialize( data = is_body compress = abap_true ).
    rs_response = send_with_policy( iv_method = 'PATCH' iv_path = iv_path
                                    iv_body = lv_body iv_body_x = `` iv_ctype = 'application/json' ).
    IF rs_response-body IS NOT INITIAL.
      TRY.
          /ui2/cl_json=>deserialize( EXPORTING json = rs_response-body CHANGING data = es_result ).
        CATCH cx_root ##NO_HANDLER.
      ENDTRY.
    ENDIF.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_http~delete_.
    rs_response = send_with_policy( iv_method = 'DELETE' iv_path = iv_path
                                    iv_body = `` iv_body_x = `` iv_ctype = `` ).
  ENDMETHOD.


  METHOD json_next_link.
    DATA(lv_pat) = |"{ iv_field }"\\s*:\\s*"([^"]*)"|.
    FIND FIRST OCCURRENCE OF PCRE lv_pat IN iv_body SUBMATCHES rv.
    IF sy-subrc <> 0.
      CLEAR rv.
    ENDIF.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_http~paginate.
    DATA(lv_path) = build_path( iv_path = iv_path it_query = it_query ).
    DATA(lv_page) = 0.
    DATA lv_stop TYPE abap_bool.

    WHILE lv_path IS NOT INITIAL AND lv_stop = abap_false.
      lv_page = lv_page + 1.
      DATA(ls_resp) = send_with_policy( iv_method = 'GET' iv_path = lv_path
                                        iv_body = `` iv_body_x = `` iv_ctype = `` ).

      io_consumer->on_page( EXPORTING iv_body = ls_resp-body iv_page_no = lv_page
                            IMPORTING ev_stop = lv_stop ).

      lv_path = json_next_link( iv_body = ls_resp-body iv_field = iv_next_field ).
    ENDWHILE.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_http~download_binary.
    DATA(ls_resp) = send_with_policy( iv_method = 'GET' iv_path = iv_path
                                      iv_body = `` iv_body_x = `` iv_ctype = `` ).
    rv = ls_resp-body_x.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_http~upload_multipart.
    DATA(lv_boundary) = |----zab{ sy-datum }{ sy-uzeit }{ sy-timlo }|.
    DATA lv_body TYPE string.
    LOOP AT it_parts INTO DATA(ls).
      lv_body = lv_body &&
        |--{ lv_boundary }{ cl_abap_char_utilities=>cr_lf }| &&
        |Content-Disposition: form-data; name="{ ls-name }"{ cl_abap_char_utilities=>cr_lf }{ cl_abap_char_utilities=>cr_lf }| &&
        |{ ls-value }{ cl_abap_char_utilities=>cr_lf }|.
    ENDLOOP.
    lv_body = lv_body && |--{ lv_boundary }--{ cl_abap_char_utilities=>cr_lf }|.

    rs_response = send_with_policy( iv_method = 'POST' iv_path = iv_path iv_body = lv_body
                                    iv_body_x = `` iv_ctype = |multipart/form-data; boundary={ lv_boundary }| ).
  ENDMETHOD.


  METHOD zif_ab_v1_ut_http~odata_filter.
    LOOP AT it_ranges INTO DATA(ls).
      SPLIT ls-value AT ':' INTO DATA(lv_op) DATA(lv_val).
      IF lv_val IS INITIAL.
        lv_val = lv_op.
        lv_op  = 'eq'.
      ENDIF.
      DATA(lv_cond) = |{ to_lower( ls-name ) } { to_lower( lv_op ) } '{ lv_val }'|.
      IF rv IS INITIAL.
        rv = lv_cond.
      ELSE.
        rv = |{ rv } and { lv_cond }|.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_http~odata_query.
    IF iv_filter IS NOT INITIAL.
      INSERT VALUE #( name = '$filter' value = iv_filter ) INTO TABLE rt.
    ENDIF.
    IF iv_select IS NOT INITIAL.
      INSERT VALUE #( name = '$select' value = iv_select ) INTO TABLE rt.
    ENDIF.
    IF iv_expand IS NOT INITIAL.
      INSERT VALUE #( name = '$expand' value = iv_expand ) INTO TABLE rt.
    ENDIF.
    IF iv_top > 0.
      INSERT VALUE #( name = '$top' value = |{ iv_top }| ) INTO TABLE rt.
    ENDIF.
    IF iv_skip > 0.
      INSERT VALUE #( name = '$skip' value = |{ iv_skip }| ) INTO TABLE rt.
    ENDIF.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_http~soap_envelope.
    DATA lv_hdr TYPE string.
    LOOP AT it_header_xml INTO DATA(lv).
      lv_hdr = lv_hdr && lv.
    ENDLOOP.
    DATA lv_hdr_tag TYPE string.
    IF lv_hdr IS NOT INITIAL.
      lv_hdr_tag = |<soapenv:Header>{ lv_hdr }</soapenv:Header>|.
    ENDIF.
    rv = |<?xml version="1.0" encoding="UTF-8"?>| &&
         |<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">| &&
         lv_hdr_tag &&
         |<soapenv:Body>{ iv_body_xml }</soapenv:Body></soapenv:Envelope>|.
  ENDMETHOD.


  METHOD zif_ab_v1_ut_http~soap_call.
    zif_ab_v1_ut_http~with_header( iv_name = 'SOAPAction' iv_value = iv_action ).
    DATA(ls_resp) = send_with_policy( iv_method = 'POST' iv_path = iv_path
                                      iv_body = iv_request_xml iv_body_x = ``
                                      iv_ctype = 'text/xml; charset=utf-8' ).
    IF ls_resp-code >= 400.
      zcx_ab_v1_ut=>raise_t100( iv_msgno = '024' iv_msgv1 = iv_action iv_msgv2 = |{ ls_resp-code }| ).
    ENDIF.
    rv_response_xml = ls_resp-body.
  ENDMETHOD.

ENDCLASS.
