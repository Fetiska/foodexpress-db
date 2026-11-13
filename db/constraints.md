# ограничения

## типы enum

| тип | значения | правило |
|---|---|---|
| `restaurant_status` | `активен`, `неактивен` | BR-4.3 |
| `product_status` | `доступно`, `нет_в_наличии`, `архив` | BR-5.5 |
| `courier_status` | `свободен`, `занят`, `на_доставке`, `уволен` | BR-6.2 |
| `order_status` | `создан`, `готовится`, `в_доставке`, `доставлен`, `отменён` | BR-7.7 |
| `order_pay_status` | `ожидает`, `оплачен`, `ошибка` | BR-7.9 |
| `payment_status` | `успех`, `ошибка`, `в_обработке` | BR-8.2 |
| `payment_type` | `карта`, `наличные`, `безнал` | BR-8.2 |
| `review_entity_type` | `блюдо`, `ресторан`, `заказ` | BR-9.1 |

## первичные ключи

| таблица | ключ |
|---|---|
| `client` | `client_id` |
| `address` | `address_id` |
| `client_address` | (`client_id`, `address_id`) |
| `restaurant` | `restaurant_id` |
| `courier` | `courier_id` |
| `courier_pay` | (`year`, `month`, `courier_id`) |
| `product_category` | `product_category_id` |
| `product` | `product_id` |
| `"order"` | `order_id` |
| `payment` | `payment_id` |
| `order_structure` | (`order_id`, `product_id`) |
| `review` | `review_id` |

## ограничения check

| таблица | ограничение | правило | обоснование |
|---|---|---|---|
| `client` | `ck_client_login_nonempty` | BR-2.1, BR-11.3 | зарегистрированному клиенту нужен непустой логин |
| `client` | `ck_client_password_md5` | BR-2.3 | пароль хранится как 32-символьный MD5-хеш |
| `client` | `ck_client_phone_nonempty` | BR-2.1, BR-11.3 | зарегистрированному клиенту нужен непустой телефон |
| `address` | `ck_address_street_nonempty` | BR-3.1, BR-11.3 | у физического адреса должна быть улица |
| `address` | `ck_address_house_nonempty` | BR-3.1, BR-11.3 | у физического адреса должен быть номер дома |
| `address` | `ck_address_apartment_nonempty` | BR-3.2, BR-11.3 | если указан офис или квартира, значение не может быть пустым |
| `restaurant` | `ck_restaurant_name_nonempty` | BR-4.1, BR-11.3 | у ресторана должно быть название |
| `restaurant` | `ck_restaurant_description_nonempty` | BR-4.1, BR-11.3 | у ресторана должно быть описание |
| `restaurant` | `ck_restaurant_details_nonempty` | BR-4.1, BR-4.5 | юридические реквизиты хранятся в обязательном поле |
| `restaurant` | `ck_restaurant_rating` | BR-4.2 | указанный рейтинг должен быть от 0 до 5 |
| `restaurant` | `ck_restaurant_work_hours` | BR-4.4 | время закрытия должно быть позже времени открытия |
| `courier` | `ck_courier_fio_nonempty` | BR-6.1, BR-11.3 | у курьера должно быть ФИО |
| `courier` | `ck_courier_phone_nonempty` | BR-6.1, BR-11.3 | у курьера должен быть телефон |
| `courier` | `ck_courier_coefficient` | BR-6.4 | коэффициент должен быть от 0.1 до 0.5 |
| `courier` | `ck_courier_dismissal_required` | BR-6.3 | уволенному курьеру нужна дата увольнения |
| `courier` | `ck_courier_dismissal_after_hire` | BR-6.1 | дата увольнения не может быть раньше даты найма |
| `courier_pay` | `ck_courier_pay_month` | BR-10.2 | номер календарного месяца должен быть от 1 до 12 |
| `courier_pay` | `ck_courier_pay_amount` | BR-10.4 | зарплата курьера не может быть отрицательной |
| `courier_pay` | `ck_courier_pay_coefficient` | BR-6.4, BR-10.2 | применённый коэффициент должен быть от 0.1 до 0.5 |
| `product_category` | `ck_product_category_name_nonempty` | BR-5.7, BR-11.3 | у категории должно быть название |
| `product` | `ck_product_name_nonempty` | BR-5.2, BR-11.3 | у блюда должно быть название |
| `product` | `ck_product_description_nonempty` | BR-5.2, BR-11.3 | у блюда должно быть описание |
| `product` | `ck_product_price` | BR-5.3 | цена блюда не может быть отрицательной |
| `product` | `ck_product_rating` | BR-5.4 | указанный рейтинг должен быть от 0 до 5 |
| `"order"` | `ck_order_description_nonempty` | BR-7.1, BR-11.3 | у заказа должно быть значение описания |
| `"order"` | `ck_order_amount` | BR-7.10 | сумма блюд не может быть отрицательной |
| `"order"` | `ck_order_commission` | BR-1.4, BR-7.10 | комиссия равна 10% суммы блюд с округлением до копеек |
| `"order"` | `ck_order_total` | BR-7.10 | общая сумма равна сумме блюд плюс комиссия |
| `"order"` | `ck_order_minimum_total` | BR-1.8 | общая сумма заказа должна быть не меньше 1000 ₽ |
| `"order"` | `ck_order_delivery_after_order` | BR-7.13 | доставка не может завершиться раньше создания заказа |
| `"order"` | `ck_delivered_order_has_delivery_time` | BR-7.12 | у доставленного заказа должно быть время доставки |
| `payment` | `ck_payment_amount` | BR-1.8, BR-8.4 | сумма попытки должна быть положительной и равняться сумме заказа, что проверяет триггер |
| `payment` | `ck_payment_transaction_nonempty` | BR-8.2, BR-8.3 | у каждой попытки должен быть внешний идентификатор транзакции |
| `order_structure` | `ck_order_structure_quantity` | BR-7.15 | количество заказанного блюда должно быть положительным |
| `review` | `ck_review_description_nonempty` | BR-9.3, BR-11.3 | у отзыва должен быть текст |
| `review` | `ck_review_rating` | BR-9.4 | рейтинг отзыва должен быть от 1 до 5 |

## ограничения unique и индексы

| таблица | ограничение или индекс | правило | обоснование |
|---|---|---|---|
| `client` | `uq_client_login` | BR-2.2 | логин клиента уникален |
| `client` | `uq_client_phone` | BR-2.2 | телефон клиента уникален |
| `address` | `uq_address_physical` | BR-3.3, BR-3.4 | один физический адрес хранится один раз, а NULL в квартире или офисе считается адресом без помещения |
| `restaurant` | `uq_restaurant_address` | BR-3.3 | у двух ресторанов не может быть одного адреса |
| `payment` | `uq_payment_transaction` | BR-8.3 | идентификаторы транзакций уникальны |
| `payment` | `uq_payment_one_success_per_order` при `status = 'успех'` | BR-8.1, BR-8.7 | у заказа не может быть больше одной успешной попытки |
| `review` | `uq_review_order_entity` | BR-9.5 | клиент может оставить не более одного отзыва на каждый объект в рамках заказа |
| `client_address` | первичный ключ (`client_id`, `address_id`) | BR-2.5 | адрес связывается с одним клиентом не более одного раза |
| `order_structure` | первичный ключ (`order_id`, `product_id`) | BR-7.16 | одно блюдо встречается в заказе только один раз |
| `courier_pay` | первичный ключ (`year`, `month`, `courier_id`) | BR-10.3 | на курьера и месяц приходится одна запись о выплате |

## внешние ключи

| таблица | столбцы | цель | правило | обоснование |
|---|---|---|---|---|
| `client_address` | `client_id` | `client(client_id)` | BR-2.4 | каждая связь адреса относится к клиенту |
| `client_address` | `address_id` | `address(address_id)` | BR-2.4 | каждая связь клиента относится к адресу |
| `restaurant` | `address_id` | `address(address_id)` | BR-3.3 | у каждого ресторана есть адрес |
| `courier_pay` | `courier_id` | `courier(courier_id)` | BR-10.2 | каждая выплата относится к курьеру |
| `product` | `product_category_id` | `product_category(product_category_id)` | BR-5.1 | у каждого блюда есть категория |
| `product` | `restaurant_id` | `restaurant(restaurant_id)` | BR-5.1 | каждое блюдо принадлежит ресторану |
| `"order"` | `courier_id` | `courier(courier_id)` | BR-7.5 | за заказ отвечает назначенный курьер |
| `"order"` | `client_id` | `client(client_id)` | BR-7.1, BR-7.2 | у заказа есть оформивший его клиент |
| `"order"` | `address_id` | `address(address_id)` | BR-7.4 | у заказа есть адрес доставки |
| `"order"` | `restaurant_id` | `restaurant(restaurant_id)` | BR-7.2 | у заказа есть один ресторан |
| `"order"` | (`client_id`, `address_id`) | `client_address(client_id, address_id)` | BR-7.4 | адрес доставки принадлежит клиенту, оформившему заказ |
| `payment` | `order_id` | `"order"(order_id)` | BR-8.1 | каждая попытка оплаты относится к заказу |
| `order_structure` | `order_id` | `"order"(order_id)` | BR-7.14 | каждая позиция относится к заказу |
| `order_structure` | `product_id` | `product(product_id)` | BR-7.14 | каждая позиция ссылается на существующее блюдо |
| `review` | `client_id` | `client(client_id)` | BR-9.2 | у каждого отзыва есть клиент |
| `review` | `order_id` | `"order"(order_id)` | BR-9.2 | каждый отзыв связан с заказом |

## смысл попыток оплаты

- BR-8.1 ограничивает число успешных попыток одной на заказ, но не ограничивает число неуспешных попыток
- неуспешная или обрабатываемая попытка может существовать вместе с успешной
- по BR-8.7 статусы оплаты заказа работают так: `оплачен` означает, что есть успешная попытка, `ожидает` означает, что есть обрабатываемая попытка и нет успешной, `ошибка` означает, что все попытки завершились ошибкой
- FOOD-102 требует одинаковое число строк в заказах и платежах, поэтому генератор создаёт по одной успешной попытке на заказ, а дополнительные неуспешные попытки проверяются отдельно

## бизнес-правила, которые проверяют триггеры

- `validate_order_structure_restaurant` проверяет, что блюдо принадлежит ресторану заказа
- `validate_order_restaurant_update` и `validate_product_restaurant_update` сохраняют это правило при изменении ресторана у заказа или блюда
- `ensure_order_has_items` проверяет в конце транзакции, что в каждом заказе есть хотя бы одна позиция
- `validate_review_target` проверяет, что отзыв оставил клиент заказа, а цель отзыва является самим заказом, его рестораном или одним из его блюд
- у пары `review.entity_type` и `review.entity_id` нет единственной цели внешнего ключа, поэтому триггер проверяет цель для каждого типа
- `validate_order_structure_review_integrity` запрещает менять позицию заказа так, чтобы существующий отзыв на блюдо потерял связь с заказанным блюдом
- `validate_payment_amount` проверяет сумму каждой попытки, а `validate_order_payment_amounts` сохраняет это равенство при изменении общей суммы заказа
- `sync_order_pay_status` рассчитывает статус оплаты заказа по его попыткам согласно BR-8.7
- `rating_change` пересчитывает средние рейтинги блюд и ресторанов после каждой вставки, правки или удаления отзыва

## поля, допускающие NULL

| таблица | поле | правило | обоснование |
|---|---|---|---|
| `address` | `apartment_office` | BR-3.2 | в некоторых адресах нет квартиры или офиса |
| `restaurant` | `rating` | BR-4.2, BR-9.6 | до первого отзыва средний рейтинг отсутствует |
| `courier` | `dismissal_date` | BR-6.3 | у работающего курьера может не быть даты увольнения |
| `product` | `photo_url` | BR-5.6 | фотография блюда необязательна |
| `product` | `rating` | BR-5.4, BR-9.6 | до первого отзыва средний рейтинг отсутствует |
| `"order"` | `delivery_timestamp` | BR-7.12 | до завершения доставки время доставки отсутствует |
| `review` | `photo_url` | BR-9.3 | фотография отзыва необязательна |

## значения по умолчанию

| таблица | поле | значение по умолчанию | правило |
|---|---|---|---|
| все сущности с UUID | поле ID | `exts.uuid_generate_v4()` | BR-11.1 |
| `courier` | `coefficient` | `0.1` | BR-6.5 |
| `"order"` | `order_timestamp` | `localtimestamp` | BR-7.1, BR-11.2 |
| `"order"` | `pay_status` | `ожидает` | BR-7.9 |
| `payment` | `transaction_timestamp` | `localtimestamp` | BR-8.2, BR-11.2 |
| `review` | `review_timestamp` | `localtimestamp` | BR-9.3, BR-11.2 |

## нормализация

- модель содержит 12 таблиц из ERD и не добавляет лишних сущностей
- адреса клиентов и ресторанов хранятся один раз, а `client_address` задаёт связь многие-ко-многим для клиента
- `product_category`, `payment`, `order_structure` и `courier_pay` отделяют независимые факты и повторяющиеся группы
- неключевые поля в таблицах связей и выплат зависят от полного первичного ключа, транзитивных зависимостей между неключевыми полями нет
- сумма блюд, комиссия и общая сумма заказа хранятся как числовые поля для контракта бэкенда, а проверки поддерживают равенство формул
- рейтинги блюд и ресторанов хранятся как кэшируемые агрегаты из ERD, их обновляет `rating_change`
- `order.pay_status` хранится как кэшируемый агрегат из ERD и рассчитывается по попыткам оплаты
- пара `review.entity_type` и `review.entity_id` хранит три типа целей отзыва в одной таблице и проверяется триггером
- зарезервированное имя таблицы `order` сохранено в кавычках как `"order"`
