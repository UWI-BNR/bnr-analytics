/**************************************************************************
 DO-FILE:     bnrcvd-2023-missing-collect.do
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
                (Group 3)   ADMISSION: sbp dbp bgmmol ecg doecg htecg mtecg
                (Group 4)   TROPONIN: tropres trop1res trop2res
                (Group 5)   ASSESSMENT: assess assess1 assess2 assess3 assess4
                (Group 6)   CT: ct doct
                (Group 7)   REPERFUSION: reperf repertype dore htore mtore 
                (Group 8)   ASPIRIN: asp1 asp2 asp3 aspdose doasp htoasp mtoasp asp_ampm
                (Group 9)  DISCHARGE: dmed1 dmed2 dmed3 dmed4 dmed5 dmed6 dmed7 dmed8 dmed9 dmed10 aspdose_dis
                (Group 10)  STROKE UNIT: doasu dodisu doasu_same dodisu_same

                This particular file:
                - Created a missing data table structure
                  That is then used for different variables in the main DO file
                  bnrcvd-2023-missing.do 
**************************************************************************/

*--- Collect Table Information
collect clear 
qui: collect:   table (yoe) (),       ///
                statistic(total ${var})     ///
                statistic(count ${var})     ///
                statistic(fvpercent ${var})
*--- Rename column headers
    collect label levels result         ///
        count      "Total Events"       ///
        total      "# Missing", modify
    collect label levels ${var}     ///
        0      "% Available"            ///
        1      "% Missing", modify
    * Column header styles and number formats
    collect style header ${var}, title(hide)
    collect style cell result[total count], nformat(%9.0fc)
    collect style cell ${var}[1], nformat(%6.1f)
    collect style cell yoe[.m], shading(background("DDDDDD"))
    *--- Title and note
    collect title "${table}. Missing Values for ${name} by Year"
    collect notes "Prepared by Ian Hambleton on `c(current_date)' for the Barbados National Registry"

