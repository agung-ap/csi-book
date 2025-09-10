# 3 Overview of database design

## In this chapter
- You learn about the goals of database design.
- You get an overview of the database design process.
- You jump-start the requirement analysis.

> **What you need to know**
>
> This chapter provides an overview of database design from a bird’s-eye view. That said, this chapter doesn’t have accompanying scripts like those in chapters 1 and 2.

## Overview
In chapters 1 and 2, you learned the basics of relational databases and SQL. Starting with this chapter, you will embark on your journey of learning database design by designing a database from scratch for the online store of The Sci-Fi Collective. In this chapter, you will get an overview of the goals and process of database design. After that, you will jump-start the requirement analysis for The Sci-Fi Collective.

![Figure: Overview](https://drek4537l1klr.cloudfront.net/hao/Figures/CH03_UN01_Hao.png)

## Goals of database design
The overall goal of database design is to deliver a well-structured, efficient database that meets the requirements of users and organizations. Beyond meeting these requirements, a successful database design typically meets five common goals:

- Data consistency and integrity
- Maintainability and ease of use
- Performance and optimization
- Data security
- Scalability and flexibility

In this section, you will peek at these goals to better understand what you should aim to achieve in database design.

### Data consistency and integrity
Data consistency and integrity are about defining appropriate data types, constraints, and relationships among entities to ensure that:
- Data remains consistent across tables.
- Data redundancy is minimized.
- Anomalies are prevented.

In chapters 1 and 2, you peeked at some poor designs that led to data redundancy and learned about three types of anomalies. In short, data consistency means taking measures to ensure that those problems don’t happen.

> **Insertion, update, and delete anomalies**
>
> - An *insertion anomaly* occurs when adding a new record to a database requires adding unrelated data.
> - An *update anomaly* happens when modifying data results in inconsistencies within the data.
> - A *delete anomaly* happens when removing data leads to unintentional loss of information.

### Maintainability and ease of use
A well-designed database should be intuitive to use and easy to maintain by the people who use it, including database administrators, data analysts, and developers of web or mobile applications that are powered by the database.

You can take a lot of measures to increase the maintainability and ease of use of a database. Following a consistent naming convention, for example, is a small thing to do when you design a database, but it can save a lot of time for people who use or maintain the database. If developers who use a database have to spend time figuring out whether and where `id`, `Id`, and `identifier` are used as the primary key columns, the database is hardly intuitive to use, let alone easy to maintain. Think about having to maintain a database with the following tables:

![Figure: Naming conventions](https://drek4537l1klr.cloudfront.net/hao/Figures/CH03_UN02_Hao.png)

### Performance and optimization
A well-designed database should optimize query performance and reduce response time. An efficient database can help save running costs and boost the performance of the applications it supports, which in turn will enhance the user experience.

You can take a lot of measures to optimize the performance of a database. The data in the `review` table you saw in chapter 2, for example, often needs to be sorted because the table and its database support the online store of The Sci-Fi Collective, and potential customers often want to see the latest reviews of the products they browse. You can index the date column in the `review` table to speed the sorting operation.

What is indexing? Think of the data in the review table as being a library of books. *Indexing* is the process of creating an index-card catalog that lists every book alphabetically along with its location. When you need to sort, you can use the index-card catalog to locate every book and put it in its sorted position.

![Figure: Indexing](https://drek4537l1klr.cloudfront.net/hao/Figures/CH03_UN03_Hao.png)

### Data security
A well-designed database should have robust security measures in place. In other words, a well-designed database prevents unauthorized access, insertion, modification, or deletion. Even when such problems happen, the sensitive data should still be well protected and easy to recover.

You can take a lot of measures to safeguard the data. If you ever need to store payment method information in your database, for example, you should store only encrypted information. Storing customers’ payment method information in plain text is a bad idea. If an evil hacker gains access to the database, they will know everyone’s credit card number. By contrast, encryption helps protect sensitive information even in a worst-case scenario.

![Figure: Data security](https://drek4537l1klr.cloudfront.net/hao/Figures/CH03_UN04_Hao.png)

### Scalability and flexibility
A well-designed and efficient database should accommodate growth and changing requirements without sacrificing performance (trying to have your cake and eat it too).

You can take various measures to enhance the scalability and flexibility of your database design. When you design your database schema, for example, separating tables can make them smaller, which in turn can speed data lookups. Also, you can implement a cache mechanism for frequently accessed data, such as the product information in The Sci-Fi Collective’s database. *Caching* involves storing frequently accessed data in fast-access memory, such as RAM, which can significantly improve database performance and responsiveness, particularly as the data size grows. Popular caching systems such as Redis (https://redis.io) and Memcached (https://www.memcached.org) can implement this mechanism.

![Figure: Caching](https://drek4537l1klr.cloudfront.net/hao/Figures/CH03_UN05_Hao.png)

## Overview of the design process
In this section, we review the overall database design process by covering the key phases and steps in database design. Some approaches to database design emphasize a well-defined sequential process such as the waterfall approach, in which each phase must be completed before moving to the next. Other approaches, such as the agile approach, focus on an iterative, and flexible approach, allowing for adjustments as the project unfolds. Despite the differences, all database design approaches have the same key phases:

- Requirement gathering
- Analysis and design
- Implementation/integration and testing

![Figure: Design process](https://drek4537l1klr.cloudfront.net/hao/Figures/CH03_UN06_Hao.png)

### Requirement gathering
*Requirement gathering* refers to gathering information about the database in different ways, such as talking to all the people who will be involved with or using the database, studying existing databases (if any), and examining other relevant aspects of information management.

To talk to all the people who will be involved with or using the database, you need to organize meetings, ask good questions, and have conversations with different groups. To build the database for The Sci-Fi Collective, you would talk to shop owners and managers, future database administrators, and software developers who will build the web and mobile applications to find out what kind of information they need to keep track of.

![Figure: Requirement gathering](https://drek4537l1klr.cloudfront.net/hao/Figures/CH03_UN07_Hao.png)

If a legacy application uses any existing databases, you need to study the application and the databases carefully. Figuring out the gap between current expectations and the old databases is critical to successful database design.

The Sci-Fi Collective has a legacy online store. After you study its database and talk to all the stakeholders, you see that the old database doesn’t support tracking inventory numbers of in-stock products, which sometimes leads to customers buying products that are no longer in stock. The developers of The Sci-Fi Collective’s web app want the new database to track inventory numbers so that the web app can let customers know promptly when a particular product goes out of stock.

Any information management within the organization that is expected to be part of the database you design is also relevant. The purchasing manager of The Sci-Fi Collective used to manage the inventory information by using a spreadsheet and a paper form. To make such management activities part of your database design, you need to study the paper form, the spreadsheet, and the management flow.

![Figure: Inventory management](https://drek4537l1klr.cloudfront.net/hao/Figures/CH03_UN08_Hao.png)

### Analysis and design
The analysis and design phase involves carefully thinking through all the requirements and coming up with a solid plan for how the database will be structured and how it will work. In the end, you will create a detailed blueprint of the database. Some key steps in this phase include data modeling and normalization.

Data modeling aims to create a conceptual design that shows how the parts of a database fit together and relate to one another. The conceptual design is typically represented visually as an entity-relationship (E-R) diagram. An E-R diagram for the database of The Sci-Fi Collective might look like this:

![Figure: E-R diagram](https://drek4537l1klr.cloudfront.net/hao/Figures/CH03_UN09_Hao.png)

We know that this diagram contains symbols and syntax that you may not understand yet. You will learn about them, as well as learn how to model data using E-R diagrams, in chapter 5.

Normalization comes after the E-R diagram is established. Normalization minimizes redundancy by breaking down a table representing more than one entity into smaller, logical units and organizing them in separate tables. As an example, someone designed a `product_review` table to hold data on both products and their reviews. As you saw in chapter 2, storing information about more than one entity in the same table can lead to redundancy and anomalies. You could normalize such a table by breaking it into two tables: `product` and `review`.

![Figure: Normalization](https://drek4537l1klr.cloudfront.net/hao/Figures/CH03_UN10_Hao.png)

You will learn more about normalization and see how to determine whether a table needs to be normalized in chapter 6.

### Implementation/integration and testing
The implementation/integration and testing phase involves building and validating the database based on the blueprint you made in the design and analysis phase. If you use the waterfall approach, the database is implemented all at the same time; if you use the agile approach, the database is implemented part by part and integrated into what has been implemented. Then you test the database to ensure that it functions correctly, performs well, and meets the intended requirements.

During implementation, you create the tables, define the columns and their data types, establish relationships between tables, apply any constraints or rules specified in your design blueprint, and determine which columns to index to optimize query performance. You learned how to use SQL to create a single table or related tables in chapters 1 and 2, and that knowledge can be very useful for this step.

After the database has been implemented, you want to test it before putting it to use. Typically, testing a database needs to validate at least three aspects:
- *Functionality*—You need to check whether the database performs the expected tasks correctly, such as creating, updating, and deleting a data entry.
- *Performance*—You need to check how well the database handles large amounts of data or heavy use.
- *Security*—You need to verify that the database has appropriate security measures in place to protect sensitive data such as passwords and payment methods.

You should identify and fix any bugs discovered during testing, of course. As in the implementation phase, the knowledge of SQL queries you gained from chapters 1 and 2 will be very useful for testing. You will learn more about the details of this phase in chapters 6 and 7.

## Key phases of database design
In the preceding section, you got an overview of the process of database design. Starting with this section, you will explore and learn the key phases in database design by designing a database for the online store of The Sci-Fi Collective from scratch. Working on a project from scratch will give you hands-on experience and detailed knowledge of components you would otherwise not pick up.

In this section, you will learn more about the first key phase in database design: requirement gathering. Because requirement gathering is an art rather than a science, following the advice and insights of experts and veterans in this trade can make your life much easier.

### The goals of the database
As you take on requirement-gathering tasks, you need to answer a critical question based on all the information to collect: what are the goals of the database?

Every database is created for some specific purpose, whether that purpose is to handle the daily transactions of a business or manage the information of an organization. You need to identify the goal of the database clearly because the database will be used to make important decisions.

Sometimes, it takes longer than expected to come to a full understanding of the goals of the database, and you need to be ready for that situation. To have a good understanding of the goal of the database for The Sci-Fi Collective, you need to interview the owner, managers, staff, and software developers. You can summarize the goals of this database as follows:

> The database of The Sci-Fi Collective is to maintain information about products, such as their inventory and reviews, and information about users, such as their payment information and purchases, as well as the transaction information linking users and products.

### Existing databases and other aspects of information management
Sometimes you can refer to an existing database for your work. If so, you should resist the urge to base your new design on the structure of the existing database. There is a good reason why the organization/business decided to hire you to design a database from scratch instead of modifying the old database. Although the existing database can contain valuable information in terms of what entities and attributes are required to structure some tables, you must be careful about potential design errors in the existing database. Also, you must recognize that it will take the same amount of effort to figure out the demands of the new database and how they differ from those of the existing database.

How do you figure out the current demands? Conduct interviews. How do you figure out the gap between the existing database and current demands? Conduct more interviews with more questions.

![Figure: Interview process](https://drek4537l1klr.cloudfront.net/hao/Figures/CH03_UN11_Hao.png)

With respect to other aspects of information management, you may find that many people discovered ingenious ways to use word processors, spreadsheets, and paper forms to collect and manage data effectively. If this type of data management needs to be part of the new database you’re designing, you may want to do at least two things:
- *Get a subject-matter expert (SME) to walk you through how the data is managed.* This walk-through should involve demonstration and stepwise explanation because it is usually difficult to grasp data management through interviews alone.
- *Ask for data samples whenever possible.* The data samples will play an important role in helping you verify the attributes and data types in the next phase of database design.

We’ll use an example to illustrate the preceding two points. The purchasing manager of The Sci-Fi Collective currently manages all the inventory data in a spreadsheet, and the database you design will eventually replace the spreadsheet to manage that data. Instead of talking only to this manager and the purchasing team, you want them to walk you through the whole process of purchasing a batch of products, such as ordering, entering data about a new product, and updating and removing records of products that are already in inventory. The process can be complicated, so getting a demonstration is the best approach whenever possible. More important, you should ask for a copy of the authentic data, which ideally should be anonymized. The data will help clarify many problems that the demonstration can’t, such as the exact number of attributes and data types.

![Figure: SME walkthrough](https://drek4537l1klr.cloudfront.net/hao/Figures/CH03_UN12_Hao.png)

### Interviews
Interviews are the most important tasks in requirement gathering. During and after the interviews, you need to identify three pieces of information: subjects, characteristics, and relationships among subjects. These three pieces of information will be critical to helping you sail through the next phase of database design.

![Figure: Interview information](https://drek4537l1klr.cloudfront.net/hao/Figures/CH03_UN13_Hao.png)

Relationships are self-explanatory, but what are subjects and characteristics? *Subjects* are people, places, things, events, and the like. *Characteristics* are the features of subjects.

![Figure: Subjects and characteristics](https://drek4537l1klr.cloudfront.net/hao/Figures/CH03_UN14_Hao.png)

#### Prepare for interviews
Before conducting interviews, carefully plan the questions and other aspects of the interviews. What questions should you prepare? The answer depends on the project as well as whom you are interviewing. To simplify the problem, you may want to group the people you interview. Although the number of groups can vary, a business or organization typically has at least three groups of people you should consider interviewing: stakeholders, SMEs, and IT/technical staff.

![Figure: Interview groups](https://drek4537l1klr.cloudfront.net/hao/Figures/CH03_UN15_Hao.png)

The Sci-Fi Collective happens to be a typical business. It has two owners and one manager, two minotaurs who are responsible for tasks such as data entry and customer service, and three elves who work as software developers. Following are some sample interview questions for each group:

- **Stakeholders**: What is the primary purpose of the database, and what specific goals do you want to achieve with it? What key features or functionalities do you expect the database to support? Should the database support any specific reporting or analytics needs?
- **SMEs**: How do you currently manage and organize your data? What challenges or limitations do you face? Can you walk me through the typical workflow or process you follow when working with data? What specific information or data elements are most critical to your work?
- **IT/technical staff**: What are the main tasks or activities you perform that involve data storage or retrieval? What reports or outputs do you typically generate from the data? What information do these reports provide? Do you perform any specific calculations or computations on the data?

You should prepare more questions for each group yourself. What is the guiding principle for preparing interview questions? A good question should help you gather relevant information about what data the database should store, how the data should be stored, and what constraints should be put in place. If there’s no time constraint, however, a bad question is better than no question. If you are new to this process, you can ask for some example questions from ChatGPT. You might ask ChatGPT to provide some sample questions by using a prompt like the following:

> When you need to design a database, you need to conduct interviews with stakeholders. What questions are typically asked during such interviews?

![Figure: Interview preparation](https://drek4537l1klr.cloudfront.net/hao/Figures/CH03_UN15_MARG01_Hao.png)

Beyond interview questions, you need to prepare many things beforehand. Here are some key questions that you need to ask yourself during preparation:
- How do you want to record the interview? Will you take notes or record the conversation? If you decide to record, do you need to gain permission from the organization?
- Where do you want to conduct the interviews?
- Do you need to invite more than one group to the same interview? If so, who had better *not* be invited to the same interview? Should there be a limit on the number of interviewees?

Also, ask yourself more questions specific to the project and participants of the interviews. The guiding principle of any preparation is to make the interviews productive and informative.

#### Identify subjects, characteristics, and relationships
During and after the interviews, you need to identify subjects, characteristics, and relationships among subjects. In case you wonder why, one of the tasks you will take on during the next design phase is mapping the subjects, characteristics, and relationships to entities, attributes, and relationships among entities.

To identify subjects and characteristics during the interview or from the record of the interview, you can look for nouns in the responses to your questions. How do you differentiate subjects from characteristics? Typically, if you can build a sentence with two nouns in which one *has* or *owns* the other, the one that is possessed is the characteristic, and the other is the subject. You can put *user* and *password* in the following sentence, for example:

> A user has a password.

The password is possessed by the user, so it is a characteristic of a user, whereas the user is a subject.

You need to perform similar deductions on interview conversations. You might ask the following question of an IT staff member working for The Sci-Fi Collective:

> Q: What are the main tasks or activities you perform that involve data storage or retrieval?

The participant may give you a response like this (in which all subjects that can be identified are underlined):

> A: As a software developer, I am mainly responsible for building and maintaining the transaction system of the online store. When a *user* makes an *order*, the transaction system is supposed to retrieve the *user*’s *account* and *payment method*, generate an order with all the information for the ordered *products*, calculate the *total price*, bill the *payment method*, and generate an *invoice*.

As you can see, it is easy to deduce at least two subjects—user and order—in this response. A user has two characteristics: account and payment method. An order has two characteristics: product information and total price. Two other subjects—invoice and product—don’t have any characteristics.

Typically, you need to ask follow-up questions to get all the characteristics of a given subject. You might have this follow-up conversation with a participant:

> Q: What information does a complete order have?
> A: Well, the same as any other online store: the prices and quantities of all the products bought by a customer. That’s it. An order is not complicated.
> Q: What about the total price? Is the total price a part of the order?
> A: Sort of. Yes. The total price is calculated based on the unit price and quantities of all the bought products.
> Q: What about the date and time when an order was put into the system? Is that a necessary piece of information for an order?
> A: Yes, yes. That’s absolutely a necessary piece.

Answers such as “the same as any other online store” and “Sort of” are vague, often requiring you to follow up and ask clarification questions. Luckily, the participant provided enough details after such vague answers. Based on the answers, you can update the characteristics of the order subject as follows:

![Figure: Order characteristics](https://drek4537l1klr.cloudfront.net/hao/Figures/CH03_UN17_Hao.png)

To wrap up the discussion of subjects and characteristics, you should always ask for sample data if possible. When you have a good understanding of the subjects and characteristics discussed by the participant, you could follow up with a question like this:

> Q: Can you provide some sample data for products, orders, invoices, and users? Anything will help.

After identifying the subjects and characteristics, you will be ready to ask about relationships among subjects. Your focus should be the relationship between every two subjects. You could ask a follow-up question about the relationship between users and orders:

> Q: How are orders related to users? Can a user make multiple orders? Can multiple users contribute to one order?
> A: A user can of course make as many orders as they like. However, our system doesn’t support multiple users contributing to one order.

You could ask a follow-up question about the relationship between products and orders:

> Q: How are orders related to products? Can an order have more than one product? Can a product show up in more than one order?
> A: An order can have more than one product. Vice versa, a product can show up in different orders.

You don’t necessarily need to do any analysis of these responses; just record them well.

So far, you have walked through all the necessary steps in an interview. When you finish interviewing all the groups in The Sci-Fi Collective, you will be able to identify a set of subjects and characteristics associated with each subject, as shown in the following figure.

![Figure: Subjects and characteristics summary](https://drek4537l1klr.cloudfront.net/hao/Figures/CH03_UN18_Hao.png)

You will also be able to identify the following relationships:
- A user can make multiple orders. An order can be made by only one user.
- A user can review multiple products as long as the user bought those products. A product can be reviewed by multiple users.
- A user can maintain multiple payment methods. A payment method can be associated with only one user.
- An order can have more than one product. A product can show up in multiple orders.

With this information, you are ready to start the next phase in your journey of designing a database for The Sci-Fi Collective.

## Recap
![Figure: Recap](https://drek4537l1klr.cloudfront.net/hao/Figures/CH03_UN19_Hao.png)

- The overall goal of database design is to deliver a well-structured and efficient database.
- Key subgoals of database design include data consistency and integrity, maintainability and ease of use, performance and optimization, data security, and scalability and flexibility.
- All database design approaches have the same key phases, including requirement gathering, analysis and design, and implementation/integration and testing.
- Requirement gathering is the phase in which you gather information about the database in different ways, such as talking to all the people involved in using the database, studying existing databases, and examining other relevant aspects of information management.
- The analysis and design phase focuses on thoroughly understanding all requirements and creating a well-defined plan for the database’s structure and functionality.
- The implementation/integration and testing phase is about building and validating the database based on the blueprint you made in the design and analysis phase.
- Conducting interviews is the most important task in requirement gathering. Before interviews, plan the interview questions carefully. During and after the interviews, identify subjects, characteristics, and relationships among subjects.
