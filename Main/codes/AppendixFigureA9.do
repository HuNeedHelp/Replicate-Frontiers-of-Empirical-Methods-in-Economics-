clear
set more off
set scheme s1color
cap cd .
set seed 1234

net from http://www.marco-sunder.de/stata/
net install rego


use est_SPY, clear
		
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

*** cumulative return/news
gen M0=ret_SPY
	forv hh = 1/24 {
	local hh1=`hh'-1
	gen M`hh'=M`hh1'+f`hh'.ret_SPY
}						

keep if fomc==1

tempfile temp
save `temp', replace

clear
g hh=.
tempfile final
save `final', replace
forv i = 0/15 {
	use `temp', clear
	rego M`i' emo S_QASR0 FFR FG AP shadowrate nopress, bs(2000) level(90)

	matrix DECOMP = e(bs_shapley_perc)
	matrix colnames DECOMP = emo S_QASR0 FFR FG AP shadowrate nopress
	matrix list DECOMP

	clear
	svmat DECOMP, names(col)
	g order=_n
	g hh=`i'
	append using `final'
	save `final', replace
}

reshape wide emo S_QASR0 FFR FG AP shadowrate nopress, i(hh) j(order)

twoway (scatter emo2 hh, msymbol(O) mcolor(blue)) ///
       (rcap emo1 emo3 hh, lc(blue)) ///
	   (line emo2 hh, lc(blue)), legend(off) ///
	   yti("%", si(small)) ti("SPY: Voice tone", size(medium)) name(emo, replace) ///
	   xtitle("Days from FOMC press conference", size(small)) xlab(, labs(small)) nodraw	
		
twoway (scatter S_QASR02 hh, msymbol(O) mcolor(red)) ///
       (rcap S_QASR01 S_QASR03 hh, lc(red)) ///
	   (line S_QASR02 hh, lc(red)), legend(off) ///
	   yti("%", si(small)) ti("SPY: Text sentiment", size(medium)) name(S_QASR0, replace) ///
	   xtitle("Days from FOMC press conference", size(small)) xlab(, labs(small)) nodraw
		
twoway (scatter FFR2 hh, msymbol(O) mcolor(gs0)) ///
       (rcap FFR1 FFR3 hh, lc(gs0)) ///
	   (line FFR2 hh, lc(gs0)), legend(off) ///
	   yti("%", si(small)) ti("SPY: FFR shock", size(medium)) name(FFR, replace) ///
	   xtitle("Days from FOMC press conference", size(small)) xlab(, labs(small)) nodraw
		
twoway (scatter FG2 hh, msymbol(O) mcolor(green)) ///
       (rcap FG1 FG3 hh, lc(green)) ///
	   (line FG2 hh, lc(green)), legend(off) ///
	   yti("%", si(small)) ti("SPY: FG shock", size(medium)) name(FG, replace) ///
	   xtitle("Days from FOMC press conference", size(small)) xlab(, labs(small)) nodraw
		
twoway (scatter AP2 hh, msymbol(O) mcolor(gold)) ///
       (rcap AP1 AP3 hh, lc(gold)) ///
	   (line AP2 hh, lc(gold)), legend(off) ///
	   yti("%", si(small)) ti("SPY: AP shock", size(medium)) name(AP, replace) ///
	   xtitle("Days from FOMC press conference", size(small)) xlab(, labs(small)) nodraw
		
twoway (scatter shadowrate2 hh, msymbol(O) mcolor(midblue)) ///
       (rcap shadowrate1 shadowrate3 hh, lc(midblue)) ///
	   (line shadowrate2 hh, lc(midblue)), legend(off) ///
	   yti("%", si(small)) ti("SPY: Shadow rate", size(medium)) name(shadowrate, replace) ///
	   xtitle("Days from FOMC press conference", size(small)) xlab(, labs(small)) nodraw
		
graph combine emo S_QASR0 FFR FG AP shadowrate, rows(2) imargin(tiny) ti("Absolute contributions to R-squared", si(medium)) note("Notes: 90% CI with median", si(vsmall))
gr export AppendixFigA9.png, width(1800) replace
		
