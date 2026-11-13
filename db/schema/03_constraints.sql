ALTER TABLE fetisov_food.client
    ADD CONSTRAINT uq_client_login UNIQUE (login),
    ADD CONSTRAINT uq_client_phone UNIQUE (phone_number),
    ADD CONSTRAINT ck_client_login_nonempty CHECK (length(btrim(login)) > 0),
    ADD CONSTRAINT ck_client_password_md5 CHECK (password ~ '^[0-9a-f]{32}$'),
    ADD CONSTRAINT ck_client_phone_nonempty CHECK (length(btrim(phone_number)) > 0);

ALTER TABLE fetisov_food.address
    ADD CONSTRAINT uq_address_physical UNIQUE NULLS NOT DISTINCT
        (street, house_number, apartment_office),
    ADD CONSTRAINT ck_address_street_nonempty CHECK (length(btrim(street)) > 0),
    ADD CONSTRAINT ck_address_house_nonempty CHECK (length(btrim(house_number)) > 0),
    ADD CONSTRAINT ck_address_apartment_nonempty
        CHECK (apartment_office IS NULL OR length(btrim(apartment_office)) > 0);

ALTER TABLE fetisov_food.client_address
    ADD CONSTRAINT fk_client_address_client
        FOREIGN KEY (client_id) REFERENCES fetisov_food.client (client_id),
    ADD CONSTRAINT fk_client_address_address
        FOREIGN KEY (address_id) REFERENCES fetisov_food.address (address_id);

ALTER TABLE fetisov_food.restaurant
    ADD CONSTRAINT uq_restaurant_address UNIQUE (address_id),
    ADD CONSTRAINT fk_restaurant_address
        FOREIGN KEY (address_id) REFERENCES fetisov_food.address (address_id),
    ADD CONSTRAINT ck_restaurant_name_nonempty
        CHECK (length(btrim(restaurant_name)) > 0),
    ADD CONSTRAINT ck_restaurant_description_nonempty
        CHECK (length(btrim(description)) > 0),
    ADD CONSTRAINT ck_restaurant_details_nonempty
        CHECK (length(btrim(company_details)) > 0),
    ADD CONSTRAINT ck_restaurant_rating
        CHECK (rating IS NULL OR rating BETWEEN 0 AND 5),
    ADD CONSTRAINT ck_restaurant_work_hours
        CHECK (work_end > work_start);

ALTER TABLE fetisov_food.courier
    ADD CONSTRAINT ck_courier_fio_nonempty CHECK (length(btrim(fio)) > 0),
    ADD CONSTRAINT ck_courier_phone_nonempty CHECK (length(btrim(phone_number)) > 0),
    ADD CONSTRAINT ck_courier_coefficient CHECK (coefficient BETWEEN 0.1 AND 0.5),
    ADD CONSTRAINT ck_courier_dismissal_required
        CHECK (status <> 'уволен' OR dismissal_date IS NOT NULL),
    ADD CONSTRAINT ck_courier_dismissal_after_hire
        CHECK (dismissal_date IS NULL OR dismissal_date >= hire_date);

ALTER TABLE fetisov_food.courier_pay
    ADD CONSTRAINT fk_courier_pay_courier
        FOREIGN KEY (courier_id) REFERENCES fetisov_food.courier (courier_id),
    ADD CONSTRAINT ck_courier_pay_month CHECK (month BETWEEN 1 AND 12),
    ADD CONSTRAINT ck_courier_pay_amount CHECK (amount >= 0),
    ADD CONSTRAINT ck_courier_pay_coefficient
        CHECK (coefficient_used BETWEEN 0.1 AND 0.5);

ALTER TABLE fetisov_food.product_category
    ADD CONSTRAINT ck_product_category_name_nonempty
        CHECK (length(btrim(product_category_name)) > 0);

ALTER TABLE fetisov_food.product
    ADD CONSTRAINT fk_product_category
        FOREIGN KEY (product_category_id)
        REFERENCES fetisov_food.product_category (product_category_id),
    ADD CONSTRAINT fk_product_restaurant
        FOREIGN KEY (restaurant_id) REFERENCES fetisov_food.restaurant (restaurant_id),
    ADD CONSTRAINT ck_product_name_nonempty CHECK (length(btrim(product_name)) > 0),
    ADD CONSTRAINT ck_product_description_nonempty
        CHECK (length(btrim(description)) > 0),
    ADD CONSTRAINT ck_product_price CHECK (price >= 0),
    ADD CONSTRAINT ck_product_rating CHECK (rating IS NULL OR rating BETWEEN 0 AND 5);

ALTER TABLE fetisov_food."order"
    ADD CONSTRAINT fk_order_courier
        FOREIGN KEY (courier_id) REFERENCES fetisov_food.courier (courier_id),
    ADD CONSTRAINT fk_order_client
        FOREIGN KEY (client_id) REFERENCES fetisov_food.client (client_id),
    ADD CONSTRAINT fk_order_address
        FOREIGN KEY (address_id) REFERENCES fetisov_food.address (address_id),
    ADD CONSTRAINT fk_order_restaurant
        FOREIGN KEY (restaurant_id) REFERENCES fetisov_food.restaurant (restaurant_id),
    ADD CONSTRAINT fk_order_client_address
        FOREIGN KEY (client_id, address_id)
        REFERENCES fetisov_food.client_address (client_id, address_id),
    ADD CONSTRAINT ck_order_description_nonempty
        CHECK (length(btrim(description)) > 0),
    ADD CONSTRAINT ck_order_amount CHECK (order_amount >= 0),
    ADD CONSTRAINT ck_order_commission
        CHECK (commission = round(order_amount * 0.10, 2)),
    ADD CONSTRAINT ck_order_total
        CHECK (total_amount = order_amount + commission),
    ADD CONSTRAINT ck_order_minimum_total CHECK (total_amount >= 1000),
    ADD CONSTRAINT ck_order_delivery_after_order
        CHECK (delivery_timestamp IS NULL OR delivery_timestamp >= order_timestamp),
    ADD CONSTRAINT ck_delivered_order_has_delivery_time
        CHECK (status <> 'доставлен' OR delivery_timestamp IS NOT NULL);

ALTER TABLE fetisov_food.payment
    ADD CONSTRAINT fk_payment_order
        FOREIGN KEY (order_id) REFERENCES fetisov_food."order" (order_id),
    ADD CONSTRAINT uq_payment_transaction UNIQUE (transaction_id),
    ADD CONSTRAINT ck_payment_amount CHECK (amount > 0),
    ADD CONSTRAINT ck_payment_transaction_nonempty
        CHECK (length(btrim(transaction_id)) > 0);

CREATE UNIQUE INDEX uq_payment_one_success_per_order
    ON fetisov_food.payment (order_id)
    WHERE status = 'успех';

ALTER TABLE fetisov_food.order_structure
    ADD CONSTRAINT fk_order_structure_order
        FOREIGN KEY (order_id) REFERENCES fetisov_food."order" (order_id),
    ADD CONSTRAINT fk_order_structure_product
        FOREIGN KEY (product_id) REFERENCES fetisov_food.product (product_id),
    ADD CONSTRAINT ck_order_structure_quantity CHECK (quantity > 0);

ALTER TABLE fetisov_food.review
    ADD CONSTRAINT fk_review_client
        FOREIGN KEY (client_id) REFERENCES fetisov_food.client (client_id),
    ADD CONSTRAINT fk_review_order
        FOREIGN KEY (order_id) REFERENCES fetisov_food."order" (order_id),
    ADD CONSTRAINT uq_review_order_entity UNIQUE (order_id, entity_type, entity_id),
    ADD CONSTRAINT ck_review_description_nonempty
        CHECK (length(btrim(description)) > 0),
    ADD CONSTRAINT ck_review_rating CHECK (rating BETWEEN 1 AND 5);
