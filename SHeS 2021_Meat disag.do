
******************************************************************
*Comparing estimates of meat intake with new vs old disaggregation

*Do file for merging meat disag file with SHeS 2021 diet data
******************************************************************


****************
*Clear settings
****************
clear matrix
macro drop _all
graph drop _all

*************************************************************
*Assign values using global macros for file location and date
*************************************************************
global location "K:\DrJaacksGroup\FSS - Dietary Monitoring\SHeS\SHeS 2021" 
global data `"$location\Data"'
global date "20231512"

*Intake24 diet data (multiple obeservations per participant, each observation = food item reported)
global diet `"$data\shes21_intake24_food-level_dietary_data_eul"'
*Demographic data
global dems `"$data\shes21i_eul"'
*Set maximum number of variables to 15,000
set maxvar 15000

*Import diet data
use "$diet", clear

	*Two items have two different food numbers - ensuring the food numbers match dairy disag file
	replace FoodNumber=10159 if FoodDescription=="Oat milk" & FoodNumber==10966 
	replace FoodNumber=821 if FoodDescription=="Savoury pastry (e.g. cheese pastry)" & FoodNumber==356

	*Save as separate diet data
	save "$data\diet_meatdisag_$date.dta", replace

**Import excel dairy disag file and convert to stata dta file
clear all
import excel using "$data\NDB_SHeS_Disag_Meat_06122023", firstrow	


***************************
*Check for duplicate items*
***************************
	
*Check for duplicates with same meat disag values
bysort FoodNumber Meat Beef Pork Lamb Other_Red_Meat Offal Poultry Game_Bird: gen n=_n
ta n 
*Drop duplocates
drop if n>1 /*511 duplicates*/
drop n
	
*Check for any duplicate FoodNumbers
bysort FoodNumber: gen n=_n
ta n /*no duplicates*/
drop n

***************************************
*Merge meat disag file with diet data*
***************************************

*Drop food description variables that are not needed
drop FoodDescription_NDB FoodDescription_SHeS FoodDescription_FSA

	*Merge disag dataset with Intake24 data
	sort FoodNumber
	merge 1:m FoodNumber using "$data\diet_meatdisag_$date.dta"
	
		*Drop items not in SHeS
		drop if _merge==1 /*465 items*/
		
		*Check items in SHeS that didn't match
		ta FoodDescription if _merge==2 /*198 all supplements - okay*/
		drop _merge
	
	*Check meat is fully disaggregated into meat subtypes
	gen meattotal=Beef + Pork + Lamb + Other_Red_Meat + Offal + Poultry + Game_Bird
	gen meatdiff=Meat-meattotal
	ta meatdiff  /*All fine*/
	drop meatdiff meattotal
	
*Drop nutrients not needed
drop Energykcal- OtherVegg WhiteFishg- OtherCheeseg


************************************************
*Merge with demographica data for survey weights
************************************************
merge m:1 Cpseriala using "$dems"
*Drop demographic data not needed
drop CHHSerialA-Bio IMode-Intake24Inv FoodEkcal-bio21wt


**********************************************************************************
*Tag each unique recall within the food-level dataset for subsequent calculations
**********************************************************************************
bysort Cpseriala RecallNo: gen n=_n==1
replace n=. if RecallNo==.


*********************************
*Dropping intake from supplements
*********************************
drop if RecipeMainFoodGroupCode==54 /*n=3,589*/


/********************************************************
Estimate g of meat in each item from new disag variables
********************************************************/
foreach var of varlist Meat- Game_Bird {
	gen `var'_g=(`var'/100)*TotalGrams	
}

		
*Label variables
foreach var of varlist Meat_g- Game_Bird_g {
		label variable `var' "new disaggregation - g per portion"
	}

	
/********************************
Create meat animal type variables 
*********************************/

/***First, re-categorising items within processed red meat, burgers, sausages and offal

Some assumptions:
1) assumed generic tongue is beef
2) assumed pate black pudding, and "meat" in tomato pasta dishes are pork (e.g. bacon)
*/

*Beef
gen Beef_Process_v1=0
replace Beef_Process_v1=ProcessedRedMeatg if (strpos(FoodDescription, "Pastrami") | strpos(FoodDescription, "Corned beef"))

gen Beef_Burgers_v1=0
replace Beef_Burgers_v1=Burgersg if (strpos(FoodDescription, "Lamb") | strpos(FoodDescription, "Hot dog"))==0

gen Beef_Sausages_v1=0
replace Beef_Sausages_v1=Sausagesg if strpos(FoodDescription, "Beef Sausage")

*Lamb
gen Lamb_Burgers_v1=0
replace Lamb_Burgers_v1=Burgersg if strpos(FoodDescription, "Lamb")

*Pork
gen Pork_Process_v1=0
replace Pork_Process_v1=ProcessedRedMeatg if Beef_Process==0

gen Pork_Burgers_v1=0
replace Pork_Burgers_v1=Burgersg if Beef_Burgers==0 & Lamb_Burgers==0

gen Pork_Sausages_v1=0
replace Pork_Sausages_v1=Sausagesg if Beef_Sausages==0 & (strpos(FoodDescription, "Chicken/turkey sausage") | strpos(FoodDescription, "Venison sausage"))==0

gen Pork_Other_v1=0
replace Pork_Other_v1=OtherRedMeatg if strpos(FoodDescription, "Meat risotto") /*Previously disag into beef and other red meat - changing to beef and pork*/

*Poultry
gen Poultry_Sausages_v1=0
replace Poultry_Sausages_v1=Sausagesg if strpos(FoodDescription, "Chicken/turkey sausage")

*Other red meat
gen OtherRedMeat_Sausages_v1=0
replace OtherRedMeat_Sausages_v1=Sausagesg if strpos(FoodDescription, "Venison sausage")

gen OtherRedMeat_Other_v1=0
replace OtherRedMeat_Other_v1=OtherRedMeatg if (strpos(FoodDescription, "Game pie") | strpos(FoodDescription, "Venison") | strpos(FoodDescription, "rabbit"))

*Offal
gen Offal_v1=0
replace Offal_v1=Offalg

*Game Birds
gen Gamebirds_v1=0
replace Gamebirds_v1=GameBirdsg

*Processed poultry
gen ProcessedPoultry_v1=0
replace ProcessedPoultry_v1=ProcessedPoultryg

*Replace values of those without recalls to missing
foreach var of varlist Beef_Process_v1 Beef_Burgers_v1 Beef_Sausages_v1 Lamb_Burgers_v1 Pork_Process_v1 Pork_Burgers_v1 Pork_Sausages_v1 Pork_Other_v1 Poultry_Sausages_v1 OtherRedMeat_Sausages_v1 OtherRedMeat_Other_v1 Offal_v1 Gamebirds_v1 ProcessedPoultry_v1{
	replace `var' =. if RecallNo==. 
}

/***********************************************************************
Calculate average daily intakes of meat from old and new disag variables
************************************************************************/

***Food level
	*Old disaggregation
	egen totalbeef_v1=rowtotal(Beefg Beef_Process_v1 Beef_Burgers_v1 Beef_Sausages_v1)
	egen totallamb_v1=rowtotal(Lambg Lamb_Burgers_v1)
	egen totalpork_v1=rowtotal(Porkg Pork_Process_v1 Pork_Burgers_v1 Pork_Sausages_v1 Pork_Other_v1)
	egen totalpoultry_v1=rowtotal(Poultryg ProcessedPoultry_v1 Poultry_Sausages_v1)
	egen totalotherred_v1=rowtotal(OtherRedMeat_Sausages_v1 OtherRedMeat_Other_v1)
	egen totaloffal_v1=rowtotal(Offal_v1)
	egen totalgamebirds_v1=rowtotal(Gamebirds_v1)

	egen totalmeat_v1=rowtotal(totalbeef_v1 totallamb_v1 totalpork_v1 totalpoultry_v1 totalotherred_v1 totaloffal_v1 totalgamebirds_v1)

	*New disaggregation
	egen totalbeef_v2=rowtotal(Beef_g)
	egen totallamb_v2=rowtotal(Lamb_g)
	egen totalpork_v2=rowtotal(Pork_g)
	egen totalpoultry_v2=rowtotal(Poultry_g)
	egen totalotherred_v2=rowtotal(Other_Red_Meat_g)
	egen totaloffal_v2=rowtotal(Offal_g)
	egen totalgamebirds_v2=rowtotal(Game_Bird_g)

	egen totalmeat_v2=rowtotal(totalbeef_v2 totallamb_v2 totalpork_v2 totalpoultry_v2 totalotherred_v2 totaloffal_v2 totalgamebirds_v2)


***Day level
	*Old disaggregation
	bysort Cpseriala RecallNo: egen Day_Beef_v1=sum(totalbeef_v1)
	bysort Cpseriala RecallNo: egen Day_Lamb_v1=sum(totallamb_v1)
	bysort Cpseriala RecallNo: egen Day_Pork_v1=sum(totalpork_v1)
	bysort Cpseriala RecallNo: egen Day_Poultry_v1=sum(totalpoultry_v1)
	bysort Cpseriala RecallNo: egen Day_OtherRed_v1=sum(totalotherred_v1)
	bysort Cpseriala RecallNo: egen Day_Offal_v1=sum(totaloffal_v1)
	bysort Cpseriala RecallNo: egen Day_GameBirds_v1=sum(totalgamebirds_v1)
	bysort Cpseriala RecallNo: egen Day_Totalmeat_v1=sum(totalmeat_v1)

	*New disaggregation
	bysort Cpseriala RecallNo: egen Day_Beef_v2=sum(totalbeef_v2)
	bysort Cpseriala RecallNo: egen Day_Lamb_v2=sum(totallamb_v2)
	bysort Cpseriala RecallNo: egen Day_Pork_v2=sum(totalpork_v2)
	bysort Cpseriala RecallNo: egen Day_Poultry_v2=sum(totalpoultry_v2)
	bysort Cpseriala RecallNo: egen Day_OtherRed_v2=sum(totalotherred_v2)
	bysort Cpseriala RecallNo: egen Day_Offal_v2=sum(totaloffal_v2)
	bysort Cpseriala RecallNo: egen Day_GameBirds_v2=sum(totalgamebirds_v2)
	bysort Cpseriala RecallNo: egen Day_Totalmeat_v2=sum(totalmeat_v2)

***Calculate mean daily intakes of meat from old and new disaggregation
*Set local macro
ds Day_* 
local dayvalues `r(varlist)'

*Loop through each daily value
foreach var of varlist `dayvalues' {
	bysort Cpseriala RecallNo: egen DayMax_`var' =max(`var') /*daily intake*/
    bysort Cpseriala: egen Wk_`var' = total(DayMax_`var') if n==1 /*total intake across all days*/
	bysort Cpseriala: egen WkMax_`var' = max(Wk_`var') /*filling in total intake across all days across all observations*/
	bysort Cpseriala: gen Avg_`var' = (WkMax_`var'/NumberOfRecalls) /*mean daily intake*/
	drop DayMax_`var' Wk_`var' WkMax_`var'
}



**************
*Save datasets
**************

*Food level dataset
save "$data\diet_foodlevel_meatdisag_$date.dta", replace
*Participant level dataset for analysis (drop duplicates and unecessary food level variables)
duplicates drop Cpseriala, force
drop n Meat_g- Day_Totalmeat_v2
save "$data\diet_participantlevel_meatdisag_$date.dta", replace


****************************************
*Create subpop variable for analysis
****************************************
*Completed at least 1 recall
gen intake24=0
replace intake24=1 if InIntake24==1

*Assign survey sampling variables
svyset [pweight=SHeS_Intake24_wt_sc], psu(psu) strata(Strata)


*******************************************************
*Compare intake estimates of old and new disaggregation
*******************************************************
*Old estimates
svy, subpop(intake24): mean Avg_Day_Totalmeat_v1 Avg_Day_Beef_v1 Avg_Day_Lamb_v1 Avg_Day_Pork_v1 Avg_Day_Poultry_v1 Avg_Day_OtherRed_v1 Avg_Day_Offal_v1 Avg_Day_GameBirds_v1 

*New estimates
svy, subpop(intake24): mean Avg_Day_Totalmeat_v2 Avg_Day_Beef_v2 Avg_Day_Lamb_v2 Avg_Day_Pork_v2 Avg_Day_Poultry_v2 Avg_Day_OtherRed_v2 Avg_Day_Offal_v2 Avg_Day_GameBirds_v2 


**********************************************************************************
*Explore differences in how meat types have been coded between old and new methods
**********************************************************************************
*Read in food level data
use "$data\diet_foodlevel_meatdisag_$date.dta", clear

*Look at number of unique food items coded according to meat type
duplicates drop FoodDescription, force


*Beef
ta RecipeMainFoodGroupDesc if Beefg>0 & Beefg!=. /*7 main food groups; 94 items*/
ta RecipeMainFoodGroupDesc if Beef_g>0 & Beef_g!=. /*10 main food groups; 125 items*/

*Lamb
ta RecipeMainFoodGroupDesc if Lambg>0 & Lambg!=. /*5 main food groups; 35 items*/
ta RecipeMainFoodGroupDesc if Lamb_g>0 & Lamb_g!=. /*4 main food groups; 44 items*/

*Pork
ta RecipeMainFoodGroupDesc if Porkg>0 & Porkg!=. /*5 main food groups; 38 items*/
ta RecipeMainFoodGroupDesc if Pork_g>0 & Pork_g!=. /*20 main food groups; 179 items*/

*Poultry
ta RecipeMainFoodGroupDesc if Poultryg>0 & Poultryg!=. /*8 main food groups; 146 items*/
ta RecipeMainFoodGroupDesc if Poultry_g>0 & Poultry_g!=. /*15 main food groups; 198 items*/

*Other red meat
ta RecipeMainFoodGroupDesc if OtherRedMeatg>0 & OtherRedMeatg!=. /*3 main food groups; 4 items*/
ta RecipeMainFoodGroupDesc if Other_Red_Meat_g>0 & Other_Red_Meat_g!=. /*3 main food groups; 4 items*/

*Offal
ta RecipeMainFoodGroupDesc if Offalg>0 & Offalg!=. /*3 main food groups; 16 items*/
ta RecipeMainFoodGroupDesc if Offal_g>0 & Offal_g!=. /*4 main food groups; 16 items*/

*Game birds
ta RecipeMainFoodGroupDesc if GameBirdsg>0 & GameBirdsg!=. /*4 main food groups; 7 items*/
ta RecipeMainFoodGroupDesc if Game_Bird_g>0 & Game_Bird_g!=. /*4 main food groups; 8 items*/
