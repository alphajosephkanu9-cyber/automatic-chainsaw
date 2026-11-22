/*
PROJECT 2 — TURKISH CAFE & RESTAURANT SALES ANALYTICS
Database: turkish_cafe_analytics
SQL dialect: MySQL 8+

Dataset: simulated cafe/restaurant chain data, 2025.
Tables: branches, products, customers, orders, order_details.

BUSINESS RULES / LIMITATIONS
- Dataset is simulated. Do not describe the findings as real company results.
- Completed orders are used for regular sales analysis.
- Cancelled and Refunded orders are analysed separately.
- Sales below are gross sales BEFORE discounts: Quantity * Unit_Price.
- Discounts must be investigated before calculating discounted/net revenue.
  orders.Discount and order_details.Item_Discount may differ in meaning/units.
  Do not subtract both without understanding their definitions.
- Gross profit is product-level gross profit, not net profit. It excludes
  operating expenses, tax, rent, salaries, commissions and other expenses.
- A NULL Table_Number on takeaway/delivery orders is expected.

Run sections individually. Save/export useful result sets and document findings.
*/

USE turkish_cafe_analytics;


/* ================================================================
00 — DATABASE STRUCTURE AND VOLUME
================================================================ */

SHOW TABLES;
DESCRIBE branches;
DESCRIBE products;
DESCRIBE customers;
DESCRIBE orders;
DESCRIBE order_details;

SELECT 'branches' AS table_name, COUNT(*) AS row_count FROM branches
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'customers', COUNT(*) FROM customers
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_details', COUNT(*) FROM order_details;

SELECT
    MIN(Order_Date) AS first_order_date,
    MAX(Order_Date) AS last_order_date,
    COUNT(DISTINCT DATE(Order_Date)) AS days_with_orders
FROM orders;


/* ================================================================
01 — DATA QUALITY
================================================================ */

-- 1.1 Duplicate key checks. Each query should return no rows.
SELECT Branch_ID, COUNT(*) AS duplicates
FROM branches GROUP BY Branch_ID HAVING COUNT(*) > 1;

SELECT Product_ID, COUNT(*) AS duplicates
FROM products GROUP BY Product_ID HAVING COUNT(*) > 1;

SELECT Customer_ID, COUNT(*) AS duplicates
FROM customers GROUP BY Customer_ID HAVING COUNT(*) > 1;

SELECT Order_ID, COUNT(*) AS duplicates
FROM orders GROUP BY Order_ID HAVING COUNT(*) > 1;

SELECT Detail_ID, COUNT(*) AS duplicates
FROM order_details GROUP BY Detail_ID HAVING COUNT(*) > 1;

-- 1.2 Nulls in important fields.
SELECT
    SUM(Branch_ID IS NULL) AS null_branch_id,
    SUM(Branch_Name IS NULL) AS null_branch_name,
    SUM(City IS NULL) AS null_city
FROM branches;

SELECT
    SUM(Product_ID IS NULL) AS null_product_id,
    SUM(Product_Name IS NULL) AS null_product_name,
    SUM(Category IS NULL) AS null_category,
    SUM(Unit_Cost IS NULL) AS null_unit_cost,
    SUM(Selling_Price IS NULL) AS null_selling_price
FROM products;

SELECT
    SUM(Customer_ID IS NULL) AS null_customer_id,
    SUM(Registration_Date IS NULL) AS null_registration_date,
    SUM(City IS NULL) AS null_city
FROM customers;

SELECT
    SUM(Order_ID IS NULL) AS null_order_id,
    SUM(Order_Date IS NULL) AS null_order_date,
    SUM(Branch_ID IS NULL) AS null_branch_id,
    SUM(Customer_ID IS NULL) AS null_customer_id,
    SUM(Order_Type IS NULL) AS null_order_type,
    SUM(Order_Status IS NULL) AS null_order_status
FROM orders;

SELECT
    SUM(Detail_ID IS NULL) AS null_detail_id,
    SUM(Order_ID IS NULL) AS null_order_id,
    SUM(Product_ID IS NULL) AS null_product_id,
    SUM(Quantity IS NULL) AS null_quantity,
    SUM(Unit_Price IS NULL) AS null_unit_price,
    SUM(Unit_Cost IS NULL) AS null_unit_cost
FROM order_details;

-- 1.3 Table number nulls by order channel.
-- Nulls on takeaway/delivery are expected; assess dine-in separately.
SELECT
    Order_Type,
    COUNT(*) AS orders,
    SUM(Table_Number IS NULL) AS null_table_numbers
FROM orders
GROUP BY Order_Type;

-- 1.4 Foreign-key integrity. Each unmatched count should be zero.
SELECT COUNT(*) AS unmatched_branches
FROM orders o LEFT JOIN branches b ON o.Branch_ID = b.Branch_ID
WHERE b.Branch_ID IS NULL;

SELECT COUNT(*) AS unmatched_customers
FROM orders o LEFT JOIN customers c ON o.Customer_ID = c.Customer_ID
WHERE c.Customer_ID IS NULL;

SELECT COUNT(*) AS unmatched_orders
FROM order_details od LEFT JOIN orders o ON od.Order_ID = o.Order_ID
WHERE o.Order_ID IS NULL;

SELECT COUNT(*) AS unmatched_products
FROM order_details od LEFT JOIN products p ON od.Product_ID = p.Product_ID
WHERE p.Product_ID IS NULL;

-- 1.5 Quantity checks.
SELECT
    MIN(Quantity) AS minimum_quantity,
    MAX(Quantity) AS maximum_quantity,
    AVG(Quantity) AS average_quantity,
    SUM(Quantity <= 0) AS nonpositive_quantity_rows
FROM order_details;

-- 1.6 Price/cost checks.
SELECT
    MIN(Unit_Price) AS min_unit_price,
    MAX(Unit_Price) AS max_unit_price,
    MIN(Unit_Cost) AS min_unit_cost,
    MAX(Unit_Cost) AS max_unit_cost,
    SUM(Unit_Price < 0) AS negative_prices,
    SUM(Unit_Cost < 0) AS negative_costs,
    SUM(Unit_Price < Unit_Cost) AS lines_price_below_cost
FROM order_details;

-- 1.7 Discount range investigation. Do not interpret until confirmed.
SELECT
    MIN(Discount) AS min_order_discount,
    MAX(Discount) AS max_order_discount,
    AVG(Discount) AS avg_order_discount
FROM orders;

SELECT
    MIN(Item_Discount) AS min_item_discount,
    MAX(Item_Discount) AS max_item_discount,
    AVG(Item_Discount) AS avg_item_discount
FROM order_details;

SELECT Discount, COUNT(*) AS order_count
FROM orders
GROUP BY Discount
ORDER BY Discount;

SELECT Item_Discount, COUNT(*) AS detail_count
FROM order_details
GROUP BY Item_Discount
ORDER BY Item_Discount;


/* ================================================================
02 — OVERALL KPIs
================================================================ */

-- Completed orders only; sales/profit shown before discounts.
SELECT
    COUNT(DISTINCT o.Order_ID) AS completed_orders,
    COUNT(DISTINCT o.Customer_ID) AS unique_customers,
    COUNT(DISTINCT o.Branch_ID) AS branches_with_completed_orders,
    SUM(od.Quantity) AS units_sold,
    ROUND(SUM(od.Quantity * od.Unit_Price), 2) AS gross_sales_before_discounts,
    ROUND(SUM(od.Quantity * od.Unit_Cost), 2) AS product_cost,
    ROUND(SUM(od.Quantity * (od.Unit_Price - od.Unit_Cost)), 2) AS gross_profit_before_discounts,
    ROUND(
        100 * SUM(od.Quantity * (od.Unit_Price - od.Unit_Cost))
        / NULLIF(SUM(od.Quantity * od.Unit_Price), 0), 2
    ) AS gross_margin_pct_before_discounts,
    ROUND(
        SUM(od.Quantity * od.Unit_Price)
        / NULLIF(COUNT(DISTINCT o.Order_ID), 0), 2
    ) AS average_order_value_before_discounts
FROM orders o
JOIN order_details od ON o.Order_ID = od.Order_ID
WHERE o.Order_Status = 'Completed';

-- Order status distribution.
SELECT
    Order_Status,
    COUNT(*) AS order_count,
    ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM orders), 2) AS pct_all_orders
FROM orders
GROUP BY Order_Status
ORDER BY order_count DESC;


/* ================================================================
03 — TIME TRENDS
================================================================ */

-- 3.1 Monthly performance.
SELECT
    DATE_FORMAT(o.Order_Date, '%Y-%m') AS sales_month,
    COUNT(DISTINCT o.Order_ID) AS completed_orders,
    SUM(od.Quantity) AS units_sold,
    ROUND(SUM(od.Quantity * od.Unit_Price), 2) AS gross_sales_before_discounts,
    ROUND(SUM(od.Quantity * (od.Unit_Price - od.Unit_Cost)), 2) AS gross_profit_before_discounts
FROM orders o
JOIN order_details od ON o.Order_ID = od.Order_ID
WHERE o.Order_Status = 'Completed'
GROUP BY DATE_FORMAT(o.Order_Date, '%Y-%m')
ORDER BY sales_month;

-- 3.2 Day-of-week performance.
SELECT
    DAYNAME(o.Order_Date) AS day_name,
    WEEKDAY(o.Order_Date) AS weekday_index_monday_zero,
    COUNT(DISTINCT o.Order_ID) AS completed_orders,
    SUM(od.Quantity) AS units_sold,
    ROUND(SUM(od.Quantity * od.Unit_Price), 2) AS gross_sales_before_discounts
FROM orders o
JOIN order_details od ON o.Order_ID = od.Order_ID
WHERE o.Order_Status = 'Completed'
GROUP BY DAYNAME(o.Order_Date), WEEKDAY(o.Order_Date)
ORDER BY weekday_index_monday_zero;

-- 3.3 Hourly performance.
SELECT
    HOUR(o.Order_Time) AS order_hour,
    COUNT(DISTINCT o.Order_ID) AS completed_orders,
    SUM(od.Quantity) AS units_sold,
    ROUND(SUM(od.Quantity * od.Unit_Price), 2) AS gross_sales_before_discounts
FROM orders o
JOIN order_details od ON o.Order_ID = od.Order_ID
WHERE o.Order_Status = 'Completed'
GROUP BY HOUR(o.Order_Time)
ORDER BY order_hour;

-- 3.4 Monthly trend by service channel.
SELECT
    DATE_FORMAT(o.Order_Date, '%Y-%m') AS sales_month,
    o.Order_Type,
    COUNT(DISTINCT o.Order_ID) AS completed_orders,
    ROUND(SUM(od.Quantity * od.Unit_Price), 2) AS gross_sales_before_discounts
FROM orders o
JOIN order_details od ON o.Order_ID = od.Order_ID
WHERE o.Order_Status = 'Completed'
GROUP BY sales_month, o.Order_Type
ORDER BY sales_month, o.Order_Type;


/* ================================================================
04 — BRANCH PERFORMANCE
================================================================ */

SELECT
    b.Branch_ID,
    b.Branch_Name,
    b.City,
    b.District,
    b.Seating_Capacity,
    COUNT(DISTINCT o.Order_ID) AS completed_orders,
    COUNT(DISTINCT o.Customer_ID) AS customers,
    SUM(od.Quantity) AS units_sold,
    ROUND(SUM(od.Quantity * od.Unit_Price), 2) AS gross_sales_before_discounts,
    ROUND(SUM(od.Quantity * (od.Unit_Price - od.Unit_Cost)), 2) AS gross_profit_before_discounts,
    ROUND(
        100 * SUM(od.Quantity * (od.Unit_Price - od.Unit_Cost))
        / NULLIF(SUM(od.Quantity * od.Unit_Price), 0), 2
    ) AS gross_margin_pct_before_discounts,
    ROUND(
        SUM(od.Quantity * od.Unit_Price)
        / NULLIF(COUNT(DISTINCT o.Order_ID), 0), 2
    ) AS average_order_value
FROM branches b
LEFT JOIN orders o
    ON b.Branch_ID = o.Branch_ID AND o.Order_Status = 'Completed'
LEFT JOIN order_details od ON o.Order_ID = od.Order_ID
GROUP BY b.Branch_ID, b.Branch_Name, b.City, b.District, b.Seating_Capacity
ORDER BY gross_sales_before_discounts DESC;

-- Branch-by-month comparison.
SELECT
    b.Branch_Name,
    b.City,
    DATE_FORMAT(o.Order_Date, '%Y-%m') AS sales_month,
    COUNT(DISTINCT o.Order_ID) AS completed_orders,
    ROUND(SUM(od.Quantity * od.Unit_Price), 2) AS gross_sales_before_discounts
FROM branches b
JOIN orders o ON b.Branch_ID = o.Branch_ID
JOIN order_details od ON o.Order_ID = od.Order_ID
WHERE o.Order_Status = 'Completed'
GROUP BY b.Branch_Name, b.City, sales_month
ORDER BY b.Branch_Name, sales_month;


/* ================================================================
05 — PRODUCT PERFORMANCE
================================================================ */

-- Full product performance.
SELECT
    p.Product_ID,
    p.Product_Name,
    p.Category,
    COUNT(DISTINCT o.Order_ID) AS orders_containing_product,
    SUM(od.Quantity) AS units_sold,
    ROUND(SUM(od.Quantity * od.Unit_Price), 2) AS gross_sales_before_discounts,
    ROUND(SUM(od.Quantity * od.Unit_Cost), 2) AS product_cost,
    ROUND(SUM(od.Quantity * (od.Unit_Price - od.Unit_Cost)), 2) AS gross_profit_before_discounts,
    ROUND(
        100 * SUM(od.Quantity * (od.Unit_Price - od.Unit_Cost))
        / NULLIF(SUM(od.Quantity * od.Unit_Price), 0), 2
    ) AS gross_margin_pct_before_discounts
FROM products p
JOIN order_details od ON p.Product_ID = od.Product_ID
JOIN orders o ON od.Order_ID = o.Order_ID
WHERE o.Order_Status = 'Completed'
GROUP BY p.Product_ID, p.Product_Name, p.Category
ORDER BY gross_sales_before_discounts DESC;

-- Top ten by volume.
SELECT
    p.Product_Name,
    p.Category,
    SUM(od.Quantity) AS units_sold,
    ROUND(SUM(od.Quantity * od.Unit_Price), 2) AS gross_sales_before_discounts
FROM products p
JOIN order_details od ON p.Product_ID = od.Product_ID
JOIN orders o ON od.Order_ID = o.Order_ID
WHERE o.Order_Status = 'Completed'
GROUP BY p.Product_ID, p.Product_Name, p.Category
ORDER BY units_sold DESC
LIMIT 10;

-- Top ten by gross profit.
SELECT
    p.Product_Name,
    p.Category,
    SUM(od.Quantity) AS units_sold,
    ROUND(SUM(od.Quantity * (od.Unit_Price - od.Unit_Cost)), 2) AS gross_profit_before_discounts
FROM products p
JOIN order_details od ON p.Product_ID = od.Product_ID
JOIN orders o ON od.Order_ID = o.Order_ID
WHERE o.Order_Status = 'Completed'
GROUP BY p.Product_ID, p.Product_Name, p.Category
ORDER BY gross_profit_before_discounts DESC
LIMIT 10;


/* ================================================================
06 — CATEGORY PERFORMANCE
================================================================ */

SELECT
    p.Category,
    COUNT(DISTINCT p.Product_ID) AS products_in_category,
    COUNT(DISTINCT o.Order_ID) AS completed_orders_with_category,
    SUM(od.Quantity) AS units_sold,
    ROUND(SUM(od.Quantity * od.Unit_Price), 2) AS gross_sales_before_discounts,
    ROUND(SUM(od.Quantity * (od.Unit_Price - od.Unit_Cost)), 2) AS gross_profit_before_discounts,
    ROUND(
        100 * SUM(od.Quantity * (od.Unit_Price - od.Unit_Cost))
        / NULLIF(SUM(od.Quantity * od.Unit_Price), 0), 2
    ) AS gross_margin_pct_before_discounts
FROM products p
JOIN order_details od ON p.Product_ID = od.Product_ID
JOIN orders o ON od.Order_ID = o.Order_ID
WHERE o.Order_Status = 'Completed'
GROUP BY p.Category
ORDER BY gross_sales_before_discounts DESC;


/* ================================================================
07 — CUSTOMER ANALYSIS
================================================================ */

-- Customer-type metrics.
SELECT
    c.Customer_Type,
    COUNT(DISTINCT c.Customer_ID) AS customers_with_completed_orders,
    COUNT(DISTINCT o.Order_ID) AS completed_orders,
    SUM(od.Quantity) AS units_purchased,
    ROUND(SUM(od.Quantity * od.Unit_Price), 2) AS gross_sales_before_discounts,
    ROUND(
        SUM(od.Quantity * od.Unit_Price)
        / NULLIF(COUNT(DISTINCT o.Order_ID), 0), 2
    ) AS average_order_value
FROM customers c
JOIN orders o ON c.Customer_ID = o.Customer_ID
JOIN order_details od ON o.Order_ID = od.Order_ID
WHERE o.Order_Status = 'Completed'
GROUP BY c.Customer_Type
ORDER BY gross_sales_before_discounts DESC;

-- Top 20 customers by gross sales. For portfolio publication, avoid exposing names.
SELECT
    c.Customer_ID,
    c.City,
    c.Customer_Type,
    COUNT(DISTINCT o.Order_ID) AS completed_orders,
    SUM(od.Quantity) AS units_purchased,
    ROUND(SUM(od.Quantity * od.Unit_Price), 2) AS gross_sales_before_discounts
FROM customers c
JOIN orders o ON c.Customer_ID = o.Customer_ID
JOIN order_details od ON o.Order_ID = od.Order_ID
WHERE o.Order_Status = 'Completed'
GROUP BY c.Customer_ID, c.City, c.Customer_Type
ORDER BY gross_sales_before_discounts DESC
LIMIT 20;

-- Purchase-frequency distribution.
WITH customer_frequency AS (
    SELECT Customer_ID, COUNT(DISTINCT Order_ID) AS completed_order_count
    FROM orders
    WHERE Order_Status = 'Completed'
    GROUP BY Customer_ID
)
SELECT
    completed_order_count,
    COUNT(*) AS customer_count
FROM customer_frequency
GROUP BY completed_order_count
ORDER BY completed_order_count;

-- Customer geography.
SELECT City, COUNT(*) AS customer_count
FROM customers
GROUP BY City
ORDER BY customer_count DESC;


/* ================================================================
08 — ORDER CHANNEL AND PAYMENT
================================================================ */

-- Order channel: volume, sales and AOV.
SELECT
    o.Order_Type,
    COUNT(DISTINCT o.Order_ID) AS completed_orders,
    SUM(od.Quantity) AS units_sold,
    ROUND(SUM(od.Quantity * od.Unit_Price), 2) AS gross_sales_before_discounts,
    ROUND(
        SUM(od.Quantity * od.Unit_Price)
        / NULLIF(COUNT(DISTINCT o.Order_ID), 0), 2
    ) AS average_order_value
FROM orders o
JOIN order_details od ON o.Order_ID = od.Order_ID
WHERE o.Order_Status = 'Completed'
GROUP BY o.Order_Type
ORDER BY gross_sales_before_discounts DESC;

-- Payment method.
SELECT
    o.Payment_Method,
    COUNT(DISTINCT o.Order_ID) AS completed_orders,
    ROUND(SUM(od.Quantity * od.Unit_Price), 2) AS gross_sales_before_discounts,
    ROUND(
        100 * COUNT(DISTINCT o.Order_ID)
        / NULLIF((SELECT COUNT(*) FROM orders WHERE Order_Status = 'Completed'), 0), 2
    ) AS pct_completed_orders
FROM orders o
JOIN order_details od ON o.Order_ID = od.Order_ID
WHERE o.Order_Status = 'Completed'
GROUP BY o.Payment_Method
ORDER BY completed_orders DESC;

-- Channel crossed with payment method.
SELECT
    o.Order_Type,
    o.Payment_Method,
    COUNT(DISTINCT o.Order_ID) AS completed_orders,
    ROUND(SUM(od.Quantity * od.Unit_Price), 2) AS gross_sales_before_discounts
FROM orders o
JOIN order_details od ON o.Order_ID = od.Order_ID
WHERE o.Order_Status = 'Completed'
GROUP BY o.Order_Type, o.Payment_Method
ORDER BY o.Order_Type, completed_orders DESC;


/* ================================================================
09 — DISCOUNT INVESTIGATION
================================================================ */

-- Compare ranges and distributions of both discount fields.
-- Confirm units/semantics before deriving net sales.
SELECT
    'orders.Discount' AS field_name,
    MIN(Discount) AS min_value,
    MAX(Discount) AS max_value,
    AVG(Discount) AS average_value,
    COUNT(*) AS records
FROM orders
UNION ALL
SELECT
    'order_details.Item_Discount',
    MIN(Item_Discount),
    MAX(Item_Discount),
    AVG(Item_Discount),
    COUNT(*)
FROM order_details;

-- Order discount values by order status.
SELECT
    Order_Status,
    COUNT(*) AS orders,
    MIN(Discount) AS minimum_discount,
    MAX(Discount) AS maximum_discount,
    AVG(Discount) AS average_discount
FROM orders
GROUP BY Order_Status;

-- Item discount values by category.
SELECT
    p.Category,
    COUNT(*) AS detail_rows,
    MIN(od.Item_Discount) AS minimum_item_discount,
    MAX(od.Item_Discount) AS maximum_item_discount,
    AVG(od.Item_Discount) AS average_item_discount
FROM order_details od
JOIN products p ON od.Product_ID = p.Product_ID
GROUP BY p.Category
ORDER BY average_item_discount DESC;


/* ================================================================
10 — CANCELLATIONS AND REFUNDS
================================================================ */

-- Status distribution by branch.
SELECT
    b.Branch_Name,
    b.City,
    o.Order_Status,
    COUNT(*) AS order_count,
    ROUND(
        100 * COUNT(*) /
        NULLIF(SUM(COUNT(*)) OVER (PARTITION BY b.Branch_ID), 0), 2
    ) AS pct_of_branch_orders
FROM branches b
JOIN orders o ON b.Branch_ID = o.Branch_ID
GROUP BY b.Branch_ID, b.Branch_Name, b.City, o.Order_Status
ORDER BY b.Branch_Name, o.Order_Status;

-- Status distribution by channel.
SELECT
    Order_Type,
    Order_Status,
    COUNT(*) AS order_count
FROM orders
GROUP BY Order_Type, Order_Status
ORDER BY Order_Type, Order_Status;

-- Status distribution by payment method.
SELECT
    Payment_Method,
    Order_Status,
    COUNT(*) AS order_count
FROM orders
GROUP BY Payment_Method, Order_Status
ORDER BY Payment_Method, Order_Status;

-- Cancelled/refunded orders by month.
SELECT
    DATE_FORMAT(Order_Date, '%Y-%m') AS order_month,
    Order_Status,
    COUNT(*) AS order_count
FROM orders
WHERE Order_Status IN ('Cancelled', 'Refunded')
GROUP BY order_month, Order_Status
ORDER BY order_month, Order_Status;

-- Products appearing on refunded orders.
-- Listed value is not necessarily the amount actually refunded.
SELECT
    p.Product_Name,
    p.Category,
    COUNT(DISTINCT o.Order_ID) AS refunded_orders_with_product,
    SUM(od.Quantity) AS units_on_refunded_orders,
    ROUND(SUM(od.Quantity * od.Unit_Price), 2) AS listed_value_before_discounts
FROM orders o
JOIN order_details od ON o.Order_ID = od.Order_ID
JOIN products p ON od.Product_ID = p.Product_ID
WHERE o.Order_Status = 'Refunded'
GROUP BY p.Product_ID, p.Product_Name, p.Category
ORDER BY refunded_orders_with_product DESC;


/* ================================================================
11 — PRODUCT PAIR / CROSS-SELLING
================================================================ */

-- Product pairs bought together in completed orders.
SELECT
    p1.Product_Name AS product_1,
    p2.Product_Name AS product_2,
    COUNT(DISTINCT od1.Order_ID) AS orders_with_both
FROM order_details od1
JOIN order_details od2
    ON od1.Order_ID = od2.Order_ID
   AND od1.Product_ID < od2.Product_ID
JOIN orders o ON od1.Order_ID = o.Order_ID
JOIN products p1 ON od1.Product_ID = p1.Product_ID
JOIN products p2 ON od2.Product_ID = p2.Product_ID
WHERE o.Order_Status = 'Completed'
GROUP BY p1.Product_ID, p1.Product_Name, p2.Product_ID, p2.Product_Name
ORDER BY orders_with_both DESC
LIMIT 20;


/* ================================================================
12 — DATA EXPORTS FOR POWER BI (OPTIONAL)
================================================================ */

-- Export 12.1: One row per completed order.
SELECT
    o.Order_ID,
    o.Order_Date,
    o.Order_Time,
    o.Branch_ID,
    o.Customer_ID,
    o.Order_Type,
    o.Payment_Method,
    o.Discount AS stored_order_discount,
    COUNT(od.Detail_ID) AS line_count,
    SUM(od.Quantity) AS total_units,
    ROUND(SUM(od.Quantity * od.Unit_Price), 2) AS gross_sales_before_discounts,
    ROUND(SUM(od.Quantity * od.Unit_Cost), 2) AS product_cost,
    ROUND(SUM(od.Quantity * (od.Unit_Price - od.Unit_Cost)), 2) AS gross_profit_before_discounts
FROM orders o
JOIN order_details od ON o.Order_ID = od.Order_ID
WHERE o.Order_Status = 'Completed'
GROUP BY
    o.Order_ID, o.Order_Date, o.Order_Time, o.Branch_ID, o.Customer_ID,
    o.Order_Type, o.Payment_Method, o.Discount;

-- Export 12.2: One row per completed order detail (product line).
SELECT
    od.Detail_ID,
    od.Order_ID,
    o.Order_Date,
    o.Order_Time,
    o.Branch_ID,
    o.Customer_ID,
    o.Order_Type,
    o.Payment_Method,
    p.Product_ID,
    p.Product_Name,
    p.Category,
    od.Quantity,
    od.Unit_Price,
    od.Unit_Cost,
    od.Item_Discount AS stored_item_discount,
    ROUND(od.Quantity * od.Unit_Price, 2) AS line_sales_before_discounts,
    ROUND(od.Quantity * od.Unit_Cost, 2) AS line_product_cost,
    ROUND(od.Quantity * (od.Unit_Price - od.Unit_Cost), 2) AS line_gross_profit_before_discounts
FROM order_details od
JOIN orders o ON od.Order_ID = o.Order_ID
JOIN products p ON od.Product_ID = p.Product_ID
WHERE o.Order_Status = 'Completed';

-- Export dimensions if needed.
SELECT * FROM branches;
SELECT * FROM products;
SELECT * FROM customers;


/* ================================================================
13 — FINDINGS / PORTFOLIO CHECKLIST
================================================================

For every analysis, document:
1. Question/business objective.
2. SQL query used.
3. Key result (actual numbers).
4. Insight (what the result indicates; avoid unsupported causes).
5. Recommendation (action and why).
6. Limitation/assumption.

Analysis checklist:
[ ] Overall KPIs
[ ] Monthly sales trend
[ ] Weekday trend
[ ] Hourly demand
[ ] Branch comparison and branch monthly trend
[ ] Product performance by sales, units and gross profit
[ ] Category performance
[ ] Customer type and frequency
[ ] Customer city distribution
[ ] Order-channel sales, volume and AOV
[ ] Payment method mix
[ ] Discount semantics and discount analysis
[ ] Cancellation/refund patterns
[ ] Product combinations
[ ] Power BI dashboard pages: Executive Overview, Branch Performance,
    Product & Category, Customer Insights, Operations

Do not claim a recommendation is proven unless the data supports it.
*/
