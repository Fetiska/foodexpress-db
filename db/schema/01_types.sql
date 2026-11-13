CREATE TYPE fetisov_food.restaurant_status AS ENUM (
    'активен',
    'неактивен'
);

CREATE TYPE fetisov_food.product_status AS ENUM (
    'доступно',
    'нет_в_наличии',
    'архив'
);

CREATE TYPE fetisov_food.courier_status AS ENUM (
    'свободен',
    'занят',
    'на_доставке',
    'уволен'
);

CREATE TYPE fetisov_food.order_status AS ENUM (
    'создан',
    'готовится',
    'в_доставке',
    'доставлен',
    'отменён'
);

CREATE TYPE fetisov_food.order_pay_status AS ENUM (
    'ожидает',
    'оплачен',
    'ошибка'
);

CREATE TYPE fetisov_food.payment_status AS ENUM (
    'успех',
    'ошибка',
    'в_обработке'
);

CREATE TYPE fetisov_food.payment_type AS ENUM (
    'карта',
    'наличные',
    'безнал'
);

CREATE TYPE fetisov_food.review_entity_type AS ENUM (
    'блюдо',
    'ресторан',
    'заказ'
);
