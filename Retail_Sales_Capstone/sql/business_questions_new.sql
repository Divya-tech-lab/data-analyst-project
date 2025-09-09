create database retails_sales_db_2;

use retails_sales_db_2; 


CREATE TABLE customers (
  customer_id VARCHAR(20) PRIMARY KEY,
  first_name  VARCHAR(100),
  last_name   VARCHAR(100),
  gender      VARCHAR(20),
  age         INT,
  signup_date DATE,
  region      VARCHAR(50),
  age_group   VARCHAR(50)
); 

CREATE TABLE products (
  product_id   VARCHAR(20) PRIMARY KEY,
  product_name VARCHAR(200),
  category     VARCHAR(100),
  brand        VARCHAR(100),
  cost_price   DECIMAL(10,2),
  unit_price   DECIMAL(10,2),
  margin_pct   DECIMAL(5,2),
  profit       DECIMAL(12,2)
);


CREATE TABLE stores (
  store_id       VARCHAR(20) PRIMARY KEY,
  store_name     VARCHAR(150),
  store_type     VARCHAR(50),
  region         VARCHAR(50),
  city           VARCHAR(100),
  operating_cost DECIMAL(12,2)
);

-- inserting new row in stores table to representing online store for foreign key to work
insert into stores values('online_store','online','online','online','online',0);

CREATE TABLE sales (
  order_id      VARCHAR(20) PRIMARY KEY,
  order_date    DATE NOT NULL,
  customer_id   VARCHAR(20) NOT NULL,
  product_id    VARCHAR(20) NOT NULL,
  store_id      VARCHAR(20) NOT NULL,
  sales_channel VARCHAR(50),
  quantity      INT NOT NULL,
  unit_price    DECIMAL(10,2) NOT NULL,
  discount_pct  DECIMAL(5,2) DEFAULT 0,
  total_amount  DECIMAL(12,2) NOT NULL,
  CONSTRAINT fk_sales_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
  CONSTRAINT fk_sales_product  FOREIGN KEY (product_id)  REFERENCES products(product_id),
  CONSTRAINT fk_sales_store    FOREIGN KEY (store_id)    REFERENCES stores(store_id)
);


CREATE TABLE returns (
  return_id     VARCHAR(20) PRIMARY KEY,
  order_id      VARCHAR(20),
  return_date   DATE,
  return_reason VARCHAR(100),
  CONSTRAINT fk_returns_order FOREIGN KEY (order_id) REFERENCES sales(order_id)
);

# calculate actual discount on sales table
select unit_price, discount_pct, round((unit_price * discount_pct), 2) as actual_discount
from sales;


# BUSINESS QUESTIONS
#(1) What is the total revenue generated in the last 12 months?

select count(*), sum(total_amount) as totalrevenuegenerated_last12months
from sales
where order_date >= '2024-04-10'
  and order_date <= '2025-07-31';


#(2) Which are the top 5 best-selling products by quantity?
select p.Product_id,
       p.Product_name,
       SUM(s.quantity) as TotalQuantitySold
from Products p
         join
     sales s on p.Product_id = s.Product_id
group by p.Product_id, p.Product_name
order by TotalQuantitySold desc
limit 5;



#(3) How many customers are from each region?
select region, count(customer_id) as number_of_customers
from customers
group by region;

#(4) Which store has the highest profit in the past year?

select s.store_id,
       st.store_name,
       round(sum(s.total_amount - (p.cost_price * s.quantity)), 2) as profit_perstore
from sales s
         left join products p
                   on s.product_id = p.product_id
         join stores st
              on st.store_id = s.store_id
where s.order_date between '2024-01-01' and '2024-12-31' and s.store_id != 'online_store'
GROUP BY s.store_id, st.store_name
order by profit_perstore desc
limit 1;

# (5) What is the return rate by product category?
with sales_with_return_flag as (select s.order_id,
                                       p.category,
                                       s.quantity,
                                       case
                                           when r.order_id is null then null
                                           else 1 end as is_returned
                                from sales s
                                         left join
                                         returns r
                                         on s.order_id = r.order_id
                                         join products p on p.product_id = s.product_id),
sales_per_category as 
(
select p.category,sum(s.quantity) as sum_of_quantity from sales s join products p on p.product_id = s.product_id
 group by p.category)
 
select swrf.category,
      sum(is_returned*quantity),
       spc.sum_of_quantity,
       (sum(is_returned*quantity) * 100.0 / spc.sum_of_quantity) as return_rate
from sales_with_return_flag swrf join sales_per_category spc on swrf.category =spc.category
group by category;

#
# SELECT
#     p.category,
#     COUNT(r.order_id),
#     COUNT(s.order_id),
#     CAST(COUNT(r.order_id) AS DECIMAL) *100.0/ COUNT(s.order_id) AS return_rate
# FROM
#     Sales s
# INNER JOIN
#     Products p ON s.product_id = p.product_id
# LEFT JOIN
#     (select distinct order_id from returns) r ON s.order_id = r.order_id
# GROUP BY
#     p.category
# ORDER BY
#     return_rate DESC;
# returns orders/total orders

#(6) What is the average revenue per customer by age group?
select c.age_group, round(avg(s.total_amount),2)
from sales s
         join customers c on s.customer_id = c.customer_id
group by c.age_group;







#(7) Which sales channel (Online vs In-Store) is more profitable on average?
select s.sales_channel,
       round(sum(s.total_amount - (p.cost_price * s.quantity)), 2) as profit_perchannel
from sales s
         left join products p
                   on s.product_id = p.product_id
where s.order_date between '2024-01-01' and '2024-12-31'
GROUP BY s.sales_channel;

#(8) How has monthly profit changed over the last 2 years by region?

select month(s.order_date),
       year(s.order_date),
       -- DATE_FORMAT(s.order_date, '%Y-%m-01') first_day_of_month,
       st.region,
       round(sum(s.total_amount - (p.cost_price * s.quantity)), 2) as profit_per_month
from sales s
         left join products p
                   on s.product_id = p.product_id
         left join stores st
                   on st.store_id = s.store_id
where s.order_date between '2023-01-01' and '2025-12-31'
  and s.store_id != 'online_store'
GROUP BY month(s.order_date), year(s.order_date),
         -- DATE_FORMAT(s.order_date, '%Y-%m-01'),
         st.region
order by 1, 2;

#(9) Identify the top 3 products with the highest return rate in each category.
with sales_with_return_flag as (select s.order_id,
                                       p.category,
                                       p.product_name,
                                       p.product_id,
                                       s.quantity,
                                       case
                                           when r.order_id is null then null
                                           else 1 end as is_returned
                                from sales s
                                         left join
                                         (select distinct order_id from returns) r
                                         on s.order_id = r.order_id
                                         join products p on p.product_id = s.product_id)
   , return_rate_per_product as (select product_id,
                                        product_name,
                                        category,
                                        (sum(is_returned*quantity) * 100.0 / sum(quantity)) as return_rate,
                                        sum(quantity),
                                        sum(is_returned*quantity)
                                 from sales_with_return_flag
                                 group by product_id, product_name, category)

   , return_rate_per_product_with_rank as (select *,
                                                  rank() over (partition by category order by return_rate desc) as return_rate_rank
                                           from return_rate_per_product)
select *
from return_rate_per_product_with_rank
where return_rate_rank <= 3;

#(10) Which 5 customers have contributed the most to total profit, and what is their
#tenure with the company?

with profit_for_each_customer as
    (select s.customer_id,
            round(sum(s.total_amount - (p.cost_price * s.quantity)), 2) as profit_per_customer
     from sales s
              left join products p
                        on s.product_id = p.product_id
              join stores st
                   on st.store_id = s.store_id
     GROUP BY s.customer_id)

   , pfec_with_rank as (select pfec.*,
                               c.first_name,
                               c.last_name,
                               c.signup_date,
                               DATEDIFF(curdate(), c.signup_date) as           user_tenure,
                               rank() over (order by profit_per_customer desc) cus_rank
                        from profit_for_each_customer pfec
                                 join customers c on pfec.customer_id = c.customer_id)

select customer_id, first_name, last_name, profit_per_customer, user_tenure
from pfec_with_rank
where cus_rank <= 10;

-- version 2
select customer_id, first_name, last_name, profit_per_customer, user_tenure
from (select profit_for_each_customer.*,
             c.first_name,
             c.last_name,
             c.signup_date,
             DATEDIFF(curdate(), c.signup_date) as           user_tenure,
             rank() over (order by profit_per_customer desc) cus_rank
      from
          (select s.customer_id,
                   round(sum(s.total_amount - (p.cost_price * s.quantity)), 2) as profit_per_customer
            from sales s
                     left join products p
                               on s.product_id = p.product_id
                     join stores st
                          on st.store_id = s.store_id
            GROUP BY s.customer_id) profit_for_each_customer
               join customers c on profit_for_each_customer.customer_id = c.customer_id) pfec_with_rank
where cus_rank <= 5;





