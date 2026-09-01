# 06 – ZCL_AB_V1_UT Utility Framework – Demo Guide

**Version:** 1.0 · Covers manual setup that abapGit cannot serialise, plus how to run the
demo reports. Applies after the implementation drop (v1.0.0).

---

## 1. Pull the repository (abapGit)

1. `SE80` / `SE21` → create package **`ZABAP_UTIL`** (software component `HOME`, or your
   Z transport layer). Short text: *Vernasoft ABAP Utility Framework (ZCL_AB_V1_UT)*.
2. `SE38` → `ZABAPGIT` (or the standalone report) → **Online**.
3. URL: `https://github.com/VernasoftTechie/Utility-Class-and-Method.git`
4. **Package: `ZABAP_UTIL`**. Folder logic **PREFIX**, starting folder `/src/`.
5. Pull. With flat `/src/` + PREFIX, **every object is created in `ZABAP_UTIL`**
   (`src/package.devc.xml` supplies its short text). `docs/*`, `README.md`,
   `.gitattributes` are ignored by `.abapgit.xml` and not imported.
6. Activate all objects (`SE80` → package → activate all, or mass-activate in ADT).
   Activation order is resolved automatically; if the facade fails on the first pass,
   re-activate once the interfaces and impl classes are green.

See `07_object_package_map.md` for the full object list.

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

`SE38` → `ZAB_V1_UT_DEMO`. Selection screen:

| Field | Meaning |
|---|---|
| `P_AREA` | listbox of the functional areas (from domain `ZAB_V1_UT_AREA`); default `STR` |
| `P_ALL` | run every area instead of just `P_AREA` |
| `P_CMT` | allow side effects that need a COMMIT (`LOG~save`) |
| `P_SEND` | actually send the demo mail |
| `P_RCPT` | recipient address for `P_SEND` |

| Area | What the demo does |
|---|---|
| STR | `to_amount('1.234,56')`, `from_amount`, SHA-256, email validator, amount-in-words |
| CONV | `add_months`, quarter bounds, commercial rounding |
| TAB | `diff` on two fixtures → insert/update/delete counts |
| DB | `exists` on `ZAB_V1_UT_ADPT` (area `ATTACH`) |
| FILE | `mime_type`, `csv_build` header line |
| JSON | `serialize` (pretty + camelCase) of a structure |
| LOG | in-memory log, `to_string`; `save` only if `P_CMT` |
| MSG | `t100_to_text` for `ZAB_V1_UT/013`, `bapiret_max_severity` on S/W/E |
| AUTH | `check` on `S_TCODE`/`SE38`, `is_user_valid( sy-uname )` |
| NUM | 3 × `next` from `ZAB_V1_UT` interval `01` (needs §2.2) |
| MAIL | `build_html_body` length; sends only if `P_SEND` + `P_RCPT` |
| ATTACH | `new_guid_c32`, `attach`→`list` against the configured adapter |
| SYS | `system_info`, `object_exists('CLAS','ZCL_AB_V1_UT')` |
| CFG | `enum_values('ZAB_V1_UT_AREA')` count |
| RAP | `new_cid` |
| JOB | `is_finished` for an unknown job |

No SAP GUI control classes are used — safe to run in batch (`SUBMIT … VIA JOB`).
Each area runs inside its own `TRY/CATCH zcx_ab_v1_ut`, so a missing prerequisite
(e.g. SNRO object for NUM) prints `ERROR: …` and the run continues.

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
