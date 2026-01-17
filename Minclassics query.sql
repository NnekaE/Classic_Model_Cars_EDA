SHOW TABLES;
SELECT 'customers' AS tbl, COUNT(*) AS row_count FROM customers;
UNION ALL SELECT 'orders', COUNT(*) FROM orders;

UNION ALL
SELECT 'orderdetails', COUNT(*) FROM orderdetails
UNION ALL
SELECT 'products', COUNT(*) FROM products;
EXPLAIN SELECT 'orders', COUNT(*) FROM orders;
SELECT * FROM products     LIMIT 10;
SELECT * FROM orders       LIMIT 10;
SELECT * FROM orderdetails LIMIT 10;
SELECT * FROM customers    LIMIT 10;

# Monthly revenue by product line (seasonality)
WITH sales AS (
  SELECT DATE_FORMAT(o.orderDate, '%Y-%m') AS ym,
         p.productLine,
         od.quantityOrdered * od.priceEach AS lineRevenue
  FROM orders o
  JOIN orderdetails od USING (orderNumber)
  JOIN products p USING (productCode)
  WHERE o.status IN ('Shipped','Resolved','On Hold','Disputed','In Process')
)
SELECT ym, productLine, ROUND(SUM(lineRevenue),2) AS revenue
FROM sales
GROUP BY ym, productLine
ORDER BY ym, revenue DESC;

#Inventory signal (recent demand vs. on‑hand)
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

#Topline Sales KPIs

WITH sales AS (
  SELECT o.orderDate,
         od.orderNumber,
         od.productCode,
         od.quantityOrdered,
         od.priceEach,
         od.quantityOrdered * od.priceEach AS lineRevenue
  FROM orders o
  JOIN orderdetails od USING (orderNumber)
  WHERE o.status IN ('Shipped','Resolved','On Hold','Disputed','In Process')
)
SELECT
  ROUND(SUM(lineRevenue),2)                                     AS total_revenue,
  SUM(quantityOrdered)                                          AS total_units,
  COUNT(DISTINCT orderNumber)                                   AS orders,
  ROUND(SUM(lineRevenue) / NULLIF(COUNT(DISTINCT orderNumber),0),2) AS avg_order_value
FROM sales;

#Seasonality & mix (monthly trend by product line + best sellers)

-- Monthly revenue by product line
WITH sales AS (
  SELECT DATE_FORMAT(o.orderDate, '%Y-%m') AS ym,
         p.productLine,
         od.quantityOrdered * od.priceEach AS lineRevenue
  FROM orders o
  JOIN orderdetails od USING (orderNumber)
  JOIN products p USING (productCode)
  WHERE o.status IN ('Shipped','Resolved','On Hold','Disputed','In Process')
)
SELECT ym, productLine, ROUND(SUM(lineRevenue),2) AS revenue
FROM sales
GROUP BY ym, productLine
ORDER BY ym, revenue DESC;

-- Best-selling products (revenue)
SELECT p.productCode, p.productName, p.productLine,
       SUM(od.quantityOrdered) AS units_sold,
       ROUND(SUM(od.quantityOrdered * od.priceEach),2) AS revenue
FROM orderdetails od
JOIN orders o USING (orderNumber)
JOIN products p USING (productCode)
WHERE o.status IN ('Shipped','Resolved','On Hold','Disputed','In Process')
GROUP BY p.productCode, p.productName, p.productLine
ORDER BY revenue DESC
LIMIT 25;

# Demand velocity vs. on‑hand → inventory signals (last 90 days)
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
         p.quantityInStock ASC, p.productName;

#Margin lens (gross profit &margin % by SKU)
SELECT p.productCode, p.productName, p.productLine,
       SUM(od.quantityOrdered) AS units_sold,
       ROUND(SUM(od.quantityOrdered * od.priceEach),2) AS revenue,
       ROUND(SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)),2) AS gross_profit,
       ROUND(100 * SUM(od.quantityOrdered * (od.priceEach - p.buyPrice))
                 / NULLIF(SUM(od.quantityOrdered * od.priceEach),0),2) AS gross_margin_pct
FROM orderdetails od
JOIN orders o USING (orderNumber)
JOIN products p USING (productCode)
WHERE o.status IN ('Shipped','Resolved','On Hold','Disputed','In Process')
GROUP BY p.productCode, p.productName, p.productLine
ORDER BY gross_profit DESC
LIMIT 25;

# Reorder‑point helper (rough cut)

SET @LEAD_DAYS := 14;  -- change as needed

WITH demand AS (
  SELECT od.productCode,
         SUM(od.quantityOrdered) AS units_90d
  FROM orderdetails od
  JOIN orders o USING (orderNumber)
  WHERE o.orderDate >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
    AND o.status IN ('Shipped','Resolved','On Hold','Disputed','In Process')
  GROUP BY od.productCode
),
calc AS (
  SELECT p.productCode, p.productName, p.productLine,
         p.quantityInStock,
         COALESCE(d.units_90d,0) / 90 AS avg_daily_demand
  FROM products p
  LEFT JOIN demand d ON d.productCode = p.productCode
)
SELECT productCode, productName, productLine,
       quantityInStock,
       ROUND(avg_daily_demand,2) AS avg_daily_demand,
       ROUND(quantityInStock / NULLIF(avg_daily_demand,0),1) AS projected_days_of_cover,
       ROUND((avg_daily_demand * @LEAD_DAYS) * 1.5, 1) AS reorder_point, -- simple safety factor
       CASE
         WHEN quantityInStock <= (avg_daily_demand * @LEAD_DAYS) * 1.5
           THEN 'Reorder recommended'
         ELSE 'OK'
       END AS action
FROM calc
ORDER BY action DESC, projected_days_of_cover ASC, productLine, productCode;
#Slow Movers (Day Since last Sale)
WITH last_sale AS (
  SELECT od.productCode, MAX(o.orderDate) AS last_sold_date
  FROM orderdetails od
  JOIN orders o USING (orderNumber)
  WHERE o.status IN ('Shipped','Resolved','On Hold','Disputed','In Process')
  GROUP BY od.productCode
)
SELECT p.productCode, p.productName, p.productLine,
       p.quantityInStock,
       ls.last_sold_date,
       DATEDIFF(CURDATE(), ls.last_sold_date) AS days_since_last_sale,
       CASE
         WHEN ls.last_sold_date IS NULL THEN 'Never sold'
         WHEN DATEDIFF(CURDATE(), ls.last_sold_date) > 180 THEN 'Very slow'
         WHEN DATEDIFF(CURDATE(), ls.last_sold_date) > 90  THEN 'Slow'
         ELSE 'Active'
       END AS movement_flag
FROM products p
LEFT JOIN last_sale ls ON ls.productCode = p.productCode
ORDER BY movement_flag DESC, days_since_last_sale DESC, quantityInStock DESC;
# Open‑order coverage (near‑term risk)

WITH open_demand AS (
  SELECT od.productCode, SUM(od.quantityOrdered) AS units_open
  FROM orderdetails od
  JOIN orders o USING (orderNumber)
  WHERE o.status IN ('In Process','On Hold')  -- adjust to your "unshipped" statuses
  GROUP BY od.productCode
)
SELECT p.productCode, p.productName, p.productLine,
       p.quantityInStock,
       COALESCE(od.units_open,0) AS units_open,
       (p.quantityInStock - COALESCE(od.units_open,0)) AS projected_balance,
       CASE
         WHEN (p.quantityInStock - COALESCE(od.units_open,0)) < 0 THEN 'Shortfall risk'
         WHEN (p.quantityInStock - COALESCE(od.units_open,0)) < 10 THEN 'Tight'
         ELSE 'Covered'
       END AS coverage_signal
FROM products p
LEFT JOIN open_demand od ON od.productCode = p.productCode
ORDER BY coverage_signal DESC, projected_balance ASC, productName;

# Storage planning proxy (value & units by product line)

SELECT productLine,
       SUM(quantityInStock) AS units_on_hand,
       ROUND(SUM(quantityInStock * buyPrice),2) AS cost_value_on_hand,
       ROUND(AVG(quantityInStock),1) AS avg_units_per_sku
FROM products
GROUP BY productLine
ORDER BY cost_value_on_hand DESC;

#(Optional) Save reusable views 

CREATE OR REPLACE VIEW vw_inventory_velocity_90d AS
WITH last_90 AS (
  SELECT od.productCode, SUM(od.quantityOrdered) AS units_90d
  FROM orderdetails od
  JOIN orders o USING (orderNumber)
  WHERE o.orderDate >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
    AND o.status IN ('Shipped','Resolved','On Hold','Disputed','In Process')
  GROUP BY od.productCode
)
SELECT p.productCode, p.productName, p.productLine, p.quantityInStock,
       COALESCE(l.units_90d,0) AS units_90d
FROM products p
LEFT JOIN last_90 l ON l.productCode = p.productCode;

CREATE OR REPLACE VIEW vw_monthly_line_revenue AS
SELECT DATE_FORMAT(o.orderDate, '%Y-%m') AS ym,
       p.productLine,
       ROUND(SUM(od.quantityOrdered * od.priceEach),2) AS revenue
FROM orders o
JOIN orderdetails od USING (orderNumber)
JOIN products p USING (productCode)
WHERE o.status IN ('Shipped','Resolved','On Hold','Disputed','In Process')
GROUP BY ym, p.productLine;

