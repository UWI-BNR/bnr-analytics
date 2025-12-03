*******************************************************
* bnrcvd-2023-redcap.do
*
* REDCap → PyCap → CSV → Stata
* - Single date range on cfadmdate
* - Selected fields only (easy to extend)
* - One CSV output file
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
   log using ${logs}\bnrcvd-2023-redcap, replace 

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
*    or set them before calling this DO.
*------------------------------------------------------
global REDCAP_START "2024-01-01"
global REDCAP_END   "2024-02-28"

display "REDCap extract: cfadmdate from ${REDCAP_START} to ${REDCAP_END}"

*------------------------------------------------------
* 2. Build output path for main CSV
*------------------------------------------------------
capture mkdir "${Pytempdata}"

local outcsv "${Pytempdata}/bnrcvd-redcap-export.csv"
display "Main REDCap CSV will be written to: `outcsv'"

*------------------------------------------------------
* 3. PyCap: export filtered records to CSV
*------------------------------------------------------
python:
from sfi import Macro
from redcap import Project
import os

# --- Get connection details and values from Stata ---
api_url    = Macro.getGlobal("REDCAP_URL")
api_token  = Macro.getGlobal("BNR_REDCAP_TOKEN")
start_date = Macro.getGlobal("REDCAP_START")
end_date   = Macro.getGlobal("REDCAP_END")
outcsv     = Macro.getLocal("outcsv")

print("Connecting to REDCap API at:", api_url)
print("Date range on cfadmdate:", start_date, "to", end_date)
print("Records CSV path:", outcsv)

# --- Connect to REDCap project ---
proj = Project(api_url, api_token)

# --- Field subset to export ------------------------------------
# NOTE:
#  - 'redcap_event_name' will be included automatically for
#    longitudinal projects; no need to list it here explicitly.
# ---------------------------------------------------------------
fields = [
    "recid",                
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

# --- Date restriction using cfadmdate and REDCap filter logic ---
filter_logic = (
    f"[cfadmdate] >= '{start_date}' "
    f"and [cfadmdate] <= '{end_date}'"
)
print("Filter logic:", filter_logic)

# --- Export records as CSV text ---
csv_text = proj.export_records(
    "csv",                # format_type as positional argument
    fields=fields,
    filter_logic=filter_logic,
)

# --- Ensure output directory exists ---
outdir = os.path.dirname(outcsv)
if outdir and not os.path.exists(outdir):
    os.makedirs(outdir, exist_ok=True)

# --- Write CSV to disk ---
with open(outcsv, "w", encoding="utf-8") as f:
    f.write(csv_text)

print("Wrote filtered records to:", outcsv)
end

*------------------------------------------------------
* 4. Import the CSV into Stata
*------------------------------------------------------
import delimited using "`outcsv'", clear stringcols(_all)

display "Imported REDCap data into Stata."
describe
list in 1/10
