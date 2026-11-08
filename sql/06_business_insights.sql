/* =====================================================================
   File   : 06_business_insights.sql
   Purpose: 40 business questions, from basic to advanced
   Levels : BASIC        (Q1  - Q12)  SELECT, WHERE, GROUP BY, aggregates
            INTERMEDIATE (Q13 - Q26)  HAVING, CASE, CTEs, subqueries, RANK
            ADVANCED     (Q27 - Q40)  window frames, cohorts, retention,
                                      RFM, Pareto, YoY, reporting view
   ===================================================================== */

USE RetailSalesDB;
GO


/* #####################################################################
   LEVEL 1: BASIC
   ##################################################################### */

-- Q1. How many transactions are in the data?
SELECT COUNT(*) AS total_transactions
FROM dbo.retail_sales;

-- Q2. What is the total revenue and how many units were sold?
SELECT SUM(total_sale) AS total_revenue,
       SUM(quantity)   AS total_units
FROM dbo.retail_sales;

-- Q3. How many unique customers do we have?
SELECT COUNT(DISTINCT customer_id) AS unique_customers
FROM dbo.retail_sales;

-- Q4. Which product categories do we sell?
SELECT DISTINCT category
FROM dbo.retail_sales
ORDER BY category;

-- Q5. Show all sales made on 2022-11-05.
SELECT *
FROM dbo.retail_sales
WHERE sale_date = '2022-11-05';

-- Q6. Show Clothing sales with 4 or more units in November 2022.
SELECT *
FROM dbo.retail_sales
WHERE category = 'Clothing'
  AND quantity >= 4
  AND sale_date >= '2022-11-01' AND sale_date < '2022-12-01';

-- Q7. What is the total revenue and order count for each category?
SELECT category,
       SUM(total_sale) AS revenue,
       COUNT(*)        AS orders
FROM dbo.retail_sales
GROUP BY category
ORDER BY revenue DESC;

-- Q8. What is the average age of customers who bought Beauty products?
SELECT CAST(AVG(age * 1.0) AS DECIMAL(5,2)) AS avg_age_beauty
FROM dbo.retail_sales
WHERE category = 'Beauty'
  AND age IS NOT NULL;

-- Q9. How many transactions had a sale amount above 1,000?
SELECT COUNT(*)        AS high_value_orders,
       SUM(total_sale) AS high_value_revenue
FROM dbo.retail_sales
WHERE total_sale > 1000;

-- Q10. How many transactions did each gender make in each category?
SELECT category, gender, COUNT(*) AS transactions
FROM dbo.retail_sales
GROUP BY category, gender
ORDER BY category, gender;

-- Q11. What are the highest and lowest single sale amounts?
SELECT MAX(total_sale) AS highest_sale,
       MIN(total_sale) AS lowest_sale,
       CAST(AVG(total_sale) AS DECIMAL(10,2)) AS average_sale
FROM dbo.retail_sales;

-- Q12. How many orders and how much revenue came in each year?
SELECT YEAR(sale_date)  AS sale_year,
       COUNT(*)         AS orders,
       SUM(total_sale)  AS revenue
FROM dbo.retail_sales
GROUP BY YEAR(sale_date)
ORDER BY sale_year;


/* #####################################################################
   LEVEL 2: INTERMEDIATE
   ##################################################################### */

-- Q13. Which month had the highest average sale in each year?
WITH monthly AS (
    SELECT YEAR(sale_date)  AS sale_year,
           MONTH(sale_date) AS sale_month,
           CAST(AVG(total_sale) AS DECIMAL(10,2)) AS avg_sale,
           RANK() OVER (PARTITION BY YEAR(sale_date)
                        ORDER BY AVG(total_sale) DESC) AS rnk
    FROM dbo.retail_sales
    GROUP BY YEAR(sale_date), MONTH(sale_date)
)
SELECT sale_year,
       DATENAME(MONTH, DATEFROMPARTS(sale_year, sale_month, 1)) AS month_name,
       avg_sale
FROM monthly
WHERE rnk = 1;

-- Q14. Who are the top 5 customers by total spend?
SELECT TOP (5)
       customer_id,
       COUNT(*)        AS orders,
       SUM(total_sale) AS total_spend
FROM dbo.retail_sales
GROUP BY customer_id
ORDER BY total_spend DESC;

-- Q15. How many unique customers bought from each category?
SELECT category, COUNT(DISTINCT customer_id) AS unique_customers
FROM dbo.retail_sales
GROUP BY category;

-- Q16. How many orders come in each shift? (Morning < 12, Afternoon 12-17, Evening > 17)
WITH shifts AS (
    SELECT *,
           CASE WHEN DATEPART(HOUR, sale_time) < 12 THEN 'Morning'
                WHEN DATEPART(HOUR, sale_time) BETWEEN 12 AND 17 THEN 'Afternoon'
                ELSE 'Evening' END AS shift
    FROM dbo.retail_sales
)
SELECT shift,
       COUNT(*)        AS orders,
       SUM(total_sale) AS revenue
FROM shifts
GROUP BY shift
ORDER BY orders DESC;

-- Q17. What share of revenue does each quarter bring? (festive season check)
SELECT DATEPART(QUARTER, sale_date) AS sale_quarter,
       SUM(total_sale) AS revenue,
       CAST(SUM(total_sale) * 100.0
            / SUM(SUM(total_sale)) OVER () AS DECIMAL(5,2)) AS share_pct
FROM dbo.retail_sales
GROUP BY DATEPART(QUARTER, sale_date)
ORDER BY sale_quarter;

-- Q18. Do weekends sell more than weekdays? (average revenue per day)
WITH daily AS (
    SELECT sale_date,
           CASE WHEN DATENAME(WEEKDAY, sale_date) IN ('Saturday', 'Sunday')
                THEN 'Weekend' ELSE 'Weekday' END AS day_type,
           SUM(total_sale) AS revenue
    FROM dbo.retail_sales
    GROUP BY sale_date
)
SELECT day_type,
       COUNT(*)                          AS selling_days,
       SUM(revenue)                      AS revenue,
       CAST(AVG(revenue) AS DECIMAL(10,2)) AS avg_revenue_per_selling_day
FROM daily
GROUP BY day_type;

-- Q19. What is the gross profit and margin for each category?
SELECT category,
       SUM(total_sale)             AS revenue,
       SUM(cogs)                   AS cogs,
       SUM(total_sale) - SUM(cogs) AS gross_profit,
       CAST((SUM(total_sale) - SUM(cogs)) * 100.0
            / SUM(total_sale) AS DECIMAL(5,2)) AS margin_pct
FROM dbo.retail_sales
GROUP BY category
ORDER BY gross_profit DESC;

-- Q20. Which customers placed 15 or more orders?
SELECT customer_id,
       COUNT(*)        AS orders,
       SUM(total_sale) AS total_spend
FROM dbo.retail_sales
GROUP BY customer_id
HAVING COUNT(*) >= 15
ORDER BY orders DESC;

-- Q21. How many customers bought from all 3 categories?
SELECT COUNT(*) AS customers_all_categories
FROM (
    SELECT customer_id
    FROM dbo.retail_sales
    GROUP BY customer_id
    HAVING COUNT(DISTINCT category) = 3
) AS t;

-- Q22. Which age group has the highest average order value?
WITH aged AS (
    SELECT *,
           CASE WHEN age BETWEEN 18 AND 25 THEN '18-25'
                WHEN age BETWEEN 26 AND 35 THEN '26-35'
                WHEN age BETWEEN 36 AND 45 THEN '36-45'
                WHEN age BETWEEN 46 AND 55 THEN '46-55'
                ELSE '56+' END AS age_group
    FROM dbo.retail_sales
    WHERE age IS NOT NULL
)
SELECT age_group,
       COUNT(*)        AS orders,
       SUM(total_sale) AS revenue,
       CAST(AVG(total_sale) AS DECIMAL(10,2)) AS avg_order_value
FROM aged
GROUP BY age_group
ORDER BY avg_order_value DESC;

-- Q23. How much revenue does each price point bring? (premium vs budget items)
SELECT price_per_unit,
       CASE WHEN price_per_unit >= 300 THEN 'Premium' ELSE 'Budget' END AS price_band,
       COUNT(*)        AS orders,
       SUM(total_sale) AS revenue,
       CAST(SUM(total_sale) * 100.0
            / SUM(SUM(total_sale)) OVER () AS DECIMAL(5,2)) AS revenue_share_pct
FROM dbo.retail_sales
GROUP BY price_per_unit
ORDER BY price_per_unit DESC;

-- Q24. Which transactions were sold below cost, and how much was lost per category?
SELECT category,
       COUNT(*)               AS loss_orders,
       SUM(cogs - total_sale) AS total_loss
FROM dbo.retail_sales
WHERE cogs > total_sale
GROUP BY category
ORDER BY total_loss DESC;

-- Q25. Which customers spend more than the average customer? (subquery)
SELECT customer_id, SUM(total_sale) AS total_spend
FROM dbo.retail_sales
GROUP BY customer_id
HAVING SUM(total_sale) > (
    SELECT AVG(customer_spend)
    FROM (SELECT SUM(total_sale) AS customer_spend
          FROM dbo.retail_sales
          GROUP BY customer_id) AS c
)
ORDER BY total_spend DESC;

-- Q26. What is the busiest hour of the day?
SELECT TOP (1) WITH TIES
       DATEPART(HOUR, sale_time) AS sale_hour,
       COUNT(*)                  AS orders
FROM dbo.retail_sales
GROUP BY DATEPART(HOUR, sale_time)
ORDER BY orders DESC;


/* #####################################################################
   LEVEL 3: ADVANCED
   ##################################################################### */

-- Q27. What is the month-over-month revenue growth? (LAG)
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

-- Q28. Compare each month with the same month last year (YoY by month).
WITH monthly AS (
    SELECT YEAR(sale_date) AS sale_year, MONTH(sale_date) AS sale_month,
           SUM(total_sale) AS revenue
    FROM dbo.retail_sales
    GROUP BY YEAR(sale_date), MONTH(sale_date)
)
SELECT cur.sale_month,
       DATENAME(MONTH, DATEFROMPARTS(2023, cur.sale_month, 1)) AS month_name,
       prev.revenue AS revenue_2022,
       cur.revenue  AS revenue_2023,
       CAST((cur.revenue - prev.revenue) * 100.0 / prev.revenue AS DECIMAL(6,2)) AS yoy_growth_pct
FROM monthly AS cur
JOIN monthly AS prev
  ON prev.sale_month = cur.sale_month
 AND prev.sale_year  = cur.sale_year - 1
ORDER BY cur.sale_month;

-- Q29. What is the year-to-date running revenue? (SUM OVER with frame)
WITH monthly AS (
    SELECT YEAR(sale_date) AS sale_year, MONTH(sale_date) AS sale_month,
           SUM(total_sale) AS revenue
    FROM dbo.retail_sales
    GROUP BY YEAR(sale_date), MONTH(sale_date)
)
SELECT sale_year, sale_month, revenue,
       SUM(revenue) OVER (PARTITION BY sale_year ORDER BY sale_month
                          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS ytd_revenue
FROM monthly
ORDER BY sale_year, sale_month;

-- Q30. What is the 3-month moving average of revenue? (smooths out spikes)
WITH monthly AS (
    SELECT DATEFROMPARTS(YEAR(sale_date), MONTH(sale_date), 1) AS month_start,
           SUM(total_sale) AS revenue
    FROM dbo.retail_sales
    GROUP BY DATEFROMPARTS(YEAR(sale_date), MONTH(sale_date), 1)
)
SELECT FORMAT(month_start, 'yyyy-MM') AS sale_month,
       revenue,
       CAST(AVG(revenue) OVER (ORDER BY month_start
                               ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS DECIMAL(10,2)) AS moving_avg_3m
FROM monthly
ORDER BY month_start;

-- Q31. Which category won each month, and how often does each category win?
WITH cat_month AS (
    SELECT DATEFROMPARTS(YEAR(sale_date), MONTH(sale_date), 1) AS month_start,
           category,
           SUM(total_sale) AS revenue,
           ROW_NUMBER() OVER (PARTITION BY DATEFROMPARTS(YEAR(sale_date), MONTH(sale_date), 1)
                              ORDER BY SUM(total_sale) DESC) AS rn
    FROM dbo.retail_sales
    GROUP BY DATEFROMPARTS(YEAR(sale_date), MONTH(sale_date), 1), category
)
SELECT category, COUNT(*) AS months_as_top_category
FROM cat_month
WHERE rn = 1
GROUP BY category
ORDER BY months_as_top_category DESC;

-- Q32. What is the busiest hour for each category?
WITH cat_hour AS (
    SELECT category,
           DATEPART(HOUR, sale_time) AS sale_hour,
           COUNT(*) AS orders,
           RANK() OVER (PARTITION BY category ORDER BY COUNT(*) DESC) AS rnk
    FROM dbo.retail_sales
    GROUP BY category, DATEPART(HOUR, sale_time)
)
SELECT category, sale_hour, orders
FROM cat_hour
WHERE rnk = 1;

-- Q33. Pareto: how many customers make up 50% and 80% of revenue?
WITH cust AS (
    SELECT customer_id, SUM(total_sale) AS revenue
    FROM dbo.retail_sales
    GROUP BY customer_id
),
cumulative AS (
    SELECT customer_id, revenue,
           ROW_NUMBER() OVER (ORDER BY revenue DESC) AS customer_rank,
           SUM(revenue) OVER (ORDER BY revenue DESC, customer_id
                              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) * 100.0
           / SUM(revenue) OVER () AS cumulative_pct
    FROM cust
)
SELECT
    MIN(CASE WHEN cumulative_pct >= 50 THEN customer_rank END) AS customers_for_50_pct,
    MIN(CASE WHEN cumulative_pct >= 80 THEN customer_rank END) AS customers_for_80_pct,
    COUNT(*)                                                    AS total_customers
FROM cumulative;

-- Q34. Customer value tiers using PERCENT_RANK
WITH cust AS (
    SELECT customer_id, SUM(total_sale) AS total_spend
    FROM dbo.retail_sales
    GROUP BY customer_id
)
SELECT customer_id, total_spend,
       CAST(PERCENT_RANK() OVER (ORDER BY total_spend) * 100 AS DECIMAL(5,2)) AS percentile,
       CASE WHEN PERCENT_RANK() OVER (ORDER BY total_spend) >= 0.90 THEN 'Platinum (top 10%)'
            WHEN PERCENT_RANK() OVER (ORDER BY total_spend) >= 0.70 THEN 'Gold'
            WHEN PERCENT_RANK() OVER (ORDER BY total_spend) >= 0.40 THEN 'Silver'
            ELSE 'Bronze' END AS tier
FROM cust
ORDER BY total_spend DESC;

-- Q35. Cohort: in which month did each customer make their first purchase?
WITH first_purchase AS (
    SELECT customer_id, MIN(sale_date) AS first_date
    FROM dbo.retail_sales
    GROUP BY customer_id
)
SELECT FORMAT(first_date, 'yyyy-MM') AS cohort_month,
       COUNT(*) AS new_customers,
       SUM(COUNT(*)) OVER (ORDER BY FORMAT(first_date, 'yyyy-MM')) AS cumulative_customers
FROM first_purchase
GROUP BY FORMAT(first_date, 'yyyy-MM')
ORDER BY cohort_month;

-- Q36. Retention: how many 2022 customers came back in 2023?
WITH c2022 AS (SELECT DISTINCT customer_id FROM dbo.retail_sales WHERE YEAR(sale_date) = 2022),
     c2023 AS (SELECT DISTINCT customer_id FROM dbo.retail_sales WHERE YEAR(sale_date) = 2023)
SELECT COUNT(*)                         AS customers_2022,
       COUNT(c2023.customer_id)         AS returned_2023,
       CAST(COUNT(c2023.customer_id) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS retention_pct
FROM c2022
LEFT JOIN c2023 ON c2023.customer_id = c2022.customer_id;

-- Q37. What is the average gap (in days) between a customer's purchases?
WITH gaps AS (
    SELECT customer_id,
           DATEDIFF(DAY,
                    LAG(sale_date) OVER (PARTITION BY customer_id ORDER BY sale_date, sale_time),
                    sale_date) AS days_since_last
    FROM dbo.retail_sales
)
SELECT CAST(AVG(days_since_last * 1.0) AS DECIMAL(6,2)) AS avg_days_between_purchases
FROM gaps
WHERE days_since_last IS NOT NULL;

-- Q38. Churn risk: which customers spent less in 2023 than in 2022?
WITH yearly AS (
    SELECT customer_id,
           SUM(CASE WHEN YEAR(sale_date) = 2022 THEN total_sale ELSE 0 END) AS spend_2022,
           SUM(CASE WHEN YEAR(sale_date) = 2023 THEN total_sale ELSE 0 END) AS spend_2023
    FROM dbo.retail_sales
    GROUP BY customer_id
)
SELECT customer_id, spend_2022, spend_2023,
       CAST((spend_2023 - spend_2022) * 100.0 / NULLIF(spend_2022, 0) AS DECIMAL(6,2)) AS change_pct,
       CASE WHEN spend_2023 < spend_2022 * 0.5 THEN 'High risk (dropped > 50%)'
            ELSE 'Watch' END AS risk_level
FROM yearly
WHERE spend_2023 < spend_2022
ORDER BY change_pct;

-- Q39. RFM segmentation (Recency, Frequency, Monetary)
WITH rfm AS (
    SELECT customer_id,
           DATEDIFF(DAY, MAX(sale_date),
                    (SELECT MAX(sale_date) FROM dbo.retail_sales)) AS recency_days,
           COUNT(*)        AS frequency,
           SUM(total_sale) AS monetary
    FROM dbo.retail_sales
    GROUP BY customer_id
),
scored AS (
    SELECT *,
           NTILE(3) OVER (ORDER BY recency_days DESC) AS r_score,   -- 3 = most recent
           NTILE(3) OVER (ORDER BY frequency)         AS f_score,   -- 3 = most frequent
           NTILE(3) OVER (ORDER BY monetary)          AS m_score    -- 3 = highest spend
    FROM rfm
),
segmented AS (
    SELECT *,
           CASE WHEN r_score = 3 AND f_score = 3 AND m_score = 3 THEN 'Champion'
                WHEN f_score >= 2 AND m_score >= 2               THEN 'Loyal'
                WHEN r_score = 1                                 THEN 'At Risk'
                ELSE 'Regular' END AS segment
    FROM scored
)
SELECT segment,
       COUNT(*)      AS customers,
       SUM(monetary) AS revenue,
       CAST(AVG(recency_days * 1.0) AS DECIMAL(6,1)) AS avg_recency_days
FROM segmented
GROUP BY segment
ORDER BY revenue DESC;

-- Q40. Create a reusable reporting view for Power BI
GO
CREATE OR ALTER VIEW dbo.vw_sales_summary AS
SELECT transaction_id,
       sale_date,
       YEAR(sale_date)              AS sale_year,
       MONTH(sale_date)             AS sale_month,
       DATEPART(QUARTER, sale_date) AS sale_quarter,
       DATENAME(WEEKDAY, sale_date) AS day_name,
       CASE WHEN DATEPART(HOUR, sale_time) < 12 THEN 'Morning'
            WHEN DATEPART(HOUR, sale_time) BETWEEN 12 AND 17 THEN 'Afternoon'
            ELSE 'Evening' END      AS shift,
       customer_id, gender, age, category, quantity, price_per_unit,
       cogs, total_sale,
       total_sale - cogs            AS gross_profit
FROM dbo.retail_sales;
GO
