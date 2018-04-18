qui {

/********************************************************
* Last Modified:  08/30/16  by Wenfeng Gong
********************************************************/
capture log c
log using "Program_running_log\Log_Data_Correction_Cleaning.log", replace
noi di "***Log_Data_Correction & Cleaning_ HH visit***"

//***************************************************************************
//HH_visit_log: correction
//***************************************************************************
// log based lab log correction
use "$tempdata\HH_visit_log_temp.dta", clear
tempfile HHlogtemp
	save `HHlogtemp', replace 

import excel using "Data_change_log\Log_HH_visit_change_log.xlsx",clear firstrow
cap drop if HH_ID=="" & Date==""
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
	local RID=HH_ID[`i']
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
		use `HHlogtemp',clear
		if "`Delete'"=="YES" {
			local datalength=_N
			drop if (Date==`RD') & (HH_ID=="`RID'")
			if `datalength'==_N+1 {
				local checkchange="PASS"
			}
			else if $HHlogupdated==0 {
				local checkchange="Unknown"
			}
		}
		else {
			di "Variable= `Variable'"
			di "Original= `Original'"
			di "New= `New'"
			cap confirm string variable `Variable'
                if _rc {
					replace `Variable' = `New' if (Date==`RD') & (HH_ID=="`RID'")  & (abs(`Variable'-`Original')<0.000001 | (`Variable'==. & `Original'==.))
 					if "`Variable'"!="Date" {
						count if (Date==`RD') & (HH_ID=="`RID'") & (abs(`Variable'-`New')<0.000001 | (`Variable'==. & `New'==.))
						local newexist=r(N)
						count if (Date==`RD') & (HH_ID=="`RID'") & (abs(`Variable'-`Original')<0.000001 | (`Variable'==. & `Original'==.))
						local oldexist=r(N)
					}
					else {
						count if (Date==`New') & (HH_ID=="`RID'") & (abs(`Variable'-`New')<0.000001 | (`Variable'==. & `New'==.))
						local newexist=r(N)
						count if (Date==`Original') & (HH_ID=="`RID'") & (abs(`Variable'-`Original')<0.000001 | (`Variable'==. & `Original'==.))
						local oldexist=r(N)
					}
			   }
				else {
					replace `Variable' = "`New'" if (Date==`RD') & (HH_ID=="`RID'")  & (`Variable'==trim("`Original'"))
 					if "`Variable'"!="HH_ID" {
						count if (Date==`RD') & (HH_ID=="`RID'") & (`Variable'==trim("`New'"))
						local newexist=r(N)
						count if (Date==`RD') & (HH_ID=="`RID'") & (`Variable'==trim("`Original'"))
						local oldexist=r(N)
					}
					else {
						count if (Date==`RD') & (HH_ID=="`New'") & (`Variable'==trim("`New'"))
						local newexist=r(N)
						count if (Date==`RD') & (HH_ID=="`Original'") & (`Variable'==trim("`Original'"))
						local oldexist=r(N)
					}
				}
			if `newexist'>=1 & `oldexist'==0 { 
				local checkchange="PASS" 
			}
		}
		save `HHlogtemp',replace
	restore
	replace change_made="`checkchange'" if _n==`i'
	noi di "HH visit log Change request ID=`LOGID' `checkchange'"
}
drop RDate
cap erase "Data_change_log\Log_HH_visit_change_log.xlsx"
export excel using "Data_change_log\Log_HH_visit_change_log.xlsx",replace firstrow(varlabels)

use `HHlogtemp',clear

//make sure HH_ID and Date is unique and missing values are replaced
di "make sure HH_ID and Date is unique and missing values are replaced"
ds HH_ID Date Logdate, not 
	ds `r(varlist)',has(type numeric)
	if "`r(varlist)'"!="" {
		foreach i of var `r(varlist)' {
			sort HH_ID Date `i'
			by HH_ID Date: replace `i'=`i'[1] if `i'==.
		}
	}
ds HH_ID Date Logdate, not 
	ds `r(varlist)',not(type numeric)
	foreach i of var `r(varlist)' {
		sort HH_ID Date `i'
		by HH_ID Date: replace `i'=`i'[_N] if `i'==""
	}

// special changes that cannot be handled by the system
replace Numberofhousesvisitedtoday="9" if InterviewerID=="13" & Date==date("01-03-16","DM20Y")
replace Numberofhousesvisitedtoday="12" if InterviewerID=="15" & Date==date("01-03-16","DM20Y")
replace Numberofhousesvisitedtoday="11" if InterviewerID=="16" & Date==date("01-03-16","DM20Y")
replace Lat="30629" if HH_ID=="111-032-307"
replace Lat="30687" if HH_ID=="111-032-604"
replace Numberofhousesvisitedtoday="16" if InterviewerID=="15" & Date==date("08-02-16","DM20Y")
replace Long="72275" if HH_ID=="111-067-312"
replace Numberofhousesvisitedtoday="21" if InterviewerID=="15" & Date==date("26-02-16","DM20Y")
replace Numberofhousesvisitedtoday="13" if InterviewerID=="16" & Date==date("26-02-16","DM20Y")
replace Long="80325" if HH_ID=="111-076-403"
replace Numberofhousesvisitedtoday="8" if InterviewerID=="13" & Date==date("02-03-16","DM20Y")
replace Long="61623" if HH_ID=="111-121-504"
replace Numberofhousesvisitedtoday="10" if InterviewerID=="16" & Date==date("02-03-16","DM20Y")
replace Long="45425" if HH_ID=="111-144-302"
replace Lat="09918" if HH_ID=="111-144-412"
replace Consented="1" if HH_ID=="111-144-504"
replace Date=date("02-02-16","DM20Y") if InterviewerID=="15" & substr(HH_ID,1,7)=="111-146"
replace Numberofhousesvisitedtoday="8" if InterviewerID=="16" & Date==date("13-02-16","DM20Y")
replace Numberofhousesvisitedtoday="8" if InterviewerID=="13" & Date==date("03-03-16","DM20Y")
replace Numberofhousesvisitedtoday="12" if InterviewerID=="15" & Date==date("03-03-16","DM20Y")
replace Lat="30629" if HH_ID=="111-032-307"
replace FW_name=proper(FW_name)
replace FW_name="Rubina Kouser" if strpos(FW_name,"Rubina Kouser")>0 | FW_name=="Rubian Kouser" | FW_name=="Runbina Kousar"
replace FW_name="Rubina Kouser" if strpos(FW_name,"Rubina Kousar")>0 | FW_name=="Rubina Kausar" | FW_name=="Rubina Koser"
replace FW_name="Rubina Kouser" if FW_name=="Rubina" & InterviewerID=="16"
replace FW_name="Afshan Naseem" if FW_name=="Afshan"
replace FW_name="Ambreen" if FW_name=="Ambeen" | FW_name=="Ambren"
replace FW_name="Asima Sardar" if FW_name=="Asima Sadar" | FW_name=="Asima Saddar" 
replace FW_name="Asima Sardar" if (strpos(FW_name,"Asima")>0 | FW_name=="Asma") & InterviewerID=="24"
replace FW_name="Farzana Aziz" if FW_name=="Farzana" | FW_name=="Farzana Ziz" | FW_name=="Farzana33" | FW_name=="Farazana"
replace FW_name="Ishrat" if FW_name=="Isharat"
replace FW_name="Lubna Chaman" if FW_name=="Luban Chaman" | FW_name=="Lubana Chaman" | FW_name=="Lubna" ///
				| FW_name=="Lubna C Haman" | FW_name=="Lubna Chama8" | FW_name=="Lubna Chamna" | FW_name=="Lunbna Chaman"
replace FW_name="Maryam" if FW_name=="Mariyum" | FW_name=="Mariyam" | FW_name=="Marium" 
replace FW_name="Munawar Sultan" if FW_name=="Muawer Sultan" | FW_name=="Munaver" | FW_name=="Munawar" ///
				| FW_name=="Munawer" | FW_name=="Munwar" | FW_name=="Munwer Sultan" 
replace FW_name="Naseem Afshan" if FW_name=="Naseem Afsha" | FW_name=="Naseem Afsahn" 
replace FW_name="Naseem Afshan" if FW_name=="Afshan Naseem"
replace FW_name="Nazia Shah" if FW_name=="Nazia" 
replace FW_name="Noureen" if FW_name=="Noreen" 
replace InterviewerID="30" if InterviewerID=="03" & FW_name=="Noureen"
replace FW_name="Paras Shah" if FW_name=="Paras" | FW_name=="Pahras Sh" | FW_name=="Raras Shah"
replace FW_name="Raheela" if FW_name=="Raheel" | FW_name=="Rahela" | FW_name=="Rheela" | strpos(FW_name,"Raheela")>0 | strpos(FW_name,"Raheeia")>0

replace Date=date("25-02-16","DM20Y") if InterviewerID=="14" & substr(HH_ID,1,7)=="111-076"
replace Lat="23571" if HH_ID=="111-076-405"
replace Lat="82963" if HH_ID=="111-224-504"
replace Date=date("19-02-16","DM20Y") if InterviewerID=="13" & substr(HH_ID,1,7)=="111-250"
replace Date=date("19-02-16","DM20Y") if InterviewerID=="15" & substr(HH_ID,1,7)=="111-250"
replace Date=date("19-02-16","DM20Y") if InterviewerID=="16" & substr(HH_ID,1,7)=="111-250"
replace ChildID="14018" if HH_ID=="111-333-407"
replace Long="54630" if HH_ID=="122-039-404"
replace Lat="27343" if HH_ID=="122-039-414"
replace Date=date("01-02-16","DM20Y") if InterviewerID=="25" & substr(HH_ID,1,7)=="122-039"
replace Long="56055" if HH_ID=="122-039-609"
replace Long="55375" if HH_ID=="122-212-605"
replace InterviewerID="27" if FW_name=="Naseem Afshan" & substr(HH_ID,1,7)=="122-323"
replace Long="44985" if HH_ID=="122-356-507"
replace Date=date("30-01-16","DM20Y") if InterviewerID=="36" & substr(HH_ID,1,7)=="124-214"
replace Lat="32107" if HH_ID=="124-252-401"
replace Date=date("15-02-16","DM20Y") if InterviewerID=="43" & substr(HH_ID,1,7)=="124-308"
replace Date=date("15-02-16","DM20Y") if InterviewerID=="44" & substr(HH_ID,1,7)=="124-308"
replace Date=date("15-02-16","DM20Y") if InterviewerID=="45" & substr(HH_ID,1,7)=="124-308"
replace Date=date("15-02-16","DM20Y") if InterviewerID=="46" & substr(HH_ID,1,7)=="124-308"
replace Long="47954" if HH_ID=="124-313-603"
replace HH_ID="124-315-307" if HH_ID=="124-316-307"
replace Date=date("19-02-16","DM20Y") if InterviewerID=="43" & substr(HH_ID,1,7)=="124-315"
replace Date=date("19-02-16","DM20Y") if InterviewerID=="44" & substr(HH_ID,1,7)=="124-315"
replace InterviewerID="46" if FW_name=="Maryam" & substr(HH_ID,1,7)=="124-315"
replace Date=date("19-02-16","DM20Y") if InterviewerID=="46" & substr(HH_ID,1,7)=="124-315"
replace Long="46076" if HH_ID=="133-143-509"
replace FW_name="Farzana Aziz" if InterviewerID=="33" & substr(HH_ID,1,7)=="133-199"
replace Lat="17590" if HH_ID=="133-202-405"
replace Long="74566" if HH_ID=="133-202-501"
replace Lat="18798" if HH_ID=="133-233-505"
replace Long="67542" if HH_ID=="133-353-001"
replace Lat="22163" if HH_ID=="133-353-006"
replace Lat="22268" if HH_ID=="133-353-401"
replace Lat="22268" if HH_ID=="133-353-403"
replace Date=date("19-02-16","DM20Y") if InterviewerID=="30" & substr(HH_ID,1,7)=="133-387"
replace Date=date("19-02-16","DM20Y") if InterviewerID=="33" & substr(HH_ID,1,7)=="133-387"
replace Lat="23787" if HH_ID=="133-387-306"
replace Long="26329" if HH_ID=="133-387-307"
replace Date=date("19-02-16","DM20Y") if InterviewerID=="34" & substr(HH_ID,1,7)=="133-387"
replace Date=date("11-04-16","DM20Y") if InterviewerID=="44" & substr(HH_ID,1,7)=="234-081"
replace Date=date("30-06-16","DM20Y") if InterviewerID=="24" & substr(HH_ID,1,7)=="312-259" & real(substr(HH_ID,9,3))>437
replace Date=date("15-07-16","DM20Y") if InterviewerID=="24" & substr(HH_ID,1,7)=="312-291" & real(substr(HH_ID,9,3))>415
replace Date=date("22-06-16","DM20Y") if InterviewerID=="34" & substr(HH_ID,1,7)=="323-010" & real(substr(HH_ID,9,3))>421
replace Date=date("28-06-16","DM20Y") if InterviewerID=="34" & substr(HH_ID,1,7)=="323-014" & real(substr(HH_ID,9,3))>414
replace ChildID="33149" if HH_ID=="323-075-308"
replace Date=date("20-07-16","DM20Y") if InterviewerID=="30" & substr(HH_ID,1,7)=="323-083" & real(substr(HH_ID,9,3))>022
replace Consented="0" if HH_ID=="421-094-309" & ChildID=="13186"
replace ChildID="" if HH_ID=="421-094-309" & ChildID=="13186"
replace HH_ID="432-000-502" if HH_ID=="432-000-5" & ChildID=="25133"
replace HH_ID="432-000-501" if HH_ID=="432-000-5" & ChildID=="25134" & Consented=="0"
replace ChildID="" if HH_ID=="432-000-501" 
replace HH_ID="432-000-503" if HH_ID=="432-000-5" & ChildID=="25134"
replace HH_ID="331-267-701" if HH_ID=="331-267-501" & InterviewerID=="17"
replace HH_ID="331-341-309" if HH_ID=="331-341-509" & Numberofhousesvisitedtoday=="15"
replace InterviewerID="13" if HH_ID=="331-341-509" & Numberofhousesvisitedtoday=="15"
replace HH_ID="541-354-302" if HH_ID=="541-354-602" & InterviewerID=="13"
replace InterviewerID="15" if HH_ID=="331-341-309" & Numberofhousesvisitedtoday=="30"
replace HH_ID="331-341-509" if HH_ID=="331-341-309" & InterviewerID=="15"
replace Date=date("21-06-16","DM20Y") if HH_ID=="323-010-422" & Date==date("22-06-16","DM20Y")
replace Consented="1" if HH_ID=="323-010-422" & Date==date("21-06-16","DM20Y")
replace Date=date("27-06-16","DM20Y") if HH_ID=="323-014-415" & Date==date("28-06-16","DM20Y")
replace Date=date("19-07-16","DM20Y") if HH_ID=="323-083-023" & Date==date("20-07-16","DM20Y")
replace Numberofhousesvisitedtoday="24" if HH_ID=="323-083-023" & Date==date("19-07-16","DM20Y")
replace Date=date("19-07-16","DM20Y") if HH_ID=="323-083-024" & Date==date("20-07-16","DM20Y")
replace Numberofhousesvisitedtoday="24" if HH_ID=="323-083-024" & Date==date("19-07-16","DM20Y")
replace Date=date("22-07-16","DM20Y") if HH_ID=="331-349-306" & Date==date("21-07-16","DM20Y")


ds Logdate Dataenteredby, not
	duplicates drop `r(varlist)', force
saveold "$tempdata\HH_visit_log_temp.dta", replace

//***************************************************************************
//HH_visit_log: cleaning
//***************************************************************************
use "$tempdata\HH_visit_log_temp.dta", clear
replace Lat="24.8" + Lat if Lat!=""
replace Long="67.1" + Long if Long!="" 
replace Long="67.0" + substr(Long,5,.) if Long!="" & ///
		(substr(HH_ID,1,7)=="111-224" )
gen Visit_Num=1
forvalue i=2/5 {
	replace Visit_Num=`i' if Revisit`i'=="v"
}
drop Revisit*
drop Numberofhousesvisitedtoday
drop Consented
ren InterviewerID FW_ID
destring FW_ID, replace
ren ChildID Child_ID
drop if Date==.
drop if HH_ID==""

ds Logdate Dataenteredby, not
	duplicates drop `r(varlist)', force
save "$cleandata\Log_HH_visit_log.dta", replace

//export the GPS coordinates to Form 1 database
use "$cleandata\Log_HH_visit_log.dta", clear
keep HH_ID Lat Long Visit_Num
ren HH_ID f1_0house_code
ren Visit_Num f1_1_1visit_no
drop if f1_0house_code==""
duplicates drop f1_0house_code f1_1_1visit_no, force
drop if Lat=="" & Long==""
gen gpssource="Manual_log_record"
tempfile HHlogtemp2
	save `HHlogtemp2', replace 
use "$cleandata\Form1_clean.dta", clear
mmerge f1_0house_code f1_1_1visit_no using `HHlogtemp2', type(n:1) unmatched(master)
replace latitude="null" if substr(latitude,1,3)!="24."
replace longitude="null" if substr(longitude,1,3)!="67."
replace gps_source=gpssource if (latitude=="null" | longitude=="null") & gpssource=="Manual_log_record"
replace latitude=Lat if gps_source=="Manual_log_record"
replace longitude=Long if gps_source=="Manual_log_record"
drop Lat Long gpssource _merge
save "$cleandata\Form1_clean.dta", replace

exit

// find variables that are not reconciled based on HHID
local idtocheck "124-308-301"
foreach id in `idtocheck' {
preserve
	keep if HH_ID=="`id'"
	qui ds HH_ID, not
	foreach var in `r(varlist)' {
		qui tab `var' 
		if `r(r)'>1 {
			di "`id' : `var'"
		}
	}
restore 
}
