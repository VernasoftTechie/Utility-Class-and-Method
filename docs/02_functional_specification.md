# 02 – ZCL_AB_V1_UT Utility Framework – Functional Specification

**Version:** 1.0 · **Status:** DRAFT · Companion to `01_architecture.md`

This document describes **what each area does**, its **inputs/outputs**, **RAP-mode**, and a
**worked example** per area. Exact signatures are in `03_technical_specification.md`.

RAP-mode legend: **Core** (safe anywhere) · **Defer** (RAP late/save phase only) ·
**GUI** (SAP GUI only) · **Gated** (on-prem only, ATC-exempted, not for RAP BO logic).

> **v1.1.0 implementation toolkit** (`HTTP` / `BULK` / `BAPI` / `CUTOVER` / `TRANSPORT`) —
> functional description **and** binding signatures live in
> [`08_implementation_toolkit.md`](08_implementation_toolkit.md). Scope actually
> delivered vs. spec: [`05_version_history.md`](05_version_history.md).

---

## FS-01 · `ZIF_AB_V1_UT_STR` – String / Type / Conversion  *(Core)*

| Capability | Input → Output |
|---|---|
| Parse amount from text | `'1.234,56'` + notation → packed amount, respecting currency decimals (TCURX) |
| Format amount to text | packed amount + currency → display string |
| Parse / format quantity | text ↔ quantity with UoM decimals |
| Parse / format date & time | text (user format / `DD.MM.YYYY` / ISO 8601) ↔ `d` / `t` |
| ALPHA conversion | `'4711'` ↔ `'0000004711'` |
| Pad / mask / trim / split / join | string ops with explicit options |
| Case & CamelCase ↔ snake_case | `'SalesOrder'` ↔ `'sales_order'` |
| Base64 encode / decode | `xstring` ↔ Base64 `string` |
| Codepage convert | `string` ↔ `xstring` for a named codepage |
| Hash / digest | `string`/`xstring` → MD5 / SHA-1 / SHA-256 hex |
| Regex | match / replace-all / extract capture groups |
| Amount in words | `12345.67` + `'USD'` → `'twelve thousand three hundred forty-five 67/100'` |
| Validators | email / phone / IBAN / PAN / GSTIN / generic check digit → `abap_bool` |

**Example** – import a spreadsheet cell holding `"1.234,50"` into a `WRBTR` field:

```abap
DATA(lv_amount) = zcl_ab_v1_ut=>str( )->to_amount(
                    iv_text     = cell_value
                    iv_currency = 'EUR'
                    iv_notation = zif_ab_v1_ut_str=>c_notation-eu ). " 1234.50
```

---

## FS-02 · `ZIF_AB_V1_UT_CONV` – Date / Time / Number / Currency / Unit  *(Core)*

| Capability | Notes |
|---|---|
| Add / subtract days, months, years | calendar-correct, month-end aware |
| Working-day arithmetic + workday check | factory calendar ID parameter |
| Date diff / age / tenure | in days, months, years |
| Period boundaries | first/last day of week, month, quarter, fiscal year (variant) |
| Week number, weekday, ISO week | |
| Timezone conversion | `timestamp` + tz → local `date`/`time` and back |
| Timestamp split / merge | `timestampl` ↔ (`date`,`time`,`msec`) |
| Currency conversion | amount + from/to + rate date + rate type → converted amount + rate |
| Unit-of-measure conversion | quantity + from/to UoM (+ material for material-specific) |
| Rounding | commercial / per-currency decimal rounding |

**Example** – due date = 30 working days after today (German calendar):

```abap
DATA(lv_due) = zcl_ab_v1_ut=>conv( )->add_workdays(
                 iv_date = cl_abap_context_info=>get_system_date( )
                 iv_days = 30
                 iv_calendar_id = 'DE' ).
```

---

## FS-03 · `ZIF_AB_V1_UT_TAB` – Internal Table / RTTI / Dynamic Data  *(Core)*

| Capability | Notes |
|---|---|
| Build dynamic internal table | from a field list, a DDIC structure name, or an RTTI type |
| CORRESPONDING with mapping | source→target component name map, deep support |
| Group / aggregate | sum, avg, min, max, count by key fields → result table |
| Sort / distinct / dedupe | dynamic field list |
| **Table diff by key** | old vs new → inserted / updated / deleted sub-tables (delta engine) |
| itab ↔ RANGES | list of values → range table; range table → dynamic WHERE string |
| Chunk / split | table + package size → list of sub-tables (for EML / parallel) |
| Pivot / transpose | row→column reshaping |
| Structure fingerprint | any structure → stable hash (change detection) |
| Deep clone / deep compare | `REF TO data` in, cloned ref / difference list out |

**Example** – delta between staged and active rows:

```abap
zcl_ab_v1_ut=>tab( )->diff(
  EXPORTING it_old = lt_active  it_new = lt_staged  it_key_fields = VALUE #( ( `ID` ) )
  IMPORTING et_insert = lt_ins  et_update = lt_upd  et_delete = lt_del ).
```

---

## FS-04 · `ZIF_AB_V1_UT_DB` – Dynamic Database Access  *(Core + Gated)*

| Capability | Mode |
|---|---|
| `read` – dynamic SELECT (columns / from / where / order-by / up-to) → `REF TO data` | **Gated** |
| `exists` – key check on a table/view | Core |
| `read_single` – one row by key components | Core (prefer typed CDS) |
| `describe` – DDIC metadata (fields, keys, texts, foreign keys, check tables) | Core |
| `where_from_ranges` – typed range tables → validated WHERE | Core |

**Guard rails:** table and field names are validated against DDIC before use; `WHERE` is
assembled only from typed range tables (no free-text). Intended for **reports & migration
tooling**, not RAP BO logic.

**Example** – generic existence check in a report:

```abap
IF zcl_ab_v1_ut=>db( )->exists( iv_entity = 'ZAB_V1_UT_ADPT'
                                it_keys   = VALUE #( ( name = 'AREA' value = 'ATTACH' ) ) ).
```

---

## FS-05 · `ZIF_AB_V1_UT_FILE` – Files  *(Core + Gated + GUI)*

| Capability | Mode |
|---|---|
| Resolve logical filename (`FILE` tcode) | Core |
| MIME type from extension / content sniff | Core |
| Zip / unzip (`cl_abap_zip`) | Core |
| CSV parse / produce (delimiter, header, quoting) | Core |
| App-server: read / write / append / delete / exists / list directory | **Gated** |
| Presentation-server: browse / upload / download / delete | **GUI** (`ZCL_AB_V1_UT_GUI`) |

**Guard rails (Gated):** `S_DATASET` authority check + logical filename resolution + path
traversal validation before every `OPEN DATASET`.

**Example** – read an inbound file on the app server (report context):

```abap
DATA(lv_content) = zcl_ab_v1_ut=>file( )->as_read(
  iv_logical_name = 'ZAB_V1_UT_INBOUND'
  iv_mode         = zif_ab_v1_ut_file=>c_mode-binary ).
```

---

## FS-06 · `ZIF_AB_V1_UT_EXCEL` – Spreadsheet  *(Core; frontend transfer = GUI)*

| Capability | Notes |
|---|---|
| `read` xlsx | `xstring` + mapping (header text→component, or column letter→component) → typed table + list of unmapped columns + row-level errors |
| `write` xlsx | internal table + options (sheet name, header style, freeze panes, auto-filter, column widths, number/date formats) → `xstring` |
| `generate_template` | structure + column texts (+ optional dropdown/data-validation) → header-only `xstring` |
| multi-sheet | write/read several sheets in one workbook |

Engine: `xco_cp_xlsx`. Works entirely on `xstring` – no GUI. Saving/opening the file on a
user's PC is done via `ZCL_AB_V1_UT_GUI=>download_file( )`.

**Example** – produce a download for a Fiori app (RAP action returns the xstring as a stream):

```abap
DATA(lv_xlsx) = zcl_ab_v1_ut=>excel( )->write(
  it_data    = lt_report
  is_options = VALUE #( sheet_name = 'Report' auto_filter = abap_true freeze_row = 1 ) ).
```

---

## FS-07 · `ZIF_AB_V1_UT_JSON` – JSON / XML  *(Core)*

| Capability | Notes |
|---|---|
| `serialize` | any data + options (pretty, camelCase, keep-initial, ISO dates) → `string` |
| `deserialize` | JSON `string` + target (CHANGING or RTTI type) → typed data |
| `pretty` | reformat an existing JSON string |
| `path_get` / `path_set` | JSON-path read/write on a string |
| `describe` | RTTI type → JSON-schema-like metadata (names, types, lengths, required) |
| `to_xml` / `from_xml` | JSON ↔ XML |
| `xml_serialize` / `xml_deserialize` | data ↔ XML via `sXML` |

**Example** – build an OData-style payload from a structure:

```abap
DATA(lv_json) = zcl_ab_v1_ut=>json( )->serialize(
  iv_data = ls_result  iv_pretty = abap_true  iv_camel_case = abap_true ).
```

---

## FS-08 · `ZIF_AB_V1_UT_LOG` – Application Log (BAL)  *(Core + Defer + GUI)*

| Capability | Mode |
|---|---|
| `create` – open a log (memory or DB), object/subobject default `ZAB_V1_UT`/`GENERAL` | Core |
| `add` – add a message: T100 key / `BAPIRET2` / exception / current `SY` | Core |
| `add_bulk` – add a `BAPIRET2` table | Core |
| `save` – persist to DB | **Defer** (own LUW) |
| `display` – show the log | **GUI** (else return the handle for Fiori/report rendering) |
| `to_bapiret` / `to_string` – convert log content | Core |

**Example** – collect validation findings inside a RAP determination, hand back for save:

```abap
DATA(lo_log) = zcl_ab_v1_ut=>log( )->create( iv_subobject = 'VALIDATION' ).
lo_log->add_exception( lx_error ).
" ... later, in save_modified:
lo_log->save( ).
```

---

## FS-09 · `ZIF_AB_V1_UT_MSG` – Messages / Exceptions  *(Core)*

| Capability | Notes |
|---|---|
| `t100_to_text` / `t100_to_bapiret` / `t100_to_symsg` | build message from class + number + &1..&4 |
| `exception_to_text` | short / long text of any `cx_root` (+ chain) |
| `bapiret_has_error` / `bapiret_max_severity` / `bapiret_filter` / `bapiret_sort` | table helpers |
| `raise` | raise `ZCX_AB_V1_UT` from a T100 key + parameters + previous |
| `to_reported` / `to_failed` | message(s) → RAP `REPORTED` / `FAILED` rows for a given `%tky` |

**Example** – RAP validation failure:

```abap
zcl_ab_v1_ut=>msg( )->to_failed(
  EXPORTING iv_msgid = 'ZAB_V1_UT' iv_msgno = '002' iv_v1 = 'S_LOAN' is_key = ls_key
  CHANGING  failed = failed  reported = reported ).
```

---

## FS-10 · `ZIF_AB_V1_UT_AUTH` – Authorization  *(Core)*

| Capability | Notes |
|---|---|
| `check` | auth object + up to 10 field/value pairs → `rv_authorized` (`abap_bool`) |
| `check_or_raise` | same, raises `ZCX_AB_V1_UT` (msg 002) on failure |
| `user_has_role` | `AGR_USERS`, respects validity dates |
| `is_user_valid` | `USR02` – not locked, within validity window |
| `permitted_values` | values the current user may use for an auth object/field |

**Example**:

```abap
IF NOT zcl_ab_v1_ut=>auth( )->check(
     iv_object = 'S_TABU_DIS'
     it_values = VALUE #( ( id = 'DICBERCLS' value = '&NC&' ) ( id = 'ACTVT' value = '03' ) ) ).
```

---

## FS-11 · `ZIF_AB_V1_UT_NUM` – Number Ranges  *(Core + Defer)*

| Capability | Mode |
|---|---|
| `next` – next number for object + interval (+ optional sub-object) | **Defer** |
| `next_bulk` – reserve N numbers | **Defer** |
| `status` – current number / percentage used | Core |

**Example** – RAP late numbering:

```abap
LOOP AT mapped-header ASSIGNING FIELD-SYMBOL(<h>).
  <h>-doc_number = zcl_ab_v1_ut=>num( )->next( iv_object = 'ZAB_V1_UT' iv_interval = '01' ).
ENDLOOP.
```

---

## FS-12 · `ZIF_AB_V1_UT_MAIL` – Email / Notification  *(Core + Defer)*

| Capability | Mode |
|---|---|
| `send` – structured request (sender, to/cc/bcc, subject, HTML + text body, attachments name/mimetype/xstring, importance, `iv_send_immediately`, `iv_commit`, request status) | **Defer** |
| `build_html_body` – title + sections/paragraphs (+ simple table) → HTML `string` | Core |
| `raise_workflow_event` – Flexible Workflow / bgPF event | Defer |

**Example** – notify on RAP save (deferred, no commit):

```abap
zcl_ab_v1_ut=>mail( )->send( VALUE #(
  to        = VALUE #( ( 'approver@corp.com' ) )
  subject   = |Loan request { ls_hdr-id } submitted|
  body_html = zcl_ab_v1_ut=>mail( )->build_html_body( ... )
  commit    = abap_false ) ).
```

---

## FS-13 · `ZIF_AB_V1_UT_ATTACH` – Attachments / GOS / DMS  *(Core + Defer)*

| Capability | Mode |
|---|---|
| `new_guid_x16` / `_c32` / `_c22` | Core |
| `list` – attachments for a BO key (objtype + objkey) | Core |
| `get` – attachment content by id | Core |
| `attach` – store a file for a BO key | **Defer** |
| `to_solix` / `from_solix` – binary ↔ `SOLIX_TAB` | Core |

Adapter chosen from `ZAB_V1_UT_ADPT` (`AREA='ATTACH'`): `ZCL_AB_V1_UT_ATTACH_GOS`
(`cl_gos_api`), `ZCL_AB_V1_UT_ATTACH_STUB` (in-memory), future `…_OPENTEXT`.

**Example**:

```abap
DATA(lv_id) = zcl_ab_v1_ut=>attach( )->attach(
  is_bo_key   = VALUE #( objtype = 'ZLOAN' objkey = ls_hdr-id )
  iv_filename = 'payslip.pdf' iv_mimetype = 'application/pdf' iv_content = lv_pdf ).
```

---

## FS-14 · `ZIF_AB_V1_UT_ALV` – ALV / Output  *(GUI – `ZCL_AB_V1_UT_GUI`)*

| Capability | Notes |
|---|---|
| `show` – fullscreen SALV from an internal table | one-liner display |
| `show_dynamic` – SALV from a dynamically-typed table | for `ZIF_AB_V1_UT_DB`/`_TAB` output |
| `build_fieldcat` – RTTI → `LVC_T_FCAT` | for `cl_gui_alv_grid` consumers (catalog build is pure) |
| `layout_save` / `layout_load` – display variant | |
| `toolbar` – register custom buttons + event handler hook | |

Not callable from RAP. `ZCL_AB_V1_UT_GUI` raises `ZCX_AB_V1_UT` (msg 011) if no SAP GUI.

**Example** (classic report):

```abap
zcl_ab_v1_ut_gui=>alv( )->show( CHANGING ct_table = lt_output ).
```

---

## FS-15 · `ZIF_AB_V1_UT_SYS` – System / Environment  *(Core)*

| Capability | Notes |
|---|---|
| `system_info` | sysid, client, client role (`T000`), install number, is-production flag |
| `object_exists` | table / structure / class / interface / CDS / function module exists? |
| `timer_start` / `timer_stop` | wall + CPU runtime measurement |
| `text` | OTR alias / text-symbol / message long text retrieval |

**Example** – guard destructive logic outside production:

```abap
IF zcl_ab_v1_ut=>sys( )->system_info( )-is_production = abap_false.
```

---

## FS-16 · `ZIF_AB_V1_UT_CFG` – Config / Customizing  *(Core)*

| Capability | Notes |
|---|---|
| `tvarv_value` / `tvarv_range` | single value / select-options from `TVARVC` |
| `is_feature_on` | feature toggle (backed by `TVARVC` or a Z-table) |
| `read_config` | generic typed read of a Z-config table by key → structure/table |
| `enum_values` | fixed values of a domain → value/text list |

**Example**:

```abap
DATA(lt_types) = zcl_ab_v1_ut=>cfg( )->enum_values( iv_domain = 'ZAB_V1_UT_AREA' ).
```

---

## FS-17 · `ZIF_AB_V1_UT_RAP` – RAP-native helpers  *(Core)*

| Capability | Notes |
|---|---|
| `read_entity` / `modify_entity` | generic EML wrapper with error harvesting into `BAPIRET2` |
| `tky` / `cid` helpers | build/inspect `%tky`, generate `%cid` |
| `failed_add` / `reported_add` | typed builders for `FAILED` / `REPORTED` |
| `auth_to_failed` | `ZIF_AB_V1_UT_AUTH` result → `FAILED`/`REPORTED` |
| `reported_to_bapiret` / `bapiret_to_reported` | conversions |
| `corresponding_control` | deep CORRESPONDING honouring `%control` flags |

**Example** – harvest EML errors:

```abap
zcl_ab_v1_ut=>rap( )->modify_entity(
  EXPORTING iv_entity = 'ZI_LOAN' it_instances = lt_upd
  IMPORTING et_messages = lt_bapiret ).
```

---

## FS-18 · `ZIF_AB_V1_UT_JOB` – Parallel / Background  *(Core + Defer)*

| Capability | Mode |
|---|---|
| `run_parallel` – split a work list, run a handler class in parallel (`cl_abap_parallel`) | Core (spawn); result collation Defer |
| `schedule_job` – `JOB_OPEN` / submit / `JOB_CLOSE` | **Defer** (after commit) |
| `trigger_bgpf` – enqueue RAP background processing | Defer |

**Example** – parallel mass processing in a report:

```abap
zcl_ab_v1_ut=>job( )->run_parallel(
  iv_handler_class = 'ZCL_MY_WORKER'  it_packages = lt_chunks  iv_max_tasks = 5 ).
```

---

## Consumption Summary by Caller Type

| Caller | May use | Must not use |
|---|---|---|
| RAP determination / validation | all **Core** | Defer, GUI, Gated |
| RAP action | Core; **Defer** only if action commits | GUI, Gated |
| RAP `save_modified` / late numbering | Core + **Defer** | GUI, Gated |
| RAP query / VH provider | **Core** | Defer, GUI, Gated |
| Classic executable report | Core + Defer + **Gated** + **GUI** (via `ZCL_AB_V1_UT_GUI`) | – |
| Background job (no GUI) | Core + Defer + Gated | GUI |
| Migration / scanning tooling | all, incl. **Gated** `DB`/`FILE` | – |
