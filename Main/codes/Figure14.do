clear
set more off
set scheme s1color
set seed 1234
cap cd .

*** save results for figures
tempname fig14
postfile `fig14'	hh ///
					bs_b_emo1 bs_ll_emo1 bs_ul_emo1  /// *baseline
					bs_b_emo2 bs_ll_emo2 bs_ul_emo2  /// *add economic surprise index
					bs_b_emo3 bs_ll_emo3 bs_ul_emo3  /// *add corporate earnings
					bs_b_emo4 bs_ll_emo4 bs_ul_emo4  /// *add pre-fomc media sentiment
					bs_b_emo5 bs_ll_emo5 bs_ul_emo5  /// *add fed chair FE
					bs_b_emo6 bs_ll_emo6 bs_ul_emo6  /// *add sign (a)symmetry (positive)
					bs_b_emo7 bs_ll_emo7 bs_ul_emo7  /// *add sign (a)symmetry (negative)
					bs_b_emo8 bs_ll_emo8 bs_ul_emo8  /// *use roberta
					bs_b_emo9 bs_ll_emo9 bs_ul_emo9  /// *use finbert
					bs_b_emo10 bs_ll_emo10 bs_ul_emo10  /// *use count approach
					bs_b_emo11 bs_ll_emo11 bs_ul_emo11  /// *use human labels
					using SPY_robustness, replace
						
						
***
use est_media_news, clear

g day_from_conf=0 if fomc==1
for num 1/5: replace day_from_conf=-X if day_from_conf==. & fomc[_n+X]==1

g date_conf=date if fomc==1
format date_conf %td
keep if day_from_conf<=0
g temp=-date
sort temp

carryforward date_conf, replace
keep date date_conf news* day_from_conf
drop if day_from_conf==0
collapse (sum) news*, by(date_conf)
ren date_conf date
tempfile pre_fomc
save `pre_fomc', replace


use est_SPY, clear
merge 1:1 date using yahoo_earnings
drop if _merge==2
drop _merge

merge 1:1 date using cesi
drop if _merge==2
drop _merge
	
g pressconf=countQA>0&countQA!=.
g nopress=pressconf==0

g emo = (pos-neg)/(pos+neg)
replace emo=0 if pressconf==0
	
g emo_pos = pos/(pos+neg)
replace emo_pos=0 if emo_pos==.
	
g emo_neg = -neg/(pos+neg)
replace emo_neg=0 if emo_neg==.
		
tsset date
g fake_date=_n
tsset fake_date

g ln_earnings=log(earnings)
replace ln_earnings=0 if earnings==0
forv hh = 0/15 {
	g earning`hh'=f`hh'.ln_earnings
}
	
*** cumulative return
gen M0=ret_SPY
forv hh = 1/15 {
	local hh1=`hh'-1
	gen M`hh'=M`hh1'+f`hh'.ret_SPY
}
	
	
gen S_statement=(dovish_s_bert - hawkish_s_bert)/(dovish_s_bert + hawkish_s_bert)
gen S_QASR=(dovish_bert-hawkish_bert+dovish_s_bert-hawkish_s_bert+dovish_r_bert-hawkish_r_bert)/(dovish_bert+hawkish_bert+dovish_s_bert+hawkish_s_bert+dovish_r_bert+hawkish_r_bert)
			
gen S_QASR0=S_QASR
replace S_QASR0=S_statement if pressconf==0

keep if fomc==1
merge 1:1 date using `pre_fomc'
drop _merge
g ln_news=ln(news)
g news_senti=(news_dovish-news_hawkish)/news
	
		
qui forv hh = 0/15 {
	noisily di "`hh'"
		
	*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	*	Baseline
	*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	bootstrap, reps(2000) bca: reg M`hh'	emo S_QASR0 FFR FG AP shadowrate nopress, level(90)

	foreach var1 in emo {
		loc se_`var1'1 = _se[`var1']
		loc b_`var1'1 = _b[`var1']
	}

	*** bias corrected estimates
	matrix A=e(ci_bca)			/* ACCELERATED confidence interval 90% */
	matrix B=e(b)-e(bias)		/* bias corrected estimate */

	loc bs_ll_emo1=A[1,1]
	loc bs_ul_emo1=A[2,1]
	loc bs_b_emo1=B[1,1]
		
	*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	*	Add change in economic surprise index
	*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	bootstrap, reps(2000) bca: reg M`hh'	emo S_QASR0 FFR FG AP shadowrate nopress dCESI, level(90)
	foreach var1 in emo {
		loc se_`var1'2 = _se[`var1']
		loc b_`var1'2 = _b[`var1']
	}

	*** bias corrected estimates
	matrix A=e(ci_bca)			/* ACCELERATED confidence interval 90% */
	matrix B=e(b)-e(bias)		/* bias corrected estimate */

	loc bs_ll_emo2=A[1,1]
	loc bs_ul_emo2=A[2,1]
	loc bs_b_emo2=B[1,1]


	*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	*	Add corporate earning announcements
	*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	bootstrap, reps(2000) bca: reg M`hh'	emo S_QASR0 FFR FG AP shadowrate nopress earning`hh', level(90)
	foreach var1 in emo {
		loc se_`var1'3 = _se[`var1']
		loc b_`var1'3 = _b[`var1']
	}

	*** bias corrected estimates
	matrix A=e(ci_bca)			/* ACCELERATED confidence interval 90% */
	matrix B=e(b)-e(bias)		/* bias corrected estimate */

	loc bs_ll_emo3=A[1,1]
	loc bs_ul_emo3=A[2,1]
	loc bs_b_emo3=B[1,1]


	*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	*	Add pre-fomc news sentiment and log(news)
	*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	bootstrap, reps(2000) bca: reg M`hh'	emo S_QASR0 FFR FG AP shadowrate nopress news_senti ln_news, level(90)
	foreach var1 in emo {
		loc se_`var1'4 = _se[`var1']
		loc b_`var1'4 = _b[`var1']
	}

	*** bias corrected estimates
	matrix A=e(ci_bca)			/* ACCELERATED confidence interval 90% */
	matrix B=e(b)-e(bias)		/* bias corrected estimate */

	loc bs_ll_emo4=A[1,1]
	loc bs_ul_emo4=A[2,1]
	loc bs_b_emo4=B[1,1]

	*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	*	Add Fed Chair FEs
	*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	bootstrap, reps(2000) bca: reghdfe M`hh'	emo S_QASR0 FFR FG AP shadowrate nopress, a(fedchair_id) level(90)

	foreach var1 in emo {
		loc se_`var1'5 = _se[`var1']
		loc b_`var1'5 = _b[`var1']
	}

	*** bias corrected estimates
	matrix A=e(ci_bca)			/* ACCELERATED confidence interval 90% */
	matrix B=e(b)-e(bias)		/* bias corrected estimate */

	loc bs_ll_emo5=A[1,1]
	loc bs_ul_emo5=A[2,1]
	loc bs_b_emo5=B[1,1]

	*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	*	Sign (a)symmetry
	*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	bootstrap, reps(2000) bca: reg M`hh'	emo_pos emo_neg S_QASR0 FFR FG AP shadowrate, level(90)

	loc se_emo6 = _se[emo_pos]
	loc b_emo6 = _b[emo_pos]
	loc se_emo7 = _se[emo_neg]
	loc b_emo7 = _b[emo_neg]

	*** bias corrected estimates
	* matrix A=e(ci_bc)			/* confidence interval 90% */
	matrix A=e(ci_bca)			/* ACCELERATED confidence interval 90% */
	matrix B=e(b)-e(bias)		/* bias corrected estimate */

	loc bs_ll_emo6=A[1,1]
	loc bs_ul_emo6=A[2,1]
	loc bs_b_emo6=B[1,1]

	loc bs_ll_emo7=A[1,2]
	loc bs_ul_emo7=A[2,2]
	loc bs_b_emo7=B[1,2]

	*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	*	Text sentiment based on RoBERTa
	*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	cap drop S_*
	gen S_statement=(dovish_s_roberta - hawkish_s_roberta)/(dovish_s_roberta + hawkish_s_roberta)
	gen S_QASR=(dovish_roberta-hawkish_roberta+dovish_s_roberta-hawkish_s_roberta+dovish_r_roberta-hawkish_r_roberta)/(dovish_roberta+hawkish_roberta+dovish_s_roberta+hawkish_s_roberta+dovish_r_roberta+hawkish_r_roberta)	
	gen S_QASR0=S_QASR
	replace S_QASR0=0 if S_QASR0==.

	bootstrap, reps(2000) bca: reg M`hh'	emo S_QASR0 FFR FG AP shadowrate nopress, level(90)

	foreach var1 in emo {
		loc se_`var1'8 = _se[`var1']
		loc b_`var1'8 = _b[`var1']
	}

	*** bias corrected estimates
	matrix A=e(ci_bca)			/* ACCELERATED confidence interval 90% */
	matrix B=e(b)-e(bias)		/* bias corrected estimate */

	loc bs_ll_emo8=A[1,1]
	loc bs_ul_emo8=A[2,1]
	loc bs_b_emo8=B[1,1]

	*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	*	Text sentiment based on FinBERT
	*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	cap drop S_*
	gen S_statement=(dovish_s_finbert - hawkish_s_finbert)/(dovish_s_finbert + hawkish_s_finbert)
	gen S_QASR=(dovish_finbert-hawkish_finbert+dovish_s_finbert-hawkish_s_finbert+dovish_r_finbert-hawkish_r_finbert)/(dovish_finbert+hawkish_finbert+dovish_s_finbert+hawkish_s_finbert+dovish_r_finbert+hawkish_r_finbert)

	gen S_QASR0=S_QASR
	replace S_QASR0=S_statement if S_QASR0==.

	bootstrap, reps(2000) bca: reg M`hh'	emo S_QASR0 FFR FG AP shadowrate nopress, level(90)

	foreach var1 in emo S_QASR0 FFR AP FG {
		loc se_`var1'9 = _se[`var1']
		loc b_`var1'9 = _b[`var1']
	}

	*** bias corrected estimates
	matrix A=e(ci_bca)			/* ACCELERATED confidence interval 90% */
	matrix B=e(b)-e(bias)		/* bias corrected estimate */

	loc bs_ll_emo9=A[1,1]
	loc bs_ul_emo9=A[2,1]
	loc bs_b_emo9=B[1,1]

	*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	*	Text sentiment based on search and count
	*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	cap drop S_*
	gen S_statement=(dovish_s_count - hawkish_s_count)/(dovish_s_count + hawkish_s_count)
	gen S_QASR=(dovish_count-hawkish_count+dovish_s_count-hawkish_s_count+dovish_r_count-hawkish_r_count)/(dovish_count+hawkish_count+dovish_s_count+hawkish_s_count+dovish_r_count+hawkish_r_count)
	gen S_QASR0=S_QASR
	
	bootstrap, reps(2000) bca: reg M`hh'	emo S_QASR0 FFR FG AP shadowrate nopress, level(90)

	foreach var1 in emo {
		loc se_`var1'10 = _se[`var1']
		loc b_`var1'10 = _b[`var1']
	}

	*** bias corrected estimates
	matrix A=e(ci_bca)			/* ACCELERATED confidence interval 90% */
	matrix B=e(b)-e(bias)		/* bias corrected estimate */


	loc bs_ll_emo10=A[1,1]
	loc bs_ul_emo10=A[2,1]
	loc bs_b_emo10=B[1,1]


	*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	*	Text sentiment based on human classification
	*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	cap drop S_*
	gen S_QASR=(total_score_QA+score_R+score_S)/(countQA+2)
	gen S_QASR0=S_QASR
	replace S_QASR0=0 if S_QASR0==.
	
	bootstrap, reps(2000) bca: reg M`hh'	emo S_QASR0 FFR FG AP shadowrate nopress, level(90)

	foreach var1 in emo {
		loc se_`var1'11 = _se[`var1']
		loc b_`var1'11 = _b[`var1']
	}

	*** bias corrected estimates
	matrix A=e(ci_bca)			/* ACCELERATED confidence interval 90% */
	matrix B=e(b)-e(bias)		/* bias corrected estimate */

	loc bs_ll_emo11=A[1,1]
	loc bs_ul_emo11=A[2,1]
	loc bs_b_emo11=B[1,1]

	
	*** standard errors: bootstrap; symmetric
	post	`fig14' (`hh') ///
			(`bs_b_emo1') (`bs_ll_emo1')  (`bs_ul_emo1') ///
			(`bs_b_emo2') (`bs_ll_emo2')  (`bs_ul_emo2') ///
			(`bs_b_emo3') (`bs_ll_emo3')  (`bs_ul_emo3') ///
			(`bs_b_emo4') (`bs_ll_emo4')  (`bs_ul_emo4') ///
			(`bs_b_emo5') (`bs_ll_emo5')  (`bs_ul_emo5') ///
			(`bs_b_emo6') (`bs_ll_emo6')  (`bs_ul_emo6') ///
			(`bs_b_emo7') (`bs_ll_emo7')  (`bs_ul_emo7') ///
			(`bs_b_emo8') (`bs_ll_emo8')  (`bs_ul_emo8') ///
			(`bs_b_emo9') (`bs_ll_emo9')  (`bs_ul_emo9') ///
			(`bs_b_emo10') (`bs_ll_emo10')  (`bs_ul_emo10') ///
			(`bs_b_emo11') (`bs_ll_emo11')  (`bs_ul_emo11')

}
postclose `fig14'


*===============================================================================
*							plot results
*===============================================================================
qui {
	use SPY_robustness, clear
	loc mm=15

	forv var = 1/11 {
		replace bs_b_emo`var'=bs_b_emo`var'*100
		replace bs_ll_emo`var'=bs_ll_emo`var'*100
		replace bs_ul_emo`var'=bs_ul_emo`var'*100
	}


	twoway (line bs_b_emo1 hh if hh<=`mm', lpattern(solid) lcolor(blue)  lwidth(thick)) ///
		(line bs_ll_emo1 hh if hh<=`mm', lpattern(dash) lcolor(blue)) ///
		(line bs_ul_emo1 hh if hh<=`mm', lpattern(dash) lcolor(blue)) ///
		, ///
		legend(off) ///
		yti("Basis points", si(small)) yline(0) ti("Panel A: Baseline", size(small)) name(SPY_emo1, replace) ///
		xtitle("Days from FOMC press conference", size(small)) xlab(, labs(small)) ylab(, labs(small)) nodraw

	twoway (line bs_b_emo2 hh if hh<=`mm', lpattern(solid) lcolor(blue)  lwidth(thick)) ///
		(line bs_ll_emo2 hh if hh<=`mm', lpattern(dash) lcolor(blue)) ///
		(line bs_ul_emo2 hh if hh<=`mm', lpattern(dash) lcolor(blue)) ///
		, ///
		legend(off) ///
		yti("Basis points", si(small)) yline(0) ti("Panel A: Add economic surprise index", size(small)) name(SPY_emo2, replace) ///
		xtitle("Days from FOMC press conference", size(small)) xlab(, labs(small)) ylab(, labs(small)) nodraw

	twoway (line bs_b_emo3 hh if hh<=`mm', lpattern(solid) lcolor(blue)  lwidth(thick)) ///
		(line bs_ll_emo3 hh if hh<=`mm', lpattern(dash) lcolor(blue)) ///
		(line bs_ul_emo3 hh if hh<=`mm', lpattern(dash) lcolor(blue)) ///
		, ///
		legend(off) ///
		yti("Basis points", si(small)) yline(0) ti("Panel B: Add corporate earnings announcements", size(small)) name(SPY_emo3, replace) ///
		xtitle("Days from FOMC press conference", size(small)) xlab(, labs(small)) ylab(, labs(small)) nodraw

	twoway (line bs_b_emo4 hh if hh<=`mm', lpattern(solid) lcolor(blue)  lwidth(thick)) ///
		(line bs_ll_emo4 hh if hh<=`mm', lpattern(dash) lcolor(blue)) ///
		(line bs_ul_emo4 hh if hh<=`mm', lpattern(dash) lcolor(blue)) ///
		, ///
		legend(off) ///
		yti("Basis points", si(small)) yline(0) ti("Panel C: Add pre-FOMC media sentiment", size(small)) name(SPY_emo4, replace) ///
		xtitle("Days from FOMC press conference", size(small)) xlab(, labs(small)) ylab(, labs(small)) nodraw

	twoway (line bs_b_emo5 hh if hh<=`mm', lpattern(solid) lcolor(blue)  lwidth(thick)) ///
		(line bs_ll_emo5 hh if hh<=`mm', lpattern(dash) lcolor(blue)) ///
		(line bs_ul_emo5 hh if hh<=`mm', lpattern(dash) lcolor(blue)) ///
		, ///
		legend(off) ///
		yti("Basis points", si(small)) yline(0) ti("Panel D: Add Fed Chair FEs", size(small)) name(SPY_emo5, replace) ///
		xtitle("Days from FOMC press conference", size(small)) xlab(, labs(small)) ylab(, labs(small)) nodraw

	twoway (line bs_b_emo6 hh if hh<=`mm', lpattern(solid) lcolor(black)  lwidth(thick)) ///
		(line bs_ll_emo6 hh if hh<=`mm', lpattern(dash) lcolor(black)) ///
		(line bs_ul_emo6 hh if hh<=`mm', lpattern(dash) lcolor(black)) ///
		(line bs_b_emo7 hh if hh<=`mm', lpattern(solid) lcolor(red)  lwidth(thick)) ///
		(line bs_ll_emo7 hh if hh<=`mm', lpattern(dash) lcolor(red)) ///
		(line bs_ul_emo7 hh if hh<=`mm', lpattern(dash) lcolor(red)) ///
		, ///
		legend(order(1 4) label(4 "Negative") label(1 "Positive") rows(2) size(small) rowgap(0.2) ring(0) position(11)) ///
		yti("Basis points", si(small)) yline(0) ti("Panel E: Sign (a)symmetry", size(small)) name(SPY_emo6, replace) ///
		xtitle("Days from FOMC press conference", size(small)) xlab(, labs(small)) ylab(, labs(small)) nodraw

	twoway (line bs_b_emo8 hh if hh<=`mm', lpattern(solid) lcolor(blue)  lwidth(thick)) ///
		(line bs_ll_emo8 hh if hh<=`mm', lpattern(dash) lcolor(blue)) ///
		(line bs_ul_emo8 hh if hh<=`mm', lpattern(dash) lcolor(blue)) ///
		, ///
		legend(off) ///
		yti("Basis points", si(small)) yline(0) ti("Panel F: RoBERTa text sentiment", size(small)) name(SPY_emo7, replace) ///
		xtitle("Days from FOMC press conference", size(small)) xlab(, labs(small)) ylab(, labs(small)) nodraw

	twoway (line bs_b_emo9 hh if hh<=`mm', lpattern(solid) lcolor(blue)  lwidth(thick)) ///
		(line bs_ll_emo9 hh if hh<=`mm', lpattern(dash) lcolor(blue)) ///
		(line bs_ul_emo9 hh if hh<=`mm', lpattern(dash) lcolor(blue)) ///
		, ///
		legend(off) ///
		yti("Basis points", si(small)) yline(0) ti("Panel G: FinBERT text sentiment", size(small)) name(SPY_emo8, replace) ///
		xtitle("Days from FOMC press conference", size(small)) xlab(, labs(small)) ylab(, labs(small)) nodraw

	twoway (line bs_b_emo10 hh if hh<=`mm', lpattern(solid) lcolor(blue)  lwidth(thick)) ///
		(line bs_ll_emo10 hh if hh<=`mm', lpattern(dash) lcolor(blue)) ///
		(line bs_ul_emo10 hh if hh<=`mm', lpattern(dash) lcolor(blue)) ///
		, ///
		legend(off) ///
		yti("Basis points", si(small)) yline(0) ti("Panel H: Search-and-count text sentiment", size(small)) name(SPY_emo9, replace) ///
		xtitle("Days from FOMC press conference", size(small)) xlab(, labs(small)) ylab(, labs(small)) nodraw

	twoway (line bs_b_emo11 hh if hh<=`mm', lpattern(solid) lcolor(blue)  lwidth(thick)) ///
		(line bs_ll_emo11 hh if hh<=`mm', lpattern(dash) lcolor(blue)) ///
		(line bs_ul_emo11 hh if hh<=`mm', lpattern(dash) lcolor(blue)) ///
		, ///
		legend(off) ///
		yti("Basis points", si(small)) yline(0) ti("Panel I: Human-classification text sentiment", size(small)) name(SPY_emo10, replace) ///
		xtitle("Days from FOMC press conference", size(small)) xlab(, labs(small)) ylab(, labs(small)) nodraw

}

gr combine SPY_emo2 SPY_emo3 SPY_emo4 SPY_emo5 SPY_emo6 SPY_emo7 SPY_emo8 SPY_emo9 SPY_emo10, rows(3) imargin(tiny) ti("SPY: Voice Tone", size(medium))
gr display, ysize(12) xsize(20)
gr export Fig14.png, width(1800) replace
erase SPY_robustness.dta
