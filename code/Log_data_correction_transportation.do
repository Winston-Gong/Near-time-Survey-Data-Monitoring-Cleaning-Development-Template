qui {

/********************************************************
* Last Modified:  08/31/16  by Wenfeng Gong
********************************************************/
capture log c
log using "Program_running_log\Log_Data_Correction_Cleaning.log", replace
noi di "***Log_Data_Correction & Cleaning _ Transportation***"

//***************************************************************************
//Transportation_log: correction
//***************************************************************************
// log based lab log correction
use "$tempdata\Transportation_log_temp.dta", clear
ds Logdate Dataenteredby, not
	duplicates drop `r(varlist)', force
tempfile Translogtemp
	save `Translogtemp', replace 

import excel using "Data_change_log\Log_Transportation_change_log.xlsx",clear firstrow allstring
cap drop if Driver=="" & Date=="" & Trip_of_day==""
replace delete_record="NO" if delete_record==""
replace delete_record="NO" if lower(delete_record)=="no"
replace delete_record="YES" if lower(delete_record)=="yes"
gen RDate=date(Date,"DM20Y")
	format RDate %td_D-N-Y
gen Temp_Time_depart=clock(Time_depart,"hm")
	order Temp_Time_depart, after(Time_depart)
	format Temp_Time_depart %tc_HH:MM
cap tostring change_made, force replace
cap tostring ID, force replace
cap tostring original, force replace
cap tostring new, force replace
replace original=trim(original)
replace new=trim(new)
replace delete=trim(delete)

forvalues i= 1/`=_N' {
	local LOGID=ID[`i']
	local RD=RDate[`i']
	local RID=Driver[`i'] //reference ID
	local SRID=Trip_of_day[`i'] // second reference ID
	local TRID=Temp_Time_depart[`i'] // third reference ID
	local Variable=variable[`i']
	local Original=original[`i']
	local New=new[`i']
	local Delete=delete_record[`i']
	local checkchange="ERROR"
	//treat time variables
	if substr("`Variable'",1,5)=="Time_" {
		local New=clock("`New'","hm")
		local Original=clock("`Original'","hm")
	}
	if "`Variable'"=="Date" {
		local New=date("`New'","DM20Y")
		local Original=date("`Original'","DM20Y")
	}

	preserve 
		use `Translogtemp',clear
		if "`Delete'"=="YES" {
			local datalength=_N
			drop if (Date==`RD') & (Driver=="`RID'") & (Trip_of_day=="`SRID'") & (Time_depart==`TRID')
			if `datalength'==_N+1 {
				local checkchange="PASS"
			}
		}
		else {
			di "Variable= `Variable'"
			di "Original= `Original'"
			di "New= `New'"
			cap confirm string variable `Variable'
                if _rc {
					count if (Date==`RD') & (Driver=="`RID'") & (Trip_of_day=="`SRID'") & (Time_depart==`TRID') & (abs(`Variable'-`Original')<0.000001 | (`Variable'==. & `Original'==.))
					replace `Variable' = `New' if (Date==`RD') & (Driver=="`RID'") & (Trip_of_day=="`SRID'") & (Time_depart==`TRID') & (abs(`Variable'-`Original')<0.000001 | (`Variable'==. & `Original'==.))
                }
				else {
					count if (Date==`RD') & (Driver=="`RID'") & (Trip_of_day=="`SRID'") & (Time_depart==`TRID') & (`Variable'==trim("`Original'"))
					replace `Variable' = "`New'" if (Date==`RD') & (Driver=="`RID'") & (Trip_of_day=="`SRID'") & (Time_depart==`TRID') & (`Variable'==trim("`Original'"))
				}
			if r(N)==1 { 
				local checkchange="PASS" 
			}
		}
		save `Translogtemp',replace
	restore
	replace change_made="`checkchange'" if _n==`i'
	noi di "Transportation log Change request ID=`LOGID' `checkchange'"
}
drop RDate
drop Temp_Time_depart
cap erase "Data_change_log\Log_Transportation_change_log.xlsx"
export excel using "Data_change_log\Log_Transportation_change_log.xlsx",replace firstrow(varlabels)

use `Translogtemp',clear

//make sure Driver and Trip_of_day and Date is unique and missing values are replaced
di "make sure Driver and Trip_of_day and Time_depart and Date is unique and missing values are replaced"
ds Driver Trip_of_day Time_depart Date Logdate, not 
	ds `r(varlist)',has(type numeric)
	if "`r(varlist)'"!="" {
		foreach i of var `r(varlist)' {
			sort Driver Trip_of_day Time_depart Date `i'
			by Driver Trip_of_day Time_depart Date: replace `i'=`i'[1] if `i'==.
		}
	}
ds Driver Trip_of_day Time_depart Date Logdate, not 
	ds `r(varlist)',not(type numeric)
	foreach i of var `r(varlist)' {
		sort Driver Trip_of_day Time_depart Date `i'
		by Driver Trip_of_day Time_depart Date: replace `i'=`i'[_N] if `i'==""
	}
ds Logdate Dataenteredby, not
	duplicates drop `r(varlist)', force

// special changes that cannot be handled by the system
replace Trip_of_day="2" if Trip_of_day=="1" & Driver=="Tariq" & Date==date("13-10-16","DM20Y") & Meter_depart=="50251"
replace Trip_of_day="3" if Trip_of_day=="1" & Driver=="Tariq" & Date==date("13-10-16","DM20Y") & Meter_depart=="50256"
replace Trip_of_day="4" if Trip_of_day=="1" & Driver=="Tariq" & Date==date("13-10-16","DM20Y") & Meter_depart=="50261"
replace Trip_of_day="5" if Trip_of_day=="1" & Driver=="Tariq" & Date==date("13-10-16","DM20Y") & Meter_depart=="50264"
//tab Driver,m

save "$tempdata\Transportation_log_temp.dta", replace

//***************************************************************************
//Transportation_log: cleaning
//***************************************************************************
use "$tempdata\Transportation_log_temp.dta", clear
drop if Driver=="" | Date==.
destring Trip_of_day,replace force
destring Trip_purpose, replace
label define trippurpose 1 "Transport_Worker" 2 "Transport_Blood"
	lab value Trip_purpose trippurpose

//save "Entered_data\Processed_log_data\Transportation_log.dta", replace
save "Entered_data\Processed_log_data\Log_Transportation_log.dta",replace
save "$cleandata\Log_Transportation_log.dta", replace

exit
