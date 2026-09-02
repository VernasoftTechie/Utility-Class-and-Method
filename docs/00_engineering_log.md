# 00 – Engineering Log (mistakes made & how to avoid them)

> **Read this before writing or changing any ABAP / abapGit object in this repo, and
> before concluding that something "should work".** Every entry below cost at least one
> pull → activate → ATC → fix cycle. Do not repeat them.

Target platform for all rules: **SAP S/4HANA 2023 on-premise, Standard ABAP (7.58)**.

---

## 0. Process

| # | Lesson |
|---|---|
| P1 | **abapGit "activate" does NOT reliably block syntax errors.** A class can show as active and still not compile. The **ATC / SLIN** run is the authoritative syntax check — every *"Prerequisites for the extended program check → syntax error in …CP"* / *"cannot be executed in this case"* entry maps **1:1** to a code fix. Converge by: pull → activate → ATC on the package → fix every syntax finding → repeat until zero. |
| P2 | A **syntax error in one method breaks the whole class load** → every call on that class dumps `SYNTAX_ERROR`, which is **uncatchable** (`TRY/CATCH` cannot help). The only fix is correct code. |
| P3 | When unsure of a modern class/method signature, prefer a **classic well-known function module** or a **hand-rolled implementation** over a guessed `CL_*` method. Guessed APIs (`xco_cp_xlsx=>…->cell(…)`, `cl_gos_api=>create_instance( is_lpor = )`) cost cycles. |
| P4 | Architecture / spec approval **before** implementation (Rulebook §8). Stage commits: foundation → interfaces → impls → facade → GUI → reports. |
| P5 | Put `##NO_TEXT` on diagnostic string literals passed as message parameters, and on demo `WRITE` output, to keep ATC's "Strings without text elements" quiet. |
| P6 | Every genuine runtime failure path must raise `ZCX_AB_V1_UT` — **never let an FM dump**. Guard by existence check first (see #33). |

---

## 1. abapGit serialization

| # | Lesson |
|---|---|
| G1 | `.prog.xml` needs a `<TPOOL>` block (`ID=R` title, `ID=I` text symbols e.g. `B01`, `ID=S` selection texts keyed by param name). Without it, selection texts are blank / show technical names. |
| G2 | `.clas.xml` — use the full `<VSEOCLASS>` form (`CLSNAME LANGU DESCRIPT STATE CLSFINAL CLSCCINCL FIXPT UNICODE WITH_UNIT_TESTS`). The stripped form is unreliable. `.intf.xml` → full `<VSEOINTERF>` (`… EXPOSURE=2 STATE=1 UNICODE=X`). |
| G3 | Message class `.msag.xml`: `<T100U_TAB>` items must contain **only** `<ARBGB> <MSGNR> <SELFDEF>`. Invented fields (`<NAME>`, `<DATUM>`) break message creation → ATC *"message 001 … does not exist"* even though the class shell activates. |
| G4 | Data element `.dtel.xml`: `SCRLEN1/2/3` must be `>=` the char length of `SCRTEXT_S/M/L` (maxes 10 / 20 / 40), `HEADLEN` 55. Too-short `SCRLEN3` → *"Long key word length N > maximum length M"* → DE won't activate → **cascades** to every table that uses it (invalid key type, nametab fails, extensibility contract fails). |
| G5 | Table `.tabl.xml`: typed fields use `<ROLLNAME>` + `<COMPTYPE>E</COMPTYPE>` and **no** `DATATYPE/LENG` alongside. Set `<EXCLASS>1</EXCLASS>` (not extensible) to silence *"Enhancement category … missing"*. |
| G6 | A `.clas.xml` with **no matching `.clas.abap`** → abapGit *"File not found … Import of object … failed"*. Create both files or neither. Same for `.prog.xml`. |
| G7 | `.abapgit.xml` `<IGNORE>` must list `/README.md`, `/docs/*`, `/.gitattributes`, `/.gitignore`, `/LICENSE`, `/CLAUDE.md`. |
| G8 | Add `.gitattributes` forcing `eol=lf` for `*.abap` / `*.xml` — abapGit expects LF. |
| G9 | Package: one flat `/src/`, `FOLDER_LOGIC=PREFIX`, `STARTING_FOLDER=/src/`. `src/package.devc.xml` supplies only the short text (`<CTEXT>`); the package **name** comes from the abapGit repo link at pull time. All objects land in that one package. |
| G10 | Local classes of a global class → abapGit files `*.clas.locals_def.abap` (CCDEF) + `*.clas.locals_imp.abap` (CCIMP), and the `.clas.xml` needs `<CLSCCINCL>X</CLSCCINCL>`. Keep the XML flags consistent with the files that actually exist: `<WITH_UNIT_TESTS>X</WITH_UNIT_TESTS>` only when `*.clas.testclasses.abap` is present; drop `CLSCCINCL` when there is no locals include. Mismatch = confusing import warnings. |

---

## 2. ABAP type system

| # | Lesson |
|---|---|
| T1 | **`RETURNING` params must be completely typed.** No generic `TYPE p` / `numeric` / `any` / `data` / bare `c`. Use `decfloat34` for numeric returns, `string` for text, a concrete DDIC/local type otherwise. |
| T2 | Method **`IMPORTING` params are by-reference by default** → the actual must be **compatible**, not just convertible. A `c` field / text symbol passed to a `TYPE string` formal **fails** (*"not type-compatible"*). Fixes: formal `TYPE csequence` or `TYPE clike` (generic, accepts by-ref); or `VALUE(iv_x) TYPE string` (by-value converts); or caller `CONV string( … )`. Backtick literals `` `…` `` are type `string`. |
| T3 | Generic-to-generic by-reference: the actual must be **at least as specific** as the formal. `clike` actual → `csequence` formal = **fails** (clike is broader). `string` actual → `csequence`/`clike` formal = OK. |
| T4 | `DEFAULT` value must be type-compatible with the param. `iv_sep TYPE string DEFAULT cl_abap_char_utilities=>newline` (a `c LENGTH 1` constant) **fails**. Make it `OPTIONAL` and default in the body. |
| T5 | `DATA(x) = COND #( … )` / `SWITCH #( … )` — `#` needs a type from context; `DATA(x) =` provides none → error. Use `COND type( … )` explicitly, or pre-declare `DATA x TYPE t.` then `x = COND #( … ).`. Assigning to a typed target/param **does** give context. |
| T6 | `VALUE type( itab[ idx ] OPTIONAL )` is **not** valid. Use `READ TABLE … INTO wa INDEX i.` (+ `CLEAR wa` on `sy-subrc <> 0`) or a helper method. |
| T7 | `CONV #( x )` where `#` would resolve to a **generic** type (target param is `csequence`/`clike`/`any`) → error. Use `CONV string( x )`. `CONV #( x )` **is** fine when the target is a concrete type (e.g. `rvari_vnam`). |
| T8 | `cl_abap_unit_assert=>assert_equals( exp = ref act = ref )` for **object references** is unreliable → `assert_true( xsdbool( ref1 = ref2 ) )`. |

---

## 3. ABAP statements

| # | Lesson |
|---|---|
| S1 | `DELETE ADJACENT DUPLICATES … COMPARING (name)` — the dynamic form needs a **char-like data object** (comma/space list of field names), **not an internal table**. (`SORT itab BY (sortorder_tab)` **does** take a table of `abap_sortorder`.) |
| S2 | `SELECT … ORDER BY (itab)` with an **empty** dynamic order table can dump. Build the statement conditionally (add `ORDER BY` only when non-empty). Empty dynamic `WHERE ( )` = no restriction (safe). |
| S3 | `IMPORTING/EXPORTING/CHANGING` params `TYPE ANY TABLE` **cannot** use index ops (`READ … INDEX`, `APPEND`, `lt[ n ]`, `INSERT … INDEX`). Use `TYPE STANDARD TABLE` or `INDEX TABLE`. `ANY TABLE` allows only `LOOP AT`, `READ … WITH KEY`, `INSERT … INTO TABLE`. |
| S4 | `APPEND` needs an index table. `INSERT … INTO TABLE` works on any table kind. |
| S5 | Offset/length on a **method-call result** is illegal: `method( )+6(2)`. Assign to a var first. `method( )-component` (structured result) **is** allowed. |
| S6 | Inline `DATA()` is not allowed in some positions (certain classic `CALL FUNCTION … IMPORTING` slots with `EXCEPTIONS`) → pre-declare the target. |
| S7 | `WRITE / |template|` — write an intermediate variable, not a string-template expression directly. |
| S8 | `AUTHORITY-CHECK … ID '…' FIELD f` — `f` must be C/N/D/T, **not `string`**. Copy to `DATA f TYPE c LENGTH n.` |
| S9 | `sy-abcde` offset access works but is obsolete → local `CONSTANTS c_abc TYPE c LENGTH 26 VALUE 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'`. |
| S10 | Short-circuit `AND`/`OR` in `IF` **is** guaranteed (7.0+): `IF ref IS BOUND AND ref->x = 1.` is safe. |
| S11 | `CALL FUNCTION … EXCEPTIONS … OTHERS = n` — SLIN wants `sy-subrc` processed afterwards; or set all exception numbers to `0` to suppress the check when the failure is deliberately ignored. |

---

## 4. Exceptions & dumps

| # | Lesson |
|---|---|
| E1 | Checked exceptions (`CX_STATIC_CHECK` incl. `ZCX_AB_V1_UT`): any method calling a raising method must `RAISING` or `CATCH` it — **activation error** otherwise. `FOR TESTING` methods **can** declare `RAISING`. |
| E2 | `cl_system_uuid=>create_uuid_*_static( )` declares `RAISING cx_uuid_error` — wrap: `TRY … CATCH cx_uuid_error ##NO_HANDLER. ENDTRY.` |
| E3 | `run()`-style dispatchers: `CATCH cx_root` catches every ABAP exception (incl. `cx_no_check`) but **not** `SYNTAX_ERROR` and **not** `MESSAGE TYPE 'X'/'A'`. |
| E4 | Classic FMs can `MESSAGE X/A` internally on bad input → uncatchable dump. **Guard with an existence check first:** `BAL_LOG_CREATE` → check `balobj`; number-range runtime → check `tnro`; dynamic table → `cl_abap_dyn_prg=>check_table_or_view_name_str`. |
| E5 | `COMMIT WORK` — framework rule is **none**. Sanctioned exceptions, documented in `01`: `MAIL~send` only when `is_mail-commit_work = abap_true`; `LOG~save` avoids the statement entirely via `BAL_DB_SAVE` on a 2nd DB connection. |

---

## 5. API specifics (things that were wrong)

| # | Lesson |
|---|---|
| A1 | **xlsx write** — `xco_cp_xlsx` worksheet `cell( )` (guessed) does not exist. Build OOXML by hand with `cl_abap_zip` + inline strings: `[Content_Types].xml`, `_rels/.rels`, `xl/workbook.xml`, `xl/_rels/workbook.xml.rels`, `xl/worksheets/sheet1.xml`; part content via `cl_abap_codepage=>convert_to( )`. |
| A2 | **xlsx read** — `cl_fdt_xl_spreadsheet` is solid: `NEW cl_fdt_xl_spreadsheet( document_name = … xdocument = … )` → `if_fdt_doc_spreadsheet~get_worksheet_names( )` / `~get_itab_from_worksheet( name )` → `REF TO data`. |
| A3 | `cl_gos_api=>create_instance( is_lpor = … )` — `is_lpor` does not exist; the GOS API varies by release/archive setup. Ship the GOS adapter **unwired** (raises "not wired"); `ZCL_AB_V1_UT_ATTACH_STUB` is the working default. |
| A4 | Weekday without `DATE_COMPUTE_DAY` (its `DAY` param type is incompatible with `p`): `( iv_date - CONV d( '19000101' ) ) MOD 7 + 1` — 1900-01-01 was a **Monday** (→ 1). |
| A5 | `cl_abap_dyn_prg=>check_table_or_view_name_str` — multiple params → **must** use `val = …` (named), not positional. |
| A6 | Domain fixed values for an enum list → FM `DD_DOMVALUES_GET` (`text = 'X'`, `TABLES dd07v_tab`), **not** `SELECT FROM DD07V`. |
| A7 | `PARAMETERS … AS LISTBOX` on a domain-typed field is **not** auto-populated → `VRM_SET_VALUES` in `AT SELECTION-SCREEN OUTPUT`. |
| A8 | `cl_abap_conv_codepage=>create_in/out` — `codepage` is `abap_encoding` (`'UTF-8'`-style), not numeric `cpcodepage`. |
| A9 | `/ui2/cl_json=>serialize/deserialize` — `pretty_name` needs a var `LIKE /ui2/cl_json=>pretty_mode-none` set via `IF`, not `COND #( … )` inline (truncation warning). |
| A10 | `cl_abap_message_digest=>calculate_hash_for_raw` — **EXPORTING** `ef_hashstring` (not RETURNING); algorithm literal `'SHA256'` (no hyphen). |
| A11 | Base64: `cl_web_http_utility=>encode_x_base64 / decode_x_base64` (not the deprecated `cl_http_utility`). |
| A12 | `xstring` literals are hex: `DATA x TYPE xstring VALUE '48656C6C6F'.`. `CONV xstring( '48656C6C6F' )` does char→byte (wrong). `|{ xstr }|` renders uppercase hex. |
| A13 | `BAL_DB_SAVE` — pass `i_2th_connection` / `i_2th_connect_commit` as **`abap_true` literals via an `IF` branch**, not `xsdbool( … )` (temp-var type mismatch with the formal). |
| A14 | `NUMBER_GET_INFO` `INTERVAL` importing param — pre-declare `DATA ls_int TYPE inriv.` (no inline `DATA()`). |
| A15 | **Parallel processing** → `cl_abap_parallel`: subclass (a **local** class in a global class pool is fine — reachable in the child work processes), `METHODS do REDEFINITION` (params `p_in TYPE xstring` / `p_out TYPE xstring`), then `run_inst( EXPORTING p_in_tab = t_in_tab p_num_tasks = i IMPORTING p_out_tab = t_out_tab )`. Out line field `-result` (xstring). `run_inst` (not `run`) so instance attributes reach the child WPs. Marshal packages as JSON via `/ui2/cl_json` + `cl_abap_codepage`. Parallel key tables need a **global/DDIC line type** (RTTI `get_relative_name( )` non-initial) so the child can `CREATE DATA … TYPE (name)`. If ATC flags the `t_in_tab`/`t_out_tab`/param names on 7.58, correct them — the pattern is right. |
| A16 | `cl_abap_tstmp=>subtract( tstmp1 tstmp2 )` → seconds as `tzntstmpl`; importing params are `TYPE timestamp`; it *raises* `cx_parameter_invalid_range` / `cx_parameter_invalid_type` (dynamic check — no compiler enforcement, but can dump). Wrap in `TRY … CATCH cx_root`. `GET TIME STAMP FIELD lv TYPE timestamp` for the endpoints. |

---

## 6. Fix history (chronological, for reference)

| Commit | What broke → fix |
|---|---|
| 16830ea | DE `ZAB_V1_UT_AREA` label > SCRLEN → SCRLEN 10/20/40; table fields → ROLLNAME+COMPTYPE E |
| a2722b3 | generic `RETURNING TYPE p` → `decfloat34` (STR/CONV); `kurst_curr`→`kurst`; `ty_mail-to`→`recipients`; `commit`→`commit_work` |
| 20a3425 | `iv_codepage` `cpcodepage`→`string`; test methods `RAISING`; offset on `last_day_of_month(…)` result |
| d017fec/6984bf0 | JSON: dropped `path_*`/`to_xml`; `pretty` string-scanner; `describe` RTTI |
| 1a2e087 | LOG `to_string` `iv_sep` DEFAULT const mismatch → OPTIONAL |
| a6c0a14 | ATC pass 1: DATE_COMPUTE_DAY; BAL_DB_SAVE xsdbool; CFG/TAB ANY→STANDARD; check_table…str named param; EXCEL `cell()`→OOXML zip; FILE AUTHORITY-CHECK char; NUM inline `DATA()`; ATTACH_GOS gutted; cx_uuid_error caught; JSON pretty_mode; msag.xml regenerated |
| 84ee212/88da13b | demo `<TPOOL>`; listbox `VRM_SET_VALUES`; `TEXT-t01` (c) vs `iv_title` (string) → `csequence` + backtick literals; LOG `balobj` guard; `WRITE` intermediate var |
| 643e6a1 | NUM `tnro` guard before number-range runtime |
| a280a3a | **`SYNTAX_ERROR` dump**: TAB `distinct` `COMPARING (it_fields)` (table) → comma-string; DB `read` rebuilt (conditional ORDER BY, explicit `lt_cols`, `CONV string`); CFG `enum_values` → `DD_DOMVALUES_GET`; EXCEL `col_letter` local const; STR `split` drop `COND #()` |
| _v1.1 s3_ | `ZCL_AB_V1_UT_BULK` + `_BULK_STORE_MEM`: packaged/parallel/restart runner. `COMMIT WORK` per package sanctioned behind `iv_commit_each` (docs/01 §2). `cl_abap_parallel` local worker (A15), `cl_abap_tstmp` wrapped (A16), locals includes (G10). |

---

## 7. Checklist before committing ABAP

- [ ] Every `RETURNING` param has a complete type (no generic `p`/`numeric`/`any`).
- [ ] No text symbol / `c` field passed to a `TYPE string` by-ref formal.
- [ ] No `COND #(` / `SWITCH #(` without a typed target or explicit `COND type(`.
- [ ] No `ANY TABLE` param with index ops; no `APPEND` on non-index tables.
- [ ] No offset access on a method-call result.
- [ ] No dynamic `COMPARING (table)`; no unconditional dynamic `ORDER BY ()`.
- [ ] Every raising call is `RAISING`-declared or `CATCH`-wrapped (incl. `cx_uuid_error`).
- [ ] Every FM that can `MESSAGE X` on bad input is preceded by an existence guard.
- [ ] `.clas.abap` ↔ `.clas.xml` (and `.prog.abap` ↔ `.prog.xml`) both present.
- [ ] Diagnostic literals carry `##NO_TEXT`.
- [ ] Ran (or asked the user to run) ATC on the package and cleared every syntax finding.
