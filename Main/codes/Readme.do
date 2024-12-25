clear
set more off
* set the base directory here
loc base_folder C:/Users/anhth/Dropbox/Research/projects/0SashaYuriy/PressConf_speeches/Replication/Public/Main
loc do_folder `base_folder'/codes/
loc dta_folder `base_folder'/data/


*~~Block 1: Pre-process financial data and FOMC data~~*
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*	Notes 1: The following files are strictly required in the "./Main/data/raw/" folder for the codes to run. If these files are absent, skip lines 97-195 in preprocess0.do and merge_all.do
*	1. fomc_all.xlsx (all FOMC text sentiment and voice emotion data)
*	2. media_all.xlsx (text sentiment data for media news and FED tweets)
*	3. policyshocks_swanson.xlsx (Swanson's policy shocks series)
*	4. shadowrate.xlsx (Wu and Xia's shadow rate series)
*	5. All csv files containing daily prices for SPY VIX VIXY GOVT LQD IVR GLD JPY EUR SHV SHY IEI IEF TLH TLT VIXM GBP TIP LQDH

*	Notes 2: The following file is needed to create Panel A of Figure 14. If this file is absent, a dta file with fake data will be created so that the codes can be run, but Panel A of Figure 14 will not be produced.
*	6. CESI.xlsx (series of Citigroup Economic Surprise Index)

*	Notes 3: The following file is needed for intraday analysis. If this file is absent, skip proprocess1.do
*	7. SPY_tick.dta (tick data for SPY)
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
cd `base_folder'
* Run preprocess0.do to create dta files containing series of financial indicators used in the main analysis
*do `do_folder'preprocess0.do

* Run preprocess1.do to create dta files containing prices for SPY matched with the timing of the answers - This will take time to run
*do `do_folder'preprocess1.do

* Run preprocess2.do to create dta files for FOMC and media data
*do `do_folder'preprocess2.do


*~~Block 2: Merge financial data with FOMC data to create samples for analysis~~*
* Run merge_all.do to merge financial/media data with control variables and create the samples for analysis
cd `dta_folder'
*do `do_folder'merge_all.do


*~~Block 3: Create tables and figures~~*
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*	Notes: The following files are required in the "./Main/data/" folder for the codes to run
*	1. FED.dta: all FOMC data
*	2. est_*.dta: all samples for analysis
*	3. SPY_intraday.dta: pre-processed intraday prices for SPY - if this file is absent, skip Figure15.do
*	4. yahoo_earnings.dta: number of corporate earning annoucements for US firms
*	5. cesi.dta: the Citigroup US Economic Surprise Index
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* Run Table1.do to create Table 1: Summary statistics for FOMC data
*do `do_folder'Table1.do

* Run Figures1-2.do to create Figure 1: Correlation between the tone of voice measure and the text sentiment measure and Figure 2: Correlation between the tone of voice measure and the policy shocks
*do `do_folder'Figures1-2.do

* Run Figures3-13.do to create Figures 3 – 13: Baseline results for different financial indicators
*do `do_folder'Figures3-13.do

* Run Figure14.do to create Figure 14: Effects of the tone of voice when additional control variables are added or when different text sentiment measures are used
*do `do_folder'Figure14.do

* Run Figure15.do to create Figure 15: High-frequency analysis
*do `do_folder'Figure15.do

* Run Figure16.do to create Figure 16: Effects of the tone of voice on the text sentiment of media news and tweets after the FOMC meetings
do `do_folder'Figure16.do


*~~Block 4: Create appendix tables and figures~~*
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*	Notes: The following files are required in the "./Main/data/" folder for the codes to run
*	1. FED.dta: all FOMC data
*	2. est_*.dta: all samples for analysis
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* Run Table1.do to create Appendix Tables A1 and A2: Tone of voice and text sentiment scores for each FOMC meeting/press conferences
do `do_folder'AppendixTablesA1-A2.do

* Run AppendixFiguresA1-A8.do to create Appendix Figures A1-A8 (additional outcome variables)
do `do_folder'AppendixFiguresA1-A8.do

* Run AppendixFigureA9.do to create Appendix Figure A9: Variance decomposition (SPY ETF)
do `do_folder'AppendixFigureA9.do

* Run AppendixFigureB1.do to create Appendix Figure D1: Control for the intensity of text sentiment
do `do_folder'AppendixFigureD1.do

* Run AppendixFigureD2.do to create Appendix Figure D2: Control for the non-linear terms of text sentiment
do `do_folder'AppendixFigureD2.do
