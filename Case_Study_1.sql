/* --------------------
   Case Study Questions
   --------------------*/
   
-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
-- not just sushi - how many points do customer A and B have at the end of January?

-- Notes: I attach the schema on the bottome in case you want to see the database. You can also see the schema on Danny Ma website.

-- 1. What is the total amount each customer spent at the restaurant?

SELECT customer_id, 
	SUM(price) total_revenue
FROM dannys_diner.sales a
LEFT JOIN dannys_diner.menu b ON a.product_id=b.product_id
GROUP BY 1
ORDER BY 1 ASC;

| customer_id | total_revenue |
| ----------- | ------------- |
| A	      | 76            |
| B	      | 74            |
| C	      | 36            |


-- 2. How many days has each customer visited the restaurant?

SELECT customer_id,
	COUNT(DISTINCT order_date) days_visited 
FROM dannys_diner.sales
GROUP BY 1
ORDER BY 1 ASC;

| customer_id | days_visited |
| ----------- | ------------ |
| A	      | 4	     |
| B	      | 6	     |
| C	      | 2	     |


-- 3. What was the first item from the menu purchased by each customer?

SELECT customer_id,
	product_id
FROM 
(
  SELECT DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_date) rank,
  	 customer_id,
  	 product_id
  FROM dannys_diner.sales
) ranked
WHERE rank = 1

| customer_id | product_id |
| ----------- | ---------- |
| A	      | 1          |
| A	      | 2          |
| B	      | 2          |
| C	      | 3          |
| C	      | 3          |


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

WITH prod_rank as
(
  SELECT DENSE_RANK() OVER(ORDER BY COUNT(product_id) DESC) rank,
         product_id,
  	 COUNT(product_id)
  FROM dannys_diner.sales
  GROUP BY 2
  ORDER BY 2 DESC 
)

SELECT a.product_id most_purchased_item,
	b.customer_id,
        COUNT(b.product_id) item_sold
FROM prod_rank a
INNER JOIN dannys_diner.sales b ON a.product_id=b.product_id AND rank = 1
GROUP BY 1, 2;

| most_purchased_item | customer_id | item_sold |
| ------------------- | ----------- | --------- |
| 3	              | A	    | 3		|
| 3	              | B	    | 2		|
| 3	              | C	    | 3		|


-- 5. Which item was the most popular for each customer?

WITH item_sold_per_cust as
(
  SELECT DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(product_id) DESC) rank,
  	 customer_id,
         product_id,
  	 COUNT(product_id) item_sold
  FROM dannys_diner.sales
  GROUP BY 2, 3
  ORDER BY 1, 2, 3 
)
  	
SELECT customer_id,
	product_id,
	item_sold
FROM item_sold_per_cust
WHERE rank = 1;

| customer_id | product_id | item_sold |
| ----------- | ---------- | --------- |
A	      | 3	   | 3	       |
B	      | 1	   | 2	       |
B	      | 2	   | 2	       |
B	      | 3	   | 2	       |
C	      | 3	   | 3	       |


-- 6. Which item was purchased first by the customer after they became a member?

WITH order_date_rank as
(
  SELECT DENSE_RANK() OVER(PARTITION BY a.customer_id ORDER BY (b.order_date-a.join_date)) rank,
  	b.customer_id,
        b.product_id,
  	(b.order_date-a.join_date) date_diff
  FROM dannys_diner.members a
  INNER JOIN dannys_diner.sales b 
  ON a.customer_id=b.customer_id AND b.order_date >= a.join_date
  ORDER BY 2, 4
)

SELECT a.customer_id,
	a.product_id,
        b.product_name
FROM order_date_rank a
INNER JOIN dannys_diner.menu b ON a.product_id=b.product_id
WHERE a.rank = 1
ORDER BY 1;

| customer_id | product_id | product_name |
| ----------- | ---------- | ------------ |
| A	      | 2	   | curry	  |
| B	      | 1	   | sushi	  |


-- 7. Which item was purchased just before the customer became a member?

WITH order_date_rank as
(
  SELECT DENSE_RANK() OVER(PARTITION BY a.customer_id ORDER BY (a.join_date-b.order_date)) rank,
  	b.customer_id,
        b.product_id,
  	(b.order_date-a.join_date) date_diff
  FROM dannys_diner.members a
  INNER JOIN dannys_diner.sales b 
  ON a.customer_id=b.customer_id AND b.order_date < a.join_date
  ORDER BY 2, 4
)

SELECT a.customer_id,
	a.product_id,
        b.product_name
FROM order_date_rank a
INNER JOIN dannys_diner.menu b ON a.product_id=b.product_id
WHERE a.rank = 1
ORDER BY 1;

| customer_id | product_id | product_name |
| ----------- | ---------- | ------------ |
| A	      | 1	   | sushi	  |
| A	      | 2	   | curry	  |
| B	      | 1	   | sushi	  |


-- 8. What is the total items and amount spent for each member before they became a member?

SELECT a.customer_id,
	COUNT(a.product_id) total_items,
	SUM(b.price) amount_spent
FROM dannys_diner.sales a
INNER JOIN dannys_diner.menu b ON a.product_id=b.product_id
INNER JOIN dannys_diner.members c ON a.customer_id=c.customer_id AND a.order_date < c.join_date
GROUP BY 1
ORDER BY 1;

| customer_id | total_items | amount_spent |
| ----------- | ----------- | ------------ |
| A	      | 2	    | 25	   |
| B	      | 3	    | 40	   |


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT a.customer_id,
	SUM(CASE
            	WHEN a.product_id = 1 THEN b.price*20
            	ELSE b.price*10 
            END) points
FROM dannys_diner.sales a
INNER JOIN dannys_diner.menu b ON a.product_id=b.product_id
GROUP BY 1
ORDER BY 1;

| customer_id | points	   |
| ----------- | ---------- |
| A	      | 860        | 
| B	      | 940        | 
| C	      | 360        | 

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
-- not just sushi - how many points do customer A and B have at the end of January?

SELECT a.customer_id,
  		SUM(CASE 
         		WHEN order_date BETWEEN join_date AND join_date+6 THEN c.price*20
  			WHEN order_date BETWEEN join_date+6 AND '2021-01-31' THEN c.price*10
  		    END) points
FROM dannys_diner.sales a
INNER JOIN dannys_diner.members b ON a.customer_id=b.customer_id AND order_date BETWEEN join_date AND '2021-01-31'
INNER JOIN dannys_diner.menu c ON a.product_id=c.product_id
GROUP BY 1;

| customer_id | points	   |
| ----------- | ---------- |
| B	      | 320	   |
| A	      | 1020	   |


-- BONUS QUESTION
-- #1 Join All The Things

SELECT a.customer_id,
	order_date,
        product_name,
        price,
        CASE
            WHEN order_date >= join_date THEN 'Y'
            WHEN order_date <= join_date THEN 'N'
            ELSE 'N'
        END AS member
FROM dannys_diner.sales a
INNER JOIN dannys_diner.menu b ON a.product_id=b.product_id
LEFT JOIN dannys_diner.members c ON a.customer_id=c.customer_id
ORDER BY 1, 2;

| customer_id | order_date               | product_name | price | member |
| ----------- | ------------------------ | ------------ | ----- | ------ |
| A	      | 2021-01-01T00:00:00.000Z | sushi 	| 10	| N	 |
| A	      | 2021-01-01T00:00:00.000Z | curry	| 15	| N	 |
| A	      | 2021-01-07T00:00:00.000Z | curry	| 15	| Y	 |
| A	      | 2021-01-10T00:00:00.000Z | ramen	| 12	| Y	 |
| A	      | 2021-01-11T00:00:00.000Z | ramen	| 12	| Y	 |
| A	      | 2021-01-11T00:00:00.000Z | ramen	| 12	| Y	 |
| B	      | 2021-01-01T00:00:00.000Z | curry	| 15	| N	 |
| B	      | 2021-01-02T00:00:00.000Z | curry	| 15	| N	 |
| B	      | 2021-01-04T00:00:00.000Z | sushi	| 10	| N	 |
| B	      | 2021-01-11T00:00:00.000Z | sushi	| 10	| Y	 |
| B	      | 2021-01-16T00:00:00.000Z | ramen	| 12	| Y	 |
| B	      | 2021-02-01T00:00:00.000Z | ramen	| 12	| Y	 |
| C	      | 2021-01-01T00:00:00.000Z | ramen	| 12	| N	 |
| C 	      | 2021-01-01T00:00:00.000Z | ramen	| 12	| N	 |
| C	      | 2021-01-07T00:00:00.000Z | ramen	| 12	| N	 |
 

-- #1 Rank All The Things

SELECT a.customer_id,
	order_date,
        product_name,
        price,
        CASE
            WHEN order_date >= join_date THEN 'Y'
            WHEN order_date <= join_date THEN 'N'
            ELSE 'N'
        END AS member,
        CASE 
	    WHEN order_date >= join_date THEN DENSE_RANK() OVER (PARTITION BY a.customer_id ORDER BY CASE WHEN order_date >= join_date THEN order_date END) 
	    ELSE null 
	END ranking
FROM dannys_diner.sales a
INNER JOIN dannys_diner.menu b ON a.product_id=b.product_id
LEFT JOIN dannys_diner.members c ON a.customer_id=c.customer_id
ORDER BY 1, 2;

| customer_id | order_date               | product_name | price | member | ranking |
| ----------- | ------------------------ | ------------ | ----- | ------ | ------- |
| A	      | 2021-01-01T00:00:00.000Z | sushi 	| 10	| N	 | null	   |
| A	      | 2021-01-01T00:00:00.000Z | curry	| 15	| N	 | null	   |
| A	      | 2021-01-07T00:00:00.000Z | curry	| 15	| Y	 | 1	   |
| A	      | 2021-01-10T00:00:00.000Z | ramen	| 12	| Y	 | 2	   |
| A	      | 2021-01-11T00:00:00.000Z | ramen	| 12	| Y	 | 3	   |
| A	      | 2021-01-11T00:00:00.000Z | ramen	| 12	| Y	 | 3	   |
| B	      | 2021-01-01T00:00:00.000Z | curry	| 15	| N	 | null	   |
| B	      | 2021-01-02T00:00:00.000Z | curry	| 15	| N	 | null	   |
| B	      | 2021-01-04T00:00:00.000Z | sushi	| 10	| N	 | null	   |
| B	      | 2021-01-11T00:00:00.000Z | sushi	| 10	| Y	 | 1	   |
| B	      | 2021-01-16T00:00:00.000Z | ramen	| 12	| Y	 | 2	   |
| B	      | 2021-02-01T00:00:00.000Z | ramen	| 12	| Y	 | 3	   |
| C	      | 2021-01-01T00:00:00.000Z | ramen	| 12	| N	 | null	   |
| C 	      | 2021-01-01T00:00:00.000Z | ramen	| 12	| N	 | null	   |
| C	      | 2021-01-07T00:00:00.000Z | ramen	| 12	| N	 | null	   |


-- Danny's Diner SCHEMA

CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
