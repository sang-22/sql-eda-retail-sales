/* =====================================================================
   File   : 01_create_database_and_tables.sql
   Purpose: Create the database, a raw staging table and the clean table
   Engine : Microsoft SQL Server (2022)
   ===================================================================== */

-- 1. Create database --------------------------------------------------
IF DB_ID('RetailSalesDB') IS NULL
    CREATE DATABASE RetailSalesDB;
GO

USE RetailSalesDB;
GO

-- 2. Staging table ----------------------------------------------------
DROP TABLE IF EXISTS dbo.retail_sales_staging;
GO

CREATE TABLE dbo.retail_sales_staging (
    transactions_id   VARCHAR(50),
    sale_date         VARCHAR(50),
    sale_time         VARCHAR(50),
    customer_id       VARCHAR(50),
    gender            VARCHAR(50),
    age               VARCHAR(50),
    category          VARCHAR(50),
    quantiy           VARCHAR(50),   -- column name is misspelled in the source CSV
    price_per_unit    VARCHAR(50),
    cogs              VARCHAR(50),
    total_sale        VARCHAR(50)
);
GO

-- 3. Clean, typed table used for all analysis ------------------------
DROP TABLE IF EXISTS dbo.retail_sales;
GO

CREATE TABLE dbo.retail_sales (
    transaction_id    INT            NOT NULL PRIMARY KEY,
    sale_date         DATE           NOT NULL,
    sale_time         TIME(0)        NOT NULL,
    customer_id       INT            NOT NULL,
    gender            VARCHAR(10)    NOT NULL,
    age               INT            NULL,        -- 10 rows have no age; kept for sales analysis
    category          VARCHAR(30)    NOT NULL,
    quantity          INT            NOT NULL,    -- renamed from "quantiy"
    price_per_unit    DECIMAL(10,2)  NOT NULL,
    cogs              DECIMAL(10,2)  NOT NULL,
    total_sale        DECIMAL(10,2)  NOT NULL
);
GO
