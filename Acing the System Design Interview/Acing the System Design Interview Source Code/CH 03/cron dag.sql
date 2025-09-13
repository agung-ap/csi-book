CREATE TABLE cron_dag (
  id INT,         -- ID of a job.
  parent_id INT,	-- Parent job. A job can have 0, 1, or multiple parents.
  PRIMARY KEY (id),
  FOREIGN KEY (parent_id) REFERENCES cron_dag (id)
);
CREATE TABLE cron_jobs (
  id INT,
  name VARCHAR(255),
  updated_at INT,
  PRIMARY KEY (id)
);
