DROP TABLE IF EXISTs sales;
DROP TABLE if exists city;
drop table if exists product;
drop table if exists customers;


create table products (
	product_id int,
	product_name varchar(35)
	price float
);

create table sales (
	sale_id int primary key,
	sale_date date,
	product_id int,
	customer_id int,
	total float,
	rating int,
	
);

create table customers (
	customer_id,
	cus
)