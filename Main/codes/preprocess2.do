clear
set more off
cap cd .
loc original ./data/raw/
loc dta ./data/

*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*	FOMC data
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*** policy decision
import excel `original'fomc_all.xlsx, sheet("fomc_policy") firstrow clear
format date %td
tsset date
g pressconf="FED"
g fomc_cycle=_n
g fomc=1
g fedchair_id=1 if fedchair=="Bernanke"
replace fedchair_id=2 if fedchair=="Yellen"
replace fedchair_id=3 if fedchair=="Powell"
save `dta'FED, replace

****** Text sentiment data **********
*** counts of hawkish/dovish phrases
import excel `original'fomc_all.xlsx, sheet("answers_count") firstrow clear
g countQA=1
collapse (sum) hawkish_count=hawkish dovish_count=dovish (sum) countQA, by(date)
merge 1:1 date using `dta'FED
drop _merge
save `dta'FED, replace
	
import excel `original'fomc_all.xlsx, sheet("remarks_count") firstrow clear
collapse (sum) hawkish_r_count=hawkish dovish_r_count=dovish, by(date)
merge 1:1 date using `dta'FED
drop _merge
save `dta'FED, replace

import excel `original'fomc_all.xlsx, sheet("statement_count") firstrow clear
collapse (sum) hawkish_s_count=hawkish dovish_s_count=dovish, by(date)
merge 1:1 date using `dta'FED
drop _merge
save `dta'FED, replace

*** fine-tune bert/roberta
foreach bb in bert roberta {
	import excel `original'fomc_all.xlsx, sheet("answers_`bb'") firstrow clear
	g hawkish=sent==0
	g dovish_=sent==2
	g neutral=sent==1
	collapse (sum) hawkish_`bb'=hawkish dovish_`bb'=dovish neutral_`bb'=neutral, by(date)
	merge 1:1 date using `dta'FED
	drop _merge
	save `dta'FED, replace
		
	import excel `original'fomc_all.xlsx, sheet("remarks_`bb'") firstrow clear
	g hawkish=sent==0
	g dovish=sent==2
	g neutral=sent==1
	collapse (sum) hawkish_r_`bb'=hawkish dovish_r_`bb'=dovish neutral_r_`bb'=neutral, by(date)
	merge 1:1 date using `dta'FED
	drop _merge
	save `dta'FED, replace

	import excel `original'fomc_all.xlsx, sheet("statement_`bb'") firstrow clear
	g hawkish=sent==0
	g dovish=sent==2
	g neutral=sent==1
	collapse (sum) hawkish_s_`bb'=hawkish dovish_s_`bb'=dovish neutral_s_`bb'=neutral, by(date)
	merge 1:1 date using `dta'FED
	drop _merge
	save `dta'FED, replace
}

*** human label
import excel `original'fomc_all.xlsx, sheet("answers_human") firstrow clear
collapse (mean) score_QA=avr_score (sum) total_score_QA = avr_score, by(date)
merge 1:1 date using `dta'FED
drop _merge
save `dta'FED, replace
	
import excel `original'fomc_all.xlsx, sheet("remarks_human") firstrow clear
ren avr_score score_R
merge 1:1 date using `dta'FED
drop _merge
save `dta'FED, replace

import excel `original'fomc_all.xlsx, sheet("statement_human") firstrow clear
ren avr_score score_S
merge 1:1 date using `dta'FED
drop _merge
save `dta'FED, replace


*** finbert
import excel `original'fomc_all.xlsx, sheet("answers_finbert") firstrow clear
g dovish_finbert = Positive>Neutral&Positive>Negative
g hawkish_finbert = Negative>Neutral&Negative>Positive
g neutral_finbert = Neutral>Positive&Neutral>Negative
collapse (sum) *_finbert, by(date)
merge 1:1 date using `dta'FED
drop _merge
save `dta'FED, replace


import excel `original'fomc_all.xlsx, sheet("remarks_finbert") firstrow clear
g dovish_r_finbert = Positive>Neutral&Positive>Negative
g hawkish_r_finbert = Negative>Neutral&Negative>Positive
g neutral_r_finbert = Neutral>Positive&Neutral>Negative
collapse (sum) *_finbert, by(date)
merge 1:1 date using `dta'FED
drop _merge
save `dta'FED, replace


import excel `original'fomc_all.xlsx, sheet("statement_finbert") firstrow clear
g dovish_s_finbert = Positive>Neutral&Positive>Negative
g hawkish_s_finbert = Negative>Neutral&Negative>Positive
g neutral_s_finbert = Neutral>Positive&Neutral>Negative
collapse (sum) *_finbert, by(date)
merge 1:1 date using `dta'FED
drop _merge
save `dta'FED, replace

*** Sentiment following Jha et al (2021)
import excel `original'fomc_all.xlsx, sheet("answers_cosine") firstrow clear
collapse (mean) cosine, by(date)
merge 1:1 date using `dta'FED
drop _merge
save `dta'FED, replace
	
import excel `original'fomc_all.xlsx, sheet("remarks_cosine") firstrow clear
collapse (mean) cosine_r = cosine, by(date)
merge 1:1 date using `dta'FED
drop _merge
save `dta'FED, replace

import excel `original'fomc_all.xlsx, sheet("statement_cosine") firstrow clear
collapse (mean) cosine_s = cosine, by(date)
merge 1:1 date using `dta'FED
drop _merge
save `dta'FED, replace


****** Speech emotion **********
import excel `original'fomc_all.xlsx, sheet("answers_emotion") firstrow clear
g pos=inlist(emotion,"happy","ps")
g neu=emotion=="neutral"
g neg=inlist(emotion,"sad","angry")
collapse (sum) pos neu neg, by(date)
merge 1:1 date using `dta'FED
drop _merge pressconf
save `dta'FED, replace

*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*	Media data
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

*** news sentiment
import excel `original'media_all.xlsx, sheet("news_sentiment") firstrow clear
g hawkish=sent==0
g dovish=sent==2
g neutral=sent==1

*drop news published in other timezones
drop if inlist(timezone,"PT","GMT")
g news=1
collapse (sum) news news_dovish=dovish news_neu=neutral news_hawkish=hawkish, by(date)
tsset date
tsfill

* drop weekend
g dow=dow(date)
drop if inlist(dow,0,6)
drop dow

unab vars: news*
foreach i of loc vars {
	replace `i'=0 if `i'==.
}

save `dta'media_news, replace

*** tweet sentiment
import excel `original'media_all.xlsx, sheet("tweets_sentiment") firstrow clear
g tweet_dovish=sent==2
g tweet_hawkish=sent==0
g tweet_neutral=sent==1
g n_tweet=1
collapse (sum) tweet_* n_tweet, by(date)

tsset date
tsfill

*drop weekend
g dow=dow(date)
drop if inlist(dow,0,6)
drop dow

foreach i in tweet_dovish tweet_hawkish tweet_neutral n_tweet {
	replace `i'=0 if `i'==.
}

save `dta'media_tweets, replace
