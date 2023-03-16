# Case Study #2 - Pizza Runner

## Data Cleaning & Transformation

### Table: customer_orders

Looking at the `customer_orders` table below, we can see that
- In the `exclusions` column, there are missing/ blank spaces ' ' and null values. 
- In the `extras` column, there are missing/ blank spaces ' ' and null values.

![cs](https://user-images.githubusercontent.com/107829400/225321265-00191e74-d32b-4684-93ca-c5d342e0e041.png)

In order to clean the table:
- Create a temporary or new table with all the columns
- Remove null and blank values in `exlusions` and `extras` columns with NULL. Reason for making missing or incorrect values NULL is to make it easier for us to convert the column data type if we wish to do so in order to make calculations easier

````sql
CREATE TABLE customer_orders1 (
SELECT order_id, customer_id, pizza_id, 
CASE WHEN exclusions = 'null' OR exclusions = '' THEN NULL
ELSE exclusions
END AS exclusions,
CASE WHEN extras = 'null' OR extras = '' THEN NULL
ELSE extras
END AS extras,
order_time from customer_orders);
`````

This is how the clean `customers_orders1` table looks like and we will use this table to run all our queries.

![2](https://user-images.githubusercontent.com/107829400/225323887-a0c7e47b-2df7-4b20-8684-729d861719e6.png)

***

### Table: runner_orders

Looking at the `runner_orders` table below, we can see that there are
- In the `distance`, `pickup time` and `duration` columns, there are values which says 'null' indicating NULL. 
- In the `cancellation` column, there are missing/ blank spaces ' ' and null values

![3](https://user-images.githubusercontent.com/107829400/225377895-335fa282-8ffb-45ac-9829-35e657d21743.png)

Our course of action to clean the table:
- In `pickup_time` column, remove 'nulls' and replace with NULL.
- In `distance` column, remove "km" and nulls and replace with NULL.
- In `duration` column, remove "minutes", "minute" and nulls and replace with NULL.
- In `cancellation` column, remove null and replace with NULL.

````sql
CREATE TABLE runner_orders1 (
SELECT order_id, runner_id,
CASE WHEN pickup_time = 'null' THEN null
ELSE pickup_time
END AS pickup_time,
CASE WHEN distance = 'null' THEN null
WHEN distance LIKE '%km' THEN TRIM('km' from distance)
ELSE distance
END AS distance,
CASE WHEN duration = 'null' THEN null
WHEN duration LIKE '%minutes' THEN TRIM('minutes' from duration)
WHEN duration LIKE '%mins' THEN TRIM('mins' from duration)
WHEN duration LIKE '%minute' THEN TRIM('minute' from duration)
ELSE duration
END AS duration,
CASE WHEN cancellation = 'null' OR cancellation = '' THEN null
ELSE cancellation
END AS cancellation from runner_orders);
````

Then, we alter the `pickup_time`, `distance` and `duration` columns to the correct data type.

````sql
ALTER TABLE runner_orders1 MODIFY pickup_time DATETIME, MODIFY COLUMN distance FLOAT, MODIFY COLUMN duration INT;
````

This is how the clean `runner_orders1` table looks like and we will use this table to run all our queries.

![4](https://user-images.githubusercontent.com/107829400/225379421-35d61c29-fa35-4d7d-9bc1-983a148afab4.png)

***

Click here for [solution](https://github.com/lavishwadhwani/8-Week-SQL-Challenge/blob/fb7dc00764a148cb7a057636ce77d3be9b5869d1/Case%20Study%20%232%20-%20Pizza%20Runner/A.%20Pizza%20Metrics.md) to **A. Pizza Metrics**!
