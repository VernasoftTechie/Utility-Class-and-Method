"! Parallel work-process worker for ZIF_AB_V1_UT_BULK~run_parallel.
"! Each work process reconstructs this instance (via CL_ABAP_PARALLEL~run_inst),
"! deserializes its JSON package, instantiates the caller's handler by name and
"! returns the handler messages as a JSON xstring.
CLASS lcl_par DEFINITION INHERITING FROM cl_abap_parallel FINAL.
  PUBLIC SECTION.
    DATA mv_handler_class TYPE seoclsname.
    DATA mv_line_name     TYPE string.
    DATA mv_context       TYPE xstring.
    METHODS do REDEFINITION.
ENDCLASS.
