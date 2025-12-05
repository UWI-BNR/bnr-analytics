/**************************************************************************
 DO-FILE:     bnrcvd-2024-count.do
 PROJECT:     BNR Refit Consultancy
 PURPOSE:     Basic count data for 2024, with comparisons across years
              tabular and visualized 
 
 AUTHOR:      Ian R Hambleton
 DATE:        [2025-11-02]
 VERSION:     [v1.0]

 METADATA:    bnrcvd-2024-count.yml (same dirpath/name as dataset)

 NOTES:       BNR simple CVD counts:
                - by type (AMI, stroke)
                - by year
                - by sex 
                - by age groups

This DO file produces core descriptive counts of cardiovascular events
(stroke and acute myocardial infarction) for 2010–2023, with a focus
on the latest year (2024).

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
    do "${do}\bnrcvd-2024-prep1"

   * Log file. This is a relative FILEPATH
   * Do not need to change 
   cap log close 
   log using ${logs}\bnrcvd-2024-count, replace 

   * Initialize 
   version 19 
   clear all
   set more off
** ----- END INITIALIZE DO FILE -------------------
** ------------------------------------------------



** --------------------------------------------------------------
** (1) Load the interim dataset - COUNT
**     Dataset prepared in: bnrcvd-2023-prep1.do
** --------------------------------------------------------------
use "${tempdata}\bnr-cvd-count-${today}-prep1.dta", clear 

** BROAD RESTRICTIONS
** LOOK AT HOSPIPTAL EVENTS FOR NOW - drop DCOs 
drop if dco==1 
drop dco 
drop if yoe==2009  /// This was a setup year - don't report


** --------------------------------------------------------------
** TABLE 1: Total by year
** --------------------------------------------------------------
** Count by year / event type 
    gen event = 1 
    #delimit ; 
    table (yoe) (etype), 
            nototals
            statistic(count event) 
            ;
    #delimit cr

** Count by year / event type and sex 
    #delimit ; 
    table (yoe) (etype sex), 
            nototals
            statistic(count event) 
            ;
    #delimit cr

** --------------------------------------------------------------
** TABLE 2: Counts by sex and broad age group (<70, 70+) 
** --------------------------------------------------------------
    
    ** Percentage 70+ - by sex / event type
    #delimit ; 
    table (sex) (etype age70), 
            nototals
            statistic(percent, across(age70)) 
            ;
    #delimit cr 

** Percentage 70+ - by sex and year / event type
    #delimit ; 
    table (sex yoe) (etype age70), 
            nototals
            statistic(percent, across(age70)) 
            ;
    #delimit cr 


** --------------------------------------------------------------
** FIGURE 1: 'Worm plot' of cumulative count (latest year) vs. 5 year av. 
** --------------------------------------------------------------
**preserve
    ** This gives cumulative counts in 2024 vs average of prior 5 years
        gen woe = week(doe) 
        collapse (sum) event , by(yoe woe etype)
        sort etype yoe woe
        ** Cumulative by year/event type
        sort etype yoe woe 
        bysort etype yoe: gen cevent = sum(event) 

    ** 5-year average count (women and men combined)
        global thisyr = real(substr("${today}", 1, 4))
        tempvar latestyr time5
        egen `latestyr' = max(yoe) 
        gen time5 = 1
        replace time5 = 2 if `latestyr' != yoe & `latestyr' - yoe < 6 
        replace time5 = 3 if `latestyr' == yoe 

        collapse (sum) event , by(time5 woe etype)
        sort time5 etype woe 
        bysort time5 etype : gen cevent = sum(event)
        keep if time5>1 
        replace cevent = cevent/5 if time5==2
        reshape wide event cevent, i(etype woe) j(time5)
        replace event3 = 0 if cevent3==. 
        replace cevent3 = cevent3[_n-1] if cevent3==. 
        
        gen evdiff = cevent3 - cevent2
        replace evdiff = . if etype==etype[_n-1] & evdiff[_n-1]==.

    ** Jan and Feb 
    #delimit ;
        gr twoway 
            (function y=0, range(1 52) lc(gs8%50) lp("_") lw(0.75))
            (line evdiff woe if etype==1 & woe<=8, lw(1) color("${str_m}"))
            (line evdiff woe if etype==2 & woe<=8, lw(1) color("${ami_m}"))
            ,
                plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin) margin(l=2 r=2 b=0 t=0)) 		
                graphregion(color(gs16) ic(gs16) ilw(thin) lw(thin) margin(l=2 r=2 b=0 t=0)) 
                ysize(4) xsize(16)

                xlab(none, 
                valuelabel labc(gs0) labs(2.5) notick nogrid glc(gs16) angle(45) format(%9.0f))
                xscale(noline lw(vthin)) 
                xtitle(" ", size(3) color(gs0) margin(l=1 r=1 t=1 b=1)) 
                
                ylab(-20(20)60,
                labc(gs0) labs(7) tlc(gs8) nogrid glc(gs16) angle(0) format(%9.0f))
                yscale(lw(vthin) lc(gs8) noextend range(-40(10)70)) 
                ytitle(" ", color(gs8) size(4.5) margin(l=1 r=1 t=1 b=1)) 

                /// 5-year average
                text(-7.5 52 "5-year average",  place(w) size(8) color(gs4))
                text(-40 26 "Cumulative CVD cases in 2024 compared to 5-year average (2019-2023)",  place(c) size(8) color(gs4))

                legend(off size(2.5) position(9) nobox ring(0) bm(t=1 b=4 l=5 r=0) colf cols(1)
                region(fcolor(gs16)  lw(none) margin(zero)) 
                order(2 1) 
                lab(1 "xx") 
                lab(2 "xx") 		
                )
                name(worm_wks_01_08, replace)
                ;
    #delimit cr	
    graph export "${graphs}/bnrcvd-worm-wks-01-08.png", replace width(3000)

    ** Jan to Apr
    #delimit ;
        gr twoway 
            (function y=0, range(1 52) lc(gs8%50) lp("_") lw(0.75))
            (line evdiff woe if etype==1 & woe<=17, lw(1) color("${str_m}"))
            (line evdiff woe if etype==2 & woe<=17, lw(1) color("${ami_m}"))
            ,
                plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin) margin(l=2 r=2 b=0 t=0)) 		
                graphregion(color(gs16) ic(gs16) ilw(thin) lw(thin) margin(l=2 r=2 b=0 t=0)) 
                ysize(4) xsize(16)

                xlab(none, 
                valuelabel labc(gs0) labs(2.5) notick nogrid glc(gs16) angle(45) format(%9.0f))
                xscale(noline lw(vthin)) 
                xtitle(" ", size(3) color(gs0) margin(l=1 r=1 t=1 b=1)) 
                
                ylab(-20(20)60,
                labc(gs0) labs(7) tlc(gs8) nogrid glc(gs16) angle(0) format(%9.0f))
                yscale(lw(vthin) lc(gs8) noextend range(-40(10)70)) 
                ytitle(" ", color(gs8) size(4.5) margin(l=1 r=1 t=1 b=1)) 

                /// 5-year average
                text(-7.5 52 "5-year average",  place(w) size(8) color(gs4))
                text(-40 26 "Cumulative CVD cases in 2024 compared to 5-year average (2019-2023)",  place(c) size(8) color(gs4))

                legend(off size(2.5) position(9) nobox ring(0) bm(t=1 b=4 l=5 r=0) colf cols(1)
                region(fcolor(gs16)  lw(none) margin(zero)) 
                order(2 1) 
                lab(1 "xx") 
                lab(2 "xx") 		
                )
                name(worm_wks_01_17, replace)
                ;
    #delimit cr	
    graph export "${graphs}/bnrcvd-worm-wks-01-17.png", replace width(3000)

    ** Jan to Jun
    #delimit ;
        gr twoway 
            (function y=0, range(1 52) lc(gs8%50) lp("_") lw(0.75))
            (line evdiff woe if etype==1 & woe<=26, lw(1) color("${str_m}"))
            (line evdiff woe if etype==2 & woe<=26, lw(1) color("${ami_m}"))
            ,
                plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin) margin(l=2 r=2 b=0 t=0)) 		
                graphregion(color(gs16) ic(gs16) ilw(thin) lw(thin) margin(l=2 r=2 b=0 t=0)) 
                ysize(4) xsize(16)

                xlab(none, 
                valuelabel labc(gs0) labs(2.5) notick nogrid glc(gs16) angle(45) format(%9.0f))
                xscale(noline lw(vthin)) 
                xtitle(" ", size(3) color(gs0) margin(l=1 r=1 t=1 b=1)) 
                
                ylab(-20(20)60,
                labc(gs0) labs(7) tlc(gs8) nogrid glc(gs16) angle(0) format(%9.0f))
                yscale(lw(vthin) lc(gs8) noextend range(-40(10)70)) 
                ytitle(" ", color(gs8) size(4.5) margin(l=1 r=1 t=1 b=1)) 

                /// 5-year average
                text(-7.5 52 "5-year average",  place(w) size(8) color(gs4))
                text(-40 26 "Cumulative CVD cases in 2024 compared to 5-year average (2019-2023)",  place(c) size(8) color(gs4))

                legend(off size(2.5) position(9) nobox ring(0) bm(t=1 b=4 l=5 r=0) colf cols(1)
                region(fcolor(gs16)  lw(none) margin(zero)) 
                order(2 1) 
                lab(1 "xx") 
                lab(2 "xx") 		
                )
                name(worm_wks_01_26, replace)
                ;
    #delimit cr	
    graph export "${graphs}/bnrcvd-worm-wks-01-26.png", replace width(3000)


    ** Jan to Aug
    #delimit ;
        gr twoway 
            (function y=0, range(1 52) lc(gs8%50) lp("_") lw(0.75))
            (line evdiff woe if etype==1 & woe<=35, lw(1) color("${str_m}"))
            (line evdiff woe if etype==2 & woe<=35, lw(1) color("${ami_m}"))
            ,
                plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin) margin(l=2 r=2 b=0 t=0)) 		
                graphregion(color(gs16) ic(gs16) ilw(thin) lw(thin) margin(l=2 r=2 b=0 t=0)) 
                ysize(4) xsize(16)

                xlab(none, 
                valuelabel labc(gs0) labs(2.5) notick nogrid glc(gs16) angle(45) format(%9.0f))
                xscale(noline lw(vthin)) 
                xtitle(" ", size(3) color(gs0) margin(l=1 r=1 t=1 b=1)) 
                
                ylab(-20(20)60,
                labc(gs0) labs(7) tlc(gs8) nogrid glc(gs16) angle(0) format(%9.0f))
                yscale(lw(vthin) lc(gs8) noextend range(-40(10)70)) 
                ytitle(" ", color(gs8) size(4.5) margin(l=1 r=1 t=1 b=1)) 

                /// 5-year average
                text(-7.5 52 "5-year average",  place(w) size(8) color(gs4))
                text(-40 26 "Cumulative CVD cases in 2024 compared to 5-year average (2019-2023)",  place(c) size(8) color(gs4))

                legend(off size(2.5) position(9) nobox ring(0) bm(t=1 b=4 l=5 r=0) colf cols(1)
                region(fcolor(gs16)  lw(none) margin(zero)) 
                order(2 1) 
                lab(1 "xx") 
                lab(2 "xx") 		
                )
                name(worm_wks_01_35, replace)
                ;
    #delimit cr	
    graph export "${graphs}/bnrcvd-worm-wks-01-35.png", replace width(3000)


    ** Jan to Oct
    #delimit ;
        gr twoway 
            (function y=0, range(1 52) lc(gs8%50) lp("_") lw(0.75))
            (line evdiff woe if etype==1 & woe<=43, lw(1) color("${str_m}"))
            (line evdiff woe if etype==2 & woe<=43, lw(1) color("${ami_m}"))
            ,
                plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin) margin(l=2 r=2 b=0 t=0)) 		
                graphregion(color(gs16) ic(gs16) ilw(thin) lw(thin) margin(l=2 r=2 b=0 t=0)) 
                ysize(4) xsize(16)

                xlab(none, 
                valuelabel labc(gs0) labs(2.5) notick nogrid glc(gs16) angle(45) format(%9.0f))
                xscale(noline lw(vthin)) 
                xtitle(" ", size(3) color(gs0) margin(l=1 r=1 t=1 b=1)) 
                
                ylab(-20(20)60,
                labc(gs0) labs(7) tlc(gs8) nogrid glc(gs16) angle(0) format(%9.0f))
                yscale(lw(vthin) lc(gs8) noextend range(-40(10)70)) 
                ytitle(" ", color(gs8) size(4.5) margin(l=1 r=1 t=1 b=1)) 

                /// 5-year average
                text(-7.5 52 "5-year average",  place(w) size(8) color(gs4))
                text(-40 26 "Cumulative CVD cases in 2024 compared to 5-year average (2019-2023)",  place(c) size(8) color(gs4))

                legend(off size(2.5) position(9) nobox ring(0) bm(t=1 b=4 l=5 r=0) colf cols(1)
                region(fcolor(gs16)  lw(none) margin(zero)) 
                order(2 1) 
                lab(1 "xx") 
                lab(2 "xx") 		
                )
                name(worm_wks_01_43, replace)
                ;
    #delimit cr	
    graph export "${graphs}/bnrcvd-worm-wks-01-43.png", replace width(3000)


    ** Jan to Dec
    #delimit ;
        gr twoway 
            (function y=0, range(1 52) lc(gs8%50) lp("_") lw(0.75))
            (line evdiff woe if etype==1 & woe<=52, lp("- -") lw(1) color("${str_m}"))
            (line evdiff woe if etype==2 & woe<=52, lp("_") lw(1) color("${ami_m}"))
            ,
                plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin) margin(l=2 r=2 b=0 t=0)) 		
                graphregion(color(gs16) ic(gs16) ilw(thin) lw(thin) margin(l=2 r=2 b=0 t=0)) 
                ysize(4) xsize(16)

                xlab(none, 
                valuelabel labc(gs0) labs(2.5) notick nogrid glc(gs16) angle(45) format(%9.0f))
                xscale(noline lw(vthin)) 
                xtitle(" ", size(3) color(gs0) margin(l=1 r=1 t=1 b=1)) 
                
                ylab(-20(20)60,
                labc(gs0) labs(7) tlc(gs8) nogrid glc(gs16) angle(0) format(%9.0f))
                yscale(lw(vthin) lc(gs8) noextend range(-40(10)70)) 
                ytitle(" ", color(gs8) size(4.5) margin(l=1 r=1 t=1 b=1)) 

                /// 5-year average
                text(-7.5 52 "5-year average",  place(w) size(8) color(gs4))
                text(-40 26 "Cumulative CVD cases in 2024 compared to 5-year average (2019-2023)",  place(c) size(8) color(gs4))

                legend(off size(2.5) position(9) nobox ring(0) bm(t=1 b=4 l=5 r=0) colf cols(1)
                region(fcolor(gs16)  lw(none) margin(zero)) 
                order(2 1) 
                lab(1 "xx") 
                lab(2 "xx") 		
                )
                name(worm_wks_01_52, replace)
                ;
    #delimit cr	
    graph export "${graphs}/bnrcvd-worm-wks-01-52.png", replace width(3000)
