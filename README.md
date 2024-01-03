# SHeS_Meat-disaggregation
Disaggregating meat out of composite foods consumed in the UK and then estimating meat consumption among adults in the 2021 Scottish Health Survey. Comparing these estimates with previous meat disaggregation estimates which used an older recipe database. 

## Files

### SHeS 2021_Meat disag
This do file combines our meat disaggregation dataset (containing the quantity of meat ingredients (g) per 100g of recipes) with dietary data from SHeS. Here, we calculate the total amount (g) of meat (total and animal types - beef, lamb, pork, poultry, other red meat, offal and game birds) for each food item based on the portion consumed. We also calculate the total amount (g) of meat (total and animal types) for each food item based on previous (existing) meat disaggregation estimates available in the SHeS dataset. 

We then create a food-level and participant-level dataset for SHeS combining survey weights with dietary data (inclusive of old and new meat disaggregation estimates). At the participant-level, mean daily intakes of meat (total and animal types) and mean per cent contribution of animal types (i.e. beef, lamb, pork, poultry, other red meat, offal and game birds) to meat intake are calculated, across both old and new disaggregation estimates. 

This do-file also contains descriptive analyses of meat intake to compare estimates across old and new disaggregation estimates.

#### Data files
Three files are needed to run this do-file:
- shes21_intake24_food-level_dietary_data_eul - Intake 24 diet data. There are multiple observations per participant, each observation corresponds to a food item reported.
- shes21i_eul - participant demographic survey data. There is only one observation per participant.
- NDB_SHeS_Disag_Meat_06122023.xlsx - meat disaggregation dataset 

#### Output
- diet_foodlevel_meatdisag_20231512.dta - this dataset has multiple observations for each participant, corresponding to each food item reported.
- diet_participantlevel_meatdisag_20231512.dta - this dataset has one observation for each participant.
