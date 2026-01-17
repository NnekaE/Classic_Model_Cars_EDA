# Classic_Model_Cars_EDA
# Mint Classics Inventory Analysis & Warehouse Optimization

## 🚀 Executive Summary
This project addresses a critical business challenge for **Mint Classics**: identifying how to reduce inventory and consolidate storage facilities to cut operational costs. By leveraging SQL-driven Exploratory Data Analysis (EDA), this study evaluates sales velocity against stock levels to pinpoint underutilized assets. The final recommendations provide a roadmap for closing one warehouse while maintaining high service levels through data-backed inventory redistribution.

---

## Project Objectives

1. Explore products currently in inventory.

2. Determine important factors that may influence inventory reorganization/reduction.

3. Provide analytic insights and data-driven recommendations.

##  💾 Data Import and Export Process
To conduct this analysis, the Mint Classics database was established in MySQL Workbench using the following process:

* **Source Data Acquisition:** The raw data was provided as a .sql script containing the schema and record inserts for all tables (Products, Orders, Warehouses, etc.).

* **Database Restoration:** 1. Used the Data Import/Restore wizard within MySQL Workbench. 2. Selected the "Import from Self-Contained File" option to load the entire database structure and data in one operation. 3. Created a new target schema named mintclassics to host the tables.

* **Data Validation:** After the import, I executed SHOW TABLES; and SELECT COUNT(*) queries across all tables to ensure that the record counts matched the source file and that no data was lost during the transition.

* **Export for Portability:** For project backup and sharing, the final processed state was exported back to a self-contained .sql file, ensuring the analysis can be reproduced in any MySQL-compatible environment.

## Tools Used
* **MySQL Workbench:** For database management, visual schema inspection, and executing the analysis scripts.

* **SQL (DML/DDL):** To query, filter, and transform the raw data into business insights.

## 📊 Exploratory Data Analysis (EDA)

This project evaluates the operational efficiency of **Mint Classics** to determine if storage facilities can be closed or consolidated through strategic inventory reduction.

## 🔍 Data Understanding

To address the business challenge of warehouse consolidation, this analysis explores the relational data of Mint Classics through the lens of supply chain and inventory management.

### 1. Data Relation to Business Processes
The dataset maps directly to the **Order-to-Cash** and **Inventory Management** cycles:
* **Inventory Flow:** The `products` table tracks physical stock levels. By comparing `quantityInStock` against `quantityOrdered` in the `orderdetails` table, we can measure the "Inventory Turnover" and identify if stock is moving or stagnant.
* **Storage Strategy:** The `warehouses` and `productlines` tables allow us to see how different categories of model cars (e.g., Classic Cars vs. Planes) are distributed. This is key to identifying which facilities are underutilized.
* **Fulfillment Health:** The `status` field in the `orders` table helps filter out noise—ensuring that cancelled or disputed orders are not counted as successful sales demand.

### 2. Data Validity & Unknown Variables
To ensure the integrity of the analysis, several variables were identified that may impact the final recommendations:

Physical vs. System Stock: The analysis assumes quantityInStock reflects real-time physical inventory. Any lag in warehouse updates could lead to incorrect "Stockout" signals.

Order Status Nuances: Orders marked as 'On Hold' or 'Disputed' are treated as pending demand. If these orders are ultimately cancelled, the "Demand" calculation may be slightly inflated.

Time Sensitivity: The analysis uses a 90-day window for sales velocity. This does not account for long-term seasonality (e.g., holiday spikes) which might require higher stock levels than a 90-day average suggests.

## ⚙️ Analysis Techniques

To transform raw database records into a strategic warehouse consolidation plan, I employed several targeted data analysis techniques.

### 1. Analysis Methods & Rationale
The following techniques were chosen to balance historical performance with future stock needs:

* **Descriptive Statistics:** Used `COUNT`, `SUM`, and `AVG` to establish a baseline of current operations. This was chosen because identifying the "scale of the problem" (total stock vs. total value) is the first step in any inventory audit.
* **Inventory Signaling Model (Heuristic-based):** I developed a classification model using `CASE` logic to compare current `quantityInStock` against a 90-day demand window. This technique was chosen over simple averages because it accounts for "sales velocity," identifying exactly where capital is trapped in "Potential Overstock."
* **Recency Analysis:** By using `MAX(orderDate)`, I analyzed the "freshness" of inventory. This helps differentiate between a product that is low in stock because it’s popular versus a product that is low in stock because it hasn't been ordered in years.

### 2. Models and Algorithms
While the analysis is SQL-based, it follows specific algorithmic logic to drive decision-making:

* **Demand Forecasting Algorithm:**
    $$Average Monthly Demand = \frac{\sum \text{Quantity Ordered (90 days)}}{3}$$
* **Safety Stock Logic:** The analysis assumes a "balanced" state is maintained when stock covers approximately 3 months of demand. Anything exceeding this threshold is mathematically flagged as a candidate for warehouse removal.
* **Inventory Valuation Model:** Calculated the total financial exposure by product line to prioritize which categories offer the highest cost-savings if consolidated.

### 3. Limitations and Assumptions
To maintain the validity of the analysis, the following constraints were considered:

* **Assumption of Linear Demand:** The model assumes that the last 90 days of sales are a reliable predictor of the next 90 days. It does not account for seasonality (e.g., peak holiday sales) or market trends.
* **Snapshot Constraint:** The analysis is based on a "point-in-time" snapshot of `quantityInStock`. It does not factor in "Work in Progress" or inventory currently in transit from suppliers.
* **Status Exclusion:** The analysis assumes that only 'Shipped' and 'Resolved' orders represent true demand. Orders currently 'On Hold' are treated as potential sales but could lead to a slight overestimation of demand if later cancelled.
* **Data Completeness:** The model assumes that the `buyPrice` is static. In reality, fluctuating vendor costs could impact the profitability analysis and the urgency of liquidating specific stock.

## 💡 Insights and Conclusions
The data exploration yielded the following conclusions for the warehouse consolidation strategy:
Key Findings
Significant Overstock: A high volume of SKUs are flagged as 'Potential Overstock,' where current stock levels significantly exceed recent demand.

Facility Consolidation: The data reveals that specific warehouses contain a high concentration of slow-moving inventory. Consolidating these items into a central hub would allow for the closure of at least one underutilized facility.

Capital Efficiency: Millions of dollars are currently tied up in inventory that has not seen a sale in over 180 days.

## Recommendations
* **Consolidate Slow-Movers:** Identify the warehouse with the highest 'Potential Overstock' ratio and move its active stock to a primary facility.

* **Inventory Liquidation:**  Run targeted promotions for the 20 slowest-moving SKUs to free up physical space.

* **Dynamic Reordering:** Shift from fixed stock levels to a velocity-based reordering system based on the 90-day demand metrics provided in this analysis.

## 🛠️ Technical Skills Demonstrated
* **Database Management:** Relational Schema Design, Data Auditing, MySQL Workbench.
* **SQL Proficiency:** CTEs (Common Table Expressions), Joins, Window Functions, Case Logic.
* **Data Analysis:** Exploratory Data Analysis (EDA), Demand Forecasting, Sales Velocity, Recency Analysis.
* **Business Intelligence:** Inventory Signaling, Warehouse Optimization, Strategic Recommendations.
* **Version Control:** Git, GitHub.
  
![MySQL](https://img.shields.io/badge/mysql-%2300f.svg?style=for-the-badge&logo=mysql&logoColor=white)
![SQL](https://img.shields.io/badge/sql-%2307405e.svg?style=for-the-badge&logo=postgresql&logoColor=white)
![Git](https://img.shields.io/badge/git-%23F05033.svg?style=for-the-badge&logo=git&logoColor=white)
![GitHub](https://img.shields.io/badge/github-%23121011.svg?style=for-the-badge&logo=github&logoColor=white)


**Checking Data Scale (Record Counts):**
```sql
SELECT 'Customers' AS Table_Name, COUNT(*) AS Record_Count FROM customers
UNION ALL
SELECT 'Products', COUNT(*) FROM products
UNION ALL
SELECT 'Orders', COUNT(*) FROM orders
UNION ALL
SELECT 'OrderDetails', COUNT(*) FROM orderdetails;

* **Inventory Value & Summary Statistics:** 

-- Calculating total inventory value and average product margins
SELECT 
    productLine, 
    SUM(quantityInStock) AS total_stock,
    ROUND(AVG(buyPrice), 2) AS avg_cost,
    ROUND(SUM(quantityInStock * buyPrice), 2) AS total_stock_value
FROM products
GROUP BY productLine
ORDER BY total_stock_value DESC;



-- Identifying products with zero sales in the last 6 months
SELECT 
    p.productCode, 
    p.productName, 
    p.quantityInStock, 
    p.warehouseCode
FROM products p
LEFT JOIN orderdetails od ON p.productCode = od.productCode
LEFT JOIN orders o ON od.orderNumber = o.orderNumber
GROUP BY p.productCode
HAVING MAX(o.orderDate) < DATE_SUB((SELECT MAX(orderDate) FROM orders), INTERVAL 180 DAY)
OR MAX(o.orderDate) IS NULL;

### 🖥️ Key SQL Logic: Inventory Signaling
```sql
CASE 
    WHEN p.quantityInStock = 0 THEN 'Stockout'
    WHEN p.quantityInStock < COALESCE(l.units_90d,0)/3 THEN 'Low stock'
    WHEN p.quantityInStock > COALESCE(l.units_90d,0) THEN 'Potential overstock'
    ELSE 'Balanced'
END AS inventory_signal
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
