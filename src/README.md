# src/

ABAP objects for the `ZCL_AB_V1_UT` framework are added here **after architecture approval**
(see `../docs/01_architecture.md` §12 build order).

- abapGit layout: flat, `STARTING_FOLDER=/src/`, `FOLDER_LOGIC=PREFIX`, `MASTER_LANGUAGE=E`.
- The repository ships **no package definition** — assign your own package during the abapGit pull.

Planned objects: `ZIF_AB_V1_UT_TYPES` + 18 area interfaces, `ZCL_AB_V1_UT` (facade) + 18
headless impls + `ZCL_AB_V1_UT_GUI`, `ZCX_AB_V1_UT`, message class `ZAB_V1_UT`, DDIC
`ZAB_V1_UT_AREA` / `ZAB_V1_UT_ADAPT` / `ZAB_V1_UT_ADPT`, reports `ZAB_V1_UT_DEMO` /
`ZAB_V1_UT_DEMO_GUI`, and ABAP Unit test includes.
