USE SAKILA;

SELECT *
FROM film;

SELECT 
    title,
    length,
    RANK() OVER (ORDER BY length DESC) AS film_rank
FROM film
WHERE length IS NOT NULL
  AND length > 0;

SELECT 
    title,
    length,
    rating,
    RANK() OVER (PARTITION BY rating ORDER BY length DESC) AS film_rank
FROM film
WHERE length IS NOT NULL
  AND length > 0;

WITH actor_film_counts AS (
    SELECT
        fa.actor_id,
        COUNT(*) AS total_films
    FROM film_actor AS fa
    GROUP BY fa.actor_id
),
film_cast_ranked AS (
    SELECT
        f.film_id,
        f.title,
        CONCAT(a.first_name, ' ', a.last_name) AS actor_name,
        afc.total_films,
        ROW_NUMBER() OVER (
            PARTITION BY f.film_id
            ORDER BY afc.total_films DESC, a.actor_id) AS rn
    FROM film AS f
    JOIN film_actor AS fa 
    ON fa.film_id = f.film_id
    JOIN actor AS a 
    ON a.actor_id = fa.actor_id
    JOIN actor_film_counts AS afc 
    ON afc.actor_id = a.actor_id
)
SELECT
    title,
    actor_name,
    total_films
FROM film_cast_ranked
WHERE rn = 1
ORDER BY title;

SELECT
    DATE_FORMAT(rental_date, '%Y-%m') AS rental_month,
    COUNT(DISTINCT customer_id) AS active_customers
FROM rental
GROUP BY rental_month
ORDER BY rental_month;

WITH monthly_active AS (
    SELECT
        DATE_FORMAT(rental_date, '%Y-%m') AS rental_month,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM rental
    GROUP BY rental_month
)
SELECT
    rental_month,
    active_customers,
    LAG(active_customers) OVER (ORDER BY rental_month) AS previous_month_active
FROM monthly_active
ORDER BY rental_month;

WITH monthly_active AS (
    SELECT
        DATE_FORMAT(rental_date, '%Y-%m') AS rental_month,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM rental
    GROUP BY rental_month
),
monthly_with_lag AS (
    SELECT
        rental_month,
        active_customers,
        LAG(active_customers) OVER (ORDER BY rental_month) AS previous_month_active
    FROM monthly_active
)

SELECT
    rental_month,
    active_customers,
    previous_month_active,
    ROUND((active_customers - previous_month_active) / previous_month_active * 100, 2) AS percentage_change
FROM monthly_with_lag
ORDER BY rental_month;

WITH customer_month AS (
    SELECT DISTINCT
        customer_id,
        DATE_FORMAT(rental_date, '%Y-%m-01') AS month_start
    FROM rental
),
retained AS (
    SELECT
        curr.month_start,
        COUNT(DISTINCT curr.customer_id) AS retained_customers
    FROM customer_month AS curr
    JOIN customer_month AS prev
      ON prev.customer_id = curr.customer_id
     AND prev.month_start = DATE_SUB(curr.month_start, INTERVAL 1 MONTH)
    GROUP BY curr.month_start
)
SELECT
    DATE_FORMAT(month_start, '%Y-%m') AS rental_month,
    retained_customers
FROM retained
ORDER BY month_start;
