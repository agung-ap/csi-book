% 6 Normalization and Implementation

# Normalization and implementation

## In this chapter

- You normalize your database design.
- You implement your database design.
- You learn important concepts such as using constraints and cascade.

### What you need to know

You can find the database design covered in this chapter implemented in tools commonly used by practitioners, such as dbdiagram.io and MySQL Workbench, in the GitHub repository: https://github.com/Neo-Hao/grokking-relational-database-design. Navigate to the `chapter_06` folder and follow the instructions in the `README.md` file to load the database design into corresponding tools.

You can also find the SQL scripts corresponding to the almost-finalized database design for different relational database management systems (RDBMSs), including MySQL, MariaDB, PostgreSQL, SQLite, SQL Server, and Oracle.

## Overview

In this chapter, you will normalize and implement your database design for The Sci-Fi Collective. By doing so, you will learn about important concepts in database design, such as functional dependency, normalization, and constraints.

![Figure CH06_UN01](https://drek4537l1klr.cloudfront.net/hao/Figures/CH06_UN01_Hao.png)

## Normalization

Before converting your database design to a SQL script that creates the corresponding database and tables, you need to normalize your design. This critical step in database design is known as **normalization**.

*Normalization* is the process of organizing a database in a way that minimizes redundancy and dependency while maximizing data integrity and consistency. In other words, we break the database into smaller, more manageable tables, each table representing a single entity or concept. The primary goal of normalization is to strengthen data integrity. Although you have worked toward this goal in the preceding chapters, you are about to kick your work up a notch.

![Figure CH06_UN02](https://drek4537l1klr.cloudfront.net/hao/Figures/CH06_UN02_Hao.png)

You will use normal forms to guide the normalization process. There are multiple normal forms, including the First Normal Form (1NF), Second Normal Form (2NF), Third Normal Form (3NF), and Boyce-Codd Normal Form (BCNF). The relationship among these normal forms is hierarchical and sequential in database normalization. Each form builds on the preceding one. Being the smallest nesting doll of these four normal forms, BCNF has all the characteristics of the other three.

![Figure CH06_UN03](https://drek4537l1klr.cloudfront.net/hao/Figures/CH06_UN03_Hao.png)

### Superkeys, candidate keys, and primary keys

Do you remember what they are? The coverage of different types of keys goes back to chapter 4.

A *superkey* is a set of one or more columns of a table that can uniquely identify a row in the table, but it may contain columns that are not required to uniquely identify a row. A *candidate key* is a minimal superkey, which means that it is a superkey with no unnecessary columns. Of all the candidate keys in a table, one is chosen as the primary key. The following figure summarizes the relationships among the three types of key:

![Figure CH06_UN04](https://drek4537l1klr.cloudfront.net/hao/Figures/CH06_UN04_Hao.png)

In practice, when all your tables are in BCNF, you can consider your database fully normalized. A table in BCNF is already in 1NF to 3NF and has the following characteristics:

- It has a primary key.
- It has no multivalued columns.
- All columns are dependent on a key but nothing else.
- It contains no transitive dependency.

You will find detailed definitions of these characteristics in the following sections and use them as the guidelines to normalize the database design of The Sci-Fi Collective. A table that doesn’t meet one, two, or any guidelines may cause problems such as update and deletion anomalies. Remember attempting to combine product and customer data into one table in chapter 1?

![Figure CH06_UN05](https://drek4537l1klr.cloudfront.net/hao/Figures/CH06_UN05_Hao.png)

### Normal forms: Crazy nesting dolls

You may wonder whether normal forms can go beyond BCNF. Yes! Fourth Normal Form (4NF), Fifth Normal Form (5NF), and even Sixth Normal Form (6NF) have been proposed and discussed in the theoretical framework of database normalization.

4NF, 5NF, and 6NF build on previous normal forms, and each form targets increasingly specific, less common design problems. 4NF addresses multivalued dependencies, for example, and 5NF eliminates redundancy caused by join dependencies that are not covered by 4NF. 6NF is largely theoretical.

4NF, 5NF, and 6NF are beyond the scope of this book. If you want a quick introduction to them, grab a textbook on databases (such as *Database System Concepts*, 7th ed., by A. Silberschatz, H. F. Korth, and S. Sudarshan [McGraw-Hill Education, 2019]) or make the following request of a generative AI system:

> Give me an introduction to 4NF, 5NF, and 6NF, using plain language and examples.

![Figure CH06_UN06](https://drek4537l1klr.cloudfront.net/hao/Figures/CH06_UN06_Hao.png)

### There is always a primary key

A table in BCNF should always have a primary key. Do you see primary keys everywhere in the entity-relationship (E-R) diagram you developed in chapter 5? Great! That means each table follows the first simple guideline of BCNF.

What if you have a table that doesn’t have a primary key? Well, you need to stop and identify the primary key of that table before going any further.

### There are no multivalued columns

A table in BCNF should have no multivalued columns. What is a multivalued column? Think about a table named `course_registration` that represents students taking a variety of courses. The `course` column is a multivalued column. Each course record holds multiple values.

![Figure CH06_UN07](https://drek4537l1klr.cloudfront.net/hao/Figures/CH06_UN07_Hao.png)

The multivalued columns lead to problems such as difficult querying, data redundancy, inconsistency, and anomalies. You can easily spot a course repeated in different rows in `course_registration`, for example.

#### Who decides whether something is multivalued?

In a relational database, a table represents a single entity or a concept about which information is stored. A column in a table represents a specific attribute of the entity or concept that the table describes. Each column has a distinct name and a data type that defines the kind of data it stores. You may wonder who decides whether something should be considered a single concept, entity, or attribute. The answer is the users of the application supported by the database.

Determining whether a column is multivalued is based on the standards of users. In a table of an e-commerce database, for example, you would call out a column that represents phone numbers and stores multiple phone numbers per row as a multivalued column because each phone number represents a value that’s indivisible to users. Dividing a phone number into an area number and subscriber number makes no sense to any users of the database. As another example, you won’t consider a column in the same database that stores single email addresses per row a multivalued column because users don’t care about dividing an email address into a username and domain name.

Overall, user requirements decide the purposes of databases, which in turn decide whether a column is multivalued.

To fix such a problem, you typically need to redesign the multivalued column so that it holds only a single value in each row. Often, you need to move that multivalued column to a new table to prevent redundancy and other problems. To fix `course_registration`, for example, you limit the `course` column to hold a single course per row. But you can’t repeat the same `student_id` values in different rows of the original table because it’s the primary key. You need to break `course_registration` into two tables, one holding student information and the other holding course registration information:

![Figure CH06_UN08](https://drek4537l1klr.cloudfront.net/hao/Figures/CH06_UN08_Hao.png)

Does your database design have any tables containing multivalued columns? Nope. When you mapped each entity to a table, you didn’t attempt to use a column to hold more than one value. If you do, you will fix such problems in a similar manner.

### All columns are dependent on a key but nothing else

All columns of a table in BCNF should be functionally dependent on a key. To understand this requirement, you need to understand functional dependency.

Think about how functions work in any programming language. Suppose that you have a function, `power(x)`, that takes `x` as the only input and returns its power as the output. Given the same input `x`, the function `power(x)` always returns the same output. The input functionally determines the output.

Now let’s switch our attention to a table. In a table, given a value of column A, if there is always a unique corresponding value of column B, column A functionally determines column B—that is, column B is functionally dependent on column A. In the following table, which represents employees, `employee_name` is functionally dependent on `employee_id`. In other words, knowing the value of `employee_id` can help you determine the value of `employee_name`. This functional dependency can be expressed as follows:

```
employee_id → employee_name
```

![Figure CH06_UN09](https://drek4537l1klr.cloudfront.net/hao/Figures/CH06_UN09_Hao.png)

Functional dependency is directional. In the preceding figure, `employee_id` functionally determines `employee_name`. It doesn’t mean, however, that `employee_name` functionally determines `employee_id`. The value of `employee_name` can’t be used to determine the value of `employee_id`. Think what would happen if two different employees had the same name.

Now that you know what functional dependency is in the context of relational databases, look at this BCNF requirement again:

> A table in BCNF should have all its columns functionally dependent on a key but nothing else.

You may wonder why we say “dependent on a key” without specifying “primary key.” There is a fine-grained difference, and edge cases exist. In most cases that you’ll deal with in practice, however, you don’t need to worry about it and can relax this requirement to the following:

> A table in BCNF should have all its columns functionally dependent on the primary key but nothing else.

#### Toward a deeper understanding of BCNF

A deep understanding of BCNF and all other normal forms is helpful in normalization (before they drive you crazy). Edge cases, which are good opportunities to deepen your understanding, are beyond the scope of this book, but it doesn’t hurt to list them:

1. Table R has three columns, a, b, and c. The primary key of R is (a, b). If c is functionally dependent on a, R is not in 2NF, let alone 3NF or BCNF.
2. Table R has five columns, a, b, c, d, and e. The primary key of R is (a, b, c). d and e are functionally dependent on (a, b, c). If c is functionally dependent on d, R is in 3NF but not in BCNF.
3. Table R has five columns, a, b, c, d, and e. R has two candidate keys, (a, b) and (c, d). The primary key is (a, b). If e is functionally dependent only on (c, d), R is still in BCNF.

Before your head explodes, rest assured that you’ll rarely need to deal with case 2 or 3.

In other words, if you find a table with one or more columns that are not functionally dependent on the primary key, the table must be normalized. How? You break the table into two or more tables, each table containing only the columns that are dependent on the primary. Depending on the relationship between the two new tables, you may link them via a foreign key.

We’ll demonstrate this process with an example. Imagine a `product` table designed by a novice designer:

![Figure CH06_UN10](https://drek4537l1klr.cloudfront.net/hao/Figures/CH06_UN10_Hao.png)

It may seem logical to include supplier contact information alongside product details for convenience. But the column `supplier_contact` is functionally dependent only on `supplier_name`. In other words, the `product` table contains two functional dependencies:

```
product_id → product_name, supplier_name, category
supplier_name → supplier_contact
```

To fix this problem, you need to remove the columns that are not determined by the primary key of the `product` table. Where do they fit in? A new table. The `supplier_contact` column is functionally dependent on `supplier_name`. If the two columns are in one table that represents suppliers, they fully meet the requirement of functional dependency. If each supplier can be identified by a unique ID, you can even use this piece of information as the primary key of this new table, and it will naturally become the foreign key in the `product` table that links `product` and `supplier`:

![Figure CH06_UN11](https://drek4537l1klr.cloudfront.net/hao/Figures/CH06_UN11_Hao.png)

### Normalize your database design

When you check the design of The Sci-Fi Collective’s database against the requirement that all columns be functionally dependent on the primary key, you need to examine every table, including `purchase`:

![Figure CH06_UN12](https://drek4537l1klr.cloudfront.net/hao/Figures/CH06_UN12_Hao.png)

Undoubtedly, many columns are functionally dependent on the primary key, including `total_price`, `purchase_time`, `payment_id`, and `email`. If you think about what goes into a receipt, you see that knowing the value of `purchase_id` is equal to having a receipt, which determines the values of `total_price` and `purchase_time`:

![Figure CH06_UN13](https://drek4537l1klr.cloudfront.net/hao/Figures/CH06_UN13_Hao.png)

From this example receipt, you can tell that each purchase involves multiple products with different quantities and prices. Product quantities (`product_quantity`) and prices (`product_price`) are functionally determined by a combination of purchase ID (`purchase_id`) and product code (`code`). The product code (`code`) isn’t in the `purchase` table. That said, you have two functional dependencies in this table:

```
product_id → total_price, purchase_time, payment_id, email
purchase_id, code → product_quantity, product_price
```

Because of the two functional dependencies, this table violates BCNF.

When you start adding data to the `purchase` table, you see how tricky the problem is. Adding the data of a receipt to the `purchase` table, for example, is a mission impossible:

![Figure CH06_UN14](https://drek4537l1klr.cloudfront.net/hao/Figures/CH06_UN14_Hao.png)

You can’t repeat the values of the primary key. Even if you could, you would still face redundancy problems in other columns, such as `total_price` and `purchase_time`.

To fix this problem, move the columns that are not functionally dependent on the primary key to a new table. In this case, `product_quantity` and `product_price` are functionally dependent on the combination of `purchase_id` and `code`. But neither `purchase_id` nor `code` can functionally determine `product_quantity` or `product_price` alone:

- `purchase_id` does not functionally determine `product_quantity` or `product_price`. Each purchase can include multiple products with different quantities and prices.
- `code` does not functionally determine `product_quantity` or `product_price` in the context of a purchase. The same product can be sold in different quantities and at different prices in various purchases.

Luckily, you already have a junction table, `purchase_product`, that connects `purchase` and `product`. The junction table uses the combo of `purchase_id` and `code` as its primary key. Moving `product_quantity` and `product_price` to the `purchase_product` table is like killing two birds with one stone. With this change, both `purchase` and `purchase_product` meet the requirement of functional dependency:

![Figure CH06_UN15](https://drek4537l1klr.cloudfront.net/hao/Figures/CH06_UN15_Hao.png)

You may be tempted to eliminate `product_price` from the `purchase_product` table because you can always retrieve a product’s price from the `product` table. But it’s best not to do that. Over time, the price of a product may change due to factors such as inflation or market competition. If you rely on only the `product` table to retrieve product prices, you may lose the data required to put together a receipt from several months ago. For the same reason, you should add a product name column to the `purchase_product` table. After all, nothing should lead to changes in a receipt—not even product name changes.

![Figure CH06_UN16](https://drek4537l1klr.cloudfront.net/hao/Figures/CH06_UN16_Hao.png)

### There is no transitive dependency

A table in 3NF should have no transitive dependency. *Transitive dependency* occurs when something depends on something else that depends on yet another thing; it’s like a chain of things that need one another to work. In the context of database design, transitive dependency means that a nonkey column is functionally dependent on another nonkey column, which in turn is functionally dependent on a key of the table. The core concept of a transitive dependency is that one nonkey column’s value depends on another through a chain of dependencies, which is ultimately dependent on a key.

![Figure CH06_UN17](https://drek4537l1klr.cloudfront.net/hao/Figures/CH06_UN17_Hao.png)

A table representing employees has the following columns and functional dependencies:

![Figure CH06_UN18](https://drek4537l1klr.cloudfront.net/hao/Figures/CH06_UN18_Hao.png)

The primary key of the `employee` table is `employee_id`. In this table, `department_name` is dependent on `department_id`, and `department_id` is dependent on `employee_id`. This chained functional dependency is transitive dependency.

Transitive dependency is problematic. If a table contains transitive dependency, it leads to all kinds of problems, such as data redundancy and insertion/update/deletion anomalies. Updating a department name in the preceding `employee` table properly means updating all the `department_name` values in every row:

![Figure CH06_UN19](https://drek4537l1klr.cloudfront.net/hao/Figures/CH06_UN19_Hao.png)

What should you do with a table containing transitive dependency? Break the table into two or more tables, each table containing columns that are directly dependent on a key and dependent only on that key. Depending on the relationship between the two new tables, you may link them via a foreign key. If you stick to this principle, break the `employee` table into two tables as follows:

![Figure CH06_UN20](https://drek4537l1klr.cloudfront.net/hao/Figures/CH06_UN20_Hao.png)

The `department` table contains the nonkey columns that are involved in the transitive dependency, with the `department_id` as its primary key. The new `employee` table contains only the columns that are directly dependent on `employee_id` and dependent only on it, including the foreign key `department_id`. A foreign key is always directly dependent on the primary key because each row has a unique combination of the primary key and foreign key.

### Normalize your database design: A cycle involving three tables

A transitive dependency may be hard to spot without a deep understanding of the data, requirement analysis, and some sample data. Your `purchase` table, for example, uses two foreign keys, `email` and `payment_id`, to maintain its relationships with the `payment_method` and `user` tables:

![Figure CH06_UN21](https://drek4537l1klr.cloudfront.net/hao/Figures/CH06_UN21_Hao.png)

Without question, in the `purchase` table, all other non-primary-key columns are dependent on the primary key, including the foreign keys.

If you look beyond the `purchase` table, however, you notice something unexpected: the two foreign keys in the `purchase` table, `payment_id` and `email`, have a dependency relationship. From the `payment_method` table, you see that `email` is a foreign key that helps maintain the relationship between `payment_method` and `user`. As in the `purchase` table, the foreign key (`email`) is dependent on the primary key (`payment_method`). When you consider this new piece of information, you see a transitive dependency in `purchase`:

![Figure CH06_UN22](https://drek4537l1klr.cloudfront.net/hao/Figures/CH06_UN22_Hao.png)

In theory, you need only two relationships to connect three tables. If you notice that you are using three relationships and that the relationships are starting to look like a cycle in your E-R diagram, you may have a transitive dependency somewhere.

Now that you have identified the transitive dependency, how do you fix it? The principle is the same: a table should contain only columns that are directly dependent on the primary key and dependent only on it. You can remove the `email` column from the `purchase` table to break the direct relationship between the `user` and `purchase` tables, but `user` is still related to `purchase` via `payment_method`, as shown below.

![Figure CH06_UN23](https://drek4537l1klr.cloudfront.net/hao/Figures/CH06_UN23_Hao.png)

If normalization is your only concern, removing the link between the `user` and `purchase` tables is a brilliant move. But it may not be the best move if you are also concerned with other problems, such as query speed and cost. We will revisit the relationship between the `user` and `purchase` tables in chapter 7.

When you go through all other tables in your database design, you won’t see other transitive dependency problems. That said, you have completed all the steps to check each table against the 3NF requirements:

- It has a primary key.
- It has no multivalued columns.
- All columns are dependent on a key but nothing else.
- It contains no transitive dependency. (All its nonkey columns are directly dependent on a key.)

Your updated E-R diagram looks like this:

![Figure CH06_UN24](https://drek4537l1klr.cloudfront.net/hao/Figures/CH06_UN24_Hao.png)

## Implementation

When you finish normalization, you are ready to implement your database design. You learned how to create tables via SQL in chapters 1 and 2. With this knowledge, you may feel that you can translate your database design into SQL with little to no effort. Your `user` table looks like this in your E-R diagram:

![Figure CH06_UN25](https://drek4537l1klr.cloudfront.net/hao/Figures/CH06_UN25_Hao.png)

Translating this design directly to SQL leads to the following code snippet:

```sql
-- comment: works for MySQL and MariaDB
-- comment: see the code repo for other RDBMS
CREATE TABLE user (
	email VARCHAR(320) PRIMARY KEY,
	username VARCHAR(30),
	password VARCHAR(20),
	first_name VARCHAR(50),
	last_name VARCHAR(50),
	phone_number VARCHAR(15),
	last_login_time TIMESTAMP
);
```

Is the job done? Nope. To implement a database design successfully, you need to learn more about constraints and use that knowledge to make decisions beyond the E-R diagram.

You saw the use of constraints in chapter 2 but haven’t been formally introduced to them. *Constraints* are SQL rules applied to columns in a table to ensure data accuracy and reliability. Constraints are used to enforce data integrity and can be established during or after table creation. Without constraints, a database is like a toddler on a sugar high: chaotic and prone to causing havoc.

![Figure CH06_UN26](https://drek4537l1klr.cloudfront.net/hao/Figures/CH06_UN26_Hao.png)

In the following sections, you learn about common SQL constraints and other design decisions that you need to make. We don’t strive to cover all the constraints or SQL code required to implement the database. If you want to see the full SQL script, refer to the GitHub repository (https://mng.bz/4ao5).

### NOT NULL: Can’t have null-thing to say

The `NOT NULL` constraint ensures that a column does not accept `NULL` values in SQL. In other words, when the `NOT NULL` constraint is applied to a column, you have to provide a value for that column. The `NOT NULL` constraint can be handy for preventing problems in data storage and analytics. As we stated in chapter 1, a `NULL` value in SQL represents an unknown value. Allowing `NULL` values for columns may lead to unexpected behaviors in SQL.

![Figure CH06_UN27](https://drek4537l1klr.cloudfront.net/hao/Figures/CH06_UN27_Hao.png)

When do you need help from `NOT NULL` constraints? In most cases. Although their use depends on the requirements and the data, `NOT NULL` constraints are commonly applied in a wide range of scenarios. Columns that contain critical information for business operations (such as usernames, email addresses, or passwords) often have `NOT NULL` constraints. As another example, legal or compliance reasons force some columns to use `NOT NULL` constraints, such as date of birth in an option-trading application. Also, when two tables are related, the foreign keys may need `NOT NULL` constraints, depending on the nature of the relationship.

Do you have any columns that require `NOT NULL` constraints in the database design of The Sci-Fi Collective? Yes. Many columns in your database design contain critical data necessary for business operations. Six columns in the `user` table fall into this basket: `username`, `email`, `password`, `first_name`, `last_name`, and `last_login_time`.

![Figure CH06_UN28](https://drek4537l1klr.cloudfront.net/hao/Figures/CH06_UN28_Hao.png)

As a result, you’ll add `NOT NULL` constraints to these columns. You can do so by adding `NOT NULL` in the same code lines that define columns:

```sql
-- comment: works for MySQL, MariaDB, and SQLite
-- comment: see the code repo for other RDBMS
CREATE TABLE user (
	email VARCHAR(320) PRIMARY KEY,
	username VARCHAR(30) NOT NULL,
	password VARCHAR(20) NOT NULL,
	first_name VARCHAR(50) NOT NULL,
	last_name VARCHAR(50) NOT NULL,
	phone_number VARCHAR(15),
	last_login_time TIMESTAMP NOT NULL
);
```

You may notice that the primary key, `email`, doesn’t have the `NOT NULL` constraint. The reason is that it already has the `PRIMARY KEY` constraint, which implies a `NOT NULL` constraint and enforces it automatically.

### Primary key: The one and only

As you already know, in a solid database design, every table has a primary key. When such a design is translated to SQL, it is expressed as the primary key constraint.

The primary key constraint ensures that no duplicate rows with the same primary key exist in the same table. In addition, the primary key constraint guarantees that no row with a `NULL` value in the primary key column can be inserted into the table.

![Figure CH06_UN29](https://drek4537l1klr.cloudfront.net/hao/Figures/CH06_UN29_Hao.png)

The syntax of a primary key constraint is simple. You can add `PRIMARY KEY` to the code line that defines the column:

```sql
-- comment: works for MySQL, MariaDB and PostgreSQL
-- comment: see the code repo for other RDBMS
CREATE TABLE user (
	email VARCHAR(320) PRIMARY KEY,
	username VARCHAR(30) NOT NULL,
	password VARCHAR(20) NOT NULL,
	first_name VARCHAR(50) NOT NULL,
	last_name VARCHAR(50) NOT NULL,
	phone_number VARCHAR(15),
	last_login_time TIMESTAMP NOT NULL
);
```

If your database design is ongoing and there’s a chance that the primary key may change, however, you want to name the primary key constraint explicitly:

```sql
-- comment: works for MySQL, MariaDB and PostgreSQL
-- comment: see the code repo for other RDBMS
CREATE TABLE user (
	email VARCHAR(320),
	username VARCHAR(30) NOT NULL,
	password VARCHAR(20) NOT NULL,
	first_name VARCHAR(50) NOT NULL,
	last_name VARCHAR(50) NOT NULL,
	phone_number VARCHAR(15),
	last_login_time TIMESTAMP NOT NULL,
	CONSTRAINT pk_user PRIMARY KEY (email)
);
```

#### Naming constraints: A best practice

Naming constraints in SQL is not strictly required but is considered a best practice:

- Named constraints communicate their purpose clearly.
- Error messages become more informative.
- Avoid meaningless autogenerated names which vary across systems.

Certain inline constraints such as `NOT NULL` and `DEFAULT` are often left unnamed. Others (primary key, foreign key, unique, check) are often named when portability or maintenance matters.

What if you have a composite primary key that is composed of more than one column? You can define the primary key separately from any individual column definition. In the E-R diagram of The Sci-Fi Collective, the `purchase_product` table uses a composite primary key composed of two columns, `purchase_id` and `code`:

```sql
-- comment: works for MySQL, MariaDB, and PostgreSQL
-- comment: see the code repo for other RDBMS
CREATE TABLE purchase_product (
	purchase_id INT NOT NULL,
	code CHAR(12) NOT NULL,
	product_price DECIMAL(7,2) NOT NULL,
	product_quantity INT NOT NULL,
	product_name VARCHAR(100) NOT NULL,
	CONSTRAINT pk_purchase_product PRIMARY KEY (purchase_id, code)
);
```

### Foreign key: Playing Cupid

When two tables have a relationship, you use a foreign key to link them. A *foreign key* is at least one column in a table that refers to the primary key in another table. When a foreign key is translated to SQL, it is typically expressed as the foreign key constraint.

![Figure CH06_UN30](https://drek4537l1klr.cloudfront.net/hao/Figures/CH06_UN30_Hao.png)

The foreign key constraint enforces referential integrity. Given a relationship between two tables, the table containing the foreign key is the *child table*, and the other is the *parent table*. If you attempt to add a row to the child table but your foreign key value doesn’t exist yet in the parent table, SQL will reject it.

You have a one-to-many relationship between the `user` and `review` tables. In the `review` table, `email` is the foreign key that links `review` to `user`. If implemented properly, SQL should stop you if you try to add a `review` record with an `email` value that doesn’t exist in `user` yet.

![Figure CH06_UN31](https://drek4537l1klr.cloudfront.net/hao/Figures/CH06_UN31_Hao.png)

Implementing a foreign key constraint is similar to implementing a primary key constraint. The `review` table contains two foreign keys that reference the `user` and `product` tables:

```sql
-- comment: works for MySQL and MariaDB
-- comment: see the code repo for other RDBMS
CREATE TABLE review (
	review_id INT PRIMARY KEY,
	review_text TEXT NOT NULL,
	review_time TIMESTAMP NOT NULL,
	email VARCHAR(320) NOT NULL,
	code CHAR(12) NOT NULL,
	CONSTRAINT fk_user_review FOREIGN KEY (email) REFERENCES user(email),
	CONSTRAINT fk_product_review FOREIGN KEY (code) REFERENCES product(code)
);
```

Or define them afterward (not supported in SQLite for adding named constraints this way):

```sql
-- comment: works for MySQL, MariaDB and PostgreSQL
-- comment: SQLite doesn’t support ALTER TABLE ADD CONSTRAINT the same way
CREATE TABLE review (
	review_id INT PRIMARY KEY,
	review_text TEXT NOT NULL,
	review_time TIMESTAMP NOT NULL,
	email VARCHAR(320) NOT NULL,
	code CHAR(12) NOT NULL
);
ALTER TABLE review
	ADD CONSTRAINT fk_user_review FOREIGN KEY (email) REFERENCES user(email),
	ADD CONSTRAINT fk_product_review FOREIGN KEY (code) REFERENCES product(code);
```

It is worth noting that when a relationship is mandatory, the foreign key typically requires help from the `NOT NULL` constraint. If the minimum cardinality from `review` to `user` is one, then `email` should not allow `NULL`.

![Figure CH06_UN32](https://drek4537l1klr.cloudfront.net/hao/Figures/CH06_UN32_Hao.png)

### Referential actions

Foreign key constraints also govern behavior on update and delete operations. Beyond insertion, referential integrity cares about deletion and updating of parent rows.

![Figure CH06_UN33](https://drek4537l1klr.cloudfront.net/hao/Figures/CH06_UN33_Hao.png)

By default (RESTRICT / NO ACTION), the database prevents deleting or updating a parent row if matching child rows exist. You can specify these explicitly:

```
ON DELETE RESTRICT
ON UPDATE RESTRICT
```

When you need dependent rows to follow changes automatically, you can use `CASCADE`:

- `CASCADE` delete — Deleting a parent row deletes corresponding child rows.
- `CASCADE` update — Updating a primary key propagates to child foreign keys.

Syntax:

```
ON DELETE CASCADE
ON UPDATE CASCADE
```

![Figure CH06_UN34](https://drek4537l1klr.cloudfront.net/hao/Figures/CH06_UN34_Hao.png)

Less commonly, you may want to keep child rows but null out the foreign key when the parent is deleted—`SET NULL`:

```
ON DELETE SET NULL
ON UPDATE CASCADE
```

With `SET NULL`, foreign key values become `NULL` (so the column must allow `NULL`). Use sparingly to avoid orphan semantics.

Do you have any relationships that need explicit referential actions? Yes. The `user` table is a parent of tables including `payment_method`. If users can change or delete accounts, cascading helps maintain integrity:

```sql
-- comment: works for MySQL, MariaDB and PostgreSQL
-- comment: see the code repo for other RDBMS
CREATE TABLE payment_method (
	payment_id INT PRIMARY KEY,
	name VARCHAR(30) NOT NULL,
	card_number CHAR(16) NOT NULL,
	expiry_date CHAR(4) NOT NULL,
	email VARCHAR(320) NOT NULL,
	CONSTRAINT fk_payment_method_user
		FOREIGN KEY (email) REFERENCES user (email)
		ON DELETE CASCADE
		ON UPDATE CASCADE
);
```

### Unique: Sorry, I’m taken

Unique constraints ensure that all values in a column or a combination of columns are different. If you have some nonkey columns that should all contain unique values, you need to apply unique constraints.

![Figure CH06_UN36](https://drek4537l1klr.cloudfront.net/hao/Figures/CH06_UN36_Hao.png)

Example: An SSN column should be unique among people even if it is not the primary key.

In your design, the `username` and `phone_number` columns in `user` must be unique (nonkey columns):

```sql
-- comment: works for MySQL, MariaDB and PostgreSQL
-- comment: see the code repo for other RDBMS
CREATE TABLE user (
	email VARCHAR(320) PRIMARY KEY,
	username VARCHAR(30) NOT NULL,
	password VARCHAR(20) NOT NULL,
	first_name VARCHAR(50) NOT NULL,
	last_name VARCHAR(50) NOT NULL,
	phone_number VARCHAR(15),
	last_login_name TIMESTAMP NOT NULL,
	CONSTRAINT unq_username UNIQUE(username),
	CONSTRAINT unq_phone_number UNIQUE(phone_number)
);
```

Sometimes uniqueness applies to a combination of columns. Suppose you must ensure uniqueness of (name, manufacturer) in `product`:

```sql
-- comment: works for MySQL, MariaDB and PostgreSQL
-- comment: see the code repo for other RDBMS
CREATE TABLE product (
	code CHAR(12) PRIMARY KEY,
	name VARCHAR(100) NOT NULL,
	description TEXT NOT NULL,
	manufacturer VARCHAR(100) NOT NULL,
	photo VARCHAR(1000) NOT NULL,
	price DECIMAL(7,2) NOT NULL,
	cost DECIMAL(7,2) NOT NULL,
	inventory_quantity INT,
	CONSTRAINT unq_name_manufacturer UNIQUE(name, manufacturer)
);
```

### Default to awesome

You use the default constraint to set a default value for a column when a new row is inserted and no value is provided. Typical cases:

- Timestamp columns (created_at, modified_at)
- Numeric counters or amounts
- Optional columns needing placeholders

Your `purchase` table includes `purchase_time` which should default to the current time:

![Figure CH06_UN39](https://drek4537l1klr.cloudfront.net/hao/Figures/CH06_UN39_Hao.png)

```sql
CREATE TABLE purchase (
	purchase_id INT PRIMARY KEY,
	total_price DECIMAL(13,2) NOT NULL,
	purchase_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	payment_id INT NOT NULL,
	CONSTRAINT fk_payment_method_purchase
		FOREIGN KEY (payment_id) REFERENCES payment_method(payment_id)
);
```

Notes:

- `NOT NULL` is still useful; a default does not prevent explicit insertion of `NULL`.
- `CURRENT_TIMESTAMP` is widely supported (MySQL, MariaDB, SQLite, PostgreSQL).

#### Clocking databases: Navigating UTC across RDBMSs

Storing in UTC avoids DST and time zone headaches. `CURRENT_TIMESTAMP` may already store UTC (e.g., MySQL internally normalizes). In PostgreSQL you need `TIMESTAMP WITH TIME ZONE` if you want timezone-aware values:

```sql
-- PostgreSQL
CREATE TABLE purchase (
	purchase_id INT PRIMARY KEY,
	total_price DECIMAL(13,2) NOT NULL,
	purchase_time TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
	payment_id INT NOT NULL,
	CONSTRAINT fk_payment_method_purchase
		FOREIGN KEY (payment_id) REFERENCES payment_method(payment_id)
);
```

Check your RDBMS docs (or ask an assistant) for exact behavior in a new system.

### Check: Enforce data decorum

A *check constraint* is a rule that specifies a condition each row must meet. Use it to enforce data ranges or formats.

Example enforcing age range:

```sql
-- comment: works for MySQL, MariaDB and PostgreSQL
CREATE TABLE person (
	person_id INT NOT NULL,
	last_name VARCHAR(255) NOT NULL,
	first_name VARCHAR(255),
	age INT,
	CONSTRAINT age_check CHECK (age >= 0 AND age <= 120)
);
```

In your design, `user_address.state` (and similarly `billing_address.state`) should be constrained to valid U.S. state names. Example:

```sql
-- comment: works for MySQL, MariaDB, PostgreSQL, Oracle
CREATE TABLE user_address (
	email VARCHAR(320) PRIMARY KEY,
	street_address VARCHAR(255),
	address_line_optional VARCHAR(100),
	city CHAR(100) NOT NULL,
	state VARCHAR(20) NOT NULL,
	postal_code CHAR(5) NOT NULL
);
ALTER TABLE user_address
	ADD CONSTRAINT chk_state
	CHECK (
		state IN (
			'Alabama','Alaska','Arizona','Arkansas','California',
			-- ... other states ...
			'West Virginia','Wisconsin','Wyoming'
		)
	);
```

The `IN` list defines allowed values.

## Recap

![Figure CH06_UN40](https://drek4537l1klr.cloudfront.net/hao/Figures/CH06_UN40_Hao.png)

- Normalization is the process of breaking the database into smaller, more manageable tables, each representing a single entity or concept.
- Typically, when all your tables are in BCNF, you can consider your database fully normalized. A table in BCNF must:
	- Have a primary key.
	- Have no multivalued columns.
	- Have all columns dependent on a key but nothing else.
	- Contain no transitive dependency (all nonkey columns directly depend on a key).
- `NOT NULL` and primary key/foreign key constraints play critical roles.
- Name constraints when possible for clarity and portability.
- Use `NOT NULL` to avoid unknowns, `UNIQUE` for alternate uniqueness, `DEFAULT` for timestamps/placeholders, `CHECK` for value validation.
