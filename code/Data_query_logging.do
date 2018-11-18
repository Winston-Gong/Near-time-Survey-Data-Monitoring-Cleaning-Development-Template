qui {
/********************************************************
* Last Modified:  11/14/18  by Wenfeng Gong
* Project Name:   Near-time data inspection tool (template)
* File Name:      Data_query_logging.do 
********************************************************/
capture log c
log using "Program_running_log\Data_query_logging.log", replace
noi di "***Data_query_logging****"

//reflect previously Cancelled query
use "Data_query\Query_history\querylist.dta", clear
replace Date="." if Date==""
mmerge checkpoint HH_ID Child_ID Visit_Num Date using "Data_query\Query_history\Query_history_Force-cancelled.dta", type(1:1) unmatched(both) update replace
drop if Status=="Force-cancelled"
save,replace

//read query response
import excel using "Data_query\Query_list_no_supporting_variable.xlsx",clear firstrow allstring
ren Status Status
keep checkpoint HH_ID Child_ID Visit_Num Date FW_ID Status Responsible Comment
destring Visit_Num, replace
destring checkpoint, replace
cap tostring Child_ID, replace
cap tostring Date, replace
cap tostring Status, replace
cap tostring HH_ID, replace
cap tostring Responsible, replace
cap tostring Comment, replace
cap tostring FW_ID, replace
replace Child_ID="." if Child_ID==""
replace Date="." if Date==""
tempfile resposelog
drop if checkpoint==.
replace Status="cancelled" if strpos(lower(Status), "cancel")>0
save `resposelog'

//compile query response from query list with supporting variable
cap import excel using "$datapath\Query_list_with_supporting_variable.xlsx",clear firstrow allstring
if _rc!=601 {
	keep checkpoint HH_ID Child_ID Visit_Num Date Status Responsible Comment
	destring Visit_Num, replace
	destring checkpoint, replace
	replace Child_ID="." if Child_ID==""
	replace Date="." if Date==""
	tempfile resposelog2
	replace Status="cancelled" if strpos(lower(Status), "cancel")>0
	ren Status Status2
	ren Responsible Responsible2
	ren Comment Comment2
	drop if checkpoint==.
	save `resposelog2'
	use `resposelog',clear
	mmerge checkpoint HH_ID Child_ID Visit_Num Date using `resposelog2', type(1:1) unmatched(both) 
	drop if _merge==2 & trim(lower(Status2))!="resolved" & trim(lower(Status2))!="cancelled"
	replace Status=Status2 if trim(lower(Status2))=="resolved" | trim(lower(Status2))=="cancelled"
	replace Comment=Comment2 if trim(Comment)=="." | trim(Comment)=="" | trim(Comment)=="&&" 
	replace Comment=Comment + " && " + Comment2 if strpos(Comment,Comment2)<1 & strpos(Comment2,Comment)<=1 & trim(Comment2)!="&&"
	replace Responsible=Responsible2 if trim(Responsible)=="." | trim(Responsible)=="" | trim(Responsible)=="&" 
	replace Responsible=Responsible + " & " + Responsible2 if strpos(Responsible,Responsible2)<1 & strpos(Responsible2,Responsible)<=1 & trim(Responsible2)!="&"
	drop Status2 Responsible2 Comment2
	save `resposelog',replace
}

//reflect query response
use "Data_query\Query_history\querylist.dta", clear
mmerge checkpoint Child_ID HH_ID Visit_Num Date using `resposelog', type(1:1) unmatched(both) update replace
//// check the query status update methodology
replace Status="New" if Status=="" & _merge==1
replace Status="New" if Status=="Resolved-need_confirm" & inlist(_merge,3,4,5)
replace Status="Fail-resolve" if trim(lower(Status))=="resolved" & inlist(_merge,3,4,5)
replace Status="Resolved-need_confirm" if trim(lower(Status))!="resolved" & _merge==2
replace Status="Resolved-confirmed" if trim(lower(Status))=="resolved" & _merge==2
replace Status="Force-cancelled" if trim(lower(Status))=="cancelled" & trim(Comment)!=""
replace Status="Cancelled" if trim(lower(Status))=="cancelled" & trim(Comment)==""
replace Status="Pending" if trim(lower(Status))=="new" & inlist(_merge,3,4,5)
replace Status="Pending" if trim(lower(Status))=="pending" & inlist(_merge,3,4,5)
replace Status="Pending" if trim(lower(Status))=="" & inlist(_merge,3,4,5)
drop _merge

//backup the Resolved and Cancelled
preserve 
	keep if Status=="Force-cancelled"
	append using "Data_query\Query_history\Query_history_Force-cancelled.dta"
	save "Data_query\Query_history\Query_history_Force-cancelled.dta", replace
	cap saveold "Data_query\Query_history\Query_history_Force-cancelled.dta", replace version(13)
	cap export excel using "Data_query\Query_history\Query_history_Force-cancelled.xlsx",replace firstrow(varlabels)
restore
preserve 
	keep if Status=="Resolved-confirmed"
	append using "Data_query\Query_history\Query_history_Resolved.dta"
	save "Data_query\Query_history\Query_history_Resolved.dta", replace
	cap saveold "Data_query\Query_history\Query_history_Resolved.dta", replace version(13)
	cap export excel using "Data_query\Query_history\Query_history_Resolved.xlsx",replace firstrow(varlabels)
restore
copy "Data_query\Query_history\Query_history_Force-cancelled.dta" "Data_query\Query_history\backup\Query_history_Force-cancelled_backup_$S_DATE.dta", replace
copy "Data_query\Query_history\Query_history_Resolved.dta" "Data_query\Query_history\backup\Query_history_Resolved_backup_$S_DATE.dta", replace

//create new query list
drop if Status=="Force-cancelled"
drop if Status=="Resolved-confirmed"
lab var Visit_Num Visit_Num
lab var Date Date
lab var FW_ID FW_ID
lab var HH_ID HH_ID
lab var Child_ID Child_ID
lab var checkpoint checkpoint
save "Data_query\Query_history\querylist.dta", replace

import excel using "code\Checkpoint_description.xlsx",clear firstrow
replace checkpoint=substr(checkpoint,11,.)
destring checkpoint, replace
drop Variables
drop if checkpoint==.
tempfile checkpointlist
save `checkpointlist'

use "Data_query\Query_history\querylist.dta", clear
mmerge checkpoint using `checkpointlist', type(n:1) unmatched(master)
drop _merge
sort HH_ID Child_ID checkpoint Visit_Num Status
export excel using "Data_query\Query_list_no_supporting_variable.xlsx",replace firstrow(varlabel)

exit
