# Retail Sales Analysis | SQL Server EDA

Exploratory data analysis of 2 years of retail transactions (Jan 2022 – Dec 2023) using **Microsoft SQL Server**. The project covers loading raw CSV data, cleaning it, profiling it and answering business questions about sales trends, categories, customers and timing.

---

## Business Problem

A retail store sells **Clothing, Electronics and Beauty** products. Management wants to know:

- How are sales trending month to month and year to year?
- Which categories drive revenue and profit?
- Who are the most valuable customers, and how concentrated is revenue?
- When do customers shop: which months, days and times of day?
- How do age and gender affect buying behaviour?

## Dataset

| Item | Detail |
|---|---|
| File | `data/raw/retail_sales.csv` |
| Rows | 2,000 raw → 1,997 after cleaning |
| Columns | 11 (see [data dictionary](data/data_dictionary.md)) |
| Period | 1 Jan 2022 – 31 Dec 2023 |
| Customers | 155 unique |

Amounts are shown in ₹ (the source data has no currency).

## Tools

- Microsoft SQL Server 2022 
- SQL Server Management Studio (SSMS)


## Project Structure

```
sql-eda-retail-sales/
├── README.md
├── data/
│   ├── raw/retail_sales.csv
│   └── data_dictionary.md
├── sql/
│   ├── 01_create_database_and_tables.sql   -- database, staging & clean tables
│   ├── 02_load_data.sql                    -- BULK INSERT the CSV
│   ├── 03_data_cleaning.sql                -- quality checks + clean load
│   ├── 04_data_profiling.sql               -- shape of the data, KPIs
│   ├── 05_eda_analysis.sql                 -- trends, categories, customers, demographics
│   └── 06_business_insights.sql            -- 40 business questions (basic → advanced)
├── findings/
│   └── insights_summary.md
└── images/                                 -- charts / dashboard screenshots
```

## Approach

1. **Load:** CSV loaded into an all-text staging table so nothing fails on import.
2. **Clean:** checked duplicates, missing values, type conversion, spelling variants and the `quantity × price = total_sale` rule.
   - Removed **3 rows** with no quantity, price, cogs or sale amount.
   - Kept **10 rows** with missing age (valid sales), excluded only from age analysis.
   - Fixed data types, trimmed text, renamed the misspelled `quantiy` column to `quantity`.
   - Flagged **70 loss-making transactions** (cogs > sale) instead of deleting them.
3. **Profile:** row counts, date range, KPIs, distributions.
4. **Analyse:** sales trends, category performance, customer value, demographics.
5. **Report:** 40 business questions (basic → advanced) answered, plus a view (`vw_sales_summary`) ready for Power BI.

## SQL Skills Used

`CTEs` · `Window functions (LAG, RANK, DENSE_RANK, ROW_NUMBER, NTILE, PERCENT_RANK, SUM/AVG OVER)` · `Running totals & moving averages` · `Self-joins` · `Cohort & retention analysis` · `RFM segmentation` · `CASE WHEN` · `GROUP BY / HAVING` · `Subqueries` · `Date functions (DATEPART, DATENAME, DATEFROMPARTS, DATEDIFF)` · `TRY_CAST` · `BULK INSERT` · `Views`

## Business Questions (Basic → Advanced)

All 40 questions are answered in [`sql/06_business_insights.sql`](sql/06_business_insights.sql).

### Level 1: Basic (SELECT, WHERE, GROUP BY, aggregates)
1. How many transactions are in the data?
2. What is the total revenue and how many units were sold?
3. How many unique customers do we have?
4. Which product categories do we sell?
5. Show all sales made on 2022-11-05.
6. Show Clothing sales with 4 or more units in November 2022.
7. What is the total revenue and order count for each category?
8. What is the average age of Beauty customers?
9. How many transactions had a sale amount above 1,000?
10. How many transactions did each gender make in each category?
11. What are the highest and lowest single sale amounts?
12. How many orders and how much revenue came in each year?

### Level 2: Intermediate (HAVING, CASE, CTEs, subqueries, RANK)
13. Which month had the highest average sale in each year?
14. Who are the top 5 customers by total spend?
15. How many unique customers bought from each category?
16. How many orders come in each shift (morning / afternoon / evening)?
17. What share of revenue does each quarter bring?
18. Do weekends sell more than weekdays?
19. What is the gross profit and margin for each category?
20. Which customers placed 15 or more orders?
21. How many customers bought from all 3 categories?
22. Which age group has the highest average order value?
23. How much revenue does each price point bring (premium vs budget)?
24. Which transactions were sold below cost, and how much was lost?
25. Which customers spend more than the average customer?
26. What is the busiest hour of the day?

### Level 3: Advanced (window frames, cohorts, retention, segmentation)
27. Month-over-month revenue growth (`LAG`)
28. Each month vs the same month last year (self-join)
29. Year-to-date running revenue (`SUM OVER` with frame)
30. 3-month moving average of revenue
31. Top category in each month and how often each category wins (`ROW_NUMBER`)
32. Busiest hour for each category
33. Pareto: how many customers make up 50% and 80% of revenue?
34. Customer value tiers with `PERCENT_RANK`
35. Cohort: new customers by first-purchase month
36. Retention: how many 2022 customers came back in 2023?
37. Average gap in days between a customer's purchases
38. Churn risk: customers who spent less in 2023 than in 2022
39. RFM segmentation (Recency, Frequency, Monetary)
40. Reusable reporting view for Power BI

## Key Insights

| KPI | Value |
|---|---|
| Total revenue | ₹9,11,720 |
| Gross profit | ₹7,21,957 (79.2% margin) |
| Orders | 1,997 |
| Average order value | ₹457 |
| Customers | 155 (all repeat buyers) |

**Sales and seasonality**
1. **Growth is flat.** Revenue grew only **1.3%** from 2022 (₹4,52,825) to 2023 (₹4,58,895).
2. **Sep–Dec is peak season.** Q4 brings **43% of revenue**, and December 2022 was the best month (₹72,880).
3. **But the peak season got weaker in 2023.** October (−15%), November (−17%) and December (−5%) all fell compared with 2022. The small overall growth came from February (+56%) and July (+62%).
4. **Evenings are the busiest.** **53% of orders** happen after 5 PM, and 7 PM is the single busiest hour.
5. **Weekends sell more.** A weekend selling day brings about **15% more revenue** than a weekday (₹1,554 vs ₹1,349).

**Products**
6. **Categories are evenly balanced.** Electronics (34.4%), Clothing (34.1%) and Beauty (31.5%). Clothing was the top category in 10 of 24 months.
7. **Premium items drive the business.** The two premium price points (₹300 and ₹500) bring **88% of revenue**.
8. **70 sales were below cost**, losing ₹1,713 in total, mostly in Electronics and Clothing.

**Customers**
9. **No new customers in 2023.** All 155 customers made their first purchase in 2022, mostly in the first 3 months.
10. **Retention is strong but spend is dropping.** 95% of 2022 customers came back in 2023, but **90 customers spent less**, and 59 of them cut their spend by more than half.
11. **Revenue is spread out.** 38 customers make up half of revenue, and 85 make up 80%, so this is not a classic 80/20 pattern.
12. **Customers return about every 48 days**, and 128 of 155 have bought from all 3 categories.
13. **Younger customers spend more per order.** The 18–25 group has the highest average order value (₹503) vs ₹413 for 56+.

## Recommendations

- **Win new customers.** With zero new customers in 2023, growth depends on a shrinking base. Run acquisition campaigns and referral offers.
- **Win back the 59 high-risk customers** with personalised offers before they stop buying.
- **Protect the festive season.** Find out why Oct–Nov 2023 fell (stock, pricing, competition) and plan Q4 stock and staffing early.
- **Use evenings and weekends** for promotions, and afternoon offers to lift the slowest shift.
- **Focus on premium items** and the **18–25 segment**, who spend the most per order.
- **Review the 70 loss-making sales** for pricing or discount mistakes.

## Sample Query: Month-over-Month Growth

```sql
WITH monthly AS (
    SELECT DATEFROMPARTS(YEAR(sale_date), MONTH(sale_date), 1) AS month_start,
           SUM(total_sale) AS revenue
    FROM dbo.retail_sales
    GROUP BY DATEFROMPARTS(YEAR(sale_date), MONTH(sale_date), 1)
)
SELECT FORMAT(month_start, 'yyyy-MM') AS sale_month,
       revenue,
       LAG(revenue) OVER (ORDER BY month_start) AS prev_month_revenue,
       CAST((revenue - LAG(revenue) OVER (ORDER BY month_start)) * 100.0
            / LAG(revenue) OVER (ORDER BY month_start) AS DECIMAL(6,2)) AS mom_growth_pct
FROM monthly
ORDER BY month_start;
```

## How to Run

1. Clone this repo.
2. Open SSMS and run the scripts in `sql/` **in order (01 → 06)**.
3. In `02_load_data.sql`, change the file path to where `retail_sales.csv` is on your machine. If `BULK INSERT` gives a permission error, use **Tasks → Import Flat File** in SSMS instead (steps are in the script).

## Author

**Santosh Gundumalla**: Data Analyst / BI Developer 
[LinkedIn](https://www.linkedin.com/in/gundumallasantosh/) · [GitHub](https://github.com/sang-22)
