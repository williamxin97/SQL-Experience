This analysis completely omits customers who have been involuntarily terminated.
Attrition is counted as (voluntary attrition) / (customers who don't voluntarily attrite + voluntary attrition)

There are main steps to this analysis:

1. Find up-to-date information about all accounts
	- We need account close dates and close reasons
	- Account open dates is unnecessary, but included anyway
	- NOTE: This is the section that you need to change if you want to inlcude non-voluntary attrition.
		- 1_modified is an optional section that counts non-voluntary attrition as non-attrition.
		- Otherwise, non-voluntary attrition is completely excluded from the data.
2. Join complaints data and account information
	- This section is also necessary to get attrition data for control populations
3. Join to product segmentation data - which card product each account holds
	- Also joins mapped driver data
4. Filter by the first complaint by tier for each account per month, to avoid overrepresentation of heavy complainers
5. Create new variables, like time between complaint and account closure
6. Join to spend data for every account
7. Group spend data per account into time buckets, ie monthly, yearly, etc


iac_final is the final table. Here are what some of the fields created in (5) mean.
-	Com_m: month of complaint relative to ‘2019-01-01’. Can be ignored in favor of date_received
-	Open_m: month of opening date of the account relative to ‘2019-01-01’. 
-	Close_m: month of closing date of the account relative to ‘2019-01-01’
-	Com_dead_m: month of account close relative to complaint. Ex: 1 means that the account was closed within 1 month of complaining
-	Open_com_d: days between account open and complaint. Ex: -10 means that a complaint happened 10 days after account open
-	Com_dead_d: com_dead_m, but in days instead of months
-	Spend_12, spend_3, spend_1: past 12, 3, and 1 months of spend relative to the complaint date
-	Spend_12f, spend_3f, spend_1f: future 12, 3, and 1 months of spend relative to complaint date

