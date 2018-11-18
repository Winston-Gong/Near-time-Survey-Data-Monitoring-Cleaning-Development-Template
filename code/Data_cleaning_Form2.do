qui {

/********************************************************
* Last Modified:  03/01/16  by Wenfeng Gong
* File Name:      C:\Google Drive\IVAC - Vaccination Coverage Survey\Data\Automated_Data_Monitoring_Cleaning\code\Data_cleaning_Form2.do
********************************************************/

capture log c
log using "Program_running_log\Data_cleaning_Form2.log", replace
noi di "***Data_cleaning_Form2***"

use "$tempdata\form2temp.dta", clear

//for some technical reasons, duplicate data may be submitted 
duplicates drop 

destring f2_5, replace force
ren f1_0 f1_0house_code

//get child age in days
gen interviewdate = date(f2_2, "DM20Y")
	format interviewdate %td_D-N-Y
replace f2_7_2="15" + substr(f2_7_2,3,.) if substr(f2_7_2,1,2)=="99" // change date of month to 15 when missing
gen childbdate = date(f2_7_2, "DM20Y")
	format childbdate %td_D-N-Y
//list f2_7_2 if f2_7_2!="null" & childbdate==.
gen childby = trim(substr(f2_7_3, strpos(f2_7_3, " year")-1,1))
	destring childby,replace force
gen childbm = trim(substr(f2_7_3, strpos(f2_7_3, " month")-2,2))
	destring childbm,replace force
	order childby childbm, after(f2_7_3)
	replace childby=0 if childby==. & childbm>0 & childbm<99
	replace childby=childby+1 if childbm>=12 & childbm<99
	replace childbm=childbm-12 if childbm>=12 & childbm<99
gen childageindays =childby*365 + childbm*30+15
replace childageindays =childbm*30 if childby==.
destring f2_7_1,replace force
replace f2_7_1=1 if f2_7_3=="null" & f2_7_2!="null"
replace f2_7_1=2 if f2_7_3!="null" & f2_7_2=="null"
replace childageindays = interviewdate-childbdate if f2_7_1==1
gen childageinmonths=childby*12+childbm
replace childageinmonths=childbm if childby==.
replace childageinmonths=mofd(childageindays) if f2_7_1==1
replace childageinmonths=12 if childageindays<366 & childageindays>=360
replace childageinmonths=23 if childageindays<=735 & childageindays>730
drop childbdate 

//get caregiver age in years
destring f2_8_2, gen(cgby) force
replace cgby=. if cgby==9999
destring f2_8_1, gen(cgbm) force
replace cgbm=. if cgbm==99
gen interviewyear=yofd(interviewdate)
gen interviewmonth=month(interviewdate)
gen cgageinyear=interviewyear-cgby
replace cgageinyear=cgageinyear-1 if cgbm>interviewmonth & cgbm!=.
destring f2_9, gen(cgageinyear2) force
replace cgageinyear=cgageinyear2 if cgageinyear2!=. & cgageinyear==.
drop cgbm cgby

// turn f2_4 to missing if the door is not answered
mmerge f1_0 using "$cleandata\Form1_clean.dta", type(n:1) unmatched(master) uif(f1_1_4s==14 & f1_1_1==maxvisit) ukeep(f1_1_4s)
replace f2_4childrencount12to23=. if f2_4childrencount12to23==0 & f1_1_4s==14 // no answer door
drop _merge f1_1_4s

// confirm eligiblility
gen eligible=0 
lab define no0yes1 ///
		0 "NO" ///
		1 "YES" 
lab var eligible "Confirmed eligible"
replace eligible=1 if f2_4>0 & f2_4!=. & f2_5==1 & childageindays>=360 & childageindays<=735
lab value eligible no0yes1

save "$cleandata\Form2_clean.dta",replace
copy "$cleandata\Form2_clean.dta" "$backupdata\Form2_clean_backup_$S_DATE.csv", replace


exit
