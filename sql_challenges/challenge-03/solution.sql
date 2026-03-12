-- Lesson 10
SELECT MAX(years_employed) 
FROM employees;

SELECT role, AVG(years_employed) 
FROM employees 
GROUP BY role;

SELECT building, SUM(years_employed) 
FROM employees 
GROUP BY building;
-- Lesson 11
SELECT role, COUNT(*) 
FROM employees 
WHERE role = 'Artist';

SELECT role, COUNT(*) 
FROM employees 
GROUP BY role;

SELECT role, SUM(years_employed) 
FROM employees 
WHERE role = 'Engineer';

-- Aggregating Rows: Databases for Developers

-- 4 Try It!
select count(distinct shape) number_of_shapes,
       stddev(distinct weight) distinct_weight_stddev
from   bricks;

-- 6
select shape, sum(weight) as shape_weight
from   bricks
group by shape;

-- 8
select shape, sum(weight)
from   bricks
group by shape
having sum(weight) < 4;