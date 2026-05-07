create database global_fashion;

use global_fashion;
show tables;

describe transactions;

select * from transactions limit 1;
select count(*) from transactions;

USE global_fashion;

show columns from transactions;

USE global_fashion;
-- Check all 6 tables exist
SHOW TABLES;
-- Count rows in each table
SELECT 'transactions' AS table_name, COUNT(*) AS row_count FROM transactions
UNION ALL
SELECT 'customers', COUNT(*) FROM customers
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'stores', COUNT(*) FROM stores
UNION ALL
SELECT 'employees', COUNT(*) FROM employees
UNION ALL
SELECT 'discounts', COUNT(*) FROM discounts;

USE global_fashion;
DESCRIBE transactions;
DESCRIBE customers;
DESCRIBE products;
DESCRIBE stores;
DESCRIBE employees;
DESCRIBE discounts;

#data cleaning
#null(missing) values

USE global_fashion;

SELECT
  SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
  SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS null_product_id,
  SUM(CASE WHEN line_total IS NULL THEN 1 ELSE 0 END) AS null_line_total,
  SUM(CASE WHEN transaction_type IS NULL THEN 1 ELSE 0 END) AS null_type,
  SUM(CASE WHEN payment_method IS NULL THEN 1 ELSE 0 END) AS null_payment,
  SUM(CASE WHEN unit_price IS NULL THEN 1 ELSE 0 END) AS null_unit_price,
  SUM(CASE WHEN invoice_total IS NULL THEN 1 ELSE 0 END) AS null_invoice_total
FROM transactions;

SELECT
  SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
  SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) AS null_country,
  SUM(CASE WHEN city IS NULL THEN 1 ELSE 0 END) AS null_city,
  SUM(CASE WHEN gender IS NULL THEN 1 ELSE 0 END) AS null_gender,
  SUM(CASE WHEN date_of_birth IS NULL THEN 1 ELSE 0 END) AS null_dob
FROM customers;

#check duplicates
SELECT invoice_id, Line, COUNT(*) AS cnt
FROM transactions
GROUP BY invoice_id, Line
HAVING cnt > 1
LIMIT 10;

USE global_fashion;
DESCRIBE transactions;

#transaction types
SELECT transaction_type, COUNT(*) AS total
FROM transactions
GROUP BY transaction_type;

#date range
SELECT MIN(date) AS earliest, MAX(date) AS latest
FROM transactions;

#bad prices
SELECT COUNT(*) AS bad_prices
FROM transactions
WHERE unit_price <= 0 AND transaction_type = 'Sale';

SELECT COUNT(*) AS zero_qty
FROM transactions
WHERE quantity = 0;










#part_1 : Advanced SQL Analysis - Retail Sales
#Q1 - Customer Demographics
USE global_fashion;

SELECT
  c.country,
  c.city,
  COUNT(DISTINCT t.customer_id) AS unique_customers,
  ROUND(AVG(t.invoice_total), 2) AS avg_purchase_value
FROM transactions t
JOIN customers c ON t.customer_id = c.customer_id
WHERE t.transaction_type = 'Sale'
GROUP BY c.country, c.city
ORDER BY unique_customers DESC;

#Q2 - Monthly Return % Trend
SELECT
  DATE_FORMAT(date, '%Y-%m') AS month,
  COUNT(*) AS total_transactions,
  SUM(CASE WHEN transaction_type = 'Return'
      THEN 1 ELSE 0 END) AS total_returns,
  ROUND(
    SUM(CASE WHEN transaction_type = 'Return'
        THEN 1 ELSE 0 END)
    * 100.0 / COUNT(*),
  2) AS return_pct
FROM transactions
GROUP BY DATE_FORMAT(date, '%Y-%m')
ORDER BY month;

#Q3 - Top Categories by Revenue & % Share
SELECT
  p.category,
  ROUND(SUM(t.line_total), 2) AS total_revenue,
  ROUND(
    SUM(t.line_total) * 100.0
    / SUM(SUM(t.line_total)) OVER (),
  2) AS revenue_share_pct
FROM transactions t
JOIN products p ON t.product_id = p.product_id
WHERE t.transaction_type = 'Sale'
GROUP BY p.category
ORDER BY total_revenue DESC;

#Q4- Payment Method Performance
SELECT
  payment_method,
  COUNT(DISTINCT invoice_id) AS total_orders,
  ROUND(SUM(invoice_total), 2) AS total_sales_value,
  ROUND(AVG(invoice_total), 2) AS avg_basket_value
FROM transactions
WHERE transaction_type = 'Sale'
GROUP BY payment_method
ORDER BY total_sales_value DESC;

#Q5 - Promotion Impact
SELECT
  CASE WHEN discount > 0
       THEN 'Discounted'
       ELSE 'Full Price'
  END AS sale_type,
  COUNT(*) AS num_transactions,
  ROUND(SUM(line_total), 2) AS total_revenue,
  ROUND(AVG(line_total), 2) AS avg_line_value
FROM transactions
WHERE transaction_type = 'Sale'
GROUP BY sale_type
ORDER BY total_revenue DESC;

#Q6 - Customer Loyalty: New vs Repeat Customers
WITH first_purchase AS (
    SELECT
        customer_id,
        MIN(date) AS first_date
    FROM transactions
    WHERE transaction_type = 'Sale'
    GROUP BY customer_id
),
labeled AS (
    SELECT
        t.customer_id,
        t.date,
        t.invoice_total,
        CASE
            WHEN DATE_FORMAT(t.date,'%Y-%m')
               = DATE_FORMAT(fp.first_date,'%Y-%m')
            THEN 'New'
            ELSE 'Repeat'
        END AS customer_type
    FROM transactions t
    JOIN first_purchase fp ON t.customer_id = fp.customer_id
    WHERE t.transaction_type = 'Sale'
)
SELECT
    DATE_FORMAT(date, '%Y-%m') AS month,
    COUNT(DISTINCT CASE WHEN customer_type='New'
                   THEN customer_id END) AS new_customers,
    COUNT(DISTINCT CASE WHEN customer_type='Repeat'
                   THEN customer_id END) AS repeat_customers,
    ROUND(AVG(invoice_total), 2) AS avg_spend
FROM labeled
GROUP BY DATE_FORMAT(date, '%Y-%m')
ORDER BY month;

#Q7 - Store Performance Ranking
SELECT
  s.store_id,
  s.store_name,
  s.country,
  s.city,
  ROUND(SUM(
    CASE WHEN t.transaction_type = 'Sale'
         THEN t.line_total ELSE 0 END
  ), 2) AS total_revenue,
  COUNT(CASE WHEN t.transaction_type = 'Return'
             THEN 1 END) AS total_returns,
  COUNT(CASE WHEN t.transaction_type = 'Sale'
             THEN 1 END) AS total_sales,
  ROUND(
    COUNT(CASE WHEN t.transaction_type = 'Return'
               THEN 1 END)
    * 100.0
    / NULLIF(COUNT(CASE WHEN t.transaction_type = 'Sale'
                        THEN 1 END), 0),
  2) AS return_rate_pct
FROM transactions t
JOIN stores s ON t.store_id = s.store_id
GROUP BY s.store_id, s.store_name, s.country, s.city
ORDER BY total_revenue DESC;

#Q8 - Price Band Analysis
USE global_fashion;

SELECT
  CASE
    WHEN unit_price < 30  THEN 'Budget (under $30)'
    WHEN unit_price < 60  THEN 'Mid ($30 to $60)'
    WHEN unit_price < 100 THEN 'Premium ($60 to $100)'
    ELSE                       'Luxury (over $100)'
  END AS price_band,
  COUNT(*) AS num_transactions,
  ROUND(SUM(CASE WHEN transaction_type = 'Sale'
            THEN line_total ELSE 0 END), 2) AS total_revenue,
  ROUND(SUM(CASE WHEN transaction_type = 'Return'
            THEN ABS(line_total) ELSE 0 END), 2) AS total_returns,
  ROUND(AVG(CASE WHEN transaction_type = 'Sale'
            THEN line_total END), 2) AS avg_sale_value
FROM transactions
GROUP BY price_band
ORDER BY price_band;

#Q9 - Basket Size Insights
USE global_fashion;

WITH basket AS (
    SELECT
        t.invoice_id,
        c.country,
        SUM(t.quantity) AS total_items,
        MAX(t.invoice_total) AS basket_value
    FROM transactions t
    JOIN customers c ON t.customer_id = c.customer_id
    WHERE t.transaction_type = 'Sale'
    GROUP BY t.invoice_id, c.country
)
SELECT
    country,
    COUNT(invoice_id) AS num_orders,
    ROUND(AVG(total_items), 2) AS avg_items_per_order,
    ROUND(AVG(basket_value), 2) AS avg_order_value
FROM basket
GROUP BY country
ORDER BY avg_order_value DESC;

#Q10 - Monthly Revenue Growth
USE global_fashion;

WITH monthly_rev AS (
    SELECT
        DATE_FORMAT(date, '%Y-%m') AS month,
        p.category,
        ROUND(SUM(t.line_total), 2) AS revenue
    FROM transactions t
    JOIN products p ON t.product_id = p.product_id
    WHERE t.transaction_type = 'Sale'
    GROUP BY DATE_FORMAT(date, '%Y-%m'), p.category
),
top3 AS (
    SELECT category
    FROM monthly_rev
    GROUP BY category
    ORDER BY SUM(revenue) DESC
    LIMIT 3
),
with_prev AS (
    SELECT
        m.month,
        m.category,
        m.revenue,
        LAG(m.revenue)
            OVER (PARTITION BY m.category
                  ORDER BY m.month) AS prev_month_revenue
    FROM monthly_rev m
    JOIN top3 ON m.category = top3.category
)
SELECT
    month,
    category,
    revenue,
    prev_month_revenue,
    ROUND(
        (revenue - prev_month_revenue) * 100.0
        / NULLIF(prev_month_revenue, 0),
    2) AS mom_growth_pct
FROM with_prev
ORDER BY category, month;*



