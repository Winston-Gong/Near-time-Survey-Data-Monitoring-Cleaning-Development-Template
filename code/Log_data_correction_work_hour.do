qui {

/********************************************************
* Last Modified:  02/03/16  by Wenfeng Gong
********************************************************/
capture log c
log using "Program_running_log\Log_Data_Correction_Cleaning.log", replace
noi di "***Log_Data_Correction & Cleaning _ Work Hour***"

//***************************************************************************
//Work_hour_log: correction
//***************************************************************************
// log based lab log correction
use "$tempdata\Work_hour_log_temp.dta", clear
tempfile workhourlogtemp
	save `workhourlogtemp', replace 
	
import excel using "Data_change_log\Log_Work_hour_change_log.xlsx",clear firstrow
cap drop if Team=="" & Date=="" 
replace delete_record="NO" if delete_record==""
replace delete_record="NO" if lower(delete_record)=="no"
replace delete_record="YES" if lower(delete_record)=="yes"
gen RDate=date(Date,"DM20Y")
	format RDate %td_D-N-Y
cap tostring change_made, force replace
cap tostring ID, force replace
cap tostring original, force replace
cap tostring new, force replace
replace variable=trim(variable)
replace original=trim(original)
replace new=trim(new)
replace delete=trim(delete)

forvalues i= 1/`=_N' {
	local LOGID=ID[`i']
	local RD=RDate[`i']
	local RID=Team[`i'] //reference ID
	local SRID=Trip_of_day[`i'] //secondary reference ID
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
		use `workhourlogtemp',clear
		if "`Delete'"=="YES" {
			local datalength=_N
			drop if (Date==`RD') & (Team=="`RID'") & (Trip_of_day==`SRID')
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
					count if (Date==`RD') & (Team=="`RID'") & (Trip_of_day==`SRID') & (abs(`Variable'-`Original')<0.000001 | (`Variable'==. & `Original'==.))
					replace `Variable' = `New' if (Date==`RD') & (Team=="`RID'") & (Trip_of_day==`SRID')  & (abs(`Variable'-`Original')<0.000001 | (`Variable'==. & `Original'==.))
                }
				else {
					count if (Date==`RD') & (Team=="`RID'") & (Trip_of_day==`SRID') & (`Variable'==trim("`Original'"))
					replace `Variable' = "`New'" if (Date==`RD') & (Team=="`RID'") & (Trip_of_day==`SRID') & (`Variable'==trim("`Original'"))
				}
			if r(N)==1 { 
				local checkchange="PASS" 
			}
		}
		save `workhourlogtemp',replace
	restore
	replace change_made="`checkchange'" if _n==`i'
	noi di "Work hour log Change request ID=`LOGID' `checkchange'"
}
drop RDate
cap erase "Data_change_log\Log_Work_hour_change_log.xlsx"
export excel using "Data_change_log\Log_Work_hour_change_log.xlsx",replace firstrow(varlabels)

use `workhourlogtemp',clear

//make sure Team and Date and Trip_of_Day is unique and missing values are replaced
ds Logdate Dataenteredby, not
	duplicates drop `r(varlist)', force

// special changes that cannot be handled by the system


save "$tempdata\Work_hour_log_temp.dta", replace

//***************************************************************************
//Work_hour_log: cleaning
//***************************************************************************
use "$tempdata\Work_hour_log_temp.dta", clear

tab FSinitial Team,m
replace FSinitial=upper(FSinitial)
replace FSinitial="Zaheer" if FSinitial=="ZA" & Team=="2"
replace FSinitial="Zaheer" if FSinitial=="Z" & Team=="2"
replace FSinitial="Jamal" if FSinitial=="J" & Team=="4"
replace FSinitial="Junaid" if FSinitial=="JA" & Team=="3"
replace FSinitial="Junaid" if FSinitial=="J" & Team=="3"
replace FSinitial="Nazia" if FSinitial=="NS" & Team=="1"
replace FSinitial="Yasir" if FSinitial=="Y" & Team=="1"
replace FSinitial="Yasir" if FSinitial=="YI" & Team=="1"
replace FSinitial="Shazia" if FSinitial=="S" & Team=="3"

ren Minutes_initiate temp
	gen Minutes_initiate=""
	order Minutes_initiate, after(temp)
	replace temp=lower(temp)
	replace temp="60 mins" if temp=="1 hour"
	replace Minutes_initiate=substr(temp,1,strpos(temp,"min")-1)
	replace Minutes_initiate=trim(Minutes_initiate)
	replace Minutes_initiate=substr(Minutes_initiate,1,length(Minutes_initiate)-1) if substr(Minutes_initiate,length(Minutes_initiate),1)==":"
	destring Minutes_initiate,replace
	drop temp

save "Entered_data\Processed_log_data\Log_Work_hour_log.dta",replace
save "$cleandata\Log_Work_hour_log.dta", replace

exit
