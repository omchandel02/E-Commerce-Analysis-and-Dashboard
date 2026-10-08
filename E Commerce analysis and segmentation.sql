USE ecommerce;

-- Calculate Total Net Sales, Total Quantity Sold, and Average Order Value	
SELECT ROUND(SUM(oi.line_total),2) AS "Total Net Sales", SUM(oi.quantity) AS "Total Quantity Sold", ROUND(SUM(line_total)/COUNT(DISTINCT o.order_id),2) AS "Avg Order Value"
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id;

-- Group total sales by Year and Month to analyze seasonal spikes.
SELECT date_format(o.order_date, '%M-%Y') AS month_year, ROUND(SUM(oi.line_total),2) AS "Net Sales"
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
GROUP BY month_year

-- Rank all product categories by Net Revenue, Total Gross Profit, and Discount Percentage.
SELECT p.category, ROUND(SUM(oi.line_total),2) AS "Net Revenue", SUM(oi.quantity) AS "Total Quantity", ROUND(SUM(oi.gross_sales),2) AS "Total Gross Sales", ROUND(SUM(oi.line_total) - SUM(p.unit_cost * oi.quantity),2) AS "Total Gross Profit", ROUND(SUM(oi.discount_amount),2) AS "Total Discount Amount"
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY SUM(oi.line_total) DESC;

-- Find the top reasons customers return items, the volume of returns per reason, and the total refunded money.
SELECT return_reason, COUNT(return_id) AS return_volume, ROUND(SUM(refund_amount),2) AS total_refunds, ROUND(COUNT(return_id) * 100/(SELECT COUNT(return_id) FROM returns),2) AS return_percentage
FROM returns
GROUP BY return_reason
ORDER BY total_refunds DESC;

-- Customer RFM segmentation
WITH customer_rfm AS(
SELECT customer_id, DATEDIFF("2025-12-31", MAX(order_date)) AS recency, COUNT(DISTINCT order_id) AS frequency,
SUM(order_subtotal) AS monetary
FROM orders
GROUP BY customer_id
),
rfm_scores AS(
SELECT customer_id,
NTILE(4) OVER(ORDER BY recency DESC) AS r_score,
NTILE(4) OVER(ORDER BY frequency ASC) AS f_score,
NTILE(4) OVER(ORDER BY monetary ASC) AS m_score
FROM customer_rfm
)
SELECT customer_id, r_score, f_score, m_score,
CASE 
        WHEN r_score = 4 AND f_score = 4 AND m_score = 4 THEN 'Champion'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal Customer'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
        WHEN r_score = 4 AND f_score = 1 THEN 'Recent New'
        ELSE 'Hibernating / Needs Attention'
    END AS customer_segment
FROM rfm_scores;