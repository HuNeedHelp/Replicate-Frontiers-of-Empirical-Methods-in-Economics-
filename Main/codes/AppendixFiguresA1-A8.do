clear
set more off
set scheme s1color
cap cd .
set seed 1234

qui foreach index in SHV SHY IEI IEF TLH TLT VIXM GBP {
	use est_`index', clear
		
	g pressconf=countQA!=0
	g nopress=pressconf==0

	g emo = (pos-neg)/(pos+neg)
	replace emo=0 if pressconf==0

	gen S_statement=(dovish_s_bert - hawkish_s_bert)/(dovish_s_bert + hawkish_s_bert)
	gen S_QASR=(dovish_bert-hawkish_bert+dovish_s_bert-hawkish_s_bert+dovish_r_bert-hawkish_r_bert)/(dovish_bert+hawkish_bert+dovish_s_bert+hawkish_s_bert+dovish_r_bert+hawkish_r_bert)
			
	gen S_QASR0=S_QASR
	replace S_QASR0=S_statement if pressconf==0	
						
	tsset date
	g fake_date=_n
	tsset fake_date
	
	*** cumulative return
	gen M0=ret_`index'
		forv hh = 1/24 {
		local hh1=`hh'-1
		gen M`hh'=M`hh1'+f`hh'.ret_`index'
	}
							
	*** save results for bootstrap se (not symmetric)
	tempname fig_bs
	postfile `fig_bs'	hh ///
						 bs_b_emo   bs_ll_emo bs_ul_emo  ///
						 bs_b_S_QASR0 bs_ll_S_QASR0 bs_ul_S_QASR0   ///
						 bs_b_FFR bs_ll_FFR bs_ul_FFR  ///
						 bs_b_AP bs_ll_AP bs_ul_AP  ///
						 bs_b_FG bs_ll_FG bs_ul_FG   ///
						 bs_b_emoNC bs_ll_emoNC bs_ul_emoNC  ///   /* no controls */						
						using `index'_appendix, replace	

	keep if fomc==1
		
	forv hh = 0/15 {
		noisily di "`index' : `hh'"
		bootstrap, reps(2000) bca: reg M`hh'	emo S_QASR0 FFR FG AP shadowrate nopress, level(90)
		
		foreach var1 in emo S_QASR0 FFR AP FG {
			loc se_`var1' = _se[`var1']
			loc b_`var1' = _b[`var1']
		}
		
		*** bias corrected estimates
		matrix A=e(ci_bca)			/* ACCELERATED confidence interval 90% */
		matrix B=e(b)-e(bias)		/* bias corrected estimate */
		
			
		loc bs_ll_emo=A[1,1]
		loc bs_ul_emo=A[2,1]
		loc bs_b_emo=B[1,1]
		
		loc bs_ll_S_QASR0=A[1,2]
		loc bs_ul_S_QASR0=A[2,2]	
		loc bs_b_S_QASR0=B[1,2]
		
		loc bs_ll_FFR=A[1,3]
		loc bs_ul_FFR=A[2,3]
		loc bs_b_FFR=B[1,3]
		
		loc bs_ll_FG=A[1,4]
		loc bs_ul_FG=A[2,4]
		loc bs_b_FG=B[1,4]
		
		loc bs_ll_AP=A[1,5]
		loc bs_ul_AP=A[2,5]
		loc bs_b_AP=B[1,5]
		
			
		bootstrap, reps(2000) bca: reg M`hh'	emo , level(90)
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
		post `fig_bs'		(`hh') ///
						(`bs_b_emo') (`bs_ll_emo')  (`bs_ul_emo') ///
						(`bs_b_S_QASR0')  (`bs_ll_S_QASR0')  (`bs_ul_S_QASR0')  ///
						(`bs_b_FFR')  (`bs_ll_FFR')  (`bs_ul_FFR')  ///
						(`bs_b_AP')  (`bs_ll_AP')  (`bs_ul_AP') ///
						(`bs_b_FG')  (`bs_ll_FG')  (`bs_ul_FG')  ///
						(`bs_b_emoNC')  (`bs_ll_emoNC')  (`bs_ul_emoNC') 
							
	}
	postclose `fig_bs'
		
}

	*===============================================================================
	*							plot results
	*===============================================================================
qui foreach index in SHV SHY IEI IEF TLH TLT VIXM GBP {
	use `index'_appendix, clear
	loc mm=15
		
	foreach var in emo S_QASR0 FFR AP FG emoNC {
		replace bs_b_`var'=bs_b_`var'*100
		replace bs_ll_`var'=bs_ll_`var'*100
		replace bs_ul_`var'=bs_ul_`var'*100
	}
		
		
	twoway (line bs_b_emo hh if hh<=`mm', lpattern(solid) lcolor(blue)  lwidth(thick)) ///
			(line bs_ll_emo hh if hh<=`mm', lpattern(dash) lcolor(blue)) ///
			(line bs_ul_emo hh if hh<=`mm', lpattern(dash) lcolor(blue)) ///
			, ///
			legend(off) ///
			yti("Basis points", si(small)) yline(0) ti("`index': Voice tone", size(medium)) name(`index'_emo_bs, replace) ///
			xtitle("Days from FOMC press conference", size(small)) xlab(, labs(small)) nodraw
		
	twoway (line bs_b_emoNC hh if hh<=`mm', lpattern(solid) lcolor(midblue)  lwidth(thick)) ///
			(line bs_ll_emoNC hh if hh<=`mm', lpattern(dash) lcolor(midblue)) ///
			(line bs_ul_emoNC hh if hh<=`mm', lpattern(dash) lcolor(midblue)) ///
			, ///
			legend(off) ///
			yti("Basis points", si(small)) yline(0) ti("`index': Voice tone (no controls)", size(medium)) name(`index'_emoNC_bs, replace) ///
			xtitle("Days from FOMC press conference", size(small)) xlab(, labs(small)) nodraw
			
			
	twoway (line bs_b_S_QASR0 hh if hh<=`mm', lpattern(solid) lcolor(red)  lwidth(thick)) ///
			(line bs_ll_S_QASR0 hh if hh<=`mm', lpattern(dash) lcolor(red)) ///
			(line bs_ul_S_QASR0 hh if hh<=`mm', lpattern(dash) lcolor(red)) ///
			, ///
			legend(off) ///
			yti("Basis points", si(small)) yline(0) ti("`index': Text sentiment", size(medium)) name(`index'_senti_bs, replace) ///
			xtitle("Days from FOMC press conference", size(small)) xlab(, labs(small)) nodraw
			
			
	twoway (line bs_b_FFR hh if hh<=`mm', lpattern(solid) lcolor(black)  lwidth(thick)) ///
			(line bs_ll_FFR hh if hh<=`mm', lpattern(dash) lcolor(black)) ///
			(line bs_ul_FFR hh if hh<=`mm', lpattern(dash) lcolor(black)) ///
			, ///
			legend(off) ///
			yti("Basis points", si(small)) yline(0) ti("`index': FFR shock", size(medium)) name(`index'_FFR_bs, replace) ///
			xtitle("Days from FOMC press conference", size(small)) xlab(, labs(small)) nodraw
			
	twoway (line bs_b_FG hh if hh<=`mm', lpattern(solid) lcolor(green)  lwidth(thick)) ///
			(line bs_ll_FG hh if hh<=`mm', lpattern(dash) lcolor(green)) ///
			(line bs_ul_FG hh if hh<=`mm', lpattern(dash) lcolor(green)) ///
			, ///
			legend(off) ///
			yti("Basis points", si(small)) yline(0) ti("`index': FG shock", size(medium)) name(`index'_FG_bs, replace) ///
			xtitle("Days from FOMC press conference", size(small)) xlab(, labs(small)) nodraw
			
	twoway (line bs_b_AP hh if hh<=`mm', lpattern(solid) lcolor(gold)  lwidth(thick)) ///
			(line bs_ll_AP hh if hh<=`mm', lpattern(dash) lcolor(gold)) ///
			(line bs_ul_AP hh if hh<=`mm', lpattern(dash) lcolor(gold)) ///
			, ///
			legend(off) ///
			yti("Basis points", si(small)) yline(0) ti("`index': AP shock", size(medium)) name(`index'_AP_bs, replace) ///
			xtitle("Days from FOMC press conference", size(small)) xlab(, labs(small)) nodraw
	
	if "`index'"=="SHV" loc vv=1
	if "`index'"=="SHY" loc vv=2
	if "`index'"=="IEI" loc vv=3 
	if "`index'"=="IEF" loc vv=4
	if "`index'"=="TLH" loc vv=5
	if "`index'"=="TLT" loc vv=6
	if "`index'"=="VIXM" loc vv=7 
	if "`index'"=="GBP" loc vv=8    
		
	graph combine `index'_emoNC_bs `index'_emo_bs `index'_senti_bs `index'_FFR_bs `index'_FG_bs `index'_AP_bs, rows(2) imargin(tiny)
	gr export AppendixFig`vv'.png, width(1800) replace
	erase `index'_appendix.dta
}

