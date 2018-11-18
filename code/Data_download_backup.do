qui {
/********************************************************
* Last Modified:  11/14/18  by Wenfeng Gong
* Project Name:   Near-time data inspection tool (template)
* File Name:      Data_download_backup.do 
********************************************************/
capture log c
log using "Program_running_log\Data_download_backup.log", replace
noi di "***Data_download_backup***"

//***** Back up Form 1 ****
copy "$rawdata/$form1name" "$backupdata\Form1_raw_backup_$S_DATE.csv", replace
insheet using "$rawdata/$form1name", clear
//for some technical reasons, duplicate data may be submitted 
duplicates drop 
save "$tempdata/form1temp.dta", replace

//***** Back up Form 2 ****
copy "$rawdata/$form2name" "$backupdata\Form2_raw_backup_$S_DATE.csv", replace
insheet using "$rawdata/$form2name", clear
//for some technical reasons, duplicate data may be submitted 
duplicates drop 
save "$tempdata/form2temp.dta", replace

//***** Back up Form 3 ****
copy "$rawdata/$form3name" "$backupdata\Form3_raw_backup_$S_DATE.csv", replace
insheet using "$rawdata/$form3name", clear nodouble
//for some technical reasons, duplicate data may be submitted 
duplicates drop 
save "$tempdata/form3temp.dta", replace

exit
