CREATE TABLE fetisov_food.client (
    client_id uuid PRIMARY KEY DEFAULT exts.uuid_generate_v4(),
    login varchar(64) NOT NULL,
    password varchar(32) NOT NULL,
    phone_number varchar(20) NOT NULL
);

CREATE TABLE fetisov_food.address (
    address_id uuid PRIMARY KEY DEFAULT exts.uuid_generate_v4(),
    street varchar(100) NOT NULL,
    house_number varchar(20) NOT NULL,
    apartment_office varchar(20)
);

CREATE TABLE fetisov_food.client_address (
    client_id uuid NOT NULL,
    address_id uuid NOT NULL,
    PRIMARY KEY (client_id, address_id)
);

CREATE TABLE fetisov_food.restaurant (
    restaurant_id uuid PRIMARY KEY DEFAULT exts.uuid_generate_v4(),
    restaurant_name varchar(100) NOT NULL,
    address_id uuid NOT NULL,
    description text NOT NULL,
    work_start time without time zone NOT NULL,
    work_end time without time zone NOT NULL,
    company_details text NOT NULL,
    rating numeric(3, 2),
    status fetisov_food.restaurant_status NOT NULL
);

CREATE TABLE fetisov_food.courier (
    courier_id uuid PRIMARY KEY DEFAULT exts.uuid_generate_v4(),
    fio varchar(150) NOT NULL,
    phone_number varchar(20) NOT NULL,
    status fetisov_food.courier_status NOT NULL,
    hire_date date NOT NULL,
    dismissal_date date,
    coefficient numeric(2, 1) NOT NULL DEFAULT 0.1
);

CREATE TABLE fetisov_food.courier_pay (
    year smallint NOT NULL,
    month smallint NOT NULL,
    courier_id uuid NOT NULL,
    amount numeric(12, 2) NOT NULL,
    coefficient_used numeric(2, 1) NOT NULL,
    PRIMARY KEY (year, month, courier_id)
);

CREATE TABLE fetisov_food.product_category (
    product_category_id uuid PRIMARY KEY DEFAULT exts.uuid_generate_v4(),
    product_category_name varchar(80) NOT NULL
);

CREATE TABLE fetisov_food.product (
    product_id uuid PRIMARY KEY DEFAULT exts.uuid_generate_v4(),
    product_name varchar(120) NOT NULL,
    product_category_id uuid NOT NULL,
    price numeric(12, 2) NOT NULL,
    restaurant_id uuid NOT NULL,
    photo_url text,
    rating numeric(3, 2),
    status fetisov_food.product_status NOT NULL,
    description text NOT NULL
);

CREATE TABLE fetisov_food."order" (
    order_id uuid PRIMARY KEY DEFAULT exts.uuid_generate_v4(),
    courier_id uuid NOT NULL,
    client_id uuid NOT NULL,
    address_id uuid NOT NULL,
    restaurant_id uuid NOT NULL,
    order_timestamp timestamp without time zone NOT NULL DEFAULT localtimestamp,
    delivery_timestamp timestamp without time zone,
    order_amount numeric(12, 2) NOT NULL,
    commission numeric(12, 2) NOT NULL,
    total_amount numeric(12, 2) NOT NULL,
    status fetisov_food.order_status NOT NULL,
    pay_status fetisov_food.order_pay_status NOT NULL DEFAULT 'ожидает',
    description text NOT NULL
);

CREATE TABLE fetisov_food.payment (
    payment_id uuid PRIMARY KEY DEFAULT exts.uuid_generate_v4(),
    order_id uuid NOT NULL,
    payment_type fetisov_food.payment_type NOT NULL,
    amount numeric(12, 2) NOT NULL,
    transaction_id varchar(100) NOT NULL,
    transaction_timestamp timestamp without time zone NOT NULL DEFAULT localtimestamp,
    status fetisov_food.payment_status NOT NULL
);

CREATE TABLE fetisov_food.order_structure (
    order_id uuid NOT NULL,
    product_id uuid NOT NULL,
    quantity numeric(10, 3) NOT NULL,
    PRIMARY KEY (order_id, product_id)
);

CREATE TABLE fetisov_food.review (
    review_id uuid PRIMARY KEY DEFAULT exts.uuid_generate_v4(),
    client_id uuid NOT NULL,
    review_timestamp timestamp without time zone NOT NULL DEFAULT localtimestamp,
    entity_id uuid NOT NULL,
    entity_type fetisov_food.review_entity_type NOT NULL,
    order_id uuid NOT NULL,
    description text NOT NULL,
    photo_url text,
    rating numeric(2, 1) NOT NULL
);
