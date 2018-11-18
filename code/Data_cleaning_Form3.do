qui {
/********************************************************
* Last Modified:  11/14/18  by Wenfeng Gong
* Project Name:   Near-time data inspection tool (template)
* File Name:      Data_cleaning_Form3.do 
********************************************************/

capture log c
log using "Program_running_log\Data_cleaning_Form3.log", replace
noi di "***Data_cleaning_Form3***"

use "$tempdata\form3temp.dta", clear

//for some technical reasons, duplicate data may be submitted 
duplicates drop 

//merge in some essential data from Form1&2
mmerge f3_a0_1 using "$cleandata\Form2_clean.dta", type(n:n) ///
		 umatch(f1_0) unmatched(master) ///
		ukeep(f2_7_1 childageinmonths childageindays interviewdate) 
ren f2_7_1 exactchildbirthdate
	recode exactchildbirthdate (99=9) (1=1) (2=0)

//essential variable name and format changes
cap drop f3_c9_1cliniccodepenta* 
cap drop v58 v62 v66 v70 v74
cap ren f3_c9_2additionalvaccinationcoun f3_c9_2_1addvxcountpenta1
cap ren f3_c9_3additionalvaccinationname f3_c9_3_1addvxnamepenta1
cap ren v63 f3_c9_2_2addvxcountpenta2
cap ren v64 f3_c9_3_2addvxnamepenta2
cap ren v67 f3_c9_2_3addvxcountpenta3
cap ren v68 f3_c9_3_3addvxnamepenta3
cap ren v71 f3_c9_2_4addvxcountpenta4
cap ren v72 f3_c9_3_4addvxnamepenta4
cap ren v75 f3_c9_2_5addvxcountpenta5
cap ren v76 f3_c9_3_5addvxnamepenta5
ds f3_c7_2* f3_c7_3* f3_c9_2* f3_c9_3*
foreach var in `r(varlist)' {
	local newname=substr("`var'",1,7) + "_" + substr("`var'",length("`var'"),1)+substr("`var'",8,.)
	ren `var' `newname'
}
ds f3_c13_2* f3_c16_2* f3_c22_3* f3_c25_3* f3_c25_2*
foreach var in `r(varlist)' {
	local newname=substr("`var'",1,8) + "_" + substr("`var'",length("`var'"),1)+substr("`var'",9,.)
	ren `var' `newname'
}
ds  f3_b3t f3_b4 f3_b5t f3_b6_1ttmonth f3_b6_2ttyear f3_b9 f3_c6 ///
	f3_c7_2_* f3_c8 f3_c9_2_* f3_c12 f3_c15 f3_c17 f3_c19 f3_c22_1 ///
	f3_c24 f3_c25_2_* f3_c28m f3_d3 f3_h2c
foreach var in `r(varlist)' {
	cap destring `var', force replace
}
ds f3_a0_2surveychildid cliniccodeother* f3_c13_2* f3_c16_2* f3_c22_3* f3_c25_3* ///
		measlesdiagnosedatother 
foreach var in `r(varlist)' {
	cap tostring `var', replace
}

save "$cleandata\Form3_clean.dta",replace
copy "$cleandata\Form3_clean.dta" "$backupdata\Form3_clean_backup_$S_DATE.dta", replace

//****create a HHID+ChildID listing by merge HH list Form 1 and child questionaire Form 3 *******
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
export excel using "Program_running_log\Household & Child ID List from Form3.xlsx",replace firstrow(variables)


exit
