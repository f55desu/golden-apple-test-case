WITH
    toStartOfMonth(today()) AS current_month,
    addMonths(current_month, -1) AS last_month_start,
    addMonths(current_month, -2) AS two_months_ago,
    addMonths(current_month, -3) AS three_months_ago
SELECT
    p.itemid AS itemid,
    p.name_ax AS product_name,
    p.brand_name_ax AS brand,
    p.category AS category,
    -- Продажи за последний полный месяц, шт.
    sumIf(
        s.qty,
        s.date >= last_month_start
        AND s.date < current_month
    ) AS sales_qty_last_month,
    -- Продажи за последний полный месяц, руб.
    round(
        sumIf(
            s.qty * s.price,
            s.date >= last_month_start
            AND s.date < current_month
        ), 2
    ) AS sales_rub_last_month,
    -- Средневзвешенная цена единицы товара
    round((
        sumIf(
            s.qty * s.price,
            s.date >= last_month_start
            AND s.date < current_month
        )
        /
        nullIf(
            sumIf(
                s.qty,
                s.date >= last_month_start
                and s.date < current_month
            ), 0
        )), 2
    ) AS avg_price_last_month,
    -- Средний месячный объём продаж за 3 месяца, шт.
    round(
        sumIf(
            s.qty,
            s.date >= three_months_ago
            and s.date < current_month
        ) / 3.0, 2
    ) AS avg_sales_qty_3_months,
    -- Остаток на текущую дату минус средние продажи
    toInt64(
        coalesce(stk.qty, 0)
    )
    -
    toInt64(
        round(
            sumIf(
                s.qty,
                s.date >= three_months_ago
                and s.date < current_month
            ) / 3.0
        )
    ) AS stock_minus_avg_sales
FROM dwh.products AS p
INNER JOIN dwh.sales AS s ON p.itemid = s.itemid
LEFT JOIN dwh.stock AS stk ON p.itemid = stk.itemid and stk.date = today()
GROUP BY
    p.itemid,
    p.name_ax,
    p.brand_name_ax,
    p.category,
    stk.qty
-- Оставляем товары, продававшиеся в последнем полном месяце
HAVING sales_qty_last_month > 0
ORDER BY sales_rub_last_month DESC;