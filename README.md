# AdventureWorks-Analytics-Hackhaton-2025

## Introduction
This project is my solution for the Analytics Hackhaton 2025.  I have been Tasked toeExplore and analyze the AdventureWorks dataset, identify five (5) high-quality insights that have business relevance, and Support each insight with evidence.

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
The dataset was sourced online, which I got from [https://learn.microsoft.com/en-us/sql/samples/adventureworks-install-configure?view=sql-server-ver16&tabs=ssms] Microsoft Learn. I downloaded the AdventureWorks2019.bak file. and Restored the database on SSMS. 

## Understanding the Obejective
I spent a while trying to understand the business objectives and what is expected of me. Management wants to understand business performance, customer behavior, and product trends. To be able to answer this I thought of possible questions and Insights that will help management. 

First of what are the KPIs  to track - Revenue,  Total Quantity Sold, Total Orders and Profit. 

Then,
How has Sales grown over the years
Where does Sales come from? Online or Reseller Channel?
What are our top-selling products?
Who are our top customers? What is their Purchasing Behaviour like?
What are they buying from?

When this was sorted I decided to explore the dataset. It is time to know if I have the data needed to answer this and how to go about it.

## Data Exploration
I Explored the data to have a better understanding of it. First thing I did was to have an overview of the database

After running the query I realized the database has a total of 72 Tables. 

I definitely do not need this much tables so I chose five relevant tables to focus on. The tables are 

● Sales.SalesOrderHeader: Contains Sales order details. This has an aggregated order details
● Sales.SalesOrderDetail: Contains a more detailed order details. It is more granular in the sense that it has info on all products bought for a particular order
● Production.Product: This table has the products info
● Sales.Customer: Contails Customer info
● Sales.SalesTerritory: This is a dimension table of territory Regions

I carried out further exploration of each of the tables to understand it better and also validate it, I checked for tables shape, missing values, and duplicates. 

## Data Analysis

1. Key Performance Indicators
   
I started by calculating the core KPIs: Total Revenue, Total Orders Sold, and Total Quantity
```sql
SELECT SUM(TotalDue) AS Revenue,
    COUNT(DISTINCT soh.SalesOrderID) AS OrderCount,
    SUM(OrderQty) AS Totalqty
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod
ON soh.SalesOrderID = sod.SalesOrderID
```sql








