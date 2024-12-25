clear
set more off
cap cd .

foreach index in SPY VIX VIXY GOVT LQD IVR GLD JPY EUR SHV SHY IEI IEF TLH TLT VIXM GBP TIP LQDH LQD_LQDH GOVT_TIP media_news media_tweets {
	use `index', clear
	merge 1:1 date using FED
	drop _merge
	
	unab vars: pos neu neg hawkish* dovish* neutral* score* cosine* total_score_QA countQA

	foreach i of loc vars {
		replace `i'=0 if `i'==.
	}
		
	g month=mofd(date)
	format month %tm
	merge 1:1 date using swanson
	drop _merge
	merge m:1 month using shadowrate
	drop if _merge==2
	drop _merge month
	save est_`index', replace
}

