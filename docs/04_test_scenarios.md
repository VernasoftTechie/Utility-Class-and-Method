# 04 – ZCL_AB_V1_UT Utility Framework – Test Scenarios

**Version:** 1.0 · **Status:** DRAFT · Companion to `03_technical_specification.md`

Test framework: **ABAP Unit only**. One local test class per implementation
(`*.clas.testclasses.abap`). `RISK LEVEL HARMLESS`, `DURATION SHORT` unless noted.
No writes to real Application Log / SOST / number ranges / file system outside the test's
own temp scope. Coverage target: **≥ 90 % line** on headless classes;
`ZCL_AB_V1_UT_GUI` excluded (GUI-bound, documented deviation §7 of doc 01).

Test isolation techniques:
- **`CL_OSQL_TEST_ENVIRONMENT`** – for `AGR_USERS`, `USR02`, `TVARVC`, `T000`, `ZAB_V1_UT_ADPT`, any table read by `DB`/`CFG`/`AUTH`/`SYS`.
- **BAL in-memory logs** – `create( iv_in_memory = abap_true )`; assert via `to_bapiret( )`; never `save( )`.
- **Facade injection** – `ZCL_AB_V1_UT=>set_<area>( double )` / `reset( )` in `setup`/`teardown`.
- **Send-port double** – `ZIF_AB_V1_UT_MAIL` replaced by a spy that captures `ty_mail`.
- **Stub adapter** – `ZCL_AB_V1_UT_ATTACH_STUB` under test for attach/list/get.

---

## TS-00 · Cross-cutting

| ID | Scenario | Expected |
|---|---|---|
| X-01 | **Dependency guard** – reflect used objects of `ZCL_AB_V1_UT` + every headless impl | no name starting `CL_GUI` / `CL_SALV` / `ZCL_AB_V1_UT_GUI` |
| X-02 | Facade accessor returns same instance twice | identical reference (singleton) |
| X-03 | `set_<area>` then accessor | returns the injected double |
| X-04 | `reset( )` after injection | accessor rebuilds the real default |
| X-05 | Every `[D]` method with `phase = interaction` | raises `ZCX_AB_V1_UT` msg 013 |
| X-06 | Every `[D]` method with `phase = unknown` (classic) | executes normally |
| X-07 | `ZCX_AB_V1_UT` with T100 key + 4 params | `get_text( )` resolves all `&1..&4` |
| X-08 | `ZCX_AB_V1_UT` chaining | `previous` preserved and reachable |

---

## TS-01 · STR

| ID | Scenario | Expected |
|---|---|---|
| STR-01 | `to_amount('1.234,56', notation=EU)` | `1234.56` |
| STR-02 | `to_amount('1,234.56', notation=US)` | `1234.56` |
| STR-03 | `to_amount('12.345', currency='JPY')` (0 decimals) | `12345` |
| STR-04 | `to_amount('abc')` | raises msg 008 |
| STR-05 | `from_amount(1234.5,'EUR',EU)` | `'1.234,50'` |
| STR-06 | `to_date('31.12.2026')` / `to_date('2026-12-31')` | `20261231` |
| STR-07 | `to_date('2026-13-01')` | raises msg 008 |
| STR-08 | `alpha_in('4711')` / `alpha_out('0000004711')` | `'0000004711'` / `'4711'` |
| STR-09 | `to_snake('SalesOrderItem')` / `to_camel('sales_order_item', pascal=X)` | `'sales_order_item'` / `'SalesOrderItem'` |
| STR-10 | `base64_decode(base64_encode(x))` | round-trips to original xstring |
| STR-11 | `hash('abc', SHA256)` | matches known vector `ba7816bf…` |
| STR-12 | `regex_groups('2026-08-31','(\d{4})-(\d{2})-(\d{2})')` | `['2026','08','31']` |
| STR-13 | `is_valid('a@b.com','EMAIL')` / `is_valid('nope','EMAIL')` | `X` / `' '` |
| STR-14 | `amount_in_words(105.25,'USD')` | `'one hundred five 25/100'` (locale-dependent assert) |
| STR-15 | `mask('4111111111111111', suffix=4)` | `'************1111'` |

---

## TS-02 · CONV

| ID | Scenario | Expected |
|---|---|---|
| CNV-01 | `add_months('20260131', 1)` | `'20260228'` (month-end clamp) |
| CNV-02 | `add_workdays('20260828', 1, 'DE')` (Fri→Mon) | `'20260831'` |
| CNV-03 | `is_workday('20260830','DE')` (Sunday) | `' '` |
| CNV-04 | `days_between('20260101','20260131')` | `30` |
| CNV-05 | `age(dob='20000901', on='20260831')` | `25` |
| CNV-06 | `period_bounds('20260815','QUARTER')` | `20260701 / 20260930` |
| CNV-07 | `period_bounds('20260815','FYEAR', variant='K4')` | matches variant config (osql double on `T009B`) |
| CNV-08 | `week_number('20260101')` | ISO week `1` |
| CNV-09 | `tz_from_local` then `tz_to_local` (`'UTC'`) | round-trips |
| CNV-10 | `convert_currency(100,'EUR','USD','20260101','M')` | uses rate from `TCURR` double; `ev_rate` filled |
| CNV-11 | `convert_unit(1,'KG','G')` | `1000` |
| CNV-12 | `round(2.345, 2, COMMERCIAL)` | `2.35` |

---

## TS-03 · TAB

| ID | Scenario | Expected |
|---|---|---|
| TAB-01 | `create_dynamic(structure='SFLIGHT')` | ref to standard table of SFLIGHT |
| TAB-02 | `map_corresponding` with rename map | target filled per mapping, unmapped untouched |
| TAB-03 | `aggregate` SUM+COUNT by 1 key | correct totals, one row per key |
| TAB-04 | `diff` – 1 insert / 1 update / 1 delete fixture | each sub-table has exactly the right row |
| TAB-05 | `diff` – identical tables | all three sub-tables empty |
| TAB-06 | `to_ranges(['A','B'])` | 2 rows, `SIGN=I OPTION=EQ` |
| TAB-07 | `chunk(103 rows, size=25)` | 5 chunks (25/25/25/25/3) |
| TAB-08 | `pivot` month→columns | wide table, missing cells initial |
| TAB-09 | `fingerprint(s1)` vs `fingerprint(s1')` (one field changed) | different |
| TAB-10 | `deep_equal` on cloned refs | `X` |

---

## TS-04 · DB  *(osql doubles; `read` = Gated)*

| ID | Scenario | Expected |
|---|---|---|
| DB-01 | `exists('ZAB_V1_UT_ADPT', key AREA=ATTACH)` (row present) | `X` |
| DB-02 | `exists` – row absent | `' '` |
| DB-03 | `read_single` by full key | `es_row` populated |
| DB-04 | `describe('ZAB_V1_UT_ADPT')` | metadata lists key fields `MANDT,AREA` |
| DB-05 | `read` with unknown table name | raises msg 014 (validation) |
| DB-06 | `read` with field not in table | raises msg 014 |
| DB-07 | `read` happy path (columns + range) | ref to table with expected rows |
| DB-08 | `where_from_ranges` | produces syntactically valid WHERE tokens |

---

## TS-05 · FILE  *(app-server methods = Gated)*

| ID | Scenario | Expected |
|---|---|---|
| FIL-01 | `mime_type('a.pdf')` / `'a.xlsx'` | `application/pdf` / `…spreadsheetml…` |
| FIL-02 | `zip` then `unzip` | file list + contents round-trip |
| FIL-03 | `csv_build` then `csv_parse` | table round-trips (header respected) |
| FIL-04 | `csv_parse` ragged row | raises msg 001 with row number |
| FIL-05 | `resolve_logical('ZAB_V1_UT_INBOUND')` | non-initial path (osql double on `FILEPATH`/`PATH`) |
| FIL-06 | `as_write` then `as_read` to a temp path in test dir | content round-trips; file removed in teardown |
| FIL-07 | `as_read` with `../` traversal in path | raises msg 015 |
| FIL-08 | `as_read` when `S_DATASET` check fails (auth double) | raises msg 015 |

---

## TS-06 · EXCEL  *(fixture xstrings under test)*

| ID | Scenario | Expected |
|---|---|---|
| XLS-01 | `write` a 3-col / 5-row table | valid xlsx xstring (re-openable by `read`) |
| XLS-02 | `write` → `read` round-trip, auto-map by header | data equal to source |
| XLS-03 | `read` with explicit `it_mapping` (column letter → field) | mapped correctly |
| XLS-04 | `read` file with an extra unmapped column | `et_unmapped` contains it, no dump |
| XLS-05 | `read` cell with bad date | row captured in `et_errors`, others still returned |
| XLS-06 | `read` beyond `iv_max_rows` | stops at limit |
| XLS-07 | `generate_template('SFLIGHT')` | header-only sheet, correct column texts |
| XLS-08 | `write_multi` 2 sheets | workbook has both, names correct |

---

## TS-07 · JSON

| ID | Scenario | Expected |
|---|---|---|
| JSN-01 | `serialize` structure, `camel_case=X` | keys camelCased |
| JSN-02 | `serialize`/`deserialize` round-trip (deep struct + table) | equal |
| JSN-03 | `pretty` compact JSON | indented, semantically identical |
| JSN-04 | `path_get('$.a.b[1].c')` | correct scalar |
| JSN-05 | `path_set` then `path_get` | new value present |
| JSN-06 | `describe(type)` | schema lists all components + types + lengths |
| JSN-07 | `to_xml` / `from_xml` round-trip | equal JSON |
| JSN-08 | `deserialize` malformed JSON | raises msg 005 |

---

## TS-08 · LOG

| ID | Scenario | Expected |
|---|---|---|
| LOG-01 | `create` in-memory, `add_t100` ×3, `to_bapiret` | 3 rows, right ids/types |
| LOG-02 | `add_exception` (chained) | one row per chain level |
| LOG-03 | `add_bapiret(table of 5)` | 5 rows appended |
| LOG-04 | `to_string` | newline-joined text |
| LOG-05 | `save( )` with `phase=interaction` | raises msg 013 |
| LOG-06 | `save( )` with `phase=late_save` (osql double on BAL tables) | inserts, no COMMIT issued |
| LOG-07 | `display( )` in non-GUI test | raises msg 011 (or skipped as GUI) |

---

## TS-09 · MSG

| ID | Scenario | Expected |
|---|---|---|
| MSG-01 | `t100_to_text('ZAB_V1_UT','013', v1='SAVE', v2='1')` | `'Operation SAVE not allowed in RAP phase 1'` |
| MSG-02 | `t100_to_bapiret` | `type/id/number/message_v1..4` set |
| MSG-03 | `exception_to_text(chained, with_chain=X)` | contains all levels |
| MSG-04 | `bapiret_has_error` (has 'E') / (only 'S') | `X` / `' '` |
| MSG-05 | `bapiret_max_severity` mixed S/W/E | `'E'` |
| MSG-06 | `bapiret_filter(types='E')` | only error rows |
| MSG-07 | `raise('ZAB_V1_UT','002', v1='S_X')` | `ZCX_AB_V1_UT`, text resolved |
| MSG-08 | `to_failed` / `to_reported` | RAP structures get one row for the key |

---

## TS-10 · AUTH  *(osql doubles on `AGR_USERS`, `USR02`)*

| ID | Scenario | Expected |
|---|---|---|
| AUT-01 | `check` – user authorized (test uses `S_TCODE`/`SE38` on the running user) | `X` |
| AUT-02 | `check` – deliberately impossible object/value | `' '` |
| AUT-03 | `check_or_raise` fails | raises msg 002 |
| AUT-04 | `user_has_role` – role valid today | `X` |
| AUT-05 | `user_has_role` – role expired (`GLTGB < today`) | `' '` |
| AUT-06 | `is_user_valid` – locked (`UFLAG≠0`) | `' '` |
| AUT-07 | `is_user_valid` – valid | `X` |
| AUT-08 | `permitted_values` | returns values from the auth double |

---

## TS-11 · NUM  *(number-range test uses `IF_NUMBER_RANGE`/interval double or a test NRIV)*

| ID | Scenario | Expected |
|---|---|---|
| NUM-01 | `next` twice | strictly increasing |
| NUM-02 | `next` with `phase=interaction` | raises msg 013 |
| NUM-03 | `next_bulk(10)` | 10 consecutive numbers |
| NUM-04 | `status` | `ev_current` + `ev_percentage` plausible |
| NUM-05 | `next` on non-existent object | raises msg 016 |

---

## TS-12 · MAIL  *(send-port spy; nothing actually sent)*

| ID | Scenario | Expected |
|---|---|---|
| MAI-01 | `build_html_body(title, paragraphs)` | well-formed HTML, title in `<h1>`/`<title>` |
| MAI-02 | `build_html_body` with table | `<table>` with one row per line |
| MAI-03 | `send` – spy captures `ty_mail` | recipients/subject/body/attachments match input |
| MAI-04 | `send` with `phase=interaction` | raises msg 013 |
| MAI-05 | `send` with `commit=abap_false` | spy records no COMMIT requested |
| MAI-06 | `send` no recipients | raises msg 006 |

---

## TS-13 · ATTACH  *(`ZCL_AB_V1_UT_ATTACH_STUB` under test)*

| ID | Scenario | Expected |
|---|---|---|
| ATT-01 | `new_guid_x16/_c32/_c22` | correct length, non-initial, unique across calls |
| ATT-02 | `attach` then `list` | 1 item, filename/mimetype/bytes match |
| ATT-03 | `attach` then `get(id)` | content equals uploaded xstring |
| ATT-04 | `get` unknown id | raises msg 007 |
| ATT-05 | `attach` with `phase=interaction` | raises msg 013 |
| ATT-06 | adapter selection – no active row for `ATTACH` | raises msg 012 |
| ATT-07 | `to_solix`/`from_solix` round-trip | equal xstring, length preserved |

---

## TS-14 · SYS

| ID | Scenario | Expected |
|---|---|---|
| SYS-01 | `system_info` | `sysid`/`client` = `sy-sysid`/`sy-mandt`; `is_production` from `T000` double |
| SYS-02 | `object_exists('TABL','T000')` / `('TABL','ZZZ_NOPE')` | `X` / `' '` |
| SYS-03 | `object_exists('CLAS','ZCL_AB_V1_UT')` | `X` |
| SYS-04 | `timer_start`/`timer_stop` around a small loop | `ev_seconds ≥ 0`, monotonic |
| SYS-05 | `text('OTR', known-alias)` | resolves text |

---

## TS-15 · CFG  *(osql doubles on `TVARVC`, config table)*

| ID | Scenario | Expected |
|---|---|---|
| CFG-01 | `tvarv_value('ZAB_TEST_P')` | scalar from double |
| CFG-02 | `tvarv_range('ZAB_TEST_S')` | range table with seeded rows |
| CFG-03 | `is_feature_on('X')` on / off | `X` / `' '` |
| CFG-04 | `read_config(table, keys)` | rows filtered to keys |
| CFG-05 | `enum_values('ZAB_V1_UT_AREA')` | 18 value/text pairs |
| CFG-06 | `tvarv_value` missing name | raises msg 018 |

---

## TS-16 · RAP  *(uses a disposable test RAP BO or EML doubles)*

| ID | Scenario | Expected |
|---|---|---|
| RAP-01 | `new_cid` | unique per call |
| RAP-02 | `failed_add` | one row with the key + cause |
| RAP-03 | `reported_add` | one row with message |
| RAP-04 | `auth_to_failed(authorized=' ')` | failed + reported each get a row |
| RAP-05 | `auth_to_failed(authorized='X')` | both unchanged |
| RAP-06 | `reported_to_bapiret` | message text/type carried over |
| RAP-07 | `corresponding_control` – only flagged fields copied | unflagged target fields retain old value |
| RAP-08 | `modify_entity` – harvest EML failure | `et_messages` has the BO error |

---

## TS-17 · JOB

| ID | Scenario | Expected |
|---|---|---|
| JOB-01 | `run_parallel` with trivial in-process handler, 3 packages | handler invoked 3×, messages aggregated |
| JOB-02 | `run_parallel` handler raises | `et_messages` carries msg 017, other packages still processed |
| JOB-03 | `schedule_job` with `phase=interaction` | raises msg 013 |
| JOB-04 | `schedule_job` (mock `JOB_OPEN/CLOSE`) | returns non-initial jobcount |

---

## 18. Integration Scenarios (manual / CI, `DURATION MEDIUM`)

| ID | Scenario |
|---|---|
| INT-01 | `ZAB_V1_UT_DEMO` executed for every area on a sandbox client – no dumps, expected output |
| INT-02 | `ZAB_V1_UT_DEMO_GUI` – ALV shows, variant save/load works, file download produces a real file |
| INT-03 | Real BAL: `LOG->save( iv_commit = abap_true )` then verify in `SLG1` under object `ZAB_V1_UT` |
| INT-04 | Real GOS: attach a PDF to a test BO, retrieve via `get`, verify byte-equal |
| INT-05 | Real mail: send to a test mailbox, verify in `SOST` |
| INT-06 | Consume `ZCL_AB_V1_UT` from a RAP BO behaviour pool – ATC clean, no GUI dependency pulled |

---

## Coverage Map

| Class | Target | Excluded |
|---|---|---|
| `ZCL_AB_V1_UT_STR/_CONV/_TAB/_MSG/_JSON/_SYS/_CFG/_RAP` | ≥ 95 % | – |
| `ZCL_AB_V1_UT_DB/_FILE/_EXCEL/_AUTH/_LOG/_ATTACH_*` | ≥ 90 % | true `OPEN DATASET` error branches |
| `ZCL_AB_V1_UT_MAIL/_NUM/_JOB` | ≥ 85 % | real dispatch paths (integration only) |
| `ZCL_AB_V1_UT` facade | ≥ 95 % | – |
| `ZCL_AB_V1_UT_GUI` | n/a | entire class (GUI) – integration tests only |
