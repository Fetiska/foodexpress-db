CREATE PROCEDURE fetisov_food.insert_test_data(value integer)
LANGUAGE plpgsql
SET search_path = pg_catalog, fetisov_food, exts
AS $$
DECLARE
    v_client_offset bigint;
    v_courier_offset bigint;
    v_category_offset bigint;
    v_address_offset bigint;
    v_restaurant_offset bigint;
    v_product_offset bigint;
    v_order_offset bigint;
    v_restaurant_statuses fetisov_food.restaurant_status[];
    v_courier_statuses fetisov_food.courier_status[];
    v_product_statuses fetisov_food.product_status[];
    v_order_statuses fetisov_food.order_status[];
    v_payment_statuses fetisov_food.payment_status[];
    v_payment_types fetisov_food.payment_type[];
    v_review_types fetisov_food.review_entity_type[];
    v_success_index integer;
    v_dismissed_index integer;
BEGIN
    IF value IS NULL OR value < 1 THEN
        RAISE EXCEPTION 'value must be a positive integer'
            USING ERRCODE = '22023';
    END IF;

    v_restaurant_statuses := enum_range(NULL::fetisov_food.restaurant_status);
    v_courier_statuses := enum_range(NULL::fetisov_food.courier_status);
    v_product_statuses := enum_range(NULL::fetisov_food.product_status);
    v_order_statuses := enum_range(NULL::fetisov_food.order_status);
    v_payment_statuses := enum_range(NULL::fetisov_food.payment_status);
    v_payment_types := enum_range(NULL::fetisov_food.payment_type);
    v_review_types := enum_range(NULL::fetisov_food.review_entity_type);
    v_success_index := array_position(
        v_payment_statuses,
        'успех'::fetisov_food.payment_status
    );
    v_dismissed_index := array_position(
        v_courier_statuses,
        'уволен'::fetisov_food.courier_status
    );

    IF v_success_index IS NULL
       OR v_dismissed_index IS NULL
       OR v_dismissed_index <= 1 THEN
        RAISE EXCEPTION 'required enum values are missing';
    END IF;

    CREATE TEMP TABLE IF NOT EXISTS _seed_clients (
        client_no integer PRIMARY KEY,
        client_id uuid NOT NULL
    ) ON COMMIT DROP;
    CREATE TEMP TABLE IF NOT EXISTS _seed_couriers (
        courier_no integer PRIMARY KEY,
        courier_id uuid NOT NULL
    ) ON COMMIT DROP;
    CREATE TEMP TABLE IF NOT EXISTS _seed_categories (
        category_no integer PRIMARY KEY,
        category_id uuid NOT NULL
    ) ON COMMIT DROP;
    CREATE TEMP TABLE IF NOT EXISTS _seed_addresses (
        address_no integer PRIMARY KEY,
        address_id uuid NOT NULL
    ) ON COMMIT DROP;
    CREATE TEMP TABLE IF NOT EXISTS _seed_restaurants (
        restaurant_no integer PRIMARY KEY,
        restaurant_id uuid NOT NULL
    ) ON COMMIT DROP;
    CREATE TEMP TABLE IF NOT EXISTS _seed_products (
        product_no integer PRIMARY KEY,
        product_id uuid NOT NULL,
        restaurant_no integer NOT NULL
    ) ON COMMIT DROP;
    CREATE TEMP TABLE IF NOT EXISTS _seed_orders (
        order_no integer PRIMARY KEY,
        order_id uuid NOT NULL,
        client_no integer NOT NULL,
        client_id uuid NOT NULL,
        courier_no integer NOT NULL,
        courier_id uuid NOT NULL,
        address_id uuid NOT NULL,
        restaurant_no integer NOT NULL,
        restaurant_id uuid NOT NULL,
        order_timestamp timestamp without time zone NOT NULL,
        status fetisov_food.order_status NOT NULL,
        order_amount numeric(12, 2) NOT NULL
    ) ON COMMIT DROP;

    TRUNCATE TABLE
        pg_temp._seed_clients,
        pg_temp._seed_couriers,
        pg_temp._seed_categories,
        pg_temp._seed_addresses,
        pg_temp._seed_restaurants,
        pg_temp._seed_products,
        pg_temp._seed_orders;

    SELECT count(*) INTO v_client_offset FROM fetisov_food.client;
    SELECT count(*) INTO v_courier_offset FROM fetisov_food.courier;
    SELECT count(*) INTO v_category_offset FROM fetisov_food.product_category;
    SELECT count(*) INTO v_address_offset FROM fetisov_food.address;
    SELECT count(*) INTO v_restaurant_offset FROM fetisov_food.restaurant;
    SELECT count(*) INTO v_product_offset FROM fetisov_food.product;
    SELECT count(*) INTO v_order_offset FROM fetisov_food."order";

    INSERT INTO pg_temp._seed_clients (client_no, client_id)
    SELECT g.seed_no, exts.uuid_generate_v4()
      FROM generate_series(1, value) AS g(seed_no);

    INSERT INTO pg_temp._seed_couriers (courier_no, courier_id)
    SELECT g.seed_no, exts.uuid_generate_v4()
      FROM generate_series(1, value) AS g(seed_no);

    INSERT INTO pg_temp._seed_categories (category_no, category_id)
    SELECT g.seed_no, exts.uuid_generate_v4()
      FROM generate_series(1, value) AS g(seed_no);

    INSERT INTO pg_temp._seed_addresses (address_no, address_id)
    SELECT g.address_no, exts.uuid_generate_v4()
      FROM generate_series(1, value * 5) AS g(address_no);

    INSERT INTO pg_temp._seed_restaurants (restaurant_no, restaurant_id)
    SELECT g.seed_no, exts.uuid_generate_v4()
      FROM generate_series(1, value) AS g(seed_no);

    INSERT INTO pg_temp._seed_products (product_no, product_id, restaurant_no)
    SELECT g.product_no,
           exts.uuid_generate_v4(),
           ((g.product_no - 1) / 5) + 1
      FROM generate_series(1, value * 5) AS g(product_no);

    INSERT INTO fetisov_food.client (
        client_id,
        login,
        password,
        phone_number
    )
    SELECT sc.client_id,
           'seed_client_' || (v_client_offset + sc.client_no)::text,
           md5(random()::text),
           '+7' || lpad(
               ((v_client_offset + sc.client_no) % 10000000000)::text,
               10,
               '0'
           )
      FROM pg_temp._seed_clients AS sc;

    INSERT INTO fetisov_food.courier (
        courier_id,
        fio,
        phone_number,
        status,
        hire_date,
        dismissal_date
    )
    SELECT sc.courier_id,
           'Seed Courier ' || (v_courier_offset + sc.courier_no)::text,
           '+7' || lpad(
               ((v_courier_offset + sc.courier_no) % 10000000000)::text,
               10,
               '0'
           ),
           CASE
               WHEN value > 1 AND sc.courier_no = value
                   THEN v_courier_statuses[v_dismissed_index]
               ELSE v_courier_statuses[
                   ((sc.courier_no - 1) % (v_dismissed_index - 1)) + 1
               ]
           END,
           (current_date - interval '6 months')::date,
           CASE
               WHEN value > 1 AND sc.courier_no = value
                   THEN current_date - 1
               ELSE NULL
           END
      FROM pg_temp._seed_couriers AS sc;

    INSERT INTO fetisov_food.product_category (
        product_category_id,
        product_category_name
    )
    SELECT sc.category_id,
           'Seed Category ' || (v_category_offset + sc.category_no)::text
      FROM pg_temp._seed_categories AS sc;

    INSERT INTO fetisov_food.address (
        address_id,
        street,
        house_number,
        apartment_office
    )
    SELECT sa.address_id,
           'Seed Street ' || (v_address_offset + sa.address_no)::text,
           'H' || (v_address_offset + sa.address_no)::text,
           CASE
               WHEN sa.address_no % 2 = 0 THEN NULL
               ELSE 'A' || sa.address_no::text
           END
      FROM pg_temp._seed_addresses AS sa;

    INSERT INTO fetisov_food.client_address (client_id, address_id)
    SELECT sc.client_id,
           sa.address_id
      FROM pg_temp._seed_clients AS sc
      CROSS JOIN generate_series(1, 4) AS slot(address_slot)
      JOIN pg_temp._seed_addresses AS sa
        ON sa.address_no = value + (sc.client_no - 1) * 4 + slot.address_slot;

    INSERT INTO fetisov_food.restaurant (
        restaurant_id,
        restaurant_name,
        address_id,
        description,
        work_start,
        work_end,
        company_details,
        rating,
        status
    )
    SELECT sr.restaurant_id,
           'Seed Restaurant ' || (v_restaurant_offset + sr.restaurant_no)::text,
           sa.address_id,
           'Seed restaurant description ' || sr.restaurant_no::text,
           time '09:00',
           time '21:00',
           'Seed legal details ' || sr.restaurant_no::text,
           NULL,
           v_restaurant_statuses[1]
      FROM pg_temp._seed_restaurants AS sr
      JOIN pg_temp._seed_addresses AS sa
        ON sa.address_no = sr.restaurant_no;

    INSERT INTO fetisov_food.product (
        product_id,
        product_name,
        product_category_id,
        price,
        restaurant_id,
        photo_url,
        rating,
        status,
        description
    )
    SELECT sp.product_id,
           'Seed Product ' || (v_product_offset + sp.product_no)::text,
           sc.category_id,
           500 + ((sp.product_no - 1) % 5) * 100,
           sr.restaurant_id,
           NULL,
           NULL,
           v_product_statuses[1],
           'Seed product description ' || sp.product_no::text
      FROM pg_temp._seed_products AS sp
      JOIN pg_temp._seed_categories AS sc
        ON sc.category_no = ((sp.product_no - 1) % value) + 1
      JOIN pg_temp._seed_restaurants AS sr
        ON sr.restaurant_no = sp.restaurant_no;

    INSERT INTO pg_temp._seed_orders (
        order_no,
        order_id,
        client_no,
        client_id,
        courier_no,
        courier_id,
        address_id,
        restaurant_no,
        restaurant_id,
        order_timestamp,
        status,
        order_amount
    )
    SELECT g.order_no,
           exts.uuid_generate_v4(),
           ((g.order_no - 1) % value) + 1,
           sc.client_id,
           ((g.order_no - 1) % value) + 1,
           cr.courier_id,
           sa.address_id,
           ((g.order_no - 1) % value) + 1,
           sr.restaurant_id,
           CASE
               WHEN (g.order_no - 1) % 6 = 0 THEN localtimestamp
               ELSE date_trunc('month', localtimestamp)
                    - make_interval(months => ((g.order_no - 1) % 6))
                    + interval '5 days'
           END,
           v_order_statuses[((g.order_no - 1) / value) + 1],
           (
               SELECT sum(p.price)::numeric(12, 2)
                 FROM pg_temp._seed_products AS sp
                 JOIN fetisov_food.product AS p ON p.product_id = sp.product_id
                WHERE sp.restaurant_no = ((g.order_no - 1) % value) + 1
                  AND (sp.product_no - 1) % 5 IN (0, 1)
           )
      FROM generate_series(1, value * 5) AS g(order_no)
      JOIN pg_temp._seed_clients AS sc
        ON sc.client_no = ((g.order_no - 1) % value) + 1
      JOIN pg_temp._seed_couriers AS cr
        ON cr.courier_no = ((g.order_no - 1) % value) + 1
      JOIN pg_temp._seed_restaurants AS sr
        ON sr.restaurant_no = ((g.order_no - 1) % value) + 1
      JOIN pg_temp._seed_addresses AS sa
        ON sa.address_no = value
            + (((g.order_no - 1) % value) * 4)
            + (((g.order_no - 1) / value) % 4)
            + 1;

    INSERT INTO fetisov_food."order" (
        order_id,
        courier_id,
        client_id,
        address_id,
        restaurant_id,
        order_timestamp,
        delivery_timestamp,
        order_amount,
        commission,
        total_amount,
        status,
        description
    )
    SELECT so.order_id,
           so.courier_id,
           so.client_id,
           so.address_id,
           so.restaurant_id,
           so.order_timestamp,
           CASE
               WHEN so.status = 'доставлен' THEN so.order_timestamp
               ELSE NULL
           END,
           so.order_amount,
           round(so.order_amount * 0.10, 2),
           so.order_amount + round(so.order_amount * 0.10, 2),
           so.status,
           'Seed order ' || (v_order_offset + so.order_no)::text
      FROM pg_temp._seed_orders AS so;

    INSERT INTO fetisov_food.order_structure (order_id, product_id, quantity)
    SELECT so.order_id,
           sp.product_id,
           1
      FROM pg_temp._seed_orders AS so
      JOIN pg_temp._seed_products AS sp
        ON sp.restaurant_no = so.restaurant_no
       AND (sp.product_no - 1) % 5 IN (0, 1);

    INSERT INTO fetisov_food.payment (
        order_id,
        payment_type,
        amount,
        transaction_id,
        transaction_timestamp,
        status
    )
    SELECT so.order_id,
           v_payment_types[((so.order_no - 1) % cardinality(v_payment_types)) + 1],
           o.total_amount,
           'seed_' || so.order_id::text,
           so.order_timestamp,
           v_payment_statuses[v_success_index]
      FROM pg_temp._seed_orders AS so
      JOIN fetisov_food."order" AS o ON o.order_id = so.order_id;

    INSERT INTO fetisov_food.review (
        client_id,
        review_timestamp,
        entity_id,
        entity_type,
        order_id,
        description,
        photo_url,
        rating
    )
    SELECT so.client_id,
           so.order_timestamp,
           CASE rt.entity_type
               WHEN 'блюдо' THEN sp.product_id
               WHEN 'ресторан' THEN so.restaurant_id
               ELSE so.order_id
           END,
           rt.entity_type,
           so.order_id,
           'Seed review ' || so.order_no::text,
           NULL,
           (((so.order_no - 1) % 5) + 1)::numeric(2, 1)
      FROM pg_temp._seed_orders AS so
      JOIN pg_temp._seed_products AS sp
        ON sp.restaurant_no = so.restaurant_no
       AND (sp.product_no - 1) % 5 = 0
      CROSS JOIN LATERAL (
          SELECT v_review_types[
              ((so.order_no - 1) % cardinality(v_review_types)) + 1
          ] AS entity_type
      ) AS rt;

    WITH month_series AS (
        SELECT date_trunc('month', localtimestamp)
               - make_interval(months => m.month_offset) AS month_start
          FROM generate_series(0, 5) AS m(month_offset)
    ),
    courier_months AS (
        SELECT c.courier_id,
               c.coefficient,
               cp.coefficient_used AS saved_coefficient,
               ms.month_start,
               coalesce(sum(o.commission), 0::numeric) AS commission_total
          FROM fetisov_food.courier AS c
          CROSS JOIN month_series AS ms
          LEFT JOIN fetisov_food."order" AS o
            ON o.courier_id = c.courier_id
           AND o.status = 'доставлен'
           AND o.order_timestamp >= ms.month_start
           AND o.order_timestamp < ms.month_start + interval '1 month'
          LEFT JOIN fetisov_food.courier_pay AS cp
            ON cp.courier_id = c.courier_id
           AND cp.year = extract(year FROM ms.month_start)::smallint
           AND cp.month = extract(month FROM ms.month_start)::smallint
         GROUP BY c.courier_id,
                  c.coefficient,
                  cp.coefficient_used,
                  ms.month_start
    )
    INSERT INTO fetisov_food.courier_pay (
        year,
        month,
        courier_id,
        amount,
        coefficient_used
    )
    SELECT extract(year FROM cm.month_start)::smallint,
           extract(month FROM cm.month_start)::smallint,
           cm.courier_id,
           round(coalesce(cm.saved_coefficient, cm.coefficient) * cm.commission_total, 2),
           coalesce(cm.saved_coefficient, cm.coefficient)
      FROM courier_months AS cm
    ON CONFLICT (year, month, courier_id)
    DO UPDATE SET
        amount = EXCLUDED.amount,
        coefficient_used = EXCLUDED.coefficient_used;

    UPDATE fetisov_food.courier AS c
       SET coefficient = CASE
           WHEN cm.delivered_count <= 150 THEN 0.1
           WHEN cm.delivered_count <= 250 THEN 0.2
           WHEN cm.delivered_count <= 500 THEN 0.3
           ELSE 0.5
       END
      FROM (
          SELECT c2.courier_id,
                 count(o.order_id)::integer AS delivered_count
            FROM fetisov_food.courier AS c2
            LEFT JOIN fetisov_food."order" AS o
              ON o.courier_id = c2.courier_id
             AND o.status = 'доставлен'
             AND o.order_timestamp >= date_trunc('month', localtimestamp)
             AND o.order_timestamp < date_trunc('month', localtimestamp) + interval '1 month'
           GROUP BY c2.courier_id
      ) AS cm
     WHERE c.courier_id = cm.courier_id
       AND c.status <> v_courier_statuses[v_dismissed_index];
END;
$$;
