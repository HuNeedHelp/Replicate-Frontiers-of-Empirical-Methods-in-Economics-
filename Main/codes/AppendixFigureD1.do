clear
set more off
set scheme s1color
cap cd .
set seed 1234

qui foreach index in SPY VIX VIXY LQD_LQDH GOVT LQD IVR GOVT_TIP GLD JPY EUR {
	use est_`index', clear

	g pressconf=countQA>0&countQA!=.
	g nopress=pressconf==0

	g emo = (pos-neg)/(pos+neg)
	replace emo=0 if pressconf==0

	gen S_statement=cosine_s
	gen S_QASR=(cosine_s+cosine+cosine_r)/3
				
	gen S_QASR0=S_QASR
	replace S_QASR0=S_statement if pressconf==0		
						
	tsset date
	g fake_date=_n
	tsset fake_date
	
	*** cumulative return/news
	gen M0=ret_`index'
		forv hh = 1/15 {
		local hh1=`hh'-1
		gen M`hh'=M`hh1'+f`hh'.ret_`index'
	}
							
	*** save results for bootstrap se (not symmetric)
	tempname fig_bs
	postfile `fig_bs'	hh ///
						 bs_b_emo   bs_ll_emo bs_ul_emo  ///
						 using `index'_temp, replace

	keep if fomc==1
		
	forv hh = 0/15 {
		noisily di "`index' : `hh'"
		bootstrap, reps(2000) bca: reg M`hh'	emo S_QASR0 FFR FG AP shadowrate nopress, level(90)
		
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
	
		*** standard errors: bootstrap; symmetric
		post `fig_bs'		(`hh') ///
						(`bs_b_emo') (`bs_ll_emo')  (`bs_ul_emo')
							
	}
	postclose `fig_bs'
		
}

	*===============================================================================
	*							plot results
	*===============================================================================
qui foreach index in SPY VIX VIXY LQD_LQDH GOVT LQD IVR GOVT_TIP GLD JPY EUR {
	use `index'_temp, clear
	loc mm=15
		
	foreach var in emo {
		replace bs_b_`var'=bs_b_`var'*100
		replace bs_ll_`var'=bs_ll_`var'*100
		replace bs_ul_`var'=bs_ul_`var'*100
	}
		
		
	twoway (line bs_b_emo hh if hh<=`mm', lpattern(solid) lcolor(blue)  lwidth(thick)) ///
			(line bs_ll_emo hh if hh<=`mm', lpattern(dash) lcolor(blue)) ///
			(line bs_ul_emo hh if hh<=`mm', lpattern(dash) lcolor(blue)) ///
			, ///
			legend(off) ///
			yti("Basis points", si(small)) yline(0) ti("`index': Voice tone", size(medium)) name(`index', replace) ///
			xtitle("Days from FOMC press conference", size(small)) xlab(, labs(small)) nodraw
			
	erase `index'_temp.dta
}
		
graph combine SPY VIX VIXY LQD_LQDH GOVT LQD IVR GOVT_TIP GLD JPY EUR, rows(4) imargin(tiny)
gr export AppendixFigD1.png, width(1800) replace


