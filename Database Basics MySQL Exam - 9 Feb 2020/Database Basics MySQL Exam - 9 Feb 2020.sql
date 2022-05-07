-- s1
CREATE TABLE countries(
id INT PRIMARY KEY AUTO_INCREMENT,
`name` VARCHAR(45) NOT NULL
);
CREATE TABLE `skills_data`(
id INT PRIMARY KEY AUTO_INCREMENT,
dribbling INT DEFAULT 0,
pace INT DEFAULT 0,
passing INT DEFAULT 0,
shooting INT DEFAULT 0,
speed INT DEFAULT 0,
strength INT DEFAULT 0
);
CREATE TABLE coaches(
id INT PRIMARY KEY AUTO_INCREMENT,
first_name VARCHAR(10) NOT NULL,
last_name VARCHAR(20) NOT NULL,
salary DECIMAL(10, 2) NOT NULL DEFAULT 0,
coach_level INT NOT NULL DEFAULT 0
);
CREATE TABLE towns(
id INT PRIMARY KEY AUTO_INCREMENT,
`name` VARCHAR(45) NOT NULL,
country_id INT NOT NULL,
CONSTRAINT fk_towns_countries
FOREIGN KEY (country_id)
REFERENCES countries(id)
);
CREATE TABLE stadiums(
id INT PRIMARY KEY AUTO_INCREMENT,
`name` VARCHAR(45) NOT NULL,
capacity INT NOT NULL,
town_id INT NOT NULL,
CONSTRAINT fk_stadiums_towns
FOREIGN KEY (town_id)
REFERENCES towns(id)
);
CREATE TABLE teams(
id INT PRIMARY KEY AUTO_INCREMENT,
`name` VARCHAR(45) NOT NULL,
established DATE NOT NULL,
fan_base BIGINT NOT NULL DEFAULT 0,
stadium_id INT NOT NULL,
CONSTRAINT fk_teams_stadiums
FOREIGN KEY (stadium_id)
REFERENCES stadiums(id)
);
CREATE TABLE players(
id INT PRIMARY KEY AUTO_INCREMENT,
first_name VARCHAR(10) NOT NULL,
last_name VARCHAR(20) NOT NULL,
age INT NOT NULL DEFAULT 0,
position CHAR(1) NOT NULL,
salary DECIMAL(10, 2) NOT NULL DEFAULT 0,
hire_date DATETIME,
skills_data_id INT NOT NULL,
team_id INT,
CONSTRAINT `fk_players_skills data`
FOREIGN KEY (skills_data_id)
REFERENCES `skills_data`(id),
CONSTRAINT `fk_players_teams`
FOREIGN KEY (team_id)
REFERENCES `teams`(id)
);
CREATE TABLE players_coaches(
player_id INT,
coach_id INT,
CONSTRAINT fk_coach_player
FOREIGN KEY (player_id)
REFERENCES players(id),
CONSTRAINT fk_player_coach
FOREIGN KEY (coach_id)
REFERENCES coaches(id),
CONSTRAINT pk_maping PRIMARY KEY (player_id, coach_id)
);

-- s2
-- p2
INSERT INTO coaches(first_name, last_name, salary, coach_level)
SELECT p.first_name, p.last_name, p.salary * 2, char_length(first_name) FROM players as p
WHERE p.age >= 45;

-- p3
UPDATE coaches as c
SET c.coach_level = c.coach_level + 1
WHERE first_name LIKE 'A%' AND (SELECT count(player_id) as count FROM players_coaches as pc
WHERE pc.coach_id = c.id) >= 1;

-- p4
DELETE FROM players
WHERE age >= 45;

-- s3
-- p5
SELECT first_name, age, salary FROM players
ORDER BY salary DESC;

-- p6
SELECT p.id, concat_ws(' ', p.first_name, p.last_name) as fill_name, p.age, p.position, p.hire_date 
FROM players as p
JOIN skills_data as sd ON p.skills_data_id = sd.id
WHERE p.age < 23 
AND p.position = 'A'
AND p.hire_date IS NULL
AND sd.strength > 50
ORDER BY p.salary, p.age;

-- p7
SELECT any_value(t.`name`) as `name`, any_value(t.established) as established, any_value(t.fan_base) as fan_base, 
count(p.id) as players_count 
FROM teams as t
LEFT JOIN players as p ON p.team_id = t.id
GROUP BY t.id
ORDER BY players_count DESC, fan_base DESC;

-- p7 (second)
SELECT t.name, t.established, t.fan_base, 
(SELECT count(p.id) FROM players as p WHERE p.team_id = t.id) as players_count 
FROM teams as t
ORDER BY players_count DESC, t.fan_base DESC;

-- p8
SELECT max(sd.speed) as max_speed, tow.name as town_name FROM players as p
JOIN skills_data as sd ON p.skills_data_id = sd.id
RIGHT JOIN teams as t ON p.team_id = t.id
JOIN stadiums as s ON t.stadium_id = s.id
JOIN towns as tow ON s.town_id = tow.id
WHERE t.name != 'Devify'
GROUP BY town_name
ORDER BY max_speed DESC, town_name;

-- p9
SELECT c.name, count(p.id) as total_count_of_players, sum(p.salary) as total_sum_of_salaries 
FROM players as p
RIGHT JOIN teams as t ON p.team_id = t.id
RIGHT JOIN stadiums as s ON t.stadium_id = s.id
RIGHT JOIN towns as tow ON s.town_id = tow.id
RIGHT JOIN countries as c ON tow.country_id = c.id
GROUP BY c.name
ORDER BY total_count_of_players DESC, c.name;

-- s4
-- p10
delimiter $$
CREATE FUNCTION udf_stadium_players_count(stadium_name VARCHAR(30))
RETURNS INT
DETERMINISTIC
BEGIN
DECLARE result INT;
IF (SELECT count(p.id) as count FROM players as p
 JOIN teams as t ON p.team_id = t.id
 JOIN stadiums as s ON t.stadium_id = s.id
 GROUP BY s.name
 HAVING s.name = stadium_name) IS NULL THEN SET result := 0;
 ELSE SET result := (SELECT count(p.id) as count FROM players as p
 JOIN teams as t ON p.team_id = t.id
 JOIN stadiums as s ON t.stadium_id = s.id
 GROUP BY s.name
 HAVING s.name = stadium_name);
 END IF;
 RETURN result;
 END $$
 delimiter ;
 select udf_stadium_players_count('Linklinks') as count;
 
 -- p11
 delimiter $$
 CREATE PROCEDURE udp_find_playmaker(min_dribble_points int, team_name varchar(45))
 BEGIN
 SELECT concat_ws(' ', p.first_name, p.last_name) as full_name, p.age, p.salary, sd.dribbling, sd.speed, t.name 
as team_name
FROM players as p
JOIN teams as t ON p.team_id = t.id
JOIN skills_data as sd ON p.skills_data_id = sd.id
WHERE t.name = team_name 
AND sd.dribbling > min_dribble_points
AND sd.speed > (SELECT avg(speed) FROM skills_data)
ORDER BY sd.speed DESC
LIMIT 1;
END $$
delimiter ;
CALL udp_find_playmaker(20, 'Skyble');