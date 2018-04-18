qui {

/********************************************************
* Last Modified:  08/31/16  by Wenfeng Gong
********************************************************/
capture log c
log using "Program_running_log\Log_Data_Correction_Cleaning_ GIS_Sampling.log", replace
noi di "***Log_Data_Correction & Cleaning _ GIS_Sampling***"

//***************************************************************************
//GIS_Sampling_log: correction
//***************************************************************************
// log based lab log correction
use "$tempdata\GIS_sampling_log_temp.dta", clear
tempfile GISlogtemp
	save `GISlogtemp', replace 

import excel using "Data_change_log\Log_GIS_sampling_change_log.xlsx",clear firstrow
cap drop if Quad_ID=="" & Date=="" & Dwell_ID==""
replace delete_record="NO" if delete_record==""
replace delete_record="NO" if lower(delete_record)=="no"
replace delete_record="YES" if lower(delete_record)=="yes"
gen RDate=date(Date,"DM20Y")
	format RDate %td_D-N-Y
replace original=trim(original)
replace new=trim(new)
replace delete=trim(delete)
cap tostring change_made, force replace
cap tostring ID, force replace

forvalues i= 1/`=_N' {
	local LOGID=ID[`i']
	local RD=RDate[`i']
	local RID=Quad_ID[`i'] //reference ID
	local SRID=Dwell_ID[`i'] // second reference ID
	local Variable=variable[`i']
	local Original=original[`i']
	local New=new[`i']
	local Delete=delete_record[`i']
	local checkchange="ERROR"
	//treat time variables
	//if substr("`Variable'",1,5)=="Time_" {
		//local New=clock("`New'","hm")
		//local Original=clock("`Original'","hm")
	//}
	if "`Variable'"=="Date" {
		local New=date("`New'","DM20Y")
		local Original=date("`Original'","DM20Y")
	}

	preserve 
		use `GISlogtemp',clear
		if "`Delete'"=="YES" {
			local datalength=_N
			drop if (Date==`RD') & (Quad_ID=="`RID'") & (Dwell_ID=="`SRID'")
			if `datalength'==_N+1 {
				local checkchange="PASS"
			}
			else if $GISlogupdated==0 {
				local checkchange="Unknown"
			}
		}
		else {
			di "Variable= `Variable'"
			di "Original= `Original'"
			di "New= `New'"
			cap confirm string variable `Variable'
                if _rc {
					replace `Variable' = `New' if (Date==`RD') & (Quad_ID=="`RID'") & (Dwell_ID=="`SRID'")  & (abs(`Variable'-`Original')<0.000001 | (`Variable'==. & `Original'==.))
 					if "`Variable'"!="Date" {
						count if (Date==`RD') & (Quad_ID=="`RID'") & (Dwell_ID=="`SRID'") & (abs(`Variable'-`New')<0.000001 | (`Variable'==. & `New'==.))
						local newexist=r(N)
						count if (Date==`RD') & (Quad_ID=="`RID'") & (Dwell_ID=="`SRID'") & (abs(`Variable'-`Original')<0.000001 | (`Variable'==. & `Original'==.))
						local oldexist=r(N)
					}
					else {
						count if (Date==`New') & (Quad_ID=="`RID'") & (Dwell_ID=="`SRID'") & (abs(`Variable'-`New')<0.000001 | (`Variable'==. & `New'==.))
						local newexist=r(N)
						count if (Date==`Original') & (Quad_ID=="`RID'") & (Dwell_ID=="`SRID'") & (abs(`Variable'-`Original')<0.000001 | (`Variable'==. & `Original'==.))
						local oldexist=r(N)
					}
                }
				else {
					replace `Variable' = "`New'" if (Date==`RD') & (Quad_ID=="`RID'") & (Dwell_ID=="`SRID'")  & (`Variable'==trim("`Original'"))
 					if "`Variable'"=="Quad_ID" {
						count if (Date==`RD') & (Quad_ID=="`New'") & (Dwell_ID=="`SRID'") & (`Variable'==trim("`New'"))
						local newexist=r(N)
						count if (Date==`RD') & (Quad_ID=="`Original'") & (Dwell_ID=="`SRID'") & (`Variable'==trim("`Original'"))
						local oldexist=r(N)
					}
					else if "`Variable'"=="Dwell_ID" {
						count if (Date==`RD') & (Quad_ID=="`RID'") & (Dwell_ID=="`New'") & (`Variable'==trim("`New'"))
						local newexist=r(N)
						count if (Date==`RD') & (Quad_ID=="`RID'") & (Dwell_ID=="`Original'") & (`Variable'==trim("`Original'"))
						local oldexist=r(N)
					}
					else {
						count if (Date==`RD') & (Quad_ID=="`RID'") & (Dwell_ID=="`SRID'") & (`Variable'==trim("`New'"))
						local newexist=r(N)
						count if (Date==`RD') & (Quad_ID=="`RID'") & (Dwell_ID=="`SRID'") & (`Variable'==trim("`Original'"))
						local oldexist=r(N)
					}
				}
			if `newexist'>=1 & `oldexist'==0 { 
				local checkchange="PASS" 
			}
		}
		save `GISlogtemp',replace
	restore
	replace change_made="`checkchange'" if _n==`i'
	noi di "GIS sampling log Change request ID=`LOGID' `checkchange'"
}
drop RDate
cap erase "Data_change_log\Log_GIS_sampling_change_log.xlsx"
export excel using "Data_change_log\Log_GIS_sampling_change_log.xlsx",replace firstrow(varlabels)

use `GISlogtemp',clear

//make sure Quad_ID and Date is unique and missing values are replaced
di "make sure Quad_ID and Dwell_ID and Date is unique and missing values are replaced"
ds Quad_ID Dwell_ID Date Logdate, not 
	ds `r(varlist)',has(type numeric)
	if "`r(varlist)'"!="" {
		foreach i of var `r(varlist)' {
			sort Quad_ID Dwell_ID Date `i'
			by Quad_ID Dwell_ID Date: replace `i'=`i'[1] if `i'==.
		}
	}
ds Quad_ID Dwell_ID Date Logdate, not 
	ds `r(varlist)',not(type numeric)
	foreach i of var `r(varlist)' {
		sort Quad_ID Dwell_ID Date `i'
		by Quad_ID Dwell_ID Date: replace `i'=`i'[_N] if `i'==""
	}
ds Logdate Dataenteredby, not
	duplicates drop `r(varlist)', force

// special changes that cannot be handled by the system
replace FS_Name="Jamal" if strpos(lower(trim(FS_Name)),"jamal")>0
replace FS_Name="Junaid" if strpos(lower(trim(FS_Name)),"junaid")>0
replace FS_Name="Shazia" if strpos(lower(trim(FS_Name)),"shazia")>0
replace FS_Name="Yasir" if strpos(lower(trim(FS_Name)),"yasie")>0
replace FS_Name="Yasir" if strpos(lower(trim(FS_Name)),"yasiq")>0
replace FS_Name="Yasir" if strpos(lower(trim(FS_Name)),"yasir")>0
replace FS_Name="Zaheer" if strpos(lower(trim(FS_Name)),"zaheer")>0
replace Quad_ID="547" if Quad_ID=="" & FS_Name=="Shazia" & Date==date("16-03-16","DM20Y")
replace Quad_ID="767" if Quad_ID=="" & FS_Name=="Shazia" & Date==date("18-02-16","DM20Y")
replace Quad_ID="008" if Quad_ID=="00" & FS_Name=="Yasir" & Date==date("16-06-16","DM20Y")
replace Date=date("16-06-16","DM20Y") if Quad_ID=="008" & FS_Name=="Yasir"
replace Date=date("26-06-16","DM20Y") if Quad_ID=="173" & FS_Name=="Yasir"
replace Date=date("07-05-16","DM20Y") if Quad_ID=="848" & FS_Name=="Jamal"
drop if FS_Name=="" & (Lat=="" | Lat=="0" | Lat=="253") & (Long=="" | Long=="0") & Dataenter==""
//Quad 324 was first visited in a wrong place on 27-10-16, then redone on 10-11-16, need to delete wrong records
drop if Quad_ID=="324" & Date==date("27-10-16","DM20Y")

saveold "$tempdata\GIS_sampling_log_temp.dta", replace

//***************************************************************************
//GIS_sampling_log: cleaning
//***************************************************************************
use "$tempdata\GIS_sampling_log_temp.dta", clear
replace Lat="24.8" + Lat if Lat!=""
replace Long="67.1" + Long if Long!=""

gen Team=""
replace FS_Name="Zaheer" if lower(FS_Name)=="zahir"
replace Team="1" if FS_Name=="Yasir"
replace Team="2" if FS_Name=="Zaheer" | FS_Name=="Asima"
replace Team="3" if FS_Name=="Shazia" | FS_Name=="Junaid"
replace Team="4" if FS_Name=="Jamal"

destring HH_ID_last, replace force
destring Quad_ID, replace force
tostring HH_ID_last, replace format("%03.0f")
tostring Quad_ID, replace format("%03.0f")
replace HH_ID_last=Quad_ID + "-" + HH_ID_last if HH_ID_last!="."
replace HH_ID_last= "133-" + HH_ID_last if (FS_Name=="Shazia" | FS_Name=="Junaid") & Date<=date("17-03-16","DM20Y") & HH_ID_last!="."
replace HH_ID_last= "232-" + HH_ID_last if FS_Name=="Zaheer" & (Date>date("17-03-16","DM20Y") & Date<=date("13-05-16","DM20Y")) & HH_ID_last!="."
replace HH_ID_last= "234-" + HH_ID_last if FS_Name=="Jamal" & (Date>date("17-03-16","DM20Y") & Date<=date("13-05-16","DM20Y")) & HH_ID_last!="."
replace HH_ID_last= "331-" + HH_ID_last if FS_Name=="Yasir" & (Date>date("13-05-16","DM20Y") & Date<=date("22-08-16","DM20Y")) & HH_ID_last!="."
replace HH_ID_last= "332-" + HH_ID_last if FS_Name=="Zaheer" & (Date>date("13-05-16","DM20Y") & Date<=date("22-08-16","DM20Y")) & HH_ID_last!="."
replace HH_ID_last= "432-" + HH_ID_last if FS_Name=="Zaheer" & (Date>date("22-08-16","DM20Y") & Date<=date("17-10-16","DM20Y")) & HH_ID_last!="."
replace HH_ID_last= "432-" + HH_ID_last if FS_Name=="Asima" & (Date>date("22-08-16","DM20Y") & Date<=date("17-10-16","DM20Y")) & HH_ID_last!="."
replace HH_ID_last= "433-" + HH_ID_last if FS_Name=="Junaid" & (Date>date("22-08-16","DM20Y") & Date<=date("17-10-16","DM20Y")) & HH_ID_last!="."
replace HH_ID_last= "933-" + HH_ID_last if FS_Name=="Junaid" & Date>date("17-10-16","DM20Y") & HH_ID_last!="."


//save "Entered_data\Processed_log_data\GIS_sampling_log.dta", replace
save "$cleandata\Log_GIS_sampling_log.dta", replace


exit
