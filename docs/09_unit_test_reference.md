# 09 – Unit Test Reference (every utility method)

**Version:** 1.0 · Covers v1.0.0 (18 areas) + v1.1.0 toolkit (5 areas).
Per method: what it does, RAP-mode, and the ABAP Unit test that pins it — or why there
isn't one (side effect / GUI / live-system dependency covered by integration tests).

**How to run:** SE80 → class → *Execute ▸ Unit Tests* · ADT: `Ctrl+Shift+F10` on the class
or the package · whole package: tcode `SAUNIT` / report `RS_AUCV_RUNNER` on `ZABAP_UTIL`.
All local test classes are `DURATION SHORT` / `RISK LEVEL HARMLESS` — safe on any client,
nothing is sent, no `COMMIT`.

**"Needs" legend**
| Tag | Meaning |
|---|---|
| **unit** | deterministic ABAP Unit assertion, no prerequisites |
| **unit·tolerant** | ABAP Unit, but wrapped in `TRY/CATCH` — asserts only if the system has the resource (factory calendar, SNRO object, XCO) |
| **live** | needs a real backend (HTTP endpoint, TCURR rates, UoM, work processes) → integration test INT-0x |
| **GUI** | SAP GUI only → `ZCL_AB_V1_UT_GUI`, integration test INT-02 |
| **—** | thin wrapper / side-effecting, exercised only through `ZAB_V1_UT_DEMO*` |

---

## Coverage at a glance

| Area | Impl class | Methods | Unit-tested | Notes |
|---|---|--:|--:|---|
| STR | `ZCL_AB_V1_UT_STR` | 26 | 13 | pure; untested ones are thin format wrappers |
| CONV | `ZCL_AB_V1_UT_CONV` | 19 | 11 | currency/unit need TCURR/UoM (live) |
| TAB | `ZCL_AB_V1_UT_TAB` | 10 | 8 | `map_corresponding` / `sort_dynamic` via others |
| DB | `ZCL_AB_V1_UT_DB` | 5 | 5 | osql on `T000` |
| FILE | `ZCL_AB_V1_UT_FILE` | 11 | 3 | `as_*` = Gated app-server → INT only |
| EXCEL | `ZCL_AB_V1_UT_EXCEL` | 3 | 2 | tolerant (XCO) |
| JSON | `ZCL_AB_V1_UT_JSON` | 6 | 6 | full round-trips |
| LOG | `ZCL_AB_V1_UT_LOG` | 10 | 6 | `save`/`display` = DEFER/GUI |
| MSG | `ZCL_AB_V1_UT_MSG` | 8 | 7 | |
| AUTH | `ZCL_AB_V1_UT_AUTH` | 4 | 3 | result-shape only (role data varies) |
| NUM | `ZCL_AB_V1_UT_NUM` | 3 | 1 | tolerant (SNRO) |
| MAIL | `ZCL_AB_V1_UT_MAIL` | 2 | 1 | `send` = DEFER → INT-05 |
| ATTACH | `ZCL_AB_V1_UT_ATTACH_STUB` | 8 | 6 | stub is the tested default; GOS adapter unwired |
| ALV | `ZCL_AB_V1_UT_GUI` | 3 | 0 | GUI → INT-02 |
| SYS | `ZCL_AB_V1_UT_SYS` | 4 | 4 | |
| CFG | `ZCL_AB_V1_UT_CFG` | 5 | 3 | TVARVC rows vary → negative paths tested |
| RAP | `ZCL_AB_V1_UT_RAP` | 4 | 3 | |
| JOB | `ZCL_AB_V1_UT_JOB` | 2 | 1 | `schedule_job` = DEFER |
| HTTP | `ZCL_AB_V1_UT_HTTP` | 22 | 4 | builders unit-tested; calls = DEFER → INT-08 |
| BULK | `ZCL_AB_V1_UT_BULK` | 4 | 5 tests | `run_parallel` = INT-09 |
| BAPI | `ZCL_AB_V1_UT_BAPI` | 8 | 4 | `RFC_SYSTEM_INFO` round-trip; mass/commit = INT |
| CUTOVER | `ZCL_AB_V1_UT_CUTOVER` | 6 | 3 | locks/jobs = side-effecting → demo `p_side` |
| TRANSPORT | `ZCL_AB_V1_UT_TRANSPORT` | 4 | 5 tests | reads E070/TADIR/WBCROSSGT |
| facade | `ZCL_AB_V1_UT` | 27 accessors | 5 tests | singleton + seam + no-GUI guard |

`ZCL_AB_V1_UT_DEMO_BULK_H` and the two demo reports carry no unit tests (they *are* the
manual test — INT-01 / INT-07).

---

## STR · `ZIF_AB_V1_UT_STR` — all Core

| Method | Verifies | Test | Needs |
|---|---|---|---|
| `to_amount` | `'1.234,56'`(EU) & `'1,234.56'`(US) → `1234.56`; `'abc'` → `ZCX` | `to_amount_eu` `to_amount_us` `to_amount_bad` | unit |
| `from_amount` | `1234.50` EUR/EU → `'1.234,50'` | `amount_roundtrip` | unit |
| `to_quantity` / `from_quantity` | — | — | live (UoM) |
| `to_date` | `31.12.2026` / `2026-12-31` / `20261231` → `d'20261231'`; `2026-13-45` → `ZCX` | `to_date_formats` `to_date_bad` | unit |
| `from_date` `to_time` `from_time` | — | — | — |
| `alpha_in` / `alpha_out` | `'4711'` ↔ `'0000004711'` | `alpha` | unit |
| `pad` `split` `join` | — | — | — |
| `mask` | `'4111…1111'` suffix 4 → `'************1111'` | `mask_pan` | unit |
| `to_camel` / `to_snake` | `SalesOrderItem` ↔ `sales_order_item` (pascal) | `snake_camel` | unit |
| `base64_encode` / `base64_decode` / `to_xstring` | `to_xstring('Hello')` → encode → decode is identity | `base64_roundtrip` | unit |
| `from_xstring` | — | — | — |
| `hash` | SHA-256 of `'abc'` = NIST vector `ba7816bf…` | `hash_sha256` | unit |
| `regex_groups` | `2026-08-31` / `(\d{4})-(\d{2})-(\d{2})` → 3 groups | `regex_grp` | unit |
| `regex_match` `regex_replace` `amount_in_words` | — | — | — |
| `is_valid` | `a@b.com` EMAIL → true; `nope` → false | `validators` | unit |

---

## CONV · `ZIF_AB_V1_UT_CONV` — all Core

| Method | Verifies | Test | Needs |
|---|---|---|---|
| `add_days` | `20260101` + 30 → `20260131` | `add_days_t` | unit |
| `add_months` | month-end clamp: `20260131` ±1m → `20260228` / `20251231` | `add_months_clamp` | unit |
| `add_years` | `20260115` + 3y → `20290115` | `add_years_t` | unit |
| `days_between` / `months_between` | 30 days / 3 months | `diffs` | unit |
| `years_between` | — | — | — |
| `age` | DOB `20000901` on `…0831` = 25, on `…0901` = 26 | `age_t` | unit |
| `period_bounds` | MONTH `20260215` → 01–28 Feb; QUARTER `20260815` → Jul 1–Sep 30 | `period_month` `period_quarter` | unit |
| `weekday` | in range 1..7 | `weekday_range` | unit |
| `week_number` | — | — | — |
| `add_workdays` / `is_workday` | +1 workday from a Friday advances the date | `workdays_opt` | unit·tolerant (factory cal `DE`) |
| `ts_split` / `ts_merge` | `…123045.5` → date `20260831` + time `123045` | `ts_roundtrip` | unit |
| `tz_to_local` / `tz_from_local` | — | — | — |
| `round` | `2.345`→`2.35` (half-up); `2.349` DOWN → `2.34` | `round_modes` | unit |
| `convert_currency` | — | — | live (TCURR) |
| `convert_unit` | — | — | live (UoM) |

---

## TAB · `ZIF_AB_V1_UT_TAB` — all Core

| Method | Verifies | Test | Needs |
|---|---|---|---|
| `create_dynamic` | `'T000'` → bound ref, kind = table | `create_dyn` | unit |
| `diff` | old/new keyed on `ID` → 1 insert / 1 update / 1 delete, correct ids | `diff_ins_upd_del` | unit |
| `to_ranges` | `(10)(20)` → 2 rows `I`/`EQ`/low | `ranges_build` | unit |
| `chunk` | 10 rows / size 4 → 3 chunks | `chunk_split` | unit |
| `distinct` | 3 rows, 1 dup → 2 | `distinct_all` | unit |
| `fingerprint` | equal structs → equal hash; differing → differ | `fingerprint_t` | unit |
| `deep_equal` | `a==b`, `a!=c` by ref | `deep_equal_t` | unit |
| `aggregate` | group by `GRP`, `SUM(VAL)`/`COUNT` → A=15/2, 2 groups | `aggregate_sum` | unit |
| `map_corresponding` / `sort_dynamic` | exercised via `diff` / `aggregate` internals | — | — |

---

## DB · `ZIF_AB_V1_UT_DB`

| Method | Verifies | Test | Needs |
|---|---|---|---|
| `exists` | `T000` + `MANDT=sy-mandt` → true; bogus client → false | `exists_true` `exists_false` | unit (osql) |
| `describe` | `T000` → ≥ 1 row | `describe_tab` | unit |
| `exists` (guard) | unknown entity → `ZCX` (not a dump) | `bad_entity` | unit |
| `where_from_ranges` | `bukrs=1000`,`gjahr=2026` → `BUKRS = '1000'` … | `where_helper` | unit |
| `read_single` | via `exists` internals | — | unit |
| `read` **[Gated]** | dynamic SELECT — reports/migration only | — | live |

---

## FILE · `ZIF_AB_V1_UT_FILE`

| Method | Verifies | Test | Needs |
|---|---|---|---|
| `mime_type` | `.pdf` / `.XLSX` / no-ext → correct MIME | `mime` | unit |
| `zip` / `unzip` | 2 entries in → base64 zip → 2 entries out, byte-equal | `zip_roundtrip` | unit |
| `csv_build` / `csv_parse` | 2 rows `;`-sep, header → round-trip by column | `csv_roundtrip` | unit |
| `resolve_logical` | — | — | live (FILE tcode) |
| `as_read/as_write/as_delete/as_exists/as_list_dir` **[Gated]** | app-server `OPEN DATASET` | — | live (INT) |

---

## EXCEL · `ZIF_AB_V1_UT_EXCEL` — all Core

| Method | Verifies | Test | Needs |
|---|---|---|---|
| `write` | table → xstring starting `PK` (zip magic) | `write_produces_xlsx` | unit·tolerant (XCO) |
| `write` + `read` | 2-row table survives write→read | `roundtrip` | unit·tolerant |
| `generate_template` | — | — | — |

---

## JSON · `ZIF_AB_V1_UT_JSON` — all Core

| Method | Verifies | Test | Needs |
|---|---|---|---|
| `serialize` / `deserialize` | nested struct (person+address) survives round-trip | `roundtrip` | unit |
| `serialize` / `deserialize` (camelCase) | `first_name` → `"firstName"` and back | `camel_case` | unit |
| `pretty` | compact → newlines, `"x,y"` preserved, still parseable | `pretty_valid` | unit |
| `describe` | struct → JSON schema with `"kind": "elementary"` | `describe_struct` | unit |
| `xml_serialize` / `xml_deserialize` | struct survives XML round-trip | `xml_roundtrip` | unit |

---

## LOG · `ZIF_AB_V1_UT_LOG`

| Method | Verifies | Test | Needs |
|---|---|---|---|
| `create` | returns a handle (no BAL object required to collect) | (all) | unit |
| `add_t100` / `add_bapiret` | 2×T100 + 1×bapiret → `to_bapiret( )` has 3 | `collect_msgs` | unit |
| `add_exception` | one `ZCX` → 1 message | `from_exception` | unit |
| `to_bapiret` | see above | `collect_msgs` `from_exception` | unit |
| `to_string` | contains the message text (`*hello*`) | `as_string` | unit |
| `add_symsg` `handle` | via `add_*` internals | — | unit |
| `save` **[DEFER]** | `BAL_DB_SAVE` on 2nd connection | — | live (INT-03) |
| `display` **[GUI]** | — | — | GUI |

---

## MSG · `ZIF_AB_V1_UT_MSG` — all Core

| Method | Verifies | Test | Needs |
|---|---|---|---|
| `t100_to_text` | msg 013 `SAVE`/`1` → *"Operation SAVE not allowed in RAP phase 1"* | `t100_text` | unit |
| `bapiret_has_error` | E present → true; only S/I → false | `bapiret_helpers` | unit |
| `bapiret_max_severity` | S/W/E list → `'E'` | `bapiret_helpers` | unit |
| `bapiret_filter` | filter `'E'` → 1 row | `bapiret_helpers` | unit |
| `raise` | raises `ZCX` whose text contains the param | `raise_ok` | unit |
| `exception_to_text` | `ZCX` → text contains `*boom*` | `exc_text` | unit |
| `t100_to_bapiret` `symsg_to_bapiret` | via `raise` / `t100_to_text` internals | — | unit |

---

## AUTH · `ZIF_AB_V1_UT_AUTH` — all Core

| Method | Verifies | Test | Needs |
|---|---|---|---|
| `check` | `S_TCODE`/`SU3` → returns a clean `abap_bool` (never dumps) | `check_returns_bool` | unit |
| `is_user_valid` | `sy-uname` → true; `ZZNOUSER9` → false | `current_user_valid` `unknown_user_invalid` | unit |
| `check_or_raise` | via `check` + `MSG~raise` | — | unit |
| `user_has_role` | — | — | live (role data) |

---

## NUM · `ZIF_AB_V1_UT_NUM`

| Method | Verifies | Test | Needs |
|---|---|---|---|
| `next` | two draws from `ZAB_V1_UT`/`01` strictly increasing | `next_increasing` | unit·tolerant (SNRO) |
| `next_bulk` **[DEFER]** | — | — | live |
| `status` | — | — | live |

---

## MAIL · `ZIF_AB_V1_UT_MAIL`

| Method | Verifies | Test | Needs |
|---|---|---|---|
| `build_html_body` | title → `<h2>`, paragraphs → `<p>`, table → `<table>`/`<td>`, `& < >` escaped | `html_title` `html_table` `html_escaped` | unit |
| `send` **[DEFER]** | `cl_bcs`, `COMMIT` only if `is_mail-commit_work` | — | live (INT-05) |

---

## ATTACH · `ZIF_AB_V1_UT_ATTACH` (tested via `ZCL_AB_V1_UT_ATTACH_STUB`)

| Method | Verifies | Test | Needs |
|---|---|---|---|
| `new_guid_x16` / `_c32` / `_c22` | non-initial, unique, length 22 | `guids` | unit |
| `attach` / `list` / `get` | attach → list shows it (name, 5 bytes); `get` byte-equal; other BO key → empty | `attach_list_get` | unit |
| `get` (guard) | unknown id → `ZCX` | `get_unknown` | unit |
| `to_solix` / `from_solix` | 16-byte xstring → solix table → back identical | `solix_roundtrip` | unit |
| GOS adapter (`ZCL_AB_V1_UT_ATTACH_GOS`) | ships **unwired** — raises "not wired" | — | live |

---

## ALV · `ZIF_AB_V1_UT_ALV` — all GUI (`ZCL_AB_V1_UT_GUI`)

| Method | Verifies | Test | Needs |
|---|---|---|---|
| `show` / `show_dynamic` / `build_fieldcat` | ALV renders; fieldcat generated | — | GUI (INT-02) |

---

## SYS · `ZIF_AB_V1_UT_SYS` — all Core

| Method | Verifies | Test | Needs |
|---|---|---|---|
| `system_info` | `sysid` / `client` = `sy-sysid` / `sy-mandt` | `info` | unit |
| `object_exists` | `TABL T000` / `CLAS ZCL_AB_V1_UT_STR` → true; bogus → false | `exists_tabl` `exists_clas` `exists_missing` | unit |
| `timer_start` / `timer_stop` | elapsed + CPU ≥ 0 after a busy loop | `timer` | unit |

---

## CFG · `ZIF_AB_V1_UT_CFG` — all Core

| Method | Verifies | Test | Needs |
|---|---|---|---|
| `enum_values` | domain `ZAB_V1_UT_AREA` → 18 values incl. `JSON` | `enum_area` | unit |
| `tvarv_value` (guard) | unknown var → `ZCX` | `tvarv_missing` | unit |
| `is_feature_on` | unknown feature → false | `feature_off` | unit |
| `tvarv_range` `read_config` | — | — | live (TVARVC / config table rows) |

> `enum_area` asserts **18** — v1.1 added 5 domain values, so this will read **23**. Update
> the expected count when the domain is re-activated, or relax it to `>= 18`.

---

## RAP · `ZIF_AB_V1_UT_RAP` — all Core

| Method | Verifies | Test | Needs |
|---|---|---|---|
| `new_cid` | non-initial, unique across calls | `cid_unique` | unit |
| `bapiret_to_text` | E/S list → 2 lines, `'E: boom*'` | `ret_to_text` | unit |
| `corresponding_control` | copies only fields flagged in the control struct | `control_copy` | unit |
| `messages_to_bapiret` | via `bapiret_to_text` internals | — | unit |

---

## JOB · `ZIF_AB_V1_UT_JOB`

| Method | Verifies | Test | Needs |
|---|---|---|---|
| `is_finished` | unknown job → false | `unknown_job_not_finished` | unit |
| `schedule_job` **[DEFER]** | `JOB_OPEN`/`SUBMIT`/`JOB_CLOSE` | — | live |

---

## HTTP · `ZIF_AB_V1_UT_HTTP`

| Method | Verifies | Test | Needs |
|---|---|---|---|
| `for_url` / `with_header` / `with_retry` | fluent chain returns the same instance | `fluent_returns_self` | unit |
| `odata_filter` | `Bukrs eq:1000`, `Gjahr 2026` → `bukrs eq '1000' and gjahr eq '2026'` | `odata_filter_t` | unit |
| `odata_query` | `$filter` / `$top` / `$select` entries emitted | `odata_query_t` | unit |
| `soap_envelope` | wraps `<soapenv:Envelope>` / `<soapenv:Body>` | `soap_envelope_t` | unit |
| `for_destination` `set_auth_*` `with_cache` `with_log` | config setters — exercised in `ZAB_V1_UT_DEMO_INT` | — | — |
| `request` `get_json` `post_json` `put_json` `patch_json` `delete_` `paginate` `download_binary` `upload_multipart` `soap_call` **[DEFER]** | real network call over `cl_http_client` | — | live (INT-08) |

---

## BULK · `ZIF_AB_V1_UT_BULK` (+ `ZCL_AB_V1_UT_BULK_STORE_MEM`)

| Method | Verifies | Test | Needs |
|---|---|---|---|
| `run_packaged` | 10 keys / pkg 3 → COMPLETE, `processed=10`, every key handled once | `packaged_all` | unit |
| `run_packaged` (errors) | handler returns `E` → `errors` counter increments per package | `packaged_errors` | unit |
| `resume` | store seeded at checkpoint 10 → resumes at key 7, COMPLETE, checkpoint cleared | `resume_from_ckpt` | unit |
| `run_packaged` (guard) | non-table `ir_keys` → `ZCX` (no dump) | `invalid_keys` | unit |
| `ZCL_AB_V1_UT_BULK_STORE_MEM` | `save` → `load` → `delete` round-trip | `store_roundtrip` | unit |
| `progress` | `SAPGUI_PROGRESS_INDICATOR` + batch job-log line | — | — |
| `run_parallel` **[DEFER]** | `cl_abap_parallel` dispatch across work processes | — | live (INT-09) |

---

## BAPI · `ZIF_AB_V1_UT_BAPI`

| Method | Verifies | Test | Needs |
|---|---|---|---|
| `bdc_dynpro` / `bdc_field` | build 3 `BDCDATA` rows with `PROGRAM`/`DYNBEGIN`/`FNAM`/`FVAL` set | `bdc_builders` | unit |
| `call` (guard) | unknown FM → `ZCX` (msg 028) | `unknown_bapi` | unit |
| `bdc_run` (guard) | unknown tcode → `ZCX` (msg 031) | `unknown_tcode` | unit |
| `call_by_name` | `RFC_SYSTEM_INFO` → `es_export` (`rfcsi`) populated via FUPARAREF auto-bind | `call_by_name_ro` | unit |
| `call` `mass` `commit` `rollback` `bdc_run` **[DEFER]** | real BAPI + `BAPI_TRANSACTION_*` | — | live (demo `p_side`, test-run) |

---

## CUTOVER · `ZIF_AB_V1_UT_CUTOVER`

| Method | Verifies | Test | Needs |
|---|---|---|---|
| `task_run` | 3 tasks via injected executor → 3× DONE, executor saw all | `tasks_all_ok` | unit |
| `task_run` (stop-on-error) | middle task fails → DONE / ERROR / SKIPPED + message set | `tasks_stop_error` | unit |
| `readiness_check` | returns ≥ 1 finding, never dumps (VBHDR/TBTCO/APQI reads) | `readiness_runs` | unit |
| `lock_users` / `unlock_users` **[DEFER]** | `BAPI_USER_LOCK` / `_UNLOCK`, `S_USER_GRP` check | — | live (demo `p_side`) |
| `suspend_jobs` / `release_jobs` **[DEFER]** | report-only list; live change raises msg 032 | — | — |

---

## TRANSPORT · `ZIF_AB_V1_UT_TRANSPORT` — all Core (read-only)

| Method | Verifies | Test | Needs |
|---|---|---|---|
| `custom_code_inventory` | `$TMP` → no dump; objects ≥ types | `inventory_tmp` | unit |
| `custom_code_inventory` (guard) | unknown package → `ZCX` | `inventory_bad_pkg` | unit |
| `objects_in_request` (guard) | unknown request → `ZCX` (msg 034) | `request_not_found` | unit |
| `locking_requests` | unknown object → empty table | `locking_empty` | unit |
| `where_used` | WBCROSSGT read path runs without dumping | `where_used_runs` | unit |

---

## Facade · `ZCL_AB_V1_UT`

| Aspect | Verifies | Test |
|---|---|---|
| lazy singletons | `str()`/`json()`/`conv()`/`bulk()`/`bapi()`/`cutover()`/`transport()` return the same instance each call | `accessors_are_singletons` `toolkit_accessors` |
| `http()` | a **fresh** instance per call (fluent/stateful); `set_http()` seam pins one | `toolkit_accessors` |
| seam + `reset` | `set_str(double)` → `str()` returns the double; `reset()` restores the real impl | `injection_and_reset` |
| phase guard | `set_phase` / `phase` round-trip; `reset` → `unknown` | `phase_roundtrip` |
| no GUI leak | no `CL_GUI*` / `CL_SALV*` reachable from any `ZCL_AB_V1_UT*` headless class (WBCROSSGT scan, `ZCL_AB_V1_UT_GUI` excluded) | `no_gui_dependencies` |

---

## Prerequisites for an all-green run

Most tests are self-contained. These make the **tolerant** ones assert instead of skip:

| Resource | Enables | Setup |
|---|---|---|
| SNRO object `ZAB_V1_UT` interval `01` | `NUM~next_increasing` | tcode `SNRO` |
| Factory calendar `DE` | `CONV~workdays_opt` | `SCAL` (usually present) |
| XCO xlsx runtime | `EXCEL~write/roundtrip` | standard on S/4 2023 |
| SLG0 object `ZAB_V1_UT` | `LOG~save` (INT-03) | tcode `SLG0` |
| Domain `ZAB_V1_UT_AREA` re-activated | fix `CFG~enum_area` expected count 18 → 23 | after v1.1 pull |

## v1.1 test patterns (reuse these)

- **Injected collaborator** — `task_run`/`run_packaged` take an interface (`…_EXEC`,
  `…_HANDLER`); tests pass a tiny local `lcl_*` double, never a real backend.
- **In-memory store** — `ZCL_AB_V1_UT_BULK_STORE_MEM` (session `CLASS-DATA`) is the default
  and the test store; `=>reset( )` in `setup`.
- **Tolerant env checks** — wrap a call that needs a system resource in `TRY / CATCH
  zcx_ab_v1_ut` and assert only in the success branch (see `CONV~workdays_opt`,
  `NUM~next_increasing`, `EXCEL~*`).
- **Guard tests** — every "bad input" path asserts a `ZCX_AB_V1_UT`, never a dump
  (`cl_abap_unit_assert=>fail( )` after the call, `CATCH` swallows the expected exception).
- **Read-only probes** — `RFC_SYSTEM_INFO`, `T000`, `$TMP`, `sy-uname` are safe fixtures
  present on every system.
