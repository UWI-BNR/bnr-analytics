*******************************************************
* bnrcvd-2024-redcap-format.do
*
* REDCap → PyCap → CSV → Stata
* - Single date range on cfadmdate
* - Selected fields only (easy to change)
* - One DTA output file
* - All variables imported with metadata attached
* - This creates a more involved python code block
* - for a simpler python code block, see:
*
*      do/bnrcvd-2024-redcap-noformat.do
*   
*******************************************************
 

** ------------------------------------------------
** ----- INITIALIZE DO FILE -----------------------
   * Set path 
   * (EDIT bnrpath.ado 
   *  to change to your LOCAL PATH) 
   bnrpath 

   * GLOBALS. This is a relative FILEPATH
   * Do not need to change 
   do "do/bnrcvd-globals.do"

   * Log file. This is a relative FILEPATH
   * Do not need to change 
   cap log close 
   log using ${logs}\bnrcvd-2023-redcap-format, replace 

   * Initialize 
   version 19 
   clear all
   set more off
** ----- END INITIALIZE DO FILE -------------------
** ------------------------------------------------



*------------------------------------------------------
* 0. Load globals (REDCAP_URL, REDCAP_TOKEN, tempdata)
* SECURITY NOTE:
* This DO FILE expects the REDCap API token to be provided either via:
*   - an environment variable BNR_REDCAP_TOKEN, or
*   - a local (untracked) do-file that sets global BNR_REDCAP_TOKEN.
* The token MUST NOT be hard-coded in this script or committed to Git.
*------------------------------------------------------
do "${do}/bnrcvd-globals.do"
do "${do}/bnrcvd-2023-redcap-token.do"
global REDCAP_URL   "https://caribdata.org/redcap/api/"

*------------------------------------------------------
* 1. Set / override date range globals for cfadmdate
*    (YYYY-MM-DD). You can change these in this file,
*------------------------------------------------------

        global REDCAP_START "2024-01-01"
        global REDCAP_END   "2024-01-31"
        global EXPORT_YR    "2024"
        global EXPORT_MO    "01"
        global EXPORT_DT    "202401"
        global EXPORT_VS    "v01"
        /// global REDCAP_START "2024-02-01"
        /// global REDCAP_END   "2024-02-28"
        /// global EXPORT_YR    "2024"
        /// global EXPORT_MO    "02"
        /// global EXPORT_DT    "202402"
        /// global EXPORT_VS    "v01"
        /// global REDCAP_START "2024-03-01"
        /// global REDCAP_END   "2024-03-31"
        /// global EXPORT_YR    "2024"
        /// global EXPORT_MO    "03"
        /// global EXPORT_DT    "202403"
        /// global EXPORT_VS    "v01"
        /// global REDCAP_START "2024-04-01"
        /// global REDCAP_END   "2024-04-30"
        /// global EXPORT_YR    "2024"
        /// global EXPORT_MO    "04"
        /// global EXPORT_DT    "202404"
        /// global EXPORT_VS    "v01"
        /// global REDCAP_START "2024-05-01"
        /// global REDCAP_END   "2024-05-31"
        /// global EXPORT_YR    "2024"
        /// global EXPORT_MO    "05"
        /// global EXPORT_DT    "202405"
        /// global EXPORT_VS    "v01"
        /// global REDCAP_START "2024-06-01"
        /// global REDCAP_END   "2024-06-30"
        /// global EXPORT_YR    "2024"
        /// global EXPORT_MO    "06"
        /// global EXPORT_DT    "202406"
        /// global EXPORT_VS    "v01"
        /// global REDCAP_START "2024-07-01"
        /// global REDCAP_END   "2024-07-31"
        /// global EXPORT_YR    "2024"
        /// global EXPORT_MO    "07"
        /// global EXPORT_DT    "202407"
        /// global EXPORT_VS    "v01"
        /// global REDCAP_START "2024-08-01"
        /// global REDCAP_END   "2024-08-31"
        /// global EXPORT_YR    "2024"
        /// global EXPORT_MO    "08"
        /// global EXPORT_DT    "202408"
        /// global EXPORT_VS    "v01"
        /// global REDCAP_START "2024-09-01"
        /// global REDCAP_END   "2024-09-30"
        /// global EXPORT_YR    "2024"
        /// global EXPORT_MO    "09"
        /// global EXPORT_DT    "202409"
        /// global EXPORT_VS    "v01"
        /// global REDCAP_START "2024-10-01"
        /// global REDCAP_END   "2024-10-31"
        /// global EXPORT_YR    "2024"
        /// global EXPORT_MO    "10"
        /// global EXPORT_DT    "202410"
        /// global EXPORT_VS    "v01"
        /// global REDCAP_START "2024-11-01"
        /// global REDCAP_END   "2024-11-30"
        /// global EXPORT_YR    "2024"
        /// global EXPORT_MO    "11"
        /// global EXPORT_DT    "202411"
        /// global EXPORT_VS    "v01"
        /// global REDCAP_START "2024-12-01"
        /// global REDCAP_END   "2024-12-31"
        /// global EXPORT_YR    "2024"
        /// global EXPORT_MO    "12"
        /// global EXPORT_DT    "202412"
        /// global EXPORT_VS    "v01"

display "REDCap extract: cfadmdate from ${REDCAP_START} to ${REDCAP_END}"

*------------------------------------------------------
* 2. Build output path for CSV if used - 
*    Not currently used in this DO file
*    We jump straight from pandas data frame to Stata DTA 
*------------------------------------------------------
capture mkdir "${Pytempdata}"
local outcsv "${Pytempdata}/bnrcvd-redcap-export.csv"

** Using PyCap to Extract BNR event data drirectly from REDCap API
** PID=670
python:
from sfi import Macro
from redcap import Project
import os
import pandas as pd

# ================================================================
# 0. Read configuration passed in from Stata
#    (These are defined earlier in your DO file as globals/locals)
# ================================================================
api_url    = Macro.getGlobal("REDCAP_URL")
api_token  = Macro.getGlobal("BNR_REDCAP_TOKEN")
start_date = Macro.getGlobal("REDCAP_START")
end_date   = Macro.getGlobal("REDCAP_END")
outcsv     = Macro.getLocal("outcsv")   # used only to derive the .dta name

print("Connecting to REDCap API at:", api_url)
print("Date range on cfadmdate:", start_date, "to", end_date)

# ================================================================
# 1. Define which REDCap fields to export
#
# IMPORTANT:
#   - This list is the single source of truth for which variables
#     are pulled from REDCap.
#   - To add/remove variables, edit this list only.
#   - Paste your existing fields = [...] list in the marked section.
# ================================================================
# BEGIN: your existing field list
fields = [
    "recid",                
    "cstatus",
    "eligible",
    "ineligible",
    "duplicate",
    "duprec",
    "dupcheck",
    "toabs",
    "cfdoa",              
    "fname",              
    "mname",              
    "lname",              
    "sex",                
    "dob",                
    "cfage",              
    "cfage_da",           
    "natregno",           
    "recnum",             
    "cfadmdate",          
    "admtime",            
    "dlc",                
    "cfdod",              
    "parish",             
    "ward___1",           
    "ward___2",           
    "ward___3",           
    "ward___4",           
    "ward___5",           
    "htype",              
    "stype",              
    "edate",              
    "etime",              
    "pstroke",            
    "pstrokeyr",          
    "pami",               
    "pamiyr",             
    "htn",                
    "diab",               
    "sysbp",              
    "diasbp",             
    "bgmmol",             
    "ecg",                
    "ecgd",               
    "ecgt",               
    "tropres",            
    "trop1res",           
    "trop2res",           
    "assess",             
    "assess1",            
    "assess2",            
    "assess3",            
    "assess4",            
    "ct",                 
    "doct",               
    "reperf",             
    "repertype",          
    "reperfd",            
    "reperft",            
    "asp___1",            
    "asp___2",            
    "asp___3",            
    "aspdose",            
    "aspd",               
    "aspt",               
    "asptimeampm_2",      
    "vstatus",
    "dismeds___1",
    "dismeds___2",
    "dismeds___3",
    "dismeds___4",
    "dismeds___5",
    "dismeds___6",
    "dismeds___7",
    "dismeds___8",
    "dismeds___9",
    "dismeds___10",
    "aspdosedis",
    "strunit",
    "sunitadmsame",
    "astrunitd",
    "sunitdissame",
    "dstrunitd"
]
# END: your existing field list

# --- Safety check: make sure we have at least one field defined ---
if not fields:
    raise SystemExit("No REDCap fields specified in 'fields' list. Please check the DO file.")

# ================================================================
# 2. Restrict export using cfadmdate (REDCap filter logic)
#    - This filtering happens inside REDCap, not in pandas.
# ================================================================
filter_logic = (
    f"[cfadmdate] >= '{start_date}' and [cfadmdate] <= '{end_date}'"
)
print("REDCap filter logic:", filter_logic)

# ================================================================
# 3. Connect to REDCap and export:
#    - df_data: the actual record data
#    - df_meta: the metadata (field names, labels, types, choices)
# ================================================================
print("Creating REDCap Project connection...")
proj = Project(api_url, api_token)

print("Exporting records...")
df_data = proj.export_records(
    fields=fields,
    filter_logic=filter_logic,
    raw_or_label="raw",        # keep REDCap raw codes; we’ll build labels
    record_type="flat",
    format_type="df",          # ask PyCap for a pandas DataFrame
    df_kwargs={
        "index_col": None,
        # We know the data are YYYY-MM-DD, so no day-first ambiguity.
        "dayfirst": False,
    },
)

print("Exporting metadata...")
df_meta = proj.export_metadata(
    format_type="df",
    df_kwargs={"index_col": "field_name"},
)

print("Data shape:", df_data.shape)
print("Metadata shape:", df_meta.shape if df_meta is not None else "no metadata returned")

# Ensure metadata is indexed by 'field_name' (for easier lookup)
if df_meta is not None and df_meta.index.name != "field_name":
    if "field_name" in df_meta.columns:
        df_meta = df_meta.set_index("field_name")

# ================================================================
# 4. Build:
#    - var_labels: Stata variable labels
#    - value_labels: Stata value label maps
#    - convert_dates: instructions for Stata date conversion
#
#    Uses REDCap metadata so this stays in sync with the project.
#    DATE ASSUMPTION: all date fields are stored as "YYYY-MM-DD".
# ================================================================
var_labels    = {}
value_labels  = {}
convert_dates = {}

if df_meta is not None:
    # Loop through each field in the metadata table
    for field_name, row in df_meta.iterrows():
        field_type = str(row.get("field_type", "")).lower()
        valtype    = str(row.get("text_validation_type_or_show_slider_number", "")).lower()
        choices    = str(row.get("select_choices_or_calculations", "") or "")

        # --------------------------------------------------------
        # 4.1 Fields that exist directly as columns in df_data
        # --------------------------------------------------------
        if field_name in df_data.columns:

            # --- Variable label (what Stata shows as "label") ---
            label = row.get("field_label", "")
            if isinstance(label, str) and label.strip():
                # Stata variable labels are typically <= 80 chars
                var_labels[field_name] = label[:80]

            # --- DATE FIELDS (simplified for YYYY-MM-DD) ---
            # If the validation mentions "date", we treat it as a date.
            # Assumes the stored string is always "YYYY-MM-DD".
            if "date" in valtype:
                df_data[field_name] = pd.to_datetime(
                    df_data[field_name],
                    format="%Y-%m-%d",
                    errors="coerce",
                )
                convert_dates[field_name] = "td"   # Stata daily date

            # --- Numeric text / calc / slider ---
            numeric_valtypes = ("integer", "number", "float")
            if (
                field_type in ("calc", "slider")
                or any(v in valtype for v in numeric_valtypes)
            ):
                df_data[field_name] = pd.to_numeric(df_data[field_name], errors="coerce")

            # --- Single-choice categorical: radio / dropdown ---
            if field_type in ("radio", "dropdown") and choices:
                # REDCap choices look like: "1, Yes | 2, No | 3, Don't know"
                mapping = {}
                for chunk in choices.split("|"):
                    chunk = chunk.strip()
                    if not chunk:
                        continue
                    if "," in chunk:
                        code_str, lab = chunk.split(",", 1)
                    else:
                        code_str, lab = chunk, chunk
                    code_str = code_str.strip()
                    lab = lab.strip()

                    try:
                        code = float(code_str)
                    except ValueError:
                        # Non-numeric codes are not used for Stata value labels here
                        continue

                    mapping[code] = lab[:32000]  # Stata's safe upper limit

                if mapping:
                    df_data[field_name] = pd.to_numeric(df_data[field_name], errors="coerce")
                    value_labels[field_name] = mapping

            # --- Yes/No ---
            elif field_type == "yesno":
                mapping = {0.0: "No", 1.0: "Yes"}
                df_data[field_name] = pd.to_numeric(df_data[field_name], errors="coerce")
                value_labels[field_name] = mapping

            # --- True/False ---
            elif field_type == "truefalse":
                mapping = {0.0: "False", 1.0: "True"}
                df_data[field_name] = pd.to_numeric(df_data[field_name], errors="coerce")
                value_labels[field_name] = mapping

        # --------------------------------------------------------
        # 4.2 Checkbox fields: REDCap stores these as multiple
        #     columns like varname___1, varname___2, etc.
        # --------------------------------------------------------
        if field_type == "checkbox" and choices:
            # Parse the master choices string once
            for chunk in choices.split("|"):
                chunk = chunk.strip()
                if not chunk:
                    continue
                if "," in chunk:
                    code_str, lab = chunk.split(",", 1)
                else:
                    code_str, lab = chunk, chunk
                code_str = code_str.strip()
                lab = lab.strip()

                # Checkbox columns are named fieldname___code_str
                colname = f"{field_name}___{code_str}"
                if colname in df_data.columns:
                    # 0/1 indicator in the data
                    df_data[colname] = pd.to_numeric(df_data[colname], errors="coerce")

                    # Value labels: 0 = No, 1 = label from REDCap
                    value_labels[colname] = {
                        0.0: "No",
                        1.0: lab[:32000],
                    }

                    # Variable label: "Base field label: option label"
                    base_label = row.get("field_label", field_name)
                    pretty = f"{base_label}: {lab}"
                    var_labels[colname] = pretty[:80]

print("Number of variable labels:", len(var_labels))
print("Number of value label sets:", len(value_labels))
print("Number of date fields:", len(convert_dates))

# ================================================================
# 5. Write the final Stata .dta file and tell Stata where it is
# ================================================================
# Derive the .dta path from the CSV path supplied by Stata
outbase, _ = os.path.splitext(outcsv)
outdta = outbase + ".dta"
outdir = os.path.dirname(outdta)

# Create directory if needed
if outdir and not os.path.exists(outdir):
    os.makedirs(outdir, exist_ok=True)

print("Writing Stata dataset to:", outdta)
df_data.to_stata(
    outdta,
    write_index=False,
    version=119,               # Stata 15+ (incl. Stata 19)
    variable_labels=var_labels,
    convert_dates=convert_dates,
    value_labels=value_labels,
)

print("Finished writing Stata dataset.")

# Hand the path back to Stata as a local macro 'outdta'
Macro.setLocal("outdta", outdta)

end


/* ------------------------------------------------------
 4. Import the Stata dataset created in Python
    And add the several required derived variables
    
    pid            CVD Event Unique Identifier	(Stata running number)

    sd_db          The database used by the BNR team (e.g. Epi-Info, REDCap)
                   Not a key variable - and we can recreate from EVENT year.
                   WE DO NOT IMPORT IN NEW RELEASES. FYI, original 
                   Code by Jacqui to create this was from:

                   4_final clean_2022+2023.do

                   ** Create variable to identify database source
                    gen sd_db=1 if sd_eyear<2015
                    replace sd_db=2 if sd_eyear>2014 & sd_eyear<2020
                    replace sd_db=3 if recid==. & sd_db==.
                    replace sd_db=4 if recid!=. & sd_db==.
                    replace sd_db=5 if dd_deathid!="" & unique_id==""
                    tab sd_db sd_eyear ,m

                    label var sd_db "Stata Derived: Database"
                    label define sd_db_lab  1 "paper + Teleform" 2 "Epi Info 7" /// 
                                            3 "REDCap: BNRCVD_CORE" 4 "REDCap: BNR_CVD_new2023" /// 
                                            5 "REDCap: Death db" , modify
                    label values sd_db sd_db_lab


    sd_eyear       We recreate this from doe (so not needed)
                   WE DO NOT IMPORT IN NEW RELEASES.

    sd_absstatus   Allows calculation of dco status. Important.
                   HOWEVER, from Jan-2024 onwards we move to a different process
                   Whereby death records are cleaned 

  ------------------------------------------------------ */

    ** PID. Draw maximum from the cumulative dataset TO DATE
    use "${data}/releases/y2023/m12/bnr-cvd-indiv-full-202312-v01.dta", clear 
    tempvar pidm 
    egen `pidm' = max(pid) 
    local pidmax = `pidm'
    dis "LAST ROW = `pidmax'"

    ** Open New Export
    use "`outdta'", clear
    ** Generate PID
    gen pid = _n + `pidmax'
    order pid, first 

    ** Force recid to be string to fit cumulative dataset 
    tostring recid natregno recnum , replace




*-------------------------------------------------------------*
* CHECKING LEVELS OF MISSING DATA IN THIS NEW FILE 
*-------------------------------------------------------------*
* A. Define lists of numeric and string variables
*-------------------------------------------------------------*
    * Numeric variables (missing if == .)
    local numvars pid cfdoa sex dob cfage cfage_da cfadmdate dlc cfdod ///
        parish htype stype edate pstroke pstrokeyr pami pamiyr htn diab ///
        sysbp diasbp bgmmol ecg ecgd tropres trop1res trop2res assess ///
        assess1 assess2 assess3 assess4 ct doct reperf repertype reperfd ///
        aspdose aspd asptimeampm_2 vstatus aspdosedis sunitadmsame ///
        astrunitd sunitdissame dstrunitd

    * String variables (missing if == "" or == "99")
    local strvars recid redcap_event_name fname mname lname natregno ///
        recnum admtime etime ecgt reperft aspt
    *-------------------------------------------------------------*
    * B. Loop through numeric variables
    *-------------------------------------------------------------*
    di "---- Missing counts for NUMERIC variables ----"
    foreach v of local numvars {
        qui count if missing(`v')
        di "`v' : " r(N)
    }
    *-------------------------------------------------------------*
    * C. Loop through string variables
    *-------------------------------------------------------------*
    di "---- Missing counts for STRING variables ----"
    foreach v of local strvars {
        qui count if `v' == "" | `v' == "99"
        di "`v' : " r(N)
    }
    *-------------------------------------------------------------*

** CHECK these completion assumptions with JC 
    *   edate=when empty, completed using date of admission (cfadmdate)
    replace edate = cfadmdate if edate==. 
    *   cfage not always complete. When empty we fill with cfage_da 
    replace cfage = cfage_da if cfage==.

** Save the Exported dataset
    save "${data}/releases/y${EXPORT_YR}/m${EXPORT_MO}/bnr-cvd-indiv-full-${EXPORT_DT}-${EXPORT_VS}.dta", replace 

    ** --------------------------------------------------------------
    ** (4) FULL DATASET - Monthly Release - Save
    *  This file id dropped into the official release subfolder for each particular yyyy/mm
    ** --------------------------------------------------------------
    label data "BNR-CVD Monthly Release. ${EXPORT_YR}-${EXPORT_MO}. Prepared by Ian Hambleton, ${todayiso}"
    note : Input dataset = 2009-2023_identifiable_restructured_cvd.dta
    note : Prepared by Ian Hambleton, GA-CDRC, UWI
    note : Date created = ${todayiso}
    note : Input dataset created by J.Campbell, 25-Oct-2025 
    save "${data}/releases/y${EXPORT_YR}/m${EXPORT_MO}/bnr-cvd-indiv-full-${EXPORT_DT}-${EXPORT_VS}.dta", replace 

    ** Associated YAML metadata file - create and save
    local dataset "${data}/releases/y${EXPORT_YR}/m${EXPORT_MO}/bnr-cvd-indiv-full-${EXPORT_DT}-${EXPORT_VS}.dta"
    * Generate YAML
    bnryaml using "`dataset'", ///
        title("BNR-CVD Monthly Release (Identifiable)") ///
        version("1.0") ///
        created("${todayiso}") ///
        creator("Ian Hambleton") ///
        tier("FULL") ///
        temporal("Release-2024-01 ") ///
        spatial("Barbados") ///
        description("Confirmed cardiovascular events.") ///
        registry("CVD") ///
        content("INDIV") ///
        language("en") ///
        format("Stata 19") ///
        rights("Restricted - internal analytical use only") ///
        source("Hospital admissions (QEH)") ///
        contact("ian.hambleton@uwi.edu") /// 
        outfile("${data}/releases/y${EXPORT_YR}/m${EXPORT_MO}/bnr-cvd-indiv-full-${EXPORT_DT}-${EXPORT_VS}.yml")
