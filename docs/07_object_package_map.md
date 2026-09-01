# 07 – ZCL_AB_V1_UT Utility Framework – Object → Package Map

**Target package for every object: `ZABAP_UTIL`**

abapGit serialized objects carry **no** package assignment. Package is resolved from the
folder → package link at pull time. This repo:

| abapGit setting | Value |
|---|---|
| `STARTING_FOLDER` | `/src/` |
| `FOLDER_LOGIC` | `PREFIX` |
| Sub-packages | none – all objects flat in `/src/` |
| Package short text | from `src/package.devc.xml` |

**Result:** link the repo to `ZABAP_UTIL` when adding it in abapGit, and **all objects
below (current and future) are created in `ZABAP_UTIL`.** No per-object mapping needed.

---

## Package

| Object | Type | abapGit file | Package |
|---|---|---|---|
| `ZABAP_UTIL` | Package (DEVC) | `src/package.devc.xml` | `ZABAP_UTIL` |

## DDIC

| Object | Type | abapGit file | Package |
|---|---|---|---|
| `ZAB_V1_UT_AREA` | Domain (DOMA) | `src/zab_v1_ut_area.doma.xml` | `ZABAP_UTIL` |
| `ZAB_V1_UT_AREA` | Data element (DTEL) | `src/zab_v1_ut_area.dtel.xml` | `ZABAP_UTIL` |
| `ZAB_V1_UT_ADPT` | Table (TABL) | `src/zab_v1_ut_adpt.tabl.xml` | `ZABAP_UTIL` |

## Messages & Exception

| Object | Type | abapGit file | Package |
|---|---|---|---|
| `ZAB_V1_UT` | Message class (MSAG) | `src/zab_v1_ut.msag.xml` | `ZABAP_UTIL` |
| `ZCX_AB_V1_UT` | Exception class (CLAS) | `src/zcx_ab_v1_ut.clas.*` | `ZABAP_UTIL` |

## Interfaces (19)

| Object | abapGit file | Package |
|---|---|---|
| `ZIF_AB_V1_UT_TYPES` | `src/zif_ab_v1_ut_types.intf.*` | `ZABAP_UTIL` |
| `ZIF_AB_V1_UT_STR` | `src/zif_ab_v1_ut_str.intf.*` | `ZABAP_UTIL` |
| `ZIF_AB_V1_UT_CONV` | `src/zif_ab_v1_ut_conv.intf.*` | `ZABAP_UTIL` |
| `ZIF_AB_V1_UT_TAB` | `src/zif_ab_v1_ut_tab.intf.*` | `ZABAP_UTIL` |
| `ZIF_AB_V1_UT_DB` | `src/zif_ab_v1_ut_db.intf.*` | `ZABAP_UTIL` |
| `ZIF_AB_V1_UT_FILE` | `src/zif_ab_v1_ut_file.intf.*` | `ZABAP_UTIL` |
| `ZIF_AB_V1_UT_EXCEL` | `src/zif_ab_v1_ut_excel.intf.*` | `ZABAP_UTIL` |
| `ZIF_AB_V1_UT_JSON` | `src/zif_ab_v1_ut_json.intf.*` | `ZABAP_UTIL` |
| `ZIF_AB_V1_UT_LOG` | `src/zif_ab_v1_ut_log.intf.*` | `ZABAP_UTIL` |
| `ZIF_AB_V1_UT_MSG` | `src/zif_ab_v1_ut_msg.intf.*` | `ZABAP_UTIL` |
| `ZIF_AB_V1_UT_AUTH` | `src/zif_ab_v1_ut_auth.intf.*` | `ZABAP_UTIL` |
| `ZIF_AB_V1_UT_NUM` | `src/zif_ab_v1_ut_num.intf.*` | `ZABAP_UTIL` |
| `ZIF_AB_V1_UT_MAIL` | `src/zif_ab_v1_ut_mail.intf.*` | `ZABAP_UTIL` |
| `ZIF_AB_V1_UT_ATTACH` | `src/zif_ab_v1_ut_attach.intf.*` | `ZABAP_UTIL` |
| `ZIF_AB_V1_UT_ALV` | `src/zif_ab_v1_ut_alv.intf.*` | `ZABAP_UTIL` |
| `ZIF_AB_V1_UT_SYS` | `src/zif_ab_v1_ut_sys.intf.*` | `ZABAP_UTIL` |
| `ZIF_AB_V1_UT_CFG` | `src/zif_ab_v1_ut_cfg.intf.*` | `ZABAP_UTIL` |
| `ZIF_AB_V1_UT_RAP` | `src/zif_ab_v1_ut_rap.intf.*` | `ZABAP_UTIL` |
| `ZIF_AB_V1_UT_JOB` | `src/zif_ab_v1_ut_job.intf.*` | `ZABAP_UTIL` |

## Classes (22)

| Object | Status | abapGit file | Package |
|---|---|---|---|
| `ZCL_AB_V1_UT_STR` | committed | `src/zcl_ab_v1_ut_str.clas.*` | `ZABAP_UTIL` |
| `ZCL_AB_V1_UT_CONV` | committed | `src/zcl_ab_v1_ut_conv.clas.*` | `ZABAP_UTIL` |
| `ZCL_AB_V1_UT_TAB` | committed | `src/zcl_ab_v1_ut_tab.clas.*` | `ZABAP_UTIL` |
| `ZCL_AB_V1_UT_DB` | committed | `src/zcl_ab_v1_ut_db.clas.*` | `ZABAP_UTIL` |
| `ZCL_AB_V1_UT_FILE` | committed | `src/zcl_ab_v1_ut_file.clas.*` | `ZABAP_UTIL` |
| `ZCL_AB_V1_UT_EXCEL` | committed | `src/zcl_ab_v1_ut_excel.clas.*` | `ZABAP_UTIL` |
| `ZCL_AB_V1_UT_JSON` | committed | `src/zcl_ab_v1_ut_json.clas.*` | `ZABAP_UTIL` |
| `ZCL_AB_V1_UT_LOG` | committed | `src/zcl_ab_v1_ut_log.clas.*` | `ZABAP_UTIL` |
| `ZCL_AB_V1_UT_MSG` | committed | `src/zcl_ab_v1_ut_msg.clas.*` | `ZABAP_UTIL` |
| `ZCL_AB_V1_UT_AUTH` | committed | `src/zcl_ab_v1_ut_auth.clas.*` | `ZABAP_UTIL` |
| `ZCL_AB_V1_UT_NUM` | committed | `src/zcl_ab_v1_ut_num.clas.*` | `ZABAP_UTIL` |
| `ZCL_AB_V1_UT_MAIL` | committed | `src/zcl_ab_v1_ut_mail.clas.*` | `ZABAP_UTIL` |
| `ZCL_AB_V1_UT_ATTACH_GOS` | committed | `src/zcl_ab_v1_ut_attach_gos.clas.*` | `ZABAP_UTIL` |
| `ZCL_AB_V1_UT_ATTACH_STUB` | committed | `src/zcl_ab_v1_ut_attach_stub.clas.*` | `ZABAP_UTIL` |
| `ZCL_AB_V1_UT_SYS` | committed | `src/zcl_ab_v1_ut_sys.clas.*` | `ZABAP_UTIL` |
| `ZCL_AB_V1_UT_CFG` | committed | `src/zcl_ab_v1_ut_cfg.clas.*` | `ZABAP_UTIL` |
| `ZCL_AB_V1_UT_RAP` | committed | `src/zcl_ab_v1_ut_rap.clas.*` | `ZABAP_UTIL` |
| `ZCL_AB_V1_UT_JOB` | committed | `src/zcl_ab_v1_ut_job.clas.*` | `ZABAP_UTIL` |
| `ZCL_AB_V1_UT_PHASE` | committed | `src/zcl_ab_v1_ut_phase.clas.*` | `ZABAP_UTIL` |
| `ZCL_AB_V1_UT` (facade) | committed | `src/zcl_ab_v1_ut.clas.*` | `ZABAP_UTIL` |
| `ZCL_AB_V1_UT_GUI` | committed | `src/zcl_ab_v1_ut_gui.clas.*` | `ZABAP_UTIL` |

## Reports (2)

| Object | Status | abapGit file | Package |
|---|---|---|---|
| `ZAB_V1_UT_DEMO` | committed | `src/zab_v1_ut_demo.prog.*` | `ZABAP_UTIL` |
| `ZAB_V1_UT_DEMO_GUI` | committed | `src/zab_v1_ut_demo_gui.prog.*` | `ZABAP_UTIL` |

## Not imported (repo docs / config)

`.abapgit.xml`, `.gitattributes`, `README.md`, `docs/*` — listed in `.abapgit.xml` `<IGNORE>`.

---

## Manual objects (created in `ZABAP_UTIL` by hand – see `06_demo_guide.md` §2)

| Object | Tcode | Notes |
|---|---|---|
| Application Log object `ZAB_V1_UT` (+ subobject `GENERAL`) | `SLG0` | assign to `ZABAP_UTIL` |
| Number-range object `ZAB_V1_UT` (interval `01`) | `SNRO` | demo only; assign to `ZABAP_UTIL` |
| `ZAB_V1_UT_ADPT` seed rows | `SM30` | client data, not transported by abapGit |
