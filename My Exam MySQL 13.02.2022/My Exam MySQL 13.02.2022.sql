CREATE TABLE brands(
id INT PRIMARY KEY AUTO_INCREMENT,
name VARCHAR(40) NOT NULL UNIQUE
);
CREATE TABLE categories(
id INT PRIMARY KEY AUTO_INCREMENT,
name VARCHAR(40) NOT NULL UNIQUE
);
CREATE TABLE reviews(
id INT PRIMARY KEY AUTO_INCREMENT,
content TEXT,
rating DECIMAL(10, 2) NOT NULL,
picture_url VARCHAR(80) NOT NULL,
published_at DATETIME NOT NULL
);
CREATE TABLE products(
id INT PRIMARY KEY AUTO_INCREMENT,
name VARCHAR(40) NOT NULL,
price DECIMAL(19, 2) NOT NULL,
quantity_in_stock INT,
description TEXT,
brand_id INT NOT NULL,
category_id INT NOT NULL,
review_id INT,
CONSTRAINT fk_products_categories
FOREIGN KEY (category_id)
REFERENCES categories(id),
CONSTRAINT fk_products_brands
FOREIGN KEY (brand_id)
REFERENCES brands(id),
CONSTRAINT fk_products_reviews
FOREIGN KEY (review_id)
REFERENCES reviews(id)
);
CREATE TABLE customers(
id INT PRIMARY KEY AUTO_INCREMENT,
first_name VARCHAR(20) NOT NULL,
last_name VARCHAR(20) NOT NULL,
phone VARCHAR(30) NOT NULL UNIQUE,
address VARCHAR(60) NOT NULL,
discount_card BIT NOT NULL DEFAULT FALSE
);
CREATE TABLE orders(
id INT PRIMARY KEY AUTO_INCREMENT,
order_datetime DATETIME NOT NULL,
customer_id INT NOT NULL,
CONSTRAINT fk_orders_customers
FOREIGN KEY (customer_id)
REFERENCES customers(id)
);
CREATE TABLE orders_products(
order_id INT,
product_id INT,
CONSTRAINT fk_mapping_orders
FOREIGN KEY (order_id)
REFERENCES orders(id),
CONSTRAINT fk_mapping_products
FOREIGN KEY (product_id)
REFERENCES products(id)
);

-- s2
-- p2
INSERT INTO reviews(content, picture_url, published_at, rating)
(SELECT left(description, 15), reverse(name), '2010-10-10', price = price / 8 
FROM products
WHERE id >= 5);

-- p3
UPDATE products
SET quantity_in_stock = quantity_in_stock - 5
WHERE quantity_in_stock >= 60
AND quantity_in_stock <= 70;

-- p4
DELETE FROM customers
WHERE id NOT IN (SELECT customer_id FROM orders);

-- s3
-- p5
SELECT id, name FROM categories
ORDER BY name DESC;

-- p6
SELECT id, brand_id, name, quantity_in_stock FROM products
WHERE price > 1000
AND quantity_in_stock < 30
ORDER BY quantity_in_stock, id;

-- p7
SELECT id, content, rating, picture_url, published_at FROM reviews
WHERE content LIKE 'My%'
AND char_length(content) > 61
ORDER BY rating DESC;

-- p8
SELECT concat_ws(' ', first_name, last_name) as full_name, address, order_datetime as order_date 
FROM customers as c
JOIN orders as o ON c.id = o.customer_id
WHERE year(order_datetime) <= 2018
ORDER BY full_name DESC;

-- p9
SELECT count(p.id) as items_count, c.name, sum(p.quantity_in_stock) as total_quantity
FROM categories as c
JOIN products as p ON c.id = p.category_id
GROUP BY c.name
ORDER BY items_count DESC, total_quantity
LIMIT 5;

-- s4
-- p10
delimiter $$
CREATE FUNCTION udf_customer_products_count(name VARCHAR(30))
RETURNS INT
DETERMINISTIC
BEGIN
RETURN (SELECT count(p.id) FROM customers as c
JOIN orders as o ON c.id = o.customer_id
JOIN orders_products as op ON op.order_id = o.id
JOIN products as p ON p.id = op.product_id
WHERE c.first_name LIKE name
GROUP BY c.first_name);
END $$
delimiter ;
SELECT udf_customer_products_count('Shirley');
SELECT c.first_name,c.last_name, udf_customer_products_count('Shirley') as `total_products` FROM customers c
WHERE c.first_name = 'Shirley';

-- p11
delimiter $$
CREATE PROCEDURE udp_reduce_price(category_name VARCHAR(50))
BEGIN
UPDATE products as p
JOIN categories as c ON p.category_id = c.id
JOIN reviews as r ON r.id = p.review_id
SET p.price = p.price - (p.price * 0.3)
WHERE c.name LIKE category_name
AND r.rating < 4;
END $$
delimiter ;
CALL udp_reduce_price('Phones and tablets');