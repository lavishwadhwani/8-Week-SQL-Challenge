# Case Study #2 - Pizza Runner

## Solution - A. Pizza Metrics

### 1. How many pizzas were ordered?

````sql
SELECT COUNT(*) AS pizza_order_count
FROM customer_orders1;
````

**Answer:**

![pizcount](https://user-images.githubusercontent.com/107829400/225384581-38cd17c2-bea1-4a6c-bfb1-c9632db5396d.png)

- Total of 14 pizzas were ordered.

### 2. How many unique customer orders were made?

````sql
SELECT 
  COUNT(DISTINCT order_id) AS unique_order_count
FROM customer_orders1;
````

**Answer:**

![Screenshot 2023-03-15 223113](https://user-images.githubusercontent.com/107829400/225385243-643be5b7-7f38-472e-8248-486299ae89b6.png)

- There are 10 unique customer orders.

### 3. How many successful orders were delivered by each runner?

````sql
SELECT 
  runner_id, 
  COUNT(order_id) AS successful_orders
FROM runner_orders1
WHERE distance != 0
GROUP BY runner_id;
````

**Answer:**

![6](https://user-images.githubusercontent.com/107829400/225385689-74208363-734c-4e67-b1cf-3912edae77af.png)


- Runner 1 has 4 successful delivered orders.
- Runner 2 has 3 successful delivered orders.
- Runner 3 has 1 successful delivered order.

### 4. How many of each type of pizza was delivered?

````sql
select pizza_name, count(customer_orders1.pizza_id) as del_pizza_count from customer_orders1
join runner_orders1 on customer_orders1.order_id = runner_orders1.order_id
join pizza_names on customer_orders1.pizza_id = pizza_names.pizza_id
where runner_orders1.distance != 0
group by pizza_name;
````

**Answer:**

![7](https://user-images.githubusercontent.com/107829400/225386101-ba3ad238-8a11-41fd-bdc5-239c0eec6eb0.png)


- There are 9 delivered Meatlovers pizzas and 3 Vegetarian pizzas.

### 5. How many Vegetarian and Meatlovers were ordered by each customer?**

````sql
select c.customer_id,pizza_name, count(c.pizza_id) as pizza_count from customer_orders1 c
join pizza_names p on c.pizza_id = p.pizza_id
group by customer_id, pizza_name
order by customer_id;
````

**Answer:**

![8](https://user-images.githubusercontent.com/107829400/225386796-42821209-f2c8-4e21-ab6c-2f92826cccae.png)


- Customer 101 ordered 2 Meatlovers pizzas and 1 Vegetarian pizza.
- Customer 102 ordered 2 Meatlovers pizzas and 1 Vegetarian pizzas.
- Customer 103 ordered 3 Meatlovers pizzas and 1 Vegetarian pizza.
- Customer 104 ordered 3 Meatlovers pizza.
- Customer 105 ordered 1 Vegetarian pizza.

### 6. What was the maximum number of pizzas delivered in a single order?

````sql
select c.order_id, count(c.order_id) AS ORDER_COUNT from customer_orders1 c
join runner_orders1 r on c.order_id = r.order_id
where distance != 0
group by c.order_id
order by count(c.order_id) desc;
````

**Answer:**

![9](https://user-images.githubusercontent.com/107829400/225388110-15ed4eaf-9cd2-4468-8077-0a404da6fd8b.png)

- Maximum number of pizza delivered in a single order is 3 pizzas.

### 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

````sql
select c.customer_id,
sum(CASE WHEN exclusions != 0 OR extras != 0 THEN 1
ELSE 0
END) AS atleast1change,
SUM(CASE WHEN exclusions IS NULL AND extras IS NULL THEN 1 
ELSE 0
END) AS nochange
from customer_orders1 c
join runner_orders1 r on c.order_id = r.order_id
where r.distance != 0
group by c.customer_id
order by c.customer_id; 
````

**Answer:**

![11](https://user-images.githubusercontent.com/107829400/225388493-20780e69-d4a9-43bc-8ad9-248ddc054f25.png) 

- Customer 101 and 102 had no changes.
- Customer 103, 104 and 105 had requested at least 1 change on their pizza.

### 8. How many pizzas were delivered that had both exclusions and extras?

````sql
select count(c.order_id) as pizz_count_w from customer_orders1 c 
JOIN runner_orders1 r ON c.order_id = r.order_id
where r.distance != 0 AND c.exclusions != 0 AND c.extras != 0;
````

**Answer:**

![12](https://user-images.githubusercontent.com/107829400/225389325-522445ad-23d2-4c76-9748-f33f83c359aa.png)

- Only 1 pizza delivered that had both extra and exclusion topping.

### 9. What was the total volume of pizzas ordered for each hour of the day?

````sql
select HOUR(order_time) as hour_day, count(order_id) as order_count from customer_orders1
group by hour(order_time)
order by count(order_id) desc;
````

**Answer:**

![13](https://user-images.githubusercontent.com/107829400/225389777-fe0bf916-9207-4e39-a76c-e1d8ee326ff5.png)

### 10. What was the volume of orders for each day of the week?

````sql
select dayname(order_time) as day_of_week, count(order_id) as order_count from customer_orders1
group by dayname(order_time)
order by count(order_id) desc;
````

**Answer:**

![14](https://user-images.githubusercontent.com/107829400/225390238-7507484a-2364-4dfa-b83a-dccfe26e7b77.png)

***Click [here](https://github.com/lavishwadhwani/8-Week-SQL-Challenge/blob/04e7c35e69c90035e32aa482a3a14c326935267a/Case%20Study%20%232%20-%20Pizza%20Runner/B.%20Runner%20and%20Customer%20Experience.md) for solution for B. Runner and Customer Experience!***
