# 5 Relationships

## In this chapter

- You establish relationships between entities.
- You identify the cardinality of each relationship.
- You decide whether to represent some entities as weak entities.

### What you need to know

You can find the database design covered in this chapter implemented in tools commonly used by practitioners, such as dbdiagram.io and MySQL Workbench, in the GitHub repository (https://github.com/Neo-Hao/grokking-relational-database-design). Navigate to the `chapter_05` folder and follow the instructions in `README.md` to load the database design into the corresponding tools.

The data types that show up in this chapter apply to most relational database management systems (RDBMSs), such as MySQL, MariaDB, and PostgreSQL. If you use another RDBMS, such as SQL Server or SQLite, you may need to make small modifications to the design by replacing certain data types with equivalents specific to the target RDBMS. You can find such information in `README.md` in the `chapter_05` folder.

## Overview

In this chapter, you will develop your entity-relationship (E-R) diagram for The Sci-Fi Collective’s online store by establishing relationships among entities you identified in chapter 4. By doing so, you will learn important database design concepts, such as cardinality and dependency.

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN01_Hao.png)

## Entity-relationship diagrams

*E-R diagrams* are graphical representations of entities and their relationships in a database. E-R diagrams are not only visual tools but also documents that describe database structures and rules. Over the years, these diagrams have become a universal design language among database designers.

An E-R diagram is typically composed of boxes representing the entities and lines representing the relationships among the entities. The diagram depicts the data structure (also known as the *data schema*) but not the data. In an E-R diagram, a table with millions of records is still represented as a single entity. The E-R diagram that you will develop by the end of this chapter looks like this:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN02_Hao.png)

This diagram uses Information Engineering notation, commonly known as Crow’s Foot notation; we will briefly cover other notation types later in the chapter. If you are designing a database for a sophisticated application, you may need multiple E-R diagrams to describe its structure fully. For The Sci-Fi Collective’s online store, one E-R diagram is good enough.

Now that we have introduced E-R diagrams, let’s start developing the diagram for The Sci-Fi Collective. We are not starting from scratch because we developed a set of entities in chapter 4, but we haven’t represented the relationships of those entities yet. In the next few sections, you will learn more about relationships between entities and take on the task of establishing relationships among entities for The Sci-Fi Collective.

## Connect related entities

Now is the perfect moment to reflect on and revisit all that you have accomplished so far. In chapter 4, you established all the entities as follows:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN03_Hao.png)

In chapter 3, you went over the requirements-gathering phase and collected useful information that pertains to the relationships among the preceding entities. You copied this information:

- A *user* can *make* multiple *purchases*; an order can be made by only one user.
- A *user* can *review* multiple *products* as long as the user bought those products; a product can be reviewed by multiple users.
- A *user* can *maintain* multiple *payment methods*; a payment method can be associated with only one user.
- A *purchase* can *have* more than one *product*; a product can show up in multiple orders.

In an E-R diagram, you use a line to connect every pair of two entities that are related. To establish relationships between two entities, you will identify every relationship and connect every pair of related entities using lines.

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN04_Hao.png)

Your first step in connecting entities is synthesizing the information you gathered and the design of entities. Your goal is to generate a list of simple sentences composed only of subjects, verbs, and objects. The sentences will help you understand the relationships between every pair of entities. As you designed entities, you may have introduced changes that conflicted with the gathered information. You designed a `review` entity, for example, but it didn’t appear as a noun in the information you gathered. To reconcile such conflicts, think about whether it makes sense to keep the `review` entity. If so, adapt the synthesized information accordingly:

- A user makes purchases.
- A user writes reviews.
- A product has reviews.
- A user maintains payment methods.
- A purchase contains products.

Next, map this summary to a diagram. The nouns in every sentence represent entities. If two nouns connected by some verbs show up in one sentence, the two entities are likely to be related. You may go through a few iterations of trial and error when mapping the summary to a diagram because of possible inaccuracy and misinterpretation. When you draw an entity in your draft E-R diagram, you can skip the attributes for now because they don’t matter yet and listing all of them is tedious. Based on the preceding summary, you will develop the following draft diagram:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN05_Hao.png)

When you generate a draft diagram, you should test every relationship against the information you gathered and the sample data you collected. Also, take the draft diagram to the stakeholders and explain your design rationale because it is likely that you made some mistakes or neglected something critical in your first few iterations. The software developers of The Sci-Fi Collective, for example, will point out that an online purchase can’t be performed without a payment method. Based on the new information, answer the following question before revising the draft diagram:

Should `payment_method` be related to `purchase`?

Without the payment method information, an online order can’t be finished, and the online store can’t bill its users. Each purchase record needs to be mapped to a corresponding payment method. Therefore, a relationship between `payment_method` and `purchase` makes sense. With this question answered, add one more relationship:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN06_Hao.png)

In the next two sections, you will learn more about the characteristics of a relationship between two entities, which will empower you to develop the draft diagram further.

## Cardinality

*Cardinality* is an important characteristic of a relationship between two entities, describing the number of instances of one entity that can be associated with a single instance of another entity via the relationship. Based on that definition, cardinality is classified into several types, each of which is represented differently in an E-R diagram.

To complete your E-R diagram, you need to analyze the information you collected from the requirements-gathering phase, identify the cardinality of each relationship, and update the draft diagram accordingly.

### Direction and representation

If you consider directions, a relationship between two entities can be broken into two directional relationships. In a banking system, for example, `user` and `account` are two entities, and their relationship(s) can be summarized using two sentences:

- *Sentence 1* — A user has zero, one, or more accounts.
- *Sentence 2* — An account is associated with one and only one user.

Sentences 1 and 2 represent two different directional relationships between `user` and `account`. In both sentences, the direction flows from the subject to the object:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN07_Hao.png)

Given a directional relationship from A to B, cardinality describes the number of instances of B with which a single instance of A can be associated. Cardinality is represented by two graphic symbols on the relationship line between A and B. The symbol on the inner side represents the minimum instance number of B that a single instance of A needs to be associated with—the *min cardinality*. The symbol on the outer side represents the maximum instance number—the *max cardinality*.

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN08_Hao.png)
![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN09_Hao.png)

#### Cardinality notation: Complicated relationships with math symbols

There are several ways to notate the cardinality of a relationship. The two most popular are Chen notation and Crow’s Foot notation. Chen notation has historic significance. Crow’s Foot notation is simpler and more popular among professionals. In this book, we will stick to Crow’s Foot notation.

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN10_Hao.png)

How do you represent the relationship cardinalities of the example you saw at the beginning of this section—the relationship between the `user` and `account` entities in a banking system?

- *Sentence 1* — A user has zero, one, or more accounts.
- *Sentence 2* — An account is associated with one and only one user.

The two sentences represent two directional relationships and contain the information you need to establish their cardinalities. Because a user is associated with zero, one, or more accounts, the min cardinality is zero, and the max cardinality is many for the relationship from `user` to `account`. Similarly, an account is associated with one and only one user, so both the max and min cardinalities for the relationship from `account` to `user` are one.

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN11_Hao.png)

As you see above, you can merge the two directional relationships and use a single line to represent both. The cardinality symbols closer to `account` represent the cardinality of the relationship from `user` to `account`, whereas the symbols closer to `user` represent the cardinality of the relationship from `account` to `user`.

Now you know what cardinality is and how to represent it in E-R diagrams, you will learn about three common cardinality types and apply what you learn to develop the draft E-R diagram further.

### One-to-one: A perfect match

In a one-to-one relationship, each record in one entity is related to up to one record in the other entity. *One-to-one* refers primarily to the max cardinality of both directional relationships. The min cardinalities could be either zero or one.

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN12_Hao.png)

Given a one-to-one relationship, if both of the two min cardinalities are ones, one of the min cardinalities is typically converted to zero for easy implementation.

Consider an example. In the database of a large corporation, both departments and managers are represented, and their relationship is as follows:

- A department has one and only one manager.
- A manager works for one and only one department.

You can represent such a relationship in an E-R diagram as follows:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN13_Hao.png)

This representation is theoretically solid but impossible to implement *as-is*. To link the two entities, you need foreign keys. If the two entities in the preceding figure have attributes, you would need to place foreign keys in both tables because each department is associated with a manager and each manager is associated with a department:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN14_Hao.png)

Such an implementation is problematic for data entry. When the two tables are empty, inserting a `department` first fails because its `manager` doesn’t yet exist; inserting a `manager` first fails for the reverse reason. To solve this, relax one of the two min cardinalities from one to zero:

- A department *has zero or one* manager.
- A manager works for one and only one department.

Updated representation and implementation:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN15_Hao.png)

As you see, the min cardinality can indicate where to place the foreign key in a one-to-one relationship. Given a directional relationship from table A to table B, if the minimum cardinality is zero, not every instance of A must have a corresponding record in B. In this case, you place the foreign key in B.

Now you know what one-to-one relationships are; it’s time to work on the E-R diagram of The Sci-Fi Collective.

#### Identify one-to-one relationships in your database

Based on the requirements you gathered, you don’t currently have an explicit one-to-one relationship among existing entities. But new information about users’ addresses propels you to redesign your `user` entity.

A user’s address might look like this:

```
20 Baldwin Rd, Shelter Island, New York, 11964
```

Analysts need to filter users by city, state, or postal code. Storing the whole address in a single `VARCHAR` makes that difficult. Factor the address into a new entity, `user_address`, with multiple attributes:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN16_Hao.png)

Most attributes are strings. Choose `CHAR` or `VARCHAR` types and lengths (assuming operations only in the US for simplicity). For example, `state` could be `VARCHAR(20)`; `postal_code` could be `CHAR(5)`.

After creating `user_address`, determine the relationship between `user` and `user_address`:

- A user may not have an address when they first register, but must have one (and only one) before making a purchase.
- An address is associated with only a single user.

Cardinalities:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN17_Hao.png)

This is a one-to-one relationship. The min cardinality from `user` to `user_address` is zero, so you place the foreign key in `user_address`:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN18_Hao.png)

One-to-one relationships are relatively rare.

### One-to-many: A love triangle

One-to-many relationships are the most common cardinality type. *One-to-many* refers to the max cardinalities (one vs many). Min cardinalities may vary.

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN19_Hao.png)

If both min cardinalities are one in a one-to-many relationship, data entry can again be problematic. You typically relax the min on the “many” side from one to zero:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN20_Hao.png)

Real example: relationship between `user` and `review`:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN21_Hao.png)

Information gathered:

- A user can write zero to many reviews.
- A review can be written by one and only one user.

Visualization:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN22_Hao.png)

Merged with cardinalities:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN23_Hao.png)

Foreign key placement rule: in a one-to-many relationship, place the foreign key on the many side (the crow’s foot side). Here, `review` gets the `user` primary key as foreign key:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN24_Hao.png)

#### Identify one-to-many relationships in our database

Review other relationships:

- A user can make multiple purchases. A purchase can be made by only one user.
- A user can maintain multiple payment methods. A payment method can be associated with only one user.
- [new] A payment method can be associated with multiple purchases. A purchase is associated with one payment method.
- A purchase can have more than one product. A product can show up in multiple purchases. (This last one is *not* one-to-many; it’s many-to-many.)

Determine cardinalities—`user` ↔ `purchase` is one-to-many (optional on the purchase side from the perspective of a user who has not bought yet):

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN25_Hao.png)

Add foreign key on the many side (`purchase`):

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN26_Hao.png)

Update relationships for `payment_method` similarly:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN27_Hao.png)

Notice two relationship paths from `payment_method` to `user` (direct and via `purchase`); potential redundancy to address later (chapter
 6).

### Many-to-many: The more, the merrier

In a many-to-many relationship, both max cardinalities are many:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN28_Hao.png)

Many-to-many relationships are *implemented* as two one-to-many relationships using a junction table.

Example: bookstore with `author` and `book`:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN29_Hao.png)
![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN30_Hao.png)

Represent using a junction table `author_book` with a composite primary key (`author_id`, `book_id`):

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN31_Hao.png)

The crow’s feet point to the junction table. The original entities relate indirectly through it.

#### Composite primary keys: The ultimate combination in databases

A *composite primary key* consists of two or more attributes that together uniquely identify each row. Use it when no single column can guarantee uniqueness (common in junction tables for many-to-many relationships).

If both one-to-many sides of the decomposition have min cardinality of one, relax the min cardinality on the junction (many) side to zero to ease data entry:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN32_Hao.png)

Why not just put foreign keys in both main tables? Doing so causes redundancy and anomalies:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN33_Hao.png)

#### Cardinality yoga: Learning to flex with zeros

Relax min cardinalities (from 1 to 0) when:
- One entity is created before its counterpart in a one-to-one.
- The “one” side may exist without dependents in a one-to-many.
- Either side may exist independently in a many-to-many (often zero on both sides unless business rules require otherwise).

### Identify many-to-many relationships in your database

Remaining relationship: `purchase` ↔ `product`.

Statement: A purchase can have more than one product. A product can show up in multiple purchases.

Clarification: A product doesn’t necessarily appear in a purchase, but a purchase must contain at least one product.

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN34_Hao.png)
![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN35_Hao.png)

Implement with junction table `purchase_product` (composite key of `purchase_id` + `product_id`):

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN36_Hao.png)

Relax min cardinality near the junction when necessary for insertion sequencing:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN37_Hao.png)

Updated draft diagram:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN38_Hao.png)

## Strong and weak entities

Strong and weak entities highlight dependency. If entity B (weak) cannot exist without entity A (strong), B’s primary key often includes A’s key.

Example: `movie` (strong) and `ticket` (weak):

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN39_Hao.png)

`ticket` might use composite key (`movie_id`, plus seat/time identifiers). Such additional attributes are *partial keys*.

You can sometimes convert a weak entity to a strong one—e.g., if tickets need independent lifecycle (resale/refund), introduce a standalone surrogate key.

If two approaches are viable, pick the simpler, less error-prone design.

### Identify strong and weak entities in your database

Candidates for weak entities: `review`, `payment_method`, `purchase_product`, and address-related tables.

`review` depends on both `user` and `product` conceptually, but converting it to a weak entity with a composite key (e.g., `user_id`, `product_id`, `review_id` or timestamp) adds complexity and wider indexes without clear benefit. Keep it strong with a single primary key and foreign keys to `user` and `product`.

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN41_Hao.png)
![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN42_Hao.png)

`purchase_product` is inherently a weak (junction) entity—its composite primary key *is* the combination of foreign keys to strong entities `purchase` and `product`.

`user_address` can be simplified by treating it as a weak entity whose primary key is the user’s `email` (or `user_id` if that were your PK). This removes a separate `address_id` and reduces one foreign key constraint:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN43_Hao.png)

After converting `user_address` to weak:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN44_Hao.png)

You also notice a `billing_address` embedded concept inside `payment_method` (`billing_address` column). Like `user_address`, model it as a separate weak entity related one-to-one with `payment_method`:

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN45_Hao.png)

At this point, your refined E-R diagram is complete.

Give yourself a pat on the back: you have successfully wrapped up a round of data modeling by developing and refining your E-R diagram.

## Recap

![](https://drek4537l1klr.cloudfront.net/hao/Figures/CH05_UN46_Hao.png)

- Relationships are the binding glue between entities. Their representations are informed by requirements and analysis.
- To represent relationships in an E-R diagram, you typically go through three steps: (1) establish relationships, (2) identify cardinality, (3) examine potential weak entities.
- Cardinality comes in three flavors: one-to-one, one-to-many, and many-to-many. The flavor influences foreign key placement.
- In a one-to-one relationship, both max cardinalities are one (two bars). The foreign key can go on either side (guided by min cardinality and lifecycle).
- In a one-to-many relationship, one side’s max is one; the other’s is many (crow’s foot). Place the foreign key on the many side.
- In a many-to-many relationship, both max cardinalities are many. Implement using a junction table with the primary keys of both entities (often a composite primary key).
- Strong vs weak entities add another dimension. Choose weak entity modeling only if it simplifies the schema or enforces integrity more cleanly.
- A weak entity uses the primary key of its strong entity as part of its composite primary key; in Crow’s Foot notation it is not visually different—its behavior emerges from key structure and dependencies.