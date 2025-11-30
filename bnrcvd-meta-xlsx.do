/*
------------------------------------------------------------------------------
 add_meta_sheets.do  –  Build Excel file with metadata sheets

 This block uses Stata's Python integration to create a 3-sheet .xlsx file
 for the current dataset and an associated YAML metadata file.

 REQUIREMENTS
   - Stata 16+ with Python integration
   - Python packages installed in the Stata Python environment:
       pandas
       pyyaml    (imported as `yaml`)
       xlsxwriter (or another Excel writer supported by pandas)

 EXPECTED INPUTS (set before calling python:)
   local meta_xlsx   "full\path\to\aggregated-file.xlsx"
   local meta_yaml   "full\path\to\dataset-metadata.yml"

 WHAT IT DOES
   1. Reads the Stata dataset currently in memory.
      Creates Sheet 1: "data"              – the aggregated dataset.
   2. Reads the YAML file of dataset-level metadata.
      Creates Sheet 2: "dataset_meta"      – two columns: field, value.
   3. Queries Stata for variable-level metadata (similar to describe):
        - variable name
        - storage type
        - display format
        - value label name (if any)
        - variable label
      Creates Sheet 3: "variable_meta".

 NOTES
   - The Excel file at `meta_xlsx` will be OVERWRITTEN.
   - Run this after you have the final aggregated dataset in memory and
     the corresponding YAML metadata file saved.

 USAGE EXAMPLE
   * Set paths for this specific graphic/dataset
   local meta_xlsx "${graphs}/bnrcvd-count-figure1.xlsx"
   local meta_yaml "${graphs}/bnrcvd-count-figure1.yml"

   * Now run the Python block:
   python:
     // ... paste Python code block here ...
   end
------------------------------------------------------------------------------
*/

python:

from sfi import Data, Macro, ValueLabel
import pandas as pd
import yaml

# ---------------------------------------------------------------------
# 1. Get paths from Stata locals
#    (in Stata, define: global meta_xlsx "path\to\file.xlsx"
#                       global meta_yaml "path\to\file.yml")
# ---------------------------------------------------------------------
xlsx_path = Macro.getGlobal("meta_xlsx")
yaml_path = Macro.getGlobal("meta_yaml")

# ---------------------------------------------------------------------
# 2. Sheet 1: current Stata dataset -> data frame
# ---------------------------------------------------------------------
data_dict = Data.getAsDict()          # keys = varnames, values = lists
data_df = pd.DataFrame(data_dict)     # columns appear in Stata order

# ---------------------------------------------------------------------
# 3. Sheet 2: dataset-level metadata from YAML
#    Simple key/value layout: one row per top-level YAML entry
# ---------------------------------------------------------------------
with open(yaml_path, "r", encoding="utf-8") as f:
    meta_dict = yaml.safe_load(f)

meta_rows = []
for key, value in meta_dict.items():
    meta_rows.append(
        {
            "field": str(key),
            "value": "" if value is None else str(value),
        }
    )

meta_df = pd.DataFrame(meta_rows)

# ---------------------------------------------------------------------
# 4. Sheet 3: variable-level metadata (similar to Stata describe)
#    For each variable: name, storage type, format, value label name, var label
# ---------------------------------------------------------------------
var_rows = []
nvars = Data.getVarCount()

for idx in range(nvars):
    var_name = Data.getVarName(idx)
    var_rows.append(
        {
            "name": var_name,
            "storage_type": Data.getVarType(var_name),
            "display_format": Data.getVarFormat(var_name),
            "value_label": ValueLabel.getVarValueLabel(var_name),
            "variable_label": Data.getVarLabel(var_name),
        }
    )

var_df = pd.DataFrame(var_rows)

# ---------------------------------------------------------------------
# 5. Write Excel file with three sheets:
#       1: data
#       2: dataset_meta
#       3: variable_meta
#    (This overwrites any existing file at xlsx_path.)
# ---------------------------------------------------------------------
with pd.ExcelWriter(xlsx_path, engine="xlsxwriter") as writer:
    data_df.to_excel(writer, sheet_name="data", index=False)
    meta_df.to_excel(writer, sheet_name="dataset_meta", index=False)
    var_df.to_excel(writer, sheet_name="variable_meta", index=False)

end
