-- PURPOSE: Assess discounts, revenue by branch/order type, and monthly revenue performance.

-- ANALYSIS 4.1: ORDER-LEVEL DISCOUNT ASSESSMENT
-- ============================================================

SELECT
    COUNT(*) AS Total_Orders,
    COUNT(Discount) AS Orders_With_Discount_Value,
    SUM(CASE WHEN Discount IS NULL THEN 1 ELSE 0 END) AS Missing_Discount_Values,
    MIN(Discount) AS Minimum_Discount,
    MAX(Discount) AS Maximum_Discount,
    ROUND(AVG(Discount), 4) AS Average_Discount,
    SUM(CASE WHEN Discount = 0 THEN 1 ELSE 0 END) AS Zero_Discount_Orders,
    SUM(CASE WHEN Discount > 0 THEN 1 ELSE 0 END) AS Positive_Discount_Orders
FROM orders;


-- ANALYSIS 4.2: RELATIONSHIP BETWEEN ORDER-LEVEL AND ITEM-LEVEL DISCOUNTS
-- ============================================================

-- Sample of completed orders with the highest order-level discounts.
SELECT
    o.Order_ID,
    o.Discount AS Order_Discount,
    ROUND(AVG(od.Item_Discount), 4) AS Average_Item_Discount,
    COUNT(*) AS Number_of_Items
FROM orders o
JOIN order_details od
    ON o.Order_ID = od.Order_ID
WHERE o.Order_Status = 'Completed'
GROUP BY o.Order_ID, o.Discount
ORDER BY o.Discount DESC
LIMIT 20;


-- Count completed orders by order discount and item-discount status.
SELECT
    o.Discount AS Order_Discount,
    CASE
        WHEN item_summary.Has_Item_Discount = 1
            THEN 'With Item Discount'
        ELSE 'Without Item Discount'
    END AS Item_Discount_Status,
    COUNT(*) AS Number_of_Orders,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*)
         FROM orders
         WHERE Order_Status = 'Completed'),
        2
    ) AS Percentage_of_Completed_Orders
FROM orders o
JOIN (
    SELECT
        Order_ID,
        MAX(CASE WHEN Item_Discount > 0 THEN 1 ELSE 0 END)
            AS Has_Item_Discount
    FROM order_details
    GROUP BY Order_ID
) item_summary
    ON o.Order_ID = item_summary.Order_ID
WHERE o.Order_Status = 'Completed'
GROUP BY o.Discount, item_summary.Has_Item_Discount
ORDER BY o.Discount DESC, item_summary.Has_Item_Discount DESC;

-- ANALYSIS 4.3: REVENUE BY BRANCH
  ============================================================

WITH Order_Revenue AS (
    SELECT
        o.Order_ID,
        o.Branch_ID,
        COALESCE(o.Discount, 0) AS Order_Discount,
        SUM(od.Quantity * od.Unit_Price) AS Gross_Revenue,
        SUM( od.Quantity * od.Unit_Price * (1 - COALESCE(od.Item_Discount, 0)

-- ANALYSIS 4.4: REVENUE BY ORDER TYPE
-- ============================================================

WITH Order_Revenue AS (
    SELECT
        o.Order_ID,
        o.Order_Type,
        COALESCE(o.Discount, 0) AS Order_Discount,
        SUM(od.Quantity * od.Unit_Price) AS Gross_Revenue,
        SUM(
            od.Quantity * od.Unit_Price *
            (1 - COALESCE(od.Item_Discount, 0))
        ) AS Revenue_After_Item_Discount
    FROM orders o
    JOIN order_details od
        ON o.Order_ID = od.Order_ID
    WHERE o.Order_Status = 'Completed'
    GROUP BY o.Order_ID, o.Order_Type, o.Discount
)
SELECT
    COALESCE(Order_Type, 'Unknown') AS Order_Type,
    COUNT(*) AS Completed_Orders,
    ROUND(SUM(Gross_Revenue), 2) AS Gross_Revenue,
    ROUND(SUM(Revenue_After_Item_Discount), 2)
        AS Revenue_After_Item_Discount,
    ROUND(
        SUM(Revenue_After_Item_Discount * (1 - Order_Discount)),
        2
    ) AS Revenue_After_Both_Discounts,
    ROUND(
        SUM(Revenue_After_Item_Discount) / COUNT(*),
        2
    ) AS Average_Order_Value,
    ROUND(
        SUM(Revenue_After_Item_Discount * (1 - Order_Discount))
        / COUNT(*),
        2
    ) AS Adjusted_Average_Order_Value
FROM Order_Revenue
GROUP BY Order_Type
ORDER BY Revenue_After_Item_Discount DESC;


-- ANALYSIS 4.5: MONTHLY REVENUE TREND
-- ============================================================

SELECT
    DATE_FORMAT(
        STR_TO_DATE(o.Order_Date, '%Y-%m-%d'),
        '%Y-%m'
    ) AS Revenue_Month,
    COUNT(DISTINCT o.Order_ID) AS Completed_Orders,
    ROUND(
        SUM(
            od.Quantity * od.Unit_Price *
            (1 - COALESCE(od.Item_Discount, 0))
        ),
        2
    ) AS Monthly_Revenue,
    ROUND(
        SUM(
            od.Quantity * od.Unit_Price *
            (1 - COALESCE(od.Item_Discount, 0))
        ) / COUNT(DISTINCT o.Order_ID),
        2
    ) AS Average_Order_Value
FROM orders o
JOIN order_details od
    ON o.Order_ID = od.Order_ID
WHERE o.Order_Status = 'Completed'
GROUP BY Revenue_Month
ORDER BY Revenue_Month;
