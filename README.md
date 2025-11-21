# AdventureWorks-Analytics-Hackhaton-2025

## Introduction
This project is my end-to-end-solution for the Analytics Hackhaton 2025.  I have been tasked to explore and analyze the AdventureWorks dataset, identify five (5) high-quality insights that have business relevance, and support each insight with evidence.

## Problem Statement
AdventureWorks is a global manufacturing company that sells products through online and reseller channels. Management wants to understand business performance, customer behavior, and product trends.

## Tools Used
1. Microsoft SQL server - For Data Exploration, Cleaning and Querying
2. Power BI - To develop interactive dashboard
3. PowerPoint - For Presentation

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
I spent time understanding the business objectives and what was expected of me. Management wants to understand business performance, customer behavior, and product trends.

To address these needs, I outlined key questions and insights that would help management make informed decisions.

First, I identified the core KPIs to track: Revenue, Total Quantity Sold, Total Orders, Profit, and Profit Margin.

Then I considered questions such as:

- How has sales performance changed over the years?
- Which channel contributes more—Online or Reseller?
- What are the top-selling products?
- What is the purchasing behavior of our customers?
- Which regions generate the most revenue?

## Data Exploration
After defining the questions, I explored the data to better understand the dataset. My first step was to get an overview of the database:

```sql
SELECT TABLE_NAME
FROM AdventureWorks2019.INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
```

<img width="210" height="317" alt="image" src="https://github.com/user-attachments/assets/de150ada-aaca-490b-9672-8d50b68304c6" />

The result showed that the database contains 72 tables.

Since not all of them were needed, I selected five core tables for the analysis:

- Sales.SalesOrderHeader: Contains aggregated sales order information
- Sales.SalesOrderDetail: Contains detailed line items for each order
- Production.Product: Contains product information
- Sales.Customer: Contains customer information
- Sales.SalesTerritory: contains regional Sales territories

I explored each table to understand its structure, check for missing values, clean where necessary, and select only the relevant fields.

I then created a new schema named Cleaned to store cleaned tables as views.

```sql
CREATE SCHEMA Cleaned;
```
Example of cleaning SalesOrderHeader:

```sql
GO
CREATE VIEW Cleaned.SalesOrderHeader AS
SELECT SalesOrderID, OrderDate,ShipDate, 
       CASE WHEN OnlineOrderFlag = 0 THEN 'Reseller' ELSE 'Online' END AS Channel,
        CustomerID, TerritoryID, SubTotal, TaxAmt, Freight, TotalDue
FROM Sales.SalesOrderHeader;
GO
```
Here, I standardized OnlineOrderFlag field into readable values and renamed it to Channel.

## Data Analysis

Here, I answered the questions outlined earlier using SQL concepts such as aggregate functions, joins, and CTEs.

### 1. Key Performance Indicators
   
I began by calculating the core KPIs: Total Revenue, Total Orders, Total Quantity Sold, Profit, and Profit Margin.

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

This shows the business generated $109.85M in revenue, received 31,465 orders, sold 274.9K product units, earned $9.37M profit, and achieved an 8.53% profit margin.

The business is performing well, generating strong revenue from high-value orders, though the 8.5% margin indicates room for improvement.

### 2.  How has Sales grown over the years

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

The result shows a 54% decline in revenue in 2014, which is a significant drop.

### Investigation: Monthly Trend Analysis. What Caused this decline? 

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

The results reveal that in 2014, only six months of sales data exist. The decline is due to partial data availability, not an actual drop in performance.

### 3. Which Channel drives the most Sales?

```sql
SELECT soh.Channel,
SUM(soh.SubTotal) AS Revenue,
COUNT(DISTINCT soh.SalesOrderID) AS NumOrders,
AVG(soh.TotalDue) AS AvgOrderValue
FROM Cleaned.SalesOrderHeader soh
GROUP BY soh.Channel;
```

<img width="479" height="80" alt="image" src="https://github.com/user-attachments/assets/4fc130ba-02c3-4f5d-8ad0-8a23ce3291fc" />

Resellers generate nearly three times more revenue than online customers, even though online shoppers place more orders. This is because reseller orders have a significantly higher average order value of $23,850.

### 4. What are our top-selling products?

```sql
SELECT  Products, Category, SUM(LineTotal) as Revenue
FROM Cleaned.SalesOrderDetail sod
JOIN Cleaned.Product p
ON sod.ProductID = p.ProductID
GROUP BY Products, Category
ORDER BY Revenue DESC;
```
<img width="452" height="276" alt="image" src="https://github.com/user-attachments/assets/4534d85e-7996-41a0-8f26-82ff1c6cafde" />

Mountain-200 Black, 38 is the top-revenue product, closely followed by Mountain-200 Black, 42. Interestingly all top 10 products belong to the Bikes category.

### 5. Customer Purchasing Behavior (RFM Analysis)

I performed an RFM analysis to understand customer segments and purchasing behavior. I created a view to store RFM metrics and customer segments.

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

To understand customer distribution across segments:

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

The Champions segment generates the highest revenue $75.9M with an average spend of $31,238 per customer.

However, nearly 30% of customers are at risk:

- 11.09% At-Risk
- 8.55% Hibernating
- 10.25% Lost

representing $21.5M in vulnerable revenue

### 6. Where Are Customers Buying From?

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

The Southwest, Canada, and Northwest regions are the top performers, contributing nearly 50% of total revenue.

## Recommendations

- Reduce costs, increase repeat purchases, and explore upselling strategies to improve profit margin.
- Boost online revenue via targeted ads, promotions, and personalized campaigns.
- Introduce complementary bike-related products (helmets, cycling apparel, maintenance tools).
- Launch retention campaigns targeting At-Risk and Hibernating customers.
- Focus growth initiatives in top regions while improving underperforming territories.

## Visualization

I connected the database to Power BI for visualization, created a Date table, modeled relationships, and built DAX measures to support the dashboard.

An Image of the Data Modell

<img width="1177" height="643" alt="image" src="https://github.com/user-attachments/assets/01e4364f-e2ee-47be-b7e7-ac6a94c5adab" />

Here is an Image of the dashboard:

![Adventure_page-0001](https://github.com/user-attachments/assets/b5f4f74c-1cb8-40dd-8d3f-42c04e4bd260)

Interact with the dashboard [here](https://app.powerbi.com/view?r=eyJrIjoiNDc0MGI5YzktZDE3NS00MzhhLTllYTYtMDY2NzdmZWZjZDk4IiwidCI6ImM0ZTg5YWFlLTU4OTMtNDc0ZS1iYjZjLTA4MDI4MmM0ZWY1OCJ9)

## Presentation

The final 5-slide presentation summarizing the key insights and recommendations can be downloaded here
