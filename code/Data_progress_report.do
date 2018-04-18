qui {
/********************************************************
* Last Modified:  03/01/16  by Wenfeng Gong
* File Name:      C:\Google Drive\IVAC - Vaccination Coverage Survey\Data\Automated_Data_Monitoring_Cleaning\code\Data_progress_report.do
********************************************************/
capture log c
set linesize 200
set more off
log using "Program_running_log\Data_progress_report.log", replace
noi di "### Data_progress_report ###"

// Progress
///////////////////////////
use "$tempdata\Form1&2_temp.dta",clear
	noi di "# List of Initial HH Visit Outcomes #"
	noi tab f1_1_4status if f1_1_1==1,m
		local PR1 = r(N)
	noi di "# List of 2nd HH Visit Outcomes #"
	noi tab f1_1_4status if f1_1_1==2,m
		local PR2 = r(N)
	noi di "# List of 3rd HH Visit Outcomes #"
	noi tab f1_1_4status if f1_1_1==3,m
		local PR2 = `PR2'+r(N)
	noi di "# List of 4th HH Visit Outcomes #"
	noi tab f1_1_4status if f1_1_1==4,m
		local PR2 = `PR2'+r(N)
	noi di "# List of 5th HH Visit Outcomes #"
	noi tab f1_1_4status if f1_1_1==5,m
		local PR2 = `PR2'+r(N)
	noi di "# List of last HH Visit Outcomes #"
	noi tab f1_1_4status if f1_1_1==maxvisit,m 
	
	//tab f1_1_4s f2_5 if f1_1_1==maxvisit,m

	noi di "# Summary of HH Visit Outcomes #"
	cap drop visitsummary
	gen visitsummary=f1_1_4status
	recode visitsummary  (0 17=0) (1=1) (8 9 =2) (10 11=3) (2 3 4 5 6 7 12 14 15 16 18=4) (13=5)
	lab define visitsummary ///
		0 "Confirmed ineligible HH" ///
		1 "Enrolled, interview done" ///
		2 "Enrolled, interview incomplete" ///
		3 "Previously visited" ///
		4 "Failed visit, screening done or not" ///
		5 "Others"
	lab value visitsummary visitsummary
	lab var visitsummary "Household Visit Summary: last HH visit"
	noi tab visitsummary if f1_1_1==maxvisit,m matcell(status)
	count if (visitsummary==0 | visitsummary==5)  & f1_1_1==maxvisit
		local PR3=r(N)
	count if (visitsummary==1 | visitsummary==2)  & f1_1_1==maxvisit
		local PR9=r(N)
	count if (visitsummary==1) & f1_1_1==maxvisit
		local PR10=r(N) // need to confirm with Form 3 data
	count if (visitsummary==3) & f1_1_1==maxvisit
		local PR6=r(N)
	count if (visitsummary==4) & f1_1_1==maxvisit
		local failedvisit=r(N)

	noi di "# Limited to screening done #"
	gen screendone=0
	replace screendone=1 if f1_1_4s==0
	replace screendone=1 if childageindays!=. & cgageinyear!=.
	count if f1_1_4status==7 & f1_1_1==maxvisit
		local PR8=r(N)
	count if f1_1_4status==4 & screendone==1 & f1_1_1==maxvisit
		local PR8=`PR8'+r(N)

	count if visitsummary==4 & screendone==0 & f1_1_1==maxvisit
		local PR4=r(N)
		local PR7=`failedvisit'-`PR4'-`PR8'
		local PR5=`PR9'+`PR8'
	noi tab f1_1_4status if screendone==1 & f1_1_1==maxvisit,m
	count if inlist(f1_1_4status,1,7) & screendone==0 & f1_1_1==maxvisit
		local ER1=r(N)
		noi di "# List the households have missing screening data but are requested for enrollment #"
		noi list f1_0 if inlist(f1_1_4status,1,7) & screendone==0 & f1_1_1==maxvisit

	noi di "# List the Others (specified) HH Visit Outcomes #"
	list f1_0 f1_1_1 f1_1_4_2status_other if f1_1_4status==13

save "$tempdata\Form1&2_tempreport.dta", replace

// Progress cont.
///////////////////////////
noi di "# Summary of Blood Collection Outcomes #"
	use "$cleandata\Form4_clean.dta",clear 
	tab f4_b1_3,m
	count if f4_a0_2==maxbloodtry
	local PR11=r(N)
	//tab f4_b1_3 f4_b3c if f4_a0_2====maxbloodtry,m
	count if inlist(f4_b1_3,1) & f4_a0_2==maxbloodtry
	local PR12=r(N)
	count if !inlist(f4_b1_3,1) & inlist(f4_b3c,4,5,6,8,9,10) & f4_a0_2==maxbloodtry
	local PR13=r(N)
	count if inlist(f4_b1_3,4,5,10,11,12) & f4_a0_2==maxbloodtry
	local PR14=r(N)
	count if inlist(f4_b1_3,4,5) & f4_a0_2==maxbloodtry
	count if inlist(f4_b1_3,6,7,9) & f4_a0_2==maxbloodtry
	local PR15=r(N)
	local PR16=round(`PR15'/`PR11',0.001)
		di "`PR16'"
	local ER2=`PR11'-`PR12'-`PR13'-`PR14'-`PR15'
		di "`ER2'"
	count if inlist(f4_b1_3,6,7) & f4_a0_2!=maxbloodtry
	local PR17=r(N)
	count if inlist(f4_b1_3,9) & f4_a0_2==maxbloodtry
	local PR19=r(N)
	sort f4_a1c f4_a0_2
	by f4_a1c: gen maxtryresult=f4_b1_3[_N]
	count if inlist(f4_b1_3,6,7,9,11) & f4_a0_2==maxbloodtry-1 & !inlist(maxtryresult,6,7,9,11)
	local PR18=r(N)
	local PR20=round(`PR18'/`PR17',0.001)

///////////////////////////
noi di "# Analysis for Make-up Visits, i.e. revisit days #"
	use "$tempdata\Form1&2_tempreport.dta",clear
	drop f1_6comment f1_6comment_old f1_1_4_2status_other_old refusal_reason_other_old f1_3children_count_2orless date_created date_changed visitsummary screendone latitude longitude gps_source
	reshape wide f1_1_2 f1_1_3 f1_1_4s f1_1_4_2status_other f1_1_5 f1_1_6 f1_4 refusal_reason_other f1_5 ///
		childageindays eligible norevisitneed visitdate f1_2r changed_by gps_accuracy, i(f1_0) j(f1_1_1)
	gen revisitsum=0
	lab define revisitsum ///
		0 "Still need revisit" ///
		1 "Initial visit only" ///
		2 "Revisited 1 time, no more" ///
		3 "Revisited 2 times, no more" ///
		4 "Revisited 3 times, no more" ///
		5 "Revisited 4 times, no more" ///
		6 "Revisited 5 times, no more" 
	lab value revisitsum revisitsum
	lab var revisitsum "Household Revisit Summary"
	cap replace revisitsum=6 if f1_1_4status5!=.
	forvalue i=1/4 {
		local rev=5-`i'
		di "`rev'" // this is the theoritical last visit
		cap replace revisitsum=`rev' if revisitsum==0 & norevisitneed`rev'==1
	}
	noi tab revisitsum,m
	keep if revisitsum==0
	keep f1_0 revisitsum childageindays1 
	tempfile HHID_revisit
		save `HHID_revisit', replace 
	use "$cleandata\Form1_clean.dta",clear
	mmerge f1_0 using `HHID_revisit', type(n:1)
	cap drop _merge
	cap drop v18
	cap drop dup
	keep if revisitsum==0 
	export excel using "Data_progress_report/HH_need_revisit.xls", replace firstrow(varlabels) datestring(%td_D-N-Y)
	copy "Data_progress_report/HH_need_revisit.xls" "Data_progress_report/backup/HH_need_revisit_$S_DATE.xls", replace

///////////////////////////
noi di "# Analysis for Make-up Antibody Assessment Visits #"
	
	
	
///////////////////////////
noi di "# check number of enrollments per method per cluster (including makeup visits)#"
	use "$tempdata\Form1&2_tempreport.dta",clear
	keep if inlist(f1_1_4s,1,8,9,11) & f1_1_1==maxvisit
	drop if f1_1_4s==11 & f1_1_6=="99999"
	//duplicates list f1_0
	bysort surveymethod clusterid: gen enrollbycluster=_N
	duplicates drop surveymethod clusterid enrollbycluster, force
	lab var enrollbycluster "Num of enrolls in each cluster"
	noi tab enrollbycluster surveymethod,m
	keep surveymethod clusterid enrollbycluster round
	export excel using "Data_progress_report/Cluster_enrollment_summary (including makeup visits).xls", replace firstrow(varlabels)
/* **** skep this part in normal run, because this part does not run in the Desktop
	preserve
		keep if surveymethod==1
		export delimited using "Data_progress_report/Graph/Cluster_enrollment_summary_EPI (including makeup visits).csv", replace 
	restore
	preserve
		keep if surveymethod==3
		export delimited using "Data_progress_report/Graph/Cluster_enrollment_summary_GIS (including makeup visits).csv", replace 
	restore
	preserve
		keep if surveymethod==2
		export delimited using "Data_progress_report/Graph/Cluster_enrollment_summary_CS (including makeup visits).csv", replace 
	restore
*/

noi di "# check number of enrollments per method per cluster (excluding makeup visits)#"
	use "$tempdata\Form1&2_tempreport.dta",clear
	keep if inlist(f1_1_4s,1,8,9,11) & f1_1_1==1
	drop if f1_1_4s==11 & f1_1_6=="99999"
	//duplicates list f1_0
	bysort surveymethod clusterid: gen enrollbycluster=_N
	duplicates drop surveymethod clusterid enrollbycluster, force
	lab var enrollbycluster "Num of enrolls in each cluster"
	noi tab enrollbycluster surveymethod,m
	keep surveymethod clusterid enrollbycluster round
	export excel using "Data_progress_report/Cluster_enrollment_summary (excluding makeup visits).xls", replace firstrow(varlabels)
	//mmerge surveymethod clusterid using "$tempdata\Form1&2_tempreport.dta", type (1:n) unmatched(both)
	//sort surveymethod clusterid f1_0
	
noi di "# check number of visited per method per cluster (excluding makeup visits)#"
	use "$tempdata\Form1&2_tempreport.dta",clear
	keep if f1_1_1==1
	//duplicates list f1_0
	bysort surveymethod clusterid: gen visitedbycluster=_N
	duplicates drop surveymethod clusterid visitedbycluster, force
	lab var visitedbycluster "Num of visits in each cluster"
	noi tab visitedbycluster surveymethod,m
	keep surveymethod clusterid visitedbycluster round
	export excel using "Data_progress_report/Cluster_visit_summary (excluding makeup visits).xls", replace firstrow(varlabels)
	//mmerge surveymethod clusterid using "$tempdata\Form1&2_tempreport.dta", type (1:n) unmatched(both)
	//sort surveymethod clusterid f1_0
	graph box visitedbycluster, over(surveymethod)
	drop if visitedbycluster<10
	tab surveymethod, su(visitedbycluster)

//////////////////////////
noi di "# data collection progress curve #"
	use "$tempdata\Form1&2_tempreport.dta",clear
	sum visitdate,d
	cap distplot visitdate,frequency
	
	//export for graphing using tableau
	keep f1_0 Child_ID f1_1_1v f1_1_3 f1_1_2 f1_1_4s round visitdate interviewdate surveymethod f2_2
	gen enrolled=1 if inlist(f1_1_4s,1,8,9)
	export excel using "Data_progress_report/Graph/Study_progress_graph.xls", replace firstrow(variables)
	
///////////////////////////
noi di "# How many HHs does GIS need to visit to have 7 enrollment #"
	use "$tempdata\Form1&2_tempreport.dta",clear
	keep if f1_1_1==1
	keep if surveymethod==3
	bysort clusterid: gen fistvisitHHincluster=_N
	duplicates drop clusterid, force
	noi sum fistvisitHHincluster
noi di "# How many HHs does GIS enroll in first visit #"
	use "$tempdata\Form1&2_tempreport.dta",clear
	keep if f1_1_1==1
	keep if surveymethod==3
	bysort clusterid: gen fistvisitHHincluster=_N
	keep if inlist(f1_1_4s,1,8,9,10,11)
	bysort clusterid: gen fistvisitenroll=_N
	duplicates drop clusterid, force
	noi tab fistvisitenroll
	tab clusterid if fistvisitenroll<7
	tab fistvisitHHincluster if fistvisitenroll<7

	
///////////////////////////
noi di "# Analysis of query items #"
	use "Data_query\Query_history\querylist.dta", clear
	count
	local currentquery=r(N)
	use "Data_query\Query_history\Query_history_Force-cancelled.dta", clear
	count
	local cancelledquery=r(N)
	use "Data_query\Query_history\Query_history_Resolved.dta", clear
	count
	local resolvedquery=r(N)
	local QR2=`cancelledquery'+`resolvedquery'
	local QR1=`currentquery'+`QR2'
	import excel using "$datapath\Query_list_with_supporting_variable.xlsx",clear firstrow
	count if Critical=="Urgent"
	local QR3=r(N)

/////////////////////////
/*
noi di "# Confirmed Eligibility at visit (i.e.age in range & primary caregiver presented #"
use "$tempdata\Form1&2_tempreport",clear
	sort f1_0 f1_1_1
	bysort f1_0: keep if f1_1_1==f1_1_1[_N]
	noi tab eligible if inlist(f1_1_4s,1,7,8,9),m
	//hist childage
*/
///////////////////////////
noi di "Organized data progress flow chart"
noi di "* Initial HH visit completed: `PR1'"
noi di "* Makeup HH visit completed (revisits): `PR2'"
noi di "* Confirmed ineligible HH: `PR3'"
noi di "* Refusal/migrated/no answer door/postponed/skipped, screening not done: `PR4'"
noi di "* Eligible HH: `PR5'"
noi di "* Confirmed previously visited HH: `PR6'"
noi di "* Caregiver absent or interview postponed after screening: `PR7'"
noi di "* Refused to participate or postoned w/o reschedule, confirmed eligible: `PR8'"
noi di "* HH/children enrolled: `PR9'"
noi di "* Survey completed: `PR10'" 
noi di "* Randomized for biomarker assessment: `PR11'" 
noi di "* Successful blood collection: `PR12'" 
noi di "* Insufficient blood collected: `PR13'" 
noi di "* Postponed, no blood collected: `PR14'" 
noi di "* Refused, no blood collected: `PR15'" 
noi di "* Refusal ratio: `PR16'" 
noi di "* Refusal revisited: `PR17'" 
noi di "* Refusal averted after revisit: `PR18' (retio: `PR20')" 
noi di "* Refusal confirmed as complete refusal (no retry): `PR19'" 

noi di "* Warning: households have missing screening data but are requested for enrollment: `ER1'"
noi di "* Warning: Uncategorized antibody assessment visit outcome: `ER2'"

noi di "* Total query generated: `QR1'" 
noi di "* Total query resolved or cancelled: `QR2'" 
noi di "* Urgent query among remaining: `QR3'" 

///////////////////////////
//warning display
tokenize "$warningtracker", parse("&")
//di "$warningtracker"
//di "`1'"
//di "`2'"
//di "`3'"
local i=1
while "``i''" !="" {
	if "``i''" !="&" {
		noi di in red "``i''"
	}
	local ++i
}

/////////////////////////
exit

