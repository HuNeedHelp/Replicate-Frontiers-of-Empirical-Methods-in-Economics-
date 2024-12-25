clear
set more off
cap cd .
loc original ./data/raw/
loc dta ./data/


** Policy shock
import excel `original'policyshocks_swanson.xlsx, sheet("Data") clear
ren C FFR
ren D FG
ren E AP
drop in 1/2
g date=date(B,"DMY")
** format of date variable in the original file is not consistent
replace date=date(B,"MDY") in 213/241
format date %td
drop if date==.
keep date FFR FG AP
destring FFR FG AP, replace
sort date
foreach i in FFR FG AP {
	g d_`i'=`i'-`i'[_n-1]
}
drop if date<td(01jan2011)|date>td(31dec2019)
save `dta'swanson, replace

** (monthly) shadow rate
import excel `original'shadowrate.xls, sheet("Sheet1") clear
ren B shadowrate
tostring A, replace
g month=ym(real(substr(A,1,4)),real(substr(A,5,6)))
format month %tm
tsset month
keep month shadowrate
g d_shadowrate=d.shadowrate
tempfile shadowrate
drop if month<ym(2011,1)|month>ym(2019,12)
save `dta'shadowrate, replace

*** Citigroup Economic Surprise Index
cap confirm file `original'CESI.xlsx
if !_rc {
	import excel using `original'CESI.xlsx, sheet("Sheet3") firstrow clear
	g date=mdy(month,day,year)
	format date %td
	tsset date
	g fake_date=_n
	tsset fake_date

	ren V111CSIINTDAILY CESI
	g dCESI=d.CESI

	drop month day year y1 rawdate fake_date

	label var CESI "Citigroup Economic Surprise Index"
	label var dCESI "change in Citigroup Economic Surprise Index"

	drop if date<mdy(1,1,2011)|date>mdy(7,31,2019)
	save `dta'cesi, replace
}
* if the original CESI data are not available, generate a file containing fake data

else {
	clear
	set obs 2
	g date=mdy(1,1,2011) in 1
	replace date=mdy(6,30,2019) in 2
	format date %td
	tsset date
	tsfill
	g CESI = 1
	g dCESI = 1
	
	label var CESI "Citigroup Economic Surprise Index"
	label var dCESI "change in Citigroup Economic Surprise Index"
	save `dta'cesi, replace
}

*** Check if yahoo_earnings.dta is available, if not, created a fake dataset
cap confirm file `dta'yahoo_earnings.dta
if _rc {
	clear
	set obs 2
	g date=mdy(1,1,2011) in 1
	replace date=mdy(6,30,2019) in 2
	format date %td
	tsset date
	tsfill
	g earnings = 1
	
	label var earnings "No. of earnings announcements"
	save `dta'yahoo_earnings, replace
}
/*
*** Different financial indices
foreach i in SPY VIX VIXY GOVT LQD IVR GLD JPY EUR SHV SHY IEI IEF TLH TLT VIXM GBP TIP {
	di "`i'"
	import delim `original'`i'.csv, varnames(1) encoding(utf8) clear
	tostring date, replace
	replace date=substr(date,1,10)
	foreach j in open close{
		cap replace `j'="" if `j'=="null"
		cap destring `j', replace
	}
	drop if open==.&close==.
	g Date=date(date,"YMD")
	format Date %td
	drop date
	ren Date date
	drop if date<mdy(1,31,2010)|date>mdy(8,30,2019)
	
	* create fake date
	sort date
	g fake_date=_n
	tsset fake_date
	
	* replace missing open price with the last close price
	replace open=l.close if open==.&close!=.
	g ret = 100*ln(close/open)
	
	ren open open_`i'
	ren close close_`i'
	ren ret ret_`i'
	
	label var ret_`i' "Daily return = 100*log(close/open)"
	
	order date
	keep date *_`i'
	save `dta'`i', replace
}
** LQDH
foreach i in  LQDH {
	di "`i'"
	import excel `original'`i', firstrow clear
	foreach j in open high low close volume {
		cap replace `j'="" if `j'=="null"
		cap destring `j', replace
	}
	drop if open==.&close==.
	format date %td
	drop if date<mdy(1,31,2010)|date>mdy(8,30,2019)
	* create fake date
	sort date
	g fake_date=_n
	tsset fake_date
	
	* replace missing open price with the last close price
	replace open=l.close if open==.&close!=.
	g ret = 100*ln(close/open)
	ren open open_`i'
	ren close close_`i'
	ren ret ret_`i'
	
	label var ret_`i' "Daily return = 100*log(close/open)"
	
	order date
	keep date *_`i'
	save `dta'`i', replace
}


*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*	spread between corporate and interest-rate-hedged corporate bonds: LQD
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
use `dta'LQD, clear
merge 1:1 date using `dta'LQDH
drop _merge

gen open_LQD_LQDH=open_LQD/open_LQDH
gen close_LQD_LQDH=close_LQD/close_LQDH
gen ret_LQD_LQDH=log(close_LQD_LQDH/open_LQD_LQDH)
keep if ret_LQD_LQDH!=.

save `dta'LQD_LQDH, replace

*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*	spread between nominal and real bonds
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
use `dta'TIP, clear
merge 1:1 date using `dta'GOVT
drop _merge

gen open_GOVT_TIP=open_GOVT/open_TIP
gen close_GOVT_TIP=close_GOVT/close_TIP
gen ret_GOVT_TIP=log(close_GOVT_TIP/open_GOVT_TIP)
keep if ret_GOVT_TIP!=.

save `dta'GOVT_TIP, replace

foreach i in SPY VIX VIXY GOVT LQD IVR GLD JPY EUR SHV SHY IEI IEF TLH TLT VIXM GBP TIP LQDH LQD_LQDH GOVT_TIP {
	use `dta'`i', clear
	drop close* open*
	save `dta'`i', replace
}

