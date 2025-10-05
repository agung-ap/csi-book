# Chapter 3. LLM-Based Applications

As of early 2025, only a few companies offer large multimodal models that can understand and generate text, images, and other media, like sound and video. For brevity, we will call these AI models. The most well-known examples are the GPT models created by OpenAI, but a few other popular examples are the Gemini models created by Google, the Claude Sonnet and Haiku models created by Anthropic, and the Llama models created by Meta.

In many cases, these companies partner with other companies to offer these models as a cloud service. For example, OpenAI has a partnership with Microsoft, which provides the infrastructure to host OpenAI’s models in cloud services that can be accessed via APIs. Other companies, like Meta, provide a model snapshot, a large binary file containing the weights of a pretrained model, which users can install in their own infrastructure. This infrastructure can be “bare metal,” meaning physical machines the companies own, or cloud infrastructure they purchase from other providers.

Model-building companies also offer user-facing applications. In many cases, the name of the model and the name of the user-facing application are the same or very similar, making it easy to confuse the two. For example, the Google Gemini application uses the Google Gemini model, and the Claude application uses the Anthropic Claude Sonnet and Haiku models. OpenAI’s names are slightly different: its user-facing application, ChatGPT, allows users to interact with the GPT-4o and GPT-4o-mini models.

These applications can have different levels of sophistication. The simplest type of application is a chat-like web interface that allows users to send prompts directly to the model and returns the response. These days, most of the applications provided by large companies are more sophisticated than that. Instead of simply passing prompts directly, they add several layers of their own instructions to the user input, keep track of what the user asked earlier in that conversation (and sometimes in previous sessions), modify the user-submitted prompt to increase the chance of getting a better response, and ensure that their answers are safe and polite.

Given these additional prompts and safeguards, users get different answers when interacting with models through the API and through the default web application. For example, when a user is interacting with ChatGPT on the web through chatgpt.com, they are likely to get different answers than if they were to submit the same prompt directly to the model using an API. The answer from ChatGPT may use data from previous chats and will add some additional safeguards and instructions to the user-provided prompt. For example, when you ask a question using ChatGPT’s website, it now usually finishes the response with a question inviting the user to continue the conversation, like “Would you like to explore more?” If you use the model directly from the API, it will not include this conversational phrase.

Companies don’t have to develop and train an AI model in order to create an application that uses AI. They can license and integrate existing models such as Gemini, Claude, or GPT-4o into their user-facing applications. Since 2023, a large proportion of repositories in GitHub have been importing code that allows use of the OpenAI APIs, indicating that many developers are using the GPT cloud services to add AI features to their own applications, as shown in [Figure 3-1](https://learning.oreilly.com/library/view/llmops/9781098154196/ch03.html#ch03_figure_1_1748895493826708).

This chapter discusses the operational considerations for using AI models in user-facing applications.

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098154196/files/assets/llmo_0301.png)

###### Figure 3-1. Generative AI growth (source: [Microsoft | AI for Good Lab](https://oreil.ly/NJnTq))

# Using AI Models in Applications

Many application tasks that were formerly assisted by automation and machine learning are now using AI models. The difference between implementing automation yourself and using a foundation model is subtle but consequential, especially for LLMOps.

Before machine learning and foundation models, if you wanted to automate a task, you would need to code it yourself, programming all the possible inputs and corresponding outputs for the application. In the last decade, a lot of this automation code could be replaced by training a model using machine learning. When a new input was submitted, the ML model would generate an appropriate output, even if that input was not explicitly programmed or previously seen by the model.

Here are some examples of popular consumer-facing applications that incorporate third-party foundation models:

BeMyEyesThis [OpenAI application](https://oreil.ly/YxiJF) helps people who are blind or have low vision to navigate the world better by using their phones. They can point their phone cameras at things and hear rich descriptions. They can use the app to count money, to identify products in the supermarket, and to assist with using automated teller machines. They can even point the app at their computer screens to get technical support.

DuolingoThis foreign language–learning application [uses LLMs to create lessons](https://oreil.ly/CNNpM) faster and with more variety. The models are used to generate more versions of dialogues that adhere to difficulty standards, making lessons less repetitive and more enjoyable.

Khan AcademyThis educational website is used by hundreds of millions of people to learn academic subjects, mainly those taught in grades K–12. Khan Academy offers [Khanmigo](https://oreil.ly/bM6vS) (a portmanteau of *Khan* and *amigo*, Spanish and Portuguese for “friend”), which serves as a study buddy and personal tutor. Students can ask Khanmigo questions about careers and why the lesson they’re taking is useful for their lives (a favorite question among teenagers: “Ugh, why do I have to learn *this?*”). Khanmigo can also generate quizzes to assess learning, provide feedback on the student’s writing and answers, and generally help a student without providing the answers directly.

Microsoft CopilotThe [Copilot stack](https://oreil.ly/julAQ) accounts for perhaps the widest deployment of AI to date. Available in several popular Microsoft products, including Office, Windows, and Bing, the Copilot products help users accomplish common tasks quicker. For example, you can open Word and ask Copilot to “write a letter to Bank of America asking to close my checking account.” A letter automatically populates with the appropriate language, and you just need to fill in a few blanks. Another frequently used example is converting Word documents to PowerPoint presentations and vice versa.

# Build Versus Buy

When using an AI model in your application, one of the main decisions is whether to build your own model from scratch, start from a model and improve it through fine-tuning and/or prompt engineering, or simply use an existing model out of the box. The considerations for this decision are covered in [Chapter 1](https://learning.oreilly.com/library/view/llmops/9781098154196/ch01.html#ch01_introduction_to_large_language_models_1748895465615150). This chapter assumes that the decision has already been made and you already have one or more models ready to use in your application.

# Infrastructure Applications

While the first wave of LLM applications was mostly focused on user-facing tools for tasks like writing and summarization, the current wave of LLM-based applications is largely focused on infrastructure applications that make LLMs faster, more programmable, and more modular. They redefine what an LLM is and how it can be used. LLM applications are no longer limited to chatbots: they have become a new layer of code in software applications. (This is what we referred to as *Software 3.0* in [Chapter 2](https://learning.oreilly.com/library/view/llmops/9781098154196/ch02.html#ch02_introduction_to_llmops_1748895480208948).) Let’s look at some of these uses, one by one.

## Agentic Workflows

A single prompt can take you far. But for anything beyond a surface-level task, you need more than one-shot queries. You need memory. You need planning. You need tools. And eventually, you need agents that can *act*—not just complete a prompt but *choose* what to do next. This is where the shift from language models to agentic systems comes in.

At its core, an agent is just a loop. It observes, decides, and acts—over and over. Those acts might be to read an instruction, check its current state, fetch a resource, call a tool, or break a task into smaller ones. Each of those actions requires reasoning, and each decision affects what happens next. In an agentic system, the model is no longer passive. It’s running code, managing steps, and adapting as it goes.

This approach unlocks more complex workflows. Instead of a user stitching together model calls by hand, an agent handles the logic. It can retry failures, store intermediate state, track objectives, and even call other agents. This isn’t prompt engineering anymore—it’s system design.

Not all agents operate the same way. Some follow a fixed plan; others adapt in real time. Some agents think once, act once, and stop. Others operate in loops, revisiting goals and shifting strategy as needed. Understanding these differences helps in designing systems that are robust, interpretable, and efficient. Major types of agents include:

Single-step agentsThe simplest form of an agent is little more than a wrapped prompt. It takes an input, does some local reasoning, returns an output, and exits. There’s no memory, no iteration, no feedback loop. These are useful when the task is bounded, like generating a SQL query, converting a paragraph to a tweet, or answering a direct question. But single-step agents are brittle. They assume everything is known up front. They can’t handle surprises or partial failures. You’ll quickly outgrow them when tasks involve multiple actions or require state tracking.

Chain-of-thought agentsHere, the agent reasons step-by-step—often in the same prompt. Instead of jumping straight to the answer, it explains its logic first. This internal decomposition improves reasoning and often leads to better performance on multi-hop problems. However, the limitation is clear: it’s still all happening within a single model call. There’s no memory of what was done before. If the chain is too long or the context window too short, the agent breaks.

Plan-and-act agentsThis is where things get more interesting. These agents first generate a high-level plan, then execute it step-by-step. For example, if you tasked a plan-and-ask agent with writing a blog post, it would start by drafting an outline. Then it would write each section separately, check for coherence, and edit the result. The planning and acting can happen in the same model or across separate agents. This structure introduces what has been done, what’s left, and where things went wrong. It also allows for retries and self-correction. If a step fails, the agent can replan or fall back to an alternative.

Reflective or self-improving agentsThese agents don’t just act—they reflect on their performance. After completing a task, they might score their own output, compare it with a ground truth, or even consult another model to improve their reasoning. This creates a feedback loop where the agent learns from its past actions—not in the ML training sense but in the runtime sense. Reflection is costly but powerful. It adds robustness, especially in open-ended domains where correctness is hard to define in advance.

Recursive decomposition agentsIn this pattern, an agent tackles a task by recursively breaking it down. It might see a top-level goal, decide it’s too big, and generate subtasks. It then becomes a manager—delegating each subtask to a new instance of itself or to other specialized agents. This pattern is used in systems like AutoGPT and BabyAGI. It allows for dynamic depth: tasks get decomposed until they’re small enough to solve directly. The challenge is keeping the recursion from spiraling out of control, especially in the absence of tight constraints or time limits.

Multi-agent collaboratorsRather than using recursion, some systems *distribute* responsibility: one agent writes, another edits. One gathers data, another analyzes it. These agents have defined roles, often with isolated tools and memories. Communication happens through shared messages or task queues.

This is effective when tasks are parallelizable or when each agent has domain-specific expertise. It also forces clear interfaces: each agent must expose how to talk to it and what kind of input it expects.

Each of these patterns serves a different purpose. Some are simple, designed for speed. Others are more expressive, built for complexity. As models improve and infrastructure grows, we’ll see these workflows combine—agents that reflect and recurse in combination with systems that plan, act, and then hand off to a team. As these systems scale, coordination becomes the challenge. One agent might specialize in math. Another might handle API queries. A third might focus on summarization.

Instead of building a single monolithic agent that does everything, it makes more sense to compose smaller, focused agents that work together. This is where multi-agent systems enter. A* multi-agent system* isn’t just a collection of bots. It’s an architecture in which each agent operates semi-independently, often with its own tools, memory, and goals. The agents talk, delegate, and collaborate. For instance, one agent might take a user request and break it into subgoals. Another might execute a subtask and pass the result back. Over time, agents can even evolve internal protocols—figuring out how best to share information or resolve conflicts.

Designing these workflows is not trivial. The more agents you add, the more coordination overhead you introduce. You have to define roles, communication boundaries, and fallback plans. You need logging, observability, and memory management. You also need clarity around failure; for example, what happens when one agent goes silent or another returns an error?

That’s why agentic design is not just about the model—it requires* control flow*. What decisions should happen inside the model versus outside of it? What should be handled by logic, and what should be learned? These are architectural questions, not just engineering ones.

As of now, we’re still early in this transition. The industry is moving from LLMs as isolated prompt responders toward full-blown systems that can think in steps, delegate across agents, and operate over time. To make this possible, it needs shared protocols like MCP and A2A, which we discuss next. These protocols provide conventions that let agents talk, reason, and act as a ​team.

## Model Context Protocol

There is a quiet shift happening in how we build intelligent systems today. In the early days of language models, most applications were monoliths—self-contained, brittle, and tightly coupled to the tools they used. Every integration was handcrafted. If a model needed to talk to a database, spreadsheet, calendar, or code repository, someone had to write a custom connection for each pairing. As the number of models and tools grew, the web of integrations became unmanageable.

What emerged out of that chaos was a new design principle—simple, but transformative. Instead of trying to make every tool speak the model’s language or forcing every model to understand every tool, AI engineers split the problem, giving each part a role. That principle now lives in the form of the *Model Context Protocol* (MCP), [first introduced by Anthropic](https://oreil.ly/MLp_L) in late 2024 ([Figure 3-2](https://learning.oreilly.com/library/view/llmops/9781098154196/ch03.html#ch03_figure_2_1748895493826745)).

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098154196/files/assets/llmo_0302.png)

###### Figure 3-2. Model Context Protocol (source: [Phil Schmid](https://oreil.ly/SqaNo))

At its core, MCP is a contract among three moving parts. First, there’s the *host*—your AI application, like a desktop assistant or a chatbot. Then there’s the *server*—any external system or tool that exposes capabilities to the model. Finally, the *client* is the messenger that connects the two. What makes MCP powerful is not just that it splits the parts cleanly but that it gives them a common language; i.e., a standard way to describe what they can do, what they know, and what they can provide to the model.

With MCP, a model no longer has to guess what’s possible. Instead, it can discover tools, query data sources, and select prompts—all in real time, all through a shared protocol. This means a model doesn’t just generate responses; it acts, it calls tools, it gathers context, and it learns how to interact with the outside world in a modular, controlled way.

In practice, working with MCP feels less like magic and more like plumbing. You can plug in a GitHub integration, a Slack connector, or a calendar interface, and the model can learn to use it—without needing a new integration each time. Each server exposes tools and resources. The client mediates. The host orchestrates. And the model flows through it all, aware of the tools at its disposal.

### MCP components

At the time of writing, MCP defines three key components that external systems can expose:

ToolsThese model-controlled functions are callable operations that the language model can invoke during a session. Think of tools as function endpoints—when a model determines that it needs to take an action, such as retrieving a document, querying an API, or triggering a workflow, it does so by calling a tool. Tools are defined with a clear input/output schema and are registered with the host application at runtime.

ResourcesThese application-controlled data endpoints are read-only data sources that the model can reference to enrich its context. Unlike tools, resources do not execute logic. Instead, they expose structured data—such as a list of files, user profiles, or metadata—that the model can access via lookups. These are useful when the application wants to give the model direct access to information that doesn’t require active computation or external side effects.

PromptsThese user-controlled templates are pre-engineered prompt structures that can be presented to the model as part of the context or decision-making path. Prompts help guide the model’s behavior using predefined instructions, formats, or strategies. They can encapsulate common workflows or suggest best practices for using tools and resources effectively.

This is the new system architecture design for Software 3.0. It’s how we move from fragile, one-off agents to systems that scale. With MCP, you can build once and use what you build everywhere. The protocol acts like a universal adapter, abstracting away the messy details of each tool and giving the model a consistent way to act.

### MCP implementation

Now, let’s look into how MCP works. MCP is implemented as a client–server protocol. The host application—which could be a desktop assistant, IDE plugin, or custom agent—runs one or more MCP clients. Each client establishes a one-to-one connection with an *MCP server*, which is an external system exposing tools, resources, and prompts.

The protocol begins with a* handshake phase*, where the client and server exchange version and capability metadata. This ensures compatibility and allows the client to dynamically understand what the server offers.

Once the connection is established, the *discovery phase* begins. The client queries the server to enumerate all available tools, resources, and prompts. The server responds with structured metadata that the client can then serialize and expose to the model through the host application.

During the *interaction phase*, when a model identifies a need to call a tool, it emits a structured function call (using JSON or a similar schema). The host routes this request through the client to the server, which executes the tool logic and returns the result. The host application can then inject the output back into the model’s context, allowing the LLM to incorporate external data into its next reasoning step.

The same pattern applies for resource lookups—the model can request a resource by ID or query, and the host will retrieve the data from the MCP server via the client. Similarly, when using prompts, the host can offer predefined templates to the model based on the MCP server’s response during discovery.

All of this happens asynchronously and incrementally. The model doesn’t need to preload every tool or piece of data. It queries what it needs in real time, based on the evolving conversation or task state. This architecture introduces a high degree of modularity. A single host can connect to multiple MCP servers simultaneously. Each server needs to implement the protocol only once, and it becomes compatible with any number of model-based clients or applications that follow ​MCP.

### Example MCP project

Here is a quick example of how to build a simple server with Python to fetch weather data using MCP. This code connects to an MCP server running a weather data service. It sends a request for weather data about Lisbon, Portugal, including temperature in Celsius. It lists available resources and tools on the server. It calls a tool (`weather-tool`) to fetch the weather data. Optionally, it reads a file resource containing a weather report. Finally, it prints out the weather data received from the server:

Step 1: Set up the server parametersFirst, define the parameters required to connect to the MCP server, including the executable, server script, and any optional environment variables:

```
server_params = StdioServerParameters(
    command="python",  # Executable
    args=["weather_server.py"],  # Your new weather data server script
    env=None,  # Optional environment variables
)
```

Step 2: Define sampling callbackCreate an optional callback function that handles incoming data from the server. In this case, it processes weather-related messages:

```
async def handle_sampling_message(message):
    print(f"Received weather data: {message}")
```

Step 3: Establish a connection to the serverHere we use `stdio_client` to connect to the MCP server:

```
async with stdio_client(server_params) as (read, write):
    async with ClientSession(
        read, write, sampling_callback=handle_sampling_message
    ) as session:
```

This code has `stdio_client(server_params)` open a connection to the MCP server using the parameters you defined earlier. It returns two objects, `read` and `write`, which are the communication channels for reading from and writing to the server. `ClientSession` is used to ​create a session that will handle all communication with the server. It is passed the `read` and `write` channels and the `sampling_callback` function to process messages from the server.

Finally, `async with`* *ensures that the connection is automatically closed once the block of code is done executing.

Step 4: Initialize the sessionThis line initializes the session, setting up necessary configurations or authentication with the server. It must be called before performing any actions like listing prompts or using tools:

```
await session.initialize()
```

Step 5: List the available promptsYou can request a list of available prompts from the server. In this case, you need to retrieve a specific prompt from the server, passing any required arguments, such as a city name for the weather data:

```
prompt = await session.get_prompt(
    "weather-prompt", arguments={"city": "Lisbon"}
)
```

Step 6: List the available resources and toolsNext, you need to fetch two lists from the server: one of available resources and one of available tools. *Resources* might include files, API keys, or data that the server can access. *Tools* are functions or services that the server can call to perform specific tasks, like fetching weather data:

```
resources = await session.list_resources()
tools = await session.list_tools()
```

Step 7: Call a toolThis will call a specific tool on the server, again passing any necessary arguments (city name, temperature units). The tool will process the request and return the result:

```
weather_data = await session.call_tool(
    "weather-tool", arguments={"city": "Lisbon", "unit": "Celsius"}
)
```

Optionally, you can also fetch and read a resource from the ​server:

```
content, mime_type = await 
session.read_resource(
    "file://weather_reports/lisbon_report.pdf"
)
preview = content[:100]
print(f"Downloaded content preview: 
{preview}...")
```

Step 8: Display the resultPrint or process the result from the tool call (in this case, the weather data):

```
print(f"Weather data for Lisbon: {weather_data}")
```

Step 9: Run the codeFinally, use an event loop (`asyncio.run()`) to run the asynchronous function and complete the entire process:

```
import asyncio
asyncio.run(fetch_weather_data())
```

### MCP and the future of large language models

What’s most important about MCP is that it opens the door to something we couldn’t do before: true agentic reasoning across systems. Instead of loading up a model with all the knowledge in the world, we give it the power to seek, to ask, to call upon the right tool at the right time. That’s how intelligence works in the real world: not by knowing everything but by knowing where to look and how to act.

As the concept of MCP becomes more established, a new class of frameworks and tools has begun to emerge. These frameworks, while not always explicitly labeled as MCP based, follow similar principles of modularity and structured interaction between language models and external systems. Tools like LangChain, DSPy, and Gorilla exemplify this shift. They enable developers to build more efficient programs by managing execution across context windows, scaling interactions with language models, and integrating various tools in a consistent, predictable manner. The core logic is shared; i.e., modularize the architecture, separate concerns, and treat the language model as a flexible tool rather than a monolithic entity.

This approach is more than just a trend; it’s the beginning of a broader shift in how we interact with language models. As these frameworks mature, the interaction with models will evolve from simple prompt-based queries to more complex programmatic workflows. We will build layers of logic and structure around models, much like we would with any backend system. As the capabilities of language models expand, the MCP layer itself will evolve to handle more advanced functionalities, such as composable functions, modular logic, conditional execution, tool invocation, and memory manipulation.

Looking ahead, the context  window will continue to grow. Tools like virtualized LLMs (vLLMs) will enable persistence across sessions, allowing a model’s state to carry over from one interaction to the next. This will enable more sophisticated workflows, where a user no longer just “prompts” a model. Instead, they will interact with a fully integrated system—an LLM-native environment that includes memory, a task stack, logs, and capabilities. The line between the language model and the broader infrastructure will blur, creating an environment where the model can be treated as a dynamic, stateful component within a larger system. In the future, this protocol may be invisible to users, just as HTTP is invisible when you browse the web. But it will shape the way every AI application is built. It will become the backbone of multi-agent systems, agentic workflows, and the infrastructure that supports open-ended intelligence. It doesn’t just make LLMs smarter—it gives them hands, eyes, and a map of the world they operate in.

This evolution of MCP will lead to environments where tasks are not limited to short, isolated interactions but can span multiple steps and contexts, with the model acting as a true agent capable of interacting with a wider range of tools and resources. This shift is already happening, albeit incrementally, and will become a fundamental part of how we build AI-driven applications in the future.

## Agent-to-Agent Protocol

MCP brought structure to how language models interface with tools, memory, and external logic, giving us a formal way to treat models like programmable systems. But it assumes there is a single actor—a single agent querying tools, running logic, and managing state. What happens when there’s more than one agent?

As agentic systems grow in complexity, so does the need for coordination. An agent that schedules meetings might need to talk to another that handles email summaries, which in turn might call a tool that fetches flight times. So the next wave of model-based systems doesn’t live in isolation—it lives in a swarm. Imagine multiple agents with specialized roles, distributed across platforms and services, all trying to talk to one another. That’s where Agent2Agent protocol (A2A) steps in.

A2A, [introduced by Google as an open standard](https://oreil.ly/PuDm-), is like a foundational layer for interoperability. It defines how AI agents identify each other, communicate, negotiate tasks, and share results. It picks up where MCP stops. MCP gives one agent a structure; A2A gives a group of agents a shared language.

Without a shared protocol, these connections are brittle, with custom integrations, hard-coded dependencies, and vendor lock-in. Every agent has its own dialect, its own handshake. A2A solves this by offering a standard. It doesn’t just manage centralized orchestration—it enables decentralized collaboration. One agent doesn’t need to know how another works under the hood. It just needs to know what that agent can do and how to call it.

At its core, A2A is a communication protocol for autonomous agents. It defines a set of conventions for secure, structured, and extensible agent interactions. It [abstracts away](https://oreil.ly/Ri5XT) the vendor-specific details and focuses on capability discovery, message exchange, task delegation, and identity verification.

Agent cards form the basis of discovery and negotiation. These are JSON-based documents that advertise who the agents are, what they can do, how to contact them, and what security policies they follow. Two agents can expose their cards, find each other, assess their mutual compatibility, and begin collaborating—all without tight coupling. The  core components of A2A include:

Agent identityEach  agent signs its messages cryptographically, so you know who you’re talking to.

Agent cardsThese  include structured metadata that defines an agent’s capabilities, interfaces, and protocols.

Capability discoveryAgents query each other to find out what functions or tasks the other supports.

Task negotiationAgents can delegate work, propose plans, or asynchronously coordinate workflows.

Secure messagingAll communication is authenticated, encrypted, and audit friendly.

ExtensibilityA2A is built to evolve. You can extend the schema, define your own agent roles, and create domain-specific logic.

A typical A2A interaction follows a few predictable steps, as shown in [Figure 3-3](https://learning.oreilly.com/library/view/llmops/9781098154196/ch03.html#fig0303).

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098154196/files/assets/llmo_0303.png)

###### Figure 3-3. Typical A2A interactions

Let’s look at each step in more detail:

Step 1: DiscoveryAn agent looks up another agent’s card, either from a registry or via direct request.

Step 2: ValidationThe calling agent checks the other agent’s identity and credentials via its agent card.

Step 3: Capability matchingThe calling agent examines the other agent’s listed functions and decides how to delegate a task.

Step 4: Task delegationThe calling agent sends a structured request. The called agent may accept it, reject it, or propose an alternative.

Step 5: ExecutionIf it accepts the request, the called agent performs the task, optionally invoking its own tools or subagents.

Step 6: ResponseThe called agent returns a result to the calling agent, along with any relevant logs, metrics, or follow-up capabilities.

Each of these steps is modular. You can plug them into any system—whether you’re building agents on top of LangChain, Haystack, or your own platform. And because it’s an open spec, you don’t have to rely on Google—or any one vendor—to make it work.

# The Rise of vLLMs and Multimodal LLMs

So far, most of the LLM workflows we’ve discussed in this book revolve around text. There are tokens in and tokens out; i.e., the model interprets language, transforms it, and spits back structured thoughts. But the world isn’t made of words alone. We see. We hear. We act in spaces where text is just one part of the information stream.

Multimodal models are the next step. These models don’t just read but also see, listen, describe, and even generate across modes. These systems are built to handle input and output in multiple modalities: text, image, audio, video, and sometimes even tabular data or code. A model is multimodal if it accepts more than one modality as input or produces outputs in more than one. The most common form of multimodal model today is the vision–language model (VLM). VLMs accept both text and images as input and generate text as output. Some also generate images or annotate images with bounding boxes and captions.

This shift unlocks new kinds of capabilities that were previously impossible in pure language systems. Three things in particular make multimodal LLMs viable now:

Transformer generalizationTransformers, the architecture behind LLMs, don’t care if a token is a word or a pixel. Once data is embedded into the right format, it becomes just another stream to process.

Training scalePretraining now happens on massive corpora that include image–text pairs (like LAION or COCO), enabling vision–language alignment at scale.

Tooling and open accessProjects like [CLIP](https://oreil.ly/CZ0KA), [Flamingo](https://oreil.ly/cq0iR), [BLIP](https://oreil.ly/fK3gC), and [LLaVA](https://oreil.ly/ZeNRn) have created reusable architectures and checkpoints. You no longer need to be OpenAI or Google to train or fine-tune one.

Here’s how the pipeline typically works:

1. Input embeddingsThe text is tokenized. Images are passed through a visual encoder (often a ViT). Both get embedded into the same vector space.

2. FusionThe model combines visual and textual embeddings, attending over both. This is where reasoning happens, as the model aligns what’s seen with what’s said.

3. OutputThe model produces a text output (like a caption, description, or answer) conditioned on both modalities.

Some models, like CLIP, don’t generate text at all. Instead, they match image embeddings with text embeddings. Others, like LLaVA or MiniGPT-4, are chat based; i.e., they can answer visual questions, describe images, or interpret charts and graphs through conversation. Some of the most well-known multimodal models, as of mid-2025, include:

CLIPCLIP is a model from OpenAI that learns joint vision–text embeddings. It’s not generative—it’s matching based. You can find the image that matches a sentence or the sentence that describes an image.

BLIP and BLIP-2These are bootstrapped vision–language models, pretrained to describe and reason about images in natural language. BLIP-2 uses a frozen image encoder with a lightweight query transformer.

MiniGPT-4MiniGPT-4 combines a visual encoder with a frozen LLM, aligning their representations with minimal training. It basically acts like a visual chatbot.

LLaVALLaVA, which is built on LLaMA and CLIP-style vision encoders, allows for interactive visual dialogue and visual question answering (VQA).

FlamingoFlamingo, from DeepMind, is a powerful closed-source model that has set new benchmarks for few-shot multimodal reasoning.

BentoML and LLM FoundryBentoML and LLM Foundry, while not models themselves, provide deployment, serving, and training infrastructure to fine-tune and run VLMs on your own stack.

Multimodal agents unlock a huge new surface area for ways to use AI. They can:

-

Answer questions about an image, video frame, or document screenshot

-

Parse charts, tables, or handwritten text

-

Summarize slides

-

Transcribe whiteboards

-

Describe UI layouts

-

Navigate the physical world in robotics or assistive agents

-

Build more “human-like” interfaces that feel less robotic and more perceptual

It’s about reasoning across modalities, treating language and vision as two views of the same world. Just like in language, the shift is from pattern recognition to *contextual reasoning*.

The trajectory is clear: modality boundaries are blurring. Future systems will handle vision, language, audio, code, and interaction as part of the same cognitive loop. Some already do. The open frontier is about building agentic systems that *see, decide, and act*—not in separate blocks but as integrated flows.

This changes the architecture of everything. Prompts become interfaces, not just instructions. Inputs are multimodal, such as a voice command plus a camera feed. Outputs are also multimodal, often including a generated summary and a visual markup.

Multimodal LLMs thus aren’t just a feature upgrade—they introduce a structural change in what language models are. They represent a shift from abstract dialogue machines to embodied agents that understand and operate in the real world.

# The LLMOps Question

The main question that LLMOps teams need to answer is “Does the application perform well at a reasonable cost?” Once they can answer yes to this question, they can start working on optimizations, trying to extract maximum performance at the minimum possible cost. For LLM applications, there are several dimensions of performance, but let’s talk about cost first.

For companies that choose to buy LLM services from a cloud provider, costs can be measured directly in financial terms (you can use [LLM Price Check](https://oreil.ly/-Ez0q) for comparisons). While it’s not trivial to define performance and measure it, let’s assume for a moment that the app is already deployed in production and that the performance is at the desired level. In that case, if the main goal of the company is to maximize profits, the LLMOps team should choose the cloud LLM that provides that performance at the lowest cost.

For companies that choose to build LLMs or run LLM applications in their own hardware, there’s an additional consideration: the *opportunity cost of building versus buying*. (*Opportunity cost* here means the money, time, and market lead lost if the organization chooses to build and manage the hardware itself rather than outsourcing it using model APIs.) The demand for graphics processing units (GPUs) capable of running LLMs is very high, helping to propel the stock prices of GPU manufacturers like Nvidia to record levels. In addition to determining the cost of running an application, companies that acquire GPUs must answer one surprising question: would they make more money simply renting those GPUs? Spheron has an excellent [in-depth blog post](https://oreil.ly/6VeFD) on the economics and drawbacks of buying versus renting GPUs. In some cases, renting your GPUs is more profitable than running your own operations in-house.

## Monitoring Application Performance

The field of MLOps existed for several years before LLMs, and for many application classes, the performance metrics for MLOps and LLMOps are the same or very similar. This is because most application performance metrics are domain dependent. For example, for an application that uses LLMs to support the sales process, a key metric might be the sales conversion rate, which answers the question “Are we selling more now that we’ve started using LLMs?” For a human resources application that uses LLMs to match candidate resumes to job descriptions, a key metric may be the interview-screening success rate, which answers the question “Are we getting better candidates in our pipeline now that we’ve started using LLMs?”

Calculating these metrics doesn’t depend on the underlying technology. Whether the application is using ML, an LLM, or pen and paper to determine which customers or candidates to call, these evaluation metrics are calculated the same way. LLMs can still provide additional challenges, mainly because they are less deterministic and more susceptible to a class of changes called *drift* than ML models are. We will discuss drift in detail in [Chapter 7](https://learning.oreilly.com/library/view/llmops/9781098154196/ch07.html#ch07_evaluation_for_llms_1748896751667823). For now, it helps to think of it this way: applications that use LLMs frequently behave more like processes executed by humans than like computer-based applications, especially in terms of output variability. Your application metrics should accommodate this variability.

## Measuring a Consumer LLM Application’s Performance

To better illustrate the differences, let’s use an example that ML has solved: classifying email as spam and not spam. Let’s assume that the ML version of this application uses a popular model like XGBoost and that the LLM version of this application uses a popular model like GPT-4o. For now, let’s assume we’re using a simple prompt in our LLM-based application. For example:

```
Is the following email spam? Respond with spam if the email is spam or ham if 
the email is not spam.

[Email contents]
```

Spam detection is a classic binary classification problem for which the metrics of accuracy, precision, and recall are typically used:

AccuracyAccuracy measures the proportion of correctly classified instances out of the total instances. In this case, it indicates the overall percentage of emails that the model correctly labeled, either as spam (true positives) or not spam (true negatives). The formula for accuracy is:

Accuracy=TruePositives+TrueNegativesTotalInstancesWhile accuracy is a helpful general measure, it can be less informative when the data is imbalanced—for example, if most emails are not spam, which is a typical case.

PrecisionPrecision measures the proportion of true positive predictions (correct spam classifications) out of all the instances that the model classified as positive (spam). Precision answers the question “Of all emails classified as spam, how many actually were spam?” The formula for precision is:

Precision=TruePositivesTruePositives+FalsePositivesHigh precision indicates that when the model classifies an email as spam, it’s likely correct. However, high precision may come at the expense of missing some actual spam emails, which would lower recall.

RecallRecall (also called *sensitivity* or *true positive rate*) measures the proportion of true positive predictions out of all actual positive instances (all actual spam emails). Recall answers the question “Of all actual spam emails, how many did the model correctly identify as spam?” The formula for recall is:

Recall=TruePositivesTruePositives+FalseNegativesHigh recall means the model successfully identifies most spam emails, but this can sometimes lead to more false positives, which can reduce precision.

Accuracy provides an overall rate of correct classifications, precision shows accuracy within the positive predictions, and recall reflects the model’s ability to capture actual positives. Together, these metrics offer a well-rounded evaluation of the model’s effectiveness in distinguishing between spam and non-spam emails.

The choice of whether to prioritize precision or recall depends on the application. For instance, in spam filtering, users typically prefer higher recall—that is, catching as much spam as possible—even at the risk of flagging some non-spam emails as spam. To mitigate the problem of false positives, users have been trained over the years to look into their spam folders from time to time. In other classification tasks, such as medical diagnoses or fraud detection, your application may prefer to prioritize precision to minimize false positives and the associated expenses and stress.

In this example, regardless of whether you are using LLMs or classic ML for your application, as long as the application produces an output of “spam” or “ham,” you can calculate accuracy, precision, and recall and compare the models using the metrics above. To do so, you’d use a test dataset for which you have prelabeled correct answers: the *ground truth*. You can use this test dataset with your model to calculate the metrics above.

In a machine learning setting, the model output has a meaning: the “spamminess” level of the email. Higher numbers mean that the email is more likely to be spam. Engineers can increase this application’s precision, at the expense of recall, by setting a higher threshold for classifying an email as spam. This reduces the chance of misclassifying non-spam emails as spam, which in turn results in fewer false positives and raises precision (fewer non-spam emails are flagged as spam). However, it may also mean that more spam emails go undetected, which lowers recall.

The engineers can also go in the opposite direction, setting a lower threshold. Now the model would classify more emails as spam, catching more true spam emails and increasing recall, but increasing the likelihood of false positives (non-spam emails incorrectly classified as spam) and reducing precision.

By using this process in several values of the model output, you can plot a *precision–recall curve*, which is a shortcut to calculate the performance of the model under several different settings. The precision–recall curve shows precision on the y-axis and recall on the x-axis at different threshold levels. This curve allows an MLOps team to visualize how the precision and recall change as the threshold varies, showing the trade-offs between them. Since “spamminess” is the default output of ML models, you can create this chart easily in an ML setting by simply using your test dataset with different classification thresholds, calculating precision and recall, and plotting the results.

In general, a high-quality model will have a curve that reaches higher precision and recall levels, and a low-quality model will have a curve that stays near the origin (low precision and recall). You can measure the* area under the curve for precision and recall *(AUC-PR) in the graphs in [Figure 3-4](https://learning.oreilly.com/library/view/llmops/9781098154196/ch03.html#ch03_figure_3_1748895493826770). Higher AUC-PR values indicate a better model, as they suggest that the model maintains both high precision and high recall over a range of threshold values. That is, a model with a larger area is better overall.

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098154196/files/assets/llmo_0304.png)

###### Figure 3-4. An example case where AUR-PC is a better predictor for model performance, even though the ROC curve may tell a different story (source: [Fabio Sigrist](https://oreil.ly/InmMu))

When using an LLM as the engine of your application, you can’t easily calculate the area under the curve. The first practical problem is that the output of the model does not contain the probability that a given email is spam. One way to solve this problem is to modify the prompt and ask for the probability instead of the output, as proposed in the 2024 paper [“Calibrating Verbalized Probabilities for Large Language Models”](https://oreil.ly/dfHos):

```
What is the probability that the email below is spam? Give the answer as a real 
number between 0 and 1. Your answer should be just the number with your best 
guess of the probability. 

[Email contents]
```

Using such a prompt would let you create the graph, but here is the problem with LLMs not being deterministic: even at a temperature of zero (as little randomness as possible), an LLM may produce wildly different probability numbers for the same input email. Temperature, along with several other parameters, such as `frequency_penalty` and `presence_penalty`, allows us to define the randomness (or creativity) of the model output. A standard OpenAI request with our parameters could look something like the following:

```json
{
  "model": "gpt-4",
  "prompt": "Write a poem about machines.",
  "temperature": 0.7,
  "top_p": 0.9,
  "frequency_penalty": 0.5,
  "presence_penalty": 0.6,
  "max_tokens": 60,
  "stop": ["\n\n"]
}
```

Now, let’s take an example where I use the prompt to classify an email informing me of the delivery of components for installing a solar panel.

```
Abi, 

I just wanted to reach out and update you. We will have the components delivered
by Friday. As soon as I confirm I will schedule with you all. The government 
permits should come in approximately two more weeks.
```

I sent requests twice in a row with GPT-4o at temperature 0, and I obtained two different probabilities, 0.05 and 0.1. A third submission resulted in 0.05. Although setting the temperature to 0 is supposed to make the model deterministic, clearly this flip-flop in outputs means that you can never assume perfect consistency in LLMs. Therefore, you can’t reliably use this probability-plotting method to generate a curve and then choose the model with the best area. The typical compute metrics, like receiver operating characteristic (ROC) or recall curve, area under the curve (AUC), and area under the precision recall curve (AUC-PR),​ assume *stable scoring*; that is, the same input gives the same score every time. However, for LLMs, these curves become noisy, and the standard methods of evaluation become unreliable. The evaluation system can falsely assert that one “version” of the model is better than the other, simply because of internal randomness.

## Choosing the Best Model for Your Application

One of the most common tasks in both MLOps and LLMOps is to decide whether a new version of a model is better than an existing version. This is sometimes called the *champion/challenger test* or *A/A test* in which the model that is currently in production is called the “champion,” and the new model is called the “challenger.” If the challenger proves better than the champion, it replaces the champion and takes its place in production. The proof is usually done by evaluating both models by a metric or a collection of metrics.

To handle the inherent variability of LLM outputs, you’ll need to calculate distributions over multiple samples rather than rely on single-point metrics like AUC. In practice, this means running each test dataset several times to obtain a range of outcomes, allowing you to calculate statistical distributions such as the mean, standard deviation, and confidence intervals for the performance metric you’re evaluating.

By gathering these distributions, you can gain insights into the stability and reliability of the model’s responses. These metrics help determine whether the challenger genuinely outperforms the champion or if differences are simply due to inherent model variability.

For example, rather than using a single precision or recall figure, you would calculate the average precision and recall for both models over a large number of tests, recording the variance in these scores. The resulting distributions allow you to perform significance testing, or a [t-test](https://oreil.ly/s3VHJ), which can help you determine if the difference between the two models is statistically significant. This approach accounts for the model’s variability, offering a clearer picture of whether the challenger consistently performs better than the champion across a range of scenarios and inputs. You can use the A/A test to see if your process works. Running your decision framework on the same model twice might produce results that have different point estimates, but the difference between them should not be statistically significant.

Ultimately,  calculating distributions (see the code in [Example 3-1](https://learning.oreilly.com/library/view/llmops/9781098154196/ch03.html#ch03_example_1_1748895493838650)) rather than relying on single metrics provides a more robust framework for comparing LLM-based applications, helping mitigate the challenges posed by the nondeterministic nature of LLMs.

##### Example 3-1. Calculating two models’ distributions of precision and recall over a large number of tests

```
import matplotlib.pyplot as plt
import numpy as np
import seaborn as sns
# Simulate two distributions of model scores with a random seed
np.random.seed(42)
champion_scores = np.random.normal(loc=0.78, scale=0.02, size=100)
challenger_scores = np.random.normal(loc=0.80, scale=0.02, size=100)
# Plot the distributions
plot.figure(figsize=(10,6))
sns.kdeplot(champion_scores, label="Champion Model", color = "blue")
sns.kdeplot(challenger_scores, label="Challenger Model", color = "red")
plt.title("Distributions of Model Performance Scores")
plt.xlabel("Score")
plt.ylabel("Density")
plt.legend()
plt.grid(True)
plt.show()
```

By evaluating performance over large test sets and using statistical tools to interpret these results, you can better determine if the challenger model is a worthwhile replacement for the champion.

## Other Application Metrics

Although we used precision and recall in the preceding example for simplicity, many other metrics are used in practice. Applications like recommendation systems and ranked-choice applications (such as search algorithms) often use *mean average precision *(MAP) to evaluate ranking quality. MAP calculates the average precision for each query or user and emphasizes placing relevant items higher in the results list. MAP gives higher scores to models that rank relevant items at the top, making it particularly useful for applications where the order of results is critical. This is essential in contexts like ecommerce search, where users are more likely to click on the first few results, and high MAP scores indicate that relevant items are being effectively prioritized.

Another widely used metric for ranked applications is* normalized discounted cumulative gain *(NDCG), which evaluates the relevance of results while accounting for their positions. NDCG applies a discount factor that reduces the importance of relevant items that appear lower in the ranking, making it ideal for systems that need to surface relevant content at the very top. For example, in a news recommendation app, users are likely to click only on the first few articles, so high NDCG scores indicate that the most relevant articles are being given prime spots.

Other key metrics in ranking and recommendation applications are* hit rate* (also called *top-k accuracy*) and *coverage*. Hit rate measures how often at least one relevant item appears in the top *k* results, indicating the model’s consistency in recommending relevant items within the top ranks. For instance, in a streaming service, a high hit rate ensures that users frequently see relevant shows or movies in the top suggestions. Coverage, on the other hand, measures the proportion of items in the catalog that are recommended. This helps determine whether the model provides a wide range of options and helps it avoid repeatedly recommending popular items. High coverage in recommendation systems is desirable because it exposes users to a broader variety of content.

In many LLM-based applications, the ground truth is very subjective. For example, although you can often test whether code generated by an LLM works for a given test set, this is usually not enough to judge code quality—after all, there’s a lot of code that works but is inefficient or hard to understand. In these cases, teams tend to use customer-focused metrics like user engagement metrics, including *click-through rate* (CTR) and* conversion rate*. CTR measures the percentage of recommended items that users click, while conversion rate tracks recommendations that lead to actions like purchases or sign-ups.

In the code generation example, one way to figure out whether users like the content is whether they click “accept” for the code that is offered. Another way is to check how much they modify the code once it is incorporated in their own code. In an application that sends emails, you can see whether the user who generated the email sent it as provided and monitor the read and response rate of the emails.

# What Can You Control in an LLM-Based Application?

When implementing an application with an LLM as the core component, several parameters allow you to shape the model’s responses while balancing creativity, coherence, and efficiency. The most well-known setting is *temperature*, a setting that controls the randomness of the model’s output by adjusting how deterministic or variable the response should be. This is a number between 0 and 1. Lower numbers, such as 0.2, make the model focus on the most likely answer, which is useful for factual, consistent responses. Conversely, a higher temperature setting, like 0.8, introduces more randomness, allowing the model to generate diverse and creative content, which can be advantageous in applications like storytelling or brainstorming.

Two other parameters, *top-*k and* top-*p*,* control the diversity of responses by setting probabilistic limits. Top-*k* sampling restricts the model to only the top *k* most probable tokens at each step, thus guiding it toward a focused range of words that are statistically most likely, with lower values ensuring more coherent responses. Top-*p* sampling, on the other hand, is a *cumulative *probability threshold, where the model selects from the smallest set of tokens with a combined probability above a given value (e.g., 0.9). This allows it to consider more word options for creative responses, while still ignoring highly unlikely terms. You can use the top-*k* and top-*p* parameters alongside temperature to strike a balance between response diversity and coherence, adjusting them to the specific requirements of your application.

Another parameter that influences variety is *frequency penalty*, which applies a penalty based on how many times a token (word or phrase) has already appeared in the generated text. This means that each additional occurrence of a previously used word is penalized progressively, making it less likely that the model will repeat specific words frequently. This parameter is particularly useful in creative applications, where avoiding repetition can make the output more pleasant, ensuring that common words or phrases are not repeated too often.

In contrast, another parameter called *presence penalty* applies a more general penalty to any token that has already appeared at least once, regardless of how frequently it has been used. This means that the model is discouraged from reusing *any *word or phrase that it has already used, even if it has only appeared once. Presence penalty is less about reducing high-frequency words and more about encouraging the model to introduce entirely new vocabulary throughout the response. This can be beneficial in applications like content generation, where avoiding even mild repetition helps keep the language fresh and varied.

To manage response length and prevent excessive generation, most models allow you to set a token limit with a parameter like `max tokens`, determining the maximum number of tokens the model will generate for each response. This is crucial for both controlling costs and tailoring the response length to suit different scenarios; concise answers might require a low token limit, while longer, detailed outputs may need a higher limit. In our spam detection example, the `max tokens` can be set to a low number. In some models, the `max tokens` parameter represents both the inputs and the output tokens. The final parameter that you can easily control is the prompt, and this is where a lot of the real-world optimizations happen—through prompt engineering.

## Prompt Engineering Is “Hard”

In our spam detector example, we started with a very simple prompt:

```
Is the following email spam? Respond with spam if the email is spam or ham if 
the email is not spam. 

[Email contents]
```

Note that we’re back to the case in which the prompt is expected to produce answers that are only *spam* or *ham* and will not provide a “spamminess” value. If you use the preceding prompt, you may be surprised to find that there’s no guarantee that the model will actually follow the instructions as you expect and output only *spam* or *ham*. Some other potential outputs I’ve obtained from GPT-4o are as follows:

```
Yes, this email is spam.

Not spam.

I'm not sure.

I'm sorry, but as an AI language model, I must follow ethical guidelines, and I 
cannot engage in harmful, malicious, or offensive behavior.
```

Although the last answer may be surprising, it is a very common message from LLMs and may be triggered unexpectedly, often if the spam email has content that is deemed grossly offensive.

This raises another consideration when using LLMs instead of machine learning in applications. When integrating an LLM into an application, you have to decide what to do when the answer doesn’t conform to the expected output. A typical solution is to create a new class, such as “unknown.” But even then, you could simply coerce all outputs into *spam* or *not spam*, for example by classifying all outputs that are not *N* into *spam*. Creating the “unknown” category prevents the out-of-specification errors from being hidden from you. In this case, you’ll want to add a metric for out-of-specification error percentage and set a low target.

Making adjustments to the prompt is called *prompt engineering*. One of the simplest things you can do to improve the prompt is to add “Use only spam or ham as the answers, nothing else.” This should lower the proportion of answers that fall under “unknown.”

```
Is the following email spam? Respond with spam if the email is spam or ham 
if the email is not spam. Use only spam or ham as the answers, nothing else.

[Email contents]
```

Let’s say someone in management reads in an article that models tend to perform better if you ask them to think carefully. They ask you to test whether that change makes your spam detection application better. How can you test whether the new prompt shown next performs better or worse than the existing prompt?

```
After considering it very carefully, do you think it's likely that the email 
below is spam? Respond with spam if the email is spam or ham if the email is 
not spam. Use only spam or ham as the answers, nothing else.

[Email contents]
```

We do know one thing: using a more detailed prompt will increase costs, because models charge by the length of inputs and outputs combined.

## Did Our Prompt Engineering Produce Better Results?

To figure out whether the additional cost comes with additional performance, you’ll have to go through a decision process. [Example 3-2](https://learning.oreilly.com/library/view/llmops/9781098154196/ch03.html#ex-3-2) shows how to do this using Python. In the example, we use the *enron_spam_data.csv* file, a public labeled dataset of approximately 30,000 emails, exactly half of which are spam.

The code tests just a few emails, running 10 experiments with 30 spam and 30 ham emails each. In a real setting, you would want to use your own, much larger labeled dataset (because of drift, as we will explain in [Chapter 7](https://learning.oreilly.com/library/view/llmops/9781098154196/ch07.html#ch07_evaluation_for_llms_1748896751667823)) and do more experiments.

##### Example 3-2. Prompt engineering test

```
import pandas as pd
import numpy as np
import random
from statistics import mean, stdev
import os
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv()

client = OpenAI(
    api_key=os.environ.get("OPENAI_API_KEY")
)

# Define the prompts to test
PROMPT_A = "Is the following email spam? Respond with spam if the email is spam or 
ham if the email is not spam. Use only spam or ham as the answers, nothing else.
\n\nSubject: {subject}\n\nMessage: {message}"
PROMPT_B = "After considering it very carefully, do you think it's likely that the 
email below is spam? Respond with spam if the email is spam or ham if the email is 
not spam. Use only spam or ham as the answers, nothing else.
\n\nSubject: {subject}\n\nMessage: {message}"

# Load the dataset and sample
df = pd.read_csv("enron_spam_data.csv")
spam_df = df[df['Spam/Ham'] == 'spam'].sample(n=30)
ham_df = df[df['Spam/Ham'] == 'ham'].sample(n=30)
sampled_df = pd.concat([spam_df, ham_df])

# Evaluation function
def evaluate_prompt(prompt_template):
    true_positive = 0
    false_positive = 0
    true_negative = 0
    false_negative = 0

    for _, row in sampled_df.iterrows():
        subject = row['Subject']
        message = row['Message']
        actual_label = row['Spam/Ham']
        
        # Generate prompt with email data 
        prompt = prompt_template.format(subject=subject, message=message)
        
        # Call the OpenAI API with the given prompt
        try:
            response = client.chat.completions.create(
            messages=[
                {
                    "role": "user",
                    "content": prompt,
                }
            ],
            model="gpt-3.5-turbo-0125",
            )
            predicted_label = response.choices[0].message.content.strip().lower()
        
        except Exception as e:
            print(f"Error calling OpenAI API: {e}")
            continue

        # Convert the actual and predicted labels to lowercase for comparison
        if predicted_label == 'spam' and actual_label == 'spam':
            true_positive += 1
        elif predicted_label == 'spam' and actual_label == 'ham':
            false_positive += 1
        elif predicted_label == 'ham' and actual_label == 'ham':
            true_negative += 1
        elif predicted_label == 'ham' and actual_label == 'spam':
            false_negative += 1

    # Calculate precision and recall
    precision = (
        true_positive / (true_positive + 
    false_positive) 
        if (true_positive + false_positive) > 0 
        else 0
    )

    recall = (
        true_positive / (true_positive + 
    false_negative) 
        if (true_positive + false_negative) > 0 
        else 0
    )

    return precision, recall


# Run experiments
def run_experiments(prompt_template, n_experiments=10):
    precisions = []
    recalls = []
    for n in range(n_experiments):
        print(f"Running experiment {n+1} of {n_experiments}")
        precision, recall = evaluate_prompt(prompt_template)
        print(f"Precision: {precision:.4f}, recall: {recall:.4f}")
        precisions.append(precision)
        recalls.append(recall)
    
    # Calculate mean and standard deviation for precision and recall
    precision_mean = mean(precisions)
    precision_stdev = stdev(precisions)
    recall_mean = mean(recalls)
    recall_stdev = stdev(recalls)
    
    return precision_mean, precision_stdev, recall_mean, recall_stdev

# Run experiments for Prompt A
(
    precision_mean_a,
    precision_stdev_a,
    recall_mean_a,
    recall_stdev_a,
) = run_experiments(PROMPT_A)

print(
    f"Prompt A - Precision: {precision_mean_a:.4f} ± {precision_stdev_a:.4f}, "
    f"Recall: {recall_mean_a:.4f} ± {recall_stdev_a:.4f}"
)

# Run experiments for Prompt B
(
    precision_mean_b,
    precision_stdev_b,
    recall_mean_b,
    recall_stdev_b,
) = run_experiments(PROMPT_B)

print(
    f"Prompt B - Precision: {precision_mean_b:.4f} ± {precision_stdev_b:.4f}, "
    f"Recall: {recall_mean_b:.4f} ± {recall_stdev_b:.4f}"
)
```

The results are below:

```
Prompt A - Precision: 0.8370 ± 0.0365, Recall: 1.0000 ± 0.0000
Prompt B - Precision: 0.7763 ± 0.0311, Recall: 1.0000 ± 0.0000
```

You can see that the LLM is very good at finding spam in this dataset, with a recall of 100% with both prompts, but the precision is around 84% for the original prompt and 78% for the longer prompt. Is the new prompt better than the existing prompt? We can use a *t*-test to make that determination. Since the recall is the same for both models, we only need to do the *t*-test for the precision metric. First, we calculate the *t*-statistic:

t=x¯A-x¯BsA2nA+sB2nBIn this case, the *t*-statistic is 6.93. We can convert the *t*-statistic to a *p*-value, which in this case is approximately 2.13 × 10–9, far smaller than a typical significance threshold of 0.05.

Since the *p*-value is extremely small, we can confidently conclude that* Prompt A performs significantly better than Prompt B* in terms of precision. This result indicates that the observed difference in mean precision is highly unlikely to be due to random variation. ​Since Prompt B is also more expensive, we would not update the model to use Prompt B.

# LLM-Based Infrastructure Systems Are “Harder”

Once you get past calling an LLM with just a prompt and start orchestrating it into a live system—with memory, tools, feedback, and goals—then you are no longer dealing with the nondeterministic nature of an LLM. You’re dealing with a complex operating system with its own language, state, dependencies, and failure modes, each awaiting a failure anytime. Here, both the agentic systems as well as infrastructure-level LLM applications have their own operational or LLMOps problems.

While the agentic systems promise flexibility, reasoning, and automated decision-making, they also introduce complex control flows that can be very hard to debug and even harder to trust. As we saw in the example prompt in the previous section, LLM outputs can vary from one to another. This can make debugging very difficult. If your agent fails at step 6 in a 10-step task, rerunning it might make it fail at step 3 or succeed entirely. Thus, there’s no clear “stack trace.” Although companies like W&B have offerings like Weave (its tracing tool), perfect reproducibility in agentic workflows can be incredibly hard, if not impossible.

Another issue is that agents need context. They remember facts and refer to earlier steps to plan ahead. But storing and retrieving this memory (whether vectorized or tokenized) becomes a bottleneck in terms of both latency and accuracy. Most memory systems are brittle, leaky, and misaligned with the model’s representation space. Additionally, very few agents, if any to date, are good at “planning.” This has been documented on several Twitter/X spaces where agents often skip steps, repeat tasks, or pursue irrelevant paths. This becomes ever harder when calling tools, because when the tools fail due to API errors or empty results, the agent must recover without getting stuck in a loop or hallucinating. Again, very few, if any, agents handle these edge cases gracefully without being preprogrammed using if-else conditions. Moreover, there’s no equivalent of “unit tests” or “assertions” that works well for agentic workflows yet.

Agentic workflows break when the logic is messy—if, say, the plans don’t decompose or memory is poorly structured. However, infrastructure-level LLM applications introduce even more failure points and complexity. If the protocols don’t sync with each other, or the data flows start leaking, or the model boundaries are unclear. . .there are far too many failure points to count. While most people have been jumping on the bandwagon to adopt MCPs or A2A, very few are equipped to handle the LLMOps issues these tools introduce.

First, MCP assumes that the memory and tools are abstracted and callable. But that couldn’t be further from the truth. Memory updates go out of sync pretty often. Different agents have different scores, and the tools might update shared state without coordination. You need memory versioning, namespacing, and syncing—none of which actually come “out of the box.”

Then, say, if a model call takes time, wrapping the model call in an MCP session adds orchestration overhead. That includes setup, prompt retrieval, and tool registration issues, all of which can compound. This is where you need to consider the opportunity cost. Similarly, A2A will add network latency, serialization, and agent discovery issues, and again, for complex tasks, all of these sources of overhead compound very quickly. When a prompt fails in LangChain, you see a clear trace. When an A2A agent fails, it might return an invalid response, break the schema, or even time out. It’s never clear where it failed. Was it at the agent stage or transport or the memory layer or the tooling? You need to stack up layers and layers of observability tools and structured logging across agents and sessions.

If your workflow includes five agents, each calling three tools, and every interaction is mediated through A2A or MCP layers, then the user ends up waiting for quite a few seconds or even minutes. This ruins the user experience. Also, most of the security issues haven’t even yet been documented as of this writing. Agents might hijack each other’s memories, triggering unintended tool actions—the attack surface becomes incredibly wide, especially when you let LLMs act autonomously on the user data.

Agentic intelligence feels incredibly powerful in demos but breaks in production. Indeed, it is very fragile without solid infrastructure. Every day, I personally see tons of clever orchestrations around dumb prompt chains tied up in a brittle, underused LLMOps infrastructure. But building this infrastructure means acknowledging the costs: performance overhead, strict interface contracts, and state complexity, as well as a need for more LLMOps engineers to create the best practices, tooling, and frameworks to run these systems reliably, safely, and robustly.

# Conclusion

In this chapter, we’ve covered the key considerations for integrating LLMs into applications, from measuring performance to improving models through parameter adjustment, prompt engineering, and agentic and infrastructure applications. Using LLMs successfully in enterprise applications requires defining clear performance metrics, monitoring them, and continuously improving the models.

# References

Alayrac, Jean-Baptiste et al. [“Tackling Multiple Tasks with a Single Visual Language Model”](https://oreil.ly/hTMjp), Google DeepMind, April 28, 2022.

Anthropic. [“Introducing the Model Context Protocol”](https://oreil.ly/-UjTz), November 25, 2024.

Bevans, Rebecca. [“An Introduction to t Tests: Definitions, Formula, and Examples”](https://oreil.ly/snP0y), Scribbr, June 22, 2023.

Fiore, Steven. [“Inside Microsoft’s Copilot Stack: Building Smarter AI Assistants”](https://oreil.ly/aDxV5), *Lantern*, August 2, 2024.

Henry, Parker. [“How Duolingo Uses AI to Create Lessons Faster”](https://oreil.ly/_2C7G), Duolingo Blog, June 22, 2023.

Li, Junnan, et al. [“BLIP: Bootstrapping Language-Image Pre-training for Unified Vision-Language Un](https://oreil.ly/1YOME)[derstanding and Generation”](https://oreil.ly/1YOME), arXiv, February 15, 2022.

Microsoft | AI for Good Lab. [“When AI Became a General-Purpose Technology”](https://oreil.ly/2YnWU) [figure]. LinkedIn post by Brad Smith, Microsoft, September 2024.

Microsoft Research. n.d. [“Building Next-Gen Multimodal Foundation Models for General-Purpose Assistants”](https://oreil.ly/1ZUKe), accessed May 21, 2025.

OpenAI. n.d. [“Be My Eyes”](https://oreil.ly/CZcE_), accessed May 21, 2025.

OpenAI. [“CLIP: Connecting Text and Images”](https://oreil.ly/rbuEV), OpenAI, January 5, 2021.

OpenL. n.d. [“LLM Price Check”](https://oreil.ly/-Ez0q), accessed May 21, 2025.

Schmid, Phil. [“Model Context Protocol (MCP) an Overview”](https://oreil.ly/LGDUG), personal blog, April 3, 2025.

Sigrist, Fabio. [“Demystifying ROC and Precision-Recall Curves”](https://oreil.ly/eWU7R), *Medium*, January 25, 2022.

South, Tobin et al. [“Authenticated Delegation and Authorized AI Agents”](https://oreil.ly/cQyyw), arXiv, January 16, 2025.

Spheron Network. [“The Economics of Renting Cloud GPUs: A Comprehensive Breakdown”](https://oreil.ly/t70mb), March 13, 2025.

Wang, Cheng, et al. [“Calibrating Verbalized Probabilities for Large Language Models”](https://oreil.ly/lGJuU), arXiv, October 9, 2024.
