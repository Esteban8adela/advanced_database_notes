-- Exercise 1

CREATE TABLE comments (
    id         NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    task_id    NUMBER        NOT NULL,
    user_id    NUMBER        NOT NULL,
    content    VARCHAR2(1000) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_comments_task
        FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
    CONSTRAINT fk_comments_user
        FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Questions
-- 1. It needs a task relationship pointing to the Task model and a user relationship pointing to the User model.
-- 2. Yes. Inside your Task model, you should add: comments = relationship("Comment", back_populates="task", cascade="all, delete-orphan") to easily access a task's thread.
-- 3. They should be deleted. This is handled at the database level by ondelete="CASCADE" in the ForeignKey, and at the ORM level by cascade="all, delete-orphan" in the relationship.

-- Exercise 2
CREATE TABLE comments (
    id         NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    task_id    NUMBER         NOT NULL,
    user_id    NUMBER         NOT NULL,
    content    VARCHAR2(1000) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_comments_task FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
    CONSTRAINT fk_comments_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT ck_comment_content_not_empty CHECK (content != '')
);

DROP TABLE comments;

-- Questions 
-- 1. It executes the SQL commands required to apply the new schema changes (in this case, CREATE TABLE comments).
-- 2. It executes the exact reverse operations to undo the migration (in this case, DROP TABLE comments).
-- 3. The comments table is destroyed entirely.

-- Exercise 3
INSERT INTO teams (name, description) VALUES ('DevOps', 'Infrastructure and deployment team');

-- 2. Create diana_ops user
INSERT INTO users (username, email, full_name, team_id)
    VALUES ('diana_ops', 'diana@example.com', 'Diana Ops',
            (SELECT id FROM teams WHERE name = 'DevOps'));
INSERT INTO tasks (title, description, status, assigned_to)
    VALUES ('Setup CI/CD pipeline', 'Configure GitHub Actions', 'open',
            (SELECT id FROM users WHERE username = 'diana_ops'));
INSERT INTO tasks (title, description, status, assigned_to)
    VALUES ('Monitor prod servers', 'Set up Grafana dashboards', 'in_progress',
            (SELECT id FROM users WHERE username = 'diana_ops'));
INSERT INTO tasks (title, description, status, assigned_to)
    VALUES ('Cleanup old Docker images', 'Low priority maintenance', 'open',
            (SELECT id FROM users WHERE username = 'diana_ops'));

SELECT COUNT(*) AS task_count FROM tasks
WHERE assigned_to = (SELECT id FROM users WHERE username = 'diana_ops');

UPDATE tasks SET status = 'closed', updated_at = CURRENT_TIMESTAMP
WHERE title = 'Setup CI/CD pipeline';
DELETE FROM tasks WHERE title = 'Cleanup old Docker images';
COMMIT;

-- Exercise 4
ALTER TABLE tasks ADD estimated_hours NUMBER;
ALTER TABLE tasks DROP COLUMN estimated_hours;

COMMIT;

-- 1. The estimated_hours column is completely dropped from the database schema via an ALTER TABLE ... DROP COLUMN command.
-- 2. Any data that was saved inside the estimated_hours column is permanently deleted. Rolling back schema structurally removes the container holding that data.

--Exercise 5
-- 1. ORMs allow you to interact with your database using Python objects, which makes code more readable, provides built-in protection against SQL injection, and makes it much easier to switch database engines (e.g., from SQLite to Oracle) without rewriting queries.
-- 2. Migrations act as version control for your database schema. They allow multiple developers to keep their local databases in sync and provide a safe, reproducible way to upgrade production databases.
-- 3. You rollback when a migration was applied by mistake, when a newly deployed schema change introduces a severe bug, or when you are iterating locally and need to adjust a table design before committing the code.
-- 4. add() simply stages an object in the SQLAlchemy session (memory). commit() officially flushes that transaction to the database, executing the SQL and making the changes permanent.
-- 5. They abstract away the need to write complex SQL JOIN statements. Once configured, you can traverse foreign keys as simple Python attributes (e.g., user.team.name or task.assignee.email).