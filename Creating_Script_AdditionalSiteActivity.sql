INSERT INTO dwh.site_activity
WITH
    today() AS current_date,
    addDays(current_date, -60) AS start_date,
    (SELECT max(action_id) FROM dwh.site_activity) AS max_action_id
SELECT
    toUInt64(max_action_id + days.number * 1000 + users.number + 1) AS action_id,
    toDateTime(
        addDays(start_date, toInt32(days.number))
    ) + toIntervalSecond(
        toInt64(
            modulo(users.number * 713 + days.number * 197, 86400)
        )
    ) AS timestamp,
    toUInt64(200000 + users.number) AS user_id,
    multiIf(
        modulo(users.number * 3 + days.number * 7, 100) < 8,
        'purchase',
        modulo(users.number * 5 + days.number * 11, 100) < 30,
        'add_to_cart',
        'view_product'
    ) AS action,
    concat('/product/', toString(1001 + modulo(users.number + days.number, 12))
    ) AS item_url
FROM numbers(61) AS days
CROSS JOIN numbers(500) AS users
WHERE 
modulo(users.number * 13 + days.number * 7+ days.number * days.number * 3, 100)
<
(multiIf(modulo(users.number, 10) < 2, 85, modulo(users.number, 10) < 6, 45, 15)
+
multiIf(modulo(days.number, 7) IN (1, 2), 10, modulo(days.number, 7) = 0, -10, 0));