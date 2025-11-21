# AdventureWorks-Analytics-Hackhaton-2025

## Introduction
This project is my solution for the Analytics Hackhaton 2025.  I have been tasked to explore and analyze the AdventureWorks dataset, identify five (5) high-quality insights that have business relevance, and support each insight with evidence.

## Problem Statement
AdventureWorks is a global manufacturing company that sells products through online and reseller channels. Management wants to understand business performance, customer behavior, and product trends.

## Tools Used
1. Microsoft SQL server for Data Exploration, Cleaning and Querying
2. Power BI For interactive Dashboard
3. PowerPoint for Presentation

## Project Workflow
1. Data Collection
2. Understanding the Problem Statement
3. Data Exploration and Preparation
4. Data Analysis
5. Visualization
6. Reporting

## Data Collection
The dataset was sourced online, which I got from [Microsoft Learn](https://learn.microsoft.com/en-us/sql/samples/adventureworks-install-configure?view=sql-server-ver16&tabs=ssms). I downloaded the AdventureWorks2019.bak file. and restored the database on SSMS. 

## Understanding the Problem Statement
I spent a while trying to understand the business objectives and what is expected of me. Management wants to understand business performance, customer behavior, and product trends. To be able to answer this I thought of possible questions and Insights that will help management. 

First of what are the KPIs  to track - Revenue,  Total Quantity Sold, Total Orders, Profit and Profit Margin

Then,
How has Sales grown over the years?
Where does Sales come from? Online or Reseller Channel?
What are our top-selling products?
What is the purchasing behaviour of our Customers?
Where are they buying from?

## Data Exploration
Once the questions were defined, I went on to explore the data to have a better understanding of the dataset. First thing I did was to have an overview of the database

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

I carried out further exploration of each of the tables to get clarity and also validate them, I checked for tables shape, missing values, standardized columns where needed and selected relevant fields needed in my analysis while discarding the other.

A new schema (Cleaned) was created to save my cleaned tables, the cleaned tables were created as VIEWS. 

```sql
CREATE SCHEMA Cleaned;
```

```sql
GO
CREATE VIEW Cleaned.SalesOrderHeader AS
SELECT SalesOrderID, OrderDate,ShipDate, 
       CASE WHEN OnlineOrderFlag = 0 THEN 'Reseller' ELSE 'Online' END AS Channel,
        CustomerID, TerritoryID, SubTotal, TaxAmt, Freight, TotalDue
FROM Sales.SalesOrderHeader;
GO
```
For, example the code above is how I cleaned the SalesOrderHeader table and store as a view. I changed the OnlineOrderFlag field values to a standardized readable value and also renamed the field name to Channel.

## Data Analysis

Here, I provide answers to the questions I outlined, I made use of SQl concepts Such as Aggregate functions, JOINS, CTEs...

### . Key Performance Indicators
   
I started by calculating the core KPIs: Total Revenue, Total Orders Sold, and Total Quantity, Profit and Profit Margin. These are essential metrucs to track business performance.

```sql
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
```
<img width="610" height="52" alt="image" src="https://github.com/user-attachments/assets/98c9a1ae-e5b4-49ea-a3b3-69e5c69ba46f" />


This shows that the business has made $109.85M in revenue, recieved 31,465 orders, sold a total of 274.9K quantities Of products, made a profit of $9.37M with 8.53% Profit margin.

The business is performing well, generating strong revenue from high-value orders, but its profit margin of 8.5% is moderate, which can be improved.

### .  How has Sales grown over the years

Since we have an overview of our KPI it would be good to see how Sales has grown over the years

```sql
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
```
<img width="549" height="129" alt="image" src="https://github.com/user-attachments/assets/f880d735-b2d8-4bb7-8370-a7bdead2c608" />

The query result shows a 54% Decline in Revenue 2014, which is a significant drop

### What Caused this decline? 

To investigate why there is a huge drop I carried a further analysis, I analyzed the monthly trend each year

```sql
SELECT 
    YEAR(OrderDate) AS Year,
    MONTH(OrderDate) AS Month,
    SUM(SubTotal) AS Revenue
FROM Cleaned.SalesOrderHeader
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY Year, Month;
```

<img width="288" height="304" alt="image" src="https://github.com/user-attachments/assets/c7622686-e0a0-49a1-bcea-06c64767a528" />

The results reveal that in 2014, there were only six months of sales data, which directly explains the large decline in yearly revenue. This suggests that the drop is not due to business performance issues, but rather partial data availability.


### . Which Channel drives the most Sales?

```sql
SELECT soh.Channel,
SUM(soh.SubTotal) AS Revenue,
COUNT(DISTINCT soh.SalesOrderID) AS NumOrders,
AVG(soh.TotalDue) AS AvgOrderValue
FROM Cleaned.SalesOrderHeader soh
GROUP BY soh.Channel;
```

<img width="479" height="80" alt="image" src="https://github.com/user-attachments/assets/4fc130ba-02c3-4f5d-8ad0-8a23ce3291fc" />

Resellers generates nearly three times more revenue than online customers even though online shoppers place more orders. This is because reseller orders are much larger in value, they have an average order value of $23,850.

### . What are our top-selling products?

```sql
SELECT  Products, Category, SUM(LineTotal) as Revenue
FROM Cleaned.SalesOrderDetail sod
JOIN Cleaned.Product p
ON sod.ProductID = p.ProductID
GROUP BY Products, Category
ORDER BY Revenue DESC;
```
<img width="452" height="276" alt="image" src="https://github.com/user-attachments/assets/4534d85e-7996-41a0-8f26-82ff1c6cafde" />

Mountain-200 Black, 38 records the highest revenue, closely followed by Mountain-200 Black, 42. Interestingly all top 10 products are from the bikes category.

### . Who are our customers? What is their Purchasing Behaviour like?

For this, I did an RFM analysis, what better way to understand and know our customers better. I created a view first to store the Customers RFM information before doing a segement distribution.

```
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
```

To know how customers are distributed across the segments and understand their purchasing behaviour, I wrote this query.
```sql
SELECT Customer_Segment, 
       COUNT(*) AS CustomerCount,
       CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS DistPerc,
       SUM(Monetary) AS TotalRevenue,
       AVG(Monetary) AS AvgRevenue
FROM vw_CustomerSegments
GROUP BY Customer_Segment
ORDER BY TotalRevenue DESC;
```
<img width="660" height="226" alt="image" src="https://github.com/user-attachments/assets/3a6bbadb-a74e-4af0-9500-06a5324c62b1" />

The champions segment generates the highest revenue at $75.9M, with an impressive average spend of $31,238 per customer. However, nearly 30% of our customer base is at-risk with 11.09% classified as "At-Risk" and 8.55% "Hibernating", and 10.25% of customers are already "Lost" representing $21.5M in vulnerable revenue.

### . Finally, Where are they buying from?

```sql
SELECT Name AS TerritoryRegion, SUM(SubTotal) AS Revenue,
    (SUM(SubTotal)/ (SELECT SUM(SubTotal) FROM Cleaned.SalesOrderHeader) * 100) AS perc_total
FROM Cleaned.SalesTerritory st
JOIN Cleaned.SalesOrderHeader soh
ON st.TerritoryID = soh.TerritoryID
GROUP BY Name
ORDER BY Revenue DESC
```
<img width="394" height="273" alt="image" src="https://github.com/user-attachments/assets/0ede4db6-c776-4f63-9995-15f4c17724cc" />


SouthWest, Canada and NorthWest are the top performing regions, making almost 50% of the total generated revenue. 

## Recommendations

- The company should focus on reducing costs, increasing repeat purchases, and strategically upselling to improve revenue and profitability.
- Boost online revenue via targeted marketing, campaigns, Ads.
- Introduce products that are related to bikes, examples are helmets, cycling apparel, bike maintenance equipment.
- Launch retention campaigns targeting At-Risk and Hibernating customers.
- Focus marketing and sales efforts in top-performing regions and develop strategies to grow underperforming regions

## Dashboard

I connected the Database to PowerBI for visualization. I created a Date table, modelled the tables and created measures to aid my Visualization.

![Adventure_page-0001](https://github.com/user-attachments/assets/b5f4f74c-1cb8-40dd-8d3f-42c04e4bd260)

Interact with the dashboard here
