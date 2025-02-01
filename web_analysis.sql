SELECT * FROM website_sessions;
SELECT * FROM orders;
SELECT * FROM website_pageviews;

-- CASE 1. ANALYZING TRAFFING SOURCE
-- Soal 1. Case Traffic Source
-- Sumber session yang paling banyak mendatangkan traffic
-- Breakdown by utm_source, utm_campaign, http_referer
SELECT
	utm_source,
	utm_campaign,
	http_referer,
	COUNT(website_session_id) AS sessions
FROM website_sessions
WHERE created_at < '2012-04-13'
GROUP BY utm_source, utm_campaign, http_referer
ORDER BY sessions DESC;

-- Soal 2. Conversion Rate Top Traffic Source
-- Traffic terbesar didapatkan dari gsearch nonbrand
-- Perusahaan ingin mengetahui apakah traffic tersebut mendatangkan sales
-- Menargetkan min 5% conversion rates
SELECT
	COUNT(DISTINCT o.order_id) AS orders,
	COUNT(DISTINCT w.website_session_id) AS sessions,
	COUNT(DISTINCT o.order_id)::float / COUNT(DISTINCT w.website_session_id) * 100 AS cvr
FROM orders o
RIGHT JOIN website_sessions w
	USING(website_session_id)
WHERE w.utm_source = 'gsearch' 
	AND w.utm_campaign = 'nonbrand' 
	AND w.created_at < '2012-04-14'

-- Soal 3. Trend volume traffic/session mingguan
SELECT
	EXTRACT(WEEK FROM created_at) AS week,
	MIN(DATE(created_at)) AS week_start_date,
	COUNT(DISTINCT website_session_id) AS sessions
FROM website_sessions
WHERE created_at < '2012-05-11'
	AND utm_source = 'gsearch' 
	AND utm_campaign = 'nonbrand'
GROUP BY EXTRACT(WEEK FROM created_at)
ORDER BY week ASC;

-- Soal 4. Case Bid Optimization for Paid Traffic
SELECT
	COUNT(DISTINCT o.order_id) AS orders,
	COUNT(DISTINCT w.website_session_id) AS sessions,
	device_type,
	COUNT(DISTINCT o.order_id)::float / COUNT(DISTINCT w.website_session_id) * 100 AS cvr
FROM orders o
RIGHT JOIN website_sessions w
	USING(website_session_id)
WHERE w.utm_source = 'gsearch' 
	AND w.utm_campaign = 'nonbrand' 
	AND w.created_at < '2012-05-12'
GROUP By device_type;

-- CASE 2. ANALYZING WEBSITE PERFORMANCE
-- Soal 1. Case Top Website Pages
SELECT
	pageview_url,
	COUNT(DISTINCT website_session_id) AS sessions
FROM website_pageviews
WHERE created_at < '2012-06-10'
GROUP BY pageview_url
ORDER BY sessions DESC;

-- Soal 2. Case Top Entry Pages
-- First page view by session
WITH first_page_view_by_session AS(
SELECT
	website_session_id,
	MIN(website_pageview_id) AS first_page_id
FROM website_pageviews
WHERE created_at < '2012-06-13'
GROUP BY 1
)

SELECT
	wp.pageview_url,
	COUNT(fp.website_session_id) AS session_count
FROM first_page_view_by_session fp
LEFT JOIN website_pageviews wp
 ON(fp.first_page_id = wp.website_pageview_id)
GROUP BY 1

-- Soal 3. Case Bounce Rate Analysis
-- Step 1. Identifikasi first website pageview for relevant session
-- Identifikasi landing page tiap session
-- Menghitung pageview for each session to identify bounces
-- Summary by counting total session, bounced session, dan bounce rate
WITH first_page_view_by_session AS(
SELECT
	website_session_id,
	MIN(website_pageview_id) AS first_page_id
FROM website_pageviews
WHERE created_at < '2012-06-14'
GROUP BY 1
),
session_w_landing_page AS(
SELECT
	fp.website_session_id,
	wp.pageview_url AS landing_page
FROM first_page_view_by_session fp
LEFT JOIN website_pageviews wp
 ON(fp.first_page_id = wp.website_pageview_id)
WHERE wp.pageview_url = '/home'
ORDER BY 1),
bounced_website_session AS(
SELECT
	sw.website_session_id,
	sw.landing_page,
	COUNT(wp.website_pageview_id) AS count_page_viewed
FROM session_w_landing_page sw
LEFT JOIN website_pageviews wp
	USING(website_session_id)
GROUP BY 1,2
HAVING COUNT(wp.website_pageview_id) = 1)

SELECT
	COUNT(DISTINCT sw.website_session_id) AS sessions,
	COUNT(DISTINCT bw.website_session_id) AS bounced_sessions,
	COUNT(DISTINCT bw.website_session_id)::float / 
	COUNT(DISTINCT sw.website_session_id)*100 AS bounce_rate
FROM session_w_landing_page sw
LEFT JOIN bounced_website_session bw
USING(website_session_id)

-- Soal 3. Case Landing Page Test Analysis (Bounce rate home vs lander)
-- Step 1. Find out when the new page /lander launched
-- Step 2. Finding the first website pageview for relevant session
-- Step 3. Identify landing page for each session
-- Step 4. Counting pageviews for each session, to count bounce rate
-- Step 5. Summaryzing total session, bounce rate by LP

-- Step 1
SELECT
	MIN(created_at) AS first_created_at,
	MIN(website_pageview_id) AS first_pageview
FROM website_pageviews
WHERE pageview_url = '/lander-1'

-- Step 2
WITH first_page_view_by_session AS(
SELECT
	wp.website_session_id,
	MIN(wp.website_pageview_id) AS first_page_id
FROM website_pageviews wp
LEFT JOIN website_sessions ws
	USING(website_session_id)
WHERE wp.created_at < '2012-07-29'
	AND ws.utm_source = 'gsearch' 
	AND ws.utm_campaign = 'nonbrand'
	AND wp.website_pageview_id >= 23504
GROUP BY 1
),
session_w_landing_page AS(
SELECT
	fp.website_session_id,
	wp.pageview_url AS landing_page
FROM first_page_view_by_session fp
LEFT JOIN website_pageviews wp
 ON(fp.first_page_id = wp.website_pageview_id)
WHERE wp.pageview_url IN ('/home', '/lander-1')
ORDER BY 1),
bounced_website_session AS(
SELECT
	sw.website_session_id,
	sw.landing_page,
	COUNT(wp.website_pageview_id) AS count_page_viewed
FROM session_w_landing_page sw
LEFT JOIN website_pageviews wp
	USING(website_session_id)
GROUP BY 1,2
HAVING COUNT(wp.website_pageview_id) = 1)

SELECT
	sw.landing_page,
	COUNT(DISTINCT sw.website_session_id) AS sessions,
	COUNT(DISTINCT bw.website_session_id) AS bounced_sessions,
	COUNT(DISTINCT bw.website_session_id)::float / 
	COUNT(DISTINCT sw.website_session_id)*100 AS bounce_rate
FROM session_w_landing_page sw
LEFT JOIN bounced_website_session bw
USING(website_session_id)
GROUP BY sw.landing_page




	


