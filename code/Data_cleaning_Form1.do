qui {
/********************************************************
* Last Modified:  11/14/18  by Wenfeng Gong
* Project Name:   Near-time data inspection tool (template)
* File Name:      Data_cleaning_Form1.do
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



exit
