qui {
/********************************************************
* Last Modified:  11/14/18  by Wenfeng Gong
* Project Name:   Near-time data inspection tool (template)
* File Name:      Data_validation_Form3.do 
********************************************************/
capture log c
log using "Program_running_log\Data_validation_Form3&4.log", replace
noi di "***Data_validation_Form3&4 ****"

//***** create an empty query list (User DO NOT change) ************
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

//***** Preload programs (User DO NOT change) ************
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

//***** Define Checkpoints (User should change) ****
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


//***********************
// Checkpoint 29
use "$cleandata\Form3_clean.dta",clear 
mmerge f3_a0_1 using "$tempdata\Form1&2_temp.dta", type(1:1) unmatched(none) umatch(f1_0) uif(f1_1_1==maxvisit)
gen querytag=0
replace querytag=1 if f3_a1_1<f2_4 & f2_4!=.
querylister2, checkpoint("29")


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
// Checkpoint 56
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
replace querytag=1 if f3_c28==5 & (measlesdiagnosedatother=="" | measlesdiagnosedatother=="null")
replace querytag=1 if f3_c25_2_1==98 & (cliniccodeothermeasles1=="" | cliniccodeothermeasles1=="null")
replace querytag=1 if f3_c7_2_1==98 & (cliniccodeotherpenta1=="" | cliniccodeotherpenta1=="null")
replace querytag=1 if f3_b7b==98 & (f3_b7_2birthplaceother=="" | f3_b7_2birthplaceother=="null")
querylister2, checkpoint("56")

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
// Checkpoint 91
use "$cleandata\Form3_clean.dta",clear 
gen querytag=0
	//list all the required variables
ds f3_a0* f3_a1_1* f3_b1*  f3_b7b* f3_b8* f3_c1a* f3_c3b* f3_c5p* f3_c10* ///
	f3_c18* f3_c20* f3_c26* f3_c29* f3_d1h* f3_d4b*  f3_h2* 
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
