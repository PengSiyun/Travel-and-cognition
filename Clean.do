****Priject: Travel and cognition
****Author:  Siyun Peng
****Date:    2023/07/12
****Version: 17
****Purpose: Data Cleaning 



************************************************************************
**# 1 Merge/clean data 
************************************************************************


cd "C:\Users\peng_admin\OneDrive - Indiana University\Work with Shu"
import spss CIND Depression8_2_3 Age Sex Married Race Education WealthQt IncomeQt HBP Diabetes Lung Heart Arthritis Stroke Loneliness Isolation_1 TripGRPs using "h06f3a_FinalAnalysisBBB",clear
fre CIND Depression8_2_3 Age Sex Married Race Education WealthQt IncomeQt HBP Diabetes Lung Heart Arthritis Stroke Loneliness Isolation_1 TripGRPs

use "randhrs1992_2020v1",clear