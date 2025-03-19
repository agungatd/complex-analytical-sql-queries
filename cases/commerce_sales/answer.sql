-- This query analyzes customer purchase patterns and product performance
-- across different regions, time periods, and demographic segments.

-- CTE 1: Data Preparation - Cleaning and standardizing raw sales data
WITH sales_cleaned AS (
    SELECT
        s.sale_id,
        s.customer_id,
        s.product_id,
        s.store_id,
        s.sale_date,
        -- Handle NULL sale amounts with default value
        COALESCE(s.sale_amount, 0) AS sale_amount,
        -- Convert inconsistent timestamps to standard format
        CAST(s.sale_timestamp AS TIMESTAMP) AS sale_timestamp,
        -- Standardize payment methods
        UPPER(TRIM(s.payment_method)) AS payment_method,
        -- Flag potential duplicates for analysis
        ROW_NUMBER() OVER(PARTITION BY s.customer_id, s.product_id, s.sale_timestamp) AS dup_check
    FROM sales s
    WHERE s.sale_date >= '2025-01-01'
      AND s.sale_date < '2026-01-01'
      AND s.sale_amount IS NOT NULL
),

-- CTE 2: Customer Demographics - Enriching customer data with demographic info
customer_demographics AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        c.email,
        -- Calculate customer age from birth date
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, c.birth_date)) AS customer_age,
        -- Define age groups for segmentation
        CASE
            WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, c.birth_date)) < 25 THEN 'Young Adult'
            WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, c.birth_date)) BETWEEN 25 AND 40 THEN 'Adult'
            WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, c.birth_date)) BETWEEN 41 AND 60 THEN 'Middle Age'
            ELSE 'Senior'
        END AS age_group,
        -- Calculate customer tenure in years
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, c.registration_date)) AS years_as_customer,
        -- Determine loyalty tier based on tenure and purchase frequency
        CASE
            WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, c.registration_date)) > 5 AND c.purchase_count > 50 THEN 'Platinum'
            WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, c.registration_date)) > 3 OR c.purchase_count > 30 THEN 'Gold'
            WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, c.registration_date)) > 1 OR c.purchase_count > 10 THEN 'Silver'
            ELSE 'Bronze'
        END AS loyalty_tier,
        c.city,
        c.state,
        c.country,
        -- Parse and standardize ZIP codes
        SUBSTRING(REGEXP_REPLACE(c.zip_code, '[^0-9]', ''), 1, 5) AS zip_code
    FROM customers c
    WHERE c.account_status = 'active'
),

-- CTE 3: Product Categories - Organizing products into hierarchical categories
product_categories AS (
    SELECT
        p.product_id,
        p.product_name,
        p.price,
        p.cost,
        -- Calculate profit margin
        round(cast(((p.price - p.cost) / NULLIF(p.price, 0)) * 100 AS numeric), 2) AS profit_margin,
        -- Create category hierarchy
        pc.category_name,
        pc.parent_category,
        pc.top_level_category,
        -- Determine product seasonality
        CASE
            WHEN p.is_seasonal = TRUE THEN 'Seasonal'
            ELSE 'Year-round'
        END AS seasonality,
        -- Flag products on promotion
        CASE
            WHEN p.discount_percentage > 0 THEN TRUE
            ELSE FALSE
        END AS is_on_promotion,
        -- Calculate discount amount
        ROUND(CAST(p.price * (p.discount_percentage / 100) AS NUMERIC), 2) AS discount_amount
    FROM products p
    LEFT JOIN product_category_mapping pcm ON p.product_id = pcm.product_id
    LEFT JOIN product_categories pc ON pcm.category_id = pc.category_id
    WHERE p.is_active = TRUE
),

-- CTE 4: Store Locations - Adding geographical context to stores
store_locations AS (
    SELECT
        s.store_id,
        s.store_name,
        s.address,
        s.city,
        s.state,
        s.country,
        s.zip_code,
        -- Calculate store age in years
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, s.opening_date)) AS store_age,
        -- Determine store size category
        CASE
            WHEN s.square_footage < 5000 THEN 'Small'
            WHEN s.square_footage BETWEEN 5000 AND 15000 THEN 'Medium'
            ELSE 'Large'
        END AS store_size,
        -- Group stores by region
        r.region_name,
        r.region_manager,
        -- Add geographical coordinates
        s.latitude,
        s.longitude
    FROM stores s
    JOIN regions r ON s.region_id = r.region_id
    WHERE s.is_active = TRUE
),

-- CTE 5: Time Dimensions - Extracting useful time-related attributes
time_dimensions AS (
    SELECT DISTINCT
        sale_date,
        -- Extract time components
        EXTRACT(YEAR FROM sale_date) AS year,
        EXTRACT(QUARTER FROM sale_date) AS quarter,
        EXTRACT(MONTH FROM sale_date) AS month,
        EXTRACT(DAY FROM sale_date) AS day,
        EXTRACT(DOW FROM sale_date) AS day_of_week,
        -- Determine if weekend
        CASE
            WHEN EXTRACT(DOW FROM sale_date) IN (0, 6) THEN TRUE
            ELSE FALSE
        END AS is_weekend,
        -- Determine if holiday (simplified example)
        CASE
            WHEN TO_CHAR(sale_date, 'MM-DD') IN ('01-01', '12-25', '07-04', '11-28') THEN TRUE
            ELSE FALSE
        END AS is_holiday,
        -- Define season
        CASE
            WHEN EXTRACT(MONTH FROM sale_date) BETWEEN 3 AND 5 THEN 'Spring'
            WHEN EXTRACT(MONTH FROM sale_date) BETWEEN 6 AND 8 THEN 'Summer'
            WHEN EXTRACT(MONTH FROM sale_date) BETWEEN 9 AND 11 THEN 'Fall'
            ELSE 'Winter'
        END AS season
    FROM sales_cleaned
),

-- CTE 6: Sales Aggregation - Calculating sales metrics by customer
customer_sales_metrics AS (
    SELECT
        sc.customer_id,
        COUNT(DISTINCT sc.sale_id) AS total_transactions,
        COUNT(DISTINCT sc.product_id) AS unique_products_purchased,
        SUM(sc.sale_amount) AS total_spent,
        AVG(sc.sale_amount) AS avg_transaction_value,
        MAX(sc.sale_amount) AS largest_transaction,
        MIN(sc.sale_date) AS first_purchase_date,
        MAX(sc.sale_date) AS most_recent_purchase_date,
        -- Calculate days since last purchase
        EXTRACT(DAY FROM AGE(CURRENT_DATE, MAX(sc.sale_date))) AS days_since_last_purchase,
        -- Determine preferred payment method
        MODE() WITHIN GROUP (ORDER BY sc.payment_method) AS preferred_payment_method,
        -- Calculate frequency of purchases
        COUNT(DISTINCT sc.sale_id) / NULLIF(EXTRACT(MONTH FROM AGE(MAX(sc.sale_date), MIN(sc.sale_date))), 0) AS monthly_purchase_frequency
    FROM sales_cleaned sc
    WHERE sc.dup_check = 1
    GROUP BY sc.customer_id
),

-- CTE 7: Product Performance - Analyzing product sales and profitability
product_performance AS (
    SELECT
        sc.product_id,
        COUNT(sc.sale_id) AS total_units_sold,
        SUM(sc.sale_amount) AS total_revenue,
        AVG(sc.sale_amount) AS avg_sale_price,
        -- Calculate product profitability using CTE 3
        SUM(sc.sale_amount) * (pc.profit_margin / 100) AS estimated_profit,
        -- Calculate sales velocity (units sold per day)
        COUNT(sc.sale_id) / NULLIF(EXTRACT(DAY FROM AGE(MAX(sc.sale_date), MIN(sc.sale_date))), 0) AS daily_sales_velocity,
        -- Demographics of buyers (simplified)
        COUNT(DISTINCT sc.customer_id) AS unique_customers
        -- Calculate return rate (joining with separate returns table)
--        COALESCE(COUNT(r.return_id), 0) AS total_returns,
--        COALESCE(COUNT(r.return_id) / NULLIF(COUNT(sc.sale_id), 0) * 100, 0) AS return_rate
    FROM sales_cleaned sc
    JOIN product_categories pc ON sc.product_id = pc.product_id
--    LEFT JOIN returns r ON sc.sale_id = r.sale_id
    WHERE sc.dup_check = 1
    GROUP BY sc.product_id, pc.profit_margin
),

-- CTE 8: Regional Performance - Comparing sales across regions
ranked_products AS (
    SELECT
        sl.region_name,
        pc.product_name,
        COUNT(sc.sale_id) AS sales_count,
        ROW_NUMBER() OVER (PARTITION BY sl.region_name ORDER BY COUNT(sc.sale_id) DESC) AS rn
    FROM sales_cleaned sc
    JOIN store_locations sl ON sc.store_id = sl.store_id
    JOIN product_categories pc ON sc.product_id = pc.product_id
    WHERE sc.dup_check = 1
    GROUP BY sl.region_name, pc.product_name
),
top_product AS (
    SELECT
        region_name,
        ARRAY_AGG(product_name || ' (' || sales_count || ')') AS top_products
    FROM ranked_products
    WHERE rn <= 3
    GROUP BY region_name
),
regional_sales AS (
  SELECT
      sl.region_name,
      COUNT(DISTINCT sc.sale_id) AS total_sales,
      SUM(sc.sale_amount) AS total_revenue,
      COUNT(DISTINCT sc.customer_id) AS unique_customers,
      SUM(sc.sale_amount) / NULLIF(COUNT(DISTINCT sc.customer_id), 0) AS revenue_per_customer,
      AVG(sc.sale_amount) AS avg_sale_value,
      SUM(CASE WHEN td.season = 'Winter' THEN sc.sale_amount ELSE 0 END) AS winter_revenue,
      SUM(CASE WHEN td.season = 'Spring' THEN sc.sale_amount ELSE 0 END) AS spring_revenue,
      SUM(CASE WHEN td.season = 'Summer' THEN sc.sale_amount ELSE 0 END) AS summer_revenue,
      SUM(CASE WHEN td.season = 'Fall' THEN sc.sale_amount ELSE 0 END) AS fall_revenue
  FROM sales_cleaned sc
  JOIN store_locations sl ON sc.store_id = sl.store_id
  JOIN time_dimensions td ON sc.sale_date = td.sale_date
    WHERE sc.dup_check = 1
  GROUP BY sl.region_name
), 
regional_performance AS (
	SELECT
	    rs.region_name,
	    rs.total_sales,
	    rs.total_revenue,
	    rs.unique_customers,
	    rs.revenue_per_customer,
	    rs.avg_sale_value,
	    tp.top_products,
	    rs.winter_revenue,
	    rs.spring_revenue,
	    rs.summer_revenue,
	    rs.fall_revenue
	FROM regional_sales rs
	LEFT JOIN top_product tp ON rs.region_name = tp.region_name
),

-- CTE (Final): Bringing it all together - Comprehensive sales analysis
comprehensive_sales_analysis AS (
    SELECT
        -- Sale information
        sc.sale_id,
        sc.sale_date,
        td.year,
        td.quarter,
        td.month,
        td.day_of_week,
        td.is_weekend,
        td.is_holiday,
        td.season,
        -- Customer information
        cd.customer_id,
        cd.first_name || ' ' || cd.last_name AS customer_name,
        cd.age_group,
        cd.loyalty_tier,
        cd.city AS customer_city,
        cd.state AS customer_state,
        cd.country AS customer_country,
        csm.total_transactions,
        csm.total_spent,
        csm.avg_transaction_value,
        csm.days_since_last_purchase,
        -- Product information
        pc.product_id,
        pc.product_name,
        pc.category_name,
        pc.top_level_category,
        pc.profit_margin,
        pc.is_on_promotion,
        pp.total_units_sold,
        pp.total_revenue AS product_total_revenue,
        --pp.return_rate,
        -- Store information
        sl.store_id,
        sl.store_name,
        sl.city AS store_city,
        sl.state AS store_state,
        sl.region_name,
        sl.store_size,
        -- Transaction information
        sc.sale_amount,
        sc.payment_method,
        -- Regional performance
        rp.total_sales AS region_total_sales,
        rp.total_revenue AS region_total_revenue,
        rp.top_products AS top_products,
        -- Calculate if customer's purchase was above their average
        CASE
            WHEN sc.sale_amount > csm.avg_transaction_value THEN TRUE
            ELSE FALSE
        END AS above_customer_average,
        -- Calculate if purchase was during high-season for product
        CASE
            WHEN (pc.seasonality = 'Seasonal' AND 
                  ((pc.top_level_category = 'Winter Gear' AND td.season = 'Winter') OR
                   (pc.top_level_category = 'Summer Gear' AND td.season = 'Summer')))
            THEN TRUE
            ELSE FALSE
        END AS in_product_season,
        -- Calculate distance from customer's location to store (simplified)
        -- Note: This would typically use more complex geospatial calculations
        CASE
            WHEN cd.city = sl.city AND cd.state = sl.state THEN 'Local'
            WHEN cd.state = sl.state THEN 'In-state'
            WHEN cd.country = sl.country THEN 'In-country'
            ELSE 'International'
        END AS customer_proximity
    FROM sales_cleaned sc
    JOIN customer_demographics cd ON sc.customer_id = cd.customer_id
    JOIN product_categories pc ON sc.product_id = pc.product_id
    JOIN store_locations sl ON sc.store_id = sl.store_id
    JOIN time_dimensions td ON sc.sale_date = td.sale_date
    JOIN customer_sales_metrics csm ON sc.customer_id = csm.customer_id
    JOIN product_performance pp ON sc.product_id = pp.product_id
    JOIN regional_performance rp ON sl.region_name = rp.region_name
    WHERE sc.dup_check = 1
)
-- Main query to get final insights
SELECT
    -- Time-based analysis
    year,
    quarter,
    season,
    -- Regional analysis
    region_name,
    store_city,
    store_state,
    -- Customer segment analysis
    age_group,
    loyalty_tier,
    -- Product category analysis
    top_level_category,
    category_name,
    -- Key metrics
    COUNT(DISTINCT sale_id) AS total_transactions,
    COUNT(DISTINCT customer_id) AS unique_customers,
    SUM(sale_amount) AS total_revenue,
    AVG(sale_amount) AS avg_transaction_value,
    -- Calculate purchase behavior
    SUM(CASE WHEN above_customer_average THEN 1 ELSE 0 END) AS above_average_purchases,
    SUM(CASE WHEN in_product_season THEN sale_amount ELSE 0 END) AS seasonal_revenue,
    -- Calculate payment method distribution
    COUNT(CASE WHEN payment_method = 'CREDIT' THEN 1 END) AS credit_transactions,
    COUNT(CASE WHEN payment_method = 'DEBIT' THEN 1 END) AS debit_transactions,
	COUNT(CASE WHEN payment_method = 'CASH' THEN 1 END) AS cash_transactions,
    COUNT(CASE WHEN payment_method = 'MOBILE' THEN 1 END) AS mobile_transactions,
    -- Calculate weekend vs weekday performance
    SUM(CASE WHEN is_weekend THEN sale_amount ELSE 0 END) AS weekend_revenue,
    SUM(CASE WHEN NOT is_weekend THEN sale_amount ELSE 0 END) AS weekday_revenue,
    -- Calculate promotional impact
    SUM(CASE WHEN is_on_promotion THEN sale_amount ELSE 0 END) AS promo_revenue,
    SUM(CASE WHEN NOT is_on_promotion THEN sale_amount ELSE 0 END) AS non_promo_revenue,
    -- Calculate proximity impact
    SUM(CASE WHEN customer_proximity = 'Local' THEN sale_amount ELSE 0 END) AS local_revenue,
    SUM(CASE WHEN customer_proximity = 'In-state' THEN sale_amount ELSE 0 END) AS in_state_revenue,
    SUM(CASE WHEN customer_proximity = 'In-country' THEN sale_amount ELSE 0 END) AS in_country_revenue,
    SUM(CASE WHEN customer_proximity = 'International' THEN sale_amount ELSE 0 END) AS international_revenue,
    -- Calculate efficiency metrics
    SUM(sale_amount) / COUNT(DISTINCT customer_id) AS revenue_per_customer,
    COUNT(DISTINCT sale_id) / COUNT(DISTINCT customer_id) AS transactions_per_customer
FROM comprehensive_sales_analysis
-- Filter to relevant period if needed
--WHERE year = 2023
GROUP BY
    -- Time hierarchy
    year,
    quarter,
    season,
    -- Location hierarchy
    region_name,
    store_state,
    store_city,
    -- Customer segments
    age_group,
    loyalty_tier,
    -- Product hierarchy
    top_level_category,
    category_name
-- Sort by highest revenue
ORDER BY total_revenue DESC
-- Limit to top performers for reporting
LIMIT 100;