  
  /* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
SELECT S.customer_id, SUM(M.price)
from sales S
JOIN menu M
ON S.product_id = M.product_id
GROUP BY S.customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) AS days_visited
FROM sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
SELECT customer_id, product_name
FROM (
SELECT customer_id, product_name, 
DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_date) AS first_order FROM sales JOIN menu ON sales.product_id = menu.product_id)a
WHERE first_order = 1
GROUP BY customer_id, product_name;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT M.product_name, COUNT(S.product_id) AS times_purchased
FROM sales S
JOIN menu M
ON S.product_id = M.product_id
GROUP BY product_name
ORDER BY S.product_id DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?
WITH cte AS (SELECT customer_id, product_id,
COUNT(product_id) AS total_product FROM sales GROUP BY customer_id, product_id)

SELECT customer_id, product_id, total_product FROM (
	SELECT customer_id, product_id, total_product,
	RANK() OVER(PARTITION BY customer_id ORDER BY total_product DESC) AS first_order FROM cte) a
WHERE first_order = 1;

-- 6. Which item was purchased first by the customer after they became a member?
SELECT S.customer_id, product_name
FROM sales S
JOIN menu M ON S.product_id = M.product_id
JOIN members ME ON S.customer_id = ME.customer_id
WHERE order_date > join_date
GROUP BY customer_id;

-- 7. Which item was purchased just before the customer became a member?
SELECT customer_id, order_date, product_name FROM (
	SELECT s.customer_id, s.order_date, s.product_id, m.product_name, mem.join_date,
    DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY s.order_date DESC) ranking FROM sales s
    INNER JOIN members mem on s.customer_id = mem.customer_id
    AND s.order_date < mem.join_date
    INNER JOIN menu m ON s.product_id = m.product_id)x
    where ranking = 1;
    
-- 8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, COUNT(m.price) Quantity, SUM(m.price) Total_Amount FROM sales s
INNER JOIN menu m on s.product_id = m.product_id
INNER JOIN members mem on s.customer_id = mem.customer_id
and s.order_date < mem.join_date
group by s.customer_id
order by Total_Amount;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT customer_id, SUM(points) AS Total_Points FROM 
(
SELECT s.customer_id, m.product_name, m.price, 
CASE
WHEN m.product_name = 'sushi' THEN price*10*2 else price *10
END AS points
	FROM sales s INNER JOIN menu m ON s.product_id = m.product_id)x
GROUP BY customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH cte_member_points AS
	(SELECT M.CUSTOMER_ID AS CUSTOMER,
			SUM(CASE
					WHEN s.order_date < m.join_date THEN
						CASE
							WHEN M2.PRODUCT_NAME = 'sushi' THEN (M2.PRICE * 20)
							ELSE (M2.PRICE * 10)
						END
					WHEN S.ORDER_DATE > (m.join_date + 6) THEN 
						CASE
							WHEN M2.PRODUCT_NAME = 'sushi' THEN (M2.PRICE * 20)
							ELSE (M2.PRICE * 10)
						END 
					ELSE (M2.PRICE * 20)	
				END) AS MEMBER_POINTS
		FROM MEMBERS AS M
		JOIN SALES AS S ON S.CUSTOMER_ID = M.CUSTOMER_ID
		JOIN MENU AS M2 ON S.PRODUCT_ID = M2.PRODUCT_ID
		WHERE S.ORDER_DATE <= '2021-01-31'
		GROUP BY CUSTOMER)
SELECT *
FROM cte_member_points
ORDER BY customer;