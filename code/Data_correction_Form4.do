qui {

/********************************************************
* Last Modified:  03/28/16  by Wenfeng Gong
********************************************************/

capture log c
log using "Program_running_log\Data_correction_Form4.log", replace
noi di "***Data_correction_Form4***"

tempfile form4temp
use "$tempdata\form4temp.dta", clear
	//for some technical reasons, duplicate data may be submitted 
	duplicates drop 

	destring f4_b1_2, replace force
	replace f4_a0c="." if f4_a0c==""
	preserve
		import excel using "Entered_data\Household & Child ID List from Form3.xlsx" ///
				,clear firstrow allstring case(lower) 
		ren f3_a0_2surveychildid f4_a1collectchildid
		tempfile tempfile 
		save `tempfile', replace 
	restore
	mmerge f4_a1 using `tempfile', type(n:1) unmatched(master)
	replace f4_a0c=f3_a0_1 if f4_a0c=="."
	drop f3_a0_1
	drop _merge
		save `form4temp', replace 

import excel using "Data_change_log\Form4_change_log.xlsx",clear firstrow allstring
cap ren F4_A0 f4_a0collecthousecode
cap ren F4_A1 f4_a1collectchildid
cap ren F4_A0_2 f4_a0_2visittype
destring f4_a0_2, replace
cap drop if f4_a1=="" | f4_a0_2==.
replace variable=lower(variable)
replace delete_record="NO" if delete_record==""
replace delete_record="NO" if lower(delete_record)=="no"
replace delete_record="YES" if lower(delete_record)=="yes"
replace f4_a1=trim(f4_a1)
replace f4_a0c=trim(f4_a0c)
replace original=trim(original)
replace new=trim(new)
replace delete=trim(delete)
cap tostring change_made, force replace

replace variable="f4_a0collecthousecode" if variable=="f4_a0"
replace variable="f4_a0_2visittype" if variable=="f4_a0_2"
replace variable="f4_a1collectchildid" if variable=="f4_a1"

forvalues i= 1/`=_N' {
	local LOGID=ID[`i']
	local HH_ID=f4_a0collecthousecode[`i']
	local VisitNum=f4_a0_2visittype[`i']
	local ChildID=f4_a1collectchildid[`i']
	local Variable=variable[`i']
	local Original=original[`i']
	local New=new[`i']
	local Delete=delete[`i']
	local checkchange="ERROR"
	preserve 
		use `form4temp',clear
		if "`Delete'"=="YES" {
			local datalength=_N
			drop if (f4_a0c=="`HH_ID'") & (f4_a1=="`ChildID'") & (f4_a0_2==`VisitNum') 
			if `datalength'==_N+1 {
				local checkchange="PASS"
			}
		}
		else {
			cap confirm string variable `Variable'
                if _rc {
					count if (f4_a0c=="`HH_ID'") & (f4_a1=="`ChildID'") & (f4_a0_2==`VisitNum') & (abs(`Variable'-`Original')<0.000001 | (`Variable'==. & `Original'==.))
					replace `Variable' = `New' if (f4_a0c=="`HH_ID'") & (f4_a1=="`ChildID'") & (f4_a0_2==`VisitNum') & (abs(`Variable'-`Original')<0.000001 | (`Variable'==. & `Original'==.))
                }
				else {
					count if (f4_a0c=="`HH_ID'") & (f4_a1=="`ChildID'") & (f4_a0_2==`VisitNum') & (`Variable'==trim("`Original'"))
					replace `Variable' = "`New'" if (f4_a0c=="`HH_ID'") & (f4_a1=="`ChildID'") & (f4_a0_2==`VisitNum') & (`Variable'==trim("`Original'"))
				}
			if r(N)==1 { 
				local checkchange="PASS" 
			}
		}
		save `form4temp',replace
	restore
	replace change_made="`checkchange'" if _n==`i'
	noi di "Form 4 Change request ID=`LOGID' `checkchange'"
}

cap erase "Data_change_log\Form4_change_log.xlsx"
export excel using "Data_change_log\Form4_change_log.xlsx",replace firstrow(varlabels)

use `form4temp',clear

// delete testing ids
drop if substr(f4_a0c,3,1)=="0" & substr(f4_a0c,9,1)=="0"

// special changes that cannot be handled by the system
replace f4_a0_2=2 if f4_a0c=="122-184-509" & f4_a1=="25008" & f4_b1_1c=="14-05-16"
drop if f4_a0c=="213-183-406" & f4_a1=="34083" & f4_a0_2==2 & f4_b1_1c=="12-05-16"
drop if f4_a0c=="213-183-410" & f4_a1=="34084" & f4_a0_2==2 & f4_b1_1c=="12-05-16"
drop if f4_a0c=="234-579-602" & f4_a0_2==1 & f4_a1c=="46030" & f4_b2c=="02:30pm"
replace f4_a0_2=2 if f4_a0c=="221-286-728" & f4_a1=="17036" & f4_b1_1c=="04-06-16"
replace f4_a0_2=2 if f4_a0c=="221-274-710" & f4_a1=="17038" & f4_b1_1c=="04-06-16"
replace f4_a0_2=3 if f4_a0c=="543-011-411" & f4_a1=="34200" & f4_b1_1c=="21-12-16"

duplicates drop 
save "$tempdata\form4temp.dta", replace

exit 

