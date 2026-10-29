SELECT 'products' AS table_name, COUNT() AS rows FROM dwh.products
UNION ALL
SELECT 'sales', COUNT() FROM dwh.sales
UNION ALL
SELECT 'stock', COUNT() FROM dwh.stock
UNION ALL
SELECT 'site_activity', COUNT() FROM dwh.site_activity;