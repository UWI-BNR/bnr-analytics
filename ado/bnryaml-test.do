clear all
set more off

* Use a safe temp folder; forward slashes avoid escaping headaches
do "C:\yasuki\Sync\BNR-sandbox\006-dev\do\bnrcvd-x-090-globals.do"

* ISO date (yyyy-mm-dd)
local today = string(date(c(current_date),"DMY"),"%tdCCYY-NN-DD")

* Create a tiny dataset and save it
sysuse auto, clear
save "${tempdata}/bnr-cvd-full-`today'-prep1.dta", replace

* Path to the .dta we just saved
local out "${tempdata}/bnr-cvd-full-`today'-prep1.dta"

* Generate YAML
bnryaml using "`out'", ///
    title("BNR-CVD Full Dataset (De-identified)") ///
    version("1.0") ///
    created("`today'") ///
    tier("DEID") ///
    temporal("2009-01 to 2025-11") ///
    spatial("Barbados") ///
    description("Confirmed cardiovascular events; interim prep1 example.") ///
    registry("CVD") ///
    content("FULL") ///
    creator("BNR Analytics Team, GA-CDRC") ///
    language("en") ///
    format("Stata 18") ///
    rights("Restricted – internal analytical use only") ///
    source("Hospital admissions (QEH) and national death registration") ///
    contact("bnr@cavehill.uwi.edu") /// 
    outfile("${tempdata}/bnr-cvd-full-`today'-prep1.yml")

di as txt "YAML at: " as res "`r(yml)'"
type "`r(yml)'"
