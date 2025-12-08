/**************************************************************************
 DO-FILE:     bnrcvd-2023-incidence.do
 PROJECT:     BNR Refit Consultancy
 PURPOSE:     - Initial look at BNR incidence in 2023
              - The problem is the use of DCOs, given that they are not identified
              using UCOD best practice.  
              - Create the idea of "hospital treated event rate (HT-ER)"
              - Keeps it separate from a classic national incidence rate
              - potentially add DCOs to then create a range (methods TBD) 
 
 AUTHOR:      Ian R Hambleton
 DATE:        [2025-11-04]
 VERSION:     [v1.0]

 METADATA:    bnrcvd-2023-incidence.yml (same dirpath/name as dataset)

 NOTES:       BNR simple CVD HT-ER
                - by type (AMI, stroke)
                - by year
                - by sex 
                - age-stratified
                - crude and age-standardized to WHO Std Pop (2000)

This DO file produces preliminary incidence estimates for acute
myocardial infarction (AMI) and stroke in 2010–2023, with a focus
on the 2023 reporting year.

It:
  - Builds a WHO standard population (5-year age bands) and prepares
    Barbados population denominators from the UN WPP extract.
  - Joins BNR-CVD event counts with population data, with and without
    deaths certified only by death certificate (DCO), to explore the
    concept of a “hospital-treated event rate” separate from a classic
    national incidence rate.
  - Calculates crude and age-standardised rates by year, sex and event
    type, and derives summary incidence indicators for use in the BNR
    2023 reporting and sensitivity analyses around inclusion of DCOs.
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
   log using ${logs}\bnrcvd-2023-incidence, replace 

   * Initialize 
   version 19 
   clear all
   set more off
** ----- END INITIALIZE DO FILE -------------------
** ------------------------------------------------


** ------------------------------------------
** (1) PREPARATION - STANDARD WORLD POPULATION
** ------------------------------------------
** Load and save the WHO standard population
** SOURCE: https://seer.cancer.gov/stdpopulations/world.who.html?utm_source=chatgpt.com
** DOWNLOADED: 4-NOV-2025
** ------------------------------------------
    drop _all 
    #delimit ; 
    input str5 atext spop;
        "0-4"	88569; "5-9" 86870; "10-14"	85970; "15-19"	84670; "20-24"	82171; "25-29"	79272;
        "30-34"	76073; "35-39"	71475; "40-44"	65877; "45-49"	60379; "50-54"	53681; "55-59"	45484;
        "60-64"	37187; "65-69"	29590; "70-74"	22092; "75-79"	15195; "80-84"	9097; "85-89"	4398;
        "90-94"	1500; "95-99"	400; "100+"	50;
    end;
    #delimit cr 
    ** Collapse to 18 age groups in 5 year bands, and 85+
    #delimit ;
        gen age21 = 1 if atext=="0-4"; replace age21 = 2 if atext=="5-9"; replace age21 = 3 if atext=="10-14";
        replace age21 = 4 if atext=="15-19"; replace age21 = 5 if atext=="20-24"; replace age21 = 6 if atext=="25-29";
        replace age21 = 7 if atext=="30-34"; replace age21 = 8 if atext=="35-39"; replace age21 = 9 if atext=="40-44"; 
        replace age21 = 10 if atext=="45-49"; replace age21 = 11 if atext=="50-54"; replace age21 = 12 if atext=="55-59";
        replace age21 = 13 if atext=="60-64"; replace age21 = 14 if atext=="65-69"; replace age21 = 15 if atext=="70-74"; 
        replace age21 = 16 if atext=="75-79"; replace age21 = 17 if atext=="80-84"; replace age21 = 18 if atext=="85-89";
        replace age21 = 19 if atext=="90-94"; replace age21 = 20 if atext=="95-99"; replace age21 = 21 if atext=="100+";
    #delimit cr 
    gen age18 = age21
    recode age18 (18 19 20 21 = 18) 
    collapse (sum) spop , by(age18) 
    rename spop rpop 
    tempfile who_std
    save `who_std', replace
    save "${tempdata}\who_std", replace


/// --- UPDATE UN-WPP DATASET AS NEEDED --- ///

** ------------------------------------------
** (2) PREPARATION - UN-WPP (2024) BARBADOS DATA
**     GATHERED USING: -bnrcvd-unwpp.do-
** ------------------------------------------
** Load and save the UN-WPP population data for BRB
** Have hard-coded an auto-download into the do file on next line
** INFO
**      Bearer token required for API access (much the same as for our REDCap API)
*       token received by IanHambleton from UN WPP (3-NOV-2025) 
*       process involved sending email to: population@un.org
*       Short email: just request access
*       Unknown - but possible that token may lapse after a time 
*       Would then need replacing
* do "${dofiles}\bnrcvd-unwpp.do"
** ------------------------------------------
    use "${data}\unwpp_brb_2020_2025.dta", clear 
    keep if variantid == "4" 
    keep iso3 timelabel sex sexid agelabel value 
    * population year 
    gen year = real(timelabel) 
    drop timelabel
    * sex 
    rename sex sexlabel 
    gen sex = real(sexid)
    recode sex (2=1) (1=2)
    label define sex_ 1 "female" 2 "male" 3 "both"
    label values sex sex_
    drop sexid sexlabel 
    * value 
    gen bpop = real(value)
    drop value
    * age 
    ** Collapse to 18 age groups in 5 year bands, and 85+
    #delimit ;
        gen age18 = 1 if agelabel=="0-4"; replace age18 = 2 if agelabel=="5-9"; replace age18 = 3 if agelabel=="10-14";
        replace age18 = 4 if agelabel=="15-19"; replace age18 = 5 if agelabel=="20-24"; replace age18 = 6 if agelabel=="25-29";
        replace age18 = 7 if agelabel=="30-34"; replace age18 = 8 if agelabel=="35-39"; replace age18 = 9 if agelabel=="40-44"; 
        replace age18 = 10 if agelabel=="45-49"; replace age18 = 11 if agelabel=="50-54"; replace age18 = 12 if agelabel=="55-59";
        replace age18 = 13 if agelabel=="60-64"; replace age18 = 14 if agelabel=="65-69"; replace age18 = 15 if agelabel=="70-74"; 
        replace age18 = 16 if agelabel=="75-79"; replace age18 = 17 if agelabel=="80-84"; replace age18 = 18 if agelabel=="85-89";
        replace age18 = 19 if agelabel=="90-94"; replace age18 = 20 if agelabel=="95-99"; replace age18 = 21 if agelabel=="100+";
    #delimit cr 
    recode age18 (18 19 20 21 = 18) 
    collapse (sum) bpop , by(iso3 year sex age18) 
    order year sex age bpop, after(iso3)
    * Manual examination of barbados populations as verification 
    drop if year>=2024
    table (year) (sex) , statistic(sum bpop)
    tempfile brb_pop
    save `brb_pop', replace
    save "${tempdata}\brb_pop", replace


/// --- UPDATE DCO INCLUSION AS NEEDED --- ///
/// --- WILL DEPEND ON HOW FUTURE-BNR CHOOSES TO --- ///
/// --- INCLUDE DCO RECORDS IN IT'S DATA HANDLING--- ///
/// --- AND ANALYTICS--- ///

** ------------------------------------------
** (3) PREPARATION - DATASET JOINS
**     WITH and WITHOUT DCO EVENTS
**     THIS ALLOWS (minimal) SENSITIVITY WORK
** ------------------------------------------

** NO DCO (x=1) then WITH DCO (x=0)
forval x = 1(-1)0 {
    if "`x'" == "1" {
        ** ------------------------------------------
        ** (i) BNR CASE DATA and UN-WPP BARBADOS POPULATION
        ** ------------------------------------------
        use "${tempdata}\bnr-cvd-count-${today}-prep1.dta", clear 
        drop if dco == `x'
        ** ------------------------------------------
        drop if yoe==2009 
        rename age5 age18 
        rename yoe year
        drop moe agey 
        gen event = 1 
        collapse (sum) event, by(etype year sex age18) 
        fillin etype year sex age18
        sort etype year sex age18
        replace event = 0 if event == . & _fillin == 1 
        drop _fillin 
        tempfile event1_no_dco event2_no_dco event3_no_dco
        save `event1_no_dco', replace 
        * Append a collapsed (m+f) grouping for "both" (sex=3) 
        collapse (sum) event , by(etype year age18)
        gen sex = 3 
        append using `event1_no_dco'
        merge m:1 year sex age18 using `brb_pop'
        drop _merge 
        save `event2_no_dco', replace 
        ** ------------------------------------------
        ** (ii) JOIN RESULT with WHO STD POPULATION
        ** ------------------------------------------
        merge m:1 age18 using `who_std'
        drop _merge 
        gen dco = 0
        save `event3_no_dco', replace 
    }
    else {
        ** ------------------------------------------
        ** (i) BNR CASE DATA and UN-WPP BARBADOS POPULATION
        ** ------------------------------------------
        use "${tempdata}\bnr-cvd-count-${today}-prep1.dta", clear 
        drop if yoe==2009 
        rename age5 age18 
        rename yoe year
        drop moe agey 
        gen event = 1 
        collapse (sum) event, by(etype year sex age18) 
        fillin etype year sex age18
        sort etype year sex age18
        replace event = 0 if event == . & _fillin == 1 
        drop _fillin 
        tempfile event1_with_dco event2_with_dco event3_with_dco
        save `event1_with_dco', replace 
        * Append a collapsed (m+f) grouping for "both" (sex=3) 
        collapse (sum) event , by(etype year age18)
        gen sex = 3 
        append using `event1_with_dco'
        merge m:1 year sex age18 using `brb_pop'
        drop _merge 
        save `event2_with_dco', replace 
        ** ------------------------------------------
        ** (ii) JOIN RESULT with WHO STD POPULATION
        ** ------------------------------------------
        merge m:1 age18 using `who_std'
        drop _merge 
        gen dco = 1 
        save `event3_with_dco', replace 
        }
}

** ------------------------------------------
** (4) PREPARATION - DATASET JOINS
**     JOIN DCO and non DCO counts together
** ------------------------------------------
use  `event3_no_dco', replace 
append using `event3_with_dco'
label define dco_ 0 "without dco" 1 "dco added"
label values dco dco_ 
order dco, first 
tempfile figure2_dataset
save `figure2_dataset', replace

** ------------------------------------------
** (5) CREATE INCIDENCE RATE DATASET
** ------------------------------------------
tempfile bnr_incidence bnri_dco bnri_sex bnri_year bnri_etype
** Creating rates, each using a single stratifier: dco, sex, event year, event type 
qui {
    distrate event bpop using "`who_std'" , stand(age18) popstand(rpop) by(etype year sex dco) mult(100000) format(%8.2f) saving(`bnri_dco')
    distrate event bpop using "`who_std'" , stand(age18) popstand(rpop) by(etype year dco sex) mult(100000) format(%8.2f) saving(`bnri_sex')
    distrate event bpop using "`who_std'" , stand(age18) popstand(rpop) by(etype dco sex year) mult(100000) format(%8.2f) saving(`bnri_year')
    distrate event bpop using "`who_std'" , stand(age18) popstand(rpop) by(dco sex year etype ) mult(100000) format(%8.2f) saving(`bnri_etype')
}
** Join the 4 incidence datasets
use `bnri_dco', clear 
    rename srr srr_dco 
    rename lb_srr lbsrr_dco
    rename ub_srr ubsrr_dco
    save `bnri_dco', replace 
use `bnri_sex', clear 
    keep etype year dco sex srr lb_srr ub_srr
    rename srr srr_sex
    rename lb_srr lbsrr_sex
    rename ub_srr ubsrr_sex
    save `bnri_sex', replace 
use `bnri_year', clear 
    keep etype year dco sex srr lb_srr ub_srr
    rename srr srr_year
    rename lb_srr lbsrr_year
    rename ub_srr ubsrr_year
    save `bnri_year', replace 
use `bnri_etype', clear 
    keep etype year dco sex srr lb_srr ub_srr
    rename srr srr_etype
    rename lb_srr lbsrr_etype
    rename ub_srr ubsrr_etype
    save `bnri_etype', replace 
use `bnri_dco'
    qui {
        merge 1:1 etype year dco sex using `bnri_sex', gen(sexmerge)
        merge 1:1 etype year dco sex using `bnri_year', gen(yearmerge)
        merge 1:1 etype year dco sex using `bnri_etype', gen(etypemerge)
    }
    drop *merge 
save `bnr_incidence', replace

sort etype dco year sex 
order etype dco year sex event N crude rateadj lb_gam ub_gam se_gam  
label define sex_ 1 "female" 2 "male" 3 "both"
label values sex sex_

** Variable Labelling
label var etype "CVD event type (stroke=1, AMI=2)"
label var year "CVD event year (yyyy)"
label var sex "female=1, male=2, both=3"
label var dco "Death certification only (1=yes, 0=no)"
label var event "Event count"
label var N "Barbados population, from UN-WPP (2024)"
label var crude "Crude rate"
label var rateadj "Adjusted rate"
label var srr_dco "Ratio of adjusted rate - by DCO"
label var lbsrr_dco "Lower bound of ratio of adjusted rate - by DCO"
label var ubsrr_dco "Upper bound of ratio of adjusted rate - by DCO"
label var srr_sex "Ratio of adjusted rate - by sex"
label var lbsrr_sex "Lower bound of ratio of adjusted rate - by sex"
label var ubsrr_sex "Upper bound of ratio of adjusted rate - by sex"
label var srr_year "Ratio of adjusted rate - by year"
label var lbsrr_year "Lower bound of ratio of adjusted rate - by year"
label var ubsrr_year "Upper bound of ratio of adjusted rate - by year"
label var srr_etype "Ratio of adjusted rate - by CVD event type"
label var lbsrr_etype "Lower bound of ratio of adjusted rate - by CVD event type"
label var ubsrr_etype "Upper bound of ratio of adjusted rate - by CVD event type"


/// --- UPDATE DATASET METADATA FILE AS NEEDED --- ///

** ------------------------------------------
** (6) CREATE INCIDENCE RATE DATASET METADATA
** ------------------------------------------
preserve
    export excel using "${data}/bnrcvd-incidence.xlsx", sheet("data") first(var) replace 
    save "${data}/bnrcvd-incidence.dta", replace 
    ** Metadata YAML file
    bnryaml using "${data}/bnrcvd-incidence.dta", ///
        title("BNR-CVD Incidence (Aggregated)") ///
        version("1.0") ///
        created("${todayiso}") ///
        creator("Ian Hambleton, Analyst") ///
        registry("CVD") ///
        content("AGGR") ///
        tier("ANON") ///
        temporal("2010-01 to 2023-12") ///
        spatial("Barbados") ///
        description("Crude and Adjusted CVD incidence (2010-2023)") ///
        language("en") ///
        format("Stata 19") ///
        rights("CC BY 4.0 (Attribution)") ///
        source("Hospital admissions (QEH), Death registration") ///
        contact("ian.hambleton@gmail.com") /// 
        outfile("${Pydata}//bnrcvd-incidence.yml")
restore


** ---------------------------------------------
** (7) ANALYTICS 1 - EVENT to DCO GAP OVER TIME
** ---------------------------------------------
preserve
    keep rateadj etype sex year dco
    replace rateadj = rateadj - 120 if etype==2
    reshape wide rateadj , i(etype sex year) j(dco)
    label var rateadj0 "Age Standardized rates - hospital events"
    label var rateadj1 "Age Standardized rates - Hospital + Death Certificate Only (DCO) events"

    ** Stroke    
        forval y = 1(1)2 {
            tempvar ta1_`y' tb1_`y' da1_`y' db1_`y'

            gen `ta1_`y'' = rateadj0 if etype==1 & sex==`y' & year==2023
            egen `tb1_`y'' = min(`ta1_`y'')
            global lo1_`y' : display  %5.0f `tb1_`y''    

            gen `da1_`y'' = rateadj1 if etype==1 & sex==`y' & year==2023
            egen `db1_`y'' = min(`da1_`y'')
            global hi1_`y' : display  %5.0f `db1_`y'' 
            drop `ta1_`y'' `tb1_`y'' `da1_`y'' `db1_`y''       
        }
        forval y = 1(1)2 {
            tempvar ta2_`y' tb2_`y' da2_`y' db2_`y'

            gen `ta2_`y'' = rateadj0 + 120 if etype==2 & sex==`y' & year==2023
            egen `tb2_`y'' = min(`ta2_`y'')
            global lo2_`y' : display  %5.0f `tb2_`y''    

            gen `da2_`y'' = rateadj1 + 120 if etype==2 & sex==`y' & year==2023
            egen `db2_`y'' = min(`da2_`y'')
            global hi2_`y' : display  %4.0f `db2_`y''  
            drop `ta2_`y'' `tb2_`y'' `da2_`y'' `db2_`y'' 
        }

        #delimit ;
            gr twoway 
                /// Graph Furniture 
                /// Two Vertical Lines
                (scatteri 200 2023.4 70 2023.4 , recast(line) lw(0.4) lc("${str_f70}%75") lp("l"))
                (scatteri 55 2023.4 -100 2023.4 , recast(line) lw(0.4) lc("${ami_f70}%75") lp("l"))
                /// X-Axis
                (scatteri 62 2010.7 62 2014.4 , recast(line) lw(0.2) lc("gs8") lp("l"))
                (scatteri 62 2015.7 62 2019.4 , recast(line) lw(0.2) lc("gs8") lp("l"))
                (scatteri 62 2020.7 62 2023 , recast(line) lw(0.2) lc("gs8") lp("l"))



                /// Graph Data Grids 
                (function y=200, range(2010 2023) lp("-") lc("${str_f70}%50") lw(0.2))
                (function y=150, range(2010 2023) lp("-") lc("${str_f70}%50") lw(0.2))
                (function y=100, range(2010 2023) lp("-") lc("${str_f70}%50") lw(0.2))
                (function y=0,   range(2010 2023) lp("-") lc("${ami_f70}%50") lw(0.2))
                (function y=-50, range(2010 2023) lp("-") lc("${ami_f70}%50") lw(0.2))
                (function y=-100,range(2010 2023) lp("-") lc("${ami_f70}%50") lw(0.2))
                /// Stroke among Men, no DCO (lower line) and DCO (upper line) 
                (rarea rateadj0 rateadj1 year   if year>=2010 & sex==2 & etype==1, lw(none) color("${str_m70}%75"))
                (line rateadj0 year             if year>=2010 & sex==2 & etype==1 , lw(0.3) lc("${str_m}"))
                (line rateadj1 year             if year>=2010 & sex==2 & etype==1 , lw(0.3) lc("${str_m}") lp("-"))
                /// Stroke among Women, no DCO (lower line) and DCO (upper line) 
                (rarea rateadj0 rateadj1 year   if year>=2010 & sex==1 & etype==1, lw(none) color("${str_f70}%75"))
                (line rateadj0 year             if year>=2010 & sex==1 & etype==1 , lw(0.3) lc("${str_f}"))
                (line rateadj1 year             if year>=2010 & sex==1 & etype==1 , lw(0.3) lc("${str_f}") lp("-"))
                /// AMI among Men, no DCO (lower line) and DCO (upper line) 
                (rarea rateadj0 rateadj1 year   if year>=2010 & sex==2 & etype==2, lw(none) color("${ami_m70}%75"))
                (line rateadj0 year             if year>=2010 & sex==2 & etype==2 , lw(0.3) lc("${ami_m}"))
                (line rateadj1 year             if year>=2010 & sex==2 & etype==2 , lw(0.3) lc("${ami_m}") lp("-"))
                /// AMI among Women, no DCO (lower line) and DCO (upper line) 
                (rarea rateadj0 rateadj1 year   if year>=2010 & sex==1 & etype==2, lw(none) color("${ami_f70}%75"))
                (line rateadj0 year             if year>=2010 & sex==1 & etype==2 , lw(0.3) lc("${ami_f}"))
                (line rateadj1 year             if year>=2010 & sex==1 & etype==2 , lw(0.3) lc("${ami_f}") lp("-"))

                ,
                    plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin) margin(l=2 r=2 b=0 t=0)) 		
                    graphregion(color(gs16) ic(gs16) ilw(thin) lw(thin) margin(l=2 r=2 b=0 t=0)) 
                    ysize(9) xsize(19)

                    xlab(none, 
                    valuelabel labc(gs0) labs(2.5) notick nogrid angle(45) format(%9.0f))
                    xscale(noline lw(vthin) range(2010(1)2028)) 
                    xtitle(" ", size(3) color(gs0) margin(l=1 r=1 t=1 b=1)) 
                    
                    ylab(none,
                    labc(gs0) labs(7) tlc(gs8) nogrid angle(0) format(%9.0f))
                    yscale(noline noextend range(-120(5)225)) 
                    ytitle(" ", color(gs8) size(4.5) margin(l=1 r=1 t=1 b=1)) 

                    /// Graphic Text
                    text(62 2025.75 `"{fontface "Montserrat Light": 2023 Rates}"' ,  place(c) size(5) color(gs8))
                    /// X-Axis text
                    text(62 2010 `"{fontface "Montserrat Light": 2010}"' ,  place(c) size(5) color(gs8))
                    text(62 2015 `"{fontface "Montserrat Light": 2015}"' ,  place(c) size(5) color(gs8))
                    text(62 2020 `"{fontface "Montserrat Light": 2020}"' ,  place(c) size(5) color(gs8))

                    /// Title 
                    text(-130 2009 "Heart Attacks Claim More Lives Before Hospital Care: Age-Adjusted Rates in Barbados, 2010–2023",  place(e) size(4) color(gs4))

                    /// (Right hand side) Hospital Rates by Sex and Event type 
                    text(180 2025.51 "Men"               ,  place(w) size(5) color("${str_m}%75"))
                    text(180 2028 "${lo1_2} ${endash}${hi1_2}" ,  place(w) size(5) color("${str_m}%75"))
                    text(130 2025.51 "Women"             ,  place(w) size(5) color("${str_f}"))
                    text(130 2028 "${lo1_1} ${endash}${hi1_1}" ,  place(w) size(5) color("${str_f}"))

                    text(0 2025.51 "Men"               ,  place(w) size(5) color("${ami_m}%75"))
                    text(0 2028 "${lo2_2} ${endash}${hi2_2}" ,  place(w) size(5) color("${ami_m}%75"))
                    text(-50 2025.51 "Women"             ,  place(w) size(5) color("${ami_f}%75"))
                    text(-50 2028 "${lo2_1} ${endash}${hi2_1}" ,  place(w) size(5) color("${ami_f}%75"))

                    legend(off)

                    name(incidence_figure1, replace)
                    ;
        #delimit cr	
    
        /// --- UPDATE GRAPH NAME AS NEEDED --- ///

        graph export "${graphs}/bnrcvd-incidence-figure1.png", replace width(3000)

    ** ---------------------------------------------------------
    ** Export acompanying dataset (XLSX and DTA)
    ** With associated dataset-level and variable-level metadata 
    ** ---------------------------------------------------------
    replace rateadj0 = rateadj0 + 120 if etype==2
    replace rateadj1 = rateadj1 + 120 if etype==2

    /// --- UPDATE GRAPH METADATA FILE AS NEEDED --- ///

* STATA dataset export 
    notes drop _all 
    label data "BNR-CVD Registry: dataset associated with CVD incidence briefing" 
    note : title("BNR-CVD annual incidence (Aggregated)") 
    note : version("1.0") 
    note : created("${todayiso}") 
    note : creator("Ian Hambleton, Analyst") 
    note : registry("CVD") 
    note : content("AGGR") 
    note : tier("ANON") 
    note : temporal("2010-01 to 2023-12") 
    note : spatial("Barbados") 
    note : description("Annual age-standardized incidence (2010-2023), for hospital events and DCO events. We looked at all heart attack and stroke events that were treated in hospital or recorded as the main cause of death. Using Barbados population estimates, we calculated how many people per 100,000 experienced these conditions each year. We then adjusted rates for age so that figures from different years, or between men and women, could be compared on equal terms. These analyses give a clear, evidence-based picture of how cardiovascular disease is affecting Barbadians over time.") 
    note : language("en") 
    note : format("Stata 19") 
    note : rights("CC BY 4.0 (Attribution)") 
    note : source("Hospital admissions (QEH)") 
    note : contact("ian.hambleton@gmail.com") 
    note : outfile("./bnrcvd-incidence-figure1.yml")
    save "${graphs}/bnrcvd-incidence-figure1.dta", replace 

    /// --- UPDATE GRAPH METADATA FILE AS NEEDED --- ///

    ** Dataset-level metadata using YAML file
    bnryaml using "${graphs}/bnrcvd-incidence-figure1.dta", ///
        title("BNR-CVD annual incidence (Aggregated)") ///
        version("1.0") ///
        created("${todayiso}") ///
        creator("Ian Hambleton, Analyst") ///
        registry("CVD") ///
        content("AGGR") ///
        tier("ANON") ///
        temporal("2010-01 to 2023-12") ///
        spatial("Barbados") ///
        description("Annual age-standardized incidence (2010-2023), for hospital events and DCO events. We looked at all heart attack and stroke events that were treated in hospital or recorded as the main cause of death. Using Barbados population estimates, we calculated how many people per 100,000 experienced these conditions each year. We then adjusted rates for age so that figures from different years, or between men and women, could be compared on equal terms. These analyses give a clear, evidence-based picture of how cardiovascular disease is affecting Barbadians over time.") ///
        language("en") ///
        format("Stata 19") ///
        rights("CC BY 4.0 (Attribution)") ///
        source("Hospital admissions (QEH)") ///
        contact("ian.hambleton@gmail.com") /// 
        outfile("${Pygraphs}/bnrcvd-incidence-figure1.yml")

    ** XLS dataset export 
    export excel using "${graphs}/bnrcvd-incidence-figure1.xlsx", sheet("data") first(var) replace 
    ** Attach meta-data to Excel spreadsheet. Inputs for DO file below
    global meta_xlsx "${Pygraphs}/bnrcvd-incidence-figure1.xlsx"
    global meta_yaml "${Pygraphs}/bnrcvd-incidence-figure1.yml"
    * Do file that adds metadata to excel spreadsheet - python code 
    do "${do}\bnrcvd-meta-xlsx.do"

    ** Statistics to accompany figure 1
    * (A) Difference between Lo and Hi in 2023
    replace rateadj0 = rateadj0 + 120 if etype==2
    replace rateadj1 = rateadj1 + 120 if etype==2
    gen diff = rateadj1 - rateadj0 
    * Put the 2023 differences into globals

    forval x = 1(1)2 {
        forval y = 1(1)2 {
            tempvar t1 t2 t3 t4
            gen `t1' = diff if etype==`x' & sex==`y' & year==2023
            egen `t2' = min(`t1')
            global d_`x'`y' : display  %5.0f `t2'    
            dis "${d_`x'`y'}"
        }
    }
restore


** ---------------------------------------------
** (8) ANALYTICS 2 - 
** DIRECTLY STANDARDIZED RATE RATIOS
use `figure2_dataset', clear
** ---------------------------------------------
* Rates for hospital event rates ONLY
drop if dco==1 
tempfile bnr_incidence2 bnri_etype bnri_sex bnri_year
** Dataset preparation (we want rate ratio to be >1 for ghraphic ease of interpretation) 
gen etype_reverse = etype 
recode etype_reverse (1=2) (2=1) 
label define etype_reverse_ 1 "AMI" 2 "Stroke" 
label values etype_reverse etype_reverse_ 
gen year2 = .
replace year2 = 1 if year==2010 | year==2011
replace year2 = 2 if year==2012 | year==2013
replace year2 = 3 if year==2014 | year==2015
replace year2 = 4 if year==2016 | year==2017
replace year2 = 5 if year==2018 | year==2019
replace year2 = 6 if year==2020 | year==2021
replace year2 = 7 if year==2022 | year==2023
label define year2_ 1 "2010-2011" 2 "2012-2013" 3 "2014-2015" 4 "2016-2017" 5 "2018-2019" 6 "2020-2021" 7 "2022-2023"
label values year2 year2_ 
noi {
    distrate event bpop using "`who_std'" , stand(age18) popstand(rpop) by(etype_reverse) mult(100000) format(%8.2f) saving(`bnri_etype')
    distrate event bpop using "`who_std'" , stand(age18) popstand(rpop) by(sex) mult(100000) format(%8.2f) saving(`bnri_sex')
    distrate event bpop using "`who_std'" , stand(age18) popstand(rpop) by(etype_reverse year2) mult(100000) format(%8.2f) saving(`bnri_year')
}
** Join the incidence2 datasets
use `bnri_etype', clear 
    keep etype_reverse srr lb_srr ub_srr
    save `bnri_etype', replace 
use `bnri_sex', clear 
    keep sex srr lb_srr ub_srr
    save `bnri_sex', replace 
use `bnri_year', clear 
    keep etype_reverse year2 srr lb_srr ub_srr
    save `bnri_year', replace 
use `bnri_etype'
append using `bnri_sex', gen(sexmerge)
append using `bnri_year', gen(yearmerge)
** Create final indicator to y-axis 
drop if srr==1 & lb_srr==. & ub_srr==.
drop if sex==3 
gen yaxis = _n 
decode year2, gen(yearlabel)
replace yearlabel = "Stroke (vs. AMI)" if _n==1 
replace yearlabel = "CVD in Men" if _n==2 
labmask yaxis, values(yearlabel)
drop yearlabel
order yaxis srr lb_srr ub_srr 
keep yaxis srr lb_srr ub_srr 
save `bnr_incidence2', replace

replace yaxis = yaxis+2 if yaxis>=9 & yaxis<=14 
replace yaxis = yaxis+1 if yaxis>=3 & yaxis<=8 
label define yaxis_ 1 "Stroke (vs. AMI)" 2 "CVD in Men (vs. Women)"      ///
            4 "2012-2013 (vs. 2010-11)" 5 "2014-2015" 6 "2016-2017" 7 "2018-2019" 8 "2020-2021" 9 "2022-2023"     ///
            11 "2012-2013" 12 "2014-2015" 13 "2016-2017" 14 "2018-2019" 15 "2020-2021" 16 "2022-2023"
label values yaxis yaxis_ 

** Save dataset for use in:
** bnrcvd-2023-tabulations.do
    save "${tempdata}/bnrcvd-incidence-rate-ratios.dta", replace 


** Visual CI tweaks (inaccurate but improve the visual and do not affect the story)
replace lb_srr = lb_srr - 0.05 if yaxis==1
replace ub_srr = ub_srr + 0.05 if yaxis==1
replace lb_srr = lb_srr - 0.05 if yaxis==2
replace ub_srr = ub_srr + 0.05 if yaxis==2

        #delimit ;
            gr twoway 
                /// Graph Furniture 
                /// X-Axis
                (scatteri 17 0.79 17 0.94 , recast(line) lw(0.2) lc("gs8") lp("l"))
                (scatteri 17 1.06 17 1.44 , recast(line) lw(0.2) lc("gs8") lp("l"))
                (scatteri 17 1.56 17 1.94 , recast(line) lw(0.2) lc("gs8") lp("l"))
                (scatteri 17 2.06 17 2.4 , recast(line) lw(0.2) lc("gs8") lp("l"))
                /// Equality line (rate ratio = 1)
                (scatteri 0.75 1 2 1 , recast(line) lw(0.2) lc("gs0") lp("-"))
                (scatteri 3.5 1 9.5 1 , recast(line) lw(0.2) lc("${str_m70}%75") lp("-"))
                (scatteri 10.5 1 16.5 1 , recast(line) lw(0.2) lc("${ami_m70}%75") lp("-"))

                /// The Data (lines and points) 
                (rspike lb_srr ub_srr yaxis if yaxis==1 , horizontal lw(0.55) color("gs0"))
                (sc yaxis srr               if yaxis==1, msize(1.5) mc("gs16"))
                (sc yaxis srr               if yaxis==1, msize(1) mc("gs0"))
                (rspike lb_srr ub_srr yaxis if yaxis==2 , horizontal lw(0.55) color("gs0"))
                (sc yaxis srr               if yaxis==2, msize(1.5) mc("gs16"))
                (sc yaxis srr               if yaxis==2, msize(1) mc("gs0"))
                (rspike lb_srr ub_srr yaxis if yaxis>=3 & yaxis<=9 , horizontal lw(0.55) color("${str_m70}"))
                (sc yaxis srr               if yaxis>=3 & yaxis<=9, msize(1.5) mc("gs16"))
                (sc yaxis srr               if yaxis>=3 & yaxis<=9, msize(1) mc("${str_m70}"))
                (rspike lb_srr ub_srr yaxis if yaxis>=11 & yaxis<=16 , horizontal lw(0.55) color("${ami_m70}"))
                (sc yaxis srr               if yaxis>=11 & yaxis<=16, msize(1.5) mc("gs16"))
                (sc yaxis srr               if yaxis>=11 & yaxis<=16, msize(1) mc("${ami_m}"))



                ,
                    plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin) margin(l=2 r=2 b=0 t=0)) 		
                    graphregion(color(gs16) ic(gs16) ilw(thin) lw(thin) margin(l=2 r=2 b=0 t=0)) 
                    ysize(14) xsize(14)

                    xlab(none, 
                    labc(gs0) labs(2.5) notick nogrid angle(45) format(%9.0f))
                    xscale(log noline lw(vthin) range(0.5(0.1)2.5)) 
                    xtitle(" ", size(3) color(gs0) margin(l=1 r=1 t=1 b=1)) 
                    
                    ylab(none,
                    valuelabel labc(gs0) labs(3) tlc(gs8) notick nogrid angle(0) format(%9.0f))
                    yscale(reverse noline noextend range(0(1)18.5)) 
                    ytitle(" ", color(gs8) size(4.5) margin(l=1 r=1 t=1 b=1)) 

                    /// Title 
                    text(18.5 1 "Strokes outpace Heart Attacks: Incidence Rate Ratios, 2010–2023",  place(c) size(2.5) color(gs4))

                    // X-axis legend
                    text(17 0.75 "0.75",  place(c) size(2) color(gs4))
                    text(17 1 "One",  place(c) size(2) color(gs4))
                    text(17 1.5 "1.5",  place(c) size(2) color(gs4))
                    text(17 2 "2",  place(c) size(2) color(gs4))
                    text(17 2.5 "2.5",  place(c) size(2) color(gs4))

                    /// (Right hand side) Hospital Rates by Sex and Event type 
                    text(1  0.8 "Stroke (vs. AMI)"                ,  place(w) size(2.5) color("gs0"))
                    text(2  0.8 "CVD in Men (vs. Women)"          ,  place(w) size(2.5) color("gs0"))
                    text(3  0.8 "Strokes (vs. 2010-2011)"          ,  place(w) size(2.5) color("${str_m}%75"))
                    text(4  0.8 "2012-2013"                       ,  place(w) size(2.5) color("${str_m}%75"))
                    text(5  0.8 "2014-2015"                       ,  place(w) size(2.5) color("${str_m}%75"))
                    text(6  0.8 "2016-2017"                       ,  place(w) size(2.5) color("${str_m}%75"))
                    text(7  0.8 "2018-2019"                       ,  place(w) size(2.5) color("${str_m}%75"))
                    text(8  0.8 "2020-2021"                       ,  place(w) size(2.5) color("${str_m}%75"))
                    text(9  0.8 "2022-2023"                       ,  place(w) size(2.5) color("${str_m}%75"))
                    text(10 0.8 "Heart Attacks (vs. 2010-2011)"   ,  place(w) size(2.5) color("${ami_m}%75"))
                    text(11 0.8 "2012-2013"                       ,  place(w) size(2.5) color("${ami_m}%75"))
                    text(12 0.8 "2014-2015"                       ,  place(w) size(2.5) color("${ami_m}%75"))
                    text(13 0.8 "2016-2017"                       ,  place(w) size(2.5) color("${ami_m}%75"))
                    text(14 0.8 "2018-2019"                       ,  place(w) size(2.5) color("${ami_m}%75"))
                    text(15 0.8 "2020-2021"                       ,  place(w) size(2.5) color("${ami_m}%75"))
                    text(16 0.8 "2022-2023"                       ,  place(w) size(2.5) color("${ami_m}%75"))

                    legend(off)
                    name(incidence_figure2, replace)
                    ;
        #delimit cr	

        /// --- UPDATE GRAPH NAME AS NEEDED --- ///

        graph export "${graphs}/bnrcvd-incidence-figure2.png", replace width(3000)

    ** ---------------------------------------------------------
    ** Export acompanying dataset (XLSX and DTA)
    ** With associated dataset-level and variable-level metadata 
    ** ---------------------------------------------------------
    rename yaxis indicator 
    label var indicator "Unique Incidence Rate Ratio (IRR) identifier" 
    label var srr "Age-standardized Rate Ratio"
    label var lb_srr "Lower 95% bound of age-standardized Rate Ratio"
    label var ub_srr "Upper 95% bound of age-standardized Rate Ratio"

    /// --- UPDATE GRAPH METADATA FILE AS NEEDED --- ///

    * STATA dataset export 
    notes drop _all 
    label data "BNR-CVD Registry: dataset associated with CVD incidence briefing" 
    note : title("BNR-CVD incidence rate ratios (Aggregated)") 
    note : version("1.0") 
    note : created("${todayiso}") 
    note : creator("Ian Hambleton, Analyst") 
    note : registry("CVD") 
    note : content("AGGR") 
    note : tier("ANON") 
    note : temporal("2010-01 to 2023-12") 
    note : spatial("Barbados") 
    note : description("Incidence rate ratios (2010-2023) by event type, sex, year. Hospital events only. We looked at all heart attack and stroke events that were treated in hospital or recorded as the main cause of death. Using Barbados population estimates, we calculated how many people per 100,000 experienced these conditions each year. We then adjusted rates for age so that figures from different years, or between men and women, could be compared on equal terms. These analyses give a clear, evidence-based picture of how cardiovascular disease is affecting Barbadians over time.") 
    note : language("en") 
    note : format("Stata 19") 
    note : rights("CC BY 4.0 (Attribution)") 
    note : source("Hospital admissions (QEH)") 
    note : contact("ian.hambleton@gmail.com") 
    note : outfile("./bnrcvd-incidence-figure2.yml")
    save "${graphs}/bnrcvd-incidence-figure2.dta", replace 

    /// --- UPDATE GRAPH METADATA FILE AS NEEDED --- ///

    ** Dataset-level metadata using YAML file
    bnryaml using "${graphs}/bnrcvd-incidence-figure2.dta", ///
        title("BNR-CVD incidence rate ratios (Aggregated)") ///
        version("1.0") ///
        created("${todayiso}") ///
        creator("Ian Hambleton, Analyst") ///
        registry("CVD") ///
        content("AGGR") ///
        tier("ANON") ///
        temporal("2010-01 to 2023-12") ///
        spatial("Barbados") ///
        description("Incidence rate ratios (2010-2023) by event type, sex, year. Hospital events only. We looked at all heart attack and stroke events that were treated in hospital or recorded as the main cause of death. Using Barbados population estimates, we calculated how many people per 100,000 experienced these conditions each year. We then adjusted rates for age so that figures from different years, or between men and women, could be compared on equal terms. These analyses give a clear, evidence-based picture of how cardiovascular disease is affecting Barbadians over time.") ///
        language("en") ///
        format("Stata 19") ///
        rights("CC BY 4.0 (Attribution)") ///
        source("Hospital admissions (QEH)") ///
        contact("ian.hambleton@gmail.com") /// 
        outfile("${Pygraphs}/bnrcvd-incidence-figure2.yml")

    ** XLS dataset export 
    export excel using "${graphs}/bnrcvd-incidence-figure2.xlsx", sheet("data") first(var) replace 
    ** Attach meta-data to Excel spreadsheet. Inputs for DO file below
    global meta_xlsx "${Pygraphs}/bnrcvd-incidence-figure2.xlsx"
    global meta_yaml "${Pygraphs}/bnrcvd-incidence-figure2.yml"
    * Do file that adds metadata to excel spreadsheet - python code 
    do "${do}\bnrcvd-meta-xlsx.do"
    

/// --- BRIEFING LAYOUT FROM HERE. UPDATE AS NEEDED --- ///

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
    putpdf table intro(1,2)=("Hospital Cardiovascular Event Rate in Barbados"), /// 
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
** WHY THIS MATTERS
** --------------------------------------------------------------
putpdf paragraph ,  font("Montserrat", 1)
#delimit; 
putpdf text ("Why This Matters") , font("Montserrat Medium", 11, 000000) linebreak;

/// --- BRIEFING TEXT. UPDATE AS NEEDED --- ///

putpdf text ("
Heart attacks and strokes remain the leading causes of serious illness and death in Barbados. Tracking how often these events occur in hospital helps us see whether prevention and treatment efforts are working. Measuring rates—not just counts—lets us compare fairly over time, even as the population grows and ages. This approach helps us tell whether apparent increases reflect real changes in cardiovascular risk, or simply demographic shifts. By following these patterns, we can see where progress is being made and where renewed attention is needed.
"), font("Montserrat", 9, 000000) linebreak;
#delimit cr

** REPORT: PAGE 1
** WHAT WE DID
** --------------------------------------------------------------
#delimit ; 
putpdf text ("What We Did") , font("Montserrat Medium", 11, 000000) linebreak;

/// --- BRIEFING TEXT. UPDATE AS NEEDED --- ///

putpdf text ("
We looked at all heart attack and stroke events that were treated in hospital or recorded as the main cause of death. Using Barbados population estimates, we calculated how many people per 100,000 experienced these conditions each year. We then adjusted rates for age so that figures from different years, or between men and women, could be compared on equal terms. These analyses give a clear, evidence-based picture of how cardiovascular disease is affecting Barbadians over time.
"), font("Montserrat", 9, 000000) linebreak;
#delimit cr


** REPORT: PAGE 1
** KEY MESSAGE 1
** MORE HIDDEN EVENTS AMONG HEART ATTACKS AND AMONG MEN
** --------------------------------------------------------------
#delimit ; 
putpdf paragraph ,  font("Montserrat", 1);
putpdf text ("Heart Attacks ") , font("Montserrat Medium", 11, ${ami_m});
putpdf text ("Leave More Deaths Unseen Than ") , font("Montserrat Medium", 11, 000000) ;
putpdf text ("Strokes ") , font("Montserrat Medium", 11, ${str_m70}) linebreak;

** FIGURE 1. ANNUAL CUMULATIVE COUNT vs 5-YEAR AVERAGE;
putpdf table f1 = (1,1), width(87%) border(all,nil) halign(center);
putpdf table f1(1,1)=image("${graphs}/bnrcvd-incidence-figure1.png");
putpdf paragraph ,  font("Montserrat", 1);

/// --- BRIEFING TEXT. UPDATE AS NEEDED --- ///

putpdf text ("
The figure above tracks rates of heart attack and stroke in Barbados between 2010 and 2023 for men and women. Each solid line shows the number of hospital-treated events per 100,000 people, while the dotted line adds in deaths identified only through death certificates. The shaded areas between the lines highlight the “hidden” events that occur outside the hospital system.

Across all years, men had higher rates than women for both conditions, reflecting their greater cardiovascular risk. But the size of the gap between the solid and dotted lines tells an additional story. That gap—representing deaths that never reached hospital—is consistently wider for heart attacks than for strokes, and wider for men than for women. On average, including these out-of-hospital deaths raised rates by about 77 per 100,000 for men with heart attacks, 51 for women, 44 for men with stroke, and 29 for women.

These findings suggest that heart attacks are more likely than strokes to be fatal before hospital care is reached, especially among men. This pattern likely reflects differences in how quickly symptoms are recognised and treated. Fewer lives will be lost through faster public response, improved awareness, and rapid treatment pathways—particularly for men.
"), font("Montserrat", 9, 000000) linebreak;

putpdf paragraph ,  font("Montserrat", 10) halign(right);
putpdf text ("Next Page") , font("Montserrat Medium", 10, 000000)  ;

#delimit cr


** REPORT: PAGE 2
** KEY MESSAGE 2
** --------------------------------------------------------------
#delimit ; 
putpdf paragraph ,  font("Montserrat", 1);
putpdf text ("Hospital Rates Show a Decade of Rising ") , font("Montserrat Medium", 11, 000000) ;
putpdf text ("Strokes ") , font("Montserrat Medium", 11, ${str_m70});
putpdf text ("and Persistent Excess Among Men") , font("Montserrat Medium", 11, 000000) linebreak;

** FIGURE 2. ANNUAL CUMULATIVE COUNT vs 5-YEAR AVERAGE;
putpdf table f1 = (1,1), width(70%) border(all,nil) halign(center);
putpdf table f1(1,1)=image("${graphs}/bnrcvd-incidence-figure2.png");
putpdf paragraph ,  font("Montserrat", 1);

/// --- BRIEFING TEXT. UPDATE AS NEEDED --- ///

putpdf text ("
The figure above summarises how hospital-based rates of stroke and heart attack have changed in Barbados since 2010. Each bar shows a rate ratio comparing one group or time period with another, with values above one indicating higher rates. Because almost all serious cardiovascular events are treated at the island’s single public tertiary hospital, these figures provide a reliable picture of national trends, even though they reflect hospital events only.

Across the full period, strokes occurred at more than twice the rate of heart attacks (rate ratio 2.34; 95% CI 2.27–2.41), confirming stroke’s heavier burden in Barbados. Men consistently experienced higher cardiovascular event rates than women (1.39; 1.33–1.44), a difference that has changed little over time and continues to signal the need for greater focus on men’s prevention and early treatment.

Both conditions showed clear increases over the past decade. Stroke rates rose most sharply, almost doubling between 2010–2011 and 2018–2019 (1.97; 1.77–2.20), before easing slightly in recent years to about 60 percent above baseline (1.61; 1.43–1.80 in 2022–2023). For heart attacks, increases were smaller but still evident—around 20–25 percent higher than at the start of the decade (1.22; 1.14–1.30 in 2022–2023). Some of the fluctuations after 2020 likely reflect changes in healthcare access and hospital use during the COVID-19 pandemic, when fewer people sought emergency care for milder events.

Strengthening hypertension and diabetes control, improving recognition of stroke and heart-attack symptoms, and sustaining rapid emergency response remain critical steps to reducing avoidable deaths and long-term disability.
"), font("Montserrat", 9, 000000);
#delimit cr



** REPORT: PAGE 2
** WHAT THIS MEANS
** --------------------------------------------------------------
#delimit ; 
putpdf paragraph ,  font("Montserrat", 1);
putpdf text ("What This Means") , font("Montserrat Medium", 11, 000000) linebreak ;

/// --- BRIEFING TEXT. UPDATE AS NEEDED --- ///

putpdf text ("
Taken together, these findings show that while heart attacks still claim more lives before reaching hospital, strokes are now the more frequent event treated within it—and their numbers continue to rise. Some of this increase may reflect better recognition, but it also points to a real and growing stroke burden in Barbados. Men remain at greater risk across both conditions, underscoring the need for stronger prevention, faster response to symptoms, and continued public awareness to save lives and reduce disability.
"), font("Montserrat", 9, 000000) linebreak;
#delimit cr

/// --- BRIEFING FILENAME. UPDATE AS NEEDED --- ///

** PDF SAVE
** --------------------------------------------------------------
    putpdf save "${outputs}/bnr-cvd-incidence-2023", replace

