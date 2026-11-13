CREATE PROCEDURE fetisov_food.erase_test_data()
LANGUAGE plpgsql
SET search_path = pg_catalog, fetisov_food, exts
AS $$
BEGIN
    TRUNCATE TABLE
        fetisov_food.review,
        fetisov_food.order_structure,
        fetisov_food.payment,
        fetisov_food.courier_pay,
        fetisov_food."order",
        fetisov_food.product,
        fetisov_food.restaurant,
        fetisov_food.courier,
        fetisov_food.client_address,
        fetisov_food.address,
        fetisov_food.product_category,
        fetisov_food.client;
END;
$$;

CREATE PROCEDURE fetisov_food.add_product(
    p_product_name varchar,
    p_product_category_id uuid,
    p_price numeric,
    p_restaurant_id uuid,
    p_photo_url text,
    p_rating numeric,
    p_status fetisov_food.product_status,
    p_description text
)
LANGUAGE plpgsql
SET search_path = pg_catalog, fetisov_food, exts
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
          FROM fetisov_food.restaurant AS r
         WHERE r.restaurant_id = p_restaurant_id
    ) THEN
        RAISE EXCEPTION 'restaurant_id % does not exist', p_restaurant_id
            USING ERRCODE = '23503';
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM fetisov_food.product_category AS pc
         WHERE pc.product_category_id = p_product_category_id
    ) THEN
        RAISE EXCEPTION 'product_category_id % does not exist', p_product_category_id
            USING ERRCODE = '23503';
    END IF;

    IF p_price < 0 THEN
        RAISE EXCEPTION 'price must be nonnegative'
            USING ERRCODE = '23514';
    END IF;

    INSERT INTO fetisov_food.product (
        product_name,
        product_category_id,
        price,
        restaurant_id,
        photo_url,
        rating,
        status,
        description
    )
    VALUES (
        p_product_name,
        p_product_category_id,
        p_price,
        p_restaurant_id,
        p_photo_url,
        p_rating,
        p_status,
        p_description
    );
END;
$$;

CREATE FUNCTION fetisov_food.get_statistic()
RETURNS TABLE (
    restaurant_name text,
    best_product_name text,
    total_amount numeric,
    avg_amount numeric,
    best_user text
)
LANGUAGE sql
VOLATILE
SET search_path = pg_catalog, fetisov_food, exts
AS $$
    WITH delivered_orders AS MATERIALIZED (
        SELECT o.order_id, o.restaurant_id, o.client_id, o.total_amount
          FROM fetisov_food."order" AS o
         WHERE o.status = 'доставлен'
    ),
    metric_rows AS (
        SELECT d.restaurant_id,
               'order'::text AS metric_kind,
               d.total_amount::numeric AS amount,
               NULL::text AS product_name,
               NULL::numeric AS product_quantity,
               NULL::text AS client_login,
               NULL::bigint AS client_orders
          FROM delivered_orders AS d

        UNION ALL

        SELECT d.restaurant_id,
               'product'::text AS metric_kind,
               NULL::numeric AS amount,
               p.product_name::text AS product_name,
               sum(os.quantity)::numeric AS product_quantity,
               NULL::text AS client_login,
               NULL::bigint AS client_orders
          FROM delivered_orders AS d
          JOIN fetisov_food.order_structure AS os ON os.order_id = d.order_id
          JOIN fetisov_food.product AS p ON p.product_id = os.product_id
         GROUP BY d.restaurant_id, p.product_id, p.product_name

        UNION ALL

        SELECT d.restaurant_id,
               'user'::text AS metric_kind,
               NULL::numeric AS amount,
               NULL::text AS product_name,
               NULL::numeric AS product_quantity,
               c.login::text AS client_login,
               count(*)::bigint AS client_orders
          FROM delivered_orders AS d
          JOIN fetisov_food.client AS c ON c.client_id = d.client_id
         GROUP BY d.restaurant_id, c.client_id, c.login
    ),
    restaurant_metrics AS (
        SELECT m.restaurant_id,
               sum(m.amount) FILTER (WHERE m.metric_kind = 'order') AS total_amount,
               avg(m.amount) FILTER (WHERE m.metric_kind = 'order') AS avg_amount,
               (array_agg(
                   m.product_name
                   ORDER BY m.product_quantity DESC, random()
               ) FILTER (WHERE m.metric_kind = 'product'))[1] AS best_product_name,
               (array_agg(
                   m.client_login
                   ORDER BY m.client_orders DESC, random()
               ) FILTER (WHERE m.metric_kind = 'user'))[1] AS best_user
          FROM metric_rows AS m
         GROUP BY m.restaurant_id
    )
    SELECT r.restaurant_name::text,
           rm.best_product_name,
           coalesce(rm.total_amount, 0::numeric),
           rm.avg_amount,
           rm.best_user
      FROM fetisov_food.restaurant AS r
      LEFT JOIN restaurant_metrics AS rm ON rm.restaurant_id = r.restaurant_id
     ORDER BY r.restaurant_name, r.restaurant_id;
$$;

CREATE PROCEDURE fetisov_food.courier_salary()
LANGUAGE plpgsql
SET search_path = pg_catalog, fetisov_food, exts
AS $$
DECLARE
    v_month_start timestamp without time zone := date_trunc('month', localtimestamp);
    v_year smallint := extract(year FROM localtimestamp)::smallint;
    v_month smallint := extract(month FROM localtimestamp)::smallint;
    v_row record;
    v_new_coefficient numeric(2, 1);
BEGIN
    FOR v_row IN
        SELECT c.courier_id,
               c.status,
               c.coefficient AS current_coefficient,
               cp.coefficient_used AS saved_coefficient,
               count(o.order_id)::integer AS delivered_count,
               coalesce(sum(o.commission), 0::numeric) AS commission_total
          FROM fetisov_food.courier AS c
          LEFT JOIN fetisov_food."order" AS o
            ON o.courier_id = c.courier_id
           AND o.status = 'доставлен'
           AND o.order_timestamp >= v_month_start
           AND o.order_timestamp < v_month_start + interval '1 month'
          LEFT JOIN fetisov_food.courier_pay AS cp
            ON cp.courier_id = c.courier_id
           AND cp.year = v_year
           AND cp.month = v_month
         GROUP BY c.courier_id, c.status, c.coefficient, cp.coefficient_used
    LOOP
        INSERT INTO fetisov_food.courier_pay (
            year,
            month,
            courier_id,
            amount,
            coefficient_used
        )
        VALUES (
            v_year,
            v_month,
            v_row.courier_id,
            round(
                coalesce(v_row.saved_coefficient, v_row.current_coefficient)
                * v_row.commission_total,
                2
            ),
            coalesce(v_row.saved_coefficient, v_row.current_coefficient)
        )
        ON CONFLICT (year, month, courier_id)
        DO UPDATE SET amount = EXCLUDED.amount;

        IF v_row.status <> 'уволен' THEN
            v_new_coefficient := CASE
                WHEN v_row.delivered_count <= 150 THEN 0.1
                WHEN v_row.delivered_count <= 250 THEN 0.2
                WHEN v_row.delivered_count <= 500 THEN 0.3
                ELSE 0.5
            END;

            UPDATE fetisov_food.courier
               SET coefficient = v_new_coefficient
             WHERE courier_id = v_row.courier_id;
        END IF;
    END LOOP;
END;
$$;
