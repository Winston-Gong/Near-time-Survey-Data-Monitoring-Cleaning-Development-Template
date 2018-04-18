 /********************************************************
* Last Modified:  03/28/16  by Wenfeng Gong
********************************************************/
capture log c
set linesize 200
set more off
log using "Program_running_log\Sampling for QA revisits.log", replace
noi di "### Sampling for QA revisits ###"

//sample 8 clusters (2 per team) for QA revisit of round 1
/////////////////////////////
set seed 186
global datapath "C:\IVAC Pakistan raw data"
global tempdata "$datapath\tempdata"
use "$tempdata\Form1&2_temp.dta",clear
keep if round==1
keep if f1_1_4s==1 & f1_1_1==maxvisit
gen team=substr(f1_0,3,1)
destring team, replace
bysort team clusterid: gen finished=_N
tempfile mainfile
	save `mainfile'
keep clusterid team finished
duplicates drop 
sample 2, by(team) count
mmerge clusterid team using `mainfile', type(1:n) unmatched(master)

sort team clusterid f1_1_3 f1_1_2 finished
order team clusterid f1_1_3 f1_1_2 finished
// team1 to QA revisit CS288(14 enroll)
// team2 to QA revisit EPI243(8 enroll) & EPI385(7 enroll)
// team3 to QA revisit CS244(5 enroll) & CS027(5 enroll) & CS313(6 enroll)
// team4 to QA revisit GIS650(7 enroll) & GIS698(7 enroll)

//sample another 8 clusters (2 per team) for QA revisit of round 1
/////////////////////////////
set seed 186
global datapath "C:\IVAC Pakistan raw data"
global tempdata "$datapath\tempdata"
use "$tempdata\Form1&2_temp.dta",clear
keep if round==1
keep if f1_1_4s==1 & f1_1_1==maxvisit
gen team=substr(f1_0,3,1)
destring team, replace
bysort team clusterid: gen finished=_N
tempfile mainfile
	save `mainfile'
keep clusterid team finished
duplicates drop 
sample 4, by(team) count
mmerge clusterid team using `mainfile', type(1:n) unmatched(master)

sort team clusterid f1_1_3 f1_1_2 finished
order team clusterid f1_1_3 f1_1_2 finished
duplicates drop team clusterid finished, force

// team1 to QA revisit GIS099(7 enroll) & CS356(8 enroll)
// team2 to QA revisit CS214(7 enroll) & GIS390(7 enroll)
// team3 to QA revisit CS146(7 enroll) & EPI146(3 enroll)
// team4 to QA revisit EPI067(8 enroll) & CS184(4 enroll)

