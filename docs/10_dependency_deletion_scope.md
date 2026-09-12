# Dependency Deletion Tool — Scoping & Phase Plan

## 1. Requirement (verbatim)
> "I need a program to delete the custom objects and all its dependencies in sap abap..
> Selection can be TR or Package also.. Like If I select the table, Show the dependencies
> first like data elements and domains and If I click on Delete in the ALV it should
> delete everything.."

**Business outcome:** a developer can pick one custom object, a whole package, or a
transport request, see every DDIC object it is built from (data elements, domains, etc.)
in a single ALV with a clear safe/unsafe classification, and delete the entire
customer-namespace family in one guided, audited action — instead of manually chasing
each dependency through SE11 one at a time.

**Primary users:** ABAP developers decommissioning/cleaning up custom Z/Y developments.

## 2. System context
- SAP: S/4HANA 2023 on-prem, Standard ABAP 7.58 (same as rest of this repo — confirm)
- ABAP language version: Standard ABAP
- Data currency: live (this tool reads and writes the live DDIC of the system it runs in)

## 3. Data sources
| Source | Fields / API needed | Verified? | Risk |
|---|---|---|---|
| `TADIR` | object list by package | ✅ already wired via `ZCL_AB_V1_UT_TRANSPORT.custom_code_inventory` | — |
| `E070`/`E071` | object list by transport request (+ sub-tasks) | ✅ already wired via `objects_in_request` | — |
| `WBCROSSGT`/`WBCROSSI` | where-used, system-wide | ✅ already wired via `where_used` | — |
| `DD03L` (table fields) | `ROLLNAME` per field → data element | new read | straightforward |
| `DD04L`/`DD04T` (data element) | `DOMNAME`/`REFTYPE` → domain or built-in type | new read | straightforward |
| `DD01L` (domain) | leaf node, no further DDIC dependency | new read | straightforward |
| `DDIF_TABL_DELETE`, `DDIF_DTEL_DELETE`, `DDIF_DOMA_DELETE`, `DDIF_STRU_DELETE`, `DDIF_TTYP_DELETE`, `DDIF_SHLP_DELETE` | actual physical delete | standard FMs — the same ones SE11 "Delete" calls internally | **destructive** |

> Rule: no field name above is invented — these are the standard catalog tables/FMs SE11
> and RADMASD0 use; still to be confirmed against the target system before Phase 1 build.

## 4. Consumers & authorisation
- Who: ABAP developers with SE11/SE80 delete authority.
- Auth object: `AUTHORITY-CHECK` on `S_DEVELOP` (`ACTVT` = delete, `OBJTYPE` per DDIC type)
  enforced in the class **before** any `DDIF_*_DELETE` call — never rely on the report's
  own execution rights alone.
- **Namespace guard (hard-block, non-negotiable):** any object whose name does not start
  `Z`/`Y`, or that TADIR marks as not-original/SAP-modified, is refused outright — never
  listed as a delete candidate, regardless of how it was reached via where-used traversal.

## 5. Non-functional
- Volume: tens of objects per run (one decommissioned custom dev), not a mass cleanup.
- **Nothing is ever deleted without an explicit human confirmation step.** Default posture
  is preview-first: the ALV shows the full tree and a safe/unsafe classification before
  any delete button is even enabled.
- Every run writes an Application Log (BAL) entry: who, when, what was deleted, in what
  order — the only audit trail for an irreversible action.
- Interactive only in Phase 1 — no background/batch execution (a human must be present).

## 6. Naming & landing zone
| | Value | From Register? |
|---|---|---|
| Repo | `VernasoftTechie/Utility-Class-and-Method` | ✅ existing (user-confirmed) |
| Package | `ZABAP_UTIL` | ✅ existing (assigned on pull) |
| Object stem | `AB_V1_UT` (repo's locked stem — **not** a new per-feature stem, per this repo's `CLAUDE.md`) | ✅ |
| New objects | `ZIF_AB_V1_UT_DEPDEL` (interface), `ZCL_AB_V1_UT_DEPDEL` (impl — composes `ZCL_AB_V1_UT_TRANSPORT` for discovery), `ZAB_V1_UT_R_DEPDEL` (executable report/ALV). Reuses existing `ZCX_AB_V1_UT` exception + `ZAB_V1_UT` message class (new message range). | ✅ |
| Branch / push mode | `main`, direct push, staged commits (matches repo pattern) | ✅ |
| Client naming override | none | ✅ |

**Tagged `Gated`** (like `DB`/`FILE`) — this area performs destructive DB writes to the
DDIC, called **directly**, never through the static facade `ZCL_AB_V1_UT`, same pattern
as `ZCL_AB_V1_UT_GUI`.

## 7. Assumptions & open questions (each with a working default)
| # | Question | Working default |
|---|---|---|
| 1 | Which object types in Phase 1? | DDIC only: Table, Structure, Table Type, Data Element, Domain, Search Help, classic View, Lock Object. Classes/programs/function groups/CDS are **Phase 3**, different (riskier) delete APIs. |
| 2 | Direction of "dependency" for a table? | Downstream composition — what the object is *built from* (fields → data elements → domains), matching your example exactly. |
| 3 | A dependency (e.g. a domain) is still used by something **outside** the selected scope — delete it anyway? | **Never.** System-wide `where_used` runs on every candidate; anything referenced outside the deletion set is shown greyed out, status `KEEP — used by <object>`, not selectable. |
| 4 | Does deletion need a transport request? | Yes — user supplies an existing modifiable workbench request up front. Every `DDIF_*_DELETE` is recorded into it, same as a manual SE11 delete. The tool never auto-creates a TR. |
| 5 | Confirmation UX? | ALV with checkboxes (pre-checked = safe-to-delete only) → "Delete Selected" → modal listing the exact objects + deletion order → explicit hard confirm → only then do the `DDIF_*_DELETE` calls fire. |
| 6 | Deletion order? | Topological, computed per run: root object(s) first, each dependency only after everything inside the deleted set that used it is already gone (Table → Data Elements → Domains). |
| 7 | Package / TR selection (multi-root)? | Expand via the existing `custom_code_inventory` / `objects_in_request` reads, then run the same per-object dependency+where-used analysis across the whole list. Non-DDIC objects in that list are listed with a "Phase 3 — not deletable yet" note, never touched. |

## 8. Out of scope / parked
| Item | Label | Re-open when |
|---|---|---|
| Non-DDIC objects (classes, interfaces, programs, function groups, CDS) | Additional scope | Phase 3 approved |
| Cross-system/cross-client deletion, or objects already transported to QA+ | Action pending for discussions | never, by default — this is a local pre-release cleanup tool |
| Background/unattended mass deletion | Additional scope | not planned — human confirm is a hard requirement |
| Auto-creating the transport request | Additional scope | only if repeatedly annoying in practice |

## 9. Phase plan
| Phase | Goal | Key objects | Done when |
|---|---|---|---|
| 1 | Single-object mode: pick one custom Table/Structure/DE/Domain/View/Table Type/Search Help/Lock Object, see correct dependency tree + KEEP/DELETE classification, delete executes in correct order, logged | `ZIF_AB_V1_UT_DEPDEL`, `ZCL_AB_V1_UT_DEPDEL`, `ZAB_V1_UT_R_DEPDEL` | Delete a real disposable custom table+DE+domain in a dev system; SE11 confirms all three gone; AppLog entry exists |
| 2 | Package + Transport Request selection modes (multi-root), reusing Phase 1's per-object engine | same classes, extended report selection screen | Selecting a test package/TR shows the combined tree for every DDIC object in it |
| 3 (parked) | Extend to non-DDIC types (classes/programs/function groups) with their own delete APIs and extra confirmation gates | new area, TBD | only if you ask for it |

## 10. Phase 1 — increment plan
| Increment | Objects | Verify |
|---|---|---|
| 1a | DDIC read layer: table/structure fields → data element → domain; view/table type/search help/lock object field sources | Demo report prints the tree for a known custom table; eyeball correctness |

> **1a build note (2026-09-12):** delivered exactly Table/Structure (`TABL`) → Data
> Element (`DTEL`) → Domain (`DOMA`) via direct `SELECT` on `DD02L`/`DD03L`/`DD04L`/`DD01L`
> (same well-known-catalog-table pattern `ZCL_AB_V1_UT_TRANSPORT` already uses for
> `E070`/`E071`/`TADIR` — A24 in the engineering log). Table Type / Search Help / View /
> Lock Object roots now raise `ZCX_AB_V1_UT` ("not supported yet") instead of guessing
> `DD40L`/`DD30L`/`DD25L` field semantics without a live system to verify against
> (engineering-log P3 rule: no guessed catalog reads). Shipped: `ZIF_AB_V1_UT_DEPDEL` +
> `ZCL_AB_V1_UT_DEPDEL`, demo `ZAB_V1_UT_DEMO_DEPDEL`, unit tests `ltc_depdel`. No delete
> capability exists yet (increments 1b–1d).
| 1b | Namespace guard + eligibility engine (KEEP vs DELETE-safe) | Unit tests: a domain shared elsewhere vs. one that isn't |
| 1c | ALV report `ZAB_V1_UT_R_DEPDEL` — selection screen, tree/list, checkboxes, confirm modal | Manual dry run — delete button wired but stubbed (no `DDIF_*_DELETE` calls yet) |
| 1d | Wire `DDIF_*_DELETE` + AppLog audit behind the confirm modal | Delete disposable test objects in dev; confirm gone in SE11 + AppLog entry written |

## 11. Applicable traps (from Bolt Playbook Appendix A)
- LOG area: guard `create()` on SLG0 object existence before use.
- `AUTHORITY-CHECK` field completeness (all fields must be supplied, per prior G-series lesson).
- Gated areas carry their own ATC exemption — `DEPDEL` is Gated (destructive DDIC writes), never reachable from the static facade.

## 12. Definition of Done (Phase 1)
- [ ] Activates green (Activate All, twice)
- [ ] ATC/SLIN clean
- [ ] Demo run against a real custom test table shows correct dependency tree + correct KEEP/DELETE classification
- [ ] Actual delete tested only against disposable test objects, confirmed gone in SE11 + logged in AppLog
- [ ] Unit tests for the eligibility engine (mocked where-used results)
- [ ] `docs/00_engineering_log.md` updated with any new traps hit
- [ ] `docs/05_version_history.md` + memory updated
- [ ] Hand-off: pull → Activate All → ATC clean → run `ZAB_V1_UT_R_DEPDEL` against a **throwaway** object first
