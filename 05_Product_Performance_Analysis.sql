5.1 — Best-Selling Products by Quantity
SELECT
    p.Product_ID,
    p.Product_Name,
    SUM(od.Quantity) AS Total_Units_Sold,
    COUNT(DISTINCT o.Order_ID) AS Number_of_Orders,
    ROUND(SUM(od.Quantity * od.Unit_Price *(1 - COALESCE(od.Item_Discount, 0))), 2) AS Total_Revenue
FROM orders o
JOIN order_details od
    ON o.Order_ID = od.Order_ID
JOIN products p
    ON od.Product_ID = p.Product_ID
WHERE o.Order_Status = 'Completed'
GROUP BY
    p.Product_ID,
    p.Product_Name
ORDER BY Total_Units_Sold DESC
LIMIT 15;

5.2 — Top Products by Revenue
SELECT
    p.Product_ID,
    p.Product_Name,
    SUM(od.Quantity) AS Total_Units_Sold,
    COUNT(DISTINCT o.Order_ID) AS Number_of_Orders,
    ROUND(SUM(od.Quantity * od.Unit_Price *(1 - COALESCE(od.Item_Discount, 0))),2) AS Total_Revenue
FROM orders o
JOIN order_details od
    ON o.Order_ID = od.Order_ID
JOIN products p
    ON od.Product_ID = p.Product_ID
WHERE o.Order_Status = 'Completed'
GROUP BY
    p.Product_ID,
    p.Product_Name
ORDER BY Total_Revenue DESC
LIMIT 15;

5.3 — Product Profitability
SELECT
    p.Product_ID,
    p.Product_Name,
    SUM(od.Quantity) AS Total_Units_Sold,
    ROUND(SUM(od.Quantity * od.Unit_Price *(1 - COALESCE(od.Item_Discount, 0))),2) AS Total_Revenue,
    ROUND(SUM(od.Quantity * od.Unit_Cost),2) AS Total_Cost,
    ROUND(SUM(od.Quantity * od.Unit_Price *(1 - COALESCE(od.Item_Discount, 0))) -SUM(od.Quantity * od.Unit_Cost),2) AS Gross_Profit,
    ROUND((SUM(od.Quantity * od.Unit_Price *(1 - COALESCE(od.Item_Discount, 0))) -SUM(od.Quantity * od.Unit_Cost)) /NULLIF(
    SUM(od.Quantity * od.Unit_Price *(1 - COALESCE(od.Item_Discount, 0))),0) * 100,2) AS Gross_Profit_Margin
FROM orders o
JOIN order_details od
    ON o.Order_ID = od.Order_ID
JOIN products p
    ON od.Product_ID = p.Product_ID
WHERE o.Order_Status = 'Completed'
GROUP BY
    p.Product_ID,
    p.Product_Name
ORDER BY Gross_Profit DESC
LIMIT 15;

5.4 — Identifying Underperforming Products
WITH Product_Performance AS (
    SELECT
        od.Product_ID,
        SUM(od.Quantity) AS Total_Units_Sold,
        SUM(od.Quantity * od.Unit_Price *(1 - COALESCE(od.Item_Discount, 0))) AS Total_Revenue,
        SUM(od.Quantity * od.Unit_Cost) AS Total_Cost,
        SUM(od.Quantity * od.Unit_Price *(1 - COALESCE(od.Item_Discount, 0))) - SUM(od.Quantity * od.Unit_Cost) AS Gross_Profit
    FROM orders o
    JOIN order_details od
        ON o.Order_ID = od.Order_ID
    WHERE o.Order_Status = 'Completed'
    GROUP BY od.Product_ID
)
SELECT
    p.Product_ID,
    p.Product_Name,
    COALESCE(pp.Total_Units_Sold, 0) AS Total_Units_Sold,
    ROUND(COALESCE(pp.Total_Revenue, 0), 2) AS Total_Revenue,
    ROUND(COALESCE(pp.Total_Cost, 0), 2) AS Total_Cost,
    ROUND(COALESCE(pp.Gross_Profit, 0), 2) AS Gross_Profit
FROM products p
LEFT JOIN Product_Performance pp
    ON p.Product_ID = pp.Product_ID
ORDER BY Gross_Profit ASC
LIMIT 15;
