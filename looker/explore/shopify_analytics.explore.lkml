# explores/shopify_analytics.explore.lkml

explore: shopify_analytics {

  from: ecommerce_performance

  

  # Add business-friendly labels for e-commerce KPIs

  # Include filters for date ranges, product categories

  # Add conditional formatting for performance metrics

  # Consider drill-down paths (daily -> hourly, category -> product)

  

  # Your explore configuration here
  label: "Shopify Analytics"
  description: "Explore daily e-commerce KPIs including revenue, orders, customers, and trends across products and channels."

  
  # --- DEFAULT FIELDS & FILTERS ---

  # Default filters (show last 90 days)
  always_filter: {
    filters: [order_date: "90 days"]
  }

  # Default sorting — latest first
  default_sort: [order_date desc]


  # --- BUSINESS LOGIC / FRIENDLY LABELS ---

  # Define field sets for dashboards
  set: core_kpis {
    fields: [
      ecommerce_performance.order_count,
      ecommerce_performance.revenue,
      ecommerce_performance.avg_order_value,
      ecommerce_performance.units_sold,
      ecommerce_performance.new_customers,
      ecommerce_performance.returning_customers
    ]
  }

  set: trend_metrics {
    fields: [
      ecommerce_performance.revenue_growth_rate,
      ecommerce_performance.orders_growth_rate,
      ecommerce_performance.returning_customer_rate
    ]
  }


  # --- FILTERS ---

  # Common filters for dashboards or Looks
  filter: date_range {
    type: date
    field: ecommerce_performance.order_date
    default_value: "90 days"
    description: "Select time window for analysis (default: last 90 days)"
  }

  filter: product_category {
    type: string
    field: ecommerce_performance.product_type
    description: "Filter analytics by product type (e.g., Books, Fashion, Games)"
  }

  filter: sales_channel {
    type: string
    field: ecommerce_performance.source_name
    description: "Filter by sales channel (e.g., Web, Mobile, POS)"
  }


  # --- DRILL PATHS ---

  # Allow drill from aggregate date → day → product type → source
  drill_fields: [
    ecommerce_performance.order_date,
    ecommerce_performance.order_hour,
    ecommerce_performance.product_type,
    ecommerce_performance.source_name,
    ecommerce_performance.order_count,
    ecommerce_performance.revenue
  ]

 
  # --- VISUALIZATION & USABILITY ---

  # Conditional formatting (only works inside Looker dashboards)
  conditional_formatting: {
    measure: ecommerce_performance.revenue_growth_rate
    thresholds: [
      {value: 0, color: "#d9534f"},   # red for negative
      {value: 0.05, color: "#f0ad4e"}, # amber for moderate growth
      {value: 0.10, color: "#5cb85c"}  # green for strong growth
    ]
  }

  # Recommended visual drill:
  # daily → weekly → monthly breakdowns for revenue and orders
  suggestion: {
    label: "Revenue & Orders Over Time"
    description: "Analyze growth and seasonality patterns by channel and product type."
    fields: [
      ecommerce_performance.order_date,
      ecommerce_performance.revenue,
      ecommerce_performance.order_count
    ]
  }


  # --- EXPLAINABILITY NOTES ---

  # Business Logic Summary:
  # - Measures align to BigQuery mart `daily_ecommerce_performance`
  # - Filters optimize query performance (partition pruning)
  # - Time-based drill paths support interactive KPI exploration
  # - Conditional formatting visually highlights trends
}

