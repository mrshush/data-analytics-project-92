-- Считаем общее количество пользователей
SELECT count(*) AS customers_count FROM customers;

-- Десятка лучших продавцов:
-- суммарная выручка с проданных товаров и количестве проведенных сделок
SELECT
    e.first_name || ' ' || e.last_name AS seller,
    count(s.sales_id) AS operations,
    floor(sum(p.price * s.quantity)) AS income
FROM employees AS e
         INNER JOIN sales AS s ON e.employee_id = s.sales_person_id
         INNER JOIN products AS p USING (product_id)
GROUP BY e.employee_id
ORDER BY sum(p.price * s.quantity) DESC
LIMIT 10;

-- Продавцы по средней выручке:
-- чья средняя выручка за сделку меньше средней выручки за сделку по всем продавцам
WITH averages AS (
    SELECT DISTINCT
        e.first_name || ' ' || e.last_name AS seller,
        AVG(p.price * s.quantity)
        OVER (PARTITION BY e.first_name || ' ' || e.last_name)
                                           AS average_income,
        AVG(p.price * s.quantity) OVER () AS overall_average_income
    FROM employees AS e
             INNER JOIN sales AS s ON e.employee_id = s.sales_person_id
             INNER JOIN products AS p USING (product_id)
    ORDER BY 2
)

SELECT
    seller,
    FLOOR(average_income) AS average_income
FROM averages
WHERE
    average_income < overall_average_income
ORDER BY 2;

-- Выручка по дням недели:
-- каждая запись содержит имя и фамилию продавца, день недели и суммарную выручку
SELECT
    seller,
    day_of_week,
    income
FROM (
    SELECT
     e.first_name || ' ' || e.last_name AS seller,
     TO_CHAR(s.sale_date, 'day') AS day_of_week,
     EXTRACT(ISODOW FROM s.sale_date) AS number_day,
     FLOOR(SUM(s.quantity * p.price)) AS income
    FROM employees AS e
          INNER JOIN sales AS s ON e.employee_id = s.sales_person_id
          INNER JOIN products AS p USING (product_id)
    GROUP BY 1, 2, 3
    ORDER BY 3, 1
     ) AS foo;

-- Количество покупателей в разных возрастных группах:
-- 16-25, 26-40 и 40+
SELECT
    CASE
        WHEN age >= 16 AND age <= 25 THEN '16-25'
        WHEN age > 25 AND age <= 40 THEN '26-40'
        WHEN age > 40 THEN '40+'
        ELSE 'not_age'
        END AS age_category,
    COUNT(age) AS ages
FROM customers
GROUP BY 1
ORDER BY 1;

-- Количеству уникальных покупателей и выручка по месяцам:
-- данные по количеству уникальных покупателей и выручке, которую они принесли
SELECT
    TO_CHAR(s.sale_date, 'YYYY-MM') AS sale_date,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    FLOOR(SUM(s.quantity * p.price)) AS income
FROM sales AS s
         INNER JOIN products AS p ON s.product_id = p.product_id
GROUP BY 1;

-- Покупатели по акции:
-- первая покупка которых была в ходе проведения акций (акционные товары отпускали со стоимостью равной 0)
WITH sale_purchases AS (
    SELECT
        s.sale_date,
        s.sales_person_id,
        s.customer_id,
        s.sales_id,
        s.product_id,
        p.price,
        ROW_NUMBER() OVER (PARTITION BY c.customer_id) AS sale_number,
        e.first_name || ' ' || e.last_name AS seller,
        c.first_name || ' ' || c.last_name AS customer
    FROM sales AS s
             INNER JOIN products AS p ON s.product_id = p.product_id
             INNER JOIN employees AS e
                        ON s.sales_person_id = e.employee_id
             INNER JOIN customers AS c USING (customer_id)
    WHERE price = 0
    ORDER BY s.customer_id
)

SELECT DISTINCT ON (customer)
    customer,
    sale_date,
    seller
FROM sale_purchases;