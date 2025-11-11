-- Requirements:

-- 1. Aggregate by date, product_type, source_name, financial_status

-- 2. Calculate: order_count, revenue, avg_order_value, units_sold

-- 3. Include customer metrics: new_customers, returning_customers

-- 4. Only include orders from last 90 days (aggregates last 90 days and merges only the affected dates.)

-- 5. Partition by date, cluster by product_type is recommended, feel free to explore more cost optimisation practices.

-- 6. Handle refunds by excluding refunded orders from revenue



-- Create the target table if it does not exist
-- Replace PROJECT_ID and DATASET with actual values before running.
CREATE TABLE IF NOT EXISTS `PROJECT_ID.DATASET.daily_ecommerce_performance` (
  order_date DATE,
  product_type STRING,
  source_name STRING,
  financial_status STRING,
  order_count INT64,
  revenue FLOAT64,
  avg_order_value FLOAT64,
  units_sold INT64,
  new_customers INT64,
  returning_customers INT64
)
PARTITION BY order_date
CLUSTER BY product_type;

-- 2) Build aggregated results for the last 90 days
WITH
-- A. Select recent, non-refunded orders (last 90 days)
recent_orders AS (
  SELECT
    order_id,
    customer_id,
    DATE(SAFE_CAST(created_at AS TIMESTAMP)) AS order_date,
    source_name,
    LOWER(COALESCE(financial_status, '')) AS financial_status
  FROM `PROJECT_ID.DATASET.shopify_orders`
  WHERE DATE(SAFE_CAST(created_at AS TIMESTAMP)) >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
    AND LOWER(COALESCE(financial_status, '')) != 'refunded'
),

-- B. Aggregate order_items per order_id x product_type
order_items_agg AS (
  SELECT
    order_id,
    COALESCE(product_type, 'unknown') AS product_type,
    SUM(COALESCE(quantity,0)) AS units_sold,
    SUM( (COALESCE(price,0.0) * COALESCE(quantity,0)) - COALESCE(total_discount,0.0) ) AS item_revenue
  FROM `PROJECT_ID.DATASET.shopify_order_items`
  GROUP BY order_id, product_type
),

-- C. Join orders with their items (if an order has no items, product_type becomes 'unknown')
orders_with_items AS (
  SELECT
    r.order_id,
    r.customer_id,
    r.order_date,
    COALESCE(r.source_name, 'unknown') AS source_name,
    r.financial_status,
    oi.product_type,
    COALESCE(oi.units_sold, 0) AS units_sold,
    COALESCE(oi.item_revenue, 0.0) AS item_revenue
  FROM recent_orders r
  LEFT JOIN order_items_agg oi
    ON r.order_id = oi.order_id
),

-- D. Determine first order date for each customer using full history (helps classify new vs returning)
customer_first_order AS (
  SELECT
    customer_id,
    MIN(DATE(SAFE_CAST(created_at AS TIMESTAMP))) AS first_order_date
  FROM `PROJECT_ID.DATASET.shopify_orders`
  WHERE customer_id IS NOT NULL
  GROUP BY customer_id
),

-- E. Aggregate metrics per required dimensions
aggregated AS (
  SELECT
    owi.order_date,
    owi.product_type,
    owi.source_name,
    owi.financial_status,

    -- metrics
    COUNT(DISTINCT owi.order_id) AS order_count,
    SUM(owi.item_revenue) AS revenue,
    SAFE_DIVIDE(SUM(owi.item_revenue), NULLIF(COUNT(DISTINCT owi.order_id), 0)) AS avg_order_value,
    SUM(owi.units_sold) AS units_sold,

    -- customer segmentation
    COUNT(DISTINCT CASE WHEN cfo.first_order_date = owi.order_date THEN owi.customer_id END) AS new_customers,
    COUNT(DISTINCT CASE WHEN cfo.first_order_date < owi.order_date THEN owi.customer_id END) AS returning_customers

  FROM orders_with_items owi
  LEFT JOIN customer_first_order cfo
    ON owi.customer_id = cfo.customer_id
  GROUP BY owi.order_date, owi.product_type, owi.source_name, owi.financial_status
)

-- 3) Merge aggregated results into the mart (incrementally updates only affected rows)
MERGE `PROJECT_ID.DATASET.daily_ecommerce_performance` T
USING aggregated S
ON  T.order_date = S.order_date
AND T.product_type = S.product_type
AND T.source_name = S.source_name
AND T.financial_status = S.financial_status
WHEN MATCHED THEN
  UPDATE SET
    order_count = S.order_count,
    revenue = S.revenue,
    avg_order_value = S.avg_order_value,
    units_sold = S.units_sold,
    new_customers = S.new_customers,
    returning_customers = S.returning_customers
WHEN NOT MATCHED THEN
  INSERT (order_date, product_type, source_name, financial_status,
          order_count, revenue, avg_order_value, units_sold,
          new_customers, returning_customers)
  VALUES (S.order_date, S.product_type, S.source_name, S.financial_status,
          S.order_count, S.revenue, S.avg_order_value, S.units_sold,
          S.new_customers, S.returning_customers);


-- For simplicity and performance, customer segmentation (new vs. returning) was derived from order history. 
-- However, this mart can be easily extended by joining shopify_customers to include marketing or profile-based metrics.