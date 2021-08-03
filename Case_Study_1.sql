/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?

SELECT customer_id, 
		SUM(price) total_revenue
FROM dannys_diner.sales a
LEFT JOIN dannys_diner.menu b ON a.product_id=b.product_id
GROUP BY 1
ORDER BY 1 ASC;


-- 2. How many days has each customer visited the restaurant?

SELECT customer_id,
		COUNT(DISTINCT order_date) days_visited 
FROM dannys_diner.sales
GROUP BY 1
ORDER BY 1 ASC;


-- 3. What was the first item from the menu purchased by each customer?

SELECT product_id,
		COUNT(product_id) max_num_purchased
FROM dannys_diner.sales
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;


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


-- 8. What is the total items and amount spent for each member before they became a member?

SELECT a.customer_id,
		COUNT(a.product_id) total_items,
		SUM(b.price) amount_spent
FROM dannys_diner.sales a
INNER JOIN dannys_diner.menu b ON a.product_id=b.product_id
INNER JOIN dannys_diner.members c ON a.customer_id=c.customer_id AND a.order_date < c.join_date
GROUP BY 1
ORDER BY 1;


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

10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT a.customer_id,
  		SUM(CASE 
         		WHEN order_date BETWEEN join_date AND join_date+6 THEN c.price*20
  				WHEN order_date BETWEEN join_date+6 AND '2021-01-31' THEN c.price*10
  			END) points
FROM dannys_diner.sales a
INNER JOIN dannys_diner.members b ON a.customer_id=b.customer_id AND order_date BETWEEN join_date AND '2021-01-31'
INNER JOIN dannys_diner.menu c ON a.product_id=c.product_id
GROUP BY 1;


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
        CASE WHEN order_date >= join_date THEN DENSE_RANK() OVER (PARTITION BY a.customer_id ORDER BY CASE WHEN order_date >= join_date THEN order_date END) ELSE null END ranking
FROM dannys_diner.sales a
INNER JOIN dannys_diner.menu b ON a.product_id=b.product_id
LEFT JOIN dannys_diner.members c ON a.customer_id=c.customer_id
ORDER BY 1, 2;
