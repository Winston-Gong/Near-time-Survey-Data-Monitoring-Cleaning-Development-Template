 /********************************************************
* Last Modified:  04/05/18  by Wenfeng Gong
* Project Name:   Near-time data inspection tool (template)
* File Name:      Master.do 
********************************************************/
clear all

version 13
//Date of the latest log data
global date_HHvisitlog ""
global date_gissamplinglog ""
global date_workhourlog ""
global date_transportationlog ""


qui {
//install the following package if needed
//ssc install mmerge
//net install dm89_1.pkg
//ssc install distplot
//initializing
set more off
set memory 100m
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

local filelist: dir "$datapath\" files "form1data*.csv", respectcase
	local count: word count `filelist'  
	if `count'==1 {
		tokenize `filelist'
		global form1name "`1'"
	}
	else {
		noi di in red "Warning: Form 1 reading error; make sure there is only one form1 csv file in the data folder."
		exit
	}
local filelist: dir "$datapath\" files "form2data*.csv", respectcase
	local count: word count `filelist'  
	if `count'==1 {
		tokenize `filelist'
		global form2name "`1'"
	}
	else {
		noi di in red "Warning: Form 2 reading error; make sure there is only one form1 csv file in the data folder."
		exit
	}
local filelist: dir "$datapath\" files "form3data*.csv", respectcase
	local count: word count `filelist'  
	if `count'==1 {
		tokenize `filelist'
		global form3name "`1'"
	}
	else {
		noi di in red "Warning: Form 3 reading error; make sure there is only one form1 csv file in the data folder." 
		exit
	}
local filelist: dir "$datapath\" files "form4data*.csv", respectcase
	local count: word count `filelist'  
	if `count'==1 {
		tokenize `filelist'
		global form4name "`1'"
	}
	else {
		noi di in red "Warning: Form 4 reading error; make sure there is only one form1 csv file in the data folder."
		exit
	}


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
}
do "code\Data_download_backup.do"
do "code\Data_correction_Form1.do"
do "code\Data_cleaning_Form1.do"
do "code\Data_correction_Form2.do"
do "code\Data_cleaning_Form2.do"
do "code\Data_correction_Form3.do"
do "code\Data_cleaning_Form3.do"
do "code\Data_correction_Form4.do"
do "code\Data_cleaning_Form4.do"
do "code\Log_data_processing.do"
do "code\Log_data_correction_collection&lab.do"
do "code\Log_data_correction_HH_visit.do"
do "code\Log_data_correction_HH_visit.do" //repeat it once to fix the unchangable items due to change log made based on modified data
do "code\Log_data_correction_work_hour.do"
do "code\Log_data_correction_transportation.do"
do "code\Log_data_correction_transportation.do" //repeat it once to fix the unchangable items due to change log made based on modified data
do "code\Log_data_correction_GIS_sampling.do"
do "code\Log_data_correction_GIS_sampling.do" //repeat it once to fix the unchangable items due to change log made based on modified data
do "code\Blood_refusal_revisit.do"
do "code\Data_validation_Form1&2.do"
do "code\Data_validation_Form3&4.do"
do "code\Data_validation_Logs.do"
do "code\Data_query_logging.do"
do "code\Data_query_generate.do"
do "code\Data_progress_report.do"

qui {
// present data progress report
copy "Program_running_log\Data_progress_report.log" "Data_progress_report\Data_progress_report.log", replace

//reset warning tracker
global warningtracker ""
noi di "System completely run!"

cap log close
clear all
exit
