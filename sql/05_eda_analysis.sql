/* =====================================================================
   File   : 05_eda_analysis.sql
   Purpose: Exploratory analysis organised by business area
   Skills : GROUP BY / HAVING, CASE, CTEs, window functions
            (LAG, RANK, DENSE_RANK, NTILE, running totals), date functions
   ===================================================================== */

USE RetailSalesDB;
GO

/* =====================================================================
   A. SALES TRENDS
   ===================================================================== */

-- A1. Revenue by year with year-over-year growth
WITH yearly AS (
    SELECT YEAR(sale_date) AS sale_year,
           SUM(total_sale) AS revenue,
           COUNT(*)        AS orders
    FROM dbo.retail_sales
    GROUP BY YEAR(sale_date)
)
SELECT sale_year, revenue, orders,
       CAST((revenue - LAG(revenue) OVER (ORDER BY sale_year)) * 100.0
            / LAG(revenue) OVER (ORDER BY sale_year) AS DECIMAL(5,2)) AS yoy_growth_pct
FROM yearly
ORDER BY sale_year;

-- A2. Monthly revenue with month-over-month growth
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

-- A3. Running total of revenue within each year
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

-- A4. Revenue by quarter (seasonality)
SELECT YEAR(sale_date) AS sale_year,
       DATEPART(QUARTER, sale_date) AS sale_quarter,
       SUM(total_sale) AS revenue,
       CAST(SUM(total_sale) * 100.0
            / SUM(SUM(total_sale)) OVER (PARTITION BY YEAR(sale_date)) AS DECIMAL(5,2)) AS pct_of_year
FROM dbo.retail_sales
GROUP BY YEAR(sale_date), DATEPART(QUARTER, sale_date)
ORDER BY sale_year, sale_quarter;

-- A5. Revenue by day of week (weekday vs weekend)
SELECT DATENAME(WEEKDAY, sale_date) AS day_name,
       CASE WHEN DATENAME(WEEKDAY, sale_date) IN ('Saturday', 'Sunday')
            THEN 'Weekend' ELSE 'Weekday' END AS day_type,
       COUNT(*)        AS orders,
       SUM(total_sale) AS revenue
FROM dbo.retail_sales
GROUP BY DATENAME(WEEKDAY, sale_date)
ORDER BY revenue DESC;

-- A6. Orders by shift (time of day)
SELECT
    CASE WHEN DATEPART(HOUR, sale_time) < 12 THEN 'Morning (before 12)'
         WHEN DATEPART(HOUR, sale_time) BETWEEN 12 AND 17 THEN 'Afternoon (12-17)'
         ELSE 'Evening (after 17)' END AS shift,
    COUNT(*)        AS orders,
    SUM(total_sale) AS revenue
FROM dbo.retail_sales
GROUP BY
    CASE WHEN DATEPART(HOUR, sale_time) < 12 THEN 'Morning (before 12)'
         WHEN DATEPART(HOUR, sale_time) BETWEEN 12 AND 17 THEN 'Afternoon (12-17)'
         ELSE 'Evening (after 17)' END
ORDER BY orders DESC;

/* =====================================================================
   B. CATEGORY PERFORMANCE
   ===================================================================== */

-- B1. Revenue, profit, margin and share by category
SELECT category,
       COUNT(*)                    AS orders,
       SUM(quantity)               AS units,
       SUM(total_sale)             AS revenue,
       SUM(total_sale) - SUM(cogs) AS gross_profit,
       CAST((SUM(total_sale) - SUM(cogs)) * 100.0 / SUM(total_sale) AS DECIMAL(5,2)) AS margin_pct,
       CAST(SUM(total_sale) * 100.0 / SUM(SUM(total_sale)) OVER () AS DECIMAL(5,2))   AS revenue_share_pct,
       CAST(AVG(total_sale) AS DECIMAL(10,2)) AS avg_order_value
FROM dbo.retail_sales
GROUP BY category
ORDER BY revenue DESC;

-- B2. Best month for each category (RANK inside each category)
WITH cat_month AS (
    SELECT category, FORMAT(sale_date, 'yyyy-MM') AS sale_month,
           SUM(total_sale) AS revenue,
           RANK() OVER (PARTITION BY category ORDER BY SUM(total_sale) DESC) AS rnk
    FROM dbo.retail_sales
    GROUP BY category, FORMAT(sale_date, 'yyyy-MM')
)
SELECT category, sale_month, revenue
FROM cat_month
WHERE rnk = 1;

-- B3. Category growth: 2022 vs 2023
SELECT category,
       SUM(CASE WHEN YEAR(sale_date) = 2022 THEN total_sale ELSE 0 END) AS revenue_2022,
       SUM(CASE WHEN YEAR(sale_date) = 2023 THEN total_sale ELSE 0 END) AS revenue_2023,
       CAST((SUM(CASE WHEN YEAR(sale_date) = 2023 THEN total_sale ELSE 0 END)
           - SUM(CASE WHEN YEAR(sale_date) = 2022 THEN total_sale ELSE 0 END)) * 100.0
           / NULLIF(SUM(CASE WHEN YEAR(sale_date) = 2022 THEN total_sale ELSE 0 END), 0)
           AS DECIMAL(6,2)) AS growth_pct
FROM dbo.retail_sales
GROUP BY category;

-- B4. Loss-making transactions by category (cogs higher than sale)
SELECT category,
       COUNT(*) AS loss_orders,
       SUM(cogs - total_sale) AS total_loss
FROM dbo.retail_sales
WHERE cogs > total_sale
GROUP BY category
ORDER BY total_loss DESC;

/* =====================================================================
   C. CUSTOMER ANALYSIS
   ===================================================================== */

-- C1. Top 10 customers by revenue
SELECT TOP (10)
       customer_id,
       COUNT(*)        AS orders,
       SUM(total_sale) AS revenue,
       DENSE_RANK() OVER (ORDER BY SUM(total_sale) DESC) AS revenue_rank
FROM dbo.retail_sales
GROUP BY customer_id
ORDER BY revenue DESC;

-- C2. Revenue contribution of top 20% customers (Pareto check)
WITH cust AS (
    SELECT customer_id, SUM(total_sale) AS revenue,
           NTILE(5) OVER (ORDER BY SUM(total_sale) DESC) AS quintile
    FROM dbo.retail_sales
    GROUP BY customer_id
)
SELECT quintile,
       COUNT(*)     AS customers,
       SUM(revenue) AS revenue,
       CAST(SUM(revenue) * 100.0 / SUM(SUM(revenue)) OVER () AS DECIMAL(5,2)) AS revenue_share_pct
FROM cust
GROUP BY quintile
ORDER BY quintile;

-- C3. Customers who bought from all 3 categories
SELECT customer_id
FROM dbo.retail_sales
GROUP BY customer_id
HAVING COUNT(DISTINCT category) = 3;

-- C4. Customer segmentation by spend (RFM-style using recency, frequency, monetary)
WITH rfm AS (
    SELECT customer_id,
           DATEDIFF(DAY, MAX(sale_date), (SELECT MAX(sale_date) FROM dbo.retail_sales)) AS recency_days,
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
)
SELECT customer_id, recency_days, frequency, monetary, r_score, f_score, m_score,
       CASE
           WHEN r_score = 3 AND f_score = 3 AND m_score = 3 THEN 'Champion'
           WHEN f_score >= 2 AND m_score >= 2               THEN 'Loyal'
           WHEN r_score = 1                                 THEN 'At Risk'
           ELSE 'Regular'
       END AS segment
FROM scored
ORDER BY monetary DESC;

/* =====================================================================
   D. DEMOGRAPHICS
   ===================================================================== */

-- D1. Orders and revenue by gender within each category
SELECT category, gender,
       COUNT(*)        AS orders,
       SUM(total_sale) AS revenue
FROM dbo.retail_sales
GROUP BY category, gender
ORDER BY category, gender;

-- D2. Average order value by age group (rows with unknown age excluded)
SELECT
    CASE WHEN age BETWEEN 18 AND 25 THEN '18-25'
         WHEN age BETWEEN 26 AND 35 THEN '26-35'
         WHEN age BETWEEN 36 AND 45 THEN '36-45'
         WHEN age BETWEEN 46 AND 55 THEN '46-55'
         ELSE '56+' END AS age_group,
    COUNT(*)        AS orders,
    SUM(total_sale) AS revenue,
    CAST(AVG(total_sale) AS DECIMAL(10,2)) AS avg_order_value
FROM dbo.retail_sales
WHERE age IS NOT NULL
GROUP BY
    CASE WHEN age BETWEEN 18 AND 25 THEN '18-25'
         WHEN age BETWEEN 26 AND 35 THEN '26-35'
         WHEN age BETWEEN 36 AND 45 THEN '36-45'
         WHEN age BETWEEN 46 AND 55 THEN '46-55'
         ELSE '56+' END
ORDER BY age_group;

-- D3. Average customer age per category
SELECT category, CAST(AVG(age * 1.0) AS DECIMAL(5,2)) AS avg_age
FROM dbo.retail_sales
WHERE age IS NOT NULL
GROUP BY category;
GO
