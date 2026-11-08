/* =====================================================================
   File   : 02_load_data.sql
   Purpose: Load the raw CSV into the staging table
   ===================================================================== */

USE RetailSalesDB;
GO

TRUNCATE TABLE dbo.retail_sales_staging;
GO


BULK INSERT dbo.retail_sales_staging
FROM 'C:\Projects\sql-eda-retail-sales\data\raw\retail_sales.csv'
WITH (
    FORMAT          = 'CSV',
    FIRSTROW        = 2,          -- skip the header row
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '\n',      -- file uses Windows (CRLF) line endings; '\n' handles this
    CODEPAGE        = '65001',    -- UTF-8 file
    TABLOCK
);
GO



-- Quick check: expect 2,000 rows
SELECT COUNT(*) AS staging_rows FROM dbo.retail_sales_staging;

SELECT TOP (10) * FROM dbo.retail_sales_staging;
GO
