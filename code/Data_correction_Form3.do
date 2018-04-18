qui {

/********************************************************
* Last Modified:  11/14/16  by Wenfeng Gong
********************************************************/
set more off
capture log c
log using "Program_running_log\Data_correction_Form3.log", replace
noi di "***Data_correction_Form3***"

tempfile form3temp
use "$tempdata\form3temp.dta", clear
		save `form3temp', replace 

copy "Data_change_log\Form3_change_log.xlsx" "Data_change_log\backup\Form3_change_log_backup_$S_DATE.xlsx", replace

tempfile form4temp
use "$tempdata\form4temp.dta", clear
		save `form4temp', replace 

copy "Data_change_log\Form4_change_log.xlsx" "Data_change_log\backup\Form4_change_log_backup_$S_DATE.xlsx", replace

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

replace variable="f3_a0_1surveyhousecode" if variable=="f3_a0_1"
replace variable="f3_a0_2surveychildid" if variable=="f3_a0_2"

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
		if strpos("`Variable'","f3_a0_1")>0 {
			use `form4temp',clear
			replace f4_a0collecthousecode = "`New'" if (f4_a0collecthousecode == "`Original'") & (f4_a1collectchildid=="`ChildID'")
			save `form4temp',replace
			// also change vaccine card filename based on form 3 change log
				local Oripath="$datapath\cardimage\" + "`Original'" + ".png" 
				local newpath="$datapath\cardimage\" + "`New'" + ".png"
				local alterpath="$datapath\cardimage\" + "`New'" + "_1.png"
				cap copy "`Oripath'" "`newpath'"
				if _rc==602 {
					cap copy "`Oripath'" "`alterpath'"
				}
		}
		if strpos("`Variable'","f3_a0_2")>0 {
			use `form4temp',clear
			replace f4_a1collectchildid = "`New'" if (f4_a1collectchildid == "`Original'") & (f4_a0collecthousecode=="`HH_ID'")
			save `form4temp',replace
		}
	restore
	replace change_made="`checkchange'" if _n==`i'
	noi di "Form 3 Change request ID=`LOGID' `checkchange'"
}

cap erase "Data_change_log\Form3_change_log.xlsx"
export excel using "Data_change_log\Form3_change_log.xlsx",replace firstrow(varlabels)

use `form3temp',clear
// delete testing ids
drop if substr(f3_a0_1,3,1)=="0" & substr(f3_a0_1,9,1)=="0"

***********************************************************************
// special changes that cannot be handled by the system
drop if f3_a0_1=="221-384-716" & f3_a0_2=="17014" & dataenterer==""
drop if f3_a0_1=="232-356-413" & f3_c12p==7
drop if f3_a0_1=="232-356-413" & f3_f8_2=="Dr Iqbal"
drop if f3_a0_1=="232-449-402" & f3_a0_2=="24035" & f3_a1_2sex1==.
drop if f3_a0_1=="122-184-705" & f3_a0_2=="27008" & f3_a1_1childrencount==1
drop if f3_a0_1=="122-206-702" & f3_a0_2=="27016" & f3_a1_1childrencount==1

***********************************************************************
duplicates drop
save `form3temp',replace

// change error of vaccination card recording based on validation reading of the cards
import excel using "Data_change_log\Vaccination_card_change_log.xlsx",clear firstrow case(lower) allstring
drop nameoraddress
replace zmlabelyn=upper(zmlabelyn)
cap drop cardvalidation
drop if f3_a0_1==""
cap ren childid f3_a0_2surveychildid
duplicates drop
tempfile cardvalidation
	save `cardvalidation'
use `form3temp',clear
mmerge f3_a0_1 f3_a0_2 using `cardvalidation', type(n:1) unmatched(master) update replace ///
		uif(lower(trim(f3_a0_2surveychildid))!="no photo" & lower(trim(f3_a0_2surveychildid))!="invalid")
gen cardvalidation="validated_nochange" if _merge==3
replace cardvalidation="validated_changemade" if _merge==5 | _merge==4
mmerge f3_a0_1 using `cardvalidation', type(n:1) unmatched(master) update replace ///
		uif(lower(trim(f3_a0_2surveychildid))=="no photo") urename(f3_a0_2surveychildid temp)
replace cardvalidation="no_card_photo" if lower(trim(temp))=="no photo"
mmerge f3_a0_1 using `cardvalidation', type(n:1) unmatched(master) ///
		uif(lower(trim(f3_a0_2surveychildid))=="invalid") ukeep(f3_a0_1)
replace cardvalidation="verified_invalid" if _merge==3
replace f3_d1=8 if cardvalidation=="verified_invalid"
replace cardvalidation="no_card_shown" if inlist(f3_d1,2,3,4)
drop _merge 
cap drop temp
save `form3temp',replace
preserve
	keep if cardvalidation=="" & f3_d1==1
	keep f3_a0_1 f3_a0_2 zmlabelyn f3_d2*
	gen nameoraddress=""
	order f3_a0_1 f3_a0_2 nameoraddress zmlabelyn f3_d2* 
	cap export excel using "$datapath/cardimage/Image_need_validation.xlsx",replace firstrow(variable)
restore
preserve
	keep if cardvalidation!="no_card_shown"
	keep if cardvalidation!=""
	keep f3_a0_1 cardvalidation
	duplicates drop f3_a0_1, force
	tempfile cardvalidation2
		save `cardvalidation2', replace
restore
preserve
	import excel using "Data_change_log\Vaccination_card_change_log.xlsx",clear firstrow case(lower) allstring
	drop if f3_a0_1==""
	drop cardvalidation
	duplicates drop
	mmerge f3_a0_1 using `cardvalidation2', type(1:1) unmatched(master)
	replace cardvalidation="error_nomatch" if _merge==1
	drop _merge
	export excel using "Data_change_log\Vaccination_card_change_log.xlsx",replace firstrow(variable)
restore

**********************************************************************
use `form3temp',clear
duplicates drop
save "$tempdata\form3temp.dta", replace
use `form4temp',clear
duplicates drop
save "$tempdata\form4temp.dta", replace

exit 

