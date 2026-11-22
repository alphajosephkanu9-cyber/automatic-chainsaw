```sql
-- PROJECT: TURKISH RESTAURANT & CAFE BUSINESS ANALYSIS
-- SECTION 3: ORDER PERFORMANCE ANALYSIS
-- DATABASE: turkish_cafe_analytics
--
-- OBJECTIVE:
-- Analyze order status, branch performance, and order type
-- performance to identify operational strengths and weaknesses.




-- ANALYSIS 3.1: ORDER STATUS DISTRIBUTION
-- OBJECTIVE:
-- Calculate the number and percentage of completed, cancelled,
-- and refunded orders across the business.


SELECT
    Order_Status,
    COUNT(*) AS Total_Orders,
    ROUND(COUNT(*) * 100.0 /(SELECT COUNT(*) FROM orders),2) AS Percentage_of_Orders
FROM orders
GROUP BY Order_Status
ORDER BY Total_Orders DESC;


-- ANALYSIS 3.2: ORDER PERFORMANCE BY BRANCH
-- OBJECTIVE:
-- Compare order volumes, completed orders, cancellations,
-- and refunds across all restaurant branches.

SELECT
    b.Branch_ID,
    b.Branch_Name,
    COUNT(o.Order_ID) AS Total_Orders,
    SUM(
        CASE
            WHEN o.Order_Status = 'Completed' THEN 1 ELSE 0
        END
    ) AS Completed_Orders,
    SUM(
        CASE
            WHEN o.Order_Status = 'Cancelled' THEN 1 ELSE 0
        END
    ) AS Cancelled_Orders,
    SUM(
        CASE
            WHEN o.Order_Status = 'Refunded' THEN 1 ELSE 0
        END
    ) AS Refunded_Orders,
    ROUND(
        SUM(
            CASE
                WHEN o.Order_Status = 'Cancelled' THEN 1 ELSE 0
            END
        ) * 100.0 / COUNT(o.Order_ID),
        2
    ) AS Cancellation_Rate,
    ROUND(SUM(
            CASE
                WHEN o.Order_Status = 'Refunded' THEN 1 ELSE 0
            END
        ) * 100.0 / COUNT(o.Order_ID),2) AS Refund_Rate

FROM orders o
JOIN branches b
    ON o.Branch_ID = b.Branch_ID

GROUP BY
    b.Branch_ID,
    b.Branch_Name

ORDER BY Total_Orders DESC;


-- ANALYSIS 3.3: ORDER PERFORMANCE BY ORDER TYPE
-- OBJECTIVE:
-- Compare Dine-in, Takeaway, and Delivery based on order volume,
-- completion rate, cancellation rate, and refund rate.

SELECT
    COALESCE(Order_Type, 'Unknown') AS Order_Type,
    COUNT(DISTINCT Order_id) AS Total_Orders,
    COUNT(DISTINCT CASE
        WHEN Order_Status = 'Completed' THEN Order_id
    END) AS Completed_Orders,
    COUNT(DISTINCT CASE
        WHEN Order_Status = 'Cancelled' THEN Order_id
    END) AS Cancelled_Orders,
    COUNT(DISTINCT CASE
        WHEN Order_Status = 'Refunded' THEN Order_id
    END) AS Refunded_Orders,
    ROUND(
        COUNT(DISTINCT CASE
            WHEN Order_Status = 'Completed' THEN Order_id
        END) * 100.0 /
        COUNT(DISTINCT Order_id),2) AS Completion_Rate,
    ROUND(
        COUNT(DISTINCT CASE
            WHEN Order_Status = 'Cancelled'THEN Order_id
        END) * 100.0 /
        COUNT(DISTINCT Order_id),2) AS Cancellation_Rate,
    ROUND(COUNT(DISTINCT CASE
            WHEN Order_Status = 'Refunded'THEN Order_id
        END) * 100.0 /
        COUNT(DISTINCT Order_id),2) AS Refund_Rate
FROM orders
GROUP BY Order_Type
ORDER BY Total_Orders DESC;
