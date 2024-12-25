clear
set more off
set scheme s1color
cap cd .
set seed 1234

**************
* Panel A: Tweets' sentiment
**************
use est_media_tweets, clear
g pressconf=countQA>0&countQA!=.
g nopress=pressconf==0

g emo = (pos-neg)/(pos+neg)
replace emo=0 if pressconf==0

gen S_statement=(dovish_s_bert - hawkish_s_bert)/(dovish_s_bert + hawkish_s_bert)
gen S_QASR=(dovish_bert-hawkish_bert+dovish_s_bert-hawkish_s_bert+dovish_r_bert-hawkish_r_bert)/(dovish_bert+hawkish_bert+dovish_s_bert+hawkish_s_bert+dovish_r_bert+hawkish_r_bert)	
replace S_QASR=S_statement if pressconf==0

tsset date
g fake_date=_n
tsset fake_date

g tweet_sent = (tweet_dovish-tweet_hawkish)/n_tweet
replace tweet_sent=0 if tweet_sent==.


gen M0=tweet_sent
forv hh = 1/15 {
	local hh1=`hh'-1
	gen M`hh'=M`hh1'+f`hh'.tweet_sent
}
	
keep if fomc==1


tempname fig16
postfile `fig16'	hh ///
					bs_b_emo   bs_ll_emo bs_ul_emo  ///
					bs_b_emoNC bs_ll_emoNC bs_ul_emoNC   ///					
					using tweet, replace	


		
qui forv hh = 0/15 {
	noisily di "`hh'"
	bootstrap, reps(2000) bca: reg M`hh' emo S_QASR FFR FG AP shadowrate nopress, level(90)
		
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
		
	bootstrap, reps(2000) bca: reg M`hh' emo, level(90)
		
	foreach var1 in emo {
		loc se_`var1' = _se[`var1']
		loc b_`var1' = _b[`var1']
	}
		
		*** bias corrected estimates
		matrix A=e(ci_bca)			/* ACCELERATED confidence interval 90% */
		matrix B=e(b)-e(bias)		/* bias corrected estimate */
		
			
		loc bs_ll_emoNC=A[1,1]
		loc bs_ul_emoNC=A[2,1]
		loc bs_b_emoNC=B[1,1]
				
	
		*** standard errors: bootstrap; symmetric
		post `fig16'		(`hh') ///
						(`bs_b_emo') (`bs_ll_emo')  (`bs_ul_emo') ///
						(`bs_b_emoNC')  (`bs_ll_emoNC')  (`bs_ul_emoNC') 
							
}
postclose `fig16'
		


*===============================================================================
*							plot results
*===============================================================================

use tweet, clear
	
twoway	(line bs_b_emo hh , lpattern(solid) lcolor(blue)  lwidth(thick)) ///
		(line bs_ll_emo hh , lpattern(dash) lcolor(blue)) ///
		(line bs_ul_emo hh , lpattern(dash) lcolor(blue)) ///
		(line bs_b_emoNC hh , lpattern(solid) lcolor(midblue)  lwidth(thick)) ///
		(line bs_ll_emoNC hh , lpattern(dash) lcolor(midblue)) ///
		(line bs_ul_emoNC hh , lpattern(dash) lcolor(midblue)) ///			
		, ///
		legend(order(1 4) label(1 "Controls") label(4 "No controls") ring(0) position(10) rows(2) rowgap(0.2) ) ///
		yti("Tweet sentiment") yline(0) ///
		xtitle("Days from FOMC press conference") xlab(, labs(small)) ///
		ti("Panel A. Text sentiment in Twitter messages posted by the Fed's accounts", si(small)) name(tweet, replace)
cap erase tweet.dta




****************
* Panel B: News sentiment
****************
use est_media_news, clear
		
g pressconf=countQA>0&countQA!=.
g nopress=pressconf==0

g emo = (pos-neg)/(pos+neg)
replace emo=0 if pressconf==0
		
gen S_statement=(dovish_s_bert - hawkish_s_bert)/(dovish_s_bert + hawkish_s_bert)
gen S_QASR=(dovish_bert-hawkish_bert+dovish_s_bert-hawkish_s_bert+dovish_r_bert-hawkish_r_bert)/(dovish_bert+hawkish_bert+dovish_s_bert+hawkish_s_bert+dovish_r_bert+hawkish_r_bert)
replace S_QASR=S_statement if pressconf==0
					
tsset date
g fake_date=_n
tsset fake_date
	
** news sentiment (dovish/hawkish)
gen nsent=(news_dovish-news_hawkish)/news
replace nsent=0 if news==0
	
gen Lnews5=l.nsent+l2.nsent+l3.nsent+l4.nsent+l5.nsent

gen M0=nsent
forv hh = 1/15 {
	local hh1=`hh'-1
	gen M`hh'=M`hh1'+f`hh'.nsent
}

keep if fomc==1
	
*** save results for bootstrap se (not symmetric)
tempname fig16
postfile `fig16'	hh ///
					bs_b_emo   bs_ll_emo bs_ul_emo  ///
					bs_b_emoNC bs_ll_emoNC bs_ul_emoNC  ///   /* no controls */
					using media, replace	
		

qui forv hh = 0/15 {
	noisily di "`hh'"
	bootstrap, reps(2000) bca: reg M`hh'	emo S_QASR FFR FG AP shadowrate nopress Lnews5, level(90)
		
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
		
	bootstrap, reps(2000) bca: reg M`hh'	emo, level(90)
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
	post `fig16'		(`hh') ///
						(`bs_b_emo') (`bs_ll_emo')  (`bs_ul_emo') ///
						(`bs_b_emoNC')  (`bs_ll_emoNC')  (`bs_ul_emoNC') 
}
postclose `fig16'
		

*===============================================================================
*							plot results
*===============================================================================
use media, clear
loc mm=15
		
twoway	(line bs_b_emo hh if hh<=`mm', lpattern(solid) lcolor(blue)  lwidth(thick)) ///
		(line bs_ll_emo hh if hh<=`mm', lpattern(dash) lcolor(blue)) ///
		(line bs_ul_emo hh if hh<=`mm', lpattern(dash) lcolor(blue)) ///
		(line bs_b_emoNC hh if hh<=`mm', lpattern(solid) lcolor(midblue)  lwidth(thick)) ///
		(line bs_ll_emoNC hh if hh<=`mm', lpattern(dash) lcolor(midblue)) ///
		(line bs_ul_emoNC hh if hh<=`mm', lpattern(dash) lcolor(midblue)) ///			
		, ///
		legend(order(1 4) label(1 "Controls") label(4 "No controls") ring(0) position(1) rows(2) rowgap(0.2) ) ///
		yti("Media sentiment") yline(0) ///
		xtitle("Days from FOMC press conference") xlab(, labs(small)) ///
		ti("Panel B. Text sentiment of media coverage", si(small)) name(media, replace)
cap erase media.dta
		
		
gr combine tweet media, imargin(tiny) rows(2)
gr display, ysize(15) xsize(10)
gr export Fig16.png, width(1800) replace				
