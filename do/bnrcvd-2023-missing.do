/**************************************************************************
 DO-FILE:     bnrcvd-2023-missing.do
 PROJECT:     BNR Refit Consultancy
 PURPOSE:     Missing data points by year. Numbers printed for 2022 and 2023
              Sparkline  
 
 AUTHOR:      Ian R Hambleton
 DATE:        [2025-11-23]
 VERSION:     [v1.0]

 METADATA:    --

 NOTES:       BNR missign data pattern:
              For variables listed below
              ----------------------------------------------------------------------------------
              We look at missing levels for primary variables 
              ----------------------------------------------------------------------------------
              PRIMARY VARIABLES
                EVENT TYPE + SUBTYPE: etype, htype, stype 
                DATES: docf, dob, doe, doa, dodi, dod 
                DEMOGRAPHICS: sex, agey, parish  
              ----------------------------------------------------------------------------------
              SECONDARY VARIABLES              
                (Group 1)   PREVIOUS EVENTS: pstroke pstrokeyr pami pamiyr
                (Group 2)   HISTORY: htn diab 
                (Group 3)   ADMISSION: sbp dbp bgmmol ecg
                (Group 4)   TROPONIN: tropres trop1res trop2res
                (Group 5)   ASSESSMENT: assess assess1 assess2 assess3 assess4
                (Group 6)   CT: ct doct
                (Group 7)   REPERFUSION: reperf repertype dore htore mtore 
                (Group 8)   ASPIRIN: asp1 asp2 asp3 aspdose doasp htoasp mtoasp asp_ampm
                (Group 9)  DISCHARGE: dmed1 dmed2 dmed3 dmed4 dmed5 dmed6 dmed7 dmed8 dmed9 dmed10 aspdose_dis
                (Group 10)  STROKE UNIT: doasu dodisu doasu_same dodisu_same
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

    ** DATASET PREPARATION 
    do "${do}\bnrcvd-2023-prep1"

   * Log file. This is a relative FILEPATH
   * Do not need to change 
   cap log close 
   log using ${logs}\bnrcvd-2023-missing, replace 

   * Initialize 
   version 19 
   clear all
   set more off
** ----- END INITIALIZE DO FILE -------------------
** ------------------------------------------------



** --------------------------------------------------------------
** Load the interim dataset - FULL
** Dataset prepared in: bnrcvd-2023-prep1.do
** --------------------------------------------------------------
use "${tempdata}\bnr-cvd-full-${today}-prep1.dta", clear 
label var yoe "Event Year"


** --------------------------------------------------------------
** PART 1 
** --------------------------------------------------------------
** BROAD RESTRICTIONS
** LOOK AT HOSPITAL EVENTS FOR NOW - drop DCOs 
** --------------------------------------------------------------
    drop if dco==1 
    drop dco 
    drop if yoe==2009  /// This was a setup year - don't report, 


** --------------------------------------------------------------
** PART TWO 
** --------------------------------------------------------------
** MISSING LEVELS by VARIABLE
** --------------------------------------------------------------
    * Event Type 
    gen etype_miss = .
    replace etype_miss = 0 if etype<.
    replace etype_miss = 1 if etype>=.

    * ------------------------------------------------------------------
    * Stroke subtype 
    local tcount = 1  
    local table`tcount' = "Table `tcount'"
    local type`tcount' = "Stroke Subtype"
    local header`tcount' "`type`tcount'': level of missingness by year of event"
    * ------------------------------------------------------------------
    gen stype_miss = .
    replace stype_miss = 0 if etype==1
    replace stype_miss = 1 if etype==1 & stype>=.
    label var stype_miss "Stroke subtype"
    label define miss_ 0 "Available" 1 "Missing"
    label values stype_miss miss_ 

    * ------------------------------------------------------------------
    * AMI subtype 
    local tcount = `tcount' + 1  
    local table`tcount' = "Table `tcount'"
    local type`tcount' = "AMI Subtype"
    local header`tcount' "`type`tcount'': level of missingness by year of event"
    * ------------------------------------------------------------------
    gen htype_miss = .
    replace htype_miss = 0 if etype==2
    replace htype_miss = 1 if etype==2 & htype>=.
    label var htype_miss "AMI subtype"
    label values htype_miss miss_ 

    * ------------------------------------------------------------------
    * Date of event
        local tcount = `tcount' + 1  
    local table`tcount' = "Table `tcount'"
    local type`tcount' = "Date of Event"
    local header`tcount' "`type`tcount'': level of missingness by year of event"
    * ------------------------------------------------------------------
    gen doe_miss = .
    replace doe_miss = 0 if doe<.
    replace doe_miss = 1 if doe>=.

    * ------------------------------------------------------------------
    * Date of admission
    * ------------------------------------------------------------------
    local tcount = `tcount' + 1  
    local table`tcount' = "Table `tcount'"
    local type`tcount' = "Date of Admission"
    local header`tcount' "`type`tcount'': level of missingness by year of event"
    gen doa_miss = .
    replace doa_miss = 0 if doa<.
    replace doa_miss = 1 if doa>=.

    * ------------------------------------------------------------------
    * Date of dodi (potentially missing as long as vital status not deceased)
    local tcount = `tcount' + 1  
    local table`tcount' = "Table `tcount'"
    local type`tcount' = "Date of Hospital Discharge"
    local header`tcount' "`type`tcount'': level of missingness by year of event"
    * ------------------------------------------------------------------
    gen dodi_miss = .
    replace dodi_miss = 0 if sadi!=2 & dodi<.
    replace dodi_miss = 1 if sadi!=2 & dodi>=.

    * ------------------------------------------------------------------
    * Date of death 
    local tcount = `tcount' + 1  
    local table`tcount' = "Table `tcount'"
    local type`tcount' = "Date of Death"
    local header`tcount' "`type`tcount'': level of missingness by year of event"
    * ------------------------------------------------------------------
    gen dod_miss = .
    replace dod_miss = 0 if sadi==2 & dod<.
    replace dod_miss = 1 if sadi==2 & dod>=.

    ** (Group 1)   PREVIOUS EVENTS: pstroke pstrokeyr pami pamiyr

    * ------------------------------------------------------------------
    * Previous Stroke
    local tcount = `tcount' + 1  
    local table`tcount' = "Table `tcount'"
    local type`tcount' = "Previous Stroke"
    local header`tcount' "`type`tcount'': level of missingness by year of event"
    * ------------------------------------------------------------------
    gen pstroke_miss = .
    replace pstroke_miss = 0 if pstroke<. | pstroke==.a
    replace pstroke_miss = 1 if pstroke>=. & pstroke!=.a

    * ------------------------------------------------------------------
    * Previous AMI
    local tcount = `tcount' + 1  
    local table`tcount' = "Table `tcount'"
    local type`tcount' = "Previous Heart Attack"
    local header`tcount' "`type`tcount'': level of missingness by year of event"
    * ------------------------------------------------------------------
    gen pami_miss = .
    replace pami_miss = 0 if pami<. | pami==.a
    replace pami_miss = 1 if pami>=. & pami!=.a

    * ------------------------------------------------------------------
    * Year of Previous Stroke
    local tcount = `tcount' + 1  
    local table`tcount' = "Table `tcount'"
    local type`tcount' = "Year of Previous Stroke"
    local header`tcount' "`type`tcount'': level of missingness by year of event"
    * ------------------------------------------------------------------
    gen pstrokeyr_miss = .
    replace pstrokeyr_miss = 0 if pstroke <. | pstroke==.a
    replace pstrokeyr_miss = 1 if pstroke>=. & pstroke!=.a 

    * ------------------------------------------------------------------
    * Year of Previous Heart Attack
    local tcount = `tcount' + 1  
    local table`tcount' = "Table `tcount'"
    local type`tcount' = "Year of Previous Heart Attack"
    local header`tcount' "`type`tcount'': level of missingness by year of event"
    * ------------------------------------------------------------------
    gen pamiyr_miss = .
    replace pamiyr_miss = 0 if pami <. | pami==.a
    replace pamiyr_miss = 1 if pami>=. & pami!=.a

    ** (Group 2)   HISTORY: htn diab 

    * ------------------------------------------------------------------
    * History of Hypertension
    local tcount = `tcount' + 1  
    local table`tcount' = "Table `tcount'"
    local type`tcount' = "History of Hypertension"
    local header`tcount' "`type`tcount'': level of missingness by year of event"
    * ------------------------------------------------------------------
    gen htn_miss = .
    replace htn_miss = 0 if htn <. | htn==.a
    replace htn_miss = 1 if htn>=. & htn!=.a

    * ------------------------------------------------------------------
    * History of Diabetes
    local tcount = `tcount' + 1  
    local table`tcount' = "Table `tcount'"
    local type`tcount' = "History of Diabetes"
    local header`tcount' "`type`tcount'': level of missingness by year of event"
    * ------------------------------------------------------------------
    gen diab_miss = .
    replace diab_miss = 0 if diab <. | diab==.a
    replace diab_miss = 1 if diab>=. & diab!=.a

** (Group 3)   ADMISSION: sbp dbp bgmmol ecg (Won't tabulate associated dates: doecg htecg mtecg)
    * ------------------------------------------------------------------
    * DBP on Admission
    local tcount = `tcount' + 1  
    local table`tcount' = "Table `tcount'"
    local type`tcount' = "DBP on Admission"
    local header`tcount' "`type`tcount'': level of missingness by year of event"
    * ------------------------------------------------------------------
    gen dbp_miss = .
    replace dbp_miss = 0 if dbp <. | dbp==.a
    replace dbp_miss = 1 if dbp>=. & dbp!=.a
    * ------------------------------------------------------------------
    * SBP on Admission
    local tcount = `tcount' + 1  
    local table`tcount' = "Table `tcount'"
    local type`tcount' = "SBP on Admission"
    local header`tcount' "`type`tcount'': level of missingness by year of event"
    * ------------------------------------------------------------------
    gen sbp_miss = .
    replace sbp_miss = 0 if sbp <. | sbp==.a
    replace sbp_miss = 1 if sbp>=. & sbp!=.a
    * ------------------------------------------------------------------
    * Blood Glucose on Admission
    local tcount = `tcount' + 1  
    local table`tcount' = "Table `tcount'"
    local type`tcount' = "Blood Glucose Measurement on Admission"
    local header`tcount' "`type`tcount'': level of missingness by year of event"
    * ------------------------------------------------------------------
    gen bgmmol_miss = .
    replace bgmmol_miss = 0 if bgmmol <. | bgmmol==.a
    replace bgmmol_miss = 1 if bgmmol>=. & bgmmol!=.a
    * ------------------------------------------------------------------
    * ECG on Admission
    local tcount = `tcount' + 1  
    local table`tcount' = "Table `tcount'"
    local type`tcount' = "ECG on Admission"
    local header`tcount' "`type`tcount'': level of missingness by year of event"
    * ------------------------------------------------------------------
    gen ecg_miss = .
    replace ecg_miss = 0 if ecg <. | ecg==.a
    replace ecg_miss = 1 if ecg>=. & ecg!=.a

** (Group 4)   TROPONIN: tropres (We don't tabulate f/u measurements: trop1res trop2res)
    * ------------------------------------------------------------------
    * ECG on Admission
    local tcount = `tcount' + 1  
    local table`tcount' = "Table `tcount'"
    local type`tcount' = "Troponin tests completed"
    local header`tcount' "`type`tcount'': level of missingness by year of event"
    * ------------------------------------------------------------------
    gen tropres_miss = .
    replace tropres_miss = 0 if etype==2 & tropres<.
    replace tropres_miss = 1 if etype==2 & tropres>=.

** (Group 5)   ASSESSMENT: assess assess1 assess2 assess3 assess4
    * ------------------------------------------------------------------
    * Assessment by any therapist (strokes only)
    local tcount = `tcount' + 1  
    local table`tcount' = "Table `tcount'"
    local type`tcount' = "Assessment by any Therapist"
    local header`tcount' "`type`tcount'': level of missingness by year of event"
    * ------------------------------------------------------------------
    gen assess_miss = .
    replace assess_miss = 0 if etype==1 & (assess <. | assess==.a)
    replace assess_miss = 1 if etype==1 & assess>=. & assess!=.a
    * ------------------------------------------------------------------
    * Assessment by Occupational Therapist (strokes only)
    local tcount = `tcount' + 1  
    local table`tcount' = "Table `tcount'"
    local type`tcount' = "Assessment by Occupational Therapist"
    local header`tcount' "`type`tcount'': level of missingness by year of event"
    * ------------------------------------------------------------------
    gen assess1_miss = .
    replace assess1_miss = 0 if etype==1 & assess1 <. | assess1==.a
    replace assess1_miss = 1 if etype==1 & assess1>=. & assess1!=.a
    * ------------------------------------------------------------------
    * Assessment by Physiotherapist (strokes only)
    local tcount = `tcount' + 1  
    local table`tcount' = "Table `tcount'"
    local type`tcount' = "Assessment by Physiotherapist"
    local header`tcount' "`type`tcount'': level of missingness by year of event"
    * ------------------------------------------------------------------
    gen assess2_miss = .
    replace assess2_miss = 0 if etype==1 & (assess2 <. | assess2==.a)
    replace assess2_miss = 1 if etype==1 & assess2>=. & assess2!=.a
    * ------------------------------------------------------------------
    * Assessment by Speech Therapist (strokes only)
    local tcount = `tcount' + 1  
    local table`tcount' = "Table `tcount'"
    local type`tcount' = "Assessment by Speech Therapist"
    local header`tcount' "`type`tcount'': level of missingness by year of event"
    * ------------------------------------------------------------------
    gen assess3_miss = .
    replace assess3_miss = 0 if etype==1 & (assess3 <. | assess3==.a)
    replace assess3_miss = 1 if etype==1 & assess3>=. & assess3!=.a
    * ------------------------------------------------------------------
    * Swallowing assessment by Speech Therapist (strokes only)
    local tcount = `tcount' + 1  
    local table`tcount' = "Table `tcount'"
    local type`tcount' = "Swallowing assessment by Speech Therapist"
    local header`tcount' "`type`tcount'': level of missingness by year of event"
    * ------------------------------------------------------------------
    gen assess4_miss = .
    replace assess4_miss = 0 if etype==1 & (assess4 <. | assess4==.a)
    replace assess4_miss = 1 if etype==1 & assess4>=. & assess4!=.a

** (Group 6)   CT: ct --> (not tabulate: doct)
    * ------------------------------------------------------------------
    * CT scan
    local tcount = `tcount' + 1  
    local table`tcount' = "Table `tcount'"
    local type`tcount' = "CT scan + Report Available"
    local header`tcount' "`type`tcount'': level of missingness by year of event"
    * ------------------------------------------------------------------
    gen ct_miss = .
    replace ct_miss = 0 if etype==1 & (ct <. | ct==.a)
    replace ct_miss = 1 if etype==1 & ct>=. & ct!=.a

** (Group 7)   REPERFUSION: reperf --> (not tabulated: repertype dore htore mtore) 
** (Group 6)   CT: ct --> (not tabulate: doct)
    * ------------------------------------------------------------------
    * Reperfusion
    local tcount = `tcount' + 1  
    local table`tcount' = "Table `tcount'"
    local type`tcount' = "Reperfusion"
    local header`tcount' "`type`tcount'': level of missingness by year of event"
    * ------------------------------------------------------------------
    gen reperf_miss = .
    replace reperf_miss = 0 if reperf <. | reperf==.a
    replace reperf_miss = 1 if reperf>=. & reperf!=.a

** (Group 8)   ASPIRIN: asp1 asp2 --> (asp3 not tabulated: aspdose doasp htoasp mtoasp asp_ampm)
    * ------------------------------------------------------------------
    * Aspirin (acute)
    local tcount = `tcount' + 1  
    local table`tcount' = "Table `tcount'"
    local type`tcount' = "Aspirin use (acute)"
    local header`tcount' "`type`tcount'': level of missingness by year of event"
    * ------------------------------------------------------------------
    gen asp1_miss = .
    replace asp1_miss = 0 if asp3!=1 & (asp1 <. | asp1==.a)
    replace asp1_miss = 1 if asp3!=1 & asp1>=. & asp1!=.a
    * ------------------------------------------------------------------
    * Aspirin (chronic)
    local tcount = `tcount' + 1  
    local table`tcount' = "Table `tcount'"
    local type`tcount' = "Aspirin use (chronic)"
    local header`tcount' "`type`tcount'': level of missingness by year of event"
    * ------------------------------------------------------------------
    gen asp2_miss = .
    replace asp2_miss = 0 if asp3!=1 & (asp2 <. | asp2==.a)
    replace asp2_miss = 1 if asp3!=1 & asp2>=. & asp2!=.a

** (Group 9)   DISCHARGE: dmed1 dmed2 dmed3 dmed4 dmed5 dmed6 --> (not tabulated: dmed7 dmed8 dmed9 dmed10 aspdose_dis)
    * ------------------------------------------------------------------
    * Medication at Discharge (aspirin)
    local tcount = `tcount' + 1  
    local table`tcount' = "Table `tcount'"
    local type`tcount' = "Discharge Meds (aspirin)"
    local header`tcount' "`type`tcount'': level of missingness by year of event"

    * ------------------------------------------------------------------
    gen dmed1_miss = .
    replace dmed1_miss = 0 if dmed1 <. | dmed1==.a
    replace dmed1_miss = 1 if dmed1>=. & dmed1!=.a
    * ------------------------------------------------------------------
    * Medication at Discharge (warfarin)
    local tcount = `tcount' + 1  
    local table`tcount' = "Table `tcount'"
    local type`tcount' = "Discharge Meds (warfarin)"
    local header`tcount' "`type`tcount'': level of missingness by year of event"
    * ------------------------------------------------------------------
    gen dmed2_miss = .
    replace dmed2_miss = 0 if dmed2 <. | dmed2==.a
    replace dmed2_miss = 1 if dmed2>=. & dmed2!=.a

    * ------------------------------------------------------------------
    * Medication at Discharge (heparin)
    local tcount = `tcount' + 1  
    local table`tcount' = "Table `tcount'"
    local type`tcount' = "Discharge Meds (heparin)"
    local header`tcount' "`type`tcount'': level of missingness by year of event"
    * ------------------------------------------------------------------
    gen dmed3_miss = .
    replace dmed3_miss = 0 if dmed3 <. | dmed3==.a
    replace dmed3_miss = 1 if dmed3>=. & dmed3!=.a

    * ------------------------------------------------------------------
    * Medication at Discharge (antiplatelet)
    local tcount = `tcount' + 1  
    local table`tcount' = "Table `tcount'"
    local type`tcount' = "Discharge Meds (antiplatelet)"
    local header`tcount' "`type`tcount'': level of missingness by year of event"
    * ------------------------------------------------------------------
    gen dmed4_miss = .
    replace dmed4_miss = 0 if dmed4 <. | dmed4==.a
    replace dmed4_miss = 1 if dmed4>=. & dmed4!=.a

    * ------------------------------------------------------------------
    * Medication at Discharge (Statin)
    local tcount = `tcount' + 1  
    local table`tcount' = "Table `tcount'"
    local type`tcount' = "Discharge Meds (statin)"
    local header`tcount' "`type`tcount'': level of missingness by year of event"
    * ------------------------------------------------------------------
    gen dmed5_miss = .
    replace dmed5_miss = 0 if dmed5 <. | dmed5==.a
    replace dmed5_miss = 1 if dmed5>=. & dmed5!=.a

    * ------------------------------------------------------------------
    * Medication at Discharge (ACE inhibitor)
    local tcount = `tcount' + 1  
    local table`tcount' = "Table `tcount'"
    local type`tcount' = "Discharge Meds (ACE inhibitor)"
    local header`tcount' "`type`tcount'': level of missingness by year of event"
    * ------------------------------------------------------------------
    gen dmed6_miss = .
    replace dmed6_miss = 0 if dmed6 <. | dmed6==.a
    replace dmed6_miss = 1 if dmed6>=. & dmed6!=.a

** (Group 10)  STROKE UNIT: sunit --> (not tabulated: doasu dodisu doasu_same dodisu_same)
    * ------------------------------------------------------------------
    * Date of admission to Stroke Unit
    * ------------------------------------------------------------------
    local tcount = `tcount' + 1  
    local table`tcount' = "Table `tcount'"
    local type`tcount' = "Admission to Stroke Unit"
    local header`tcount' "`type`tcount'': level of missingness by year of event"
    gen sunit_miss = .
    replace sunit_miss = 0 if etype==1 & (sunit <. | sunit==.a)
    replace sunit_miss = 1 if etype==1 & sunit>=. & sunit!=.a 





** --------------------------------------------------------------
** PART THREE 
** --------------------------------------------------------------
** CREATING EXCEL INDEX PAGE and INDIVIDUAL NUMBERED TABLES
** Table creation in repeatable DO file: bnrcvd-2023-missing-collect.do
** --------------------------------------------------------------

** Final Excel file Formatting. Creation of Index Page 
/// local num    = "1 2 3 4 5 6 7 8 9 10"
/// local letter = "A B C D E F G H I J"
** --------------------------------------------------- 
putexcel set "${tables}/bnrcvd-2023-missing.xlsx" , replace sheet("Index", replace)
putexcel A1 = "BNR CVD Tables: Levels of Missing Data", bold font("Calibri", 14)
forvalues i = 1/`tcount' {
    /// local n  : word `i' of `num'
    /// local l  : word `i' of `letter'
    local ip = `i' + 1 
    /// di "Number1 = `i' Number2 = `ip'  Letter = `l' Letter2 = `lp'"
    putexcel B`ip' = "`table`i''", bold font("Calibri", 11)
    putexcel C`ip' = "`header`i''",  font("Calibri", 11)
    putexcel D`ip' = hyperlink("#'Table-`i''!A1", "Go To Table `i'")
}
    /// Variable subgroups 
    putexcel A2 = "Event Subtypes", bold font("Calibri", 11)
    putexcel A4 = "Dates", bold font("Calibri", 11)
    putexcel A8 = "Previous Event", bold font("Calibri", 11)
    putexcel A12 = "Risk Factors", bold font("Calibri", 11)
    putexcel A14 = "At Admission", bold font("Calibri", 11)
    putexcel A18 = "Troponin", bold font("Calibri", 11)
    putexcel A19 = "Therapist Assessment", bold font("Calibri", 11)
    putexcel A25 = "CT scan", bold font("Calibri", 11)
    putexcel A26 = "Aspirin Use", bold font("Calibri", 11)
    putexcel A28 = "Discharge Meds", bold font("Calibri", 11)
    putexcel A34 = "Stroke Unit", bold font("Calibri", 11)

** -------------------------------------------------------
** STROKE SUBTYPE 
local tcount = 1 
global var   = "stype_miss"
global name  = "Stroke Subtype"
global table = "Table-`tcount'"
** -------------------------------------------------------
    *--- Collect Table Information
    do "${do}\bnrcvd-2023-missing-collect"
    *--- Final columns / layout AND export
    collect layout (yoe) (result[total count] ${var}[1])
    collect export "${tables}/bnrcvd-2023-missing.xlsx", modify sheet("${table}", replace)

** -------------------------------------------------------
** HEART ATTACK SUBTYPE 
local tcount = `tcount' + 1
global var   = "htype_miss"
global name  = "AMI Subtype"
global table = "Table-`tcount'"
** -------------------------------------------------------
*--- Collect Table Information
    do "${do}\bnrcvd-2023-missing-collect"
    *--- Final columns / layout AND export
    collect layout (yoe) (result[total count] ${var}[1])
    collect export "${tables}/bnrcvd-2023-missing.xlsx", modify sheet("${table}", replace)

** -------------------------------------------------------
** DATE OF EVENT
local tcount = `tcount' + 1
global var   = "doe_miss"
global name  = "Date of Event"
global table = "Table-`tcount'"
** -------------------------------------------------------
*--- Collect Table Information
    do "${do}\bnrcvd-2023-missing-collect"
    *--- Final columns / layout AND export
    collect layout (yoe) (result[total count] ${var}[1])
    collect export "${tables}/bnrcvd-2023-missing.xlsx", modify sheet("${table}", replace)


** -------------------------------------------------------
** DATE OF ADMISSION
local tcount = `tcount' + 1
global var   = "doa_miss"
global name  = "Date of Admission"
global table = "Table-`tcount'"
** -------------------------------------------------------
*--- Collect Table Information
    do "${do}\bnrcvd-2023-missing-collect"
    *--- Final columns / layout AND export
    collect layout (yoe) (result[total count] ${var}[1])
    collect export "${tables}/bnrcvd-2023-missing.xlsx", modify sheet("${table}", replace)

** -------------------------------------------------------
** DATE OF DISCHARGE
local tcount = `tcount' + 1
global var   = "dodi_miss"
global name  = "Date of Discharge"
global table = "Table-`tcount'"
** -------------------------------------------------------
*--- Collect Table Information
    do "${do}\bnrcvd-2023-missing-collect"
    *--- Final columns / layout AND export
    collect layout (yoe) (result[total count] ${var}[1])
    collect export "${tables}/bnrcvd-2023-missing.xlsx", modify sheet("${table}", replace)

** -------------------------------------------------------
** DATE OF DEATH
local tcount = `tcount' + 1
global var   = "dod_miss"
global name  = "Date of Death"
global table = "Table-`tcount'"
** -------------------------------------------------------
*--- Collect Table Information
    do "${do}\bnrcvd-2023-missing-collect"
    *--- Final columns / layout AND export
    collect layout (yoe) (result[total count] ${var}[1])
    collect export "${tables}/bnrcvd-2023-missing.xlsx", modify sheet("${table}", replace)

** -------------------------------------------------------
** PREVIOUS STROKE
local tcount = `tcount' + 1
global var   = "pstroke_miss"
global name  = "Previous Stroke"
global table = "Table-`tcount'"
** -------------------------------------------------------
*--- Collect Table Information
    do "${do}\bnrcvd-2023-missing-collect"
    collect notes "Have assumed that this is collected for ALL events (strokes and heart attacks)"
    *--- Final columns / layout AND export
    collect layout (yoe) (result[total count] ${var}[1])
    collect export "${tables}/bnrcvd-2023-missing.xlsx", modify sheet("${table}", replace)

** -------------------------------------------------------
** PREVIOUS HEART ATTACK
local tcount = `tcount' + 1
global var   = "pami_miss"
global name  = "Previous Heart Attack"
global table = "Table-`tcount'"
** -------------------------------------------------------
*--- Collect Table Information
    do "${do}\bnrcvd-2023-missing-collect"
    collect notes "Have assumed that this is collected for ALL events (strokes and heart attacks)"
    *--- Final columns / layout AND export
    collect layout (yoe) (result[total count] ${var}[1])
    collect export "${tables}/bnrcvd-2023-missing.xlsx", modify sheet("${table}", replace)

** -------------------------------------------------------
** YEAR OF PREVIOUS STROKE
local tcount = `tcount' + 1
global var   = "pstrokeyr_miss"
global name  = "Year of Previous Stroke"
global table = "Table-`tcount'"
** -------------------------------------------------------
*--- Collect Table Information
    do "${do}\bnrcvd-2023-missing-collect"
    collect notes "Have assumed that this is collected for ALL events (strokes and heart attacks)"
    *--- Final columns / layout AND export
    collect layout (yoe) (result[total count] ${var}[1])
    collect export "${tables}/bnrcvd-2023-missing.xlsx", modify sheet("${table}", replace)

** -------------------------------------------------------
** YEAR OF PREVIOUS HEART ATTACK
local tcount = `tcount' + 1
global var   = "pamiyr_miss"
global name  = "Year of Previous Heart Attack"
global table = "Table-`tcount'"
** -------------------------------------------------------
*--- Collect Table Information
    do "${do}\bnrcvd-2023-missing-collect"
    collect notes "Have assumed that this is collected for ALL events (strokes and heart attacks)"
    *--- Final columns / layout AND export
    collect layout (yoe) (result[total count] ${var}[1])
    collect export "${tables}/bnrcvd-2023-missing.xlsx", modify sheet("${table}", replace)

** -------------------------------------------------------
** HISTORY OF HYPERTENSION
local tcount = `tcount' + 1
global var   = "htn_miss"
global name  = "History of Hypertension"
global table = "Table-`tcount'"
** -------------------------------------------------------
*--- Collect Table Information
    do "${do}\bnrcvd-2023-missing-collect"
    collect notes "How is this explored? Only if available in notes? Has the collection method changed over time?"
    *--- Final columns / layout AND export
    collect layout (yoe) (result[total count] ${var}[1])
    collect export "${tables}/bnrcvd-2023-missing.xlsx", modify sheet("${table}", replace)

** -------------------------------------------------------
** HISTORY OF DIABETES
local tcount = `tcount' + 1
global var   = "diab_miss"
global name  = "History of Diabetes"
global table = "Table-`tcount'"
** -------------------------------------------------------
*--- Collect Table Information
    do "${do}\bnrcvd-2023-missing-collect"
    collect notes "How is this explored? Only if available in notes? Has the collection method changed over time?"
    *--- Final columns / layout AND export
    collect layout (yoe) (result[total count] ${var}[1])
    collect export "${tables}/bnrcvd-2023-missing.xlsx", modify sheet("${table}", replace)

** -------------------------------------------------------
** DBP ON ADMISSION
local tcount = `tcount' + 1
global var   = "dbp_miss"
global name  = "DBP on Admission"
global table = "Table-`tcount'"
** -------------------------------------------------------
*--- Collect Table Information
    do "${do}\bnrcvd-2023-missing-collect"
    collect notes "What defines a measurement on admission? Might a later measured be used as a proxy?"
    *--- Final columns / layout AND export
    collect layout (yoe) (result[total count] ${var}[1])
    collect export "${tables}/bnrcvd-2023-missing.xlsx", modify sheet("${table}", replace)

** -------------------------------------------------------
** SBP ON ADMISSION
local tcount = `tcount' + 1
global var   = "sbp_miss"
global name  = "SBP on Admission"
global table = "Table-`tcount'"
** -------------------------------------------------------
*--- Collect Table Information
    do "${do}\bnrcvd-2023-missing-collect"
    collect notes "What defines a measurement on admission? Might a later measured be used as a proxy?"
    *--- Final columns / layout AND export
    collect layout (yoe) (result[total count] ${var}[1])
    collect export "${tables}/bnrcvd-2023-missing.xlsx", modify sheet("${table}", replace)

** -------------------------------------------------------
** BLOOD GLUCOSE ON ADMISSION
local tcount = `tcount' + 1
global var   = "bgmmol_miss"
global name  = "Blood Glucose on Admission"
global table = "Table-`tcount'"
** -------------------------------------------------------
*--- Collect Table Information
    do "${do}\bnrcvd-2023-missing-collect"
    collect notes "What defines a measurement on admission? Might a later measured be used as a proxy?"
    collect notes "It feels as though BLOOD GLUCOSE=No might be left as an empty database field. But just a hunch - for confirmation?"
    *--- Final columns / layout AND export
    collect layout (yoe) (result[total count] ${var}[1])
    collect export "${tables}/bnrcvd-2023-missing.xlsx", modify sheet("${table}", replace)

** -------------------------------------------------------
** ECG ON ADMISSION
local tcount = `tcount' + 1
global var   = "ecg_miss"
global name  = "ECG on Admission"
global table = "Table-`tcount'"
** -------------------------------------------------------
*--- Collect Table Information
    do "${do}\bnrcvd-2023-missing-collect"
    collect notes "Might this be an ECG at any time after admission, not necessarily at admission?"
    collect notes "It feels as though ECG=No might be left as an empty database field. But just a hunch - for confirmation?"
    *--- Final columns / layout AND export
    collect layout (yoe) (result[total count] ${var}[1])
    collect export "${tables}/bnrcvd-2023-missing.xlsx", modify sheet("${table}", replace)

** -------------------------------------------------------
** TROPONIN MEASUREMENT
local tcount = `tcount' + 1
global var   = "tropres_miss"
global name  = "Troponin Measurement"
global table = "Table-`tcount'"
** -------------------------------------------------------
*--- Collect Table Information
    do "${do}\bnrcvd-2023-missing-collect"
    collect notes "Only for Heart Attacks."
    collect notes "There is no option for zero measurements? So if no troponin, would this variable be left blank?"
    *--- Final columns / layout AND export
    collect layout (yoe) (result[total count] ${var}[1])
    collect export "${tables}/bnrcvd-2023-missing.xlsx", modify sheet("${table}", replace)

** -------------------------------------------------------
** ASSESSMENT BY ANY THERAPIST
local tcount = `tcount' + 1
global var   = "assess_miss"
global name  = "Assessment by Any Therapist"
global table = "Table-`tcount'"
** -------------------------------------------------------
*--- Collect Table Information
    do "${do}\bnrcvd-2023-missing-collect"
    collect notes "Only for Strokes."
    collect notes "This overarching variable is YES if there is a record of any individual assessment, presumably?"
    *--- Final columns / layout AND export
    collect layout (yoe) (result[total count] ${var}[1])
    collect export "${tables}/bnrcvd-2023-missing.xlsx", modify sheet("${table}", replace)

** -------------------------------------------------------
** ASSESSMENT BY OT
local tcount = `tcount' + 1
global var   = "assess1_miss"
global name  = "Assessment by Occupational Therapist"
global table = "Table-`tcount'"
** -------------------------------------------------------
*--- Collect Table Information
    do "${do}\bnrcvd-2023-missing-collect"
    collect notes "Only for Strokes."
    collect notes "Absence of information should presumably be coded as 99?"
    *--- Final columns / layout AND export
    collect layout (yoe) (result[total count] ${var}[1])
    collect export "${tables}/bnrcvd-2023-missing.xlsx", modify sheet("${table}", replace)

** -------------------------------------------------------
** ASSESSMENT BY PT
local tcount = `tcount' + 1
global var   = "assess2_miss"
global name  = "Assessment by Physiotherapist"
global table = "Table-`tcount'"
** -------------------------------------------------------
*--- Collect Table Information
    do "${do}\bnrcvd-2023-missing-collect"
    collect notes "Only for Strokes."
    collect notes "Absence of information should presumably be coded as 99?"
    *--- Final columns / layout AND export
    collect layout (yoe) (result[total count] ${var}[1])
    collect export "${tables}/bnrcvd-2023-missing.xlsx", modify sheet("${table}", replace)

** -------------------------------------------------------
** ASSESSMENT BY Speech Therapist
local tcount = `tcount' + 1
global var   = "assess3_miss"
global name  = "Assessment by Speech Therapist"
global table = "Table-`tcount'"
** -------------------------------------------------------
*--- Collect Table Information
    do "${do}\bnrcvd-2023-missing-collect"
    collect notes "Only for Strokes."
    collect notes "Absence of information should presumably be coded as 99?"
    *--- Final columns / layout AND export
    collect layout (yoe) (result[total count] ${var}[1])
    collect export "${tables}/bnrcvd-2023-missing.xlsx", modify sheet("${table}", replace)

** -------------------------------------------------------
** SWALLOWING ASSESSMENT BY Speech Therapist
local tcount = `tcount' + 1
global var   = "assess4_miss"
global name  = "Swallowing assessment by Speech Therapist"
global table = "Table-`tcount'"
** -------------------------------------------------------
*--- Collect Table Information
    do "${do}\bnrcvd-2023-missing-collect"
    collect notes "Only for Strokes."
    collect notes "Absence of information should presumably be coded as 99?"
    *--- Final columns / layout AND export
    collect layout (yoe) (result[total count] ${var}[1])
    collect export "${tables}/bnrcvd-2023-missing.xlsx", modify sheet("${table}", replace)

** -------------------------------------------------------
** CT scan 
local tcount = `tcount' + 1
global var   = "ct_miss"
global name  = "CT scan performed/available"
global table = "Table-`tcount'"
** -------------------------------------------------------
*--- Collect Table Information
    do "${do}\bnrcvd-2023-missing-collect"
    collect notes "Only for Strokes"
    collect notes "Absence of information should presumably be coded as 99?"
    *--- Final columns / layout AND export
    collect layout (yoe) (result[total count] ${var}[1])
    collect export "${tables}/bnrcvd-2023-missing.xlsx", modify sheet("${table}", replace)

** -------------------------------------------------------
** Reperfusion
local tcount = `tcount' + 1
global var   = "reperf_miss"
global name  = "Reperfusion performed"
global table = "Table-`tcount'"
** -------------------------------------------------------
*--- Collect Table Information
    do "${do}\bnrcvd-2023-missing-collect"
    collect notes "Absence of information should presumably be coded as 99?"
    *--- Final columns / layout AND export
    collect layout (yoe) (result[total count] ${var}[1])
    collect export "${tables}/bnrcvd-2023-missing.xlsx", modify sheet("${table}", replace)

** -------------------------------------------------------
** Aspirin (acute)
local tcount = `tcount' + 1
global var   = "asp1_miss"
global name  = "Aspirin (acute)"
global table = "Table-`tcount'"
** -------------------------------------------------------
*--- Collect Table Information
    do "${do}\bnrcvd-2023-missing-collect"
    collect notes "Absence of information should presumably be coded as 99?"
    *--- Final columns / layout AND export
    collect layout (yoe) (result[total count] ${var}[1])
    collect export "${tables}/bnrcvd-2023-missing.xlsx", modify sheet("${table}", replace)

** -------------------------------------------------------
** Aspirin (chronic)
local tcount = `tcount' + 1
global var   = "asp2_miss"
global name  = "Aspirin (chronic)"
global table = "Table-`tcount'"
** -------------------------------------------------------
*--- Collect Table Information
    do "${do}\bnrcvd-2023-missing-collect"
    collect notes "Absence of information should presumably be coded as 99?"
    *--- Final columns / layout AND export
    collect layout (yoe) (result[total count] ${var}[1])
    collect export "${tables}/bnrcvd-2023-missing.xlsx", modify sheet("${table}", replace)


** -------------------------------------------------------
** Discharge Medications (aspirin)
local tcount = `tcount' + 1
global var   = "dmed1_miss"
global name  = "Discharge Meds (aspirin)"
global table = "Table-`tcount'"
** -------------------------------------------------------
*--- Collect Table Information
    do "${do}\bnrcvd-2023-missing-collect"
    collect notes "There is no missing data. Is this Correct? For review."
    *--- Final columns / layout AND export
    collect layout (yoe) (result[total count] ${var}[1])
    collect export "${tables}/bnrcvd-2023-missing.xlsx", modify sheet("${table}", replace)

** -------------------------------------------------------
** Discharge Medications (warfarin)
local tcount = `tcount' + 1
global var   = "dmed2_miss"
global name  = "Discharge Meds (warfarin)"
global table = "Table-`tcount'"
** -------------------------------------------------------
*--- Collect Table Information
    do "${do}\bnrcvd-2023-missing-collect"
    collect notes "There is no missing data. Is this Correct? For review."
    *--- Final columns / layout AND export
    collect layout (yoe) (result[total count] ${var}[1])
    collect export "${tables}/bnrcvd-2023-missing.xlsx", modify sheet("${table}", replace)

** -------------------------------------------------------
** Discharge Medications (heparin)
local tcount = `tcount' + 1
global var   = "dmed3_miss"
global name  = "Discharge Meds (heparin)"
global table = "Table-`tcount'"
** -------------------------------------------------------
*--- Collect Table Information
    do "${do}\bnrcvd-2023-missing-collect"
    collect notes "There is no missing data. Is this Correct? For review."
    *--- Final columns / layout AND export
    collect layout (yoe) (result[total count] ${var}[1])
    collect export "${tables}/bnrcvd-2023-missing.xlsx", modify sheet("${table}", replace)

** -------------------------------------------------------
** Discharge Medications (antiplatelet)
local tcount = `tcount' + 1
global var   = "dmed4_miss"
global name  = "Discharge Meds (antiplatelet)"
global table = "Table-`tcount'"
** -------------------------------------------------------
*--- Collect Table Information
    do "${do}\bnrcvd-2023-missing-collect"
    collect notes "There is no missing data. Is this Correct? For review."
    *--- Final columns / layout AND export
    collect layout (yoe) (result[total count] ${var}[1])
    collect export "${tables}/bnrcvd-2023-missing.xlsx", modify sheet("${table}", replace)

** -------------------------------------------------------
** Discharge Medications (Statin)
local tcount = `tcount' + 1
global var   = "dmed5_miss"
global name  = "Discharge Meds (statin)"
global table = "Table-`tcount'"
** -------------------------------------------------------
*--- Collect Table Information
    do "${do}\bnrcvd-2023-missing-collect"
    collect notes "There is no missing data. Is this Correct? For review."
    *--- Final columns / layout AND export
    collect layout (yoe) (result[total count] ${var}[1])
    collect export "${tables}/bnrcvd-2023-missing.xlsx", modify sheet("${table}", replace)

** -------------------------------------------------------
** Discharge Medications (ACE inhibitor)
local tcount = `tcount' + 1
global var   = "dmed6_miss"
global name  = "Discharge Meds (ACE inhibitor)"
global table = "Table-`tcount'"
** -------------------------------------------------------
*--- Collect Table Information
    do "${do}\bnrcvd-2023-missing-collect"
    collect notes "There is no missing data. Is this Correct? For review."
    *--- Final columns / layout AND export
    collect layout (yoe) (result[total count] ${var}[1])
    collect export "${tables}/bnrcvd-2023-missing.xlsx", modify sheet("${table}", replace)

** -------------------------------------------------------
** Stroke Unit 
local tcount = `tcount' + 1
global var   = "sunit_miss"
global name  = "Admitted to Stroke Unit"
global table = "Table-`tcount'"
** -------------------------------------------------------
*--- Collect Table Information
    do "${do}\bnrcvd-2023-missing-collect"
    collect notes "Absence of information should presumably be coded as 99?"
    *--- Final columns / layout AND export
    collect layout (yoe) (result[total count] ${var}[1])
    collect export "${tables}/bnrcvd-2023-missing.xlsx", modify sheet("${table}", replace)





** --------------------------------------------------------------
** PART FOUR 
** --------------------------------------------------------------
** Final Table Formatting. 
** Widen the Columns of every Table
** Need to use -mata- for this
** --------------------------------------------------- 
    local num    = "1 2 3 4 5 6 7 8 9 10"
    mata: rows = (1,20) 
    mata: cols = (1,20) 
    ** -------------------------------------------------------
    forvalues i = 1/`tcount' {
        mata: workbook = xl()
        mata: workbook.load_book("${Pytables}/bnrcvd-2023-missing.xlsx")
        mata: workbook.set_sheet("Table-`i'")
        mata: workbook.set_mode("open")     // required for editing
        mata: workbook.set_column_width(1, 6, 15)
        mata: workbook.set_font(rows, cols, "Calibri", 11)
        mata: workbook.close_book()
    }
    mata: workbook = xl()
    mata: workbook.load_book("${Pytables}/bnrcvd-2023-missing.xlsx")
    mata: workbook.set_sheet("Index")
    mata: workbook.set_mode("open")     // required for editing
    mata: workbook.set_column_width(1, 1, 20)
    mata: workbook.set_column_width(2, 2, 10)
    mata: workbook.set_column_width(3, 3, 80)
    mata: workbook.set_column_width(4, 4, 15)
    mata: workbook.set_font(rows, cols, "Calibri", 11)
    mata: workbook.close_book()
