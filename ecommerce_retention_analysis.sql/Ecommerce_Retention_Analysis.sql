Use olist_analysis;

-- =====================================
-- Data Validation
-- =====================================

SELECT COUNT(*) AS orders_rows FROM orders;
SELECT COUNT(*) AS customers_rows FROM customers;
SELECT COUNT(*) AS payments_rows FROM payments;
SELECT COUNT(*) AS reviews_rows FROM reviews_clean;
SELECT COUNT(*) AS order_items_rows FROM order_items;
SELECT COUNT(*) AS products_rows FROM products;

SELECT COUNT(*) AS matched_orders
FROM orders o
INNER JOIN customers c
On o.customer_id = c.customer_id;

SELECT COUNT(*) AS unmatched_orders
FROM orders o
LEFT JOIN customers c
On o.customer_id = c.customer_id
Where c.customer_id IS NULL;

-- =====================================
-- View Creation : Order Level
-- =====================================

Create or replace view order_level_view as
Select
o.order_id,
c.customer_unique_id,
o.order_purchase_timestamp,
p.total_payment,
o.order_delivered_customer_date,
o.order_estimated_delivery_date,
o.order_status
From orders o
Left Join customers c
On o.customer_id = c.customer_id
Left Join (
Select order_id,
Sum(payment_value) as total_payment
From payments
Group by order_id
) p
On o.order_id = p.order_id;

-- =====================================
-- View Creation : Customer Level
-- =====================================

Create or replace view customer_level_view as
With delivered_orders as (
Select *
From order_level_view
Where order_status = 'delivered'
)
, order_with_gap as (
Select
order_id,
customer_unique_id,
order_purchase_timestamp,
total_payment,
order_delivered_customer_date,
Lag(order_purchase_timestamp) Over (Partition by customer_unique_id order by order_purchase_timestamp) as prev_order,
DATEDIFF(
order_purchase_timestamp,
Lag(order_purchase_timestamp) Over (Partition by customer_unique_id order by order_purchase_timestamp)
) as gap
From delivered_orders
)

Select
customer_unique_id,
Min(order_purchase_timestamp) as first_order_date,
Max(order_purchase_timestamp) as last_order_date,
Count(order_id) as total_orders,
Sum(Coalesce(total_payment,0)) as total_spend,
Avg(Coalesce(total_payment,0)) as avg_order_value,
Avg(gap) as avg_order_gap,
DATEDIFF(Max(order_purchase_timestamp), Min(order_purchase_timestamp)) as customer_lifetime_days,
Case
When Count(order_id) > 1 Then 1
Else 0
End as is_repeat_customer
From order_with_gap
Group by customer_unique_id;

-- =====================================
-- 1. Overall Retention
-- =====================================

Select
Count(*) as total_customers,
Sum(is_repeat_customer) as repeat_customers,
Round(Sum(is_repeat_customer) * 100.0 / Count(*),2) as retention_pct
From customer_level_view;

-- =====================================
-- 2. Delivery Delay vs Retention
-- =====================================

With first_orders as (
Select
customer_unique_id,
order_id,
order_purchase_timestamp,
order_delivered_customer_date,
order_estimated_delivery_date,
Row_number() Over (Partition by customer_unique_id order by order_purchase_timestamp) as rn
From order_level_view
Where order_status = 'delivered'
)

Select
Case
When order_delivered_customer_date > order_estimated_delivery_date Then 'Delayed'
Else 'On_Time'
End as delivery_status,
Count(*) as total_customers,
Sum(c.is_repeat_customer) as repeat_customers,
Round(Sum(c.is_repeat_customer) * 100.0 / Count(*),2) as retention_pct
From first_orders f
Join customer_level_view c
On f.customer_unique_id = c.customer_unique_id
Where f.rn = 1
Group by delivery_status;

-- =====================================
-- 3. Delay Severity vs Retention
-- =====================================

With first_orders as (
Select
customer_unique_id,
order_purchase_timestamp,
order_delivered_customer_date,
order_estimated_delivery_date,
Row_number() Over (Partition by customer_unique_id order by order_purchase_timestamp) as rn
From order_level_view
Where order_status = 'delivered'
)

Select
Case
When DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) <= 0 Then 'On_Time'
When DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) Between 1 And 3 Then '1-3 Days Late'
When DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) Between 4 And 7 Then '4-7 Days Late'
Else '8+ Days Late'
End as delay_bucket,
Count(*) as total_customers,
Sum(c.is_repeat_customer) as repeat_customers,
Round(Sum(c.is_repeat_customer) * 100.0 / Count(*),2) as retention_pct
From first_orders f
Join customer_level_view c
On f.customer_unique_id = c.customer_unique_id
Where f.rn = 1
Group by delay_bucket
Order by
Case
When delay_bucket = 'On_Time' Then 1
When delay_bucket = '1-3 Days Late' Then 2
When delay_bucket = '4-7 Days Late' Then 3
Else 4
End;

-- =====================================
-- 4. Review Score vs Retention
-- =====================================

With first_reviews as (
Select
o.customer_unique_id,
r.review_score,
Row_number() Over (Partition by o.customer_unique_id order by o.order_purchase_timestamp) as rn
From order_level_view o
Join reviews_clean r
On o.order_id = r.order_id
Where o.order_status = 'delivered'
)

Select
Case
When review_score In (1,2) Then 'Low (1,2)'
When review_score = 3 Then 'Medium (3)'
Else 'High (4,5)'
End as review_bucket,
Count(*) as total_customers,
Sum(c.is_repeat_customer) as repeat_customers,
Round(Sum(c.is_repeat_customer) * 100.0 / Count(*),2) as retention_pct
From first_reviews f
Join customer_level_view c
On f.customer_unique_id = c.customer_unique_id
Where f.rn = 1
Group by review_bucket;

-- =====================================
-- 5. Delay + Review Combined
-- =====================================

With first_order_exp as (
Select
o.customer_unique_id,
Case
When o.order_delivered_customer_date > o.order_estimated_delivery_date Then 'Delayed'
Else 'On_Time'
End as delivery_status,
Case
When r.review_score In (1,2) Then 'Low'
When r.review_score = 3 Then 'Medium'
Else 'High'
End as review_bucket,
Row_number() Over (Partition by o.customer_unique_id order by o.order_purchase_timestamp) as rn
From order_level_view o
Join reviews_clean r
On o.order_id = r.order_id
Where o.order_status = 'delivered'
)

Select
delivery_status,
review_bucket,
Count(*) as total_customers,
Sum(c.is_repeat_customer) as repeat_customers,
Round(Sum(c.is_repeat_customer) * 100.0 / Count(*),2) as retention_pct
From first_order_exp f
Join customer_level_view c
On f.customer_unique_id = c.customer_unique_id
Where f.rn = 1
Group by delivery_status, review_bucket
Order by delivery_status, review_bucket;

-- =====================================
-- 6. Revenue Behaviour : Repeat vs One-Time
-- =====================================

Select
is_repeat_customer,
Count(*) as customers,
Avg(total_spend) as avg_total_spend,
Avg(avg_order_value) as avg_order_value,
Sum(total_spend) / Sum(total_orders) as segment_order_aov,
Avg(total_orders) as avg_total_orders
From customer_level_view
Group by is_repeat_customer;

-- =====================================
-- 7. Spend Tier vs Retention
-- =====================================

With first_orders as (
Select
customer_unique_id,
total_payment,
Row_number() Over (Partition by customer_unique_id order by order_purchase_timestamp) as rn
From order_level_view
Where order_status = 'delivered'
)

Select
Case
When Coalesce(total_payment,0) < 100 Then 'Low_spend'
When Coalesce(total_payment,0) Between 100 And 250 Then 'Medium_spend'
Else 'High'
End as spend_bucket,
Count(*) as total_customers,
Sum(c.is_repeat_customer) as repeat_customers,
Round(Sum(c.is_repeat_customer) * 100.0 / Count(*),2) as retention_pct
From first_orders f
Join customer_level_view c
On f.customer_unique_id = c.customer_unique_id
Where f.rn = 1
Group by spend_bucket;

-- =====================================
-- 8. Category Level Retention
-- =====================================

With first_orders as (
Select
customer_unique_id,
order_id,
order_purchase_timestamp,
Row_number() Over (Partition by customer_unique_id order by order_purchase_timestamp) as rn
From order_level_view
Where order_status = 'delivered'
)
, first_order_category as (
Select
f.customer_unique_id,
Min(p.product_category_name) as category
From first_orders f
Join order_items o
On f.order_id = o.order_id
Join products p
On o.product_id = p.product_id
Where f.rn = 1
Group by f.customer_unique_id
)

Select
f.category,
Count(*) as total_customers,
Sum(c.is_repeat_customer) as repeat_customers,
Round(Sum(c.is_repeat_customer) * 100.0 / Count(*),2) as retention_pct
From first_order_category f
Join customer_level_view c
On f.customer_unique_id = c.customer_unique_id
Group by f.category
Having Count(*) >= 100
Order by retention_pct Desc
Limit 10;
