-- Расчет ключевых метрик: ARPU, ARPPU, AOV

WITH t2 AS (
    SELECT order_id
    FROM user_actions
    WHERE action = 'cancel_order'
),

t1 AS (
    SELECT order_id,
           unnest(product_ids) AS product_id
    FROM orders
    WHERE order_id NOT IN (SELECT order_id FROM t2)
),

order_cost AS (
    SELECT order_id,
           SUM(price) AS order_price
    FROM t1
    JOIN products USING (product_id)
    GROUP BY order_id
),

revenue_day AS (
    SELECT creation_time::date AS date,
           SUM(order_price) AS revenue
    FROM orders
    JOIN order_cost USING (order_id)
    GROUP BY date
    ORDER BY date
),

users AS (
    SELECT DATE(time) AS date,
           COUNT(DISTINCT user_id) FILTER (
               WHERE order_id NOT IN (
                   SELECT order_id
                   FROM user_actions
                   WHERE action = 'cancel_order'
               )
           ) AS paying_users,
           COUNT(DISTINCT user_id) AS users
    FROM user_actions
    GROUP BY date
),

order_count AS (
    SELECT time::date AS date,
           COUNT(DISTINCT order_id) AS count_orders
    FROM user_actions
    WHERE order_id NOT IN (SELECT order_id FROM t2)
    GROUP BY date
)

SELECT 
    date,
    ROUND(revenue / users::decimal, 2) AS arpu,
    ROUND(revenue / paying_users::decimal, 2) AS arppu,
    ROUND(revenue / count_orders::decimal, 2) AS aov
FROM revenue_day
JOIN users USING (date)
JOIN order_count USING (date);
