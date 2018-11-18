qui {
/********************************************************
* Last Modified:  11/14/18  by Wenfeng Gong
* Project Name:   Near-time data inspection tool (template)
* File Name:      Data_correction_Form2.do
********************************************************/

capture log c
log using "Program_running_log\Data_correction_Form2.log", replace
noi di "***Data_correction_Form2***"

tempfile form2temp
use "$tempdata\form2temp.dta", clear
		save `form2temp', replace 

//***** Read Form 2 change log ************
import excel using "Data_change_log\Form2_change_log.xlsx",clear firstrow
cap ren F1_0HOUSE_CODE f1_0house_code
cap drop if f1_0=="" 
replace variable=lower(variable)
replace delete_record="NO" if delete_record==""
replace delete_record="NO" if lower(delete_record)=="no"
replace delete_record="YES" if lower(delete_record)=="yes"
replace f1_0=trim(f1_0)
replace original=trim(original)
replace new=trim(new)
replace delete=trim(delete)
cap tostring change_made, force replace

//***** Align variables in change log and dataset ************
replace variable="f1_0house_code" if variable=="f1_0"
replace variable="f2_2interviewdate" if variable=="f2_2"
replace variable="f2_3interviewtime" if variable=="f2_3"
replace variable="f2_4childrencount12to23" if variable=="f2_4"
replace variable="f2_5caregiverpresence" if variable=="f2_5"
replace variable="f2_6rescheduled" if variable=="f2_6"
replace variable="f2_7_1childbirthdayagerecall" if variable=="f2_7_1"
replace variable="f2_7_2childbirthdate" if variable=="f2_7_2"
replace variable="f2_7_3childage" if variable=="f2_7_3"
replace variable="f2_8_1caregiverbirthmonth" if variable=="f2_8_1"
replace variable="f2_8_2caregiverbirthyear" if variable=="f2_8_2"
replace variable="f2_9caregiverage" if variable=="f2_9"
replace variable="f2_10caregiverchildrelation" if variable=="f2_10"
replace variable="f2_10_2caregiverchildrelationoth" if variable=="f2_10_2"
replace variable="f2_11comment" if variable=="f2_11"

//***** Make changes according to change log ************
forvalues i= 1/`=_N' {
	local LOGID=ID[`i']
	local HH_ID=f1_0house_code[`i']
	local Variable=variable[`i']
	local Original=original[`i']
	local New=new[`i']
	local Delete=delete[`i']
	local checkchange="ERROR"
	preserve 
		use `form2temp',clear
		if "`Delete'"=="YES" {
			local datalength=_N
			drop if (f1_0=="`HH_ID'") 
			if `datalength'==_N+1 {
				local checkchange="PASS"
			}
		}
		else {
			cap confirm string variable `Variable'
                if _rc {
					count if (f1_0=="`HH_ID'") & (abs(`Variable'-`Original')<0.000001 | (`Variable'==. & `Original'==.))
					replace `Variable' = `New' if (f1_0=="`HH_ID'")  & (abs(`Variable'-`Original')<0.000001 | (`Variable'==. & `Original'==.))
                }
				else {
					count if (f1_0=="`HH_ID'") & (`Variable'==trim("`Original'"))
					replace `Variable' = "`New'" if (f1_0=="`HH_ID'")  & (`Variable'==trim("`Original'"))
				}
			if r(N)==1 { 
				local checkchange="PASS" 
			}
		}
		save `form2temp',replace
	restore
	replace change_made="`checkchange'" if _n==`i'
	noi di "Form 2 Change request ID=`LOGID' `checkchange'"
}
cap erase "Data_change_log\Form2_change_log.xlsx"
export excel using "Data_change_log\Form2_change_log.xlsx",replace firstrow(varlabels)

use `form2temp',clear

//***** Make special changes that cannot be handled by change log ************
drop if f1_0=="111-007-405" & f2_4c==1

//***** Save edited Form 2 ************
duplicates drop
save "$tempdata\form2temp.dta", replace

exit 

