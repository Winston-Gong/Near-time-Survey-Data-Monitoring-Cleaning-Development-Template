qui {
/********************************************************
* Last Modified:  09/02/16  by Wenfeng Gong
********************************************************/
capture log c
log using "Program_running_log\Data_validation_Form3&4.log", replace
noi di "***Data_validation_Form3&4 ****"

//build on Form 1&2 query list
use "Data_query\Query_history\querylist.dta",clear 
ren f1_0 HH_ID
ren f1_1_1 Visit_Num
ren f1_1_3 FW_ID
ren f1_1_2 Date
cap drop f1_1_4s
cap gen Child_ID=""
tostring checkpoint, replace
save "Data_query\Query_history\querylist.dta", replace

//***** Preload programs ************
*the command to store Household ID for query generation
   capture program drop querylister2
   program define querylister2
    noi syntax [varlist], checkpoint(string)
	preserve 
		keep if querytag==1
		cap gen HH_ID=f3_a0_1
		cap gen Child_ID=f3_a0_2
		cap gen HH_ID=f4_a0c
		cap gen Child_ID=f4_a1
		cap gen Visit_Num=f4_a0_2
		cap gen Date=f4_b1_1
		cap gen FW_ID=f4_b1_2
		cap gen HH_ID=f1_0
		cap gen Visit_Num=f1_1_1
		cap gen Date=f1_1_2
		cap gen FW_ID=f1_1_3
		cap gen Visit_Num=.
		cap gen Date=""
		cap gen FW_ID=.
		ds HH_ID Visit_Num FW_ID Date Child_ID, varwidth(20)
		keep `r(varlist)'
		gen checkpoint="`checkpoint'"
		append using "Data_query\Query_history\querylist.dta"
		save "Data_query\Query_history\querylist.dta", replace 
	restore
	drop querytag
   end
//***** End preload programs ********
//Checkpoint 75&76: duplicate HH ID or Child ID in Form 3
use "$cleandata\Form3_clean.dta",clear 
duplicates tag f3_a0_1, gen(dup)
sum dup
if r(sum)>0 {
	local warn : di "Warning: Form 3 data are not clean and have duplicated HH_ID"
	noi di "`warn'"
	global warningtracker="$warningtracker" + "& `warn'"
	noi duplicates list f3_a0_1
	duplicates drop f3_a0_1, force 
	gen querytag=(dup>0)
	noi querylister2, checkpoint("75")
}
cap drop dup
use "$cleandata\Form3_clean.dta",clear 
duplicates tag f3_a0_2, gen(dup)
sum dup
if r(sum)>0 {
	local warn : di "Warning: Form 3 data are not clean and have duplicated Child_ID"
	noi di "`warn'"
	global warningtracker="$warningtracker" + "& `warn'"
	noi duplicates list f3_a0_2
	duplicates drop f3_a0_2, force 
	gen querytag=(dup>0)
	noi querylister2, checkpoint("76")
}
cap drop dup
duplicates drop f3_a0_1, force 
duplicates drop f3_a0_2, force 
save "$cleandata\Form3_clean.dta",replace 

//Checkpoint 77: duplicate HH ID or Child ID in Form 4
use "$cleandata\Form4_clean.dta",clear 
duplicates tag f4_a1 f4_a0_2, gen(dup)
sum dup
if r(sum)>0 {
	local warn : di "Warning: Form 4 data are not clean and have duplicated Child_ID"
	noi di "`warn'"
	global warningtracker="$warningtracker" + "& `warn'"
	noi duplicates list f4_a1 f4_a0_2
	duplicates drop f4_a1 f4_a0_2, force 
	gen querytag=(dup>0)
	noi querylister2, checkpoint("77")
}
cap drop dup
duplicates drop f4_a1 f4_a0_2, force 
save "$cleandata\Form4_clean.dta",replace 

//Checkpoint 90: duplicate Child ID in Blood Collection log
use "Entered_data\Processed_log_data\Blood_collection_log.dta", clear
duplicates tag ChildID Makeupsample, gen(dup)
	gen Date=string(Date_collect,"%td_D-N-Y")
	gen HH_ID="Phlebotomist=" + substr(Phlebotomist,1,6) + "; " + string(Makeupsample)
	gen Visit_Num=.
	gen FW_ID=.
	gen Child_ID=ChildID
sum dup
if r(sum)>0 {
	local warn : di "Warning: Blood_collection_log are not clean and have duplicated Child_ID"
	noi di "`warn'"
	global warningtracker="$warningtracker" + "& `warn'"
	noi duplicates list Date_collect ChildID Makeupsample
	gen querytag=(dup>0)
	duplicates drop ChildID HH_ID, force 
	noi querylister2, checkpoint("90")
}
cap drop dup
duplicates drop ChildID Makeupsample, force 
drop HH_ID Date Visit_Num FW_ID Child_ID
save "Entered_data\Processed_log_data\Blood_collection_log.dta", replace
save "$cleandata\Log_Blood_collection_log.dta",replace 

//Checkpoint 9001: duplicate Child ID in Lab Processing log
use "Entered_data\Processed_log_data\Lab_processing_log.dta", clear
duplicates tag SampleID Makeupsample, gen(dup)
	gen Date=string(Date_process,"%td_D-N-Y")
	gen HH_ID="Dataenterer=" + substr(Dataenteredby,1,6) + "; " + string(Makeupsample)
	gen Visit_Num=.
	gen FW_ID=.
	gen Child_ID=SampleID
sum dup
if r(sum)>0 {
	local warn : di "Warning: Lab_processing_log are not clean and have duplicated Child_ID"
	noi di "`warn'"
	global warningtracker="$warningtracker" + "& `warn'"
	noi duplicates list Date_process SampleID Makeupsample
	gen querytag=(dup>0)
	duplicates drop SampleID HH_ID, force 
	noi querylister2, checkpoint("9001")
}
cap drop dup
duplicates drop SampleID Makeupsample, force 
drop HH_ID Date Visit_Num FW_ID Child_ID
save "Entered_data\Processed_log_data\Lab_processing_log.dta", replace
save "$cleandata\Log_Lab_processing_log.dta",replace 

//***********************
// Checkpoint 20:
use "$cleandata\Form4_clean.dta",clear 
gen round=substr(f4_a0c,1,1)
gen surveymethod=substr(f4_a0c,2,1)
gen clusterid=substr(f4_a0c,5,3)
destring round, force replace
keep if inlist(f4_b1_3,1,2,3) & f4_a0_2==maxbloodtry & round==1
bysort surveymethod clusterid: gen enrollbycluster=_N
duplicates drop surveymethod clusterid, force
tostring surveymethod, replace force
replace surveymethod="EPI" if surveymethod=="1"
replace surveymethod="CS" if surveymethod=="2"
replace surveymethod="GIS" if surveymethod=="3"
replace surveymethod="LQAS" if surveymethod=="4"
mmerge surveymethod clusterid using "$tempdata\Consentcount1.dta", type(1:1) unmatched(master)
gen HH_ID=surveymethod + ";ClusterID=" + clusterid
gen Date=""
gen Visit_Num=.
gen FW_ID=.
gen Child_ID=""
gen querytag=0
replace querytag=1 if enrollbycluster!=consent2
tostring enrollbycluster,replace
tostring consent2, replace
replace Date="Form4=" + enrollbycluster + ";consent2=" + consent2
querylister2, checkpoint("20")

//***********************
// Checkpoint 2001 & 2002:
use "Entered_data\Processed_log_data\Consent list (without Round1).dta", clear
replace consent1=lower(consent1)
replace consent2=lower(consent2)
replace consent1="" if consent1!="yes"
replace consent2="" if consent2!="yes"
sum Logdate
local date_consentlog=r(max)
collapse (firstnm) consent1 consent2, by(Child_ID)
tempfile consentct
	save `consentct'
use "$cleandata\Form4_clean.dta",clear 
gen round=substr(f4_a0c,1,1)
destring round, force replace
keep if f4_a0_2==maxbloodtry
gen datenum=date(f4_b1_1,"DM20Y")
keep if datenum<=`date_consentlog' | datenum==.
gen Child_ID=f4_a1
mmerge Child_ID using `consentct', type(n:1) unmatched(both)
gen querytag=0
replace querytag=1 if consent2!="yes" & inlist(f4_b1_3,1,2,3) & round!=1
querylister2, checkpoint("2001")
gen querytag=0
replace querytag=1 if consent2=="yes" & inlist(f4_b1_3,6,7,9,10,11)
replace querytag=1 if consent2=="yes" & f4_b1_3==.
querylister2, checkpoint("2002")

//***********************
// Checkpoint 21 & 22 & 23:
insheet using "Entered_data\Radomization_result_all_for_application.csv",clear
cap drop v1
ren child_id f4_a1collectchildid
tostring f4_a1collectchildid, replace
mmerge f4_a1collectchildid using "$cleandata\Form4_clean.dta", type(1:n) unmatched(both)
duplicates drop f4_a1, force
gen HH_ID=f4_a0c
gen Child_ID=f4_a1
gen querytag=0
replace querytag=1 if result!="YES" & f4_a0_2!=.
querylister2, checkpoint("21")
drop if result!="YES"
tempfile tempfile 
	save `tempfile', replace 
import excel using "Entered_data\Household & Child ID List from Form3.xlsx" ///
			,clear firstrow allstring case(lower) 
ren f3_a0_2 Child_ID 
ren f3_a0_1 form3existingtag
mmerge Child_ID using `tempfile', type(1:1) unmatched(both)
replace HH_ID=form3existingtag if HH_ID==""
gen querytag=0
replace querytag=1 if result=="YES" & f4_a0_2==. & form3existingtag!="" & f1_1_4s=="Interview complete"
querylister2, checkpoint("22")
gen querytag=0
replace querytag=1 if f4_a0_2!=. & form3existingtag==""
querylister2, checkpoint("23")

//***********************
// Checkpoint 24
import excel using "Entered_data\Household & Child ID List from Form3.xlsx" ///
			,clear firstrow allstring case(lower) 
ren f3_a0_2 f4_a1collectchildid 
mmerge f4_a1collectchildid using "$cleandata\Form4_clean.dta", type(1:n) unmatched(both)
gen querytag=0
replace querytag=1 if _merge==2
querylister2, checkpoint("24")

//***********************
// Checkpoint 25
import excel using "Entered_data\Household & Child ID List from Form3.xlsx" ///
			,clear firstrow allstring case(lower) 
gen querytag=0
destring f1_1_1, replace
replace querytag=1 if f1_1_3!=substr(f3_a0_2, 1,2) & f1_1_1==1
destring f1_1_3, replace
querylister2, checkpoint("25")

//***********************
// Checkpoint 2501
use "$cleandata\Form4_clean.dta",clear 
gen querytag=0
replace querytag=1 if string(f4_b1_2)!=substr(f4_a1, 1,2) & f4_a0_2==1
querylister2, checkpoint("2501")

//***********************
// Checkpoint 26
use "$cleandata\Form4_clean.dta",clear 
gen querytag=0
replace querytag=1 if f4_b1_3==.
querylister2, checkpoint("26")

//***********************
// Checkpoint 27
use "$cleandata\Form4_clean.dta",clear 
gen querytag=0
replace querytag=1 if inlist(f4_b1_3,2,3) & f4_b3c==.
querylister2, checkpoint("27")

//***********************
// Checkpoint 29
use "$cleandata\Form3_clean.dta",clear 
mmerge f3_a0_1 using "$tempdata\Form1&2_temp.dta", type(1:1) unmatched(none) umatch(f1_0) uif(f1_1_1==maxvisit)
gen querytag=0
replace querytag=1 if f3_a1_1<f2_4 & f2_4!=.
querylister2, checkpoint("29")

//***********************
// Checkpoint 30
use "$cleandata\Form3_clean.dta",clear 
gen under5count=0
forvalue i=0/9 {
	replace under5count=under5count+1 if f3_a1_3_`i'mon<=60 & f3_a1_3_`i'mon!=.
}
gen querytag=0
replace querytag=1 if f3_a1_1!=under5count
querylister2, checkpoint("30")

//***********************
// Checkpoint 3001
use "$cleandata\Form3_clean.dta",clear 
gen querytag=1
forvalue i=0/9 {
	replace querytag=0 if abs(childageinmonths-f3_a1_3_`i'mon)<=1
}
querylister2, checkpoint("3001")
gen querytag=0
forvalue i=0/9 {
	replace querytag=1 if childageinmonths>(f3_a1_3_`i'mon+1) & f3_a1_3_`i'mon>11 & f3_a1_3_`i'mon!=.
}
querylister2, checkpoint("3002")

//***********************
// Checkpoint 3101
use "$cleandata\Form4_clean.dta", clear
keep f4_a0c f4_a1 f4_a0_2 f4_b1_1 maxbloodtry
gen blooddate=date(f4_b1_1,"DM20Y")
reshape wide f4_a0c blooddate f4_b1_1, i(f4_a1) j(f4_a0_2)
ren f4_a0collecthousecode1 f4_a0collecthousecode
drop f4_a0collecthousecode?
gen f4_a0_2=.
gen querytag=0
forvalue i=2/3 {
	local j=`i'-1
	replace f4_a0_2=`i' if blooddate`i'<=blooddate`j' & `i'<=maxbloodtry
	replace f4_b1_1collection_date1=f4_b1_1collection_date`i' if blooddate`i'<=blooddate`j' & `i'<=maxbloodtry
	replace querytag=1 if blooddate`i'<=blooddate`j' & `i'<=maxbloodtry
}
ren f4_b1_1collection_date1 f4_b1_1collection_date
drop f4_b1_1collection_date?
querylister2, checkpoint("3101")

//***********************
// Checkpoint 32
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
replace querytag=1 if f3_b3!=1 & (f3_b4!=. & f3_b4!=99)
querylister2, checkpoint("32")

//***********************
// Checkpoint 33
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
replace querytag=1 if f3_b5!=1 & (f3_b6_1!=. & f3_b6_1!=99)
replace querytag=1 if f3_b5!=1 & (f3_b6_2!=. & f3_b6_2!=9999)
querylister2, checkpoint("33")

//***********************
// Checkpoint 34
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
replace querytag=1 if f3_b8!=1 & (f3_b9!=. & f3_b9!=99)
querylister2, checkpoint("34")

//***********************
// Checkpoint 35
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
ds f3_c7_3_* f3_c13_2_* f3_c16_2_* f3_c25_3_1 f3_c25_3_2
foreach var in `r(varlist)' {
	gen temp=date(f3_c4b,"DM20Y") // oral history date
	format temp %td_D-N-Y
	replace querytag=1 if interviewdate-temp>childageindays+30 & interviewdate-temp!=.
	drop temp
}
querylister2, checkpoint("35")

//***********************
// Checkpoint 36
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
gen temp=date(f3_c4b,"DM20Y") //BCG oral history date
format temp %td_D-N-Y
replace querytag=1 if interviewdate-temp>childageindays+30 & interviewdate-temp!=.
querylister2, checkpoint("36")

//***********************
// Checkpoint 37
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
replace querytag=1 if f3_c3b!="RECEIVE" & (f3_c4!="" & f3_c4!="null"& f3_c4!="0--")
querylister2, checkpoint("37")

//***********************
// Checkpoint 38
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
replace querytag=1 if f3_c5p!="RECEIVE" & (f3_c6!=. & f3_c6!=99)
replace querytag=1 if f3_c5p!="RECEIVE" & (f3_c7_2_1!=. & f3_c7_2_1!=99)
replace querytag=1 if f3_c5p!="RECEIVE" & (f3_c7_2_2!=. & f3_c7_2_2!=99)
replace querytag=1 if f3_c5p!="RECEIVE" & (f3_c7_2_3!=. & f3_c7_2_3!=99)
replace querytag=1 if f3_c5p!="RECEIVE" & (f3_c7_2_4!=. & f3_c7_2_4!=99)
replace querytag=1 if f3_c5p!="RECEIVE" & (f3_c7_2_5!=. & f3_c7_2_5!=99)
replace querytag=1 if f3_c5p!="RECEIVE" & (f3_c7_3_1!="" & f3_c7_3_1!="null"& f3_c7_3_1!="0--")
replace querytag=1 if f3_c5p!="RECEIVE" & (f3_c7_3_2!="" & f3_c7_3_2!="null"& f3_c7_3_2!="0--")
replace querytag=1 if f3_c5p!="RECEIVE" & (f3_c7_3_3!="" & f3_c7_3_3!="null"& f3_c7_3_3!="0--")
replace querytag=1 if f3_c5p!="RECEIVE" & (f3_c7_3_4!="" & f3_c7_3_4!="null"& f3_c7_3_4!="0--")
replace querytag=1 if f3_c5p!="RECEIVE" & (f3_c7_3_5!="" & f3_c7_3_5!="null"& f3_c7_3_5!="0--")
replace querytag=1 if f3_c5p!="RECEIVE" & (f3_c8!=. & f3_c8!=99)
replace querytag=1 if f3_c5p!="RECEIVE" & (f3_c9_2_1!=. & f3_c9_2_1!=99)
replace querytag=1 if f3_c5p!="RECEIVE" & (f3_c9_3_1!="" & f3_c9_3_1!="null")
replace querytag=1 if f3_c5p!="RECEIVE" & (f3_c9_2_2!=. & f3_c9_2_2!=99)
replace querytag=1 if f3_c5p!="RECEIVE" & (f3_c9_3_2!="" & f3_c9_3_2!="null")
replace querytag=1 if f3_c5p!="RECEIVE" & (f3_c9_2_3!=. & f3_c9_2_3!=99)
replace querytag=1 if f3_c5p!="RECEIVE" & (f3_c9_3_3!="" & f3_c9_3_3!="null")
replace querytag=1 if f3_c5p!="RECEIVE" & (f3_c9_2_4!=. & f3_c9_2_4!=99)
replace querytag=1 if f3_c5p!="RECEIVE" & (f3_c9_3_4!="" & f3_c9_3_4!="null")
replace querytag=1 if f3_c5p!="RECEIVE" & (f3_c9_2_5!=. & f3_c9_2_5!=99)
replace querytag=1 if f3_c5p!="RECEIVE" & (f3_c9_3_5!="" & f3_c9_3_5!="null")
querylister2, checkpoint("38")

//***********************
// Checkpoint 39
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
forvalue i=1/5 {
	replace querytag=1 if (f3_c7_3_`i'=="" | f3_c7_3_`i'=="null") & f3_c6>=`i' & f3_c6!=. & f3_c6!=99
	replace querytag=1 if (f3_c7_2_`i'==. ) & f3_c6>=`i' & f3_c6!=. & f3_c6!=99
}
querylister2, checkpoint("39")

//***********************
// Checkpoint 40
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
forvalue i=1/5 {
	replace querytag=1 if f3_c8!=1 & (f3_c9_2_`i'!=. & f3_c9_2_`i'!=99)
	replace querytag=1 if f3_c8!=1 & (f3_c9_3_`i'!="" & f3_c9_3_`i'!="null")
}
querylister2, checkpoint("40")

//***********************
// Checkpoint 41
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
replace querytag=1 if f3_c10!="RECEIVE" & f3_c11=="RECEIVE"
replace querytag=1 if f3_c10!="RECEIVE" & f3_c14=="RECEIVE"
replace querytag=1 if f3_c10!="RECEIVE" & f3_c17==1
querylister2, checkpoint("41")

//***********************
// Checkpoint 42
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
replace querytag=1 if f3_c11!="RECEIVE" & (f3_c12!=0 & f3_c12!=.)
ds f3_c13_2_*
foreach var in `r(varlist)' {
	replace querytag=1 if f3_c11!="RECEIVE" & `var'!="null" & `var'!=""
}
querylister2, checkpoint("42")

//***********************
// Checkpoint 43
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
forvalue i=1/5 {
	local j=mod(`i',10)
	replace querytag=1 if (f3_c16_2_`j'=="" | f3_c16_2_`j'=="null") & f3_c15>=`i' & f3_c15!=. & f3_c15!=99
}
querylister2, checkpoint("43")

//***********************
// Checkpoint 44
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
replace querytag=1 if f3_c14!="RECEIVE" & (f3_c15!=0 & f3_c15!=.)
ds f3_c16_2_*
foreach var in `r(varlist)' {
	replace querytag=1 if f3_c14!="RECEIVE" & `var'!="null" & `var'!=""
}
querylister2, checkpoint("44")

//***********************
// Checkpoint 45
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
forvalue i=1/5 {
	forvalue j=1/10 {
		local j=mod(`i',10)
		gen tempc13=date(f3_c13_2_`j',"DM20Y") // oral history campaign OPV date
		gen tempc16=date(f3_c16_2_`i',"DM20Y") // oral history routine OPV date
		format tempc13 %td_D-N-Y
		format tempc16 %td_D-N-Y
		replace querytag=1 if tempc13==tempc16 & tempc16!=. & tempc13!=.
		drop tempc13 
		drop tempc16
	}
}
querylister2, checkpoint("45")

//***********************
// Checkpoint 46
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
replace querytag=1 if f3_c18!="RECEIVE" & f3_c19!=. & f3_c19!=99
querylister2, checkpoint("46")

//***********************
// Checkpoint 47
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
replace querytag=1 if f3_c20!="RECEIVE" & f3_c21!="null" & f3_c21!=""
replace querytag=1 if f3_c20!="RECEIVE" & f3_c23!="null" & f3_c23!=""
querylister2, checkpoint("47")

//***********************
// Checkpoint 4701
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
replace querytag=1 if f3_c21!="RECEIVE" & f3_c22_1!=. & f3_c22_1!=99
querylister2, checkpoint("4701")

//***********************
// Checkpoint 48
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
forvalue i=1/5 {
	replace querytag=1 if (f3_c22_3_`i'=="" | f3_c22_3_`i'=="null") & f3_c22_1>=`i' & f3_c22_1!=. & f3_c22_1!=99
}
querylister2, checkpoint("48")

//***********************
// Checkpoint 49
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
replace querytag=1 if f3_c23!="RECEIVE" & f3_c24!=. & f3_c24!=99
querylister2, checkpoint("49")

//***********************
// Checkpoint 50
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
forvalue i=1/3 {
	replace querytag=1 if (f3_c25_3_`i'=="" | f3_c25_3_`i'=="null") & f3_c24>=`i' & f3_c24!=. & f3_c24!=99
	replace querytag=1 if (f3_c25_2_`i'==. ) & f3_c24>=`i' & f3_c24!=. & f3_c24!=99
}
querylister2, checkpoint("50")

//***********************
// Checkpoint 51
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
forvalue i=1/5 {
	forvalue j=1/3 {
		gen tempc25=date(f3_c25_3_`j',"DM20Y") // oral history routine MCV date
		gen tempc22=date(f3_c22_3_`i',"DM20Y") // oral history campaign MCV date
		format tempc25 %td_D-N-Y
		format tempc22 %td_D-N-Y
		replace querytag=1 if tempc22==tempc25 & tempc22!=. & tempc25!=.
		drop tempc22
		drop tempc25
	}
}
querylister2, checkpoint("51")

//***********************
// Checkpoint 52
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
replace querytag=1 if f3_c26!=1 & f3_c28!=. 
replace querytag=1 if f3_c26!=1 & f3_c27!="" & f3_c27!="null"
querylister2, checkpoint("52")

//***********************
// Checkpoint 53
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
replace querytag=1 if f3_f1_1==1 & (f3_f1_2=="" | f3_f1_2=="null") & (f3_f2=="" | f3_f2=="null") 
querylister2, checkpoint("53")

//***********************
// Checkpoint 5301
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
replace querytag=1 if (f3_f1_1!=1 | (f3_f1_2=="" | f3_f1_2=="null")) & lower(trim(zmlabelyn))=="yes"
querylister2, checkpoint("5301")

//***********************
// Checkpoint 54
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
cap destring f3_f9_1, replace
cap destring f3_f8_1, replace
replace querytag=1 if f3_f10g==5 & (f3_f10_2goclinicviaother=="" | f3_f10_2goclinicviaother=="null")
replace querytag=1 if f3_f9_1==98 & (f3_f9_2clinicvisitsickother=="" | f3_f9_2clinicvisitsickother=="null")
replace querytag=1 if f3_f8_1==98 & (f3_f8_2clinicvisitcareother=="" | f3_f8_2clinicvisitcareother=="null")
replace querytag=1 if f3_f5g==3 & (f3_f5_2gocentreviaother=="" | f3_f5_2gocentreviaother=="null")
replace querytag=1 if f3_f4g==5 & (f3_f4_2gocentrewithother=="" | f3_f4_2gocentrewithother=="null")
replace querytag=1 if f3_f3o==1 & (f3_f3_1otherenrolledname=="" | f3_f3_1otherenrolledname=="null")
querylister2, checkpoint("54")

//***********************
// Checkpoint 55
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
replace querytag=1 if f3_g3t==12 & (f3_g3_1toiletother=="" | f3_g3_1toiletother=="null")
replace querytag=1 if f3_g6f==12 & (f3_g6_1fuleforcookingother=="" | f3_g6_1fuleforcookingother=="null")
replace querytag=1 if f3_g7==14 & (floorother=="" | floorother=="null")
replace querytag=1 if f3_g8==14 & (roofother=="" | roofother=="null")
replace querytag=1 if f3_g9==17 & (wallother=="" | wallother=="null")
querylister2, checkpoint("55")

//***********************
// Checkpoint 56
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
replace querytag=1 if f3_e1h==8 & (f3_e1_2headethnicityother=="" | f3_e1_2headethnicityother=="null")
replace querytag=1 if f3_c28==5 & (measlesdiagnosedatother=="" | measlesdiagnosedatother=="null")
replace querytag=1 if f3_c25_2_1==98 & (cliniccodeothermeasles1=="" | cliniccodeothermeasles1=="null")
replace querytag=1 if f3_c7_2_1==98 & (cliniccodeotherpenta1=="" | cliniccodeotherpenta1=="null")
replace querytag=1 if f3_b7b==98 & (f3_b7_2birthplaceother=="" | f3_b7_2birthplaceother=="null")
querylister2, checkpoint("56")

//***********************
// Checkpoint 57
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
replace querytag=1 if f3_g12<1000 | f3_g12==9999 | f3_g12==99999 | f3_g12==9999999
querylister2, checkpoint("57")

//***********************
// Checkpoint 58
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
ds f3_d2_*
foreach var in `r(varlist)' {
	replace querytag=1 if f3_d1!=1 & `var'!="null" & `var'!="MISS" & `var'!="" & `var'!="0--" & `var'!="DONT KNOW"
}
replace querytag=1 if inlist(f3_d1,2,3,4) & f3_d3!=.
querylister2, checkpoint("58")

//***********************
// Checkpoint 60
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
replace querytag=1 if f3_d2_3opv2=="RECEIVE" & f3_d2_3opv1!="RECEIVE"
replace querytag=1 if f3_d2_3opv3=="RECEIVE" & f3_d2_3opv2!="RECEIVE"
replace querytag=1 if f3_d2_3opv3=="RECEIVE" & f3_d2_3opv1!="RECEIVE"
querylister2, checkpoint("60")

//***********************
// Checkpoint 61
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
gen tempdate1=date(f3_d2_4opv1,"DM20Y") 
gen tempdate2=date(f3_d2_4opv2,"DM20Y") 
gen tempdate3=date(f3_d2_4opv3,"DM20Y") 
format tempdate1 %td_D-N-Y
format tempdate2 %td_D-N-Y
format tempdate3 %td_D-N-Y
replace querytag=1 if tempdate2<=tempdate1 & tempdate2!=. & tempdate1!=.
replace querytag=1 if tempdate3<=tempdate1 & tempdate3!=. & tempdate1!=.
replace querytag=1 if tempdate3<=tempdate2 & tempdate3!=. & tempdate2!=.
querylister2, checkpoint("61")

//***********************
// Checkpoint 62
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
replace querytag=1 if f3_d2_3penta2=="RECEIVE" & f3_d2_3penta1!="RECEIVE"
replace querytag=1 if f3_d2_3penta3=="RECEIVE" & f3_d2_3penta2!="RECEIVE"
replace querytag=1 if f3_d2_3penta3=="RECEIVE" & f3_d2_3penta1!="RECEIVE"
querylister2, checkpoint("62")

//***********************
// Checkpoint 63
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
gen tempdate1=date(f3_d2_4penta1,"DM20Y") 
gen tempdate2=date(f3_d2_4penta2,"DM20Y") 
gen tempdate3=date(f3_d2_4penta3,"DM20Y") 
format tempdate1 %td_D-N-Y
format tempdate2 %td_D-N-Y
format tempdate3 %td_D-N-Y
replace querytag=1 if tempdate2<=tempdate1 & tempdate2!=. & tempdate1!=.
replace querytag=1 if tempdate3<=tempdate1 & tempdate3!=. & tempdate1!=.
replace querytag=1 if tempdate3<=tempdate2 & tempdate3!=. & tempdate2!=.
querylister2, checkpoint("63")

//***********************
// Checkpoint 64
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
replace querytag=1 if f3_d2_3pcv2=="RECEIVE" & f3_d2_3pcv1!="RECEIVE"
replace querytag=1 if f3_d2_3pcv3=="RECEIVE" & f3_d2_3pcv2!="RECEIVE"
replace querytag=1 if f3_d2_3pcv3=="RECEIVE" & f3_d2_3pcv1!="RECEIVE"
querylister2, checkpoint("64")

//***********************
// Checkpoint 65
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
gen tempdate1=date(f3_d2_4pcv1,"DM20Y") 
gen tempdate2=date(f3_d2_4pcv2,"DM20Y") 
gen tempdate3=date(f3_d2_4pcv3,"DM20Y") 
format tempdate1 %td_D-N-Y
format tempdate2 %td_D-N-Y
format tempdate3 %td_D-N-Y
replace querytag=1 if tempdate2<=tempdate1 & tempdate2!=. & tempdate1!=.
replace querytag=1 if tempdate3<=tempdate1 & tempdate3!=. & tempdate1!=.
replace querytag=1 if tempdate3<=tempdate2 & tempdate3!=. & tempdate2!=.
querylister2, checkpoint("65")

//***********************
// Checkpoint 66
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
replace querytag=1 if f3_d2_3measles2=="RECEIVE" & f3_d2_3measles1!="RECEIVE"
querylister2, checkpoint("66")

//***********************
// Checkpoint 67
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
gen tempdate1=date(f3_d2_4measles1,"DM20Y") 
gen tempdate2=date(f3_d2_4measles2,"DM20Y") 
format tempdate1 %td_D-N-Y
format tempdate2 %td_D-N-Y
replace querytag=1 if tempdate2<=tempdate1 & tempdate2!=. & tempdate1!=.
querylister2, checkpoint("67")

//***********************
// Checkpoint 68
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
replace querytag=1 if f3_d2_3ipv2=="RECEIVE" & f3_d2_3ipv1!="RECEIVE"
replace querytag=1 if f3_d2_3ipv3=="RECEIVE" & f3_d2_3ipv2!="RECEIVE"
replace querytag=1 if f3_d2_3ipv3=="RECEIVE" & f3_d2_3ipv1!="RECEIVE"
querylister2, checkpoint("68")

//***********************
// Checkpoint 69
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
gen tempdate1=date(f3_d2_4ipv1,"DM20Y") 
gen tempdate2=date(f3_d2_4ipv2,"DM20Y") 
gen tempdate3=date(f3_d2_4ipv3,"DM20Y") 
format tempdate1 %td_D-N-Y
format tempdate2 %td_D-N-Y
format tempdate3 %td_D-N-Y
replace querytag=1 if tempdate2<=tempdate1 & tempdate2!=. & tempdate1!=.
replace querytag=1 if tempdate3<=tempdate1 & tempdate3!=. & tempdate1!=.
replace querytag=1 if tempdate3<=tempdate2 & tempdate3!=. & tempdate2!=.
querylister2, checkpoint("69")

//***********************
// Checkpoint 70
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
replace querytag=1 if f3_d2_3mothertt2=="RECEIVE" & f3_d2_3mothertt1!="RECEIVE"
replace querytag=1 if f3_d2_3mothertt3=="RECEIVE" & f3_d2_3mothertt1!="RECEIVE"
replace querytag=1 if f3_d2_3mothertt3=="RECEIVE" & f3_d2_3mothertt2!="RECEIVE"
replace querytag=1 if f3_d2_3mothertt4=="RECEIVE" & f3_d2_3mothertt1!="RECEIVE"
replace querytag=1 if f3_d2_3mothertt4=="RECEIVE" & f3_d2_3mothertt2!="RECEIVE"
replace querytag=1 if f3_d2_3mothertt4=="RECEIVE" & f3_d2_3mothertt3!="RECEIVE"
replace querytag=1 if f3_d2_3mothertt5=="RECEIVE" & f3_d2_3mothertt1!="RECEIVE"
replace querytag=1 if f3_d2_3mothertt5=="RECEIVE" & f3_d2_3mothertt2!="RECEIVE"
replace querytag=1 if f3_d2_3mothertt5=="RECEIVE" & f3_d2_3mothertt3!="RECEIVE"
replace querytag=1 if f3_d2_3mothertt5=="RECEIVE" & f3_d2_3mothertt4!="RECEIVE"
querylister2, checkpoint("70")

//***********************
// Checkpoint 71
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
gen tempdate1=date(f3_d2_4mothertt1,"DM20Y") 
gen tempdate2=date(f3_d2_4mothertt2,"DM20Y") 
gen tempdate3=date(f3_d2_4mothertt3,"DM20Y") 
gen tempdate4=date(f3_d2_4mothertt4,"DM20Y") 
gen tempdate5=date(f3_d2_4mothertt5,"DM20Y") 
format tempdate1 %td_D-N-Y
format tempdate2 %td_D-N-Y
format tempdate3 %td_D-N-Y
format tempdate4 %td_D-N-Y
format tempdate5 %td_D-N-Y
replace querytag=1 if tempdate2<=tempdate1 & tempdate2!=. & tempdate1!=.
replace querytag=1 if tempdate3<=tempdate1 & tempdate3!=. & tempdate1!=.
replace querytag=1 if tempdate3<=tempdate2 & tempdate3!=. & tempdate2!=.
replace querytag=1 if tempdate4<=tempdate1 & tempdate4!=. & tempdate1!=.
replace querytag=1 if tempdate4<=tempdate2 & tempdate4!=. & tempdate2!=.
replace querytag=1 if tempdate4<=tempdate3 & tempdate4!=. & tempdate3!=.
replace querytag=1 if tempdate5<=tempdate1 & tempdate5!=. & tempdate1!=.
replace querytag=1 if tempdate5<=tempdate2 & tempdate5!=. & tempdate2!=.
replace querytag=1 if tempdate5<=tempdate3 & tempdate5!=. & tempdate3!=.
replace querytag=1 if tempdate5<=tempdate4 & tempdate5!=. & tempdate4!=.
querylister2, checkpoint("71")

//***********************
// Checkpoint 72 & 73 & 74
use "$cleandata\Form4_clean.dta",clear 
gen querytag=0
replace querytag=1 if f4_b1_3==1 & f4_b3c!=. & f4_b3c>0
querylister2, checkpoint("72")
gen querytag=0
replace querytag=1 if f4_b1_3==8
querylister2, checkpoint("73")
gen querytag=0
replace querytag=1 if f4_b3c==7
querylister2, checkpoint("74")

//***********************
// Checkpoint 80
use "$cleandata\Form4_clean.dta",clear 
gen norevisitneed=0
replace norevisitneed=1 if inlist(f4_b1_3, 1, 3, 9,11)
gen querytag=0
replace querytag=1 if norevisitneed==1 & f4_a0_2!=maxbloodtry
querylister2, checkpoint("80")

//***********************
// Checkpoint 81 & 82 & 83
use "$cleandata\Form4_clean.dta",clear 
mmerge f4_a1 using "Entered_data\Processed_log_data\Blood_collection_log.dta" ///
		, type(n:1) uif(Makeupsample==maxmakeup) unmatched(both) umatch(ChildID)
sum Logdate
local maxdate_log=r(max)
drop if date(f4_b1_1,"DM20Y")>`maxdate_log' & f4_b1_1!=""
gen querytag=0
replace querytag=1 if _merge==1 & (f4_b1_3==1 | inlist(f4_b3c,4,5,6,8,9,10))
querylister2, checkpoint("81")
gen querytag=0
replace querytag=1 if _merge==3 & !(f4_b1_3==1 | inlist(f4_b3c,4,5,6,8,9,10)) & f4_a0_2==maxbloodtry & Blood_amount>0
querylister2, checkpoint("82")
gen querytag=0
replace querytag=1 if _merge==2 
	gen HH_ID="Phlebotomist=" + substr(Phlebotomist,1,6)
	gen Date=string(Date_collect,"%td_D-N-Y")
	gen Visit_Num=.
	gen FW_ID=.
querylister2, checkpoint("83")

//***********************
// Checkpoint 8101 & 8201 & 8301
use "$cleandata\Form4_clean.dta",clear 
mmerge f4_a1 using "Entered_data\Processed_log_data\Lab_processing_log.dta" ///
		, type(n:1) uif(Makeupsample==maxmakeup) unmatched(both) umatch(SampleID)
sum Logdate
local maxdate_log=r(max)
drop if date(f4_b1_1,"DM20Y")>`maxdate_log' & f4_b1_1!=""
gen querytag=0
replace querytag=1 if _merge==1 & (f4_b1_3==1 | inlist(f4_b3c,4,5,6,8,9,10))
querylister2, checkpoint("8101")
gen querytag=0
replace querytag=1 if _merge==3 & !(f4_b1_3==1 | inlist(f4_b3c,4,5,6,8,9,10)) & f4_a0_2==maxbloodtry & Blood_amount>0
querylister2, checkpoint("8201")
gen querytag=0
replace querytag=1 if _merge==2 
	gen HH_ID="Dataenterer=" + substr(Dataenteredby,1,6)
	gen Date=string(Date_process,"%td_D-N-Y")
	gen Visit_Num=.
	gen FW_ID=.
querylister2, checkpoint("8301")

//***********************
// Checkpoint 84 & 85 & 86 & 8601
use "Entered_data\Processed_log_data\Blood_collection_log.dta", clear
keep if Makeupsample==maxmakeup
mmerge ChildID using "Entered_data\Processed_log_data\Lab_processing_log.dta" ///
		, type(1:1) uif(Makeupsample==maxmakeup) unmatched(none) umatch(SampleID) ///
		urename(Blood_amount Blood_amount_lab \ Time_arrive Time_arrive_lab)
gen querytag=0
replace querytag=1 if (abs(Blood_amount-Blood_amount_lab)>=150 | (Blood_amount-Blood_amount_lab)==.)
	gen HH_ID="Field=" + string(Blood_amount) + "; Lab=" + string(Blood_amount_lab) + "; Serum=" + string(Serum_amount)
	gen Date=string(Date_collect,"%td_D-N-Y")
	gen Visit_Num=.
	gen FW_ID=.
	gen Child_ID=ChildID
querylister2, checkpoint("84")
gen querytag=0
replace querytag=1 if abs(Time_arrive-Time_arrive_lab)>=1800000
	replace HH_ID="Field=" + string(Date_collect,"%td_D-N-Y") + " " + string(Time_arrive,"%tc_HH:MM") ///
				+ "; Lab=" + string(Date_process,"%td_D-N-Y") + " " + string(Time_arrive_lab,"%tc_HH:MM")
querylister2, checkpoint("85")
gen querytag=0
replace querytag=1 if Time_arrive_lab-Time_collect>10800000 | Time_arrive_lab-Time_collect<3600000*0.25
	replace HH_ID="Collect=" + string(Time_collect,"%tc_HH:MM") + "; Arrive_per_collector=" + string(Time_arrive,"%tc_HH:MM") ///
					+ "; Arrive_per_lab=" + string(Time_arrive,"%tc_HH:MM") + "; " + substr(Phlebotomist,1,6)
querylister2, checkpoint("86")
gen querytag=0
replace querytag=1 if Time_freeze-Time_arrive_lab>7200000 | Time_freeze-Time_arrive_lab<0
	replace HH_ID="Arrive=" + string(Time_arrive_lab,"%tc_HH:MM") + "; Freeze=" + string(Time_freeze,"%tc_HH:MM")
querylister2, checkpoint("8601")

//***********************
// Checkpoint 87 & 88 & 89 & 8901
use "$cleandata\Form4_clean.dta",clear 
mmerge f4_a1 using "Entered_data\Processed_log_data\Lab_processing_log.dta" ///
		, type(n:1) uif(Makeupsample==maxmakeup) unmatched(master) umatch(SampleID) _merge(mergelab) ///
		urename(Blood_amount Blood_amount_lab \ Time_arrive Time_arrive_lab)
mmerge f4_a1 using "Entered_data\Processed_log_data\Blood_collection_log.dta" ///
		, type(n:1) uif(Makeupsample==maxmakeup) unmatched(master) umatch(ChildID) _merge(mergefield)
sum Logdate
local maxdate_log=r(max)
drop if date(f4_b1_1,"DM20Y")>`maxdate_log' & f4_b1_1!=""
gen HH_ID=f4_a0c+"; Blood_amount=" + string(Blood_amount)
gen querytag=0
replace querytag=1 if inlist(f4_b3c,4,5,6,8,9,10) & mergefield==3 & f4_a0_2==maxbloodtry ///
						& Blood_amount>=200 
querylister2, checkpoint("87")
gen querytag=0
replace querytag=1 if !inlist(f4_b3c,4,5,6,8,9,10) & mergefield==3 & f4_a0_2==maxbloodtry ///
						& Blood_amount<200 
querylister2, checkpoint("88")
drop HH_ID
gen Date=string(Date_collect,"%td_D-N-Y")
gen querytag=0
replace querytag=1 if (f4_b1_3==1 | inlist(f4_b3c,4,5,6,8,9,10)) & mergefield==3 & f4_a0_2==maxbloodtry ///
						& Date!=f4_b1_1 
querylister2, checkpoint("89")
gen HH_ID=f4_a0c+"; Time_collect=" + string(Time_collect, "%tc")
drop Date
gen querytag=0
replace querytag=1 if (f4_b1_3==1 | inlist(f4_b3c,4,5,6,8,9,10)) & mergefield==3 & f4_a0_2==maxbloodtry ///
						& abs(f4_b2-Time_collect)>3600000
querylister2, checkpoint("8901")

//***********************
// Checkpoint 8902
use "Entered_data\Processed_log_data\Blood_collection_log.dta", clear
	gen HH_ID="LogStartDate=" + string(Logstart,"%td_D-N-Y") + "; Phlebotomist=" + substr(Phlebotomist,1,6)
	gen Date=string(Date_collect,"%td_D-N-Y")
	gen Visit_Num=.
	gen FW_ID=.
	gen Child_ID=ChildID
gen querytag=0
replace querytag=1 if Date_collect<Logstart
querylister2, checkpoint("8902")

//***********************
// Checkpoint 91
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
	//list all the required variables
ds f3_a0* f3_a1_1* f3_b1*  f3_b7b* f3_b8* f3_c1a* f3_c3b* f3_c5p* f3_c10* ///
	f3_c18* f3_c20* f3_c26* f3_c29* f3_d1h* f3_d4b* f3_e1h* f3_e2c* f3_e5f* f3_e6m* ///
	f3_e7fatheroccupation f3_e8motheroccupation f3_e9m* f3_e10p* f3_f1_1* f3_f3o* f3_f4g* f3_f5g* f3_f6h* f3_f7c* ///
	f3_f10g* f3_f11h* f3_g1r* f3_g1_1* f3_g5* f3_g6f* f3_g6_2* f3_g7f* f3_g8r* f3_g9w* ///
	f3_g12h* f3_h1s* f3_h2* 
foreach v of var `r(varlist)' {
	cap tostring `v', replace force
	replace querytag=1 if trim(lower(`v'))=="null" | trim(`v')=="." | trim(`v')==""
	replace f3_a0_1=f3_a0_1 + "; `v'" if trim(lower(`v'))=="null" | trim(`v')=="." | trim(`v')==""
}
replace querytag=1 if f3_b3==. & f3_b1=="1"
replace f3_a0_1=f3_a0_1 + "; f3_b3" if f3_b3==. & f3_b1=="1"
replace querytag=1 if f3_b5==. & f3_b1=="1"
replace f3_a0_1=f3_a0_1 + "; f3_b5" if f3_b5==. & f3_b1=="1"
replace querytag=1 if f3_d3h==. & f3_d1=="1"
replace f3_a0_1=f3_a0_1 + "; f3_d3" if f3_d3h==. & f3_d1=="1"
replace querytag=1 if (trim(lower(f3_c14))=="null" | trim(f3_c14)=="") & f3_c10=="RECEIVE"
replace f3_a0_1=f3_a0_1 + "; f3_c14" if (trim(lower(f3_c14))=="null" | trim(f3_c14)=="") & f3_c10=="RECEIVE"
querylister2, checkpoint("91")

//***********************
// Checkpoint 93
use "$cleandata\Form3_clean.dta",clear 
drop if substr(f3_a0_1,1,1)=="1"
drop if f3_d1!=1
gen querytag=1
local photolist: dir "$datapath\cardimage\" files "*-*-*.*", respectcase
foreach photonam of local photolist {
	replace querytag=0 if f3_a0_1==substr("`photonam'",1,11)
}
querylister2, checkpoint("93")

//***********************
// Checkpoint 95
use "$cleandata\Form4_clean.dta",clear 
gen querytag=0
replace querytag=1 if f4_a3==1
forvalue i=1/6 {
	replace querytag=0 if f4_a3==1 & f4_a4_1_`i'!="" & f4_a4_1_`i'!="null"
}
replace querytag=1 if f4_a4_1_6!="" & f4_a4_1_6!="null" & (f4_b1_3!=4 & f4_b1_3!=5 & f4_b1_3!=9)
replace querytag=1 if f4_a4_1_2!="" & f4_a4_1_2!="null" & (f4_b1_3!=4 & f4_b1_3!=5 & f4_b1_3!=9)
querylister2, checkpoint("95")

//***********************
// Checkpoint 96
use "$cleandata\Form4_clean.dta",clear 
gen querytag=0
replace querytag=1 if f1_1_4s!="Interview complete"
querylister2, checkpoint("96")


//***********************
cap drop querytag
use "Data_query\Query_history\querylist.dta", clear
sort checkpoint HH_ID Child_ID Visit_Num FW_ID 
order checkpoint HH_ID Child_ID Visit_Num FW_ID
destring checkpoint, replace
replace Visit_Num=0 if Visit_Num==.
replace Child_ID="." if Child_ID==""
replace HH_ID="." if HH_ID==""
save "Data_query\Query_history\querylist.dta", replace

exit
