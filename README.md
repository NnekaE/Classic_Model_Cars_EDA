# Classic_Model_Cars_EDA
## Project Overview
This project focuses on helping Mint Classics, a retailer of collectible and model cars, make data‑driven decisions about the future of one of its storage facilities. By analyzing inventory, sales activity, and product movement using MySQL Workbench, the goal, can the facility be consolidated or closed without affecting customer service levels.

## Project Objectives

1. Explore products currently in inventory.

2. Determine important factors that may influence inventory reorganization/reduction.

3. Provide analytic insights and data-driven recommendations.

## Database Import:  
Imported data to a self-contained file creating a dumb of the data in the folder selected, 
Data Exported to self-contained file on the server
## Mysql Workbench 

## Data Understanding:  
 
## Analysis Techniques:  

## Insights and Conclusions:  

## Data Exploration 


### Quick data readiness & previews 
USE mintclassics; which is the name of my database 

-- Row counts by table (lint-safe alias)

SHOW TABLES;
SELECT 'customers' AS tbl, COUNT(*) AS row_count FROM customers

UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'orderdetails', COUNT(*) FROM orderdetails
UNION ALL SELECT 'products', COUNT(*) FROM products;

-- Peek at the first few rows of each table
SELECT * FROM products     LIMIT 10;
SELECT * FROM orders       LIMIT 10;
SELECT * FROM orderdetails LIMIT 10;
SELECT * FROM customers    LIMIT 10;	

### Inventory signal (recent demand vs. on hand) 
WITH last_90 AS (
  SELECT od.productCode,
         SUM(od.quantityOrdered) AS units_90d
  FROM orderdetails od
  JOIN orders o USING (orderNumber)
  WHERE o.orderDate >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
    AND o.status IN ('Shipped','Resolved','On Hold','Disputed','In Process')
  GROUP BY od.productCode
)
SELECT p.productCode, p.productName, p.productLine,
       p.quantityInStock,
       COALESCE(l.units_90d,0) AS units_90d,
       ROUND(COALESCE(l.units_90d,0)/3,2) AS avg_monthly_units_90d,
       CASE
         WHEN p.quantityInStock = 0 THEN 'Stockout'
         WHEN p.quantityInStock < COALESCE(l.units_90d,0)/3 THEN 'Low stock'
         WHEN p.quantityInStock > COALESCE(l.units_90d,0) THEN 'Potential overstock'
         ELSE 'Balanced'
       END AS inventory_signal
FROM products p
LEFT JOIN last_90 l ON l.productCode = p.productCode
ORDER BY FIELD(inventory_signal,'Stockout','Low stock','Balanced','Potential overstock'),
         p.quantityInStock ASC;
 
