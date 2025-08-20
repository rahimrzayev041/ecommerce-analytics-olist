-- sql/01_kpis.sql
-- Core KPIs for Olist. All metrics computed on delivered orders by purchase month.
-- Run in psql: \i sql/01_kpis.sql

\echo 'Building KPI CTEs...'

WITH
delivered_orders AS (
    SELECT
        o.order_id,
        o.customer_id,
        DATE_TRUNC('month', o.order_purchase_timestamp)::date AS month,
        o.order_purchase_timestamp,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,
        (o.order_delivered_customer_date IS NOT NULL) AS is_delivered,
        (o.order_delivered_customer_date IS NOT NULL AND o.order_delivered_customer_date <= o.order_estimated_delivery_date) AS delivered_on_time
    FROM orders o
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp IS NOT NULL
),
order_gmv AS (
    SELECT
        oi.order_id,
        SUM(oi.price) AS items_value,
        SUM(oi.freight_value) AS freight_value,
        SUM(oi.price + oi.freight_value) AS gmv,
        COUNT(*) AS items_count
    FROM order_items oi
    GROUP BY 1
),
orders_join AS (
    SELECT
        d.*,
        og.items_value,
        og.freight_value,
        og.gmv,
        og.items_count
    FROM delivered_orders d
    LEFT JOIN order_gmv og USING (order_id)
),
customers_map AS (
    SELECT c.customer_id, c.customer_unique_id
    FROM customers c
),
-- First order month + order counts per unique customer (lifetime)
customer_orders AS (
    SELECT
        m.customer_unique_id,
        MIN(DATE_TRUNC('month', o.order_purchase_timestamp)::date) AS first_order_month,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM orders o
    JOIN customers_map m USING (customer_id)
    WHERE o.order_status IN ('delivered','shipped','invoiced','approved','processing','created')
      AND o.order_purchase_timestamp IS NOT NULL
    GROUP BY 1
),
base AS (
    SELECT
        j.order_id,
        j.month,
        j.gmv,
        j.items_value,
        j.freight_value,
        j.items_count,
        j.delivered_on_time,
        m.customer_unique_id
    FROM orders_join j
    LEFT JOIN customers_map m USING (customer_id)
),
monthly AS (
    SELECT
        month,
        COUNT(DISTINCT order_id) AS orders_cnt,
        SUM(gmv) AS gmv,
        SUM(items_value) AS items_value,
        SUM(freight_value) AS freight_value,
        SUM(CASE WHEN delivered_on_time THEN 1 ELSE 0 END) AS ontime_deliveries,
        COUNT(DISTINCT CASE WHEN customer_unique_id IS NOT NULL THEN order_id END) AS orders_with_customer
    FROM base
    GROUP BY 1
),
monthly_enriched AS (
    SELECT
        m.month,
        m.orders_cnt,
        m.gmv,
        m.items_value,
        m.freight_value,
        (m.gmv / NULLIF(m.orders_cnt,0))::numeric(12,2) AS aov,
        (m.ontime_deliveries::numeric / NULLIF(m.orders_cnt,0))::numeric(12,4) AS ontime_rate,
        AVG(m.orders_cnt) OVER (
            ORDER BY m.month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        )::numeric(12,2) AS orders_rolling_3mo_avg,
        LAG(m.orders_cnt) OVER (ORDER BY m.month) AS orders_prev_month,
        CASE WHEN LAG(m.orders_cnt) OVER (ORDER BY m.month) IS NULL THEN NULL
             ELSE ROUND(100.0*(m.orders_cnt - LAG(m.orders_cnt) OVER (ORDER BY m.month)) / NULLIF(LAG(m.orders_cnt) OVER (ORDER BY m.month),0), 2)
        END AS orders_mom_pct
    FROM monthly m
),
-- Cohort-based repeat rate (by first purchase month)
cohort_repeat AS (
    SELECT
        co.first_order_month AS cohort_month,
        COUNT(*) FILTER (WHERE co.total_orders >= 2) AS repeat_customers,
        COUNT(*) AS cohort_size,
        ROUND(100.0 * COUNT(*) FILTER (WHERE co.total_orders >= 2) / NULLIF(COUNT(*),0), 2) AS repeat_rate_pct
    FROM customer_orders co
    GROUP BY 1
),
-- Reviews by month (proxy CSAT/NPS)
reviews_monthly AS (
    SELECT
        DATE_TRUNC('month', r.review_creation_date)::date AS month,
        AVG(r.review_score)::numeric(12,2) AS avg_review_score,
        (COUNT(*) FILTER (WHERE r.review_score >= 4)::numeric / NULLIF(COUNT(*),0))::numeric(12,4) AS share_pos_reviews
    FROM order_reviews r
    GROUP BY 1
)
SELECT
    e.month,
    e.orders_cnt,
    e.orders_rolling_3mo_avg,
    e.gmv::numeric(14,2) AS gmv,
    e.aov,
    e.ontime_rate,
    e.orders_prev_month,
    e.orders_mom_pct,
    rv.avg_review_score,
    rv.share_pos_reviews
FROM monthly_enriched e
LEFT JOIN reviews_monthly rv USING (month)
ORDER BY e.month;

\echo '--- Cohort repeat rates (first purchase month) ---'
SELECT * FROM cohort_repeat ORDER BY cohort_month;

