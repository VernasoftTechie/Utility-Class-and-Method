"! <p class="shorttext synchronized">ZCL_AB_V1_UT: transport / where-used / code inventory</p>
"! RAP-mode: all methods are Core (read-only repository/transport metadata).
INTERFACE zif_ab_v1_ut_transport
  PUBLIC.

  TYPES:
    BEGIN OF ty_object,
      pgmid    TYPE pgmid,
      object   TYPE trobjtype,
      obj_name TYPE sobj_name,
      lock     TYPE flag,
    END OF ty_object,
    ty_object_tab TYPE STANDARD TABLE OF ty_object WITH EMPTY KEY.
  TYPES:
    BEGIN OF ty_inventory,
      object TYPE trobjtype,
      count  TYPE i,
    END OF ty_inventory,
    ty_inventory_tab TYPE STANDARD TABLE OF ty_inventory WITH EMPTY KEY.

  "! Objects in a request incl. its sub-tasks (E070 / E071).
  METHODS objects_in_request
    IMPORTING iv_trkorr TYPE trkorr
    RETURNING VALUE(rt) TYPE ty_object_tab
    RAISING   zcx_ab_v1_ut.

  "! Where-used for a repository object (WBCROSSGT / WBCROSSI).
  METHODS where_used
    IMPORTING iv_type   TYPE csequence
              iv_name   TYPE csequence
    RETURNING VALUE(rt) TYPE ty_object_tab
    RAISING   zcx_ab_v1_ut.

  "! Z/Y object inventory of a package (TADIR): counts by type + full list.
  METHODS custom_code_inventory
    IMPORTING iv_package TYPE devclass
    EXPORTING et_by_type TYPE ty_inventory_tab
              et_objects TYPE ty_object_tab
    RAISING   zcx_ab_v1_ut.

  "! Which request(s) currently lock an object (E071 lockflag).
  METHODS locking_requests
    IMPORTING iv_pgmid    TYPE pgmid
              iv_object   TYPE trobjtype
              iv_obj_name TYPE csequence
    RETURNING VALUE(rt)   TYPE zif_ab_v1_ut_types=>ty_string_tab.

ENDINTERFACE.
