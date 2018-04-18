qui {

/********************************************************
* Last Modified:  02/03/16  by Wenfeng Gong
* File Name:      C:\Google Drive\IVAC - Vaccination Coverage Survey\Data\Automated_Data_Monitoring_Cleaning\code\Data_correction_Form1.do
********************************************************/

capture log c
log using "Program_running_log\Data_correction_Form1.log", replace
noi di "***Data_correction_Form1***"

tempfile form1temp
use "$tempdata\form1temp.dta", clear
		save `form1temp', replace 

copy "Data_change_log\Form1_change_log.xlsx" "Data_change_log\backup\Form1_change_log_backup_$S_DATE.xlsx", replace

tempfile form2temp
use "$tempdata\form2temp.dta", clear
		save `form2temp', replace 

copy "Data_change_log\Form2_change_log.xlsx" "Data_change_log\backup\Form2_change_log_backup_$S_DATE.xlsx", replace

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

/* merging method; abandoned
levelsof variable, local(vartoedit)
foreach i of local vartoedit {
	di "`i'"
	gen `i'_old=""
	gen `i'_new=""
	replace `i'_old=original if variable=="`i'"
	replace `i'_new=new if variable=="`i'"
}*/

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

// delete testing ids
drop if substr(f1_0,3,1)=="0" & substr(f1_0,9,1)=="0"

// special changes that cannot be handled by the system
replace f1_1_1=2 if f1_0=="111-007-404" & f1_1_3=="15"
replace f1_1_1=2 if f1_0=="213-220-006" & f1_1_2=="26-04-16"
replace f1_1_1=2 if f1_0=="124-192-604" & f1_1_2=="25-03-16"
replace f1_1_1=2 if f1_0=="124-192-612" & f1_1_2=="25-03-16"
replace f1_1_1=2 if f1_0=="124-063-607" & f1_1_2=="10-05-16"
replace f1_1_1=2 if f1_0=="124-210-601" & f1_1_2=="25-03-16"
replace f1_1_1=3 if f1_0=="221-274-710" & f1_1_2=="21-05-16"
replace f1_1_1=3 if f1_0=="221-381-303" & f1_1_2=="21-05-16"
replace f1_1_1=4 if f1_0=="232-449-405" & f1_1_2=="21-05-16"
drop if f1_0=="111-007-405" & f1_1_4s==1
drop if f1_0=="124-192-604" & f1_1_4s==0 & f1_1_2=="30-05-16"
replace f1_1_1=5 if f1_0=="213-095-406" & f1_1_2=="31-05-16"
replace latitude="24.8166483" if f1_0=="124-192-612" & f1_1_1==2
replace longitude="67.1094866" if f1_0=="124-192-612" & f1_1_1==2
replace f1_1_1=4 if f1_0=="124-192-603" & f1_1_2=="02-06-16"
drop if f1_0=="124-146-519" & f1_1_4s==1 & f1_1_1==3 & f1_1_2=="03-02-16"
drop if f1_0=="124-308-514" & f1_1_4s==5 & f1_1_1==2 & f1_1_2=="03-06-16"
drop if f1_0=="232-587-414" & f1_1_4s==0 & f1_1_1==2 & f1_1_2=="04-06-16"
drop if f1_0=="133-103-501" & f1_1_4s==0 & f1_1_1==1 & f1_1_2=="19-07-16"
replace longitude="67.1331883" if f1_0=="323-249-611" & f1_1_1==1
replace f1_1_1=3 if f1_0=="312-291-426" & f1_1_2=="30-07-16" & f1_1_1==2
replace f1_1_1=3 if f1_0=="234-081-304" & f1_1_2=="03-06-16" & f1_1_1==2
replace f1_0="234-081-604" if f1_0=="234-081-304" & f1_1_2=="03-06-16" & f1_1_1==3

ds date_changed changed_by, not
duplicates drop `r(varlist)',force

save "$tempdata\form1temp.dta", replace
use `form2temp',clear
duplicates drop
save "$tempdata\form2temp.dta", replace

exit 

