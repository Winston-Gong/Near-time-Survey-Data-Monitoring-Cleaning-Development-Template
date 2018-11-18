qui {

/********************************************************
* Last Modified:  11/14/18  by Wenfeng Gong
* Project Name:   Near-time data inspection tool (template)
* File Name:      Data_correction_Form1.do
********************************************************/

capture log c
log using "Program_running_log\Data_correction_Form1.log", replace
noi di "***Data_correction_Form1***"

//***** Backup Form 1 and 2 change logs ************
tempfile form1temp
use "$tempdata\form1temp.dta", clear
		save `form1temp', replace 
copy "Data_change_log\Form1_change_log.xlsx" "Data_change_log\backup\Form1_change_log_backup_$S_DATE.xlsx", replace

tempfile form2temp
use "$tempdata\form2temp.dta", clear
		save `form2temp', replace 
copy "Data_change_log\Form2_change_log.xlsx" "Data_change_log\backup\Form2_change_log_backup_$S_DATE.xlsx", replace

//***** Read Form 1 change log ************
import excel using "Data_change_log\Form1_change_log.xlsx",clear firstrow
cap ren F1_0HOUSE_CODE f1_0house_code
cap ren F1_1_1VISIT_NO f1_1_1visit_no
cap drop if f1_0=="" | f1_1_1==.
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
replace variable="f1_1_1visit_no" if variable=="f1_1_1"
replace variable="f1_1_2visit_datetime" if variable=="f1_1_2"
replace variable="f1_1_3field_worker" if variable=="f1_1_3"
replace variable="f1_1_4status" if variable=="f1_1_4"
replace variable="f1_1_4_2status_other" if variable=="f1_1_4_2"
replace variable="f1_1_5return_datetime" if variable=="f1_1_5"
replace variable="f1_1_6previous_child_id" if variable=="f1_1_6"
replace variable="f1_2randomization_result" if variable=="f1_2"
replace variable="f1_3children_count_2orless" if variable=="f1_3"
replace variable="f1_4refusal_reason" if variable=="f1_4"
replace variable="f1_5revisit" if variable=="f1_5"
replace variable="f1_6comment" if variable=="f1_6"

//***** Make changes according to change log ************
//***** Form 2 id is changed at same time as Form 1 ****
forvalues i= 1/`=_N' {
	local LOGID=ID[`i']
	local HH_ID=f1_0house_code[`i']
	local VisitNum=f1_1_1visit_no[`i']
	local Variable=variable[`i']
	local Original=original[`i']
	local New=new[`i']
	local Delete=delete[`i']
	local checkchange="ERROR"
	preserve 
		use `form1temp',clear
		if "`Delete'"=="YES" {
			local datalength=_N
			drop if (f1_0=="`HH_ID'") & (f1_1_1==`VisitNum') 
			if `datalength'==_N+1 {
				local checkchange="PASS"
			}
		}
		else {
			cap confirm string variable `Variable'
                if _rc {
					count if (f1_0=="`HH_ID'") & (f1_1_1==`VisitNum') & (abs(`Variable'-`Original')<0.000001 | (`Variable'==. & `Original'==.))
					replace `Variable' = `New' if (f1_0=="`HH_ID'") & (f1_1_1==`VisitNum') & (abs(`Variable'-`Original')<0.000001 | (`Variable'==. & `Original'==.))
                }
				else {
					count if (f1_0=="`HH_ID'") & (f1_1_1==`VisitNum') & (`Variable'==trim("`Original'"))
					replace `Variable' = "`New'" if (f1_0=="`HH_ID'") & (f1_1_1==`VisitNum') & (`Variable'==trim("`Original'"))
				}
			if r(N)==1 { 
				local checkchange="PASS" 
			}
		}
		save `form1temp',replace
		if strpos("`Variable'","f1_0")>0 {
			use `form2temp',clear
			replace f1_0 = "`New'" if f1_0 == "`Original'"
			save `form2temp',replace
		}
	restore
	replace change_made="`checkchange'" if _n==`i'
	noi di "Form 1 Change request ID=`LOGID' `checkchange'"
}

cap erase "Data_change_log\Form1_change_log.xlsx"
export excel using "Data_change_log\Form1_change_log.xlsx",replace firstrow(varlabels)

use `form1temp',clear

//***** Make special changes that cannot be handled by change log ************
drop if f1_0=="111-007-405" & f1_1_4s==1

//***** Save edited Form 1 and 2 ************
duplicates drop
save "$tempdata\form1temp.dta", replace
use `form2temp',clear
duplicates drop
save "$tempdata\form2temp.dta", replace

exit 

