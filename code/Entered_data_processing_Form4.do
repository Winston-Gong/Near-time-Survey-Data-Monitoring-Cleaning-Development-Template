/********************************************************
* Last Modified:  03/23/16  by Wenfeng Gong
********************************************************/
//ssc install distinct
//ssc install dropmiss
clear
set more off
set memory 100m

//working folder location
cd "C:\Dropbox (Personal)\Pakistan\Automated_Data_Monitoring_Cleaning"
//data folder location
global datapath "C:\IVAC Pakistan raw data"
//entered data folder location
global enterdata "$datapath\entered_raw"
//temporary data folder location
global tempdata "$datapath\tempdata"
//backup data folder location
global backupdata "$datapath\backupdata"
//clean data folder location
global cleandata "$datapath\cleandata"

import excel using "$enterdata\IVAC Survey Form 4 20160322.xlsx",clear firstrow allstring case(lower)
gen batch=1
save "$tempdata\Entered_Form4.dta", replace
import excel using "$enterdata\IVAC Survey Form 4 20160326.xlsx",clear firstrow allstring case(lower)
gen batch=2
append using "$tempdata\Entered_Form4.dta"
save "$tempdata\Entered_Form4.dta", replace
import excel using "$enterdata\IVAC Survey Form 4 20160328.xlsx",clear firstrow allstring case(lower)
gen batch=3
append using "$tempdata\Entered_Form4.dta"
save "$tempdata\Entered_Form4.dta", replace
import excel using "$enterdata\IVAC Survey Form 4 20160329.xlsx",clear firstrow allstring case(lower)
gen batch=4
append using "$tempdata\Entered_Form4.dta"
save "$tempdata\Entered_Form4.dta", replace
import excel using "$enterdata\IVAC Survey Form 4 20160406.xlsx",clear firstrow allstring case(lower)
gen batch=5
append using "$tempdata\Entered_Form4.dta"
save "$tempdata\Entered_Form4.dta", replace
import excel using "$enterdata\IVAC Survey Form 4 20160510.xlsx",clear firstrow allstring case(lower)
gen batch=6
append using "$tempdata\Entered_Form4.dta"
save "$tempdata\Entered_Form4.dta", replace
import excel using "$enterdata\IVAC Survey Form 4 20160523.xlsx",clear firstrow allstring case(lower)
gen batch=7
append using "$tempdata\Entered_Form4.dta"
save "$tempdata\Entered_Form4.dta", replace
import excel using "$enterdata\IVAC Survey Form 4 20160524.xlsx",clear firstrow allstring case(lower)
gen batch=8
append using "$tempdata\Entered_Form4.dta"
save "$tempdata\Entered_Form4.dta", replace
import excel using "$enterdata\IVAC Survey Form 4 20160531.xlsx",clear firstrow allstring case(lower)
gen batch=9
append using "$tempdata\Entered_Form4.dta"
save "$tempdata\Entered_Form4.dta", replace
import excel using "$enterdata\IVAC Survey Form 4 20160603.xlsx",clear firstrow allstring case(lower)
gen batch=10
append using "$tempdata\Entered_Form4.dta"
save "$tempdata\Entered_Form4.dta", replace
import excel using "$enterdata\IVAC Survey Form 4 20160608.xlsx",clear firstrow allstring case(lower)
gen batch=11
append using "$tempdata\Entered_Form4.dta"
save "$tempdata\Entered_Form4.dta", replace
import excel using "$enterdata\IVAC Survey Form 4 20160825.xlsx",clear firstrow allstring case(lower)
gen batch=12
append using "$tempdata\Entered_Form4.dta"
save "$tempdata\Entered_Form4.dta", replace
import excel using "$enterdata\IVAC Survey Form 4 20160920.xlsx",clear firstrow allstring case(lower)
gen batch=13
append using "$tempdata\Entered_Form4.dta"
save "$tempdata\Entered_Form4.dta", replace
import excel using "$enterdata\IVAC Survey Form 4 20161221.xlsx",clear firstrow allstring case(lower)
gen batch=14
append using "$tempdata\Entered_Form4.dta"
save "$tempdata\Entered_Form4.dta", replace
import excel using "$enterdata\IVAC Survey Form 4 20170405.xlsx",clear firstrow allstring case(lower)
gen batch=15
append using "$tempdata\Entered_Form4.dta"
save "$tempdata\Entered_Form4.dta", replace

drop if f4_a1=="0"
ds batch, not
dropmiss `r(varlist)', obs force
duplicates drop `r(varlist)', force

//manually correct entered data
replace f4_b1_1a="10-02-16" if f4_a1=="33016" & f4_b1_1=="06-02-16"
replace f4_b1_3a="1" if f4_a1=="33016" & f4_b1_1=="06-02-16"
drop if f4_a1=="33016" & f4_b1_1=="10-02-16"
replace f4_b1_3="7" if f4_a1=="26016" & f4_b1_3=="8" & f4_b1_4=="7"
replace f4_b1_4="" if f4_a1=="26016" & f4_b1_3=="7"
drop if f4_a1=="35001"
replace f4_c2="Measles lga hy is lye blood nhi liya gya.2nd visit par kamyabi sy blood ly liya." if f4_a1=="33012"
replace f4_b1_5a="24-03-16" if f4_a1=="16049"
drop if f4_a1=="26012" & batch==6
replace f4_c2="Mother refused blood sample due to child is sick.Mother refused on 2nd visit." ///
		if f4_a1=="26012"
replace f4_c2="Mother said she get permission from father. Child father refused for blood sampling." ///
		if f4_a1=="26019"
drop if f4_a1=="30019" & batch==6
replace f4_c2="Maa bachy ko ly k nani k ghr chli gai.2nd visit pr refused kr diya." ///
		if f4_a1=="30019"
drop if f4_a1=="30030" & batch==6
replace f4_c2="Bachy ko measeles hy is lye maa ny kaha abi blood nhi dy ge.Refused in 2nd visit." ///
		if f4_a1=="30030"
replace f4_c2="Mother said take permission from father. Blood successfully done." ///
		if f4_a1=="33006"
drop if f4_a1=="33050" & batch==5
replace f4_c2="Father refused for blood collection.2nd visit pr maa ny kaha bchy k walid ny ijazat nhi di." ///
		if f4_a1=="34006"
drop if f4_a1=="34030" & batch==5
drop if f4_a1=="35021" & batch==6
replace f4_c2="Maa boht magror hy bari mushkil sy jawabat diye.r blood ka sun kr bolny lgi m nhi karwana chahti aap log ja skty hain.2nd visit pr b refused kr diya" ///
		if f4_a1=="35021"
drop if f4_a1=="35031" & batch==6
replace f4_c2="child mother say I have only 1 child I cant give the blood and my husband don’t take permission for blood.mother refused in 2nd visit." ///
		if f4_a1=="35031"
drop if f4_a1=="13008" & batch!=14
replace f4_c2="first visit blood not done because child was sick; second visit could not locate the house" if f4_a1=="24029"
replace f4_a2="1" if f4_a1=="45008"
replace f4_c2="mother refused for blood; revisited by Ghazala total refusal" if f4_a1=="46006"
drop if f4_a1=="15024" & f4_a2=="2"

//duplicates list f4_a1

ds batch f4_a1, not
foreach i of var `r(varlist)' {
	sort f4_a1 `i'
	by f4_a1: replace `i'=`i'[_N] if `i'==""
}

ds batch, not
duplicates drop `r(varlist)', force
noi duplicates list f4_a1


// find variables that are not reconciled based on child ID.
local idtocheck "15024"
foreach id in `idtocheck' {
preserve
	keep if f4_a1=="`id'"
	qui ds f4_a1, not
	foreach var in `r(varlist)' {
		qui tab `var' 
		if `r(r)'>1 {
			di "`id' : `var'"
		}
	}
restore 
}


***************************************
//data cleaning
ren f4_a1 f4_a1collectchildid
ren f4_a2 f4_a2childpresent
ren f4_a3 f4_a3pastmonthvaccination
destring f4_a3, replace
gen f4_a4_1_1datebcg=""
gen f4_a4_1_2datepentavalent=""
gen f4_a4_1_3dateopv=""
gen f4_a4_1_4datepcv=""
gen f4_a4_1_5dateipv=""
gen f4_a4_1_6datemeasles=""
gen f4_a4_1_7_1nameothervaccine=""
gen f4_a4_1_7_2dateothervaccine=""
forvalue i=1/4 {
	replace f4_a4_1_1datebcg=f4_a4_1_1datebcg+f4_a4_`i'_1 if strpos(lower(trim(f4_a4_`i')),"bcg")>0
	replace f4_a4_1_2datepentavalent=f4_a4_1_2datepentavalent+f4_a4_`i'_1 if ///
				strpos(lower(trim(f4_a4_`i')),"pent")+strpos(lower(trim(f4_a4_`i')),"dtp")>0
	replace f4_a4_1_3dateopv=f4_a4_1_3dateopv+f4_a4_`i'_1 if ///
				strpos(lower(trim(f4_a4_`i')),"opv")+strpos(lower(trim(f4_a4_`i')),"polio")>0
	replace f4_a4_1_4datepcv=f4_a4_1_4datepcv+f4_a4_`i'_1 if ///
				strpos(lower(trim(f4_a4_`i')),"pcv")+strpos(lower(trim(f4_a4_`i')),"pneum")>0
	replace f4_a4_1_5dateipv=f4_a4_1_5dateipv+f4_a4_`i'_1 if ///
				strpos(lower(trim(f4_a4_`i')),"ipv")+strpos(lower(trim(f4_a4_`i')),"inactive")>0 & strpos(lower(trim(f4_a4_`i')),"inactive")==0
	replace f4_a4_1_6datemeasles=f4_a4_1_6datemeasles+f4_a4_`i'_1 if ///
				strpos(lower(trim(f4_a4_`i')),"measles")+strpos(lower(trim(f4_a4_`i')),"mcv")>0
	replace f4_a4_1_7_1nameothervaccine=f4_a4_1_7_1nameothervaccine+f4_a4_`i' ///
		if strpos(lower(trim(f4_a4_`i')),"bcg")+strpos(lower(trim(f4_a4_`i')),"pent") ///
		+strpos(lower(trim(f4_a4_`i')),"dtp")+strpos(lower(trim(f4_a4_`i')),"opv") ///
		+strpos(lower(trim(f4_a4_`i')),"polio")+strpos(lower(trim(f4_a4_`i')),"pcv") ///
		+strpos(lower(trim(f4_a4_`i')),"pneum")+strpos(lower(trim(f4_a4_`i')),"ipv") ///
		+strpos(lower(trim(f4_a4_`i')),"inactive")+strpos(lower(trim(f4_a4_`i')),"measles") ///
		+strpos(lower(trim(f4_a4_`i')),"mcv")==0
	replace f4_a4_1_7_2dateothervaccine=f4_a4_1_7_2dateothervaccine+f4_a4_`i'_1 ///
		if strpos(lower(trim(f4_a4_`i')),"bcg")+strpos(lower(trim(f4_a4_`i')),"pent") ///
		+strpos(lower(trim(f4_a4_`i')),"dtp")+strpos(lower(trim(f4_a4_`i')),"opv") ///
		+strpos(lower(trim(f4_a4_`i')),"polio")+strpos(lower(trim(f4_a4_`i')),"pcv") ///
		+strpos(lower(trim(f4_a4_`i')),"pneum")+strpos(lower(trim(f4_a4_`i')),"ipv") ///
		+strpos(lower(trim(f4_a4_`i')),"inactive")+strpos(lower(trim(f4_a4_`i')),"measles") ///
		+strpos(lower(trim(f4_a4_`i')),"mcv")==0
}
drop f4_a4_*_1
drop f4_a4_2 f4_a4_3 f4_a4_4
ren f4_a4_1 f4_a4_1pastmonthvaccname
ren f4_a5 f4_a5collectionapproval
destring f4_a5, replace
ren f4_b1_1 f4_b1_1collection_date1
ren f4_b1_2 f4_b1_2collectedby1
ren f4_b1_3 f4_b1_3collectionresult1
ren f4_b1_4 f4_b1_4othercollectionresult1
ren f4_b1_5 f4_b1_5collectionrescheduled1
ren f4_b1_1a f4_b1_1collection_date2
ren f4_b1_2a f4_b1_2collectedby2
ren f4_b1_3a f4_b1_3collectionresult2
ren f4_b1_4a f4_b1_4othercollectionresult2
ren f4_b1_5a f4_b1_5collectionrescheduled2
ren f4_b1_1b f4_b1_1collection_date3
ren f4_b1_2b f4_b1_2collectedby3
ren f4_b1_3b f4_b1_3collectionresult3
ren f4_b1_4b f4_b1_4othercollectionresult3
ren f4_b1_5b f4_b1_5collectionrescheduled3
ren f4_b2 f4_b2collectiontime
ren f4_b3 f4_b3collection_problem
ren f4_b3_2 f4_b3_2othercollectionproblem
ren f4_c1 f4_ccollection_comment
replace f4_ccollection_comment=f4_ccollection_comment+"; "+ f4_c2
drop f4_c2

reshape long f4_b1_1collection_date f4_b1_2collectedby f4_b1_3collectionresult ///
		f4_b1_4othercollectionresult f4_b1_5collectionrescheduled, i(f4_a1collectchildid) j(f4_a0_2visittype)

destring f4_a2, replace
destring f4_b1_3, replace

drop if f4_b1_1=="" & f4_b1_2=="" & f4_b1_3==. & f4_b1_4=="" & f4_b1_5==""

//check for having visit 2 but not visit 1
sort f4_a1 f4_a0
by f4_a1: gen maxbloodtry=_N
list f4_a1 f4_a0 if f4_a0>maxbloodtry

//* Child ID 25008 only exist for "the second visit", but it is actually the first visit
replace f4_a0=1 if f4_a1=="25008"

//manually correct entered data
replace f4_a3=2 if f4_a1=="33012" & f4_a0==2
replace f4_a5=1 if f4_a1=="33012" & f4_a0==2
drop if f4_a1=="3" & f4_a0==2

drop batch
drop maxbloodtry
saveold "$tempdata\Entered_Form4.dta", replace

//save unidentifiable data
copy "$tempdata\Entered_Form4.dta" "Entered_data/Entered_Form4.dta", replace

