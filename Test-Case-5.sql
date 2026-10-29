WITH
    today() AS current_date,
    current_date - 60 AS start_date,
    daily_activity AS (SELECT toDate(timestamp) AS activity_date, user_id FROM dwh.site_activity GROUP BY activity_date, user_id),
    calendar AS (SELECT addDays(start_date, number) AS report_date FROM numbers(61))

SELECT
    c.report_date,
    addDays(c.report_date, -6) AS period_start,
    c.report_date AS period_end,
    uniqExactIf(
        a.user_id,
        a.activity_date >= addDays(c.report_date, -6)
        AND a.activity_date <= c.report_date
    ) AS wau
FROM calendar AS c
CROSS JOIN daily_activity AS a
GROUP BY c.report_date
ORDER BY c.report_date;