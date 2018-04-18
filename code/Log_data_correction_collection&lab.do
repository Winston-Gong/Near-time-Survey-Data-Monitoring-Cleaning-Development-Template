qui {

/********************************************************
* Last Modified:  02/03/16  by Wenfeng Gong
********************************************************/
capture log c
log using "Program_running_log\Log_Data_Correction_Cleaning_Collection&Lab.log", replace
noi di "***Log_Data_Correction & Cleaning_Collection&Lab***"

//***************************************************************************
//Blood_collection_log: correction
//***************************************************************************

use "$tempdata\Blood_collection_log_temp.dta", clear

//treat date variables
gen Date_collect=.
cap replace Date_collect=date(Dateofcollection,"DMY")
cap replace Date_collect=date(Dateofcollection,"DM20Y")
	format Date_collect %td_D-N-Y
order Date_collect
drop Dateofcollection

//treat time variables
gen hour=substr(Timeofcollection,1,strpos(Timeofcollection,":")-1)
destring hour,replace force
replace hour=hour+12 if hour>=0 & hour<=7
replace hour=hour-12 if hour!=. & hour!=99 & hour>=20
tostring hour,replace format(%02.0f)
replace Timeofcollection=hour+substr(Timeofcollection,strpos(Timeofcollection,":"),.)
gen Time_collect=clock(Timeofcollection,"hms")
	format Time_collect %tc_HH:MM
drop Timeofcollection hour

gen hour=substr(Timearriveatlab,1,strpos(Timearriveatlab,":")-1)
destring hour,replace force
replace hour=hour+12 if hour>=0 & hour<=7
replace hour=hour-12 if hour!=. & hour!=99 & hour>=20
tostring hour,replace format(%02.0f)
replace Timearriveatlab=hour+substr(Timearriveatlab,strpos(Timearriveatlab,":"),.)
gen Time_arrive=clock(Timearriveatlab,"hms")
	format Time_arrive %tc_HH:MM
drop Timearriveatlab hour

ds Dataenteredby Logdate, not
	duplicates drop `r(varlist)', force

ren Estimateamountofblood Blood_amount
destring Blood_amount, replace ignore("ul")

gen Makeupsample=0
replace Makeupsample=1 if Revisit=="1"
replace Makeupsample=2 if Revisit3rd=="1"
drop Revisit Revisit3rd

// log based blood collection log correction
tempfile bloodlogtemp
	save `bloodlogtemp', replace 

import excel using "Data_change_log\Log_Blood_collection_change_log.xlsx",clear firstrow
cap drop if Child_ID=="" 
replace delete_record="NO" if delete_record==""
replace delete_record="NO" if lower(delete_record)=="no"
replace delete_record="YES" if lower(delete_record)=="yes"
gen CDate=date(Collection_Date,"DM20Y")
	format CDate %td_D-N-Y
replace original=trim(original)
replace new=trim(new)
replace delete=trim(delete)
cap tostring change_made, force replace
cap tostring ID, force replace

replace variable="Date_collect" if variable=="Collection_Date"

forvalues i= 1/`=_N' {
	local LOGID=ID[`i']
	local CD=CDate[`i']
	local CID=Child_ID[`i']
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
	if "`Variable'"=="Logstart" | "`Variable'"=="Date_collect" {
		local New=date("`New'","DM20Y")
		local Original=date("`Original'","DM20Y")
	}

	preserve 
		use `bloodlogtemp',clear
		if "`Delete'"=="YES" {
			local datalength=_N
			drop if (Date_collect==`CD') & (ChildID=="`CID'")
			if `datalength'==_N+1 {
				local checkchange="PASS"
			}
		}
		else {
			cap confirm string variable `Variable'
                if _rc {
					count if (Date_collect==`CD') & (ChildID=="`CID'") & (abs(`Variable'-`Original')<0.000001 | (`Variable'==. & `Original'==.))
					replace `Variable' = `New' if (Date_collect==`CD') & (ChildID=="`CID'")  & (abs(`Variable'-`Original')<0.000001 | (`Variable'==. & `Original'==.))
                }
				else {
					count if (Date_collect==`CD') & (ChildID=="`CID'") & (`Variable'==trim("`Original'"))
					replace `Variable' = "`New'" if (Date_collect==`CD') & (ChildID=="`CID'")  & (`Variable'==trim("`Original'"))
				}
			if r(N)==1 { 
				local checkchange="PASS" 
			}
		}
		save `bloodlogtemp',replace
	restore
	replace change_made="`checkchange'" if _n==`i'
	noi di "Blood collection log Change request ID=`LOGID' `checkchange'"
}
drop CDate
cap erase "Data_change_log\Log_Blood_collection_change_log.xlsx"
export excel using "Data_change_log\Log_Blood_collection_change_log.xlsx",replace firstrow(varlabels)

use `bloodlogtemp',clear

// special changes that cannot be handled by the system
replace Logstart=date("15-02-16","DM20Y") if Logstart==date("15-03-16","DM20Y") ///
				& Phlebotomist=="Kainat"
				
bysort ChildID: egen maxmakeup=max(Makeupsample)
save "$tempdata\Blood_collection_log_temp.dta", replace

use "$tempdata\Blood_collection_log_temp.dta", clear

ds Logdate Dataenteredby, not
	duplicates drop `r(varlist)', force
save "Entered_data\Processed_log_data\Blood_collection_log.dta",replace
save "$cleandata\Log_Blood_collection_log.dta", replace


//***************************************************************************
//Lab_processing_log: correction
//***************************************************************************

use "$tempdata\Lab_processing_log_temp.dta", clear

//treat date variables
gen Date_process=.
cap replace Date_process=date(Datetoday,"DMY")
cap replace Date_process=date(Datetoday,"DM20Y")
	format Date_process %td_D-N-Y
order Date_process
drop Datetoday

//treat time variables
gen hour=substr(Timeofsamplearrival,1,strpos(Timeofsamplearrival,":")-1)
destring hour,replace force
replace hour=hour+12 if hour>=0 & hour<=7
replace hour=hour-12 if hour!=. & hour!=99 & hour>=20
tostring hour,replace format(%02.0f)
replace Timeofsamplearrival=hour+substr(Timeofsamplearrival,strpos(Timeofsamplearrival,":"),.)
gen Time_arrive=clock(Timeofsamplearrival,"hms")
	format Time_arrive %tc_HH:MM
drop Timeofsamplearrival hour

gen hour=substr(Timeofstoragein35degress,1,strpos(Timeofstoragein35degress,":")-1)
destring hour,replace force
replace hour=hour+12 if hour>=0 & hour<=7
replace hour=hour-12 if hour!=. & hour!=99 & hour>=20
tostring hour,replace format(%02.0f)
replace Timeofstoragein35degress=hour+substr(Timeofstoragein35degress,strpos(Timeofstoragein35degress,":"),.)
gen Time_freeze=clock(Timeofstoragein35degress,"hms")
	format Time_freeze %tc_HH:MM
drop Timeofstoragein35degress hour

sort Logdate SampleID
ren Estimateamountofblood Blood_amount
ren Amountofserum Serum_amount
replace Blood_amount=trim(lower(Blood_amount))
replace Blood_amount="0" if Blood_amount=="none" | Blood_amount=="nil"
destring Blood_amount, replace ignore("ul")
replace Serum_amount=trim(lower(Serum_amount))
destring Serum_amount, replace ignore("ul")

ds Dataenteredby Logdate TechnicianInitial, not
	duplicates drop `r(varlist)', force
duplicates list SampleID
mmerge Date_process SampleID using "Entered_data\Processed_log_data\Blood_collection_log.dta", ///
			type(n:n) unmatched(master) umatch(Date_collect ChildID) ukeep(Makeupsample)
replace Makeupsample=0 if Makeupsample==.
drop _merge

// log based lab log correction
tempfile lablogtemp
	save `lablogtemp', replace 

import excel using "Data_change_log\Log_Lab_processing_change_log.xlsx",clear firstrow
cap drop if Child_ID=="" 
replace delete_record="NO" if delete_record==""
replace delete_record="NO" if lower(delete_record)=="no"
replace delete_record="YES" if lower(delete_record)=="yes"
gen RDate=date(ReceiveDate,"DM20Y")
	format RDate %td_D-N-Y
replace original=trim(original)
replace new=trim(new)
replace delete=trim(delete)
cap tostring change_made, force replace
cap tostring ID, force replace

replace variable="Date_process" if variable=="ReceiveDate"

forvalues i= 1/`=_N' {
	local LOGID=ID[`i']
	local RD=RDate[`i']
	local CID=Child_ID[`i']
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
	if "`Variable'"=="Logstart" | "`Variable'"=="Date_process" {
		local New=date("`New'","DM20Y")
		local Original=date("`Original'","DM20Y")
	}

	preserve 
		use `lablogtemp',clear
		if "`Delete'"=="YES" {
			local datalength=_N
			drop if (Date_process==`RD') & (SampleID=="`CID'")
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
					count if (Date_process==`RD') & (SampleID=="`CID'") & (abs(`Variable'-`Original')<0.000001 | (`Variable'==. & `Original'==.))
					replace `Variable' = `New' if (Date_process==`RD') & (SampleID=="`CID'")  & (abs(`Variable'-`Original')<0.000001 | (`Variable'==. & `Original'==.))
                }
				else {
					count if (Date_process==`RD') & (SampleID=="`CID'") & (`Variable'==trim("`Original'"))
					replace `Variable' = "`New'" if (Date_process==`RD') & (SampleID=="`CID'")  & (`Variable'==trim("`Original'"))
				}
			if r(N)==1 { 
				local checkchange="PASS" 
			}
		}
		save `lablogtemp',replace
	restore
	replace change_made="`checkchange'" if _n==`i'
	noi di "Lab processing log Change request ID=`LOGID' `checkchange'"
}
drop RDate
cap erase "Data_change_log\Log_Lab_processing_change_log.xlsx"
export excel using "Data_change_log\Log_Lab_processing_change_log.xlsx",replace firstrow(varlabels)

use `lablogtemp',clear

//make sure SampleID is unique and missing values are replaced
di "make sure SampleID is unique and missing values are replaced"
ds SampleID Makeupsample Logdate, not 
	ds `r(varlist)',has(type numeric)
	foreach i of var `r(varlist)' {
		sort SampleID Makeupsample `i'
		by SampleID Makeupsample: replace `i'=`i'[1] if `i'==.
	}
ds SampleID Makeupsample Logdate, not 
	ds `r(varlist)',not(type numeric)
	foreach i of var `r(varlist)' {
		sort SampleID Makeupsample `i'
		by SampleID Makeupsample: replace `i'=`i'[_N] if `i'==""
	}
ds Logdate Dataenteredby, not
	duplicates drop `r(varlist)', force

// special changes that cannot be handled by the system

bysort SampleID: egen maxmakeup=max(Makeupsample)
save "$tempdata\Lab_processing_log_temp.dta", replace

ds Logdate Dataenteredby, not
	duplicates drop `r(varlist)', force
save "Entered_data\Processed_log_data\Lab_processing_log.dta", replace
save "$cleandata\Log_Lab_processing_log.dta", replace

local idtocheck "25021 34019 44020"
foreach id in `idtocheck' {
preserve
	keep if SampleID=="`id'"
	qui ds 
	foreach var in `r(varlist)' {
		qui tab `var',m
		if `r(r)'>1 {
			di "`id' : `var'"
		}
	}
restore 
}

exit
