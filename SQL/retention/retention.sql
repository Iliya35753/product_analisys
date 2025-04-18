with t2 as (SELECT start_date,
                   date,
                   round(count(distinct user_id)::decimal/max(count(distinct user_id)) OVER(PARTITION BY start_date), 2) as retention
            FROM   (SELECT user_id,
                           min(time::date) OVER (PARTITION BY user_id) as start_date,
                           time::date as date
                    FROM   user_actions) t1
            GROUP BY start_date, date
            ORDER BY start_date, date)
SELECT date_trunc('month', start_date)::date as start_month,
       start_date,
       extract('day' FROM   age(date, start_date))::int as day_number, retention
FROM   t2
