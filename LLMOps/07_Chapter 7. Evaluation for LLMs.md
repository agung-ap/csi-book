# Chapter 7. Evaluation for LLMs

Language models have become increasingly sophisticated, but assessing their effectiveness accurately remains a significant challenge.

The importance of LLM evaluation has garnered attention not only from academia but also from industry stakeholders. This convergence of research and testing efforts signifies the importance of the problem and the collective determination to find effective solutions. It also accelerates the pace of innovation, helping researchers understand and improve these models further.

In academia, researchers have been exploring new methodologies, developing innovative metrics, and conducting rigorous experiments to push the boundaries of LLM evaluation Although there are some leading contenders, there are no clear winners yet, since many metrics and scoreboards end up being useful for just a short period or for a narrow set of applications. Regardless, industry players are keenly aware of the practical implications of LLM performance.

At its core, evaluation aims to gauge how well an LLM accomplishes its intended purpose, whether it’s generating coherent and contextually relevant text, understanding user input, or completing specific tasks. In this chapter, you’ll learn about a systematic framework designed to tackle this challenge for different applications, along with some tips on what has worked.

# Why Evaluation Is a Hard Problem

*Evaluating* LLMs is the process of assessing their performance and capabilities. It involves a combination of methods to determine how well an LLM achieves its intended purpose and adheres to ethical guidelines.

Developing and deploying ML solutions requires creating new types of testing and evaluation than those used in traditional software development. In particular, ML models use random numbers during training and need to be tested in aggregate across datasets, as well as on specific atomic pieces of data that can help validate that the training worked correctly. However, once the models are trained, most ML models are deterministic in that they don’t use random methods to make inferences; i.e., that the same inputs will always produce the same outputs.

In contrast, LLMs use random numbers during training and making inferences, so the same input can produce different outputs even if there have been no changes in the model. Several other assumptions no longer hold or need to be augmented. This chapter will explore several open questions around datasets, metrics, and methodology selection.

Any operational ML solution must provide some expected performance characteristics before going into production. You also need a way to monitor it effectively to identify and fix any performance problems after deployment. Model evaluation helps:

-

Ensure that the model is performing as expected

-

Identify areas where the model can be improved

-

Ensure that the model is being used safely and responsibly

Why is evaluating LLMs so hard? There are several reasons:

-

First, human language is very complex and can be difficult to quantify. This makes it difficult to develop accurate quality evaluation metrics.

-

Language models are typically trained on large datasets of text. This makes it difficult to find a representative sample of text that the model has never seen before to use for evaluation.

-

Language models can exhibit bias in line with the datasets they are trained on, generating text that violates social, ethical, or legal norms.

The difficulty of interpreting why LLMs generate particular outputs can lead to challenges around reproducibility and consistent experimental design.

LLMs are trained on massive amounts of data, and the number of possible inputs they can receive is practically infinite, so it’s impossible to exhaustively test them on every scenario. Evaluating even a tiny fraction of possibilities is a monumental task. Therefore, we must content ourselves with evaluating categories of scenarios, such as:

-

Informativeness and factuality

-

Is the output factually correct?

-

Does the output contain sufficient information relevant to the input prompt?

-

Is the generated text a complete response to the input?

-

Fluency and coherence

-

Are the outputs grammatically correct and readable?

-

Do they follow a logical flow?

-

Is the output language at an appropriate level?

-

Engagement and style

-

How engaging and interesting are the LLM’s outputs?

-

Is the writing style appropriate?

-

Safety and bias

-

What harmful content could this LLM generate?

-

Could the output be used to put people at risk?

-

Is the output using biased concepts or language?

-

Grounding

-

How well grounded is the LLM’s response in real-world information?

-

Does it offer appropriate references?

-

Does it avoid hallucinations?

-

Efficiency

-

What computational resources does the LLM require to generate outputs?

-

How long does it take to start generating the response?

-

How long does it take to generate a complete response?

While there are clear success metrics for some types of tasks (e.g., accuracy in image recognition: “Is this a picture of a bird?”), what constitutes a “good” response from an LLM can be subjective. Does the output provide relevant information? Is it creative? Is it factually accurate? These goals can conflict, making it hard to design a single metric that captures everything. “Good performance” can mean several things.

Another difference between evaluating ML and LLM models is that when an ML model fails an evaluation task, the developing team usually turns to *interpretability *tools that explain why the model made decisions. Such tools try to understand the internal mechanisms of models by running an extremely large number of examples through a model and measuring how changes in the input influence the output. Since most ML models are deterministic (the same input will always provide the same output), these tools allow developers to understand what parts of the input are important for generating some outputs, essentially improving their understanding of how the model works internally. ​As of today, interpretability tools are unavailable for LLMs because LLMs have too many parameters and are nondeterministic; thus, an immense quantity of examples and computation time would be needed to understand their internal ​workings.

# Evaluating Performance

There are a number of ways to evaluate and monitor the accuracy of LLM-based solutions during development and after deployment. *Manually checking* the output for accuracy and correctness can be time-consuming, and it depends on the judgment of evaluators. *Automatic evaluation* uses tools to evaluate the accuracy of the LLM’s output; essentially, you’re using LLMs to evaluate LLMs. User feedback is also helpful in identifying areas where the LLM is performing poorly and needs improvement.

Most importantly, you cannot evaluate an LLM without an application. In many LLM applications, users know which real-world performance metrics would be useful. For example, let’s say your company is using LLMs to generate text scripts for web advertisements. When humans write the advertising copy, a typical evaluation method is to perform an *A/B test*, randomly offering different options to similar audiences, A and B, and measuring the success rate (for example, number of ad clicks) of each audience. If the success rate for the audience receiving option A is different enough from that of option B to be statistically significant, the company would select option A as the more successful script. The same method can be used on LLM-generated copy. Indeed, for many common ML tasks, such as classifying text, identifying images, and counting objects, it makes sense to simply use the existing pre-LLM methods and metrics.

There are, however, some metrics that are specific to NLP and don’t require user involvement, making them less costly and good choices to evaluate LLMs.

Since a major part of what LLMs do is generate content, we use a set of metrics called *generative metrics* to measure the quality of the content generated. The most basic of these, called n*-gram-based metrics*, assess the similarity between generated text and existing data by examining the overlap of sequences of *n* words. To use this metric for an evaluation, you should know the expected “correct” answer, and you can compare how many of the *n* words generated by the LLM are in the correct answer.

For example, if *n* equals 1, the comparison looks at individual words; if *n* equals 2, it considers pairs of words; and so on. These metrics quantify the degree of similarity based on the shared *n*-grams, providing insights into the coherence and relevance of the generated text compared to the correct answer.

For example, one of your tests could be “Q: What’s the capital of France? A: Paris.” The *n*-gram test can be very simple and will work well when the LLM answers “Paris” (100% of the *n*-grams match) but won’t perform well when the LLM provides the correct answer “The capital of France is Paris.” Since you were expecting the answer to be Paris, only 16.6% of the words in the second answer match the correct answer, and you may think that the LLM is not performing as well as it really is.

Second*, similarity-based metrics *aim to capture various aspects of similarity between generated text and a reference text. They include:

BERTScoreMeasures both content overlap and fluency

SemScoreChecks that the generated text conveys the same meaning and intent as the reference text

MoverScoreCalculates the minimum amount of “work” required to transform one text into another

These metrics compare how similar two whole sentences are by computing embeddings and comparing them. Using the same example as before, the LLM answers “It’s Paris” and “The capital of France is Paris” will both generate a high score, as both these sentences have similar meanings. One problem is that the sentence “Teh KaPiTaLL of Franceland is PARIS” will also score high in terms of meaning similarity, even though it’s full of spelling errors and uses the made-up word “Franceland.”

Therefore, we turn to *LLM-based metrics*, which use other LLMs to evaluate the target LLM’s generation quality and identify potential hallucinations. These metrics identify correct answers and can also evaluate fluency and grammatical correctness, but they are expensive to compute. Here are some popular metrics and the papers that define how to implement and use them:

G-EvalScores the generated text based on its coherence, fluency, and factual consistency as judged by another LLM.

UniEvalConsiders multiple factors like fluency, grammaticality, and factual coherence through an ensemble of LLM evaluators.

GPTScoreDesigned specifically for GPT-like models, it uses an LLM to evaluate aspects like coherence, safety, and factual consistency.

TRUEUses other LLMs to assess factual correctness and identify potential factual hallucinations.

SelfCheckGPTDesigned for GPT models, it focuses on identifying logical inconsistencies and factual errors in the generated text.

These metrics are configurable to your specific use case. Although many provide example questions and expected answers in their papers, you should generate a question-and-answer database that is applicable to your use case.

There are also many general benchmarks for LLMs that have the goal of evaluating how well an LLM performs as a general problem-solver, without focusing on a specific task. These benchmarks tend to be more useful if you’re building a platform-level LLM, like Google’s Gemini or OpenAI’s ChatGPT. Although such benchmark results are useful in some aspects and appear frequently in marketing materials that describe how good a model is, they suffer from an important drawback: they can’t tell how well a model will perform on a specific task. It’s possible that model A performs substantially better than model B in general tasks and therefore on a general benchmark like GLUE, but model B may perform better than model A in the tasks you need it to do; for example, analyzing legal documents. It is therefore important to understand these benchmarks for what they are: an aggregate score of general applicability.

Some of the top benchmarks are listed in [Table 7-1](https://learning.oreilly.com/library/view/llmops/9781098154196/ch07.html#ch07_table_1_1748896751659531), but keep in mind that this is an active area of research, with new benchmarks being proposed all the time.

| Benchmark | Description | Focus |
| --- | --- | --- |
| [General Language Understanding Evaluation](https://oreil.ly/rcLR4) (GLUE) | <br>			Suite of tasks assessing core NLP abilities<br> | <br>			Natural language understanding (NLU)<br> |
| [SuperGLUE](https://oreil.ly/mpepc) | <br>			Successor to GLUE, featuring more challenging tasks<br> | <br>			NLU<br> |
| [HellaSwag](https://oreil.ly/2VpX9) | <br>			Focuses on reasoning and commonsense understanding<br> | <br>			Natural language inference (NLI)<br> |
| [TruthfulQA](https://oreil.ly/adQ-N) | <br>			Evaluates factual correctness and avoidance of factual hallucinations<br> | <br>			Question qnswering (QA)<br> |
| [Massive Multitask Language Understanding](https://oreil.ly/0xT-x) (MMLU) | <br>			Large-scale benchmark on diverse tasks<br> | <br>			Multi-task learning<br> |

These benchmarks are public, and so are their question-and-answer pairs. This allows different LLMs to be compared on the exact same criteria and therefore allows comparisons between LLMs.

However, this creates a problem: LLM developers can train the model simply to perform well on the benchmarks, like a student memorizing the answers to an upcoming exam. This is a very serious problem in practice. It’s not uncommon to see an LLM perform well in general benchmarks, only to perform below the level of GPT-3.5 (a now-obsolete but inexpensive model) in a practical application, like describing a scene. When this happens, there’s usually little reason to use the model that has the higher general scores—your users should have the final word.

Another problem is that LLMs are highly sensitive to the compatibility of the data used in training and prompts used in evaluation. A seemingly minor change in the prompt can lead to drastically different outputs. This makes it difficult to design prompts that consistently elicit the desired response and assess the LLM’s true capabilities.

For example, some models may respond better when asked to “think step-by-step” ([Wei et al., 2023](https://oreil.ly/YIrYf)), while others might respond better when asked politely, with prompts starting with “please.” These are the results of training bias. In this example, if the portion of the training dataset that contained more polite instructions had a higher proportion of correct answers, simply adding “please” to all prompts will yield better results on benchmarks.

LLMs use another trick that students frequently use to improve their exam scores when they don’t know the answer to a question: they repeat or paraphrase parts of the question or prompt in their responses. This can create a false sense of understanding or agreement, making the text produced for the answer highly related to the question, even when the quality of the answer itself is low.

In summary, benchmarks can be useful to compare LLMs with other LLMs, but be aware of their limitations and use them with ​care.

Some applications of LLM are so common that they deserve special attention, like RAG and multi-agent systems. Although the metrics described here can be used to evaluate RAG and multi-agent systems, each of them has its own specific metrics, described in the next sections.

## Evaluating What Breaks Before It Breaks Everything

When LLMs first entered production environments, their early failures appeared sporadic and unpredictable. These initial glitches were often dismissed as the model simply “acting weird,” a kind of random quirkiness rather than a systemic issue. However, as usage expanded and data accumulated, clearer, more consistent patterns of failure began to surface. These patterns are not traditional software bugs, like segmentation faults or crashes, but rather what we call failure modes (see [Table 7-2](https://learning.oreilly.com/library/view/llmops/9781098154196/ch07.html#table0702)).

| Failure mode | Where to evaluate | Tools/signals |
| --- | --- | --- |
| Hallucinations | Retrieval, prompt, inference | Similarity to source, factual checks |
| Prompt regressions | Orchestration | Prompt diffing, quality degradation logs |
| Latency spikes | Inference, retrieval | p95/p99 latency metrics, tracing |
| Data drift | Input, retrieval | Embedding shifts, cluster distribution |
| Inconsistent behavior | Inference | Session-level tracing, repeat queries |
| Safety violations | Output | Toxicity filters, PII detection |

*Failure modes* represent recurring but explainable breakdowns that arise due to a fundamental mismatch between the model’s internal assumptions and the complex realities of real-world data and interactions. Unlike conventional software errors that trigger exceptions or cause program crashes, failure modes are often “silent failures”. The system continues to operate normally on the surface, producing outputs that look syntactically valid and stylistically coherent. Yet beneath this veneer, these outputs can be factually incorrect, ethically problematic, or structurally flawed. This subtlety makes failure modes particularly insidious, as they evade detection by traditional debugging methods, which typically rely on outright crashes or obvious error signals.

Therefore, the evaluation paradigm for LLMs must evolve beyond reactive debugging toward a more proactive approach (see [Figure 7-1](https://learning.oreilly.com/library/view/llmops/9781098154196/ch07.html#fig0701)). Instead of waiting for failures to disrupt users, the goal becomes to anticipate and detect these failure modes early, before they propagate harm or misinformation. This proactive detection requires sophisticated monitoring frameworks that combine automated metrics, human-in-the-loop validation, and domain-specific checks to identify when the model’s assumptions no longer hold, or when outputs deviate from expected behavior. By shifting evaluation from post-hoc fixes to continuous, anticipatory oversight, we can better ensure the reliability, safety, and ethical integrity of LLM deployments at scale.

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098154196/files/assets/llmo_0701.png)

###### Figure 7-1. Evaluating traditional ML models versus LLMs

Let us try to understand the most common failure modes in modern LLM pipelines and identify where observability and evaluation tools can intercept them early.

### Hallucinations

Among the various failure modes LLMs exhibit, hallucinations stand out as the most infamous and challenging to manage. Hallucinations happen when an LLM produces responses that are linguistically fluent and confident, yet factually incorrect or completely fabricated. This phenomenon arises because LLMs generate text by predicting the most statistically likely token sequences based on their training data, rather than querying a reliable, up-to-date factual knowledge base. Therefore, hallucinations are an inherent risk, especially when LLMs are applied in high-stakes domains such as healthcare, finance, or legal services, where inaccurate or misleading information can lead to serious consequences.

Evaluating hallucinations extends beyond simply detecting isolated factual errors. Instead, it demands a systematic, longitudinal approach to pattern monitoring. This typically involves logging all generated outputs and, where possible, comparing them to verified ground truths. When exact ground-truth data isn’t accessible, one alternative strategy is conducting consistency checks across multiple generations of the model’s responses to detect contradictions or instability. These evaluation methods help identify individual hallucinations as well as the conditions and contexts in which they occur more frequently.

In RAG systems, hallucinations often signal problems in the retrieval component. For instance, if the retriever fetches irrelevant, outdated, or low-quality documents, the LLM is more likely to generate incorrect or fabricated content. This interdependence makes it important to maintain observability across both the retrieval and inference layers. Comprehensive monitoring frameworks that track the quality and relevance of retrieved documents alongside the model’s output can help diagnose whether hallucinations are stemming from retrieval failures, generative errors, or a combination of both. Understanding these root causes is essential for designing targeted mitigation strategies, such as improving retrieval accuracy, integrating more reliable knowledge sources, or incorporating verification mechanisms during generation.

### Prompt regressions

*Prompt regression* represents a particularly subtle yet deeply frustrating failure mode in LLM deployments. Unlike obvious output errors, prompt regressions arise from seemingly minor changes to the prompt templates, such as renaming variables, inserting or removing whitespace, or adjusting formatting, that unexpectedly degrade the quality of the model’s outputs. These degradations are often not immediately apparent, making them harder to detect and diagnose in real time.

The challenge is compounded by the inherent nondeterminism of LLMs: given the same input, the model may generate different outputs across runs, due to sampling methods and stochastic token prediction. This variability makes it difficult to reproduce prompt regressions consistently, posing a significant barrier to traditional debugging approaches.

To manage this complexity, robust evaluation systems must integrate detailed prompt versioning and logging capabilities. Tracking changes at a granular level is essential, as is supporting prompt diffs that highlight exactly what was modified between versions. By correlating these prompt changes with measurable metrics, such as declines in response helpfulness, factual accuracy, or structural coherence, teams can precisely pinpoint when and how regressions begin to manifest.

This systematic correlation enables effective root-cause analysis, allowing developers to identify the problematic prompt iterations swiftly. More importantly, it empowers teams to roll back to previously stable prompt versions when they detect regressions, preserving output quality and user trust. In this way, prompt-regression monitoring becomes part of a proactive evaluation strategy to ensure that subtle prompt-engineering tweaks don’t unintentionally erode model performance or reliability over time.

### Latency spikes

Regardless of a system’s intelligence or sophistication, users uniformly reject slow and unresponsive experiences. Latency, especially spikes occurring at the high end of the distribution, such as the 95th (p95) or 99th percentiles (p99) is particularly damaging. These tail latencies, though rare in frequency, disproportionately impact user experience by causing noticeable delays and, in some cases, triggering downstream timeouts or failures in interconnected systems.

Effective evaluation of latency requires continuous, fine-grained monitoring that tracks not only average response times but also token usage patterns and relevant system-level metrics. This comprehensive observability is important for detecting abrupt increases in latency early, before they degrade service quality at scale.

When such latency spikes occur, robust tracing mechanisms become indispensable for root cause analysis. These tools enable engineers to dissect the request pipeline and identify bottlenecks or failure points. Potential culprits may include excessively long input prompts that increase processing time, delays within retrieval components responsible for fetching relevant documents, or bottlenecks in upstream dependencies, such as vector databases or external APIs. Additionally, changes to the underlying model version or system infrastructure can introduce unexpected latency regressions.

Without this level of observability, latency spikes remain invisible to monitoring dashboards and alerting systems until end users experience degraded performance or failures. Therefore, embedding end-to-end tracing and real-time latency monitoring into the evaluation workflow is essential for maintaining smooth, predictable system behavior and ensuring a consistently responsive user experience.

### Data drift

In live production environments, user behavior and input data are in a state of continuous flux. This dynamic landscape often leads to data drift, a phenomenon where the foundational assumptions embedded in a system–such as expected input formats, distributions of user intents, or the nature of contextual embeddings–gradually diverge from the evolving reality of incoming data.

Data drift manifests in several distinct ways. Input drift typically shows up as an increase in adversarial or malformed queries that deviate from the original training or design expectations. This can stress the system’s robustness and degrade output quality. Retriever drift occurs when the relevance of the documents returned by retrieval components declines, even if the retrieval algorithms and configurations remain unchanged. Similarly, embedding drift arises when the vector representations used to compare semantic similarity become less effective, causing retrieval systems to fail despite stable system parameters.

Effectively evaluating drift demands rigorous statistical monitoring of input feature distributions over time. Techniques include cluster analyses of query types to detect emerging user intents or new patterns of interaction, histograms of token lengths to track shifts in input verbosity, and continuous measurement of embedding similarity scores to catch subtle shifts in semantic representation. These quantitative early-warning signals allow engineering teams to anticipate when the system’s assumptions will no longer hold.

By proactively detecting drift, teams gain the opportunity to retrain models, refresh retrieval indexes, and redesign prompt templates before any degradation becomes noticeable to end users. This anticipatory approach ensures that the system adapts seamlessly to evolving data landscapes, maintaining both accuracy and user satisfaction over time.

### Inconsistent behavior

The inherently stochastic nature of LLM generation means that repeating the exact same query multiple times can yield different responses on each occasion, a phenomenon called nondeterminism. This variability is a natural consequence of probabilistic token sampling strategies, which promote diversity and creativity in generated text. However, this randomness presents a fundamental challenge for use cases where auditability, compliance, and reproducibility are critical. In such contexts, inconsistent outputs can undermine trust, complicate debugging, and even violate regulatory requirements.

Evaluating and managing inconsistent behavior requires a session-level tracing framework that goes beyond simply logging inputs and outputs. It must capture rich contextual metadata alongside each interaction, including model hyperparameters like temperature and top-k sampling values, specific model versions, and any relevant prior conversation history or user interactions. This comprehensive trace allows teams to reconstruct and analyze the exact environment and conditions that produced a given output.

With detailed session-level logs (see [Figure 7-2](https://learning.oreilly.com/library/view/llmops/9781098154196/ch07.html#fig0702)), it becomes possible to identify patterns of variability, correlate output inconsistencies with particular settings or context changes, and enforce reproducibility where necessary by fixing sampling parameters or replaying interaction sequences. This granular level of evaluation is essential for deploying LLMs responsibly in sensitive domains where predictable, verifiable behavior is nonnegotiable.

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098154196/files/assets/llmo_0702.png)

###### Figure 7-2. Logging styles vary in scope, from isolated events to full sessions

Consistency can be enforced selectively, using deterministic decoding strategies like greedy or beam search, although this typically sacrifices output diversity. The key is balancing consistency where required and building monitoring systems that highlight inconsistency when it matters.

### Ethical and compliance risks

LLMs can inadvertently produce toxic content or biased language, leak private information, or be vulnerable to jailbreak prompts. These risks carry serious legal and reputational consequences. To mitigate them, evaluation tools must integrate automated filters and classifiers that flag problematic outputs in real time, as we discussed earlier in the chapter. Metrics such as safety scores, toxicity indices, and bias measurements should be collected alongside model metadata for auditing purposes.

## Metrics for RAG Applications

A RAG application uses an LLM to generate text, but it helps the LLM be more precise by retrieving data from a knowledge base and appending that data to the user prompt. RAG applications go through the steps shown in [Figure 7-3](https://learning.oreilly.com/library/view/llmops/9781098154196/ch07.html#ch07_figure_1_1748896751654685).

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098154196/files/assets/llmo_0703.png)

###### Figure 7-3. RAG application workflow

Let’s look at each step in more detail:

User inputThe user submits a question or prompt to the RAG application.

RetrievalThe application utilizes a retrieval system to search a database of relevant documents or text data, such as *n* articles, manuals, code snippets, or any other information relevant to the LLM’s domain. The retrieval system identifies the most relevant portions of the data based on the user’s query, using techniques like vector similarity search.

Prompt augmentationThe application concatenates a developer-crafted prompt with the retrieved text from the previous step and the original user input.

LLM generationThe augmented prompt is then sent to the LLM, which uses the additional context it provides to generate a response and present it to the user.

In addition to the generation metrics described in the previous section, RAGs can benefit from retrieval metrics that assess the effectiveness of the retrieval component. Some key retrieval metrics include:

RecallThis measures how thoroughly the system gathers the material that really matters. To compute it, you start with a “ground-truth” collection of documents that experts have already judged relevant to a query. When the retrieval step runs, you look at the overlap between this authoritative set and the documents the system produced. If the engine surfaces almost every item the experts identified, recall is considered high; if it misses many of them, recall is low. You can measure the result as a percentage.

Mean reciprocal rank (MRR)This measures how quickly a user sees the first genuinely useful result. For each query, scan the ranked list from the top until you encounter the first relevant document and note its position. A document in the first slot is ideal, one in the fifth slot is less impressive, and so on. You then convert those positions into scores that reward early appearance and average the scores across many queries. A high MRR means that users usually encounter something relevant right at or near the top of the page. Although you can use whatever scoring mechanism you want, a typical way to score a search that retrieves *n* documents is to assign *n* points if a correct answer comes in the first position, *n* – 1 if it comes in the second position, and so on.

Mean average precision (MAP)This evaluates both the placement and consistency of relevant items throughout the list. Working down through the results for a single query, you keep a running tally so that every time another relevant document appears, you check what fraction of everything seen so far is relevant. When you finish the list, you average those interim fractions to summarize that one query. For example, if your retrieval step is expected to return three results and the three results returned are relevant, the average precision is 100%. If the first and second results are relevant, the AP is (100% + 100% + 0%) / 3 = 67%. If the first and third results are relevant, the AP is (100% + 0% + 67%) / 3 = 56%. Repeating the process for many queries and averaging again yields MAP. For example, the MAP of the last two queries is (67%+ 56%) / 2 = 61%. A high value indicates that relevant documents show up frequently and are distributed toward the top of the result rather than being scattered sparsely or bunched near the bottom.

Context precisionThis metric looks at the flip side of recall; i.e., given everything the retriever returned, how much of it is genuinely helpful? You inspect each passage to decide whether it supports the language model’s task or merely adds noise. When the bulk of retrieved results match the ground-truth collection of documents, context precision is high; when irrelevant or misleading passages dominate, the score drops. You can measure context precision as a percentage.

RelevanceThis approach provides a balance between precision and recall. It considers both how completely the retrieved set covers the needed facts and how free it is of extraneous material. High relevance means the context supplied to the language model simultaneously contains nearly all critical information and avoids clutter, thereby giving the model an ideal foundation for an accurate, focused response. Although you can calculate relevance by taking the simple average (or even the sum) of precision and recall, practitioners typically take the harmonic mean of precision and recall (this is called the F1-score), which makes balanced results like 60% precision and 60% recall score higher than unbalanced results like 90% precision and 30% recall.

While you can measure each of these metrics on your own, in practice you’re likely to use an evaluation tool. Most evaluation tools can measure both the retrieval metrics just described and the generation metrics described in the previous section. For simple applications, you can use an [existing framework](https://oreil.ly/QUyLl) like [Ragas](https://oreil.ly/JkFwY) that provides prebuilt functionality and streamlined workflow. Ragas is a Python-based application that contains all the previous metrics and can measure the outputs of your application and summarize the results in a single score. Ragas is also designed to be user-friendly, with clear documentation and examples. This makes it easier for researchers and developers, even those without extensive coding experience, to evaluate their RAG systems.

For most production applications, you will need a customizable evaluator that allows you to define your own metrics, add your own datasets, and integrate tests with your CI/CD tools; for example, by automatically running a set of tests after a new model version is deployed. One popular open source tool to perform these tasks is the [LangSmith](https://oreil.ly/F8EVF) toolset, created by the makers of LangChain.

To perform evaluations in LangSmith, you first define a dataset of test cases and one or more evaluators. For each evaluator, you can define a metric (such as the metrics in this chapter) or a rubric that explains, in English, how to score answers. You can use the LangSmith programming interface to connect the output of your LLM to the evaluator and automatically score it.

Because LangSmith offers an SDK, you can run the tests during development, but you can also run the tests whenever you deploy a new model. You do this by creating a script that sends prompts to the new model and uses LangSmith to evaluate the answers as soon as the model is deployed by your CI/CD tool.

You can also use the SDK to create a script that periodically runs a test in production using a fixed dataset to see whether a model is *drifting*; that is, whether the model’s performance is changing over time. In general, you would expect that running the same test over the same dataset would have the same score, but if you’re using an LLM service like OpenAI’s GPT API or Google’s Gemini API, the underlying model can change outside of your control. This is called *model drift* and is explained in more detail at the end of this chapter. In any case, running a periodic test as described here will let you detect model drift.

## Metrics for Agentic Systems

In late 2024, the term *agentic system* started to become more popular. In the context of LLMs, an agentic system is an AI system with several internal modules and multiple steps that can autonomously plan, decide, and act to pursue high-level goals with only strategic human oversight. In an agentic system, the user sends a request to a coordinating LLM that breaks the requests into tasks. The coordinating LLM then sends each task to itself, to other LLMs, or to specialist programs. It compiles their responses and provides the compilation to the user. This multistep process generates a myriad of evaluation issues.

All the metrics defined earlier in this chapter still apply; thus, if one of the components of the agentic system is a RAG system, you can use the RAG metrics, and for content-generating LLMs, you can use the generative metrics defined toward the beginning of this chapter. There are, however, additional complexities:

Dynamic behaviorAgents can exhibit emergent behaviors based on their interactions, making it hard to predict outcomes or when these behaviors will occur.

Context sensitivityThe performance of agents can vary significantly based on context, requiring extensive testing across different scenarios.

Continuous learningMany LLMs and agents adapt over time based on interactions, making static evaluations less relevant.

Feedback loopsThe presence of feedback loops between agents can create nonlinear effects that are hard to replicate.

Integration with existing systemsDeploying agents in real-world environments can reveal unforeseen issues that aren’t present in simulated settings.

Environmental variabilityChanges in the operational environment can lead to unexpected behaviors, complicating the evaluation process.

Multiple goalsAgents may have conflicting objectives or collaborate in ways that require balancing multiple criteria, complicating evaluation metrics. Sometimes two agents have poor metrics individually but collaborate well and generate output that is better than would be produced by collaboration between two different agents with better individual metrics.

In practice, it’s easier to evaluate the end product of the agentic collaboration. Therefore, the two main ways of evaluating agentic systems are human evaluators and LLM evaluators. While human evaluation is considered the gold standard, it can be expensive and time-consuming. On the other hand, using LLMs as evaluators often strikes a good balance among cost, quality, and effectiveness, but it can occasionally be biased. Two other problems are that LLMs are opaque and resource intensive. If you use an LLM evaluator, don’t be completely hands-off. An LLM evaluating a model can start to perform poorly, so it’s advisable to have some level of human double-checking. Additionally, there is no universally accepted set of metrics for evaluating agentic systems, leading to inconsistencies.

Also, resource constraints (on computational power and memory, for example) limit how much evaluation one can do. Resource consumption may vary widely for different configurations, affecting scalability assessments.

For any LLM-based agentic system there are four key evaluation objectives:

Examine its internal properties.This means looking at its core language skills, how well it grasps context, whether it can learn and transfer knowledge, and how readily unexpected abilities (emergent behaviors) appear. You also ask how quickly it adapts to new environments or tasks and how effectively multiple agents cooperate. Evidence comes from coherence and relevance in answers, comprehension during live interactions, decision-making in controlled scenarios, and responsiveness when the situation changes. Logs and simulations reveal collective behaviors, while longitudinal testing shows whether performance improves, plateaus, or degrades over time. To measure performance, you can use the metrics defined previously.

Audit performance at the engineering level.You care about efficiency, scalability, and robustness when things go wrong. Measure the computational resources used to fulfill tasks. Stress tests show what happens as you scale up the number of agents or workloads, and fault injection experiments probe resilience and recovery strategies under adverse conditions.

Focus on the quality of interaction.Here you want to know how engaging, clear, and trustworthy the dialogue feels to human users. Metrics such as session length, turn-taking frequency, and response latency quantify engagement, while surveys probe perceived reliability, conversational coherence, and relationship warmth. Observational studies of real-world use round out the picture by documenting how users actually behave around the agent.

Measure user satisfaction.Ultimately, people must feel the system helps them accomplish their goals, and it should leave them with a positive emotional impression. You can capture explicit feedback on task success (like a thumbs-up or thumbs-down after each response), run sentiment analysis on user comments, and conduct surveys that gauge both moment-to-moment emotions and overall approval.

One typical way to measure success is to calculate the net promoter score (NPS) by asking users “How likely are you to recommend the system for a task?” and give a score between 0 and 10 inclusive. Users who give a score of 9 or 10 are considered *promoters*, and users who give scores between 0 and 6 are considered *detractors*. The NPS is calculated as % Promoters – % Detractors. It can range from +100 (every user is a promoter) to –100 (every user is a detractor). Scores above +30 indicate strong performance.

Together, these four perspectives—system properties, technical performance, interaction quality, and user satisfaction—provide a holistic, complementary view of how well an agentic LLM system actually works in practice.

Given the complexity of measuring agentic systems, practitioners usually use different measurement strategies at different steps of the system-development process. If you were to break the development of an agentic system down into three steps, then model development and training, deployment, and production monitoring would be the different metrics that are most important at each stage.

### Stage 1: Model development and training and integration into the agentic system

While the model is still in the lab, focus on *intrinsic capabilities*:

Language abilitiesTrack response coherence and end-user comprehension. You can use the generative metrics and the associated tools described in this chapter.

IntegrationMeasure how each component of the agentic system is used when a user request comes in. Test whether the appropriate agents are involved in the tasks. For example, if you have a program that performs math (a calculator agent) that should be called by your orchestrating LLM when the user enters a math question, ensure that this is what actually happens. If it isn’t, you may need to adjust your orchestrating prompt.

### Stage 2: Agentic system deployment

With a trained model checkpoint in hand, you now ask, “Will people trust this system and find it useful?”

Trust and reliabilityUse survey-based internal user trust scores. The NPS metric defined previously is a good indicator of whether users like the system and find it useful.

User–agent relationshipLong-form user interviews and quick user satisfaction polls can tell you how test users feel about the system.

Overall satisfaction and perceived effectivenessA/B tasks, success rate tallies, and sentiment analysis of open-text feedback provide ground truth.

Built-in survey widgets make it easy to collect this data in a controlled sandbox before you expose the system to real customers.

### Stage 3: Production

At scale, you watch for higher-order phenomena and operational health:

Agent component utilizationCheck whether component agents are being used as you expected. You may have created several specialist agents in anticipation of user workloads, but if some are not being used, it may make sense to shut them down and move their functionality to the orchestrating LLM where answers will be provided quickly.

EngagementMeasure average session duration and per-user interaction frequency as leading indicators of churn. Are users completing tasks? Are they returning day after day to complete more tasks?

Computational efficiencyAs with any computational system, monitor the computational resources. Log average task completion time and resource utilization (CPU/GPU) to spot bottlenecks before your cloud bill spikes.

# General Evaluation Considerations

Ultimately, the success of your system is measured by its users. The main goal of metrics that can be automatically measured is to catch errors and improve the system to improve the user experience without frustrating users. However, as much as you can afford to do so, conduct user studies over an extended period to track changes in trust and satisfaction as users interact with your product.

NPS is a quick and useful one-question indicator of success and for that reason is widely adopted in many industries.

Satisfaction widgets are also very useful; for example, you can collect user feedback after each interaction by adding “thumbs-up” and “thumbs-down” buttons after each response, providing user feedback on real-world interactions.

You can also use commercial monitoring platforms like [Weights & Biases](https://wandb.ai/site) or develop your own metrics with the LangSmith tool described earlier in this chapter to monitor your system in production. LangSmith can automatically evaluate the outputs of the agentic system. Weights & Biases can collect metrics, show dashboards, and emit alerts when metrics become lower than some threshold you define.

By integrating channels for immediate user feedback, you can learn from user interactions and improve your application over time. This iterative process of collecting feedback and updating your application ensures that it adapts to user preferences, ultimately enhancing trust and satisfaction.

## The Value of Automated Metrics

As shown in [Chapter 6](https://learning.oreilly.com/library/view/llmops/9781098154196/ch06.html#ch06_api_first_llm_deployment_1748919660052702), automated metrics can make it a lot easier for you to see whether changes are improving your application. For example, let’s say you have an application that generates text that describes an image. Your existing prompt has an NPS of 90%, but a new paper is proposing a different prompting technique (for example, using bullet points). If your metrics are automated, it’s easier to create an A/B test, offering output from the existing prompt to audience A and from the new prompt to audience B. You should expect the NPS of audience A to remain close to 90% (since it’s using the existing prompt). If the NPS of audience B, the one using the new prompt, is higher, you can decide to switch everyone to the new prompt.

Another use of A/B tests is to improve computational efficiency. LLMOps practitioners frequently try to reduce prompts while keeping the same performance. Since most LLMs are priced (or consume resources) based on prompt size, you want to use the smallest prompt that achieves a given quality threshold. You don’t even need to generate the smaller prompts yourself; you can use an LLM to summarize or reduce existing prompts while keeping the meaning and intention of the original prompt. If you have automated metrics, you can then test several prompts and select the smallest one that achieves your performance requirements. This can save enormous amounts of money and resources. Of course, you can also do this without using automated metrics, but it will take a lot longer.

## Model Drift

LLMs are under constant development, with new models and new model versions coming up all the time. The performance of your application can drift because of a change in the model. Sometimes it improves, but sometimes it declines. If you don’t measure it, you won’t know.

For example, the popular GPT-3.5 Turbo model has four versions, the first two of which ceased to work on February 13, 2025. For users who configured their settings to “auto-update,” calls to these deprecated versions started going to the latest version automatically. For all other users, they just started returning errors.

In both cases, LLMOps would help. The latter case is more obvious, as even the most basic of monitoring systems (receiving lots of angry emails from disappointed users) will catch it.

The former case, when a model automatically changes to a new version, can generate unexpected issues. For example, it’s possible that some guardrails that you had to implement to prevent errors in earlier versions of the model are not necessary anymore. A typical case is dedicating a large portion of the prompt to safeguards against biases and offensive answers. Newer versions of models typically incorporate defenses against several known attacks, so including these defenses in your prompts might become just a waste of money.

A more difficult scenario is when performance unexpectedly drops. It’s possible for a prompt that worked with the old version to stop working with the new version, for unknown reasons.

Ideally, you would know about the version shift ahead of time so you could perform tests and make adjustments while both versions are still available. However, not all applications developed during the initial AI boom were built with metrics and monitoring in mind. Many developers were surprised when their applications suddenly stopped working or started giving different results due to a change in the backend of their cloud model provider.

# Traditional Metrics Aren’t Enough

As we discussed earlier, in the RAG and Agents Evaluation section, standard metrics such as accuracy and loss have long served as foundational indicators of model performance during the training and validation phases. These metrics effectively quantify how well a model fits its training data or generalizes to held-out validation sets. However, they fall short in capturing the nuanced and multifaceted failure modes that emerge once models are deployed in complex, real-world production environments.

In production, outputs can be syntactically fluent and stylistically polished, yet harbor hallucinations, latent biases, or structural inconsistencies that traditional metrics like accuracy or loss simply do not detect. These subtle issues often have serious downstream consequences, from propagating misinformation to causing ethical violations and user dissatisfaction.

As a result, production-level evaluation demands toolsets and frameworks that are specifically designed for continuous, real-time monitoring of model behavior. These systems focus on detecting anomalies, tracking data and concept drift, assessing user impact, and identifying emerging ethical risks. Effective evaluation in this context requires more than just recognizing failure modes; it calls for architecting comprehensive observability pipelines that can capture these failures early and with high fidelity.

Such observability systems must be capable of tracing errors back to the precise stages in the inference or data-processing pipeline where they arose, whether that means input preprocessing, retrieval components, the generative model itself, or post-processing layers. Such granular mapping lets engineering teams perform rapid root-cause analysis, prioritize fixes, and confidently roll out mitigations. This proactive, end-to-end monitoring infrastructure transforms evaluation from a reactive afterthought into a strategic, integral part of maintaining reliability, safety, and ethical integrity in LLM-powered systems at scale.

## The Observability Pipeline

Evaluation can no longer be an afterthought, applied only after a response is generated. It must be embedded throughout the LLM pipeline, from initial input to final user feedback (see [Figure 7-4](https://learning.oreilly.com/library/view/llmops/9781098154196/ch07.html#fig0704)).

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098154196/files/assets/llmo_0704.png)

###### Figure 7-4. Observability pipeline for LLMs

## Preprocessing and Prompt Construction

LLM deployment failures often trace back not to the model itself, but to the prompts it receives. In production environments, prompts are rarely fixed, handcrafted snippets. Instead, they are dynamically generated, assembled from templates, and parameterized based on upstream data sources or evolving user state. This dynamism introduces complexity and variability that can subtly undermine the system’s performance if not carefully managed.

Evaluation at the prompt stage focuses on several critical dimensions. First, prompts must be syntactically valid, correctly formatted, and free from errors that could disrupt parsing or tokenization. Second, they need to be semantically coherent, providing clear, unambiguous instructions that align with the model’s expected input format. Third, rigorous version control of prompt templates and their variants is essential. By capturing every prompt version and structural modification, teams gain traceability that links downstream inference errors directly back to specific prompt changes.

To prevent cascading failures during model inference, it’s important to detect malformed inputs early, such as missing context variables or incorrectly injected parameters. Monitoring metrics like prompt token length distribution is another key operational practice. Excessively long prompts risk being truncated, which can omit vital context and degrade the output quality. Conversely, prompts that are too short may fail to provide sufficient context, effectively starving the model of the information it needs to generate accurate and relevant responses. By continuously tracking these distributions, teams can proactively identify regressions and intervene before they impact end users’ experience.

As prompt engineering matures into a formalized discipline, evaluation in this stage evolves from reactive debugging toward a model of foundational pipeline governance. This shift emphasizes systematic oversight, reproducibility, and controlled iteration, ensuring that prompt generation remains a stable, reliable cornerstone of the overall LLM inference pipeline.

## Retrieval in RAG Pipelines

In RAG systems, failures frequently originate not within the LLM itself, but within the retrieval stage. Evaluating retrieval performance is therefore critical. It involves assessing multiple dimensions: the contextual relevance of retrieved documents, the freshness of the information, and timeliness relative to the query’s intent and domain.

Effective RAG observability frameworks should log the exact set of documents retrieved for each user query, to enable retrospective analysis and reproducibility. Quantitative metrics, such as similarity scores between retrieved documents and verified ground-truth sources, provide objective measures of retrieval accuracy. Monitoring retrieval latency is also essential, since delays in fetching documents directly impact the system’s overall responsiveness and the user experience.

One of the most powerful evaluation techniques in this context is *embedding similarity drift detection*. By continuously tracking the statistical distributions of query and document embeddings, teams can detect subtle shifts that may signal degradation in retrieval quality. These shifts often precede more obvious failures, such as hallucinations or vague, nonspecific responses, caused by irrelevant or outdated documents. Once this kind of drift is detected, timely interventions include retraining the retriever, refreshing the index, and reconfiguring the retrieval pipeline.

Without this granular observability, it becomes extremely challenging to differentiate failures caused by retrieval issues from those arising in the generation stage. Properly instrumented evaluation pipelines that span both the retrieval and generation components are thus indispensable for maintaining the reliability, accuracy, and user trustworthiness of RAG-powered enterprise LLM systems.

## LLM Inference

At the inference stage, the key metrics span several dimensions. Factual accuracy assesses whether the generated text aligns with verifiable truth, while hallucination rate measures the frequency of hallucinations. Fluency evaluates the readability and coherence of outputs. Latency tracks response times, which directly affect user experience and system throughput.

To enable deep diagnostics, observability systems must log detailed metadata for every inference call:

-

Token counts for both inputs and outputs reveal usage patterns and potential truncations.

-

Temperature and other sampling parameters clarify the probabilistic nature of generation.

-

Model versioning lets you trace performance changes to specific code or model updates.

-

Abrupt shifts in completion length may indicate truncation errors or latent failures that aren’t immediately obvious in the delivered responses, making this metric particularly valuable.

Beyond surface metrics, internal evaluation techniques provide an additional layer of quality assurance. Self-consistency checks, which compare multiple generations of the same prompt, can identify outputs that are superficially fluent but inconsistent or contradictory. Similarly, confidence scores derived from auxiliary evaluators or specialized classifiers help flag outputs that deviate from the expected factual or ethical standards.

Inference is rarely a standalone process; it’s usually embedded within intricate chains or pipelines involving multiple calls, retrieval steps, and post-processing. This is where structured logging and trace visualization tools become essential. These tools enable real-time monitoring, facilitate root-cause analysis, and empower teams to pinpoint precisely where failures or inefficiencies occur within complex workflows. Together, these observability practices elevate inference evaluation from a passive measurement to an active governance mechanism that’s essential for maintaining reliability, accuracy, and trustworthiness in deployed LLM systems.

## Postprocessing and Output Validation

After the generation phase, outputs typically undergo a *postprocessing* stage, where formatting, cleanup, and structural adjustments prepare the data for delivery to end users or downstream systems. Although this step may seem straightforward, even minor structural errors introduced here can cascade into significant failures throughout the application stack.

Evaluation at the post-processing stage centers on *structural validation*. This involves verifying that the generated outputs conform to expected formats: for instance, ensuring that JSON responses are syntactically valid, adhere strictly to predefined schemas, and include all mandatory fields. This is important, because outputs that appear grammatically correct can still be functionally unusable if key data elements are missing or malformed.

Automated tooling plays a vital role here. *Schema validators* check systematically for structural integrity, while additional automated checks can detect empty completions or other anomalies that could disrupt downstream processing. In high-stakes domains and compliance-critical applications, undetected errors during post-processing risk triggering silent failures or even regulatory breaches, with potentially severe consequences.

By elevating postprocessing to a formal, evaluable stage within the overall system pipeline, teams gain the ability to proactively detect and remediate structural issues before they propagate. This perspective transforms post-processing from a passive formatting step into a critical checkpoint for ensuring output reliability, correctness, and compliance in production LLM deployments.

## Capturing Feedback

Feedback data includes signals like user ratings, thumbs-up/down, direct textual feedback, and implicit behavioral indicators, like engagement duration, query abandonment, and rates of escalation to human agents.

Consistently capturing and integrating this feedback grounds your evaluation firmly in real-world user experience, revealing nuanced gaps and failure modes that static internal benchmarks and offline testing might overlook. Metrics in this stage serve as vital usability indicators that directly inform system refinement priorities. These include *dwell time*, which measures how long users engage with generated content; *abandonment rates*, which signal frustration or dissatisfaction, and *retry frequency*, which can indicate unclear or unhelpful responses.

Evaluation platforms like LangSmith facilitate rubric-driven scoring of outputs, along dimensions like factuality, relevance, and structural correctness. These scores are enriched with metadata, including model versions, prompt variants, and contextual information, enabling fine-grained traceability and longitudinal performance analysis.

As approaches like human-in-the-loop fine-tuning and reward modeling mature, feedback transitions from a passive measurement tool into an active driver of continuous improvement. User signals become training data that dynamically steers model updates and pipeline adjustments, closing the loop between deployment and iteration.

Every stage of the pipeline yields unique and complementary insights into your system’s health. Their real power emerges when these observations are integrated holistically into an end-to-end observability framework. This interconnected visibility is critical for maintaining robust, reliable, and user-centered LLM applications in dynamic production environments.

At its core, observability is an anomaly-detection problem. You’re looking for patterns or deviations from expected behavior in your system’s metrics, logs, traces, and outputs. Like a smoke detector, the goal isn’t to catch every minor issue but to catch the ones that matter before they spread into serious failures. Post-LLM evaluation metrics that you likely set up in training, these observability metrics cover the remainder of the pipeline. You can do this across four stages, each with its own benefits:

Stage 1: Threshold-based alertsThis is the simplest form. Here, you can set explicit limits on key metrics, like API response times over 2 seconds or token counts exceeding 1024. When thresholds are crossed, tools like Prometheus collect the data, and Grafana triggers alerts that notify teams via Slack or issue trackers. It’s straightforward and fast to implement, but may miss complex or evolving issues since the thresholds are static.

Stage 2: Statistical anomaly detectionHere, you move beyond fixed limits by analyzing metric behavior over time using rolling statistics, such as moving averages and z-scores. For example, a sudden spike in latency with a high z-score signals an anomaly worth investigating. Grafana dashboards paired with AlertManager highlight these deviations, and integrating with trace tools like LangSmith helps pinpoint which requests or outputs caused the alert. This method adapts to normal fluctuations, reducing false positives.

Stage 3: Drift detectionThis monitors changes in input data or retrieval quality that can degrade AI performance over time. For instance, if user queries shift or similarity scores in retriever embeddings drop, it’s a sign that data or retrieval may be stale. Using libraries like FAISS for embedding analysis and frameworks like LangChain for pipeline monitoring, you can detect these shifts early. Automated workflows then refresh retrievers or retrain the models, thus keeping the system accurate and relevant.

Stage 4: Feedback Signal MonitoringUser feedback and fallback behaviors provide direct insight into real-world system health. A drop in positive ratings or an increase in fallback (default) responses indicates issues in user experience or model degradation. Tools like LangSmith and MLflow link this feedback to specific model versions and deployments, helping teams diagnose the root cause and decide whether to rollback or retrain.

A robust observability system combines all these four layers. While the following tools mentioned are my general suggestions, feel free to stick with the stack you already have:

-

Prometheus collects runtime metrics (CPU, memory, latency, token usage).

-

Grafana offers real-time dashboards and alerting on thresholds and statistical anomalies.

-

MLflow/ZenML tracks model versions and experiment metadata.

-

LangSmith provides trace-level insights and connects feedback signals to model performance.

My goal here is not to recommend tools but to provide you with some references. Regardless of the tool you choose, or even if you choose to hard-code everything, what matters most is your implementation technique. By layering simple threshold alerts, adaptive statistical methods, drift detection, and user feedback monitoring, you can build a comprehensive pipeline that catches everything from obvious breaches to subtle degradations in AI system health.

# Conclusion

This chapter covered general LLM evaluation metrics and additional considerations for two specific cases: RAG and multi-agent systems. The importance of automatically collecting metrics cannot be overstated. It can mean the difference between having a successful and trusted application and waking up to lots of angry users.

While the chapter has focused on general principles that work regardless of the specific metrics used, it also points to the latest metrics and frameworks available as of the writing of this chapter. Keep in mind that this is a very active area of research. However, while new metrics may be created at any time, the principles will remain the same.

# References

CoreWeave. n.d. [Weights & Biases](https://wandb.ai/site), accessed May 21, 2025.

Es, Shahul, et al. [“Ragas: Automated Evaluation of Retrieval Augmented Generation”](https://oreil.ly/QUyLl), arXiv, April 2025.

Fu, Jinlan, et al. [“GPTScore: Evaluate as You Desire”](https://oreil.ly/ylJna), arXiv, February 2023.

Hendrycks, Dan, et al. [“Measuring Massive Multitask Language Understanding”](https://oreil.ly/0xT-x), arXiv, January 2021.

Honovich, Or, et al. [“TRUE: Re-Evaluating Factual Consistency Evaluation”](https://oreil.ly/UwZvJ), arXiv, May 2022.

LangSmith. n.d. [“Get Started with LangSmith”](https://oreil.ly/F8EVF), accessed May 21, 2025.

Lin, Stephanie, et al. [“TruthfulQA: Measuring How Models Mimic Human Falsehoods”](https://oreil.ly/adQ-N), arXiv, May 2022.

Liu, Yang, et al. [“G-Eval: NLG Evaluation Using GPT-4 with Better Human Alignment”](https://oreil.ly/IzuUL), arXiv, May 2023.

Machan, J. J. n.d. [Ragas](https://oreil.ly/JkFwY), accessed May 21, 2025.

Manakul, Potsawee, et al. [“SelfCheckGPT: Zero-Resource Black-Box Hallucination Detection for Generative Large Language Models”](https://oreil.ly/8AKE9), arXiv, October 2023.

Wang, Alex, et al. [“GLUE: A Multi-Task Benchmark and Analysis Platform for Natural Language Understanding”](https://oreil.ly/rcLR4), arXiv, February 2019.

Wang, Alex, et al. [“SuperGLUE: A Stickier Benchmark for General-Purpose Language Understanding Systems”](https://oreil.ly/mpepc), arXiv, February 2020.

Wei, Jason, et al. [“Chain-of-Thought Prompting Elicits Reasoning in Large Language Models”](https://oreil.ly/YIrYf), arXiv, January 2023.

Zellers, Rowan, et al. [“HellaSwag: Can a Machine Really Finish Your Sentence?”](https://oreil.ly/2VpX9), arXiv, May 2019.

Zhong, Ming, et al. [“Towards a Unified Multi-Dimensional Evaluator for Text Generation”](https://oreil.ly/nMMsh), arXiv, October 2022.
