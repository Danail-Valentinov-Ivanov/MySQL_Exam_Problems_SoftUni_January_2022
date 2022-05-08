CREATE TABLE pictures(
id INT PRIMARY KEY AUTO_INCREMENT,
url VARCHAR(100) NOT NULL,
added_on DATETIME NOT NULL
);
CREATE TABLE categories(
id INT PRIMARY KEY AUTO_INCREMENT,
name VARCHAR(40) NOT NULL UNIQUE
);
CREATE TABLE towns(
id INT PRIMARY KEY AUTO_INCREMENT,
name VARCHAR(20) NOT NULL UNIQUE
);
CREATE TABLE products(
id INT PRIMARY KEY AUTO_INCREMENT, 
name VARCHAR(40) NOT NULL UNIQUE,
best_before DATE,
price DECIMAL(10, 2) NOT NULL,
description TEXT,
category_id INT NOT NULL,
picture_id INT NOT NULL,
CONSTRAINT fk_products_categories
FOREIGN KEY (category_id)
REFERENCES categories(id),
CONSTRAINT fk_products_pictures
FOREIGN KEY (picture_id)
REFERENCES pictures(id)
);
CREATE TABLE addresses(
id INT PRIMARY KEY AUTO_INCREMENT,
name VARCHAR(50) NOT NULL UNIQUE,
town_id INT NOT NULL,
CONSTRAINT fk_addresses_town
FOREIGN KEY (town_id)
REFERENCES towns(id)
);
CREATE TABLE stores(
id INT PRIMARY KEY AUTO_INCREMENT,
name VARCHAR(20) NOT NULL UNIQUE,
rating FLOAT NOT NULL,
has_parking BOOLEAN DEFAULT FALSE,
address_id INT NOT NULL,
CONSTRAINT fk_stores_addresses
FOREIGN KEY (address_id)
REFERENCES addresses(id)
);
CREATE TABLE products_stores(
product_id INT NOT NULL,
store_id INT NOT NULL,
CONSTRAINT fk_mapping_products
FOREIGN KEY (product_id)
REFERENCES products(id),
CONSTRAINT fk_mapping_stores
FOREIGN KEY (store_id)
REFERENCES stores(id),
CONSTRAINT pk_product_store
PRIMARY KEY (product_id, store_id)
);
CREATE TABLE employees(
id INT PRIMARY KEY AUTO_INCREMENT,
first_name VARCHAR(15) NOT NULL,
middle_name CHAR(1),
last_name VARCHAR(20) NOT NULL,
salary DECIMAL(19, 2) DEFAULT 0,
hire_date DATE NOT NULL,
manager_id INT,
store_id INT NOT NULL,
CONSTRAINT fk_employees_stores
FOREIGN KEY (store_id)
REFERENCES stores(id),
CONSTRAINT fk_employees_self_reference
FOREIGN KEY (manager_id)
REFERENCES employees(id)
);

-- s2
-- p2
SELECT p.id FROM products as p
LEFT JOIN products_stores as ps ON p.id = ps.product_id
WHERE ps.product_id IS NULL;

INSERT INTO products_stores(product_id, store_id)
VALUES
(9, 1),
(10, 1),
(13, 1),
(16, 1),
(18, 1);

-- p2 (second)
INSERT INTO products_stores(product_id, store_id)
(SELECT p.id, 1 FROM products as p
LEFT JOIN products_stores as ps ON p.id = ps.product_id
WHERE ps.product_id IS NULL);

-- p3
UPDATE employees as e
JOIN stores as s ON e.store_id = s.id
SET e.manager_id = 3, salary = salary - 500
WHERE year(e.hire_date) > 2003
AND s.name NOT IN('Cardguard', 'Veribet');

-- p4
DELETE FROM employees
WHERE salary >= 6000 AND manager_id IS NOT NULL;

-- s3
-- p5
SELECT first_name, middle_name, last_name, salary, hire_date FROM employees
ORDER BY hire_date DESC;

-- p6
SELECT pr.name as product_name, pr.price, pr.best_before, 
concat(left(pr.description, 10), '...') as short_description, url
FROM pictures as p
JOIN products as pr ON pr.picture_id = p.id
WHERE char_length(pr.description) > 100
AND year(p.added_on) < 2019
AND pr.price > 20
ORDER BY pr.price DESC;

-- p7
SELECT s.name, count(p.id) as product_count, round(avg(p.price), 2) as avg 
FROM stores as s
LEFT JOIN products_stores as ps ON s.id = ps.store_id
LEFT JOIN products as p ON ps.product_id = p.id
GROUP BY s.name
ORDER BY product_count DESC, avg DESC, s.id;

-- p8
SELECT concat(e.first_name, ' ', e.last_name) as Full_name, s.name as Store_name, a.name as Address, e.salary as Salary
FROM employees as e
JOIN stores as s ON e.store_id = s.id
JOIN addresses as a ON s.address_id = a.id
WHERE e.salary < 4000
AND char_length(s.name) > 8
AND e.last_name LIKE '%n'
AND a.name REGEXP '[5]';

-- p9
SELECT reverse(s.name) as reversed_name, concat(upper(t.name), '-', a.name) as full_address, 
count(e.id) as employees_count
FROM employees as e
JOIN stores as s ON e.store_id = s.id
JOIN addresses as a ON s.address_id = a.id
JOIN towns as t ON a.town_id = t.id
GROUP BY s.id
HAVING employees_count >= 1
ORDER BY full_address;

-- s4
-- p10
delimiter $$
CREATE FUNCTION udf_top_paid_employee_by_store(store_name VARCHAR(50))
RETURNS VARCHAR(200)
DETERMINISTIC
BEGIN
RETURN (SELECT concat(first_name, ' ', middle_name, '. ', last_name, ' works in store for ', 
timestampdiff(year, hire_date, '2020-10-18'), ' years') 
FROM employees
WHERE salary = (SELECT max(e.salary) FROM employees as e
JOIN stores as s ON e.store_id = s.id
GROUP BY s.name
HAVING s.name = store_name));
END $$
delimiter ;
SELECT udf_top_paid_employee_by_store('Stronghold');

-- p11
delimiter $$
CREATE PROCEDURE udp_update_product_price(address_name varchar(50))
BEGIN
DECLARE increase_value INT;
CASE
WHEN address_name LIKE '0%' 
THEN SET increase_value := 100;
ELSE SET increase_value := 200;
END CASE;
UPDATE products SET price = price + increase_value 
WHERE id IN (SELECT ps.product_id
FROM addresses as a
JOIN stores as s ON a.id = s.address_id
JOIN products_stores as ps ON s.id = ps.store_id
WHERE a.name = address_name);
END $$
delimiter ;
CALL udp_update_product_price('07 Armistice Parkway');
SELECT name, price FROM products WHERE id = 15;