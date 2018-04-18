qui {
/********************************************************
* Last Modified:  08/30/16  by Wenfeng Gong
********************************************************/
capture log c
log using "Program_running_log\log_data_processing.log", replace
noi di "***Log_Data_Processing****"


//***************************************
//Signed_Consent_Count: read & backup
//***************************************
copy "$logdata\Signed_consent_count\Signed_Consent_Count_Round1_only.xls" ///
		"$logdata\backup\Signed_Consent_Count_Round1_only_$S_DATE.xls", replace
import excel using "$logdata\Signed_consent_count\Signed_Consent_Count_Round1_only.xls",clear firstrow
drop if consent1==. & consent2==.
save "$tempdata\Consentcount1.dta", replace // for round 1 only
save "$cleandata\Log_Consent_count (round1 only).dta", replace

clear
tempfile consent
local j=1
local filelist: dir "$logdata\Signed_consent_count\" files "Signed_Consent_Count_*-*-1*.xlsx", respectcase
foreach filenam of local filelist {
	di "`filenam'"
	local datestr=substr("`filenam'",length("Signed_Consent_Count_")+1,.)
	//di "`datestr'"
	//di "`=strpos("`datestr'",".xlsx")'"
	local datestr=substr("`datestr'",1, strpos("`datestr'",".xlsx")-1)
	di "`datestr'"
	local fullfilename="$logdata\Signed_consent_count\" + "`filenam'"
	
	import excel using "`fullfilename'", clear allstring
	gen Logdate=date("`datestr'", "DM20Y")
		format Logdate %td_D-N-Y
	gen verify=.
	cap replace verify=date(C,"DMY")
	cap replace verify=date(C,"DM20Y")
	if verify[1]!=Logdate[1] {
		local  warn : di "Warning: `filenam' is not correctly processed due to date error"
		noi di "`warn'"
		global warningtracker="$warningtracker" + "& `warn'"
		continue
	}
	copy "`fullfilename'" "$logdata\backup/`filenam'",replace

	count
	forvalue i=2/`r(N)' {
		if E[`i']=="" {
			replace E=E[`i'-1] in `i'
		}
		if G[`i']=="" {
			replace G=G[`i'-1] in `i'
		}
	}
	ren E team
	ren G cluster
	ren B Child_ID
	ren D consent1
	ren F consent2
	order Logdate team cluster Child_ID consent1 consent2
	drop if A==""
	drop if Child_ID==""
	keep Logdate team cluster Child_ID consent1 consent2
	if `j'>1 {
		append using `consent',force
	}
	save `consent',replace
	local ++j
}
save "Entered_data\Processed_log_data\Consent list (without Round1).dta",replace 
save "$cleandata\Log_Consent list (without Round1).dta", replace
sum Logdate
local maxLogdate=r(max)
di %td_D-N-Y `maxLogdate'
if `maxLogdate'<$Today -3 {
	local disdate : di %td_D-N-Y `maxLogdate'
	local warn : di "Warning: Consent count log outdated with last update on `disdate'"  
	noi di "`warn'"
	global warningtracker="$warningtracker" + "& `warn'"
}

//***************************************
//Fieldwork calendar: read & backup
//***************************************
copy "$logdata\Fieldwork calendar\Fieldwork_calendar.xlsx" ///
		"$logdata\backup\Fieldwork_calendar_$S_DATE.xlsx", replace
import excel using "$logdata\Fieldwork calendar\Fieldwork_calendar.xlsx", firstrow clear
forvalue i=1/5 {
	gen cluster`i'=substr(Clusters,1,strpos(Clusters,"/")-1)
		replace cluster`i'=Clusters if cluster`i'==""
		replace Clusters="" if Clusters==cluster`i'
		replace Clusters=substr(Clusters,strpos(Clusters,"/")+1,.)
	destring cluster`i', replace force
	tostring cluster`i', replace format(%03.0f)
}
format Date %td_DD-NN-YY
gen Datestr=string(Date, "%td_DD-NN-YY")
replace Method=trim(upper(Method))
replace Method="BLOOD REFUSAL REVISIT" if Method=="BLOOD REVISIT"
replace Method="CS COORDINATES CHECK" if Method=="CS COORDINATES"
replace Method="CS MAPPING" if Method=="CS MAP"
gen Fieldday=0
replace Fieldday=1 if strpos(Method,"MAPPING")>0
replace Fieldday=1 if strpos(Method,"BLOOD REFUSAL REVISIT")>0
replace Fieldday=1 if Method=="CS"
replace Fieldday=1 if Method=="GIS"
replace Fieldday=1 if Method=="EPI"
replace Fieldday=1 if Method=="LQAS"
replace Fieldday=1 if Method=="REVISIT"
cap tostring H,replace
cap gen comment=G+H+I
cap drop G H I
drop ClustersQuadrat
save "Entered_data\Processed_log_data\Fieldwork_calendar.dta",replace 
save "$cleandata\Log_Fieldwork_calendar.dta", replace
sum Date
local maxLogdate=r(max)
di %td_D-N-Y `maxLogdate'
if `maxLogdate'<$Today -3 {
	local disdate : di %td_D-N-Y `maxLogdate'
	local warn : di "Warning: Fieldwork Calendar outdated with last update on `disdate'"  
	noi di "`warn'"
	global warningtracker="$warningtracker" + "& `warn'"
}

//*********************************************
//Blood_collection_log: read & backup
//*********************************************
clear
tempfile collectionlog
local j=1
local filelist: dir "$logdata\Blood_collection_log\" files "Blood_collection_log_*-*-1*.xlsx", respectcase
foreach filenam of local filelist {
	di "`filenam'"
	local datestr=substr("`filenam'",length("Blood_collection_log_")+1,.)
	//di "`datestr'"
	//di "`=strpos("`datestr'",".xlsx")'"
	local datestr=substr("`datestr'",1, strpos("`datestr'",".xlsx")-1)
	di "`datestr'"
	local fullfilename="$logdata\Blood_collection_log\" + "`filenam'"
	
	import excel using "`fullfilename'", clear allstring firstrow
	gen Logdate=date("`datestr'", "DM20Y")
		format Logdate %td_D-N-Y
	copy "`fullfilename'" "$logdata\backup/`filenam'",replace
	
	ds ChildID*
	dropmiss `r(varlist)', obs force
	gen Logstart=.
	cap replace Logstart=date(Dateofstartusingthelog,"DMY")
	cap replace Logstart=date(Dateofstartusingthelog,"DM20Y")
		format Logstart %td_D-N-Y
	order Logstart
	drop Dateofstartusingthelog
	gen id=_n
	ren PhlebotomistNurseName Phlebotomist
	reshape long ChildID Dateofcollection Timeofcollection Estimateamountofblood ///
				Revisit Revisit3rd Timearriveatlab Signatureoflabpersonnel ///
				, i(id) j(index)
	drop if ChildID==""
	drop id index

	if `j'>1 {
		append using `collectionlog',force
	}
	save `collectionlog',replace
	local ++j
}
save "$tempdata\Blood_collection_log_temp.dta", replace
 
sum Logdate
local maxLogdate=r(max)
di %td_D-N-Y `maxLogdate'
if `maxLogdate'<$Today -7 {
	local disdate : di %td_D-N-Y `maxLogdate'
	local warn : di "Warning: Blood collection log outdated with last update on `disdate'"  
	noi di "`warn'"
	global warningtracker="$warningtracker" + "& `warn'"
}

//*********************************************
//Lab_processing_log: read & backup
//*********************************************
clear
tempfile lablog
local j=1
local filelist: dir "$logdata\Lab_processing_log\" files "Lab_processing_log_*-*-1*.xlsx", respectcase
foreach filenam of local filelist {
	di "`filenam'"
	local datestr=substr("`filenam'",length("Lab_processing_log_")+1,.)
	//di "`datestr'"
	//di "`=strpos("`datestr'",".xlsx")'"
	local datestr=substr("`datestr'",1, strpos("`datestr'",".xlsx")-1)
	di "`datestr'"
	local fullfilename="$logdata\Lab_processing_log\" + "`filenam'"
	
	import excel using "`fullfilename'", clear allstring firstrow
	gen Logdate=date("`datestr'", "DM20Y")
		format Logdate %td_D-N-Y
	copy "`fullfilename'" "$logdata\backup/`filenam'",replace
		
	ds SampleID*
	dropmiss `r(varlist)', obs force
	gen Logstart=.
	cap replace Logstart=date(Dateofstartusingthelog,"DMY")
	cap replace Logstart=date(Dateofstartusingthelog,"DM20Y")
		format Logstart %td_D-N-Y
	order Logstart
	drop Dateofstartusingthelog
	gen id=_n
	ren LabRecordKeeperName LabRecordKeeper
	ren SampleQualityIssueshaemolys Haemolysis1
	ren AB Haemolysis2
	ren AC Haemolysis3
	ren AD Haemolysis4
	ren AE Haemolysis5
	ren AF Haemolysis6
	ren SampleQualityIssuesunclotte Clotted1
	ren AH Clotted2
	ren AI Clotted3
	ren AJ Clotted4
	ren AK Clotted5
	ren AL Clotted6
	reshape long SampleID Datetoday Timeofsamplearrival Estimateamountofblood ///
				Haemolysis Clotted Otherissues Amountofserum Timeofstoragein35degress ///
				Batchno Numberofaliquots TechnicianInitial , i(id) j(index)
	drop if SampleID==""
	drop id index


	if `j'>1 {
		append using `lablog',force
	}
	save `lablog',replace
	local ++j
}
save "$tempdata\Lab_processing_log_temp.dta",replace
sum Logdate
local maxLogdate=r(max)
di %td_D-N-Y `maxLogdate'
if `maxLogdate'<$Today -14 {
	local disdate : di %td_D-N-Y `maxLogdate'
	local warn : di "Warning: Lab processing log outdated with last update on `disdate'"  
	noi di "`warn'"
	global warningtracker="$warningtracker" + "& `warn'"
}

//*********************************************
//HH_visit_log: read & backup
//*********************************************
clear
tempfile HHlog
local j=1
local filelist=""
cap local filelist: dir "$datapath\entered_raw\" files "HH_visit_log_*-*-1*.xlsx", respectcase
cap foreach filenam of local filelist {
	di "`filenam'"
	local datestr=substr("`filenam'",length("HH_visit_log_")+1,.)
	//di "`datestr'"
	//di "`=strpos("`datestr'",".xlsx")'"
	local datestr=substr("`datestr'",1, strpos("`datestr'",".xlsx")-1)
	di "`datestr'"
	local fullfilename="$datapath\entered_raw\" + "`filenam'"
	
	import excel using "`fullfilename'", clear allstring firstrow
	gen Logdate=date("`datestr'", "DM20Y")
		format Logdate %td_D-N-Y
	
	ds HousholdID*
	dropmiss `r(varlist)', obs force
	duplicates drop
	gen Date=.
	order Date
	cap replace Date=date(TodaysDate,"DMY") if strpos(TodaysDate,"-2016")>0
	cap replace Date=date(TodaysDate,"DM20Y") if strpos(TodaysDate,"-16")>0
	cap replace Date=date(TodaysDate,"MDY") if strpos(TodaysDate,"/2016")>0
		format Date %td_D-N-Y
	drop TodaysDate
	gen id=_n
	ren InterviewerName FW_name
	forvalue i=1/7 {
		ren HousholdID`i' HH_ID`i'
		ren GPScoordinates`i' Lat`i'
		ren GPScoordinates2`i' Long`i'
	}

	reshape long HH_ID Lat Long Consented ChildID Revisit2nd Revisit3rd Revisit4th Revisit5th ///
				, i(id) j(index)
	drop if HH_ID=="" & ChildID==""
	replace HH_ID=substr(HH_ID,1,3)+"-"+substr(HH_ID,4,3)+"-"+substr(HH_ID,7,3) if HH_ID!=""
	drop id index
	ds Logdate, not
	duplicates drop `r(varlist)', force
	
	if `j'>1 {
		append using `HHlog',force
	}
	save `HHlog',replace
	local ++j
}


if `j'==1 {
	use "$tempdata\HH_visit_log_temp.dta",clear
	global HHlogupdated=0
}
else {
	saveold "$tempdata\HH_visit_log_temp.dta",replace
	copy "$tempdata\HH_visit_log_temp.dta" "$backupdata\HH_visit_log_temp_backup_$S_DATE.dta", replace
	global HHlogupdated=1
}
sum Logdate
local maxLogdate=r(max)
di %td_D-N-Y `maxLogdate'
if `maxLogdate'<$Today -14 {
	local disdate : di %td_D-N-Y `maxLogdate'
	local warn : di "Warning: HH visit log outdated with last update on `disdate'"  
	noi di "`warn'"
	global warningtracker="$warningtracker" + "& `warn'"
}

//*********************************************
//Work_hour_log: read & backup
//*********************************************
clear
tempfile Workhourlog
local j=1
local filelist=""
cap local filelist: dir "$logdata\Work_hour_log\" files "Work_hour_log_*-*-1*.xlsx", respectcase
cap foreach filenam of local filelist {
	di "`filenam'"
	local datestr=substr("`filenam'",length("Work_hour_log_")+1,.)
	//di "`datestr'"
	//di "`=strpos("`datestr'",".xlsx")'"
	local datestr=substr("`datestr'",1, strpos("`datestr'",".xlsx")-1)
	di "`datestr'"
	local fullfilename="$logdata\Work_hour_log\" + "`filenam'"
	
	import excel using "`fullfilename'", clear allstring firstrow
	gen Logdate=date("`datestr'", "DM20Y")
		format Logdate %td_D-N-Y
	copy "`fullfilename'" "$logdata\backup/`filenam'",replace
		
	ds Dateofvisit*
	dropmiss `r(varlist)', obs force
	duplicates drop
	gen id=_n
	ren Timeworkersleftforfieldfrom Time_depart1
	ren K Time_depart2
	ren L Time_depart3
	ren M Time_depart4
	ren N Time_depart5
	ren O Time_depart6
	ren P Time_depart7
	ren Timewhenworkwasstartedinth Time_arrive1
	ren R Time_arrive2
	ren S Time_arrive3
	ren T Time_arrive4
	ren U Time_arrive5
	ren V Time_arrive6
	ren W Time_arrive7
	ren TimespentonallocatingtheHou Minutes_initiate1
	ren Y Minutes_initiate2
	ren Z Minutes_initiate3
	ren AA Minutes_initiate4
	ren AB Minutes_initiate5
	ren AC Minutes_initiate6
	ren AD Minutes_initiate7
	ren Timewhenfirsthouseholdwasvi Time_initiate1
	ren AF Time_initiate2
	ren AG Time_initiate3
	ren AH Time_initiate4
	ren AI Time_initiate5
	ren AJ Time_initiate6
	ren AK Time_initiate7
	ren Timewhenworkercameoutofthe Time_end1
	ren AM Time_end2
	ren AN Time_end3
	ren AO Time_end4
	ren AP Time_end5
	ren AQ Time_end6
	ren AR Time_end7
	ren Timewhenworkercamebackfrom Time_back1
	ren AT Time_back2
	ren AU Time_back3
	ren AV Time_back4
	ren AW Time_back5
	ren AX Time_back6
	ren AY Time_back7
	forvalue i=1/7 {
		ren Dateofvisit`i' Date`i'
	}

	reshape long Date Time_depart Time_arrive Minutes_initiate Time_initiate ///
		Time_end Time_back FSinitial, i(id) j(index)
	drop if Date==""
	ren TeamNo Team
	ren Date temp
	gen Date=date(temp, "DM20Y")
		format Date %td_D-N-Y
		drop temp
		order Date
	drop id index
	ds Logdate, not
	duplicates drop `r(varlist)', force
	
	if `j'>1 {
		append using `Workhourlog',force
	}
	save `Workhourlog',replace
	local ++j
}
	ds Logdate, not
	duplicates drop `r(varlist)', force

ren Time_depart temp
	gen Time_depart=clock(temp,"hms")
	format Time_depart %tc_HH:MM
	replace Time_depart=Time_depart+1000 if mod(Time_depart/1000,60)==59
	order Time_depart, after(temp)
	drop temp
ren Time_arrive temp
	gen Time_arrive=clock(temp,"hms")
	format Time_arrive %tc_HH:MM
	replace Time_arrive=Time_arrive+1000 if mod(Time_arrive/1000,60)==59
	order Time_arrive, after(temp)
	drop temp
ren Time_initiate temp
	gen Time_initiate=clock(temp,"hms")
	format Time_initiate %tc_HH:MM
	replace Time_initiate=Time_initiate+1000 if mod(Time_initiate/1000,60)==59
	order Time_initiate, after(temp)
	drop temp
ren Time_back temp
	gen Time_back=clock(temp,"hms")
	format Time_back %tc_HH:MM
	replace Time_back=Time_back+1000 if mod(Time_back/1000,60)==59
	order Time_back, after(temp)
	drop temp
ren Time_end temp
	gen Time_end=clock(temp,"hm")
	format Time_end %tc_HH:MM
	replace Time_end=Time_end+1000 if mod(Time_end/1000,60)==59
	order Time_end, after(temp)
	drop temp

sort Date Team Time_depart
by Date Team: gen Trip_of_day=_n
by Date Team: replace Trip_of_day=Trip_of_day[_n-1] if Trip_of_day>1 & Time_depart!=. & Time_depart==Time_depart[_n-1]
order Date Team Trip_of_day

save "$tempdata\Work_hour_log_temp.dta",replace
sum Logdate
local maxLogdate=r(max)
di %td_D-N-Y `maxLogdate'
if `maxLogdate'<$Today -14 {
	local disdate : di %td_D-N-Y `maxLogdate'
	local warn : di "Warning: Work Hour log outdated with last update on `disdate'"  
	noi di "`warn'"
	global warningtracker="$warningtracker" + "& `warn'"
}

//*********************************************
//Transportation_log: read & backup
//*********************************************
clear
tempfile Translog
local j=1
local filelist: dir "$logdata\Transportation_log\" files "Transportation_log_*-*-1*.xlsx", respectcase
foreach filenam of local filelist {
	di "`filenam'"
	local datestr=substr("`filenam'",length("Transportation_log_")+1,.)
	//di "`datestr'"
	//di "`=strpos("`datestr'",".xlsx")'"
	local datestr=substr("`datestr'",1, strpos("`datestr'",".xlsx")-1)
	di "`datestr'"
	local fullfilename="$logdata\Transportation_log\" + "`filenam'"
	
	import excel using "`fullfilename'", clear allstring firstrow
	gen Logdate=date("`datestr'", "DM20Y")
		format Logdate %td_D-N-Y
	copy "`fullfilename'" "$logdata\backup/`filenam'",replace
	
	ds Date*
	dropmiss `r(varlist)', obs force
	duplicates drop
	gen id=_n
	forvalue i=1/15 {
		ren Tripnumberoftheday`i' Trip_of_day`i'
		ren Vehiclenumber`i' Vehicle_ID`i' 
		ren NameofDriver`i' Driver`i'
		ren Reasonforgoingtofield`i' Trip_purpose`i'
		ren Timeofdeparture`i' Time_depart`i'
		ren Timeofarrival`i' Time_arrive`i'
		ren Meterreadingdeparture`i' Meter_depart`i'
		ren Meterreadingarrival`i' Meter_arrive`i'
		ren Comments`i' Comment_sign`i'
	}
	
	reshape long Date Trip_of_day Vehicle_ID Driver Trip_purpose ///
				Time_depart Time_arrive Meter_depart Meter_arrive Comment_sign ///
				, i(id) j(index)
	drop if Date==""
	drop id index
	ren Date Datecopy
	gen Date=.
	order Date
	cap replace Date=date(Datecopy,"DMY") if strpos(Datecopy,"-2016")>0
	cap replace Date=date(Datecopy,"DM20Y") if strpos(Datecopy,"-16")>0
	cap replace Date=date(Datecopy,"MDY") if strpos(Datecopy,"/2016")>0
		format Date %td_D-N-Y
	drop Datecopy
	ren Time_depart temp
		gen Time_depart=clock(temp,"hms")
		format Time_depart %tc_HH:MM
		replace Time_depart=Time_depart+1000 if mod(Time_depart/1000,60)==59
		order Time_depart, after(temp)
		drop temp
	ren Time_arrive temp
		gen Time_arrive=clock(temp,"hms")
		format Time_arrive %tc_HH:MM
		replace Time_arrive=Time_arrive+1000 if mod(Time_arrive/1000,60)==59
		order Time_arrive, after(temp)
		drop temp

	ds Logdate, not
	duplicates drop `r(varlist)', force

	if `j'>1 {
		append using `Translog',force
	}
	save `Translog',replace
	local ++j
}

replace Driver="Seraj" if strpos(lower(Driver),"seraj")>0
replace Driver="Seraj" if strpos(lower(Driver),"siraj")>0
replace Driver="Amjad" if strpos(lower(Driver),"amjad")>0
replace Driver="Faraz" if strpos(lower(Driver),"faraz")>0
replace Driver="Zubair" if strpos(lower(Driver),"zubair")>0
replace Driver="Muneer" if strpos(lower(Driver),"muneer")>0
replace Driver="Seraj" if strpos(lower(Driver),"saraj")>0
replace Driver="Bilal" if strpos(lower(Driver),"bilal")>0
replace Driver="Waqas" if strpos(lower(Driver),"waqas")>0
replace Driver="Tariq" if strpos(lower(Driver),"tariq")>0

save "$tempdata\Transportation_log_temp.dta",replace
sum Logdate
local maxLogdate=r(max)
di %td_D-N-Y `maxLogdate'
if `maxLogdate'<$Today -14 {
	local disdate : di %td_D-N-Y `maxLogdate'
	local warn : di "Warning: Transportation log outdated with last update on `disdate'"  
	noi di "`warn'"
	global warningtracker="$warningtracker" + "& `warn'"
}

//*********************************************
//GIS_sampling log: read & backup
//*********************************************
clear
tempfile GISlog
local j=1
local filelist=""
cap local filelist: dir "$datapath\entered_raw\" files "GIS_sampling_log_*-*-1*.xlsx", respectcase
cap foreach filenam of local filelist {
	di "`filenam'"
	local datestr=substr("`filenam'",length("GIS_sampling_log")+1,.)
	//di "`datestr'"
	//di "`=strpos("`datestr'",".xlsx")'"
	local datestr=substr("`datestr'",1, strpos("`datestr'",".xlsx")-1)
	di "`datestr'"
	local fullfilename="$datapath\entered_raw\" + "`filenam'"
	
	import excel using "`fullfilename'", clear allstring firstrow
	gen Logdate=date("`datestr'", "DM20Y")
		format Logdate %td_D-N-Y
		
	ds QuadID* Date
	dropmiss `r(varlist)', obs force
	duplicates drop
	ren Date Datecopy
	gen Date=.
	order Date
	cap replace Date=date(Datecopy,"DMY") if strpos(Datecopy,"-2016")>0
	cap replace Date=date(Datecopy,"DM20Y") if strpos(Datecopy,"-16")>0
	cap replace Date=date(Datecopy,"MDY") if strpos(Datecopy,"/2016")>0
		format Date %td_D-N-Y
	drop Datecopy
	gen id=_n
	forvalue i=1/9 {
		ren ID`i' Dwell_ID`i'
		ren Unexist`i' Condition`i'
		replace Condition`i'="Exist" if Condition`i'=="0"
		replace Condition`i'="Unexist" if Condition`i'=="1"
		ren SameasanotherID`i' Sameas`i'
		ren HouseholdIDLast3Digits`i' HH_ID_last`i'
	}
	forvalue i=11/13 {
		ren ID`i' Dwell_ID`i'
		gen Condition`i'="New"
		ren HouseholdIDLast3Digits`i' HH_ID_last`i'
	}
	ren GPScoordinate11 Lat1
	ren GPScoordinate12 Lat4
	ren GPScoordinate13 Lat7
	ren GPScoordinate15 Lat11
	ren GPScoordinate16 Lat12
	ren GPScoordinate17 Lat13
	ren GPScoordinate21 Long1
	ren GPScoordinate22 Long4
	ren GPScoordinate23 Long7
	ren GPScoordinate25 Long11
	ren GPScoordinate26 Long12
	ren GPScoordinate27 Long13
	drop BH BJ BL BN BP
	ren BetweenID1 BetweenID11
	ren BetweenID2 BetweenID12
	ren BetweenID3 BetweenID13
	ren AndID1 AndID11
	ren AndID2 AndID12
	ren AndID3 AndID13

	reshape long Dwell_ID Condition Sameas Lat Long Residential Visited HH_ID_last Comments ///
			BetweenID AndID, i(id) j(index)
	drop if Dwell_ID==""
	drop id index
	ds Logdate, not
	duplicates drop `r(varlist)', force
	ren SupervisorName FS_Name
	order Date FS_Name QuadID Dwell_ID Condition Sameas
	ren QuadID Quad_ID
	
	if `j'>1 {
		append using `GISlog',force
	}
	save `GISlog',replace
	local ++j
}
if `j'==1 {
	use "$tempdata\GIS_sampling_log_temp.dta",clear
	global GISlogupdated=0
}
else {
	saveold "$tempdata\GIS_sampling_log_temp.dta",replace
	copy "$tempdata\GIS_sampling_log_temp.dta" "$backupdata\GIS_sampling_log_temp_backup_$S_DATE.dta", replace
	global GISlogupdated=1
}
sum Logdate
local maxLogdate=r(max)
di %td_D-N-Y `maxLogdate'
if `maxLogdate'<$Today -14 {
	local disdate : di %td_D-N-Y `maxLogdate'
	local warn : di "Warning: GIS sampling log outdated with last update on `disdate'"  
	noi di "`warn'"
	global warningtracker="$warningtracker" + "& `warn'"
}


cap log close
exit
