-- s1
CREATE TABLE users(
id INT PRIMARY KEY,
username VARCHAR(30) NOT NULL UNIQUE,
`password` VARCHAR(30) NOT NULL,
email VARCHAR(50) NOT NULL,
gender CHAR NOT NULL,
age INT NOT NULL,
job_title VARCHAR(40) NOT NULL,
ip VARCHAR(30) NOT NULL
);
CREATE TABLE photos(
id INT PRIMARY KEY AUTO_INCREMENT,
`description` TEXT NOT NULL,
`date` DATETIME NOT NULL,
views INT NOT NULL DEFAULT 0
);
CREATE TABLE addresses(
id INT PRIMARY KEY AUTO_INCREMENT,
address VARCHAR(30) NOT NULL,
town VARCHAR(30) NOT NULL,
country VARCHAR(30) NOT NULL,
user_id INT NOT NULL,
CONSTRAINT fk_addresses_users
FOREIGN KEY (user_id)
REFERENCES users(id)
);
CREATE TABLE comments(
id INT PRIMARY KEY AUTO_INCREMENT,
`comment` VARCHAR(255) NOT NULL,
`date` DATETIME NOT NULL,
photo_id INT NOT NULL,
CONSTRAINT fk_comments_photos
FOREIGN KEY (photo_id)
REFERENCES photos(id)
);
CREATE TABLE users_photos(
user_id INT NOT NULL,
photo_id INT NOT NULL,
CONSTRAINT fk_mapping_users
FOREIGN KEY (user_id)
REFERENCES users(id),
CONSTRAINT fk_mapping_photos
FOREIGN KEY (photo_id)
REFERENCES photos(id)
);
CREATE TABLE likes(
id INT PRIMARY KEY AUTO_INCREMENT,
photo_id INT,
user_id INT,
CONSTRAINT fk_likes_users
FOREIGN KEY (user_id)
REFERENCES users(id),
CONSTRAINT fk_likes_photos 
FOREIGN KEY (photo_id)
REFERENCES photos(id)
);

-- s2
-- p2
INSERT INTO addresses(address, town, country, user_id)
(SELECT username, `password`, ip, age FROM users
WHERE gender = 'M');

-- p3
UPDATE addresses
SET country = 'Blocked'
WHERE country LIKE 'B%';
UPDATE addresses
SET country = 'Test'
WHERE country LIKE 'T%';
UPDATE addresses
SET country = 'In Progress'
WHERE country LIKE 'P%';

-- p4
DELETE FROM addresses
WHERE id % 3 = 0;

-- s3
-- p5
SELECT username, gender, age FROM users
ORDER BY age DESC, username;

-- p6
SELECT p.id, p.date as date_and_time, p.description, count(c.id) as commentsCount 
FROM photos as p
JOIN comments as c ON p.id = c.photo_id
GROUP BY c.photo_id
ORDER BY commentsCount DESC, p.id
LIMIT 5;

-- p7
SELECT concat_ws(' ', u.id, u.username) as id_username, u.email 
FROM users as u
JOIN users_photos as up ON u.id = up.user_id
WHERE up.user_id = up.photo_id
ORDER BY u.id;

-- p8
SELECT p.id as photo_id, count(DISTINCT l.id) as likes_count, count(DISTINCT c.id) as comments_count 
FROM photos as p
LEFT JOIN comments as c ON p.id = c.photo_id
LEFT JOIN likes as l ON p.id = l.photo_id
GROUP BY p.id 
ORDER BY likes_count DESC, comments_count DESC, photo_id;

-- p9
SELECT (concat(left(description, 30), '...')) as summary, date FROM photos
WHERE day(date) = 10
ORDER BY date DESC;

-- s4
-- p10
delimiter $$
CREATE FUNCTION udf_users_photos_count(username VARCHAR(30))
RETURNS INT
DETERMINISTIC
BEGIN
RETURN (
CASE
WHEN (SELECT count(photo_id) FROM users_photos
WHERE user_id = (SELECT id FROM users as u WHERE u.username = username)
GROUP BY user_id) IS NULL THEN 0
ELSE (SELECT count(photo_id) FROM users_photos
WHERE user_id = (SELECT id FROM users as u WHERE u.username = username)
GROUP BY user_id)
END
);
END $$
delimiter ;
SELECT udf_users_photos_count('ssantryd') as photosCount;

-- p11
delimiter $$
CREATE PROCEDURE udp_modify_user(some_address VARCHAR(30), some_town VARCHAR(30))
BEGIN
UPDATE users 
SET age = age + 10
WHERE id = (SELECT user_id FROM addresses
WHERE address = some_address
AND town = some_town);
END $$
delimiter ;
CALL udp_modify_user('97 Valley Edge Parkway', 'Divinópolis');
SELECT u.username, u.email,u.gender,u.age,u.job_title FROM users AS u
WHERE u.username = 'eblagden21';