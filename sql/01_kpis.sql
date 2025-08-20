\echo 'Building KPI CTEs...'

-- ========== 1) Monthly KPIs (single consolidated table) ==========
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
),
gmv_by_month AS (
  SELECT date_trunc('month', o.order_purchase_timestamp) AS month,
         SUM(oi.price + oi.freight_value) AS gmv
  FROM orders o
  JOIN order_items oi USING (order_id)
  GROUP BY 1
),
ontime_by_delivery_month AS (
  SELECT
    date_trunc('month', order_delivered_customer_date) AS month,
    COUNT(*)                                             AS delivered_total,
    COUNT(*) FILTER (WHERE order_delivered_customer_date <= order_estimated_delivery_date) AS delivered_on_time,
    COUNT(*) FILTER (WHERE order_delivered_customer_date <= order_estimated_delivery_date)::numeric
      / NULLIF(COUNT(*),0)                              AS ontime_rate
  FROM orders
  WHERE order_delivered_customer_date IS NOT NULL
  GROUP BY 1
),
reviews_by_month AS (
  SELECT
    date_trunc('month', review_creation_date) AS month,
    COUNT(*)                                  AS review_cnt,
    AVG(review_score)                         AS avg_review_score,
    COUNT(*) FILTER (WHERE review_score >= 4)::numeric
      / NULLIF(COUNT(*),0)                    AS share_pos_reviews
  FROM order_reviews
  GROUP BY 1
)
SELECT
  s.month::date AS month,

  COALESCE(o.orders_cnt, 0) AS orders_cnt,

  ROUND(AVG(COALESCE(o.orders_cnt,0)) OVER (
          ORDER BY s.month
          ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
       )::numeric, 2) AS orders_rolling_3mo_avg,

  COALESCE(g.gmv, 0)::numeric AS gmv,
  ROUND(COALESCE(g.gmv,0)::numeric / NULLIF(COALESCE(o.orders_cnt,0),0), 2) AS aov,

  -- on-time delivery (by delivery month)
  COALESCE(d.ontime_rate, 0)::numeric AS ontime_rate,

  -- previous month & MoM %
  LAG(COALESCE(o.orders_cnt,0)) OVER (ORDER BY s.month)            AS orders_prev_month,
  ROUND((
    COALESCE(o.orders_cnt,0) - LAG(COALESCE(o.orders_cnt,0)) OVER (ORDER BY s.month)
  ) / NULLIF(LAG(COALESCE(o.orders_cnt,0)) OVER (ORDER BY s.month), 0)::numeric, 4) AS orders_mom_pct,

  -- review metrics (by review month)
  ROUND(COALESCE(r.avg_review_score,0)::numeric, 2) AS avg_review_score,
  ROUND(COALESCE(r.share_pos_reviews,0)::numeric, 4) AS share_pos_reviews
FROM month_spine s
LEFT JOIN orders_by_month o  ON s.month = o.month
LEFT JOIN gmv_by_month g     ON s.month = g.month
LEFT JOIN reviews_by_month r ON s.month = r.month
LEFT JOIN ontime_by_delivery_month d ON s.month = d.month
ORDER BY month;

\echo '--- Cohort repeat rates (first purchase month) ---'

-- ========== 2) Cohort Repeat Purchase Rate (self-contained) ==========
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
  SELECT f.cohort_month, o.order_cnt
  FROM first_purchase f
  JOIN order_counts o USING (customer_unique_id)
)
SELECT
  cohort_month::date                           AS cohort_month,
  COUNT(*)                                     AS customers_ge_1,
  COUNT(*) FILTER (WHERE order_cnt >= 2)       AS customers_ge_2,
  ROUND(
    COUNT(*) FILTER (WHERE order_cnt >= 2)::numeric
    / NULLIF(COUNT(*), 0),
    4
  )                                            AS repeat_purchase_rate
FROM cohorted
GROUP BY 1
ORDER BY 1;
