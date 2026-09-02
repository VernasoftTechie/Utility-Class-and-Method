# 08 – Implementation Toolkit (v1.1.0) – Architecture & Technical Spec

**Status:** DRAFT – for approval. Build starts **after v1.0.0 is ATC-clean + C1-released.**
**Applies:** the rules in `00_engineering_log.md` (complete RETURNING types, `csequence`
text inputs, `STANDARD TABLE` params, FM existence guards, no dynamic-token traps).

RAP-mode legend: **[C]** Core · **[D]** Defer · **[G]** Gated. Every network / commit /
job / lock operation is **[D]**.

---

## 1. New objects

| Object | Kind | Notes |
|---|---|---|
| `ZIF_AB_V1_UT_HTTP` | interface | REST / OData / SOAP consumer |
| `ZCL_AB_V1_UT_HTTP` | class | impl over `cl_web_http_client` |
| `ZIF_AB_V1_UT_BULK` | interface | packaged / parallel / restart runner |
| `ZIF_AB_V1_UT_BULK_HANDLER` | interface | caller implements the per-package work |
| `ZIF_AB_V1_UT_BULK_STORE` | interface | caller implements checkpoint persistence |
| `ZCL_AB_V1_UT_BULK` | class | impl |
| `ZCL_AB_V1_UT_BULK_STORE_MEM` | class | in-memory default store (adapter pattern) |
| `ZIF_AB_V1_UT_BAPI` | interface | BAPI / BDC mass executor |
| `ZCL_AB_V1_UT_BAPI` | class | impl |
| `ZIF_AB_V1_UT_CUTOVER` | interface | go-live task runner + readiness + locks |
| `ZIF_AB_V1_UT_CUTOVER_EXEC` | interface | caller implements `run_task` |
| `ZCL_AB_V1_UT_CUTOVER` | class | impl |
| `ZIF_AB_V1_UT_TRANSPORT` | interface | transport contents + where-used + code inventory |
| `ZCL_AB_V1_UT_TRANSPORT` | class | impl |
| `ZAB_V1_UT_DEMO_INT` | report | working demo of every method in the 5 areas |

**Domain `ZAB_V1_UT_AREA`** gains values: `HTTP BULK BAPI CUTOVER TRANSPORT`.
**Message class `ZAB_V1_UT`** gains 021–035 (see §8).
**Facade `ZCL_AB_V1_UT`** gains accessors `http( ) bulk( ) bapi( ) cutover( ) transport( )`
+ `set_http( ) …` test seams. No new DDIC tables.

---

## 2. `ZIF_AB_V1_UT_HTTP`

```abap
INTERFACE zif_ab_v1_ut_http PUBLIC.

  TYPES:
    BEGIN OF ty_header,   name TYPE string, value TYPE string, END OF ty_header,
    ty_header_tab TYPE STANDARD TABLE OF ty_header WITH KEY name,
    BEGIN OF ty_response,
      code    TYPE i,
      reason  TYPE string,
      body    TYPE string,
      body_x  TYPE xstring,
      headers TYPE ty_header_tab,
    END OF ty_response.
  CONSTANTS:
    BEGIN OF c_method, get TYPE string VALUE 'GET', post TYPE string VALUE 'POST',
                       put TYPE string VALUE 'PUT', patch TYPE string VALUE 'PATCH',
                       delete TYPE string VALUE 'DELETE', END OF c_method.

  "--- configuration (fluent; returns me) ---------------------------------
  METHODS for_url         IMPORTING iv_url TYPE csequence
                          RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_http.
  METHODS for_destination IMPORTING iv_destination TYPE rfcdest
                          RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_http.
  METHODS set_auth_basic  IMPORTING iv_user TYPE csequence iv_password TYPE csequence
                          RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_http.
  METHODS set_auth_bearer IMPORTING iv_token TYPE csequence
                          RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_http.
  METHODS set_oauth2_client_credentials
                          IMPORTING iv_token_url TYPE csequence iv_client_id TYPE csequence
                                    iv_client_secret TYPE csequence iv_scope TYPE csequence OPTIONAL
                          RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_http.
  METHODS with_header     IMPORTING iv_name TYPE csequence iv_value TYPE csequence
                          RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_http.
  METHODS with_retry      IMPORTING iv_max TYPE i DEFAULT 3 iv_backoff_ms TYPE i DEFAULT 500
                                    it_on_status TYPE zif_ab_v1_ut_types=>ty_string_tab OPTIONAL
                          RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_http.
  METHODS with_cache      IMPORTING iv_ttl_seconds TYPE i
                          RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_http.
  METHODS with_log        IMPORTING io_log TYPE REF TO zif_ab_v1_ut_log
                          RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_http.

  "--- calls -------------------------------------------------------------
  "! [D] generic request. iv_path is appended to the base url/destination.
  METHODS request
    IMPORTING iv_method TYPE csequence iv_path TYPE csequence OPTIONAL
              iv_body TYPE csequence OPTIONAL iv_body_x TYPE xstring OPTIONAL
              it_query TYPE zif_ab_v1_ut_types=>ty_nv_tab OPTIONAL
    RETURNING VALUE(rs_response) TYPE ty_response
    RAISING   zcx_ab_v1_ut.

  "! [D] serialize is_body -> JSON, send, deserialize response JSON -> cs_result.
  METHODS get_json    IMPORTING iv_path TYPE csequence OPTIONAL it_query TYPE zif_ab_v1_ut_types=>ty_nv_tab OPTIONAL
                      EXPORTING es_result TYPE any RETURNING VALUE(rs_response) TYPE ty_response RAISING zcx_ab_v1_ut.
  METHODS post_json   IMPORTING iv_path TYPE csequence OPTIONAL is_body TYPE any
                      EXPORTING es_result TYPE any RETURNING VALUE(rs_response) TYPE ty_response RAISING zcx_ab_v1_ut.
  METHODS put_json    IMPORTING iv_path TYPE csequence OPTIONAL is_body TYPE any
                      EXPORTING es_result TYPE any RETURNING VALUE(rs_response) TYPE ty_response RAISING zcx_ab_v1_ut.
  METHODS patch_json  IMPORTING iv_path TYPE csequence OPTIONAL is_body TYPE any
                      EXPORTING es_result TYPE any RETURNING VALUE(rs_response) TYPE ty_response RAISING zcx_ab_v1_ut.
  METHODS delete_     IMPORTING iv_path TYPE csequence OPTIONAL
                      RETURNING VALUE(rs_response) TYPE ty_response RAISING zcx_ab_v1_ut.

  "! [D] follow OData __next / offset pagination; io_consumer->on_page( body ) per page.
  METHODS paginate    IMPORTING iv_path TYPE csequence it_query TYPE zif_ab_v1_ut_types=>ty_nv_tab OPTIONAL
                                io_consumer TYPE REF TO zif_ab_v1_ut_http_page RAISING zcx_ab_v1_ut.

  METHODS download_binary IMPORTING iv_path TYPE csequence OPTIONAL
                          RETURNING VALUE(rv) TYPE xstring RAISING zcx_ab_v1_ut.
  METHODS upload_multipart IMPORTING iv_path TYPE csequence OPTIONAL it_parts TYPE zif_ab_v1_ut_types=>ty_nv_tab
                          RETURNING VALUE(rs_response) TYPE ty_response RAISING zcx_ab_v1_ut.

  "--- OData query builder [C] -----------------------------------------
  METHODS odata_filter IMPORTING it_ranges TYPE zif_ab_v1_ut_types=>ty_nv_tab   " field -> "OP:value"
                       RETURNING VALUE(rv) TYPE string.
  METHODS odata_query  IMPORTING iv_filter TYPE csequence OPTIONAL iv_select TYPE csequence OPTIONAL
                                 iv_expand TYPE csequence OPTIONAL iv_top TYPE i DEFAULT 0 iv_skip TYPE i DEFAULT 0
                       RETURNING VALUE(rt) TYPE zif_ab_v1_ut_types=>ty_nv_tab.

  "--- SOAP [D] --------------------------------------------------------
  METHODS soap_call    IMPORTING iv_action TYPE csequence iv_request_xml TYPE csequence
                                 iv_path TYPE csequence OPTIONAL
                       RETURNING VALUE(rv_response_xml) TYPE string RAISING zcx_ab_v1_ut.
  METHODS soap_envelope IMPORTING iv_body_xml TYPE csequence it_header_xml TYPE zif_ab_v1_ut_types=>ty_string_tab OPTIONAL
                       RETURNING VALUE(rv) TYPE string.

  "--- test seam -----------------------------------------------------
  METHODS set_transport IMPORTING io TYPE REF TO if_web_http_client.

ENDINTERFACE.
```

Helper: `ZIF_AB_V1_UT_HTTP_PAGE` → `METHODS on_page IMPORTING iv_body TYPE string EXPORTING ev_stop TYPE abap_bool RAISING zcx_ab_v1_ut.`

**Impl notes:** `cl_web_http_client_manager=>create_by_http_destination( )` or
`=>create_by_url( )`. If the destination carries an OAuth2 profile it is used
automatically; otherwise `set_oauth2_client_credentials` does a `POST` to the token URL
(`grant_type=client_credentials`), caches the token + expiry in memory, re-fetches on
401 once. `2xx` → success; `>=400` → `ZCX_AB_V1_UT` msg 021 unless `with_retry` covers the
status. Body returned as both `string` and `xstring`.

---

## 3. `ZIF_AB_V1_UT_BULK`

```abap
INTERFACE zif_ab_v1_ut_bulk PUBLIC.

  TYPES:
    BEGIN OF ty_result,
      run_id      TYPE string,
      status      TYPE string,           " COMPLETE | INCOMPLETE | FAILED
      total       TYPE i,
      processed   TYPE i,
      errors      TYPE i,
      resume_token TYPE string,
      messages    TYPE bapiret2_t,
      seconds     TYPE decfloat34,
    END OF ty_result.

  "! [D] Chunk ir_keys by iv_pkg_size; io_handler processes each package;
  "!     commit after each package when iv_commit_each = abap_true.
  "!     If io_store + iv_max_seconds are set, saves a checkpoint and returns
  "!     status = INCOMPLETE + resume_token when the budget is exceeded.
  METHODS run_packaged
    IMPORTING ir_keys        TYPE REF TO data
              iv_pkg_size    TYPE i DEFAULT 1000
              io_handler     TYPE REF TO zif_ab_v1_ut_bulk_handler
              iv_commit_each TYPE abap_bool DEFAULT abap_true
              iv_run_id      TYPE csequence OPTIONAL
              io_store       TYPE REF TO zif_ab_v1_ut_bulk_store OPTIONAL
              iv_max_seconds TYPE i DEFAULT 0
    RETURNING VALUE(rs_result) TYPE ty_result
    RAISING   zcx_ab_v1_ut.

  "! [D] Real parallel dispatch via CL_ABAP_PARALLEL. iv_handler_class is
  "!     instantiated fresh in each work process; iv_context is a serialized
  "!     xstring handed to every instance. Handler must be stateless.
  METHODS run_parallel
    IMPORTING ir_keys          TYPE REF TO data
              iv_pkg_size      TYPE i DEFAULT 1000
              iv_handler_class TYPE seoclsname
              iv_context       TYPE xstring OPTIONAL
              iv_max_tasks     TYPE i DEFAULT 5
              iv_server_group  TYPE rzlli_apcl OPTIONAL
    RETURNING VALUE(rs_result) TYPE ty_result
    RAISING   zcx_ab_v1_ut.

  "! [C] resume a previously INCOMPLETE run from its checkpoint.
  METHODS resume
    IMPORTING iv_run_id  TYPE csequence
              io_store   TYPE REF TO zif_ab_v1_ut_bulk_store
              io_handler TYPE REF TO zif_ab_v1_ut_bulk_handler
              iv_pkg_size TYPE i DEFAULT 1000
              iv_max_seconds TYPE i DEFAULT 0
    RETURNING VALUE(rs_result) TYPE ty_result
    RAISING   zcx_ab_v1_ut.

  "! [C] foreground progress bar + batch job-log line.
  METHODS progress
    IMPORTING iv_done TYPE i iv_total TYPE i iv_text TYPE csequence OPTIONAL.

ENDINTERFACE.
```

```abap
INTERFACE zif_ab_v1_ut_bulk_handler PUBLIC.
  "! Process one package. ir_keys is a REF TO a table slice (same line type as the input).
  METHODS process_package
    IMPORTING ir_keys           TYPE REF TO data
    RETURNING VALUE(rt_messages) TYPE bapiret2_t
    RAISING   zcx_ab_v1_ut.
ENDINTERFACE.

INTERFACE zif_ab_v1_ut_bulk_store PUBLIC.
  METHODS save   IMPORTING iv_run_id TYPE string iv_checkpoint TYPE string iv_processed TYPE i
                 RAISING   zcx_ab_v1_ut.
  METHODS load   IMPORTING iv_run_id TYPE string
                 EXPORTING ev_checkpoint TYPE string ev_processed TYPE i ev_found TYPE abap_bool
                 RAISING   zcx_ab_v1_ut.
  METHODS delete IMPORTING iv_run_id TYPE string RAISING zcx_ab_v1_ut.
ENDINTERFACE.
```

`ZCL_AB_V1_UT_BULK_STORE_MEM` = `CLASS-DATA` table, session-lifetime. Facade `bulk( )`
returns a singleton; the store defaults to `_MEM` unless the caller passes one.

---

## 4. `ZIF_AB_V1_UT_BAPI`

```abap
INTERFACE zif_ab_v1_ut_bapi PUBLIC.

  TYPES:
    BEGIN OF ty_call,   import_ref TYPE REF TO data, tables_ref TYPE REF TO data, END OF ty_call,
    ty_call_tab TYPE STANDARD TABLE OF ty_call WITH EMPTY KEY,
    BEGIN OF ty_mass_result,
      total     TYPE i,
      committed TYPE i,
      failed    TYPE i,
      errors    TYPE bapiret2_t,      " message_v4 carries the source index
    END OF ty_mass_result.

  "! [D] low level - full control via an RFC-style parameter table.
  METHODS call
    IMPORTING iv_bapi   TYPE tfdir-funcname
              it_params TYPE abap_func_parmbind_tab
    RETURNING VALUE(rt_return) TYPE bapiret2_t
    RAISING   zcx_ab_v1_ut.

  "! [D] high level - auto-bind by parameter name (RTTI + FM interface introspection).
  "!     is_import : components map to the BAPI IMPORTING params.
  "!     it_tables : name -> REF TO table, map to the BAPI TABLES params (incl. RETURN).
  METHODS call_by_name
    IMPORTING iv_bapi     TYPE tfdir-funcname
              is_import   TYPE any OPTIONAL
              it_tables   TYPE zif_ab_v1_ut_types=>ty_nv_tab OPTIONAL   " name -> ref-id
              ir_tables   TYPE REF TO data OPTIONAL                     " table of ( name, ref )
              iv_test_run TYPE abap_bool DEFAULT abap_false
    EXPORTING es_export   TYPE any
    RETURNING VALUE(rt_return) TYPE bapiret2_t
    RAISING   zcx_ab_v1_ut.

  "! [D] N calls, BAPI_TRANSACTION_COMMIT every iv_commit_every.
  METHODS mass
    IMPORTING iv_bapi         TYPE tfdir-funcname
              it_calls        TYPE ty_call_tab
              iv_commit_every TYPE i DEFAULT 100
              iv_stop_on_error TYPE abap_bool DEFAULT abap_false
              iv_test_run     TYPE abap_bool DEFAULT abap_false
    RETURNING VALUE(rs_result) TYPE ty_mass_result
    RAISING   zcx_ab_v1_ut.

  METHODS commit   IMPORTING iv_wait TYPE abap_bool DEFAULT abap_true RAISING zcx_ab_v1_ut.   " [D]
  METHODS rollback RAISING zcx_ab_v1_ut.                                                       " [D]

  "! [D] classic batch input for a transaction with no BAPI. CALL TRANSACTION ... USING.
  METHODS bdc_run
    IMPORTING iv_tcode  TYPE tcode
              it_bdcdata TYPE STANDARD TABLE
              iv_mode   TYPE c DEFAULT 'N'
              iv_update TYPE c DEFAULT 'S'
    RETURNING VALUE(rt_return) TYPE bapiret2_t
    RAISING   zcx_ab_v1_ut.

  METHODS bdc_dynpro IMPORTING iv_program TYPE csequence iv_dynpro TYPE csequence
                     CHANGING  ct_bdcdata TYPE STANDARD TABLE.
  METHODS bdc_field  IMPORTING iv_name TYPE csequence iv_value TYPE csequence
                     CHANGING  ct_bdcdata TYPE STANDARD TABLE.

ENDINTERFACE.
```

**Impl notes:** `call` uses `CALL FUNCTION iv_bapi PARAMETER-TABLE it_params`.
`call_by_name` reads the FM interface via `FUNCTION_IMPORT_INTERFACE` / RTTI of the FM
group, builds `abap_func_parmbind_tab`, maps `is_import` components by name, sets
`TEST_RUN`/`TESTRUN` if present, returns the `RETURN`/`ET_RETURN` table. `mass` loops,
accumulates errors with the source index in `message_v4`, commits on the interval,
rolls back the current package on error when `iv_stop_on_error`.

---

## 5. `ZIF_AB_V1_UT_CUTOVER`

```abap
INTERFACE zif_ab_v1_ut_cutover PUBLIC.

  TYPES:
    BEGIN OF ty_task_status,
      name    TYPE string, status TYPE string,   " PENDING | RUNNING | DONE | ERROR | SKIPPED
      started TYPE timestampl, finished TYPE timestampl, seconds TYPE decfloat34,
      message TYPE string,
    END OF ty_task_status,
    ty_task_status_tab TYPE STANDARD TABLE OF ty_task_status WITH KEY name,
    BEGIN OF ty_finding,
      category TYPE string, severity TYPE symsgty, count TYPE i, text TYPE string,
    END OF ty_finding,
    ty_finding_tab TYPE STANDARD TABLE OF ty_finding WITH EMPTY KEY.

  "! [D] run tasks in order; io_executor->run_task( name ) per task; stop or continue on error.
  METHODS task_run
    IMPORTING it_task_names   TYPE zif_ab_v1_ut_types=>ty_string_tab
              io_executor     TYPE REF TO zif_ab_v1_ut_cutover_exec
              iv_stop_on_error TYPE abap_bool DEFAULT abap_true
    RETURNING VALUE(rt_status) TYPE ty_task_status_tab
    RAISING   zcx_ab_v1_ut.

  "! [C] system readiness: transports not imported, jobs cancelled in the last iv_hours,
  "!     lock entries, SM13 update errors, spool errors, optional RFC ping list.
  METHODS readiness_check
    IMPORTING iv_hours        TYPE i DEFAULT 24
              it_rfc_dests    TYPE zif_ab_v1_ut_types=>ty_string_tab OPTIONAL
    RETURNING VALUE(rt_findings) TYPE ty_finding_tab.

  "! [D] BAPI_USER_LOCK per user; skips it_except + already-locked users; tracks its own.
  METHODS lock_users   IMPORTING it_except TYPE zif_ab_v1_ut_types=>ty_string_tab OPTIONAL
                       RETURNING VALUE(rt_locked) TYPE zif_ab_v1_ut_types=>ty_string_tab
                       RAISING   zcx_ab_v1_ut.
  METHODS unlock_users RAISING zcx_ab_v1_ut.   " unlocks only the ones lock_users locked

  "! [D] set released/scheduled jobs to suspended; release_jobs reverses only its own.
  METHODS suspend_jobs  IMPORTING iv_report_only TYPE abap_bool DEFAULT abap_true
                        RETURNING VALUE(rt_jobs) TYPE zif_ab_v1_ut_types=>ty_string_tab
                        RAISING   zcx_ab_v1_ut.
  METHODS release_jobs  RAISING zcx_ab_v1_ut.

ENDINTERFACE.

INTERFACE zif_ab_v1_ut_cutover_exec PUBLIC.
  METHODS run_task IMPORTING iv_name TYPE string RAISING zcx_ab_v1_ut.
ENDINTERFACE.
```

**Impl notes:** each `[D]` method `AUTHORITY-CHECK`s first (`S_USER_GRP` activity 05 for
lock, `S_BTCH_ADM`, `S_ADMI_FCD`). Locked-user + suspended-job registers are `CLASS-DATA`
(session-lifetime). `suspend_jobs` defaults to **report-only** (`iv_report_only`).
`readiness_check` reads `E070`/`E071`, `TBTCO`, `SEQG3` (`ENQUEUE_READ`), `VBERROR`,
`TSP01`, optional `RFC_PING`.

---

## 6. `ZIF_AB_V1_UT_TRANSPORT`

```abap
INTERFACE zif_ab_v1_ut_transport PUBLIC.

  TYPES:
    BEGIN OF ty_object, pgmid TYPE pgmid, object TYPE trobjtype, obj_name TYPE sobj_name,
                        lock TYPE flag, END OF ty_object,
    ty_object_tab TYPE STANDARD TABLE OF ty_object WITH EMPTY KEY,
    BEGIN OF ty_inventory, object TYPE trobjtype, count TYPE i, END OF ty_inventory,
    ty_inventory_tab TYPE STANDARD TABLE OF ty_inventory WITH EMPTY KEY.

  "! [C] objects in a request incl. its sub-tasks (E070 / E071).
  METHODS objects_in_request
    IMPORTING iv_trkorr TYPE trkorr
    RETURNING VALUE(rt) TYPE ty_object_tab
    RAISING   zcx_ab_v1_ut.

  "! [C] where-used for a repository object (FM RS_EU_CROSSREF; WBCROSSGT fallback).
  METHODS where_used
    IMPORTING iv_type TYPE csequence iv_name TYPE csequence
    RETURNING VALUE(rt) TYPE ty_object_tab
    RAISING   zcx_ab_v1_ut.

  "! [C] Z/Y object inventory of a package (TADIR), counts by type + orphan flag.
  METHODS custom_code_inventory
    IMPORTING iv_package TYPE devclass
    EXPORTING et_by_type TYPE ty_inventory_tab
              et_objects TYPE ty_object_tab
    RAISING   zcx_ab_v1_ut.

  "! [C] which request(s) currently lock an object.
  METHODS locking_requests
    IMPORTING iv_pgmid TYPE pgmid iv_object TYPE trobjtype iv_obj_name TYPE csequence
    RETURNING VALUE(rt) TYPE zif_ab_v1_ut_types=>ty_string_tab.

ENDINTERFACE.
```

---

## 7. Demo – `ZAB_V1_UT_DEMO_INT`

Selection screen: listbox area (`HTTP`/`BULK`/`BAPI`/`CUTOVER`/`TRANSPORT`) + params
`p_url` (HTTP base), `p_dest` (RFC dest), `p_bapi`, `p_trkorr`, `p_pkg` (devclass),
`p_write` (allow Defer side effects). Every method gets one line of output, each area in
its own `TRY/CATCH cx_root`.

| Area | Demo (read-only unless `p_write`) |
|---|---|
| HTTP | `for_url( p_url )->with_retry( )->get_json( )` against a public echo endpoint or `p_url`; `odata_filter` / `odata_query` builders printed; `soap_envelope` printed |
| BULK | `run_packaged` over an in-memory key table of 25 with a local handler that just counts; `progress`; checkpoint via `_MEM` store; `resume` |
| BAPI | `call_by_name( 'BAPI_USER_GET_DETAIL' username = sy-uname )` (read-only, no commit); `bdc_dynpro`/`bdc_field` builders printed |
| CUTOVER | `readiness_check( )` → findings table; `lock_users` only if `p_write` |
| TRANSPORT | `objects_in_request( p_trkorr )`; `where_used( 'TABL' 'ZAB_V1_UT_ADPT' )`; `custom_code_inventory( p_pkg )` |

---

## 8. Message class additions

| No | Text |
|---|---|
| 021 | HTTP &1 &2 returned status &3 |
| 022 | HTTP request failed: &1 |
| 023 | OAuth2 token request failed: &1 |
| 024 | SOAP call &1 failed: &2 |
| 025 | Bulk run &1: &2 |
| 026 | Bulk handler error in package &1: &2 |
| 027 | Bulk checkpoint store error: &1 |
| 028 | BAPI &1 not found or not remote-enabled |
| 029 | BAPI &1 parameter &2 could not be bound |
| 030 | BAPI mass stopped at index &1: &2 |
| 031 | CALL TRANSACTION &1 ended with &2 |
| 032 | Cutover task &1 failed: &2 |
| 033 | Not authorized for cutover operation &1 |
| 034 | Transport &1 not found |
| 035 | Where-used lookup failed for &1 &2 |

---

## 9. Build order (after v1.0.0 C1)

1. Domain values + message numbers 021–035.
2. `ZIF_AB_V1_UT_HTTP_PAGE`, `_BULK_HANDLER`, `_BULK_STORE`, `_CUTOVER_EXEC` (helper interfaces).
3. The 5 area interfaces.
4. `ZCL_AB_V1_UT_HTTP` → `_BULK` (+ `_BULK_STORE_MEM`) → `_BAPI` → `_CUTOVER` → `_TRANSPORT`, each with ABAP Unit.
5. Facade accessors + seams.
6. `ZAB_V1_UT_DEMO_INT` + doc refresh (02 / 03 / 04 / 06 / 07).
7. ATC (production + gated profiles) → fix → extend C1 release to the new interfaces + facade.
