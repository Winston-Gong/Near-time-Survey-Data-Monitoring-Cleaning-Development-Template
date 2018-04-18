qui {
/********************************************************
* Last Modified:  02/02/16  by Wenfeng Gong
* File Name:      C:\Google Drive\IVAC - Vaccination Coverage Survey\Data\Automated_Data_Monitoring_Cleaning\code\Data_cleaning_Form1.do
********************************************************/

capture log c
log using "Program_running_log\Data_cleaning_Form1.log", replace
noi di "***Data_cleaning_Form1***"

use "$tempdata\form1temp.dta", clear

//for some technical reasons, duplicate data may be submitted 
duplicates drop 

cap drop v18

lab define no2yes1 ///
		0 "NO" ///
		1 "YES" 

lab define interviewoutcome ///
	0 "Confirmed NO eligible child" ///
	1 "Interview complete" ///
	2 "Primary caregiver not at home/absent" ///
	3 "Postponed with specific return date" ///
	4 "Postponed without return date" ///
	5 "Migrated out" ///
	6 "Refused to participate: Screening NOT done" ///
	7 "Refused to participate: Screening complete" ///
	8 "Consented & interview partly completed: will complete later" ///
	9 "Consented & interview partly completed: will not complete" ///
	10 "Previously visited HH with NO child enrolled" ///
	11 "Previously visited HH with child enrolled" ///
	12 "Skipped household because unsafe to visit" ///
	13 "Other (recode needed)" ///
	14 "No answer door (reason unknown)" ///
	15 "Confirmed no residents" ///
    16 "Primary caregiver never at home for revisit" ///
    17 "Primary caregiver below 18" 

lab value f1_1_4status interviewoutcome
lab var f1_1_4status "HH Visit Outcome"
lab var f1_1_4_2 "List of other HH visit outcomes"
lab var f1_0 "HH_ID"
lab var f1_1_1 "Visit_Num"
lab var f1_1_2 "Visit_Date"
lab var f1_1_3 "FW_ID"
lab var f1_1_5 "Return_Date"

cap destring f1_1_3, replace force
destring f1_5, replace force

gen surveymethod=substr(f1_0,2,1)
destring surveymethod, replace
lab define surveymethod ///
	1 "EPI" ///
	2 "CS" ///
	3 "GIS" ///
	4 "LQAS"
lab value surveymethod surveymethod

gen norevisitneed=0
replace norevisitneed=1 if ///
	inlist(f1_1_4status,0,1,5,9,10,11,12,15,16,17) | /// these codes will NOT be revisited
	(f1_1_4status==6 & f1_5revisit!=1) | ///
	(f1_1_4status==7 & f1_5revisit!=1) 

bysort f1_0: gen maxvisit=_N // latest visit number of the HH

gen clusterid=substr(f1_0,5,3)
gen round=substr(f1_0,1,1)
	destring round, replace
gen visitdate=date(f1_1_2,"DM20Y")
	format visitdate %td_D-N-Y


save "$cleandata\Form1_clean.dta",replace
copy "$cleandata\Form1_clean.dta" "$backupdata\Form1_clean_backup_$S_DATE.csv", replace

************** create spreadsheet for translation of comments *************

use "$cleandata\Form1_clean.dta",clear
ds f1_1_4_2status_other refusal_reason_other f1_6comment
tempfile tempf
foreach i of var `r(varlist)' {
	preserve
		keep f1_0house_code f1_1_1 `i'
		gen  variable="`i'"
		gen new=""
		ren `i' original
		drop if trim(lower(original))=="" | trim(lower(original))=="null"
		cap append using `tempf'
		save `tempf',replace
	restore
}
use `tempf',clear
sort original
gen ID=_n
order ID f1_0house_code f1_1_1 variable original new

save `tempf',replace
local filelist: dir "Entered_data\" files "Comment_Translation_Form1_*.xlsx", respectcase
foreach filenam of local filelist {
	import excel using "Entered_data/`filenam'",clear firstrow
	drop if variable==""
	mmerge f1_0house_code f1_1_1 variable using `tempf', type(1:n) unmatched(using)
	drop if _merge==3
	save `tempf',replace
}
use `tempf',clear

cap export excel using "Entered_data\Comment_Translation_Form1.xlsx",replace firstrow(variables)

************** incorporate spreadsheet for translation of comments *************
tempfile tempf2
local filelist: dir "Entered_data\" files "Comment_Translation_Form1_*.xlsx", respectcase
foreach filenam of local filelist {
	import excel using "Entered_data/`filenam'",clear firstrow
	drop if variable==""
	drop ID
	ren original o
	ren new n
	cap drop _merge
	cap tostring n, replace
	replace n="" if trim(n)=="."
	reshape wide o n, i(f1_0house_code f1_1_1) j(variable) string 
	save `tempf2',replace
	use "$cleandata\Form1_clean.dta",clear
	mmerge f1_0house_code f1_1_1 using `tempf2', type(n:1) unmatched(master) update replace
	
	ds f1_1_4_2status_other refusal_reason_other f1_6comment
	foreach i of var `r(varlist)' {
		cap gen `i'_old=""
		cap order `i'_old, after(`i')
		cap replace `i'_old=o`i' if o`i'==`i' & trim(n`i')!=""
		cap replace `i'=n`i' if o`i'==`i' & trim(n`i')!=""
		cap drop n`i' o`i'
	}
	save "$cleandata\Form1_clean.dta",replace
}

exit
