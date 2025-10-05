# Chapter 10. The Future of LLMs and LLMOps

In the next decade, the future of LLMOps, LLMs, NLP, and knowledge graphs will converge in ways we can barely imagine today. Imagine AI systems no longer as distant tools but as deeply integrated into every facet of our lives. Even the most popular LLMs today are [somewhat clunky iterations](https://oreil.ly/O3IFm), but in the near future, I believe they will be [refined](https://oreil.ly/yW4T3) to a point where their understanding of language will [rival human intuition](https://oreil.ly/k8EyH). This is because of emergent traits in LLMs.

Currently, the main way users interact with LLMs is through text-based chats, but in coming years, LLMs won’t just be answering questions; they’ll be engaging in complex problem-solving, offering insights, and pushing the boundaries of creativity itself. For example, in September 2024, OpenAI released Advanced Voice Mode for its ChatGPT application, which can detect voice tone—including sarcasm. Much of this work is related to impending innovations across the infrastructure stack. Meta [recently wrote](https://oreil.ly/16e8R) about issues beyond algorithms and architecture that arise in training these models at scale (see [Figure 10-1](https://learning.oreilly.com/library/view/llmops/9781098154196/ch10.html#ch10_figure_1_1748896837889780)).

LLMOps will be the backbone supporting these systems as they mature into a seamless, self-sustaining infrastructure. Instead of manual intervention, pipelines for training, fine-tuning, and deploying these models will be fully automated, speeding up advances in this area. LLMOps engineers will spend less time debugging code and more time refining high-level system strategies, including platform and infrastructure designs that automatically balance model training with compute costs.

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098154196/files/assets/llmo_1001.png)

###### Figure 10-1. Reliability is a key goal for LLMOps, but even Meta struggles with it, as more innovation is needed at the infrastructure level (source: [Engineering at Meta](https://oreil.ly/xlokW); used with permission)

These models will adapt on the fly, learning from real-world feedback at a rate that feels almost magical. This has been the primary goal of AutoML, which is an active area of research in ML. Most importantly, as LLMs start generating higher-quality translated content, they can more easily expand their capabilities to additional languages, even less common ones. An additional source of excitement ([Figure 10-2](https://learning.oreilly.com/library/view/llmops/9781098154196/ch10.html#ch10_figure_2_1748896837889817)) is that LLMs are getting better at using multimodal inputs. Currently, it takes an LLM a few seconds to process text, voice, and images, and a lot of [progress is being made](https://oreil.ly/IWfM4) in simultaneous speech-to-text translation, a critical step toward speech-to-speech translation. Once simultaneous speech-to-text quality is high enough, existing text-to-speech models such as OpenAI Whisper can be used to complete the speech-to-speech translation pipeline.

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098154196/files/assets/llmo_1002.png)

###### Figure 10-2. [X post](https://oreil.ly/fbw7V) by Barret Zoph on September 24, 2024, during his time as vice president of research at OpenAI

One of the limitations of LLMs is that, at their core, they generate the most likely next word based on the data they were trained on and the prompt submitted, but they don’t seem to understand even simple concepts. In a popular example (pictured in [Figure 10-3](https://learning.oreilly.com/library/view/llmops/9781098154196/ch10.html#ch10_figure_3_1748896837889849)), Meta’s LLM could easily tell that Tom Cruise’s mom is Mary Lee Pfeiffer but had trouble with the question “Who is Mary Lee Pfeiffer’s famous actor son?” It frequently answered with the names of other famous actors, such as Matt Damon, Tom Hanks, and Michelle Pfeiffer—the “famous actor” part of the prompt took precedence.

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098154196/files/assets/llmo_1003.png)

###### Figure 10-3. Meta’s AI answers to questions about actor Tom Cruise and his mother, Mary Lee Pfeiffer, that show a lack of conceptual understanding

One solution that is under research is to use knowledge graphs that contain relationships between concepts. *Knowledge graphs* contain representations of interconnected concepts and their relationships. For example, Wikipedia lists Mary Lee Pfeiffer as Tom Cruise’s mother, but the fact that he is her son is not written down: it’s implicit. Knowledge graphs [make relationships explicit](https://oreil.ly/aGwVQ), creating systems that understand context in a way that’s [almost human](https://oreil.ly/ILvsK).

Conversations with LLMs will become indistinguishable from human conversations. No more fumbling with chatbots or dealing with “robotic” responses. Advances in personalization can allow future LLM applications to combine several facts they learn about users in the course of their interactions. Simple versions of this already exist today. For example, ChatGPT already learns what programming language an individual user frequently asks questions about and provides answers in that language by default. [Recent research](https://oreil.ly/n6lZt) provides several other examples of adding personalization for education, healthcare, and finance. Although these use cases currently appear mostly in research papers, when deployed successfully in production across every ecommerce application out there, LLMs will anticipate users’ needs, contextualize interactions, and even predict trends—all while learning continuously from new data streams.

One of the key concerns people voice about LLMs has to do with the alignment risks associated with these models; namely, if a model is capable of showing emergence and can predict and emulate human behavior, then how do we know it will continue to be helpful in the long run? Should development pause while researchers closely monitor these models’ performance? How can we ensure that the model is not behaving in a sociopathic way, providing harmless answers only when it realizes it’s being tested? [Researchers are exploring answers](https://oreil.ly/BAilf) to these questions.

As someone who believes in holding a [Stoic outlook](https://oreil.ly/yfbPd) toward this future, my opinion is that we should embrace any technology that makes life simpler, richer, and more meaningful. As with all progress, the true winners will be those who understand that it’s not about the machine but about how we, as humans, use it wisely.

LLM architecture has advanced exponentially from the mid-2010s to the mid-2020s, but the coming years promise even more profound shifts. These changes will redefine not only how LLMs are structured but also how they interact with data, humans, and each other. From increased scalability to more efficient computation, from hybrid architectures combining multiple paradigms to emergent self-learning systems, the future of LLMs has breathtaking potential. This chapter explores several aspects of that potential.

# Scaling Beyond Current Boundaries

Today’s LLMs, like GPT-4, have reached impressive scales, but they are far from their limits. Going into the 2030s, we should expect to see architectures designed with scalability in mind from the ground up. This is not simply about increasing the number of parameters; it’s about efficient, targeted scaling. Future architectures will incorporate hierarchical layers of models (also known as *hierarchical attention networks*), where each layer is optimized for a specific domain of understanding such as reasoning, emotion, or even creativity (see [Figure 10-4](https://learning.oreilly.com/library/view/llmops/9781098154196/ch10.html#ch10_figure_4_1748896837889880)).

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098154196/files/assets/llmo_1004.png)

###### Figure 10-4. In the scaling law, N represents the number of data points, and D is the number of parameters; larger models with more data points tend to perform better than larger models with less data (source: “First Principles on AI Scaling” by [Dynomight](https://oreil.ly/uCTJD))

Rather than creating ever-larger monolithic models, we’ll see more modular LLMs that can delegate tasks to specialized submodels. Imagine an architecture where the base LLM understands language but calls on additional “expert” modules trained for niche tasks like legal reasoning, medical diagnostics, or creative writing. Instead of having one large base model trying to be an expert in everything, we would have models that are experts in different things: a healthcare model, a legal model, a creative writing model, etc.

A specialist model can outperform a generalist model and use fewer resources. This is already happening for math problems and web searches in ChatGPT. [Researchers have found](https://oreil.ly/c1svH) that GPT performs below average in graduate-level math, and all GPT models have [knowledge cutoffs](https://oreil.ly/pv6sA), meaning that they are unaware of events after their cutoff date. Currently, when GPT detects that an user is asking a question about an event that occurred after its training cutoff date, it outsources the question to a different model called [SearchGPT](https://oreil.ly/kJtXj), then uses the results to provide an answer inside the existing chat. Combining generalist models with specialist models allows LLMs to operate efficiently and with greater depth in specialized areas, reducing the computational overhead while improving output precision.

To support such adaptable massive systems, innovations in distributed computing and parallelization will be key. As Evan Morikawa, who led OpenAI engineering when ChatGPT was becoming ever more popular, explains in an [interview](https://oreil.ly/bMlsK), models need to be hosted not on singular clusters but across decentralized networks of nodes. This shift will optimize training times, data latency, and real-time inference, making LLMs vastly more efficient in handling large-scale, real-world applications.

# Hybrid Architectures: Merging Neural Networks with Symbolic AI

One of the current limitations of LLMs lies in their reliance on deep learning alone, which excels at pattern recognition but struggles with symbolic reasoning and logic. In many cases, scientists have already discovered patterns and codified them into symbolic formulas (e.g., Newton’s theory of gravity), but the way neural networks are trained doesn’t allow them to use existing formulas—they have to rediscover patterns by themselves.

The future of LLMs will involve hybrid architectures that merge the strengths of neural networks with symbolic AI approaches. These architectures will allow models not only to predict the next word in a sentence but also to use known rules and formulas, as humans do.

*Neurosymbolic*, or “hybrid,” AI architectures unite the intuitive, pattern-matching power of neural networks with the precise, rule-based reasoning of symbolic systems. LLMs excel at processing text and generating natural-sounding responses by learning statistical regularities from massive datasets, while symbolic AI can represent explicit facts, logical constraints, and rules, making it far easier to trace its reasoning process and enforce consistency. By merging these two approaches, we will develop systems that can understand human language, perform rigorous logical operations, and provide explanations for their conclusions.

In practice, this can manifest in multiple ways. For instance, one method is to have an LLM convert user queries into structured representations—such as logical formulas—and then rely on a symbolic reasoner to apply domain-specific rules or constraints. This hybrid approach can also aid in explainability—one of the key weaknesses in today’s LLMs. Users will be able to query why the model arrived at a particular conclusion, and the model can refer to the symbolic pathways used in the answer, providing a more transparent window into its decision-making process.

## Sparse and Mixture-of-Experts Models

One of the biggest bottlenecks in scaling LLMs today is their sheer computational cost. Current models process every input with all their parameters, at inference time, regardless of the complexity or simplicity of the task. Future architectures will move toward sparse models and mixture-of-experts systems, where only a subset of the model’s parameters is activated for a given task.

In *sparse models*, only the most relevant parameters or neurons are activated for a particular query, allowing for massive reductions in resource consumption while maintaining high-quality results. We believe that sparse modeling, combined with the modular approach, will lead to the development of powerful, efficient LLMs capable of running on consumer-grade hardware while delivering enterprise-level performance.

*Mixture-of-experts (MoE) models*, by contrast, allow LLMs to dynamically activate specialized “experts” based on the input’s requirements. A user asking for medical advice would engage a different subset of the model’s neurons than a user requesting help with poetry. This approach drastically reduces the number of computations per query while increasing the depth of understanding in each domain. It’s a “divide and conquer” strategy, where LLMs focus computational resources only where they are needed most.

## Memory-Augmented Models: Toward Persistent, Context-Rich AI

Current LLMs operate with limited memory. While capable of handling context within a few thousand tokens, they struggle to maintain long-term memory across sessions. The next generation of LLMs will address this with *memory-augmented architectures* capable of storing and retrieving vast amounts of data over long periods. These models will have persistent memory layers, allowing them to recall user interactions from years ago or build a comprehensive knowledge base that evolves with time.

This kind of persistent memory will also revolutionize [how LLMs handle personalized tasks](https://oreil.ly/tsGoZ). Rather than starting from scratch with each interaction, future models will remember the user’s preferences, needs, and history, enabling richer, more nuanced conversations and solutions. However, that comes with its own challenges in production, including unexpected behavior when dealing with inconsistencies in data. For example, imagine a single parent who is a senior government official but who also asks questions about how to raise a female child without specifically telling the model that the questions are about another person. For example, they ask, “What are the signs that my first period is arriving?” instead of “What are the signs that my daughter’s first period is arriving?” The personalization algorithm may incorrectly conclude that the user is a teenage girl who is also a senior government official.

Persistent memory will be key in enterprise applications, where models will continuously learn from organizational data, building an ever-growing repository of insights and expertise.

## Interpretable and Self-Optimizing Models

As LLMs become more pervasive, the need for interpretability will grow. Users and businesses alike will demand models that can explain their reasoning, mitigate biases, and adapt in real time. Future LLM architectures will include built-in interpretability features using causal learning, where each decision or prediction can be traced back through a chain of reasoning or probabilistic mapping.

These models will also be self-optimizing. Using reinforcement learning, LLMs will learn from user feedback, fine-tuning their own parameters to better align with desired outcomes. Over time, these models will become more personalized, adjusting not just to individuals but also to the specific needs of organizations or industries. Imagine a legal AI model that, after interacting with a team of lawyers for months, begins to understand the specific nuances of that firm’s legal style, approach to risk, and preferred legal precedents. These models will learn through iterative feedback, continuously improving without needing massive retraining efforts. They are currently being explored ([Huang et al. 2022](https://oreil.ly/F30ZX); [Jin et al. 2025](https://oreil.ly/Xaf-t)) as agents to aid operational productivity, but many applications remain unexplored.

## Cross-Model Collaboration, Meta-Learning, and Multi-Modal Fine-Tuning

In the future, no single LLM will operate in isolation. We’ll see architectures where multiple models collaborate, exchanging data, insights, and strategies in real time.

*Meta-learning* will also become more prominent, so instead of having to be trained from scratch, LLMs will learn how to learn. This means they will be capable of adjusting their architectures dynamically based on the tasks they encounter and will optimize themselves without human intervention, using different distillation techniques. This shift will push LLMs toward becoming self-evolving entities, reducing the need for constant retraining and manual updates. Overall, we will move beyond the brute-force scaling of today’s models to more refined, hybridized architectures capable of reasoning, learning, and adapting in ways that feel almost human.

In addition, as LLMs increasingly interact with multimodal data (text, images, audio, etc.), multimodal fine-tuning techniques will become essential. These methods will enable LLMs to integrate and process information from various modalities, enhancing their ability to perform complex tasks that require understanding of diverse data types.

## RAG

RAG models will continue to evolve, integrating retrieval-based components with generative models to enhance accuracy and relevance. These hybrid models will retrieve relevant information from large databases or knowledge sources and use it to generate more informed and contextually appropriate responses. Advances in real-time retrieval mechanisms will allow them to access and utilize up-to-date information dynamically so they can provide current and contextually relevant responses. This promises to improve RAG models’ effectiveness in applications such as customer support, knowledge management, and content creation.

Future RAG systems will better integrate with knowledge graphs and external databases, enabling LLMs to leverage structured knowledge for more accurate, detailed, factually correct, and comprehensive responses—even to complex queries.

Innovations in retrieval mechanisms will focus on improving efficiency and scalability ([Gao et al. 2024](https://oreil.ly/EO8IV)). Techniques like approximate nearest neighbor search and indexing will be optimized to handle large-scale data and reduce latency in retrieval processes.

To conclude, sparse models and modular frameworks will make LLMs far more efficient, while memory-augmented models will bring persistence and depth to their understanding. The future of LLMs is not just one of bigger models but smarter ones—architectures that grow, learn, and reason, forming a new foundation for AI-driven innovation across every aspect ​of society.

# The Future of LLMOps

I expect the coming decade to bring a lot of innovation to LLMOps, including the infrastructure layer that will be guided by that framework. One of the biggest contributions of any Ops framework is that it helps practitioners understand what tools they can build to automate and streamline best practices across the industry. For example, the biggest contribution of DevOps was the boom in cloud services infrastructures. For MLOps, it was data- and model-versioning tools. For LLMOps, I personally believe that the biggest booms will be in tools for resource optimization, evaluation, and multimodal data management.

## Advances in GPU Technology

GPUs play a key role in LLMOps, and their evolution will continue to drive advancements in model performance and efficiency. Over the next decade, several emerging trends in GPU technology will significantly impact LLMOps.

The future of GPUs will see the rise of highly specialized AI hardware designed specifically for the unique demands of LLM training and inference, as [Figure 10-5](https://learning.oreilly.com/library/view/llmops/9781098154196/ch10.html#ch10_figure_5_1748896837889900) illustrates. Companies like NVIDIA, AMD, and Intel are developing next-generation GPUs with enhanced architectures tailored for AI workloads. These include more GPU cores, increased memory bandwidth, and optimized tensor operations to accelerate model training and reduce latency during inference.

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098154196/files/assets/llmo_1005.png)

###### Figure 10-5. Predicting GPU performance over the next 30 years (source: [Epoch AI](https://oreil.ly/TzddI), used with permission)

As LLMs grow in size, the need for efficient multi-GPU and distributed training strategies will become more pronounced. Advances in distributed computing frameworks, such as NVIDIA’s NVLink and AMD’s Infinity Fabric, will enable more seamless scaling across multiple GPUs and nodes. This will improve training efficiency and reduce the time required to develop and deploy large-scale models.

With the increasing computational demands of LLMs, energy consumption is a critical concern. Future GPUs will focus on enhancing energy efficiency. Incorporating techniques like dynamic voltage and frequency scaling (DVFS) and using advanced cooling solutions will mitigate their environmental impact and operational costs.

Finally, although still in its infancy, quantum computing presents potential opportunities for accelerating LLM operations. Quantum processors could complement traditional GPUs, offering exponential speedups for certain types of calculations. Researchers are exploring hybrid approaches that combine quantum and classical computing to tackle complex LLM tasks.

## Data Management and Efficiency

As you learned in [Chapter 4](https://learning.oreilly.com/library/view/llmops/9781098154196/ch04.html#ch04_data_engineering_for_llms_1748895507364914), effective data management is critical for training and deploying LLMs. Since LLMs require vast amounts of high-quality data, there will be an increasing emphasis on data curation and quality control. We expect techniques for automated data cleaning, augmentation, and validation to become more sophisticated, ensuring that training datasets are diverse, accurate, and representative.

Innovations in data storage and retrieval will be important for managing these massive datasets. Distributed file systems, object storage solutions, and high-performance databases will be incorporated into existing vector databases to handle the scale and complexity of data efficiently.

With growing awareness of data privacy, organizations will adopt advanced methods for protecting user data. Techniques like federated learning and differential privacy will be integrated into data management, allowing LLMs to learn from decentralized data sources without compromising individual privacy.

[Synthetically generated data](https://oreil.ly/gJ7J4) will become a key supplement to real-world data, improving training speed, reducing privacy concerns (as synthetic data is machine generated), and reducing reliance on expensive or scarce data. The [Microsoft phi-4 small language model](https://oreil.ly/_DXcC) released in late 2024 has, by using some synthetic data, achieved good benchmarks at low cost and a small number of parameters.

## Privacy and Security

Privacy and security will be paramount as LLMs become more integrated into sensitive and high-stakes applications. The deployment of LLMs will involve advanced security measures to protect against attacks and ensure data integrity. Techniques such as model watermarking, adversarial training, and secure multi-party computation will be employed to safeguard models from tampering and misuse.

As LLMs become more pervasive, ethical considerations will drive the development of guidelines and best practices for their use. New laws like the ones in the [United States](https://oreil.ly/KjaEW), the state of [California](https://oreil.ly/48e1Z), and the [European Union](https://oreil.ly/xV4NL) will incentivize organizations to focus on transparency, fairness, and accountability, implementing measures to ensure that LLMs are used responsibly and ethically. Also, given the massive training and maintenance costs, it’s economical for large AI providers to develop models that follow a large market’s most restrictive set of rules and deploy them broadly, rather than train and maintain different models for each set of legal requirements. For example, if the EU requires that models only use anonymized data, it’s economical to train and maintain one model worldwide that uses anonymized data rather than two, one that does and one that does not.

## Comprehensive Evaluation Frameworks

I expect that new evaluation frameworks will be developed to assess LLMs across a range of dimensions beyond standard metrics like recall and precision, including factual accuracy, logical accuracy, and coherence. These frameworks will incorporate both qualitative and quantitative measures to provide a holistic view of model performance.

Establishing industry benchmarks and standards, ideally from organizations such as the United Nations International Telecommunication Union (ITU), the Institute of Electrical and Electronics Engineers Standards Association (IEEE SA), and the International Organization for Standardization (ISO), will be essential for comparing LLM performance across different models and platforms. Standardized benchmarks will facilitate fair evaluation and enable organizations to make informed decisions when selecting or developing LLMs.

Ongoing monitoring and evaluation will become standard practice to ensure that LLMs maintain high performance over time. Techniques for continuous evaluation and performance tracking will help identify and address issues as they arise, ensuring that models remain effective and relevant.

# How to Succeed as an LLMOps Engineer

To succeed as an LLMOps engineer, you need to take a system administrator approach to productionizing LLMs. As directly responsible individuals (DRIs), engineers must be able to understand, evaluate, and manage risk.

Our LLMOps maturity model ([Chapter 2](https://learning.oreilly.com/library/view/llmops/9781098154196/ch02.html#ch02_introduction_to_llmops_1748895480208948)) can come handy when budgeting for different kinds of errors, from software fault tolerance to model evaluation errors. You cannot monitor everything. Set reasonable expectations and automate labeling and debugging for different kinds of errors. These could mean keeping an error trail, creating groups of related errors, and using LLM agents to explain and even debug them. An LLMOps engineer often acts as the on-call engineer, which requires dealing with all sorts of problems: hardware, data quality, privacy, and user errors. These issues need to be dealt with quickly, often as emergencies. LLMs can help LLMOps engineers sift through the problems and provide suggested solutions, increasing productivity.

As you learned in [Chapter 2](https://learning.oreilly.com/library/view/llmops/9781098154196/ch02.html#ch02_introduction_to_llmops_1748895480208948), LLMOps has four goals: security, scalability, robustness, and reliability. It can be a tough balancing act to prioritize among monitoring inferences for security testing, optimizing the model inference pipeline, A/B testing the model releases, managing the compute nodes, and optimizing the run pipelines.

Depending on the number of active users the LLM-based application has, the features under development, and the size of the team, LLMOps engineers’ workloads can vary massively.

# Conclusion

The world of LLMOps is not just about cutting-edge technology; it’s also about processes and measurements. Together, technology, measurements, and processes are the pillars supporting the future of AI.

In this book, you’ve learned about how to apply, deploy, and maintain LLMs efficiently. We discussed the importance of data quality and data management, and we explored the art and science of improving LLMs through fine-tuning and prompt engineering.

We’ve examined the revolutionary potential of RAG to bridge the gap between the general knowledge possessed by LLMs and the recent and/or specialized data some applications need. We’ve also discussed privacy and security, recognizing that safeguarding our digital interactions is as important as advancing our technological frontiers.

Yet, amid these advancements, it’s important to remember the essence of our pursuit. LLMOps is more than a technical discipline; it’s about ensuring that our creations serve humanity in ways that are ethical, transparent, and equitable.

Economists recognize AI as one of a very few [general-purpose technologies](https://oreil.ly/H2GYl), in the same class as the internet, electricity, or the printing press. These general-purpose technologies tend to be incorporated into almost every human activity, changing the trajectory of progress. LLMOps can help us make the most of AI, preventing and correcting problems and accelerating advances.

The future is ours to shape. Let’s make it a future that reflects our highest aspirations and our deepest values.

# References

Abdin, Marah, et al. [“Phi-4 Technical Report”](https://oreil.ly/_DXcC), arXiv, December 12, 2024.

Amodei, Dario. [“Machines of Loving Grace: How AI Could Transform the World for the Better”](https://oreil.ly/yW4T3), October 11, 2024.

Bolaños Guerra, Bernardo and Jorge Luis Morton Gutierrez. [“On Singularity and the Stoics: Why Stoicism Offers a Valuable Approach to Navigating the Risks of AI (Artificial Intelligence)”](https://oreil.ly/yfbPd), *AI and Ethics*, August 2024.

[California AI Transparency Act](https://oreil.ly/48e1Z), Sb-942 (2023–2024) (enacted).

Chen, Zhuo, et al. [“Knowledge Graphs Meet Multi-Modal Learning: A Comprehensive Survey”](https://oreil.ly/aGwVQ), arXiv, February 2024.

Dynomight. [“First Principles on AI Scaling”](https://oreil.ly/uCTJD), July 2023.

Eloundou, Tyna, et al. [“GPTs Are GPTs: An Early Look at the Labor Market Impact Potential of Large Language Models”](https://oreil.ly/H2GYl), arXiv, August 2023.

EU Artificial Intelligence Act. [“Article 50—Transparency Obligations for Providers and Deployers of Certain AI Systems”](https://oreil.ly/xV4NL), (enacted).

Federal A.I. Governance and Transparency Act of 2024, H.R.7532, 118th Congress (2023–2024) (introduced). [https://oreil.ly/KjaEW](https://oreil.ly/KjaEW).

Fountas, Zafeirios, et al. [“Human-like Episodic Memory for Infinite Context LLMs”](https://oreil.ly/tsGoZ), arXiv, October 2024.

Frieder, Simon, et al. [“Mathematical Capabilities of ChatGPT”](https://oreil.ly/c1svH) arXiv, July 2023.

Gao, Yunfan, et al. [“Retrieval-Augmented Generation for Large Language Models: A Survey”](https://oreil.ly/EO8IV), arXiv, March 2024.

Hagendorff, Thilo, et al. [“Human-like Intuitive Behavior and Reasoning Biases Emerged in Large Language Models but Disappeared in ChatGPT”](https://oreil.ly/k8EyH), *Nature Computational Science* 3 (10): 833–38 (2023).

Hobbhahn, Marius and Tamay Besiroglu. [“Predicting GPU Performance”](https://oreil.ly/TzddI), Epoch.ai, December 1, 2022.

Huang, Jiaxin, et al. [“Large Language Models Can Self-Improve”](https://oreil.ly/F30ZX), arXiv, October 2022.

Ji, Jiaming, et al. [“AI Alignment: A Comprehensive Survey”](https://oreil.ly/BAilf), arXiv, April 2025.

Jin, Haolin, et al. [“From LLMs to LLM-Based Agents for Software Engineering: A Survey of Current, Challenges and Future”](https://oreil.ly/Xaf-t), arXiv, April 2025.

Lee, Jenya, et al. [“How Meta Trains Large Language Models at Scale”](https://oreil.ly/16e8R), *Engineering at Meta* (blog), June 12, 2024

Liu, Ruibo, et al. [“Best Practices and Lessons Learned on Synthetic Data for Language Models”](https://oreil.ly/gJ7J4), arXiv, August 2024.

OpenAI. [SearchGPT Prototype](https://oreil.ly/kJtXj), July 25, 2024.

OpenAI Platform. n.d. [Models](https://oreil.ly/pv6sA), accessed May 21, 2025.

Orosz, Gergely, [“Scaling ChatGPT: Five Real-World Engineering Challenges”](https://oreil.ly/bMlsK), *The Pragmatic Engineer*, February 20, 2024.

Pan, Shirui et al. [“Unifying Large Language Models and Knowledge Graphs: A Roadmap”](https://oreil.ly/ILvsK) *IEEE Transactions on Knowledge and Data Engineering* 36 (7): 3580–99 (2024).

Papi, Sara, et al. [“How ‘Real’ Is Your Real-Time Simultaneous Speech-to-Text Translation System?”](https://oreil.ly/IWfM4), arXiv, December 2024.

Tu, Shangqing, et al. [“ChatLog: Carefully Evaluating the Evolution of ChatGPT Across Time”](https://oreil.ly/O3IFm), arXiv, June 2024.

Zhang, Zhehao, et al. [“Personalization of Large Language Models: A Survey”](https://oreil.ly/n6lZt), arXiv, May 2025.

# Further Reading

Hagendorff, Thilo, et al. [“Thinking Fast and Slow in Large Language Models”](https://oreil.ly/AQZbR), *Nature Computational Science* 3 (10): 833–38 (2023).
