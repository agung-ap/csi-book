# Security and Optimization

## In this chapter
- You evaluate and strengthen the security of your database.
- You further improve the storage efficiency of your database design beyond normalization.
- You learn about indexing and how to apply it when implementing your database design to improve query performance.
- You learn about denormalization and apply it to your database design to further improve query performance.

## What you need to know
You can find the (now complete) database design represented with practitioner tools (dbdiagram.io, MySQL Workbench, etc.) in the GitHub repository: https://github.com/Neo-Hao/grokking-relational-database-design (see the `chapter_07` folder and follow the `README.md`).

You can also find SQL scripts for multiple RDBMSs (MySQL, MariaDB, PostgreSQL, SQLite, SQL Server, Oracle) representing the finalized design.

## Overview
In this chapter you explore database security and optimization. You evaluate integrity and confidentiality, enhance storage efficiency beyond normalization, understand when to denormalize, and apply indexing to improve query performance.

## Security

### Integrity
Integrity involves maintaining accuracy, completeness, and trustworthiness of data. Review your design to ensure:
- Every column uses the most appropriate data type
- Every table has a primary key
- Foreign keys enforce relationships
- Constraints derive from requirements (not guesses)

Example (missing foreign key):
```sql
CREATE TABLE author (
  author_id INT PRIMARY KEY,
  author_name VARCHAR(100) NOT NULL
);

CREATE TABLE book (
  book_id INT PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  author_id INT NOT NULL
);
```

Add the foreign key constraint:
```sql
CREATE TABLE book (
  book_id INT PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  author_id INT NOT NULL,
  CONSTRAINT FK_author_id FOREIGN KEY (author_id)
    REFERENCES author(author_id)
);
```

### Confidentiality
Two main approaches:
1. Access control (MAC, RBAC)
2. Encryption (one-way hashing, symmetric)

#### Access control (RBAC examples: MySQL/MariaDB)
```sql
-- USER role
CREATE ROLE standard_user;
GRANT SELECT ON database_name.product TO standard_user;
GRANT INSERT ON database_name.purchase TO standard_user;
GRANT INSERT ON database_name.purchase_product TO standard_user;
GRANT INSERT ON database_name.review TO standard_user;
CREATE USER 'morpheus'@'%' IDENTIFIED BY 'password';
GRANT standard_user TO 'morpheus'@'%';
```
```sql
-- ANALYST role
CREATE ROLE analyst;
GRANT SELECT ON database_name.product TO analyst;
GRANT SELECT ON database_name.purchase TO analyst;
GRANT SELECT ON database_name.purchase_product TO analyst;
GRANT SELECT ON database_name.review TO analyst;
CREATE USER 'smith'@'%' IDENTIFIED BY 'password';
GRANT analyst TO 'smith'@'%';
ALTER USER 'smith'@'%' DEFAULT ROLE analyst;
```
```sql
-- ADMIN role
CREATE ROLE admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON database_name.product TO admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON database_name.purchase TO admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON database_name.purchase_product TO admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON database_name.review TO admin;
CREATE USER 'david'@'%' IDENTIFIED BY 'password';
GRANT admin TO 'david'@'%';
ALTER USER 'david'@'%' DEFAULT ROLE admin;
```

#### Encryption
- One-way hashing (bcrypt, PBKDF2, SHA-512) for passwords  
  Resize column for bcrypt (60 chars):
  ```sql
  ALTER TABLE user MODIFY COLUMN password CHAR(60);
  ```
- Symmetric encryption (AES, 3DES, Blowfish) for reusable sensitive data (card numbers, expiry dates):
  ```sql
  ALTER TABLE payment_method
    MODIFY COLUMN card_number CHAR(45),
    MODIFY COLUMN expiry_date CHAR(45);
  ```

Key management: environment variables, KMS, or HSM (never store keys in the same DB).

## Storage considerations

### Consolidating redundant tables
Merge similar address tables into a single `address` table with a surrogate key and a composite UNIQUE constraint to prevent duplicates:
```sql
CREATE TABLE IF NOT EXISTS address (
  address_id INT AUTO_INCREMENT PRIMARY KEY,
  street_address VARCHAR(255) NOT NULL,
  address_line_optional VARCHAR(100),
  city VARCHAR(100) NOT NULL,
  state VARCHAR(20) NOT NULL,
  postal_code CHAR(5) NOT NULL,
  CONSTRAINT unique_address_constraint
    UNIQUE (street_address, address_line_optional, postal_code, city, state)
);
```
Reference it:
```sql
ALTER TABLE payment_method
  ADD COLUMN address_id INT NOT NULL,
  ADD CONSTRAINT fk_address_payment_method
    FOREIGN KEY (address_id) REFERENCES address(address_id);

ALTER TABLE user
  ADD COLUMN address_id INT NULL,
  ADD CONSTRAINT fk_address_user
    FOREIGN KEY (address_id) REFERENCES address(address_id);
```

### Categorical data
Extract low-cardinality repeating values (e.g., US states) into a dedicated lookup table (`state`) and reference it.

## Indexing

### Standard indexes
Speed sorting and exact match filters.

Example queries & indexes:
```sql
SELECT * FROM movie ORDER BY rating DESC LIMIT 30;
CREATE INDEX idx_rating ON movie (rating);

SELECT * FROM movie WHERE rating = 5;

CREATE INDEX idx_date ON movie (date);

SELECT * FROM movie ORDER BY date DESC, rating DESC LIMIT 30;
CREATE INDEX idx_combo ON movie (rating, date); -- order columns by leading usage
```
Primary keys auto-indexed; foreign keys are not—index frequent FK filters manually.

### Full-text indexes
Use for keyword / partial / fuzzy search.

MySQL/MariaDB:
```sql
CREATE FULLTEXT INDEX ft_idx_title ON movie (title);
SELECT * FROM movie
 WHERE MATCH(title) AGAINST('exciting' IN NATURAL LANGUAGE MODE);
```

PostgreSQL (conceptually):
```sql
ALTER TABLE movie ADD COLUMN tsv_title tsvector;
UPDATE movie SET tsv_title = to_tsvector('english', title);
CREATE INDEX gin_idx_title ON movie USING gin(tsv_title);
SELECT * FROM movie WHERE tsv_title @@ plainto_tsquery('english','exciting');
```

### Example application indexes
```sql
-- product name keyword search
CREATE FULLTEXT INDEX ft_idx_name ON product (name);

-- review lookups by code
CREATE INDEX idx_code ON review (code);

-- payment methods by user email
CREATE INDEX idx_email ON payment_method (email);
```

## Denormalization
Introduce controlled redundancy to reduce costly multi-table joins (last resort).

Process:
1. Identify very frequent, expensive multi-join queries.
2. Add direct relationship / duplicate selective columns to remove joins.

Example: add `artist_id` directly to `song` to avoid always joining `album` when listing songs by artist.

Trade-offs: transitive dependencies, potential update anomalies. Mitigate with:
- Documentation
- Controlled write paths
- Possibly triggers or application-level synchronization

Store example: reintroducing direct `user` → `purchase` link to avoid joining `payment_method` solely to trace ownership.

## Recap
- Encrypt sensitive data (hash passwords; symmetrically encrypt reusable secrets).
- Optimize storage beyond normalization (merge redundant tables, factor categorical domains).
- Add appropriate indexes (standard for equality/sort; full-text for search).
- Denormalize only when profiling shows sustained benefit and integrity risks are manageable.
