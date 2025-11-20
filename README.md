# AdventureWorks-Analytics-Hackhaton-2025

## Introduction
This project is my solution for the Analytics Hackhaton 2025.  I have been tasked to Explore and analyze the AdventureWorks dataset, identify five (5) high-quality insights that have business relevance, and Support each insight with evidence.

## Problem Statement
AdventureWorks is a global manufacturing company that sells products through online and reseller channels. Management wants to understand business performance, customer behavior, and product trends.

## Tools Used
1. Microsoft SQL server
2. Power BI For interactive Dashboard
3. PowerPoint for Presentation

## Project Workflow
1. Data Collection
2. Data Exploration
3. Data Analysis
4. Visualization
5. Reporting

## Data Collection
The dataset was sourced online, which I got from [Microsoft Learn](https://learn.microsoft.com/en-us/sql/samples/adventureworks-install-configure?view=sql-server-ver16&tabs=ssms). I downloaded the AdventureWorks2019.bak file. and Restored the database on SSMS. 

## Understanding the Obejective
I spent a while trying to understand the business objectives and what is expected of me. Management wants to understand business performance, customer behavior, and product trends. To be able to answer this I thought of possible questions and Insights that will help management. 

First of what are the KPIs  to track - Revenue,  Total Quantity Sold, Total Orders and Profit. 

Then,
How has Sales grown over the years
Where does Sales come from? Online or Reseller Channel?
What are our top-selling products?
Who are our top customers? What is their Purchasing Behaviour like?
Where are they buying from?

When this was sorted I decided to explore the dataset. It is time to know if I have the data needed to answer this and how to go about it.

## Data Exploration
I Explored the data to have a better understanding of it. First thing I did was to have an overview of the database

```sql
SELECT TABLE_NAME
FROM AdventureWorks2019.INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
```

<img width="210" height="317" alt="image" src="https://github.com/user-attachments/assets/de150ada-aaca-490b-9672-8d50b68304c6" />


After running the query I realized the database has a total of 72 Tables. 

I definitely do not need this much tables so I chose five relevant tables to focus on. The tables are 

- Sales.SalesOrderHeader: Contains sales order details (aggregated order information)
- Sales.SalesOrderDetail: Contains detailed line-item order information for each product in an order
- Production.Product: Contains product information
- Sales.Customer: Contains customer information
- Sales.SalesTerritory: contains regional territories

I carried out further exploration of each of the tables to understand it better and also validate it, I checked for tables shape, missing values, and duplicates. 

## Data Analysis

### . Key Performance Indicators
   
I started by calculating the core KPIs: Total Revenue, Total Orders Sold, and Total Quantity

```sql
SELECT SUM(TotalDue) AS Revenue,
    COUNT(DISTINCT soh.SalesOrderID) AS TotalOrders,
    SUM(OrderQty) AS Totalqty
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod
ON soh.SalesOrderID = sod.SalesOrderID
```
<img width="371" height="54" alt="image" src="https://github.com/user-attachments/assets/69bce0d6-34fa-4a6f-8df3-35da57b60438" />

This shows that the business has made 2926970124.0414 in revenue, recieved 31,465 orders and sold a total of 274914 quantities

### .  How has Sales grown over the years

I thought It would be good to see how Sales has grown over the years

```sql
WITH YearlyRevenue AS
(
    SELECT 
        YEAR(OrderDate) AS Year,
        SUM(TotalDue) AS Revenue
    FROM Sales.SalesOrderHeader
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
ORDER BY Year
```
<img width="547" height="131" alt="Screenshot 2025-11-20 011719" src="https://github.com/user-attachments/assets/4be949e3-2863-4614-ba0a-5916ff2e749c" />

It shows that Revenue declined by 54% in 2014

### What Caused this decline? what month did the drop-off happen?

54% decline is a lot and does not look god for the business I carried a further analysis to know hy it happened 

```sql
SELECT 
    YEAR(OrderDate) AS Year,
    MONTH(OrderDate) AS Month,
    SUM(TotalDue) AS Revenue
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY Year, Month;
```

<img width="288" height="304" alt="image" src="https://github.com/user-attachments/assets/c7622686-e0a0-49a1-bcea-06c64767a528" />

The results Showed only six months of sales data for 2014 and this confirms that the decline is not a business-drop rather incomplete data or unfair comparison.


### . Which Channel drives the most Sales?

```sql
SELECT soh.OnlineOrderFlag,
SUM(soh.TotalDue) AS Revenue,
COUNT(DISTINCT soh.SalesOrderID) AS NumOrders,
AVG(soh.TotalDue) AS AvgOrderValue
FROM Sales.SalesOrderHeader soh
GROUP BY soh.OnlineOrderFlag;
```
<img width="483" height="73" alt="image" src="https://github.com/user-attachments/assets/1386ca30-3f3c-4f4c-ac7d-45245bd9ca35" />

Resellers generates nearly three times more revenue than online customers even though online shoppers place more orders. This is because reseller orders are much larger in value, they have an average order value of $23,850.

### . What are our top-selling products?

```sql
SELECT TOP 10 p.Name AS Products, pc.Name AS Category, SUM(LineTotal) as Revenue
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p
ON sod.ProductID = p.ProductID
JOIN Production.ProductSubCategory ps
ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory pc
ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY p.Name,pc.Name
ORDER BY Revenue DESC
```
<img width="452" height="276" alt="image" src="https://github.com/user-attachments/assets/4534d85e-7996-41a0-8f26-82ff1c6cafde" />

Mountain-200 Black, 38 records the highest revenue, closely followed by Mountain-200 Black, 42. Interestingly all top 10 products are under the bike category.

### . Who are our customers? What is their Purchasing Behaviour like?

For this, I did an RFM analysis, what better way we will understand and know how customers better. I created a view first to store the Customers RFM information before doing a segement distribution.

```
GO
CREATE VIEW vw_CustomerSegments AS
WITH CustomerOrders AS (
    SELECT c.CustomerID,
           MAX(soh.OrderDate) AS LastOrderDate,
           COUNT(DISTINCT soh.SalesOrderID) AS Frequency,
           SUM(soh.TotalDue) AS Monetary
    FROM Sales.Customer c
    JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
    GROUP BY c.CustomerID
),
RFM_Metrics AS (
    SELECT CustomerID,
           DATEDIFF(day, LastOrderDate, (SELECT MAX(OrderDate) FROM Sales.SalesOrderHeader)) AS RecencyDays,
           Frequency,
           Monetary
    FROM CustomerOrders
),
RFM_Scores AS (
    SELECT CustomerID,
           RecencyDays,
           Frequency,
           Monetary,
           NTILE(5) OVER (ORDER BY RecencyDays ASC) AS R_Score,
           NTILE(5) OVER (ORDER BY Frequency DESC) AS F_Score,
           NTILE(5) OVER (ORDER BY Monetary DESC) AS M_Score
    FROM RFM_Metrics
)
SELECT CustomerID,
       RecencyDays,
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
FROM RFM_Scores
GO
```

To know how customers are distributed across the segments and understand their purchasing behaviour, I wrote this query.
```sql
SELECT Customer_Segment, 
       COUNT(*) AS CustomerCount,
       CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS Percentage,
       SUM(Monetary) AS TotalRevenue,
       AVG(Monetary) AS AvgRevenue
FROM vw_CustomerSegments
GROUP BY Customer_Segment
ORDER BY TotalRevenue DESC
```

### . Finally, Where are they buying from?

```sql
SELECT Name AS TerritoryRegion, SUM(TotalDue) AS Revenue,
    (SUM(TotalDue)/ (SELECT SUM(TotalDue) FROM Sales.SalesOrderHeader) * 100) AS perc_total
FROM Sales.SalesTerritory st
JOIN Sales.SalesOrderHeader soh
ON st.TerritoryID = soh.TerritoryID
GROUP BY Name
ORDER BY Revenue DESC
```

<img width="403" height="280" alt="image" src="https://github.com/user-attachments/assets/4840d3ec-346d-4b81-9e85-3014e080e3dd" />

SouthWest, Canada and NorthWest are the top performing regions, making almost 50% of the total generated revenue. 

## Recommendations
- ed
- 













