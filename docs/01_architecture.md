# 01 – ZCL_AB_V1_UT Utility Framework – Architecture

**Version:** 1.0
**Status:** DRAFT – awaiting architecture approval (Rulebook §8, step 2)
**Platform:** SAP S/4HANA 2023 (on-premise), Standard ABAP, Clean-Core-aligned
**Repository:** https://github.com/VernasoftTechie/Utility-Class-and-Method
**Package:** `ZABAP_UTIL` (all objects; link the repo to it on abapGit pull — see `07_object_package_map.md`)
**abapGit layout:** `STARTING_FOLDER=/src/`, `FOLDER_LOGIC=PREFIX`, `MASTER_LANGUAGE=E`, flat

---

## 1. Purpose & Positioning

`ZCL_AB_V1_UT` is a **general-purpose, reusable, interface-driven utility framework** –
not RAP-only. It is consumed by:

- RAP behaviour pools, determinations, validations, actions, queries, EML
- Classic executable reports, function modules, background jobs, migration tooling

It contains **no business logic** – only cross-cutting technical helpers.

### Execution-context split

| Component | Reachable from | Contains |
|---|---|---|
| `ZCL_AB_V1_UT` (static facade) → area interfaces → headless impls | RAP + reports + jobs | everything tagged **Core** / **Defer** |
| `ZCL_AB_V1_UT_GUI` (called directly, never via facade) | classic reports / dialog programs only | ALV, dynamic ALV, presentation-server files, dialogs |

Delivery: **entire catalogue in one drop**, including **ATC-gated** helpers (dynamic SELECT,
application-server file I/O) isolated behind their own interfaces.

---

## 2. RAP-Mode Classification (applied to every method)

| Tag | Rule |
|---|---|
| **Core** | Pure / read-only / no UI / no side effects. Safe anywhere incl. RAP BO logic. |
| **Defer** | Side-effecting. RAP-usable only in `save_modified` / late-numbering / `additional save` / after `COMMIT`. Never mid-transaction or in draft. Guarded by a phase hint → raises `ZCX_AB_V1_UT` (msg 013) if misused. |
| **GUI** | SAP GUI only (`cl_gui_*`, `cl_salv_table` display, frontend files). Lives in `ZCL_AB_V1_UT_GUI`. Not RAP. Fiori equivalent = CDS UI annotations / OData media streams. |
| **Gated** | Works on-prem Standard ABAP (incl. RAP) but breaks Clean Core / not ABAP-Cloud portable. Separate ATC exemption; documented "reports & migration tooling only, not RAP BO logic". Prefer the noted alternative. |

### Cross-cutting hard rules (enforced by ATC + a dependency unit test)

1. No `COMMIT WORK` / `ROLLBACK` anywhere in the framework, with **sanctioned
   exceptions**, each caller-opt-in and off for RAP:
   - `ZIF_AB_V1_UT_MAIL~send` issues `COMMIT WORK` *only* when the caller passes
     `is_mail-commit_work = abap_true` (classic report / batch use). RAP callers leave
     it unset and let the LUW / saver commit.
   - `ZIF_AB_V1_UT_BULK~run_packaged` / `~resume` issue `COMMIT WORK` after each package
     *only* when the caller passes `iv_commit_each = abap_true` (default; the standard
     mass-processing pattern — bounded LUW per package, DB locks released, restartable).
     RAP / LUW-owning callers pass `iv_commit_each = abap_false`.
   `ZIF_AB_V1_UT_LOG~save` avoids the statement entirely by using `BAL_DB_SAVE` on a
   secondary DB connection.
2. No `MESSAGE` to screen, no `CALL SCREEN/TRANSACTION/DIALOG` in the core.
   `SUBMIT ... VIA JOB ... AND RETURN` is allowed in `ZIF_AB_V1_UT_JOB~schedule_job` (Defer).
3. No `cl_gui_*` / `cl_salv_*` reference reachable from `ZCL_AB_V1_UT` (asserted by test).
4. Side-effecting methods take `iv_commit = abap_false` and document their RAP phase.

---

## 3. Design Principles

1. **Facade + one interface per functional area.** Static facade `ZCL_AB_V1_UT` exposes lazy
   accessors returning area interfaces; each area impl stays small (ATC-clean).
2. **Interface-driven for testability.** Every area mockable via ABAP Unit doubles; facade
   has per-area injection seams (`set_<area>( )`) + `reset( )`.
3. **No business logic.**
4. **Headless-safe by construction.** Zero static dependency core → GUI.
5. **Released-API-first.** Unavoidable classic/gated APIs isolated behind interfaces and
   listed in §7 (Deviations).
6. **Caller owns the LUW.**
7. **Single exception type** `ZCX_AB_V1_UT` (`CX_STATIC_CHECK`, `IF_T100_MESSAGE`, `previous`),
   messages from `ZAB_V1_UT`. No `MESSAGE` statements.
8. **Clean ABAP** throughout (inline decl, `VALUE`/`REDUCE`/`CORRESPONDING`, constructor
   operators, 100% OO; no header lines / `OCCURS` / `TABLES` / SELECT-in-LOOP / native SQL).

---

## 4. Functional Area Catalogue

Legend in §2. Full method signatures in `03_technical_specification.md`.

| # | Interface | Area | Highlights | Modes present |
|---|---|---|---|---|
| 1 | `ZIF_AB_V1_UT_STR`   | String / Type / Conversion | string↔amount/qty/date, ALPHA, Base64, hash, regex, validators, amount-in-words | Core |
| 2 | `ZIF_AB_V1_UT_CONV`  | Date / Time / Number / Currency / Unit | working-day math, fiscal periods, tz conversion, currency & UoM conversion, rounding | Core |
| 3 | `ZIF_AB_V1_UT_TAB`   | Internal Table / RTTI / Dynamic Data | dynamic itab, CORRESPONDING+mapping, group/aggregate, **table diff**, ranges, chunk, pivot | Core |
| 4 | `ZIF_AB_V1_UT_DB`    | Dynamic Database Access | dynamic SELECT, exists, DDIC metadata, WHERE from ranges | Core + **Gated** |
| 5 | `ZIF_AB_V1_UT_FILE`  | Files | logical filenames, MIME, zip, CSV; app-server I/O; (frontend → GUI) | Core + **Gated** + GUI |
| 6 | `ZIF_AB_V1_UT_EXCEL` | Spreadsheet | xlsx read/write (xstring), dynamic column mapping, template gen | Core (+ GUI transfer) |
| 7 | `ZIF_AB_V1_UT_JSON`  | JSON / XML | (de)serialize RTTI, pretty, JSON-path, schema gen, XML, JSON↔XML | Core |
| 8 | `ZIF_AB_V1_UT_LOG`   | Application Log (BAL) | create/add/save/display, BAL↔BAPIRET2↔string | Core + **Defer** + GUI |
| 9 | `ZIF_AB_V1_UT_MSG`   | Messages / Exceptions | T100→text/BAPIRET2, exception→text, severity helpers, →REPORTED/FAILED | Core |
| 10 | `ZIF_AB_V1_UT_AUTH` | Authorization | generic AUTHORITY-CHECK, role check, user valid/locked, permitted values | Core |
| 11 | `ZIF_AB_V1_UT_NUM`  | Number Ranges | next number, status/config read | Core + **Defer** |
| 12 | `ZIF_AB_V1_UT_MAIL` | Email / Notification | CL_BCS send (HTML, PDF/xstring), HTML body builder, workflow event | Core + **Defer** |
| 13 | `ZIF_AB_V1_UT_ATTACH` | Attachments / GOS / DMS | GUID, GOS list/get/attach, adapter (stub/GOS/OpenText), binary↔SOLIX | Core + **Defer** |
| 14 | `ZIF_AB_V1_UT_ALV`  | ALV / Output | fullscreen/container/popup SALV, dynamic ALV, field catalog, variant, toolbar | **GUI** |
| 15 | `ZIF_AB_V1_UT_SYS`  | System / Environment | sysid/client/prod check, object existence, runtime timer, OTR text | Core |
| 16 | `ZIF_AB_V1_UT_CFG`  | Config / Customizing | TVARVC, feature toggles, generic Z-config read, enum provider | Core |
| 17 | `ZIF_AB_V1_UT_RAP`  | RAP-native helpers | EML wrapper, %cid/%tky, FAILED/REPORTED builders, ETag, deep CORRESPONDING+%control | Core |
| 18 | `ZIF_AB_V1_UT_JOB`  | Parallel / Background | `cl_abap_parallel`, job scheduling, bgPF trigger | Core + **Defer** |

Shared types live in `ZIF_AB_V1_UT_TYPES` (types-only, no methods).

---

## 5. Object Inventory (abapGit `/src/`, flat)

**Interfaces (19):** `ZIF_AB_V1_UT_TYPES` + the 18 area interfaces above.

**Classes (22):**
`ZCL_AB_V1_UT` (facade) ·
`ZCL_AB_V1_UT_STR / _CONV / _TAB / _DB / _FILE / _EXCEL / _JSON / _LOG / _MSG / _AUTH /
_NUM / _MAIL / _ATTACH_GOS / _ATTACH_STUB / _SYS / _CFG / _RAP / _JOB` (18 headless impls) ·
`ZCL_AB_V1_UT_GUI` (implements `ZIF_AB_V1_UT_ALV` + frontend file services) ·
`ZCX_AB_V1_UT` (exception)

**Message class (1):** `ZAB_V1_UT`

**DDIC (3):** `ZAB_V1_UT_ADPT` (table: `AREA`, `ADAPTER_CLASS`, `IS_ACTIVE`),
`ZAB_V1_UT_AREA` (domain), `ZAB_V1_UT_ADAPT` (data element)

**Reports (2):** `ZAB_V1_UT_DEMO` (Core/Defer smoke test), `ZAB_V1_UT_DEMO_GUI` (ALV / files)

**ABAP Unit:** `*.clas.testclasses.abap` includes for all 18 headless impls + facade +
`ZCX_AB_V1_UT`. Dependency-guard test asserts no `CL_GUI*` / `CL_SALV*` in the used-objects
set of the facade and headless impls. `ZCL_AB_V1_UT_GUI` excluded from coverage.

**Manual (abapGit cannot serialise) — see `06_demo_guide.md`:**
- SLG0 log object `ZAB_V1_UT` + subobject `GENERAL`
- SNRO number-range object `ZAB_V1_UT` (for the `NUM` demo only)
- `ZAB_V1_UT_ADPT` seed rows via SM30 (`ATTACH → …_STUB` sandbox / `…_GOS` QA+PRD)

---

## 6. Facade & Layering

```
RAP behaviour pools / queries / EML ─┐        Classic reports / dialog progs ─┐
Executable reports / background jobs ─┼─► ZCL_AB_V1_UT (static facade)        │
                                      │     str() conv() tab() db() file()    │
                                      │     excel() json() log() msg() auth() │
                                      │     num() mail() attach() sys() cfg()  │
                                      │     rap() job()  + set_*/reset seams   │
                                      │        │ returns ZIF_AB_V1_UT_<area>   │
                                      │        ▼                               │
                                      │  default impl (lazy singleton)         │
                                      │        │ uses                          ▼
                                      │  released/stable APIs        ZCL_AB_V1_UT_GUI
                                      │  cl_bali · xco_cp_xlsx ·     (ALV, dynamic ALV,
                                      │  xco_cp_json · /ui2/cl_json ·  field catalog, layout,
                                      │  cl_bcs · cl_gos_api ·         toolbar, frontend files)
                                      │  cl_system_uuid · cl_abap_* ·  — called DIRECTLY,
                                      │  FM AUTHORITY_CHECK ·          never via the facade
                                      │  cl_numberrange_runtime ·
                                      │  cl_abap_parallel
                                      ▼
   Gated (own ATC exemption): ZIF_AB_V1_UT_DB dynamic SELECT · ZIF_AB_V1_UT_FILE OPEN DATASET
   Config: ZAB_V1_UT_ADPT          SLG0: ZAB_V1_UT (manual)
```

- Accessors lazily instantiate + cache a singleton default impl.
- `ZCL_AB_V1_UT=>set_<area>( io_double )` / `=>reset( )` — unit tests only.
- Facade has **no reference** to `ZCL_AB_V1_UT_GUI`.

---

## 7. Accepted Deviations from the Rulebook (for ATC exemption & governance sign-off)

| # | Deviation | Rationale | Mitigation |
|---|---|---|---|
| 1 | `/ui2/cl_json` (SAP-delivered, not C1-released) | universal on-prem availability; camelCase + pretty | isolated behind `ZIF_AB_V1_UT_JSON`; fallback `CALL TRANSFORMATION id` + `xco_cp_json` |
| 2 | Classic APIs `cl_bcs`, FM `AUTHORITY_CHECK`, GOS | on-prem 2023, no released equivalent with same scope | each behind its interface; swappable |
| 3 | SAP GUI APIs (`cl_salv_table`, `cl_gui_*`) | ALV + file dialogs are inherently GUI | fully quarantined in `ZCL_AB_V1_UT_GUI`; dependency-guard unit test |
| 4 | Naming stem `AB_V1_UT` (not domain-specific) | reusable cross-project framework | type prefixes `ZCL_`/`ZIF_`/`ZCX_` retained; DDIC/msgclass/reports use `ZAB_V1_UT_` |
| 5 | Reports `ZAB_V1_UT_DEMO` / `_DEMO_GUI` | demo artefacts required by Rulebook step 5 | excluded from strict production ATC profile |
| 6 | Manual SLG0 / SM30 / SNRO steps | abapGit cannot serialise these | documented in `06_demo_guide.md` |
| 7 | **Dynamic SELECT** (`ZIF_AB_V1_UT_DB`) | migration-tool scanning + generic report needs | **own ATC exemption**; `Gated`; "not for RAP BO logic / not ABAP-Cloud portable"; prefer typed CDS |
| 8 | **`OPEN DATASET`** app-server file I/O (`ZIF_AB_V1_UT_FILE`) | interface/batch file exchange on-prem | **own ATC exemption**; `Gated`; `S_DATASET` check + logical filename + path validation mandatory |

---

## 8. Error Handling & Messages

`ZCX_AB_V1_UT` — single exception, `IF_T100_MESSAGE`, `previous`, optional `severity`.
Message class `ZAB_V1_UT` — full seed list in `03_technical_specification.md` §Messages.

---

## 9. Security (Rulebook §6)

- `ZCL_AB_V1_UT_AUTH` is the single sanctioned `AUTHORITY-CHECK` wrapper; no bypass.
- `ZIF_AB_V1_UT_FILE` (gated): mandatory `S_DATASET` check + logical filename resolution +
  path-traversal validation before any `OPEN DATASET`.
- `ZIF_AB_V1_UT_DB` (gated): table/field identifiers validated against DDIC; WHERE built
  only from typed range tables — no free-text injection.
- `ZCL_AB_V1_UT_ATTACH`: configurable authority object (default `S_GOS_GOS`) before
  `attach` / `get`.
- `ZCL_AB_V1_UT_MAIL`: recipients never derived from untrusted input.
- No hardcoded users / credentials / RFC destinations / addresses.
- All failures via `ZCX_AB_V1_UT` + optional BAL — no silent failures.

---

## 10. Performance (Rulebook §1)

- Set-based DB access only; single-row reads by key; no SELECT-in-LOOP; explicit field lists.
- Excel streamed via XCO; configurable max-row guard.
- `ZIF_AB_V1_UT_TAB` aggregation uses `GROUP BY` runtime, not nested loops.
- Facade caches area singletons.
- `ZIF_AB_V1_UT_JOB` for large volumes (`cl_abap_parallel`).
- No implicit COMMIT; LUW owned by caller / RAP runtime.

---

## 11. Locked Assumptions

1. S/4HANA 2023 on-premise; Standard ABAP language version.
2. Facade + one interface per area; 18 area interfaces + `ZIF_AB_V1_UT_TYPES`.
3. Full catalogue delivered together, including gated `DB` + `FILE` helpers.
4. Excel engine `xco_cp_xlsx`; JSON `/ui2/cl_json` + `xco_cp_json`.
5. Email `cl_bcs`, default sender = system address, caller-overridable.
6. Attachments: GOS via `cl_gos_api` + `_STUB` + `ZAB_V1_UT_ADPT` config table.
7. Auth: FM `AUTHORITY_CHECK`, `AGR_USERS`, `USR02`.
8. Gated helpers isolated behind `ZIF_AB_V1_UT_DB` / `ZIF_AB_V1_UT_FILE`, each with its own
   ATC exemption and "not for RAP BO logic" warning.
9. Interfaces + facade released **C1** after first ATC-clean run.
10. Names: `ZCL_AB_V1_UT`, `ZCL_AB_V1_UT_GUI`, `ZIF_AB_V1_UT_*`, `ZCL_AB_V1_UT_<area>`,
    `ZCX_AB_V1_UT`, message class `ZAB_V1_UT`, `ZAB_V1_UT_DEMO`, `ZAB_V1_UT_DEMO_GUI`.
11. BAL log object `ZAB_V1_UT` / subobject `GENERAL` — manual SLG0.
12. **Package `ZABAP_UTIL`** — one flat package for every object (`src/package.devc.xml`
    supplies its short text); link the repo to it on abapGit pull.

### Resolved defaults

| # | Decision |
|---|---|
| A | SLG0: single object `ZAB_V1_UT` + subobject `GENERAL` |
| B | Attachment authority object: `S_GOS_GOS`, caller-overridable |
| C | Sandbox adapter seed `_STUB`; QA/PRD `_GOS` |
| D | C1 release after first ATC-clean run |

---

## 12. Build Order (on approval)

1. Message class `ZAB_V1_UT`, exception `ZCX_AB_V1_UT`
2. DDIC: `ZAB_V1_UT_AREA` (domain), `ZAB_V1_UT_ADAPT` (DE), `ZAB_V1_UT_ADPT` (table)
3. `ZIF_AB_V1_UT_TYPES` + all 18 area interfaces
4. Headless impls + unit tests, in dependency order:
   `STR → CONV → MSG → SYS → CFG → TAB → JSON → LOG → AUTH → DB → FILE → EXCEL → NUM →
   MAIL → ATTACH (STUB, GOS) → RAP → JOB`
5. `ZCL_AB_V1_UT` facade + injection tests + dependency-guard test
6. `ZCL_AB_V1_UT_GUI` (`ZIF_AB_V1_UT_ALV` + frontend files)
7. `ZAB_V1_UT_DEMO`, `ZAB_V1_UT_DEMO_GUI`
8. Docs refresh, README update
9. ATC run (production profile + gated-exemption profile) → fix → C1 release

---

## 13. Approval

- [ ] Architecture approved — proceed to implementation per §12.
- [ ] Changes requested (see comments).
