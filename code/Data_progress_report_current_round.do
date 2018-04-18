qui {
/********************************************************
* Last Modified:  03/01/16  by Wenfeng Gong
* File Name:      C:\Google Drive\IVAC - Vaccination Coverage Survey\Data\Automated_Data_Monitoring_Cleaning\code\Data_progress_report.do
********************************************************/
capture log c
set linesize 200
set more off

//working folder location
cd "C:\Dropbox (Personal)\Pakistan\Automated_Data_Monitoring_Cleaning"
//data folder location
global datapath "C:\IVAC Pakistan raw data"
//temporary data folder location
global tempdata "$datapath\tempdata"
//backup data folder location
global backupdata "$datapath\backupdata"
//clean data folder location
global cleandata "$datapath\cleandata"
//entered log data
global logdata "Entered_data\Entered_log_data"
//setup warning tracker
global warningtracker ""
//set today's date
global Today=date("$S_DATE", "DMY")

//set the current round number
global currentround=4

noi di "### Data_progress_report Round $currentround only ###"
log using "Program_running_log\Data_progress_report_current_round.log", replace

// Progress
///////////////////////////
use "$tempdata\Form1&2_temp.dta",clear
	drop if round!=$currentround
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
		
	di "# List the Others (specified) HH Visit Outcomes #"
	list f1_0 f1_1_1 f1_1_4_2 if f1_1_4status==13

save "$tempdata\Form1&2_tempreport.dta", replace

// Progress cont.
///////////////////////////
noi di "# Summary of Blood Collection Outcomes #"
	use "$cleandata\Form4_clean.dta",clear 
	gen round=substr(f4_a0c, 1,1)
	destring round, replace
	keep if round==$currentround
	count if f4_a0_2==maxbloodtry
	local PR11=r(N)
	//tab f4_b1_3 f4_b3c if f4_a0_2====maxbloodtry,m
	count if inlist(f4_b1_3,1) & !inlist(f4_b3c,1,2,3,4,5,6) & f4_a0_2==maxbloodtry
	local PR12=r(N)
	count if inlist(f4_b3c,4,5,6) & f4_a0_2==maxbloodtry
	local PR13=r(N)
	count if inlist(f4_b1_3,4,5) & f4_a0_2==maxbloodtry
	local PR14=r(N)
	count if inlist(f4_b1_3,6,7) & f4_a0_2==maxbloodtry
	local PR15=r(N)
	local PR16=round(`PR15'/`PR11',0.001)
	local ER2=`PR11'-`PR12'-`PR13'-`PR14'-`PR15'

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
	keep surveymethod clusterid enrollbycluster 
	export excel using "Data_progress_report/Cluster_enrollment_summary (round $currentround only) (including makeup visits).xls", replace firstrow(varlabels)

noi di "# check number of enrollments per method per cluster (excluding makeup visits)#"
	use "$tempdata\Form1&2_tempreport.dta",clear
	keep if inlist(f1_1_4s,1,8,9,11) & f1_1_1==1
	drop if f1_1_4s==11 & f1_1_6=="99999"
	//duplicates list f1_0
	bysort surveymethod clusterid: gen enrollbycluster=_N
	duplicates drop surveymethod clusterid enrollbycluster, force
	lab var enrollbycluster "Num of enrolls in each cluster"
	noi tab enrollbycluster surveymethod,m
	keep surveymethod clusterid enrollbycluster 
	export excel using "Data_progress_report/Cluster_enrollment_summary (round $currentround only) (excluding makeup visits).xls", replace firstrow(varlabels)
	mmerge surveymethod clusterid using "$tempdata\Form1&2_tempreport.dta", type (1:n) unmatched(both)
	sort surveymethod clusterid f1_0

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

noi di "* Error: households have missing screening data but are requested for enrollment: `ER1'"
noi di "* Error: Uncategorized antibody assessment visit outcome: `ER2'"

/////////////////////////
exit

