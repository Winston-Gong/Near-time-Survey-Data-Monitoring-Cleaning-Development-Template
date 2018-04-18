qui {
/********************************************************
* Last Modified:  09/02/16  by Wenfeng Gong
********************************************************/
capture log c
log using "Program_running_log\Data_validation_Logs.log", replace
noi di "***Data_validation_Logs ****"

//build on Form 3&4 query list
use "Data_query\Query_history\querylist.dta", clear
cap tostring checkpoint, replace
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
		cap gen Child_ID="."
		cap gen HH_ID="."
		ds HH_ID Visit_Num FW_ID Date Child_ID, varwidth(20)
		keep `r(varlist)'
		gen checkpoint="`checkpoint'"
		append using "Data_query\Query_history\querylist.dta"
		save "Data_query\Query_history\querylist.dta", replace 
	restore
	drop querytag
   end
//***** End preload programs ********
//Checkpoint 100: duplicate Child ID in HH visit log
use "$cleandata\Log_HH_visit_log.dta", clear
duplicates tag HH_ID Visit_Num, gen(dup)
	sort dup HH_ID Date
	ren Date Datenum
	gen Date=string(Datenum,"%td_D-N-Y")
sum dup
if r(sum)>0 {
	local warn : di "Warning: Household_visit_log are not clean and have duplicated HH_ID"
	noi di "`warn'"
	global warningtracker="$warningtracker" + "& `warn'"
	noi duplicates list HH_ID Visit_Num
	gen querytag=(dup>0)
	duplicates drop HH_ID Visit_Num, force 
	noi querylister2, checkpoint("100")
}
cap drop dup
duplicates drop HH_ID Visit_Num, force 
save "$cleandata\Log_HH_visit_log.dta",replace 

//Checkpoint 110: duplicate Child ID in Transportation log
use "$cleandata\Log_Transportation_log.dta", clear
duplicates tag Date Driver Trip_of_day, gen(dup)
	ren Date Datenum
	gen Date=string(Datenum,"%td_D-N-Y")
	gen HH_ID="Driver: " + Driver 
	gen Child_ID="Trip: " + string(Trip_of_day)
	order HH_ID Child_ID
sum dup
if r(sum)>0 {
	local warn : di "Warning: Transportation_log are not clean and have duplicated Date Driver Trip_of_day"
	noi di "`warn'"
	global warningtracker="$warningtracker" + "& `warn'"
	noi duplicates list Date Driver Trip_of_day
	gen querytag=(dup>0)
	duplicates drop Date Driver Trip_of_day, force 
	noi querylister2, checkpoint("110")
}
cap drop dup 
cap drop HH_ID Child_ID
duplicates drop Date Driver Trip_of_day, force 
save "$cleandata\Log_Transportation_log.dta",replace 
save "Entered_data\Processed_log_data\Log_Transportation_log.dta",replace

//Checkpoint 120: duplicate Child ID in Work Hour log
use "$cleandata\Log_Work_hour_log.dta", clear
duplicates tag Date Team Trip_of_day, gen(dup)
	ren Date Datenum
	gen Date=string(Datenum,"%td_D-N-Y")
	gen HH_ID="Team: " + Team 
	gen Child_ID="Trip: " + string(Trip_of_day)
	order HH_ID Child_ID
sum dup
if r(sum)>0 {
	local warn : di "Warning: Work_hour_log are not clean and have duplicated Date Team Trip_of_day"
	noi di "`warn'"
	global warningtracker="$warningtracker" + "& `warn'"
	noi duplicates list Date Team Trip_of_day
	gen querytag=(dup>0)
	duplicates drop Date Team Trip_of_day, force 
	noi querylister2, checkpoint("120")
}
cap drop dup 
cap drop HH_ID Child_ID
duplicates drop Date Team Trip_of_day, force 
save "$cleandata\Log_Work_hour_log.dta",replace 
save "Entered_data\Processed_log_data\Log_Work_hour_log.dta",replace

//Checkpoint 130: duplicate Child ID in GIS sampling log
use "$cleandata\Log_GIS_sampling_log.dta", clear
duplicates tag Date Quad_ID Dwell_ID, gen(dup)
	sort dup Date Quad_ID Dwell_ID
	ren Date Datenum
	gen Date=string(Datenum,"%td_D-N-Y")
	gen HH_ID="Quad: " + Quad_ID 
	gen Child_ID="Dwelling: " + Dwell_ID
sum dup
if r(sum)>0 {
	local warn : di "Warning: GIS_sampling_log are not clean and have duplicated HH_ID"
	noi di "`warn'"
	global warningtracker="$warningtracker" + "& `warn'"
	noi duplicates list Date Quad_ID Dwell_ID
	gen querytag=(dup>0)
	duplicates drop Date Quad_ID Dwell_ID, force 
	noi querylister2, checkpoint("130")
}
cap drop dup
cap drop HH_ID Child_ID
duplicates drop Date Quad_ID Dwell_ID, force 
sort Date Team
save "$cleandata\Log_GIS_sampling_log.dta",replace 

//***********************
// Checkpoint 101
use "$cleandata\Form1_clean.dta",clear
keep if f1_1_1visit_no==1
mmerge f1_0house_code using "$cleandata\Log_HH_visit_log.dta", type(1:n) unmatched(master) umatch(HH_ID)
sum Logdate
gen querytag=1 if _merge==1 & visitdate<`r(max)'
querylister2, checkpoint("101")

//***********************
// Checkpoint 102 106 107
use "$cleandata\Log_HH_visit_log.dta", clear
mmerge HH_ID Visit_Num using "$cleandata\Form1_clean.dta", type(1:1) unmatched(master) umatch(f1_0house_code f1_1_1visit_no)
gen querytag=1 if _merge==1 & Datenum<$Today-3
querylister2, checkpoint("102")
gen querytag=1 if _merge==3 & Datenum!=visitdate
querylister2, checkpoint("106")
gen querytag=1 if _merge==3 & FW_ID!=f1_1_3field_worker
querylister2, checkpoint("107")

//***********************
// Checkpoint 103 104 105
use "$cleandata\Log_HH_visit_log.dta", clear
drop if Child_ID=="" | Child_ID=="99999"
duplicates drop HH_ID Child_ID, force
mmerge Child_ID using "$cleandata\Form3_clean.dta", type(n:1) unmatched(both) umatch(f3_a0_2)
gen querytag=1 if _merge==1 & Datenum<$Today-3
querylister2, checkpoint("103")
sum Logdate
gen querytag=1 if _merge==2 & interviewdate<`r(max)'
querylister2, checkpoint("104")
gen querytag=1 if _merge==3 & HH_ID!=f3_a0_1
querylister2, checkpoint("105")

//***********************
// Checkpoint 111 114
use "$cleandata\Log_Transportation_log.dta", clear
	gen HH_ID="Driver: " + Driver 
	gen Child_ID="Trip: " + string(Trip_of_day)
gen querytag=1 if Trip_of_day==.
querylister2, checkpoint("111")
sort Datenum Driver Trip_of_day
by Datenum Driver: gen maxtrip=Trip_of_day[_N]
by Datenum Driver: gen counttrip=_N
by Datenum Driver: gen numtrip=_n
keep if counttrip==numtrip
gen querytag=1 if Trip_of_day!=0 & Trip_of_day!=. & maxtrip!=counttrip
querylister2, checkpoint("114")

//*********************** 
// Checkpoint 112 113
use "$cleandata\Log_Transportation_log.dta", clear
	gen HH_ID="Driver: " + Driver 
	gen Child_ID="Trip: " + string(Trip_of_day)
gen traveltime=(Time_arrive-Time_depart)/1000/60
gen querytag=1 if traveltime<5 | traveltime>480 | traveltime==.
querylister2, checkpoint("112")
gen querytag=1 if traveltime>60 & traveltime<=480 
querylister2, checkpoint("113")

//*********************** 
// Checkpoint 115
use "$cleandata\Log_Transportation_log.dta", clear
	gen HH_ID="Driver: " + Driver 
	gen Child_ID="Trip: " + string(Trip_of_day)
gen querytag=1 if Trip_purpose==.
querylister2, checkpoint("115")

//*********************** 
// Checkpoint 116
use "$cleandata\Log_Transportation_log.dta", clear
	gen HH_ID="Driver: " + Driver 
	gen Child_ID="Trip: " + string(Trip_of_day)
gen traveldist=real(Meter_arrive)-real(Meter_depart)
gen querytag=1 if traveldist<1 | traveldist>50 | traveldist==.
querylister2, checkpoint("116")

//*********************** 
// Checkpoint 117 118
use "Entered_data\Processed_log_data\Fieldwork_calendar.dta",clear
cap drop Subdivision
keep if Fieldday==1
gen HH_ID=Method
bysort Date: replace HH_ID=HH_ID+" & "+HH_ID[_n-1] if HH_ID!=Method[_n-1]
gen Child_ID= string(Teamnumber)
bysort Date: replace Child_ID=Child_ID+" & "+Child_ID[_n-1]
replace Child_ID="Team: " + Child_ID
replace HH_ID="Method: " + HH_ID
order Child_ID
replace Child_ID=substr(Child_ID, 1, length(Child_ID)-3)
replace HH_ID=substr(HH_ID, 1, length(HH_ID)-3)
collapse (sum) Fieldday (last) HH_ID Child_ID Datestr, by(Date)
ren Date Datenum
ren Datestr Date
mmerge Date using "$cleandata\Log_Transportation_log.dta", type(1:n) unmatched(master) 
sum Logdate
gen querytag=1 if _merge==1 & Datenum<`r(max)'
querylister2, checkpoint("117")
keep if _merge==3 
collapse (first) Fieldday HH_ID Child_ID , by(Date Driver)
gen i=_n
collapse (first) Fieldday HH_ID Child_ID (count) i, by(Date)
gen querytag=1 if Fieldday>2 & i<2
querylister2, checkpoint("118")

//*********************** 
// Checkpoint 119
use "$cleandata\Log_Blood_collection_log.dta",clear
gen HH_ID=_n
collapse (count) HH_ID, by(Date_collect)
tostring HH_ID, replace
replace HH_ID="Num of Sample: " + HH_ID
gen Date=string(Date_collect, "%td_DD-NN-YY")
mmerge Date using "$cleandata\Log_Transportation_log.dta", type(1:n) unmatched(master) uif(Trip_purpose==2)
sum Logdate
gen querytag=1 if _merge==1 & Date_collect<`r(max)'
querylister2, checkpoint("119")

//*********************** 
// Checkpoint 121 122
use "Entered_data\Processed_log_data\Fieldwork_calendar.dta",clear
cap drop Subdivision
keep if Fieldday==1
gen HH_ID="Method: " + Method
gen Child_ID="Team: " + string(Teamnumber)
order HH_ID Child_ID
tostring Teamnumber, gen(Team)
ren Date Datenum
ren Datestr Date
mmerge Date Team using "$cleandata\Log_Work_hour_log.dta", type(n:n) unmatched(master)
sum Logdate
gen querytag=1 if _merge==1 & Datenum<`r(max)'
querylister2, checkpoint("121")
keep if _merge==3 
bysort Date Team: gen maxtrip=_N
keep if maxtrip==Trip_of_day
destring cluster*, replace force
egen num_cluster=rownonmiss(cluster1 cluster2 cluster3 cluster4 cluster5)
gen querytag=1 if maxtrip<num_cluster
querylister2, checkpoint("122")

//*********************** 
// Checkpoint 123
use "$cleandata\Log_Work_hour_log.dta",clear
	gen HH_ID="Team: " + Team 
	gen Child_ID="Trip: " + string(Trip_of_day)
gen querytag=1 if FSinitial=="" | length(FSinitial)<3
querylister2, checkpoint("123")

//*********************** 
// Checkpoint 124 125 126
use "$cleandata\Log_Work_hour_log.dta",clear
	gen HH_ID="Team: " + Team 
	gen Child_ID="Trip: " + string(Trip_of_day)
gen time1=(Time_arrive-Time_depart)/1000/60
gen time2=(Time_initiate-Time_arrive)/1000/60
gen time3=(Time_end-Time_initiate)/1000/60
gen time4=(Time_back-Time_end)/1000/60
gen querytag=1 if time1<5 | time1>40 | time1==.
replace querytag=1 if time2<0 
replace querytag=1 if time3<0 
replace querytag=1 if time4<5 | (time4>60 & time4!=.)
replace querytag=1 if Time_depart<clock("08:45","hm")
replace querytag=1 if Time_back>clock("17:00","hm")
querylister2, checkpoint("124")
gen querytag=1 if abs(time2-Minutes_initiate)>5 & time2!=.
querylister2, checkpoint("125")
gen querytag=1 if time3+time2<60 
querylister2, checkpoint("126")

//*********************** 
// Checkpoint 131
use "Entered_data\Processed_log_data\Fieldwork_calendar.dta",clear
cap drop Subdivision
keep if Fieldday==1 & Method=="GIS"
gen HH_ID="Method: " + Method
gen Child_ID="Team: " + string(Teamnumber)
tostring Teamnumber, gen(Team)
order HH_ID Child_ID
ren Date Datenum
ren Datestr Date
sort Datenum Team
mmerge Date Team using "$cleandata\Log_GIS_sampling_log.dta", type(1:n) unmatched(master)
sum Logdate
gen querytag=1 if _merge==1 & Datenum<`r(max)'
querylister2, checkpoint("131")

//*********************** 
// Checkpoint 132
use "$cleandata\Log_GIS_sampling_log.dta",clear
	gen HH_ID="Quad: " + Quad_ID 
	gen Child_ID="Dwelling: " + Dwell_ID
gen querytag=1 if (Condition=="Exist" | Condition=="New") & Residential=="1" & Sameas=="0" & (Visited=="0" | HH_ID_last=="")
querylister2, checkpoint("132")

//*********************** 
// Checkpoint 133 136
use "$cleandata\Log_GIS_sampling_log.dta",clear
	gen HH_ID="Quad: " + Quad_ID 
	gen Child_ID="Dwelling: " + Dwell_ID
drop if HH_ID_last=="." | HH_ID_last==""
destring Sameas, replace
drop if Sameas>0 & Sameas!=.
duplicates tag HH_ID_last, gen(dup)
gen querytag=(dup>=1)
querylister2, checkpoint("136")
duplicates drop HH_ID_last, force
mmerge HH_ID_last using "$cleandata\Form1_clean.dta", type(1:1) unmatched(master) umatch(f1_0house_code) uif(f1_1_1==maxvisit)
gen querytag=1 if _merge==1
querylister2, checkpoint("133")

//*********************** 
// Checkpoint 134
use "$cleandata\Log_GIS_sampling_log.dta",clear
	gen HH_ID="Quad: " + Quad_ID 
	gen Child_ID="Dwelling: " + Dwell_ID
keep if Condition!="New"
destring Dwell_ID, replace force
sort Quad_ID Dwell_ID
by Quad_ID: gen maxDwell=_N
collapse (last) Dwell_ID Date HH_ID Child_ID maxDwell, by(Quad_ID)
gen querytag=1 if Dwell_ID!=maxDwell
querylister2, checkpoint("134")

//*********************** 
// Checkpoint 135
use "$cleandata\Log_GIS_sampling_log.dta",clear
	gen HH_ID="Quad: " + Quad_ID 
	gen Child_ID="Dwelling: " + Dwell_ID
keep if Condition=="New"
destring BetweenID, replace force
destring AndID, replace force
gen querytag=1 if BetweenID==. | AndID==.
querylister2, checkpoint("135")

	
//***********************
cap drop querytag
use "Data_query\Query_history\querylist.dta", clear
sort checkpoint HH_ID Child_ID Visit_Num FW_ID 
order checkpoint HH_ID Child_ID Visit_Num FW_ID
destring checkpoint, replace
replace Visit_Num=0 if Visit_Num==.
replace Child_ID="." if Child_ID==""
replace HH_ID="." if HH_ID==""
replace Date="." if Date==""
save "Data_query\Query_history\querylist.dta", replace

exit
