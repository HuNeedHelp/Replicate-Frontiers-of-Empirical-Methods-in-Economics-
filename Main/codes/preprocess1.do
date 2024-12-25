clear 
set more off
cap cd .
loc original ./data/raw/
loc dta ./data/

*~~~~~~Note that the dta file containing tick data for SPY is required for the code to run. The fomc_all.xlsx file is provided in this replication package~~~~~*

use `original'FED_QA_timing, clear
keep item datetime_start datetime_end date
format datetime_start datetime_end %tc
format date %td
levelsof item, local(item)
save `dta'FED_QA_timing, replace

clear
g date=.
save `dta'SPY_start, replace
save `dta'SPY_end, replace

qui foreach i of local item {
	noi di "`i'"
	use `dta'FED_QA_timing, clear
	keep if item=="`i'"
	keep item date datetime_start
	merge 1:m date using `original'SPY_tick_DO_NOT_DISTRIBUTE
	keep if _merge==3
	* if no price was recorded at the time when the answer started, replace with the last available price
	keep if time_1s>=datetime_start-60*60*1000&time_1s<=datetime_start+15*60*1000
	
	tsset time_1s, delta(1 second)
	tsfill
	replace price=l.price if price==.&l.price!=.
	
	carryforward item date datetime_start, replace
	g p_start = price if datetime_start==time_1s
	drop if p_start==.
	keep item date p_start
	append using `dta'SPY_start
	save `dta'SPY_start, replace
	
	use `dta'FED_QA_timing, clear
	keep if item=="`i'"
	keep item date datetime_end
	merge 1:m date using `original'SPY_tick_DO_NOT_DISTRIBUTE
	keep if _merge==3
	drop _merge
	* if no price was recorded at the time when the answer ended, replace with the last available price
	keep if time_1s>=datetime_end-15*60*1000
	tsset time_1s, delta(1 second)
	tsfill
	replace price=l.price if price==.&l.price!=.
	
	carryforward item date datetime_end, replace
	
	forv i = 0/15 {
		g p_`i'=price if time_1s-datetime_end==`i'*60*1000
		replace p_`i'=0 if p_`i'==.
	}
	collapse (max) p_*, by(item date)
	append using `dta'SPY_end
	save `dta'SPY_end, replace
}

use `dta'SPY_start, clear
merge 1:1 item using `dta'FED_QA_timing
drop _merge
merge 1:1 item using `dta'SPY_end
drop _merge
save `dta'SPY_intraday, replace
erase `dta'FED_QA_timing.dta
erase `dta'SPY_start.dta
erase `dta'SPY_end.dta
