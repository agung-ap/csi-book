# Chapter 4. Data Engineering for LLMs

In this chapter, you will learn about data engineering, data management practices, and the database tools and systems available. The discussion will be geared toward data, DevOps, and MLOps engineers who want to become LLMOps engineers and/or lead their company’s data engineering efforts. By the end of this chapter, you will have a strong grasp of the foundations of data engineering, as well as best practices for LLMs.

# Data Engineering and the Rise of LLMs

In the late 1960s, British computer scientist Edgar F. Codd, fresh from finishing his doctorate in self-replicating computers, was working at IBM. Codd became fascinated by the theory of data arrangement and in 1970 published an internal IBM paper called [“A Relational Model of Data for Large Shared Data Banks”](https://oreil.ly/JG1bn) that introduced what we know today as *relational databases*. For example, instead of a sales table in which each record contains all the information about the products and the customers to whom they’ve been sold, relational databases store this data in multiple related tables: one for customers, one for products, and one for sales. Before relational databases, something as simple as a change in customer address would require changing all sales records for that customer, which was an expensive operation in mainframes. In a relational database, you can change just the customer record, and all the related records will be updated.

While it didn’t fascinate anyone at IBM right away, the paper caught the fancy of several other computer scientists and hobbyists, including Oracle founder Larry Ellison, who developed and sold the first relational database compatible with IBM mainframes. IBM also developed a language to query databases, originally named SEQUEL but now called Structured Query Language (SQL), which later became a standard. In 1981, Codd’s work on relational databases won him a Turing Award, the most prestigious accolade in computer science. Recognizing the popularity of relational databases and the need for systems to manage them, in 1983 IBM created its own database management system, called DB2. Relational databases became the industry standard, used everywhere: for indexing, cataloging, and so on. The people who managed these systems for enterprises at IBM and Oracle were called *database administrators*, usually abbreviated as DBAs. (The title *data engineer* became popular alongside cloud computing in the 2010s.)

Codd later cowrote another paper, [“Providing OLAP to User-Analysts: An IT Mandate,”](https://oreil.ly/gUwKl) which coined the term *online analytical processing* (OLAP) to refer to a system for quickly processing and querying multidimensional data. OLAP is the foundation of most data-processing systems today.

In 1990, Tim Berners-Lee created the World Wide Web, which exponentially increased the volume of data being generated and recorded. While a lot of this data was structured, meaning of fixed maximum length and type like a postal code, a lot of it was also unstructured, of variable length and type, like music, essays, and videos. Relational databases organize information into tables with predefined columns and strongly enforced data types. Because every row in a table must follow the same schema, they excel at handling highly structured data and supporting complex, SQL-based queries that join many tables together with consistent ACID (atomicity, consistency, isolation, durability) guarantees. This makes them the go-to choice for transactional systems such as banking, inventory, and traditional business applications where data integrity and cross-table relationships are required, but not as suitable for the unstructured data that exists in the internet.

*Nonrelational* (NoSQL) databases emerged to address workloads that relational systems handle less efficiently—massive, rapidly changing, or loosely structured datasets. Key-value stores provide fast lookups by pairing a unique key with data. A specific type of key-value store, document databases, store each record as a self-contained JSON document, allowing every document to have its own shape. This flexibility is ideal for content management systems, product catalogs, and other domains where fields vary across records, which is very common with internet data. Key-value databases can also store binary files, such as videos and images, in *blobs* (binary large objects), making them ideally suited for use in this new data environment.

In addition, we have vector and graph databases. *Graph databases* focus on representing interconnected entities. Instead of tables or documents, they store nodes and edges, enabling millisecond-level pathfinding queries such as social network friend-of-a-friend searches, supply chain impact analysis, or discovery of the relationships between documents.

*Vector databases* are designed to store and index high-dimensional embeddings—dense numeric vectors that capture the semantic meaning of text, images, audio, or other content. Instead of looking for exact matches, they use* approximate nearest neighbor *(ANN) algorithms to return the items whose vectors lie closest to a query vector in that multidimensional space. This makes them the engine behind semantic search, recommendation systems, image-or-audio similarity matching, and *retrieval-augmented generation*(*RAG*) pipelines that supply LLM prompts with relevant context in milliseconds.

Because each model excels at a different access pattern, modern applications often combine them: a relational store for ACID-compliant transactions; a document or key-value store for flexible, semistructured content and media blobs; a graph database for when relationships themselves are the primary data; and a vector database for anything that hinges on “meaningful similarity.” Much of the data engineering work consists of choosing the right balance among these database types and combining their data for the desired application.

LLMs are driving another revolution in data storage and management. Before LLMs, data scientists and analysts relied on simpler techniques for NLP tasks, such as representing textual data as numerical features (which ML algorithms require). Two of the most commonly used methods to analyze a collection of documents (called a *corpus*) were called *bag of words* (BoW) and *term frequency–inverse document frequency* (TF-IDF). Both methods transform unstructured text into structured, matrix-based formats that can be processed by traditional ML algorithms. BoW represents text as a sparse matrix, where each row corresponds to a document and each column corresponds to a word from the corpus. The value in each cell reflects the number of times that word appears in the document (called *term frequency*, or TF), ignoring word order but preserving frequency. TF-IDF builds on BoW by weighting TF with a measure of how rare that word is across the entire corpus (called* inverse document frequency*, or IDF). This adjustment reduces the impact of common words like *the* and *and* while emphasizing terms that are more informative in context.

These matrix representations are typically stored in structured or binary data formats and processed with tools suited to the size of the data. Before LLMs became mainstream, the backbone of NLP workflows was a set of tools that included Python packages like Pandas and NumPy, to provide efficient frameworks for manipulating BoW and TF-IDF matrices, and Parquet and HDF5, for storing and querying larger, preprocessed datasets. In production environments, databases like PostgreSQL, MongoDB, and Elasticsearch were widely used to store, index, and query NLP data, particularly for applications requiring fast retrieval or search capabilities. These tools enabled the development of applications like search engines, recommendation systems, sentiment analysis, and text classification models.

One of the main contributors to the rise of LLMs was the development of embeddings. As you learned in [Chapter 1](https://learning.oreilly.com/library/view/llmops/9781098154196/ch01.html#ch01_introduction_to_large_language_models_1748895465615150), embeddings are algorithms that transform textual data into a numerical representation—vectors of real numbers—that also encodes meaning. With embeddings, words and phrases with similar meanings are “closer” to each other than words and phrases with different meanings. ​This led to the introduction of the *vector database*, a new kind of database that can store vectors along with other metadata items and use ML algorithms to query them. As mentioned in [Chapter 2](https://learning.oreilly.com/library/view/llmops/9781098154196/ch02.html#ch02_introduction_to_llmops_1748895480208948), LLMOps is a framework for making and maintaining LLM applications that are reliable, robust, and scalable in production. However, as the adage goes, your model is only as good as your data: “Garbage in, garbage out.” Let’s take it a step further and say that your LLMOps maturity is only as good as your data engineering system.

In its early years, data management work was primarily about acquiring, storing, and retrieving data. Machine learning and LLMs have added new steps like transforming the data into appropriate representations, which requires additional skills. To acquire these skills, companies have two options, as we discussed in the previous chapter: either hire LLM engineers, upskill them, and integrate them into the data team or hire data engineers, integrate them into LLM development teams, and upskill them into LLMOps engineers.

Either way, the shift from task-specific to task-agnostic machine learning models is only going to continue. The data market is huge and growing, and companies working with LLMs need skilled professionals to manage their data engineering systems.

# The DataOps Engineer Role

DataOps engineers usually have prior experience as data engineers or data scientists, with additional expertise to navigate the complexities of domain composition, data quantity, and data quality at scale. They are skilled in advanced techniques such as global deduplication and dynamic data selection for continuous fine-tuning.

Data engineering for LLMs involves designing, developing, and managing data pipelines and infrastructure to support training, evaluating, and deploying these models. DataOps engineers implement and optimize scaling laws; balance trade-offs between quality and quantity; and manage diverse, large-scale datasets. However, their role goes beyond managing data pipelines. They orchestrate the entire data lifecycle for LLMs, from data acquisition to deployment, continuously improving model performance in a highly complex and evolving landscape.

This specialization marks a significant evolution from the data engineering and management practices of the past, requiring a much more sophisticated and targeted approach to the daily work of a data engineer. Before the LLM era, data engineering was dominated by pipelines moving well-defined, mostly structured data from operational sources into data warehouses and lakes for reporting or analytics. The emphasis was on batch ETL/ELT jobs, dimensional modeling, slowly changing dimensions, and governance practices that treated data quality as a matter of schema conformance, referential integrity, and basic deduplication. Unstructured text might be archived in data lakes, but it was rarely a first-class citizen; search and analytics workloads still revolved around rows, columns, and aggregate SQL.

LLM-centric workloads change everything. Now the raw material is heterogeneous text, code, images, audio, and chat logs whose value depends on *semantic richness*—that is, the informational value of the content—rather than a rigid structure. Pipelines must tokenize, chunk, embed, and version this content; store it in vector indexes for similarity search; and apply filters for personally identifiable information, toxicity, and licensing constraints. Instead of ETL jobs, teams run continuous ingestion and re-embedding loops so that RAG systems stay fresh, and they log every prompt–response pair so that the inputs and outputs can be evaluated and improve the future performance of this system. Data quality in this context is judged by grounding, factuality, and bias metrics—attributes that require automated red-teaming and human-in-the-loop (HITL) review rather than the data structure violation checks of the past.

As a result, modern data engineering stacks now blend traditional warehouses with object stores, vector databases, and feature stores. Orchestration frameworks like Airflow and Dagster coexist with LLMOps tools, and governance expands to cover model cards, dataset nutrition labels, and lineage tracing of each token back to its legal source. Supporting LLMs transforms data engineering from “plumbing with rows and columns” into “becoming the owners and guardians of language and knowledge.”

Data engineering directly impacts how well ML applications and LLMs perform. The quality, type, and amount of data used during training can make or break a model’s effectiveness. There are two additional complications here. The first is that almost all of the data used for LLMs is unstructured. The second is that there is a lot more data. These two differences make some tasks substantially harder. For example, in traditional machine learning, you can check a data input for outliers, perhaps by discarding all records in which someone’s age is listed as negative or over 130 years old. This is much harder to do with unstructured data, making data management for LLMs substantially more complex than data engineering for non-generative ML models.

# Data Management

While *data management* focuses on managing an organization’s data assets, *data engineering *involves designing and building infrastructure for data storage, processing, and analysis. An effective data engineering team for LLMs requires both a DataOps engineer, to focus on data management, and a data engineer, to focus on data pipeline design and management (see [Figure 4-1](https://learning.oreilly.com/library/view/llmops/9781098154196/ch04.html#ch04_figure_1_1748895507345505)). Together they integrate diverse data sources, help LLMs learn better, and help avoid problems like hallucination and bias.

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098154196/files/assets/llmo_0401.png)

###### Figure 4-1. Components of data engineering for LLMs

There are two basic approaches to data management for LLMs: static and dynamic. *Static data management* means keeping the dataset the same throughout training. This can lead to issues like repetitive data that does not adapt to the model’s changing needs. *Dynamic data management* involves continuously updating and tweaking the data as the model trains. This method is more flexible, but it can be trickier to handle because it requires constant attention to the data’s quality and relevance.

Some methods adjust the dataset dynamically during training. For example, *dynamic data pruning* removes  less useful examples as training progresses, and *binary classifiers* can help determine when to stop early, based on how well the model follows instructions. Other techniques involve choosing tasks that provide the most information or refining tasks through an iterative process.

## Synthetic Data

As of this writing, newer models, such as Microsoft Phi-4 and DeepSeek-R1, have shown performance improvements using *synthetic data*—data that is automatically created from existing data while maintaining its statistical properties. For example, from a dataset that contains the heights, positions, and scoring records of 100 real basketball players, you could use statistical techniques to create a large number of records of nonexistent players who are similar to the existing ones, augmenting the dataset. To synthetically create the type of long-form text used to train LLMs, DataOps engineers frequently use older generations of text-generating models.

As we mentioned earlier, when it comes to task composition, balancing quantity with quality is the key. Larger datasets usually mean more diverse and higher-quality data, which generally leads to better performance but also requires efficient data-processing pipelines. To build strong models, DataOps engineers need to master orchestration: automatically applying these techniques at the appropriate times.

## LLM Pipelines

So what’s changed between conventional ML and LLMs, and why do we need a different pipeline?

As mentioned, in conventional ML you’re typically dealing with *structured data*—numbers neatly organized in tables or spreadsheets. The data comes from databases, sensors, or APIs. It’s clean, manageable, and straightforward. Conventional ML leans heavily on *feature engineering*, where data engineers take raw data and shape it into something useful, crafting numerical features that feed the model what it needs to make predictions. It’s a hands-on process where the human touch really matters.

In most cases, you’re working with smaller datasets. You don’t need massive amounts of data, and processing can be handled with traditional CPUs or GPUs. This approach is efficient and controlled, and it works well when the task is clear. It remains the go-to for tasks that need clear predictions or classifications, where the data is structured and the problem has a defined boundary.

When it comes to LLMs, though, it’s all about *unstructured data*—text that’s messy, sprawling, and unorganized, such as articles, code, and social media posts. The data sources range from web scraping to document repositories and text APIs. It’s a flood of information, far more chaotic than the clean spreadsheets of traditional ML. Real-world data is unstructured. For example, imagine that you’re using data from news websites to train a model (note that an appropriate license is required for this use). If you go check a few news websites right now, you’ll likely see lots of other artifacts mixed with the news articles: advertisements, images, boxes explaining some concepts in additional detail, boxes with related news, a list of editor picks, and so on, all interspersed with the article itself and each one using a different format. In addition, news websites are massive datasets—enormous volumes of text that require powerful graphics processing units (GPUs) or even specialized hardware like tensor processing units (TPUs) to process. This is data at scale, and the processing power needs to match it.

A final difference is that while traditional ML models have very clear performance metrics, such as precision and recall, LLMs need to produce content that is human-like, and judging whether the output is human-like frequently requires submitting the generated output to humans. This task requires a lot more experimentation than models that work with structured data. For example, with structured data, you can easily improve the model by dropping outliers or incorrect examples, which means that some classes of data are clearly more valuable than others. Given the state of the current research, it’s still not clear what classes of data are more valuable for LLM training; for example, text that contains wrong information may still be helpful if it has a good sentence structure. Besides dealing with unstructured data and requiring more computing power, the LLMOps engineer needs to perform experiments to improve the data input and to measure the desired outputs.

## Training an LLM

At a high level, training an LLM has two steps: pretraining and instruction fine-tuning ([Figure 4-2](https://learning.oreilly.com/library/view/llmops/9781098154196/ch04.html#ch04_figure_2_1748895507345543)). In the *pretraining* step, the model learns the general rules and facts of language—grammar, syntax, style, domain knowledge. This occurs before you ever ask it to follow instructions or specialize for a task. The pretraining step is usually done by occlusion: getting a chunk of data, hiding a word, and training a machine learning model to guess the word. Your goal is to train a model that minimizes the errors of guessing words. *Fine-tuning* is usually done by providing a set of complex instructions and expected answers. With this step, your goal is to train a model that minimizes the errors in the answers. As it is traditional in machine learning, the better data you have, the better your result, so we will spend the rest of this chapter talking about strategies to ensure your data engineering is done well.

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098154196/files/assets/llmo_0402.png)

###### Figure 4-2. Example of an LLM training pipeline

### The original data engineering lifecycle

Conventionally, the *data engineering lifecycle *(DELC) for ML teams has looked like the diagram in [Figure 4-3](https://learning.oreilly.com/library/view/llmops/9781098154196/ch04.html#ch04_figure_3_1748895507345568). The DELC comprises five stages that turn raw data into a useful end product, ready for consumption by analysts, data scientists, ML engineers, and others. As such, the role of a data engineer before LLMs was to develop and maintain data pipelines and ensure data quality.

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098154196/files/assets/llmo_0403.png)

###### Figure 4-3. The data engineering lifecycle (source: [Fundamentals of Data Engineering](https://learning.oreilly.com/library/view/fundamentals-of-data/9781098108298/))

Back then, the five key components of the DELC were:

GenerationThis involves working with the teams and processes that are generating the data. For example, if the data is being generated by an API or a survey, the engineer works with the team that is building the API or survey to ensure that the data generated is of high quality. This component also includes creating synthetic data, if required.

IngestionThis includes collecting and transferring data into the appropriate data storage.

StorageThe engineer merges the data into data lakes and stores it in a database.

TransformationThis includes *data cleaning*, which is the process of dealing with outliers, missing data, and duplicate data.

ServingTransformed data is made available to end users and/or data science teams.

### Emerging questions in data engineering

Creating a DELC for LLMOps (see [Figure 4-4](https://learning.oreilly.com/library/view/llmops/9781098154196/ch04.html#ch04_figure_4_1748895507345590)) requires answering new questions, many of which remain unaddressed in the data engineering literature and practice.

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098154196/files/assets/llmo_0404.png)

###### Figure 4-4. A data management pipeline for LLMs (based on an image by [Wang et al., 2023](https://oreil.ly/o9BYJ))

This chapter will build toward a new DELC by addressing concerns like ​these:

-

What kind of data composition is ideal for your LLM applications?

-

Which scaling law applies to you?

-

How much repetition is acceptable?

-

What techniques should you use for data quality filtering?

-

What models should you use to remove duplicates from the data?

-

How should you handle toxic and biased data?

-

How much data diversity do you need?

-

How can you craft the best prompts when generating synthetic data?

-

How should you monitor data aging?

If you don’t know some of these terms, it’s totally all right; the next section discusses them in detail. In fact, in the latter half of this chapter, you will learn how to think about these problems methodologically. But first, let’s examine these emerging concerns one by one.

## Data Composition

Publicly available training datasets typically consist of a diverse array of data sourced from multiple domains. This multi-domain approach is common among LLMs. Early training corpora were composed of highly diverse data, including sources like web pages and Wikipedia, and were valued for their broad coverage and variety. However, as the focus on data quality increased, more specialized, higher-quality content was needed, such as books and academic papers. This shift was driven by the need for language models to perform advanced tasks and exhibit enhanced capabilities.

[More-recent research shows](https://oreil.ly/nXFWr) that LLMs trained on both computer code and unstructured text are better at solving unstructured tasks. It turns out that what LLMs learn when they train on relatively structured coding data also transfers to unstructured tasks. At the same time, LLMs’ ability to generate code has improved, and software engineers and data scientists are now using tools like GitHub Copilot widely. These innovations mean that domains like code and mathematical texts have recently begun to occupy a larger proportion of the total training data.

This trend suggests that, over time, a broader range of domains is being included in training datasets to provide LLMs with more diverse and powerful abilities. [Research has shown](https://oreil.ly/5WJNK) that an appropriately mixed, multi-domain training dataset can be vital for developing models with robust generalized capabilities.

As of this writing, researchers are creating guiding principles for determining the optimal domain mixture ratios in pretraining. Early efforts combined careful experimentation with intuitive reasoning; [more recent advancements](https://oreil.ly/13j5J) have introduced automated methods for assigning domain weights to create a suitable target distribution.

## Scaling Laws

Even before the widespread adoption of LLMs, the relationship between the size of the training dataset and the performance of transformer-based language models had already gained significant attention from researchers. Training a model involves minimizing loss, or the rate of errors generated by the model. For example, if the model needs to guess the next word in the phrase “I was very thirsty so I drank…,” guessing “bookshelf” will result in a greater loss than guessing “water.” [Kaplan et al. showed](https://oreil.ly/h2AGb) in 2020 that a language model’s loss follows a power law relationship, in which one quantity changes proportionally to another quantity raised to a fixed exponent. For example, the volume of a sphere follows a power law relationship with the cube of its radius. In language models, loss follows a power law relationship with either the training dataset size or the model size (number of parameters), provided that neither of these factors is a bottleneck and that the training computational budget is adequate.

Mathematically, this relationship can be expressed as:

Loss∝(1N)αorLoss∝(1D)βwhere:

-

*N* represents the model size

-

*D* represents the training dataset size

-

α and β are constants that depend on the specific conditions of the model and dataset

Kaplan and coauthors conclude that model loss decreases predictably as long as both the model size and training dataset size are scaled up simultaneously. Furthermore, they suggest that to maintain optimal performance, the sizes of the model and the training dataset should scale at roughly the same rate, assuming a large enough computing budget.

Additionally, they analyze the optimal allocation of resources, given a fixed computing budget *C*, and find that the optimal training dataset size and the optimal model size should have the following relationship:

Dopt∝C0.27andNopt∝C0.73This indicates that the model size should increase faster than the training dataset size to achieve the best performance, provided that the computing budget is fixed.

As LLMs became larger and more widely adopted, extracting the best possible training from a computing budget became a lot more economically important. Building on Kaplan’s work, [Hoffmann and coauthors](https://oreil.ly/VFC8X) conducted experiments with much larger language models and proposed a new scaling law, often referred to as the *Chinchilla scaling law*, that highlights the trade-off between model size and the amount of training data. It suggests that many existing LLMs, like GPT-3, are *undertrained* relative to their size, meaning they have more parameters than necessary for the data they were trained on. The law posits that, to achieve optimal performance, there should be a balance between increasing the number of parameters and increasing the volume of the training data, with a preference for scaling data if the compute budget is fixed.

Models that follow this principle achieve better performance than larger models trained on less data while requiring fewer computational resources. This insight has shifted the focus of LLM research from simply making models larger and larger to allocating compute more efficiently between model size and data quantity.

## Data Repetition

While early studies on scaling laws focused on models trained on unique data for only one epoch, recent research has explored the effects of *repeating* data within the training dataset. As models continue to grow, the demand for high-quality training data increases, raising concerns about potentially exhausting the supply of such data.

To address these concerns, several studies have examined the impact of repeated pretraining on entire datasets for multiple epochs. These studies have introduced a scaling law for repeated training, which highlights diminishing returns as repetition increases and model sizes become larger. This phenomenon, of model performance deterioration over successive epochs, is known as *multi-epoch degradation*. This degradation is influenced by factors such as dataset size, model parameters, and training objectives. As expected, [researchers tried](https://oreil.ly/NWMdx) the classic data improvement techniques to see if they could improve the effectiveness of the existing data for training. Most of them proved largely ineffective except for a technique called *dropout*, which has shown some benefit.

## Data Quality

A variety of quality control techniques are used in pretraining LLMs to ensure the datasets are clean and effective. These include quality filtering, deduplication, and toxicity filtering. Other aspects of the data that are important to improving LLM performance include data diversity and data age.

Let’s take a look at these points more closely:

Quality filteringPublic datasets often contain low-quality data that can hinder LLMs’ training. Common Crawl, for example, is a publicly available web archive that provides vast amounts of raw data collected through web scraping. It includes a diverse range of content, such as blog posts, news articles, forum discussions, and even spam or irrelevant web pages. While this breadth can be valuable, its quality is uneven; Common Crawl datasets frequently include outdated, redundant, or poorly formatted text, as well as content with bias, misinformation, or offensive material.

Deduplication*Deduplication* means ensuring that the dataset is free from repeated or redundant content. This process is important for several reasons. First, it reduces the risk of *memorization*, ​where the model learns specific phrases or examples by repetition instead of generalizing patterns across the data. Second, it minimizes the *train–test overlap*, which happens when identical or very similar data appears in both the training set and evaluation tests, potentially making the test dataset less effective and inflating performance metrics. Third, removing unnecessary repetitions allows the model to focus on diverse and unique content, which leads to better generalization. Deduplication aims to help the model to achieve low *perplexity*, a measure of how well the model predicts the next word.

Toxicity and bias filtering*Toxicity filtering* means removing content that is rude, disrespectful, or otherwise likely to generate negative interactions. Since raw text corpora often contain toxic content, toxicity filters help prevent LLMs from generating harmful outputs. These filters typically use heuristic and rule-based methods, as well as *n*-gram classifiers. While toxicity filtering is effective in reducing the risk of generating toxic context, it can sometimes compromise the model’s ability to generalize as well as its ability to identify toxic content.

In fact, it’s hard to filter content appropriately. For example, texts about marginalized groups frequently contain terms that are deemed toxic. When filtering documents containing toxic terms, you may also filter away documents that are useful for marginalized groups. This increases the risk of marginalizing minority groups in the data, [presenting a challenge](https://oreil.ly/B2y3x) in [building unbiased LLMs](https://oreil.ly/p4sBy).

Data diversity*Data diversity* ensures that the model learns from a wide range of linguistic styles, cultural contexts, and knowledge domains. For example, including text from scientific articles, creative writing, legal documents, social media, and conversational dialog helps the model respond appropriately in different scenarios. Moreover, linguistic diversity—covering multiple languages, dialects, and regional expressions—ensures that the model is accessible to and effective for a global audience. Without sufficient diversity, LLMs risk becoming narrowly specialized or biased, reducing their usefulness and fairness in real-world applications.

Achieving data diversity comes with significant challenges. Public datasets often overrepresent certain languages, regions, or demographics while underrepresenting others. For example, web-based datasets like Common Crawl often disproportionately feature English-language content and informal text, leaving many languages and formal writing styles underrepresented.

Data ageRecent LLMs are often pretrained using newer data, since some of the knowledge the data contains can be time-sensitive. The temporal shift between the pretraining data and the evaluation data can lead to inaccurate performance estimates. This can be hard to correct through fine-tuning, especially for larger models. This issue underlines the importance of considering data age in the pretraining process.

Maintaining a balance among domain composition, data quantity, and data quality in pretraining LLMs is challenging due to several complex interdependencies.

As of this writing, researchers have proposed scaling laws to help us understand how different factors—like data quantity, domain composition, and data quality—work together to influence model performance. [One 2024 study](https://oreil.ly/Vp_SB) has shown a positive correlation between data quality and model scale when the total amount of data remains constant. These interactions make it difficult to optimize one aspect without affecting others, so balancing these factors often involves various trade-offs. For example, increasing data quantity can sometimes lead to lower data quality if the additional data is less relevant or more noisy. Similarly, focusing on high-quality data might reduce the overall quantity available for training. These trade-offs become even more pronounced when working within a fixed computational budget, as optimizing for one factor may necessitate compromises in others.

*Global deduplication*, which removes overlaps among different domains, adds another layer of complexity. While it is essential for reducing redundancy and improving model efficiency, it can also inadvertently remove valuable information, especially if the overlaps are not perfectly identified. [Another study](https://oreil.ly/x7ovs) suggests that domains with higher quality and diversity are more beneficial to model performance than others, further complicating the selection process.

Finally, the relationship among domain composition, data quantity, and data quality isn’t static. These factors interact dynamically and synergistically, meaning that changes in one area can have unpredictable effects on the others. This complexity makes it challenging to develop a one-size-fits-all strategy. Optimizing LLM training requires continuous adjustment and fine-tuning based on specific model goals and constraints. However, the following section provides a general preprocessing pipeline that you can adapt as needed. Later in the chapter, you’ll learn about the specific challenges of preprocessing instructional datasets.

# A General Data-Preprocessing Pipeline for LLMs

The pipeline presented here has 10 basic steps. Before you begin, however, there is a “step 0”: defining how you’ll measure success. Once you do all these steps, how will you know whether the process worked and so the new version improves on earlier ones? These techniques are discussed in detail in [Chapter 7](https://learning.oreilly.com/library/view/llmops/9781098154196/ch07.html#ch07_evaluation_for_llms_1748896751667823), but here’s a general approach to basic measurement.

First, establish a small set of *core metrics* that you can compute after every pipeline run. A quick way to do this is to have a set of prompts for which you know the correct answer and that you can quickly evaluate, ranging from simple questions such as “What’s 2 + 2?” and “What’s the capital of France?” to more complex questions such as “Answer with either yes or no: Is this a picture of a bird?” or “Answer either yes or no: Is Tom Cruise the son of Mary Lee Pfeiffer?” These fast-to-compute answers act as smoke alarms:, so if a change to data collection, deduplication, or weighting derails the model, the problem shows up immediately.

In addition, run periodic LLM evaluations using traditional benchmarks such as Massive Multitask Language Understanding (MMLU; see [Chapter 7](https://learning.oreilly.com/library/view/llmops/9781098154196/ch07.html#ch07_evaluation_for_llms_1748896751667823)) and your safety and bias check prompts (see [Chapter 8](https://learning.oreilly.com/library/view/llmops/9781098154196/ch08.html#ch08_governance_monitoring_privacy_and_security_1748896766177413)). Minor variations up and down are expected, but as you train, you want to make sure that things are moving up in aggregate rather than getting stuck at a low point or sharply dropping once you make a change to one of the steps of data preprocessing.

With that introduction to measurement out of the way, let’s go through the 10 steps of data preprocessing.

## Step 1: Catalog Your Data

Before anything else, you need to get clear on what kind of data you actually need. What’s the end goal? How will the model be applied? Those answers should guide how you select your pretraining data. Defining your data types, language, domain, and quality standards early on means setting yourself up with a clear target so you’re not just collecting data for the sake of it. Organize your sources into a database so that you can tag the data you collect later.

## Step 2: Check Privacy and Legal Compliance

Next, ensure that you’ll stay within the bounds of data privacy laws and in compliance with legal regulations. This step isn’t just about protecting yourself; it’s about respecting the data and the people it may represent. Make sure you have the appropriate licenses for the data that you want in your data catalog. Make a note of the license in a database so that you use it to tag the data you collect later.

## Step 3: Filter the Data

Not all data is created equal, and the quality of your sources matters. Look to a variety of sources—websites, books, academic papers—but make sure they match your predefined criteria. Reliable, accurate data is crucial. For instance, in a great example of mitigating risks early, the [CulturaX corpus](https://oreil.ly/ZJqyL) filters out harmful content through a blacklist. Specialized filters, or even cloud-based solutions, can help you avoid low-quality sources before you begin. Here you have the option to discard the data you don’t use or to simply mark in a database that you filtered it out. The latter strategy consumes more storage but makes it easier to add and remove filters later.

# Cleaning Data: A Few Core Rules

When you’re cleaning up data, following these guidelines will help you stay on track and keep the quality high:

-

Assess the completeness of sentences. If a sentence is incomplete—whether it’s missing punctuation or just doesn’t make sense semantically—it needs to be filtered out. Incomplete thoughts aren’t useful.

-

Remove private personal identifying information (PII). Either strip it out completely or replace it with placeholder text. Privacy is paramount.

-

Delete harmful content, such as anything violent, pornographic, or otherwise harmful. It’s not just about filtering content; it’s about being responsible.

-

Get rid of abnormal symbols. Anything that doesn’t belong or seems out of place is just noise in your data.

-

Remove technical clutter. Things like HTML, CSS, and JavaScript identifiers serve no purpose in the dataset and distract from the actual content.

-

Delete sentences with curly braces—they’re often placeholders or junk data.

-

Cut out overly short sentences. Brevity can be useful, but too-short sentences might lack context or meaning. If they don’t add value, they shouldn’t be there.

-

Remove redundant content like navigation bars or “like” buttons. This irrelevant text clutters the data.

-

Get rid of text with specific unwanted words. There are always certain words or phrases that just don’t belong. Identify those and remove them wherever they pop up.

## Step 4: Perform Data Deduplication

The success of your data collection depends on having a strategy. What’s your time frame? How large is your data scope? How often will you be collecting data? Answering these questions up front means you’ll be able to gather a diverse set of data while keeping up with the real-time nature of most applications. This is where cloud-based platforms, which provide scalable data management, become especially useful. Again, you can discard or tag the data as duplicate.

# Methods for Deduplication

When it comes to deduplication—removing repeated or redundant data—a few key methods stand out:

Term frequency–inverse document frequency (TF-IDF) soft dedupingThis approach compares the frequency of words in a text with their frequency in the entire dataset. If two texts share high similarity based on their TF-IDF scores, you remove one of them. Words that appear a lot in one text but not much in the whole corpus get a higher weight, signaling that they’re crucial to that specific document.

MinHashThis algorithm estimates how similar two sets of text are. It uses random hashing to generate a set of minimum hash values, then compares those to estimate similarity. It’s efficient both in terms of computation and storage, making it ideal when you’re dealing with large-scale datasets.

SimHashThis algorithm turns text feature vectors into fixed-length hash codes, then measures similarity by comparing how far apart these hash codes are. The closer the codes, the more similar the texts. It’s a reliable way to calculate text similarity while keeping the process lightweight.

There are plenty of other ways to handle duplicates. One simple but effective method is to delete duplicate sentences that appear consecutively, keeping only the first instance. You can also remove documents that share the same URL in the dataset. Another popular approach is to use MinHashLSH with *n*-grams, which flags content as duplicate if the similarity exceeds a certain threshold, typically around 0.8.

Each of these methods has its own strengths, but the goal remains the same: to strip out the unnecessary, the redundant, and the irrelevant so your data stays lean and focused. The cleaner the data, the better your model performs.

## Step 5: Collect Data

This is where the real work begins. Use web crawlers, APIs, and other tools to collect data from the sources you’ve identified (be sure to check the terms of service and avoid any copyright violations). Whether you’re using HTML parsing or PDF text extraction, make sure the data is clean and structured. One popular way is to use curated datasets like [Falcon](https://oreil.ly/-5wkX) or [CommonCrawl](https://oreil.ly/TaXZi). CommonCrawl offers data in the [WARC (Web ARChive) format](https://oreil.ly/-kH_a), containing all the raw data for the page, and in the WET (WARC encapsulated text) format, the subset of WARC that contains only the plain text of the body. Even when you’re building your own dataset, adhering to these formats is helpful as you can use one of the many tools available in GitHub to process files in the given format.

As you collect the data, add the metadata from the previous steps.

## Step 6: Detect Encoding

Ensuring proper encoding is nonnegotiable. Incorrect text encoding can ruin your data, as encoding errors can look normal at a glance and thus be hard to detect. They can also generate gibberish—in some cases just for a few characters of your text. You can make use of encoding detection tools, such as the open source [Chardet](https://oreil.ly/V7Ub0), to make sure you’re processing the text files using the correct encoding. In this way, you’ll be able to detect errors before you see the model’s output. Add the encoding to the metadata of the data you collected in step 5.

## Step 7: Detect Languages

Next up, identify the languages within your data using language detection tools such as [lingua-py](https://oreil.ly/0jVgJ). Then separate the data into subsets by language. Knowing the language of the training data is often useful, and you can also check that you have enough language representation in your LLM for your use case. For example, if you’re generating an LLM that is supposed to speak Portuguese, you want to have a fair amount of Portuguese data for training. Add the language to the metadata.

## Step 8: Chunking

Once you’ve gathered your raw data and ensured you can read it in the proper encoding and language, it’s time to break it down into usable parts. Extract the textual elements and parse them into manageable chunks. Most models have a maximum text size that they can use. In this step, break your input text into chunks that are less than that size.

There are multiple ways to do chunking:

-

Fixed-size chunks are easy to code but can break ideas into separate chunks.

-

Sentence-based chunks are great for documents with clear, distinct ideas.

-

Paragraph-based chunks keep the broader context intact, but they are larger than sentence-based chunks.

There are more advanced text-chunking techniques. For example, you can add additional metadata for each chunk by using an existing LLM to evaluate each chunk for sentiment and determine the chunk’s topic, or even submit entire documents to an existing LLM and ask it to return the chunks. An [even more sophisticated approach](https://oreil.ly/ZETMR), called agentic chunking, involves uploading each document to an existing LLM, creating an agent that simulates an analyst asking questions about the document, and recording the most frequently used chunks.

Note that using LLMs for chunking can become very expensive in terms of compute resources. Regardless of the method used, chunks should contain all the metadata from the previous steps such as data source, license, encoding, and language.

## Step 9: Back Up Your Data

It may sound simple, but regular backups are a crucial safety net. Data loss can be devastating, and routine backups ensure you always have something to fall back on.

## Step 10: Perform Maintenance and Updates

Finally, this isn’t a one-and-done process. Your data collection system needs maintenance. Regular updates and refinements, by updating sources or improving strategies, ensure that your data stays fresh and relevant. Continuous improvement is key.

These steps can be used to generate raw preprocessed chunks for both the pretraining and fine-tuning steps. [Chapter 5](https://learning.oreilly.com/library/view/llmops/9781098154196/ch05.html#ch05_model_domain_adaptation_for_llm_based_applications_1748896666813361) talks about LLM training in detail. In order to understand a quick way of generating the data for the fine-tuning step, it’s helpful to understand vectorization, discussed next.

# Vectorization

*Vectorization* is the process of converting text data into a high-dimensional numerical representation, or *vector*, that captures its essential characteristics. The verb *embedding* is often used interchangeably with *vectorizing*. *Embedding* (as a noun) can also refer to the resulting vector itself.

Once vectors are generated, they can be stored in vector databases. Vectorization was popular many years before LLMs. For example, the ElasticSearch database system made vectors available in 2019 to allow users to query for text that was similar to text they provided. Today’s vector databases extend the capabilities of vector storage and search to massive datasets.

The most desired characteristic of an embedding process (also called an *embedding model*) is that it generates embeddings that are good at capturing differences in meaning. A good embedding model will generate embeddings that are close to each other when the meanings of words or phrases are close, and distant when the meanings of words and phrases are different.

If you generated your dataset using the 10 steps described in the previous section, you have a dataset of several chunks of text that you generated in step 8 of that process. You can enrich that data with embeddings by using a model to add an embedding field to each chunk.

There are many models for generating embeddings. One way is simply to upload the data to a vector database (discussed in more detail in the next section). Another is to generate custom embeddings yourself by using models like OpenAI’s `text-embedding-3-large` or BERT and storing the results in the vector database. The best approach depends on your specific needs.

For example, OpenAI’s algorithm `text-embedding-3-small` accepts an [input of up to 8,191 tokens and outputs a vector of 1,536 real numbers, regardless of the size of the input](https://oreil.ly/2rapG). If you try to embed one token with two characters, like “no,” the output embedding will have a size of 1,536 real numbers. If you try to embed a paragraph containing 8,000 characters, the embedding will also have a size of 1,536 real numbers. Therefore, this model is a good choice if the chunks you generated in step 8 have up to 8,000 characters (with one token equivalent to about 4 characters on average), but it’s potentially wasteful if the chunks you generated are very small, like 100 characters. In that case, it’s possible that a smaller embedding model (like BERT) would offer the same performance at a lower price.

Vectorization is used for an important use case for LLMs: retrieval-augmented generation. RAG uses an LLM to generate answers by first searching a dataset for chunks that are similar to a query and then using the LLM to “glue” the retrieved chunks together to make the answer look natural. Vector databases can speed up the retrieval step substantially. We talk more about RAG applications in [Chapter 6](https://learning.oreilly.com/library/view/llmops/9781098154196/ch06.html#ch06_api_first_llm_deployment_1748919660052702), but let’s first discuss vector databases.

## Vector Databases

In many applications, you need to find text that is similar to some other text. For example, when looking for a product at Amazon, you might want to find similar products. *Vector databases* make this easy by finding text with similar meaning. A vector database can connect an Amazon search of “laptop backpack with USB charger” to items tagged “tech-friendly daypack, 17-inch, built-in power bank,” even when none of the keywords line up perfectly.

For many search applications, you don’t need a vector database. Unless your dataset is very big (and when training LLMs or running a global ecommerce site, it will be), remember the [advice](https://oreil.ly/ez8fn) of Andrej Karpathy, former director of AI at Tesla and part of the founding team at OpenAI: when starting a project, all you might need is the free NumPy Python library.

Vector databases are designed to store embeddings and quickly perform searches for embeddings that are close to a given embedding. Imagine you have a bunch of data—maybe text, images, or a mix of both. The first step is to vectorize it. Once that’s done, the database can store these vectors in a way that makes it easy to find similar data points. This process is called *indexing*. When a text query is submitted, the query is also vectorized, and then the database calculates the distance of the submitted query to distances of the stored records by performing a [nearest neighbor search](https://oreil.ly/oq2Du). This means that you can find the most similar items to a given query in a vector space.

Vector databases allow you to store metadata along with your data and its embedding vector. You can use this to narrow down your search space before performing a vector similarity search. This can significantly improve query efficiency, especially for large datasets. For example, if you already know the language of your query and you have a language field in your metadata, you can use it to improve performance.

When choosing a vector database, a few considerations are scalability, fault tolerance, and availability of indexing techniques, in addition to cost. These characteristics are ​detailed ​in [Table 4-1](https://learning.oreilly.com/library/view/llmops/9781098154196/ch04.html#ch04_table_1_1748895507351911).

| Feature | Description | Common metrics | Indexing techniques (impact) |
| --- | --- | --- | --- |
| Scalability | <br>			Ability to handle increasing data volume and query load<br> | <br>			Throughput (queries per second)<br><br>			Latency (query execution time)<br><br>			Storage capacity<br> | <br>			Horizontal scaling capability (affects throughput)<br><br>			Sharding strategy (impacts query efficiency)<br> |
| Fault tolerance | <br>			Ability to maintain availability during failures<br> | <br>			Uptime percentage<br><br>			Time to recovery (MTTR)<br> | <br>			Data replication (ensures data availability)<br><br>			High availability (HA) features (minimize downtime)<br> |
| Indexing techniques | <br>			Methods for efficient search in high-dimensional vector spaces<br> | <br>			Search accuracy (retrieval of relevant vectors)<br><br>			Search speed<br> | <br>			Metric trees (HNSW, VP-Tree): Efficient for moderate data and dimensionality<br><br>			Hashing (LSH): Faster for approximate nearest neighbors (trade-off with accuracy)<br><br>			Inverted file (IVF): Improves speed if you can use several metadata filters<br> |

## Maintaining Fresh Data

Step 10 of developing the preprocessing pipeline is about keeping the data up-to-date. Keeping the index synchronized with real-time changes in your underlying data can be challenging, with methods on a continuum from “Tell me if there have been any changes when I ask” to “Tell me instantly about changes whenever they happen.” *Polling* is the simplest approach: you periodically query the source data and compare the latest snapshot with what is already in the database. It is easy to understand and works when your data volume or freshness requirements are modest, but it wastes resources by repeatedly asking even when nothing has changed. It also introduces latency equal to the frequency with which you perform queries. If you refresh your data every year, it will take at least a year to detect a change.

A more precise alternative is *change data capture* (CDC), which taps directly into the source’s transaction or commit log or some metadata about freshness (like the document’s last modified date). Instead of hunting for differences in the whole set of documents, you can read a list of documents that have changed and update only them. CDC still involves pulling data, but it eliminates guesswork and minimizes the bandwidth spent on checks that would result in meaningless updates.

When the producer of the data can actively push information, you move into event-driven and streaming territory. In an *event-driven* update model, the owner of the data sends messages such as “product description changed” or “article updated.” Each event is self-contained and can trigger updates in the database immediately.

# LlamaIndex

[LlamaIndex](https://oreil.ly/owRAr) ​(originally released as GPT Index in late 2022) is an open source data framework that lets you connect data to any LLM workflow. It handles the unglamorous plumbing: loading data from hundreds of formats, chunking, embedding, indexing, and retrieving vector embeddings.

You could preprocess your data and generate vector representations using LlamaIndex. Implement a separate pipeline using CDC or event-driven updates to capture real-time data changes. This pipeline could trigger vector regeneration for the changed data and update the vector database through its API (if supported).

## Generating the Fine-Tuning Dataset

If you just do the 10 steps described in the preprocessing data section, you’ll have enough data to perform the pretraining step of your LLM. However, for almost all practical applications, you need your LLM to do something in addition to guessing obscured words. The most common task for an LLM is answering questions, and for that, you’ll need to provide it with a list of questions and expected answers. This is called an *instruction dataset* or a *fine-tuning training dataset*.

There are four primary approaches to creating fine-tuning training datasets:

Curate it manuallyThis is the most hands-on approach. You and your team curate and design the dataset yourself, carefully selecting and crafting each instruction to fit your needs. It’s slow and labor intensive, but it gives you control, which pays off when you need a dataset that’s highly specific or tailored to a particular task.

Collect and improve existing open source datasetsWhy reinvent the wheel when there’s already valuable data out there? You can pull from open source datasets, refining and improving them to better suit your needs. This is a shortcut that doesn’t sacrifice quality, especially when paired with some strategic enhancements. By fine-tuning what already exists, you’re leveraging the collective work of the community to accelerate your own progress.

Generate it with an LLMYou can use an LLM to generate an instruction-tuning dataset. For this, you need to have your chunks in a vector database. This process is described in detail in the next section.

Hybrid methodFinally, don’t forget that there’s strength in combining these approaches. You can blend manual creation, open source dataset curation, and model generation to cover all your bases. A simple way to combine these methods is to simply use them all, appending each dataset to the other. This hybrid method gives you flexibility—letting you tap into the best of each approach based on the task at hand.

There are two general categories of fine-tuning datasets. *General instruction fine-tuning datasets* are broad and cover a wide range of tasks across many domains. They’re intended to improve the model’s ability to follow general instructions, making it more versatile. The broader the dataset, the better your model becomes at understanding and executing varied instructions. *Domain-specific instruction fine-tuning datasets*, on the other hand, are narrow in focus and built for specialized fields. For example, a medical instruction dataset will train the model to handle tasks like diagnostics or healthcare assistance. By focusing on a specific domain, you’re sharpening the model’s expertise in that particular area.

## Automatically Generating an Instruction Fine-Tuning Dataset

Step 1: Preprocessing and vectorizationWe recommend using [LlamaIndex](https://oreil.ly/1uMXc) to process your large corpus of text data. LlamaIndex can perform many of the preprocessing steps in the general pipeline outlined previously, like tokenization and cleaning. It can also generate high-quality vector representations for each chunk in your corpus. You can store these document vectors in many different databases.

Step 2: Building a retrieval mechanismCreate a simple program that, given a question, retrieves the closest associated chunks from the vector database you created in step 1. You can use LlamaIndex’s out-of-the-box `VectorIndexRetriever` functionality for this.

Step 3: Generating questionsSubmit documents (not chunks) to an existing LLM and ask it to generate sets of questions that can be answered by the document. You may need to break up the document into multiple parts, but they can be much larger than the chunks in your database. For example, a chunk usually will have 8,000 characters (so that you can generate an embedding for it), while GPT-4o can generate a list of questions for a document containing approximately 400,000 characters.

Step 4: Asking an existing LLM to decide the best answerSubmit each question you generated in step 3 to the program you wrote in step 2. The result will be a list of chunks that are closely related to the question. Send both the question and the list of answers to an existing LLM and ask it to select the chunk that contains the best answer and use that chunk to generate an intelligible, complete answer. You can ask the LLM to generate the output as a JSON-formatted record of the form `{"instruction": <question>, "input": "", "output": <answer>}`. Repeat the cycle until you have the desired number of examples.

After generating questions and answers, run basic hygiene checks: deduplicate almost-identical question–answer pairs by computing text-level cosine similarity, filter out answers that introduce information not present in the retrieved passages, and then spot-check a small random sample by hand to be sure the automatic filters are calibrated correctly. If you want to make the dataset richer, you can prompt the LLM to ask follow-up questions that go deeper on the same passage, or to return answers in constrained formats such as valid JSON—both strategies teach the fine-tuned model to handle more complex instructions.

The entire pipeline can be pared down when resources are scarce. For a small corpus, you might precompute embeddings with a lightweight library like BERT, skip the retrieval step, and have the LLM generate both the question and its answer from a single passage, verifying with cosine similarity that the answer remains close to the source text.

# What If Your Data Isn’t Static?

While there is never a one-size-fits-all approach, I have a few recommendations for working with dynamic data:

-

Integrate with real-time data feeds. Utilize low-latency messaging protocols like Kafka or Apache Pulsar for efficient data delivery.

-

Segment data into time windows (context windows) compatible with your data update frequency and add timestamps as metadata to tell the LLM how old the data is. For example, you may have a dataset that contains data that is a week old, a dataset that contains data that is a few months old, and a dataset that contains historical data. They can be all in the same database with different metadata tags.

Maintain a separate pipeline for training on data with the different timestamps This can save money on retraining. For example, you may retrain your LLM on the week-old dataset every day but on the month-old data only weekly.

Implement data versioning to track different LLM data iterations and easily roll back to previous versions if needed.

# Conclusion

This chapter discussed the end-to-end data engineering pipeline for LLMs. While data engineering for LLMs is still a nascent field, the tips and guidelines provided in this chapter should give you a good foundation for every step of the process so you can optimize your pipelines for your specific use case.

# References

Chang, Ernie, et al. [“Scaling Parameter-Constrained Language Models with Quality Data”](https://oreil.ly/4v-i1), arXiv, October 2024.

Chardet. n.d. [“Chardet: The Universal Character Encoding Detector”](https://oreil.ly/NU-hl), accessed May 21, 2025.

Codd, E. F. [“A Relational Model of Data for Large Shared Data Banks”](https://oreil.ly/14TGS), *Communications of the ACM*13 (6): 377–87 (1970).

Common Crawl. n.d. [Common Crawl](https://oreil.ly/TaXZi), accessed May 21, 2025.

Dodge, Jesse, et al. [“Documenting Large Webtext Corpora: A Case Study on the Colossal Clean Crawled Corpus”](https://oreil.ly/g1Gek) arXiv, September 2021.

Gao, Yunfan, et al. [“Retrieval-Augmented Generation for Large Language Models: A Survey”](https://oreil.ly/9D0yi), arXiv, March 27, 2024.

Hoffmann, Jordan, et al. [“Training Compute-Optimal Large Language Models”](https://oreil.ly/F2I7y), arXiv, March 2022.

Kaplan, Jared, et al. [“Scaling Laws for Neural Language Models”](https://oreil.ly/IwsIC), arXiv, January 2020.

Lee, Cinoo, et al. [“People Who Share Encounters with Racism Are Silenced Online by Humans and Machines, but a Guideline-Reframing Intervention Holds Promise”](https://oreil.ly/e7va9), *Proceedings of the National Academy of Sciences* 121 (38): e2322764121 (2024).

LlamaIndex. n.d. [“Vector Stores”](https://oreil.ly/05_gK), accessed May 21, 2025.

Ma, Yingwei, et al. [“At Which Training Stage Does Code Data Help LLMs Reasoning?”](https://oreil.ly/ZVMyR), arXiv, September 2023.

Nguyen, Thuat, et al., [“CulturaX: A Cleaned, Enormous, and Multilingual Dataset for Large Language Models in 167 Languages”](https://oreil.ly/Hfb9j), arXiv, September 2023.

OpenAi Platform. n.d. [“Vector Embeddings”](https://oreil.ly/zj-2l), accessed May 21, 2025.

Pemistahl. n.d. [lingua-py](https://oreil.ly/VIIBH), accessed May 21, 2025.

Penedo, Guilherme, et al. [“The RefinedWeb Dataset for Falcon LLM: Outperforming Curated Corpora with Web Data, and Web Data Only”](https://oreil.ly/ZBNxW), arXiv, June 2023.

Reis, Joe and Matt Housley. [Fundamentals of Data Engineering](https://learning.oreilly.com/library/view/fundamentals-of-data/9781098108298/), O’Reilly, 2022.

Salley, C., et al. [“Providing OLAP to User-Analysts: An IT Mandate”](https://oreil.ly/u549E) (1998).

Wang, Zige, et al. [“Data Management for Large Language Models: A Survey”](https://oreil.ly/JWI_9), arXiv, August 2024.

WARC Specifications. n.d. [“The WARC Format 1.0”](https://oreil.ly/QnaDE), accessed May 21, 2025.

Xu, Yipei, et al. [“Source Prompt: Coordinated Pre-Training of Language Models on Diverse Corpora from Multiple Sources”](https://oreil.ly/8-tjT), arXiv, November 2023.

Xue, Fuzhao, et al. [“To Repeat or Not to Repeat: Insights from Scaling LLM Under Token-Crisis”](https://oreil.ly/5AAg5), arXiv, October 2023.

Yang, Rui, et al. [“RAGVA: Engineering Retrieval Augmented Generation-Based Virtual Assistants in Practice”](https://oreil.ly/Zv3UP), arXiv, February 2025.

# Further Reading

Gao, Leo, et al. [“The Pile: An 800GB Dataset of Diverse Text for Language Modeling”](https://oreil.ly/H9Ycv), arXiv, December 2020.
