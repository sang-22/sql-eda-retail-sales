/* =====================================================================
   File   : 03_data_cleaning.sql
   Purpose: Check data quality in staging, then load a clean typed table
   ===================================================================== */

USE RetailSalesDB;
GO

/* ---------------------------------------------------------------------
   STEP 1: Data quality checks on the raw data
   --------------------------------------------------------------------- */

-- 1.1 Duplicate transaction IDs (expect 0)
SELECT transactions_id, COUNT(*) AS cnt
FROM dbo.retail_sales_staging
GROUP BY transactions_id
HAVING COUNT(*) > 1;

-- 1.2 Fully duplicate rows (expect 0)
SELECT COUNT(*) - COUNT(DISTINCT CONCAT_WS('|', transactions_id, sale_date, sale_time,
       customer_id, gender, age, category, quantiy, price_per_unit, cogs, total_sale))
       AS duplicate_rows
FROM dbo.retail_sales_staging;

-- 1.3 Missing values per column (empty string counts as missing)
SELECT
    SUM(CASE WHEN NULLIF(TRIM(transactions_id), '') IS NULL THEN 1 ELSE 0 END) AS transactions_id_null,
    SUM(CASE WHEN NULLIF(TRIM(sale_date), '')       IS NULL THEN 1 ELSE 0 END) AS sale_date_null,
    SUM(CASE WHEN NULLIF(TRIM(sale_time), '')       IS NULL THEN 1 ELSE 0 END) AS sale_time_null,
    SUM(CASE WHEN NULLIF(TRIM(customer_id), '')     IS NULL THEN 1 ELSE 0 END) AS customer_id_null,
    SUM(CASE WHEN NULLIF(TRIM(gender), '')          IS NULL THEN 1 ELSE 0 END) AS gender_null,
    SUM(CASE WHEN NULLIF(TRIM(age), '')             IS NULL THEN 1 ELSE 0 END) AS age_null,
    SUM(CASE WHEN NULLIF(TRIM(category), '')        IS NULL THEN 1 ELSE 0 END) AS category_null,
    SUM(CASE WHEN NULLIF(TRIM(quantiy), '')         IS NULL THEN 1 ELSE 0 END) AS quantity_null,
    SUM(CASE WHEN NULLIF(TRIM(price_per_unit), '')  IS NULL THEN 1 ELSE 0 END) AS price_null,
    SUM(CASE WHEN NULLIF(TRIM(cogs), '')            IS NULL THEN 1 ELSE 0 END) AS cogs_null,
    SUM(CASE WHEN NULLIF(TRIM(REPLACE(total_sale, CHAR(13), '')), '') IS NULL THEN 1 ELSE 0 END) AS total_sale_null
FROM dbo.retail_sales_staging;
-- Result: age = 10 missing, quantity / price / cogs / total_sale = 3 missing

-- 1.4 Values that will not convert to the right type
SELECT *
FROM dbo.retail_sales_staging
WHERE TRY_CAST(sale_date AS DATE) IS NULL
   OR TRY_CAST(sale_time AS TIME) IS NULL
   OR TRY_CAST(customer_id AS INT) IS NULL;

-- 1.5 Distinct values in text columns (spot spelling variations)
SELECT DISTINCT TRIM(gender)   AS gender   FROM dbo.retail_sales_staging;
SELECT DISTINCT TRIM(category) AS category FROM dbo.retail_sales_staging;

-- 1.6 Does total_sale = quantity x price_per_unit?
SELECT *
FROM dbo.retail_sales_staging
WHERE TRY_CAST(total_sale AS DECIMAL(10,2))
   <> TRY_CAST(quantiy AS INT) * TRY_CAST(price_per_unit AS DECIMAL(10,2));
-- Result: 0 mismatches among rows that have values

-- 1.7 Sales below cost (loss-making transactions) - flagged, not removed
SELECT COUNT(*) AS loss_making_rows
FROM dbo.retail_sales_staging
WHERE TRY_CAST(cogs AS DECIMAL(10,2)) > TRY_CAST(total_sale AS DECIMAL(10,2));

/* ---------------------------------------------------------------------
   STEP 2: Cleaning decisions
   - 3 rows have no quantity, price, cogs or total_sale -> REMOVE
     (a sale with no amount cannot be used in any revenue analysis)
   - 10 rows have no age -> KEEP, age stays NULL
     (the sale is valid; these rows are only left out of age analysis)
   - Trim spaces, fix data types, rename "quantiy" to "quantity"
   --------------------------------------------------------------------- */

TRUNCATE TABLE dbo.retail_sales;

INSERT INTO dbo.retail_sales (
    transaction_id, sale_date, sale_time, customer_id, gender, age,
    category, quantity, price_per_unit, cogs, total_sale
)
SELECT
    TRY_CAST(TRIM(transactions_id) AS INT),
    TRY_CAST(TRIM(sale_date)       AS DATE),
    TRY_CAST(TRIM(sale_time)       AS TIME(0)),
    TRY_CAST(TRIM(customer_id)     AS INT),
    TRIM(gender),
    TRY_CAST(TRY_CAST(NULLIF(TRIM(age), '') AS DECIMAL(5,1)) AS INT),
    TRIM(category),
    TRY_CAST(TRY_CAST(TRIM(quantiy) AS DECIMAL(10,2)) AS INT),
    TRY_CAST(TRIM(price_per_unit)  AS DECIMAL(10,2)),
    TRY_CAST(TRIM(cogs)            AS DECIMAL(10,2)),
    TRY_CAST(TRIM(REPLACE(total_sale, CHAR(13), '')) AS DECIMAL(10,2))  -- strip stray carriage return
FROM dbo.retail_sales_staging
WHERE NULLIF(TRIM(quantiy), '')        IS NOT NULL
  AND NULLIF(TRIM(price_per_unit), '') IS NOT NULL
  AND NULLIF(TRIM(cogs), '')           IS NOT NULL
  AND NULLIF(TRIM(REPLACE(total_sale, CHAR(13), '')), '') IS NOT NULL;                    ś

/* ---------------------------------------------------------------------
   STEP 3: Validate the clean table
   --------------------------------------------------------------------- */
SELECT COUNT(*) AS clean_rows FROM dbo.retail_sales;              -- expect 1,997
SELECT COUNT(*) AS rows_without_age FROM dbo.retail_sales
WHERE age IS NULL;                                                 -- expect 10
GO
