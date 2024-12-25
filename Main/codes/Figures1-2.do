clear
set more off
set scheme s1color
cap cd .

use FED, clear
g month=mofd(date)
format month %tm
	
merge 1:1 date using swanson
drop _merge
	
merge 1:1 date using cesi
drop _merge
	
merge m:1 month using shadowrate
drop if _merge==2


g pressconf = countQA!=.	
g emo = (pos-neg)/(pos+neg)
	
gen S_remarks=(dovish_r_bert - hawkish_r_bert)/(dovish_r_bert + hawkish_r_bert)
gen S_QA=(dovish_bert - hawkish_bert)/(dovish_bert  +  hawkish_bert)
gen S_statement=(dovish_s_bert - hawkish_s_bert)/(dovish_s_bert  +  hawkish_s_bert)
	
gen S_QASR=(dovish_bert - hawkish_bert + dovish_s_bert - hawkish_s_bert + dovish_r_bert - hawkish_r_bert)/(dovish_bert + hawkish_bert + dovish_s_bert + hawkish_s_bert + dovish_r_bert + hawkish_r_bert)
replace S_QASR = S_statement if S_QASR==.

*** compute correlation
corr emo S_QASR S_statement S_remarks S_QA

***=============================================================================
*** relationship between voice tone and text sentiment
tsset date

twoway	(scatter S_statement emo if fedchair=="Bernanke" & pressconf==1, msymbol(Th) ) ///
		(scatter S_statement emo if fedchair=="Yellen" & pressconf==1, msymbol(Sh) ) ///
		(scatter S_statement emo if fedchair=="Powell" & pressconf==1, msymbol(o) ) ///
		(lfit S_statement emo  if pressconf==1, lcolor(black)) ///
		, ///
		xtitle("Voice tone: Q&A") ytitle("Text Sentiment: Statement") ///
		legend(off) ///
		title("Panel A. Text Sentiment (Statement) vs. Voice Tone", size(small)) ///
		name(fig1, replace) nodraw
		
	
twoway (scatter S_remarks emo if fedchair=="Bernanke", msymbol(Th) ) ///
	   (scatter S_remarks emo if fedchair=="Yellen", msymbol(Sh) ) ///
		(scatter S_remarks emo if fedchair=="Powell", msymbol(o) ) ///
		(lfit S_remarks emo , lcolor(black)) ///
		, ///
		xtitle("Voice tone: Q&A") ytitle("Text Sentiment: Remarks") ///
		legend(off) ///
		title("Panel B. Text Sentiment (Remarks) vs. Voice Tone", size(small)) ///
		name(fig2, replace) nodraw
		
twoway (scatter  S_QA emo if fedchair=="Bernanke", msymbol(Th) ) ///
	   (scatter  S_QA emo if fedchair=="Yellen", msymbol(Sh) ) ///
		(scatter  S_QA emo if fedchair=="Powell", msymbol(o) ) ///
		(lfit  S_QA emo , lcolor(black)) ///
		, ///
		ytitle("Text Sentiment: Q&A") xtitle("Voice tone: Q&A") ///
		legend(off) ///
		title("Panel C. Text Sentiment (Q&A) vs. Voice Tone", size(small)) ///
		name(fig3, replace) nodraw
			
twoway (scatter S_QASR emo if fedchair=="Bernanke", msymbol(Th) ) ///
	   (scatter S_QASR emo if fedchair=="Yellen", msymbol(Sh) ) ///
		(scatter S_QASR emo if fedchair=="Powell", msymbol(o) ) ///
		(lfit S_QASR emo, lcolor(black)) ///
		, ///
		xtitle("Voice tone: Q&A") ytitle("Text Sentiment: All") ///
		title("Panel D. Text Sentiment (All) vs. Voice Tone", size(small)) ///
		name(fig4, replace)	///
		legend(order(1 2 3) label(1 "Bernanke") label(2 "Yellen") label(3 "Powell") ring(0) position(5) rows(3) rowgap(0.2)) nodraw

gr combine fig1 fig2 fig3 fig4, imargin(tiny)
gr export Fig1.png, width(1800) replace

	
***=============================================================================
*** relationship with policy shocks
twoway (scatter  FFR emo if fedchair=="Bernanke" & pressconf==1, msymbol(Th) ) ///
	   (scatter  FFR emo if fedchair=="Yellen" & pressconf==1, msymbol(Sh) ) ///
		(scatter  FFR emo if fedchair=="Powell" & pressconf==1, msymbol(o) ) ///
		(lfit  FFR emo if pressconf==1, lcolor(black)) ///
		, ///
		ytitle("FFR shock") xtitle("Voice tone") ///
		title("Panel A. Voice Tone vs. FFR shock", size(medium)) ///
		name(figv1, replace)	///
		legend(off) nodraw
	
twoway (scatter  FG emo if fedchair=="Bernanke" & pressconf==1, msymbol(Th) ) ///
	   (scatter  FG emo if fedchair=="Yellen" & pressconf==1, msymbol(Sh) ) ///
		(scatter  FG emo if fedchair=="Powell" & pressconf==1, msymbol(o) ) ///
		(lfit  FG emo if pressconf==1, lcolor(black)) ///
		, ///
		ytitle("FG shock")  xtitle("Voice tone")  ///
		title("Panel B. Voice Tone vs. FG shock", size(medium)) ///
		name(figv2, replace)	///
		legend(off)	nodraw
		

twoway (scatter  AP emo if fedchair=="Bernanke" & pressconf==1, msymbol(Th) ) ///
	   (scatter  AP emo if fedchair=="Yellen" & pressconf==1, msymbol(Sh) ) ///
		(scatter  AP emo if fedchair=="Powell" & pressconf==1, msymbol(o) ) ///
		(lfit  AP emo if pressconf==1, lcolor(black)) ///
		, ///
		ytitle("AP shock")  xtitle("Voice tone")  ///
		title("Panel C. Voice Tone vs. AP shock", size(medium)) ///
		name(figv3, replace)	///
		legend(off)	nodraw
			
twoway (scatter  shadow emo if fedchair=="Bernanke" & pressconf==1, msymbol(Th) ) ///
	   (scatter  shadow emo if fedchair=="Yellen" & pressconf==1, msymbol(Sh) ) ///
		(scatter  shadow emo if fedchair=="Powell" & pressconf==1, msymbol(o) ) ///
		(lfit  shadow emo if pressconf==1, lcolor(black)) ///
		, ///
		ytitle("Shadow policy rate")  xtitle("Voice tone")  ///
		title("Panel D. Voice Tone vs. Shadow rate", size(medium)) ///
		name(figv4, replace)	///
		legend(off)	nodraw
		
corr emo FFR FG AP shadow if pressconf==1
		
graph combine figv1 figv2 figv3 figv4, imargin(tiny) rows(2)
gr export Fig2.png, width(1800) replace
