****Priject: Travel and cognition
****Author:  Siyun Peng
****Date:    2023/07/12
****Version: 17
****Purpose: Data Cleaning 



************************************************************************
**# 1 Merge/clean data 
************************************************************************




/*Merge data*/


cd "C:\Users\peng_admin\OneDrive - Indiana University\Work with Shu"
use "COGIMP9220A_R",clear //1992-2020 cognition 
rename *, lower
gen hhidpn = hhid + pn
destring hhidpn,replace
keep r8cog27 r9cog27 r1?cog27 hhidpn //keep MoCA since 2006 (r8 is 2006)
merge 1:1 hhidpn using "randhrs1992_2020v1",keep(match) keepusing(raehsamp raestrat ragender raracem raeduc raedyrs r8* r9* r1?* *atotb *itot) nogen
merge 1:1 hhidpn using "h06f4a",keep(match) keepusing(klb001c klb001d klb001e) nogen //merge with 2006 travel data from left behind


/*Clean variables*/


*Travel
//venndiag klb001c klb001d klb001e,missing
//graph export "venn.tif",replace
gen trip=klb001e //local
replace trip=2 if klb001c==1 //Within US
replace trip=3 if klb001d==1 //aboard
replace trip=. if klb001c==. & klb001d==. & klb001e==. //missing when all 3 missing
replace trip=0 if klb001c==5 & klb001d==5 & klb001e==5 //no trip when all 3 no
recode trip (5=0) //cases local=0 but missing on Domestic & Aboard
lab define trip 0 "No trip" 1 "Local" 2 "Domestic" 3 "International"
lab values trip trip
drop if missing(trip)

*Cognitive function 27
foreach x of numlist 8/15 {
	rename r`x'cog27 cog`x'
}

*Loneliness
foreach x of numlist 8/15 {
	rename r`x'lblonely3 lonely`x'
}

*Cesd depression (also available in rand longitudinal as r8cesd)
foreach x of numlist 8/15 {
	rename r`x'cesd cesd`x'
}

*Social isolation


*Covariates
rename (r8agey_m) (age) //only use age at 2006, otherwise it is colinear with year
label var age "Age"
keep if age>50

recode ragender (1=0) (2=1),gen(women)
label define women 0 "Men" 1 "Women"
label values women women
label var women "Women"

rename (raracem) (race)
recode race (1=1) (2 3=0)
label define race 1 "White" 0 "Non-White"
label values race race
label var race "Race"

/*
rename (raeduc) (edu)
label define edu 1 "Lt high-school" 2 "GED" 3 "High school" 4 "Some college" 5 "College and above"
label values edu edu
label var edu "Education"
*/
rename raedyrs edu
label var edu "Education"


foreach x of numlist 8/15 {
	recode r`x'iadl5a (0=0) (1/5=1),gen(iadl`x')
	recode r`x'mstat (1 2 3=1) (4/8=0),gen(married`x')
	xtile wealth`x' = h`x'atotb,n(4)
	xtile income`x' = h`x'itot,n(4)
	} //IADL: any difficulty using a telephone, taking medication, handling money, shopping, preparing meals


*reshape wide to long
keep married* iadl* edu race women age cesd* lonely* cog* trip income* wealth* hhidpn raehsamp r8lbwgtr raestrat
reshape long married iadl income wealth cesd lonely cog, i(hhidpn) j(year)

recode year (8=0) (9=2) (10=4) (11=6) (12=8) (13=10) (14=12) (15=14)

lab var cesd "Depressive symptoms"
lab var lonely "Loneliness"
lab var cog "Cognitive function"
lab var iadl "IADL"
lab var married "Married"
lab var income "Household income"
lab var wealth "Household wealth"



************************************************************************
**# 2 Regressions
************************************************************************


*2006 only
preserve


keep if year==0
drop if missing(cog, lonely, cesd)
svyset raehsamp [pw=r8lbwgtr], strata(raestrat) //raehsamp and raestrat fix variance
desctable edu i.race i.women age i.married i.iadl i.income i.wealth cog lonely cesd, filename("descriptives") stats(svymean sd n) group(trip) listwise
foreach x in cog lonely cesd age {
	svy: reg `x' i.trip 
}
foreach x in edu race women married iadl income wealth {
    tab `x' trip, chi2 
}

pwcorr cog lonely cesd trip,sig

eststo clear
foreach x in cog lonely cesd {
	eststo `x'1 : reg `x' i.trip edu i.race i.women age i.married i.iadl i.income i.wealth ,vce(robust)
	eststo `x'2 : svy: reg `x' i.trip edu i.race i.women age i.married i.iadl i.income i.wealth
}
esttab *1 using "reg.csv",label replace b(%5.3f) se(%5.3f) r2 nogap compress nonum noomitted nobase noconstant
esttab *2 using "reg.csv",label append b(%5.3f) se(%5.3f) r2 nogap compress nonum noomitted nobase noconstant

foreach x in cog lonely cesd {
svy: reg `x' i.trip edu i.race i.women age i.married i.iadl i.income i.wealth
margins i.trip
mplotoffset, tit("") ytit("`: var label `x''",size(medlarge)) xtit("") xlab(,labsize(medlarge)) recastci(rarea) ciopt(color(%30)) legend(off) saving(`x',replace) 
}
graph combine "cog" "lonely" "cesd",imargin(0 0 0 0)
graph export "figure.tif", replace



restore



*Multilevel growth curve model (no sig when age>65)

mixed cog c.year##i.trip i.edu i.race i.women age i.married i.iadl i.income i.wealth || hhidpn : c.year, var cov(unstr) vce(robust)
margins i.trip, at(year= (0 (2) 14))
marginsplot, ytit("Cognitive function",size(medlarge)) xtit("Years since 2006",size(medlarge))
graph export "longitudinal.tif", replace


fre CIND Depression8_2_3 Age Sex Married Race Education WealthQt IncomeQt HBP Diabetes Lung Heart Arthritis Stroke Loneliness Isolation_1 TripGRPs
