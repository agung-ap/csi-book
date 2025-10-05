# Chapter 2. Introduction to LLMOps

The size and complexity of LLMs’ architecture can make productionizing these models incredibly hard. *Productionizing* means not just deploying a model but also monitoring it, evaluating it, and optimizing its performance.

There are constantly new challenges. Depending on your application, these may include how to process data, how to store and dynamically adapt prompts, how to monitor user interaction, and—most pressing—how to prevent the model from spreading misinformation or memorizing training data (which can lead it to release personal information). That’s why operationalizing LLMs, which means managing them day-to-day in production, requires a new framework.

*LLMOps*, as it’s called, is an operational framework for putting LLM applications in production. Although its name and principles are inspired by its older siblings, MLOps and DevOps, LLMOps is significantly more nuanced. The LLMOps framework can help companies reduce technical debt, maintain compliance, deal with LLMs’ dynamic and experimental nature, and minimize operational and reputational risk by avoiding common pitfalls.

This chapter starts by discussing what LLMOps is and how and where it departs from MLOps. We’ll then introduce you to the LLMOps engineer role and where it fits into existing ML teams. From there, we’ll look at how to measure LLMOps readiness within teams, assess your organization’s LLMOps maturity, and identify crucial KPIs for measuring success. Toward the end of this chapter, we will outline some challenges that are specific to productionizing LLM applications.

# What Are Operational Frameworks?

*Operational frameworks* provide a structured approach to managing complex workflows and pipelines within an organization. These frameworks integrate tools and practices to automate and streamline organizational processes and ensure consistency and quality across the project lifecycle.

Some of the earliest operational frameworks can be traced back to military strategy and the Industrial Revolution. Two of the most popular ones, both introduced in 1986, are [Toyota’s Lean Production System](https://oreil.ly/oNheh), which put Toyota ahead of most of its contemporaries, and [Six Sigma](https://oreil.ly/GHXWt), Motorola’s data-driven approach to improving processes and reducing defects.

In 2008, the tech industry began to adopt what is now one of the most popular operational frameworks in software: DevOps. (The term combines *software development *and *operations*.) In 2018, MLOps, an operational framework for non-generative machine learning (ML) models, became the talk of the town; since then we’ve seen SecOps (Security Operations), DataSecOps, and many more.

With the massive adoption of LLMs in 2023, a new operational framework started floating around within companies that were building LLM applications: LLMOps. LLMOps is still in its infancy, but as generative models become integral to software products, its popularity is likely to boom.

[Figure 2-1](https://learning.oreilly.com/library/view/llmops/9781098154196/ch02.html#ch02_figure_1_1748895480187715) shows the slow rise of Ops frameworks over the years. Use of LLMOps started to pick up with the mass adoption of LLMs in early 2023. As of this writing, more and more enterprises are realizing that they can add value and profit with LLM-based offerings, leading to an upward trend for LLMOps. In fact, 2025 may be the best year yet for LLMOps frameworks.

Deploying LLMs can be as simple as integrating a chatbot into your website via an API or as complicated as building your own LLM and frontend from scratch. But maintaining them to be performant (productionizing them)—that is, keeping them reliable, scalable, secure, and robust—is a massive challenge. This book, like LLMOps, is focused on exactly this question: what happens *after* you deploy your LLM in production?

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098154196/files/assets/llmo_0201.png)

###### Figure 2-1. Google Ngram showing the rise in popularity of the term LLMOps from 2019 to 2024

## From MLOps to LLMOps: Why Do We Need a New Framework?

There is some overlap between MLOps and LLMOps; both deal with the operational lifecycles of ML models, after all. They also share common principles in terms of managing ML workflows. However, the two frameworks diverge in their primary focuses and objectives. While MLOps handles non-generative models (both language and computer vision), LLMOps deals with generative language models—and thus with mammoth levels of complexity. The complexity of these models owes not only to their scale and architecture but also to the unique processes involved in data engineering, domain adaptation, evaluation, and monitoring for them. The key distinctions are apparent in LLMs’ prediction transparency, latency, and memory and computational requirements.

Perhaps the biggest difference is the shift in how end users consume these models. Non-generative ML models are predictive tools used for passive consumption, such as in dashboarding, recommendations, and analytics. By contrast, LLM applications are deployed as [Software 3.0](https://oreil.ly/g9dn6) in consumer-facing applications for active user interaction. This brings several challenges from Software 1.0 (DevOps) back to the surface. In fact, it wouldn’t be wrong to say that LLMOps shares more similarities with DevOps than with MLOps.

Building your own generative AI application requires tools, frameworks, and expectations to match the scale and complexity of these models, and this is far beyond the scope of the existing MLOps solutions. To help you understand the differences between the various kinds of Ops frameworks, let’s do a thought experiment.

Imagine MLOps as being something like building a small home from the ground up. In comparison, DevOps, which deals with the entire product lifecycle, would be like developing a large shopping complex. And LLMOps? It’s more like building the Burj Khalifa. For all three frameworks, you are working with the same construction materials: wood, steel, concrete, bricks, hammers, and so on. Much of the basic process is the same, too: you lay down the foundation, lay down the plumbing, and finally build the walls. But you wouldn’t contract your local construction workers to engineer the Burj Khalifa, would you?

Most of MLOps for natural language modeling is based on building smaller, discriminative models for tasks like sentiment analysis, topic modeling, and summarization. For these tasks, you first hypothesize ideal features, model your data as a function of those features, and then optimize the model for that specific task.

LLMs, by contrast, are generative, domain agnostic, and task agnostic. That fundamental difference means you can use the same model for summarizing or for answering questions, without having to fine-tune it.

The best use cases for LLMs are when you don’t know what features to optimize for (or, even better, if the features are too abstract) and when you need to model multimodal data within a single pipeline. Unlike smaller discriminative models, LLMs don’t rely on predefined features or task-specific architectures. Instead, as you learned in [Chapter 1](https://learning.oreilly.com/library/view/llmops/9781098154196/ch01.html#ch01_introduction_to_large_language_models_1748895465615150), they are trained on vast amounts of text data to learn the patterns and structures in language itself. For LLMs, the training process involves a *loss function*, which measures how well the model’s generated outputs match the expected outputs across various tasks. For example, during training, the model might generate a sequence of text; the loss function calculates the difference between this generated sequence and the target sequence.

Additionally, for a standard comparison, the hyperparameter space for a 175-billion parameter GPT-4 ​model would likely be approximately 1,500 times larger than that for a standard discriminative BERT model (which has 110 million parameters). This makes it incredibly costly to fine-tune and do the kind of iterative training that is typical in MLOps. [Table 2-1](https://learning.oreilly.com/library/view/llmops/9781098154196/ch02.html#ch02_table_1_1748895480195288) outlines some of the key differences between the MLOps and LLMOps model lifecycles.

| Lifecycle step | Context | MLOps | LLMOps |
| --- | --- | --- | --- |
| Data collection | <br>			Ease<br> | <br>			Always and straightforward.<br> | <br>			Sometimes—data composition is a very hard problem.<br> |
| Data  <br><br>			preprocessing | <br>			Ease<br> | <br>			Fix missing data and outliers—very easy!<br> | <br>			Hard. Requires:<br><br>			<br>				<br>				Deduplication<br>				<br>				<br>				Toxicity filtering<br>				<br>				<br>				Diversity management<br>				<br>				<br>				Quantity control<br>				<br>			<br> |
| Model learning | <br>			Model size<br> | <br>			ML models, such as classifiers or regressors, typically have at max around 200 million parameters and are generally less computationally intensive for experimentation than are LLMs.<br> | <br>			LLMs typically have 100 billion or even trillions of parameters, making them significantly larger and more complex than many non-generative models. Their massive scale impacts resource requirements, storage, and computational efficiency.<br> |
| Hyperparameters | <br>			Accuracy<br> | <br>			Limited hyperparameter space makes search easy, making them ideal for predictive problems.<br> | <br>			Massive hyperparameter space leads to real-time search latency. This makes them ideal for generative and evolutionary tasks that require creativity. Accuracy can be a computational bottleneck.<br> |
| Model training duration | <br>			Training scale and duration<br> | <br>			Less resource intensive and generally faster. Can be easily deployed as notebooks on the cloud or as containerized solutions across a single node.<br> | <br>			Involves processing massive datasets with distributed training across large clusters of GPUs or TPUs and optimizing for parallel processing. Can take days or weeks. Operationalizing may require dynamic resource scaling and involves designing scalable infrastructure and orchestration systems to handle varying workloads efficiently.<br> |
| Domain  <br><br>			adaptation | <br>			Cost<br> | <br>			Full fine-tuning is essential and affordable.<br> | <br>			Full fine-tuning is too expensive and pretty rare. Instead, popular techniques are:<br><br>			<br>				Prompt engineering<br>				RAGs<br>				Knowledge graphs<br>				Parameter-efficient fine-tuning<br>			<br> |
| Evaluation | <br>			Ease<br> | <br>			<br>				Easy<br>				Discriminative<br>				Well-defined probability space<br>			<br> | <br>			<br>				Extremely hard problem<br>				Generative and thus hard to detect<br>				Unbounded probability space<br>			<br> |
| Robustness | <br>			Static versus dynamic<br> | <br>			Model behavior stays the same in production.<br> | <br>			Model behavior changes in production based on interactions and requires constant monitoring for alignment.<br> |
| Security | <br>			Secure<br> | <br>			Highly secure.<br> | <br>			<br>				Highly vulnerable<br>				Needs a DataSecOps framework<br>			<br> |

## Four Goals for LLMOps

LLMOps operates on an LLM-specific set of design pattern principles to ensure that your LLM applications achieve four key goals: security, scalability, robustness, and reliability. Let’s take a closer look at these goals:

SecurityMinimizing the regulatory, reputational, and operational risks associated with deploying LLM applications in production

ScalabilityBuilding, storing, and maintaining LLM applications that can generalize across data and scale efficiently on demand while optimizing latency, throughput, and costs

RobustnessMaintaining high performance of LLM applications over time in the face of data drift, model drift, third-party updates, and other challenges

ReliabilityImplementing rigorous inference monitoring, error handling, and redundancy mechanisms to prevent downtime and failures

LLMOps teams automate repetitive processes to more quickly optimize these applications at scale and avoid those “LLM-oops!” moments. Another key aspect of the LLMOps framework is fostering consistency, transparency, and collaboration between diverse interdisciplinary teams. These teams often include data engineers, data scientists, research scientists, software engineers, and business operations teams.

LLMOps is an entirely new field, so, as of this writing in 2025, there are very few mature tools and resources available. The LLMOps teams at various organizations are thus developing their tools and processes internally, based on prototypical open source libraries and toolkits.

# LLMOps Teams and Roles

Today, there are two kinds of companies out there building with LLMs: the newer startups, which focus primarily on LLM applications, and companies with existing ML models that are now building their own GenAI teams.

In the latter category, there are so few skilled Ops professionals that most companies recruit ML engineer candidates internally and then upskill them to LLMOps, instead of hiring externally. A major reason for this is a general lack of clarity around use cases as well as the expected job responsibilities. So the current norm is to hire 8 to 10 people internally from different departments, which could include product managers, full-stack engineers, system architects, data engineers, data scientists, ML engineers, platform engineers, cybersecurity professionals, and developer advocates. Many companies want someone who already understands the business inside and out to test the feasibility of several potential use cases and projects before committing to one.

Newer startups, however, have no choice but to build a team from the ground up. These teams can look very different, depending on whether they are working on LLMOps infrastructure (LLMOps SaaS companies) or LLM use cases such as copywriting, education, or process optimization. [Figure 2-2](https://learning.oreilly.com/library/view/llmops/9781098154196/ch02.html#ch02_figure_2_1748895480187751) provides a very basic model of an LLMOps team, but these teams come in all shapes and sizes, with different levels of business and technical maturity. (Later in the chapter, we’ll look at how to assess your company’s LLMOps maturity.)

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098154196/files/assets/llmo_0202.png)

###### Figure 2-2. Structure of an LLMOps team

Most companies cannot afford the cost of building and training an LLM for use in their application. Instead, most choose to use a foundational model. This is where AI engineers come in: to build a quick proof of concept using LLMOps tools. Most come from a software-engineering background; they may know how to build a full-stack application quickly, but don’t necessarily have a deep understanding of ML/LLM models’ inner workings or how to optimize them.

Once the proof of concept is completed, building, deploying, and optimizing ML models for the business falls to LLM engineers, ​ML scientists (interchangeable titles, depending on the organization), and LLMOps ​engineers tasked as reliability engineers.

If a team chooses to deploy an LLM application using API integration, the initial deployment will be pretty straightforward. The LLMOps engineers work alongside AI engineers to scale the model and improve its performance. Ideally, each AI engineer is paired with an LLMOps engineer; the AI engineer can focus on adapting and fine-tuning the model to meet the business needs, while the LLMOps engineer manages deployment and optimization. For open source models, managing deployment automatically falls to the LLMOps engineer.

As the tech industry moves from non-generative models to generative models, it is shifting away from feature engineering, or creating features to model the data and experimenting with different hyperparameters to optimize performance. Generative models, and specifically LLMs, do not require feature engineering. Today, the core requirements are usually prompt engineering or building a RAG pipeline—skills that lie within the domain of AI engineers.

Another big shift is that the data engineering pipeline and the monitoring and evaluation pipeline have become far more complex. Evaluating LLMs is much more than straightforward quantitative scoring. Some industry benchmarks exist—like [BLEU](https://oreil.ly/OxqU2), a benchmark used to evaluate machine translation, and [ROUGE](https://oreil.ly/1y3e4), a benchmark used to evaluate summarization, but these are only loosely correlated with application performance. Moving to a model that has a better score is no guarantee of better user satisfaction. Standardized scores may be good for comparing LLMs in general, but ultimately users care about whether the LLM application is solving their problem.

In addition, since LLMs are deployed in consumer-facing applications, metrics like perceived latency and throughput become make-or-break factors in market competition. The model is not the only deciding factor: the deployment, evaluation, and monitoring pipelines are also at the front and center of performance assessment.

Let’s look at some of the roles involved in these pipelines:

Data engineerData engineers are professionals responsible for designing, building, and maintaining systems and pipelines that enable the efficient collection, storage, and transformation of data as well as access to it. Their work ensures that data is available, reliable, and organized in a way that allows data scientists and other engineers to create and evaluate models and data-driven applications. Data retrieval and movement are the most fundamental skills for data engineers, but as they progress in their career, developing data architectures becomes more important.

Data engineering for LLMs requires specialized understanding: how to chunk the data, what tokenization model to use, and so on. Thus, it’s best to pair each data engineer with an ML scientist (with an LLM engineering background) along with the LLMOps engineer for automating and streamlining LLM systems at scale.

AI engineerThe core skill set of an AI engineer is full-stack engineering and development (React, Node.js, Django) plus familiarity with the common LLMOps tools and frameworks for deploying applications, like LangChain and Llama Index. They need a foundational understanding of end-to-end AI application development, including prompt engineering and RAG systems. Companies building their teams from scratch usually look to hire AI engineers who also know a lot about using cloud services to deploy and manage AI applications and have experience working with external APIs and vector databases.

ML scientistThe day-to-day work of an ML scientist, NLP scientist, or LLM engineer involves researching, designing, and optimizing LLMs using frameworks like PyTorch, TensorFlow, and JAX. This role requires a deep understanding of NLP algorithms and tasks, such as tokenization, named-entity recognition (NER), sentiment analysis, and machine translation. Candidates should know model architectures and training and fine-tuning processes.

LLMOps engineerThe goal  of an LLMOps engineer is to ensure that LLM applications remain reliable, robust, secure, and scalable. The day-to-day work involves building and maintaining operational LLM pipelines as a project owner.

Let’s now look at the LLMOps engineer role in more detail.

## The LLMOps Engineer Role

This role requires extensive expertise in deploying, monitoring, fine-tuning, training, scaling, and optimizing LLM models in production environments; infrastructure and platform engineering; data engineering; and system reliability.

Companies building LLM teams usually seek LLMOps engineers who understand the unique challenges associated with LLMs and are experienced in making build-versus-buy trade-off, including by weighing cost efficiency against system performance.

To stand out as a candidate for this role, you’ll need proficiency in a unique blend of specialized skills and a deep technical understanding of the entire LLM lifecycle, from data management to model deployment and monitoring. You’ll also need to be a problem solver, a strong team player, and an effective communicator as well as meticulously detail oriented.

To illustrate what this means in practice, let’s look at a typical day in the work life of a fictional LLMOps engineer.

## A Day in the Life

While the specific responsibilities for this role will vary across organizations, the core tasks typically encompass a blend of infrastructure management, collaboration, optimization, and compliance. To give you a quick taste of what this looks like in practice, here’s what a typical LLM engineer’s workday might look like:

7:30 AM–8:30 AM: Morning check-in-

Review monitoring dashboards for any overnight alerts or performance issues in deployed LLMs; address any urgent issues or escalate them to the appropriate teams.

-

Lead the team’s daily stand-up meeting to discuss ongoing projects, blockers, and priorities for the day.

8:30 AM–10:00 AM: Infrastructure management and optimization-

Modularize code for reusability​, creating separate modules for provisioning GPUs, managing storage, and networking.

-

Implement batching mechanisms to process multiple inference requests, reducing the per-request overhead.

-

Implement latency optimization techniques like kernel fusion, quantization, and dynamic batching to enhance model performance.

10:00 AM–11:30 AM: Collaboration and project planning meeting-

Meet with data scientists, ML engineers, and red teaming engineers to discuss usage requirements, timelines, monitoring errors, and scaling challenges.

11:30 AM–12:30 PM: API development and model deployment-

Design inference endpoints and cache for different models in production, ensuring compatibility with the rest of the application.

12:30 PM–1:30 PM: Lunch break1:30 PM–3:00 PM: Monitoring and troubleshooting-

Troubleshoot any issues that arise. For example, let’s say the users are experiencing long delays when making requests to the inference API. The engineer would identify the source of latency by examining hardware utilization and network latency and reviewing usage logs. They would then implement a solution; e.g., using a Pod Autoscaler or caching the frequent requests.

3:00 PM–4:30 PM: Research and continuous learning-

Experiment with new tools, libraries, or frameworks that could be integrated into the existing tech stack to improve efficiency and performance.

4:30 PM–5:30 PM: End-of-day wrap-up, review, and on-call prep-

Review the day’s tasks and update the tickets with completed tasks and next steps.

-

Prepare for any on-call duties, ensuring that all monitoring systems are correctly configured and that you’re ready to respond to any incidents.

-

Attend any final meetings or syncs with cross-functional teams to ensure alignment on upcoming priorities.

-

Wrap up any remaining tasks and make sure that all systems are running smoothly before logging off for the day.

After regular working hours, if you are on call, you’ll need to remain available to address any critical issues that may arise.

## Hiring an LLMOps Engineer Externally

There are two ways to fill an LLMOps engineer role: you can hire externally, or you can hire internally and upskill your people, training ML engineers to become LLMOps engineers. This section will look at external hiring first and then discuss how to upskill current employees.

If you’re hiring for this role, other skills to look for in candidates for LLMOps engineering roles include experience or proficiency in:

-

Converting models to and from libraries like PyTorch or JAX

-

Understanding ML metrics like accuracy, precision, recall, and PR-AUC

-

Understanding data drift and concept drift

-

Running and benchmarking models to understand the impact of computational graph representation on performance across the neural engine, GPU, and CPU

-

Deploying and scaling ML models in cloud environments like AWS, GCP, and Azure

-

Using LLM inference latency optimization techniques, including kernel fusion, quantization, and dynamic batching

-

Building Ops pipelines for data engineering, deployment, and infrastructure as code (IaC) using tools like Terraform, managing vector databases, and ETL processes for large-scale training datasets

-

Understanding red-teaming strategies, interfaces, and guidelines

-

Using Docker for containerization and Kubernetes for orchestration to ensure scalable and consistent deployments

-

Collaborating on and managing projects with teams that include LLM engineers, data scientists, and ML/NLP engineers

Every company, of course, has its own interviewing process. Some conduct many rounds of interviews; others combine several of the interviews into a single on-site meeting. This section describes a fairly standard four-round interview process, as pictured in [Figure 2-3](https://learning.oreilly.com/library/view/llmops/9781098154196/ch02.html#ch02_figure_3_1748895480187773).

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098154196/files/assets/llmo_0203.png)

###### Figure 2-3. Components of an LLMOps interview

Let’s look at each round in more detail:

Round 1: Initial screeningThe goal during initial screening is to determine that the applicant has the fundamental skills and experience required for the role. This can be assessed via a resume assessment sheet. The questions you’re asking here are very high level. Do they have experience with deploying LLMs in production environments? Do they mention specific frameworks and tools for managing LLM pipelines, and are these the same tools your company uses? If not, will they be able to learn and adopt your stack? Can they show or talk about any past projects?

Round 2: Technical assessmentThe goal in this round is to assess the candidate’s technical proficiency in core areas such as LLM deployment, data engineering, and infrastructure management. Some questions you might ask include:

-

Describe the steps you take to fine-tune a pretrained large language model. How do you ensure that the model is optimized for the specific use case?

-

Walk me through the deployment process of an LLM you’ve worked on. What challenges did you face? How did you overcome them?

-

How would you set up a CI/CD pipeline for LLM training, fine-tuning, and deployment?

-

How do you design and manage data pipelines for large-scale ML projects? What tools do you use, and how do you ensure data quality?

-

How do you monitor and troubleshoot latency issues in production?

-

How do you handle versioning and tracking datasets used in training or fine-tuning LLMs?

-

How do you ensure high availability and cost-efficiency in your cloud infrastructure?

Round 3: System design interviewThe goal in this round is to assess the candidate’s ability to design scalable, reliable, and maintainable systems for deploying and managing LLMs. Sample questions for this round could include:

-

Tell me about a time when you had to make a build-versus-buy decision for a component of your ML infrastructure. What factors did you consider?

-

How would you design an API for serving LLM inferences at scale? Discuss considerations for load balancing, fault tolerance, and latency reduction.

-

How would you use an IaC tool to manage the cloud infrastructure for an LLM deployment? What strategies would you employ to optimize resource usage and cost? What potential problems do you think you’d encounter while scaling it?

-

Describe your approach to dynamic batching in inference service. How do techniques like quantizing and mixed precision training affect the performance and efficiency of LLMs?

-

How do you manage memory in CUDA when training LLMs? What strategies do you use to prevent issues like out-of-memory errors?

-

How do you benchmark model performance before and after optimization? What metrics do you consider, and what tools do you use?

-

How would you diagnose and address performance degradation after an optimization?

Final round: Behavioral interviewIn the fourth round, you’ve narrowed the pool to the most qualified candidates. Now you need to assess their personalities: Are they self-driven? Can they work in a team, handle challenges with equanimity, and contribute to a collaborative environment? Sample questions:

-

How do you stay up-to-date on the latest advancements in LLMs and machine learning operations?

-

How do you approach integrating data scientists’ feedback into the deployment process?

-

How would you collaborate with a red-teaming engineer to address potential security vulnerabilities in an LLM deployment?

-

What experience do you have with on-call rotations? How do you handle critical incidents during off hours?

You’ll also want to ensure the candidate aligns with your organization’s values, particularly in areas like innovation, continuous learning, and collaboration. You can ask questions like:

-

What are your favorite technology blogs or podcasts?

-

How do you keep up with new advances in the field?

## Hiring Internally: Upskilling an MLOps Engineer into an LLMOps Engineer

The gap between MLOps engineers and LLMOps engineers is significant in terms of the scale, complexity, and the technical challenges involved in their roles. Thus, upskilling an existing employee requires a focused effort to build their understanding.

That said, the foundational skills of MLOps—such as model deployment, automation, and cloud management—provide a solid base from which to grow. With dedicated learning and hands-on experience, an MLOps engineer can transition into the LLMOps domain effectively. The core upside of hiring internally is that candidates are already aligned with the organization’s values and culture and have a keen understanding of its KPIs.

To excel, new LLMOps engineers need resources and training to deepen their understanding of large-scale model architectures and transformer architectures, attention mechanisms, infrastructure management, and LLM-specific optimization techniques. They also need to understand how LLMs differ from non-generative ML models. We recommend pairing them up with LLM engineers to experiment with and evaluate different models.

This role isn’t just about building an app that uses LLMs. LLMOps engineers also manage the balance among cost, cloud resources, and user experience and handle huge unstructured datasets. Therefore, pair them with data engineers to help build a data-processing pipeline so they can familiarize themselves with the data sources at their disposal, how the data is structured in the databases, how different databases retrieve information, what the company’s latency expectations are, and how to handle data filtering. Allow them to introduce multi-node setups and distributed systems for different models while focusing on cost optimization and errors. Get them to benchmark different LLM models and debug their performance optimization. Finally, allow them to present their logging practices and the guardrails they have set up for maintaining reliability and performance at scale.

Most MLOps engineers already have skills in model versioning, data versioning, managing rollbacks, and GitHub actions, so upskilling these professionals can be an effective strategy for building a strong LLMOps team.

Next, let’s look at how to make sure the goals of your LLMOps engineers are aligned with your ​organizational goals.

# LLMs and Your Organization

You learned at the beginning of this chapter that the four key goals of the LLMOps framework are security, scalability, robustness, and reliability. For LLMOps teams, then, the next big question is how to measure the application’s performance against those goals. How will you know you’re succeeding? The company’s expectations should be clearly defined and remain quantitatively, as well as qualitatively, measurable at all times.

Three kinds of metrics will allow you to measure your team’s performance toward its goals: SLOs, SLAs, and KPIs. These terms are in common usage among site reliability engineers, and now LLMOps teams are rapidly adopting them as well:

Service-level objectives (SLOs)Service-level objectives are specific, measurable targets set by an organization to gauge the quality of its services internally. They define what level of service the organization aims to achieve. For example, an SLO for a cloud-hosting company might be to ensure that server uptime is at least 99.9% per month.

Service-level agreements (SLAs)Service-level agreements are formal contracts between a service provider and a customer that define the level of service the provider commits to deliver. They typically include specific performance goals and stipulate remedies if those metrics are not met. For example, if the uptime for an internet provider falls below 99.9% annually, the SLA might stipulate that the customer will receive a 10% discount on its next billing cycle.

Key performance indicators (KPIs)Key performance indicators measure the overall success and performance of specific business activities. They provide insight into how well the organization is achieving its strategic objectives. For example, an important KPI for an app might be its churn rate or the percentage of customers who stop using the app over a certain period.

In August 2024, a [Gartner Research study predicted](https://oreil.ly/dIBVc) that 30% of existing GenAI projects would fail by 2025. (In fact, Gartner [published similar findings](https://oreil.ly/Rq3K3) in 2018, predicting that 85% of ML projects would fail in production by 2022.) The key failure points outlined in the 2024 study are notable because they are the operational aspects of LLM development and deployment—including data quality issues, the lack of a strong evaluation framework, and the high costs of scaling these models in production.

That said, one of the most obvious issues is mismatched expectations between management and engineering teams. For the last 10 years, one of data scientists’ biggest skill gaps has been in translating ML model metrics into organizational and product success metrics. In other words, when you’re measuring abstract goals like model security, scalability, robustness, and reliability, how do you communicate what this means for the business? That’s what SLOs, SLAs, and KPIs are for.

Using an SLO-SLA-KPI framework allows LLMOps teams to automate, streamline, and manage expectations across multiple stakeholders. SLOs make it evident to all stakeholders what level of service is being aimed for. SLAs ensure accountability so that everyone involved is aware of their roles and the agreed-upon service levels. This can also help you track performance and address any deviations from the expected standards. And KPIs provide visibility into real-time data to help detect potential issues early, facilitating informed decision-making.

# The Four Goals of LLMOps

Let’s look more closely at the LLMOps goals to see how these metrics translate.

## Reliability

As you know well by now, LLMs are extremely complex, with billions of parameters. Their behavior can be unpredictable, and they sometimes exhibit unexpected responses or errors due to their scale and the intricacies of their training data. Additionally, if the training data is biased, outdated, or unrepresentative of certain domains, the model’s performance can be unreliable in those areas.

LLMs also struggle at times with understanding the context, nuance, and intent behind user queries. This can lead to incorrect, irrelevant, or misleading responses. What’s more, LLMs usually aren’t updated in real time. As language evolves, if new information is not integrated into the training data via regular retraining, models can become outdated, leading to decreased reliability.

All of these issues come down to reliability. The reliability of LLM-based applications can be measured in terms of system availability, error rates, and customer satisfaction. [Table 2-2](https://learning.oreilly.com/library/view/llmops/9781098154196/ch02.html#ch02_table_2_1748895480195314) shows how these metrics would look as SLOs, SLAs, and KPIs.

|   | SLO | SLA | KPI |
| --- | --- | --- | --- |
| Availability | <br>			Maintain 99.9% uptime per month<br> | <br>			Ensure that the system is available for at least 99.95% of requests over a rolling 30-day period<br> | <br>			Customer satisfaction score (CSAT) related to system availability<br> |
| Error rate | <br>			Keep the error rate below 0.1% for all API requests<br> | <br>			Ensure that less than 1% of user interactions result in errors<br> | <br>			Track error rate trends over time and analyze root causes of major errors<br> |
| Customer satisfaction | <br>			CSAT score of at least 90%<br> | <br>			Ensure that the net promoter score (NPS) remains above 8<br> | <br>			Post-interaction surveys or feedback forms; CSAT score<br> |

## Scalability

LLMs tend to have a large memory footprint, often exceeding the capacity of a single machine. Distributing a model across multiple GPUs or nodes while maintaining performance is technically challenging. Handling large volumes of data efficiently is critical.

Another significant challenge is scaling the data pipeline to feed data into the model at the required speed without causing bottlenecks. This can be especially hard for applications like chatbots or interactive services, where low latency is crucial. Scaling while keeping response times low can be challenging, since scaling up increases resource contention and network overhead. Therefore, balancing performance with cost efficiency is a constant concern.

LLMOps scalability can be measured via metrics like latency, throughput, response time, resource scaling, capacity planning, and recovery time objective (RTO), as shown in [Table 2-3](https://learning.oreilly.com/library/view/llmops/9781098154196/ch02.html#ch02_table_3_1748895480195328).

|   | SLO | SLA | KPI |
| --- | --- | --- | --- |
| Latency | <br>			Serve 95% of requests within 200 milliseconds<br> | <br>			Keep the average response time for API calls under 100 milliseconds<br> | <br>			Average response time for user interactions<br> |
| Throughput | <br>			Process a minimum of 1,000 requests per second during peak traffic hours<br> | <br>			Handle at least 1 million concurrent connections without degradation<br> | <br>			Peak throughput capacity during load testing<br> |
| Response  <br><br>			time | <br>			Maintain a web page load time of under 3 seconds for 95% of users<br> | <br>			Ensure that the login process completes within 500 milliseconds for 99% of users<br> | <br>			User experience metrics related to response times<br> |
| Resource scaling | <br>			Automatically scale up resources to handle a 50% increase in traffic within 5 minutes<br> | <br>			Ensure that adding servers linearly increases throughput without impacting latency<br> | <br>			Scalability test results and cost-effectiveness of scaling solutions<br> |
| Capacity planning | <br>			Maintain CPU utilization below 80% during peak hours<br> | <br>			Ensure that enough database connections are available to handle double the anticipated peak load<br> | <br>			Resource utilization trends and forecasting accuracy<br> |
| RTO | <br>			Achieve a recovery time objective of under 30 minutes for critical system failures<br> | <br>			Ensure that the system can recover from a database failure and restore service within 15 minutes<br> | <br>			Historical RTO metrics and improvement initiatives<br> |

## Robustness

Over time, the statistical properties of the model’s training data can change, leading to a drift in the model’s performance. This is particularly problematic for models that interact with real-time or rapidly changing data. This can lead to performance degradation in the form of outdated or irrelevant responses.

Continuous training and fine-tuning are necessary to maintain robustness, but they require significant computational resources and careful management to avoid introducing new biases or errors. You can measure robustness via metrics like data freshness, model evaluation, and consistency, as shown in [Table 2-4](https://learning.oreilly.com/library/view/llmops/9781098154196/ch02.html#ch02_table_4_1748895480195338).

|   | SLO | SLA | KPI |
| --- | --- | --- | --- |
| Data  <br><br>			freshness | <br>			Ensure that dashboard data is refreshed every 5 minutes<br> | <br>			Guarantee that data is updated in real time<br> | <br>			Data refresh latency and accuracy of real-time data updates<br> |
| Model evaluation | <br>			Maintain a performance degradation rate of less than 5% over 6 months<br> | <br>			Guarantee regular updates and reviews of model evaluation metrics<br> | <br>			Accuracy, relevance, and update frequency of evaluation metrics<br> |
| Consistency | <br>			Guarantee strong consistency for data reads and writes across all regions<br> | <br>			Maintain eventual consistency with a maximum propagation delay of 1 second<br> | <br>			Consistency model adherence and replication latency<br> |

## Security

Maintaining LLM application security is challenging: these are complex models handling sensitive data in the face of constantly evolving security threats. LLMs are especially vulnerable to adversarial attacks, data poisoning, and other forms of exploitation that can compromise their integrity and security.

Managing and controlling access to the LLM and its data is complicated, especially in a multi-access or multi-tenant environment, but it’s critical for preventing unauthorized access and misuse. [Table 2-5](https://learning.oreilly.com/library/view/llmops/9781098154196/ch02.html#ch02_table_5_1748895480195348) shows some ways to measure it.

|   | SLO | SLA | KPI |
| --- | --- | --- | --- |
| Data  <br><br>			privacy | <br>			Ensure data encryption for all in-transit and at-rest data<br> | <br>			Ensure no breaches occur<br> | <br>			Encryption compliance status<br> |
| Model  <br><br>			integrity | <br>			Detect and address any model tampering within 24 hours<br> | <br>			Guarantee prompt detection of and response to unauthorized modifications<br> | <br>			Number of unauthorized modifications detected<br> |
| Access  <br><br>			control | <br>			Achieve a user authentication success rate of 99.9%<br> | <br>			Ensure robust user authentication and authorization mechanisms<br> | <br>			Rate of unauthorized access attempts<br> |
| Red  <br><br>			teaming | <br>			Ensure detection of 99.9% of attempted adversarial attacks<br> | <br>			Ensure regular security assessments and updates<br> | <br>			Frequency of security assessments and the number of critical vulnerabilities identified<br> |

When all teams—whether they are involved in development, operations, or management—understand the agreed-upon service levels and performance indicators, they can work together more effectively toward common goals. This alignment fosters a unified approach to managing and improving project performance. It also helps in making data-backed decisions about resource allocation, process changes, and strategic adjustments. Most importantly, it helps in building trust and ensuring that everyone is on the same page regarding expectations and outcomes.

Overall, implementing an SLO-SLA-KPI framework​ not only enhances transparency and fosters collaboration, but it also serves as a foundational element in evaluating and advancing the maturity of your LLMOps practices, which is the topic of this chapter’s final section.

# The LLMOps Maturity Model

LLMOps maturity is a way of determining how well an organization’s LLM operations align with industry best practices and standards. Assessing LLMOps maturity helps organizations identify their strengths, areas for improvement, and opportunities for scaling and enhancing the robustness of their LLM systems.

A few years ago, Microsoft published a [machine learning operations maturity model](https://oreil.ly/1Tjgw) detailing a progressive set of requirements and stages to measure the maturity of MLOps production environments and processes. The LLMOps maturity model we present here, inspired by Microsoft’s MLOps model, is meant to do the same for LLMOps teams. Although this is by no means a comprehensive audit, we hope to see several variations put into practice.

The three LLMOps maturity levels are as follows:

Level 0No LLMOps practices are implemented. The organization’s lack of formal structures and processes for managing and deploying its LLM systems hinders its effectiveness.

Level 1The organization applies MLOps practices but without LLM-specific adaptations. This is an improvement over Level 0 in terms of formalization and processes but still lacks the sophistication needed for full LLM operations.

Level 2Achieving Level 2 represents a mature LLMOps state, characterized by advanced documentation, robust monitoring and compliance measures, and the integration of sophisticated orchestration and human review strategies. Usually, this can be assessed by asking some questions about whether decision strategies and model performance measures and metrics are well documented within the team.

Various measures of LLMOps maturity levels are outlined in [Table 2-6](https://learning.oreilly.com/library/view/llmops/9781098154196/ch02.html#ch02_table_6_1748895480195357).

|   | Level 0:  <br><br>			No LLMOps | Level 1:  <br><br>			MLOps, no LLMOps | Level 2:  <br><br>			Full LLMOps |
| --- | --- | --- | --- |
| Are the business goals and KPIs of the LLM project documented and kept up to date? | <br>			Not documented<br> | <br>			There is documentation, but it’s often outdated<br> | <br>			Full documentation with regular updates; KPIs include model performance metrics, operational efficiency, and cost-effectiveness<br> |
| Are LLM model risk evaluation metrics documented? | <br>			No formal risk assessment<br> | <br>			Basic risk evaluation for model accuracy and data security<br> | <br>			Comprehensive risk evaluation including bias, fairness, data drift, and performance degradation with mitigation strategies in place<br> |
| Is there a documented and regularly updated overview of all team members involved in the project, along with their responsibilities? | <br>			No documentation<br> | <br>			High-level roles are documented, but responsibilities may be unclear for the newer roles<br> | <br>			Detailed team structure with roles, responsibilities, and contact details that is regularly reviewed and updated<br> |
| Is the choice of LLM well documented and cost-compared against other open source/proprietary offerings? | <br>			No documentation or cost analysis<br> | <br>			Basic documentation of LLM choice, minimal cost comparison<br> | <br>			Detailed documentation including rationale for choice, performance benchmarks, and cost comparison against alternative models<br> |
| Is the API for the model vendor well documented, including request and response structure, data types, and other relevant details? | <br>			No API documentation<br> | <br>			Model developed in-house<br> | <br>			Comprehensive API documentation, including request/response examples, data types, error codes, and versioning details<br> |
| Is the software architecture well documented and kept up to date? | <br>			No documentation<br> | <br>			There is a high-level architecture overview, but it may be outdated<br> | <br>			Detailed architecture diagrams including data flow, system components, and integration points that are updated regularly<br> |

Documenting the factors shown in [Table 2-6](https://learning.oreilly.com/library/view/llmops/9781098154196/ch02.html#ch02_table_6_1748895480195357) can be incredibly helpful when choosing and deploying any new model. For example, given the significant costs that are associated with deploying an LLM application, cost-benchmark analysis documentation allows the company to decide which model to roll into production and estimate the project timeline.

After deployment, the company also needs to assess how well the team has documented the model’s performance measures and metrics. This is to make sure that everyone on the team understands the expectations and that they are comprehensively monitoring the model performance in production.

[Table 2-7](https://learning.oreilly.com/library/view/llmops/9781098154196/ch02.html#ch02_table_7_1748895480195367) outlines three levels of LLMOps maturity with regard to model performance and evaluation. Keeping these different levels in mind, organizations and the LLMOps team will be better prepared to deal with contingencies and can better align projects with business goals, mitigate risks, and enhance operational efficiency.

|   | Level 0:  <br><br>			No LLMOps | Level 1:  <br><br>			MLOps, no LLMOps | Level 2:  <br><br>			Full LLMOps |
| --- | --- | --- | --- |
| Does the LLM system operate within its knowledge limits, and recognize when it is operating outside those limits? | <br>			No mechanisms to detect limits<br> | <br>			Basic detection of operational limits<br> | <br>			Advanced guardrails, limit detection mechanisms, and documentation of context-aware warnings using techniques like confidence scoring and thresholding<br> |
| Are the LLM’s inputs and outputs automatically stored? | <br>			No automatic storage<br> | <br>			Basic storage of inputs and outputs<br> | <br>			Automated storage of all inputs and outputs with indexing for easy retrieval and analysis<br> |
| Is A/B testing performed regularly? | <br>			No A/B testing<br> | <br>			Occasional A/B testing with limited coverage<br> | <br>			Regular A/B testing with comprehensive test coverage and analysis, using tools like Optimizely or custom frameworks<br> |
| Are all API requests and responses logged, and are API response time and health status monitored? | <br>			No logging or monitoring<br> | <br>			Basic logging and response time monitoring<br> | <br>			Comprehensive logging with detailed request/response analysis; real-time health monitoring using tools like ELK stack<br> |
| Is the LLM monitored for toxicity and bias? | <br>			No outlier detection or bias monitoring<br> | <br>			Basic outlier detection with manual review<br> | <br>			Advanced automated toxicity and bias detection pipelines using statistical methods and regular bias audits, with automated alerting for low-confidence predictions<br> |
| Are processes in place to ensure that LLM operations comply with regulations such as GDPR, HIPAA, and other relevant data protection laws? | <br>			No process exists<br> | <br>			Process to ensure that LLM operations comply with regulations such as GDPR, HIPAA, or other relevant data protection laws<br> | <br>			Process to ensure that LLM operations comply with regulations such as GDPR, HIPAA, or other relevant data collection and protection laws and copyright laws<br> |
| Does the LLM-based app use anonymization to protect users’ identities while maintaining the data’s utility for LLMs? | <br>			No anonymization<br> | <br>			Basic anonymization techniques applied<br> | <br>			Advanced automated anonymization methods, including data masking and aggregations<br> |
| Does the organization perform regular security reviews and audits of LLM infrastructure and code? | <br>			No regular reviews<br> | <br>			Periodic security reviews and audits<br> | <br>			Regular, comprehensive security reviews and audits, including third-party assessments and vulnerability scans<br> |

Let’s look at these levels in more detail:

Level 0: No LLMOpsMachine learning efforts are often isolated and experimental, and they lack any systematic deployment and monitoring framework. The models may be developed in silos, often resulting in unreliability and inefficiency. Chevrolet’s [chatbot blunder](https://oreil.ly/CtHrG) is an excellent example; due to a lack of monitoring and guardrails, the app was abused by the community for algebra homework. It also offered Chevrolet cars in no-take-backsies deals and promoted Tesla cars instead.

Level 1: MLOps, no LLMOpsThe organization is likely to have a robust pipeline for model training, testing, and deployment, with automated monitoring and retraining workflows. However, this setup is designed to build for small models and is not fully optimized for the specific challenges of LLMs.

Level 2: Full LLMOpsAt the highest level of maturity, the organization has adopted LLMOps practices and is fully optimized for LLM applications. Its infrastructure is capable of handling large-scale LLM deployments, fine-tuning, real-time inference, auto-scaling, and resource management. Mature LLMOps teams have failover and rollback mechanisms in place and can act quickly if the updated model underperforms after deployment. The organization can deliver more reliable responses, get a good ROI, and reduce operational risks.

# Conclusion

In this chapter, we discussed the team structure for organizations building LLM applications. We discussed various roles and how to build a highly effective team. Finally, we discussed a framework for typing the LLM performance metrics with the business KPIs. In the next chapter, we will talk about how LLMs have changed the data engineering landscape, and we’ll show you how to build performant data pipelines for ​LLMs.

# References

Azure Machine Learning. [“Machine Learning Operations Maturity Model”](https://oreil.ly/EebdS), Learn Azure, accessed May 21, 2025.

Friedman, Itamar. [“Software 3.0—The Era of Intelligent Software Development”](https://oreil.ly/AtCSq), *Medium*, May 3, 2022.

Lin, Chin-Yew. [“ROUGE: A Package for Automatic Evaluation of Summaries”](https://oreil.ly/IvSev), *Text Summarization Branches Out*, (Association for Computational Linguistics, 2024).

Kadambi, Sreedher. [“Shingo Principles: Bridging Lean and Toyota Production System Success”](https://oreil.ly/wCmAE). Skil Global, May 28, 2021.

Mcintyre, Branden. [“Chevy Chatbot Misfire: A Case Study in LLM Guardrails and Best Practices”](https://oreil.ly/VQHov), *Medium*, December 22, 2023.

Papineni, Kishore, et al. [“BLEU: A Method for Automatic Evaluation of Machine Translation”](https://oreil.ly/zyIEO), *ACL ’02: Proceedings of the 40th Annual Meeting of the Association for Computational Linguistics*, edited by Pierre Isabelle, Eugene Charniak, and Dekang Lin (Association for Computational Linguistics, 2002).

# Further Reading

Shingo, Shigeo. *Zero Quality Control: Source Inspection and the Poka-Yoke System*, (Routledge, 2021).

Tennant, Geoff. *Six Sigma: SPC and TQM in Manufacturing and Services*, (Routledge, 2001).
