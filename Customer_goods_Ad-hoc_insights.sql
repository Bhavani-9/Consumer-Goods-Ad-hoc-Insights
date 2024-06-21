-- 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.--

SELECT DISTINCT market FROM dim_customer
WHERE customer = "Atliq Exclusive" AND region = 'APAC';

-- 2. What is the percentage of unique product increase in 2021 vs. 2020? 
-- The final output contains these fields, unique_products_2020, unique_products_2021, percentage_chg --

SELECT COUNT(DISTINCT(p.product_code)) AS unique_products_2020
FROM dim_product p
JOIN fact_gross_price gp
ON p.product_code = gp.product_code
WHERE fiscal_year = 2020;

SELECT COUNT(DISTINCT(p.product_code)) AS unique_products_2021
FROM dim_product p
JOIN fact_gross_price gp
ON p.product_code = gp.product_code
WHERE fiscal_year = 2021;

WITH x AS (SELECT COUNT(DISTINCT(p.product_code)) AS unique_products_2020
			FROM dim_product p
			JOIN fact_gross_price gp
			ON p.product_code = gp.product_code
			WHERE fiscal_year = 2020),
	 y AS (	SELECT COUNT(DISTINCT(p.product_code)) AS unique_products_2021
			FROM dim_product p
			JOIN fact_gross_price gp
			ON p.product_code = gp.product_code
			WHERE fiscal_year = 2021)
SELECT 	unique_products_2020,
		unique_products_2021,
		ROUND(((unique_products_2021-unique_products_2020)*100/unique_products_2020),1) AS prc_change
FROM x ,y;

# 3. Provide a report with all the unique product counts for each segment
# and sort them in descending order of product counts. 
#The final output contains 2 fields, segment, product_count
SELECT * FROM gdb023.dim_product;
SELECT segment,COUNT(product_code) AS product_ccount
FROM dim_product
GROUP BY segment 
ORDER BY product_ccount DESC;

# 4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? 
# The final output contains these fields, segment, product_count_2020, product_count_2021, difference


SELECT  p.product_code AS product_count_2020 FROM dim_product p
JOIN fact_gross_price gp
ON p.product_code = gp.product_code
WHERE gp.fiscal_year=2020;

SELECT  p.product_code AS product_count_2021 FROM dim_product p
JOIN fact_gross_price gp
ON p.product_code = gp.product_code
WHERE gp.fiscal_year=2021;


WITH x AS 
		(SELECT p.segment,COUNT(DISTINCT(p.product_code)) AS product_count_2020 
FROM dim_product p
JOIN fact_gross_price gp
ON p.product_code = gp.product_code
WHERE gp.fiscal_year=2020
GROUP BY p.segment),
	y AS 
		(SELECT p.segment,COUNT(DISTINCT(p.product_code)) AS product_count_2021 
FROM dim_product p
JOIN fact_gross_price gp
ON p.product_code = gp.product_code
WHERE gp.fiscal_year=2021
GROUP BY segment)
SELECT x.segment,x.product_count_2020,y.product_count_2021,(y.product_count_2021-x.product_count_2020) AS difference
FROM x
JOIN y
ON x.segment = y.segment
GROUP BY segment
ORDER BY difference DESC
LIMIT 1;

# 5. Get the products that have the highest and lowest manufacturing costs.
# The final output should contain these fields, product_code, product, manufacturing_cost

WITH man_rank AS(
SELECT 	p.product_code,
		p.product,
        m.manufacturing_cost,
        RANK() OVER (ORDER BY m.manufacturing_cost DESC) AS max_rank,
        RANK() OVER (ORDER BY m.manufacturing_cost ASC) AS min_rank
FROM dim_product p
JOIN fact_manufacturing_cost m
ON p.product_code = m.product_code)
SELECT product_code,product,manufacturing_cost FROM man_rank
WHERE max_rank =1 
OR min_rank =1;

# 6. Generate a report which contains the top 5 customers who received 
# an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. 
# The final output contains these fields, customer_code, customer, average_discount_percentage

SELECT 	c.customer_code,
		c.customer,
		AVG(d.pre_invoice_discount_pct) AS average_discount_percentage FROM dim_customer c
JOIN fact_pre_invoice_deductions d
ON c.customer_code = d.customer_code
WHERE d.fiscal_year = 2021 
AND market = 'INDIA'
GROUP BY c.customer,c.customer_code
ORDER BY average_discount_percentage DESC
LIMIT 5;

# 7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . 
# This analysis helps to get an idea of low and high-performing months and take strategic decisions. 
# The final report contains these columns: Month, Year, Gross sales Amount

SELECT 	monthname(s.date) AS month ,
		YEAR(s.date) AS year,
        SUM(g.gross_price*s.sold_quantity) AS Gross_sales_Amount
FROM fact_gross_price g
JOIN fact_sales_monthly s
ON g.product_code = s.product_code
JOIN dim_customer c
ON c.customer_code = s.customer_code
WHERE c.customer = 'Atliq Exclusive'
GROUP BY month,year
ORDER BY year, month ;

# 8. In which quarter of 2020, got the maximum total_sold_quantity? 
# The final output contains these fields sorted by the total_sold_quantity, Quarter, total_sold_quantity

SELECT QUARTER(date) AS quater,
		SUM(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly 
WHERE fiscal_year = 2020
GROUP BY quater
ORDER BY total_sold_quantity DESC
LIMIT 1;

# 9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
# The final output contains these fields, channel gross_sales_mln, percentage.


WITH sales AS (
SELECT 	c.channel ,
		SUM(g.gross_price*s.sold_quantity) gross_sales_mln
FROM dim_customer c
JOIN fact_sales_monthly s
ON c.customer_code = s.customer_code
JOIN fact_gross_price g
ON s.product_code = g.product_code
WHERE s.fiscal_year = 2021
GROUP BY c.channel)
SELECT 	channel,
		gross_sales_mln,
        ROUND(gross_sales_mln*100/(SELECT SUM(gross_sales_mln) FROM sales),1) as percentage
FROM sales
ORDER BY gross_sales_mln DESC
LIMIT 1;

# 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
# The final output contains these fields, division, product_code,product, total_sold_quantity, rank_order
 WITH CTE AS (       
SELECT 	p.division,
		p.product_code,
        p.product,
        SUM(s.sold_quantity) AS total_sold_quantity,
        row_number() OVER(PARTITION BY p.division ORDER BY SUM(s.sold_quantity) DESC) AS tsq_rank
FROM fact_sales_monthly s
JOIN  dim_product p
ON s.product_code = p.product_code
WHERE s.fiscal_year = 2021
GROUP BY p.product,p.division,p.product_code)
SELECT division,product_code,product,total_sold_quantity FROM CTE
WHERE tsq_rank <=3
ORDER BY total_sold_quantity DESC















