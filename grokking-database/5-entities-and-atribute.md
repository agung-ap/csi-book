# 4 Entities and attributes

## In this chapter

- You start the design and analysis phase of database design.
- You learn about keys and common data types in databases.
- You design your first few entities, identifying their attributes, primary keys, and data types.

---

### What you need to know

You can find the database design covered in this chapter (so far, only entities and attributes) implemented in tools commonly used by practitioners, such as dbdiagram.io and MySQL Workbench, in the GitHub repository: [https://github.com/Neo-Hao/grokking-relational-database-design](https://github.com/Neo-Hao/grokking-relational-database-design). You can navigate to the `chapter_04` folder and follow the instructions in `README.md` to load the database design into corresponding tools.

The data types covered in this chapter apply to most relational database management systems (RDBMSs), such as MySQL, MariaDB, and PostgreSQL. If you use another RDBMS, such as SQL Server or SQLite, you need to make small modifications to the design by replacing certain data types with equivalents specific to the target RDBMS. You can find such information in `README.md` in the `chapter_04` folder.

---

## Overview

In chapter 3, you walked through the database design process and went over the requirements-gathering phase for the online store of The Sci-Fi Collective.

Starting with this chapter, you will move to the next phase of database design: design and analysis. The first step of design and analysis is data modeling, which aims to generate an entity-relationship (E-R) diagram. In this chapter, you will focus on designing all the required entities for the database of The Sci-Fi Collective. By doing so, you will learn about entities, attributes, keys, and data types.

## Entities and attributes

In this section, you will focus on turning the subjects and characteristics you deduced from requirements gathering into entities and attributes. 

An *entity* is a distinct object or concept that can be described by many attributes. A subject and its characteristics may seem ready to be turned into an entity with attributes with few to no changes. A *subject* is simply an entity, and a *characteristic* is simply an attribute. But you need to put a little bit of thought into naming entities and attributes.

First, you need to choose between singular and plural names for your entities and attributes.

#### Singular vs. plural: To s or not to s?

Edgar Codd at IBM developed the first RDBMS in the 1970s. In his database, he used singular names for entities (such as `employee`). Other developers followed his lead.

Singular names are best used with primary entities (such as a single `employee` table). Singular approaches have their root in object-oriented programming (OOP), in which a class translates as an entity that contains several objects of the same class.

On the other hand, plural names are more natural as table titles. An `employees` table contains records of employees, for example. Plural table names, however, might cause confusion and errors for someone who isn’t sure whether to use plurals in writing queries. Our best recommendation is to aim for consistent use of either convention.

Second, you need to pick a naming convention for the attributes and stick to it. Sticking to a consistent naming convention can prevent typos and other errors in query writing and database maintenance. In this book, we will follow the singular naming convention.

Common naming conventions include:

- Snake case (`first_name`)
- Camel case (`firstName`)
- Pascal case (`FirstName`)
- Uppercase (`FIRST_NAME`)
- Hungarian notation, a special case that includes the data type (often abbreviated) as part of the name (`strFirstName`)
- Semantic naming, a special case that includes the purpose of a variable as part of the name (`customerName`)

Among these naming conventions, snake and camel cases are equally popular, followed by Pascal case. Make your choice based on preference and unique software requirements. In this book, we will stick to snake case.

With these two naming decisions made, you can easily map subjects/characteristics to entities/attributes. The `user` subject and its characteristics, for example, can be mapped to the `user` entity and its attributes.

Following the two naming conventions, we will convert all the subjects/characteristics for the online store of The Sci-Fi Collective to the following entities/attributes.

Beyond the naming conventions, you need to check two things about column names:

- *Whether you have names longer than the upper limit*—Many RDBMSs have limits on column-name lengths. MariaDB, for example, limits column names to 64 characters. If you have such a column name, you should shorten it.
- *Whether you used reserved SQL keywords as entity or attribute names*—Using reserved SQL keywords as names can lead to many problems, such as syntax errors in SQL query execution and maintainability problems.

If you use `SELECT` to name an entity, for example, the database system may not understand whether you are referring to the keyword `SELECT` or the entity with that name. Therefore, if you used any reserved keywords as names, you should replace them.

The reserved SQL keywords may vary from one database system to another. You can find a list of keywords in the MySQL documentation: https://mng.bz/zZ6r.

All database systems have a set of common keywords, such as `SELECT`, `ORDER`, `INSERT`, `GROUP`, and `JOIN`. We used the reserved SQL keyword `ORDER` to name one of our entities, so we need to replace it with a different word that has a similar meaning, such as `purchase`.

---

## Keys

Now that you have converted the subjects and characteristics you deduced in chapter 2 to entities and attributes, you are ready to start identifying primary keys in each entity.

A *primary key* refers to one or more attributes that can be used to identify an individual data record. The values of primary keys are unique. A table can have only one primary key.

Why does an entity need a primary key? An entity (set) will eventually be converted to a table in a database. The primary key identifies each row in a table uniquely, enforces data integrity by preventing duplication, and establishes relationships between tables in a relational database. All in all, identifying primary keys is an important step in completing your database design.

The guiding principle in identifying a primary key is simple: pick the best *candidate key* as the primary key. If no good candidate key is available, create a new attribute to serve as the primary key. In this section, we explain what candidate keys are and demonstrate this principle in two examples, starting with the `user` entity.

The `user` entity contains seven attributes. When you put the gathered requirements and sample data side by side, you can easily spot the attributes that should have unique values, preventing duplication of user data:

- `username`—Two users can’t have the same username. A new user can’t register with a username that’s already in the database.
- `email`—Emails must be unique for verification and account recovery. An email address can’t be used to register two different users.
- `phone_number`—Phone numbers must be unique for verification and account recovery. Different users can’t register the same phone number.

The three attributes are three different candidate keys for the `user` table. A *candidate key* is the smallest possible combination of attributes that can uniquely identify a row in a table. *Smallest* means that no subpart of a candidate key can uniquely identify a row. The combination of `username` and `first_name`, for example, can identify a row uniquely, but `username`, when used as a subpart of this combination, can also identity a row uniquely. Therefore, the combination of `username` and `first_name` is not a candidate key. On the other hand, `username` is a candidate key.

You start by examining each attribute to see whether it can identify a row uniquely. If you can’t find such an attribute, start combining columns to see whether they can identify a row uniquely. In our case, the `user` table contains three candidate keys: `username`, `email`, and `phone_number`. To pick one primary key, you must compare their qualities:

The meanings of these requirements are clear. *Stable*, for example, means not likely to change, and *simple* means easy to understand and use. The *unique* and *nonempty* (non-nullability) requirements are satisfied almost by default in `username` and `email`. The `phone_number` values might be `NULL` because even if a customer doesn’t have or doesn’t want to give us a phone number, we still welcome that customer to register as a user.

The rest of the metrics can be quite subjective. Usernames, for example, can be easier to change than email addresses; on the other hand, email addresses tend to be longer, which affects access speed. In our case, we will settle on `email` as the primary key for the `user` table because of its stability. The Sci-Fi Collective allows users to update their usernames but not their email addresses, and updates to primary key values are strongly discouraged. You can indicate which attribute is the primary key by underlining it or adding a key symbol to its left.

Consider another example. Among the seven attributes and their possible combinations in the `product` table, you can identify at least two candidate keys:

- *Product codes*—In the real world, most products have product codes, which can help identify products uniquely. Because each product has a unique code, the code can also prevent redundancy.
- *Product names and manufacturers*—The combination of product names and manufacturers can also uniquely identify products and prevent redundancy in the `product` table.

The product code is a clear winner over the combination of product name and manufacturer. The product code is simpler and shorter.

Although the concept of the product code may be less familiar, it is not difficult to grasp. The product code is based on the Universal Product Code (UPC), unique 12-digit numbers assigned to each product sold in stores and online around the world. So you can settle for `product_code` and use it as the primary key for the `product` table.

In both examples, we picked the primary key from a set of candidate keys. What if no candidate key is available or is a good fit? We will answer this question by picking a primary key for the `review` table, which has two columns: `review_text` and `review_time`. Neither of the two columns can uniquely identify a row in the `review` table. Although the combination of `review_text` and `review_time` can identify rows uniquely in most cases, it is still possible for two reviews with the same text to be recorded at the same time. That said, no candidate key is available for the `review` table.

When you are in a situation like this one, always think about the alternative: creating a new column and using it as the primary key. You can opt to create a numeric column and use it as the primary key for the `review` table. Numeric primary keys are smaller and can fit completely in computer memory, making them much faster to search. They also scale better and are more standardized than a combination of two attributes. We will create an autoincrementing numeric attribute, `review_id`, and use it as the primary key for the `review` table. This type of key is known as a *surrogate key*.

Undoubtedly, a surrogate key can identify rows in a table uniquely. But can such a key prevent redundancy? Well, not by itself. It is still possible for two identical rows of data to be inserted into the `review` table. Would redundancy be a problem? For tables such as `user` and `product`, it is important to eliminate redundancy. By contrast, reviews are always displayed as lists of texts on the same screen. As long as a row of review data can be identified uniquely, it can be updated or deleted properly. Therefore, redundancy won’t be much of a problem for the `review` table.

Following the same logic, you see that the `payment_method` and `purchase` tables are in a similar situation: identifying each row uniquely is more important than eliminating redundancy. For the `purchase` table, redundancy is tolerable. The `purchase` table represents the transaction records of users. A transaction record is immutable. For the `payment_method` table, redundancy is not only tolerable but also acceptable. The Sci-Fi Collective allows two different users to add the same payment method to their individual accounts. (Think about when a couple uses each other’s credit cards.)

In such a scenario, autoincrementing surrogate keys are a great choice for the primary keys. We will name the surrogate keys `payment_id` in the `payment_method` table and `purchase_id` in the `purchase` table.

#### Superkeys, candidate keys, and primary keys

Another type of key that we haven’t mentioned yet is the superkey. A *superkey* is a set of one or more columns of a table that can uniquely identify a row in the table. But it may contain columns that aren’t required to uniquely identify a row.

A candidate key is a minimal superkey, which means that it has no unnecessary columns. Finally, of all the candidate keys in a table, one is chosen as the primary key.

---

## Data types

You successfully identified or generated the primary keys of all entities in the preceding section. In this section, you will work to define data types for all attributes—a necessary step toward completing your design of entities and attributes. To implement the database based on your design, you need the data types of attributes.

### String data types: Power of personality

The most common types of string data are `CHAR`, `VARCHAR`, and `TEXT`. The major difference among them lies in storage requirements. When databases are small, the result is negligible, but as databases grow, so do computational (such as access speed) and memory requirements.

**Guidelines for choosing a string data type:**

- When an attribute has data of uniform length, use `CHAR`.
- When an attribute has data of a relatively short but varied length, use `VARCHAR`. "Relatively short" here also implies that an upper limit can be easily estimated (such as 500 characters).
- When an attribute is expected to have a large amount of text data that regularly exceeds a few thousand characters (1,000 plus), use `TEXT`, especially if the upper limit is hard to estimate.

Some examples:
- State/province data as part of the address information of your customers in the United States and Canada can use a two-character designation (such as WA for Washington state). `CHAR` is the perfect data type for this attribute.
- Users’ names can be expected to vary in length, but most names don’t need to go beyond 30 characters. Therefore, `VARCHAR` is the perfect data type for this attribute.

As for the data type `TEXT`, it is typically used to hold a large amount of text data, such as a product description, a product manual, or book text.

**Strings and database performance:**

In some databases, `TEXT` may not be stored inline along with the rest of the columns; instead, the data may exist in secondary file storage, requiring further lookups and a performance delay. Use this data type sparingly and only when necessary (for description fields, for example).

Text attributes are indexable through full-text indexes (specialized indexes for larger text that work like a search engine), which are not supported by all database systems. If the string data in an attribute is short, and if you expect this attribute to be searched frequently, `VARCHAR` is the better choice of data type.

#### Identify string attributes in our database

For each entity:
1. Check the requirements and the sample data that you got from the requirements-gathering phase.
2. Identify the attributes that should be strings.
3. Choose a string data type (`CHAR`, `VARCHAR`, or `TEXT`).

For example, the `user` entity has seven attributes. All are strings, so `VARCHAR` is the most appropriate data type. A phone number, for example, cannot contain more than 15 digits (excluding formatting), so the data type of `phone_number` would be `VARCHAR(15)`.

When you identify all the data types of the attribute, you can put the data type to the right of the attribute to complete your design of the `user` entity.

For the `product` entity, all four attributes are strings. `VARCHAR` is good enough for the `name` and `manufacturer` attributes. Product descriptions and photo URLs can be long strings—especially product descriptions. Assign `TEXT` to the description attribute. For photo URLs, `VARCHAR(1000)` is reasonable.

**Character sets:**

In every database you design and implement, you need to make a big decision about the tables, columns, and data in it. That decision is which character set to use for a database, and it’s better to make it early than late. A *character set* is a set of rules determining how characters are represented and stored in a database. Choose a character set that aligns with the languages and symbols you’ll be working with to ensure data accuracy and compatibility.

---

### Integer data types

The most common types of integer data are `TINYINT`, `SMALLINT`, `INT`, and `BIGINT`. These data types allocate a fixed number of bytes based on a power of 2 and are 1, 2, 4, and 8 bytes, respectively. These data types have different minimum and maximum values, which vary depending on whether they are set up as signed or unsigned.

For primary keys, use unsigned integers. For example, `payment_id` can be `INT UNSIGNED`.

Some attributes, like card numbers and expiry dates, may look like integers but should be stored as strings to preserve leading zeros and avoid unnecessary problems. For example, card numbers as `CHAR(16)` and expiry dates as `CHAR(4)`.

For the `code` attribute in the `product` entity (UPC), use `CHAR(12)`.

---

### Decimal data types

For attributes that represent money, use decimal types. You have two choices: floating-point types (`FLOAT`, `DOUBLE`) and fixed-point types (`DECIMAL`, `NUMERIC`). When accuracy is required, use fixed-point types.

For example, for `price` and `cost` attributes, use `DECIMAL(7, 2)`, where 7 is the precision and 2 is the scale (number of digits after the decimal point). For large monetary values, increase the precision as needed.

---

### Temporal data types

Most database systems support temporal data types, such as `DATE`, `TIME`, `DATETIME`, and `TIMESTAMP`.

- Use `DATE` for dates without time.
- Use `TIME` for time without date.
- Use `DATETIME` for both date and time.
- Use `TIMESTAMP` to record the exact moment of an event that needs to be consistent across time zones.

Store date and time values in Coordinated Universal Time (UTC) for consistency.

In our database, `review_time` in `review` and `purchase_time` in `purchase` should be `TIMESTAMP`. Add a `last_login_time` attribute to the `user` entity as `TIMESTAMP`.

---

## Recap

- Designing an entity requires identifying all its attributes, the primary key, and the data types of all attributes.
- A primary key should be able to identify each row in a table uniquely. If no candidate key is available or a good fit, you can always create a numeric attribute and use it as the primary key.
- Common data types in databases include string, integer, decimal, and temporal. To decide which data type to use, think about what job a data type is good for as well as the demands of your particular case.
- Using proper data types ensures that a database stores data efficiently and meets the demands of data querying.
