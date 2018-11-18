qui {
/********************************************************
* Last Modified:  11/14/18  by Wenfeng Gong
* Project Name:   Near-time data inspection tool (template)
* File Name:      Data_query_generate.do 
********************************************************/
capture log c
log using "Program_running_log\Data_query_generate.log", replace
noi di "***Data_query_generate***"

import excel using "code\Checkpoint_description.xlsx",clear firstrow
replace checkpoint=substr(checkpoint,11,.)
destring checkpoint, replace
drop if checkpoint==.
tempfile checkpointlist
save `checkpointlist'
tempfile maindata

clear
tempfile output
use "Data_query\Query_history\querylist.dta", clear
drop if checkpoint<100000
save `output'

use "Data_query\Query_history\querylist.dta", clear
mmerge checkpoint using `checkpointlist', type(n:1) unmatched(master)
drop _merge
tempfile workfile
save `workfile'
levelsof checkpoint,local(cplevs)
foreach cp of local cplevs {
	use `workfile',clear
		keep if checkpoint==`cp'
		replace Variables=trim(Variables)
		local vlist=Variables[1]
		if "`vlist'"=="" {
			append using `output'
			save `output', replace
			continue
		}
		tokenize `vlist', parse(" ;")
		//di "1=|`1'|, 2=|`2'|, 3=|`3'|, 4=|`4'|, 5=|`5'|, 6=|`6'|"
		local varadd = ""
		while `"`1'"'!="" {
			cap ds `1'
			if _rc==111 {
				local varadd = "`varadd'" + " " + "`1'"
			}
			mac shift
		}
		//di "`varadd'"
		if Form[1]=="Form1" | Form[1]=="Form2" {
			noi di "Checkpoint `cp': Form 1&2"
			preserve 
				use "$tempdata\Form1&2_temp.dta",clear
				gen checkpoint=`cp'
				gen HH_ID=f1_0 
				gen Visit_Num=f1_1_1 
				replace Visit_Num=0 if Visit_Num==.
				save `maindata',replace
			restore
				sort checkpoint HH_ID Visit_Num Status
				ds checkpoint HH_ID Visit_Num, not
				collapse (firstnm) `r(varlist)', by(checkpoint HH_ID Visit_Num)
				mmerge checkpoint HH_ID Visit_Num using `maindata', type(n:1) ukeep(`varadd') unmatched(master)
		}
		else if Form[1]=="Form4" {
			noi di "Checkpoint `cp': Form 4"
			preserve 
				use "$cleandata\Form4_clean.dta",clear
				gen checkpoint=`cp'
				gen  HH_ID=f4_a0collecthousecode
				gen  Visit_Num=f4_a0_2visittype
				gen  Child_ID=f4_a1collectchildid
				replace Visit_Num=0 if Visit_Num==.
				save `maindata',replace
			restore
			mmerge checkpoint HH_ID Child_ID Visit_Num using `maindata', type(n:1) ukeep(`varadd') unmatched(master)
		}
		else if Form[1]=="Form3" {
			noi di "Checkpoint `cp': Form 3"
			preserve 
				use "$cleandata\Form3_clean.dta",clear
				gen checkpoint=`cp'
				gen  HH_ID=f3_a0_1surveyhousecode
				gen  Child_ID=f3_a0_2surveychildid
				save `maindata',replace
			restore
			mmerge checkpoint HH_ID Child_ID using `maindata', type(n:1) ukeep(`varadd') unmatched(master)
		}
		else if Form[1]=="Translog" {
			noi di "Checkpoint `cp': Translog"
			preserve 
				use "$cleandata\Log_Transportation_log.dta",clear
					gen HH_ID="Driver: " + Driver 
					gen Child_ID="Trip: " + string(Trip_of_day)
				gen checkpoint=`cp'
				ren Time_depart temp
					gen Time_depart=string(temp, "%tC_HH:MM")
					drop temp
				ren Time_arrive temp
					gen Time_arrive=string(temp, "%tC_HH:MM")
					drop temp
				replace Date="." if Date==""
				save `maindata',replace
			restore
			mmerge checkpoint Date HH_ID Child_ID using `maindata', type(n:1) ukeep(`varadd') unmatched(master)
		}
		else if Form[1]=="Worklog" {
			noi di "Checkpoint `cp': Worklog"
			preserve 
				use "$cleandata\Log_Work_hour_log.dta",clear
					gen HH_ID="Team: " + Team 
					gen Child_ID="Trip: " + string(Trip_of_day)
				gen checkpoint=`cp'
				ren Time_depart temp
					gen Time_depart=string(temp, "%tC_HH:MM")
					drop temp
				ren Time_arrive temp
					gen Time_arrive=string(temp, "%tC_HH:MM")
					drop temp
				ren Time_initiate temp
					gen Time_initiate=string(temp, "%tC_HH:MM")
					drop temp
				ren Time_end temp
					gen Time_end=string(temp, "%tC_HH:MM")
					drop temp
				ren Time_back temp
					gen Time_back=string(temp, "%tC_HH:MM")
					drop temp
				replace Date="." if Date==""
				save `maindata',replace
			restore
			mmerge checkpoint Date HH_ID Child_ID using `maindata', type(n:1) ukeep(`varadd') unmatched(master)
		}
		else if Form[1]=="GISlog" {
			noi di "Checkpoint `cp': GISlog"
			preserve 
				use "$cleandata\Log_GIS_sampling_log.dta",clear
					gen HH_ID="Quad: " + Quad_ID 
					gen Child_ID="Dwelling: " + Dwell_ID
				gen checkpoint=`cp'
				replace Date="." if Date==""
				save `maindata',replace
			restore
			mmerge checkpoint Date HH_ID Child_ID using `maindata', type(n:1) ukeep(`varadd') unmatched(master)
		}

		replace Variables="" if checkpoint==`cp'
		ds `varadd'
		label drop _all
		foreach varaddi of var `r(varlist)' {
			if "`varaddi'"=="f4_b2collectiontime" {
				tostring `varaddi', replace force format(%tc_HH:MM) 
			}
			else {
				tostring `varaddi', replace force
			}
			replace Variables=Variables + "`varaddi'=" + `varaddi' + "; " if checkpoint==`cp'
			drop `varaddi'
		}
		append using `output'
		save `output', replace
}

use `output', clear
cap drop _merge
sort HH_ID Child_ID checkpoint Visit_Num Status 
order checkpoint HH_ID Child_ID Visit_Num

export excel using "$datapath\Query_list_with_supporting_variable.xlsx",replace firstrow(variables)

exit
