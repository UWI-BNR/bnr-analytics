*--------------------------------------------------------------------
*  Barbados National Registry (BNR) Refit Consultancy
*  Refit Process Audit - Case Example 2
*--------------------------------------------------------------------
*  PURPOSE:
*  To highlight the poor DM/ folder and file structure.
*
*  AUTHOR:  IAN HAMBLETON
*  PROJECT: BNR Refit Consultancy
*  CREATED: 31-OCT-2025

** This DO file extends the QC and forensic review by examining file
** structures, duplicates, and internal inconsistencies across the
** 2023 BNR-CVD datasets.
**
** It:
**   - Scans sub-directories of the BNR document repository to explore
**   - Filename uniqueness.
**   - Duplicate folders and datasets stored in the document repository
**   - The idea was to highlight the poor folder and file structure in
**     the DM/ folder.
*--------------------------------------------------------------------

*--------------------------------------------------------------------
** IMPORTANT NOTE 
*--------------------------------------------------------------------
** THIS DO FILE WAS A ONE-OFF, TO EXPLORE THE POTENTIAL 2023 DATASETS
** FOR INCLUSION IN THE CUMULATIVE BNR-CVD DATASET
** IT IS NOT PART OF THE REGULAR ANALYTICS PIPELINE
*--------------------------------------------------------------------


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
   log using ${logs}\bnrcvd-2023-forensics2, replace 

   * Initialize 
   version 19 
   clear all
   set more off
** ----- END INITIALIZE DO FILE -------------------
** ------------------------------------------------


** Load dataset
** This represents the total *.dta files in the DM/ folder
** Listing created using "Eveything" software
** Search "*.dta" in "C:\yasuki\Sync\DM"
** Full pathnames then copied to Excel spreadsheet

** We now explore:
**      (a) How many files
**      (b) How many duplicates
**      (c) How many distinct dataset locations
import excel "${data}\dm-dta-filenames.xlsx", sheet("Sheet1") firstrow clear
rename CyasukiSyncDMStataStatado fullpath
** Strip path - just want filename for now 
generate filename = regexs(1) if regexm(fullpath, "([^/\\]+)$")
** And just the filepath - no filename
generate dirpath = regexs(1) if regexm(fullpath, "^(.*[\\/])[^\\/]+$")
drop fullpath 

** Filename uniqueness
preserve
	count
	sort filename
	gen file_dup = 0 
	replace file_dup = 1 if filename==filename[_n-1]
	** Number range of same file
	bysort filename : gen file_dup_num = _n 
	bysort filename : egen file_dup_tot = max(file_dup_num)
	gen unique = 0 
	replace unique = 1 if filename!=filename[_n-1]
	order unique file_dup file_dup_num file_dup_tot, after(filename)
	tab file_dup
	tab file_dup_num
	tab file_dup_tot
	keep if unique==1 
	tab file_dup_tot
	replace file_dup_tot = 10 if file_dup_tot>=10

	colorpalette #012169 #ffffff #c8102E #128BBF , nograph
	local list r(p) 
	** Primary
	local dblu `r(p1)'
	local whi `r(p2)'
	local red `r(p3)'
	local lblu `r(p4)'

	** Graphic of number of duplicate datasets
	#delimit ;
		histogram
			file_dup_tot
			,
				freq discrete barw(0.75) col(#596b6d)
				
				plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin) margin(l=2 r=2 b=0 t=0)) 		
				graphregion(color(gs16) ic(gs16) ilw(thin) lw(thin) margin(l=2 r=2 b=3 t=5)) 
				ysize(8) xsize(16)

				xlab(1(1)10, notick labs(`size') tlc(gs0) labc(gs2) notick nogrid glc(gs16))
				/// xscale(fill log lw(vthin) lc(gs2) range(10(1000)15010)) 
				xtitle("How many instances of each file?", size(`size') color(gs2) margin(l=1 r=1 t=1 b=1)) 

				ylab(0(200)1000,
				labc(gs2) labs(4) tstyle(major_notick) nogrid glc(gs2) angle(0) format(%9.0f))
				/// yscale(fill log lw(vthin) lc(gs2) ) 
				ytitle("", size(`size') color(gs2) margin(l=1 r=1 t=1 b=1)) 

				legend(off)
				name(figure1, replace);
				/// graph export "`outputpath'/figure4_`x'.png", replace width(4000);
				;
	#delimit cr	
	graph export "${graphs}\forensics2-figure1.jpg", replace width(2000)
restore 

** Filepaths containing datasets
sort dirpath 
	gen dir_dup = 0 
	replace dir_dup = 1 if dirpath==dirpath[_n-1]
	** Number range of same PATHS
	bysort dirpath : gen dir_dup_num = _n 
	bysort dirpath : egen dir_dup_tot = max(dir_dup_num)
	gen unique = 0 
	replace unique = 1 if dirpath!=dirpath[_n-1]
	order unique dir_dup dir_dup_num dir_dup_tot, after(dirpath)
	keep dirpath dir_dup dir_dup_tot
	keep if dir_dup==0
	count 
	tab dir_dup_tot





