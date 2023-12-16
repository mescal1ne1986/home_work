# Домашнее задание к занятию «SQL. Часть 1»
---

Задание можно выполнить как в любом IDE, так и в командной строке.

### Задание 1

Получите уникальные названия районов из таблицы с адресами, которые начинаются на “K” и заканчиваются на “a” и не содержат пробелов.

### Ответ 1
```sql
SELECT DISTINCT district 
FROM address
WHERE district LIKE 'K%a' AND district NOT LIKE '% %';
```
### Задание 2

Получите из таблицы платежей за прокат фильмов информацию по платежам, которые выполнялись в промежуток с 15 июня 2005 года по 18 июня 2005 года **включительно** и стоимость которых превышает 10.00.
### Ответ 2
```sql
SELECT amount, payment_date
FROM payment
WHERE CAST(payment_date AS DATE) BETWEEN 20050614 AND 20050618 AND amount > 10.00;
```
### Задание 3

Получите последние пять аренд фильмов.
### Ответ 3
```sql
SELECT rental_date from rental ORDER BY rental_id DESC 
LIMIT 5;
```
### Задание 4

Одним запросом получите активных покупателей, имена которых Kelly или Willie. 

Сформируйте вывод в результат таким образом:
- все буквы в фамилии и имени из верхнего регистра переведите в нижний регистр,
- замените буквы 'll' в именах на 'pp'.
### Ответ 4
```sql
SELECT LOWER(REPLACE(first_name, 'LL', 'PP')) AS Имя, LOWER(last_name) AS Фамилия
FROM customer
WHERE active = 1 AND (first_name LIKE 'Kelly' OR first_name LIKE 'Willie');
```
