/* =====================================================================
   File   : 04_data_profiling.sql
   Purpose: Understand the shape of the clean data before analysis
   ===================================================================== */

USE RetailSalesDB;
GO

-- 1. Overall size and coverage
SELECT
    COUNT(*)                         AS total_transactions,
    COUNT(DISTINCT customer_id)      AS unique_customers,
    COUNT(DISTINCT category)         AS categories,
    MIN(sale_date)                   AS first_sale,
    MAX(sale_date)                   AS last_sale,
    DATEDIFF(MONTH, MIN(sale_date), MAX(sale_date)) + 1 AS months_covered
FROM dbo.retail_sales;

-- 2. Headline KPIs
SELECT
    SUM(total_sale)                                  AS total_revenue,
    SUM(cogs)                                        AS total_cogs,
    SUM(total_sale) - SUM(cogs)                      AS gross_profit,
    CAST((SUM(total_sale) - SUM(cogs)) * 100.0
         / SUM(total_sale) AS DECIMAL(5,2))          AS gross_margin_pct,
    CAST(AVG(total_sale) AS DECIMAL(10,2))           AS avg_order_value,
    SUM(quantity)                                    AS units_sold
FROM dbo.retail_sales;

-- 3. Numeric column summary
SELECT 'age' AS column_name, MIN(age) AS min_val, MAX(age) AS max_val,
       CAST(AVG(age * 1.0) AS DECIMAL(10,2)) AS avg_val FROM dbo.retail_sales
UNION ALL
SELECT 'quantity', MIN(quantity), MAX(quantity),
       CAST(AVG(quantity * 1.0) AS DECIMAL(10,2)) FROM dbo.retail_sales
UNION ALL
SELECT 'price_per_unit', MIN(price_per_unit), MAX(price_per_unit),
       CAST(AVG(price_per_unit) AS DECIMAL(10,2)) FROM dbo.retail_sales
UNION ALL
SELECT 'total_sale', MIN(total_sale), MAX(total_sale),
       CAST(AVG(total_sale) AS DECIMAL(10,2)) FROM dbo.retail_sales;

-- 4. Price points available (only 5 distinct prices in this data)
SELECT price_per_unit, COUNT(*) AS transactions
FROM dbo.retail_sales
GROUP BY price_per_unit
ORDER BY price_per_unit;

-- 5. Category and gender split
SELECT category, COUNT(*) AS transactions,
       CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS DECIMAL(5,2)) AS pct
FROM dbo.retail_sales
GROUP BY category;

SELECT gender, COUNT(*) AS transactions,
       CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS DECIMAL(5,2)) AS pct
FROM dbo.retail_sales
GROUP BY gender;

-- 6. Age distribution (NULL ages shown separately)
SELECT
    CASE
        WHEN age IS NULL           THEN 'Unknown'
        WHEN age BETWEEN 18 AND 25 THEN '18-25'
        WHEN age BETWEEN 26 AND 35 THEN '26-35'
        WHEN age BETWEEN 36 AND 45 THEN '36-45'
        WHEN age BETWEEN 46 AND 55 THEN '46-55'
        ELSE '56+'
    END AS age_group,
    COUNT(*) AS customers_txn
FROM dbo.retail_sales
GROUP BY
    CASE
        WHEN age IS NULL           THEN 'Unknown'
        WHEN age BETWEEN 18 AND 25 THEN '18-25'
        WHEN age BETWEEN 26 AND 35 THEN '26-35'
        WHEN age BETWEEN 36 AND 45 THEN '36-45'
        WHEN age BETWEEN 46 AND 55 THEN '46-55'
        ELSE '56+'
    END
ORDER BY age_group;
GO
