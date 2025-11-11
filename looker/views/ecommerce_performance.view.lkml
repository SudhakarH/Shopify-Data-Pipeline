Write a LookML view for the e-commerce performance mart:

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
  
  # --- DIMENSIONS ---

  dimension_group: order_date {
    type: time
    timeframes: [raw, hour, date, week, month, quarter, year]
    sql: ${TABLE}.order_date ;;
    datatype: date
    convert_tz: no
    label: "Order Date"
    description: "Date when orders were placed"
  }

  dimension: product_type {
    primary_key: no
    sql: ${TABLE}.product_type ;;
    label: "Product Type"
    description: "Type of product sold (e.g., Book, Clothing, Game)"
  }

  dimension: source_name {
    sql: ${TABLE}.source_name ;;
    label: "Sales Channel"
    description: "Source or channel through which the order was placed (web, mobile, pos)"
  }

  dimension: financial_status {
    sql: ${TABLE}.financial_status ;;
    label: "Financial Status"
    description: "Order payment status (paid, pending, etc.)"
  }

  
  # --- MEASURES ---

  measure: order_count {
    type: sum
    sql: ${TABLE}.order_count ;;
    label: "Total Orders"
    description: "Total number of orders placed"
  }

  measure: units_sold {
    type: sum
    sql: ${TABLE}.units_sold ;;
    label: "Units Sold"
    description: "Total quantity of products sold"
  }

  measure: revenue {
    type: sum
    sql: ${TABLE}.revenue ;;
    value_format_name: "eur"
    label: "Total Revenue (€)"
    description: "Total gross revenue excluding refunded orders"
  }

  measure: avg_order_value {
    type: average
    sql: ${TABLE}.avg_order_value ;;
    value_format_name: "eur"
    label: "Average Order Value (€)"
    description: "Average revenue per order"
  }

  measure: new_customers {
    type: sum
    sql: ${TABLE}.new_customers ;;
    label: "New Customers"
    description: "Count of customers placing their first order on that date"
  }

  measure: returning_customers {
    type: sum
    sql: ${TABLE}.returning_customers ;;
    label: "Returning Customers"
    description: "Count of customers who have ordered before this date"
  }

  # --- DERIVED / CALCULATED FIELDS ---

  measure: returning_customer_rate {
    type: number
    sql: SAFE_DIVIDE(${returning_customers}, (${new_customers} + ${returning_customers})) ;;
    value_format_name: "percent_1"
    label: "Returning Customer Rate"
    description: "Proportion of returning customers among all customers for the period"
  }

  measure: avg_units_per_order {
    type: number
    sql: SAFE_DIVIDE(${units_sold}, NULLIF(${order_count}, 0)) ;;
    label: "Avg Units per Order"
    description: "Average number of items per order"
  }

  measure: revenue_growth_rate {
    type: number
    sql: SAFE_DIVIDE(
      ${revenue} - LAG(${revenue}) OVER (ORDER BY ${order_date}),
      LAG(${revenue}) OVER (ORDER BY ${order_date})
    ) ;;
    value_format_name: "percent_1"
    label: "Revenue Growth Rate"
    description: "Day-over-day revenue growth percentage"
  }

  measure: orders_growth_rate {
    type: number
    sql: SAFE_DIVIDE(
      ${order_count} - LAG(${order_count}) OVER (ORDER BY ${order_date}),
      LAG(${order_count}) OVER (ORDER BY ${order_date})
    ) ;;
    value_format_name: "percent_1"
    label: "Order Growth Rate"
    description: "Day-over-day change in order volume"
  }

  # --- DEFAULTS & SETTINGS ---
  always_filter: {
    filters: [order_date: "90 days"]
  }

  # Helps Looker auto-select date as default sort field
  default_sort: [order_date desc]


}