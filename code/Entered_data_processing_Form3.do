qui{
/********************************************************
* Last Modified:  04/06/16  by Wenfeng Gong
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

import excel using "$enterdata\IVAC Survey Form 3_enterer1 20160314.xlsx",clear firstrow allstring case(lower)
gen batch=1
save "$tempdata\Entered_Form3.dta", replace
import excel using "$enterdata\IVAC Survey Form 3_enterer2 20160314.xlsx",clear firstrow allstring case(lower)
gen batch=2
append using "$tempdata\Entered_Form3.dta"
save "$tempdata\Entered_Form3.dta", replace
import excel using "$enterdata\IVAC Survey Form 3 20160321.xlsx",clear firstrow allstring case(lower)
gen batch=3
append using "$tempdata\Entered_Form3.dta"
save "$tempdata\Entered_Form3.dta", replace
import excel using "$enterdata\IVAC Survey Form 3 20160329.xlsx",clear firstrow allstring case(lower)
gen batch=4
append using "$tempdata\Entered_Form3.dta"
save "$tempdata\Entered_Form3.dta", replace
import excel using "$enterdata\IVAC Survey Form 3 20160406.xlsx",clear firstrow allstring case(lower)
gen batch=5
append using "$tempdata\Entered_Form3.dta"
save "$tempdata\Entered_Form3.dta", replace
import excel using "$enterdata\IVAC Survey Form 3 20160513.xlsx",clear firstrow allstring case(lower)
gen batch=6
append using "$tempdata\Entered_Form3.dta"
save "$tempdata\Entered_Form3.dta", replace
import excel using "$enterdata\IVAC Survey Form 3 20160514.xlsx",clear firstrow allstring case(lower)
gen batch=7
append using "$tempdata\Entered_Form3.dta"
save "$tempdata\Entered_Form3.dta", replace
import excel using "$enterdata\IVAC Survey Form 3 20170131.xlsx",clear firstrow allstring case(lower)
gen batch=8
append using "$tempdata\Entered_Form3.dta"
save "$tempdata\Entered_Form3.dta", replace



//clean format of date variables
ds f3_c4 f3_c7_3* f3_c13_2* f3_c16_2* f3_c22_3* f3_c25_3* f3_d2_4*
foreach var in `r(varlist)' {
	replace `var'=substr(`var',1,2) + "-" + substr(`var',3,2) + "-" + substr(`var',5,2) ///
		if strpos(`var',"/")+strpos(`var',"-")==0 & `var'!=""
	replace `var'=substr(`var',1,2) + "-" + substr(`var',4,2) + "-" + substr(`var',7,2) ///
		if strpos(`var',"/")>0 & strpos(`var',"-")==0 & `var'!=""
}

//put True/False variable to 1 or missing
ds f3_d2_* f3_g5_* f3_g10_*
foreach i of var `r(varlist)' {
	replace `i'="" if `i'=="0"
}

ds batch id, not
dropmiss `r(varlist)', obs force

//manually correct entered data; they cannot be moved to change log because the 
// following code to complete missing entereed value based on same id record is 
// required after changing the ids to correct values. 
replace f3_a0_1="111243506" if id=="442" & (batch==1 | batch==2)
replace f3_a0_2="15034" if id=="442" & (batch==1 | batch==2)
replace f3_a0_1="133383501" if id=="328" & (batch==1 | batch==2)
replace f3_a0_2="35033" if id=="328" & (batch==1 | batch==2)
replace f3_a0_1="133383317" if id=="335" & (batch==1 | batch==2)
replace f3_a0_2="33041" if id=="335" & (batch==1 | batch==2)
replace f3_a0_1="133383505" if id=="345" & (batch==1 | batch==2)
replace f3_a0_2="35034" if id=="345" & (batch==1 | batch==2)
replace f3_e7="MCB Bank Worker" if f3_a0_1=="111243506"
replace f3_c7_2="Alkhidmat Hospital" if f3_a0_1=="122206408"
replace f3_c7_2_2="Alkhidmat Hospital" if f3_a0_1=="122206408"
replace f3_c7_2_3="Alkhidmat Hospital" if f3_a0_1=="122206408"
replace f3_c25_2="Alkhidmat Hospital" if f3_a0_1=="122206408"
replace f3_c5="1. Yes" if f3_a0_1=="111144412"
replace f3_c10="1. Yes" if f3_a0_1=="111144412"
replace f3_c20="1. Yes" if f3_a0_1=="111144412"
replace f3_a1_3b="6" if f3_a0_1=="133383010"
replace f3_b9="17" if f3_a0_1=="133383010"
replace f3_c7_1="16" if f3_a0_1=="133383010"
replace f3_c7_1_2="Chinoit General Hospital Korangi 21/2" if f3_a0_1=="133383010"
replace f3_c7_1_3="Chinoit General Hospital Korangi 21/2" if f3_a0_1=="133383010"
replace f3_c12="99" if f3_a0_1=="133383010"
replace f3_c15="4" if f3_a0_1=="133383010"
replace f3_c17="1. Yes" if f3_a0_1=="133383010"
replace f3_c24="2" if f3_a0_1=="133383010"
replace f3_c25_1="16. Chinoit General Hospital Korangi 21/2" if f3_a0_1=="133383010"
replace f3_c25_3="99/99/99" if f3_a0_1=="133383010"
replace f3_g1="4" if f3_a0_1=="133383010"
replace f3_g2="1" if f3_a0_1=="133383010"
replace f3_g7="7" if f3_a0_1=="133383010"
replace f3_g9="12" if f3_a0_1=="133383010"
replace f3_g11="1. Yes" if f3_a0_1=="133383010"
replace f3_g12="25000" if f3_a0_1=="133383010"
replace f3_h2="11.24" if f3_a0_1=="133383010"
replace dataenterer="Asima Sardar" if dataenterer=="Asima sardar"
drop if f3_a0_1=="" & f3_a0_2==""
replace f3_c7_2="Govt hospital babar market" if f3_a0_1=="111007309"
replace f3_c7_2_2="Govt hospital babar market" if f3_a0_1=="111007309"
replace f3_c7_2_3="Govt hospital babar market" if f3_a0_1=="111007309"
replace f3_c25_2="Govt hospital babar market" if f3_a0_1=="111007309"
replace f3_c25_2_2="Govt hospital babar market" if f3_a0_1=="111007309"
replace f3_e7="company /pana filax" if f3_a0_1=="111007309"
replace f3_f5_2="moter bike" if f3_a0_1=="111007309"
replace f3_f8_2="rashid mustafa landhi" if f3_a0_1=="111007309"
replace dataenterer="Asima & Nazia" if f3_a0_1=="111007309"
replace f3_c7_1="12" if f3_a0_1=="111144417"
replace f3_c7_1_2="Jinnah Medical College Hospital Bilal Colony" if f3_a0_1=="111144417"
replace f3_c7_1_3="Jinnah Medical College Hospital Bilal Colony" if f3_a0_1=="111144417"
replace f3_c13_2c="99/11/15" if f3_a0_1=="111144417"
replace f3_c25_1="12. Jinnah Medical College Hospital Bilal Colony" if f3_a0_1=="111144417"
replace f3_c7_2="Urban Hospital Hadraabad" if f3_a0_1=="111144607"
replace f3_c7_2_2="Urban Hospital Hadraabad" if f3_a0_1=="111144607"
replace f3_c7_2_3="Urban Hospital Hadraabad" if f3_a0_1=="111144607"
replace f3_c25_2="Urban Hospital Hadraabad" if f3_a0_1=="111144607"
replace f3_c17="2. No" if f3_a0_1=="111144607"
replace f3_c20="1. Yes" if f3_a0_1=="111144607"
replace f3_d2_4l="25-03-15" if f3_a0_1=="111146506"
replace f3_c30="Rotarix1" if f3_a0_1=="111349322"
replace f3_c30_2="Rotarix2" if f3_a0_1=="111349322"
replace f3_b7="2. At a hospital" if f3_a0_1=="111349513"
replace f3_d2_4l="16-07-15" if f3_a0_1=="111349606"
replace f3_c7_2="Alkhidmat" if f3_a0_1=="122356604"
replace f3_c7_2_2="Alkhidmat" if f3_a0_1=="122356604"
replace f3_c7_2_3="Alkhidmat" if f3_a0_1=="122356604"
replace f3_c25_2="Alkhidmat" if f3_a0_1=="122356604"
replace f3_c17="2. No" if f3_a0_1=="122356604"
replace f3_c9_3="PCV1" if f3_a0_1=="122356604"
replace f3_c9_2_3="PCV2" if f3_a0_1=="122356604"
replace f3_c9_3_3="PCV3" if f3_a0_1=="122356604"
replace f3_e7="soi gas company/contractor" if f3_a0_1=="111349322"
replace f3_e8="House wife" if lower(f3_e8)=="house wife"
replace dataenterer="Asima & Nazia" if f3_a0_1=="111349322"
replace f3_c7_2="hamayu clinic korangi 3" if f3_a0_1=="111349325"
replace f3_c7_2_2="hamayu clinic korangi 3" if f3_a0_1=="111349325"
replace f3_e7="Indus pharma medicene company /matcine oproter" if f3_a0_1=="111349325"
replace f3_f8_2="Dr jalal clinic korangi 2 1/2" if f3_a0_1=="111349325"
replace dataenterer="Asima & Nazia" if f3_a0_1=="111349325"
replace f3_f5_2="Motor bike" if f3_a0_1=="111349513"
replace dataenterer="Asima & Nazia" if f3_a0_1=="111349513"
replace f3_e7="Spear parts shop/Owner" if f3_a0_1=="111349513"
replace f3_c7_2="Hamayu clinic" if f3_a0_1=="122356605"
replace f3_c7_2_2="Hamayu clinic" if f3_a0_1=="122356605"
replace f3_c7_2_3="Hamayu clinic" if f3_a0_1=="122356605"
replace f3_c25_2="Hamayu clinic" if f3_a0_1=="122356605"
replace f3_c25_2_2="Hamayu clinic" if f3_a0_1=="122356605"
drop if f3_a0_1=="111215"
replace f3_c1="1. Yes" if f3_a0_1=="122356505"
replace f3_c3="1. Yes" if f3_a0_1=="122356505"
replace f3_c5="1. Yes" if f3_a0_1=="122356505"
replace f3_c10="1. Yes" if f3_a0_1=="122356505"
replace f3_c20="1. Yes" if f3_a0_1=="122356505"
replace f3_a1_2="Female" if f3_a0_1=="122356505"
drop if f3_a0_1=="122356505" & f3_a1_3b=="13"
drop if f3_a0_1=="122356505" & f3_a1_2=="Male"
replace f3_c7_1="19" if f3_a0_2=="33006"
replace f3_c25_1="19. Hope Nasir Colony" if f3_a0_2=="33006"
replace f3_c25_1_2="19. Hope Nasir Colony" if f3_a0_2=="33006"
replace f3_e7="Bakri job/labour" if f3_a0_2=="33006"
replace f3_e8="cooking/cook" if f3_a0_2=="33006"
replace f3_e7="Karkhana/Labour" if f3_a0_1=="124001602"
replace dataenterer="Nazia Shah" if dataenterer=="Nazi Shah"
replace dataenterer="Nazia Shah" if hm=="Nazia Shah"
replace f3_d2_4j="09-07-14" if f3_a0_1=="133068302"
drop if dataenterer=="Nazia Shah" & f3_a0_2=="15007"
drop if dataenterer=="Asima Sardar" & f3_a0_2=="27006"
drop if dataenterer=="Nazia" & f3_a0_2=="27006" & f3_c9_3=="pcv 1"
drop if dataenterer=="Nazia" & f3_a0_2=="27011" 
drop if f3_c4=="99-99-99" & f3_a0_2=="27034" 

//make sure HHID is unique and missing values are replaced
di "make sure HHID is unique and missing values are replaced"
ds batch id f3_a0_1 f3_a0_2, not
foreach i of var `r(varlist)' {
	sort f3_a0_1 f3_a0_2 `i'
	by f3_a0_1 f3_a0_2: replace `i'=`i'[_N] if `i'==""
}
drop batch id
duplicates drop 
noi duplicates list f3_a0_1
noi duplicates list f3_a0_2 //has conflicting duplication, need to check dataentry 
//for following IDs will be taken care of in change log: 
// 133024305, 25025, 26026, 45010, 33006

//exit

// find variables that are not reconciled based on HHID
local idtocheck "111144504"
foreach id in `idtocheck' {
preserve
	keep if f3_a0_1=="`id'"
	qui ds f3_a0_1, not
	foreach var in `r(varlist)' {
		qui tab `var' 
		if `r(r)'>1 {
			di "`id' : `var'"
		}
	}
restore 
}
// find variables that are not reconciled based on child ID.
local idtocheck "27034"
foreach id in `idtocheck' {
preserve
	keep if f3_a0_2=="`id'"
	qui ds f3_a0_2, not
	foreach var in `r(varlist)' {
		qui tab `var' 
		if `r(r)'>1 {
			di "`id' : `var'"
		}
	}
restore 
}

//list suspesious incompleted data entry
noi di "list suspesious incompleted data entry"
noi list f3_a0_1 f3_a0_2 if dataenter==""
// 45019 is a incomplete interview

//recover True/False variable 
ds f3_d2_* f3_g5_* f3_g10_*
foreach i of var `r(varlist)' {
	replace `i'="0" if `i'==""
}

***************************************
//data cleaning
ren f3_a0_1 f3_a0_1surveyhousecode
replace f3_a0_1=substr(f3_a0_1,1,3) + "-" + substr(f3_a0_1,4,3)+ "-" + substr(f3_a0_1,7,3)
ren f3_a0_2 f3_a0_2surveychildid
lab var f3_a0_1 "HH_ID"
lab var f3_a0_2 "Child_ID"
ren f3_a1_1 f3_a1_1childrencount
destring f3_a1_1, replace
ren f3_a1_2 f3_a1_2_1
ren f3_a1_3a f3_a1_3a_1
ren f3_a1_3b f3_a1_3b_1
forvalue i=1/5 {
	ren f3_a1_2_`i' f3_a1_2sex`i'
	replace f3_a1_2sex`i'="1" if f3_a1_2sex`i'=="Male"
	replace f3_a1_2sex`i'="2" if f3_a1_2sex`i'=="Female"
	destring f3_a1_2sex`i', replace
	gen f3_a1_3age`i'=f3_a1_3a_`i' + " years and " + f3_a1_3b_`i' + " months"
	replace f3_a1_3age`i'="null" if f3_a1_3a_`i'=="" & f3_a1_3b_`i' ==""
	drop f3_a1_3a_`i' f3_a1_3b_`i'	
}
ren f3_b1 f3_b1intervieweechildmother
ren f3_b2 f3_b2motheralive
ren f3_b3 f3_b3ttpregnancy
ren f3_b4 f3_b4ttpregnancycount
destring f3_b4, replace
ren f3_b5 f3_b5ttprepregnancy
ren f3_b6_1 f3_b6_1ttmonth
destring f3_b6_1, replace
ren f3_b6_2 f3_b6_2ttyear
destring f3_b6_2, replace
ren f3_b7 f3_b7birthplace
ren f3_b7_2 f3_b7_2birthplaceother
ren f3_b8 f3_b8breastfeed
ren f3_b9 f3_b9breastfeedmonthcount
destring f3_b9, replace
ren f3_c1 f3_c1allvaccinationreceived
//f3_c2 treat multiple select varialbes 
	ren f3_c2 temp
	gen f3_c2missedvaccinationrecall=0
	forvalue i=1/8 {
		local value=10^(8-`i')
		replace f3_c2m=f3_c2m + `value' if strpos(temp,"`i'")>0
	}
	replace f3_c2m=. if f3_c2m==0
	tostring f3_c2m, replace format(%08.0f)
	drop temp
ren f3_c3 f3_c3bcgreceivedrecall
ren f3_c4 f3_c4bcgreceivedrecalldate
ren f3_c5 f3_c5pentareceivedrecall
ren f3_c6 f3_c6pentadosescountrecall
destring f3_c6, replace
ren f3_c7_1 f3_c7_2_1cliniccodepenta1
destring f3_c7_2_1, replace
replace f3_c7_2_1=98 if f3_c7_2_1==22
ren f3_c7_1_2 f3_c7_2_2cliniccodepenta2
ren f3_c7_1_3 f3_c7_2_3cliniccodepenta3
ren f3_c7_2 cliniccodeotherpenta1
ren f3_c7_2_2 cliniccodeotherpenta2
ren f3_c7_2_3 cliniccodeotherpenta3
ren f3_c7_3 f3_c7_3_1datepenta1
ren f3_c7_3_2 f3_c7_3_2datepenta2
ren f3_c7_3_3 f3_c7_3_3datepenta3
ren f3_c8 f3_c8vaccinationwithpentarecall
ren f3_c9_2 f3_c9_2_1addvxcountpenta1
ren f3_c9_3 f3_c9_3_1addvxnamepenta1
ren f3_c9_2_2 f3_c9_2_2addvxcountpenta2
ren f3_c9_2_3 f3_c9_3_2addvxnamepenta2
ren f3_c9_3_2 f3_c9_2_3addvxcountpenta3
ren f3_c9_3_3 f3_c9_3_3addvxnamepenta3
destring f3_c9_2_1addvxcountpenta1, replace
destring f3_c9_2_2addvxcountpenta2, replace
destring f3_c9_2_3addvxcountpenta3, replace
ren f3_c10 f3_c10polioreceivedrecall
ren f3_c11 f3_c11poliodriverecall
ren f3_c12 f3_c12poliodosesdrivecountrecall
destring f3_c12, replace
ren f3_c13_2a f3_c13_2_1datepolio1
ren f3_c13_2b f3_c13_2_2datepolio2
ren f3_c13_2c f3_c13_2_3datepolio3
ren f3_c13_2d f3_c13_2_4datepolio4
ren f3_c13_2e f3_c13_2_5datepolio5
ren f3_c14 f3_c14polioclinicrecall
ren f3_c15 f3_c15poliodosescliniccountrecal
destring f3_c15, replace
ren f3_c16_2a f3_c16_2_1datepolio1
ren f3_c16_2b f3_c16_2_2datepolio2
ren f3_c16_2c f3_c16_2_3datepolio3
ren f3_c16_2d f3_c16_2_4datepolio4
ren f3_c16_2e f3_c16_2_5datepolio5
ren f3_c17 f3_c17firstpoliodose
ren f3_c18 f3_c18ipv
ren f3_c19 f3_c19ipvcount
destring f3_c19, replace
ren f3_c20 f3_c20measlesrecall
ren f3_c21 f3_c21measlesdriverecall
ren f3_c22_1 f3_c22_1measlesdrivecountrecall
destring f3_c22_1, replace
ren f3_c22_3a f3_c22_3_1datemeasles1
ren f3_c22_3b f3_c22_3_2datemeasles2
ren f3_c22_3c f3_c22_3_3datemeasles3
ren f3_c22_3d f3_c22_3_4datemeasles4
ren f3_c22_3e f3_c22_3_5datemeasles5
ren f3_c23 f3_c23measlesclinicrecall
ren f3_c24 f3_c24measlescliniccountrecall
destring f3_c24, replace
ren f3_c25_1 f3_c25_2_1cliniccodemeasles1
ren f3_c25_1_2 f3_c25_2_2cliniccodemeasles2
ren f3_c25_1_3 f3_c25_2_3cliniccodemeasles3
ren f3_c25_2 cliniccodeothermeasles1
ren f3_c25_2_2 cliniccodeothermeasles2
ren f3_c25_2_3 cliniccodeothermeasles3
ren f3_c25_3 f3_c25_3_1datemeasles1
ren f3_c25_3_2 f3_c25_3_2datemeasles2
ren f3_c25_3_3 f3_c25_3_3datemeasles3
ren f3_c26 f3_c26measlesdisease
ren f3_c27 f3_c27measlesdiseasedate
destring f3_c27m, replace
tostring f3_c27m, replace format(%02.0f)
replace f3_c27m="" if f3_c27m=="."
replace f3_c27m=f3_c27m+"-"+substr(f3_c27_b,3,2) if f3_c27_b!=""
drop f3_c27_b
ren f3_c28 f3_c28measlesdiagnosedat
ren f3_c28_2 measlesdiagnosedatother
ren f3_c29 f3_c29othervaccination
ren f3_c30 f3_c30othervaccinationname
replace f3_c30o=f3_c30o+"$$"+f3_c30_2+"$$"+f3_c30_3
drop f3_c30_2 f3_c30_3
ren f3_d1 f3_d1healthcarecardpresent
ren f3_d2_3a f3_d2_3bcg 
ren f3_d2_4a f3_d2_4bcg 
ren f3_d2_3b f3_d2_3polio 
ren f3_d2_4b f3_d2_4polio
ren f3_d2_3c f3_d2_3opv1 
ren f3_d2_4c f3_d2_4opv1
ren f3_d2_3d f3_d2_3opv2 
ren f3_d2_4d f3_d2_4opv2
ren f3_d2_3e f3_d2_3opv3
ren f3_d2_4e f3_d2_4opv3
ren f3_d2_3f f3_d2_3penta1
ren f3_d2_4f f3_d2_4penta1
ren f3_d2_3g f3_d2_3penta2 
ren f3_d2_4g f3_d2_4penta2
ren f3_d2_3h f3_d2_3penta3
ren f3_d2_4h f3_d2_4penta3
ren f3_d2_3i f3_d2_3pcv1 
ren f3_d2_4i f3_d2_4pcv1
ren f3_d2_3j f3_d2_3pcv2 
ren f3_d2_4j f3_d2_4pcv2
ren f3_d2_3k f3_d2_3pcv3 
ren f3_d2_4k f3_d2_4pcv3
ren f3_d2_3l f3_d2_3measles1 
ren f3_d2_4l f3_d2_4measles1
ren f3_d2_3m f3_d2_3measles2
ren f3_d2_4m f3_d2_4measles2
ren f3_d2_3n f3_d2_3ipv1 
ren f3_d2_4n f3_d2_4ipv1
ren f3_d2_3o f3_d2_3ipv2
ren f3_d2_4o f3_d2_4ipv2
ren f3_d2_3p f3_d2_3ipv3
ren f3_d2_4p f3_d2_4ipv3
ren f3_d2_3q f3_d2_3mothertt1
ren f3_d2_4q f3_d2_4mothertt1
ren f3_d2_3r f3_d2_3mothertt2 
ren f3_d2_4r f3_d2_4mothertt2
ren f3_d2_3s f3_d2_3mothertt3 
ren f3_d2_4s f3_d2_4mothertt3
ren f3_d2_3t f3_d2_3mothertt4 
ren f3_d2_4t f3_d2_4mothertt4
ren f3_d2_3u f3_d2_3mothertt5 
ren f3_d2_4u f3_d2_4mothertt5
ren f3_d3 f3_d3healthcarecardimagetaken
ren f3_d4 f3_d4bcgmark
ren f3_e1 f3_e1headethnicity
ren f3_e1_2 f3_e1_2headethnicityother
ren f3_e2 f3_e2childbornkorangi
ren f3_e3 f3_e3korangiarrivaldate
destring f3_e3k, replace
tostring f3_e3k, replace format(%02.0f)
replace f3_e3k="" if f3_e3k=="."
replace f3_e3k=f3_e3k+"-"+substr(f3_e3_b,3,2) if f3_e3_b!=""
drop f3_e3_b
ren f3_e4 f3_e4livedatbefore
ren f3_e5 f3_e5fathereducation
destring f3_e5, replace
ren f3_e6 f3_e6mothereducation
destring f3_e6, replace
ren f3_e7 f3_e7fatheroccupation
ren f3_e8 f3_e8motheroccupation
ren f3_e9 f3_e9mothercellphone
ren f3_e10 f3_e10peoplecount
destring f3_e10, replace
ren f3_f1_1 f3_f1_1zmenrolled
ren f3_f2_2 f3_f1_2zmqrcode
ren f3_f2_1 f3_f2zmphone
ren f3_f3 f3_f3otherenrolled
ren f3_f3_1 f3_f3_1otherenrolledname
ren f3_f4 f3_f4gocentrewith
ren f3_f4_2 f3_f4_2gocentrewithother
ren f3_f5 f3_f5gocentrevia
ren f3_f5_2 f3_f5_2gocentreviaother
ren f3_f6 f3_f6homecentertime
destring f3_f6, replace
ren f3_f7 f3_f7clinicvisit
ren f3_f8_1 f3_f8_1clinicvisitcare
destring f3_f8_1, replace
replace f3_f8_1=98 if f3_f8_1==22
ren f3_f8_2 f3_f8_2clinicvisitcareother
ren f3_f9_1 f3_f9_1clinicvisitsick
destring f3_f9_1, replace
replace f3_f9_1=98 if f3_f9_1==22
ren f3_f9_2 f3_f9_2clinicvisitsickother
ren f3_f10 f3_f10goclinicvia
ren f3_f10_2 f3_f10_2goclinicviaother
ren f3_f11 f3_f11homeclinictime
destring f3_f11, replace
ren f3_g1 f3_g1roomcount
destring f3_g1r, replace
ren f3_g1_1 f3_g1_1homeownership
ren f3_g2 f3_g2watersource
ren f3_g3 f3_g3toilet
ren f3_g3_1 f3_g3_1toiletother
ren f3_g4 f3_g4toiletusebyothers
gen f3_g5houseitems=""
ds f3_g5_*
foreach var in `r(varlist)' {
	replace f3_g5houseitems=f3_g5houseitems+`var'
	drop `var'
}
ren f3_g6 f3_g6fuleforcooking
ren f3_g6_1 f3_g6_1fuleforcookingother
ren f3_g6_2 f3_g6_2kitchen
ren f3_g7 f3_g7floor
ren f3_g7_1 floorother
ren f3_g8 f3_g8roof
ren f3_g8_1 roofother
ren f3_g9 f3_g9wall
ren f3_g9_1 wallother
gen f3_g10peopleitems=""
ds f3_g10_*
foreach var in `r(varlist)' {
	replace f3_g10peopleitems=f3_g10peopleitems+`var'
	drop `var'
}
ren f3_g11 f3_g11bankaccount
ren f3_g12 f3_g12houseincome
destring f3_g12, replace
ren f3_h1 f3_h1scaleatzero
ren f3_h2 f3_h2childweight
destring f3_h2, replace
ren f3_i1 f3_i1comment

//clean clinic code variables
ds f3_c7_2_2 f3_c7_2_3
foreach var in `r(varlist)' {
	replace `var'="1" if `var'=="Sindh Govt,Dispensary,Bilal Colony"
	replace `var'="2" if `var'=="Sindh Govt,Dispensary,Emergency Center Korangi 1/2"
	replace `var'="3" if `var'=="Homeophatic Dispensary ,Sector 35-b"
	replace `var'="4" if `var'=="MCH Center Korangi No 21/2"
	replace `var'="5" if `var'=="BHU 48/E Korangi"
	replace `var'="6" if strpos(`var', "BHU 50/A Korang")>0
	replace `var'="7" if `var'=="BHU 33/C Korangi"
	replace `var'="8" if `var'=="BHU 51/B Korangi"
	replace `var'="9" if `var'=="Sindh Govt Hospital Korangi No 5"
	replace `var'="10" if `var'=="Baldia Maternity Home Korangi 21/2"
	replace `var'="11" if `var'=="THO office Korangi 2.5"
	replace `var'="12" if `var'=="Jinnah Medical College Hospital Bilal Colony"
	replace `var'="13" if `var'=="Sir Syed Hospital"
	replace `var'="14" if `var'=="Jinnah Foundation Bhittai Colony near Altaf Town"
	replace `var'="15" if `var'=="Indus Hospital"
	replace `var'="16" if `var'=="Chinoit General Hospital Korangi 21/2"
	replace `var'="17" if `var'=="Anjuman-e-Khawateen baray Falah-o-Behbod,Korangi"
	replace `var'="18" if `var'=="East Side Hospital(vita Chorangi)"
	replace `var'="19" if `var'=="Hope Nasir Colony"
	replace `var'="21" if `var'=="Creek G.H(48-E Chakra Goth)"
	replace `var'="98" if `var'=="Other"
	replace `var'="99" if `var'=="Don't know"
	destring `var',replace
}

//clean format of vaccine receive/miss variables
ds f3_c3b f3_c5 f3_c10 f3_c11 f3_c14 f3_c18 f3_c20 f3_c21 f3_c23 
foreach var in `r(varlist)' {
	replace `var'="RECEIVE" if `var'=="1. Yes"
	replace `var'="MISS" if `var'=="2. No"
	replace `var'="DONT KNOW" if `var'=="3. Don't know"
}
ds f3_d2_3*
foreach var in `r(varlist)' {
	replace `var'="RECEIVE" if `var'=="1"
	replace `var'="MISS" if `var'=="0"
}

//clean format of date variables
ds f3_c4 f3_c7_3_* f3_c13_2* f3_c16_2* f3_c22_3* f3_c25_3* f3_d2_4*
foreach var in `r(varlist)' {
	replace `var'=substr(`var',1,2) + "-" + substr(`var',3,2) + "-" + substr(`var',5,2) ///
		if strpos(`var',"/")+strpos(`var',"-")==0 & `var'!=""
	replace `var'=substr(`var',1,2) + "-" + substr(`var',4,2) + "-" + substr(`var',7,2) ///
		if strpos(`var',"/")>0 & strpos(`var',"-")==0 & `var'!=""
}

//treat the single selection coded varaiables
ds f3_b1 f3_b2 f3_b3 f3_b5 f3_b7b f3_b8 f3_c1a f3_c8 f3_c17 f3_c25_2_* f3_c26 f3_c28m ///
	f3_c29 f3_d1 f3_d3 f3_d4 f3_e1h f3_e2 f3_e4 f3_e9 f3_f1_1 f3_f3o f3_f4g f3_f5g ///
	f3_f7 f3_f10g f3_g1_1 f3_g2 f3_g3t f3_g4 f3_g6f f3_g6_2 f3_g7 f3_g8 f3_g9 f3_g11 ///
	f3_h1
foreach var in `r(varlist)' {
	replace `var'=substr(`var',1, strpos(`var',".")-1)
	destring `var',replace
}
drop hm
saveold "$tempdata\Entered_Form3.dta", replace

exit





