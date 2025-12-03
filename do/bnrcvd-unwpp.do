/**************************************************************************
 DO-FILE:     bnrcvd-unwpp.do
 PROJECT:     BNR Refit Consultancy
 PURPOSE:     Auto-download of Barbados population data
              UN WPP (UN Population Division Data Portal) 
                - CSV download + import (with Bearer token)
                - Uses Python http.client (no external packages) to fetch CSV directly
                - Handles vertical-bar CSV and optional 'sep=|' first line
 
 AUTHOR:      Ian R Hambleton
 DATE:        [2025-11-04]
 VERSION:     [v1.0]

 METADATA:    --.yml (same dirpath/name as dataset)

 NOTES:       UN WPP population data (2009-2025):
                - by type (AMI, stroke)
                - by year
                - by sex 
                - by age groups
**************************************************************************/

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
   log using ${logs}\bnrcvd-2023-count, replace 

   * Initialize 
   version 19 
   clear all
   set more off
** ----- END INITIALIZE DO FILE -------------------
** ------------------------------------------------


********************************************************************************
* (A) SETUP
*       Edit data filenames
********************************************************************************
local csvfile   "${tempdata}\unwpp_brb_2020_2025.csv"
local dtafile   "${tempdata}\unwpp_brb_2020_2025.dta"
local dtafile2  "${data}\unwpp_brb_2020_2025.dta"

********************************************************************************
* (B) API PARAMETERS
********************************************************************************
* Host and path template per UN Data Portal API
local host      "population.un.org"
local indicator "46"     // Code for Total Population (NOTE: verify for each individual use case)
local location  "52"    //  Code for Barbados (UN DP location id) 
local startyr   "2010"
local endyr     "2025"

* IMPORTANT: request CSV; pagingInHeader=false is fine for full bodies
local path "/dataportalapi/api/v1/data/indicators/`indicator'/locations/`location'/start/`startyr'/end/`endyr'?pagingInHeader=false&format=csv"

* Bearer token
* Received by IanHambleton from UN WPP (3-NOV-2025) 
* process involved sending email to: population@un.org
* Short email: just request access
* Token may lapse after a time and need replacing (unsure of this - IRH)
local token "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1bmlxdWVfbmFtZSI6Imlhbi5oYW1ibGV0b25AdXdpLmVkdSIsIm5iZiI6MTc2MjE3ODYxNCwiZXhwIjoxNzkzNzE0NjE0LCJpYXQiOjE3NjIxNzg2MTQsImlzcyI6ImRvdG5ldC11c2VyLWp3dHMiLCJhdWQiOiJkYXRhLXBvcnRhbC1hcGkifQ.hh6Um1uhfazYSwnnWWKVkEqTYmYE-EsqWOtJaQZsD18"

********************************************************************************
* (C) PYTHON: FETCH CSV WITH AUTH, CLEAN 'sep=|' IF PRESENT
********************************************************************************
local http_status ""

python:
import http.client, ssl
from sfi import Macro

host     = Macro.getLocal("host")
path     = Macro.getLocal("path")
token    = Macro.getLocal("token")
csvfile  = Macro.getLocal("csvfile")

ctx  = ssl.create_default_context()
conn = http.client.HTTPSConnection(host, timeout=90, context=ctx)
headers = {"Authorization": "Bearer " + token}

conn.request("GET", path, headers=headers)
res = conn.getresponse()
status = res.status
body   = res.read()
conn.close()

Macro.setLocal("http_status", str(status))

# Write raw response
with open(csvfile, "wb") as f:
    f.write(body)

# Remove a leading 'sep=|' line if present (common in UN DP CSV)
try:
    with open(csvfile, "rb") as f:
        first = f.readline()
        rest  = f.read()
    # compare case-insensitively and strip whitespace
    if first.decode("utf-8", errors="ignore").strip().lower().startswith("sep=|"):
        with open(csvfile, "wb") as f:
            f.write(rest)
except Exception:
    # If anything odd happens, keep the file as-is; Stata can still read with rowrange()
    pass
end

display as txt "HTTP status: `http_status'"
if "`http_status'" != "200" {
    di as error "Download failed (HTTP `http_status'). Check token/parameters."
    exit 498
}

confirm file "`csvfile'"

********************************************************************************
* (D) IMPORT CSV (vertical-bar delimiter) INTO STATA
********************************************************************************
* UN DP CSV commonly uses '|' as the separator
import delimited using "`csvfile'", clear delimit("|") varnames(2) encoding(utf8) bindquote(strict) stringcols(_all)

* Optional: destring likely-numeric columns (example)
* quietly destring year value*, replace ignore(",") force

compress
save "`dtafile'", replace
save "`dtafile2'", replace
di as result "✅ Imported UN WPP CSV and saved as `dtafile'"
di as result "✅ Imported UN WPP CSV and saved as `dtafile2'"
