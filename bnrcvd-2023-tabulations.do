/**************************************************************************
 DO-FILE:     bnrcvd-2023-tabulations.do
 PROJECT:     BNR Refit Consultancy
 PURPOSE:     Online report tabulations 2023, with comparisons across years
              as appropriate
 
 AUTHOR:      Ian R Hambleton
 DATE:        [2025-11-18]
 VERSION:     [v1.0]

 METADATA:    

 NOTES:       Tabulations created listed below:
              General stratifiers
                - by type (AMI, stroke)
                - by year
                - by sex 
                - by age groups
**************************************************************************/

** GLOBALS 
do "C:\yasuki\Sync\BNR-sandbox\006-dev\do\bnrcvd-2023-prep1"
do "C:\yasuki\Sync\BNR-sandbox\006-dev\do\bnrcvd-globals"

* Log File 
cap log close 
log using ${logs}\bnrcvd-2023-tabulations, replace 

** --------------------------------------------------------------
** (1) Load the interim dataset - COUNT
**     Dataset prepared in: bnrcvd-2023-prep1.do
** --------------------------------------------------------------
use "${tempdata}\bnr-cvd-count-${today}-prep1.dta", clear 
gen event = 1 
local outputfile = "md xlsx" 
gen woe = week(doe) 
tempfile input 
save `input', replace 


** --------------------------------------------------------------

** TABLE 1: Event count by:
**          - Event Type
**          - Year
**          - Sex
** --------------------------------------------------------------
drop if yoe==2009 
label var sex "Patient Sex" 
label var etype "CVD Event Type"
#delimit ; 
        gen year = 1 if yoe == 2023;  replace year = 2 if yoe == 2022;  replace year = 3 if yoe == 2021;
        replace year = 4 if yoe == 2020;  replace year = 5 if yoe == 2019;  replace year = 6 if yoe == 2018;
        replace year = 7 if yoe == 2017;  replace year = 8 if yoe == 2016;  replace year = 9 if yoe == 2015;
        replace year = 10 if yoe == 2014; replace year = 11 if yoe == 2013; replace year = 12 if yoe == 2012;
        replace year = 13 if yoe == 2011; replace year = 14 if yoe == 2010;
        labmask year, values(yoe);
        label var year "CVD Event Year"; 
        table (year) (etype sex), 
            statistic(count event) 
            export("${tempdata}\bnr-cvd-2023-table1.md", replace as(md))
            title(Table 1. Annual Event Count by Year)
            ;
        table (year) (etype sex), 
            statistic(count event) 
            export("${tempdata}\bnr-cvd-2023-table1.xlsx", replace as(xlsx) sheet("Table1", replace))
            note(Prepared by Ian Hambleton on ${todayiso}, for the Barbados National Registry)            
            title(Table 1. Annual Event Count by Year)
            ;
#delimit cr


** --------------------------------------------------------------
** TABLE 2: Weekly Event count:
**          - Event Type
**          - Year
**          - Sex
**          We will use JavaScript to select year
** --------------------------------------------------------------
forval yr = 2010(1)2023 {
        #delimit ; 
        table (woe) (etype) if yoe==`yr', 
                statistic(count event) 
                export("${tempdata}\bnr-cvd-2023-table2-`yr'.md", replace as(md))
                title(Table 2. Weekly Event Count for `yr')
                ;
        table (woe) (etype) if yoe==`yr', 
                statistic(count event) 
                export("${tempdata}\bnr-cvd-2023-table2.xlsx", modify as(xlsx) sheet("Table2_`yr'", replace))
                note(Prepared by Ian Hambleton on ${todayiso}, for the Barbados National Registry)            
                title(Table 2. Weekly Event Count for `yr')
                ;
        #delimit cr
}



** --------------------------------------------------------------
** TABLE 3: Proportion of strokes / AMIs by age (<70yrs, 70+ yrs)
**          - Event Type
**          - Year
**          - Sex
** --------------------------------------------------------------
** 5-year average count (women and men separately)
preserve
        tempvar latestyr time5
        egen `latestyr' = max(yoe) 
        gen time5 = 1
        replace time5 = 3 if `latestyr' != yoe & `latestyr' - yoe < 6 
        replace time5 = 2 if `latestyr' == yoe 
        collapse (sum) event , by(time5 etype sex age70)
        drop if time5==1 
        sort etype sex time5 age70
        bysort etype sex time5 : egen denom = sum(event)
        replace event = event/5 if time5==2
        replace denom = denom/5 if time5==2
        gen perc = (event/denom) * 100  
        label define time5_ 3 "Average (2018-2022)" 2 "2023"
        label values time5 time5_ 
        label var time5 "Time period"

        #delimit ; 
        table (time5 age70) (etype sex), 
                statistic(mean perc) 
                nototals 
                nformat(%5.1f)
                export("${tempdata}\bnr-cvd-2023-table3.md", replace as(md))
                title(Table 3. Event Percentage among Younger Adults (<70 years) and Older Adults (70+ years))
                ;
        #delimit cr 
        #delimit ; 
        table (time5 age70) (etype sex), 
                statistic(mean perc) 
                nototals 
                nformat(%5.1f)
                export("${tempdata}\bnr-cvd-2023-table3.xlsx", modify as(xlsx) sheet("Table3", replace))
                note(Prepared by Ian Hambleton on ${todayiso}, for the Barbados National Registry)            
                title(Table 3. Event Percentage among Younger Adults (<70 years) and Older Adults (70+ years))
                ;
        #delimit cr 
restore


** --------------------------------------------------------------
** TABLE 4: Proportion of strokes / AMIs by age (10-year age bands)
**          - Event Type
**          - Year
**          - Sex
** --------------------------------------------------------------
** 5-year average count (women and men separately)
        tempfile interim1 both1 strat1
        use `input', clear 
        tempvar latestyr time5
        egen `latestyr' = max(yoe) 
        gen time5 = 1
        replace time5 = 2 if `latestyr' != yoe & `latestyr' - yoe < 6 
        replace time5 = 3 if `latestyr' == yoe 
        gen age10 = age5 
        recode age10 (1 2 3 4 5 6 7 8 = 1) /// 
                (9 10 = 2) (11 12 = 3) (13 14 = 4) /// 
                (15 16 = 5) (17 18 = 6)
        label define age10_ 1 "<40" 2 "40-49" 3 "50-59" 4 "60-69" 5 "70-79" 6 "80+"
        label values age10 age10_ 
        save `interim1', replace 

        collapse (sum) event , by(time5 etype age10)
        gen sex = 3 
        save `both1', replace 

        use `interim1', clear 
        collapse (sum) event , by(time5 etype sex age10)
        save `strat1', replace 
        append using `both1'

        drop if time5==1 
        sort etype sex time5 age10
        bysort etype sex time5 : egen denom = sum(event)
        replace event = event/5 if time5==2
        replace denom = denom/5 if time5==2
        gen perc = (event/denom) * 100  

        label define time5_ 2 "Average (2018-2022)" 3 "2023"
        label values time5 time5_ 
        label var time5 "Time period"
        label define sex_ 3 "All", modify 
        label values sex sex_ 
        label var etype "CVD Event Type"
        label var sex "Patient Sex"

        #delimit ; 
        table (time5 age10) (etype sex), 
                statistic(mean perc) 
                nototals 
                nformat(%5.1f)
                export("${tempdata}\bnr-cvd-2023-table4.md", replace as(md))
                title(Table 4. Event Percentage by 10-Year Age Groups)
                ;
        #delimit cr 
        #delimit ; 
        table (time5 age10) (etype sex), 
                statistic(mean perc) 
                nototals 
                nformat(%5.1f)
                export("${tempdata}\bnr-cvd-2023-table4.xlsx", modify as(xlsx) sheet("Table4", replace))
                note(Prepared by Ian Hambleton on ${todayiso}, for the Barbados National Registry)            
                title(Table 4. Event Percentage by 10-Year Age Groups)
                ;
        #delimit cr 


** --------------------------------------------------------------
** TABLE 5: Incidence Rates Hospital Events (with and without DCOs)
**          - Event Type
**          - Year
**          - Sex
** --------------------------------------------------------------
use "${data}/bnrcvd-incidence.dta", clear 
        rename year yoe 
        #delimit ; 
        gen year = 1 if yoe == 2023;  replace year = 2 if yoe == 2022;  replace year = 3 if yoe == 2021;
        replace year = 4 if yoe == 2020;  replace year = 5 if yoe == 2019;  replace year = 6 if yoe == 2018;
        replace year = 7 if yoe == 2017;  replace year = 8 if yoe == 2016;  replace year = 9 if yoe == 2015;
        replace year = 10 if yoe == 2014; replace year = 11 if yoe == 2013; replace year = 12 if yoe == 2012;
        replace year = 13 if yoe == 2011; replace year = 14 if yoe == 2010;
        #delimit cr 
        labmask year, values(yoe)
        label var year "CVD Event Year"
        label var sex "Patient sex" 
        label var dco "Does Event Rate include DCOs?"
        label define dco_ 0 "Without DCO" 1 "DCO added", modify 
        label values dco dco_
        label var lb_gam "Lower 95% Limit"
        label var ub_gam "Upper 95% Limit"
        forval yr = 2010(1)2023 {
                #delimit ; 
                table (year dco) (etype sex) if yoe==`yr', 
                        statistic(mean crude) 
                        statistic(mean rateadj) 
                        statistic(mean lb_gam) 
                        statistic(mean ub_gam) 
                        nototals 
                        nformat(%5.1f)
                        export("${tempdata}\bnr-cvd-2023-table5-`yr'.md", replace as(md))
                        title(Table 5. CVD Incidence Rates for `yr')
                        ;
                table (year dco) (etype sex) if yoe==`yr', 
                        statistic(mean crude) 
                        statistic(mean rateadj) 
                        statistic(mean lb_gam) 
                        statistic(mean ub_gam) 
                        nototals 
                        nformat(%5.1f)
                        export("${tempdata}\bnr-cvd-2023-table5.xlsx", modify as(xlsx) sheet("Table5_`yr'", replace))
                        note(Prepared by Ian Hambleton on ${todayiso}, for the Barbados National Registry)            
                        note(Adjusted Rate Confidence Limits (95%) - Tiwari, Clegg and Zhou bounds)            
                        note(Adjusted Rates use the WHO (2000) World Standard Population)            
                        note(DCO = Death Certificate Only Events)            
                        title(Table 5. CVD Incidence Rates for `yr')
                        ;
                #delimit cr 
        }


** --------------------------------------------------------------
** TABLE 6: Incidence Rate Ratios for Hospital Events
**          - Event Type
**          - Year
**          - Sex
** --------------------------------------------------------------
use "${tempdata}/bnrcvd-incidence-rate-ratios.dta", clear 
rename srr srr1 
rename lb_srr srr2 
rename ub_srr srr3
reshape long srr, i(yaxis) j(type) 
label var yaxis "Indicence Rate Comparison ${dagger} ${ddagger}"
label var srr "Incidence Rate Ratio"
**label var srr2 "Lower 95% Limit"
**label var srr3 "Upper 95% Limit"
label var type "Incidence Rate Ratio"
label define type_ 1 "IRR" 2 "Lower 95% Limit" 3 "Upper 95% Limit"
label values type type_ 

                #delimit ; 
                table (yaxis) (type), 
                        statistic(mean srr) 
                        nototals 
                        nformat(%5.2f)
                        export("${tempdata}\bnr-cvd-2023-table6.md", replace as(md))
                        note(Prepared by Ian Hambleton on ${todayiso}, for the Barbados National Registry)            
                        note(${dagger} IRR = Incidence Rate Ratio with 95% Confidence Limits)            
                        note(${ddagger} Each 2-year time period compared to (2010-2011))            
                        title(Table 6. CVD Incidence Rate Ratios (2010 to 2023) for Hospital Events)
                        ;
                table (yaxis) (type), 
                        statistic(mean srr) 
                        nototals 
                        nformat(%5.2f)
                        export("${tempdata}\bnr-cvd-2023-table6.xlsx",  modify as(xlsx) sheet("Table6", replace))
                        note(Prepared by Ian Hambleton on ${todayiso}, for the Barbados National Registry)            
                        note(${dagger} IRR = Incidence Rate Ratio with 95% Confidence Limits)            
                        note(${ddagger} Each 2-year time period compared to (2010-2011))            
                        title(Table 6. CVD Incidence Rate Ratios (2010 to 2023) for Hospital Events)
                        ;
                #delimit cr 



** --------------------------------------------------------------
** TABLE 7: Case Fatality Among hospital Events
**          - Event Type
**          - Year (2-year age bands)
**          - Sex (female, male, both)
**          - Age groups (Less than 70 yrs , 70 yrs and older)
** --------------------------------------------------------------
use "${tempdata}/bnrcvd-case-fatality.dta", clear 

recode year2 (7=1) (6=2) (5=3) (4=4) (3=5) (2=6) (1=7) 
label define year2_ 1 "2022-2023" 2 "2020-2021" 3 "2018-2019" 4 "2016-2017" 5 "2014-2015" 6 "2012-2013" 7 "2010-2011",modify
label values year2 year2_

        #delimit ; 
        table (year2) (etype sex) , 
                statistic(mean ccase)  
                nformat(%5.1f)
                
                export("${tempdata}\bnr-cvd-2023-table7.md", replace as(md))
                note(Prepared by Ian Hambleton on ${todayiso}, for the Barbados National Registry)            
                title(Table 7. CVD In-Hospital Fatality Percentage (2010 to 2023))
                ;
        table (year2) (etype sex) , 
                statistic(mean ccase)  
                nformat(%5.1f)
                
                export("${tempdata}\bnr-cvd-2023-table7.xlsx", modify as(xlsx) sheet("Table7", replace))
                note(Prepared by Ian Hambleton on ${todayiso}, for the Barbados National Registry)            
                title(Table 7. CVD In-Hospital Fatality Percentage (2010 to 2023))
                ;
        #delimit cr 

** --------------------------------------------------------------
** TABLE 8: Median Length of Stay
**          - Event Type
**          - Event Type & Year
**          - Broad age groups (<70 yrs, 70 yrs and older)
** --------------------------------------------------------------
use "${tempdata}/bnrcvd-length-of-stay.dta", clear 
keep if cf==1 
        #delimit ; 
        gen year = 1 if yoe == 2023;  replace year = 2 if yoe == 2022;  replace year = 3 if yoe == 2021;
        replace year = 4 if yoe == 2020;  replace year = 5 if yoe == 2019;  replace year = 6 if yoe == 2018;
        replace year = 7 if yoe == 2017;  replace year = 8 if yoe == 2016;  replace year = 9 if yoe == 2015;
        replace year = 10 if yoe == 2014; replace year = 11 if yoe == 2013; replace year = 12 if yoe == 2012;
        replace year = 13 if yoe == 2011; replace year = 14 if yoe == 2010;
        #delimit cr 
        labmask year, values(yoe)
        label var year "CVD Event Year"
        label var sex "Patient sex" 
        label var etype "CVD Event Type"

        #delimit ; 
        table (year) (etype sex) , 
                statistic(median los_primary)  
                statistic(p25 los_primary)  
                statistic(p75 los_primary)  
                nformat(%5.0f)
                export("${tempdata}\bnr-cvd-2023-table8.md", replace as(md))
                note(Prepared by Ian Hambleton on ${todayiso}, for the Barbados National Registry)            
                title(Table 8. CVD Typical (Median) In-Hospital Length of Stay (2010 to 2023))
                ;
        table (year) (etype sex) , 
                statistic(median los_primary)  
                statistic(p25 los_primary)  
                statistic(p75 los_primary)  
                nformat(%5.0f)
                export("${tempdata}\bnr-cvd-2023-table8.xlsx", modify as(xlsx) sheet("Table8", replace))
                note(Prepared by Ian Hambleton on ${todayiso}, for the Barbados National Registry)            
                title(Table 8. CVD Typical (Median) In-Hospital Length of Stay (2010 to 2023))
                ;
        #delimit cr 


