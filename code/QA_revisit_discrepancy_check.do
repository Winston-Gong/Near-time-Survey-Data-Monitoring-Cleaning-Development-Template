//qui {
/********************************************************
* Last Modified:  04/04/16  by Wenfeng Gong
********************************************************/
//***** Preload programs ************
*the famous AllVars command
   capture program drop AllVars
   program define AllVars
      syntax [varlist] [, Exclude(varlist) CHAR D Label(string)]
      global AllVars `varlist' 
      if "`varlist'"~="" { 
	     unab unaball : `varlist'
      }
      else { 
      	  global AllVars `unabexc' 
      }
      if "`exclude'"~="" { 
      	  unab unabexc : `exclude'
      }
      tokenize `unabexc'
      while `"`1'"'!="" {
         global AllVars : subinstr global AllVars "`1'" "", word
         global AllVars : subinstr global AllVars "  " " ", all
         mac shift
      }
      if "`char'"~="" { 
      	foreach X of any $AllVars {
            local i : type `X'
            if substr("`i'",1,3)=="str" { 
            local j `j' `X'
            }
         }
         global AllVars `j'
      }
		local j
      if "`lable'"~="" { 
      	foreach X of any $AllVars {
            local i : variable label `X'
            if index(lower("`i'"),lower("`lable'"))>0 { 
            local j `j' `X'
            }
         }
         global AllVars `j'
      }
      global NAllVars: word count $AllVars
      di _n(1) in y "\$AllVars (${NAllVars}):" " $AllVars"
      if "`d'"~="" { 
      	 dd $AllVars
         }
   end

//***** End preload programs ********

capture log c
noi di "***QA_revisit_discrepancy_check***"

//initializing
set more off
set memory 100m
global form1name "form1dataQArevisit_160404"
global form2name "form2dataQArevisit_160404"
global form3name "form3dataQArevisit_160404"
global form4name ""

//working folder location
cd "C:\IVAC Pakistan raw data\QArevisitdata"
//data folder location
global qadata "C:\IVAC Pakistan raw data\QArevisitdata"
global cleandata "C:\IVAC Pakistan raw data\cleandata"
global datapath "C:\IVAC Pakistan raw data"
global tempdata "$datapath\tempdata"


********************************
**** Read round1 QA revisit data
//before read Form 3 with insheet; need to read the F3_G5 variable first, this 
// variable is read by insheet as numeric, and too long to convert back as string
clear
insheet using "$qadata/$form3name.csv", nonames
foreach var of varlist _all {
	local name =`var'[1]
	if strpos("`name'","F3_G5")>0 {
		ren `var' f3_g5houseitems
	}
	if strpos("`name'","F3_G10")>0 {
		ren `var' f3_g10peopleitems
	}
}
keep f3_g5houseitems f3_g10peopleitems
drop in 1
gen id=_n
tempfile tempfile 
	save `tempfile', replace 

insheet using "$qadata/$form3name.csv", clear nodouble
//add g5 and g10
gen id=_n
drop f3_g5houseitems f3_g10peopleitems
mmerge id using `tempfile', type(1:1)
drop id _merge

duplicates drop 

ds f3_c7_2* f3_c7_3* f3_c9_2* f3_c9_3*
foreach var in `r(varlist)' {
	local newname=substr("`var'",1,7) + "_" + substr("`var'",length("`var'"),1)+substr("`var'",8,.)
	ren `var' `newname'
}
ds f3_c13_2* f3_c16_2* f3_c22_3* f3_c25_3* f3_c25_2*
foreach var in `r(varlist)' {
	local newname=substr("`var'",1,8) + "_" + substr("`var'",length("`var'"),1)+substr("`var'",9,.)
	ren `var' `newname'
}
ds f3_a1_2sex* f3_b6_1ttmonth f3_b6_2ttyear f3_c7_2_* f3_c15 f3_c17 f3_c19 f3_c22_1 ///
	f3_c24 f3_c28m f3_e4 f3_f1_1zm 
foreach var in `r(varlist)' {
	cap destring `var', force replace
}
ds f3_a0_2surveychildid cliniccodeother* f3_c13_2* f3_c16_2* f3_c22_3* f3_c25_3* ///
		measlesdiagnosedatother f3_f1_2 
foreach var in `r(varlist)' {
	cap tostring `var', replace
}
tostring f3_c2m, replace format(%08.0f)
//trim long text variables for correction process
ds f3_b7_2 cliniccodeother* f3_f8_2 f3_f5_2 f3_f4_2 f3_f3_1 f3_f2 f3_f1_2 f3_e7 f3_e8 ///
		f3_c30o f3_f9_2 f3_f10_2 f3_g3_1 f3_g6_1 floorother roofother wallother
foreach var in `r(varlist)' {
	replace `var'=trim(`var')
}
save "$tempdata/QAformtemp.dta", replace

insheet using "$qadata/$form2name.csv", clear
replace f2_11=trim(f2_11)
ren f1_0 f3_a0_1surveyhousecode
drop datechanged changedby datecreated f2_2 f2_3
duplicates drop 

//fix an unknown Form 2 duplication error
replace f2_4=99 if f3_a0_1=="111-243-301"
replace f2_5=2 if f3_a0_1=="111-243-301"
replace f2_6="30-03-16" if f3_a0_1=="111-243-301"
drop if f3_a0_1=="111-243-301" & f2_7_2=="null"

sort f3_a0_1
mmerge f3_a0 using "$tempdata/QAformtemp.dta", type(1:1) unmatched(both)

//clean format of date variables
ds f2_7_2 f3_c4 f3_c7_3* f3_c13_2* f3_c16_2* f3_c22_3* f3_c25_3* f3_d2_4*
foreach var in `r(varlist)' {
	replace `var'="0" + substr(`var',1,1) + "-" + "0" + substr(`var',3,1) + "-" + substr(`var',7,2) ///
		if strpos(`var',"/")==2 & strpos(substr(`var',strpos(`var',"/")+1,.),"/")==2 & strpos(`var',"-")==0 & `var'!="" & `var'!="null"
	replace `var'=substr(`var',1,2) + "-" + "0" + substr(`var',4,1) + "-" + substr(`var',8,2) ///
		if strpos(`var',"/")==3 & strpos(substr(`var',strpos(`var',"/")+1,.),"/")==2 & strpos(`var',"-")==0 & `var'!="" & `var'!="null"
	replace `var'="0" + substr(`var',1,1) + "-" + substr(`var',3,2) + "-" + substr(`var',8,2) ///
		if strpos(`var',"/")==2 & strpos(substr(`var',strpos(`var',"/")+1,.),"/")==3 & strpos(`var',"-")==0 & `var'!="" & `var'!="null"
	replace `var'=substr(`var',1,2) + "-" + substr(`var',4,2) + "-" + substr(`var',9,2) ///
		if strpos(`var',"/")==3 & strpos(substr(`var',strpos(`var',"/")+1,.),"/")==3 & strpos(`var',"-")==0 & `var'!="" & `var'!="null"
}

// team1 to QA revisit CS288(14 enroll)
// team2 to QA revisit EPI243(8 enroll) & EPI385(7 enroll)
// team3 to QA revisit CS244(5 enroll) & CS027(5 enroll) & CS313(6 enroll)
// team4 to QA revisit GIS650(7 enroll) & GIS698(7 enroll)

// team1 to QA revisit GIS099(7 enroll) & CS356(8 enroll)
// team2 to QA revisit CS214(7 enroll) & GIS390(7 enroll)
// team3 to QA revisit CS146(7 enroll) & EPI146(3 enroll)
// team4 to QA revisit EPI067(8 enroll) & CS184(4 enroll)

//fix HHID misuse in QA data
replace f3_a0_1="99" if f3_a0_1=="131-099-306"
replace f3_a0_1="131-099-306" if f3_a0_1=="131-099-302"
replace f3_a0_1="131-099-302" if f3_a0_1=="99"
replace f3_a0_1="122-288-702" if f3_a0_1=="121-288-301"

replace f3_a0_1=substr(f3_a0_1,1,2) + substr(f3_a0_2,1,1) + substr(f3_a0_1,4,5) ///
				+substr(f3_a0_2,2,1) + substr(f3_a0_1,10,.) if f3_a0_2!=""
list f3_a0_1 if f3_a0_2==""
replace f3_a0_1="111-067-604" if f3_a0_1=="114-067-404"
replace f3_a0_1="111-067-613" if f3_a0_1=="114-067-413"
replace f3_a0_1="124-214-307" if f3_a0_1=="122-214-407"
replace f3_a0_1="124-214-513" if f3_a0_1=="122-214-513"
replace f3_a0_1="124-146-304" if f3_a0_2=="43009" 
replace f3_a0_1="122-356-505" if f3_a0_1=="112-356-501" 
replace f3_a0_1="122-356-515" if f3_a0_1=="112-356-515" 
replace f3_a0_1="111-146-506" if f3_a0_1=="121-146-506" 
replace f3_a0_1="124-146-517" if f3_a0_1=="134-146-517" 
replace f3_a0_1="133-390-302" if f3_a0_1=="133-390-303" 

ds f3_b7_2 cliniccodeother* f3_f8_2 f3_f5_2 f3_f4_2 f3_f3_1 f3_f2 f3_f1_2 f3_e7 f3_e8 ///
		f3_c30o f3_f9_2 f3_f10_2 f3_g3_1 f3_g6_1 floorother roofother wallother
foreach var in `r(varlist)' {
	replace `var'=trim(`var')
}
tostring f2_7_1, replace force

replace f2_7_1=f2_7_2+"; "+ f2_7_3

AllVars f2_4-f3_c30, exclude(f3_a0_1 _merge *comment f2_7_2 f2_7_3)
foreach var in $AllVars {
	local qaname="q"+substr("`var'",2,.)
	ren `var' `qaname'
}
save "$tempdata/QAformtemp.dta", replace

clear
gen HH_ID=""
gen Question=""
gen Original_value=""
gen QArevisit_value=""
gen Order=.
tempfile discrepancy
	save `discrepancy'
	
use "$cleandata\Form2_clean.dta",clear
ren f1_0 f3_a0_1surveyhousecode
mmerge f3_a0_1 using "$cleandata\Form3_clean.dta", type(1:1) unmatched(both)
mmerge f3_a0_1 using "$tempdata/QAformtemp.dta", type(1:1) unmatched(using)
ren f3_a0_1 HH_ID
gen Question=""
tostring f2_7_1, replace force
replace f2_7_1=f2_7_2+"; "+ f2_7_3

gen Order=0
foreach var in $AllVars { 
	local qaname="q"+substr("`var'",2,.)
	tostring `var', replace force
	tostring `qaname', replace force
	replace Order=Order+1
	count
	forvalue i=1/`r(N)' {
		//di "`var'"
		//di "`=`qaname'[`i']'"
		//di "`=`var'[`i']'"
		if (lower("`=`var'[`i']'") != lower("`=`qaname'[`i']'")) & ///
			("`=`qaname'[`i']'"!="null") & ("`=`qaname'[`i']'"!="") & ///
			("`=`qaname'[`i']'"!="99") & (strpos("`=`qaname'[`i']'","999")==0) & ///
			("`=`qaname'[`i']'"!=".") ///
		{
			preserve
				keep in `i'
				keep HH_ID Question Order `var' `qaname' 
				replace Question="`var'"
				ren `var' Original_value
				ren `qaname' QArevisit_value
				append using `discrepancy'
				save `discrepancy',replace
			restore
		}
	}
}

use `discrepancy', clear
order HH_ID Order Question
sort HH_ID Order 
export excel "output_discrepancy", firstrow(variables) replace
exit
