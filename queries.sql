-- Считаем общее количество пользователей
SELECT count(*) AS customers_count FROM customers;

-- Десятка лучших продавцов
SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    COUNT(s.sales_id) AS operations,
    SUM(FLOOR(p.price * s.quantity)) AS income
FROM employees e
         INNER JOIN sales s ON e.employee_id = s.sales_person_id
         INNER JOIN products p USING (product_id)
GROUP BY e.employee_id
ORDER BY SUM(p.price * s.quantity) DESC
LIMIT 10;

-- Продавцы по средней выручке
WITH averages AS (
    SELECT
        DISTINCT CONCAT(e.first_name, ' ', e.last_name) AS seller,
        AVG(p.price * s.quantity) OVER (PARTITION BY CONCAT(e.first_name, ' ', e.last_name)) AS average_income,
        AVG(p.price * s.quantity) OVER () AS overall_average_income
    FROM employees e
    INNER JOIN sales s ON e.employee_id = s.sales_person_id
    INNER JOIN products p USING (product_id)
    ORDER BY 2
)
SELECT
    seller,
    FLOOR(average_income) AS average_income
FROM averages
WHERE
    average_income < overall_average_income
ORDER BY 2;

-- Выручка по дням недели
SELECT seller, day_of_week, income
FROM (
    SELECT
        CONCAT(e.first_name, ' ', e.last_name) AS seller,
        TO_CHAR(s.sale_date, 'Day') AS day_of_week,
        EXTRACT(ISODOW FROM s.sale_date) AS number_day,
        SUM(FLOOR(s.quantity * p.price)) AS income
    FROM employees e
    INNER JOIN sales s ON e.employee_id = s.sales_person_id
    INNER JOIN products p USING (product_id)
    GROUP BY 1, 2, 3
    ORDER BY 3, 1) AS foo;
