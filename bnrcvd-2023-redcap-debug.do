*******************************************************
* bnrcvd-2023-redcap.do
* Minimal test: pull data from REDCap via PyCap, 
* then import into Stata
*******************************************************

version 19
clear all



*------------------------------------------------------
* 1. Point Stata to Python installation
*------------------------------------------------------
* Adjust this path to your actual python.exe
global PYEXE "C:/Users/ianha/AppData/Local/Programs/Python/Python313/python.exe"

capture python set exec `"$PYEXE"', permanently
python query    // optional: check Stata can see Python



*------------------------------------------------------
* 2. REDCap connection details
*    (we will hard-code later, to read from a
*     separate, .gitignored config file)
*------------------------------------------------------
global REDCAP_URL   "https://caribdata.org/redcap/api/"
global REDCAP_TOKEN "B971D9B37E1C94B99E7DF485B1B47BAD"

*------------------------------------------------------
* 3. Local macro path for PyCap to write CSV into
*------------------------------------------------------
* Use your new global with forward slashes.
* Example name: BNR_TMP_FWD  (change to whatever you actually used)
local outcsv "${BNR_TMP_FWD}/import.csv"
di "Writing REDCap CSV to: `outcsv'"



** DEBUG 1  -basic access
python:
from sfi import Macro
import requests

api_url   = Macro.getGlobal("REDCAP_URL")
api_token = Macro.getGlobal("REDCAP_TOKEN")

# 1) Very minimal test: ask REDCap its version
payload_version = {
    "token":   api_token,
    "content": "version",
    "format":  "json"
}
rv = requests.post(api_url, data=payload_version)
print("VERSION call – status:", rv.status_code)
print("VERSION body (first 200 chars):")
print(rv.text[:200])
print("--------------------------------------------------")

# 2) Next, try metadata – this is what PyCap is calling internally
payload_meta = {
    "token":   api_token,
    "content": "metadata",
    "format":  "json"
}
rm = requests.post(api_url, data=payload_meta)
print("METADATA call – status:", rm.status_code)
print("METADATA body (first 500 chars):")
print(rm.text[:500])
print("--------------------------------------------------")
end

** DEBUG 2 - full access at token level
python:
from sfi import Macro
import requests

api_url   = Macro.getGlobal("REDCAP_URL")
api_token = Macro.getGlobal("REDCAP_TOKEN")

# VERSION
rv = requests.post(api_url, data={
    "token":   api_token,
    "content": "version",
    "format":  "json"
})
print("VERSION status:", rv.status_code)
print("VERSION body:", rv.text[:200])
print("--------------------------------------------------")

# A SMALL RECORDS TEST
rr = requests.post(api_url, data={
    "token":   api_token,
    "content": "record",
    "format":  "json",
    "type":    "flat",
    "fields[0]": "recid",
    "fields[1]": "cfage",   # adjust to a real field if needed
    "records[0]": "1",                       # or any known record id
    "records[1]": "2",                       # or any known record id
    "records[2]": "3",                       # or any known record id
    "records[3]": "4",                       # or any known record id
    "records[4]": "5"                       # or any known record id
})
print("RECORDS status:", rr.status_code)
print("RECORDS body (first 5000 chars):")
print(rr.text[:5000])
print("--------------------------------------------------")
end







/*
** Example from 
python:
from sfi import Macro
from redcap import Project

api_url   = Macro.getGlobal("REDCAP_URL")
api_token = Macro.getGlobal("REDCAP_TOKEN")
outcsv    = Macro.getLocal("outcsv")   # <-- path from Stata

proj = Project(api_url, api_token)

# Pull all records as CSV text
csv_text = proj.export_records('csv')

# Write CSV to the path Stata built
with open(outcsv, "w", encoding="utf-8") as f:
    f.write(csv_text)

print("Wrote REDCap data to:", outcsv)
end


import delimited using "`outcsv'", clear stringcols(_all)

describe
summarize
list in 1/10
