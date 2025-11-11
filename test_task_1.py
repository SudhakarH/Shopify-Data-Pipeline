import json
from dag.utils.process_webhook import process_shopify_order_webhook

with open("payload_example.json") as f:
    data = json.load(f)

is_valid, transformed, errors = process_shopify_order_webhook(data)

print("Valid:", is_valid)
print("Errors:", errors)
print("Orders:", len(transformed["orders"]))
print("Line Items:", len(transformed["line_items"]))
print("Customers:", len(transformed["customers"]))
print(json.dumps(transformed["orders"], indent=2))
print(json.dumps(transformed["line_items"], indent=2))
print(json.dumps(transformed["customers"], indent=2))


#this script just for testing process_shopify_order_webhook 