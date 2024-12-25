clear
set more off
cap cd .

use FED, clear
g pressconf=countQA!=.

g emotion = (pos - neg)/(pos + neg)

gen S_remarks=(dovish_r_bert - hawkish_r_bert)/(dovish_r_bert + hawkish_r_bert)
gen S_QA=(dovish_bert - hawkish_bert)/(dovish_bert  +  hawkish_bert)
gen S_statement=(dovish_s_bert - hawkish_s_bert)/(dovish_s_bert  +  hawkish_s_bert)
	
gen S_QASR=(dovish_bert - hawkish_bert + dovish_s_bert - hawkish_s_bert + dovish_r_bert - hawkish_r_bert)/(dovish_bert + hawkish_bert + dovish_s_bert + hawkish_s_bert + dovish_r_bert + hawkish_r_bert)
replace S_QASR = S_statement if S_QASR==.

** All
clear matrix
eststo: quietly estpost summarize fomc pressconf, listwise
esttab using Table1.csv, cells("sum") nodepvar plain sfmt(%9.0fc) replace

* Tone of voice
clear matrix
eststo: quietly estpost summarize pos neg neu , listwise
esttab using Table1.csv, cells("sum") nodepvar plain sfmt(%9.0fc) append

clear matrix
eststo: quietly estpost summarize emotion, listwise
esttab using Table1.csv, cells("mean") nodepvar plain sfmt(%9.2fc) append
esttab using Table1.csv, cells("sd") nodepvar plain sfmt(%9.2fc) append

* Text sentiment - Statement
clear matrix
eststo: quietly estpost summarize hawkish_s_bert dovish_s_bert neutral_s_bert, listwise
esttab using Table1.csv, cells("sum") nodepvar plain sfmt(%9.0fc) append

clear matrix
eststo: quietly estpost summarize S_statement , listwise
esttab using Table1.csv, cells("mean") nodepvar plain sfmt(%9.2fc) append
esttab using Table1.csv, cells("sd") nodepvar plain sfmt(%9.2fc) append

* Text sentiment - Remarks
clear matrix
eststo: quietly estpost summarize hawkish_r_bert dovish_r_bert neutral_r_bert, listwise
esttab using Table1.csv, cells("sum") nodepvar plain sfmt(%9.0fc) append

clear matrix
eststo: quietly estpost summarize S_remarks , listwise
esttab using Table1.csv, cells("mean") nodepvar plain sfmt(%9.2fc) append
esttab using Table1.csv, cells("sd") nodepvar plain sfmt(%9.2fc) append

* Text sentiment - Q&A
clear matrix
eststo: quietly estpost summarize hawkish_bert dovish_bert neutral_bert, listwise
esttab using Table1.csv, cells("sum") nodepvar plain sfmt(%9.0fc) append

clear matrix
eststo: quietly estpost summarize S_QA, listwise
esttab using Table1.csv, cells("mean") nodepvar plain sfmt(%9.2fc) append
esttab using Table1.csv, cells("sd") nodepvar plain sfmt(%9.2fc) append

* Text sentiment - all
clear matrix
eststo: quietly estpost summarize S_QASR, listwise
esttab using Table1.csv, cells("mean") nodepvar plain sfmt(%9.2fc) append
esttab using Table1.csv, cells("sd") nodepvar plain sfmt(%9.2fc) append

** By FED chair
clear matrix
bys fedchair: eststo: quietly estpost summarize fomc pressconf, listwise
esttab using Table1.csv, cells("sum") nodepvar plain sfmt(%9.0fc) append

* Tone of voice
clear matrix
bys fedchair: eststo: quietly estpost summarize pos neg neu , listwise
esttab using Table1.csv, cells("sum") nodepvar plain sfmt(%9.0fc) append

clear matrix
bys fedchair: eststo: quietly estpost summarize emotion, listwise
esttab using Table1.csv, cells("mean") nodepvar plain sfmt(%9.2fc) append
esttab using Table1.csv, cells("sd") nodepvar plain sfmt(%9.2fc) append

* Text sentiment - Statement
clear matrix
bys fedchair: eststo: quietly estpost summarize hawkish_s_bert dovish_s_bert neutral_s_bert, listwise
esttab using Table1.csv, cells("sum") nodepvar plain sfmt(%9.0fc) append

clear matrix
bys fedchair: eststo: quietly estpost summarize S_statement , listwise
esttab using Table1.csv, cells("mean") nodepvar plain sfmt(%9.2fc) append
esttab using Table1.csv, cells("sd") nodepvar plain sfmt(%9.2fc) append

* Text sentiment - Remarks
clear matrix
bys fedchair: eststo: quietly estpost summarize hawkish_r_bert dovish_r_bert neutral_r_bert, listwise
esttab using Table1.csv, cells("sum") nodepvar plain sfmt(%9.0fc) append

clear matrix
bys fedchair: eststo: quietly estpost summarize S_remarks , listwise
esttab using Table1.csv, cells("mean") nodepvar plain sfmt(%9.2fc) append
esttab using Table1.csv, cells("sd") nodepvar plain sfmt(%9.2fc) append

* Text sentiment - Q&A
clear matrix
bys fedchair: eststo: quietly estpost summarize hawkish_bert dovish_bert neutral_bert, listwise
esttab using Table1.csv, cells("sum") nodepvar plain sfmt(%9.0fc) append

clear matrix
bys fedchair: eststo: quietly estpost summarize S_QA, listwise
esttab using Table1.csv, cells("mean") nodepvar plain sfmt(%9.2fc) append
esttab using Table1.csv, cells("sd") nodepvar plain sfmt(%9.2fc) append

* Text sentiment - all
clear matrix
bys fedchair: eststo: quietly estpost summarize S_QASR, listwise
esttab using Table1.csv, cells("mean") nodepvar plain sfmt(%9.2fc) append
esttab using Table1.csv, cells("sd") nodepvar plain sfmt(%9.2fc) append
