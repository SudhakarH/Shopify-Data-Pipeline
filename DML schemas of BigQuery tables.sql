-- Shopify orders from webhook data
shopify_orders (
    order_id STRING, --required
    order_number STRING, --required
    customer_id STRING, --required
    email STRING,
    total_price FLOAT64,
    subtotal_price FLOAT64,
    total_tax FLOAT64,
    currency STRING,            -- 'EUR'
    financial_status STRING,    -- 'paid', 'pending', 'refunded'
    fulfillment_status STRING,  -- 'fulfilled', 'partial', 'unfulfilled'
    tags STRING,                -- comma-separated: 'books,vintage,rare'
    source_name STRING,         -- 'web', 'mobile', 'pos'
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
-- Order line items (products in each order)
shopify_order_items (
    order_id STRING, --required
    line_item_id STRING, --required
    product_id STRING, --required
    variant_id STRING,
    title STRING,
    variant_title STRING,
    quantity INT64,
    price FLOAT64,
    total_discount FLOAT64,
    vendor STRING,        -- 'momox-books', 'momox-fashion', etc.
    product_type STRING,  -- 'Book', 'CD', 'Game', 'Clothing'
    created_at TIMESTAMP

)
-- Customer data from Shopify API
shopify_customers (
    customer_id STRING, --required
    email STRING, --required
    first_name STRING,
    last_name STRING,
    total_spent FLOAT64,
    orders_count INT64,
    accepts_marketing BOOLEAN,
    state STRING,         -- 'enabled', 'disabled'
    tags STRING,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
