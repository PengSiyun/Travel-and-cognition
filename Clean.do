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
merge 1:1 hhidpn using "randhrs1992_2020v1",keep(match) keepusing(r8* r9* r1?*) nogen
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
lab define trip 0 "No trip" 1 "Local" 2 "Domestic" 3 "Aboard"
lab values trip trip
drop if missing(trip)

*Cognitive function 27
foreach x of numlist 8/15 {
	gen cogn`x' =r`x'tr20 + r`x'ser7 + r`x'bwc20
    recode cogn`x' (12/27=0) (0/11=1),gen(cogn`x'_b)
}
label define cogn_b 0 "Normal cognition" 1 "Possible CIND/dementia" 
label values cogn*_b cogn_b 
label var cogn*_b "Possible CIND/dementia" //cognition


*Loneliness
revrs klb020a-klb020c,replace  
alpha klb020a-klb020c,gen(lone06) 
label var lone06 "Loneliness" //lonely alpha=0.82

*Cesd depression (also available in rand longitudinal as r8cesd)
recode kd110-kd117 (5=0) (8 9=.)
recode kd113 kd115 (1=0) (0=1)
egen cesd06=rowtotal(kd110-kd117),mi
*klb027g-klb027r likert scale one in LB


*IADL from COVID paper
recode kg013 (1/10=1) (0=0),gen(msm16) //mobility, strength, motor skills
recode kg014 kg016 kg021 kg023 kg025 kg030 (1=1) (5=0) (6 7=1) (8 9=.)
egen adl06=rowtotal(kg014 kg016 kg021 kg023 kg025 kg030),mi
recode adl06 (0=0) (1/6=1)
recode kg041 kg044 kg047 kg050 kg059 (1=1) (5=0) (6 7=1) (8 9=.)
egen iadl06=rowtotal(kg041 kg044 kg047 kg050 kg059),mi
recode iadl06 (0=0) (1/5=1)
recode iadl06 (.=1) if adl06==1 //limitation in adl -> limitation in iadl
recode iadl06 (.=0) if msm16==0 //can jog a mile -> can prepare a meal

*Covariates
rename ka019 age
keep if age>50
lab var age "Age"

recode kx060_r (2=0),gen(men) 
lab var men "Men"
 i.Married i.Race Education i.WealthQt i.IncomeQt 

*reshape wide to long
reshape long


************************************************************************
**# 2 Regressions
************************************************************************


xtset hhidpn time
xtreg cog27 c.time##i.travel 06controls

*Multilevel growth curve model
mixed cog27 c.time##i.travel 06controls || hhidpn : time, var cov(unstr)

foreach x in cogtot27_imp2006 Depression8_2_3 Loneliness Isolation_1 {
	reg `x' i.TripGRPs age i.Sex i.Married i.Race Education i.WealthQt i.IncomeQt i.iadl06,vce(robust)

}

fre CIND Depression8_2_3 Age Sex Married Race Education WealthQt IncomeQt HBP Diabetes Lung Heart Arthritis Stroke Loneliness Isolation_1 TripGRPs
