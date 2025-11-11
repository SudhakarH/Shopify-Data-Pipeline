Project Overview

This case study simulates a real-world Data Engineering pipeline for ingesting Shopify webhook data, transforming it into analytical insights, and modeling it for Looker dashboards.

The goal is to demonstrate end-to-end data engineering capabilities — from raw JSON ingestion to BI-ready data models — using Airflow, BigQuery, and Looker.

Folder Structure
Sudhakar_Hanumanth_DE_momox/
├─ README.md
├─ requirements.txt
├─ dag/
│  ├─ shopify_pipeline_dag.py
│  |─ utils/
│  │  ├─ process_webhook.py
│  |  └─ __init__.py
|  └─ sql/
│     └─ ecommerce_mart.sql
├─ lookml/
│  ├─ views/ecommerce_performance.view.lkml
│  └─ explores/shopify_analytics.explore.lkml
├─ Documentation.md
├─ open questions.txt
└─ test_task_1.py


## Pipeline Components
 Airflow DAG: shopify_pipeline_dag.py

Orchestrates the full data flow:

Load & validate webhook JSON
    Uses process_shopify_order_webhook() to ensure required fields, normalize timestamps, and hash sensitive data.

Ingest into BigQuery
    Loads data into 3 tables: shopify_orders, shopify_order_items, shopify_customers

Transform data into analytics mart
    Executes ecommerce_mart.sql to create analytics.daily_ecommerce_performance

Trigger Looker model refresh
    Handles retries, alerts, and logging with Airflow’s built-in mechanisms.

## FLOW:
Start → Process Webhook → Load to BQ (3 tables)→ Build Mart → Refresh Looker → End


### Python Transformation: process_webhook.py

Validates required fields: order_id, customer_id, total_price, created_at
Converts timestamps to Berlin (CET/CEST)
Normalizes financial & fulfillment statuses
Hashes customer first and last names using SHA256
Produces flattened outputs for:
    Orders
    Line Items
    Customers

### BigQuery Transformation: ecommerce_mart.sql

Creates daily_ecommerce_performance mart with:
Aggregations by order_date, product_type, source_name, financial_status
Metrics:
        order_count
        revenue
        avg_order_value
        units_sold
        new_customers
        returning_customers
        Excludes refunded orders
Optimized with:
        Partition by order_date
        Cluster by product_type
        Incremental 90-day merge window

### LookML Models
View: ecommerce_performance.view.lkml
        Defines metrics and time-based dimensions
        Adds derived measures (growth rates, conversion rates)
        Applies 90-day filter by default
Explore: shopify_analytics.explore.lkml
        Provides user-friendly analytics exploration
        Includes filters for date range, product type, and sales channel
        Adds drill-downs (date → hour → product → source)
        Includes conditional formatting for KPI trends

### Open Questions.txt
    Covers proactive reliability and observability:
    Data Freshness — SLA-based alerting when webhooks stop arriving
    Revenue Accuracy — Cross-check BQ totals vs. Shopify API metrics
    Webhook Reliability — Retry & deduplication for exactly-once processing
    Pub/Sub Architecture — Event-based ingestion via topics per entity
    Dead Letter Queues — Capture failed webhook events for replay

### How to Run

1. Place payload_example.json in /dags/data/ and ecomerce_mart.sql in /dags/sql/

2. Update Airflow variables:
        GCP_PROJECT_ID
        BQ_DATASET

3. Run DAG: shopify_pipeline

4. Check BigQuery datasets:
        shopify_raw → raw tables
        analytics → daily_ecommerce_performance

5. Open Looker and explore Shopify Analytics


📬 Contact
Author: Sudhakar Hanumanth
Email: hanumanthsudhakar@gmail.com
Role: Data Engineer
Case Study: Data Engineer – GCP & Looker (momox)