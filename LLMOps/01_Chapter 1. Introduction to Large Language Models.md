# Chapter 1. Introduction to Large Language Models

The rise in popularity of large language models (LLMs) is no accident; they’re transforming how we interact with technology and pushing the boundaries of what machine learning models can do.

But here’s the catch: while these models are impressive, scaling them up and managing them in production is no walk in the park. The leap from a research project to a fully fledged, reliable tool is filled with obstacles. We’re talking about meeting enormous computational requirements, managing complex data, and ensuring that everything runs smoothly and securely whether you are self-hosting or using proprietary models.

Before we dive into the nitty-gritty of LLM operations, it’s important to understand why and how these models came to be. Knowing their origins and trajectory helps us appreciate the challenges we face when predicting their behaviors in production.

The evolution of LLMs reflects a series of incremental innovations, each addressing specific limitations of previous models. Early models were limited in scope and required extensive human input for even basic tasks. With advancements in architecture, such as the shift from recurrent neural networks (RNNs) to transformers, and the scaling of model sizes, LLMs have become more sophisticated. This evolution has brought about new challenges, such as managing massive amounts of data and ensuring efficient training processes.

So, let’s get into it.

# Some Key Terms

There are three terms we should clarify before going any further:

Foundation models*Foundation models* are advanced ML architectures that serve as the foundational building blocks for creating specialized models. They are pretrained on massive datasets, often consisting of text and recently including other data types such as code, images, audio, and video to develop general language comprehension and pattern recognition capabilities. These models encode statistical relationships and linguistic structures from their training data, forming a robust starting point for further fine-tuning. This fine-tuning tailors the models to specific tasks or applications, such as powering LLMs or other AI-driven solutions.

Large language models*Large language models* are specialized implementations of foundation models that have undergone additional training or fine-tuning to excel in specific language-based tasks. These models are designed to predict and generate human-like text by analyzing and emulating natural language patterns. LLMs are highly versatile, supporting several natural language processing (NLP) applications such as text generation, sentiment analysis, language translation, question answering, and more. Popular use cases include chatbots, content creation, multilingual communication, data analysis, code generation, recommendation systems, and virtual assistants. [“Enterprise Use Cases for LLMs”](https://learning.oreilly.com/library/view/llmops/9781098154196/ch01.html#ch01_enterprise_use_cases_for_llms_1748895465616095) will look at these applications in more detail.

Generative AI models*Generative AI*, or *GenAI*, refers to foundation models that have been trained specifically to generate content (images, text, audio, or video) based on the patterns and information they have learned. Some of the earliest generative AI models were generative adversarial networks (GANs), introduced in 2018; more recently, diffusion models, LLMs, and multimodal models like Gemini have become available. Given their generative nature, LLMs are considered a subset of generative AI models. In the context of LLMs, generative AI can generate text responses, creative stories, product descriptions, and more, based on input and learned patterns.

Confusingly, these three terms are frequently used interchangeably and loosely. For example, a popular image generation model, DALL-E, is better categorized as a generative AI model than as a large language model. Recently, however, the DALL-E image generation functionality has been integrated into the ChatGPT chatbot, one of the most popular LLM applications. Therefore, a user can ask an LLM like ChatGPT to generate images. Over time, the language seems to be evolving toward calling all of these *AI models,* for simplicity.

# Transformer Models

The transformer model, introduced by the paper [“Attention Is All You Need,”](https://oreil.ly/J8MBW) marked one of the biggest shifts in how we approach sequence-based tasks. Transformers have set new standards in how to handle language data.

Before transformers, the most popular solution for NLP tasks was *recurrent neural networks*. RNNs process data sequentially, one step at a time, which makes them suitable for handling time-dependent data such as text. However, this sequential processing introduces a significant drawback: RNNs often struggle to retain information from earlier steps as they move forward in the sequence, especially over long inputs.

During neural network training, the model processes input data and generates predictions. These predictions are compared to the correct answers using a loss function, which calculates the error (how far the predictions are from the correct answers). An algorithm, such as *backpropagation*, calculates *gradients*: values that indicate how the model’s parameters (weights and biases) should be adjusted to reduce the error and improve accuracy.

However, in long sequences like those handled by RNNs, gradients can become very small as they are repeatedly multiplied during backpropagation. Over time, these small values may shrink so much that computers treat them as zero, effectively stopping the model from learning. This issue is known as the *vanishing gradient problem*, and it prevents the model from learning long-term dependencies in the data.

*Transformers*, on the other hand, overcome this limitation by using self-attention and parallel processing, allowing them to handle sequences more efficiently and capture long-range dependencies effectively. Instead of processing data one step at a time, transformers analyze all input tokens (e.g., words in a sentence) simultaneously. *Self-attention* is a mechanism that allows each word or token in a sequence to focus on other words in the same sequence, regardless of their position. This is achieved by calculating a set of attention weights that measure the relevance of each token in the sequence to every other token. For instance, in a sentence, self-attention can help a word like *it* to align itself with its correct reference, even if that reference is several words away. Thus, self-attention allows the model to weigh the importance of each token relative to others in the input, enabling it to capture relationships across the entire input sequence efficiently. This parallel processing not only speeds up computation but also eliminates the issues associated with sequential processing, like the vanishing gradient problem.

Thanks to their ability to manage long-range dependencies and handle vast amounts of data, transformer-based models excel in various NLP tasks, including translation, summarization, and question answering. Their ability to focus on different parts of the sequence regardless of their relative distance, along with positional encoding to retain sequence order, allows transformers to handle long sequences without losing context.

Some people wondered, “Well, since they can be scaled much better now, how about we throw more computing power and a lot more data at these models to see what happens?” Models like GPT-3, LLaMA, and their successors demonstrated that increasing the number of parameters can significantly improve the performance of transformer models.

Transformers have extended their influence beyond NLP into image processing with innovations like the *vision transformer* (ViT), which treats image patches as sequences and applies transformer models to them. ViT has shown promising results in image classification, offering a viable alternative to the previous solution, convolutional neural networks (CNNs). Additionally, in recommender systems, transformers’ ability to model complex patterns and dependencies enhances accuracy and personalization. [Table 1-1](https://learning.oreilly.com/library/view/llmops/9781098154196/ch01.html#ch01_table_1_1748895465606161) compares the abilities of the neural network models we’ve discussed.

|   | CNNs | RNNs | Transformers |
| --- | --- | --- | --- |
| Application | <br>			Best suited for spatial-based tasks (e.g., images)<br> | <br>			Well suited for sequence-based tasks (e.g., NLP)<br> | <br>			Well suited for capturing all three modalities: images, NLP, and speech<br> |
| Computation | <br>			Highly parallelizable input processing<br> | <br>			Sequential processing<br> | <br>			Parallel processing of inputs<br> |
| Performance on language-specific tasks | <br>			Need large number of stacked convolution blocks for handling long-range dependencies<br> | <br>			Can handle long-range dependencies much better than CNNs but can handle the dependencies well only to a given length<br> | <br>			Can handle long- to very-long-range dependencies much better than other architectures such as RNNs or LSTMs<br> |
| Scalability | <br>			Scalable<br> | <br>			Limited scalability<br> | <br>			Highly scalable<br> |
| Data requirements | <br>			Work well even on small datasets<br> | <br>			Work well even on small datasets<br> | <br>			Don’t work well on small datasets<br> |
| Ease of training | <br>			Easy to train and tune<br> | <br>			Require more tuning than CNNs<br> | <br>			Difficult to train and tune<br> |
| Interpretability | <br>			Easy to debug<br> | <br>			Difficult to debug<br> | <br>			Difficult to debug<br> |
| Deployment | <br>			Easy to deploy<br> | <br>			Easy to deploy<br> | <br>			Difficult to deploy<br> |
| Small edge devices | <br>			Works well on edge devices<br> | <br>			Works well on edge devices<br> | <br>			Limited support for edge devices<br> |
| Explainability | <br>			Supports wide variety of explainability<br> | <br>			Limited explainability<br> | <br>			Very limited explainability<br> |

This trend of throwing more compute and data at transformers is what sparked the evolution of LLMs, as well as the shift from an architecture that can do well on a single modality to one that generalizes on most modalities. Understanding this evolution can help you appreciate the differences in model architectures.

# Large Language Models

LLMs excel at understanding context and making associations among words, phrases, and concepts to provide relevant information based on the input query or prompt. While structured knowledge bases rely on human-curated data, LLMs can automatically extract knowledge from unstructured text. When trained on diverse textual sources, they can process a vast amount of information without explicit human intervention. However, this also introduces a challenge, as the model can learn biased or incorrect information from the training data.

LLMs are also designed to understand and generate human-like text and to be accessible through natural language queries in conversational, interactive settings. This makes them convenient and user-friendly for retrieving information and obtaining responses.

These models are “large” not just because of the amount of data they’re trained on but also because of their number of parameters. Think of *parameters* as being like “knobs” inside the models that may be adjusted during training to help the models learn better. In neural networks, parameters are weights and biases. When an input like a prompt is presented to a model, it first transforms the input into a numerical representation, and then the numbers are processed through the neural network. Each node in the neural network contains a bias, adding or subtracting to the input value, and each connection between nodes contains a weight that will multiply the value of the input as it passes through nodes. Using more parameters greatly extends the capabilities of traditional transformer models, but not without massive trade-offs in cost and evaluation complexity.

There are two basic categories of LLMs, discriminative and generative. *Discriminative models*, such as ​BERT (Bidirectional Encoder Representations from Transformers), which was introduced in 2018, learn the boundary between classes in a classification problem. They’re concerned with the conditional probability *P*(*y*|*x*), which is the probability of the output given the input. Discriminative transformer models are typically used for tasks like text classification, sentiment analysis, and named-entity recognition, where the goal is to predict a label or category given some input ​text.

*Generative models*, such as GPT-3 and GPT-4, learn the joint probability distribution of the input and the output, or *P*(*x*, *y*), and can generate new data points similar to the training data. Generative models are used for tasks like text generation, where the goal is to generate new text similar to the text the model was trained on. Not all LLMs need to be generative, although most are. Throughout this book, when we refer to “LLMs,” we mean generative LLMs.

# LLM Architectures

There are two main types of architecture for language models: encoders and decoders. Encoders and decoders can also be combined, and there is ongoing research on new architectures.

## Encoder-Only LLMs

*Encoder-only models* are designed​ to process and comprehend input text, transforming it into a meaningful representation or embedding. *Embeddings* are numerical representations of data, such as words, phrases, or sentences, in a high-dimensional vector space. Embeddings capture meaning and context in a way that results in words with similar meanings or contexts being placed close together in this vector space. This representation captures the essence of the input, making it suitable for tasks where understanding the context is needed.

One of the most notable examples of an encoder-only model is [BERT](https://oreil.ly/f2AL4). During its pretraining phase, BERT uses *masked language modeling*, a technique where random words in the text are masked and the model learns to predict these masked words based on the surrounding context. BERT is also trained using next-sentence prediction, where it determines whether one sentence follows another ​logically.

The primary advantage of encoder-only models lies in their syntactic understanding of text; i.e., their ability to capture the intricate relationships between words and their contexts. These models excel in tasks such as sentiment analysis, named-entity recognition, and question answering.

However, encoder-only models have their limitations. They are not designed for generating new text; their focus is solely on understanding and analyzing the input. This limitation can be restrictive when using them in applications requiring text generation or completion.

## Decoder-Only LLMs

*Decoder-only models* are good​ at generating coherent and contextually relevant text based on an input or prompt. Examples of this architecture are the generative pretrained transformer (GPT) series, including GPT-2, GPT-3, and the most recent GPT-4.

These models are pretrained using a *language modeling objective*. With this technique, they learn to predict the next word in a sequence given the preceding context, allowing them to generate text that flows naturally and maintains coherence over longer passages.

The key advantage of decoder-only models is their ability to generate high-quality text. This makes them extremely effective for tasks such as text completion, summarization, and creative writing. They also exhibit *emergent properties*, meaning that they can perform tasks beyond their initial training objective, such as translation and question answering, without additional fine-tuning.

However, their focus on text generation can be a limitation in tasks requiring deep understanding of the input text. Decoder-only models generate text based on patterns learned during training, which may not always align with the specific nuances of the input.

## Encoder–Decoder LLMs

*Encoder–decoder models* combine​ the strengths of both encoder and decoder architectures, making them suitable for tasks involving complex mappings between input and output sequences.

In this setup, the encoder processes the input text to create an embedding, which the decoder then uses to generate the output text. Notable examples include Bidirectional and Auto-Regressive Transformer (BART) and Text-To-Text Transfer Transformer (T5). BART, introduced in 2019, is trained using* denoising auto-encoding*, where parts of the input text are corrupted and the model learns to reconstruct the original text.

The encoder–decoder architecture excels at tasks where the input and output are different in structure and length, such as machine translation and text summarization. However, the complexity of training and the computational resources these models require can be a drawback. Their dual architecture means they must effectively integrate both components, which can be demanding in terms of both data and processing power.

## State Space Architectures

A new approach tries to solve one of the problems with transformers, which is that the self-attention mechanism has *quadratic complexity*. This means that the number of computations required for inferencing grows with the square of input size, since the relationship between each pair of tokens needs to be modeled. Mathematically, it is often represented as *O*(*n*2), where *n* is the number of tokens (words or subwords in a sentence). Quadratic complexity is generally a hard computational problem, especially when using larger datasets.

The *state space architecture* replaces the transformer approach by incorporating *state space representations*, which model the state of the system instead of recording it at each step. This compression allows for linear computational complexity, improving computational performance and reducing memory requirements, but it increases the rate of error.

Researchers are trying to solve the error problem. Recent examples are [Mamba and Mamba-2](https://oreil.ly/p3rqX), which create a state representation that dynamically attempts to determine the important parts of the prompt by modeling importance as a state space parameter. In experimental settings, Mamba performs as well as a transformer-based model that has double the number of parameters for small and medium prompts but still has not delivered on the promise of low error rates for larger prompts.

Each LLM architectural design has its own sets of strengths and limitations. Encoder-only models like BERT are highly effective for understanding and analyzing text but fall short in generating new content. Decoder-only models, exemplified by the GPT series, excel in generating coherent and contextually relevant text but are nondeterministic, which can be problematic for some applications like text classification. Emerging architectures like state space models, which promise enhancements in performance and applicability, should be monitored, but they haven’t been proven yet.

## Small Language Models

Another recent development is *small language models* (SLMs), which are compact, efficient language models designed to perform NLP tasks while using fewer computational resources than LLMs.

Unlike LLMs, which contain billions of parameters and require substantial memory and processing power, SLMs are often designed to have millions or even just hundreds of thousands of parameters. The trade-off is that they must focus on specific tasks or subjects. This makes them lightweight, cost-effective, and deployable on a wider range of devices, including mobile phones, IoT edge devices, and in environments with limited computational resources. The development of SLMs has been driven by the demand for efficient, accessible AI solutions that can operate in real time and offline, providing functionality without relying on cloud-based infrastructure.

SLMs do not perform well on tasks that require contextual understanding, extensive memory, or reasoning abilities. They are not intended for more general problem-solving and need to be fine-tuned on specific datasets to perform well on particular tasks, maximizing efficiency while maintaining accuracy within a defined scope. While LLMs tend to perform several NLP tasks reasonably well in a large number of domains, SLMs need to be specifically trained. For instance, an LLM might be able to perform moderately well at summarizing legal documents as well as medical articles, while an SLM would excel in one and perform poorly at the other.

# Choosing an LLM

In the LLM world, it’s easy to get swept up in the excitement of the latest breakthroughs and cutting-edge technologies. New models pop up all the time. The truth is, selecting the right LLM is more than just a technical decision; it’s a strategic choice with far-reaching implications.

## Considerations in the Selection of an LLM

Here are five reasons why the model you choose can make all the difference:

Alignment with objectivesAre you looking for a model that excels at generating human-like text? Or do you need one that can understand complex queries and provide accurate responses? The specific capabilities of different models can vary significantly. Some are designed with a focus on conversational abilities, while others are optimized for tasks like summarization or translation. Choosing a model that aligns with your objectives ensures that you’re investing in a tool that will deliver the results you need.

Performance and efficiencyNot all LLMs are created equal. Larger models might offer impressive performance and efficiency, but they often come with high computational costs and slower response times. Smaller, more optimized models tend to provide faster results and be more cost-effective, but rarely do they match the performance of their larger counterparts.

Training data and biasThe training data used to develop an LLM shapes its behavior and outputs. Variations in the datasets on which models are trained can lead to variations in how they handle specific topics or issues. Some models exhibit biases based on their training data, which can impact the accuracy and fairness of their responses. Choosing a model with a diverse and representative training dataset can help mitigate these risks and ensure more reliable and equitable outcomes.

Customization and adaptabilityYour needs might not fit neatly into the one-size-fits-all approach of a generic LLM. Some models offer greater flexibility and can be fine-tuned or customized to better suit your specific requirements. If that’s what you need, choose one with strong customization capabilities so that you can mold it to better fit your use case.

Integration and supportThe practical aspects of integrating an LLM into your existing systems and workflows cannot be overlooked. Some models come with robust support and documentation, making integration smoother and less time-consuming. Others require more effort to set up and maintain. Considering how well a model integrates with your infrastructure and the level of support available can save you time and reduce headaches over the long run.

Overall, the LLM model you choose is not just a technical decision; it’s a strategic one that impacts the effectiveness, efficiency, and overall success of your AI initiatives. Remember: the model you choose matters. By carefully evaluating your needs and understanding the strengths and limitations of different models, you can make an informed choice that aligns with your goals and sets you up for success.

## The Big Debate: Open Source Versus Proprietary LLMs

Companies must navigate a complex landscape when choosing among open source, closed-source, and open weight LLMs. [Figure 1-1](https://learning.oreilly.com/library/view/llmops/9781098154196/ch01.html#ch01_figure_1_1748895465600862) shows the choices of a sample of companies today. This section looks at each option’s limitations and benefits.

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098154196/files/assets/llmo_0101.png)

###### Figure 1-1. Enterprise adoption of different proprietary LLMs (source: [Andreessen Horowitz](https://oreil.ly/lqXYT))

### Open source and open weight LLMs

Open source and open weight are two types of publicly accessible LLMs that have gained traction in the AI community as of this writing, particularly among those looking to customize, deploy, or study advanced AI without relying on proprietary solutions.

*Open source *LLMs are models with freely available underlying source code. Anyone can inspect, modify, and potentially redistribute the model and its architecture. These models typically include details about the architecture, training methods, and source code for the framework. Using open source models provides technical transparency and adaptability and fosters a community of collaboration. However, open source LLMs may or may not come with pretrained weights, the trained parameters that make the model functional and useful for specific tasks. These weights are the model’s “knowledge” gained from its training on large datasets and are essential for the model to perform effectively without retraining from scratch. Companies that want to take advantage of such models may need to acquire the training data themselves.

With *open weight* LLMs, the weights are publicly accessible. Having access to the weights means that users can directly deploy the model for real-world applications like text generation, summarization, and translation or fine-tune it on their own data. While many open weight models are also open source, some restrict use for commercial applications or require adherence to specific licensing terms, as seen with models like Meta’s Llama series.

The distinction between open source and open weight LLMs is crucial in determining how accessible and useful a model is “out of the box.” Open source models without weights can still allow for architectural experimentation and model-training setups, but they lack immediate functionality for practical applications until they are trained, and training requires substantial computational resources. In contrast, open weight models provide ready-to-use capabilities, making them more accessible to developers who do not have the resources for large-scale model training but want to fine-tune or deploy a pretrained model.

By leveraging open source and/or open weight models such as Llama or Mistral, companies can deploy models on existing hardware. This can be more cost-effective than using cloud-based proprietary solutions, which involve renting hardware. Such an approach can be particularly advantageous for startups or small to medium enterprises (SMEs) operating under tight budget constraints. For these companies, the financial savings can free up resources for other needs, like fine-tuning.

A company may have requirements besides financial concerns, such as wanting to ensure that the training data includes or excludes specific datasets. In these cases, an open weight model is not sufficient; the business really needs an open source model. For example, a company may want to guarantee that a model has never seen a specific data point; an open weight model whose training dataset is not shared can’t offer such a guarantee.

Community support is another potential advantage of open source LLMs. The collaborative nature of the open source ecosystem means that developers, researchers, and organizations continuously contribute to improving these models, and newly fine-tuned models are easily available via Hugging Face. Companies benefit not only from this collective intelligence but also from access to a wider range of resources, tools, and best practices. This community-driven development is dynamic and evolving, and it’s often where new developments begin.

However, the open source/open weight approach is not without its challenges. Maintenance and support can be significant hurdles. Data privacy and security also emerge as big concerns. Transparency can be a double-edged sword, exposing a company to potential risks even as it demands significant effort to safeguard sensitive information and comply with data protection regulations. Ensuring that these models do not become a vector for security breaches requires meticulous attention and proactive measures.

Scalability and performance are additional considerations. Open source LLMs aren’t always optimized for large-scale deployments. Companies with substantial operational demands might face performance bottlenecks or scalability challenges. The customization required to adapt open source models for enterprise-grade applications can be resource intensive and require significant engineering efforts.

Open source and open weight language models also introduce security concerns. Anyone can immediately use, fine-tune, or modify pretrained open weight models and potentially apply them in harmful ways, such as generating misinformation, creating realistic fake content, or deploying automated tools for phishing and social engineering. Since open weight models’ training data often includes both public and proprietary datasets, they can also sometimes unintentionally generate or reveal sensitive or biased information embedded in the training data, posing privacy risks.

Furthermore, open source models, which include the code and architectural blueprints, are vulnerable to manipulation and exploitation. Malicious actors can introduce harmful code or adjust models to bypass safety mechanisms, then distribute these altered versions under the guise of legitimate software. This can lead to scenarios where organizations unknowingly adopt models that include backdoors or biased, harmful outputs. The decentralized nature of open source development means that code modifications don’t always go through rigorous security checks, leaving room for vulnerabilities that could be exploited. Addressing these security challenges requires adopting responsible AI practices, including rigorous code reviews, security audits, and clear usage policies to mitigate risks while promoting open collaboration.

Carefully review any contractual restrictions on usage before adopting a model. You don’t want to build a whole commercial application around an open source LLM only to find out that it does not allow commercial usage.

### Closed-source LLMs

On the other side of the spectrum are *closed-source*, or *proprietary*, LLMs such as those developed by leading tech giants. These models often come with robust support and maintenance, including dedicated assistance for troubleshooting and optimizing performance. This support infrastructure ensures that any issues encountered are addressed promptly, allowing companies to focus on their core activities without getting sidetracked by technical difficulties.

Closed-source LLMs are generally optimized for large-scale deployments, making sure that they can scale with operational loads effectively, so they often come with performance guarantees. Their performance benchmarks often reflect their ability to deliver consistent and reliable results—a critical factor for companies with high operational demands.

One of the primary limitations of the closed-source approach is the high cost. Another is the lack of transparency, which means that companies have limited visibility into the internal workings of these models. While this concern may seem unusual, consider a scenario in which a commercial LLM provider inadvertently consumes private data during training. You use this LLM provider for your own application, and some of your users realize how to get your application to reveal the private data. The people whose data was revealed sue you. We recommend that you fully understand what legal protections are in place when using information services like third-party LLMs.

Regardless of these drawbacks, companies are willing to make expensive bets right now, hoping for excellent returns in the future from investing in GenAI applications.

# Enterprise Use Cases for LLMs

LLMs are transforming enterprise operations in many industries, from changing how we retrieve knowledge to enhancing autonomous agents. They do this through a handful of applications, including knowledge retrieval, translation, audio–speech synthesis, recommender systems, and autonomous agents.

## Knowledge Retrieval

People have long used search engines to discover information, but the limitations of these tools’ have become more apparent as data volumes and complexity grow. LLMs offer a new paradigm for accessing and using information. Unlike conventional systems, which rely heavily on keyword matching and ranking algorithms, LLMs bring a conversational, personalized approach to information retrieval.

Users can engage in long conversations with LLMs. Instead of simply receiving a list of links or documents, they can set parameters for the tone, intent, and structure of the information they need. This capability transforms the search experience from a transactional process into a dynamic dialogue. For example, an LLM can interpret a request like “Explain this concept as if I were a beginner,” and provide a tailored explanation that’s both accessible and relevant.

On the data retrieval side, LLMs can enhance productivity tools, for example through integrations with office software suites like those from Google and Microsoft. Imagine querying a spreadsheet with natural language to extract insights or asking a document to summarize key points. This simplifies data management and makes complex information more accessible. Furthermore, LLMs can integrate with internal systems to automate routine tasks and create knowledge graphs, streamlining workflows and enhancing organizational efficiency. However, while LLMs improve the accuracy and relevance of information retrieval, they also require meticulous handling to ensure data privacy and system security.

## Translation

Translation is another domain where LLMs are being used heavily. Traditional machine translation systems often struggled with languages for which they had limited datasets, as they had to rely on statistical methods. LLMs are changing this by offering zero-shot and few-shot translation capabilities. *Zero-shot *refers to the model’s ability to translate languages without prior examples, a feat that was previously challenging. *Few-shot*, on the other hand, allows LLMs to perform well with minimal data.

This is particularly advantageous for translating languages that are underrepresented in training datasets. For companies involved in global operations or content creation, this is a major selling point. It eases localization of content, such as subtitling films or translating marketing materials, without extensive data requirements, allowing companies to expand into new markets without investing too many resources up front.

LLMs trained on multilingual datasets can easily adapt to new languages, allowing translations across a broader spectrum of languages, including those with sparse resources. The applications for this extend to literature, film, and even real-time communication, where accurate and contextually appropriate translation can be helpful.

Yet, while LLMs offer significant improvements over traditional translation methods, maintaining accuracy and handling idioms still remain open challenges.

## Speech Synthesis

The ability to generate speech that resonates with human listeners can significantly enhance user experience and interaction.* Speech synthesis*, generating audio that mimics human speech from text, is another area where LLMs are making remarkable progress. Historically, speech synthesis systems have struggled with creating natural and engaging audio outputs: the sound generated sounded clearly “robotic.” LLMs, however, have the potential to revolutionize this field by generating human-like speech with impressive fidelity. With training on text and audio datasets, LLMs can understand and replicate the subtleties of human speech, such as intonation, rhythm, and stress.

This is useful for applications like virtual assistants, realistic voice-overs for characters in video games, or engaging audio content for educational materials. Using LLMs to automate the creation of speech content makes it easy for businesses to produce large volumes of content without the time and costs of extensive manual recording. However, audio–speech synthesis still has room to improve, especially with regard to recognizing accents and other variations in speech.

## Recommender Systems

Recommender systems are at the heart of many digital platforms, from ecommerce to streaming services. LLMs enhance these systems by incorporating a deeper understanding of users’ preferences and contextual factors. Earlier recommender systems relied on historical user data and predefined algorithms, which often led to limited or repetitive suggestions. LLMs, with their ability to process and interpret diverse data sources, offer a more nuanced approach.

LLM-powered recommender systems can analyze user interactions, preferences, and even conversational cues, including audio and video inputs, to deliver personalized recommendations in real time. For example, if a user describes a product in natural language and provides an image, the LLM can integrate both modalities to offer more relevant suggestions, even in response to ambiguous or vague requests.

Despite these advantages, many challenges remain unsolved. For example, maintaining user trust requires careful attention to the model’s transparency and reasoning.

## Autonomous AI Agents

*AI agents* are designed to perform specific tasks autonomously, leveraging LLMs to execute complex operations that would otherwise require human intervention.

For example, in a customer service environment, traditional automated agent systems might follow rigid scripts or rely on basic rule-based logic. LLM-powered AI agents, however, can engage in dynamic, context-aware conversations. They understand user queries more deeply, interpret intent more accurately, and generate responses that are more natural and engaging.

In project management, LLMs can power intelligent project assistants that manage schedules, set reminders, and even draft project reports. These AI agents can interact with team members, understand project requirements, and adapt their responses to ongoing developments.

## Agentic Systems

*Agentic systems* represent a more novel application of LLMs, where AI agents not only perform tasks but also make strategic decisions. These systems leverage LLMs’ data processing and analysis capabilities to discern patterns and make informed decisions in real time. This is particularly helpful in environments where decisions need to be based on complex, multifaceted information (as shown by the example workflow in [Figure 1-2](https://learning.oreilly.com/library/view/llmops/9781098154196/ch01.html#ch01_figure_2_1748895465600898)).

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098154196/files/assets/llmo_0102.png)

###### Figure 1-2. Agentic AI in the enterprise (source: [Haptik](https://oreil.ly/NapOi))

In finance, agentic systems can digest data from financial reports, news articles, and market analytics, then use it to analyze market trends, assess risk factors, and make investment recommendations that align with investment strategies.

Similarly, in supply chain management, agentic systems can optimize inventory levels, predict demand fluctuations, and coordinate logistics based on data from various sources—such as sales forecasts, supply chain disruptions, and production schedules.

However, these systems aren’t always reliable. Integrating them into existing workflows requires careful planning. Companies must consider how AI agents and agentic systems will interact with human teams, how they will be managed, and how their outputs will be monitored. Clear guidelines and oversight mechanisms are essential to ensure that these systems complement rather than disrupt existing operations. These issues are discussed in [Chapter 8](https://learning.oreilly.com/library/view/llmops/9781098154196/ch08.html#ch08_governance_monitoring_privacy_and_security_1748896766177413).

Data security and privacy are also big concerns. LLMs handle vast amounts of sensitive information, and protecting it from breaches or misuse is key. You need to establish strong data governance policies and invest in security measures to safeguard against potential risks. These issues, too, are discussed in [Chapter 8](https://learning.oreilly.com/library/view/llmops/9781098154196/ch08.html#ch08_governance_monitoring_privacy_and_security_1748896766177413).

# Ten Challenges of Building with LLMs

LLMs introduce several new challenges, which can be amplified by the enormous scale of LLMs and their numerous applications. Addressing these challenges is important for integrating and deploying LLMs in production. Following is a list of 10 challenges with pointers to the chapters in this book where they are addressed.

## 1. Size and Complexity

LLMs generally have millions or even billions of parameters. This makes training, monitoring, and evaluating them extremely complex. Moreover, being generative models, they can fail silently, producing hallucinations and inaccurate information. Addressing this requires a structured approach that not only includes benchmarks commonly used for machine learning but also adds several other techniques; [Chapter 7](https://learning.oreilly.com/library/view/llmops/9781098154196/ch07.html#ch07_evaluation_for_llms_1748896751667823) explores this topic further.

## 2. Training Scale and Duration

Training LLMs requires processing large datasets. This is difficult not only from the data management perspective but also in terms of the memory and computational resources required for training the models. We discuss this in [Chapter 3](https://learning.oreilly.com/library/view/llmops/9781098154196/ch03.html#ch03_llm_based_applications_1748895493844515).

Training LLMs can take days, weeks, or even months, and managing parallel and distributed training across large clusters of GPUs and TPUs requires specialized hardware and organizational skills. This means that hardware represents a major dependency on external organizations and market availability, one that requires careful, systematic planning. We discuss this in [Chapter 9](https://learning.oreilly.com/library/view/llmops/9781098154196/ch09.html#ch09_scaling_hardware_infrastructure_and_resource_ma_1748896826216961).

Handling large, potentially sensitive training datasets requires careful security measures and anonymization, as discussed in [Chapter 2](https://learning.oreilly.com/library/view/llmops/9781098154196/ch02.html#ch02_introduction_to_llmops_1748895480208948).

## 3. Prompt Engineering

One of the most common ways to make an LLM work better for a specific problem is prompt engineering, the science and art of crafting the text inputs that are sent to the models. Prompt updates can significantly improve or degrade the user experience. But prompt engineering is iterative and can be difficult to master and document, especially with closed-source LLMs. You’ll find a discussion of this in [Chapter 5](https://learning.oreilly.com/library/view/llmops/9781098154196/ch05.html#ch05_model_domain_adaptation_for_llm_based_applications_1748896666813361).

Updates of proprietary models, like OpenAI’s GPT-4, can result in significant *model drift*, where the same inputs suddenly provide a different output due to a model update. Model drift requires effort and financial commitment to fix. This becomes additionally complex when there are many interdependent prompts connected to each other, such as in an *orchestration framework* (i.e., a structured platform used to automate, coordinate, and manage complex tasks and services) and there’s a change in the underlying model, as the entire complex prompt chain can break in unexpected and hard-to-detect ways. If your infrastructure relies heavily on prompt-engineering pipelines, monitoring is crucial; [Chapter 7](https://learning.oreilly.com/library/view/llmops/9781098154196/ch07.html#ch07_evaluation_for_llms_1748896751667823) goes into this in more depth.

## 4. Inference Latency and Throughput

Responses provided by LLMs are also called *inferences*. LLMs are often deployed in applications that require real-time or near-real-time responses, which means that optimizing for speed becomes important. This can be especially complex with dynamic models like LLMs. Also, maintaining high throughput without having access to model parameters can add complexity for LLMOps teams. Edge devices used in IoT applications introduce even more challenges related to limited computational resources and varying network conditions. These issues are discussed in [Chapter 9](https://learning.oreilly.com/library/view/llmops/9781098154196/ch09.html#ch09_scaling_hardware_infrastructure_and_resource_ma_1748896826216961).

## 5. Ethical Considerations

Like any other machine learning model, LLMs generate outputs based on the data that they have been trained on. LLMs applications are frequently designed to create the experience of chatting with a human instead of a machine, making them accessible to a much larger user base than specialized machine learning systems and greatly increasing the impact of potential biases introduced by the training data.

[Chapter 7](https://learning.oreilly.com/library/view/llmops/9781098154196/ch07.html#ch07_evaluation_for_llms_1748896751667823) discusses techniques for monitoring LLM outputs, and the privacy and ethical implications of their use are explained in [Chapter 8](https://learning.oreilly.com/library/view/llmops/9781098154196/ch08.html#ch08_governance_monitoring_privacy_and_security_1748896766177413).

## 6. Resource Scaling and Orchestration

The scale at which LLMs operate often requires load balancing and dynamic resource scaling. Different proprietary models can also behave very differently based on the use case, and constant scenario modeling is expensive and time intensive. [Chapter 5](https://learning.oreilly.com/library/view/llmops/9781098154196/ch05.html#ch05_model_domain_adaptation_for_llm_based_applications_1748896666813361) explores how to manage dependencies across various components in distributed multi-model environments, ensuring reliability and scalability.

## 7. Integrations and Toolkits

LLMs require several new integrations and toolkits that are adapted to both generative as well as discriminative use cases and involve communicating with various APIs. Integrating these LLMs into existing systems requires robust security protocols to prevent vulnerabilities and potential misuse. Changes in LLMs and version management, discussed in [Chapter 8](https://learning.oreilly.com/library/view/llmops/9781098154196/ch08.html#ch08_governance_monitoring_privacy_and_security_1748896766177413), can also lead to compatibility issues across the stack.

## 8. Broad Applicability

LLMs are adaptable and easy to use, which means that they can be applied to numerous consumer-facing applications, as we will see in [Chapter 3](https://learning.oreilly.com/library/view/llmops/9781098154196/ch03.html#ch03_llm_based_applications_1748895493844515). This makes them more likely to be exposed to untested scenarios than traditional machine learning systems, and thus they require a faster feedback loop to monitor and improve their performance. [Chapter 7](https://learning.oreilly.com/library/view/llmops/9781098154196/ch07.html#ch07_evaluation_for_llms_1748896751667823) addresses monitoring techniques.

## 9. Privacy and Security

Collecting real-time information involves handling user data, sometimes including personally identifying information (PII). This means that security and privacy become the cornerstone of maintaining trust and regulatory compliance. This challenge extends well beyond inference monitoring, touching the domain of cybersecurity.

Even companies such as OpenAI have [received reports about database leaks](https://oreil.ly/yqPpG) into user accounts that made chat interactions visible to unauthorized users. We talk more about privacy and security in [Chapter 8](https://learning.oreilly.com/library/view/llmops/9781098154196/ch08.html#ch08_governance_monitoring_privacy_and_security_1748896766177413).

Regularly auditing your data management processes, both internally and externally, is also vital for enhancing user trust and complying with legal requirements. Best practices for data management are discussed in [Chapter 4](https://learning.oreilly.com/library/view/llmops/9781098154196/ch04.html#ch04_data_engineering_for_llms_1748895507364914).

## 10. Costs

One of the biggest considerations for LLMs is cost, both immediate and long-term. While most transformer models require expensive training, maintaining and scaling LLMs incurs the highest costs, especially in the inference stages. You could end up paying even for failed requests, so experimenting with model performance can become very expensive very quickly for companies building on closed and proprietary models.

Even in open source models, excessive fine-tuning can quickly lead to a phenomenon called *overfitting*, where the model appears to perform extremely well because it learns the training dataset but does not generalize to the unseen data that will be presented to it by real users. There are always trade-offs between generalization ability and cost; these are explored in [Chapter 5](https://learning.oreilly.com/library/view/llmops/9781098154196/ch05.html#ch05_model_domain_adaptation_for_llm_based_applications_1748896666813361).

# Conclusion

Adopting LLMs requires careful consideration and strategic planning to navigate these intricate challenges, and organizations require a new discipline and a set of new tools to succeed. We call this discipline LLMOps, and we start our journey by defining it in the next ​chapter.

# References

Dao, Tri, and Albert Gu. [“Transformers Are SSMs: Generalized Models and Efficient Algorithms Through Structured State Space Duality”](https://oreil.ly/POlHU), arXiv, May 31, 2024.

Devlin, Jacob, et al. [“BERT: Pre-Training of Deep Bidirectional Transformers for Language Understanding”](https://oreil.ly/84NM2), arXiv, May 24, 2019.

Haptik. n.d. [“A Comprehensive Guide to Agentic AI”](https://oreil.ly/CO7uA), Accessed May 21, 2025.

OpenAI. [“March 20 ChatGPT Outage: Here’s What Happened”](https://oreil.ly/5kdkr), March 24, 2023.

Vaswani, Ashish, et al. “Attention Is All You Need”, In [NIPS’17: Proceedings of the 31st International Conference on Neural Information Processing Systems](https://oreil.ly/hfTxe), edited by Ulrike von Luxburg, Isabelle Guyon, Samy Bengio, Hanna Wallach, and Rob Fergus (Curran Associates, 2017).

Wang, Sarah, and Shangda Xu. [“16 Changes to the Way Enterprises Are Building and Buying Generative AI”](https://oreil.ly/yRrmR), Andreessen Horowitz, March 21, 2024.
