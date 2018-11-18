qui {

/********************************************************
* Last Modified:  11/14/18  by Wenfeng Gong
* Project Name:   Near-time data inspection tool (template)
* File Name:      Data_correction_Form3.do 
********************************************************/
set more off
capture log c
log using "Program_running_log\Data_correction_Form3.log", replace
noi di "***Data_correction_Form3***"

tempfile form3temp
use "$tempdata\form3temp.dta", clear
cap tostring f3_a0_2surveychildid, force replace
		save `form3temp', replace 

copy "Data_change_log\Form3_change_log.xlsx" "Data_change_log\backup\Form3_change_log_backup_$S_DATE.xlsx", replace

//***** Read Form 3 change log ************
import excel using "Data_change_log\Form3_change_log.xlsx",clear firstrow allstring
cap ren F3_A0_1 f3_a0_1surveyhousecode
cap ren F3_A0_2 f3_a0_2surveychildid
cap drop if f3_a0_2=="" 
replace variable=lower(variable)
replace delete_record="NO" if delete_record==""
replace delete_record="NO" if lower(delete_record)=="no"
replace delete_record="YES" if lower(delete_record)=="yes"
replace f3_a0_1=trim(f3_a0_1)
replace f3_a0_2=trim(f3_a0_2)
replace original=trim(original)
replace new=trim(new)
replace delete=trim(delete)
cap tostring change_made, force replace

//***** Align variables in change log and dataset ************
replace variable="f3_a0_1surveyhousecode" if variable=="f3_a0_1"
replace variable="f3_a0_2surveychildid" if variable=="f3_a0_2"

//***** Make changes according to change log ************
forvalues i= 1/`=_N' {
	local LOGID=ID[`i']
	local HH_ID=f3_a0_1surveyhousecode[`i']
	local ChildID=f3_a0_2surveychildid[`i']
	local Variable=variable[`i']
	local Original=original[`i']
	local New=new[`i']
	local Delete=delete[`i']
	local checkchange="ERROR"
	preserve 
		use `form3temp',clear
		if "`Delete'"=="YES" {
			local datalength=_N
			drop if (f3_a0_1=="`HH_ID'") & (f3_a0_2=="`ChildID'") 
			if `datalength'==_N+1 {
				local checkchange="PASS"
			}
		}
		else {
			cap confirm string variable `Variable'
                if _rc {
					count if (f3_a0_1=="`HH_ID'") & (f3_a0_2=="`ChildID'") & (abs(`Variable'-`Original')<0.000001 | (`Variable'==. & `Original'==.))
					replace `Variable' = `New' if (f3_a0_1=="`HH_ID'") & (f3_a0_2=="`ChildID'") & (abs(`Variable'-`Original')<0.000001 | (`Variable'==. & `Original'==.))
                }
				else {
					count if (f3_a0_1=="`HH_ID'") & (f3_a0_2=="`ChildID'") & (`Variable'==trim("`Original'"))
					replace `Variable' = "`New'" if (f3_a0_1=="`HH_ID'") & (f3_a0_2=="`ChildID'") & (`Variable'==trim("`Original'"))
				}
			if r(N)==1 { 
				local checkchange="PASS" 
			}
		}
		save `form3temp',replace
	restore
	replace change_made="`checkchange'" if _n==`i'
	noi di "Form 3 Change request ID=`LOGID' `checkchange'"
}

cap erase "Data_change_log\Form3_change_log.xlsx"
export excel using "Data_change_log\Form3_change_log.xlsx",replace firstrow(varlabels)

use `form3temp',clear

***********************************************************************
//***** Make special changes that cannot be handled by change log ************

***********************************************************************
duplicates drop
save `form3temp',replace


//***** Save edited Form 3 ************
use `form3temp',clear
duplicates drop
save "$tempdata\form3temp.dta", replace

exit 

