-- Exercise 1
SELECT * FROM accounts WHERE account_id IN (1, 3);

UPDATE accounts SET balance = balance - 50 WHERE account_id = 3;
UPDATE accounts SET balance = balance + 50 WHERE account_id = 1;

COMMIT;

SELECT * FROM accounts WHERE account_id IN (1, 3);


-- Exercise 2
UPDATE accounts SET balance = balance - 10000 WHERE account_id = 2;
UPDATE accounts SET balance = balance + 10000 WHERE account_id = 3;

SELECT * FROM accounts;

ROLLBACK;

SELECT * FROM accounts WHERE account_id = 2;


-- Exercise 3
UPDATE accounts SET balance = balance + 25 WHERE account_id = 1;

SAVEPOINT alice_updated;

UPDATE accounts SET balance = balance - 25 WHERE account_id = 3;

ROLLBACK TO SAVEPOINT alice_updated;

UPDATE accounts SET balance = balance - 25 WHERE account_id = 2;

COMMIT;


-- Exercise 4
CREATE OR REPLACE PROCEDURE deposit_funds(
    p_account_id IN NUMBER, 
    p_amount     IN NUMBER
) AS
BEGIN
    IF p_amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Deposit amount must be positive.');
    END IF;

    UPDATE accounts 
    SET balance = balance + p_amount 
    WHERE account_id = p_account_id;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

EXEC deposit_funds(3, 75);

-- Exercise 5
/*
Q1: Patient Booking Transaction
    - Inside: Reserving the time slot and creating the appointment record. These are "Atomic"—you shouldn't have a reserved slot without a record, or a record without a reserved slot.
    - Outside: Sending the notification. Transactions involve database locks; waiting for an external email server to respond would slow down the database. Plus, you can't "rollback" an email once it's sent!

Q2: The "Hidden Commit" Problem
    - If a developer calls your procedure as part of a 10-step process, your COMMIT will finalize everything they did up to that point. This robs the developer of the ability to roll back their own transaction if step 6 fails, because your step 5 already saved the work to the disk.

Q3: Function vs. Procedure in SELECT
    - calculate_copay(): Yes. Functions are designed to return values and (ideally) don't change the state of the database, making them safe for SELECT statements.
    - post_payment(): No. Procedures are intended to perform actions (DML like UPDATE/INSERT). Oracle prevents you from calling a procedure in a SELECT statement because a simple query shouldn't have "side effects" like changing data balances.
*/