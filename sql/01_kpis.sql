
-- =========================================================
-- Olist KPIs — sql/01_kpis.sql (PostgreSQL)
-- =========================================================

-- 1) Orders by month + rolling 3-month average
WITH month_spine AS (
  SELECT generate_series(
           date_trunc('month', (SELECT min(order_purchase_timestamp) FROM orders)),
           date_trunc('month', (SELECT max(order_purchase_timestamp) FROM orders)),
           interval '1 month'
         ) AS month
),
orders_by_month AS (
  SELECT date_trunc('month', order_purchase_timestamp) AS month,
         COUNT(*)::int AS orders_cnt
  FROM orders
  GROUP BY 1
)
SELECT
  s.month::date                                       AS month,
  COALESCE(o.orders_cnt, 0)                           AS orders_cnt,
  ROUND(AVG(COALESCE(o.orders_cnt,0)) OVER (
          ORDER BY s.month
          ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        )::numeric, 2)                                AS orders_rolling_3mo_avg
FROM month_spine s
LEFT JOIN orders_by_month o USING (month)
ORDER BY month;

-- 2) Revenue (GMV) by month = SUM(price + freight_value)
SELECT
  date_trunc('month', o.order_purchase_timestamp)::date AS month,
  SUM(oi.price + oi.freight_value)                      AS gmv
FROM orders o
JOIN order_items oi USING (order_id)
GROUP BY 1
ORDER BY 1;

-- 3) AOV by month = GMV / orders  (COALESCE GMV to 0 so tail months show 0.00, not NULL)
WITH monthly_orders AS (
  SELECT date_trunc('month', order_purchase_timestamp) AS month,
         COUNT(*)::int AS orders_cnt
  FROM orders
  GROUP BY 1
),
monthly_gmv AS (
  SELECT date_trunc('month', o.order_purchase_timestamp) AS month,
         SUM(oi.price + oi.freight_value)                AS gmv
  FROM orders o
  JOIN order_items oi USING (order_id)
  GROUP BY 1
)
SELECT
  m.month::date                                           AS month,
  COALESCE(g.gmv, 0)::numeric                             AS gmv,
  m.orders_cnt                                            AS orders_cnt,
  ROUND(COALESCE(g.gmv, 0)::numeric / NULLIF(m.orders_cnt,0), 2) AS aov
FROM monthly_orders m
LEFT JOIN monthly_gmv g USING (month)
ORDER BY month;

-- 4) Active customers per month (distinct customer_unique_id who ordered that month)
SELECT
  date_trunc('month', o.order_purchase_timestamp)::date AS month,
  COUNT(DISTINCT c.customer_unique_id)                  AS active_customers
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
GROUP BY 1
ORDER BY 1;

-- 5) Repeat purchase rate by first purchase cohort (by CUSTOMER_UNIQUE_ID)
--    RPR = customers with ≥2 lifetime orders / customers with ≥1 order,
--    cohorts defined by first purchase month of the customer_unique_id.
WITH orders_with_unique AS (
  SELECT o.order_id, o.order_purchase_timestamp, c.customer_unique_id
  FROM orders o
  JOIN customers c ON c.customer_id = o.customer_id
),
first_purchase AS (
  SELECT
    customer_unique_id,
    date_trunc('month', MIN(order_purchase_timestamp)) AS cohort_month
  FROM orders_with_unique
  GROUP BY 1
),
order_counts AS (
  SELECT customer_unique_id, COUNT(*) AS order_cnt
  FROM orders_with_unique
  GROUP BY 1
),
cohorted AS (
  SELECT
    f.cohort_month,
    o.order_cnt
  FROM first_purchase f
  JOIN order_counts o USING (customer_unique_id)
)
SELECT
  cohort_month::date                                   AS cohort_month,
  COUNT(*)                                             AS customers_ge_1,
  COUNT(*) FILTER (WHERE order_cnt >= 2)               AS customers_ge_2,
  ROUND(
    COUNT(*) FILTER (WHERE order_cnt >= 2)::numeric
    / NULLIF(COUNT(*), 0),
    4
  )                                                    AS repeat_purchase_rate
FROM cohorted
GROUP BY 1
ORDER BY 1;

-- 6) On-time delivery rate by delivery month
--    delivered_on_time: delivered_customer_date <= estimated_delivery_date
WITH delivered AS (
  SELECT
    date_trunc('month', order_delivered_customer_date) AS delivery_month,
    (order_delivered_customer_date <= order_estimated_delivery_date) AS on_time
  FROM orders
  WHERE order_delivered_customer_date IS NOT NULL
)
SELECT
  delivery_month::date                                  AS delivery_month,
  COUNT(*)                                              AS delivered_total,
  COUNT(*) FILTER (WHERE on_time)                       AS delivered_on_time,
  ROUND(
    COUNT(*) FILTER (WHERE on_time)::numeric
    / NULLIF(COUNT(*), 0),
    4
  )                                                     AS on_time_delivery_rate
FROM delivered
GROUP BY 1
ORDER BY 1;

-- =========================================================
-- End of file
-- =========================================================

