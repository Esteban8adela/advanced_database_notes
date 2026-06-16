-- ============================================================
-- EXERCISE 1: Define "Team Velocity"
-- ============================================================
-- CONTRACT:
-- 1. Business Question: How much actual work is each team finishing?
-- 2. Definition: Total number of 'completed' tasks per team member. 
-- 3. Edge Cases: Teams with no completed tasks should show 0. Unassigned tasks are ignored.
-- 4. Unit: Tasks per person (Count / Count).
-- 5. Misleading if: We just count total tasks without dividing by team size. 10 tasks for a 5-person team is different than 10 tasks for a 1-person team.

WITH team_stats AS (
    SELECT 
        t.id,
        t.name AS team_name,
        COUNT(DISTINCT u.id) AS team_size,
        COUNT(CASE WHEN ts.status = 'completed' THEN ts.id END) AS completed_tasks
    FROM teams t
    LEFT JOIN users u ON t.id = u.team_id
    LEFT JOIN tasks ts ON u.id = ts.assigned_to
    GROUP BY t.id, t.name
),
velocity_data AS (
    SELECT 
        team_name,
        team_size,
        completed_tasks,
        CASE 
            WHEN team_size = 0 THEN 0 
            ELSE ROUND(completed_tasks / team_size, 2) 
        END AS velocity_per_person
    FROM team_stats
)
SELECT 
    v.*,
    CASE 
        WHEN velocity_per_person < (SELECT AVG(velocity_per_person) FROM velocity_data) THEN 'Below Average'
        ELSE 'Above/On Average'
    END AS performance_flag
FROM velocity_data
ORDER BY velocity_per_person DESC;


-- ============================================================
-- EXERCISE 2: Define "On-Time Delivery Rate"
-- ============================================================
-- CONTRACT:
-- 1. Business Question: Are we hitting our deadlines?
-- 2. Definition: % of completed tasks where completed_at is before or on the due_date.
-- 3. Edge Cases: Tasks without due dates are excluded. Time of day matters (we truncate to midnight for fair daily comparison).
-- 4. Unit: Percentage (%).
-- 5. Misleading if: We include cancelled tasks or tasks with no deadline.

SELECT 
    priority,
    COUNT(*) AS total_completed,
    ROUND(
        SUM(CASE WHEN TRUNC(completed_at) <= due_date THEN 1 ELSE 0 END) / COUNT(*) * 100, 
    1) AS on_time_pct,
    ROUND(
        AVG(CASE WHEN TRUNC(completed_at) > due_date THEN EXTRACT(DAY FROM (completed_at - CAST(due_date AS TIMESTAMP))) * 24 ELSE NULL END), 
    1) AS avg_hours_late
FROM tasks
WHERE status = 'completed' AND due_date IS NOT NULL
GROUP BY priority
ORDER BY on_time_pct DESC;


-- ============================================================
-- EXERCISE 3: Improve "Tasks per Team" 
-- ============================================================

SELECT 
    t.name AS team_name,
    COUNT(ts.id) AS total_tasks,
    COUNT(CASE WHEN ts.status IN ('open', 'in_progress', 'blocked') THEN ts.id END) AS active_tasks,
    ROUND(
        NVL(
            COUNT(CASE WHEN ts.status = 'completed' THEN ts.id END) / 
            NULLIF(COUNT(CASE WHEN ts.status != 'cancelled' THEN ts.id END), 0) * 100
        , 0), 
    1) AS completion_rate,
    CASE 
        WHEN COUNT(CASE WHEN ts.status IN ('open', 'in_progress', 'blocked') THEN ts.id END) > 10 THEN 'Overloaded'
        WHEN COUNT(CASE WHEN ts.status IN ('open', 'in_progress', 'blocked') THEN ts.id END) >= 5 THEN 'Healthy'
        ELSE 'Underutilized'
    END AS health_score
FROM teams t
LEFT JOIN users u ON u.team_id = t.id
LEFT JOIN tasks ts ON ts.assigned_to = u.id
GROUP BY t.id, t.name
ORDER BY active_tasks DESC;


-- ============================================================
-- EXERCISE 4: Improve "Average Resolution Time" 
-- ============================================================

WITH task_times AS (
    SELECT 
        priority,
        EXTRACT(DAY FROM (completed_at - created_at)) * 24 +
        EXTRACT(HOUR FROM (completed_at - created_at)) +
        (EXTRACT(MINUTE FROM (completed_at - created_at)) / 60) AS resolution_hours
    FROM tasks
    WHERE status = 'completed' AND completed_at IS NOT NULL
)
SELECT 
    priority,
    COUNT(*) AS task_count,
    ROUND(AVG(resolution_hours), 1) AS avg_hours,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY resolution_hours), 1) AS median_hours,
    ROUND(MIN(resolution_hours), 1) AS fastest_hours,
    ROUND(MAX(resolution_hours), 1) AS slowest_hours,
    CASE 
        WHEN priority = 'critical' AND AVG(resolution_hours) <= 24 THEN 'Met'
        WHEN priority = 'high' AND AVG(resolution_hours) <= 72 THEN 'Met'
        WHEN priority = 'medium' AND AVG(resolution_hours) <= 168 THEN 'Met'
        WHEN priority = 'low' AND AVG(resolution_hours) <= 336 THEN 'Met'
        ELSE 'Missed SLA'
    END AS target_status
FROM task_times
GROUP BY priority;


-- ============================================================
-- EXERCISE 5: Improve "Overdue Tasks"
-- ============================================================

SELECT 
    ts.title,
    u.username AS assignee,
    t.name AS team,
    ts.priority,
    ts.due_date,
    TRUNC(SYSDATE) - ts.due_date AS days_overdue,
    CASE 
        WHEN ts.priority = 'critical' THEN 'CRITICAL'
        WHEN ts.priority = 'high' AND (TRUNC(SYSDATE) - ts.due_date) > 2 THEN 'HIGH'
        WHEN ts.priority = 'medium' AND (TRUNC(SYSDATE) - ts.due_date) > 5 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS severity
FROM tasks ts
LEFT JOIN users u ON ts.assigned_to = u.id
LEFT JOIN teams t ON u.team_id = t.id
WHERE ts.due_date < TRUNC(SYSDATE)
  AND ts.status NOT IN ('completed', 'cancelled')
  AND ts.due_date IS NOT NULL
ORDER BY 
    CASE severity 
        WHEN 'CRITICAL' THEN 1 
        WHEN 'HIGH' THEN 2 
        WHEN 'MEDIUM' THEN 3 
        WHEN 'LOW' THEN 4 
    END, 
    days_overdue DESC;

    -- ============================================================
-- EXERCISE 6: Fix the "Productivity Score"
-- ============================================================
-- PROBLEM: Está contando todas las tareas asignadas, sin importar si 
-- están completadas, canceladas o apenas creadas. Medir productividad 
-- asignando trabajo fomenta crear "tareas basura".
--
-- REWRITE: Puntos por tareas completadas basándonos en la prioridad.

SELECT 
    u.full_name,
    SUM(
        CASE ts.priority 
            WHEN 'critical' THEN 4
            WHEN 'high' THEN 3
            WHEN 'medium' THEN 2
            WHEN 'low' THEN 1
            ELSE 0 
        END
    ) AS value_delivered_score
FROM users u
JOIN tasks ts ON ts.assigned_to = u.id
WHERE ts.status = 'completed'
GROUP BY u.id, u.full_name
ORDER BY value_delivered_score DESC;


-- ============================================================
-- EXERCISE 7: Fix the "Team Efficiency"
-- ============================================================
-- PROBLEM: El ID de la tarea es un Primary Key (un identificador). 
-- Sacar el promedio matemático de un ID no tiene ningún sentido. 
-- Es como intentar promediar números de teléfono.
--
-- REWRITE: Calcular el ratio de completitud (Completion Rate).

SELECT 
    t.name AS team_name,
    COUNT(CASE WHEN ts.status = 'completed' THEN 1 END) || ' / ' || COUNT(ts.id) AS progress,
    ROUND(COUNT(CASE WHEN ts.status = 'completed' THEN 1 END) / NULLIF(COUNT(ts.id), 0) * 100, 1) AS efficiency_pct
FROM teams t
JOIN users u ON u.team_id = t.id
JOIN tasks ts ON ts.assigned_to = u.id
GROUP BY t.id, t.name
ORDER BY efficiency_pct DESC;


-- ============================================================
-- EXERCISE 8: Fix the "Urgency Index"
-- ============================================================
-- PROBLEM: La prioridad es un VARCHAR ('high', 'low'), no puedes multiplicarlo
-- por 10. Tampoco puedes sumarle una fecha directamente y esperar un índice 
-- numérico razonable.
--
-- REWRITE: Asignar valores numéricos a la prioridad y penalizar por cercanía
-- o retraso a la fecha de entrega.

SELECT 
    title, 
    priority,
    due_date,
    (CASE priority 
        WHEN 'critical' THEN 40 
        WHEN 'high' THEN 30 
        WHEN 'medium' THEN 20 
        WHEN 'low' THEN 10 
        ELSE 0 
    END) - (due_date - TRUNC(SYSDATE)) AS actual_urgency_score
FROM tasks
WHERE status NOT IN ('completed', 'cancelled')
ORDER BY actual_urgency_score DESC;