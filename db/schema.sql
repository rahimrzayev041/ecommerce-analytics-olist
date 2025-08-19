-- orders
CREATE TABLE IF NOT EXISTS orders (
  order_id TEXT PRIMARY KEY,
  customer_id TEXT,
  order_status TEXT,
  order_purchase_timestamp TIMESTAMP,
  order_approved_at TIMESTAMP,
  order_delivered_carrier_date TIMESTAMP,
  order_delivered_customer_date TIMESTAMP,
  order_estimated_delivery_date TIMESTAMP
);

-- order_items (item id repeats per order -> composite PK)
CREATE TABLE IF NOT EXISTS order_items (
  order_id TEXT,
  order_item_id INT,
  product_id TEXT,
  seller_id TEXT,
  shipping_limit_date TIMESTAMP,
  price NUMERIC,
  freight_value NUMERIC,
  PRIMARY KEY (order_id, order_item_id)
);

-- order_payments
CREATE TABLE IF NOT EXISTS order_payments (
  order_id TEXT,
  payment_sequential INT,
  payment_type TEXT,
  payment_installments INT,
  payment_value NUMERIC
);

-- order_reviews
CREATE TABLE IF NOT EXISTS order_reviews (
  review_id TEXT PRIMARY KEY,
  order_id TEXT,
  review_score INT,
  review_comment_title TEXT,
  review_comment_message TEXT,
  review_creation_date TIMESTAMP,
  review_answer_timestamp TIMESTAMP
);

-- customers
CREATE TABLE IF NOT EXISTS customers (
  customer_id TEXT PRIMARY KEY,
  customer_unique_id TEXT,
  customer_zip_code_prefix INT,
  customer_city TEXT,
  customer_state TEXT
);

-- sellers
CREATE TABLE IF NOT EXISTS sellers (
  seller_id TEXT PRIMARY KEY,
  seller_zip_code_prefix INT,
  seller_city TEXT,
  seller_state TEXT
);

-- products
CREATE TABLE IF NOT EXISTS products (
  product_id TEXT PRIMARY KEY,
  product_category_name TEXT,
  product_name_length INT,
  product_description_length INT,
  product_photos_qty INT,
  product_weight_g INT,
  product_length_cm INT,
  product_height_cm INT,
  product_width_cm INT
);

-- geolocation
CREATE TABLE IF NOT EXISTS geolocation (
  geolocation_zip_code_prefix INT,
  geolocation_lat FLOAT,
  geolocation_lng FLOAT,
  geolocation_city TEXT,
  geolocation_state TEXT
);

-- indexes
CREATE INDEX IF NOT EXISTS idx_orders_purchase_ts  ON orders(order_purchase_timestamp);
CREATE INDEX IF NOT EXISTS idx_customers_state     ON customers(customer_state);
CREATE INDEX IF NOT EXISTS idx_sellers_state       ON sellers(seller_state);
CREATE INDEX IF NOT EXISTS idx_order_items_product ON order_items(product_id);
