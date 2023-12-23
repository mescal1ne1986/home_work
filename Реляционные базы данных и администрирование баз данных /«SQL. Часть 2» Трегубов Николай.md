# Домашнее задание к занятию «SQL. Часть 2»
---

Задание можно выполнить как в любом IDE, так и в командной строке.

### Задание 1

Одним запросом получите информацию о магазине, в котором обслуживается более 300 покупателей, и выведите в результат следующую информацию: 
- фамилия и имя сотрудника из этого магазина;
- город нахождения магазина;
- количество пользователей, закреплённых в этом магазине.
### Ответ 1
```sql
SELECT CONCAT(s.last_name, ' ', s.first_name) AS staff, c.city, COUNT(c2.store_id) AS custumers
FROM customer c2
INNER JOIN store s2 ON s2.store_id = c2.store_id
INNER JOIN staff s ON s.staff_id = s2.manager_staff_id 
INNER JOIN address a ON s.address_id = a.address_id
INNER JOIN city c ON c.city_id = a.city_id
GROUP BY c2.store_id
HAVING COUNT(c2.store_id) > 300;
```
### Задание 2

Получите количество фильмов, продолжительность которых больше средней продолжительности всех фильмов.

### Ответ 2
```sql
SELECT COUNT(f.title) 
FROM film f
WHERE f.`length` > (SELECT AVG(`length`) FROM film)
```
### Задание 3
Получите информацию, за какой месяц была получена наибольшая сумма платежей, и добавьте информацию по количеству аренд за этот месяц.


### Ответ 3
```sql
SELECT MONTH(payment_date), SUM(p.amount), COUNT(p.rental_id) 
FROM payment p
GROUP BY MONTH(payment_date)
ORDER BY SUM(p.amount ) DESC
LIMIT 1;

ну или по годам и месяцам (хотя резултат один и тот же

SELECT DATE_FORMAT(payment.payment_date, '%Y-%m') AS current_month, COUNT(rental.rental_id) AS rental_count
FROM payment
JOIN rental ON payment.rental_id = rental.rental_id
GROUP BY current_month
ORDER BY SUM(payment.amount) DESC
LIMIT 1;
```
### Задание 4
Посчитайте количество продаж, выполненных каждым продавцом. Добавьте вычисляемую колонку «Премия». Если количество продаж превышает 8000, то значение в колонке будет «Да», иначе должно быть значение «Нет».


### Ответ 4
```sql
SELECT f.title AS 'Bad product'
FROM film f
LEFT JOIN inventory i ON f.film_id = i.film_id
LEFT JOIN rental r ON i.inventory_id = r.inventory_id
WHERE r.inventory_id IS NULL;
