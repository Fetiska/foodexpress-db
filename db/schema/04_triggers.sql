CREATE FUNCTION fetisov_food.validate_order_structure_restaurant()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, fetisov_food, exts
AS $$
DECLARE
    v_order_restaurant uuid;
    v_product_restaurant uuid;
BEGIN
    SELECT o.restaurant_id, p.restaurant_id
      INTO v_order_restaurant, v_product_restaurant
      FROM fetisov_food."order" AS o
      JOIN fetisov_food.product AS p ON p.product_id = NEW.product_id
     WHERE o.order_id = NEW.order_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'order_id % and product_id % must exist', NEW.order_id, NEW.product_id
            USING ERRCODE = '23503';
    END IF;

    IF v_order_restaurant <> v_product_restaurant THEN
        RAISE EXCEPTION 'product % belongs to a different restaurant than order %',
            NEW.product_id, NEW.order_id
            USING ERRCODE = '23514';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER validate_order_structure_restaurant
BEFORE INSERT OR UPDATE OF order_id, product_id
ON fetisov_food.order_structure
FOR EACH ROW
EXECUTE FUNCTION fetisov_food.validate_order_structure_restaurant();

CREATE FUNCTION fetisov_food.validate_order_restaurant_update()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, fetisov_food, exts
AS $$
BEGIN
    IF NEW.restaurant_id IS DISTINCT FROM OLD.restaurant_id AND EXISTS (
        SELECT 1
          FROM fetisov_food.order_structure AS os
          JOIN fetisov_food.product AS p ON p.product_id = os.product_id
         WHERE os.order_id = NEW.order_id
           AND p.restaurant_id <> NEW.restaurant_id
    ) THEN
        RAISE EXCEPTION 'order % contains products from another restaurant', NEW.order_id
            USING ERRCODE = '23514';
    END IF;

    IF NEW.client_id IS DISTINCT FROM OLD.client_id AND EXISTS (
        SELECT 1
          FROM fetisov_food.review AS r
         WHERE r.order_id = NEW.order_id
           AND r.client_id <> NEW.client_id
    ) THEN
        RAISE EXCEPTION 'order % already has reviews by its original client', NEW.order_id
            USING ERRCODE = '23514';
    END IF;

    IF NEW.restaurant_id IS DISTINCT FROM OLD.restaurant_id AND EXISTS (
        SELECT 1
          FROM fetisov_food.review AS r
         WHERE r.order_id = NEW.order_id
           AND r.entity_type = 'ресторан'
           AND r.entity_id <> NEW.restaurant_id
    ) THEN
        RAISE EXCEPTION 'order % already has a review for its original restaurant', NEW.order_id
            USING ERRCODE = '23514';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER validate_order_restaurant_update
BEFORE UPDATE OF restaurant_id, client_id
ON fetisov_food."order"
FOR EACH ROW
EXECUTE FUNCTION fetisov_food.validate_order_restaurant_update();

CREATE FUNCTION fetisov_food.ensure_order_has_items()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, fetisov_food, exts
AS $$
DECLARE
    v_order_id uuid;
    v_order_ids uuid[];
BEGIN
    IF TG_TABLE_NAME = 'order' THEN
        v_order_ids := ARRAY[NEW.order_id];
    ELSIF TG_OP = 'DELETE' THEN
        v_order_ids := ARRAY[OLD.order_id];
    ELSE
        v_order_ids := ARRAY[OLD.order_id, NEW.order_id];
    END IF;

    FOREACH v_order_id IN ARRAY v_order_ids LOOP
        IF EXISTS (
            SELECT 1
              FROM fetisov_food."order" AS o
             WHERE o.order_id = v_order_id
        ) AND NOT EXISTS (
            SELECT 1
              FROM fetisov_food.order_structure AS os
             WHERE os.order_id = v_order_id
        ) THEN
            RAISE EXCEPTION 'order % must contain at least one item', v_order_id
                USING ERRCODE = '23514';
        END IF;
    END LOOP;

    RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER ensure_order_has_items_after_insert
AFTER INSERT ON fetisov_food."order"
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION fetisov_food.ensure_order_has_items();

CREATE CONSTRAINT TRIGGER ensure_order_has_items_after_structure_change
AFTER UPDATE OR DELETE ON fetisov_food.order_structure
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION fetisov_food.ensure_order_has_items();

CREATE FUNCTION fetisov_food.validate_order_structure_review_integrity()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, fetisov_food, exts
AS $$
DECLARE
    v_invalidates_review boolean := false;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_invalidates_review := true;
    ELSE
        v_invalidates_review := NEW.order_id IS DISTINCT FROM OLD.order_id
                                OR NEW.product_id IS DISTINCT FROM OLD.product_id;
    END IF;

    IF v_invalidates_review AND EXISTS (
        SELECT 1
          FROM fetisov_food.review AS r
         WHERE r.order_id = OLD.order_id
           AND r.entity_type = 'блюдо'
           AND r.entity_id = OLD.product_id
    ) THEN
        RAISE EXCEPTION 'order item is referenced by a product review'
            USING ERRCODE = '23514';
    END IF;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER validate_order_structure_review_integrity
BEFORE UPDATE OF order_id, product_id OR DELETE
ON fetisov_food.order_structure
FOR EACH ROW
EXECUTE FUNCTION fetisov_food.validate_order_structure_review_integrity();

CREATE FUNCTION fetisov_food.validate_product_restaurant_update()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, fetisov_food, exts
AS $$
BEGIN
    IF NEW.restaurant_id IS DISTINCT FROM OLD.restaurant_id AND EXISTS (
        SELECT 1
          FROM fetisov_food.order_structure AS os
          JOIN fetisov_food."order" AS o ON o.order_id = os.order_id
         WHERE os.product_id = NEW.product_id
           AND o.restaurant_id <> NEW.restaurant_id
    ) THEN
        RAISE EXCEPTION 'product % is used by orders from its current restaurant', NEW.product_id
            USING ERRCODE = '23514';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER validate_product_restaurant_update
BEFORE UPDATE OF restaurant_id
ON fetisov_food.product
FOR EACH ROW
EXECUTE FUNCTION fetisov_food.validate_product_restaurant_update();

CREATE FUNCTION fetisov_food.validate_review_target()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, fetisov_food, exts
AS $$
DECLARE
    v_order_client uuid;
    v_order_restaurant uuid;
BEGIN
    SELECT o.client_id, o.restaurant_id
      INTO v_order_client, v_order_restaurant
      FROM fetisov_food."order" AS o
     WHERE o.order_id = NEW.order_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'review order_id % does not exist', NEW.order_id
            USING ERRCODE = '23503';
    END IF;

    IF NEW.client_id <> v_order_client THEN
        RAISE EXCEPTION 'review client_id must match the client who placed order %', NEW.order_id
            USING ERRCODE = '23514';
    END IF;

    CASE NEW.entity_type
        WHEN 'блюдо' THEN
            IF NOT EXISTS (
                SELECT 1
                  FROM fetisov_food.order_structure AS os
                 WHERE os.order_id = NEW.order_id
                   AND os.product_id = NEW.entity_id
            ) THEN
                RAISE EXCEPTION 'reviewed product % must be part of order %',
                    NEW.entity_id, NEW.order_id
                    USING ERRCODE = '23514';
            END IF;
        WHEN 'ресторан' THEN
            IF NEW.entity_id <> v_order_restaurant THEN
                RAISE EXCEPTION 'reviewed restaurant must match order %', NEW.order_id
                    USING ERRCODE = '23514';
            END IF;
        WHEN 'заказ' THEN
            IF NEW.entity_id <> NEW.order_id THEN
                RAISE EXCEPTION 'order review entity_id must equal order_id'
                    USING ERRCODE = '23514';
            END IF;
    END CASE;

    RETURN NEW;
END;
$$;

CREATE TRIGGER validate_review_target
BEFORE INSERT OR UPDATE OF client_id, order_id, entity_type, entity_id
ON fetisov_food.review
FOR EACH ROW
EXECUTE FUNCTION fetisov_food.validate_review_target();

CREATE FUNCTION fetisov_food.rating_change()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, fetisov_food, exts
AS $$
DECLARE
    v_old_type fetisov_food.review_entity_type;
    v_old_id uuid;
    v_new_type fetisov_food.review_entity_type;
    v_new_id uuid;
BEGIN
    IF TG_OP <> 'INSERT' THEN
        v_old_type := OLD.entity_type;
        v_old_id := OLD.entity_id;
    END IF;

    IF TG_OP <> 'DELETE' THEN
        v_new_type := NEW.entity_type;
        v_new_id := NEW.entity_id;
    END IF;

    IF v_old_type IS NOT NULL
       AND (v_old_type, v_old_id) IS DISTINCT FROM (v_new_type, v_new_id) THEN
        IF v_old_type = 'блюдо' THEN
            UPDATE fetisov_food.product AS p
               SET rating = (
                   SELECT avg(r.rating)
                     FROM fetisov_food.review AS r
                    WHERE r.entity_type = 'блюдо'
                      AND r.entity_id = v_old_id
               )
             WHERE p.product_id = v_old_id;
        ELSIF v_old_type = 'ресторан' THEN
            UPDATE fetisov_food.restaurant AS r
               SET rating = (
                   SELECT avg(rv.rating)
                     FROM fetisov_food.review AS rv
                    WHERE rv.entity_type = 'ресторан'
                      AND rv.entity_id = v_old_id
               )
             WHERE r.restaurant_id = v_old_id;
        END IF;
    END IF;

    IF v_new_type IS NOT NULL THEN
        IF v_new_type = 'блюдо' THEN
            UPDATE fetisov_food.product AS p
               SET rating = (
                   SELECT avg(r.rating)
                     FROM fetisov_food.review AS r
                    WHERE r.entity_type = 'блюдо'
                      AND r.entity_id = v_new_id
               )
             WHERE p.product_id = v_new_id;
        ELSIF v_new_type = 'ресторан' THEN
            UPDATE fetisov_food.restaurant AS r
               SET rating = (
                   SELECT avg(rv.rating)
                     FROM fetisov_food.review AS rv
                    WHERE rv.entity_type = 'ресторан'
                      AND rv.entity_id = v_new_id
               )
             WHERE r.restaurant_id = v_new_id;
        END IF;
    END IF;

    RETURN NULL;
END;
$$;

CREATE TRIGGER rating_change
AFTER INSERT OR UPDATE OR DELETE
ON fetisov_food.review
FOR EACH ROW
EXECUTE FUNCTION fetisov_food.rating_change();

CREATE FUNCTION fetisov_food.validate_payment_amount()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, fetisov_food, exts
AS $$
DECLARE
    v_total_amount numeric(12, 2);
BEGIN
    SELECT o.total_amount
      INTO v_total_amount
      FROM fetisov_food."order" AS o
     WHERE o.order_id = NEW.order_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'payment order_id % does not exist', NEW.order_id
            USING ERRCODE = '23503';
    END IF;

    IF NEW.amount IS DISTINCT FROM v_total_amount THEN
        RAISE EXCEPTION 'payment amount must equal order total_amount %', v_total_amount
            USING ERRCODE = '23514';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER validate_payment_amount
BEFORE INSERT OR UPDATE OF order_id, amount
ON fetisov_food.payment
FOR EACH ROW
EXECUTE FUNCTION fetisov_food.validate_payment_amount();

CREATE FUNCTION fetisov_food.validate_order_payment_amounts()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, fetisov_food, exts
AS $$
BEGIN
    IF EXISTS (
        SELECT 1
          FROM fetisov_food.payment AS p
         WHERE p.order_id = NEW.order_id
           AND p.amount IS DISTINCT FROM NEW.total_amount
    ) THEN
        RAISE EXCEPTION 'order total_amount must match every payment attempt amount'
            USING ERRCODE = '23514';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER validate_order_payment_amounts
BEFORE UPDATE OF total_amount
ON fetisov_food."order"
FOR EACH ROW
EXECUTE FUNCTION fetisov_food.validate_order_payment_amounts();

CREATE FUNCTION fetisov_food.validate_order_pay_status()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, fetisov_food, exts
AS $$
DECLARE
    v_expected fetisov_food.order_pay_status;
    v_attempt_count bigint;
    v_success_count bigint;
    v_processing_count bigint;
BEGIN
    SELECT count(*),
           count(*) FILTER (WHERE p.status = 'успех'),
           count(*) FILTER (WHERE p.status = 'в_обработке')
      INTO v_attempt_count, v_success_count, v_processing_count
      FROM fetisov_food.payment AS p
     WHERE p.order_id = NEW.order_id;

    v_expected := CASE
        WHEN v_success_count > 0 THEN 'оплачен'::fetisov_food.order_pay_status
        WHEN v_attempt_count = 0 OR v_processing_count > 0
            THEN 'ожидает'::fetisov_food.order_pay_status
        ELSE 'ошибка'::fetisov_food.order_pay_status
    END;

    IF NEW.pay_status IS DISTINCT FROM v_expected THEN
        RAISE EXCEPTION 'order pay_status must match payment attempts; expected %', v_expected
            USING ERRCODE = '23514';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER validate_order_pay_status
BEFORE INSERT OR UPDATE OF pay_status
ON fetisov_food."order"
FOR EACH ROW
EXECUTE FUNCTION fetisov_food.validate_order_pay_status();

CREATE FUNCTION fetisov_food.sync_order_pay_status()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, fetisov_food, exts
AS $$
DECLARE
    v_order_id uuid;
    v_order_ids uuid[];
    v_pay_status fetisov_food.order_pay_status;
    v_attempt_count bigint;
    v_success_count bigint;
    v_processing_count bigint;
BEGIN
    IF TG_OP = 'INSERT' THEN
        v_order_ids := ARRAY[NEW.order_id];
    ELSIF TG_OP = 'DELETE' THEN
        v_order_ids := ARRAY[OLD.order_id];
    ELSIF OLD.order_id = NEW.order_id THEN
        v_order_ids := ARRAY[NEW.order_id];
    ELSE
        v_order_ids := ARRAY[OLD.order_id, NEW.order_id];
    END IF;

    FOREACH v_order_id IN ARRAY v_order_ids LOOP
        SELECT count(*),
               count(*) FILTER (WHERE p.status = 'успех'),
               count(*) FILTER (WHERE p.status = 'в_обработке')
          INTO v_attempt_count, v_success_count, v_processing_count
          FROM fetisov_food.payment AS p
         WHERE p.order_id = v_order_id;

        v_pay_status := CASE
            WHEN v_success_count > 0 THEN 'оплачен'::fetisov_food.order_pay_status
            WHEN v_attempt_count = 0 OR v_processing_count > 0
                THEN 'ожидает'::fetisov_food.order_pay_status
            ELSE 'ошибка'::fetisov_food.order_pay_status
        END;

        UPDATE fetisov_food."order" AS o
           SET pay_status = v_pay_status
         WHERE o.order_id = v_order_id
           AND o.pay_status IS DISTINCT FROM v_pay_status;
    END LOOP;

    RETURN NULL;
END;
$$;

CREATE TRIGGER sync_order_pay_status
AFTER INSERT OR UPDATE OR DELETE
ON fetisov_food.payment
FOR EACH ROW
EXECUTE FUNCTION fetisov_food.sync_order_pay_status();
