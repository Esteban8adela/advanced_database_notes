-- ============================================================
-- Lesson 03 — Indexes: Class Exercises
-- Work through these before looking at the hints
-- ============================================================

-- ============================================================
-- Exercise 1 — Find the slow query
--
-- Run this query. Look at the execution plan.
-- Is Oracle using an index? Should it?
-- ============================================================

EXPLAIN PLAN FOR
SELECT * FROM patient_visits WHERE site_id = 3;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Questions:
-- a) What scan type do you see? Why?
    -- TABLE ACCESS FULL. Oracle chooses this because there is no index on the site_id column.
-- b) site_id has values 1–5. Is this high or low cardinality?
    -- This is very low cardinality (only 5 distinct values across the whole table).
-- c) Would adding an index on site_id help? Why or why not?
    -- No. Reading ~20% of a table via an index (which requires random I/O) is generally slower than a Full Table Scan (sequential multi-block read).

-- ============================================================
-- Exercise 2 — Create an index and see if it helps
--
-- Create an index on visit_date.
-- Then run the range query below and check the plan.
-- ============================================================

-- Step 1: Create it
-- (write the CREATE INDEX statement here)


-- Step 2: Gather stats
BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'PATIENT_VISITS', cascade => TRUE);
END;
/

-- Step 3: Run the range query and check the plan
EXPLAIN PLAN FOR
SELECT * FROM patient_visits
WHERE visit_date BETWEEN SYSDATE - 30 AND SYSDATE;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Questions:
-- a) Does Oracle use the index for this range?
    -- Yes, it uses an INDEX RANGE SCAN because 30 days is a very small fraction of the total data.
-- b) Change the range to the last 7 days. Does the plan change?
    -- It remains an INDEX RANGE SCAN, but the estimated Cost and Rows decrease.
-- c) Change to the last 700 days. What happens?
    -- The execution plan flips back to a TABLE ACCESS FULL.
-- d) Why does the range size affect whether Oracle uses the index?
    -- The Cost-Based Optimizer calculates that fetching ~95% of the rows individually via an index is much more expensive than scanning the whole table in bulk.

-- ============================================================
-- Exercise 3 — Composite index
--
-- You often query by both patient_id AND visit_date together:
--   WHERE patient_id = 1234 AND visit_date > SYSDATE - 90
--
-- Two options:
--   Option A: Two separate indexes (one per column)
--   Option B: One composite index (patient_id, visit_date)
--
-- Create the composite index and test the query.
-- ============================================================

CREATE INDEX idx_pv_patient_date ON patient_visits(patient_id, visit_date);

BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'PATIENT_VISITS', cascade => TRUE);
END;
/

EXPLAIN PLAN FOR
SELECT * FROM patient_visits
WHERE patient_id = 1234
  AND visit_date > SYSDATE - 90;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Questions:
-- a) Does the plan use the composite index?
    -- Yes, it perfectly uses the idx_pv_patient_date composite index.
-- b) Now try querying ONLY on visit_date (no patient_id). Does the composite index get used? Why not?
    -- No. A B-tree index is sorted hierarchically by the leading column first. Without the patient_id, Oracle doesn't know where to start looking in the tree.
-- c) What's the rule about column order in composite indexes?
    -- You must query against the leading edge. Always order columns from most frequently queried to least frequently queried.

-- Bonus test — leading column only:
EXPLAIN PLAN FOR
SELECT * FROM patient_visits WHERE patient_id = 1234;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Trailing column only (index cannot be used from the middle):
EXPLAIN PLAN FOR
SELECT * FROM patient_visits WHERE visit_date > SYSDATE - 90;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- ============================================================
-- Exercise 4 — Function that breaks an index
--
-- There IS an index on patient_id (from lesson 03).
-- Predict what happens when you wrap the column in a function.
-- ============================================================

-- This query CAN use the index:
EXPLAIN PLAN FOR
SELECT * FROM patient_visits WHERE patient_id = 5432;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- This one cannot — why?
EXPLAIN PLAN FOR
SELECT * FROM patient_visits WHERE TO_CHAR(patient_id) = '5432';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Questions:
-- a) What scan type did the second query use?
    -- TABLE ACCESS FULL.
-- b) Why does wrapping a column in a function break index use?
    -- The index stores raw numbers. TO_CHAR forces Oracle to evaluate the function on every single row before making a comparison, rendering the index useless.
-- c) How would you rewrite the second query to allow index use?
    -- Apply the function/formatting to the parameter instead of the database column:
    -- WHERE patient_id = TO_NUMBER('5432') OR simply WHERE patient_id = 5432

-- ============================================================
-- Exercise 5 — Discussion: real-world scenarios
--
-- For each scenario below, decide:
--   a) Would you add an index?
--   b) On which column(s)?
--   c) Any concerns?
-- ============================================================

-- Scenario A:
-- A reporting table gets loaded once per night (batch ETL).
-- During the day, analysts run SELECT queries by date range.
-- The table has 50 million rows.
-- → Index on date? Yes/No, why? 
    -- Yes, to support analyst date-range queries.
-- Concern
    -- Indexes slow down batch inserts. Best practice is to drop/disable the index before the nightly ETL load, then rebuild it afterwards.

-- Scenario B:
-- An OLTP orders table gets 10,000 inserts per minute.
-- Support staff look up orders by customer_id or order_status.
-- order_status has 4 values: pending, processing, shipped, cancelled.
-- → What indexes would you add? 
    -- customer_id: High cardinality, perfect for fast OLTP lookups.

-- Scenario C:
-- A patient table has an email column (unique per patient).
-- There are 5 million patients.
-- The app frequently does: WHERE email = 'user@example.com'
-- → What kind of index would be best here?
    -- A UNIQUE INDEX on the email column. This speeds up single-row lookups and strictly enforces data integrity by preventing duplicate emails.

