WITH
    toStartOfMonth(today()) AS current_month,
    addMonths(current_month, -1) AS last_month_start,
    addMonths(current_month, -2) AS previous_month_start
SELECT
    p.brand_name_ax AS brand,
    /* Выручка за последний полный месяц */
    round(sumIf(
            s.qty * s.price,
            s.date >= last_month_start
            AND s.date < current_month
        ), 2
    ) AS revenue_last_month,
    /* Выручка за предыдущий полный месяц */
    round(sumIf(
            s.qty * s.price,
            s.date >= previous_month_start
            AND s.date < last_month_start
        ), 2
    ) AS revenue_previous_month,
    /* Абсолютное изменение выручки */
    round(sumIf(
            s.qty * s.price,
            s.date >= last_month_start
            AND s.date < current_month
        )
        -
        sumIf(
            s.qty * s.price,
            s.date >= previous_month_start
            AND s.date < last_month_start
        ), 2
    ) AS revenue_change_rub,
    /* Изменение выручки в процентах */
    round(100.0 *
        (sumIf(
            s.qty * s.price,
            s.date >= last_month_start
            and s.date < current_month
        )
        -
        sumIf(
            s.qty * s.price,
            s.date >= previous_month_start
            and s.date < last_month_start
        )
        )
        /
        nullIf(sumIf(
            s.qty * s.price,
            s.date >= previous_month_start
            and s.date < last_month_start
        ), 0 ), 2
    ) AS revenue_change_percent
FROM dwh.sales AS s
INNER JOIN dwh.products AS p ON s.itemid = p.itemid
WHERE s.date >= previous_month_start and s.date < current_month
GROUP BY p.brand_name_ax
HAVING revenue_last_month > 0
ORDER BY revenue_last_month DESC
LIMIT 5;