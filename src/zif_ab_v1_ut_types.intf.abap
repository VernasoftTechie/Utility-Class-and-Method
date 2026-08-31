"! <p class="shorttext synchronized">ZCL_AB_V1_UT: shared types (no methods)</p>
"! Common type pool for the utility framework. Released with contract C1.
INTERFACE zif_ab_v1_ut_types
  PUBLIC.

  "! Generic name / value pair (auth fields, dynamic keys, options, mappings)
  TYPES: BEGIN OF ty_nv,
           name  TYPE string,
           value TYPE string,
         END OF ty_nv.
  TYPES ty_nv_tab TYPE STANDARD TABLE OF ty_nv WITH KEY name.

  TYPES ty_string_tab TYPE STANDARD TABLE OF string WITH EMPTY KEY.

  "! RAP execution-phase hint that drives the Defer guard in ZCL_AB_V1_UT.
  TYPES ty_phase TYPE i.
  CONSTANTS:
    BEGIN OF c_phase,
      "! Classic report / function module / background job - Defer methods allowed
      unknown      TYPE ty_phase VALUE 0,
      "! RAP interaction / draft phase - Defer methods refused
      interaction  TYPE ty_phase VALUE 1,
      "! RAP early save phase
      early_save    TYPE ty_phase VALUE 2,
      "! RAP save_modified / adjust_numbers - Defer methods allowed
      late_save     TYPE ty_phase VALUE 3,
      "! After COMMIT WORK - Defer methods allowed
      after_commit  TYPE ty_phase VALUE 4,
    END OF c_phase.

  "! Generic business-object key for attachment services.
  TYPES: BEGIN OF ty_bo_key,
           objtype TYPE swo_objtyp,
           objkey  TYPE swo_typeid,
         END OF ty_bo_key.

  "! Structured DDIC key component (field name + value as text).
  TYPES: BEGIN OF ty_key,
           name  TYPE string,
           value TYPE string,
         END OF ty_key.
  TYPES ty_key_tab TYPE STANDARD TABLE OF ty_key WITH KEY name.

  CONSTANTS c_msgid TYPE symsgid VALUE 'ZAB_V1_UT'.

ENDINTERFACE.
