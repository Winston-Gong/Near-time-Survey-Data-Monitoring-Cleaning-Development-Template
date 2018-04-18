qui {
/********************************************************
* Last Modified:  03/24/16  by Wenfeng Gong
********************************************************/

capture log c
log using "Program_running_log\Data_cleaning_Form4.log", replace
noi di "***Data_cleaning_Form4***"

use "$tempdata\form4temp.dta", clear


sort f4_a1 f4_a0_2
by f4_a1: gen maxbloodtry=_N

//treat time variable
replace f4_b2=lower(f4_b2)
replace f4_b2=subinstr(f4_b2,";",":",1)
replace f4_b2=subinstr(f4_b2,".",":",1)
gen hour=substr(f4_b2,1,strpos(f4_b2,":")-1)
destring hour,replace force
replace hour=hour+12 if hour>=0 & hour<=7
replace hour=hour-12 if hour!=. & hour!=99 & hour>=20
tostring hour,replace format(%02.0f)
replace f4_b2=hour+substr(f4_b2,strpos(f4_b2,":"),.)
gen Form4time=clock(f4_b2,"hm")
	format Form4time %tc_HH:MM
drop f4_b2collectiontime hour
ren Form4time f4_b2collectiontime

lab define bloodoutcome ///
	1 "Blood collection successful" ///
	2 "Difficulty-postponed" ///
	3 "Difficulty-NOT return" ///
	4 "Not attempted; postponed w/ return date" ///
	5 "Not attempted; postponed w/o return date" ///
	6 "Refused to participate: Section A NOT completed" ///
	7 "Refused to participate: Section A completed" ///
	8 "Others" ///
	9 "Complete refusal" ///
	10 "Cannot find caregiver" ///
	11 "Confirmed migrated" ///
	12 "House locked"
lab value f4_b1_3 bloodoutcome

lab define bloodproblem ///
	1 "No blood: moving too much" ///
	2 "No blood: cried inconsolably" ///
	3 "No blood: stoped in middle" ///
	4 "Insufficient blood: moving too much" ///
	5 "Insufficient blood: clotting" ///
	6 "Insufficient blood: stoped in middle" ///
	7 "Others" ///
	8 "Insufficient blood: child is anemic" ///
	9 "Insufficient blood: reason unknown" ///
	10 "Insufficient blood: Nurse did not draw blood correctly" ///
	11 "No blood: child is anemic"
lab value f4_b3c bloodproblem

save "$cleandata\Form4_clean.dta",replace
copy "$cleandata\Form4_clean.dta" "$backupdata\Form4_clean_backup_$S_DATE.csv", replace

************** create spreadsheet for translation of comments *************
use "$cleandata\Form4_clean.dta",clear
ds f4_a4_1_7_1nameothervaccine f4_b1_4othercollectionresult ///
	f4_b3_2othercollectionproblem f4_ccollection_comment
tempfile tempf
foreach i of var `r(varlist)' {
	preserve
		keep f4_a0collecthousecode f4_a0_2visittype f4_a1collectchildid `i'
		gen  variable="`i'"
		gen new=""
		ren `i' original
		drop if trim(lower(original))=="" | trim(lower(original))=="null" | trim(lower(original))=="ok"
		cap append using `tempf'
		save `tempf',replace
	restore
}
use `tempf',clear
gen ID=_n
order ID f4_a0collecthousecode f4_a0_2visittype f4_a1collectchildid variable original new
sort f4_a0collecthousecode f4_a0_2visittype f4_a1collectchildid variable ID
save `tempf',replace

local filelist: dir "Entered_data\" files "Comment_Translation_Form4_*.xlsx", respectcase
foreach filenam of local filelist {
	import excel using "Entered_data/`filenam'",clear firstrow
	drop if variable==""
	mmerge f4_a0collecthousecode f4_a0_2visittype f4_a1collectchildid variable using `tempf', type(1:n) unmatched(using)
	drop if _merge==3
	sort f4_a0collecthousecode f4_a0_2visittype f4_a1collectchildid variable ID
	save `tempf',replace
}
use `tempf',clear
sort original
cap export excel using "Entered_data\Comment_Translation_Form4.xlsx",replace firstrow(variables)

************** incorporate spreadsheet for translation of comments *************
tempfile tempf2
local filelist: dir "Entered_data\" files "Comment_Translation_Form4_*.xlsx", respectcase
foreach filenam of local filelist {
	import excel using "Entered_data/`filenam'",clear firstrow
	drop if variable==""
	drop ID
	ren original o
	ren new n
	cap drop _merge
	cap tostring n, replace
	replace n="" if trim(n)=="."
	reshape wide o n, i(f4_a0collecthousecode f4_a0_2visittype f4_a1collectchildid) j(variable) string 
	save `tempf2',replace
	use "$cleandata\Form4_clean.dta",clear
	mmerge f4_a0collecthousecode f4_a0_2visittype f4_a1collectchildid using `tempf2', type(n:1) unmatched(master) update replace
	
	ds f4_a4_1_7_1nameothervaccine f4_b1_4othercollectionresult ///
		f4_b3_2othercollectionproblem f4_ccollection_comment
	foreach i of var `r(varlist)' {
		cap gen `i'_old=""
		cap order `i'_old, after(`i')
		cap replace `i'_old=o`i' if o`i'==`i' & trim(n`i')!=""
		cap replace `i'=n`i' if o`i'==`i' & trim(n`i')!=""
		cap drop n`i' o`i'
	}
	save "$cleandata\Form4_clean.dta",replace
}


exit
