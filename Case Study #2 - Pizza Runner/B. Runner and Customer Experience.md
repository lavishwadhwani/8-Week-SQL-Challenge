# Case Study #2 Pizza Runner

## Solution - B. Runner and Customer Experience

### 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

````sql
SELECT WEEK(registration_date) AS week_no, COUNT(runner_id) as runners_signed from runners
GROUP BY week_no;
````

**Answer:**

![21](https://user-images.githubusercontent.com/107829400/225392961-713f8ae4-517b-4f96-99c9-88cf32a4d004.png)


### 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
avg time from home to hq to pickup order = arrival time - departure time  |   
arrival time = pickup time and departure time = order time

````sql
SELECT runner_id, AVG(TIMESTAMPDIFF(MINUTE, order_time, pickup_time)) AS AVGPICKUPTIME from customer_orders1 c 
JOIN runner_orders1 r ON c.order_id = r.order_id
GROUP BY runner_id;
````

**Answer:**

![22](https://user-images.githubusercontent.com/107829400/225394355-ea426b98-bc20-4ca3-9936-b05a12b8d783.png)

### 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
prep time = order time - pickup time

````sql
WITH prep_time_cte AS
(
  SELECT 
    c.order_id, 
    COUNT(c.order_id) AS pizza_order, 
    c.order_time, 
    r.pickup_time, 
    DATEDIFF(MINUTE, c.order_time, r.pickup_time) AS prep_time_minutes
  FROM customer_orders1 AS c
  JOIN runner_orders1 AS r
    ON c.order_id = r.order_id
  WHERE r.distance != 0
  GROUP BY c.order_id, c.order_time, r.pickup_time
)
SELECT 
  pizza_order, 
  AVG(prep_time_minutes) AS avg_prep_time_minutes
FROM prep_time_cte
WHERE prep_time_minutes > 1
GROUP BY pizza_order;
````

**Answer:**

![24](https://user-images.githubusercontent.com/107829400/225395834-ecd1de17-6ca6-43dd-a6dd-3cd59be35000.png)


### 4. What was the average distance travelled for each customer?

````sql
SELECT 
  c.customer_id, 
  AVG(r.distance) AS avg_distance
FROM customer_orders1 AS c
JOIN runner_orders1 AS r
  ON c.order_id = r.order_id
WHERE r.duration != 0
GROUP BY c.customer_id;
````

**Answer:**

![31](https://user-images.githubusercontent.com/107829400/225396849-f4589c79-3f7d-4096-a8c3-1500f9c56b99.png)


### 5. What was the difference between the longest and shortest delivery times for all orders?
max(delivery_time) - min(delivery_time)

````sql
SELECT MAX(duration) - MIN(duration) from runner_orders1;
````

![41](https://user-images.githubusercontent.com/107829400/225398089-a35236e8-0c8b-401a-85d9-e9cd0f987e91.png)

### 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

```sql
SELECT 
	runner_id,
	distance,
	duration,
	ROUND(distance/ duration * 60, 2) AS speed_km_hr
FROM runner_orders1
WHERE cancellation is null
ORDER BY 
	runner_id,
	speed_km_hr
;
```

![42](https://user-images.githubusercontent.com/107829400/225398749-5dcc2831-4fe0-4e83-ae87-5c9201b337be.png)


### 7. What is the successful delivery percentage for each runner?
```sql
SELECT 
	runner_id,	
	count(order_id) as total_orders,
	count(pickup_time) as total_orders_delivered,
	cast(count(pickup_time) as float) / cast(count(order_id) as float) * 100 
		as successful_delivery_percent
FROM runner_orders1
GROUP BY runner_id;
```

![51](https://user-images.githubusercontent.com/107829400/225399940-3b402c49-d2c8-4a39-947d-329eb4bc5eab.png)

***Click [here](https://github.com/lavishwadhwani/8-Week-SQL-Challenge/blob/ded677db9d6f9f89425704f6f3613e70d36bcfb4/Case%20Study%20%232%20-%20Pizza%20Runner/C.%20Ingredient%20Optimisation.md) for solution for C. Ingredients Optimisation***
