/* --------------------------------------
   Case Study 2 Questions - Pizza Metrics
   -------------------------------------- */
   
-- 1. How many pizzas were ordered?
-- 2. How many unique customer orders were made?
-- 3. How many successful orders were delivered by each runner?
-- 4. How many of each type of pizza was delivered?
-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
-- 6. What was the maximum number of pizzas delivered in a single order?
-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
-- 8. How many pizzas were delivered that had both exclusions and extras?
-- 9. What was the total volume of pizzas ordered for each hour of the day?
-- 10. What was the volume of orders for each day of the week?

-- 1. How many pizzas were ordered?

select count(order_id) Num_of_Pizzas_Ordered
from pizza_runner.customer_orders

| Num_of_Pizzas_Ordered |
| --------------------- |
| 14                    |


-- 2. How many unique customer orders were made?

select count(distinct order_id) Unique_Orders
from pizza_runner.customer_orders

| unique_orders |
| ------------- |
| 10            |


-- 3. How many successful orders were delivered by each runner?

select runner_id, 
	count(order_id)
from pizza_runner.runner_orders
where cancellation is null
group by 1

| runner_id |	count |
| --------- | ----- |
| 1	        | 4     |
| 2	        | 3     |
| 3	        | 1     |


-- 4. How many of each type of pizza was delivered?

select pizza_id,
	count(*) Delivered_Pizzas
from pizza_runner.customer_orders a
left join pizza_runner.runner_orders b ON a.order_id = b.order_id
where cancellation is null
group by 1

pizza_id	delivered_pizzas
1	9
2	3


-- 5. How many Vegetarian and Meatlovers were ordered by each customer?

select customer_id,
	sum(case when pizza_id = 1 then 1 else 0 end) Vegetarian,
	sum(case when pizza_id = 2 then 1 else 0 end) Meatlovers
from pizza_runner.customer_orders
group by 1
order by 1


-- 6. What was the maximum number of pizzas delivered in a single order?

select Max(Delivered_Pizzas) as Max_Num_of_Delivered_Pizza
from 
(
  select count(order_id) Delivered_Pizzas
  from pizza_runner.customer_orders
  group by order_id
) Dlvrd_Pizza


-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

select customer_id,
	sum(case when exclusions is not null or extras is not null then 1 else 0 end) At_Least_1_Change,
	sum(case when exclusions is null and extras is null then 1 else 0 end) No_Changes
from pizza_runner.customer_orders a
left join pizza_runner.runner_orders b ON a.order_id = b.order_id
where cancellation is null
group by 1


-- 8. How many pizzas were delivered that had both exclusions and extras?

select sum(case when exclusions is not null and extras is not null then 1 else 0 end) Warped_Pizzas
from pizza_runner.customer_orders a
left join pizza_runner.runner_orders b ON a.order_id = b.order_id
where cancellation is null


-- 9. What was the total volume of pizzas ordered for each hour of the day?

select extract(hour from order_time) Hours,
	count(order_id) Num_of_Pizzas
from pizza_runner.customer_orders
group by 1
order by 1


-- 10. What was the volume of orders for each day of the week?

select to_Char(order_time, 'day') days,
	count(order_id) Num_of_Orders
from pizza_runner.customer_orders
group by 1
