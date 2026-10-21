use OlistDB;
GO

-- Order status distribution
SELECT order_status, COUNT(*) AS orders,
       CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER() AS decimal(5,2)) AS percentage
FROM orders GROUP BY order_status ORDER BY orders DESC;

/*
orders  order_status percentage
96478	delivered	97.02
1107	shipped	    1.11
625	    canceled	0.63
609	    unavailable	0.61
314	    invoiced	0.32
301	    processing	0.30
5	    created	    0.01
2	    approved	0.00
*/

-- Date range of the data
SELECT MIN(order_purchase_timestamp) AS first_order, 
       MAX(order_purchase_timestamp) AS last_order
FROM orders;
/* 
first_order                    last_order
2016-09-04 21:15:19.0000000	   2018-10-17 17:30:18.0000000
*/


-- Are the dates in a logical order?
SELECT
  SUM(CASE WHEN order_approved_at < order_purchase_timestamp THEN 1 ELSE 0 END) AS approved_before_purchase,
  SUM(CASE WHEN order_delivered_carrier_date < order_approved_at THEN 1 ELSE 0 END) AS carrier_before_approval,
  SUM(CASE WHEN order_delivered_customer_date < order_delivered_carrier_date THEN 1 ELSE 0 END) AS delivered_before_carrier,
  SUM(CASE WHEN order_status = 'delivered' AND order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS delivered_but_no_date,
  SUM(CASE WHEN order_status <> 'delivered' AND order_delivered_customer_date IS NOT NULL THEN 1 ELSE 0 END) AS not_delivered_but_has_date
FROM orders;

/* 
 approved_before_purchase - 0	
carrier_before_approval - 1359	
delivered_before_carrier - 23	
delivered_but_no_date - 8	
not_delivered_but_has_date - 6
*/

-- Numeric ranges
SELECT MIN(price) AS min_price,
       MAX(price) AS max_price, 
       AVG(price) AS avg_price,
       SUM(CASE WHEN price <= 0 THEN 1 ELSE 0 END) AS nonpositive_prices,
       MIN(freight_value) AS min_freight, 
       MAX(freight_value) AS max_freight
FROM orderitems;

/* 
min_price - 0.850000023841858	
max_price - 6735	
avg_price - 120.653739029919	
nonpositive_prices - 0	
min_freight - 0	
max_freight - 409.679992675781
*/

-- review_score should be only 1 to 5
SELECT review_score, COUNT(*) AS [no.of reviews]
FROM order_reviews
GROUP BY review_score
ORDER BY review_score;

/*

review_score    no.of reviews
1	            11424
2	            3151
3	            8179
4	            19142
5	            57328

*/

-- payment_type: distinct values and counts
SELECT payment_type, COUNT(*) AS [no.of payments]
FROM orderpayments
GROUP BY payment_type
ORDER BY [no.of payments] DESC;

/*
payment_type   no.of payments
credit_card	    76795
boleto	        19784
voucher	        5775
debit_card	    1529
not_defined	    3
*/

-- state codes: should be 2-letter Brazilian state abbreviations
SELECT customer_state, COUNT(*) AS [no.of CX record with state code]
FROM customers
GROUP BY customer_state
ORDER BY [no.of CX record with state code] DESC;
/*
SP	41746
RJ	12852
MG	11635
RS	5466
PR	5045
SC	3637
BA	3380
DF	2140
ES	2033
GO	2020
PE	1652
CE	1336
PA	975
MT	907
MA	747
MS	715
PB	536
PI	495
RN	485
AL	413
SE	350
TO	280
RO	253
AM	148
AC	81
AP	68
RR	46
*/

--  for sellers.seller_state
SELECT seller_state, COUNT(*) AS  [no.of record with seller state code]
FROM sellers
GROUP BY seller_state
ORDER BY [no.of record with seller state code] DESC;

/*
SP	1849
PR	349
MG	244
SC	190
RJ	171
RS	129
GO	40
DF	30
ES	23
BA	19
CE	13
PE	9
PB	6
MS	5
RN	5
MT	4
RO	2
SE	2
MA	1
PA	1
AC	1
PI	1
AM	1
*/
-- product size and weight: zeros and extremes
SELECT MIN(product_weight_g) AS min_weight, MAX(product_weight_g) AS max_weight,
       SUM(CASE WHEN product_weight_g = 0 THEN 1 ELSE 0 END) AS zero_weight,
       MIN(product_length_cm) AS min_length, MAX(product_length_cm) AS max_length,
       MIN(product_height_cm) AS min_height, MAX(product_height_cm) AS max_height,
       MIN(product_width_cm)  AS min_width,  MAX(product_width_cm)  AS max_width
FROM products;

/*
 min_weight - 0
 max_weight - 40425	
 zero_weight - 4	
 min_length - 7	
 max_length - 105	
 min_height - 2	
 max_height - 105	
 min_width - 6	
 max_width - 118
*/
