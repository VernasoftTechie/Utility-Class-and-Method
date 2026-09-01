# Utility-Class-and-Method

**`ZCL_AB_V1_UT`** — a general-purpose, interface-driven ABAP utility framework for
SAP S/4HANA 2023 (on-premise), consumed by RAP applications, executable reports,
background jobs and migration tooling.

> **Status: v1.0.0 — code complete.** All 18 areas implemented and activated on
> S/4HANA 2023. Pending: ATC run + C1 release. See
> [`docs/05_version_history.md`](docs/05_version_history.md) for scope delivered vs. spec.

Built to the *Vernasoft ABAP & RAP Engineering Rulebook*: Clean ABAP, RAP-compliant,
Clean-Core-aligned, ATC-compliant, fully documented, repository-driven.

---

## What's here

| Path | Contents |
|---|---|
| [`docs/01_architecture.md`](docs/01_architecture.md) | Architecture, RAP-mode model, layering, 8 accepted rulebook deviations, object inventory, build order |
| [`docs/02_functional_specification.md`](docs/02_functional_specification.md) | What each of the 18 areas does — inputs/outputs, RAP-mode, worked example per area |
| [`docs/03_technical_specification.md`](docs/03_technical_specification.md) | Binding ABAP signatures: 19 interfaces, facade, exception, message class, DDIC, GUI class, reports |
| [`docs/04_test_scenarios.md`](docs/04_test_scenarios.md) | ABAP Unit scenario catalogue + coverage map |
| [`docs/05_version_history.md`](docs/05_version_history.md) | Change log + release plan |
| [`docs/06_demo_guide.md`](docs/06_demo_guide.md) | Manual setup (SLG0 / SNRO / SM30) + how to run the demo reports |
| [`docs/07_object_package_map.md`](docs/07_object_package_map.md) | Every object → package `ZABAP_UTIL` |
| `src/` | ABAP objects (abapGit, `/src/` flat, FOLDER_LOGIC `PREFIX`, package `ZABAP_UTIL`) |

---

## Design in one picture

```
RAP BOs / queries / EML ─┐        Classic reports / dialog progs ─┐
Reports / background jobs ┼─► ZCL_AB_V1_UT (static facade)        │
                          │     str() conv() tab() db() file()    │
                          │     excel() json() log() msg() auth()  │
                          │     num() mail() attach() sys() cfg()   │
                          │     rap() job()                        │
                          │        │ returns ZIF_AB_V1_UT_<area>   │
                          │        ▼                               ▼
                          │  headless impls (Core / Defer)   ZCL_AB_V1_UT_GUI
                          │                                  (ALV, dynamic ALV,
                          │                                   frontend files — GUI only,
                          │                                   never via the facade)
                          ▼
   Gated, own ATC exemption: ZIF_AB_V1_UT_DB (dynamic SELECT) · ZIF_AB_V1_UT_FILE (OPEN DATASET)
```

### RAP-mode tags (on every method)

| Tag | Meaning |
|---|---|
| **Core** | pure / read-only — safe anywhere, including RAP BO logic |
| **Defer** | side-effecting — RAP only in `save_modified` / late numbering / after commit |
| **GUI** | SAP GUI only — `ZCL_AB_V1_UT_GUI`, never from RAP |
| **Gated** | on-prem only, ATC-exempted, **not for RAP BO logic** — dynamic SELECT, app-server files |

---

## Functional areas (18)

`STR` · `CONV` · `TAB` · `DB` · `FILE` · `EXCEL` · `JSON` · `LOG` · `MSG` · `AUTH` ·
`NUM` · `MAIL` · `ATTACH` · `ALV` · `SYS` · `CFG` · `RAP` · `JOB`

---

## Naming convention

| Object | Pattern |
|---|---|
| Facade / impl / GUI classes | `ZCL_AB_V1_UT`, `ZCL_AB_V1_UT_<AREA>`, `ZCL_AB_V1_UT_GUI` |
| Interfaces | `ZIF_AB_V1_UT_<AREA>`, `ZIF_AB_V1_UT_TYPES` |
| Exception | `ZCX_AB_V1_UT` |
| Message class | `ZAB_V1_UT` |
| DDIC | `ZAB_V1_UT_ADPT` (table), `ZAB_V1_UT_AREA` (domain + data element) |
| Reports | `ZAB_V1_UT_DEMO`, `ZAB_V1_UT_DEMO_GUI` |

---

## Object inventory (committed)

**Interfaces (19):** `ZIF_AB_V1_UT_TYPES` + `_STR _CONV _TAB _DB _FILE _EXCEL _JSON _LOG
_MSG _AUTH _NUM _MAIL _ATTACH _ALV _SYS _CFG _RAP _JOB`

**Classes (22):** `ZCL_AB_V1_UT` (facade) · `ZCL_AB_V1_UT_STR _CONV _TAB _DB _FILE _EXCEL
_JSON _LOG _MSG _AUTH _NUM _MAIL _ATTACH_STUB _ATTACH_GOS _SYS _CFG _RAP _JOB` (18 impls) ·
`ZCL_AB_V1_UT_PHASE` · `ZCL_AB_V1_UT_GUI` · `ZCX_AB_V1_UT`

**Other:** message class `ZAB_V1_UT` · domain + data element `ZAB_V1_UT_AREA` · table
`ZAB_V1_UT_ADPT` · reports `ZAB_V1_UT_DEMO` / `ZAB_V1_UT_DEMO_GUI` · 13 ABAP Unit classes

---

## Installation

1. Create package **`ZABAP_UTIL`**.
2. abapGit → Online → `https://github.com/VernasoftTechie/Utility-Class-and-Method.git`
   → **Package `ZABAP_UTIL`** → Pull → activate.
   Flat `/src/` + `FOLDER_LOGIC PREFIX` ⇒ every object is created in `ZABAP_UTIL`
   ([`docs/07_object_package_map.md`](docs/07_object_package_map.md)).
3. One-off manual setup (SLG0 / SNRO / SM30) in
   [`docs/06_demo_guide.md`](docs/06_demo_guide.md) §2.
