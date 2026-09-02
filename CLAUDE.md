# CLAUDE.md — ZCL_AB_V1_UT utility framework

## ALWAYS do this first

**Before writing or changing any ABAP source, any abapGit serialized object (`.clas.*`,
`.intf.*`, `.prog.*`, `.tabl.xml`, `.dtel.xml`, `.doma.xml`, `.msag.xml`), or before
concluding that a piece of code "should work" — read [`docs/00_engineering_log.md`](docs/00_engineering_log.md).**

It is the running log of every mistake already made on this project (abapGit
serialization quirks, ABAP type-system by-reference rules, dynamic-token syntax,
uncatchable dumps, wrong API signatures) and how to avoid them. Each entry cost a
pull → activate → ATC → fix cycle. Do not repeat them.

When a new bug is found and fixed, **add it to `docs/00_engineering_log.md`** (the right
section + the fix-history table) in the same change.

## Project facts

- Target: **SAP S/4HANA 2023 on-premise, Standard ABAP 7.58**.
- Repo layout: flat `/src/`, abapGit `FOLDER_LOGIC=PREFIX`, package `ZABAP_UTIL`
  (assigned on pull). `docs/*`, `README.md`, `.gitattributes`, this file → `<IGNORE>`.
- Naming: `ZCL_AB_V1_UT` (facade), `ZCL_AB_V1_UT_<AREA>`, `ZIF_AB_V1_UT_<AREA>`,
  `ZCX_AB_V1_UT`, message class `ZAB_V1_UT`, DDIC `ZAB_V1_UT_*`, reports `ZAB_V1_UT_*`.
- Docs: `01` architecture · `02` functional spec · `03` technical spec · `04` test
  scenarios · `05` version history · `06` demo guide · `07` object→package map ·
  `00` engineering log.
- **The ATC / SLIN run on package `ZABAP_UTIL` is the authoritative syntax check.**
  abapGit "activate" does not reliably block syntax errors.

## Working rules

- Architecture/spec approval before implementation (Rulebook §8). Stage commits.
- Every runtime failure path raises `ZCX_AB_V1_UT` — no method may dump. Guard FMs that
  `MESSAGE X` with an existence check first.
- No `COMMIT WORK` except the documented sanctioned cases (`01` §2).
- Every public method needs a **working demo** in `ZAB_V1_UT_DEMO` / `ZAB_V1_UT_DEMO_GUI`.
- Run the checklist in `docs/00_engineering_log.md` §7 before committing ABAP.
