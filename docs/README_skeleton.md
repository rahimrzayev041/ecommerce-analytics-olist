# E-Commerce Analytics (Olist, Brazil) — Portfolio Project

End-to-end analytics on a real marketplace dataset: KPIs, cohorts/retention, RFM, shipping SLAs, and a dashboard (Power BI/Tableau).

## Repo structure
```
data/
  raw/                # original CSVs (git-ignored)
  processed/          # exports for BI
notebooks/
  01_connect_and_eda.ipynb
sql/
  00_schema_postgres.sql
  01_kpis.sql
docs/
  powerbi_dax.md
  case_study.md
```

## How to reproduce
1. Create a PostgreSQL DB `olist` and import CSVs into tables named: `orders`, `order_items`, `order_payments`, `order_reviews`, `customers`, `geolocation`, `products`, `sellers` (+ optional `product_category_name_translation`).
2. Run `sql/00_schema_postgres.sql` to add PKs & indexes.
3. Run `sql/01_kpis.sql` to generate monthly KPIs & cohort repeat table.
4. Open `notebooks/01_connect_and_eda.ipynb` for Python EDA, RFM, and exports to `data/processed/` for your dashboard.

## Deliverables
- SQL KPIs and cohort analysis
- Python EDA, RFM, shipping lead-times
- A BI dashboard
- Short case study in `docs/case_study.md`
