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

## Scope delivered vs. spec (v1.0.0)

The design docs 02/03 describe the full catalogue. During implementation a few methods
were trimmed where a correct, generic, testable implementation was not feasible in a
standalone utility (they belong closer to the caller). The **binding contract is the
activated interface**; docs 02/03 are being updated to match.

| Interface | Delivered | Trimmed (do inline in the caller / future) |
|---|---|---|
| `ZIF_AB_V1_UT_STR` | all | – (`alpha_in` gained `iv_length`) |
| `ZIF_AB_V1_UT_CONV` | all | – |
| `ZIF_AB_V1_UT_TAB` | all | `pivot` |
| `ZIF_AB_V1_UT_DB` | `read`(gated) `exists` `read_single` `describe` `where_from_ranges` | – |
| `ZIF_AB_V1_UT_FILE` | all (`as_*` gated) | – |
| `ZIF_AB_V1_UT_EXCEL` | `read` `write` `generate_template` | `write_multi` |
| `ZIF_AB_V1_UT_JSON` | `serialize` `deserialize` `pretty` `describe` `xml_serialize` `xml_deserialize` | `path_get` `path_set` `to_xml` `from_xml` |
| `ZIF_AB_V1_UT_LOG` | all (`to_string` `iv_sep` OPTIONAL) | – |
| `ZIF_AB_V1_UT_MSG` | `t100_to_*` `exception_to_text` `bapiret_*` `raise` `symsg_to_bapiret` | `to_reported` `to_failed` (→ `ZIF_AB_V1_UT_RAP`) |
| `ZIF_AB_V1_UT_AUTH` | `check` `check_or_raise` `user_has_role` `is_user_valid` | `permitted_values` |
| `ZIF_AB_V1_UT_NUM` | all | – |
| `ZIF_AB_V1_UT_MAIL` | `send` `build_html_body` | `raise_workflow_event` |
| `ZIF_AB_V1_UT_ATTACH` | all (STUB + GOS adapters) | – |
| `ZIF_AB_V1_UT_ALV` | `show` `show_dynamic` `build_fieldcat` | `layout_save` `layout_load` `toolbar` |
| `ZIF_AB_V1_UT_SYS` | `system_info` `object_exists` `timer_start` `timer_stop` | `text` |
| `ZIF_AB_V1_UT_CFG` | all | – |
| `ZIF_AB_V1_UT_RAP` | `new_cid` `messages_to_bapiret` `bapiret_to_text` `corresponding_control` | `read_entity` `modify_entity` `failed_add` `reported_add` `auth_to_failed` |
| `ZIF_AB_V1_UT_JOB` | `schedule_job` `is_finished` | `run_parallel` (→ use `CL_ABAP_PARALLEL`), `trigger_bgpf` |

### Sanctioned `COMMIT WORK`
`ZIF_AB_V1_UT_MAIL~send` issues `COMMIT WORK` only when `is_mail-commit_work = abap_true`
(classic / batch). `ZIF_AB_V1_UT_LOG~save` uses `BAL_DB_SAVE` on a 2nd DB connection
(`iv_commit = abap_true`) and issues no `COMMIT` statement.
`ZIF_AB_V1_UT_BULK~run_packaged`/`~resume` — `COMMIT WORK` per package only when
`iv_commit_each = abap_true` (default). `ZIF_AB_V1_UT_BAPI~mass`/`~commit` — via
`BAPI_TRANSACTION_COMMIT`, only when `iv_test_run = abap_false`.

## Scope delivered vs. spec (v1.1.0 – implementation toolkit)

| Interface | Delivered | Trimmed / report-only |
|---|---|---|
| `ZIF_AB_V1_UT_HTTP` | REST (`get/post/put/patch/delete_json`), `request`, `paginate`, `download_binary`, `upload_multipart`, OAuth2 client-credentials, retry/backoff, OData + SOAP builders | – |
| `ZIF_AB_V1_UT_BULK` | `run_packaged`, `resume`, `run_parallel` (`CL_ABAP_PARALLEL`), `progress`; `ZCL_AB_V1_UT_BULK_STORE_MEM` in-memory store | `run_parallel` keys need a global/DDIC line type |
| `ZIF_AB_V1_UT_BAPI` | `call`, `call_by_name` (FUPARAREF auto-bind), `mass`, `commit`, `rollback`, `bdc_run`, `bdc_dynpro`, `bdc_field` | – |
| `ZIF_AB_V1_UT_CUTOVER` | `task_run`, `readiness_check`, `lock_users`, `unlock_users` | `suspend_jobs`/`release_jobs` **report-only** — live released↔scheduled change raises msg 032 (needs a landscape scheduler API); action via SM37 |
| `ZIF_AB_V1_UT_TRANSPORT` | `objects_in_request`, `where_used`, `custom_code_inventory`, `locking_requests` | – |

### Remaining before release
- ATC run (production + gated-exemption profiles), fix findings.
- C1 release of `ZIF_AB_V1_UT_TYPES` + 18 interfaces + `ZCL_AB_V1_UT` + `ZCX_AB_V1_UT`.
- Manual: SLG0 `ZAB_V1_UT`, SNRO `ZAB_V1_UT` (demo), SM30 seed `ZAB_V1_UT_ADPT`.

---

## Change Log

| Version | Date | Author | Summary |
|---|---|---|---|
| — | 2026-08-31 | Vernasoft AI | Document set created; architecture v2 (full 18-area catalogue, gated helpers included, `ZAB_V1_UT_*` naming) drafted for approval. |
| — | 2026-09-01 | Vernasoft AI | Approved. Build stages 1–3a pushed. Activation fixes: data element `ZAB_V1_UT_AREA` label lengths; `RETURNING` params generic `TYPE p` → `TYPE decfloat34` in `_STR`/`_CONV`; `_CONV` `iv_rate_type` `kurst_curr`→`kurst`; `_MAIL` `ty_mail-to`→`recipients`, `commit`→`commit_work`. |
| — | 2026-09-02 | Vernasoft AI | v1.1.0 implementation toolkit built (stages 1–8): DDIC + msgs 021–035 + 11 interfaces; `ZCL_AB_V1_UT_HTTP` (classic `cl_http_client`); `ZCL_AB_V1_UT_BULK` + `_BULK_STORE_MEM` (`cl_abap_parallel` worker); `ZCL_AB_V1_UT_BAPI` (FUPARAREF auto-bind, BDC); `ZCL_AB_V1_UT_CUTOVER`; `ZCL_AB_V1_UT_TRANSPORT`; facade accessors + seams; `ZAB_V1_UT_DEMO_INT` + `ZCL_AB_V1_UT_DEMO_BULK_H`. Engineering log extended to A24 / G10. Pending: ATC on package + C1 release extension. |
| **v1.0.0** | 2026-09-02 | Vernasoft AI | **All 18 areas implemented, activated in S/4HANA 2023.** 22 classes (facade + 18 area impls + `ZCX_AB_V1_UT` + `ZCL_AB_V1_UT_PHASE` + `ZCL_AB_V1_UT_GUI`), 19 interfaces, message class, 3 DDIC objects, 2 demo reports, 13 ABAP Unit classes. See §"Scope delivered vs. spec" below. Pending: ATC run + C1 release. |

---

## Compatibility Notes

- Target: **SAP S/4HANA 2023 on-premise**, Standard ABAP language version.
- `xco_cp_xlsx` read+write assumed available (2023 FPS). If a lower release is targeted,
  `ZCL_AB_V1_UT_EXCEL` falls back to `cl_fdt_xl_spreadsheet` (read) — tracked as a future
  PATCH, no signature change.
- `/ui2/cl_json` presence assumed (UI2 component). Fallback path documented in `01` §7-1.
- Package assignment is **not** part of this repo — set during abapGit pull.
