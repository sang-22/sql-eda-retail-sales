# Data Dictionary

Table: `dbo.retail_sales` (clean table). The raw CSV column name is shown where it differs.

| Column | Type | Description | Notes |
|---|---|---|---|
| transaction_id | INT | Unique ID of the sale | Raw name: `transactions_id`. Primary key |
| sale_date | DATE | Date of the sale | 2022-01-01 to 2023-12-31 |
| sale_time | TIME | Time of the sale | Used to build shifts |
| customer_id | INT | Customer who made the purchase | 155 unique customers |
| gender | VARCHAR | Male / Female | |
| age | INT | Customer age | 18–64; 10 rows missing (kept as NULL) |
| category | VARCHAR | Product category | Clothing, Electronics, Beauty |
| quantity | INT | Units sold | Raw name: `quantiy` (typo). 1–4 |
| price_per_unit | DECIMAL | Price of one unit | Only 5 price points: 25, 30, 50, 300, 500 |
| cogs | DECIMAL | Cost of goods sold for the transaction | 70 rows where cogs > total_sale |
| total_sale | DECIMAL | Sale amount = quantity × price_per_unit | |
