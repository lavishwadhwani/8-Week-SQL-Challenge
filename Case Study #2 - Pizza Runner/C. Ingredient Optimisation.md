### C. Ingredient Optimisation

#### 1. What are the standard ingredients for each pizza?

````sql
SELECT
  n.pizza_name,
  GROUP_CONCAT(t.topping_name SEPARATOR ', ') AS toppings
FROM
  pizza_runner.pizza_toppings AS t
  JOIN pizza_runner.pizza_recipes AS r ON t.topping_id = r.topping_id
  JOIN pizza_runner.pizza_names AS n ON r.pizza_id = n.pizza_id
WHERE
  t.topping_id IN (
    SELECT CAST(col AS UNSIGNED)
    FROM UNNEST(SPLIT_STRING(r.toppings, ',')) AS col
  )
GROUP BY
  n.pizza_name
ORDER BY
  n.pizza_name;

````
#### 2. What was the most commonly added extra?

````sql
WITH extras_table AS (
  SELECT
    order_id,
    CAST(JSON_EXTRACT(extras, '$[*]') AS UNSIGNED) AS topping_id
  FROM
    pizza_runner.customer_orders AS c
  WHERE
    extras IS NOT NULL
)
SELECT
  topping_name AS extra_ingredient,
  COUNT(topping_name) AS number_of_pizzas
FROM
  extras_table AS et
  JOIN pizza_runner.pizza_toppings AS t ON et.topping_id = t.topping_id
GROUP BY
  topping_name
HAVING
  COUNT(topping_name) = (
    SELECT
      COUNT(topping_name)
    FROM
      extras_table AS et2
      JOIN pizza_runner.pizza_toppings AS t2 ON et2.topping_id = t2.topping_id
    WHERE
      t2.topping_name = topping_name
    GROUP BY
      t2.topping_name
    ORDER BY
      COUNT(topping_name) DESC
    LIMIT
      1
  )

````

***The most poplular extra ingredient is bacon.***

#### 3. What was the most common exclusion?

````sql
SELECT
  excluded_ingredient,
  number_of_pizzas
FROM
  (
    SELECT
      topping_name AS excluded_ingredient,
      COUNT(topping_name) AS number_of_pizzas,
      RANK() OVER (
        ORDER BY
          COUNT(topping_name) DESC
      ) AS rank
    FROM
      pizza_runner.customer_orders AS c
      JOIN (
        SELECT
          *
        FROM
          pizza_runner.pizza_toppings
      ) AS t ON t.topping_id = ANY(STRING_TO_ARRAY(c.exclusions, ',')::int[])
    WHERE
      c.exclusions IS NOT NULL
    GROUP BY
      topping_name
  ) t
WHERE
  rank = 1;

````

***The most common exclusion is cheese.***

#### 4. Generate an order item for each record in the `customers_orders` table in the format of one of the following:

- Meat Lovers

- Meat Lovers - Exclude Beef

- Meat Lovers - Extra Bacon

- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

````sql
SELECT
  order_id,
  CONCAT(
    pizza_name,
    ' ',
    IF(COUNT(exclusions) > 0, '- Exclude ', ''),
    GROUP_CONCAT(exclusions SEPARATOR ', '),
    IF(COUNT(extras) > 0, ' - Extra ', ''),
    GROUP_CONCAT(extras SEPARATOR ', ')
  ) AS pizza_name_exclusions_and_extras
FROM
  (
    SELECT
      ra.order_id,
      pizza_name,
      CASE
        WHEN exclusions != 'null' AND topping_id IN (
          SELECT
            UNNEST(STRING_TO_ARRAY(exclusions, ',') :: INT[])
        ) THEN topping_name
      END AS exclusions,
      CASE
        WHEN extras != 'null' AND topping_id IN (
          SELECT
            UNNEST(STRING_TO_ARRAY(extras, ',') :: INT[])
        ) THEN topping_name
      END AS extras
    FROM
      pizza_runner.customer_orders AS c
      JOIN pizza_runner.pizza_names AS n ON c.pizza_id = n.pizza_id
      JOIN pizza_runner.pizza_toppings AS t ON n.pizza_id = t.pizza_id
      JOIN (
        SELECT
          order_id,
          ROW_NUMBER() OVER () AS rank
        FROM
          pizza_runner.customer_orders
      ) AS ra ON c.order_id = ra.order_id
    WHERE
      exclusions != 'null' OR extras != 'null'
    GROUP BY
      ra.order_id,
      pizza_name,
      exclusions,
      extras,
      topping_id,
      topping_name
  ) AS toppings_as_names
GROUP BY
  pizza_name,
  order_id
ORDER BY
  order_id

````


#### 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the `customer_orders` table and add a 2x in front of any relevant ingredients

For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

````sql
SELECT 
  order_id,
  CONCAT(
    pizza_name,
    ': ',
    GROUP_CONCAT(
      topping_name
      ORDER BY
        topping_name
      SEPARATOR ', '
    )
  ) AS all_ingredients
FROM (
  SELECT
    rank,
    order_id,
    pizza_name,
    CONCAT(
      CASE
        WHEN (SUM(count_toppings) + SUM(count_extra)) > 1 THEN CONCAT((SUM(count_toppings) + SUM(count_extra)), 'x')
      END,
      topping_name
    ) AS topping_name
  FROM (
    SELECT
      rank,
      ra.order_id,
      pizza_name,
      topping_name,
      CASE
        WHEN exclusions != 'null' AND t.topping_id IN (SELECT UNNEST(STRING_TO_ARRAY(exclusions, ',') :: int []))
          THEN 0
        ELSE 
          CASE
            WHEN t.topping_id IN (SELECT UNNEST(STRING_TO_ARRAY(r.toppings, ',') :: int [])) THEN COUNT(topping_name)
            ELSE 0
          END
      END AS count_toppings,
      CASE
        WHEN extras != 'null' AND t.topping_id IN (SELECT UNNEST(STRING_TO_ARRAY(extras, ',') :: int [])) THEN COUNT(topping_name)
        ELSE 0
      END AS count_extra
    FROM
      pizza_runner.pizza_toppings AS t
      JOIN pizza_runner.pizza_recipes AS r ON t.topping_id = ANY (STRING_TO_ARRAY(r.toppings, ',') :: int [])
      JOIN pizza_runner.pizza_names AS n ON r.pizza_id = n.pizza_id
      JOIN pizza_runner.customer_orders AS c ON n.pizza_id = c.pizza_id
      JOIN (SELECT *, ROW_NUMBER() OVER () AS rank FROM pizza_runner.customer_orders) AS ra ON c.order_id = ra.order_id
    WHERE
      exclusions != 'null' OR extras != 'null'
    GROUP BY
      rank,
      ra.order_id,
      pizza_name,
      topping_name,
      exclusions,
      extras,
      t.topping_id
  ) AS toppings
  WHERE count_toppings > 0 OR count_extra > 0
  GROUP BY
    rank,
    order_id,
    pizza_name,
    topping_name
) AS ingredients
GROUP BY
  order_id,
  pizza_name,
  rank
ORDER BY
  rank;

````

#### 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

````sql
SELECT
  topping_name,
  (SUM(topping_count) + SUM(extras_count)) AS total_ingredients
FROM
  (
    SELECT
      topping_name,
      CASE
        WHEN extras != 'null'
        AND topping_id IN (
          SELECT
            unnest(string_to_array(extras, ',') :: int [])
        ) THEN count(topping_name)
        ELSE 0 END AS extras_count,
      CASE
        WHEN exclusions != 'null'
        AND topping_id IN (
          SELECT
            unnest(string_to_array(exclusions, ',') :: int [])
        ) THEN NULL
        ELSE CASE
          WHEN topping_id IN (
            SELECT
              UNNEST(STRING_TO_ARRAY(toppings, ',') :: int [])
          ) THEN COUNT(topping_name)
        END
      END AS topping_count
    FROM
      pizza_runner.pizza_toppings AS t
      JOIN pizza_runner.pizza_recipes AS r ON t.pizza_id = r.pizza_id
      JOIN pizza_runner.runner_orders AS ro ON ro.order_id = r.order_id
    WHERE
      ra.pickup_time != 'null'
      AND ra.distance != 'null'
      AND ra.duration != 'null'
    GROUP BY
      topping_name,
      exclusions,
      extras,
      toppings,
      topping_id
  ) AS topping_count
GROUP BY
  topping_name
ORDER BY
  total_ingredients DESC

````


### D. Pricing and Ratings

#### 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?


````sql
WITH profit AS (
    SELECT
        pizza_name,
        CASE
            WHEN pizza_name = 'Meatlovers' THEN COUNT(pizza_name) * 12
            ELSE COUNT(pizza_name) * 10
        END AS profit
    FROM
        pizza_runner.customer_orders AS c
        JOIN pizza_runner.pizza_names AS n ON c.pizza_id = n.pizza_id
        JOIN pizza_runner.runner_orders AS r ON c.order_id = r.order_id
    WHERE
        pickup_time != 'null'
        AND distance != 'null'
        AND duration != 'null'
    GROUP BY
        pizza_name
)
SELECT SUM(profit) AS profit_in_dollars
FROM profit;

````


***The total profit is $138***

#### 2. What if there was an additional $1 charge for any pizza extras?

#### - Add cheese is $1 extra

````sql
WITH profit AS (
  SELECT
    pizza_name,
    CASE
      WHEN pizza_name = 'Meatlovers' THEN COUNT(pizza_name) * 12
      ELSE COUNT(pizza_name) * 10
    END AS profit
  FROM
    pizza_runner.customer_orders AS c
    JOIN pizza_runner.pizza_names AS n ON c.pizza_id = n.pizza_id
    JOIN pizza_runner.runner_orders AS r ON c.order_id = r.order_id
  WHERE
    pickup_time != 'null'
    AND distance != 'null'
    AND duration != 'null'
  GROUP BY
    1
),
extras AS (
  SELECT
    COUNT(topping_id) AS extras
  FROM
    (
      SELECT
        UNNEST(STRING_TO_ARRAY(extras, ',') :: int []) AS topping_id
      FROM
        pizza_runner.customer_orders AS c
        JOIN pizza_runner.runner_orders AS r ON c.order_id = r.order_id
      WHERE
        pickup_time != 'null'
        AND distance != 'null'
        AND duration != 'null'
        AND extras != 'null'
    ) e
)
SELECT
  SUM(profit.profit) + extras.extras AS profit_in_dollars
FROM
  profit,
  extras

````


***The total profit with extras is $142***

#### 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

````sql
SET
  search_path = pizza_runner;
DROP TABLE IF EXISTS runner_rating;
CREATE TABLE runner_rating (
    "id" SERIAL PRIMARY KEY,
    "order_id" INTEGER,
    "customer_id" INTEGER,
    "runner_id" INTEGER,
    "rating" INTEGER,
    "rating_time" TIMESTAMP
  );
INSERT INTO
  runner_rating (
    "order_id",
    "customer_id",
    "runner_id",
    "rating",
    "rating_time"
  )
VALUES
  ('1', '101', '1', '5', '2020-01-01 19:34:51'),
  ('2', '101', '1', '5', '2020-01-01 20:23:03'),
  ('3', '102', '1', '4', '2020-01-03 10:12:58'),
  ('4', '103', '2', '5', '2020-01-04 16:47:06'),
  ('5', '104', '3', '5', '2020-01-08 23:09:27'),
  ('7', '105', '2', '4', '2020-01-08 23:50:12'),
  ('8', '102', '2', '4', '2020-01-10 12:30:45'),
  ('10', '104', '1', '5', '2020-01-11 20:05:35');
````

#### 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?

- `customer_id`
- `order_id`
- `runner_id`
- `rating`
- `order_time`
- `pickup_time`
- Time between order and pickup
- Delivery duration
- Average speed
- Total number of pizzas

````sql
SELECT
  co.customer_id,
  ro.order_id,
  ro.runner_id,
  rating,
  TO_CHAR(order_time, 'YYYY-MM-DD HH24:MI:SS') AS order_time,
  pickup_time,
  ROUND(
    DATE_PART(
      'minute',
      TO_TIMESTAMP(pickup_time, 'YYYY-MM-DD HH24:MI:SS') - co.order_time
    )
  ) AS time_between_order_and_pickup,
  TO_NUMBER(duration, '99') AS delivery_time_in_minutes,
  ROUND(
    AVG(
      TO_NUMBER(distance, '99D9') /(TO_NUMBER(duration, '99') / 60)
    )
  ) AS average_speed,
  COUNT(ro.order_id) AS number_of_pizzas
FROM
  pizza_runner.runner_orders as ro
  JOIN pizza_runner.runner_rating as rr on ro.order_id = rr.order_id
  JOIN pizza_runner.customer_orders as co on ro.order_id = co.order_id
GROUP BY
  co.customer_id,
  ro.order_id,
  ro.runner_id,
  rating,
  order_time,
  pickup_time,
  duration
  ORDER BY 1
````

  
#### 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?


````sql
WITH profit AS (
  SELECT
    pizza_name,
    CASE
      WHEN pizza_name = 'Meatlovers' THEN COUNT(pizza_name) * 12
      ELSE COUNT(pizza_name) * 10
    END AS profit
  FROM
    pizza_runner.customer_orders AS c
    JOIN pizza_runner.pizza_names AS n ON c.pizza_id = n.pizza_id
    JOIN pizza_runner.runner_orders AS r ON c.order_id = r.order_id
  WHERE
    pickup_time != 'null'
    AND distance != 'null'
    AND duration != 'null'
  GROUP BY
    1
),
expenses AS (
  SELECT
   sum(TO_NUMBER(distance, '99D9')*0.3) as expense
  FROM
    pizza_runner.runner_orders
      WHERE
        pickup_time != 'null'
        AND distance != 'null'
        AND duration != 'null'
    ) 
SELECT
  SUM(profit) - expense AS net_profit_in_dollars
FROM
  profit,
  expenses
GROUP BY
  expense
````
  
***Pizza Runner has left over $94.44***

### E. Bonus Questions

#### If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?

````sql
INSERT INTO
  pizza_runner.pizza_names ("pizza_id", "pizza_name")
VALUES
  (3, 'Supreme');
INSERT INTO
  pizza_runner.pizza_recipes ("pizza_id", "toppings")
VALUES
  (3, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12');
````
