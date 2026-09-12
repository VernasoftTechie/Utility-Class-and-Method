"! <p class="shorttext synchronized">ZCL_AB_V1_UT: DDIC dependency discovery for deletion</p>
"! RAP-mode: ddic_dependencies is Core (read-only DDIC catalog reads). Delete methods
"! added in a later increment of this area are GATED (destructive DDIC writes) - never
"! reachable from the static facade ZCL_AB_V1_UT, called directly like ZCL_AB_V1_UT_GUI.
"! See docs/10_dependency_deletion_scope.md.
INTERFACE zif_ab_v1_ut_depdel
  PUBLIC.

  "! One node in a DDIC composition tree (what an object is built from).
  TYPES: BEGIN OF ty_node,
           object        TYPE trobjtype,   " TABL / DTEL / DOMA
           obj_name      TYPE sobj_name,
           level         TYPE i,           " 0 = the root object itself
           parent_object TYPE trobjtype,
           parent_name   TYPE sobj_name,
           via_field     TYPE fieldname,   " table field that introduced this edge (blank for the root and for a DTEL->DOMA edge)
           is_customer   TYPE abap_bool,   " Z/Y namespace check by name only - NOT a where-used/eligibility check (that is a later increment)
         END OF ty_node,
         ty_node_tab TYPE STANDARD TABLE OF ty_node WITH EMPTY KEY.

  "! Walks the DDIC composition tree of one customer DDIC object:
  "! Table/Structure (object TABL) -> its fields' data elements (DTEL) -> their domains (DOMA).
  "! A DTEL or DOMA root is also accepted (partial tree from that point down).
  "! The root must be customer namespace (Z/Y) or the call is refused outright - this
  "! area must never be able to touch a standard SAP object, even indirectly.
  "! Table Type / Search Help / View / Lock Object roots are not yet supported here
  "! (raises ZCX_AB_V1_UT) - parked as an open question in docs/10 &7 Q1.
  METHODS ddic_dependencies
    IMPORTING iv_object   TYPE trobjtype
              iv_obj_name TYPE sobj_name
    RETURNING VALUE(rt)   TYPE ty_node_tab
    RAISING   zcx_ab_v1_ut.

ENDINTERFACE.
