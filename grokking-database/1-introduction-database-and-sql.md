# 1 Introducing databases and SQL

## In this chapter

- You get a foundation for the rest of the book.
- You learn the basics of relational databases.
- You peek into database design.
- You write your first SQL query and learn more about the basics of SQL.

### What you need to know

As you read this chapter, you will find some code snippets. If you want to execute those code snippets or see what changes need to be made to the code for different relational database management systems (RDBMSs), check the GitHub repository that accompanies this book (https://github.com/Neo-Hao/grokking-relational-database-design). You can find the scripts for this chapter in the `chapter_01` folder; follow the instructions in the `README.md` file to run the scripts.

## Overview

Database design is a critical yet easily neglected step in software development. Nearly every application requires data storage and management to some extent, but not every application has a well-designed database. If you design a database without knowing the principles of effective database design, your application may suffer from problems you weren’t expecting, such as disorganized data or queries that take too long and too many resources to run. These problems can lead to bugs and a bad user experience.

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH01_UN01_Hao.png)

By contrast, effective database design can serve as a solid foundation for effective software development. Effective database design makes sure that an application’s data is well organized and structured, which in turn supports efficient data querying and manipulation that contributes to solid applications and superior user experience. Regardless of where you are in your journey of learning programming and software development, it is essential to learn how to design databases effectively and possibly how to talk to nontech people without making their eyes glaze over with boredom as well.

This book covers how to design databases and assumes no previous knowledge of databases or programming. By the end of this book, you will have a good understanding of how to design relational databases from scratch. We aim to help you achieve this goal via down-to-earth definitions and explanations, rich examples, and active learning practice.

This chapter aims to introduce relational databases, define a set of terms that you will see in the next few chapters, and cover the basics of *Structured Query Language* (SQL). SQL (often pronounced “sequel”) is the programming language used to manage data in relational databases, and it’s essential for you to have some understanding of SQL to have a robust understanding of database design.

### Relational databases

Once upon a time, a small company used Microsoft Excel spreadsheets to store all its customer data. At first, everything seemed to run smoothly, and the company was able to access and update the data as needed. As time went on, the company grew and acquired more customers, and the spreadsheets became increasingly more difficult to manage. There were duplicates and inconsistencies in the data, and the spreadsheets became so large and unwieldy that they took a long time to load and update.

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH01_UN02_Hao.png)

One day, the company received a call from a customer who was charged twice for a single purchase. When the company tried to access the customer’s data in a spreadsheet to investigate the problem, they found that the data had been corrupted and was no longer accessible. As more and more customers began to report similar problems, the company learned the hard way that spreadsheets are a bad choice for storing customer data. The company eventually invested in a relational database system that could handle the scale of its data and ensure the integrity of its records.

If you have a very small amount of data with a simple structure to store, a spreadsheet can get the job done; you don’t need a database at all. However, as data complexity and volume increase, you probably should think again. When you need to apply access control to the data, maintain its consistency, integrity, and scalability, and conduct routine data analysis, you absolutely need a database.

Relational databases have been, and still are, the default technology for storing and accessing data when scale, data consistency, and data integrity are all required. In recent years, machine learning and AI have helped sustain and even boost the popularity of relational databases. In this section, you will learn some fundamental concepts of relational databases, such as tables, entities, and RDBMS.

### Tables, entities, and primary keys

A *relational database* is a collection of tables that store data. A table is like a spreadsheet, which you are likely familiar with. Just like a spreadsheet, the data in a table is organized into rows and columns. A table can be used to represent an entity or a relationship between entities, with each row representing a single data record of that entity and each column representing an attribute of that entity.

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH01_UN02_MARG01_Hao.png)

What is an entity? An *entity* is an object or concept that can be described by many attributes. Suppose that we are running an online store called The Sci-Fi Collective that sells sci-fi products (such as a time machine that takes you back only 5 minutes, in case you forgot your keys). Products sold by The Sci-Fi Collective are entities, and each can be described by at least four attributes: name, description, price, and manufacturer. When we map products to a table in the database supporting the online store of The Sci-Fi Collective, the four attributes will be mapped to four individual columns, and each product will be represented as a row in this table.

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH01_UN03_Hao.png)

In addition to the four columns, you may notice that we added another column, `product_id`, in the preceding table. All values in the `product_id` column are unique and can be used to identify an individual row. We call `product_id` the *primary key* of the `product` table. Think of the primary key as the “one ring to rule them all”: each table can have only one to uniquely identify its rows. You can find a much deeper discussion of primary keys in chapter 4.

It is not uncommon for one spreadsheet to store the information of multiple entities. You may wonder whether to do the same with tables in a relational database. If we decide to store the information of customers and products in one table for The Sci-Fi Collective, for example, the table will look like this:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH01_UN04_Hao.png)

This table is a typical poorly designed table. Beyond the data redundancy, which you can spot easily, such a design can cause many unexpected problems. If a customer’s information appears in only one row, for example, when we want to delete a product, we will have to delete the customer in the same row from our database. This problem is known as a *delete anomaly*. Consider another example: from time to time we need to insert into this table a product that no customers have bought, but the table requires us to provide valid customer information whenever we add a row. The contradicting requirements leave us in an awkward situation; we can’t add any new products. This problem is known as an *insertion anomaly*.

As you can see, bad database design can lead to problems that negatively affect software quality. To avoid such problems, you must master the basic principles and best practices of database design.

### Relational database management systems and SQL

Relational databases and tables rely on the help of RDBMS to physically store and manage the data. Edgar Codd at IBM developed the first RDBMS in the 1970s.

An *RDBMS* is software that interacts with the underlying hardware and operating system to physically store and manage data in relational databases. Additionally, an RDBMS provides tools to create, modify, and query databases along with other important functions such as security controls. You may be familiar with some commonly used RDBMS, such as MySQL, MariaDB, PostgreSQL, and SQLite. When you need to deploy a database that you designed, you will need to interact with one of the available RDBMS on the market.

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH01_UN05_Hao.png)

One of the most notable tools that nearly all RDBMSs support is SQL, a programming language that you can use to create, modify, and query data stored in tables in an RDBMS. Although different RDBMS vendors may implement their own variations and extensions, SQL has been standardized over the years. As a result, the consistency of SQL among RDBMSs is high, and the variations don’t matter much in the context of this book.

Because this book is primarily a database design book, of course, SQL may seem less important. Database design doesn’t necessarily require you to use SQL. Some RDBMS comes with graphical tools to generate SQL scripts that automatically create databases and tables based on your design. But having some understanding of SQL can make it easier to learn database design, especially when it relates to structural or design problems such as data integrity, optimization, and scalability. After all, SQL is a standardized language that most RDBMSs use, so knowing SQL will allow you to rely less on graphical tools and work with different types of RDBMSs. We will cover the basics of SQL in this chapter and in chapter 2.

## Your first SQL query

In this section, you will learn SQL by executing your first SQL query. We will use the example that you saw in the preceding section, the database of The Sci-Fi Collective (because who doesn’t like sci-fi stuff?). The database contains many tables, but the `product` table is all you need to focus on for now. The `product` table looks like the following:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH01_UN06_Hao.png)

First, you will load a prepared SQL script to generate a database and this table. We prepared the SQL scripts that generate this table with data, which you can find in our GitHub repository (https://github.com/Neo-Hao/grokking-relational-database-design). You can follow the instructions of the `README.md` file in the `chapter_01` folder to execute the prepared script for your preferred RDBMS or tool. The easiest approach is to use SQLite Online, as follows:

1. Clone or download our GitHub repository (https://github.com/Neo-Hao/grokking-relational-database-design).
2. Navigate to SQLite Online (https://sqliteonline.com).
3. Choose your target RDBMS in the left sidebar, and click the Click button to Connect.
4. Click Import, and load the script corresponding to your chosen RDBMS (such as `mysql_db.sql` from the downloaded or cloned GitHub repository for MariaDB).
5. Click Okay.

After that, you will be ready to query the `product` table. You can type the following query (as a whole) into the code editor on SQLite Online and then click Run:

```sql
SELECT name
FROM product
WHERE price > 20;
```

What does this query do? The `price > 20` part may be a dead giveaway. The query retrieves the names of products whose prices are higher than `20`. We know that there are 10 rows representing 10 products in the `product` table and that 5 products (such as Atomic Nose Hair Trimmer) sell at a price below `20`, so the names of the other 5 products are returned. Your result should look like this:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH01_UN07_Hao.png)

You may notice that this SQL query has a lot of similarities to plain English. The reason is that SQL is special. You see, most programming languages are imperative. Coding with an *imperative* language, such as Java or Python, requires you to specify both what to do and how to do it. SQL, however, is *declarative*, which means that you need to specify only what to do. The steps required to carry out the task are SQL’s job to figure out. Specifying what you want instead of how to get it done is more natural for human beings, and that’s why SQL resembles plain English.

To be specific, SQL is like English, with little to no small talk. But you don’t have the same freedom in word choices when it comes to putting together a SQL query. You must use a set of SQL clauses (also known as *statements*) and follow some rules. In your first query, you used the following three clauses:

- `SELECT` — The `SELECT` clause allows you to specify the columns you want to retrieve from a table. In your first query, you only asked for the `name` column; thus, the `SELECT` statement was `SELECT name`.
- `FROM` — The `FROM` clause specifies the source you want to retrieve data from one or more tables. In your first query, you asked only for data from the `product` table; thus, the `FROM` clause was `FROM product`.
- `WHERE` — The `WHERE` clause allows you to specify conditions to filter the data retrieved by the `SELECT` clause. In your first query, you want only the names of those products whose prices are higher than `20`; thus, the query was `SELECT name FROM product WHERE price > 20;`.

When you finish a SQL query, you should use a semicolon (`;`) to indicate its end. The semicolon tells the RDBMS that this is the end of a SQL query and that anything after it belongs to a new query.

## The basics of SQL queries

Our preferred approach for learning SQL is to grasp the most important clauses and learn the rest only when necessary. Although SQL has many clauses, they are not equally important. The most important ones can help you build a solid foundation, as well as construct a mental map that can guide your future learning.

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH01_UN08_Hao.png)

Therefore, instead of trying to cover every SQL clause, we will cover only the ones that are essential or critical to your future learning. In this chapter, you will learn important clauses that you can use to query a single table.

### Filtering

Filtering is a common data retrieval task. Whenever you need only a subset of data that meets some criteria, you need the help of the `WHERE` clause to filter the data.

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH01_UN08_MARG02_Hao.png)

From your first SQL query, you know that the `WHERE` clause is followed by the criteria you want to use to filter the data. The following query, for example, retrieves the names and descriptions of products whose prices are lower than `30` from the `product` table:

```sql
SELECT name, description
FROM product
WHERE price < 30;
```

When you want to retrieve more than one column, you can list all of them after the `SELECT` keyword and separate them with commas.

What if we want to retrieve only the products that come from a specific manufacturer, such as Mad Inventors Inc.? We can achieve this via the following query:

```sql
SELECT name
FROM product
WHERE manufacturer = 'Mad Inventors Inc.';
```

This query yields the following result:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH01_UN09_Hao.png)

In the preceding query, the operator that checks equality is a single equal sign (`=`). Additionally, you may notice that the manufacturer name is wrapped in single quotes (`' '`), indicating a string data type. Does SQL have different data types? Yes. SQL data can be broadly divided into six categories:

- Numeric data types (such as `INT`)
- String data types (such as `TEXT`)
- Date or time data types (such as `DATE`)
- Unicode character string data types (such as `VARCHAR`)
- Binary data types (such as `BINARY`)
- Miscellaneous data types (such as `XML`)

In the `product` table, the data type of the `manufacturer` column is string. By contrast, the `price` column is numeric.

Now that you know how to filter both numeric and string data, you can create one filter that combines the two criteria by using logical operators. `AND` and `OR` are the two most frequently used logical operators. The `AND` operator means the same as it does in plain English; the same can be said of `OR`. We can combine two individual criteria using `AND`, as follows:

```sql
SELECT *
FROM product
WHERE price < 30 AND
manufacturer = 'Mad Inventors Inc.';
```

This query yields the following result:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH01_UN10_Hao.png)

Unlike previous queries, this query retrieves every column from the `product` table. The star (`*`) following the `SELECT` keyword indicates all columns. The combination of the two filtering criteria retrieves all columns of only the products that are manufactured by Mad Inventors Inc. and have a price below `30`.

### Aggregation

Aggregation, an important task in SQL, involves performing calculations on a set of rows to produce a single result. By aggregating data, you can gain insights into trends and patterns in the data that may not be visible at the individual record level. The most frequently used aggregate functions are

- `COUNT()` — Counts the number of rows
- `SUM()` — Calculates the sum of values in a numeric column
- `AVG()` — Calculates the average value in a numeric column
- `MAX()` — Finds the maximum value in a column
- `MIN()` — Finds the minimum value in a column

When we formulate a SQL query that involves aggregation, we should place the aggregate function in the `SELECT` statement. We can count the number of rows in the `product` table this way:

```sql
SELECT COUNT(*) FROM product;
```

This query yields the following result:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH01_UN11_Hao.png)

You may notice that the column name is the same as the aggregate function command. If you are dealing with an RDBMS other than MariaDB, the column name may be `COUNT()` or something else. If you don’t like the default column name, you can provide a more readable one by using an alias via the `AS` clause. You can calculate the average price of all products that are sold in the store and use `avg_price` as the column name, as in this example:

```sql
SELECT AVG(price) AS avg_price
FROM product
WHERE manufacturer = 'Mad Inventors Inc.';
```

This query yields the following result, in which the column name is `avg_price` and the only value is the average of all product prices in the table:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH01_UN12_Hao.png)

In both examples, you applied aggregate functions to all rows in a table. You can also apply aggregate functions to multiple groups of rows in a table. Sometimes, you need to group the data by one or more columns and analyze the grouped data. You can group data via the `GROUP BY` clause, which is commonly used in combination with aggregate functions. The `GROUP BY` clause is always followed by one or more attribute names separated by commas. You can count the number of products per manufacturer like this:

```sql
SELECT COUNT(*) AS product_count, manufacturer
FROM product
GROUP BY manufacturer;
```

This query yields the following result, possibly in varying order:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH01_UN13_Hao.png)

As another example, you can calculate the average price of products per manufacturer:

```sql
SELECT AVG(price) AS avg_price, manufacturer
FROM product
GROUP BY manufacturer;
```

This query yields the following result:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH01_UN14_Hao.png)

When you use aggregate functions with the `GROUP BY` clause, you need to include the attributes following the `GROUP BY` clause in the `SELECT` statement. Otherwise, the results may not make much sense. The following query groups the data by the `manufacturer` column but doesn’t include it in the `SELECT` statement:

```sql
--comment: will yield something difficult to interpret
SELECT COUNT(*) AS product_count
FROM product
GROUP BY manufacturer;
```

The result will be much harder to chew because you see only a column of numbers and have no idea what the numbers stand for:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH01_UN15_Hao.png)

As another example, the following query calculates the average product price per manufacturer but doesn’t include the `manufacturer` column in the `SELECT` statement:

```sql
--comment: will yield something difficult to interpret
SELECT AVG(price) AS avg_price
FROM product
GROUP BY manufacturer;
```

As in the last example, the result is difficult to interpret because you see only a column of decimals and have no idea what they stand for:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH01_UN16_Hao.png)

More important, you should exclude from the `SELECT` statement any columns that are not in the `GROUP BY` clause unless they are used with aggregate functions. The following query attempts to count the number of products per manufacturer, but the `name` column in the `SELECT` statement is neither in the `GROUP BY` clause nor used with an aggregate function:

```sql
-- comment: will either lead to an error 
-- comment: or yield a misleading result
SELECT COUNT(*) AS product_count, manufacturer, name
FROM product
GROUP BY manufacturer;
```

A query like this one leads to errors or yields a misleading result, depending on the RDBMS you use. PostgreSQL, for example, will make the following complaint:

```text
ERROR: column "product.name" must appear 
in the GROUP BY clause or be used in 
an aggregate function
```

SQLite yields a misleading result without complaint:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH01_UN17_Hao.png)

If you check all 10 products in the `product` table, you see that there is only 1 Atomic Nose Hair Trimmer instead of 3. But because the query doesn’t know how to deal with the `name` column, it simply shows the `name` value in the first row it encounters per group.

As another example, the following query attempts to calculate the average price of products per manufacturer, but the `product_id` column in the `SELECT` statement is not in the `GROUP BY` clause:

```sql
-- comment: will either lead to an error 
-- comment: or yield a misleading result
SELECT product_id, AVG(price) AS avg_price, manufacturer
FROM product
GROUP BY manufacturer;
```

Depending on the RDBMS you use, you may get either an error or a misleading result. PostgreSQL, for example, will make the following complaint:

```text
ERROR: column "product.product_id" must appear 
in the GROUP BY clause or be used in an 
aggregate function
```

SQLite will yield a misleading result without complaint:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH01_UN18_Hao.png)

If you check the third row of the `product` table, you will see that its price is `29.99` instead of `22.5449…`. The preceding aggregated result is obviously wrong. Because this query doesn’t know how to deal with the `product_id` column, it simply shows the first `product_id` value it encounters per manufacturer group.

In summary, when you use aggregate functions with the `GROUP BY` clause, you need to be careful about what attributes to include in the `SELECT` statement. The `SELECT` statement should contain only those nonaggregate attributes that show up in the `GROUP BY` clause. *Nonaggregate attributes* are attributes that are not involved in aggregation.

## Table and data management

You’ve worked with SQL on a table that we gave you, but sometimes, you need to make your own tables and to manage those tables and their data.

Table and data management are important tasks in SQL. The SQL commands dedicated to such tasks are commonly known as *data definition language* (DDL). By contrast, the SQL clauses and statements you saw in previous sections are known as *data manipulation language*. Understanding some DDL is particularly useful for database design.

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH01_UN19_Hao.png)

In this section, you will learn three common table management tasks: creating, altering, and deleting a table. You will also learn how to add data to a new table.

### Create tables and add data to tables

You will learn how to create a table and add data to it from the prepared scripts that accompany this chapter. The scripts (such as `mysql_db.sql` for MySQL or MariaDB) aim to create the `product` table for the database supporting The Sci-Fi Collective and populate it with a set of sample data. The `product` table is created with the following command:

```sql
CREATE TABLE product (
 product_id INT PRIMARY KEY,
 name TEXT NOT NULL,
 description TEXT NOT NULL,
 price DECIMAL(5, 2) NOT NULL,
 manufacturer TEXT NOT NULL
);
```

We need to answer two questions about the command that creates the `product` table:

- What is the general syntax for creating a table?
- What do the different keywords do in this query example?

#### SQL drama: When your tables throw a fit over duplications

If you have followed along and imported the given SQL script in previous sections, you will see some complaints from SQL when you try to run the following `CREATE TABLE` command.

Why? You ran the same command when you imported the given SQL script in the section “Your first SQL query,” which creates a table named `product`. The same RDBMS can’t have two tables with the same name. The same can be said of the data insertion commands that will be covered next. A table can’t have two identical rows, especially not two rows with the same primary key.

If you want to run the `CREATE TABLE` and data insertion commands covered in this section after importing the prepared scripts, you can do the following:

- If you are using SQLite Online, you can easily reset everything by refreshing the browser tab.
- If you are using an RDBMS running locally or on a server, you need to delete that corresponding table first. You will learn more about deleting and altering tables in this section.

What is the general syntax for creating a table? To create a table, you need the help of the `CREATE TABLE` command. The syntax of the `CREATE TABLE` command is as follows:

```sql
CREATE TABLE table_name (
 column1_name datatype [optional_parameters],
 column2_name datatype [optional_parameters],
 ...
 columnN_name datatype [optional_parameters],
 PRIMARY KEY (columnX_name)
);
```

The definition of the primary key can also be part of the definition of a column, as you saw in the `product` table example. Unlike optional parameters, the primary key is required in every table.

What do the different keywords do in this query example? First, we specified the table name as `product` and defined five columns:

- `product_id` — A numeric data type (`INT`)
- `name` — A string data type (`TEXT`)
- `description` — A string data type (`TEXT`)
- `price` — A numeric data type (`DECIMAL`)
- `manufacturer` — A string data type (`TEXT`)

`INT` indicates integer, and `TEXT` indicates string. The only data type worth explaining here is probably `DECIMAL`. `DECIMAL`, as a numeric data type, accepts two parameters. The first parameter defines the total number of digits, and the second one defines the number of digits to the right of the decimal point. We use `DECIMAL(5,2)`, for example, to define the price attribute to allow five digits in total and two digits to the right of the decimal point.

In addition to the data types, you may notice that we specified every attribute as `NOT NULL`. In SQL, a `NULL` value represents an unknown value. Similar to when you’re trying to remember someone’s name and it’s on the tip of your tongue, the value is either missing or unknown. Allowing `NULL` values for attributes may lead SQL to have unexpected behaviors. When you add 10 and a `NULL` value, for example, you end up with a `NULL` value; the sum of an unknown value and 10 is still unknown. When you do calculations on `NULL` values, all the results may end up as `NULL`.

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH01_UN20_Hao.png)

Last, the `PRIMARY KEY` definition was used to specify which attribute we want to use as the primary key for this table. The attribute name needs to be placed in parentheses following the `PRIMARY KEY` definition.

When the `product` table is created in a database, it is ready for you to add data to it. To add data to a table, you need help from the `INSERT INTO` command. The `INSERT INTO` command allows you to insert one or more rows of data into a table. Here’s its basic syntax:

```sql
INSERT INTO table_name (column1, column2, ...)
VALUES (value1, value2, ...);
```

In the same script, you can find an example of adding data to the `product` table. You can insert a single row into the table as follows:

```sql
INSERT INTO product (product_id, name, description, 
price, manufacturer)
VALUES (
 1,
 'Atomic Nose Hair Trimmer',
 'Trim your nose hairs... of an atomic clock!',
 19.99,
 'Mad Inventors Inc.'
);
```

Or you can insert multiple rows of data into the table:

```sql
INSERT INTO product 
(product_id, name, description, price, manufacturer)
VALUES 
(
 2,
 'Selfie Toaster',
 'Get your face on... with our selfie toaster',
 24.99,
 'Goofy Gadgets Corp.'
),
(
 3,
 'Cat-Poop Coffee',
 'The only coffee... the finest cat poop ...',
 29.99,
 'Absurd Accessories'
);
```

### Alter and drop tables

From time to time, you may need to alter or drop an existing table because—let’s face it—sometimes you need to rearrange the furniture in your data house.

There are many ways to alter a table, such as adding a column, modifying the data type of a column, or renaming the entire table. You can rely on the help of the `ALTER TABLE` command to perform all these tasks. If you want to add another column representing serial numbers to the `product` table, for example, you can use the following query:

```sql
ALTER TABLE product
ADD serial_number INT;
```

When the preceding query gets executed, a new column named `serial_number` is added to this table, and its data type is integer. When you realize that integer is not the best data type for serial numbers, you may update its data type to string via the following query:

```sql
-- comment: SQLite doesn’t support altering
-- comment: a column’s data type directly
ALTER TABLE product
ALTER COLUMN serial_number TEXT;
```

Although you have many ways to alter a table, there’s only one way to drop a table. To do so, you need the `DROP TABLE` command followed by the name of the table you want to drop. If you intend to drop the `product` table, for example, you can use the following query:

```sql
DROP TABLE_product;
```

You need to be careful when using the `DROP TABLE` command because it will permanently delete the table and all its data.

This section doesn’t aim to be an exhaustive list of all commands for altering or dropping a table. If you want to know more, please check out the SQL manual or your target RDBMS. That said, you have taken an important step toward mastering databases and database design. The things you’ve achieved in this chapter will propel your learning throughout the rest of the book—small choices that may cascade into a design masterpiece worthy of being displayed in a tech gala one day, should they ever become reality.

## Recap

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH01_UN21_Hao.png)

- A relational database is a collection of tables that store data.
- A table is used to represent an entity or a relationship between entities in a database.
- An entity is an object or concept that can be described by many attributes.
- An RDBMS is software that interacts with the underlying hardware and operating system to physically store and manage data in relational databases.
- Filtering data requires help from at least three SQL clauses: `SELECT`, `FROM`, and `WHERE`.
- Data aggregation functions are often used in combination with the `GROUP BY` clause.
- SQL commands that are used to manage tables are known as DDL. Table management typically involves three commands: `CREATE TABLE`, `ALTER TABLE`, and `DROP TABLE`.
- You can insert a single row or multiple rows of data into a table via the `INSERT TO … VALUE …` statement.