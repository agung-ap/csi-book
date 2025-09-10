# 2 Related tables and more SQL

### In this chapter
- You learn what related tables are and how to query them.
- You revisit table and data management.
- You explore how to learn more SQL on your own.

> **What you need to know**
>
> To understand the SQL covered in this chapter, you need to know what databases and tables are, as well as the basics of SQL queries. If not, read chapter 1 first.
>
> As you read this chapter, you will find more code snippets. If you want to execute those code snippets or see their variations for different relational database management systems (RDMBSs), check the GitHub repository that accompanies this book ([https://github.com/Neo-Hao/grokking-relational-database-design](https://github.com/Neo-Hao/grokking-relational-database-design)). You can find the scripts for this chapter in the `chapter_02` folder; follow the instructions in the `README.md` file to run the scripts.
>
> The easiest approach is to use SQLite Online as follows:
> 1. Clone or download our GitHub repository ([https://github.com/Neo-Hao/grokking-relational-database-design](https://github.com/Neo-Hao/grokking-relational-database-design)).
> 2. Locate the scripts in the `chapter_02` folder.
> 3. Visit [https://sqliteonline.com](https://sqliteonline.com). Choose your target RDBMS in the left sidebar and click Click to Connect.
> 4. Click Import to load the script corresponding to your chosen RDBMS (such as `mysql_db.sql` from the downloaded or cloned GitHub repository for MariaDB).
> 5. Click Okay.

## Overview
In chapter 1, you learned the basics of SQL, and you learned how to query or create a single table. In this chapter, you will continue learning a bit more of SQL by querying and creating related tables. Then you will peek into how to pick up more SQL keywords by yourself in the future.

## Related tables
In this section, you will learn how to work with two or more tables that are related. These *related tables* are tables in a database that are connected by one or more common columns. The Sci-Fi Collective, for example (the online store you know from chapter 1), allows customers to create user accounts, shop online, and leave reviews for the products they bought. The Sci-Fi Collective is supported by a database composed of multiple tables. Among these tables are two that are related: `product` and `review`. The `product` table represents the products that are sold, and the `review` table represents the reviews customers leave for the products they bought. The two tables have a common column (`product_id`). The relationship between the two tables is summarized in the following figure:

![product-review relationship](https://drek4537l1klr.cloudfront.net/hao/Figures/CH02_UN01_Hao.png)

The `product_id` column is shared by the `product` and `review` tables. In the `product` table, the `product_id` column is the primary key. In the `review` table, the `product_id` column is known as the *foreign key*, which refers to the primary key of another table. In this case, the other table is `product`.

In other words, the value in the `product_id` column helps connect a row in the `product` table and a row in the `review` table. In the `product` table, for example, the row with a `product_id` value of `3` records a product named Cat-Poop Coffee; in the `review` table, the row with a `review_id` value of `1` records a positive review for Cat-Poop Coffee. How would you know that the review is for Cat-Poop Coffee? The two rows have the same `product_id` value.

### Number(s) of shared columns
As curious as you are, you may wonder whether the `product` and `review` tables can share a few more columns. That’s a great question about database design. A more generalized question would be whether two related tables should share columns beyond the primary/foreign key(s). The answer is no.

To simplify our discussion, let’s look at the scenario in which two related tables use single columns as the primary keys: the `product` and `review` tables. Theoretically speaking, the number of columns shared by two related tables can range from only the primary/foreign key(s) to all columns from both tables. Using the `product` and `review` tables as an example, the following figure summarizes this spectrum:

![spectrum of shared columns](https://drek4537l1klr.cloudfront.net/hao/Figures/CH02_UN02_Hao.png)

If two related tables share every column, it is obvious that one of them is redundant and thus unnecessary. If you choose to delete one of them, you will find yourself dealing with a problem similar to one you saw in chapter 1: using one table to represent two entities, which will lead to insertion or delete anomalies. OK, making two tables share every column is a bad idea.

How about making the two tables share only a few columns, such as one or two columns beyond the primary/foreign key(s)? That’s also a bad idea. First, you would still have redundancy, even if it’s less serious than a redundant table. Second, you will set a trap for yourself when you need to update data in such tables. If you update data in only one table and forget the other, you will end up with inconsistent data.

Suppose that you decide to make the `product` and `review` tables share one more column—`manufacturer`—in addition to `product_id`. When you need to update the manufacturer of a product, you have to update both the `product` and `review` tables. Otherwise, you will end up with new manufacturer data in one table but old data in the other. Such a problem is known as an *update anomaly*. As you can see in the following figure, two related tables shouldn’t share columns beyond the primary/foreign key(s).

![update anomaly](https://drek4537l1klr.cloudfront.net/hao/Figures/CH02_UN03_Hao.png)

### Join data from related tables
From time to time, you will need to join data from related tables. If you want to know about how each product of The Sci-Fi Collective is reviewed, for example, you will need to join at least the product name from the `product` table and the corresponding product reviews from the `review` table and then make sure that data from both tables is joined properly. In SQL, you can write the query that does this job as follows:

```sql
SELECT name, review_text
FROM product 
JOIN review
ON product.product_id = review.product_id;
```

This query yields the following result:

![join result](https://drek4537l1klr.cloudfront.net/hao/Figures/CH02_UN04_Hao.png)

We need to explain quite a few things about this query:
- What is the general syntax for retrieving data from related tables?
- What does the `JOIN…ON…` clause do?
- What is the dot, and how do we use dot notation as in `product.product_id` and `review.product_id`?

> **What is the general syntax for retrieving data from related tables?**
>
> ```sql
> SELECT column1, column2, ...
> FROM table1
> JOIN table2
> ON table1.column = table2.column;
> ```

**What does the `JOIN…ON` clause do?**

Suppose that you have two toy boxes, one with cars and the other with racetracks. You want to play with both kinds of toys, so you pour all the toys from both boxes onto the floor; then you need to find which cars would work on what types of racetracks. That’s what the `JOIN` clause does.

![join analogy](https://drek4537l1klr.cloudfront.net/hao/Figures/CH02_UN05_Hao.png)

In detail, the `JOIN` clause takes two tables (toy boxes) and pours all the rows (toys) on the floor; then it looks for matching values in the shared column (like the match between a car and a racetrack) between the two tables. If it finds a match, it puts the corresponding rows (cars and trucks that go together) together in a new table (your play area).

![join result analogy](https://drek4537l1klr.cloudfront.net/hao/Figures/CH02_UN05_MARG01_Hao.png)

**What is the dot, and how do we use dot notation as in `product.product_id` and `review.product_id`?**

*Dot notation* is SQL syntax used to separate parts of a name. `product.product_id`, for example, refers to the `product_id` column in the `product` table. As another example, `product.name` can refer to the `name` column in the `product` table. Dot notation is especially handy when you query related tables because it helps you to be specific about the columns in case they have the same name, such as `product.product_id` and `review.product_id`. This approach makes it clear which column and which table you are referring to and prevents confusion.

If two tables that you want to join have multiple columns that share a name, you may want to rename them in the `SELECT` statement to prevent confusion. Otherwise, you might end up with a result set that looks like a mixed-up game of Scrabble played by a mischievous toddler.

Suppose that you have two related tables, `employee` and `department`, and you want to join them to get the names of the departments to which employees belong.

![employee-department join](https://drek4537l1klr.cloudfront.net/hao/Figures/CH02_UN06_Hao.png)

Both tables have a column named `name`, so you need to use dot notation to specify which `name` column to select:

```sql
SELECT employee.name, department.name
FROM employee
JOIN department
ON employee.department_id = department.id;
```

Depending on the RDBMS you use, you may see the same column names, as in the preceding figure, or two identical column names (such as `name`). To prevent confusion, you can rename the columns with an alias via the `AS` clause:

```sql
SELECT employees.name AS employee_name, 
      departments.name AS department_name
FROM employees
JOIN departments
ON employees.department_id = departments.id;
```

### Types of JOINS
Now that you know the basics of the `JOIN` clause, we’ll dive a bit deeper into joins by discussing their variations. Before we do so, we’ll try to refresh your memory on the general syntax of joining tables:

```sql
SELECT column1, column2, ...
FROM table1
JOIN table2
ON table1.column = table2.column;
```

The `JOIN` keyword can be replaced by the following keywords, which may lead to different query results:
- `INNER JOIN` returns only the rows that have matching values in both tables; `INNER JOIN` is the same as `JOIN`.
- `LEFT JOIN` returns all the rows from table 1 and the matching rows from table 2. If a record in table 1 has no match in table 2, the result includes the table 1 record with `NULL` values for table 2 columns.
- `RIGHT JOIN` returns all the rows from the table 2 and the matching rows from table 1. If a record in table 2 has no match in table 1, the result includes the table 2 record with `NULL` values for table 1 columns.
- `FULL OUTER JOIN` returns all the rows from both tables, including the nonmatching rows. If a record in table 1 has a matching record in table 2, the result includes a single row with data from both tables. If a record in table 1 has no match in table 2, the result includes the table 1 record with `NULL` values for table 2 columns; if a record in table 2 has no match in table 1, the result includes the table 2 record with `NULL` values for table 1 columns.

The relationships among the left table, the right table, and the returned results are summarized in the following figure:

![join types](https://drek4537l1klr.cloudfront.net/hao/Figures/CH02_UN07_Hao.png)

It is worth noting that `LEFT JOIN`, `RIGHT JOIN`, and `FULL OUTER JOIN` may lead to query results with `NULL` values. One side effect of getting `NULL` values in the result is that you need to handle them carefully. `NULL` values can cause errors if you try to perform calculations or comparison. (As an example, 10 + `NULL` will lead to `NULL.`) Our `product` table, for example, contains some new products in our store that have not been reviewed by any users. When we perform a `LEFT JOIN` between the `product` and `review` tables, we end up with some rows that have `NULL` values in the columns from the `review` table. The `LEFT JOIN` query would be

```sql
SELECT name, review_text
FROM product 
LEFT JOIN review
ON product.product_id = review.product_id;
```

This query yields the following result:

![left join result](https://drek4537l1klr.cloudfront.net/hao/Figures/CH02_UN08_Hao.png)

As you can see, every match between the `product` and `review` table is included. A product like Atomic Nose Hair Trimmer can be reviewed more than once and show up in the result table as multiple rows. Also, if a product was not reviewed, it is still included in the result table, such as The Mind Probe, with a `review_text` value of `NULL`.

### WHERE vs. JOIN
As curious as you are, you may be tempted to try joining two tables by using the `WHERE` clause. You learned in chapter 1 how to use the `WHERE` clause to filter a subset of data from a table that meets certain criteria. If you know that it is possible to list multiple tables in the `FROM` statement, you might put together the following query to join the `product` and `review` tables you saw earlier:

```sql
SELECT name, review_text
FROM product, review
WHERE product.product_id = review.product_id;
```

Would this query work and yield the same result as the example we saw earlier? Yes. This query will work fine to join the two tables, and it yields the same result as the query using the `JOIN` clause:

```sql
SELECT name, review_text
FROM product 
JOIN review
ON product.product_id = review.product_id;
```

Whenever you need to query related tables, however, `JOIN` is generally preferred to `WHERE` for at least three reasons:
- *Readability*—Explicit `JOIN` makes the query’s intention clearer and easier to understand.
- *Maintainability*—Explicit `JOIN` is less prone to errors and more straightforward to modify or debug.
- *Optimization*—When you use a `WHERE` clause to query two related tables, the query essentially asks for a cross join between the two tables, which is more difficult for most RDBMSs to optimize than an explicit `JOIN`.

> **Cross join: A wild dance in which everyone twirls with everyone else**
>
> A *cross join* in SQL is an operation that combines every row from one table with every row from another table. It generates all possible combinations of rows between the two tables, returning a huge result.
>
> If the `FROM` clause in your query is followed by two or more tables, your query will perform a cross join between those tables. `FROM product, review`, for example, means that every row in the `product` table will be paired with every row in the `review` table whether or not a match exists.
>
> Cross joins may require scanning the involved tables separately, and they demand a large amount of memory from the RDBMS.

## Revisit table and data management
This section explores how to manage related tables and their data. In chapter 1, you learned how to manage a single table and its data. In the preceding section, you worked with a pair of related tables that we gave you. Now you will apply what you learned in chapter 1 and the preceding section to expand your knowledge of table and data management to related tables.

![table management](https://drek4537l1klr.cloudfront.net/hao/Figures/CH02_UN09_Hao.png)

### Manage related tables
You will learn how to create related tables from the prepared scripts that accompany this chapter. The scripts aim to create two related tables, `product` and `review`, for the database supporting The Sci-Fi Collective and to populate them with a set of sample data. You need to pick the script that works with your target RDBMS, of course (such as `mysql_db.sql` for MySQL or MariaDB).

You create the `product` table the same way that you did in chapter 1:

```sql
CREATE TABLE product (
 product_id INT PRIMARY KEY,
 name TEXT NOT NULL,
 description TEXT NOT NULL,
 price DECIMAL(5, 2) NOT NULL,
 manufacturer TEXT NOT NULL
);
```

You create the `review` table as follows:

```sql
-- comment: works for MySQL and MariaDB
-- comment: see the code repo for other RDBMS
CREATE TABLE review (
 review_id INT PRIMARY KEY,
 product_id INT NOT NULL,
 review_text TEXT NOT NULL,
 datetime DATETIME NOT NULL 
   DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT fk_product_review
   FOREIGN KEY (product_id) 
   REFERENCES product (product_id)
);
```

We need to answer two questions about this query:
- What is the general syntax for creating two tables that have a relationship?
- What does the `CONSTRAINT…FOREIGN KEY…REFERENCES…` clause do?

**What is the general syntax for creating two tables that have a relationship?**

As you know, the shared column `product_id` is the primary key in the `product` table and the foreign key in the `review` table. Given a pair of two related tables, we call a table like `product` the *parent table* because it uses the shared column as the primary key. We call a table like `review` the *child table* because it holds the foreign key.

![parent-child table](https://drek4537l1klr.cloudfront.net/hao/Figures/CH02_UN10_Hao.png)

As you can see from the command that creates the `product` table, the syntax for creating a parent table is the same as the syntax for creating a single table that is not related to other tables.

To create a child table, you need to specify the foreign key that references the primary key in the parent table. You still need to define all the columns, data types, and the primary key, of course. The general syntax for creating a child table is

```sql
CREATE TABLE child_table_name (
  column1 datatype1 [NOT NULL],
  column2 datatype2 [NOT NULL],
  ...,
  foreign_key_column datatype,
  CONSTRAINT fk_parent_child 
    FOREIGN KEY (foreign_key_column) REFERENCES  
    parent_table_name(parent_table_primary_key)
);
```

Alternatively, you can create the two tables independently and add the foreign key constraint to the child table afterward:

```sql
-- comment: assuming the parent and child tables 
-- comment: have been created
ALTER TABLE child_table_name
 ADD CONSTRAINT fk_parent_child
   FOREIGN KEY (foreign_key_column) REFERENCES 
   parent_table_name(parent_table_primary_key);
```

**What does the `CONSTRAINT…FOREIGN KEY…REFERENCES…` clause do?**

In short, the clause creates a foreign key constraint, which serves as a link between two related tables. The constraint is twofold:
- The constraint ensures that the foreign key column in the child table references only valid primary key values in the parent table.
- The constraint ensures that the updating or deletion of rows in the parent table doesn’t violate the consistency between two related tables.

![referential integrity](https://drek4537l1klr.cloudfront.net/hao/Figures/CH02_UN11_Hao.png)

We refer to these two aspects as *referential integrity*. The `CONSTRAINT…FOREIGN KEY…REFERENCES…` clause enforces referential integrity between two related tables.

If you take a closer look at the `CONSTRAINT…FOREIGN KEY…REFERENCES…` clause, you can divide it into two parts, as shown in the following figure.

![constraint parts](https://drek4537l1klr.cloudfront.net/hao/Figures/CH02_UN12_Hao.png)

The `FOREIGN KEY…REFERENCES…` statement creates the foreign key constraint that enforces referential integrity. The `CONSTRAINT…` clause allows you to name this constraint. When you create a foreign key constraint, you don’t necessarily need to name it, but naming it will make it easy to access whenever you need to modify such a constraint in the future. We named the foreign key constraint `fk_product_review` in the `review` table, for example. If we ever need to drop this constraint, we can access the constraint via this name:

```sql
-- comment: SQLite doesn't support ALTER TABLE 
-- comment: DROP CONSTRAINT
ALTER TABLE review 
 DROP CONSTRAINT fk_product_review;
```

If you don’t name a constraint yourself, the RDBMS will name it automatically, using its default naming convention. Although the automatically-picked name can be retrieved, this name and the default naming convention vary from one RDBMS to another. To avoid this hassle, we recommend that you always name constraints (as you should always name pets). After all, dropping or disabling a constraint can be a common task whenever you need to modify your database design.

### Manage data in related tables
The syntax for adding, updating, and deleting data in related tables remains the same as you saw in chapter 1. The scripts that we prepared for this chapter added a set of data to both the `product` and `review` tables:

```sql
-- comment: add data to the product table
INSERT INTO product (product_id, name,
              description, price, manufacturer)
VALUES (
 1,
 'Atomic Nose Hair Trimmer',
 'Trim your nose hairs … an atomic clock!',
 19.99,
 'Mad Inventors Inc.'
),
...;
-- comment: add data to the review table
INSERT INTO review (review_id, product_id, 
             review_text, datetime)
VALUES (
 1,
 3,
 'Great product, would definitely recommend!',
 '2022-01-01 12:30:00'
),
...;
```

What makes data management for related tables different, however, is the foreign key constraint. Earlier in this chapter, you learned that the foreign key constraint enforces referential integrity on a pair of two related tables:
- The foreign key constraint ensures that the foreign key column in the child table references only valid primary key values in the parent table.
- The foreign key constraint ensures that the deletion of rows in the parent table doesn’t violate the consistency between two related tables.

When you try to add data to the child table, the new data needs to be consistent with the existing data in the parent table; otherwise, the RDBMS will complain. Suppose that you are trying to add a new row of review data to the `review` table, but the `product_id` value (such as `3000`) in this row can’t be found in the `product` table:

```sql
INSERT INTO review (review_id, product_id, 
             review_text, datetime)
VALUES (
 1,
 3000,
 'Great product!',
 '2023-05-01 12:30:00'
);
```

When you execute this command, your RDBMS will give you an error message similar to the following:

```
ERROR 1452 (23000): 
Cannot add or update a child row: 
a foreign key constraint fails …
```

Likewise, when you alter or delete data from the parent table, the alteration or deletion shouldn’t lead to orphan data records in the child table; if it does, the RDBMS will complain. Suppose that you want to delete a row of product data from the `product` table, but this product data is referenced in the `review` table. If you delete this row, the deletion will create some orphan review data in the `review` table. Fortunately, the foreign key constraint will stop this situation from happening, and you will get an error message similar to the following:

![delete error](https://drek4537l1klr.cloudfront.net/hao/Figures/CH02_UN13_Hao.png)

The ultimate form of deleting data records from the parent table is dropping the table entirely. If this action is ever allowed, all the data in the child table will become orphan data. Fortunately, the foreign key constraint stops it from happening, and you get an error message similar to the following:

```
ERROR: cannot drop table … because other objects depend on it
DETAIL: constraint… on table…depends on table…
```
