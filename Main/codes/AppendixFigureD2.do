clear
set more off
set scheme s1color
cap cd .

set seed 1234


use est_SPY, clear

g pressconf=countQA>0&countQA!=.
g emo = (pos-neg)/(pos+neg)
replace emo=0 if pressconf==0

g emo_pos = pos/(pos+neg)
replace emo_pos=0 if emo_pos==.

g emo_neg = -neg/(pos+neg)
replace emo_neg=0 if emo_neg==.

gen S_statement = (dovish_s_bert - hawkish_s_bert)/(dovish_s_bert + hawkish_s_bert)
gen S_statement_pos = dovish_s_bert/(dovish_s_bert + hawkish_s_bert)
gen S_statement_neg = -hawkish_s_bert/(dovish_s_bert + hawkish_s_bert)
gen S_QASR=(dovish_bert-hawkish_bert+dovish_s_bert-hawkish_s_bert+dovish_r_bert-hawkish_r_bert)/(dovish_bert+hawkish_bert+dovish_s_bert+hawkish_s_bert+dovish_r_bert+hawkish_r_bert)
gen S_QASR_pos = (dovish_bert+dovish_s_bert+dovish_r_bert)/(dovish_bert+hawkish_bert+dovish_s_bert+hawkish_s_bert+dovish_r_bert+hawkish_r_bert)
gen S_QASR_neg = -(hawkish_bert+hawkish_s_bert+hawkish_r_bert)/(dovish_bert+hawkish_bert+dovish_s_bert+hawkish_s_bert+dovish_r_bert+hawkish_r_bert)
		
gen S_QASR0=S_QASR
replace S_QASR0=S_statement if pressconf==0

gen S_QASR0_pos=S_QASR_pos
replace S_QASR0_pos = S_statement_pos if pressconf==0

gen S_QASR0_neg=S_QASR_neg
replace S_QASR0_neg = S_statement_neg if pressconf==0

gen S_QASR0_2 = S_QASR0^2
					
tsset date
g fake_date=_n
tsset fake_date

*** cumulative return/news
gen M0=ret_SPY
	forv hh = 1/15 {
	local hh1=`hh'-1
	gen M`hh'=M`hh1'+f`hh'.ret_SPY
}
						
*** save results for bootstrap se (not symmetric)
tempname fig_bs
postfile `fig_bs'	hh ///
					 bs_b_emo1 bs_ll_emo1 bs_ul_emo1  ///
					 bs_b_emo2 bs_ll_emo2 bs_ul_emo2  ///						
					 using temp, replace	

keep if fomc==1
	
qui forv hh = 0/15 {
	noisily di "SPY : `hh'"
	bootstrap, reps(2000) bca: reg M`hh'	emo S_QASR0 S_QASR0_2 FFR FG AP shadowrate, level(90)
	
	foreach var1 in emo {
		loc se_`var1' = _se[`var1']
		loc b_`var1' = _b[`var1']
	}
	
	*** bias corrected estimates
	matrix A=e(ci_bca)			/* ACCELERATED confidence interval 90% */
	matrix B=e(b)-e(bias)		/* bias corrected estimate */
	
		
	loc bs_ll_emo1=A[1,1]
	loc bs_ul_emo1=A[2,1]
	loc bs_b_emo1=B[1,1]
	
	
	bootstrap, reps(2000) bca: reg M`hh'	emo S_QASR0_pos FFR FG AP shadowrate, level(90)
	
	foreach var1 in emo {
		loc se_`var1' = _se[`var1']
		loc b_`var1' = _b[`var1']
	}
	
	*** bias corrected estimates
	matrix A=e(ci_bca)			/* ACCELERATED confidence interval 90% */
	matrix B=e(b)-e(bias)		/* bias corrected estimate */
	
		
	loc bs_ll_emo2=A[1,1]
	loc bs_ul_emo2=A[2,1]
	loc bs_b_emo2=B[1,1]
	

	*** standard errors: bootstrap; symmetric
	post `fig_bs'		(`hh') ///
					(`bs_b_emo1') (`bs_ll_emo1')  (`bs_ul_emo1') ///
					(`bs_b_emo2') (`bs_ll_emo2')  (`bs_ul_emo2')
						
}
postclose `fig_bs'
		


	*===============================================================================
	*							plot results
	*===============================================================================
qui foreach index in SPY {
	use temp, clear
	loc mm=15
		
	foreach var in emo1 emo2 {
		replace bs_b_`var'=bs_b_`var'*100
		replace bs_ll_`var'=bs_ll_`var'*100
		replace bs_ul_`var'=bs_ul_`var'*100
	}
		
		
	twoway (line bs_b_emo1 hh if hh<=`mm', lpattern(solid) lcolor(blue)  lwidth(thick)) ///
			(line bs_ll_emo1 hh if hh<=`mm', lpattern(dash) lcolor(blue)) ///
			(line bs_ul_emo1 hh if hh<=`mm', lpattern(dash) lcolor(blue)) ///
			, ///
			legend(off) ///
			yti("Basis points", si(small)) yline(0) ti("SPY: Control for Quadratic Text Sentiment", size(medium)) name(SPY_emo1, replace) ///
			xtitle("Days from FOMC press conference", size(small)) xlab(, labs(small)) nodraw
		
	twoway (line bs_b_emo2 hh if hh<=`mm', lpattern(solid) lcolor(midblue)  lwidth(thick)) ///
			(line bs_ll_emo2 hh if hh<=`mm', lpattern(dash) lcolor(midblue)) ///
			(line bs_ul_emo2 hh if hh<=`mm', lpattern(dash) lcolor(midblue)) ///
			, ///
			legend(off) ///
			yti("Basis points", si(small)) yline(0) ti("SPY: Control for Positive Text Sentiment", size(medium)) name(SPY_emo2, replace) ///
			xtitle("Days from FOMC press conference", size(small)) xlab(, labs(small)) nodraw
			
			
		
	graph combine SPY_emo1 SPY_emo2, rows(2) imargin(tiny)
	gr export AppendixFigD2.png, width(1800) replace
	erase temp.dta
}

