-- Monday Coffee -- Data Analysis

select * from city;
select * from products;
select * from customers;
select * from sales;


/* Question 1: How many people in each city are estimated to consume coffee, 
given that 25% of the population does?*/
select city_name,
	ROUND((population * 0.25)/1000000,2) as population_consum,
	city_rank
from city
order by 2;



/* Question 2:What is the total revenue 
generated from coffee sales across all cities in the last quarter of 2023?*/

SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
WHERE 
	EXTRACT(YEAR FROM s.sale_date)  = 2023
	AND
	EXTRACT(quarter FROM s.sale_date) = 4
GROUP BY 1
ORDER BY 2 DESC;

/*How many units of each coffee product have been sold?*/
SELECT 
	p.product_name,
	COUNT(s.sale_id) as total_orders
FROM products as p
LEFT JOIN
sales as s
ON s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC;


/*What is the average sales amount per customer in each city?*/
SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue,
	COUNT(DISTINCT s.customer_id) as total_cx,
	ROUND(
			SUM(s.total)::numeric/
				COUNT(DISTINCT s.customer_id)::numeric
			,2) as avg_sale_per_customer
	
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC;


/*Provide a list of cities along with their 
populations and estimated coffee consumers.*/
select 
	city_name,
	population,
	ROUND((population * 0.25)/1000000,2) as population_consum
from city
group by city_name
order by 1;

/*What are the top 3 selling products in each city based on sales volume?*/
SELECT * 
FROM 
(
	SELECT 
		ci.city_name,
		p.product_name,
		COUNT(s.sale_id) as total_orders,
		DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) as rank
	FROM sales as s
	JOIN products as p
	ON s.product_id = p.product_id
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1, 2
) as t1
WHERE rank <= 3


/*How many unique customers are there in each 
city who have purchased coffee products?*/
select 
	count(distinct c.customer_name) as count,
	ci.city_name	
from city as ci
join customers as c
on c.city_id = ci.city_id
join sales as s
on s.customer_id = c.customer_id
where s.product_id < 14
group by 2
order by 1 desc;


/*Find each city and their average sale per 
customer and avg rent per customer*/
SELECT 
	ci.city_name,
	COUNT(DISTINCT s.customer_id) as total_cx,
	ROUND(
		ci.estimated_rent::numeric/COUNT(DISTINCT s.customer_id)::numeric,2) as avg_rent_per_cx,
	ROUND(
			SUM(s.total)::numeric/
				COUNT(DISTINCT s.customer_id)::numeric
			,2) as avg_sale_per_customer
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1,ci.estimated_rent
ORDER BY 3 DESC; 


/*Sales growth rate: Calculate the percentage growth (or decline) 
in sales over different time periods (monthly).*/
with monthly_sales
as
(
select 
	ci.city_name,
	extract(month from s.sale_date) as month,
	extract(year from s.sale_date) as year,
	sum(s.total) as total_sale
	from sales as s
	join customers as c
	on c.customer_id = s.customer_id
	join city as ci
	on ci.city_id = c.city_id
	group by 1,2,3
	order by 1,3,2
),
growth_ratio 
as 
(
	select
		city_name,
		month,
		year,
		total_sale as cr_month_sale, --current month sales
		LAG(total_sale,1) OVER(PARTITION by city_name order by year,month) 
		as last_month_sale
	from monthly_sales)

select
	city_name,
	month,
	year,
	cr_month_sale,
	last_month_sale,
	ROUND((cr_month_sale-last_month_sale)::numeric/last_month_sale::numeric*100,2) as growth_rate

from 
	growth_ratio
where 
last_month_sale is not null;


/*Identify top 3 city based on highest sales, return city name, 
total sale, total rent, total customers, estimated coffee consumer*/
with city_table
as
(
select
		ci.city_name,
		sum(s.total) as total_sales,
		count(distinct s.customer_id) AS total_customers,
		ROUND(
				SUM(s.total)::numeric/
					COUNT(DISTINCT s.customer_id)::numeric
				,2) as c
	from sales as s
	join customers as c
	on s.customer_id = c.customer_id
	join city as ci
	on ci.city_id = c.city_id
	group by 1
	order by 1 desc
),
city_rent
as
(	select
	city_name,
	estimated_rent,
	ROUND((population * 0.25)/1000000, 3) as estimated_coffee_consumer_in_millions
	from city)
select 
	cr.city_name,
	ct.total_sales,
	cr.estimated_rent as total_rent,
	cr.estimated_coffee_consumer_in_millions,
	ct.total_customers,
	cr.estimated_rent as total_rent,
	round(cr.estimated_rent::numeric/ct.total_customers::numeric,2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC;