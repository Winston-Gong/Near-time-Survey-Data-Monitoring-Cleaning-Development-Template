qui {
/********************************************************
* Last Modified:  11/14/18  by Wenfeng Gong
* Project Name:   Near-time data inspection tool (template)
* File Name:      Data_validation_Form1&2.do 
********************************************************/
capture log c
log using "Program_running_log\Data_validation_Form1&2.log", replace
noi di "***Data_validation_Form1&2 ****"

//***** create an empty query list (User DO NOT change) ************
cap rm "Data_query\Query_history\querylist.dta"
use "$cleandata\Form1_clean.dta",clear 
keep f1_0 f1_1_1 f1_1_3 f1_1_2 f1_1_4s
drop if f1_0!=""
gen Child_ID="."
save "Data_query\Query_history\querylist.dta", replace

//***** Preload programs (User DO NOT change) ************
*the command to store Household ID for query generation
   capture program drop querylister
   program define querylister
    noi syntax [varlist], checkpoint(string)
	preserve 
		keep if querytag==1
		cap gen Child_ID="."
		cap ds f1_1_1 f1_1_3 f1_1_2 f1_1_4s Child_ID, varwidth(20)
		keep f1_0 `r(varlist)'
		gen checkpoint="`checkpoint'"
		append using "Data_query\Query_history\querylist.dta"
		save "Data_query\Query_history\querylist.dta", replace 
	restore
	drop querytag
   end
//***** End preload programs ********


//***** Define Checkpoints (User should change) ****
//Checkpoint 1&2: duplicate HH ID due to correction
use "$cleandata\Form1_clean.dta",clear 
duplicates tag f1_0 f1_1_1, gen(dup)
sum dup
if r(sum)>0 {
	local  warn : di "Warning: Form 1 data are not clean and have duplicates"
	noi di "`warn'"
	global warningtracker="$warningtracker" + "& `warn'"
	noi duplicates list f1_0 f1_1_1
	duplicates drop f1_0 f1_1_1, force 
	gen querytag=(dup>0)
	noi querylister , checkpoint("1")
	cap drop dup
	save, replace
}
use "$cleandata\Form2_clean.dta",clear 
duplicates tag f1_0, gen(dup)
sum (dup)
if r(sum)>0 {
	local  warn : di "Warning: Form 2 data are not clean and have duplicates"
	noi di "`warn'"
	global warningtracker="$warningtracker" + "& `warn'"
	noi duplicates list f1_0
	duplicates drop f1_0, force 
	preserve 
		cap drop dup
		save "$cleandata\Form2_clean.dta", replace
	restore
	gen querytag=(dup>0)
	mmerge f1_0 using "$cleandata\Form1_clean.dta", type(1:1) unmatched(master) ukeep(f1_1_1 f1_1_3 f1_1_2 f1_1_4s) uif(f1_1_1==maxvisit)
	querylister, checkpoint("2")
}

//// merge Form 2 to Form 1 for all following checkpoints
// Checkpoint 78: 
use "$cleandata\Form1_clean.dta",clear
mmerge f1_0 using "$cleandata\Form2_clean.dta", type(n:1) unmatched(both) 
count if _merge==2 
if r(N)>0 {
	local  warn : di "Warning: Form 2 data are not clean and some Form2 do not have correcsponding Form1"
	noi di "`warn'"
	global warningtracker="$warningtracker" + "& `warn'"
	gen querytag=0
	replace querytag=1 if _merge==2
	querylister, checkpoint("78")
	drop if _merge==2
}
drop _merge
save "$tempdata\Form1&2_temp.dta", replace
//***********************
// add Child ID
import excel using "Program_running_log\Household & Child ID List from Form3.xlsx" ///
			,clear firstrow allstring case(lower)
drop f1_1_1 f1_1_3 f1_1_4s f1_1_2
ren f3_a0_1 f1_0house_code
ren f3_a0_2 Child_ID
mmerge f1_0house_code using "$tempdata\Form1&2_temp.dta", type(1:n) unmatched(using)
drop _merge
save "$tempdata\Form1&2_temp.dta",replace

//***********************
// Checkpoint 3: child age
use "$tempdata\Form1&2_temp.dta", clear
gen querytag=0
replace querytag=1 if (childageindays<360 | childageindays>735 | childageindays==.) & inlist(f1_1_4s,1,7,8,9)
querylister, checkpoint("3")

//***********************
// Checkpoint 4: caregiver age
//list cgageinyear2 cgageinyear if cgageinyear2!=cgageinyear
gen querytag=0
replace querytag=1 if (cgageinyear<18 | cgageinyear>100 | cgageinyear==.) & inlist(f1_1_4s,1,7,8,9)
querylister, checkpoint("4")

//***********************
// Checkpoint 5: suspected ineligibility
gen querytag=0
replace querytag=1 if (f2_4<1) & inlist(f1_1_4s,1,7,8,9)
querylister, checkpoint("5")

//***********************
// Checkpoint 6: Interviewer ID conflict with Household ID 
gen fwidinhhid=substr(f1_0,3,1) + substr(f1_0,9,1)
destring fwidinhhid,replace force
gen querytag=0
replace querytag=1 if (fwidinhhid!=f1_1_3) & f1_1_1==1
querylister, checkpoint("6")
drop fwidinhhid

//***********************
// Checkpoint 7: 
gen querytag=0
replace querytag=1 if f1_1_4s==13
querylister, checkpoint("7")

//***********************
// Checkpoint 8: 
gen querytag=0
replace querytag=1 if (f2_5!=1) & inlist(f1_1_4s,1,7,8,9)
querylister, checkpoint("8")

//***********************
// Checkpoint 9 & 10 & 11:
import excel using "Program_running_log\Household & Child ID List from Form3.xlsx" ///
			,clear firstrow allstring case(lower)
drop f1_1_1 f1_1_3 f1_1_4s f1_1_2
ren f3_a0_1 f1_0house_code
ren f3_a0_2 Child_ID
mmerge f1_0house_code using "$tempdata\Form1&2_temp.dta", type(1:n) unmatched(both)
keep if f1_1_1==maxvisit
gen querytag=0
replace querytag=1 if f1_1_4s==1 & Child_ID==""
querylister, checkpoint("9")
gen querytag=0
replace querytag=1 if (f1_1_4s==8 | f1_1_4s==9) & Child_ID==""
querylister, checkpoint("10")
gen querytag=0
replace querytag=1 if !inlist(f1_1_4s,1,8,9) & Child_ID!=""
querylister, checkpoint("11")

//***********************
// Checkpoint 12:
use "$tempdata\Form1&2_temp.dta", clear
gen querytag=0
replace querytag=1 if (childageindays==. | cgageinyear==.) & inlist(f1_1_4status,1,7,8,9) & f1_1_1==maxvisit
replace querytag=1 if (childageindays!=. & cgageinyear!=.) & inlist(f1_1_4status,5,6,14,15) & f1_1_1==maxvisit
querylister, checkpoint("12")

//***********************
// Checkpoint 16:
use "$tempdata\Form1&2_temp.dta", clear
gen querytag=0
replace querytag=1 if f1_4r=="6" & (refusal_reason_other=="null" | refusal_reason_other=="")
querylister, checkpoint("16")

//***********************
// Checkpoint 17:
use "$tempdata\Form1&2_temp.dta", clear
gen querytag=0
replace querytag=1 if f2_10c=="6" & (f2_10_2=="null" | f2_10_2=="")
querylister, checkpoint("17")

//***********************
// Checkpoint 18:
use "$tempdata\Form1&2_temp.dta", clear
gen querytag=0
replace querytag=1 if norevisitneed==1 & f1_1_1!=maxvisit
querylister, checkpoint("18")

//***********************
// Checkpoint 28:
use "$tempdata\Form1&2_temp.dta", clear
gen querytag=0
replace querytag=1 if f1_1_4s==0 & f2_4!=0 
replace querytag=1 if (f1_1_4s!=0 & f1_1_4s!=10) & f2_4==0 & f1_1_1==maxvisit
querylister, checkpoint("28")

//***********************
// Checkpoint 31:
use "$tempdata\Form1&2_temp.dta", clear
keep f1_0 Child_ID f1_1_1 f1_1_2 maxvisit
summarize maxvisit
local maxmaxvisit=`r(max)'
gen visitdate=date(f1_1_2,"DM20Y")
reshape wide Child_ID visitdate f1_1_2, i(f1_0) j(f1_1_1)
ren Child_ID1 Child_ID
drop Child_ID?
gen f1_1_1=.
gen querytag=0
forvalue i=2/`maxmaxvisit' {
	local j=`i'-1
	replace f1_1_1=`i' if visitdate`i'<=visitdate`j' & `i'<=maxvisit
	replace f1_1_2visit_datetime1=f1_1_2visit_datetime`i' if visitdate`i'<=visitdate`j' & `i'<=maxvisit
	replace querytag=1 if visitdate`i'<=visitdate`j' & `i'<=maxvisit
}
ren f1_1_2visit_datetime1 f1_1_2visit_datetime
drop f1_1_2visit_datetime?
querylister, checkpoint("31")


//***********************
// Checkpoint 79:
import excel using "Program_running_log\Household & Child ID List from Form3.xlsx" ///
			,clear firstrow allstring case(lower)
drop f1_1_1 f1_1_3 f1_1_4s f1_1_2 f3_a0_1
ren f3_a0_2 f1_1_6previous_child_id
drop if f1_1_6=="99999"
mmerge f1_1_6 using "$tempdata\Form1&2_temp.dta", type(n:n) unmatched(using) uif(f1_1_4s==11 & f1_1_6!="99999")
gen querytag=0
replace querytag=1 if _merge!=3 
querylister, checkpoint("79")

//***********************
// Checkpoint 94:
use "$tempdata\Form1&2_temp.dta", clear
sort f1_0 f1_1_1
by f1_0: replace f1_1_3=f1_1_3[_N]
by f1_0: replace f1_1_4s=f1_1_4s[_N]
keep f1_0 f1_1_1 f1_1_3 f1_1_2 f1_1_4s Child_ID f2_2 maxvisit
reshape wide f1_1_2, i(f1_0) j(f1_1_1) 
gen querytag=1
gen f1_1_1visit_no=maxvisit
gen f1_1_2visit_datetime=""
sum maxvisit
forvalue i=1/`r(max)' {
	replace f1_1_2visit_datetime=f1_1_2visit_datetime`i' if maxvisit==`i'
	replace querytag=0 if f2_2==f1_1_2visit_datetime`i'
	drop f1_1_2visit_datetime`i'
}
querylister, checkpoint("94")

//***********************
use "Data_query\Query_history\querylist.dta", clear
sort checkpoint f1_0
order checkpoint f1_0
destring checkpoint, replace
replace f1_1_1=0 if f1_1_1==.
gen Status=""
lab var Status "Status(Resolved/Cancelled)"
gen Responsible=""
gen Comment=""
save "Data_query\Query_history\querylist.dta", replace

exit
