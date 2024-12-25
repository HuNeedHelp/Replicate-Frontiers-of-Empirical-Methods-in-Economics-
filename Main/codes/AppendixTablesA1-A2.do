clear
set more off
set scheme s1color
cap cd .

use FED, clear
tsset date
g emotion = (pos - neg)/(pos + neg)
drop if emotion==.
replace emotion=round(emotion,0.01)
keep date fedchair pos neu neg emotion
order date fedchair pos neu neg emotion
export excel using AppendixTableA1.xlsx, firstrow(variables) replace

use FED, clear
foreach i in dovish_bert hawkish_bert dovish_s_bert hawkish_s_bert dovish_r_bert hawkish_r_bert {
	replace `i'=0 if `i'==.
}
tsset date
gen sentiment=(dovish_bert - hawkish_bert + dovish_s_bert - hawkish_s_bert + dovish_r_bert - hawkish_r_bert)/(dovish_bert + hawkish_bert + dovish_s_bert + hawkish_s_bert + dovish_r_bert + hawkish_r_bert)
keep date fedchair sentiment
order date fedchair sentiment
replace sentiment=round(sentiment,0.01)
export excel using AppendixTableA2.xlsx, firstrow(variables) replace
