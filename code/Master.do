 /********************************************************
* Last Modified:  11/14/18  by Wenfeng Gong
* Project Name:   Near-time data inspection tool (template)
* File Name:      Master.do 
* The master.do file should run by survey data managers everyday
* to perform data inspection and create update report
********************************************************/
qui {

//***** Reset environment (User DO NOT change) ************
clear all
version 13
set more off
set memory 100m
//setup warning tracker
global warningtracker ""
//set today's date
global Today=date("$S_DATE", "DMY")

//***** Install following packages for first-time user (User DO NOT change) ****
//ssc install mmerge
//net install dm89_1.pkg
//ssc install distplot

//***** Define folder location (User should change) ****
//working folder location (should be a cloud shared folder if multiple stations are needed)
cd "E:\Dropbox (Personal)\Pakistan\Near-time Survey Data Monitoring Cleaning Development Template"
//data folder location (should not be placed on internet if data are sensitive)
global datapath "Data_folder"
//raw data folder location
global rawdata "$datapath\rawdata"
//temporary data folder location
global tempdata "$datapath\tempdata"
//backup data folder location
global backupdata "$datapath\backupdata"
//clean data folder location
global cleandata "$datapath\cleandata"
//define names of each raw data file
global form1name "Example Form 1 household visit records.csv"
global form2name "Example Form 2 household screening data.csv"
global form3name "Example Form 3 household survey results.csv"
}

//***** Run functional do files (User should change) ****
//***** User should customize the following do filed before running ****

do "code\Data_download_backup.do"
do "code\Data_correction_Form1.do"
do "code\Data_cleaning_Form1.do"
do "code\Data_correction_Form2.do"
do "code\Data_cleaning_Form2.do"
do "code\Data_correction_Form3.do"
do "code\Data_cleaning_Form3.do"
do "code\Data_validation_Form1&2.do"
do "code\Data_validation_Form3.do"
do "code\Data_query_logging.do"
do "code\Data_query_generate.do"
do "code\Data_progress_report.do"

//***** Finishing run (User DO NOT change) ****
qui {
// copy data progress report
copy "Program_running_log\Data_progress_report.log" "Data_progress_report\Data_progress_report.log", replace

//reset warning tracker
global warningtracker ""
noi di "Near-time data inspection successfully complete!"

cap log close
clear all
exit
