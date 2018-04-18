qui {
/********************************************************
* Last Modified:  03/24/16  by Wenfeng Gong
********************************************************/

capture log c
log using "Program_running_log\Data_cleaning_Form3.log", replace
noi di "***Data_cleaning_Form3***"

use "$tempdata\form3temp.dta", clear

//for some technical reasons, duplicate data may be submitted 
duplicates drop 

//complete variable index name
ds f3_a1_3* f3_a1_2* 
foreach var in `r(varlist)' {
	local newname=substr("`var'",1,7) + "_" + substr("`var'",length("`var'"),1)+substr("`var'",8,.)
	ren `var' `newname'
}
/*ds 
foreach var in `r(varlist)' {
	local newname=substr("`var'",1,8) + "_" + substr("`var'",length("`var'"),1)+substr("`var'",9,.)
	ren `var' `newname'
}
*/
// treat age variables
ds f3_a1_3* 
foreach var in `r(varlist)' {
	gen childby = trim(substr(`var', strpos(`var', " year")-1,1))
	destring childby,replace force
	gen childbm = trim(substr(`var', strpos(`var', " month")-2,2))
	destring childbm,replace force
	replace childby=0 if (childby==9 | childby==99 | childby==.) & childbm!=. & childbm!=99
	//replace childbm=99 if childbm==.
	local newvar=substr("`var'",1,9)+"mon" 
	gen `newvar'=childby*12+childbm if childby!=9 & childby!=99
	replace `newvar'=childby*12+6 if childby!=9 & childby!=99 & childbm==99
	replace `newvar'=childby*12+0 if childby!=9 & childby!=99 & childbm==.
	replace `newvar'=. if (childby==9 | childby==99 | childby==.) & childbm==99
	drop childby childbm
	order `newvar', after(`var')
}

ds f3_d2_3*
foreach var in `r(varlist)' {
	replace `var'="null" if f3_d1!=1 & `var'=="MISS" & substr(f3_a0_1,1,1)=="1"
}
ds f3_d2_4*
foreach var in `r(varlist)' {
	replace `var'="null" if f3_d1!=1 & `var'=="0--" & substr(f3_a0_1,1,1)=="1"
}

//delete vaccine card observations if card is verified invalid
ds f3_d2_3*
foreach var in `r(varlist)' {
	replace `var'="DONT KNOW" if f3_d1==8
}
ds f3_d2_4*
foreach var in `r(varlist)' {
	replace `var'="null" if f3_d1==8
}

//get some essential data from Form1&2
mmerge f3_a0_1 using "$cleandata\Form2_clean.dta", type(n:n) ///
		 umatch(f1_0) unmatched(master) ///
		ukeep(f2_7_1 childageinmonths childageindays interviewdate) 
ren f2_7_1 exactchildbirthdate
	recode exactchildbirthdate (99=9) (1=1) (2=0)

save "$cleandata\Form3_clean.dta",replace
copy "$cleandata\Form3_clean.dta" "$backupdata\Form3_clean_backup_$S_DATE.dta", replace

//************check age variable ************
use "$cleandata\Form3_clean.dta",clear
keep if exactchildbirthdate!=1
keep f3_a0_1surveyhousecode f3_a0_2surveychildid childageinmonths interviewdate childageindays
export excel using "Data_progress_report\Child age need cross-check.xlsx",replace firstrow(variables) datestring("%td_D-N-Y")

//************HHID+ChildID listing*****************
use "$cleandata\Form3_clean.dta",clear
keep f3_a0_1 f3_a0_2 
noi duplicates drop f3_a0_1, force //be very cautious here, the data is not clean
noi duplicates drop f3_a0_2, force //be very cautious here, the data is not clean
tempfile tempfile 
	save `tempfile', replace 
	
use "$cleandata\Form1_clean.dta", replace
keep if f1_1_1==maxvisit
keep f1_0 f1_1_1 f1_1_3 f1_1_2 f1_1_4s
ren f1_0 f3_a0_1surveyhousecode
duplicates drop f3_a0_1, force

mmerge f3_a0_1surveyhousecode using `tempfile', type(1:1) unmatched(using)
drop _merge
export excel using "Entered_data\Household & Child ID List from Form3.xlsx",replace firstrow(variables)

************** create spreadsheet for translation of comments *************
use "$cleandata\Form3_clean.dta",clear
ds f3_b7_2birthplaceother cliniccodeotherpenta1 cliniccodeotherpenta2 cliniccodeotherpenta3 ///
	cliniccodeotherpenta4 cliniccodeotherpenta5 cliniccodeothermeasles1 ///
	cliniccodeothermeasles2 cliniccodeothermeasles3 cliniccodeothermeasles4 ///
	cliniccodeothermeasles5 measlesdiagnosedatother f3_c30othervaccinationname ///
	f3_e1_2headethnicityother f3_e7fatheroccupation f3_e8motheroccupation ///
	f3_f3_1otherenrolledname f3_f4_2gocentrewithother f3_f5_2gocentreviaother ///
	f3_f8_2clinicvisitcareother f3_f9_2clinicvisitsickother f3_f10_2goclinicviaother ///
	f3_g3_1toiletother f3_g6_1fuleforcookingother floorother ///
	roofother wallother f3_i1comment
tempfile tempf
foreach i of var `r(varlist)' {
	preserve
		di "`i'"
		keep f3_a0_1surveyhousecode f3_a0_2surveychildid `i'
		gen  variable="`i'"
		gen new=""
		ren `i' original
		drop if trim(lower(original))=="" | trim(lower(original))=="null" | trim(lower(original))=="ok" | trim(lower(original))=="$$$$"
		cap append using `tempf'
		save `tempf',replace
	restore
}
use `tempf',clear
sort original
gen ID=_n
order ID f3_a0_1surveyhousecode f3_a0_2surveychildid variable original new

save `tempf',replace
local filelist: dir "Entered_data\" files "Comment_Translation_Form3_*.xlsx", respectcase
foreach filenam of local filelist {
	import excel using "Entered_data/`filenam'",clear firstrow
	drop if variable==""
	mmerge f3_a0_1surveyhousecode f3_a0_2surveychildid variable using `tempf', type(1:n) unmatched(using)
	drop if _merge==3
	save `tempf',replace
}
use `tempf',clear

cap export excel using "Entered_data\Comment_Translation_Form3.xlsx",replace firstrow(variables)

************** incorporate spreadsheet for translation of comments *************
tempfile tempf2
local filelist: dir "Entered_data\" files "Comment_Translation_Form3_*.xlsx", respectcase
foreach filenam of local filelist {
	import excel using "Entered_data/`filenam'",clear firstrow
	drop if variable==""
	drop ID
	ren original o
	ren new n
	cap drop _merge
	cap tostring n, replace
	replace n="" if trim(n)=="."
	reshape wide o n, i(f3_a0_1surveyhousecode f3_a0_2surveychildid) j(variable) string 
	save `tempf2',replace
	use "$cleandata\Form3_clean.dta",clear
	mmerge f3_a0_1 f3_a0_2 using `tempf2', type(n:1) unmatched(master) update replace
	
	ds f3_b7_2birthplaceother cliniccodeotherpenta1 cliniccodeotherpenta2 cliniccodeotherpenta3 ///
		cliniccodeotherpenta4 cliniccodeotherpenta5 cliniccodeothermeasles1 ///
		cliniccodeothermeasles2 cliniccodeothermeasles3 cliniccodeothermeasles4 ///
		cliniccodeothermeasles5 measlesdiagnosedatother f3_c30othervaccinationname ///
		f3_e1_2headethnicityother f3_e7fatheroccupation f3_e8motheroccupation ///
		f3_f3_1otherenrolledname f3_f4_2gocentrewithother f3_f5_2gocentreviaother ///
		f3_f8_2clinicvisitcareother f3_f9_2clinicvisitsickother f3_f10_2goclinicviaother ///
		f3_g3_1toiletother f3_g6_1fuleforcookingother floorother ///
		roofother wallother f3_i1comment
	foreach i of var `r(varlist)' {
		cap gen `i'_old=""
		cap order `i'_old, after(`i')
		cap replace `i'_old=o`i' if o`i'==`i' & trim(n`i')!=""
		cap replace `i'=n`i' if o`i'==`i' & trim(n`i')!=""
		cap drop n`i' o`i'
	}
	save "$cleandata\Form3_clean.dta",replace
}


exit
