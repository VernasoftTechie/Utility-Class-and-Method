# 06 – ZCL_AB_V1_UT Utility Framework – Demo Guide

**Version:** 1.0 · Covers manual setup that abapGit cannot serialise, plus how to run the
demo reports. Applies after the implementation drop (v1.0.0).

---

## 1. Pull the repository (abapGit)

1. `SE38` → `ZABAPGIT` (or the standalone report) → **Online**.
2. URL: `https://github.com/VernasoftTechie/Utility-Class-and-Method.git`
3. **Package:** assign your existing target package (e.g. `ZRAP_MIGR` or a dedicated Z
   package). The repo intentionally ships **no** package definition.
4. Folder logic **PREFIX**, starting folder `/src/`.
5. Pull. `docs/*` is ignored by `.abapgit.xml` and not imported.
6. Activate all objects. Expected activation order is handled by ADT/abapGit; if the
   facade fails first pass, re-activate after the interfaces are green.

---

## 2. Manual setup (one-off, per system)

### 2.1 Application Log object — `SLG0`

| Field | Value |
|---|---|
| Object | `ZAB_V1_UT` |
| Text | Vernasoft Utility Framework |
| Sub-object | `GENERAL` — "General" |
| (optional) Sub-object | `VALIDATION`, `INBOUND`, `JOB` as needed by consumers |

Transport: the `SLG0` entries are transportable customizing — include in your workbench/
customizing transport.

### 2.2 Number-range object — `SNRO` (only for the `NUM` demo)

| Field | Value |
|---|---|
| Object | `ZAB_V1_UT` |
| Domain for number length | `CHAR10` (or numeric to taste) |
| Interval `01` | From `0000000001` To `0000999999`, current `0` |

Not required by the framework itself — only by `ZAB_V1_UT_DEMO` when exercising `ZIF_AB_V1_UT_NUM`.

### 2.3 Adapter configuration — `SM30` on `ZAB_V1_UT_ADPT`

| AREA | ADAPTER_CLASS | IS_ACTIVE |
|---|---|---|
| `ATTACH` | `ZCL_AB_V1_UT_ATTACH_STUB` | `X`  ← sandbox / dev |
| `ATTACH` | `ZCL_AB_V1_UT_ATTACH_GOS` | `X`  ← QA / production instead of the stub |

Exactly **one** active row per area. The framework raises `ZAB_V1_UT` msg 012 if none is active.

### 2.4 Logical file names — `FILE` (only for the gated `FILE` demo)

Define e.g. `ZAB_V1_UT_INBOUND` / `ZAB_V1_UT_OUTBOUND` pointing at an allowed
application-server directory, and grant `S_DATASET` for that path to the demo user.

---

## 3. Running `ZAB_V1_UT_DEMO` (headless / Core + Defer)

`SE38` → `ZAB_V1_UT_DEMO`. Selection screen: one radio button per functional area (STR,
CONV, TAB, DB, FILE, JSON, LOG, MSG, AUTH, NUM, MAIL, ATTACH, SYS, CFG, RAP, JOB) plus a
"Run all" option.

| Area | What the demo does |
|---|---|
| STR | parses `'1.234,56'`, hashes a string, validates an email, prints amount-in-words |
| CONV | adds 30 working days, shows quarter bounds, converts KG→G |
| TAB | builds a dynamic table, runs `diff` on two fixtures, prints insert/update/delete counts |
| DB | `exists` + `describe` on `ZAB_V1_UT_ADPT` (read/dynamic SELECT shown read-only) |
| FILE | zip/unzip a fixture, CSV round-trip; app-server write+read if a logical name is set |
| JSON | serialize a structure (pretty + camelCase), deserialize back, print schema |
| LOG | in-memory log with 3 messages, `to_string`; `save` only if "commit" checkbox ticked |
| MSG | builds text from `ZAB_V1_UT/013`, shows severity helpers on a mixed BAPIRET2 table |
| AUTH | `check` on `S_TCODE`/`SE38`, `is_user_valid` for `sy-uname` |
| NUM | draws 3 numbers from `ZAB_V1_UT` interval `01` (needs 2.2) |
| MAIL | builds an HTML body and prints it; only sends if "send" checkbox ticked + recipient given |
| ATTACH | new GUID, `attach`→`list`→`get` against the configured adapter |
| SYS | prints system info, checks object existence, times a loop |
| CFG | reads a TVARVC value, lists `ZAB_V1_UT_AREA` enum |
| RAP | `new_cid`, builds a `REPORTED` row, converts to BAPIRET2 |
| JOB | `run_parallel` over 3 in-process packages |

No SAP GUI control classes are used — safe to run in batch (`SUBMIT … VIA JOB`).

---

## 4. Running `ZAB_V1_UT_DEMO_GUI` (SAP GUI only)

`SE38` → `ZAB_V1_UT_DEMO_GUI`. Requires a SAP GUI session.

1. **Static ALV** — displays a sample flight table via `ZIF_AB_V1_UT_ALV~show`.
2. **Dynamic ALV** — builds a table at runtime from a field list and shows it via
   `show_dynamic`.
3. **Field catalog** — prints the generated `LVC_T_FCAT` for a structure.
4. **Layout variant** — save the current layout as a variant, reload it.
5. **File services** — pick a file, upload to `xstring`, download it back under a new name.

If run without a SAP GUI (e.g. background), it raises `ZAB_V1_UT` msg 011 and exits cleanly.

---

## 5. Consuming the framework from a RAP business object

```abap
METHOD validate_amount.
  READ ENTITIES OF zi_loan IN LOCAL MODE ENTITY loan
    FIELDS ( amount currency ) WITH CORRESPONDING #( keys )
    RESULT DATA(lt_loan).

  LOOP AT lt_loan INTO DATA(ls_loan).
    IF zcl_ab_v1_ut=>str( )->to_amount( iv_text = ls_loan-amount_raw
                                        iv_currency = ls_loan-currency ) <= 0.
      zcl_ab_v1_ut=>msg( )->to_failed( is_key = ls_loan CHANGING failed = failed ).
      zcl_ab_v1_ut=>msg( )->to_reported(
        it_return = VALUE #( ( id = 'ZAB_V1_UT' number = '008' type = 'E'
                               message_v1 = ls_loan-amount_raw ) )
        is_key = ls_loan CHANGING reported = reported ).
    ENDIF.
  ENDLOOP.
ENDMETHOD.

METHOD save_modified.
  zcl_ab_v1_ut=>set_phase( zif_ab_v1_ut_types=>c_phase-late_save ).
  DATA(lo_log) = zcl_ab_v1_ut=>log( )->create( iv_subobject = 'VALIDATION' ).
  " ... add messages ...
  lo_log->save( ).                       " Defer method – allowed here
  zcl_ab_v1_ut=>mail( )->send( ls_mail ). " commit = abap_false
ENDMETHOD.
```

Rules recap: **Core** anywhere · **Defer** only from `save_modified` / late numbering /
after commit (set the phase first) · **GUI** never from RAP · **Gated** (`db->read`,
`file->as_*`) never from RAP BO logic.

---

## 6. Uninstall

abapGit → repository → **Remove** (keeps objects) or delete the package contents in `SE80`.
Also remove: `SLG0` object `ZAB_V1_UT`, `SNRO` object `ZAB_V1_UT`, `ZAB_V1_UT_ADPT` entries.
