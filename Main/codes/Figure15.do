clear
set more off
set scheme s1color
cap cd .
loc original ./raw/

set seed 1234


**** Match timing based on the ending time of each answer
import excel `original'fomc_all.xlsx, sheet("answers_bert") firstrow clear
g hawkish_bert=sent==0
g dovish_bert=sent==2
g neutral_bert=sent==1
drop sent
save est_SPY_intraday, replace

import excel `original'fomc_all.xlsx, sheet("answers_emotion") firstrow clear
g pos=inlist(emotion,"happy","ps")
g neu=emotion=="neutral"
g neg=inlist(emotion,"sad","angry")
merge 1:1 item date using est_SPY_intraday
drop _merge emotion

merge 1:1 item date using SPY_intraday
drop _merge

bys date (datetime_end): g order_QA=_n
g p_start_a1 = p_start if order_QA==1
sort date datetime_end
carryforward p_start_a1, replace

g r0 = 100*log(p_0/p_start)
g rm0 = 100*log(p_0/p_start_a1)
forv i = 1/15 {
	* return from the start of answer A to `i' min after the ending of answer A
	g r`i' = 100*log(p_`i'/p_start)
	* cumulative return from the start of the first answer to `i' min after the ending of answer A
	g rm`i' = 100*log(p_`i'/p_start_a1)	
}

foreach i in hawkish_bert dovish_bert neutral_bert pos neu neg {
	*** cumulative emotion/sentiment measures	
	bys date (order_QA): g `i'_cu = sum(`i')
}

* cumulative sentiment/tone
g emo_cu = (pos_cu-neg_cu)/(pos_cu+neg_cu)
replace emo_cu =0 if emo_cu==.

gen S_QA_cu=(dovish_bert_cu-hawkish_bert_cu)/(dovish_bert_cu+hawkish_bert_cu)
replace S_QA_cu =0 if S_QA_cu ==.

* un-cumulative sentiment/tone
g emo = -1 if neg==1
replace emo=0 if neu==1
replace emo=1 if pos==1

g S_QA = -1 if hawkish_bert==1
replace S_QA = 0 if neutral_bert==1
replace S_QA = 1 if dovish_bert==1

gen fedchair=""
replace fedchair="Bernanke" if date<=date("31-01-2014","DMY")
replace fedchair="Yellen" if date>date("31-01-2014","DMY")&date<=date("02-02-2018","DMY")
replace fedchair="Powell" if date>date("02-02-2018","DMY") 
egen fedchair_id = group(fedchair)
egen fomc_gr = group(date)

*** save results for bootstrap se (not symmetric)
tempname fig15
postfile `fig15'	hh ///
					bs_b_emo_cu   bs_ll_emo_cu bs_ul_emo_cu  ///
					bs_b_emoNC_cu   bs_ll_emoNC_cu bs_ul_emoNC_cu  ///
					bs_b_emo   bs_ll_emo bs_ul_emo  ///
					bs_b_emoNC   bs_ll_emoNC bs_ul_emoNC  ///
					using SPY_fig15, replace	


qui forv hh = 0/15 {
	noisily di "SPY : `hh'"
	*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	*	"Cumulative" specification
	*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	bootstrap, reps(2000) bca cluster(fomc_gr): reghdfe r`hh'	emo_cu S_QA_cu , a(fomc_gr order_QA) level(90)

	foreach var1 in emo_cu {
		loc se_`var1' = _se[`var1']
		loc b_`var1' = _b[`var1']
	}

	*** bias corrected estimates
	matrix A=e(ci_bca)			/* ACCELERATED confidence interval 90% */
	matrix B=e(b)-e(bias)		/* bias corrected estimate */


	loc bs_ll_emo_cu=A[1,1]
	loc bs_ul_emo_cu=A[2,1]
	loc bs_b_emo_cu=B[1,1]



	bootstrap, reps(2000) bca cluster(fomc_gr): reghdfe r`hh'	emo_cu, a(fomc_gr order_QA) level(90)
	foreach var1 in emo_cu  {
		loc se_`var1'NC = _se[`var1']
		loc b_`var1'NC = _b[`var1']
	}

	*** bias corrected estimates
	matrix A=e(ci_bca)			/* ACCELERATED confidence interval 90% */
	matrix B=e(b)-e(bias)		/* bias corrected estimate */


	loc bs_ll_emoNC_cu=A[1,1]
	loc bs_ul_emoNC_cu=A[2,1]
	loc bs_b_emoNC_cu=B[1,1]


	*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	*	"Flow" specification
	*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	bootstrap, reps(2000) bca cluster(fomc_gr): reghdfe r`hh'	emo S_QA , a(fomc_gr order_QA) level(90)

	foreach var1 in emo {
		loc se_`var1' = _se[`var1']
		loc b_`var1' = _b[`var1']
	}

	*** bias corrected estimates
	matrix A=e(ci_bca)			/* ACCELERATED confidence interval 90% */
	matrix B=e(b)-e(bias)		/* bias corrected estimate */


	loc bs_ll_emo=A[1,1]
	loc bs_ul_emo=A[2,1]
	loc bs_b_emo=B[1,1]



	bootstrap, reps(2000) bca cluster(fomc_gr): reghdfe r`hh'	emo, a(fomc_gr order_QA) level(90)
	foreach var1 in emo  {
		loc se_`var1'NC = _se[`var1']
		loc b_`var1'NC = _b[`var1']
	}

	*** bias corrected estimates
	matrix A=e(ci_bca)			/* ACCELERATED confidence interval 90% */
	matrix B=e(b)-e(bias)		/* bias corrected estimate */


	loc bs_ll_emoNC=A[1,1]
	loc bs_ul_emoNC=A[2,1]
	loc bs_b_emoNC=B[1,1]

	*** standard errors: bootstrap; symmetric
	post	`fig15'		(`hh') ///
			(`bs_b_emo_cu')		(`bs_ll_emo_cu')	(`bs_ul_emo_cu') ///
			(`bs_b_emoNC_cu')	(`bs_ll_emoNC_cu')  (`bs_ul_emoNC_cu') ///
			(`bs_b_emo')		(`bs_ll_emo')		(`bs_ul_emo') ///
			(`bs_b_emoNC')		(`bs_ll_emoNC')  	(`bs_ul_emoNC')

}
postclose `fig15'
		

*===============================================================================
*							plot results
*===============================================================================
qui {
	use SPY_fig15, clear
	loc mm=15
		
	foreach var in emo_cu emoNC_cu emo emoNC {
		replace bs_b_`var'=bs_b_`var'*100
		replace bs_ll_`var'=bs_ll_`var'*100
		replace bs_ul_`var'=bs_ul_`var'*100
	}
		
		
	twoway (line bs_b_emo hh if hh<=`mm', lpattern(solid) lcolor(blue)  lwidth(thick)) ///
			(line bs_ll_emo hh if hh<=`mm', lpattern(dash) lcolor(blue)) ///
			(line bs_ul_emo hh if hh<=`mm', lpattern(dash) lcolor(blue)) ///
			, ///
			legend(off) ///
			yti("Basis points", si(small)) yline(0) ti("SPY: Voice tone", size(medium)) name(SPY_emo_bs, replace) ///
			xtitle("Minutes", size(small)) xlab(, labs(small)) nodraw
		
	twoway (line bs_b_emoNC hh if hh<=`mm', lpattern(solid) lcolor(midblue)  lwidth(thick)) ///
			(line bs_ll_emoNC hh if hh<=`mm', lpattern(dash) lcolor(midblue)) ///
			(line bs_ul_emoNC hh if hh<=`mm', lpattern(dash) lcolor(midblue)) ///
			, ///
			legend(off) ///
			yti("Basis points", si(small)) yline(0) ti("SPY: Voice tone (no controls)", size(medium)) name(SPY_emoNC_bs, replace) ///
			xtitle("Minutes", size(small)) xlab(, labs(small)) nodraw
			
			
	twoway (line bs_b_emo_cu hh if hh<=`mm', lpattern(solid) lcolor(blue)  lwidth(thick)) ///
			(line bs_ll_emo_cu hh if hh<=`mm', lpattern(dash) lcolor(blue)) ///
			(line bs_ul_emo_cu hh if hh<=`mm', lpattern(dash) lcolor(blue)) ///
			, ///
			legend(off) ///
			yti("Basis points", si(small)) yline(0) ti("SPY: Voice tone", size(medium)) name(SPY_emo_cu_bs, replace) ///
			xtitle("Minutes", size(small)) xlab(, labs(small)) nodraw
		
	twoway (line bs_b_emoNC_cu hh if hh<=`mm', lpattern(solid) lcolor(midblue)  lwidth(thick)) ///
			(line bs_ll_emoNC_cu hh if hh<=`mm', lpattern(dash) lcolor(midblue)) ///
			(line bs_ul_emoNC_cu hh if hh<=`mm', lpattern(dash) lcolor(midblue)) ///
			, ///
			legend(off) ///
			yti("Basis points", si(small)) yline(0) ti("SPY: Voice tone (no controls)", size(medium)) name(SPY_emoNC_cu_bs, replace) ///
			xtitle("Minutes", size(small)) xlab(, labs(small)) nodraw
		
	gr combine SPY_emoNC_bs SPY_emo_bs, col(2) imargin(tiny) ti("Tone of Voice") name(SPY, replace)
	gr combine SPY_emoNC_cu_bs SPY_emo_cu_bs, col(2) imargin(tiny) ti("Cumulative Tone of Voice") name(SPY_cu, replace)
	gr combine SPY SPY_cu, rows(2)
	gr export Fig15.png, width(1800) replace
	erase SPY_fig15.dta
}

