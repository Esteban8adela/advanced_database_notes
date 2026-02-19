-- Lesson 6
SELECT title, domestic_sales, international_sales 
FROM movies
  JOIN boxoffice
    ON movies.id = boxoffice.movie_id;

SELECT title, domestic_sales, international_sales 
FROM movies
  JOIN boxoffice
    ON movies.id = boxoffice.movie_id
WHERE international_sales > domestic_sales;

SELECT title, rating 
FROM movies
  JOIN boxoffice
    ON movies.id = boxoffice.movie_id
ORDER BY rating desc;

-- Lesson 7
SELECT DISTINCT building
FROM employees;

SELECT building_name, capacity
FROM buildings;

SELECT DISTINCT building_name, role
FROM buildings
  LEFT JOIN employees
    ON buildings.building_name = employees.building;

    --Interview Question
SELECT pages.page_id
FROM pages
  LEFT JOIN page_likes
    ON pages.page_id = page_likes.page_id
WHERE page_likes.page_id IS NULL
ORDER BY pages.page_id ASC;