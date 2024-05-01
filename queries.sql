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
        FLOOR(SUM(s.quantity * p.price)) AS income
    FROM employees e
    INNER JOIN sales s ON e.employee_id = s.sales_person_id
    INNER JOIN products p USING (product_id)
    GROUP BY 1, 2, 3
    ORDER BY 3, 1) AS foo;

-- Количество покупателей в разных возрастных группах
SELECT
    CASE
        WHEN age >= 16 AND age <= 25 THEN '16-25'
        WHEN age > 25 AND age <= 40 THEN '26-40'
        WHEN age > 40 THEN '40+'
        ELSE 'not_age'
    END AS age_category,
    COUNT(age)
FROM customers
GROUP BY 1
ORDER BY 1;

-- Количеству уникальных покупателей и выручка
SELECT
    TO_CHAR(s.sale_date, 'YYYY-MM') AS date,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    FLOOR(SUM(s.quantity * p.price)) AS income
FROM sales s
INNER JOIN products p USING (product_id)
GROUP BY 1;

-- Покупатели, первая покупка которых была в ходе проведения акций (акционные товары отпускали со стоимостью равной 0)
WITH sale_purchases AS (SELECT s.sale_date,
                               s.sales_person_id,
                               CONCAT(e.first_name, ' ', e.last_name) AS seller,
                               s.customer_id,
                               CONCAT(c.first_name, ' ', c.last_name) AS customer,
                               s.sales_id,
                               s.product_id,
                               p.price
                        FROM sales s
                                 INNER JOIN products p USING (product_id)
                                 INNER JOIN employees e
                                            ON s.sales_person_id = e.employee_id
                                 INNER JOIN customers c USING (customer_id)
                        WHERE price = 0
                        ORDER BY s.customer_id)
SELECT
    customer,
    sale_date,
    seller
FROM sale_purchases
GROUP BY 1, 2, 3;
