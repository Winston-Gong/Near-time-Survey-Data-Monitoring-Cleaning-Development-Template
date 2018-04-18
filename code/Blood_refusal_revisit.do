qui {
 /********************************************************
* Last Modified:  04/06/16  by Wenfeng Gong
********************************************************/
//############# read revisit feedback ##############
clear 
capture log c
log using "Program_running_log\Blood Refusal Revisit.log", replace
noi di "***Blood Refusal Revisit***"

import excel using "Data_progress_report/HH_need_Blood_revisit.xls", clear firstrow allstring
cap ren Past_Visit Visit
keep HH_ID Child_ID Visit Complete New_Comment
destring Visit, replace
replace Complete="9" if trim(lower(Complete))=="yes" | trim(Complete)=="1"
destring Complete, replace
replace Visit=Visit+1
ren HH_ID f4_a0collecthousecode
ren Child_ID f4_a1collectchildid
ren Visit f4_a0_2visittype
keep if Complete!=. | New_Comment!=""
count
if r(N)>0 {
	mmerge f4_a0c f4_a1 f4_a0_2 using "Data_progress_report/Blood_revisit_feedback_history.dta", type(1:1) unmatched(both) update
	cap gen update_date=.
	replace update_date=date("$S_DATE", "DMY") if _merge==1 | _merge==5
	drop _merge
	format update_date %td_D-N-Y
	saveold "Data_progress_report/Blood_revisit_feedback_history.dta", replace 

	use "$cleandata\Form4_clean.dta",clear
	mmerge f4_a0c f4_a1 f4_a0_2 using "Data_progress_report/Blood_revisit_feedback_history.dta", type(n:1) unmatched(both)
	count if _merge==2 
	if r(N)>0 {
		local warn : di "Warning: some blood revisit feedbacks are not included in database, probably because Form4 are not submitted."
		noi di "`warn'"
		global warningtracker="$warningtracker" + "& `warn'"
		noi list f4_a0c f4_a1 f4_a0_2 if _merge==2 
	}
	drop if _merge==2 
	replace f4_b1_3=9 if Complete==9 & f4_a0_2==maxbloodtry & _merge==3
	replace f4_ccollection_comment=f4_ccollection_comment+New_Comment if New_Comment!="" & f4_a0_2==maxbloodtry & _merge==3
	drop New_Comment Complete _merge
	save "$cleandata\Form4_clean.dta",replace
}
use "Data_progress_report/Blood_revisit_feedback_history.dta", clear
cap gen update_date=date("07-04-16", "DMY")
sum update_date
local maxLogdate=r(max)
di %td_D-N-Y `maxLogdate'
if `maxLogdate'<$Today -10 {
	local disdate : di %td_D-N-Y `maxLogdate'
	local warn : di "Warning: Blood revisit log has not updated in 10 days with last update on `disdate'"  
	noi di "`warn'"
	global warningtracker="$warningtracker" + "& `warn'"
}

//####################################
clear
noi di "# Find household for visit after refusal for blood collection #"
use "$cleandata\Form4_clean.dta",clear
sort f4_a1 f4_a0_2
by f4_a1: keep if _n==_N
drop if inlist(f4_b1_3, 1, 3, 9, 11)
drop if f4_a0_2==3
keep if f1_1_4s=="Interview complete"
gen Today=date("$S_DATE", "DMY")
format Today %td_D-N-Y
//di %td_CY-N-D  date("$S_DATE", "DMY") " $S_TIME"
gen Last_Vx=date(f4_a4_1_6, "DM20Y")
replace Last_Vx=date(f4_a4_1_2, "DM20Y") if Last_Vx==.
gen Delayto=Last_Vx+30
replace Delayto=date(f4_b1_1, "DM20Y")+30 if Delayto==. & ///
				(strpos(lower(f4_a4_1p),"measles")+ strpos(lower(f4_a4_1p),"penta")>0)
drop if Delayto!=. & Delayto>Today+2

gen Consent2="UK"
replace Consent2="YES" if f4_b1_3==2
ren f4_b1_1 Last_Date
ren f4_a0c HH_ID
ren f4_a1 Child_ID
ren f4_a0_2 Visit
ren f4_b1_5 Return_Date
decode f4_b1_3, gen(Status)
ren f4_ccollection_comment Old_Comments
ren f4_b1_2 FW
replace Old_Comments="Delay last time because recent " + f4_a4_1p + " dose. " + Old_Comments ///
			if (strpos(lower(f4_a4_1p),"measles")+ strpos(lower(f4_a4_1p),"penta")>0)
replace Status=Status + ": "+f4_b1_4othercollectionresult if trim(f4_b1_4othercollectionresult)!=""
decode f4_b3c, gen(otherproblem) 
replace otherproblem=otherproblem+ ": "+f4_b3_2 if trim(f4_b3_2)!=""
replace Status=Status + "; Problem: " + otherproblem if trim(otherproblem)!=""
gen Complete_Refuse=""
gen New_Comment=""
sort HH_ID 
order Today HH_ID Child_ID Visit Last_Date FW Return_Date Status Old_Comments Consent2 Complete_Refuse New_Comment
keep Today - New_Comment
destring Complete_Refuse, replace
tempfile bloodrevisitlist
	save `bloodrevisitlist',replace

//retrive back the old comments if the ID is not cleared from revisit list because Form 4 is not submitted
use "Data_progress_report/Blood_revisit_feedback_history.dta", clear
	ren f4_a0c HH_ID 
	ren f4_a1 Child_ID
	ren f4_a0_2 Visit
	replace Visit=Visit-1
	keep HH_ID Child_ID Visit New_Comment Complete_Refuse
tempfile hist
	save `hist',replace
use `bloodrevisitlist',clear
mmerge HH_ID Child_ID Visit using `hist', type(1:1) unmatched(master) update
replace New_Comment="This revisit done but Form4 missing. " + New_Comment if _merge==4 & strpos(New_Comment,"This revisit done but Form4 missing")<1
drop _merge

export excel using "Data_progress_report/HH_need_Blood_revisit.xls", replace firstrow(variables) datestring(%td_D-N-Y)
copy "Data_progress_report/HH_need_Blood_revisit.xls" "Data_progress_report/backup/HH_need_Blood_revisit$S_DATE.xls", replace

exit
