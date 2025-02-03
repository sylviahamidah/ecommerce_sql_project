SELECT * FROM orders;
SELECT * FROM order_item_refunds;
SELECT * FROM products;
SELECT * FROM website_pageviews;
SELECT * FROM website_sessions;

-- CASE 1. PRODUCT ANALYSIS
-- Soal 1. Case Trend Analysis
SELECT
	EXTRACT(YEAR FROM created_at) AS year,
	EXTRACT(MONTH FROM created_at) AS month,
	SUM(items_purchased) AS number_of_sales,
	SUM(items_purchased * price_usd) AS total_revenue,
	SUM(price_usd - cogs_usd) AS total_margin
FROM orders
WHERE created_at < '2013-01-05'
GROUP BY 1, 2
ORDER BY 1, 2

-- Soal 2. Case Analyzing Effect of New Product
SELECT
	EXTRACT(YEAR FROM w.created_at) AS year,
	EXTRACT(MONTH FROM w.created_at) AS month,
	COUNT(DISTINCT o.order_id) AS orders,
	COUNT(DISTINCT w.website_session_id) AS sessions,
	COUNT(DISTINCT o.order_id)::float / COUNT(DISTINCT w.website_session_id) * 100 AS sessions_to_order_cvr,
	SUM(CASE WHEN o.primary_product_id = 1 THEN 1 ELSE 0 END) AS product_one_orders,
	SUM(CASE WHEN o.primary_product_id = 2 THEN 1 ELSE 0 END) AS product_two_orders
FROM website_sessions w
LEFT JOIN orders o
	USING(website_session_id)
WHERE w.created_at BETWEEN '2012-04-01' AND '2013-04-06'
GROUP BY 1, 2

-- CASE 2. USER ANALYSIS
-- Soal 1. Case Identifying Repeat Visitors
-- Step 1: Identify relevant new sessions
-- Step 2: Use user_id from step 1 to find any repeat sessions
-- Step 3: Analyze data, how many session did user have?
-- Step 4: Agregate the user-level analysis

WITH new_sessions AS(
	SELECT
		user_id,
		website_session_id
	FROM website_sessions
	WHERE created_at < '2014-11-01'
		AND created_at > '2014-01-01'
		AND is_repeat_session = 0
),
session_w_repeat AS(
SELECT
	ns.user_id,
	ns.website_session_id AS new_session_id,
	ws.website_session_id AS repeat_session_id
FROM new_sessions ns
LEFT JOIN website_sessions ws
	ON ns.user_id = ws.user_id
	AND ws.website_session_id > ns.website_session_id
	AND created_at < '2014-11-01'
	AND created_at > '2014-01-01'
	AND is_repeat_session = 1
),
user_level AS(
SELECT
	user_id,
	COUNT(DISTINCT new_session_id) AS count_new,
	COUNT(DISTINCT repeat_session_id) AS count_repeat
FROM session_w_repeat
GROUP BY 1)

SELECT
	count_repeat AS repeat_sessions,
	COUNT(DISTINCT user_id) AS users
FROM user_level
GROUP BY 1
