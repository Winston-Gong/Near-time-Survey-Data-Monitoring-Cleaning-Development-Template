qui {
/********************************************************
* Last Modified:  03/29/16  by Wenfeng Gong
* File Name:      C:\Google Drive\IVAC - Vaccination Coverage Survey\Data\Automated_Data_Monitoring_Cleaning\code\Data_download_backup.do
********************************************************/
capture log c
log using "Program_running_log\Data_download_backup.log", replace
noi di "***Data_download_backup***"

copy "$datapath/$form1name" "$backupdata\Form1_raw_backup_$S_DATE.csv", replace
insheet using "$datapath/$form1name", clear
//for some technical reasons, duplicate data may be submitted 
duplicates drop 
//trim long text variables for correction process
replace f1_1_4_2=trim(f1_1_4_2)
replace refusal_reason_other=trim(refusal_reason_other)
replace f1_6=trim(f1_6)
save "$tempdata/form1temp.dta", replace

copy "$datapath/$form2name" "$backupdata\Form2_raw_backup_$S_DATE.csv", replace
insheet using "$datapath/$form2name", clear
//for some technical reasons, duplicate data may be submitted 
duplicates drop 
//trim long text variables for correction process
replace f2_11=trim(f2_11)
save "$tempdata/form2temp.dta", replace

//before read Form 3 with insheet; need to read the F3_G5 variable first, this 
// variable is read by insheet as numeric, and too long to convert back as string
clear
insheet using "$datapath/$form3name", nonames
foreach var of varlist _all {
	local name =`var'[1]
	if strpos("`name'","F3_G5")>0 {
		ren `var' f3_g5houseitems
	}
	if strpos("`name'","F3_G10")>0 {
		ren `var' f3_g10peopleitems
	}
}
keep f3_g5houseitems f3_g10peopleitems
drop in 1
gen id=_n
tempfile tempfile 
	save `tempfile', replace 

copy "$datapath/$form3name" "$backupdata\Form3_raw_backup_$S_DATE.csv", replace
copy "$tempdata/Entered_Form3.dta" "$backupdata\Entered_Form3_backup_$S_DATE.dta", replace
insheet using "$datapath/$form3name", clear nodouble
//add g5 and g10
gen id=_n
drop f3_g5houseitems f3_g10peopleitems
mmerge id using `tempfile', type(1:1)
drop id _merge

duplicates drop 
//append entered data from paper
cap drop f3_c9_1cliniccodepenta* 
cap drop v58 v62 v66 v70 v74
cap ren f3_c9_2additionalvaccinationcoun f3_c9_2_1addvxcountpenta1
cap ren f3_c9_3additionalvaccinationname f3_c9_3_1addvxnamepenta1
cap ren v63 f3_c9_2_2addvxcountpenta2
cap ren v64 f3_c9_3_2addvxnamepenta2
cap ren v67 f3_c9_2_3addvxcountpenta3
cap ren v68 f3_c9_3_3addvxnamepenta3
cap ren v71 f3_c9_2_4addvxcountpenta4
cap ren v72 f3_c9_3_4addvxnamepenta4
cap ren v75 f3_c9_2_5addvxcountpenta5
cap ren v76 f3_c9_3_5addvxnamepenta5
ds f3_c7_2* f3_c7_3* f3_c9_2* f3_c9_3*
foreach var in `r(varlist)' {
	local newname=substr("`var'",1,7) + "_" + substr("`var'",length("`var'"),1)+substr("`var'",8,.)
	ren `var' `newname'
}
ds f3_c13_2* f3_c16_2* f3_c22_3* f3_c25_3* f3_c25_2*
foreach var in `r(varlist)' {
	local newname=substr("`var'",1,8) + "_" + substr("`var'",length("`var'"),1)+substr("`var'",9,.)
	ren `var' `newname'
}
ds f3_a1_1c f3_a1_2sex* f3_b3t f3_b4 f3_b5t f3_b6_1ttmonth f3_b6_2ttyear f3_b9 f3_c6 ///
	f3_c7_2_* f3_c8 f3_c9_2_* f3_c12 f3_c15 f3_c17 f3_c19 f3_c22_1 ///
	f3_c24 f3_c25_2_* f3_c28m f3_d3 f3_e2 f3_e4 f3_f1_1zm f3_c29o f3_d1h f3_d4b f3_e5f ///
	f3_e6m f3_e9m f3_e10p f3_f6h f3_f7c f3_f11h f3_g1r f3_g6f f3_g6_2k f3_g12h f3_e1h ///
	f3_g2w f3_g1_1h f3_g3t f3_g4t f3_g7f f3_g8r f3_g9w f3_g11b f3_h1s f3_h2c
foreach var in `r(varlist)' {
	cap destring `var', force replace
}
ds f3_a0_2surveychildid cliniccodeother* f3_c13_2* f3_c16_2* f3_c22_3* f3_c25_3* ///
		measlesdiagnosedatother f3_f1_2 
foreach var in `r(varlist)' {
	cap tostring `var', replace
}
tostring f3_c2m, replace format(%08.0f)
append using "$tempdata\Entered_Form3.dta"
novarabbrev {
	cap replace f3_i1comment=f3_i1comment + f3_i1
	cap drop f3_i1
}

//trim long text variables for correction process
ds f3_a1_3age* f3_b7_2 cliniccodeother* f3_f8_2 f3_f5_2 f3_f4_2 f3_f3_1 f3_f2 f3_f1_2 f3_e7 f3_e8 ///
		f3_c30o f3_f9_2 f3_f10_2 f3_g3_1 f3_g6_1 floorother roofother wallother f3_i1
foreach var in `r(varlist)' {
	replace `var'=trim(`var')
}
save "$tempdata/form3temp.dta", replace

copy "Entered_data/Entered_Form4.dta" "$tempdata\Entered_Form4.dta", replace
copy "Entered_data/Entered_Form4.dta" "$backupdata\Entered_Form4_backup_$S_DATE.dta", replace
copy "$datapath/$form4name" "$backupdata\Form4_raw_backup_$S_DATE.csv", replace
insheet using "$datapath/$form4name", clear
duplicates drop 
//append entered data from paper
cap tostring f4_a1collectchildid,replace
cap tostring f4_b1_2, replace
cap destring f4_a3, replace force
cap destring f4_a5, replace force
append using "$tempdata\Entered_Form4.dta"
cap destring f4_b3c, replace force
//trim long text variables for correction process
replace f4_a4_1_7_1=trim(f4_a4_1_7_1)
replace f4_b1_4=trim(f4_b1_4)
replace f4_b3_2=trim(f4_b3_2)
replace f4_c=trim(f4_c)
save "$tempdata/form4temp.dta", replace

exit
