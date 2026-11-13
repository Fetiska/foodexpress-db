CREATE VIEW fetisov_food.how_much_money AS
WITH RECURSIVE month_bounds AS (
    SELECT min(date_trunc('month', o.order_timestamp)::date) AS first_month,
           max(date_trunc('month', o.order_timestamp)::date) AS last_month
      FROM fetisov_food."order" AS o
     WHERE o.status = 'доставлен'
),
month_series (month_start) AS (
    SELECT mb.first_month
      FROM month_bounds AS mb
     WHERE mb.first_month IS NOT NULL

    UNION ALL

    SELECT (ms.month_start + interval '1 month')::date
      FROM month_series AS ms
      CROSS JOIN month_bounds AS mb
     WHERE ms.month_start < mb.last_month
),
monthly_orders AS (
    SELECT date_trunc('month', o.order_timestamp)::date AS month_start,
           sum(o.order_amount)::numeric AS sum_no_commission,
           sum(o.total_amount)::numeric AS sum_with_commission
      FROM fetisov_food."order" AS o
     WHERE o.status = 'доставлен'
     GROUP BY date_trunc('month', o.order_timestamp)::date
),
monthly_pay AS (
    SELECT make_date(cp.year::integer, cp.month::integer, 1) AS month_start,
           sum(cp.amount)::numeric AS courier_pay
      FROM fetisov_food.courier_pay AS cp
     GROUP BY cp.year, cp.month
),
monthly_totals AS (
    SELECT ms.month_start,
           to_char(ms.month_start, 'YYYY-MM')::text AS year_month,
           coalesce(mo.sum_no_commission, 0::numeric) AS sum_no_commission,
           coalesce(mo.sum_with_commission, 0::numeric) AS sum_with_commission,
           coalesce(mo.sum_with_commission, 0::numeric)
               - coalesce(mo.sum_no_commission, 0::numeric) AS commission,
           coalesce(mp.courier_pay, 0::numeric) AS courier_pay
      FROM month_series AS ms
      LEFT JOIN monthly_orders AS mo ON mo.month_start = ms.month_start
      LEFT JOIN monthly_pay AS mp ON mp.month_start = ms.month_start
),
monthly_with_previous AS (
    SELECT mt.*,
           lag(mt.commission) OVER (ORDER BY mt.month_start) AS prev_commission
      FROM monthly_totals AS mt
)
SELECT mwp.year_month,
       mwp.sum_no_commission,
       mwp.sum_with_commission,
       mwp.commission,
       mwp.prev_commission,
       mwp.commission - mwp.prev_commission AS commission_diff,
       mwp.courier_pay,
       mwp.commission - mwp.courier_pay AS net_profit
  FROM monthly_with_previous AS mwp;
