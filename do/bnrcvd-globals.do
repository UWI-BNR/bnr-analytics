*--------------------------------------------------------------------
*  Barbados National Registry (BNR) Refit Consultancy
*  Global environment setup
*--------------------------------------------------------------------
*  PURPOSE:
*  This file defines global macros for folder paths and system-level
*  constants so that other DO files can run on any desktop without
*  manual edits.
*
*  AUTHOR:  IAN HAMBLETON
*  PROJECT: BNR Refit Consultancy
*  CREATED:  `c(current_date)'
*--------------------------------------------------------------------

** ------------------------------------------------
** ----- INITIALIZE DO FILE -----------------------
    * Set path 
    * (EDIT bnrpath.ado 
    *  to change to your LOCAL PATH) 
    bnrpath 
    global root "${BNRROOT}"
    * Sanity check  
    dis "Root path set to: ${BNRROOT}" 
    * Log file. This is a relative FILEPATH
    * Do not need to change 
    cap log close 
    log using "log\bnrcvd-globals", replace     
    * Initialize 
    version 19 
    clear all
    set more off
** ----- END INITIALIZE DO FILE -------------------
** ------------------------------------------------


*-------------------------------
* 2. Folder structure (Stata Use)
*-------------------------------
global do        "${root}\do"
global ado       "${root}\ado"
global data      "${root}\data"
global tempdata  "${root}\temp"
global logs      "${root}\log"
global graphs    "${root}\graphics"
global outputs   "${root}\outputs"
global tables   "${root}\tables"
*-------------------------------
* 2. Folder structure (Python Use)
*-------------------------------
global Pyroot      "${root}"
global Pydata      "${Pyroot}/data"
global Pytempdata  "${Pyroot}/temp"
global Pydofiles   "${Pyroot}/do"
global Pylogs      "${Pyroot}/log"
global Pygraphs    "${Pyroot}/graphics"
global Pyoutputs   "${Pyroot}/outputs"
global Pytables   "${Pyroot}/tables"

*-------------------------------
* 3. System / session globals
*-------------------------------
* today's date in ISO format (e.g., 2025-10-28)
local today: display %tdCCYY-NN-DD daily("`c(current_date)'","DMY")
global todayiso = "`today'"

** Date without delimiters
global today : display %tdCYND date(c(current_date), "DMY")

* log file name example: project_YYYYMMDD.log
global logname = "bnr_${today}"

*-------------------------------
* 4. Optional: user and version info
*-------------------------------
global analyst   "`c(username)'"
global stata_v   "`c(version)'"
global project   "BNR Refit"

*-------------------------------
* 5. Convenience globals
*-------------------------------
* Temporary working directory (if used)
global temp      "${root}\temp"

* Path to ado files (if any custom ado directory is used)
global adopath   "${root}\ado"

*-------------------------------
* 6. REDCap globals
*-------------------------------
** API Key (via secure storage - do not hardcode here)


*-------------------------------
* 7. BNR Report Color Palette
*-------------------------------
** Function        | Hex       | Name         |
** --------------- | --------- | ------------ |
** AMI main        | `#D62828` | Heart red    |
** AMI male        | `#A4161A` | Deep red     |
** AMI female      | `#F77F00` | Coral orange |
** Stroke main     | `#6A4C93` | Brain purple |
** Stroke male     | `#472D75` | Deep violet  |
** Stroke female   | `#9C89B8` | Lavender     |
** Highlight       | `#FFBA08` | Amber        |
** Baseline / mean | `#8D99AE` | Cool grey    |
** Background      | `#FAFAFA` | Off-white    |
** Text            | `#2E2E2E` | Charcoal     |
** Dark frame      | `#1D3557` | Navy         |
#delimit ; 
colorpalette    #A4161A #D46A6A #EF5350 #F7A6A3 
                #472D75 #8B6FB4 #9C89B8 #C9B6E4
                #FFBA08 #8D99AE #FAFAFA #2E2E2E #1D3557, nograph;
#delimit cr
local list r(p) 
** AMI
global ami_m `r(p1)'
global ami_m70 `r(p2)'
global ami_f `r(p3)'
global ami_f70 `r(p4)'
** Stroke
global str_m `r(p5)'
global str_m70 `r(p6)'
global str_f `r(p7)'
global str_f70 `r(p8)'
** Others
global highlight `r(p9)'
global baseline  `r(p10)'
global background `r(p11)'
global text       `r(p12)'
global darkframe  `r(p13)'


** Unicode markers for graphics
** Numbers = HTML numerics
/// †  	U+2020 (alt-08224)	DAGGER = obelisk, obelus, long cross
/// ‡  	U+2021 (alt-08225)	DOUBLE DAGGER = diesis, double obelisk
/// •  	U+2022 (alt-08226)	BULLET = black small circle
global dagger = uchar(8224)
global ddagger = uchar(8225)
global sbullet = uchar(8226)
global mbullet = uchar(9679)
global lbullet = uchar(11044)
global tbullet = uchar(9675)
global fisheye = uchar(9673)
global section = uchar(0167) 
global teardrop = uchar(10045) 
global flower = uchar(8270)
global endash = uchar(8211)
global emdash = uchar(8212)