USE AdventureWorks2019
GO

-- My first step is to get an overview of the database:

SELECT TABLE_NAME
FROM AdventureWorks2019.INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';

-- The result showed that the database contains 72 tables.

/* I selected five core tables to use for my analysis, 
    Sales.SalesOrderHeader, Sales.SalesOrderDetail, Production.Product,Sales.Customer, Sales.SalesTerritory
*/

-- DATA EXPLORATION/DATA CLEANING

/* Before going deep in exploring and cleaning the data, 
I want to create a new schema in which I will save all the clean tables
*/ 

CREATE SCHEMA Cleaned;


-- Sales Order Header Table

-- Quick overview of the first five rows of the table

SELECT TOP 5 *
FROM Sales.SalesOrderHeader;


--  How many rows does this table have
SELECT COUNT(*)
FROM Sales.SalesOrderHeader;
-- 31465 rows of data

-- . How many columns does the table have? Column names?  data types, null columns
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'SalesOrderHeader';

/*
  Table has 26 columns, they all have correct datatypes. 9 columns might have null values, none of this columns is needed
in my analysis. So I will ignore.
*/


-- Now, I want to select only relevant columns and store this cleaned data in a view.

GO
CREATE VIEW Cleaned.SalesOrderHeader AS
SELECT SalesOrderID, OrderDate,ShipDate, 
       CASE WHEN OnlineOrderFlag = 0 THEN 'Reseller' ELSE 'Online' END AS Channel,
        CustomerID, TerritoryID, SubTotal, TaxAmt, Freight, TotalDue
FROM Sales.SalesOrderHeader;
GO



-- Sales Order Detail Table

-- How many rows does the Sales Order Detail Table have

SELECT COUNT(*)
FROM Sales.SalesOrderDetail;
-- 121317 rows of data

-- Column information of the table 

SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'SalesOrderDetail';

/* 
The Table has 11 rows, all valid Datatype and one collumn has nulls. The null column is not needed for my analysis
so it will be ignored.
*/

-- Now, I will select relevant columns and save to a view
GO
CREATE VIEW Cleaned.SalesOrderDetail AS
SELECT SalesOrderID, SalesOrderDetailID, OrderQty, ProductID, UnitPrice, LineTotal
FROM Sales.SalesOrderDetail
GO


-- Product Table

SELECT *
FROM Production.Product 

-- How many Rows does the Product Table have?
SELECT COUNT(*)
FROM Production.Product
-- 504 rows

SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'Production'
  AND TABLE_NAME = 'Product';
-- 25 Columns, all valid datatypes, nulls in some tables.

-- Create a view for the clean data

GO
CREATE VIEW Cleaned.Product AS 
SELECT ProductID, p.Name AS Products,
       CASE WHEN pc.Name IS NULL THEN 'N/A' ELSE pc.Name END AS Category, 
       CASE WHEN ps.Name IS NULL THEN 'N/A' ELSE ps.Name END AS SubCategory,
        ProductNumber, SafetyStockLevel, ReorderPoint,StandardCost, ListPrice,
        DaysToManufacture
FROM Production.Product p
LEFT JOIN Production.ProductSubCategory ps
ON p.ProductSubcategoryID = ps.ProductSubcategoryID
LEFT JOIN Production.ProductCategory pc
ON ps.ProductCategoryID = pc.ProductCategoryID
GO

-- Customer Table 

SELECT *
FROM Sales.Customer; 

SELECT COUNT (*)
FROM Sales.Customer;
-- 19,820 rows of data, There are 19,820 customers.

SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'Sales'
  AND TABLE_NAME = 'Customer';

-- I will save the clean customer data with relevant info to a view. 
GO
CREATE VIEW Cleaned.Customer AS 
SELECT CustomerID, StoreID, TerritoryID
FROM Sales.Customer
GO


-- Sales Territory Table

SELECT TOP 5 *
FROM Sales.SalesTerritory; 

-- What is the table shape?
SELECT COUNT(*)
FROM Sales.SalesTerritory; 

SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'SalesTerritory';

-- The SalesTerritory table has 10 rows, 10 columns, all columns have valid datatypes and no null columns.

-- Create view to keep the clean data
GO
CREATE VIEW Cleaned.SalesTerritory AS
SELECT TerritoryID, Name, CountryRegionCode,[Group]
FROM Sales.SalesTerritory
GO



-- Data Analysis

-- 1. Key Performance Indicators. total Revenue,total Orders sold, Total qty Sold, Profit and Profit Margin?

SELECT
    (SELECT SUM(SubTotal) FROM Cleaned.SalesOrderHeader) AS Revenue,

    (SELECT COUNT(*) FROM Cleaned.SalesOrderHeader) AS TotalOrders,

    (SELECT SUM(OrderQty) FROM Cleaned.SalesOrderDetail) AS TotalQty,

    (SELECT 
        SUM(sod.LineTotal - (sod.OrderQty * p.StandardCost))
        FROM Cleaned.SalesOrderDetail sod
        JOIN Cleaned.Product p
        ON sod.ProductID = p.ProductID) AS Profit,

    ROUND((SELECT SUM(sod.LineTotal - (sod.OrderQty * p.StandardCost))
            FROM Cleaned.SalesOrderDetail sod
            JOIN Cleaned.Product p
            ON sod.ProductID = p.ProductID)
                /
            (SELECT SUM(SubTotal) 
            FROM Cleaned.SalesOrderHeader) * 100, 2) AS ProfitMargin;

/* This shows the business generated $109.85M in revenue, received 31,465 orders, sold 274.9K product units, 
earned $9.37M profit, and achieved an 8.53% profit margin.*/


-- 2.  How has revenue grown over the years? 
WITH YearlyRevenue AS
(
    SELECT 
        YEAR(OrderDate) AS Year,
        SUM(SubTotal) AS Revenue
    FROM Cleaned.SalesOrderHeader
    GROUP BY YEAR(OrderDate)
)
SELECT 
    Year,
    Revenue,
    LAG(Revenue) OVER (ORDER BY Year) AS Prev_Revenue,
    ROUND(
        CASE 
            WHEN LAG(Revenue) OVER (ORDER BY Year) IS NULL THEN NULL
            ELSE 100.0 * (Revenue - LAG(Revenue) OVER (ORDER BY Year)) / LAG(Revenue) OVER (ORDER BY Year)
        END, 2
    ) AS Growth_Percent
FROM YearlyRevenue
ORDER BY Year;

-- The result shows a 54% decline in revenue in 2014, which is a significant drop.

-- Investigation: Monthly Trend Analysis. What Caused this decline? 

SELECT 
    YEAR(OrderDate) AS Year,
    MONTH(OrderDate) AS Month,
    SUM(SubTotal) AS Revenue
FROM Cleaned.SalesOrderHeader
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY Year, Month;

/* The results reveal that in 2014, only six months of sales data exist.
    The decline is due to partial data availability, not an actual drop in performance.*/

-- 3. Which Channel drives the most Sales? 

SELECT soh.Channel,
SUM(soh.SubTotal) AS Revenue,
COUNT(DISTINCT soh.SalesOrderID) AS NumOrders,
AVG(soh.TotalDue) AS AvgOrderValue
FROM Cleaned.SalesOrderHeader soh
GROUP BY soh.Channel;

/* Resellers generate nearly three times more revenue than online customers, even though online shoppers place more orders. 
This is because reseller orders have a significantly higher average order value of $23,850.*/


-- 4. What are our top-selling products?

SELECT  Products, Category, SUM(LineTotal) as Revenue
FROM Cleaned.SalesOrderDetail sod
JOIN Cleaned.Product p
ON sod.ProductID = p.ProductID
GROUP BY Products, Category
ORDER BY Revenue DESC;

-- 5. Customer Purchasing Behavior (RFM Analysis)
-- Create an RFM view

GO
CREATE VIEW vw_CustomerSegments AS
WITH CustomerOrders AS (
    SELECT c.CustomerID,
           MAX(soh.OrderDate) AS LastOrderDate,
           COUNT(DISTINCT soh.SalesOrderID) AS Frequency,
           SUM(soh.SubTotal) AS Monetary
    FROM Cleaned.Customer c
    JOIN Cleaned.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
    GROUP BY c.CustomerID
),
RFM_Metrics AS (
    SELECT CustomerID,
           DATEDIFF(day, LastOrderDate, (SELECT MAX(OrderDate) FROM Cleaned.SalesOrderHeader)) AS Recency,
           Frequency,
           Monetary
    FROM CustomerOrders
),
RFM_Scores AS (
    SELECT CustomerID,
           Recency,
           Frequency,
           Monetary,
           NTILE(5) OVER (ORDER BY Recency ASC) AS R_Score,
           NTILE(5) OVER (ORDER BY Frequency DESC) AS F_Score,
           NTILE(5) OVER (ORDER BY Monetary DESC) AS M_Score
    FROM RFM_Metrics
)
SELECT CustomerID,
       Recency,
       Frequency,
       Monetary,
       R_Score,
       F_Score,
       M_Score,
       CAST(R_Score AS VARCHAR) + CAST(F_Score AS VARCHAR) + CAST(M_Score AS VARCHAR) AS RFM_Score,
       CASE
           
           WHEN R_Score <= 2 AND F_Score <= 2 AND M_Score <= 2 THEN 'Champions'
           WHEN R_Score <= 3 AND F_Score <= 2 AND M_Score <= 3 THEN 'Loyal Customers'
           WHEN M_Score <= 2 AND F_Score >= 4 THEN 'Big spenders'
           WHEN R_Score <= 2 AND F_Score <= 3 AND M_Score <= 4 THEN 'Promising'
           WHEN R_Score >= 4 AND F_Score <= 3 AND M_Score <= 3 THEN 'At-risk'
           WHEN R_Score >= 4 AND F_Score <= 4 THEN 'Hibernating'
           WHEN R_Score >= 4 AND F_Score >= 4 AND M_Score >= 4 THEN 'Lost'
           ELSE 'Others'
       END AS Customer_Segment
FROM RFM_Scores;
GO

-- What is the Segment Distribution of our Customers? 
SELECT Customer_Segment, 
       COUNT(*) AS CustomerCount,
       CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS DistPerc,
       SUM(Monetary) AS TotalRevenue,
       AVG(Monetary) AS AvgRevenue
FROM vw_CustomerSegments
GROUP BY Customer_Segment
ORDER BY TotalRevenue DESC;

/* The Champions segment generates the highest revenue $75.9M with an average spend of $31,238 per customer.
However, nearly 30% of customers are at risk*/


-- 6. Where Are Customers Buying From?

SELECT Name AS TerritoryRegion, SUM(SubTotal) AS Revenue,
    (SUM(SubTotal)/ (SELECT SUM(SubTotal) FROM Cleaned.SalesOrderHeader) * 100) AS perc_total
FROM Cleaned.SalesTerritory st
JOIN Cleaned.SalesOrderHeader soh
ON st.TerritoryID = soh.TerritoryID
GROUP BY Name
ORDER BY Revenue DESC

-- The Southwest, Canada, and Northwest regions are the top performers, contributing nearly 50% of total revenue.


