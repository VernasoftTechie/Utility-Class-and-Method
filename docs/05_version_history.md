# 05 – ZCL_AB_V1_UT Utility Framework – Version History

Semantic-ish versioning: **MAJOR** = breaking interface change · **MINOR** = additive
(new method / new area) · **PATCH** = implementation fix, no signature change.

---

## Unreleased

### Docs (this commit)
- Added `docs/01_architecture.md` – architecture, RAP-mode model, 8 accepted deviations.
- Added `docs/02_functional_specification.md` – per-area capabilities + worked examples.
- Added `docs/03_technical_specification.md` – binding signatures for 19 interfaces, facade,
  exception, message class, DDIC, GUI class, reports.
- Added `docs/04_test_scenarios.md` – ABAP Unit scenario catalogue + coverage map.
- Added `docs/06_demo_guide.md` – manual setup (SLG0 / SNRO / SM30) + demo run guide.
- Repo scaffolding: `.abapgit.xml` (`/src/`, PREFIX), `src/` placeholder.

**Status:** awaiting architecture approval (Rulebook §8 step 2). No ABAP objects committed yet.

---

## Planned – v1.0.0 (first implementation drop)

On approval, per `01_architecture.md` §12 build order:

1. Message class `ZAB_V1_UT`, exception `ZCX_AB_V1_UT`.
2. DDIC: domain `ZAB_V1_UT_AREA`, data element `ZAB_V1_UT_ADAPT`, table `ZAB_V1_UT_ADPT`.
3. `ZIF_AB_V1_UT_TYPES` + 18 area interfaces.
4. 18 headless implementation classes + ABAP Unit tests.
5. Facade `ZCL_AB_V1_UT` + injection & dependency-guard tests.
6. `ZCL_AB_V1_UT_GUI`.
7. Reports `ZAB_V1_UT_DEMO`, `ZAB_V1_UT_DEMO_GUI`.
8. ATC run (production + gated-exemption profiles), fixes.
9. C1 release of interfaces + facade + exception + types.

---

## Change Log

| Version | Date | Author | Summary |
|---|---|---|---|
| — | 2026-08-31 | Vernasoft AI | Document set created; architecture v2 (full 18-area catalogue, gated helpers included, `ZAB_V1_UT_*` naming) drafted for approval. |
| — | 2026-09-01 | Vernasoft AI | Approved. Build stages 1–3a pushed. Activation fixes: data element `ZAB_V1_UT_AREA` label lengths; **`RETURNING` params changed from generic `TYPE p` to `TYPE decfloat34`** in `_STR` (`to_amount`, `to_quantity`) and `_CONV` (`convert_unit`, `round`); `_CONV` `iv_rate_type` `kurst_curr`→`kurst`; `_NUM`/`_SYS` packed exports → `decfloat34`; `_MAIL` `ty_mail-to`→`recipients`, `commit`→`commit_work` (reserved-word safety). |

---

## Compatibility Notes

- Target: **SAP S/4HANA 2023 on-premise**, Standard ABAP language version.
- `xco_cp_xlsx` read+write assumed available (2023 FPS). If a lower release is targeted,
  `ZCL_AB_V1_UT_EXCEL` falls back to `cl_fdt_xl_spreadsheet` (read) — tracked as a future
  PATCH, no signature change.
- `/ui2/cl_json` presence assumed (UI2 component). Fallback path documented in `01` §7-1.
- Package assignment is **not** part of this repo — set during abapGit pull.
