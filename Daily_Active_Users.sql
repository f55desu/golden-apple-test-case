SELECT toDate(timestamp) AS activity_date, uniqExact(user_id) AS daily_active_users
FROM dwh.site_activity
GROUP BY activity_date
ORDER BY daily_active_users ASC, activity_date;