# Power BI Setup (recommended model + measures)

## Model (relationships)
- **Orders** (Date: `order_purchase_timestamp` → link to `Calendar[Date]`)
- **Order Items** → Many-to-one to **Orders** on `order_id`
- **Customers** → One-to-many with **Orders** on `customer_id`
- **Reviews** → Many-to-one to **Orders** on `order_id` (optional inactive; use USERELATIONSHIP in measures if needed)
- Optional: **Products**, **Sellers** for drilldowns
- Add a **Calendar** table:

```DAX
Calendar = 
  VAR MinDate = DATE(2016,1,1)
  VAR MaxDate = DATE(2018,12,31)
  RETURN CALENDAR(MinDate, MaxDate)
```

## Calculated columns
In **Orders**:
```DAX
Order Month = DATE(YEAR(Orders[order_purchase_timestamp]), MONTH(Orders[order_purchase_timestamp]), 1)

Delivered On Time =
  VAR Delivered = NOT ISBLANK(Orders[order_delivered_customer_date])
  VAR OnTime = Orders[order_delivered_customer_date] <= Orders[order_estimated_delivery_date]
  RETURN IF(Delivered && OnTime, 1, 0)
```

## Core measures
```DAX
Orders := DISTINCTCOUNT(Orders[order_id])

GMV := SUM('Order Items'[price]) + SUM('Order Items'[freight_value])

AOV := DIVIDE([GMV], [Orders])

Active Customers := DISTINCTCOUNT(Customers[customer_unique_id])

Delivered Orders := CALCULATE([Orders], NOT ISBLANK(SELECTEDVALUE(Orders[order_delivered_customer_date])))

On-Time Deliveries := SUM(Orders[Delivered On Time])

On-Time Rate := DIVIDE([On-Time Deliveries], [Delivered Orders])

Orders MoM := [Orders] - CALCULATE([Orders], DATEADD('Calendar'[Date], -1, MONTH))

Orders MoM % := 
  VAR Prev = CALCULATE([Orders], DATEADD('Calendar'[Date], -1, MONTH))
  RETURN DIVIDE([Orders] - Prev, Prev)

Avg Review Score := AVERAGE(order_reviews[review_score])

Share Positive Reviews := 
  DIVIDE(
    CALCULATE(COUNTROWS(order_reviews), order_reviews[review_score] >= 4),
    COUNTROWS(order_reviews)
  )
```

## Pages & visuals
- **Overview**: KPI cards ([Orders], [GMV], [AOV], [On-Time Rate]); line chart Orders by month; bar chart GMV by month; slicers (category, state).
- **Customers**: Active Customers by month; cohort-style table (use first order month as group); RFM segment bar.
- **Operations**: Avg delivery days; On-Time Rate by seller/state; box/violin alt: clustered bars.
- **Geography**: Map of GMV by state/city; shipping distance vs delay (if you derive distance).

## Tips
- Create a measure for **Delivery Days** in Power Query or as a column in your fact table: `DATEDIFF(Orders[order_purchase_timestamp], Orders[order_delivered_customer_date], DAY)`.
- Hide keys/technical columns from the report view.
