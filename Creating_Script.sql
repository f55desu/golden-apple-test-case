-- Учебные таблицы для заданий 4 и 5

CREATE DATABASE IF NOT EXISTS dwh;

DROP TABLE IF EXISTS dwh.products;
DROP TABLE IF EXISTS dwh.sales;
DROP TABLE IF EXISTS dwh.stock;
DROP TABLE IF EXISTS dwh.site_activity;

-- 1. Справочник товаров
CREATE TABLE dwh.products
(
    itemid UInt64,
    name_ax String,
    brand_name_ax String,
    category String
)
ENGINE = MergeTree
ORDER BY itemid;

INSERT INTO dwh.products VALUES
(1001, 'Clarins Double Serum 30 мл', 'Clarins', 'Уход'),
(1002, 'Clarins Lip Comfort Oil', 'Clarins', 'Макияж'),
(1003, 'Shiseido Ultimune 30 мл', 'Shiseido', 'Уход'),
(1004, 'Shiseido Synchro Skin Foundation', 'Shiseido', 'Макияж'),
(1005, 'Clinique Moisture Surge 50 мл', 'Clinique', 'Уход'),
(1006, 'Clinique High Impact Mascara', 'Clinique', 'Макияж'),
(1007, 'Estee Lauder Advanced Night Repair', 'Estee Lauder', 'Уход'),
(1008, 'Estee Lauder Double Wear Foundation', 'Estee Lauder', 'Макияж'),
(1009, 'Sisley Black Rose Cream Mask', 'Sisley', 'Уход'),
(1010, 'Sisley Phyto Rouge Lipstick', 'Sisley', 'Макияж'),
(1011, 'Payot Pate Grise Gel', 'Payot', 'Уход'),
(1012, 'BABOR Cleansing Foam', 'BABOR', 'Уход');

-- 2. Продажи.
-- Период: 150 дней до начала текущего месяца.
-- Поэтому в данных всегда есть последний полный месяц.
CREATE TABLE dwh.sales
(
    sale_id UInt64,
    date Date,
    itemid UInt64,
    qty UInt16,
    price Decimal(18, 2)
)
ENGINE = MergeTree
ORDER BY (date, itemid, sale_id);

INSERT INTO dwh.sales
WITH
    toStartOfMonth(today()) AS current_month,
    addDays(current_month, -150) AS start_date
SELECT
    toUInt64(days.number * 10000 + p.itemid) AS sale_id,
    addDays(start_date, toInt32(days.number)) AS date,
    p.itemid,
    toUInt16(
        1 + modulo(days.number * 7 + p.itemid * 3, 4)
    ) AS qty,
    toDecimal64(
        round(
            (250 + (p.itemid - 1000) * 350)
            * if(
                modulo(days.number + p.itemid, 17) < 4,
                0.80,
                1.00
            ), 2
        ), 2
    ) AS price
FROM numbers(150) AS days
CROSS JOIN dwh.products AS p;

-- 3. Остатки.
-- Есть ежедневные остатки, включая остатки на текущую дату.
CREATE TABLE dwh.stock
(
    date Date,
    itemid UInt64,
    qty UInt32
)
ENGINE = MergeTree
ORDER BY (date, itemid);

INSERT INTO dwh.stock
SELECT
    addDays(today(), -150 + toInt32(days.number)) AS date,
    p.itemid,
    toUInt32(
        20 + modulo(days.number * 11 + p.itemid * 19, 80)
    ) AS qty
FROM numbers(151) AS days
CROSS JOIN dwh.products AS p;

-- 4. Активность пользователей на сайте.
-- 61 день данных: WAU можно рассчитывать в скользящем окне 7 дней.
CREATE TABLE dwh.site_activity
(
    action_id UInt64,
    timestamp DateTime,
    user_id UInt64,
    action String,
    item_url String
)
ENGINE = MergeTree
ORDER BY (timestamp, user_id, action_id);

INSERT INTO dwh.site_activity
WITH addDays(today(), -60) AS start_date
SELECT
    toUInt64(days.number * 100000 + users.number + 1) AS action_id,
    toDateTime(addDays(start_date, toInt32(days.number))) + toIntervalSecond(
        toInt64(modulo(users.number * 713 + days.number * 197, 86400))
    ) AS timestamp,
    toUInt64(100000 + modulo(users.number, 160)) AS user_id,
    multiIf(
        modulo(users.number + days.number, 15) = 0, 'purchase',
        modulo(users.number + days.number, 5) = 0, 'add_to_cart',
        'view_product'
    ) AS action,
    concat(
        '/product/',
        toString(1001 + modulo(users.number + days.number, 12))
    ) AS item_url
FROM numbers(61) AS days
CROSS JOIN numbers(260) AS users
WHERE modulo(days.number * 11 + users.number * 3, 7) != 0;