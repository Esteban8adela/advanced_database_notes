
### `sql_challenges/challenge-01/README.md`

```md
# SQL Challenge - Analytic Functions: Databases for Developers

## Problem
https://datalemur.com/questions/sql-top-three-salaries

## Schema
```sql
SELECT 
    department_name, 
    name, 
    salary
FROM (
    SELECT 
        d.department_name, 
        e.name, 
        e.salary,
        DENSE_RANK() OVER (
            PARTITION BY e.department_id 
            ORDER BY e.salary DESC
        ) as rank_num
    FROM employee e
    JOIN department d ON e.department_id = d.department_id
) temp
WHERE rank_num <= 3
ORDER BY 
    department_name ASC, 
    salary DESC, 
    name ASC;