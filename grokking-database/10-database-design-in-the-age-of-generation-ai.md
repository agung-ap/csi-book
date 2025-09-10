# 8 Database design in the age of generative AI

## In this chapter

- You explore how to use generative AI to speed database design.
- You learn how to fine-tune the prompts to get precisely what you want from generative AI tools.
- You go through the full pipeline to design and implement a database for a spaceship manufacturer with the help of generative AI tools.

### What you need to know

This chapter is different from others in a major way. You are unlikely to replicate the demonstrated interactions with large language models (LLMs) due to their probabilistic nature and continuous changes. When we wrote this chapter, we used ChatGPT 4o. That said, ChatGPT may get your design exactly right or wrong in different ways even if you use the prompts demonstrated in this chapter.

The database design covered in this chapter (it's finally complete), using tools commonly used by practitioners, such as dbdiagram.io and MySQL Workbench, can be found in the GitHub repository (https://github.com/Neo-Hao/grokking-relational-database-design). Navigate to the `chapter_08` folder and follow the instructions in the `README.md` file to load the database design into corresponding tools.

Also, you can find the full-text prompts for ChatGPT and SQL scripts corresponding to the final database design for different relational database management systems (RDBMS), including MySQL, MariaDB, PostgreSQL, SQLite, SQL Server, and Oracle.

## Overview

In this chapter, you will explore how to take advantage of generative AI to speed database design, and you will see what a typical workflow looks like when you're working toward a complete database design with help from generative AI.

You picked up all the essentials for designing a robust database in the previous seven chapters by working on the database of The Sci-Fi Collective. It is time for a change. In this chapter, you will design a database for a company that manufactures spaceships. By working on this new project from scratch, you will start to appreciate how generative AI tools can make your life easier and understand their limitations in delivering what you expect.

Quite a few LLMs can serve our purposes, such as ChatGPT, Claude, Google Gemini, and Llama. We will use ChatGPT (GPT-4o) to demonstrate our interactions with a generative AI tool in this chapter. Due to the way ChatGPT models were trained, specific prompt formats and practices work particularly well and lead to more useful responses.

Following are three rules of thumb for working with ChatGPT:

- *Be specific, descriptive, and as detailed as possible.* All LLMs, including ChatGPT, can't be seven steps ahead of you and know what you truly want to ask when your question or request is vague or imprecise. How ChatGPT responds to your questions and instructions is captured by the age-old adage "Garbage in, garbage out." This axiom may sound familiar if you are in the field of computer science or software engineering.

- *Separate instructions from context.* Most LLMs work better when you separate instructions from context. ChatGPT hopes that you'll put instructions at the beginning of a prompt and use `###` or `"""` to separate them from the context. When you need to summarize some long text passages in bullet points, for example, here is what ChatGPT recommends:

#### ChatGPT GPT-4o

Summarize the text below as a bullet-point list of the most important points.

**Text**: `"""`

some long texts go here

`"""`

- *Articulate the desired output format through examples.* ChatGPT responds better when you give it specific format requirements. This practice also makes it easier to programmatically parse out multiple outputs reliably. When you need to summarize some long text passages in a few target entities, here is what ChatGPT recommends:

#### ChatGPT GPT-4o

Extract the important entities mentioned in the text below. Extract all company names, people names, and specific topics which fit the content and the general overarching themes

**Desired format**:

**Company names**: `<comma_separated_list>`

**People names**: `-||-`

**Specific topics**: `-||-`

**General themes**: `-||-`

**Text**: `"""`

some long texts go here

`"""`

You can read more about recommended practices for using ChatGPT at https://mng.bz/QD41. In our experience, the three rules of thumb are most important and helpful for database design.

Before you start the database design, we want to emphasize that you shouldn't dwell on replicating the interactions with ChatGPT demonstrated in the chapter. The same request doesn't necessarily lead to the same answer for many reasons, including randomness, previous context, and model updates or refinements. Instead, focus on learning how to use ChatGPT efficiently, what working with ChatGPT looks like, and when to rely on your own judgment.

## Requirements analysis

In line with the galactic theme, you will design a database for a company named SHIPS R US that specializes in manufacturing spaceships. SHIPS R US distributes spaceships in large batches to dealers across the galaxy, who eventually sell the spaceships to customers. A good analogy is how Toyota and Ford sell cars. Like those companies, SHIPS R US requires a web application powered by a database to manage all the relevant information, such as spaceship models, production records, and dealer and customer information. Your task is to design a database for this web application.

For the sake of brevity, we'll assume that you've applied all the techniques you learned in chapter 3 to collect and analyze the requirements of the SHIPS R US database. The synthesized high-level requirements are

- The database needs to maintain records on all spaceship brands and models, manufactured spaceships, dealers, customers, and relationships between dealers and customers.
- A spaceship brand is associated with multiple models, and a model is associated with multiple spacecraft.
- One or more spaceships are distributed to a dealer, who serves one or more customers.
- A customer is served by one or more dealers and is associated with one or more spaceships that they bought from the dealer(s.)
- A spaceship is associated with one model and can be associated with no more than one owner and no more than one dealer.

These requirements focus on entities and their relationships. Beyond this summary, you have another set of requirements focusing on entities and attributes (explored further in the next section).

## Entities and attributes

In this section, you design entities and attributes based on the requirement analysis with the help of ChatGPT.

### Entities

Based on the high-level requirement summary, you extracted five entities: brand, model, spaceship, dealer, and customer. If this fact is not obvious to you or you want to see how capable ChatGPT is, you can make the following request to ChatGPT:

> I am designing a database. Help me identify all the entities based on the given requirements.
>
> **Requirements**: `"""`
>
> The database needs to maintain records of all spaceship brands and models, manufactured spaceships, dealers, customers, and relationships between dealers and customers.
>
> A spaceship brand is associated with multiple models, and a model is associated with multiple spacecrafts.
>
> A dealer is distributed one or more spaceships and serves one or more customers.
>
> A customer is served by one or more dealers and is associated with one or more spaceships that they bought from the dealers.
>
> A spaceship is associated with one model and can be associated with no more than one owner and no more than one dealer.
>
> `"""`

As you can see from this request, we deliberately separated the instructions from the context to get better answers from ChatGPT. This question is so simple that separating instructions from context does very little, but it is a good idea to stick to the rules of thumb, and it will make a difference when you have a much more complicated question or request. Overall, the answer you get from ChatGPT will be similar to the one shown in this image:

[The image would show ChatGPT's response identifying the five entities]

### Attributes

You worked hard on requirement analysis and have a set of synthesized requirements to help you identify the attributes of each entity:

- *A brand has a name.* The number of brands is limited and smaller than five.
- *A model has a four-digit number and name.* The number is unique per model.
- *A spaceship has a 17-digit serial number (like a vehicle identification number for a car), a recommended price, and a year number.* The serial number is unique per spaceship. The unit for the recommended price is US dollars (USD). The year number represents the year in which the spaceship was manufactured.
- *A dealer has a name, address, phone number, email address, and dealer website URL.* The dealer may be anywhere on Earth.
- *A customer has a name, address, phone number, and email address.* Multiple customers may share an address. The customer may live anywhere on Earth.

Developing the entity-relationship (E-R) diagram is a milestone in database design, requiring you to identify the attributes and their corresponding data types as well as the primary key for each entity. This step can be tedious and requires you to dig deep into the details of the gathered requirements. ChatGPT can offer help. You could use the preceding requirements for attributes to formulate the following request:

> I am designing a database for a manufacturer of spaceships. I have identified five entities: brand, model, spaceship, dealer, and customer. Help me identify attributes and the primary key per entity based on the given requirements. Generate output using the desired format.
>
> **Desired format**:
>
> **Entity name**: `spaceship`
>
> **Attributes**:
>
> **Serial number**: `CHAR(17)`
>
> **Recommended price**: `NUMERIC(8, 2)`
>
> **Primary key**: Serial number
>
> **Requirements**: `"""`
>
> A brand has a name …… The customer may live anywhere on Earth.
>
> (This is an excerpt. Full text can be found at https://bit.ly/grdb.)
>
> `"""`

As you can see from this request, we added the desired format for the output, which increases the consistency of the output and makes sure that it is ready to use for future interactions with ChatGPT. Following is a sample answer from ChatGPT to this request:

#### ChatGPT GPT-4o

**Entity name of Brand**: `brand`

**Attributes**:

**Name**: `name - VARCHAR(100)`

**Primary key**: `name`

**Entity name of Model**: `model`

**Attributes**:

**Model number**: `model_number - CHAR(4)`

**Model name**: `model_name - VARCHAR(100)`

**Primary key**: Model number

**Entity name of Spaceship**: `spaceship`

**Attributes**:

**Serial number**: `serial_number - CHAR(17)`

**Recommended price**: `recommended_price – NUMERIC(8, 2)`

……

As soon as you see the answer, you may realize that you missed something in formulating your request: naming the entities and attributes properly. The names of entities and attributes don't follow the naming conventions we discussed in chapter 3. To fix that problem, you can ask ChatGPT a follow-up question or reformulate your initial question. Regardless of your choice, we recommend that you give ChatGPT an example of how the output should be formatted. Here is an example follow-up request:

> Regenerate your answer using a new format but the same requirements. Make sure that names of entities and attributes are all snake-cased.
>
> **New format**:
>
> **Entity name of Spaceship**: `spaceship`
>
> **Attributes**:
>
> **Serial number**: `serial_number - CHAR(17)`
>
> **Recommended price**: `recommended_price – NUMERIC(8, 2)`
>
> **Primary key**: `serial_number`

Here is a sample answer from ChatGPT to this request:

#### ChatGPT GPT-4o

**Entity name of Brand**: `brand`

**Attributes**:

**Name**: `name - VARCHAR(100)`

**Primary key**: `name`

**Entity name of Model**: `model`

**Attributes**:

**Model number**: `model_number - CHAR(4)`

**Model name**: `model_name - VARCHAR(100)`

**Primary key**: `model_number`

**Entity name of Spaceship**: `spaceship`

**Attributes**:

**Serial number**: `serial_number - CHAR(17)`

**Recommended price**: `recommended_price – NUMERIC(8, 2)`

**Year**: `year - year`

**Primary key**: `serial_number`

**Entity name of Dealer**: `dealer`

**Attributes**:

**Name**: `name - VARCHAR(100)`

**Address**: `address - VARCHAR(255)`

**Phone number**: `phone_number - CHAR(15)`

**Email address**: `email_address - VARCHAR(100)`

**Website URL**: `website_url - VARCHAR(255)`

**Primary key**: `name`

**Entity name of Customer**: `customer`

**Attributes**:

**Name**: `name - VARCHAR(100)`

**Address**: `address - VARCHAR(255)`

**Phone number**: phone_`number - CHAR(15)`

**Email address**: `email_address - VARCHAR(100)`

**Primary key**: `email_address`

As you see, ChatGPT does many things right, such as using the desired format, following snake-case convention in naming entities and attributes, and making some reasonable guesses on data length when no requirements are specified.

Some design choices in the answer are questionable, however. Three notable problems stand out.

First, the selection of primary keys of certain entities may not be what you want. Because the requirement summaries don't provide enough information about how primary keys should be selected, ChatGPT took the liberty of sneaking in some assumptions. The `name` attribute was chosen as the primary key of the `dealer` entity, for example, and the `email_address` attribute was chosen as the primary key of the `customer` entity. Both choices are problematic. Although a dealer's name is not likely to change often, it is possible for two dealers to have the same name, even in a single US state, let alone the world. A different attribute should be used as the primary key, but what would that be? After diving into the requirement analysis further, you find the following information:

- A customer is allowed to update their email address and phone number.
- A dealer is allowed to update their email address and phone number.

In other words, neither the email nor the phone number is stable. If you make either attribute the primary key of an entity, you will face a lot of trouble in updating phone number or email addresses. That said, no single attributes are readily available to be used as the primary key in `dealer` or `customer`. As you learned in chapter 4, a surrogate key that increments automatically can be used as the primary key in this situation. Such a primary key has no problems in identifying a data record uniquely but can't prevent data duplications by itself—that is, it can't prevent a person or a robot to register more than one account using the same information. Based on what you learned in chapter 6, you can add a unique constraint to the `email_address` attribute and another to the `phone_number` attribute to address concerns about data duplication. When you revise the design of the `customer` entity based on these considerations, it looks like this:

> **Entity name of Customer**: `customer`
>
> **Attributes**:
>
> **Customer ID**: `customer_id – INT`
>
> **Name**: `name - VARCHAR(100)`
>
> ……
>
> **Primary key**: `customer_id`
>
> **Note 1**: `email_address` requires a unique constraint; `phone_number` requires a unique constraint

The `dealer` entity has a similar update:

> **Entity name of Dealer**: `dealer`
>
> **Attributes**:
>
> **Dealer ID**: `dealer_id – INT`
>
> **Name**: `name - VARCHAR(100)`
>
> ……
>
> **Primary key**: `dealer_id`
>
> ……

Second, the design of phone-number attributes failed to account for the fact that a dealer or customer can be anywhere on Earth. Both `customer` and `dealer` have a `phone_number` attribute. The data length `CHAR(15)` may not be sufficient for all international numbers. If you do some research on phone-number lengths, you find that the maximum length of a phone number is 15 digits, thanks to the international phone-numbering plan. This length assumes that the country code is included and that the number is a simple numeric string without spaces, dashes, or parentheses. Some international numbers, however, have non-numeric strings. In such a case, the total length may exceed 15 characters. To address this problem, you can separate the country code from the phone number and prepare two attributes to store each piece of data separately. When you revise the design of the `customer` entity based on these considerations, it looks like this:

> **Entity name of Customer**: `customer`
>
> **Attributes**:
>
> **Customer ID**: `customer_id – INT`
>
> **Name**: `name - VARCHAR(100)`
>
> **Phone number**:
>
> ```
>   country_code - CHAR(5)
>  customer_phone_number - CHAR(15)
> ```
>
> ……

The `dealer` entity has a similar update:

> **Entity name of Dealer**: `dealer`
>
> **Attributes**:
>
> **Dealer ID**: `dealer_id – INT`
>
> **Name**: `name - VARCHAR(100)`
>
> **Phone number**:
>
> ```
>   country_code - CHAR(5)
>  dealer_phone_number - CHAR(15)
> ```
>
> ……

The separation between country codes and phone numbers can help standardize phone numbers and ensure consistency in how phone numbers are stored. More important, `VARCHAR(15)` is sufficient for any phone numbers when the country code is not considered.

Third, the design of address attributes failed to account for the fact that the dealer and customer can be anywhere on Earth. A single attribute, `VARCHAR(255)`, may not be sufficient for storing some long addresses. What's worse, this design will lead to many addresses with unpredictable formats because no structure is enforced. Unpredictable formats create further troubles in parsing, searching, and filtering, let alone data validation and error handling.

To make address storage more robust and flexible, consider breaking the address into multiple attributes. You might update the design of the `customer` entity like this:

> **Entity name of Customer**: `customer`
>
> **Attributes**:
>
> ……
>
> **Address**:
>
> ```
>   street_address - VARCHAR(255)
>  suburb - VARCHAR(100)
>  city - VARCHAR(100)
>  state_province - VARCHAR(100)
>  postal_code - VARCHAR(20)
>       country - CHAR(2)
> ```
>
> ……

The design of the `dealer` entity is updated as follows:

> **Entity name of Dealer**: `dealer`
>
> **Attributes**:
>
> ……
>
> **Address**:
>
> ```
>   street_address - VARCHAR(255)
>  suburb - VARCHAR(100)
>  city - VARCHAR(100)
>  state_province - VARCHAR(100)
>  postal_code - VARCHAR(20)
>  country - CHAR(2)
> ```
>
> ……

As soon as you break the address information into six attributes in both the `customer` and `dealer` entities, you may notice that the two entities suddenly have significant overlap. This situation may ring a bell if you remember chapter 7, which addressed a similar problem between a user address and a billing address. If you use the same solution, you can prepare a new table representing addresses and link that table to both the `dealer` and `customer` entities. The new table looks like this:

> **Entity name of Address**: `address`
>
> **Attributes**:
>
> **Address ID**: `address_id - INT`
>
> **Street address**: `street_address - VARCHAR(255)`
>
> **Suburb**: `suburb - VARCHAR(100)`
>
> **City**: `city - VARCHAR(100)`
>
> **State/Province**: `state_province - VARCHAR(100)`
>
> **Postal code**: `postal_code - VARCHAR(20)`
>
> **Country**: `country - CHAR(2)`
>
> **Primary key**: `address_id`

The postal codes are not universally applicable. Some countries use them, and others don't. Countries that use postal codes tend to have different opinions about how they should be formatted. As a result, you should make the `postal_code` attribute optional, which means that it can be `null`. The same can be said of the `suburb` attribute. With the `address` entity representing addresses, you can remove the attributes about addresses from the `customer` and `dealer` entities.

It is important to keep a record of your revisions in text because you are not done designing and implementing the database, and ChatGPT is a primarily a text-based AI tool. You'll feed your design of entities and attributes to ChatGPT again for future design revisions and implementations. When you merge all your revisions with the answers from ChatGPT, you get the following results:

> **Entity name of Brand**: `brand`
>
> **Attributes**:
>
> **Name**: `name - VARCHAR(100)`
>
> **Primary key**: `name`

> **Entity name of Model**: `model`
>
> **Attributes**:
>
> **Model number**: `model_number - CHAR(4)`
>
> **Model name**: `model_name - VARCHAR(100)`
>
> **Primary key**: `model_number`

> **Entity name of Spaceship**: `spaceship`
>
> **Attributes**:
>
> **Serial number**: `serial_number - CHAR(17)`
>
> **Recommended price**: `recommended_price – NUMERIC(8, 2)`
>
> **Year**: `year - year`
>
> **Primary key**: `serial_number`

> **Entity name of Dealer**: `dealer`
>
> **Attributes**:
>
> **Dealer ID**: `dealer_id – INT`
>
> **Name**: `name - VARCHAR(100)`

> **Email address**: `email_address - VARCHAR(100)`
>
> **Website URL**: `website_url – VARCHAR(255)`
>
> **Phone number**:
>
> ```
>   country_code - CHAR(5)
>  dealer_phone_number - CHAR(15)
> ```
>
> **Primary key**: `dealer_id`
>
> **Note 1**: `email_address` requires a unique constraint; (`country_code`, `phone_number`) requires a unique constraint

> **Entity name of Customer**: `customer`
>
> **Attributes**:
>
> **Customer ID**: `customer_id – INT`
>
> **Name**: `name - VARCHAR(100)`
>
> **Email address**: `email_address - VARCHAR(100)`
>
> **Phone number**:
>
> ```
>   country_code - CHAR(5)
>  customer_phone_number - CHAR(15)
> ```
>
> **Primary key**: `customer_id`
>
> **Note 1**: `email_address` requires a unique constraint; (`country_code`, `phone_number`) requires a unique constraint

> **Entity name of Address**: `address`
>
> **Attributes**:
>
> **Address ID**: `address_id - INT`
>
> **Street address**: `street_address - VARCHAR(255)`
>
> **Suburb**: `suburb - VARCHAR(100)`
>
> **City**: `city - VARCHAR(100)`
>
> **State/Province**: `state_province - VARCHAR(100)`
>
> **Postal code**: `postal_code - VARCHAR(20)`
>
> **Country**: `country - CHAR(2)`
>
> **Primary key**: `address_id`
>
> **Note 1**: `suburb` and `postal_code` are optional

### Communicate your design

You have completed the design of entities and attributes based on the requirement analysis and ChatGPT. Everything is stored in a long, formatted piece of text. The text is essential for communicating with ChatGPT but not great for sharing your design with other people. To communicate your design effectively, you have to visualize it.

If you have only a few entities, you can use any diagram tool to draw them. You can draw all the entities of SHIPS R US as follows:

[The image would show a diagram of the entities]

If you are working on a much bigger project that involves a dozen or more entities, however, you may want to turn to ChatGPT for help again. Although ChatGPT can't generate the diagram you need in the target format, you can ask it to generate the corresponding SQL code and import the code into a tool that visualizes database design based on SQL code, such as dbdiagram.io (https://dbdiagram.io). To ask ChatGPT for SQL code, try the following example request:

> I am designing a database. Help me generate MySQL code based on the following description of entities and attributes. Keep the entities independent from one another.
>
> **Description**: `"""`
>
> **Entity name of Brand**: `brand`
>
> **Attributes**:
>
> **Name**: `name - VARCHAR(100)`
>
> **Primary key**: `name`
>
> ……
>
> **Country**: `country - CHAR(2)`
>
> **Primary key**: `address_id`
>
> **Note 1**: `suburb` and `postal_code` are optional
>
> (This is an excerpt. Full text can be found at https://bit.ly/grdb.)
>
> `"""`

After getting the code, you can copy and paste it by using the import function of dbdiagram.io:

[The image would show the dbdiagram.io import interface]

The generated visualization is much easier to share with others and appropriate for communication:

[The image would show the resulting diagram]

As you can see, ChatGPT can speed the process of database design. Although you can't use the answers directly, they are useful as the starting point in your problem-solving journey. When you get some answers from ChatGPT, it is up to you to identify the problems in those answers and fix them based on your requirement analysis and knowledge of database design. When you need to communicate your design to others, ChatGPT can convert the text-based design to SQL code, which in turn can be turned into a diagram.

## Relationships among entities

Now that you have identified and designed all the entities, their attributes, and corresponding data types for the database, you are ready to work on the relationships among entities. The following list may refresh your memory of the requirements for relationships:

- The database needs to maintain records of all spaceship brands and models, manufactured spaceships, dealers, customers, and relationships between dealers and customers.
- A spaceship brand is associated with multiple models, and a model is associated with multiple spacecraft.
- A dealer is distributed one or more spaceships and serves one or more customers.
- A customer is served by one or more dealer, and is associated with one or more spaceships that they bought from the dealer.
- A spaceship is associated with one model and can be associated with no more than one owner and no more than one dealer.
- A customer is associated with one address. Multiple customers may share an address. A dealer is associated with one address.

You added the last item when you decided to use an independent entity to represent addresses. You need to address the relationship between customers and addresses as you build the relationships among entities; the same is true of dealers and addresses.

As what you did in the preceding section, you can start by asking ChatGPT to generate a design draft. To achieve a more useful response, follow the rules of thumb to structure your request. Try the following request:

> I am designing a database for a manufacturer of spaceships. I have identified six entities: brand, model, spaceship, dealer, customer, and address. Help me identify the relationships between each pair of entities based on the given requirements. Generate output using the desired format.
>
> **Desired format**:
>
> **brand | model**
>
> **Relationship**: one to many
>
> **Note**: The side pointing to model is many
>
> **Requirements**: `"""`
>
> The database needs to maintain records of all spaceship brands and models …… A dealer is associated with one address.
>
> (This is an excerpt. Full text can be found at https://bit.ly/grdb.)
>
> `"""`

Here is a sample response from ChatGPT:

#### ChatGPT GPT-4o

**brand | model**

**Relationship**: one to many

**Note**: the side pointing to model is many

**model | spaceship**

**Relationship**: one to many

**Note**: The side pointing to spaceship is many

**spaceship | dealer**

**Relationship**: many to one

**Note**: The side pointing to dealer is one

**spaceship | customer**

**Relationship**: many to one

**Note**: A customer can own multiple spaceships, and a spaceship can be owned by multiple customers (e.g., shared ownership)

**dealer | address**

**Relationship**: one to one

**Note**: Each dealer is associated with exactly one address

**customer | address**

**Relationship**: many to one

**Note**: The side pointing to address is one

As in the design of entities and attributes, ChatGPT does many things right. In the preceding answer, most relationships were developed properly with the exception of the relationship between `customer` and `spaceship`. The requirements you gathered were quite explicit:

[The image would show the requirements about spaceship ownership]

It is possible that when the information on a relationship is scattered across multiple sentences, ChatGPT has difficulty parsing it properly. It is also possible that ChatGPT somehow starts to hallucinate when answering this question. Regardless, you have a robust mastery of database design after reading the first seven chapters of this book, and the error is not hard to fix:

> **spaceship | customer**
>
> **Relationship**: many to one
>
> **Note**: the side pointing to customer is one

You may also notice that the relationship between `customer` and `dealer` is missing. The requirement you gathered is clear:

- A dealer serves one or more customers.
- A customer is served by a dealer.

You can add this relationship yourself to the text of relationships:

> **customer | dealer**
>
> **Relationship**: many to many
>
> **Note**: both sides are many

### Minimum cardinalities and foreign keys

ChatGPT didn't provide much information about the min cardinalities or foreign keys of relationships between pairs of entities. You didn't ask for this information to begin with because you needed to make sure that each relationship (max cardinalities) was identified properly first. Now is a good time to make a new request to ChatGPT. Here is an example of how you might structure this request:

> I am designing a database for a manufacturer of spaceships. I have identified some of the characteristics of six entities: brand, model, spaceship, dealer, customer, and address. Help me identify the min cardinality and where the foreign key should be placed between each pair of entities based on the given requirements and the known relationship characteristics. Generate output using the desired format.
>
> **Desired format**:
>
> **brand | model**
>
> **Relationship**: one to many
>
> **Note 1**: The side pointing to model is many
>
> **Note 2**: The foreign is in model
>
> **Note 3**: The min cardinality close to model is relaxed from 1 to 0
>
> **Requirements**: `"""`
>
> The database needs to maintain records of all spaceship brands and models …… A dealer is associated with one address.
>
> (This is an excerpt. Full text can be found at https://bit.ly/grdb.)
>
> `"""`
>
> **Characteristics**: `"""`
>
> **brand | model**
>
> **Relationship**: one to many
>
> **Note**: The side pointing to model is many
>
> ……
>
> **customer | address**
>
> **Relationship**: many to one
>
> **Note**: The side pointing to address is one
>
> (This is an excerpt. Full text can be found at https://bit.ly/grdb.)
>
> `"""`

Following is a sample answer from ChatGPT to this request:

#### ChatGPT GPT-4o

**brand | model**

**Relationship**: one to many

**Note 1**: The side pointing to model is many

**Note 2**: The foreign key is in model

**Note 3**: The minimum cardinality close to model is relaxed from 1 to 0

**model | spaceship**

**Relationship**: one to many

**Note 1**: The side pointing to spaceship is many

**Note 2**: The foreign key is in spaceship

**Note 3**: The minimum cardinality close to spaceship is relaxed from 1 to 0

**customer | dealer**

**Relationship**: many to many

**Note 1**: A junction table `customer_dealer` is needed

**Note 2**: The foreign keys are in `customer_dealer`

**Note 3**: The minimum cardinalities close to `customer_dealer` are relaxed from 1 to 0

**spaceship | dealer**

**Relationship**: many to one

**Note 1**: The side pointing to dealer is one

**Note 2**: The foreign key is in spaceship

**Note 3**: The minimum cardinality close to dealer is relaxed from 1 to 0

**spaceship | customer**

**Relationship**: many to one

**Note 1**: The side pointing to customer is one

**Note 2**: The foreign key is in spaceship

**Note 3**: The minimum cardinality close to spaceship is relaxed from 1 to 0

**dealer | address**

**Relationship**: one to one

**Note 1**: Each dealer is associated with exactly one address

**Note 2**: The foreign key is in dealer

**Note 3**: The minimum cardinality close to address is 1

**customer | address**

**Relationship**: many to one

**Note 1**: The side pointing to address is one

**Note 2**: The foreign key is in customer

**Note 3**: The minimum cardinality close to address is relaxed from 1 to 0

ChatGPT handled the placement of foreign keys quite well, especially when three entities are related. The relationships among `customer`, `dealer`, and `address` are similar to a challenge you tackled in earlier chapters: how to handle the relationships among address, user, and payment methods for The Sci-Fi Collective. The relationships among `customer`, `dealer`, and `address` are summarized as follows:

[The image would show the relationships diagram]

Beyond foreign keys, ChatGPT is rather confused about the min cardinalities, especially when a min cardinality needs to be relaxed from one to zero. It is up to you to fix those mistakes, using what you learned from chapter 5. If your memory is blurred, here are some rules of thumb about when to relax a min cardinality:

- In a one-to-one relationship, if one entity is typically created before the other, you may set the min cardinality of the second entity to zero to allow the first entity to exist without an immediate counterpart.
- In a one-to-many relationship, the cardinality that's closer to the many side needs to be relaxed. This relaxation allows for cases in which the entity on the one side might exist without any corresponding entries on the many side. A customer might exist without any addresses, for example.
- In a many-to-many relationship, the min cardinalities are often set to zero on both sides if either entity can exist without the other. If there are strict business rules about the existence of the entities, however, you might keep one cardinality set to one.

You can start with the relationships between `dealer` and `address` and between `customer` and `address`. The gathered requirements don't say much about the min cardinalities of their relationships. After following up with the software developers, you gained some new understanding:

- *A dealer can't have an account without an address.* SHIPS R US's web app doesn't allow dealers to register accounts without providing address information. In other words, it is not possible for a dealer record to exist without a corresponding address.
- *SHIPS R US maintains user records for purposes such as outreach and recalls but doesn't allow customers to register accounts directly.* Instead, dealers enter the customer information plus the address information into the system. In other words, it is not possible for a customer record to exist without a corresponding address.

Combining such information and rules of thumb about when to relax a min cardinality, you can make the following revisions:

[The image would show cardinality revisions]

The revision to the relationship between `customer` and `address` is straightforward considering that the relationship is one-to-many. The min cardinality of the many side needs to be relaxed to make data entry possible. By contrast, the revision to the relationship between `dealer` and `address` is more nuanced. You may wonder whether you can relax the side closer to `address` instead of `dealer`. You can, but doing so will make things messier and less consistent, as demonstrated in the following figure:

[The image would show alternative cardinality options]

Because `dealer` is the child table in this relationship, it contains the foreign key `address_id`. In other words, a new record in the `dealer` table needs to reference an existing `address_id` value. As the result, relaxing the cardinality closer to `dealer` is a better choice. The revised relationships between `customer` and `address` and between `dealer` and `address` can be summarized as follows:

[The image would show the final cardinality design]

Beyond the two relationships, you can find one more min cardinalities that need to be relaxed in the relationship between `spaceship` and `customer`. The requirements for this relationship are

- A spaceship is associated with one model and can be associated with no more than one owner and no more than one dealer.
- A customer is associated with one or more spaceships that they bought.

In other words, when a spaceship is manufactured, its record is entered into the system immediately without being associated with a customer. Based on this information, the min cardinality close to `customer` rather than `spaceship` needs to be relaxed to zero:

[The image would show spaceship-customer cardinality]

The revised relationship can be summarized as follows:

[The image would show the final spaceship-customer relationship]

You may notice that the foreign key of this relationship (`customer_id`) is in `spaceship`. By default, `customer_id` needs to reference a record in `customer`. To make sure that the foreign key is aligned with the requirements, make it optional. In other words, it should allow `NULL` values.

### Communicate your design

As discussed earlier in this chapter in the "Entities and attributes" section, you are likely to need visualization to communicate your design better. If you choose to draw your design by hand, you'll get something like the following figure.

[The image would show the complete hand-drawn ERD]

If you need ChatGPT and dbdigram.io for a much bigger project, you must retrieve the SQL code first. The following request aims to get MySQL code from ChatGPT:

> I am designing a database. Help me generate MySQL code based on the following description of entities and relationships.
>
> **Description**: `"""`
>
> # description of entities starts here
>
> **Entity name of Brand**: `brand`
>
> **Attributes**:
>
> **Name**: name `- VARCHAR(100)`
>
> **Primary key**: name
>
> ……
>
> # description of relationships starts here
>
> **brand | model**
>
> **Relationship**: one to many
>
> **Note 1**: The side pointing to model is many
>
> ……
>
> **Country**: `country - CHAR(2)`
>
> **Primary key**: `address_id`
>
> **Note 1**: `suburb` and `postal_code` are optional
>
> (This is an excerpt. Full text can be found at https://bit.ly/grdb.)
>
> `"""`

After getting the code, you can copy and paste it into dbdiagram.io to get the following diagram:

[The image would show the final dbdiagram.io visualization]

## Implementation

Now that you designed the entities, attributes, and relationships for the database of SHIPS R US, you are ready to implement the database. First, however, you have to make sure that your database design is normalized. When you check your database design against the requirements for normal forms, you see that your database design is in Boyce-Codd Normal Form (BCNF). You can also ask ChatGPT to help with the checking ("Is my database design normalized?") and verify the answers later.

[The image would show normalization analysis]

### Constraints

Applying constraints based on requirement analysis is a necessary step in implementing your database design. In chapter 6, you learned about a variety of constraints, such as primary key, foreign key, `NOT NULL`, and unique constraints. Review your analysis to identify the attributes that require constraints and the type of constraints that are appropriate. ChatGPT can offer help for this task as well. Copy and paste all the relevant requirements and the revised output from the preceding two sections and then formulate a new request:

> I am designing a database. Help me identify the attributes that need constraints and the type of constraints using the desired format based on the given requirements, entities and attributes, and relationships among entities.
>
> **Desired formats**:
>
> **Entity name**: `brand`
>
> **Attribute in focus**:
>
> * `model_number`: primary key
>
> * `model_name`: `NOT NULL`
>
> * `brand_name`: foreign key
>
> **Requirements**: `"""`
>
> The database needs to maintain records of all spaceship brands and models, manufactured ……
>
> (This is an excerpt. Full text can be found at https://bit.ly/grdb.)
>
> `"""`
>
> **Entity and attributes**: `"""`
>
> **Entity name of Brand**: `brand`
>
> **Attributes**:
>
> **Name**: `name - VARCHAR(100)……`
>
> (This is an excerpt. Full text can be found at https://bit.ly/grdb.)
>
> `"""`
>
> **Relationships**: `"""`
>
> **brand | model**
>
> **Relationship**: one to many
>
> **Note 1**: The side pointing to model is many……
>
> (This is an excerpt. Full text can be found at https://bit.ly/grdb.)
>
> `"""`

Here is a sample answer to this request:

#### ChatGPT GPT-4o

**Entity**: `Brand`

**Attribute in focus**:

**name**: primary key

**Entity**: `Model`

**Attributes in focus**:

`model_number`: primary key constraint

`model_name`: `NOT NULL`

`brand_name`: foreign key constraint (references `brand.name`)

**Entity**: `Spaceship`

**Attributes in focus**:

`serial_number`: primary key

`recommended_price`: `CHECK` (e.g., `CHECK (recommended_price >= 0)`)

`year`: `CHECK` (e.g., `CHECK (year >= 1900)`)

`model_number`: foreign key (references `model.model_number`)

`dealer_id`: foreign key (references `dealer.dealer_id`)

`customer_id`: foreign key (references `customer.customer_id`)

**Entity**: `Dealer`

**Attributes in focus**:

`dealer_id`: primary key

`name`: `NOT NULL`

`email_address`: `UNIQUE`

`website_url`: `NOT NULL`

(`country_code`, `dealer_phone_number`): `UNIQUE`

`address_id`: foreign key (references `address.address_id`)

**Entity**: `Customer`

**Attributes in focus**:

`customer_id`: primary key

`name`: `NOT NULL`

`email_address`: `UNIQUE`

(`country_code`, `customer_phone_number`): `UNIQUE`

`address_id`: foreign key (references `address.address_id`)

**Entity**: `Customer_Dealer`

**Attributes in focus**:

(`customer_id, dealer_id`): primary key

`customer_id`: foreign key (references `customer. customer_id`)

`dealer_id`: foreign key (references `dealer.dealer_id)`

**Entity**: `Address`

**Attributes in focus**:

`address_id: primary key`

`country`: `CHECK (ensures valid country codes, e.g., CHECK (country IN ('US', 'CA', ...)))`

As you see, ChatGPT properly identified most of the constraints, but it missed a few attributes that require `NOT NULL` constraints. Also, it neglected the scenarios in which an attribute requires more than one constraint. `email_address` in `dealer`, for example, requires both `NOT NULL` and `UNIQUE` constraints. You need to fix these problems yourself and store revised text of the constraints so that you can use them for the next step.

### Optimization

In optimization, you aim to reduce redundancy and increase the consistency and efficiency of your database design before converting it to code. You can pose some open-ended general questions to ChatGPT (such as "How do I optimize my database design?"). But asking specific questions about certain things that you notice always results in better responses.

[The image would show optimization suggestions]

You may notice, for example, that the ChatGPT suggested using a `CHECK` constraint on the `country` attribute in `address`. Considering that there are about 200 countries in the world, however, this constraint will be painful to code and messy. You can raise a question about this aspect:

> Q1. Applying a `CHECK` constraint to the `country` attribute in the `address` table is painful because there are about 200 countries in the world. What's a common and recommended approach to store such information without this constraint but still retain the data validity check?

You can raise the same question about the `country_code` attribute in `customer` and `dealer`:

> Q2. To ensure the validity of the country code of phone numbers in the `customer`/`address` tables, what's a common and recommended approach to store such information?

ChatGPT's responses are quite useful:

#### ChatGPT GPT-4o

Q1 Answer: Instead of using a `CHECK` constraint for the country code, a better approach is to use a reference to a separate `Country` table. This table would contain a list of valid country codes and their corresponding names …

Q2 Answer: To ensure the data validity, you can follow a similar approach to use a separate table …

To synthesize the two suggestions, you can create a single table to store information about each country, such as country abbreviation, country code, and name. The table will be prepopulated with valid information, so it can be linked to `customer`, `dealer`, and `address` to ensure data validity. The updated database design is as follows:

[The image would show the updated design with country table]

You need to update the information you stored about entities, attributes, relationships, and constraints. Then you will be ready to convert the updated design to SQL code with the help of ChatGPT. To achieve the best result, be specific in your request. Here is an example request that asks for MySQL code:

> I am designing a database. Generate MySQL code based on the given entity, attributes, and relationships, and constraints.
>
> **Entity and attributes**: `"""`
>
> **Entity name of Brand**: `brand` ……
>
> (This is an excerpt. Full text can be found at https://bit.ly/grdb.)
>
> `"""`
>
> **Relationships**: `"""`
>
> **brand | model** ……
>
> (This is an excerpt. Full text can be found at https://bit.ly/grdb.)
>
> `"""`
>
> **Constraints**: `"""`
>
> **Entity**: `brand` ……
>
> (This is an excerpt. Full text can be found at https://bit.ly/grdb.)
>
> `"""`

Depending on the RDBMS you are using, you may want the code to be in a different SQL dialect. As long as the provided information is detailed enough, it is hard for ChatGPT to make serious mistakes at this step. You can find the full SQL code in `chapter_08` folder in our GitHub repository. If your requirements have sufficient information about which columns require indexing, chapter 7 shows you how to take preemptive measures to index those columns. Otherwise, you can wait for the data and the use of database tell you more.

Finally, ChatGPT can be very useful for generating sample data that you can use to test your database and for identifying problems preemptively. Following is a sample request for testing data:

> I am designing a database. Generate sample data that can be used for testing based on the given SQL code that implements the database.
>
> **SQL Code**:
>
> ```sql
> '''
> -- Create brand table
> CREATE TABLE brand (name VARCHAR(100) PRIMARY KEY);
> ……
> -- Create customer_dealer table
> CREATE TABLE customer_dealer (
>  customer_id INT NOT NULL,
>  dealer_id INT NOT NULL,
>  CONSTRAINT pk_customer_dealer ……
>  CONSTRAINT fk_customer_dealer_customer ……
>  CONSTRAINT fk_customer_dealer_dealer ……
> );
> ```
>
> (This is a snippet. Full code can be found at https://bit.ly/grdb.)
>
> `"""`

Now you've gone through the full process of database design with the help of ChatGPT. Good job!

## Recap

- To use ChatGPT for database design effectively, follow some rules of thumb: be specific, descriptive, and as detailed as possible; separate instructions from context; and articulate the desired output format through examples.
- You should take a stepwise approach to using ChatGPT to help with database design and make verifications and revisions to ChatGPT's output at each step.
- Store the design at each milestone in text for smooth communication with ChatGPT in the future.
- If you need to communicate your design draft with coworkers, you can convert your design to SQL code with the help of ChatGPT and visualize it by using tools such as dbdiagram.io.