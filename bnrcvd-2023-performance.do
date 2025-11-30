/**************************************************************************
 DO-FILE:     bnrcvd-2023-performance.do
 PROJECT:     BNR Refit Consultancy
 PURPOSE:     - Initial look at hospital performance metrics
              - Case-fatality 
 
 AUTHOR:      Ian R Hambleton
 DATE:        [2025-11-07]
 VERSION:     [v1.0]

 METADATA:    bnrcvd-2023-performance.yml (same dirpath/name as dataset)

 NOTES:       Hospital performance metrics
              QM1:  Proportion of patients with MI receiving aspirin within 24 hrs
                    VARS: doa htoa mtoa asp1 asp2 asp3 aspdose doasp htoasp mtoasp asptimeampm_2
  
              QM2:  Proportion of STEMI patients who received reperfusion via fibrinolysis
                    VARS: htype (for STEMI) repertype (any non-missing value)
  
              QM3:  Median time to reperfusion for STEMI cases
                    VARS: doa htoa mtoa ecg doecg htecg mtecg repertype dore htore mtore
  
              QM4:  Proportion of patients receiving an echocardiogram before discharge
                    VARS: ecg doecg htecg mtecg
  
              QM5:  Documented aspirin prescribed at discharge
                    VARS: dmed1 (consider also those on chronic use at admission: asp2)
  
              QM6:  Documented statins prescribed at discharge
                    VARS: dmed5
**************************************************************************/

* Log File 
cap log close 
log using ${logs}\bnrcvd-2023-performance, replace 

** GLOBALS 
do "C:\yasuki\Sync\BNR-sandbox\006-dev\do\bnrcvd-globals"

** --------------------------------------------------------------
** (1) Load the interim dataset - HOSPITAL PERFORMANCE
**     Dataset prepared in: bnrcvd-2023-prep1.do
** --------------------------------------------------------------
use "${tempdata}\bnr-cvd-performance-${today}-prep1.dta", clear 
drop if dco==1 

** 5-year indicator (create timeframe for later time limit)
    global thisyr = real(substr("${today}", 1, 4))
    tempvar latestyr time5
    egen `latestyr' = max(yoe) 
    gen time5 = 1
    replace time5 = 2 if `latestyr' != yoe & `latestyr' - yoe < 6 
    replace time5 = 3 if `latestyr' == yoe 
    label define time5_ 1 ">5yrs ago" 2 "<=5 yrs ago" 3 "This year"
    label values time5 time5_ 

    ** Temp file for start of each performance metric
    tempfile performance1 
    save "${tempdata}\`performance1'", replace



** -----------------------------------------------------------------------
** QM1:     Proportion of patients with MI receiving aspirin within 24 hrs
** 
**          VARS: asp1 (consider also those on chronic use at admission: asp2)
**          WHO:  AMI patients
**          
**          ANALYSIS NOTE:
**          Previous analyses have dropped 'Partial Abstractions'
**          I've not done that - counts towards missingness 
**          GLOBALS (naming explanation)
**            Apirin Given
**                  ab5_p (a=aspirin, b=both sexes, 5=five-year av, p=perc)
**                  afy_n (a=aspirin, f=female, y=latest year, n=numerator)
**                  am5_d (a=aspirin, m=male, y=five-year, d=denominator)
**                  etc.
**            Aspirin Given within 24-hours
**                  a24_b5 (a24-Aspirin with 24 hrs, b=both sexes, 5=five-year)
**                  etc.
** -----------------------------------------------------------------------
    keep eid time5 yoe doe htoe mtoe sex etype doa htoa mtoa asp1 asp2 asp3 aspdose doasp htoasp mtoasp asp_ampm 
    * AMI only
    keep if etype==2 & time5>1
    drop etype 
    ** Weighted percentage (acute aspirin given)
    gen event = 1 
    ** For aspirin, we assume missing = not received
    ** The reason for this is that there seems to be different field completion rules:
    ** not completing the negative - pre middle of 2020
    replace asp1 = 0 if asp1==. 
    ** Create weighted count (row/N), which allows collapse to actual count 
    bysort time5     : egen tevent1 = sum(event) 
    bysort time5 sex : egen tevent2 = sum(event) 
    forval x = 1(1)2 {
        gen wevent`x' = event / tevent`x' 
        gen perc`x' = (asp1*wevent`x') * 100
        format perc`x' %5.1f
        }
    * Percentage aspirin given (women + men combined) 
    preserve 
        collapse (sum) perc1 asp1 event, by(time5)    
        global ab5_p = perc1[1]
        global aby_p = perc1[2]
        global ab5_n = asp1[1]/5
        global aby_n = asp1[2]
        global ab5_d = event[1]/5
        global aby_d = event[2]
        dis "${ab5_p}"
        dis "${aby_p}"
        dis "${ab5_n}"
        dis "${aby_n}"
        dis "${ab5_d}"
        dis "${aby_d}"
    restore
    * Percentage aspirin given (women + men stratified) 
    preserve 
        collapse (sum) perc2 asp1 event, by(time5 sex)    
        global af5_p = perc2[1]
        global am5_p = perc2[2]
        global afy_p = perc2[3]
        global amy_p = perc2[4]
        global af5_n = asp1[1]/5
        global am5_n = asp1[2]/5
        global afy_n = asp1[3]
        global amy_n = asp1[4]
        global af5_d = event[1]/5
        global am5_d = event[2]/5
        global afy_d = event[3]
        global amy_d = event[4]
        dis "${af5_p}"
        dis "${am5_p}"
        dis "${afy_p}"
        dis "${amy_p}"
        dis "${af5_n}"
        dis "${am5_n}"
        dis "${afy_n}"
        dis "${amy_n}"
        dis "${af5_d}"
        dis "${am5_d}"
        dis "${afy_d}"
        dis "${amy_d}"
    restore

    * P(Given within 24 hours | Given acute aspirin)  
    gen secs = 0 
    gen asp_arr = dhms(doe, htoe, mtoe, secs)
    gen asp_giv = dhms(doasp, htoasp, mtoasp, secs)
    generate diff_hrs = clockdiff(asp_arr, asp_giv , "hour")
    gen diff24 = .
    replace diff24 = 0 if diff_hrs<. 
    replace diff24 = 1 if diff_hrs<=24
    * women + men combined 
    tab time5 diff24, row matcell(d24)
    matrix list d24
    global a24_b5 = (d24[1,2] / (d24[1,1] + d24[1,2]) ) * 100
    global a24_by = (d24[2,2] / (d24[2,1] + d24[2,2]) ) * 100
    dis "${a24_b5}" "  ,  "   "${a24_by}"
    * women
    tab time5 diff24 if sex==1, nofreq row matcell(d24)
    global a24_f5 = (d24[1,2] / (d24[1,1] + d24[1,2]) ) * 100
    global a24_fy = (d24[2,2] / (d24[2,1] + d24[2,2]) ) * 100
    dis "${a24_f5}" "  ,  "   "${a24_fy}"
    * men
    tab time5 diff24 if sex==2, nofreq row matcell(d24)
    global a24_m5 = (d24[1,2] / (d24[1,1] + d24[1,2]) ) * 100
    global a24_my = (d24[2,2] / (d24[2,1] + d24[2,2]) ) * 100
    dis "${a24_m5}" "  ,  "   "${a24_my}"


** -----------------------------------------------------------------------
** QM2:  Proportion of STEMI patients who received reperfusion via fibrinolysis
**       VARS: htype (for STEMI) repertype (any non-missing value)
** -----------------------------------------------------------------------
    use "${tempdata}\`performance1'", clear
    keep eid time5 yoe doe htoe mtoe sex etype htype doa htoa mtoa ecg doecg htecg mtecg reperf repertype dore htore mtore
    * AMI STEMI only
    keep if etype==2 & htype==1 
    drop etype 
    * Keep current year + 5 previous years (for 5-yr average) 
    keep if time5>1

    ** Reperfusion (=no) given a zero count 
    recode reperf 2=0  
    gen event = 1 
    replace event = . if reperf>=.  

    ** Weighted percentage (reperfusion given)
    bysort time5     : egen tevent1 = sum(event) 
    bysort time5 sex : egen tevent2 = sum(event) 
    forval x = 1(1)2 {
        gen wevent`x' = event / tevent`x' 
        gen perc`x' = (reperf*wevent`x') * 100
        format perc`x' %5.1f
        }
    * Percentage reperfusion given (women + men combined) 
    preserve 
        collapse (sum) perc1 reperf event, by(time5)    
        global rb5_p = perc1[1]
        global rby_p = perc1[2]
        global rb5_n = reperf[1]/5
        global rby_n = reperf[2]
        global rb5_d = event[1]/5
        global rby_d = event[2]
        dis "${rb5_p}"
        dis "${rby_p}"
        dis "${rb5_n}"
        dis "${rby_n}"
        dis "${rb5_d}"
        dis "${rby_d}"
    restore
    * Percentage reperfusion given (women + men stratified) 
    preserve 
        collapse (sum) perc2 reperf event, by(time5 sex)    
        global rf5_p = perc2[1]
        global rm5_p = perc2[2]
        global rfy_p = perc2[3]
        global rmy_p = perc2[4]
        global rf5_n = reperf[1]/5
        global rm5_n = reperf[2]/5
        global rfy_n = reperf[3]
        global rmy_n = reperf[4]
        global rf5_d = event[1]/5
        global rm5_d = event[2]/5
        global rfy_d = event[3]
        global rmy_d = event[4]
        dis "${rf5_p}"
        dis "${rm5_p}"
        dis "${rfy_p}"
        dis "${rmy_p}"
        dis "${rf5_n}"
        dis "${rm5_n}"
        dis "${rfy_n}"
        dis "${rmy_n}"
        dis "${rf5_d}"
        dis "${rm5_d}"
        dis "${rfy_d}"
        dis "${rmy_d}"
    restore
/*
** -----------------------------------------------------------------------
** QM3:  Median time to reperfusion for STEMI cases
**       VARS: doa htoa mtoa ecg doecg htecg mtecg repertype dore htore mtore
** -----------------------------------------------------------------------
    * P(Given within 24 hours | Given reperfusion)  
    gen secs = 0 
    gen rep_arr = dhms(doe, htoe, mtoe, secs)
    gen rep_giv = dhms(dore, htore, mtore, secs)
    generate diff_hrs = clockdiff(rep_arr, rep_giv , "minute")
    * women + men combined
    preserve 
        collapse (p50) diff_p50=diff_hrs (p25) diff_p25=diff_hrs (p75) diff_p75=diff_hrs, by(time5)
        global rb5_p50 = diff_p50[1]
        global rb5_p25 = diff_p25[1]
        global rb5_p75 = diff_p75[1]
        global rby_p50 = diff_p50[2]
        global rby_p25 = diff_p25[2]
        global rby_p75 = diff_p75[2]
            dis "${rb5_p50}"
            dis "${rb5_p25}"
            dis "${rb5_p75}"
            dis "${rby_p50}"
            dis "${rby_p25}"
            dis "${rby_p75}"
    restore 
    * women + men separately
    collapse (p50) diff_p50=diff_hrs (p25) diff_p25=diff_hrs (p75) diff_p75=diff_hrs, by(time5 sex)
    global rf5_p50 = diff_p50[1]
    global rf5_p25 = diff_p25[1]
    global rf5_p75 = diff_p75[1]
    global rfy_p50 = diff_p50[3]
    global rfy_p25 = diff_p25[3]
    global rfy_p75 = diff_p75[3]
        dis "${rf5_p50}"
        dis "${rf5_p25}"
        dis "${rf5_p75}"
        dis "${rfy_p50}"
        dis "${rfy_p25}"
        dis "${rfy_p75}"
    global rm5_p50 = diff_p50[2]
    global rm5_p25 = diff_p25[2]
    global rm5_p75 = diff_p75[2]
    global rmy_p50 = diff_p50[4]
    global rmy_p25 = diff_p25[4]
    global rmy_p75 = diff_p75[4]
        dis "${rm5_p50}"
        dis "${rm5_p25}"
        dis "${rm5_p75}"
        dis "${rmy_p50}"
        dis "${rmy_p25}"
        dis "${rmy_p75}"


** -----------------------------------------------------------------------
** QM4: Echocardiogram at discharge
** -----------------------------------------------------------------------
    use "${tempdata}\`performance1'", clear

    keep eid time5 yoe doe htoe mtoe sex etype htype doa htoa mtoa ecg doecg htecg mtecg reperf repertype dore htore mtore
    * AMI STEMI only
    keep if etype==2
    drop etype 
    * Keep current year + 5 previous years (for 5-yr average) 
    keep if time5>1
    ** Weighted percentage (ecg given)
    gen event = 1 
    recode ecg 2=0 
    bysort time5     : egen tevent1 = sum(event) 
    bysort time5 sex : egen tevent2 = sum(event) 
    forval x = 1(1)2 {
        gen wevent`x' = event / tevent`x' 
        gen perc`x' = (ecg*wevent`x') * 100
        format perc`x' %5.1f
        }
    * Percentage reperfusion given (women + men combined) 
    preserve 
        collapse (sum) perc1 event, by(time5)    
        global eb5_p = perc1[1]
        global eby_p = perc1[2]
        global eb5_n = event[1]/5
        global eby_n = event[2]
        dis "${eb5_p}"
        dis "${eby_p}"
        dis "${eb5_n}"
        dis "${eby_n}"
    restore
    * Percentage reperfusion given (women + men stratified) 
    preserve 
        collapse (sum) perc2 event, by(time5 sex)    
        global ef5_p = perc2[1]
        global em5_p = perc2[2]
        global efy_p = perc2[3]
        global emy_p = perc2[4]
        global ef5_n = event[1]/5
        global em5_n = event[2]/5
        global efy_n = event[3]
        global emy_n = event[4]
        dis "${ef5_p}"
        dis "${em5_p}"
        dis "${efy_p}"
        dis "${emy_p}"
        dis "${ef5_n}"
        dis "${em5_n}"
        dis "${efy_n}"
        dis "${emy_n}"
    restore

