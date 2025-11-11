from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.operators.empty import EmptyOperator
from airflow.providers.http.sensors.http import HttpSensor
from datetime import datetime, timedelta
import json
import os

from dag.utils.process_webhook import process_shopify_order_webhook # hypothetical import of your functions question 1
# import sql from __your_question_2_answers__

# those are just import examples, you might use any packages required

# constants - these are just a dummy constants, need to replace with actual value/path
GCP_PROJECT_ID = "momox-data-eng"
BQ_DATASET = "shopify_raw"
BQ_ANALYTICS_DATASET = "analytics"
RAW_JSON_PATH = "/dag/payload_example.json"     #need to mention the exact location of JSON file - it may look like this /opt/airflow/dags/data/payload_example.json
SQL_MART_PATH = "/dag/sql/ecomerce_mart.sql"    #need to mention the exact location of SQL file - it may look like this /opt/airflow/dags/sql/ecomerce_mart.sql

# Design DAG for Shopify data processing (Shopify >> BigQuery  >> mart )
DEFAULT_ARGS = {
    "owner": "airflow",
    "depends_on_past": False,
    "email_on_failure": True,
    "retries": 3,
    "retry_delay": timedelta(minutes=5),
}

# Your DAG implementation here (can be a folder with multiple files for packages)


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

# - Webhook data validation (you might use previous python answers) example: process_shopify_order_webhook

# - Load to bigquery BigQueryInsertJobOperator(

# - SQL transformations (you might use previous sql answers) example: your_question_2_answers__

# Incremental order processing (handle updates to existing orders)

    # Dummy start marker
    
    start = EmptyOperator(
        task_id="start_pipeline",
        doc_md="### Start of the Shopify data pipeline."
    )

    # LOAD AND PROCESS WEBHOOK JSON
    
    def process_shopify_webhook(**context):
        """Load webhook JSON and run transformation from Task 1."""
        with open(RAW_JSON_PATH, "r") as f:
            payload = json.load(f)

        is_valid, transformed_data, errors = process_shopify_order_webhook(payload)

        if not is_valid or errors:
            raise ValueError(f"Validation failed: {errors}")

        context["ti"].xcom_push(key="orders", value=transformed_data["orders"])
        context["ti"].xcom_push(key="line_items", value=transformed_data["line_items"])
        context["ti"].xcom_push(key="customers", value=transformed_data["customers"])
        return "Webhook processed successfully."


    # In production, we might replace local file ingestion with an HttpSensor
    # that waits for a Shopify webhook POST or a Pub/Sub trigger.

    process_webhook = PythonOperator(
        task_id="process_webhook",
        python_callable=process_shopify_webhook,
        provide_context=True,
    )

    
    # LOAD INTO BIGQUERY TABLES
   
    from google.cloud import bigquery

    def load_to_bigquery(table_name, records):
        """Helper to append data to BigQuery tables."""
        client = bigquery.Client(project=GCP_PROJECT_ID)
        dataset_ref = client.dataset(BQ_DATASET)
        table_ref = dataset_ref.table(table_name)

        job_config = bigquery.LoadJobConfig(
            write_disposition=bigquery.WriteDisposition.WRITE_APPEND,
            source_format=bigquery.SourceFormat.NEWLINE_DELIMITED_JSON,
            autodetect=True,
            # NOTE: Autodetect is used for simplicity in this case study.
            # In production, schema should be explicitly defined.
        )

        tmp_file = f"/tmp/{table_name}.json"
        with open(tmp_file, "w") as f:
            for r in records:
                f.write(json.dumps(r) + "\n")

        with open(tmp_file, "rb") as src:
            job = client.load_table_from_file(src, table_ref, job_config=job_config)
        job.result()
        os.remove(tmp_file)

        return f"Loaded {len(records)} rows into {BQ_DATASET}.{table_name}"

    def upload_orders(**context):
        recs = context["ti"].xcom_pull(key="orders", task_ids="process_webhook")
        return load_to_bigquery("shopify_orders", recs)

    def upload_items(**context):
        recs = context["ti"].xcom_pull(key="line_items", task_ids="process_webhook")
        return load_to_bigquery("shopify_order_items", recs)

    def upload_customers(**context):
        recs = context["ti"].xcom_pull(key="customers", task_ids="process_webhook")
        return load_to_bigquery("shopify_customers", recs)

    orders = PythonOperator(
        task_id="load_orders_to_bq",
        python_callable=upload_orders,
        provide_context=True,
    )

    items = PythonOperator(
        task_id="load_items_to_bq",
        python_callable=upload_items,
        provide_context=True,
    )

    customers = PythonOperator(
        task_id="load_customers_to_bq",
        python_callable=upload_customers,
        provide_context=True,
    )

     
    # TRANSFORM — BUILD ANALYTICS MART
      
    with open(SQL_MART_PATH, "r") as f:
        mart_sql = f.read()

    build_analytics_mart = BigQueryInsertJobOperator(
        task_id="build_daily_ecommerce_mart",
        configuration={
            "query": {
                "query": mart_sql,
                "useLegacySql": False,
            }
        },
        gcp_conn_id="google_cloud_default",
    )

       
    # SIMULATE LOOKER REFRESH
        
    def refresh_looker():
        print("Looker model refresh triggered for ecommerce_performance.lkml")

    looker_refresh = PythonOperator(
        task_id="refresh_looker",
        python_callable=refresh_looker,
    )

    # Dummy end marker
    end = EmptyOperator(
        task_id="end_pipeline",
        doc_md="### End of the Shopify data pipeline."
    )

       
    # DAG FLOW
       
    start >> process_webhook >> [orders, items, customers] >> build_analytics_mart >> looker_refresh >> end


# general importance:

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