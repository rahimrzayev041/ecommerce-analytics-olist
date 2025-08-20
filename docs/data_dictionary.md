# Olist E-commerce — Data Dictionary

> Source: Olist Brazilian E-Commerce Public Dataset (CSV) loaded into PostgreSQL `olist`.

## Table: `orders`
Primary key: `order_id`  
Indexes: `order_purchase_timestamp`

| Column | Type | Meaning |
|---|---|---|
| order_id | TEXT (PK) | Unique order identifier. |
| customer_id | TEXT | Buyer ID (FK → `customers.customer_id`). |
| order_status | TEXT | Order status (e.g., delivered, shipped, canceled, invoiced, processing). |
| order_purchase_timestamp | TIMESTAMP | When the purchase was placed. |
| order_approved_at | TIMESTAMP | When payment was approved. |
| order_delivered_carrier_date | TIMESTAMP | When the order left the seller to the carrier. |
| order_delivered_customer_date | TIMESTAMP | When the order was delivered to the customer. |
| order_estimated_delivery_date | TIMESTAMP | Estimated delivery date at purchase time. |

## Table: `order_items`
Primary key: **(order_id, order_item_id)**  
Indexes: `product_id`

| Column | Type | Meaning |
|---|---|---|
| order_id | TEXT | Order ID (FK → `orders.order_id`). |
| order_item_id | INT | Line item sequence within an order (starts at 1). |
| product_id | TEXT | Product ID (FK → `products.product_id`). |
| seller_id | TEXT | Seller ID (FK → `sellers.seller_id`). |
| shipping_limit_date | TIMESTAMP | Deadline for the seller to ship the item. |
| price | NUMERIC | Item price paid by the customer. |
| freight_value | NUMERIC | Shipping cost portion attributed to the item. |

## Table: `order_payments`
(No PK enforced; multiple payments per order are allowed.)

| Column | Type | Meaning |
|---|---|---|
| order_id | TEXT | Order ID (FK → `orders.order_id`). |
| payment_sequential | INT | Payment attempt/sequence within the order (1,2,…). |
| payment_type | TEXT | Method (credit_card, boleto, voucher, debit_card, not_defined). |
| payment_installments | INT | Number of installments (for applicable methods). |
| payment_value | NUMERIC | Amount paid in this payment row. |

## Table: `order_reviews`
Primary key: `review_id`  
(Loaded with de-duplication on `review_id`.)

| Column | Type | Meaning |
|---|---|---|
| review_id | TEXT (PK) | Unique review identifier. |
| order_id | TEXT | Reviewed order (FK → `orders.order_id`). |
| review_score | INT | Rating from 1 (worst) to 5 (best). |
| review_comment_title | TEXT | Short review title (optional). |
| review_comment_message | TEXT | Review body (optional). |
| review_creation_date | TIMESTAMP | When the review was created. |
| review_answer_timestamp | TIMESTAMP | When the platform/seller answered the review. |

## Table: `customers`
Primary key: `customer_id`  
Indexes: `customer_state`

| Column | Type | Meaning |
|---|---|---|
| customer_id | TEXT (PK) | Anonymized ID for a customer at order level. |
| customer_unique_id | TEXT | Persistent person identifier across orders (1:N with `customer_id`). |
| customer_zip_code_prefix | INT | ZIP prefix of the shipping address. |
| customer_city | TEXT | Customer city. |
| customer_state | TEXT | Two-letter state code. |

## Table: `sellers`
Primary key: `seller_id`  
Indexes: `seller_state`

| Column | Type | Meaning |
|---|---|---|
| seller_id | TEXT (PK) | Unique seller identifier. |
| seller_zip_code_prefix | INT | Seller location ZIP prefix. |
| seller_city | TEXT | Seller city. |
| seller_state | TEXT | Two-letter state code. |

## Table: `products`
Primary key: `product_id`

| Column | Type | Meaning |
|---|---|---|
| product_id | TEXT (PK) | Unique product identifier. |
| product_category_name | TEXT | Original (Portuguese) category name. |
| product_name_length | INT | Character count of product name (nullable). |
| product_description_length | INT | Character count of description (nullable). |
| product_photos_qty | INT | Number of product photos (nullable). |
| product_weight_g | INT | Weight in grams (nullable). |
| product_length_cm | INT | Length in cm (nullable). |
| product_height_cm | INT | Height in cm (nullable). |
| product_width_cm | INT | Width in cm (nullable). |

## Table: `geolocation`
(No PK; multiple points per ZIP prefix.)

| Column | Type | Meaning |
|---|---|---|
| geolocation_zip_code_prefix | INT | ZIP prefix. |
| geolocation_lat | FLOAT | Latitude. |
| geolocation_lng | FLOAT | Longitude. |
| geolocation_city | TEXT | City name (raw). |
| geolocation_state | TEXT | Two-letter state code. |

### Relationships (cardinality)
- `customers (1) ──< (N) orders`
- `orders (1) ──< (N) order_items`
- `products (1) ──< (N) order_items`
- `sellers (1) ──< (N) order_items`
- `orders (1) ──< (N) order_payments`
- `orders (1) ──< (N) order_reviews` (usually ≤1 per order, but duplicates exist in raw)
- `geolocation` links to customers/sellers by `*_zip_code_prefix` (no strict FK).

