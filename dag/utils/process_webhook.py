# feel free to add anything you need here
import hashlib
from datetime import datetime
import pytz

REQUIRED_FIELDS = ["order_id", "customer_id", "total_price", "created_at"]

def hash_value(value: str) -> str:
    """Hash string value for privacy using SHA256."""
    if value is None or value == "":
        return None
    return hashlib.sha256(value.encode("utf-8")).hexdigest()

def to_berlin_time(utc_time_str: str) -> str:
    """Convert UTC timestamp to Berlin (CET/CEST) timezone."""
    try:
        utc = pytz.utc
        berlin = pytz.timezone("Europe/Berlin")
        utc_dt = datetime.strptime(utc_time_str, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=utc)
        berlin_dt = utc_dt.astimezone(berlin)
        return berlin_dt.strftime("%Y-%m-%d %H:%M:%S")
    except Exception:
        return None

def validate_required_fields(payload: dict) -> list[str]:
    """Check for missing or empty required fields."""
    errors = []
    for field in REQUIRED_FIELDS:
        if field not in payload or payload[field] in (None, ""):
            errors.append(f"Missing or empty field: {field}")
    return errors

def process_shopify_order_webhook(webhook_payload: dict) -> tuple[bool, dict, list[str]]:

    """

    Process Shopify order webhook and transform for BigQuery.

    Args:

        webhook_payload: Raw Shopify webhook JSON

    Returns:

        tuple: (is_valid: bool, transformed_data: dict, errors: list[str])

    """

    # Your implementation here
    errors = []
    all_orders = []
    all_line_items = []
    all_customers = []

    shopify_orders = webhook_payload.get("shopify_orders", [])
    shopify_customers = webhook_payload.get("shopify_customers", [])

    # Build customer lookup dict for quick matching
    customers_lookup = {c["customer_id"]: c for c in shopify_customers if "customer_id" in c}

    

    for order in shopify_orders:
        order_errors = validate_required_fields(order)
        if order_errors:
            errors.extend(order_errors)
            continue


        transformed_order = {
            "order_id": order.get("order_id"),
            "order_number": order.get("order_number"),
            "customer_id": order.get("customer_id"),
            "email": order.get("email"),
            "total_price": order.get("total_price"),
            "subtotal_price": order.get("subtotal_price"),
            "total_tax": order.get("total_tax"),
            "currency": order.get("currency", "EUR"),
            "financial_status": (order.get("financial_status") or "").lower(),
            "fulfillment_status": (order.get("fulfillment_status") or "").lower(),
            "tags": order.get("tags"),
            "source_name": order.get("source_name"),
            "created_at": to_berlin_time(order.get("created_at")),
            "updated_at": to_berlin_time(order.get("updated_at")),
            
        }
        all_orders.append(transformed_order)

        # Flatten line items for BigQuery table
        for item in order.get("line_items", []):
            all_line_items.append({
                "order_id": order.get("order_id"),
                "line_item_id": item.get("line_item_id"),
                "product_id": item.get("product_id"),
                "variant_id": item.get("variant_id"),
                "title": item.get("title"),
                "variant_title": item.get("variant_title"),
                "quantity": item.get("quantity"),
                "price": item.get("price"),
                "total_discount": item.get("total_discount"),
                "vendor": item.get("vendor"),
                "product_type": item.get("product_type"),
                "created_at": to_berlin_time(item.get("created_at")),
            })

    for customer in shopify_customers:
    

        transformed_customer = {
            "customer_id": customer.get("customer_id"),
            "email": customer.get("email"),
            "first_name": hash_value(customer.get("first_name")),
            "last_name": hash_value(customer.get("last_name")),
            "total_spent": customer.get("total_spent") ,
            "orders_count": customer.get("orders_count"),
            "accepts_marketing": customer.get("accepts_marketing"),
            "state": customer.get("state"),         
            "tags": customer.get("tags"),
            "created_at": to_berlin_time(order.get("created_at")),
            "updated_at": to_berlin_time(order.get("updated_at")),
        }
        all_customers.append(transformed_customer)

    transformed_data = {
        "orders": all_orders,
        "line_items": all_line_items,
        "customers": all_customers
    }

    return True, transformed_data, errors

   

# Add any utility functions needed for data validation, deduplication, etc.
