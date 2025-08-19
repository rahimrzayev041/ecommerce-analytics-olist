\set ON_ERROR_STOP on
\copy orders         FROM 'data/raw/olist_orders_dataset.csv'           WITH (FORMAT csv, HEADER true);
\copy order_items    FROM 'data/raw/olist_order_items_dataset.csv'      WITH (FORMAT csv, HEADER true);
\copy order_payments FROM 'data/raw/olist_order_payments_dataset.csv'   WITH (FORMAT csv, HEADER true);
\copy order_reviews  FROM 'data/raw/olist_order_reviews_dataset.csv'    WITH (FORMAT csv, HEADER true);
\copy customers      FROM 'data/raw/olist_customers_dataset.csv'        WITH (FORMAT csv, HEADER true);
\copy sellers        FROM 'data/raw/olist_sellers_dataset.csv'          WITH (FORMAT csv, HEADER true);
\copy products       FROM 'data/raw/olist_products_dataset.csv'         WITH (FORMAT csv, HEADER true);
\copy geolocation    FROM 'data/raw/olist_geolocation_dataset.csv'      WITH (FORMAT csv, HEADER true);
ANALYZE;
