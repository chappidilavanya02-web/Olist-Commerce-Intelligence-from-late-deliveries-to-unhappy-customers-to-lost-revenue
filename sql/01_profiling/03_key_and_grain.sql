--STEP : 3 Grain & keys
--purpose: For every table, confirm what one row means and which column(S) identify it.
--Results are summaried in docs/data_dictionary.md


use OlistDB ;
GO

-- orders table : one row = one order, key: order_id
SELECT COUNT(*) AS total_rows, 
        COUNT(DISTINCT order_id) AS distinct_orders
FROM orders;
--Result: total_rows = 99441, distinct_orders = 99441 (equal, so order_id is the primary key)

-- orderitems table : one row = one item in an order. Key: (order_id, order_item_id)
SELECT COUNT(*) AS duplicate_keys
FROM (SELECT order_id, order_item_id
      FROM orderitems
      GROUP BY order_id, order_item_id
      HAVING COUNT(*) > 1) d; 
-- Result: duplicate_keys = 0 (the pair is a valid composite key)

--customers table:  one row = one customer record per order. Key: customer_id
SELECT COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customer_ids,
    COUNT(DISTINCT customer_unique_id) AS unique_customers_unique_ids
FROM customers;
-- Result: 99441 rows, 99441 distinct customer_id, 96096 distinct customer_unique_id
-- customer_id is the primary key. The 3345 extra records (99441 - 96096) belong to
-- people who ordered more than once. Use customer_unique_id to count real customers.

--products table: one row = one product. Key: product_id
SELECT COUNT(*) AS total_rows, 
        COUNT(DISTINCT product_id) AS Distinct_product_ids
FROM products;
-- Result: total_rows = 32951, distinct_product_ids = 32951 (equal, so product_id is the primary key)

--payments table: one row = one payment record of an order. Key: (order_id, payment_sequential)
SELECT COUNT(*) AS duplicate_keys
FROM (SELECT order_id, payment_sequential
      FROM orderpayments
      GROUP BY order_id, payment_sequential
      HAVING COUNT(*) > 1) d; 
--Result: duplicate_keys = 0 (the pair is a valid composite key)

--sellers table: one row = one seller. Key: seller_id
SELECT COUNT(*) AS total_rows, 
        COUNT(DISTINCT seller_id) AS Distinct_seller_id
FROM sellers;
-- Result: total_rows = 3095, distinct_seller_ids = 3095 (equal, so seller_id is the primary key)


--reviews table:  one row = one review attached to one order.
SELECT COUNT(*) AS total_rows,
        COUNT(DISTINCT review_id) AS Distinct_review_id
FROM order_reviews
-- Result: 99224 rows, 98410 distinct review_id, so review_id alone is NOT unique.

-- 1. Is (review_id, order_id) unique?
SELECT COUNT(*) AS duplicate_keys
FROM (SELECT review_id, order_id
      FROM order_reviews
      GROUP BY review_id, order_id
      HAVING COUNT(*) > 1) d;
-- Result: duplicate_keys = 0, so the key is (review_id, order_id)


-- 2. How many orders have more than one review?
SELECT COUNT(*) AS orders_with_multiple_reviews
FROM (SELECT order_id
      FROM order_reviews
      GROUP BY order_id
      HAVING COUNT(*) > 1) d;
-- Result: 547 orders. Reduce reviews to one row per order before joining to orders.


-- 3. Look at a few repeated review_ids
SELECT TOP 10 review_id, COUNT(*) AS n
FROM order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1
ORDER BY n DESC;
-- Result: the most repeated review_ids appear 3 times.


--geolocation table: no natural key
SELECT COUNT(*) as total_rows, 
        COUNT(DISTINCT geolocation_zip_code_prefix) as distinct_geolocation_zip
FROM geolocation;
--Result: 1000163 rows, 19015 distinct zip prefixes (about 52 rows per prefix).
-- Collapse to one row per prefix before joining.
