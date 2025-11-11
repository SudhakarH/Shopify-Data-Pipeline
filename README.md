
## README.md
```markdown
# Data Engineering Case Study

Welcome! You're joining "XYZ" BI team to help optimize our e-commerce operations. 

We integrate with Shopify to manage our online storefront while building and maintaining 
reliable data pipelines that transform Shopify webhook data into actionable business insights 
for our second-hand marketplace.

Challenge Overview
You'll work with Shopify webhook/API data mock (json) and your task are:

1. Design and implement data ingestion pipelines from Shopify into BigQuery using Airflow.

2. Create a LookML model for e-commerce analytics using Looker. 

3. Optimize queries for cost and performance.

4. Build monitoring and error handling for real-time data flows


## Structure
- `{your_name_DE}/` → root directory.
- `airflow_dag/` → Airflow DAGs for orchestration.
- `sql/` → BigQuery transformation scripts for analytics mart.
- `Shopify webhook processing functions and utils`.
- `lookml/` → LookML models, views, and explores.
- `monitoring/` → Monitoring and error-handling strategy.

{your_name_DE}/
├─ README.md
├─ requirements.txt
├─ .gitignore
├─ dag/
│  ├─ __init__.py
│  ├─ main_dag.py                       # possible feel free to chose
│  ├─ utils/
│  │  ├─ __init__.py
│  │  ├─ process_webhook.py             # possible feel free to chose
│  │  └─ utils.py
│  └─ sql/
│     └─ ecommerce_mart.sql             # possible feel free to chose
├─ lookml/                              # possible feel free to chose
│  ├─ views/ecommerce_performance.view.lkml
│  └─ explores/shopify_analytics.explore.lkml
└─ monitoring/monitoring_strategy.md

## Assumptions
- Prices always provided in EUR or converted before ingestion.
- Refunds fully exclude orders from revenue calculations.
- The ingestion has to be incremental.
- Orders can be updated.
- Customer status derived from earliest order.

## Deliverables
With an airflow dag do load of json to bigquery, process ELT bigquery data, make it available for looker.

- Python webhook processing functions
- SQL mart for e-commerce analytics
- LookML view & explore
- Airflow DAG for pipeline orchestration
- Monitoring strategy (documented)
```

---
## Task 1 - Question 1
## For the dag, create functions that allow you to process json data meeting the following requirements:
1. Unique orders.
2. Validate required fields (order_id, customer_id, total_price, created_at). Cannot be null or empty.
3. Transform timestamps to Berlin Time (CET/CEST).
4. Normalize financial_status and fulfillment_status to lowercase.
5. Hash first_name and last_name in customer data for privacy.

## python/process_webhook.py
```python
from datetime import datetime, timezone
import re

def process_shopify_order_webhook(webhook_payload: dict) -> tuple[bool, dict, list[str]]:
    """
    Process Shopify order webhook and transform for BigQuery.

    Args:
        webhook_payload: Raw Shopify webhook JSON
        

    Returns:
        tuple: (is_valid: bool, transformed_data: dict, errors: list[str])
    """

    # Your implementation here

    pass

```

---
You have these BigQuery tables that should be populated from Shopify webhooks or API calls:

There is an example json that covers the 3 tables.

## sql/ecommerce_mart.sql
```sql
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
    vendor STRING,        -- 'books', 'fashion', etc.
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
```

## Task 2 - Create a SQL query that transforms Shopify data from previous tables into an analytics mart:

Create daily e-commerce performance mart with the following requirements:

1. Aggregate by date, product_type, source_name, financial_status
2. Calculate: order_count, revenue, avg_order_value, units_sold
3. Include customer metrics: new_customers, returning_customers
4. Partition by date, cluster by product_type
5. Handle refunds by excluding refunded orders from revenue


---

## Task 3.1 Write a LookML view for the e-commerce performance mart:
## lookml/views/ecommerce_performance.view.lkml

```lkml
# views/ecommerce_performance.view.lkml
view: ecommerce_performance {
  sql_table_name: `analytics.daily_ecommerce_performance` ;;
  
  # Define appropriate dimensions and measures for e-commerce analytics
  # Include:
  # - Date dimension with time-based grouping options
  # - Product type and sales channel dimensions  
  # - Revenue measures (total, average order value)
  # - Order metrics (count, conversion rates)
  # - Customer segmentation (new vs returning)
  # - Calculated fields for growth rates and trends
  
  # Your LookML code here
}

```

Task 3.2 Use it to make an explore .lkml with business logic.


## lookml/explores/shopify_analytics.explore.lkml
```lkml
# explores/shopify_analytics.explore.lkml
explore: shopify_analytics {
  from: ecommerce_performance
  
  # Add business-friendly labels for e-commerce KPIs
  # Include filters for date ranges, product categories
  # Add conditional formatting for performance metrics
  # Consider drill-down paths (daily -> hourly, category -> product)
  
  # Your explore configuration here
}

```

---
## Task 4 Write an airflow dag that allows to run the whole pipeline 
## dag/shopify_pipeline_dag.py (dag_task_4.py)
```python
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.providers.http.sensors.http import HttpSensor
from datetime import datetime, timedelta

# Hypothetical import of your functions from question 1
from __your_question_1_answers__ import process_shopify_order_webhook
# import sql from __your_question_2_answers__

# Those are just import examples, you might use any packages required

# Design DAG for Shopify data processing (Shopify >> BigQuery  >> mart )
DEFAULT_ARGS = { #example default args
    'owner': 'airflow',
    'retries': 3,
    'retry_delay': timedelta(minutes=5),
}

# Your DAG implementation here
# (can be a folder with multiple files for packages)


with DAG(
    dag_id='shopify_pipeline',
    default_args=DEFAULT_ARGS,
    description='Shopify >> BigQuery >> Analytics Mart',
    schedule_interval=timedelta(hours=1),
    start_date=datetime(2025, 1, 1),
    catchup=False,
    tags=['shopify', 'bigquery'],
) as dag:

    # Include (most important):
    # - Webhook data validation (use previous python answers)
    #   Example: process_shopify_order_webhook
    # - Load to BigQuery using BigQueryInsertJobOperator
    # - SQL transformations (use previous sql answers)
    #   Example: your_question_2_answers__
    # - Incremental order processing (handle updates to existing orders)

    # General importance:
    # - Schema and Data quality checks (missing orders, price anomalies)
    # - Alerting on failures and Retry logic with exponential backoff
    # - Idempotent processing to avoid duplicates
    # - Logging and monitoring
    # - Modular code structure and Scalability considerations
    # - Documentation of DAG and tasks
    # - Use of Airflow XComs for inter-task communication if needed
    # - Use of Airflow Pools to limit concurrency if needed
    # - Use of Airflow BranchPythonOperator for conditional logic if needed
    # - Use of Airflow TaskGroups for better organization if needed
    # - Use of Airflow Macros for dynamic values if needed
    # - Use of Airflow SLA for task deadlines if needed
```

---
## Task 5
## open questions.txt
```markdown
# Monitoring Strategy for Shopify Pipelines
Describe how you would monitor Shopify data pipelines:


Data Freshness: How to detect when Shopify webhooks stop arriving?


Revenue Accuracy: How to validate that BigQuery totals match Shopify?


Webhook Reliability: How to handle missed or delayed webhook deliveries? 
How to ensure exactly-once processing of Shopify webhooks?

Pub/Sub Architecture: Would you consider the use of Pub/Sub topics for different event types 
(orders, refunds, customer updates)? What are your thoughts on this approach?

## Infrastructure Considerations
- Pub/Sub topics per event type: `orders`, `refunds`, `customers`.
- Cloud Run preferred for scalable webhook handling (vs. Cloud Functions).
- Dead letter queues for resiliency.

---




