/**************************************************************************
 DO-FILE:     bnrcvd-2023-length-of-stay.do
 PROJECT:     BNR Refit Consultancy
 PURPOSE:     - Initial look at BNR in-hospital length of stay in 2023
 
 AUTHOR:      Ian R Hambleton
 DATE:        [2025-11-13]
 VERSION:     [v1.0]

 METADATA:    bnrcvd-2023-length-of-stay.yml (same dirpath/name as dataset)

 NOTES:       BNR case-fatality 
                - by type (AMI, stroke)
                - by year
                - by sex 
                - age-stratified
                - crude and age-standardized to WHO Std Pop (2000)

This script provides an initial description of in-hospital length of
stay (LOS) for BNR-CVD events in 2010–2023, with emphasis on 2023.

It:
  - Loads the prepared length-of-stay dataset (derived from the main
    BNR-CVD events file) and restricts analysis to hospital-treated
    AMI and stroke events (excluding DCO-only cases and the 2009
    setup year).
  - Derives primary LOS measures using discharge or death dates and
    flags very long stays for review, in the context of changes to
    discharge-date recording in the 2023 REDCap database.
  - Uses median regression and related summaries to examine trends in
    LOS by event type and sex, and generates tabulations and figures
    (medians and IQRs) for inclusion in the 2023 BNR-CVD reporting
    and service-planning discussions.
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
   log using ${logs}\bnrcvd-2023-length-of-stay, replace 

   * Initialize 
   version 19 
   clear all
   set more off
** ----- END INITIALIZE DO FILE -------------------
** ------------------------------------------------

** DATASET PREPARATION 
do "${do}\bnrcvd-2023-prep1"

** --------------------------------------------------------------
** (1) Load the interim dataset - CASE-FATALITY
**     Dataset prepared in: bnrcvd-2023-prep1.do
** --------------------------------------------------------------
    use "${tempdata}\bnr-cvd-length-of-stay-${today}-prep1.dta", clear 

** BROAD RESTRICTIONS
** HOSPIPTAL EVENTS ONLY - drop DCOs 
    drop if dco==1 
    drop dco 
    drop if yoe==2009  /// Setup year - don't report

* IRH 13-NOV-2025 
* Very obvious date errors - simply convert to missing for this 2023 briefing exercise
    replace dod = . if dod>1000000 
    replace dodi = . if dodi>1000000 

** 2-year intervals 
gen yoa = year(doa) 
gen year2 = .
replace year2 = 1 if yoa==2010 | yoa==2011
replace year2 = 2 if yoa==2012 | yoa==2013
replace year2 = 3 if yoa==2014 | yoa==2015
replace year2 = 4 if yoa==2016 | yoa==2017
replace year2 = 5 if yoa==2018 | yoa==2019
replace year2 = 6 if yoa==2020 | yoa==2021
replace year2 = 7 if yoa==2022 | yoa==2023
label define year2_ 1 "2010-2011" 2 "2012-2013" 3 "2014-2015" 4 "2016-2017" 5 "2018-2019" 6 "2020-2021" 7 "2022-2023"
label values year2 year2_ 
order year2, after(yoe)

** Vital Status At Discarge (sadi, 1=alive, 2=dead) 
**      Incomplete variable
**      Can improve by exploring date of death cf. date of discharge 
* Difference between date of event and date of death (days)
    gen doe_dod_diff = dod - doe
* Case-Fatality Rate (with uncertainty as follows): 
*   1 = CONFIRMED alive at discharge
*   2 = POSSIBLE alive at discharge (death, but after 28 days of event)
*   3 = CONFIRMED death within hospital
*   4 = PROBABLE death within hospital (death, within 7 days of event)
*   5 = POSSIBLE death within hospital (death, between 7 and 28 days of event)
    gen cf = sadi
    recode cf (2=3)
    replace cf = 2 if sadi==. & dod<. & doe_dod_diff>28
    replace cf = 4 if sadi==. & dod<. & doe_dod_diff<=7 
    replace cf = 5 if sadi==. & dod<. & doe_dod_diff>7 & doe_dod_diff<=28
    replace cf = .a if cf==. 
    label define cf_ 1 "Conf.Alive" 2 "Undoc Alive" 3 "Conf.CF" 4 "Prob.CF" 5 "Poss.CF" .a "No dates"
    label values cf cf_ 

** Length of stay (Using only CONFIRMED alive, CONFIRMED hospital death, AND PROBABLE hospital death )
    gen los_primary = dodi - doa 
    order cf los_primary , after(sadi) 
    label var cf "Vital status at discharge/death (with uncertainty)"
    label var los_primary "Length of hospital stay (days)"

* IRH 13-NOV-2025 
    * A number of -dodi- that seem too long for an in-hospital stay
    * Possibly linked to dodi change of meaning in 2023
    * JC notes (email to IRH 7-NOV-2023): 
    *       "...dlc used to mean date of last known contact 
    *       then BNR changed it to discharge date in the 2023 REDCap database. 
    *       I had to copy the previous discharge date variable into dlc."
    * IRH 13-NOV-2025 
    * After some exploration. These longs stay are:
    *           (A) spread evenly through time
    *           (B) mostly among strokes
    * So this may well be a real effect - with hospital acting as longer-term post-care facility
    gen los_poss_error = 0 
    replace los_poss_error = 1 if los_primary>=60 & los_primary<. 
    order cf los_poss_error , after(los_primary) 

** Median regression - trend in median los for stroke and heart separately 
qreg los_primary i.etype
qreg los_primary i.sex
qreg los_primary i.etype i.sex
qreg los_primary i.etype i.sex year
qreg los_primary i.sex year if etype==1
qreg los_primary i.sex year if etype==2

** Temporary save of PID dataset 
tempfile pid_los 
save `pid_los', replace 
* Save for tabulations 
save "${tempdata}/bnrcvd-length-of-stay.dta", replace 

** Hospital days by Event Type and 2-year period 
tempfile nevent1 nevent2 nevent3 nevent4 nevent5 
    preserve
        collapse (count) nevent=los_primary if cf==1 , by(etype)
        save `nevent1', replace 
    restore 
    preserve
        collapse (count) nevent=los_primary if cf==1 , by(sex)
        save `nevent2', replace 
    restore 
    preserve
        collapse (count) nevent=los_primary if cf==1 , by(etype sex)
        save `nevent3', replace 
    restore 
    preserve
        collapse (count) nevent=los_primary if cf==1 , by(etype year2)
        save `nevent4', replace 
    restore 
    preserve 
        use `nevent2', clear 
        append using `nevent1'
        * append using `tlos3'
        append using `nevent4'
        drop if nevent==0
        gen yaxis = _n
        order yaxis sex etype year2
        ** Annual count 
        gen nevent_1yr = nevent/14 if yaxis<=4 
        replace nevent_1yr = nevent/2 if yaxis>=5 
        save `nevent5', replace 
    restore

* LoS Summary Metrics for graphic 
* Graphic restricted to those alive at discharge 
* Create aggregrated dataset as a combination of several collapsed datasets 
    tempfile los1 los2 los3 los4 los5 los6
    preserve
        collapse (p50) los50=los_primary (p25) los25=los_primary     ///
                 (p75) los75=los_primary (p5) los05=los_primary     /// 
                 (p95) los95=los_primary if cf==1 , by(etype)
        save `los1', replace 
    restore 
    preserve
        collapse (p50) los50=los_primary (p25) los25=los_primary     ///
                 (p75) los75=los_primary (p5) los05=los_primary     /// 
                 (p95) los95=los_primary if cf==1  , by(sex)
        save `los2', replace 
    restore 
    preserve
        collapse (p50) los50=los_primary (p25) los25=los_primary     ///
                 (p75) los75=los_primary (p5) los05=los_primary     /// 
                 (p95) los95=los_primary if cf==1  , by(etype sex)
        save `los3', replace 
    restore 
    preserve
        collapse (p50) los50=los_primary (p25) los25=los_primary     ///
                 (p75) los75=los_primary (p5) los05=los_primary     /// 
                 (p95) los95=los_primary if cf==1  , by(etype year2)
        save `los4', replace 
    restore 

use `los2', clear 
append using `los1'
* append using `los3'
append using `los4'
drop if los50==.
gen yaxis = _n
merge 1:1 yaxis using `nevent5'
drop _merge 
order yaxis sex etype year2
* Spacing between yaxis blocks (4 blocks : ETYPE / SEX / STROKE years / AMI years) 
replace yaxis = yaxis + 1 if yaxis >=3 
replace yaxis = yaxis + 1 if yaxis >=6 
replace yaxis = yaxis + 1 if yaxis >=14 


** ---------------------------------------------
** (8) ANALYTICS 1 - 
** LENGTH of STAY MEDIAN VALUES
** ---------------------------------------------
        #delimit ;
            gr twoway 
                /// Graph Furniture 
                /// X-Axis
                (scatteri 22 2 22 4.5 , recast(line) lw(0.2) lc("gs8") lp("l"))
                (scatteri 22 5.5 22 9.5 , recast(line) lw(0.2) lc("gs8") lp("l"))
                (scatteri 22 10.5 22 14.5 , recast(line) lw(0.2) lc("gs8") lp("l"))
                (scatteri 22 15.5 22 19.5 , recast(line) lw(0.2) lc("gs8") lp("l"))
                /// Equality line (rate ratio = 1)
                (scatteri 0.75 0  2.0 0 , recast(line) lw(0.2) lc("gs0") lp("-"))
                (scatteri  3.5 0  5.5 0 , recast(line) lw(0.2) lc("gs0") lp("-"))
                (scatteri  6.5 0 13.5 0 , recast(line) lw(0.2) lc("${str_m70}%75") lp("-"))
                (scatteri 14.5 0 22.0 0 , recast(line) lw(0.2) lc("${ami_m70}%75") lp("-"))

                /// The Data (lines and points) 

                (rspike los25 los75 yaxis if yaxis>=1 & yaxis<=2 , horizontal lw(0.55) color("gs0"))
                (sc yaxis los50           if yaxis>=1 & yaxis<=2 , msize(1.5) mc("gs16"))
                (sc yaxis los50           if yaxis>=1 & yaxis<=2 , msize(1) mc("gs0"))
                (rspike los25 los75 yaxis if yaxis>=4            , horizontal lw(0.55) color("${str_m70}"))
                (sc yaxis los50           if yaxis>=4            , msize(1.5) mc("gs16"))
                (sc yaxis los50           if yaxis>=4            , msize(1) mc("${str_m}"))
                (rspike los25 los75 yaxis if yaxis>=5            , horizontal lw(0.55) color("${ami_m70}"))
                (sc yaxis los50           if yaxis>=5            , msize(1.5) mc("gs16"))
                (sc yaxis los50           if yaxis>=5            , msize(1) mc("${ami_m}"))

                (rspike los25 los75 yaxis if yaxis>=7 & yaxis<=13 , horizontal lw(0.55) color("${str_m70}"))
                (sc yaxis los50           if yaxis>=7 & yaxis<=13 , msize(1.5) mc("gs16"))
                (sc yaxis los50           if yaxis>=7 & yaxis<=13 , msize(1) mc("${str_m}"))
                (rspike los25 los75 yaxis if yaxis>=14            , horizontal lw(0.55) color("${ami_m70}"))
                (sc yaxis los50           if yaxis>=14            , msize(1.5) mc("gs16"))
                (sc yaxis los50           if yaxis>=14            , msize(1) mc("${ami_m}"))

                ,
                    plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin) margin(l=2 r=2 b=0 t=0)) 		
                    graphregion(color(gs16) ic(gs16) ilw(thin) lw(thin) margin(l=2 r=2 b=0 t=0)) 
                    ysize(14) xsize(15)

                    xlab(none, 
                    labc(gs0) labs(2.5) notick nogrid angle(45) format(%9.0f))
                    xscale(noextend lw(vthin) range(-10(1)22)) 
                    xtitle(" ", size(3) color(gs0) margin(l=1 r=1 t=1 b=1)) 
                    
                    ylab(none,
                    valuelabel labc(gs0) labs(3) tlc(gs8) notick nogrid angle(0) format(%9.0f))
                    yscale( reverse noline noextend range(0(0.5)22.5) ) 
                    ytitle(" ", color(gs8) size(4.5) margin(l=1 r=1 t=1 b=1)) 

                    /// Title 
                    text(23.25 5 "Median Length of Stay (Days), 2010–2023",  place(c) size(2.5) color(gs4))

                    // X-axis legend
                    text(22 1 "One",  place(c) size(2) color(gs4))
                    text(22 5 "5",  place(c) size(2) color(gs4))
                    text(22 10 "10",  place(c) size(2) color(gs4))
                    text(22 15 "15",  place(c) size(2) color(gs4))
                    text(22 20 "20",  place(c) size(2) color(gs4))

                    /// (Right hand side) Hospital Rates by Sex and Event type 
                    text(1   -1 "Women"          ,  place(w) size(2.5) color("gs0"))
                    text(2   -1 "Men"          ,  place(w) size(2.5) color("gs0"))
                    text(4   -1 "Stroke "                ,  place(w) size(2.5) color("${str_m}%75"))
                    text(5   -1 "Heart Attack"          ,  place(w) size(2.5) color("${ami_m}%75"))
                    text(7   -7 "Stroke"                       ,  place(w) size(2.5) color("${str_m}%75"))
                    text(7   -2 "2010-2011"                       ,  place(w) size(2.25) color("${str_m}%75"))
                    text(8   -2 "2012-2013"                       ,  place(w) size(2.25) color("${str_m}%75"))
                    text(9   -2 "2014-2015"                       ,  place(w) size(2.25) color("${str_m}%75"))
                    text(10  -2 "2016-2017"                       ,  place(w) size(2.25) color("${str_m}%75"))
                    text(11  -2 "2018-2019"                       ,  place(w) size(2.25) color("${str_m}%75"))
                    text(12  -2 "2020-2021"                       ,  place(w) size(2.25) color("${str_m}%75"))
                    text(13  -2 "2022-2023"                       ,  place(w) size(2.25) color("${str_m}%75"))

                    text(15 -7 "Heart Attack "   ,  place(w) size(2.5) color("${ami_m}%75"))
                    text(15 -2 "2010-2011"                       ,  place(w) size(2.25) color("${ami_m}%75"))
                    text(16 -2 "2012-2013"                       ,  place(w) size(2.25) color("${ami_m}%75"))
                    text(17 -2 "2014-2015"                       ,  place(w) size(2.25) color("${ami_m}%75"))
                    text(18 -2 "2016-2017"                       ,  place(w) size(2.25) color("${ami_m}%75"))
                    text(19 -2 "2018-2019"                       ,  place(w) size(2.25) color("${ami_m}%75"))
                    text(20 -2 "2020-2021"                       ,  place(w) size(2.25) color("${ami_m}%75"))
                    text(21 -2 "2022-2023"                       ,  place(w) size(2.25) color("${ami_m}%75"))

                    legend(off)
                    name(length_of_stay_figure1, replace)
                    ;
        #delimit cr	
        graph export "${graphs}/bnrcvd-length-of-stay-figure1.png", replace width(3000)

    ** ---------------------------------------------------------
    ** Export acompanying dataset (XLSX and DTA)
    ** With associated dataset-level and variable-level metadata 
    ** ---------------------------------------------------------
    * Label stata variables
    drop nevent_1yr 
    rename yaxis indicator 
    label var indicator "unique summary measure indicator"
    label var etype "CVD event type (stroke=1, AMI=2, Both=3)"
    label var year2 "CVD event year (2-year intervals)"
    label var sex "female=1, male=2, both=3"
    label var etype "CVD event type (stroke=1, AMI=2)"
    label var year "CVD event year (yyyy)"
    label var sex "female=1, male=2, both=3"
    label var los50 "Length of hospital stay: 50th percentile"
    label var los25 "Length of hospital stay: 25th percentile"
    label var los75 "Length of hospital stay: 75th percentile"
    label var los05 "Length of hospital stay: 5th percentile"
    label var los95 "Length of hospital stay: 95th percentile"
    label var nevent "Number of events"
    replace sex = 3 if sex==. 
    replace etype = 3 if etype==. 
    replace year2 = 0 if year2==. 
    label define sex_ 3 "Both", modify 
    label define etype_ 3 "Both", modify 
    label define year2_ 0 "All years", modify 

    * STATA dataset export 
    notes drop _all 
    label data "BNR-CVD Registry: dataset associated with CVD length-of-stay briefing" 
    note : title("BNR-CVD Length of In-Hospital Stay (Aggregated)") 
    note : version("1.0") 
    note : created("${todayiso}") 
    note : creator("Ian Hambleton, Analyst") 
    note : registry("CVD") 
    note : content("AGGR") 
    note : tier("ANON") 
    note : temporal("2010-01 to 2023-12") 
    note : spatial("Barbados") ///
    note : description("Median length of hospital stay. Cardiovascular admissions place substantial pressure on the health system, not only through the number of events but through the time patients spend in hospital. Length of hospital stay (LOS) reflects severity, access to step-down care, and ward efficiency—all key considerations for service planning. We analysed median LOS (with 25th–75th percentiles) for all stroke and heart attack (acute myocardial infarction, AMI) admissions between 2010 and 2023, using routinely collected hospital data held by the BNR. We summarised trends over time and applied quantile (median) regression, which estimates how the median LOS shifts across groups, to explore differences by event type, sex, and two-year periods.") 
    note : language("en") 
    note : format("Stata 19") 
    note : rights("CC BY 4.0 (Attribution)") 
    note : source("Hospital admissions (QEH)") 
    note : contact("ian.hambleton@gmail.com") 
    note : outfile("./bnrcvd-length-of-stay-figure1.yml")
    save "${graphs}/bnrcvd-length-of-stay-figure1.dta", replace 

    ** Dataset-level metadata using YAML file
    bnryaml using "${graphs}/bnrcvd-length-of-stay-figure1.dta", ///
        title("BNR-CVD Length of In-Hospital Stay (Aggregated)") ///
        version("1.0") ///
        created("${todayiso}") ///
        creator("Ian Hambleton, Analyst") ///
        registry("CVD") ///
        content("AGGR") ///
        tier("ANON") ///
        temporal("2010-01 to 2023-12") ///
        spatial("Barbados") ///
        description("Median length of hospital stay. Cardiovascular admissions place substantial pressure on the health system, not only through the number of events but through the time patients spend in hospital. Length of hospital stay (LOS) reflects severity, access to step-down care, and ward efficiency—all key considerations for service planning. We analysed median LOS (with 25th–75th percentiles) for all stroke and heart attack (acute myocardial infarction, AMI) admissions between 2010 and 2023, using routinely collected hospital data held by the BNR. We summarised trends over time and applied quantile (median) regression, which estimates how the median LOS shifts across groups, to explore differences by event type, sex, and two-year periods.") ///
        language("en") ///
        format("Stata 19") ///
        rights("CC BY 4.0 (Attribution)") ///
        source("Hospital admissions (QEH)") ///
        contact("ian.hambleton@gmail.com") /// 
        outfile("${Pygraphs}/bnrcvd-length-of-stay-figure1.yml")

    ** XLS dataset export 
    export excel using "${graphs}/bnrcvd-length-of-stay-figure1.xlsx", sheet("data") first(var) replace 
    ** Attach meta-data to Excel spreadsheet. Inputs for DO file below
    global meta_xlsx "${Pygraphs}/bnrcvd-length-of-stay-figure1.xlsx"
    global meta_yaml "${Pygraphs}/bnrcvd-length-of-stay-figure1.yml"
    * Do file that adds metadata to excel spreadsheet - python code 
    do "${do}\bnrcvd-meta-xlsx.do"



** FIGURE 2 
use `pid_los', clear
keep if yoe>=2014 

** Hospital days by Event Type and 2-year period 
tempfile nevent1 nevent2
    preserve
        collapse (count) nevent=los_primary if cf==1 , by(etype yoe)
        save `nevent1', replace 
        gen yaxis = _n
        order yaxis etype yoe
        save `nevent1', replace 
    restore

* LoS Summary Metrics for graphic 
* Graphic restricted to those alive at discharge 
* Create aggregrated dataset as a combination of several collapsed datasets 
    tempfile los1
    preserve
        collapse (p50) los50=los_primary (p25) los25=los_primary     ///
                 (p75) los75=los_primary (p5) los05=los_primary     /// 
                 (p95) los95=los_primary if cf==1  , by(etype yoe)
        save `los1', replace 
    restore 

use `los1', clear 
gen yaxis = _n
merge 1:1 yaxis using `nevent1'
drop _merge 
order yaxis etype yoe

** Now calculate the median difference across years for each event type 
** We use 2015 as the baseline comparator  
gen t1 = los50 if yoe==2014
bysort etype : egen median2015 = min(t1) 
drop t1 
sort yaxis
gen exdays = (los50 - median2015) * nevent
gen exday_week = exdays/52
gen zero = 0

** Shift AMI to Lower Axis 
replace exday_week = exday_week - 30 if etype==2 
gen zero_ami = -30

** For reporting on graph  
gen ex50 = round(exdays/52, 0.1)
format ex50 %4.2f
local ex50_str = ex50[10]
global ex50_str : display %4.1f `ex50_str'
local ex50_ami = ex50[20]
global ex50_ami : display %4.1f `ex50_ami'


** FIGURE 2 - CHANGE IN BED DAYS OVER TIME
        #delimit ;
            gr twoway 
                /// Graph Furniture 
                /// 2014 POINT  - STROKE 
                (scatteri 0 2014.6 0 2023.5 , recast(line) lw(0.4) lc("gs0") lp("l"))
                (scatteri 0 2014 , msize(3) mlc("gs0") mlw(0.1) mfc("${str_m}%75") lp("l"))
                /// 2014 POINT  - AMI 
                (scatteri -30 2014.6 -30 2023.5 , recast(line) lw(0.4) lc("gs0") lp("l"))
                (scatteri -30 2014 , msize(3) mlc("gs0") mlw(0.1) mfc("${ami_m}%75") lp("l"))
                /// X-Axis
                (scatteri -15 2014.7 -15 2015.3 , recast(line) lw(0.2) lc("gs6") lp("l"))
                (scatteri -15 2016.7 -15 2017.3 , recast(line) lw(0.2) lc("gs6") lp("l"))
                (scatteri -15 2018.7 -15 2019.3 , recast(line) lw(0.2) lc("gs6") lp("l"))
                (scatteri -15 2020.7 -15 2021.3 , recast(line) lw(0.2) lc("gs6") lp("l"))
                (scatteri -15 2022.7 -15 2023.3 , recast(line) lw(0.2) lc("gs6") lp("l"))
                /// X AXIS LINE
                (scatteri 30 2013.25 -10 2013.25 , recast(line) lw(0.3) lc("${str_m70}") lp("l"))
                (scatteri -20 2013.25 -32 2013.25 , recast(line) lw(0.3) lc("${ami_m70}") lp(""))
                /// RHS SEPARATOR
                (scatteri -28 2024.5 26 2024.5 , recast(line) lw(0.3) lc("gs6") lp("l"))

                /// Stroke LOS Bed Days Change 
                (rbar zero exday_week yoe if etype==1, barw(0.5) lw(none) color("${str_m70}%75"))
                /// AMI LOS Bed Days Change 
                (rbar zero_ami exday_week yoe if etype==2, barw(0.5) lw(none) color("${ami_m70}%75"))
                ,
                    plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin) margin(l=2 r=2 b=0 t=0)) 		
                    graphregion(color(gs16) ic(gs16) ilw(thin) lw(thin) margin(l=2 r=2 b=0 t=0)) 
                    ysize(9) xsize(19)

                    xlab(none, 
                    valuelabel labc(gs0) labs(2.5) notick nogrid angle(45) format(%9.0f))
                    xscale(noline lw(vthin) range(2012.5(0.5)2028)) 
                    xtitle(" ", size(3) color(gs0) margin(l=1 r=1 t=1 b=1)) 
                    
                    ylab(none,
                    labc(gs0) labs(7) tlc(gs8) nogrid angle(0) format(%9.0f))
                    yscale(noline noextend range(-40(1)35)) 
                    ytitle(" ", color(gs8) size(4.5) margin(l=1 r=1 t=1 b=1)) 

                    /// X-AXIS TEXT
                    text(-15 2014 `"{fontface "Montserrat Light": 2014}"' ,  place(c) size(5) color(gs6))
                    text(-15 2016 `"{fontface "Montserrat Light": 2016}"' ,  place(c) size(5) color(gs6))
                    text(-15 2018 `"{fontface "Montserrat Light": 2018}"' ,  place(c) size(5) color(gs6))
                    text(-15 2020 `"{fontface "Montserrat Light": 2020}"' ,  place(c) size(5) color(gs6))
                    text(-15 2022 `"{fontface "Montserrat Light": 2022}"' ,  place(c) size(5) color(gs6))
                    /// Y-AXIS TEXT
                    text( 30 2012.75 `"{fontface "Montserrat Light": 30}"' ,  place(c) size(5) color("${str_m70}"))
                    text( 20 2012.75 `"{fontface "Montserrat Light": 20}"' ,  place(c) size(5) color("${str_m70}"))
                    text( 10 2012.75 `"{fontface "Montserrat Light": 10}"' ,  place(c) size(5) color("${str_m70}"))
                    text( 0 2012.75  `"{fontface "Montserrat Light": 0}"'  ,  place(c) size(5) color("${str_m70}"))
                    text(-20 2012.75 `"{fontface "Montserrat Light": 10}"' ,  place(c) size(5) color("${ami_m70}"))
                    text(-30 2012.75 `"{fontface "Montserrat Light": 0}"'  ,  place(c) size(5) color("${ami_m70}"))

                    /// Title 
                    text(-40 2020 "Extra typical bed-days, Barbados 2014–2023",  place(c) size(4.75) color(gs4))

                    /// (Right hand side) Hospital ETBD/week
                    text(30 2026.5 "Extra Bed Days" ,  place(c) size(5) color("gs4"))
                    text(25 2026.5 "(2023 vs. 2014)"      ,  place(c) size(5) color("gs4"))
                    text(13 2026.5 "${ex50_str}" ,  place(c) size(7) color("${str_m}%75"))
                    text(6 2026.5 "per week" ,  place(c) size(7) color("${str_m}%75"))
                    text(-17 2026.5 "${ex50_ami}" ,  place(c) size(7) color("${ami_m}%75"))
                    text(-24 2026.5 "per week" ,  place(c) size(7) color("${ami_m}%75"))

                    legend(off)

                    name(length_of_stay_figure2, replace)
                    ;
        #delimit cr	
        graph export "${graphs}/bnrcvd-length-of-stay-figure2.png", replace width(3000)

    ** ---------------------------------------------------------
    ** Export acompanying dataset (XLSX and DTA)
    ** With associated dataset-level and variable-level metadata 
    ** ---------------------------------------------------------
    * Label stata variables
    drop median2015 exday_week zero zero_ami ex50 
    rename yaxis indicator 
    label var indicator "unique summary measure indicator"
    label var yoe "CVD event year (yyyy)"
    label var etype "CVD event type (stroke=1, AMI=2)"
    label var los50 "Length of hospital stay: 50th percentile"
    label var los25 "Length of hospital stay: 25th percentile"
    label var los75 "Length of hospital stay: 75th percentile"
    label var los05 "Length of hospital stay: 5th percentile"
    label var los95 "Length of hospital stay: 95th percentile"
    label var nevent "Number of events"
    label var exdays "Extra typical bed-days per year compared to 2014"

    * STATA dataset export 
    notes drop _all 
    label data "BNR-CVD Registry: dataset associated with CVD length-of-stay briefing" 
    note : title("BNR-CVD Extra Typical Bed Day Demand (Aggregated)") 
    note : version("1.0") 
    note : created("${todayiso}") 
    note : creator("Ian Hambleton, Analyst") 
    note : registry("CVD") 
    note : content("AGGR") 
    note : tier("ANON") 
    note : temporal("2014-01 to 2023-12") 
    note : spatial("Barbados") ///
    note : description("Extra typical bed-day demand. Hospital planners need to understand not only how long patients typically stay, but how those stays add up across all admissions to create pressure on bed capacity. A small increase in the typical length of stay can translate into a large number of additional beds needed when multiplied across hundreds of patients. To capture this system-level impact, we created an “extra typical bed-days” metric. This measures how many more bed-days are required today compared with a decade ago, based on changes in the median length of stay and the number of stroke and heart attack admissions. Using routinely collected BNR between 2014 and 2023, we calculated the difference in median length of stay between each year and a 2014 baseline, and multiplied this by the number of events in each year. This approach avoids distortion from rare but very long hospital stays so provides a robust indicator of how routine changes in typical patient care accumulate into real bed pressure over time.") 
    note : language("en") 
    note : format("Stata 19") 
    note : rights("CC BY 4.0 (Attribution)") 
    note : source("Hospital admissions (QEH)") 
    note : contact("ian.hambleton@gmail.com") 
    note : outfile("./bnrcvd-length-of-stay-figure2.yml")
    save "${graphs}/bnrcvd-length-of-stay-figure2.dta", replace 

    ** Dataset-level metadata using YAML file
    bnryaml using "${graphs}/bnrcvd-length-of-stay-figure2.dta", ///
        title("BNR-CVD Extra Typical Bed Day Demand (Aggregated)") ///
        version("1.0") ///
        created("${todayiso}") ///
        creator("Ian Hambleton, Analyst") ///
        registry("CVD") ///
        content("AGGR") ///
        tier("ANON") ///
        temporal("2014-01 to 2023-12") ///
        spatial("Barbados") ///
        description("Extra typical bed-day demand. Hospital planners need to understand not only how long patients typically stay, but how those stays add up across all admissions to create pressure on bed capacity. A small increase in the typical length of stay can translate into a large number of additional beds needed when multiplied across hundreds of patients. To capture this system-level impact, we created an “extra typical bed-days” metric. This measures how many more bed-days are required today compared with a decade ago, based on changes in the median length of stay and the number of stroke and heart attack admissions. Using routinely collected BNR between 2014 and 2023, we calculated the difference in median length of stay between each year and a 2014 baseline, and multiplied this by the number of events in each year. This approach avoids distortion from rare but very long hospital stays so provides a robust indicator of how routine changes in typical patient care accumulate into real bed pressure over time.") ///
        language("en") ///
        format("Stata 19") ///
        rights("CC BY 4.0 (Attribution)") ///
        source("Hospital admissions (QEH)") ///
        contact("ian.hambleton@gmail.com") /// 
        outfile("${Pygraphs}/bnrcvd-length-of-stay-figure2.yml")

    ** XLS dataset export 
    export excel using "${graphs}/bnrcvd-length-of-stay-figure2.xlsx", sheet("data") first(var) replace 
    ** Attach meta-data to Excel spreadsheet. Inputs for DO file below
    global meta_xlsx "${Pygraphs}/bnrcvd-length-of-stay-figure2.xlsx"
    global meta_yaml "${Pygraphs}/bnrcvd-length-of-stay-figure2.yml"
    * Do file that adds metadata to excel spreadsheet - python code 
    do "${do}\bnrcvd-meta-xlsx.do"


** --------------------------------------------------------------
** REPORT: INITIALIAZE
** --------------------------------------------------------------
putpdf clear 
putpdf begin, pagesize(letter)      ///
    font("Montserrat", 9)       ///
    margin(top,0.5cm)               /// 
    margin(bottom,0.25cm)           ///
    margin(left,0.5cm)              ///
    margin(right,0.25cm)            

** REPORT: PAGE 1 
** TITLE, ATTRIBUTION, DATE of CREATION
** --------------------------------------------------------------
    putpdf table intro = (2,12), width(100%) halign(left)    
    putpdf table intro(.,.), border(all, nil)
    putpdf table intro(1,.), font("Montserrat", 8, 000000)  
    putpdf table intro(1,1)
    putpdf table intro(1,2), colspan(11)
    putpdf table intro(2,1), colspan(12)
    putpdf table intro(1,1)=image("${graphs}/uwi_crest_small.jpg")
    putpdf table intro(1,2)=("Hospital Stay among Cardiovascular Patients in Barbados"), /// 
                            halign(left) linebreak font("Montserrat Medium", 12, 000000)
    putpdf table intro(1,2)=("Briefing created by the Barbados National Chronic Disease Registry, "), /// 
                            append halign(left) font("Montserrat", 9, 6d6d6d)
    putpdf table intro(1,2)=("The University of the West Indies. "), halign(left) append font("Montserrat", 9, 6d6d6d) linebreak 
    putpdf table intro(1,2)=("Group Contacts"), /// 
                            halign(left) append italic font("Montserrat", 9, 6d6d6d) 
    putpdf table intro(1,2)=(" ${fisheye} "), /// 
                            halign(left) append font("Montserrat", 9, 6d6d6d) 
    putpdf table intro(1,2)=("Christina Howitt (BNR lead)"), /// 
                            halign(left) append italic font("Montserrat", 9, 6d6d6d) 
    putpdf table intro(1,2)=(" ${fisheye} "), /// 
                            halign(left) append font("Montserrat", 9, 6d6d6d) 
    putpdf table intro(1,2)=("Ian Hambleton (analytics) "), /// 
                            halign(left) append italic font("Montserrat", 9, 6d6d6d) 
    putpdf table intro(1,2)=("${fisheye} Updated on $S_DATE at $S_TIME "), font("Montserrat Medium", 9, 6d6d6d) halign(left) italic append linebreak
    putpdf table intro(2,1)=("${fisheye} For all our surveillance outputs "), /// 
                            halign(left) append font("Montserrat", 10, 434343) 
    putpdf table intro(2,1)=("${fisheye} https://uwi-bnr.github.io/resource-hub/5Downloads/ ${fisheye}"), /// 
                            halign(center) font("Montserrat", 10, 434343) append
                         

** REPORT: PAGE 1 
** WHY THIS MATTERS | WHAT WE DID
** --------------------------------------------------------------
putpdf paragraph ,  font("Montserrat", 1)
#delimit; 
putpdf text ("Why This Matters | What We Did") , font("Montserrat Medium", 11, 000000) linebreak;
putpdf text ("
Cardiovascular admissions place substantial pressure on the health system, not only through the number of events but through the time patients spend in hospital. Length of hospital stay (LOS) reflects severity, access to step-down care, and ward efficiency—all key considerations for service planning. We analysed median LOS (with 25th–75th percentiles) for all stroke and heart attack (acute myocardial infarction, AMI) admissions between 2010 and 2023, using routinely collected hospital data held by the BNR. We summarised trends over time and applied quantile (median) regression, which estimates how the median LOS shifts across groups, to explore differences by event type, sex, and two-year periods.
"), font("Montserrat", 9, 000000) linebreak;
#delimit cr

** REPORT: PAGE 1
** KEY MESSAGE 1
** PATIENTS ARE STAYING LONGER IN HOSPITAL — AND THE GAP IS WIDENING.
** --------------------------------------------------------------
#delimit ; 
putpdf paragraph ,  font("Montserrat", 1);
putpdf text ("Stroke ") , font("Montserrat Medium", 11,  ${str_m70}) ;
putpdf text ("Patients are Staying Longer in Hospital — and the Gap is Widening.") , font("Montserrat Medium", 11, 000000);

** FIGURE 1;
putpdf table f1 = (1,1), width(75%) border(all,nil) halign(center);
putpdf table f1(1,1)=image("${graphs}/bnrcvd-length-of-stay-figure1.png");
#delimit cr

** REPORT: PAGE 1
** WHAT THIS MEANS
** --------------------------------------------------------------
#delimit ; 

putpdf paragraph ,  font("Montserrat", 1);
putpdf text ("Key Messages | What This Means") , font("Montserrat Medium", 11, 000000) linebreak ;
putpdf text ("
Stroke patients consistently spend longer in hospital than those admitted with heart attacks, and this gap has widened steadily over the past decade. In 2022–23, the median length of stay for stroke reached around 8–9 days (IQR typically 4–15 days), compared with 5–6 days for heart attacks (IQR about 3–8 days). Median regression shows that stroke stays have been rising by around half 
"), font("Montserrat", 9, 000000);

putpdf paragraph ,  font("Montserrat", 10) halign(right);
putpdf text ("Next Page") , font("Montserrat Medium", 10, 000000)  ;
#delimit cr



** REPORT: PAGE 2
** --------------------------------------------------------------
#delimit ; 

putpdf paragraph ,  font("Montserrat", 1);
putpdf text ("
a day every two years, while heart attack stays have remained stable. Differences between women and men are small for both conditions. Together, these findings show that increasing hospital time is concentrated among stroke patients, highlighting the importance of strengthening early mobilisation, rehabilitation access, and discharge planning to reduce bed pressures and support recovery.
"), font("Montserrat", 9, 000000);

putpdf paragraph ,  font("Montserrat", 1);
putpdf text ("Translating Hospital Stays into Demand for Hospital Beds") , font("Montserrat Medium", 11, 000000) linebreak;
putpdf text ("
Hospital planners need to understand not only how long patients typically stay, but how those stays add up across all admissions to create pressure on bed capacity. A small increase in the typical length of stay can translate into a large number of additional beds needed when multiplied across hundreds of patients. To capture this system-level impact, we created an “extra typical bed-days” metric. This measures how many more bed-days are required today compared with a decade ago, based on changes in the median length of stay and the number of stroke and heart attack admissions. Using routinely collected BNR between 2014 and 2023, we calculated the difference in median length of stay between each year and a 2014 baseline, and multiplied this by the number of events in each year. This approach avoids distortion from rare but very long hospital stays so provides a robust indicator of how routine changes in typical patient care accumulate into real bed pressure over time.
"), font("Montserrat", 9, 000000) linebreak;
#delimit cr


#delimit ; 
** FIGURE 2. XX;
putpdf paragraph ,  font("Montserrat", 1);
putpdf text ("Rising Bed-Day Demand from Longer ") , font("Montserrat Medium", 11, 000000) ;
putpdf text ("Stroke ") , font("Montserrat Medium", 11,  ${str_m70}) ;
putpdf text ("Stays | ") , font("Montserrat Medium", 11, 000000) ;
putpdf text ("Heart Attack ") , font("Montserrat Medium", 11,  ${ami_m70}) ;
putpdf text ("Stays Hold Steady.") , font("Montserrat Medium", 11, 000000) ;

putpdf table f1 = (1,1), width(100%) border(all,nil) halign(center);
putpdf table f1(1,1)=image("${graphs}/bnrcvd-length-of-stay-figure2.png");
putpdf paragraph ,  font("Montserrat", 1);
putpdf text ("Key Messages | What This Means ") , font("Montserrat Medium", 11, 000000) linebreak;
putpdf text ("
The extra typical bed-days metric shows how changes in typical length of stay and the number of admissions combine to create real pressure on hospital capacity. Compared with 2014, stroke admissions in 2023 generated around 1,372 additional typical bed-days, equivalent to almost 4 extra beds occupied every day of the year. This increase arises from both a higher median length of stay and a sustained volume of stroke admissions, meaning that even modest shifts in typical stay length compound into substantial demand at the system level. In contrast, heart attack admissions contribute only a small and fairly consistent increase in typical bed-day demand when comparing each year to 2014, adding modest pressure but without the escalating pattern seen in stroke.

For hospital planners, these findings demonstrate how rising bed-day demand accumulates invisibly in routine flow, stretching capacity even when total admission numbers change little year to year. Strengthening early supported discharge, improving access to step-down care, and ensuring timely rehabilitation will be essential to prevent these additional pressures from becoming enduring constraints on hospital throughput.
"), font("Montserrat", 9, 000000);
#delimit cr

** PDF SAVE
** --------------------------------------------------------------
    putpdf save "${outputs}/bnr-cvd-length-of-stay-2023", replace

