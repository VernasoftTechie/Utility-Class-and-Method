# 03 – ZCL_AB_V1_UT Utility Framework – Technical Specification

**Version:** 1.0 · **Status:** DRAFT (design contract – no implementation until approved)

Contains the **binding signatures** for every object. Method bodies are **not** in scope for
this document (Rulebook §8). RAP-mode tag per method: **[C]** Core · **[D]** Defer · **[G]**
Gated · **[U]** GUI.

Conventions: importing params `iv_`/`is_`/`it_`/`io_`; returning `rv_`/`rs_`/`rt_`/`ro_`;
exporting `ev_`/`es_`/`et_`; changing `cv_`/`cs_`/`ct_`. All fallible methods
`RAISING zcx_ab_v1_ut`. Boolean = `abap_bool`.

---

## 1. Shared Types – `ZIF_AB_V1_UT_TYPES`

```abap
INTERFACE zif_ab_v1_ut_types PUBLIC.

  TYPES:
    "! Name/value pair (auth fields, dynamic keys, options)
    BEGIN OF ty_nv,
      name  TYPE string,
      value TYPE string,
    END OF ty_nv,
    ty_nv_tab TYPE STANDARD TABLE OF ty_nv WITH KEY name,

    ty_string_tab TYPE STANDARD TABLE OF string WITH EMPTY KEY,

    "! RAP execution phase hint for Defer-tagged methods
    ty_phase TYPE i.

  CONSTANTS:
    BEGIN OF c_phase,
      unknown      TYPE ty_phase VALUE 0,
      interaction  TYPE ty_phase VALUE 1,   " early / draft – Defer methods refuse
      early_save   TYPE ty_phase VALUE 2,
      late_save    TYPE ty_phase VALUE 3,   " save_modified / adjust_numbers – Defer ok
      after_commit TYPE ty_phase VALUE 4,
    END OF c_phase.

  TYPES:
    BEGIN OF ty_bo_key,
      objtype TYPE swo_objtyp,
      objkey  TYPE swo_typeid,
    END OF ty_bo_key.

  CONSTANTS c_msgid TYPE symsgid VALUE 'ZAB_V1_UT'.

ENDINTERFACE.
```

---

## 2. Exception – `ZCX_AB_V1_UT`

```abap
CLASS zcx_ab_v1_ut DEFINITION PUBLIC INHERITING FROM cx_static_check FINAL.
  PUBLIC SECTION.
    INTERFACES if_t100_message.
    CONSTANTS:
      BEGIN OF generic,      msgid TYPE symsgid VALUE 'ZAB_V1_UT', msgno TYPE symsgno VALUE '001',
        attr1 TYPE scx_attrname VALUE 'MV1', attr2 TYPE scx_attrname VALUE 'MV2',
        attr3 TYPE scx_attrname VALUE 'MV3', attr4 TYPE scx_attrname VALUE 'MV4', END OF generic.
    DATA: mv1 TYPE string READ-ONLY, mv2 TYPE string READ-ONLY,
          mv3 TYPE string READ-ONLY, mv4 TYPE string READ-ONLY,
          severity TYPE symsgty READ-ONLY.
    METHODS constructor
      IMPORTING textid   LIKE if_t100_message=>t100key OPTIONAL
                previous TYPE REF TO cx_root OPTIONAL
                severity TYPE symsgty DEFAULT 'E'
                mv1 TYPE string OPTIONAL mv2 TYPE string OPTIONAL
                mv3 TYPE string OPTIONAL mv4 TYPE string OPTIONAL.
ENDCLASS.
```

---

## 3. Message Class – `ZAB_V1_UT` (seed)

| No | Text | Params |
|---|---|---|
| 001 | Utility error: &1 &2 &3 &4 | generic |
| 002 | Missing authorization for object &1 | object |
| 003 | XLSX could not be parsed (&1) | reason |
| 004 | Column '&1' could not be mapped | column |
| 005 | JSON/XML (de)serialization failed: &1 | reason |
| 006 | Email could not be sent: &1 | reason |
| 007 | Attachment operation failed: &1 | reason |
| 008 | Invalid date/number format: &1 | value |
| 009 | Application Log operation failed: &1 | reason |
| 010 | User &1 is invalid or locked | user |
| 011 | No SAP GUI session — GUI utilities unavailable | – |
| 012 | No attachment adapter configured for area &1 | area |
| 013 | Operation &1 not allowed in RAP phase &2 | method, phase |
| 014 | Dynamic query rejected: &1 | reason |
| 015 | File access denied for path &1 | path |
| 016 | Number range &1: &2 | object, reason |
| 017 | Parallel task failed: &1 | reason |
| 018 | Config key &1 not found | key |
| 019 | Object &1 &2 does not exist | type, name |
| 020 | Conversion failed: &1 → &2 | from, to |

---

## 4. DDIC

### Domain `ZAB_V1_UT_AREA` – CHAR 10, fixed values
`STR CONV TAB DB FILE EXCEL JSON LOG MSG AUTH NUM MAIL ATTACH ALV SYS CFG RAP JOB`

### Data element `ZAB_V1_UT_ADAPT` – CHAR 30 (class name), label "Adapter Class"

### Table `ZAB_V1_UT_ADPT` – customizing, delivery class `C`, maintenance allowed

| Field | Key | Type | Notes |
|---|---|---|---|
| `MANDT` | X | `MANDT` | |
| `AREA` | X | `ZAB_V1_UT_AREA` | functional area |
| `ADAPTER_CLASS` | | `ZAB_V1_UT_ADAPT` | implementing class |
| `IS_ACTIVE` | | `ABAP_BOOLEAN` | exactly one active row per area |

---

## 5. Facade – `ZCL_AB_V1_UT`

```abap
CLASS zcl_ab_v1_ut DEFINITION PUBLIC FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    "--- area accessors (lazy singleton) ---
    CLASS-METHODS str    RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_str.
    CLASS-METHODS conv   RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_conv.
    CLASS-METHODS tab    RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_tab.
    CLASS-METHODS db     RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_db.
    CLASS-METHODS file   RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_file.
    CLASS-METHODS excel  RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_excel.
    CLASS-METHODS json   RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_json.
    CLASS-METHODS log    RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_log.
    CLASS-METHODS msg    RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_msg.
    CLASS-METHODS auth   RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_auth.
    CLASS-METHODS num    RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_num.
    CLASS-METHODS mail   RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_mail.
    CLASS-METHODS attach RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_attach.
    CLASS-METHODS sys    RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_sys.
    CLASS-METHODS cfg    RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_cfg.
    CLASS-METHODS rap    RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_rap.
    CLASS-METHODS job    RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_job.

    "--- RAP phase context (optional; drives Defer guard) ---
    CLASS-METHODS set_phase IMPORTING iv_phase TYPE zif_ab_v1_ut_types=>ty_phase.
    CLASS-METHODS phase     RETURNING VALUE(rv) TYPE zif_ab_v1_ut_types=>ty_phase.

    "--- test seams (ABAP Unit only) ---
    CLASS-METHODS set_str    IMPORTING io TYPE REF TO zif_ab_v1_ut_str.
    " ... one set_<area> per area ...
    CLASS-METHODS reset.
  PRIVATE SECTION.
    CLASS-DATA: go_str TYPE REF TO zif_ab_v1_ut_str,
                " ... one per area ...
                gv_phase TYPE zif_ab_v1_ut_types=>ty_phase.
ENDCLASS.
```

> `ZCL_AB_V1_UT` references only the **interfaces**. `ZCL_AB_V1_UT_GUI` is **not** referenced.

---

## 6. Area Interfaces

### 6.1 `ZIF_AB_V1_UT_STR`  *(all [C])*

```abap
INTERFACE zif_ab_v1_ut_str PUBLIC.
  TYPES ty_notation TYPE c LENGTH 2.
  CONSTANTS: BEGIN OF c_notation, us TYPE ty_notation VALUE 'US',   " 1,234.56
                                  eu TYPE ty_notation VALUE 'EU',   " 1.234,56
                                  raw TYPE ty_notation VALUE 'RW',  " 1234.56
             END OF c_notation.
  CONSTANTS: BEGIN OF c_algo, md5 TYPE string VALUE 'MD5',
                              sha1 TYPE string VALUE 'SHA1',
                              sha256 TYPE string VALUE 'SHA-256', END OF c_algo.

  METHODS to_amount   IMPORTING iv_text TYPE string iv_currency TYPE waers_curc OPTIONAL
                                iv_notation TYPE ty_notation DEFAULT c_notation-raw
                      RETURNING VALUE(rv_amount) TYPE p                RAISING zcx_ab_v1_ut. " [C]
  METHODS from_amount IMPORTING iv_amount TYPE numeric iv_currency TYPE waers_curc OPTIONAL
                                iv_notation TYPE ty_notation DEFAULT c_notation-raw
                      RETURNING VALUE(rv_text) TYPE string.                                 " [C]
  METHODS to_quantity IMPORTING iv_text TYPE string iv_unit TYPE meins OPTIONAL
                      RETURNING VALUE(rv_qty) TYPE p                    RAISING zcx_ab_v1_ut.
  METHODS from_quantity IMPORTING iv_qty TYPE numeric iv_unit TYPE meins OPTIONAL
                      RETURNING VALUE(rv_text) TYPE string.
  METHODS to_date     IMPORTING iv_text TYPE string iv_format TYPE string OPTIONAL
                      RETURNING VALUE(rv_date) TYPE d                   RAISING zcx_ab_v1_ut.
  METHODS from_date   IMPORTING iv_date TYPE d iv_format TYPE string OPTIONAL
                      RETURNING VALUE(rv_text) TYPE string.
  METHODS to_time     IMPORTING iv_text TYPE string RETURNING VALUE(rv_time) TYPE t
                      RAISING zcx_ab_v1_ut.
  METHODS from_time   IMPORTING iv_time TYPE t iv_with_seconds TYPE abap_bool DEFAULT abap_true
                      RETURNING VALUE(rv_text) TYPE string.
  METHODS alpha_in    IMPORTING iv_value TYPE clike RETURNING VALUE(rv) TYPE string.
  METHODS alpha_out   IMPORTING iv_value TYPE clike RETURNING VALUE(rv) TYPE string.
  METHODS pad         IMPORTING iv_value TYPE clike iv_len TYPE i iv_char TYPE c DEFAULT ' '
                                iv_side TYPE c DEFAULT 'L' RETURNING VALUE(rv) TYPE string.
  METHODS mask        IMPORTING iv_value TYPE clike iv_visible_prefix TYPE i DEFAULT 0
                                iv_visible_suffix TYPE i DEFAULT 4 iv_char TYPE c DEFAULT '*'
                      RETURNING VALUE(rv) TYPE string.
  METHODS split       IMPORTING iv_value TYPE string iv_sep TYPE string DEFAULT ','
                                iv_trim TYPE abap_bool DEFAULT abap_true
                      RETURNING VALUE(rt) TYPE zif_ab_v1_ut_types=>ty_string_tab.
  METHODS join        IMPORTING it_values TYPE zif_ab_v1_ut_types=>ty_string_tab
                                iv_sep TYPE string DEFAULT ',' RETURNING VALUE(rv) TYPE string.
  METHODS to_camel    IMPORTING iv_value TYPE string iv_pascal TYPE abap_bool DEFAULT abap_false
                      RETURNING VALUE(rv) TYPE string.
  METHODS to_snake    IMPORTING iv_value TYPE string RETURNING VALUE(rv) TYPE string.
  METHODS base64_encode IMPORTING iv_data TYPE xstring RETURNING VALUE(rv) TYPE string.
  METHODS base64_decode IMPORTING iv_b64 TYPE string RETURNING VALUE(rv) TYPE xstring
                      RAISING zcx_ab_v1_ut.
  METHODS to_xstring  IMPORTING iv_string TYPE string iv_codepage TYPE cpcodepage OPTIONAL
                      RETURNING VALUE(rv) TYPE xstring RAISING zcx_ab_v1_ut.
  METHODS from_xstring IMPORTING iv_xstring TYPE xstring iv_codepage TYPE cpcodepage OPTIONAL
                      RETURNING VALUE(rv) TYPE string RAISING zcx_ab_v1_ut.
  METHODS hash        IMPORTING iv_data TYPE string iv_algo TYPE string DEFAULT c_algo-sha256
                      RETURNING VALUE(rv_hex) TYPE string RAISING zcx_ab_v1_ut.
  METHODS regex_match   IMPORTING iv_value TYPE string iv_pattern TYPE string
                      RETURNING VALUE(rv) TYPE abap_bool.
  METHODS regex_replace IMPORTING iv_value TYPE string iv_pattern TYPE string iv_with TYPE string
                      RETURNING VALUE(rv) TYPE string.
  METHODS regex_groups  IMPORTING iv_value TYPE string iv_pattern TYPE string
                      RETURNING VALUE(rt) TYPE zif_ab_v1_ut_types=>ty_string_tab.
  METHODS amount_in_words IMPORTING iv_amount TYPE numeric iv_currency TYPE waers_curc
                      RETURNING VALUE(rv) TYPE string RAISING zcx_ab_v1_ut.
  METHODS is_valid    IMPORTING iv_value TYPE string iv_kind TYPE string  " EMAIL|PHONE|IBAN|PAN|GSTIN
                      RETURNING VALUE(rv) TYPE abap_bool.
ENDINTERFACE.
```

### 6.2 `ZIF_AB_V1_UT_CONV`  *(all [C])*

```abap
INTERFACE zif_ab_v1_ut_conv PUBLIC.
  METHODS add_days     IMPORTING iv_date TYPE d iv_days TYPE i RETURNING VALUE(rv) TYPE d.
  METHODS add_months   IMPORTING iv_date TYPE d iv_months TYPE i RETURNING VALUE(rv) TYPE d.
  METHODS add_years    IMPORTING iv_date TYPE d iv_years TYPE i RETURNING VALUE(rv) TYPE d.
  METHODS add_workdays IMPORTING iv_date TYPE d iv_days TYPE i iv_calendar_id TYPE scal-fcalid
                       RETURNING VALUE(rv) TYPE d RAISING zcx_ab_v1_ut.
  METHODS is_workday   IMPORTING iv_date TYPE d iv_calendar_id TYPE scal-fcalid
                       RETURNING VALUE(rv) TYPE abap_bool RAISING zcx_ab_v1_ut.
  METHODS days_between  IMPORTING iv_from TYPE d iv_to TYPE d RETURNING VALUE(rv) TYPE i.
  METHODS months_between IMPORTING iv_from TYPE d iv_to TYPE d RETURNING VALUE(rv) TYPE i.
  METHODS years_between  IMPORTING iv_from TYPE d iv_to TYPE d RETURNING VALUE(rv) TYPE i.
  METHODS age          IMPORTING iv_dob TYPE d iv_on TYPE d OPTIONAL RETURNING VALUE(rv) TYPE i.
  METHODS period_bounds IMPORTING iv_date TYPE d iv_kind TYPE string  " WEEK|MONTH|QUARTER|FYEAR
                                  iv_fiscal_variant TYPE periv OPTIONAL
                       EXPORTING ev_first TYPE d ev_last TYPE d RAISING zcx_ab_v1_ut.
  METHODS week_number  IMPORTING iv_date TYPE d RETURNING VALUE(rv) TYPE kweek.
  METHODS weekday      IMPORTING iv_date TYPE d RETURNING VALUE(rv) TYPE i.   " 1=Mon..7=Sun
  METHODS tz_to_local  IMPORTING iv_timestamp TYPE timestampl iv_tzone TYPE ttzz-tzone
                       EXPORTING ev_date TYPE d ev_time TYPE t.
  METHODS tz_from_local IMPORTING iv_date TYPE d iv_time TYPE t iv_tzone TYPE ttzz-tzone
                       RETURNING VALUE(rv) TYPE timestampl.
  METHODS ts_split     IMPORTING iv_ts TYPE timestampl EXPORTING ev_date TYPE d ev_time TYPE t
                                 ev_msec TYPE i.
  METHODS ts_merge     IMPORTING iv_date TYPE d iv_time TYPE t iv_msec TYPE i DEFAULT 0
                       RETURNING VALUE(rv) TYPE timestampl.
  METHODS convert_currency IMPORTING iv_amount TYPE numeric iv_from TYPE waers iv_to TYPE waers
                                     iv_date TYPE d DEFAULT sy-datum iv_rate_type TYPE kurst_curr DEFAULT 'M'
                       EXPORTING ev_amount TYPE p ev_rate TYPE f RAISING zcx_ab_v1_ut.
  METHODS convert_unit IMPORTING iv_qty TYPE numeric iv_from TYPE meins iv_to TYPE meins
                                 iv_material TYPE matnr OPTIONAL
                       RETURNING VALUE(rv) TYPE p RAISING zcx_ab_v1_ut.
  METHODS round        IMPORTING iv_value TYPE numeric iv_decimals TYPE i DEFAULT 2
                                 iv_mode TYPE string DEFAULT 'COMMERCIAL'
                       RETURNING VALUE(rv) TYPE p.
ENDINTERFACE.
```

### 6.3 `ZIF_AB_V1_UT_TAB`  *(all [C])*

```abap
INTERFACE zif_ab_v1_ut_tab PUBLIC.
  METHODS create_dynamic  IMPORTING it_fields TYPE zif_ab_v1_ut_types=>ty_nv_tab OPTIONAL
                                    iv_structure TYPE string OPTIONAL
                                    io_type TYPE REF TO cl_abap_datadescr OPTIONAL
                          RETURNING VALUE(rr_table) TYPE REF TO data RAISING zcx_ab_v1_ut.
  METHODS map_corresponding IMPORTING it_source TYPE ANY TABLE
                                      it_mapping TYPE zif_ab_v1_ut_types=>ty_nv_tab
                            CHANGING  ct_target TYPE STANDARD TABLE RAISING zcx_ab_v1_ut.
  METHODS aggregate       IMPORTING it_data TYPE ANY TABLE
                                    it_group_by TYPE zif_ab_v1_ut_types=>ty_string_tab
                                    it_measures TYPE zif_ab_v1_ut_types=>ty_nv_tab   " field -> SUM|AVG|MIN|MAX|COUNT
                          EXPORTING et_result TYPE STANDARD TABLE RAISING zcx_ab_v1_ut.
  METHODS sort_dynamic    CHANGING ct_data TYPE STANDARD TABLE
                          IMPORTING it_order_by TYPE zif_ab_v1_ut_types=>ty_nv_tab. " field -> ASC|DESC
  METHODS distinct        CHANGING ct_data TYPE STANDARD TABLE
                          IMPORTING it_fields TYPE zif_ab_v1_ut_types=>ty_string_tab OPTIONAL.
  METHODS diff            IMPORTING it_old TYPE ANY TABLE it_new TYPE ANY TABLE
                                    it_key_fields TYPE zif_ab_v1_ut_types=>ty_string_tab
                          EXPORTING et_insert TYPE STANDARD TABLE et_update TYPE STANDARD TABLE
                                    et_delete TYPE STANDARD TABLE RAISING zcx_ab_v1_ut.
  METHODS to_ranges       IMPORTING it_values TYPE ANY TABLE iv_sign TYPE c DEFAULT 'I'
                                    iv_option TYPE c DEFAULT 'EQ'
                          EXPORTING et_range TYPE ANY TABLE.
  METHODS chunk           IMPORTING it_data TYPE ANY TABLE iv_size TYPE i
                          RETURNING VALUE(rt_chunks) TYPE REF TO data.
  METHODS pivot           IMPORTING it_data TYPE ANY TABLE iv_row_field TYPE string
                                    iv_col_field TYPE string iv_value_field TYPE string
                          EXPORTING et_result TYPE STANDARD TABLE RAISING zcx_ab_v1_ut.
  METHODS fingerprint     IMPORTING is_data TYPE any RETURNING VALUE(rv) TYPE string.
  METHODS deep_equal      IMPORTING ir_a TYPE REF TO data ir_b TYPE REF TO data
                          RETURNING VALUE(rv) TYPE abap_bool.
ENDINTERFACE.
```

### 6.4 `ZIF_AB_V1_UT_DB`

```abap
INTERFACE zif_ab_v1_ut_db PUBLIC.
  TYPES: BEGIN OF ty_key, name TYPE string, value TYPE string, END OF ty_key,
         ty_key_tab TYPE STANDARD TABLE OF ty_key WITH KEY name.
  METHODS read         IMPORTING iv_entity TYPE string it_columns TYPE zif_ab_v1_ut_types=>ty_string_tab OPTIONAL
                                 it_where TYPE zif_ab_v1_ut_types=>ty_string_tab OPTIONAL " typed range refs only
                                 it_order_by TYPE zif_ab_v1_ut_types=>ty_string_tab OPTIONAL
                                 iv_up_to TYPE i DEFAULT 0
                       RETURNING VALUE(rr_result) TYPE REF TO data RAISING zcx_ab_v1_ut. " [G]
  METHODS exists       IMPORTING iv_entity TYPE string it_keys TYPE ty_key_tab
                       RETURNING VALUE(rv) TYPE abap_bool RAISING zcx_ab_v1_ut.            " [C]
  METHODS read_single  IMPORTING iv_entity TYPE string it_keys TYPE ty_key_tab
                       EXPORTING es_row TYPE any RAISING zcx_ab_v1_ut.                     " [C]
  METHODS describe     IMPORTING iv_entity TYPE string
                       RETURNING VALUE(rr_meta) TYPE REF TO data RAISING zcx_ab_v1_ut.    " [C]
  METHODS where_from_ranges IMPORTING it_ranges TYPE zif_ab_v1_ut_types=>ty_nv_tab
                       RETURNING VALUE(rt) TYPE zif_ab_v1_ut_types=>ty_string_tab.         " [C]
ENDINTERFACE.
```

### 6.5 `ZIF_AB_V1_UT_FILE`

```abap
INTERFACE zif_ab_v1_ut_file PUBLIC.
  CONSTANTS: BEGIN OF c_mode, text TYPE string VALUE 'TEXT', binary TYPE string VALUE 'BIN', END OF c_mode.
  METHODS resolve_logical IMPORTING iv_logical_name TYPE fileintern iv_params TYPE zif_ab_v1_ut_types=>ty_nv_tab OPTIONAL
                       RETURNING VALUE(rv_path) TYPE string RAISING zcx_ab_v1_ut.          " [C]
  METHODS mime_type    IMPORTING iv_filename TYPE string iv_content TYPE xstring OPTIONAL
                       RETURNING VALUE(rv) TYPE string.                                    " [C]
  METHODS zip          IMPORTING it_files TYPE zif_ab_v1_ut_types=>ty_nv_tab " name -> base64 content
                       RETURNING VALUE(rv_zip) TYPE xstring RAISING zcx_ab_v1_ut.          " [C]
  METHODS unzip        IMPORTING iv_zip TYPE xstring
                       RETURNING VALUE(rt_files) TYPE zif_ab_v1_ut_types=>ty_nv_tab RAISING zcx_ab_v1_ut. " [C]
  METHODS csv_parse    IMPORTING iv_content TYPE string iv_sep TYPE c DEFAULT ',' iv_header TYPE abap_bool DEFAULT abap_true
                       EXPORTING et_table TYPE STANDARD TABLE RAISING zcx_ab_v1_ut.        " [C]
  METHODS csv_build    IMPORTING it_table TYPE ANY TABLE iv_sep TYPE c DEFAULT ',' iv_header TYPE abap_bool DEFAULT abap_true
                       RETURNING VALUE(rv) TYPE string.                                    " [C]
  METHODS as_read      IMPORTING iv_logical_name TYPE fileintern OPTIONAL iv_path TYPE string OPTIONAL
                                 iv_mode TYPE string DEFAULT c_mode-binary
                       RETURNING VALUE(rv_content) TYPE xstring RAISING zcx_ab_v1_ut.      " [G]
  METHODS as_write     IMPORTING iv_logical_name TYPE fileintern OPTIONAL iv_path TYPE string OPTIONAL
                                 iv_content TYPE xstring iv_append TYPE abap_bool DEFAULT abap_false
                                 iv_mode TYPE string DEFAULT c_mode-binary RAISING zcx_ab_v1_ut. " [G]
  METHODS as_delete    IMPORTING iv_path TYPE string RAISING zcx_ab_v1_ut.                 " [G]
  METHODS as_exists    IMPORTING iv_path TYPE string RETURNING VALUE(rv) TYPE abap_bool.   " [G]
  METHODS as_list_dir  IMPORTING iv_dir TYPE string RETURNING VALUE(rt) TYPE zif_ab_v1_ut_types=>ty_string_tab
                       RAISING zcx_ab_v1_ut.                                               " [G]
ENDINTERFACE.
```
Presentation-server file methods are on `ZCL_AB_V1_UT_GUI` – see §7.

### 6.6 `ZIF_AB_V1_UT_EXCEL`  *(all [C])*

```abap
INTERFACE zif_ab_v1_ut_excel PUBLIC.
  TYPES: BEGIN OF ty_options,
           sheet_name  TYPE string,
           header_bold TYPE abap_bool,
           auto_filter TYPE abap_bool,
           freeze_row  TYPE i,
           freeze_col  TYPE i,
         END OF ty_options,
         BEGIN OF ty_error, row TYPE i column TYPE string reason TYPE string, END OF ty_error,
         ty_error_tab TYPE STANDARD TABLE OF ty_error WITH EMPTY KEY.
  METHODS read     IMPORTING iv_xlsx TYPE xstring it_mapping TYPE zif_ab_v1_ut_types=>ty_nv_tab OPTIONAL
                             iv_sheet TYPE string OPTIONAL iv_max_rows TYPE i DEFAULT 0
                   EXPORTING et_data TYPE STANDARD TABLE et_errors TYPE ty_error_tab
                             et_unmapped TYPE zif_ab_v1_ut_types=>ty_string_tab
                   RAISING zcx_ab_v1_ut.
  METHODS write    IMPORTING it_data TYPE ANY TABLE is_options TYPE ty_options OPTIONAL
                   RETURNING VALUE(rv_xlsx) TYPE xstring RAISING zcx_ab_v1_ut.
  METHODS write_multi IMPORTING it_sheets TYPE zif_ab_v1_ut_types=>ty_nv_tab " sheet -> table ref key
                   RETURNING VALUE(rv_xlsx) TYPE xstring RAISING zcx_ab_v1_ut.
  METHODS generate_template IMPORTING iv_structure TYPE string it_column_texts TYPE zif_ab_v1_ut_types=>ty_nv_tab OPTIONAL
                   RETURNING VALUE(rv_xlsx) TYPE xstring RAISING zcx_ab_v1_ut.
ENDINTERFACE.
```

### 6.7 `ZIF_AB_V1_UT_JSON`  *(all [C])*

```abap
INTERFACE zif_ab_v1_ut_json PUBLIC.
  METHODS serialize   IMPORTING iv_data TYPE any iv_pretty TYPE abap_bool DEFAULT abap_false
                                iv_camel_case TYPE abap_bool DEFAULT abap_false
                                iv_keep_initial TYPE abap_bool DEFAULT abap_true
                      RETURNING VALUE(rv_json) TYPE string RAISING zcx_ab_v1_ut.
  METHODS deserialize IMPORTING iv_json TYPE string iv_camel_case TYPE abap_bool DEFAULT abap_false
                      CHANGING  ca_data TYPE any RAISING zcx_ab_v1_ut.
  METHODS pretty      IMPORTING iv_json TYPE string RETURNING VALUE(rv) TYPE string RAISING zcx_ab_v1_ut.
  METHODS path_get    IMPORTING iv_json TYPE string iv_path TYPE string RETURNING VALUE(rv) TYPE string
                      RAISING zcx_ab_v1_ut.
  METHODS path_set    IMPORTING iv_json TYPE string iv_path TYPE string iv_value TYPE string
                      RETURNING VALUE(rv) TYPE string RAISING zcx_ab_v1_ut.
  METHODS describe    IMPORTING io_type TYPE REF TO cl_abap_typedescr OPTIONAL iv_data TYPE any OPTIONAL
                      RETURNING VALUE(rv_schema) TYPE string RAISING zcx_ab_v1_ut.
  METHODS to_xml      IMPORTING iv_json TYPE string RETURNING VALUE(rv) TYPE string RAISING zcx_ab_v1_ut.
  METHODS from_xml    IMPORTING iv_xml TYPE string RETURNING VALUE(rv) TYPE string RAISING zcx_ab_v1_ut.
  METHODS xml_serialize   IMPORTING iv_data TYPE any RETURNING VALUE(rv) TYPE xstring RAISING zcx_ab_v1_ut.
  METHODS xml_deserialize IMPORTING iv_xml TYPE xstring CHANGING ca_data TYPE any RAISING zcx_ab_v1_ut.
ENDINTERFACE.
```

### 6.8 `ZIF_AB_V1_UT_LOG`

```abap
INTERFACE zif_ab_v1_ut_log PUBLIC.
  METHODS create        IMPORTING iv_object TYPE balobj_d DEFAULT 'ZAB_V1_UT'
                                  iv_subobject TYPE balsubobj DEFAULT 'GENERAL'
                                  iv_extnumber TYPE balnrext OPTIONAL iv_in_memory TYPE abap_bool DEFAULT abap_true
                        RETURNING VALUE(ro_log) TYPE REF TO zif_ab_v1_ut_log RAISING zcx_ab_v1_ut. " [C]
  METHODS add_symsg     RETURNING VALUE(ro_log) TYPE REF TO zif_ab_v1_ut_log.                        " [C]
  METHODS add_t100      IMPORTING iv_msgid TYPE symsgid iv_msgno TYPE symsgno iv_type TYPE symsgty DEFAULT 'E'
                                  iv_v1 TYPE clike OPTIONAL iv_v2 TYPE clike OPTIONAL
                                  iv_v3 TYPE clike OPTIONAL iv_v4 TYPE clike OPTIONAL
                        RETURNING VALUE(ro_log) TYPE REF TO zif_ab_v1_ut_log.                        " [C]
  METHODS add_bapiret   IMPORTING it_return TYPE bapiret2_t RETURNING VALUE(ro_log) TYPE REF TO zif_ab_v1_ut_log. " [C]
  METHODS add_exception IMPORTING io_exception TYPE REF TO cx_root iv_type TYPE symsgty DEFAULT 'E'
                        RETURNING VALUE(ro_log) TYPE REF TO zif_ab_v1_ut_log.                        " [C]
  METHODS save          IMPORTING iv_commit TYPE abap_bool DEFAULT abap_false RAISING zcx_ab_v1_ut.  " [D]
  METHODS display       RAISING zcx_ab_v1_ut.                                                        " [U]
  METHODS handle        RETURNING VALUE(rv) TYPE balloghndl.                                         " [C]
  METHODS to_bapiret    RETURNING VALUE(rt) TYPE bapiret2_t.                                         " [C]
  METHODS to_string     IMPORTING iv_sep TYPE string DEFAULT cl_abap_char_utilities=>newline
                        RETURNING VALUE(rv) TYPE string.                                             " [C]
ENDINTERFACE.
```

### 6.9 `ZIF_AB_V1_UT_MSG`  *(all [C])*

```abap
INTERFACE zif_ab_v1_ut_msg PUBLIC.
  METHODS t100_to_text    IMPORTING iv_msgid TYPE symsgid iv_msgno TYPE symsgno
                                    iv_v1 TYPE clike OPTIONAL iv_v2 TYPE clike OPTIONAL
                                    iv_v3 TYPE clike OPTIONAL iv_v4 TYPE clike OPTIONAL
                          RETURNING VALUE(rv) TYPE string.
  METHODS t100_to_bapiret IMPORTING iv_msgid TYPE symsgid iv_msgno TYPE symsgno iv_type TYPE symsgty DEFAULT 'E'
                                    iv_v1 TYPE clike OPTIONAL iv_v2 TYPE clike OPTIONAL
                                    iv_v3 TYPE clike OPTIONAL iv_v4 TYPE clike OPTIONAL
                          RETURNING VALUE(rs) TYPE bapiret2.
  METHODS exception_to_text IMPORTING io_exception TYPE REF TO cx_root iv_long TYPE abap_bool DEFAULT abap_false
                                    iv_with_chain TYPE abap_bool DEFAULT abap_true
                          RETURNING VALUE(rv) TYPE string.
  METHODS bapiret_has_error   IMPORTING it_return TYPE bapiret2_t RETURNING VALUE(rv) TYPE abap_bool.
  METHODS bapiret_max_severity IMPORTING it_return TYPE bapiret2_t RETURNING VALUE(rv) TYPE symsgty.
  METHODS bapiret_filter      IMPORTING it_return TYPE bapiret2_t iv_types TYPE string DEFAULT 'EAX'
                          RETURNING VALUE(rt) TYPE bapiret2_t.
  METHODS raise           IMPORTING iv_msgid TYPE symsgid DEFAULT 'ZAB_V1_UT' iv_msgno TYPE symsgno
                                    iv_v1 TYPE clike OPTIONAL iv_v2 TYPE clike OPTIONAL
                                    iv_v3 TYPE clike OPTIONAL iv_v4 TYPE clike OPTIONAL
                                    io_previous TYPE REF TO cx_root OPTIONAL RAISING zcx_ab_v1_ut.
  METHODS to_reported     IMPORTING it_return TYPE bapiret2_t is_key TYPE any
                          CHANGING  reported TYPE any.
  METHODS to_failed       IMPORTING is_key TYPE any CHANGING failed TYPE any.
ENDINTERFACE.
```

### 6.10 `ZIF_AB_V1_UT_AUTH`  *(all [C])*

```abap
INTERFACE zif_ab_v1_ut_auth PUBLIC.
  METHODS check          IMPORTING iv_object TYPE xuobject it_values TYPE zif_ab_v1_ut_types=>ty_nv_tab
                                   iv_user TYPE syuname DEFAULT sy-uname
                         RETURNING VALUE(rv_authorized) TYPE abap_bool.
  METHODS check_or_raise IMPORTING iv_object TYPE xuobject it_values TYPE zif_ab_v1_ut_types=>ty_nv_tab
                                   iv_user TYPE syuname DEFAULT sy-uname RAISING zcx_ab_v1_ut.
  METHODS user_has_role  IMPORTING iv_user TYPE syuname iv_role TYPE agr_name
                                   iv_on TYPE d DEFAULT sy-datum RETURNING VALUE(rv) TYPE abap_bool.
  METHODS is_user_valid  IMPORTING iv_user TYPE syuname RETURNING VALUE(rv) TYPE abap_bool.
  METHODS permitted_values IMPORTING iv_object TYPE xuobject iv_field TYPE xufield
                                     iv_user TYPE syuname DEFAULT sy-uname
                         RETURNING VALUE(rt) TYPE zif_ab_v1_ut_types=>ty_string_tab.
ENDINTERFACE.
```

### 6.11 `ZIF_AB_V1_UT_NUM`

```abap
INTERFACE zif_ab_v1_ut_num PUBLIC.
  METHODS next        IMPORTING iv_object TYPE inri-object iv_interval TYPE inri-nrrangenr
                                iv_subobject TYPE inri-subobject OPTIONAL iv_toyear TYPE inri-toyear OPTIONAL
                      RETURNING VALUE(rv_number) TYPE string RAISING zcx_ab_v1_ut.   " [D]
  METHODS next_bulk   IMPORTING iv_object TYPE inri-object iv_interval TYPE inri-nrrangenr iv_count TYPE i
                      RETURNING VALUE(rt_numbers) TYPE zif_ab_v1_ut_types=>ty_string_tab RAISING zcx_ab_v1_ut. " [D]
  METHODS status      IMPORTING iv_object TYPE inri-object iv_interval TYPE inri-nrrangenr
                      EXPORTING ev_current TYPE string ev_percentage TYPE p RAISING zcx_ab_v1_ut. " [C]
ENDINTERFACE.
```

### 6.12 `ZIF_AB_V1_UT_MAIL`

```abap
INTERFACE zif_ab_v1_ut_mail PUBLIC.
  TYPES: BEGIN OF ty_attachment, filename TYPE string mimetype TYPE string content TYPE xstring, END OF ty_attachment,
         ty_attachment_tab TYPE STANDARD TABLE OF ty_attachment WITH EMPTY KEY,
         BEGIN OF ty_mail,
           sender            TYPE string,
           to                TYPE zif_ab_v1_ut_types=>ty_string_tab,
           cc                TYPE zif_ab_v1_ut_types=>ty_string_tab,
           bcc               TYPE zif_ab_v1_ut_types=>ty_string_tab,
           subject           TYPE string,
           body_html         TYPE string,
           body_text         TYPE string,
           attachments       TYPE ty_attachment_tab,
           importance        TYPE c LENGTH 1,       " H/M/L
           send_immediately  TYPE abap_bool,
           request_status    TYPE abap_bool,
           commit            TYPE abap_bool,
         END OF ty_mail.
  METHODS send            IMPORTING is_mail TYPE ty_mail RETURNING VALUE(rv_send_request_id) TYPE string
                          RAISING zcx_ab_v1_ut.                                     " [D]
  METHODS build_html_body IMPORTING iv_title TYPE string it_paragraphs TYPE zif_ab_v1_ut_types=>ty_string_tab OPTIONAL
                                    it_table TYPE ANY TABLE OPTIONAL
                          RETURNING VALUE(rv_html) TYPE string.                      " [C]
  METHODS raise_workflow_event IMPORTING iv_event TYPE string is_container TYPE any OPTIONAL
                          RAISING zcx_ab_v1_ut.                                      " [D]
ENDINTERFACE.
```

### 6.13 `ZIF_AB_V1_UT_ATTACH`

```abap
INTERFACE zif_ab_v1_ut_attach PUBLIC.
  TYPES: BEGIN OF ty_item, id TYPE string filename TYPE string mimetype TYPE string
                           bytes TYPE i created_by TYPE syuname created_at TYPE timestampl, END OF ty_item,
         ty_item_tab TYPE STANDARD TABLE OF ty_item WITH KEY id.
  METHODS new_guid_x16 RETURNING VALUE(rv) TYPE sysuuid_x16.                          " [C]
  METHODS new_guid_c32 RETURNING VALUE(rv) TYPE sysuuid_c32.                          " [C]
  METHODS new_guid_c22 RETURNING VALUE(rv) TYPE sysuuid_c22.                          " [C]
  METHODS list         IMPORTING is_bo_key TYPE zif_ab_v1_ut_types=>ty_bo_key
                       RETURNING VALUE(rt) TYPE ty_item_tab RAISING zcx_ab_v1_ut.     " [C]
  METHODS get          IMPORTING iv_id TYPE string RETURNING VALUE(rv_content) TYPE xstring
                       RAISING zcx_ab_v1_ut.                                          " [C]
  METHODS attach       IMPORTING is_bo_key TYPE zif_ab_v1_ut_types=>ty_bo_key iv_filename TYPE string
                                 iv_mimetype TYPE string iv_content TYPE xstring
                                 iv_auth_object TYPE xuobject DEFAULT 'S_GOS_GOS'
                       RETURNING VALUE(rv_id) TYPE string RAISING zcx_ab_v1_ut.       " [D]
  METHODS to_solix     IMPORTING iv_content TYPE xstring RETURNING VALUE(rt) TYPE solix_tab. " [C]
  METHODS from_solix   IMPORTING it_solix TYPE solix_tab iv_length TYPE i
                       RETURNING VALUE(rv) TYPE xstring.                              " [C]
ENDINTERFACE.
```

### 6.14 `ZIF_AB_V1_UT_ALV`  *(all [U] – implemented by `ZCL_AB_V1_UT_GUI`)*

```abap
INTERFACE zif_ab_v1_ut_alv PUBLIC.
  METHODS show          CHANGING ct_table TYPE STANDARD TABLE
                        IMPORTING iv_title TYPE string OPTIONAL iv_variant TYPE slis_vari OPTIONAL
                        RAISING zcx_ab_v1_ut.
  METHODS show_dynamic  IMPORTING ir_table TYPE REF TO data iv_title TYPE string OPTIONAL
                        RAISING zcx_ab_v1_ut.
  METHODS build_fieldcat IMPORTING io_table_type TYPE REF TO cl_abap_tabledescr
                        RETURNING VALUE(rt_fcat) TYPE lvc_t_fcat RAISING zcx_ab_v1_ut.
  METHODS layout_save   IMPORTING iv_report TYPE sy-repid iv_variant TYPE slis_vari is_layout TYPE any
                        RAISING zcx_ab_v1_ut.
  METHODS layout_load   IMPORTING iv_report TYPE sy-repid iv_variant TYPE slis_vari
                        EXPORTING es_layout TYPE any RAISING zcx_ab_v1_ut.
  METHODS toolbar       IMPORTING it_buttons TYPE zif_ab_v1_ut_types=>ty_nv_tab io_handler TYPE REF TO object.
ENDINTERFACE.
```

### 6.15 `ZIF_AB_V1_UT_SYS`  *(all [C])*

```abap
INTERFACE zif_ab_v1_ut_sys PUBLIC.
  TYPES: BEGIN OF ty_system,
           sysid TYPE sy-sysid client TYPE sy-mandt client_role TYPE cccategory
           install_number TYPE string is_production TYPE abap_bool host TYPE string,
         END OF ty_system.
  METHODS system_info   RETURNING VALUE(rs) TYPE ty_system.
  METHODS object_exists IMPORTING iv_type TYPE string  " TABL|STRU|CLAS|INTF|DDLS|FUNC
                                  iv_name TYPE string RETURNING VALUE(rv) TYPE abap_bool.
  METHODS timer_start   RETURNING VALUE(rv_handle) TYPE string.
  METHODS timer_stop    IMPORTING iv_handle TYPE string EXPORTING ev_seconds TYPE p ev_cpu_ms TYPE p.
  METHODS text          IMPORTING iv_kind TYPE string  " OTR|SYMBOL|MSG_LONG
                                  iv_key TYPE string RETURNING VALUE(rv) TYPE string.
ENDINTERFACE.
```

### 6.16 `ZIF_AB_V1_UT_CFG`  *(all [C])*

```abap
INTERFACE zif_ab_v1_ut_cfg PUBLIC.
  METHODS tvarv_value  IMPORTING iv_name TYPE rvari_vnam RETURNING VALUE(rv) TYPE string.
  METHODS tvarv_range  IMPORTING iv_name TYPE rvari_vnam EXPORTING et_range TYPE ANY TABLE.
  METHODS is_feature_on IMPORTING iv_feature TYPE string RETURNING VALUE(rv) TYPE abap_bool.
  METHODS read_config  IMPORTING iv_table TYPE string it_keys TYPE zif_ab_v1_ut_types=>ty_nv_tab OPTIONAL
                       EXPORTING et_rows TYPE STANDARD TABLE RAISING zcx_ab_v1_ut.
  METHODS enum_values  IMPORTING iv_domain TYPE domname
                       RETURNING VALUE(rt) TYPE zif_ab_v1_ut_types=>ty_nv_tab RAISING zcx_ab_v1_ut.
ENDINTERFACE.
```

### 6.17 `ZIF_AB_V1_UT_RAP`  *(all [C])*

```abap
INTERFACE zif_ab_v1_ut_rap PUBLIC.
  METHODS read_entity      IMPORTING iv_entity TYPE string it_keys TYPE ANY TABLE
                           EXPORTING et_result TYPE STANDARD TABLE et_messages TYPE bapiret2_t
                           RAISING zcx_ab_v1_ut.
  METHODS modify_entity    IMPORTING iv_entity TYPE string it_instances TYPE ANY TABLE
                                     iv_operation TYPE string DEFAULT 'UPDATE'
                           EXPORTING et_messages TYPE bapiret2_t RAISING zcx_ab_v1_ut.
  METHODS new_cid          RETURNING VALUE(rv) TYPE string.
  METHODS failed_add       IMPORTING is_key TYPE any iv_fail_cause TYPE i DEFAULT if_abap_behv=>cause-unspecific
                           CHANGING  failed TYPE any.
  METHODS reported_add     IMPORTING is_key TYPE any io_message TYPE REF TO if_abap_behv_message
                           CHANGING  reported TYPE any.
  METHODS auth_to_failed   IMPORTING iv_authorized TYPE abap_bool is_key TYPE any iv_object TYPE xuobject
                           CHANGING  failed TYPE any reported TYPE any.
  METHODS reported_to_bapiret IMPORTING it_reported TYPE ANY TABLE RETURNING VALUE(rt) TYPE bapiret2_t.
  METHODS corresponding_control IMPORTING is_source TYPE any is_control TYPE any CHANGING cs_target TYPE any.
ENDINTERFACE.
```

### 6.18 `ZIF_AB_V1_UT_JOB`

```abap
INTERFACE zif_ab_v1_ut_job PUBLIC.
  METHODS run_parallel  IMPORTING iv_handler_class TYPE string it_packages TYPE REF TO data
                                  iv_max_tasks TYPE i DEFAULT 5 iv_server_group TYPE rzlli_apcl OPTIONAL
                        EXPORTING et_messages TYPE bapiret2_t RAISING zcx_ab_v1_ut.   " [C]/[D]
  METHODS schedule_job  IMPORTING iv_job_name TYPE btcjob iv_report TYPE sy-repid
                                  iv_variant TYPE raldb_vari OPTIONAL iv_start_immediately TYPE abap_bool DEFAULT abap_true
                        RETURNING VALUE(rv_jobcount) TYPE btcjobcnt RAISING zcx_ab_v1_ut. " [D]
  METHODS trigger_bgpf  IMPORTING iv_key TYPE string RAISING zcx_ab_v1_ut.             " [D]
ENDINTERFACE.
```

---

## 7. GUI Class – `ZCL_AB_V1_UT_GUI`

```abap
CLASS zcl_ab_v1_ut_gui DEFINITION PUBLIC FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    INTERFACES zif_ab_v1_ut_alv.
    CLASS-METHODS alv RETURNING VALUE(ro) TYPE REF TO zif_ab_v1_ut_alv.
    "--- presentation-server files (GUI only) ---
    CLASS-METHODS pick_file     IMPORTING iv_title TYPE string OPTIONAL iv_filter TYPE string OPTIONAL
                                RETURNING VALUE(rv_path) TYPE string RAISING zcx_ab_v1_ut.
    CLASS-METHODS upload_file    IMPORTING iv_path TYPE string iv_binary TYPE abap_bool DEFAULT abap_true
                                RETURNING VALUE(rv_content) TYPE xstring RAISING zcx_ab_v1_ut.
    CLASS-METHODS download_file  IMPORTING iv_path TYPE string iv_content TYPE xstring
                                          iv_binary TYPE abap_bool DEFAULT abap_true RAISING zcx_ab_v1_ut.
    CLASS-METHODS ensure_gui     RAISING zcx_ab_v1_ut.   " raises msg 011 if no SAP GUI
  PRIVATE SECTION.
    CLASS-DATA go_alv TYPE REF TO zif_ab_v1_ut_alv.
ENDCLASS.
```

---

## 8. Reports

| Report | Purpose | ALV? |
|---|---|---|
| `ZAB_V1_UT_DEMO` | Selection screen with a radio per area; runs a representative Core/Defer call and writes results with `WRITE`/plain list. No GUI classes. | no |
| `ZAB_V1_UT_DEMO_GUI` | Demonstrates `ZIF_AB_V1_UT_ALV` (static + dynamic ALV, field catalog, variant) and `ZCL_AB_V1_UT_GUI` file pick/upload/download. | yes |

---

## 9. Exception Matrix (per area → message numbers)

| Interface | Raises (msg no.) |
|---|---|
| STR | 008, 020, 001 |
| CONV | 008, 020, 001 |
| TAB | 001, 020 |
| DB | 014, 019, 001 |
| FILE | 015, 001, 019 |
| EXCEL | 003, 004, 001 |
| JSON | 005, 001 |
| LOG | 009, 013 (save in wrong phase) |
| MSG | 001 |
| AUTH | 002, 010 |
| NUM | 016, 013 |
| MAIL | 006, 013 |
| ATTACH | 007, 012, 013 |
| ALV / GUI | 011, 001 |
| SYS | 019, 001 |
| CFG | 018, 019 |
| RAP | 001, 020 |
| JOB | 017, 013 |

---

## 10. RAP Phase Guard (Defer methods)

`ZCL_AB_V1_UT=>set_phase( )` is set by the caller (typically in a RAP saver / handler).
Every **[D]** method calls a private `assert_phase( )` that raises `ZCX_AB_V1_UT` msg 013 when
`ZCL_AB_V1_UT=>phase( ) < c_phase-late_save` **and** the phase is not `c_phase-unknown`
(unknown = classic report/job → allowed). This keeps RAP callers honest without blocking
non-RAP callers.

---

## 11. Released API Contract (C1) – after first ATC-clean run

`ZIF_AB_V1_UT_TYPES`, all 18 area interfaces, `ZCL_AB_V1_UT`, `ZCX_AB_V1_UT` →
release state **Released**, contract **C1 (Use in Cloud Development / other packages)**.
`ZCL_AB_V1_UT_GUI` and the two reports remain **not released**.
