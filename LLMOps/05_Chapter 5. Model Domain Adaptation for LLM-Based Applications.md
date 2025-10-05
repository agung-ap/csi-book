# Chapter 5. Model Domain Adaptation for LLM-Based Applications

In the previous chapter, we discussed different architectures for model deployment. In this chapter, we will talk about how to do domain adaptation for your models. Practitioners frequently refer to *domain adaptation* as “fine-tuning,” but fine-tuning is actually just one of many ways to make a model work well in your domain.

In this chapter, we will look at several model adaptation methods, including prompt engineering, fine-tuning, and retrieval augmented generation (RAG).

We will also look at how to optimize LLMs to run them in resource-constrained environments that require model compression. Finally, we will discuss best practices and scaling laws to show you how to determine how much data your LLMs need to run effectively.

# Training LLMs from Scratch

Training LLMs from scratch can be simple or resource intensive, depending on your application. For most applications, it makes sense to use an existing open source LLM or proprietary LLM. On the other hand, there’s no better way to learn how an LLM works than to train one from scratch.

Training an LLM from scratch is a complex, resource-intensive task requiring a comprehensive pipeline that necessitates data preparation, model architecture selection, training configuration, and monitoring. Let’s walk through a structured approach to training an LLM from scratch.

## Step 1: Pick a Task

Determine why you’re building this model, the domain it will serve, and the tasks it will perform (such as text generation, summarization, or code generation). Decide on success criteria, such as perplexity, accuracy, or other domain-specific evaluation metrics.

## Step 2: Prepare the Data

Before you feed data into a model, the model preprocessing step makes sure that the input is in a form the model can handle effectively. This involves tokenizing text, removing noise, normalizing formats, and sometimes simplifying complex structures into components the model can understand more easily. Preprocessing can also include feature selection, which is about picking the most relevant data so the model’s “focus” is on what really matters. This step includes:

Collecting large-scale text dataHigh-quality sources include books, articles, websites, research papers, code repositories, and domain-specific texts if the model is specialized (such as for use in the legal or medical fields).

Cleaning the dataThis includes removing non-useful elements (like advertisements or formatting artifacts) and handling misspellings. Use libraries like Hugging Face for this task.

Tokenizing the dataYou can do this using subword tokenization methods like byte-pair encoding (BPE) or SentencePiece, as is done in models like BERT and GPT-3. You can also use Hugging Face’s `AutoTokenizer` for this task. Tokenization is essential for handling large vocabularies and avoiding the need for excessive parameters.

## Step 3: Decide on the Model Architecture

Choose a model size appropriate for your data, resources, and goals. Model configurations range from smaller models (hundreds of millions of parameters) to full-scale LLMs (billions or even trillions of parameters). As discussed in [Chapter 1](https://learning.oreilly.com/library/view/llmops/9781098154196/ch01.html#ch01_introduction_to_large_language_models_1748895465615150), adapt the base architecture to fit your specific needs, whether that’s changing the number of layers, changing the attention mechanism, or adding specialized components (such as retrieval-augmented mechanisms if focusing on knowledge-intensive tasks). Three general types of architecture are shown in [Figure 5-1](https://learning.oreilly.com/library/view/llmops/9781098154196/ch05.html#ch05_figure_1_1748896666799655).

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098154196/files/assets/llmo_0501.png)

###### Figure 5-1. Three types of LLM architectures (source: [Abhinav Kimothi](https://oreil.ly/bR9E1))

## Step 4: Set Up Your Training Infrastructure

Training a large model typically requires distributed training across multiple GPUs or TPUs, ideally with high memory (16 GB+) and fast interconnects (like NVLink). Frameworks like PyTorch’s Distributed Data Parallel (DDP) or TensorFlow’s `MultiWorkerMirroredStrategy` can come in handy. Those coming from an MLOps background may already know of libraries like DeepSpeed and Megatron-LM that are designed to optimize memory and computation for large-scale model training.

Although there are plenty of optimizers for training ML models, including stochastic gradient descent (SGD) and Autograd, we suggest selecting an optimizer suitable for large models, such as Adam or AdamW, and use mixed-precision training (for instance, FP16) to reduce memory usage and accelerate training.

## Step 5: Implement Training

Train the model on the task. While implementing the training, there are a few things to think of. What will your hyperparameters be? What will be your seed value? You can view one of the simplest implementations for training LLMs from scratch in this [one-hour video by Andrej Karpathy](https://oreil.ly/PfnyZ) (see [Example 5-1](https://learning.oreilly.com/library/view/llmops/9781098154196/ch05.html#ch05_example_1_1748896666808696)).

##### Example 5-1. Implementation for training an LLM from scratch by Andrej Karpathy (used with permission)

```
import torch
import torch.nn as nn
from torch.nn import functional as F

# define your hyperparameters
batch_size = 16 # how many independent sequences will we process in parallel?
block_size = 32 # what is the maximum context length for predictions?
max_iters = 5000
eval_interval = 100
learning_rate = 1e-3
device = 'cuda' if torch.cuda.is_available() else 'cpu'
eval_iters = 200
n_embd = 64
n_head = 4
n_layer = 4
dropout = 0.0
# ------------

torch.manual_seed(1337)

URL="https://raw.githubusercontent.com/karpathy/char-rnn/master/data/
    tinyshakespeare/input.txt"
wget $URL
with open('input.txt', 'r', encoding='utf-8') as f:
    text = f.read()

# here are all the unique characters that occur in this text
chars = sorted(list(set(text)))
vocab_size = len(chars)
# create a mapping from characters to integers
stoi = { ch:i for i,ch in enumerate(chars) }
itos = { i:ch for i,ch in enumerate(chars) }
encode = lambda s: [stoi[c] for c in s] # encoder: take a string, output a list of 
integers
decode = lambda l: ''.join([itos[i] for i in l]) # decoder: take a list of integers, 
output a string

# Train and test splits
data = torch.tensor(encode(text), dtype=torch.long)
n = int(0.9*len(data)) # first 90% will be train, rest val
train_data = data[:n]
val_data = data[n:]

# data loading
def get_batch(split):
    # generate a small batch of data of inputs x and targets y
    data = train_data if split == 'train' else val_data
    ix = torch.randint(len(data) - block_size, (batch_size,))
    x = torch.stack([data[i:i+block_size] for i in ix])
    y = torch.stack([data[i+1:i+block_size+1] for i in ix])
    x, y = x.to(device), y.to(device)
    return x, y

@torch.no_grad()
def estimate_loss():
    out = {}
    model.eval()
    for split in ['train', 'val']:
        losses = torch.zeros(eval_iters)
        for k in range(eval_iters):
            X, Y = get_batch(split)
            logits, loss = model(X, Y)
            losses[k] = loss.item()
        out[split] = losses.mean()
    model.train()
    return out

class Head(nn.Module):
    """ one head of self-attention """

    def __init__(self, head_size):
        super().__init__()
        self.key = nn.Linear(n_embd, head_size, bias=False)
        self.query = nn.Linear(n_embd, head_size, bias=False)
        self.value = nn.Linear(n_embd, head_size, bias=False)
        self.register_buffer('tril', torch.tril(torch.ones(block_size, block_size)))

        self.dropout = nn.Dropout(dropout)

    def forward(self, x):
        B,T,C = x.shape
        k = self.key(x)   # (B,T,C)
        q = self.query(x) # (B,T,C)
        # compute attention scores ("affinities")
        wei = q @ k.transpose(-2,-1) * C**-0.5 # (B, T, C) @ (B, C, T) -> (B, T, T)
        wei = wei.masked_fill(self.tril[:T, :T] == 0, float('-inf')) # (B, T, T)
        wei = F.softmax(wei, dim=-1) # (B, T, T)
        wei = self.dropout(wei)
        # perform the weighted aggregation of the values
        v = self.value(x) # (B,T,C)
        out = wei @ v # (B, T, T) @ (B, T, C) -> (B, T, C)
        return out

class MultiHeadAttention(nn.Module):
    """ multiple heads of self-attention in parallel """

    def __init__(self, num_heads, head_size):
        super().__init__()
        self.heads = nn.ModuleList([Head(head_size) for _ in range(num_heads)])
        self.proj = nn.Linear(n_embd, n_embd)
        self.dropout = nn.Dropout(dropout)

    def forward(self, x):
        out = torch.cat([h(x) for h in self.heads], dim=-1)
        out = self.dropout(self.proj(out))
        return out

class FeedFoward(nn.Module):
    """ a simple linear layer followed by a non-linearity """

    def __init__(self, n_embd):
        super().__init__()
        self.net = nn.Sequential(
            nn.Linear(n_embd, 4 * n_embd),
            nn.ReLU(),
            nn.Linear(4 * n_embd, n_embd),
            nn.Dropout(dropout),
        )

    def forward(self, x):
        return self.net(x)

class Block(nn.Module):
    """ Transformer block: communication followed by computation """

    def __init__(self, n_embd, n_head):
        # n_embd: embedding dimension, n_head: the number of heads we'd like
        super().__init__()
        head_size = n_embd // n_head
        self.sa = MultiHeadAttention(n_head, head_size)
        self.ffwd = FeedFoward(n_embd)
        self.ln1 = nn.LayerNorm(n_embd)
        self.ln2 = nn.LayerNorm(n_embd)

    def forward(self, x):
        x = x + self.sa(self.ln1(x))
        x = x + self.ffwd(self.ln2(x))
        return x

# super simple bigram model
class BigramLanguageModel(nn.Module):

    def __init__(self):
        super().__init__()
        # each token directly reads off the logits for the next token from a lookup 
        table
        self.token_embedding_table = nn.Embedding(vocab_size, n_embd)
        self.position_embedding_table = nn.Embedding(block_size, n_embd)
        self.blocks = nn.Sequential(
            *[Block(n_embd, n_head=n_head) for _ in range(n_layer)]
        )
        self.ln_f = nn.LayerNorm(n_embd) # final layer norm
        self.lm_head = nn.Linear(n_embd, vocab_size)

    def forward(self, idx, targets=None):
        B, T = idx.shape

        # idx and targets are both (B,T) tensor of integers
        tok_emb = self.token_embedding_table(idx) # (B,T,C)
        pos_emb = self.position_embedding_table(torch.arange(T, device=device)) 
        x = tok_emb + pos_emb # (B,T,C)
        x = self.blocks(x) # (B,T,C)
        x = self.ln_f(x) # (B,T,C)
        logits = self.lm_head(x) # (B,T,vocab_size)

        if targets is None:
            loss = None
        else:
            B, T, C = logits.shape
            logits = logits.view(B*T, C)
            targets = targets.view(B*T)
            loss = F.cross_entropy(logits, targets)

        return logits, loss

    def generate(self, idx, max_new_tokens):
        # idx is (B, T) array of indices in the current context
        for _ in range(max_new_tokens):
            # crop idx to the last block_size tokens
            idx_cond = idx[:, -block_size:]
            # get the predictions
            logits, loss = self(idx_cond)
            # focus only on the last time step
            logits = logits[:, -1, :] # becomes (B, C)
            # apply softmax to get probabilities
            probs = F.softmax(logits, dim=-1) # (B, C)
            # sample from the distribution
            idx_next = torch.multinomial(probs, num_samples=1) # (B, 1)
            # append sampled index to the running sequence
            idx = torch.cat((idx, idx_next), dim=1) # (B, T+1)
        return idx

model = BigramLanguageModel()
m = model.to(device)
# print the number of parameters in the model
print(sum(p.numel() for p in m.parameters())/1e6, 'M parameters')

# create a PyTorch optimizer
optimizer = torch.optim.AdamW(model.parameters(), lr=learning_rate)

for iter in range(max_iters):

    # every once in a while evaluate the loss on train and val sets
    if iter % eval_interval == 0 or iter == max_iters - 1:
        losses = estimate_loss()
        print(
            f"step {iter}: "
            f"train loss {losses['train']:.4f}, "
            f"val loss {losses['val']:.4f}"
        )

    # sample a batch of data
    xb, yb = get_batch('train')

    # evaluate the loss
    logits, loss = model(xb, yb)
    optimizer.zero_grad(set_to_none=True)
    loss.backward()
    optimizer.step()

# generate from the model
context = torch.zeros((1, 1), dtype=torch.long, device=device)
print(decode(m.generate(context, max_new_tokens=2000)[0].tolist()))
```

Now that you know how a simple LLM works, let’s look into how to combine different model architectures.

# Model Ensembling Approaches

*Ensembling* refers to combining multiple models to get better results than any single model can provide on its own. Thus, each model contributes something unique, balancing one another’s weaknesses and complementing their strengths. Ensembling LLMs is a powerful approach for boosting performance, enhancing robustness, and increasing the interpretability of language models. While ensembling has traditionally been more common in smaller ML models, such as random forests or smaller-scale NLP models, it’s becoming increasingly relevant for LLMs due to their specialized behavior and varied responses.

There are, of course, trade-offs with ensembling LLMs. One of the main challenges is computational cost—running multiple large models in parallel can be resource intensive. Memory usage and inference time increase significantly, which can sometimes be prohibitive for real-time, low-latency applications.

Another challenge is complexity in deployment. Deploying an ensemble of LLMs requires orchestrating several models, managing dependencies, and possibly integrating ensemble-specific logic. Model ensembling, however, can often be optimized by using quantized versions of models, caching predictions, or limiting the ensemble to run only when certain criteria are met (for example, if a model’s confidence is low). These techniques will be discussed in [Chapter 9](https://learning.oreilly.com/library/view/llmops/9781098154196/ch09.html#ch09_scaling_hardware_infrastructure_and_resource_ma_1748896826216961).

However, for most people and companies, model domain adaptation is one of the most common and cost-effective ways to improve LLM accuracy. Let’s look into a few ways to ensemble LLMs effectively, along with some code examples.

## Model Averaging and Blending

One straightforward method is to average the predictions of multiple models. This is useful when working with models that have different strengths, such as one model that excels at generating fact-based text and another that is more creative. When we average their responses or blend their outputs, we get a more balanced response. This can be as simple as computing the probability distribution across models and averaging them. In practice, it can also look like generating the softmax probability distributions for each model and averaging them for final predictions.

The code in [Example 5-2](https://learning.oreilly.com/library/view/llmops/9781098154196/ch05.html#ch05_example_2_1748896666808730) simply iterates over each model, sums up their outputs, and divides by the number of models to get the average prediction.

##### Example 5-2. Averaging the predictions of multiple models

```
import torch

def average_ensemble(models, input_text):
    avg_output = None
    for model in models:
        outputs = model(input_text)
        if avg_output is None:
            avg_output = outputs
        else:
            avg_output += outputs
    avg_output /= len(models)
    return avg_output
```

Here, `models` is a list of model instances, and `input_text` is the text prompt.

## Weighted Ensembling

Sometimes it’s beneficial to give more weight to certain models based on their accuracy or performance on specific tasks. For instance, if Model A is known to perform better on summarization tasks, it can be given a higher weight than Model B in the ensemble. *Weighted ensembling* allows us to incorporate domain expertise or empirical model evaluations directly into the ensemble. In [Example 5-3](https://learning.oreilly.com/library/view/llmops/9781098154196/ch05.html#ch05_example_3_1748896666808750), `weights` is a list with the same length as `models`, containing the weight for each respective model.

##### Example 5-3. Weighted ensembling

```
def weighted_ensemble(models, weights, input_text):
    weighted_output = torch.zeros_like(models[0](input_text))
    for model, weight in zip(models, weights):
        output = model(input_text)
        weighted_output += output * weight
    return weighted_output
```

The output is a weighted combination that can be adjusted depending on the desired emphasis for each model in the ensemble.

## Stacked Ensembling (Two-Stage Model)

In a *stacked ensembling *approach, the outputs from multiple models are fed into a secondary model (often a smaller, simpler model) that learns to combine their outputs effectively. This metamodel learns patterns in the output spaces of the LLMs. This can be particularly useful for complex tasks like summarization or translation, where different models might capture different nuances of the input.

The method in [Example 5-4](https://learning.oreilly.com/library/view/llmops/9781098154196/ch05.html#ex-5-4) uses an SKlearn model as a metamodel, which is trained on the outputs of the LLMs. It requires a training phase as it learns to make sense of each LLM’s predictions.

##### Example 5-4. Stacked ensembling

```
from sklearn.linear_model import LogisticRegression
import numpy as np

def stacked_ensemble(models, meta_model, input_texts):
    model_outputs = []
    for model in models:
        outputs = [model(text).numpy() for text in input_texts]
        model_outputs.append(outputs)
    stacked_features = np.hstack(model_outputs)
    meta_model.fit(stacked_features, labels) # assuming labels for training
    return meta_model.predict(stacked_features)
```

Now, what if you don’t want to combine different models but simply different model architectures? Well, with LLMs you can do that too, since every model architecture has its own strengths.

## Diverse Ensembles for Robustness

Using diverse models—like a mixture of encoder–decoder architectures and transformer-based language models—can be very effective for handling edge cases or generating more comprehensive answers. This diversity brings complementary strengths to the models and tends to be more resistant to errors in any single model. For example, if one model is prone to hallucinations (a known issue in some LLMs), the other models can serve as a balancing force, correcting or limiting this effect.

Diversity in ensembling also opens doors for specialized responses using models that focus on different aspects of language, like factuality or creativity. For example, ensembling a smaller factual model with a generative transformer-based model can yield an LLM that provides both creativity and accurate information.

## Multi-Step Decoding and Voting Mechanisms

A unique way to generate text in high-latency, high-accuracy applications is to use voting mechanisms, where models vote on the next token or phrase. Voting schemes like majority, weighted, or ranked voting help ensure that common tokens across models have a higher chance of being selected, while outlier tokens are filtered out. This process can significantly improve the coherence and consistency of generated text, especially for complex prompts or tasks requiring precise language. [Example 5-5](https://learning.oreilly.com/library/view/llmops/9781098154196/ch05.html#ch05_example_4_1748896666808768) provides code for a majority vote.

##### Example 5-5. Majority voting

```
from collections import Counter

def voting_ensemble(models, input_text):
   all_predictions = []
   for model in models:
       output = model.generate(input_text)
       all_predictions.append(output)

   # Count the most common output
   majority_vote = Counter(all_predictions).most_common(1)[0][0]
   return majority_vote
```

Here, `voting_ensemble` uses a majority vote to select the most common output from each model. If there’s a tie, additional logic can be added to consider weighted voting or random selection among the tied options.

## Composability

In ensembling, another popular technique is composability. *Composability* is the ability to mix and match models or parts of models flexibly. Some ensemble methods might combine outputs from multiple models by averaging them, while others might chain models so that the output of one becomes the input for another. This setup allows you avoid using a massive, all-encompassing model for complex tasks by using smaller, specialized models instead.

For example, suppose we have a summarization model, a translation model, and a sentiment-analysis model. Instead of retraining a single, monolithic model that can handle all three tasks, we can compose these individual models in a pipeline where each one processes the output of the previous one. This modular approach allows for adaptability and maintenance, as each model can be fine-tuned independently, reducing the overall computational cost and development time (see [Example 5-6](https://learning.oreilly.com/library/view/llmops/9781098154196/ch05.html#ch05_example_5_1748896666808785)).

##### Example 5-6. Composing a model

```
def compose_pipeline(input_text, models):
    """
    Process the input text through a pipeline of models.
    Each model in the list `models` applies a specific transformation.
    """
    for model in models:
        input_text = model(input_text) 
    return input_text

# Define models for translation, summarization, and sentiment analysis
translated_text = translate_model("Translate this text to French.")
summarized_text = summarize_model(translated_text)
sentiment_result = sentiment_model(summarized_text)
```

Here, `translate_model`, `summarize_model`, and `sentiment_model` can be individually updated or replaced, which is especially beneficial if one of the models becomes outdated or needs retuning.

There are many benefits to composability. For instance, it provides modularity, since different models can be plugged in as needed, enhancing flexibility. Composability allows for easy extension by adding or swapping individual models, making these models scalable. It is also efficient, since you can optimize individual components without affecting the rest of the pipeline.

However, composability doesn’t come without challenges. First, errors in one component can propagate downstream, potentially compounding inaccuracies. Secondly, each stage adds processing time, which may affect real-time applications. And finally, ensuring coherent responses across multiple models requires careful coordination and tuning.

## Soft Actor–Critic

This is where the *soft actor–critic* (SAC) technique comes in. SAC can be advantageous for LLMs where the goal is not just to maximize accuracy but to achieve a balance between different qualitative aspects, such as creativity and coherence. SAC is a reinforcement learning technique that helps the ensemble balance exploration with exploitation. One of the unique features of SAC is its use of “soft” reward maximization, introducing entropy regularization. It promotes exploratory actions, encouraging the model to try different responses rather than always choosing the most predictable one, an approach that can lead to more natural and varied responses in language tasks.

When we ensemble LLMs, SAC can fine-tune how the models interact, making them more adaptable to new information or tasks without overcommitting to one approach. It’s particularly useful for dynamic environments where responses need to adapt based on user feedback or other shifting factors as well as for developing generalized models.

In LLMs, you can use SAC to adjust model outputs to maximize rewards associated with desirable behaviors. For example, in a customer service chatbot, rewards might be based on user satisfaction, response brevity, and politeness. SAC allows the LLM to learn a policy that maximizes these rewards through trial and error, iteratively improving its responses based on feedback.

SAC operates with two core components. The *actor network* proposes actions (in LLMs, possible responses or actions in dialogue), while *critic networks *evaluate the value of the proposed actions, considering both immediate and future rewards.

Implementing SAC for LLMs involves defining a reward function tailored to the task, setting up the actor and critic networks, and training the policy over several episodes, as shown in [Example 5-7](https://learning.oreilly.com/library/view/llmops/9781098154196/ch05.html#ch05_example_6_1748896666808799).

##### Example 5-7. SAC implementation

```
import torch
import torch.nn as nn
import torch.optim as optim

class Actor(nn.Module):
    def __init__(self):
        super(Actor, self).__init__()
        self.layer = nn.Linear(768, 768)  # Assuming LLM output size
        self.output = nn.Softmax(dim=-1)

    def forward(self, x):
        x = self.layer(x)
        return self.output(x)

class Critic(nn.Module):
    def __init__(self):
        super(Critic, self).__init__()
        self.layer = nn.Linear(768, 1)

    def forward(self, x):
        return self.layer(x)

# Initialize actor, critic, and optimizers
actor = Actor()
critic = Critic()
actor_optimizer = optim.Adam(actor.parameters(), lr=1e-4)
critic_optimizer = optim.Adam(critic.parameters(), lr=1e-3)

for episode in range(num_episodes):
    text_output = language_model(input_text)  # Generate response
    reward = compute_reward(text_output) 

    critic_value = critic(text_output)
    critic_loss = torch.mean((critic_value - reward) ** 2)
    critic_optimizer.zero_grad()
    critic_loss.backward()
    critic_optimizer.step()

    actor_loss = -critic_value + entropy_coefficient * torch.mean(actor(text_output))
    actor_optimizer.zero_grad()
    actor_loss.backward()
    actor_optimizer.step()
```

SAC comes with its own benefits. For instance, its entropy-based exploration ensures that responses remain varied, which is ideal for creative language tasks. SAC can also adapt responses over time based on live feedback, improving adaptability in real-world applications like chatbots. In addition, it allows for custom reward functions to tune behavior, making it suitable for multiobjective tasks.

One challenge of SAC is that reward functions must be carefully crafted for each task, balancing multiple objectives, which is a hard task. Second, as with many reinforcement learning algorithms, training such models can be sensitive to hyperparameters, requiring significant tuning. And most importantly, SAC can be computationally intensive, especially for large models.

# Model Domain Adaptation

While LLMs are generally powerful, they often lack specific knowledge or contextual nuances for specialized domains. For example, ChatGPT may understand everyday medical terms, but it might not accurately interpret complex medical jargon or nuanced legal phrases without additional tuning. By fine-tuning an LLM on domain-specific data, you can enhance its ability to understand and produce domain-relevant content, improving both accuracy and coherence in that context.

*Model adaptation* means refining a pretrained model to make it perform better on specific tasks or respond to unique contexts. This approach is particularly useful for LLMs that have been pretrained on diverse but general-purpose data. When applied to specialized areas like legal, medical, or scientific text, domain adaptation helps these models understand and generate more accurate, relevant, and context-sensitive responses.

Domain adaptation methods vary in complexity, from simple fine-tuning on domain-specific datasets to more advanced techniques that adapt models to the specialized vocabulary, terminology, and stylistic nuances of a particular field.

Overall, there are three core benefits to model domain adaptation:

-

Improvement of LLMs’ performance on tasks in underrepresented domains, such as medical texts or legal documents.

-

Reduction of the need to collect and label large amounts of data for each new domain. This can be especially useful for domains where data is scarce or expensive to collect.

-

The ability to make LLMs more accessible to a wider range of users, even if the user does not have expertise in that specific domain.

Let’s look at an example to clarify further. Say your target domain has unique vocabulary, such as chemical compounds or legal citations. You can update the tokenizer and embedding layers to include domain-specific tokens to improve the model’s performance, as shown in [Example 5-8](https://learning.oreilly.com/library/view/llmops/9781098154196/ch05.html#ch05_example_7_1748896666808815).

##### Example 5-8. Adding domain-specific tokens

```bash
# Custom vocabulary
custom_vocab = ["moleculeA", "compoundX", "geneY"]

# Add new tokens to the tokenizer
tokenizer.add_tokens(custom_vocab)
model.resize_token_embeddings(len(tokenizer))
```

These custom tokenizers can identify unique entities (like chemical formulas or legal citations) as atomic tokens, ensuring that the model recognizes them as distinct units rather than breaking them down into subwords. Embedding these domain-specific tokens helps the model better grasp domain-relevant information and retain consistency across complex terminologies.

There are three techniques for model domain adaptation: prompt engineering, RAG, and fine-tuning. Strictly speaking, RAG is a form of dynamic prompt engineering where developers use a retrieval system to add content to an existing prompt, but RAG systems are used so often that it’s worth discussing them separately.

One critical difference with fine-tuning is that you must have access to the model’s weights, information that is usually not available with cloud-based, proprietary LLMs.

# Prompt Engineering

In *prompt engineering*, we customize the prompts or questions we give the model to get more accurate or insightful responses. The way a prompt is structured has a massive impact on how well a model understands the task at hand and, ultimately, how well it performs. Given LLMs’ versatility, prompt engineering has become an important skill for getting the most out of these models across different domains and tasks.

The key is to understand how different prompt structures lead to different model behaviors. There are various strategies—ranging from simple one-shot prompting to more complex techniques like chain-of-thought prompting—that can significantly improve the effectiveness of LLMs. Let’s look into some common techniques.

## One-Shot Prompting

*One-shot prompting *refers to providing the model with a single example of a prompt and the kind of output you’re expecting. This is a relatively simple approach. The idea is to show the model what kind of answer or action you want by giving a clear and concise example. One-shot prompting works best when the task is simple and well-defined and doesn’t require the model to infer many patterns. If you’re asking the model to translate text, a one-shot prompt might look like this:

```
Prompt: Translate the following English sentence to French: 'Hello, how are you?'
French translation: 'Bonjour, comment ça va ?'
```

After showing the example, you can then ask the model to translate a new sentence:

```
Prompt: Translate the following English sentence to French: 'Good morning, I 
          hope you're doing well.'
```

For more complex tasks, one-shot prompting may not provide enough context for the model to generate reliable or meaningful results.

## Few-Shot Prompting

*Few-shot prompting* takes things a step further by providing the model with multiple examples of the desired output. This method is useful when the task involves identifying patterns or when the model needs more context to perform well. These examples give the model a better understanding of what the output should look like, and it can then apply those patterns to unseen examples.

Few-shot prompting is particularly useful when the task involves generating specific types of responses, such as text generation in a particular style or format. The more examples you give, the better the model becomes at identifying the task’s underlying structure.

For example, imagine you’re asking the model to generate math word problems, and you give it a few examples to show how to generate them from given data:

```
Prompt: Here's how to create a word problem based on the following math equation:
1. 3 + 5 = 8 
'If you have 3 apples and pick 5 more, how many apples do you have in total?'
2. 10 – 4 = 6 
'A store had 10 apples, but 4 were sold. How many apples are left in the store?'
```

Now, you can ask the model to generate a new problem:

```
Prompt: Create a word problem based on the following math equation: 7 + 2 = 9.
```

With few-shot examples, the model is more likely to generate a relevant word problem that matches the style and logic of the examples provided. Few-shot prompting is highly effective in tasks like text summarization, translation, and question generation.

## Chain-of-Thought Prompting

*Chain-of-thought prompting* encourages the model to break down its reasoning process step-by-step, making the reasoning process more explicit and understandable, rather than just providing the final answer. This approach is particularly valuable for complex tasks that require logical reasoning, multiple steps, or problem-solving, such as mathematical reasoning, decision-making, or any situation where intermediate steps are important. It helps models avoid making incorrect or oversimplified assumptions by encouraging them to evaluate different aspects of the task before reaching a conclusion.

Let’s say you’re asking the model to solve a math problem that involves multiple steps. Using chain-of-thought prompting, you would encourage the model to reason through the problem rather than simply provide an answer:

```
Prompt: Let's solve this step-by-step:
What is 8 × 6?
Step 1: First, break it into smaller numbers: 8 × (5 + 1).
Step 2: Now calculate: 8 × 5 = 40.
Step 3: Then calculate 8 × 1 = 8.
Step 4: Add the results: 40 + 8 = 48.
So, 8 × 6 = 48.
```

Now, you can ask the model to solve a new problem:

```
Prompt: Let's solve this step-by-step: What is 12 × 7?
```

Chain-of-thought prompting helps the model demonstrate its reasoning and ensures that it isn’t skipping over crucial details.

One powerful strategy is to combine these different types of prompting to leverage their individual strengths. For example, you might start with few-shot prompting to give the model some context and examples, then switch to chain-of-thought prompting to guide it through the reasoning process. This hybrid approach can be highly effective for more intricate tasks that require both pattern recognition and logical reasoning.

```
Prompt: Here are some examples of how to generate creative descriptions for 
objects:
1. 'A tall oak tree with thick branches reaching out, casting a large shadow on 
the grass.'
2. 'A small, round pebble with smooth edges and a soft, pale color.'
Now, describe this object: 'A rusty old bicycle.' Let's break it down step-by-
step.
```

This combined approach would help the model generate a detailed and coherent description by first learning from a few examples and then reasoning through the unique features of the object.

## Retrieval-Augmented Generation

*Retrieval-augmented generation* (RAG) is one of the most powerful techniques for combining pretrained language models with external knowledge sources. It uses retrieval-based methods to improve the generative model’s ability to handle complex queries or provide more accurate, fact-based responses. RAG models combine the power of information retrieval with text generation, making them especially useful for tasks where knowledge from large external corpora or databases is required.

RAG works by retrieving relevant documents or pieces of information from a knowledge base or search engine, which are then used to inform the generation process. This method enables the model to reference real-world data, producing responses that are not limited by the model’s preexisting knowledge.

In a typical RAG model, the input query goes through two main stages. First, in the *retrieval* stage, a retrieval system fetches relevant documents or text snippets from a knowledge base, search engine, or database. Then, in the *generation* stage, the LLM generates output based on the input query and the retrieved text snippets.

RAG allows the model to effectively handle complex questions, fact-check its responses, and dynamically reference a broad range of external information. For example, a question-answering system built with a RAG model could provide more accurate answers by first retrieving relevant documents or Wikipedia entries and then generating a response based on those documents.

The code in [Example 5-9](https://learning.oreilly.com/library/view/llmops/9781098154196/ch05.html#ch05_example_8_1748896666808830) demonstrates how you can implement a simple RAG-based model.

##### Example 5-9. RAG implementation

```
from transformers import RagTokenizer, RagRetriever, RagSequenceForGeneration

tokenizer = RagTokenizer.from_pretrained("facebook/rag-token-nq")
retriever = RagRetriever.from_pretrained("facebook/rag-token-nq")

# Load the RAG model
model = RagSequenceForGeneration.from_pretrained("facebook/rag-token-nq")

question = "What is the capital of France?"

inputs = tokenizer(question, return_tensors="pt")

retrieved_docs = retriever.retrieve(question, return_tensors="pt")

# Generate an answer using the RAG model and the retrieved documents
outputs = model.generate(input_ids=inputs['input_ids'],
                context_input_ids=retrieved_docs['context_input_ids'],
                context_attention_mask=retrieved_docs['context_attention_mask'])

answer = tokenizer.decode(outputs[0], skip_special_tokens=True)
print(answer)
```

RAG can be particularly useful in scenarios like open-domain question answering, where the model may need to access and reference up-to-date or highly specific information.

## Semantic Kernel

[Semantic Kernel](https://oreil.ly/ljuli) is a framework designed to simplify integrating LLMs into applications that require dynamic knowledge, reasoning, and state tracking. It’s particularly useful when you want to build complex, modular AI systems that can interact with external APIs, knowledge bases, or decision-making processes. Semantic Kernel focuses on building more flexible AI systems that can handle a variety of tasks beyond just generating text. It allows for modularity, enabling developers to easily combine different components—such as embeddings, prompt templates, and custom functions—in a cohesive manner.

It supports asynchronous processing, which is useful for managing long-running tasks or interacting with external services, and can be used in conjunction with models that require reasoning through complex steps, like those using chain-of-thought prompting. The framework supports maintaining and retrieving *semantic memory*, which helps the model to remember past interactions or previously retrieved information to generate more consistent results. Finally, Semantic Kernel can integrate external functions and APIs, making it easy to combine model inference with real-world data.

As [Example 5-10](https://learning.oreilly.com/library/view/llmops/9781098154196/ch05.html#ch05_example_9_1748896666808845) shows, you can use Semantic Kernel to build a modular assistant that can:

-

Retrieve historical information from a knowledge base

-

Use an external API to fetch live data (such as stock prices)

-

Process natural language instructions

-

Perform complex reasoning tasks by chaining multiple AI functions together

##### Example 5-10. Semantic Kernel

```javascript
from semantic_kernel import Kernel
from semantic_kernel.ai.openai import OpenAITextCompletion
from semantic_kernel.memory import MemoryStore
from semantic_kernel.plugins import AzureTextPlugin

kernel = Kernel()
kernel.add_ai("openai", OpenAITextCompletion(api_key="your-openai-api-key"))

# Set up memory for semantic memory handling
memory = MemoryStore()
kernel.add_memory("semantic_memory", memory)

# Define a simple chain-of-thought function
def chain_of_thought(input_text: str) -> str:
    response = kernel.run_ai("openai", "text-davinci-003", input_text)
    return f"Thought Process: {response}"

kernel.add_function("chain_of_thought", chain_of_thought)

user_input = "How does quantum computing work?"

reasoned_output = kernel.invoke("chain_of_thought", user_input)
print("Reasoning Output:", reasoned_output)

kernel.add_plugin("external_api", AzureTextPlugin(api_key="your-azure-api-key"))
external_output = kernel.invoke("external_api", "fetch_knowledge", user_input)
print("External Output:", external_output)
```

You can also integrate external functions (like fetching data from Azure APIs) to further enrich the model’s responses and maintain state across interactions. This makes Semantic Kernel an excellent choice for creating sophisticated AI-driven applications.

While RAG enhances generative models by integrating external knowledge sources for fact-based responses, Semantic Kernel provides a flexible framework for building modular AI systems with advanced reasoning and stateful interactions. If you want to make behavioral changes in a model, however, you should use *fine-tuning.*

# Fine-Tuning

Compared to training from scratch, which requires massive amounts of data and compute, *fine-tuning* allows you to adapt an already-trained model to new tasks with fewer resources. By modifying the model’s parameters based on specific data or behaviors, fine-tuning makes LLMs more effective for specialized applications, whether for handling a particular industry’s terminology or modulating the model’s style and tone. Note that fine-tuning changes a model’s weights, and this means you must have access to it, either directly through a model checkpoint or indirectly, like OpenAI provides through its fine-tuning APIs.

Fine-tuning offers a range of strategies to adapt pretrained models to specialized tasks, improve their efficiency, and ensure they align with user expectations. Techniques like adaptive fine-tuning, adapters, and parameter-efficient methods help tailor LLMs to specific domains, all while reducing resource requirements. Fine-tuning isn’t just about improving task accuracy; it also focuses on adjusting model behavior, ensuring that outputs are ethically sound, efficient, and user-friendly. Whether you’re working with a complex domain-specific model or a general-purpose assistant, fine-tuning makes your models smarter, more efficient, and more aligned with your needs.

In this section, we’ll dive into several key strategies for fine-tuning LLMs, from adaptive fine-tuning to techniques like prefix tuning and parameter-efficient fine-tuning (PEFT), each serving different needs while maintaining efficiency.

## Adaptive Fine-Tuning

*Adaptive fine-tuning* is the process of updating a model’s parameters so it can better handle a specific dataset or task. It involves training the model on new data that is more closely aligned with the task at hand. For example, if you have an LLM that has been pretrained on general web text, adaptive fine-tuning can help it specialize in a particular area like medical texts, legal jargon, or customer service interactions. The goal of adaptive fine-tuning is to adjust the model’s weights in a way that enables it to capture more domain-specific knowledge without forgetting the general understanding it already possesses.

Suppose you’re fine-tuning a model for medical question answering. Your base model might be trained on a diverse dataset, but for the fine-tuning dataset, you’ll use a collection of medical-related texts—such as research papers, clinical notes, and FAQs. Consider the following prompt:

```
Question: What are the symptoms of a heart attack?
Answer: Symptoms of a heart attack include chest pain, shortness of breath, 
nausea, and cold sweats.
```

## Adapters (Single, Parallel, and Scaled Parallel)

*Adapters* are a powerful method for efficient fine-tuning. Instead of retraining the entire model, adapters introduce small, task-specific modules that are trained while leaving the original model’s parameters frozen. This approach makes fine-tuning much more computationally efficient since only a small part of the model is modified. Adapters are particularly useful when you need to apply fine-tuning across multiple tasks, as they allow the model to maintain its general capabilities while adapting to specific contexts. Methods for using adapters include:

Single adapterA single task-specific adapter is added to the model, allowing it to focus on one task. The rest of the model stays unchanged.

Parallel adaptersMultiple adapters can be trained in parallel for different tasks. Each adapter handles its task, and the original model’s weights remain frozen.

Scaled parallel adaptersFor more complex use cases, multiple adapters can be trained at different scales, allowing the model to handle more complex tasks and achieve higher performance without overburdening its architecture.

Say you’re applying the model to two tasks: text summarization and sentiment analysis. You could introduce two parallel adapters, one fine-tuned for summarization and the other for sentiment analysis. The model would utilize the appropriate adapter for each task while still benefiting from its general knowledge.

## Behavioral Fine-Tuning

*Behavioral fine-tuning* focuses on adjusting the model’s behavior to match specific expectations, such as producing more ethical, polite, or user-friendly outputs. In many real-world applications, it’s crucial that language models align with human values, especially when interacting with sensitive topics or making decisions that affect users. Through fine-tuning on data that reflects the desired behavior, the model can learn to produce responses that better adhere to a code of conduct or ethical guidelines. This is particularly useful in customer-service chatbots, healthcare assistants, and other models that interact directly with users.

For a chatbot that provides mental health advice, you could fine-tune the model using datasets that emphasize empathetic responses, ensuring that the model’s replies are both helpful and compassionate. Consider the following prompt and output:

```
User: I'm feeling really down today.
Model (after behavioral fine-tuning): I'm so sorry to hear that. It's important 
to talk to someone when you're feeling this way. Would you like to share more?
```

Behavioral fine-tuning is vital in ensuring that models don’t just deliver accurate responses but also reflect the right tone and ethics.

## Prefix Tuning

*Prefix tuning* is a technique for fine-tuning a model’s behavior for specific tasks without drastically changing its structure or altering its core weights. Instead of modifying the entire model, prefix tuning adjusts only a small, tunable part of the model: the *prefix*, a small input sequence that is prepended to the input data. The model uses the prefix to adapt its outputs to a specific task.

This method is highly efficient because it requires fewer resources than traditional fine-tuning and allows for specialized adaptations without having to retrain the entire model. If you are fine-tuning a model to generate poetry, the prefix might include a sequence that sets the tone or style of the poem, while the model generates the rest of the content accordingly:

```
Prefix: Write a romantic poem in the style of Shakespeare.
Input: 'The evening sky is painted in hues of orange.'
```

Here, only the prefix is adjusted to favor the Shakespearean style, but the rest of the model remains unchanged.

## Parameter-Efficient Fine-Tuning

*Parameter-efficient fine-tuning* (PEFT) is a technique designed to fine-tune large models using minimal resources. Traditional fine-tuning involves modifying the entire model’s parameters, which can be both time-consuming and costly. PEFT techniques, like *low-rank adaptation* (LoRA) and quantized LoRA (qLoRA), focus on modifying only a small, low-ranked portion of the model’s weights, saving on memory and compute resources while maintaining model performance. They are particularly useful when working with very large models, such as GPT-3 or GPT-4, where full fine-tuning would be prohibitively expensive. LoRA introduces a low-rank approximation for the weight updates, reducing the number of parameters that need to be fine-tuned. This makes the process more efficient without sacrificing accuracy. And qLoRA builds on LoRA by incorporating quantization to reduce storage requirements even further, making it ideal for large-scale deployments.

For an LLM deployed in a resource-constrained environment, you could apply LoRA to adjust just the weights that handle specific tasks, such as summarization or question answering. This allows for quicker updates and lowers computational costs.

## Instruction Tuning and Reinforcement Learning from Human Feedback

*Instruction tuning* involves fine-tuning a model so that it follows explicit instructions in a more precise and reliable way. This can be particularly useful when you need the model to consistently perform specific tasks based on user instructions or prompts.

With *reinforcement learning from human feedback *(RLHF), the model receives feedback from humans on its outputs, allowing it to improve over time. This feedback loop helps the model better align with user expectations and improve the relevance, coherence, and overall quality of its responses.

RLHF is often used to fine-tune models for conversational agents or other interactive systems, ensuring that the model’s responses are not only accurate but also helpful and appropriate to the context.

For a virtual assistant, you might first fine-tune the model using instruction tuning to ensure it answers questions directly. Then, using RLHF, you would gather feedback from users on the helpfulness of responses and adjust the model to improve its conversational behavior.

An instruction-tuning prompt might be:

```
Answer the following question directly: What is the capital of France?
```

The output:

```
The capital of France is Paris.
```

An RLHF prompt might be:

```
How do I change the oil in my car?
```

The output:

```
Changing the oil in your car involves draining the old oil, replacing the oil 
filter, and refilling with fresh oil. Would you like a step-by-step guide?
```

With RLHF, the model can continue to learn and improve, aligning its behavior with real-world user needs.

## Choosing Between Fine-Tuning and Prompt Engineering

If you don’t have access to a way to modify the model’s weights and you want to adapt your model for a specific domain, you will have to use prompt engineering. But when both choices are available, which one should you use?

The first thing to consider is the cost, as fine-tuning is expensive in terms of computational costs. You can usually get to a better prompt with a few hours of experimentation, but running a fine-tuning experiment can cost thousands of dollars. A recent price list from OpenAI (as of this writing) lists the fine-tuning cost for its latest GPT-4o model at $25,000 per million tokens.

While fine-tuning charges the costs up front, prompt engineering is more like a mortgage. Developing a larger prompt through prompt engineering will increase your costs for every request, whereas inference costs the same whether the model is fine-tuned or not. One additional thing to consider is that there is a lot of change in the LLM space these days, so the time horizons to recoup costs are likely to be short. If fine-tuning and prompt engineering have the same performance and costs over a 10-year horizon, but the model you’re using will have a 2-year life span, it’s not cost-effective to prepay for 10 years of something that you’re only going to use for 2 years. Prompt engineering in this case would be a better choice in terms of cost.

Even if you have access to the model weights, don’t need to worry about costs, and only want to focus on performance, it helps to know that fine-tuning and prompt engineering solve different problems. Prompt engineering changes what the model *knows about*, giving it more context. RAG does what prompt engineering does, but on a much larger scale, using a system to generate prompts dynamically based on inputs. On the other hand, fine-tuning changes how the model *behaves*. The quadrant diagram in [Figure 5-2](https://learning.oreilly.com/library/view/llmops/9781098154196/ch05.html#ch05_figure_2_1748896666799695) illustrates this.

For example, let’s assume the model you’re using has all the knowledge it needs, but you want it to generate answers using a specific XML format instead of the usual chat outputs because your output will be consumed by another system. In this case, fine-tuning the model will yield much better performance than giving it lots of examples of how you want the output to look through prompt engineering.

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098154196/files/assets/llmo_0502.png)

###### Figure 5-2. LLM and context optimization

It’s worthwhile to point out an unexpected consequence of changing how a model behaves through fine-tuning: it can cause the model to stop doing things it did before. Let’s say you are using a model like GPT-3.5-turbo to generate blog posts about your product, and it’s doing a good job, but the posts are not very technical. An AI engineer suggests fine-tuning the model using the messages in the “product chat” channel inside your company, where people discuss technical features of the product. After fine-tuning the model, you ask it to “generate a 500-word blog post about feature *X* of our product,” something that it would do reasonably well before, just without much technical depth. Now it answers: “I’m too busy.” Fine-tuning changed how the model behaves. In this case, a RAG solution that searches the product chat data and creates a prompt describing feature *X* to the old model would work a lot better.

# Mixture of Experts

Adaptive fine-tuning and PEFT methods optimize the adaptation of large language models by selectively updating parameters or leveraging instruction tuning. A more recent technique, *mixture of experts* (MoE), approaches optimization from a different angle, that of architectural modularity and conditional computation. Unlike fine-tuning, which changes the model’s parameters after training, MoE changes the model’s structure itself by leveraging many “experts,” which are smaller specialized subnetworks inside one big model (see [Figure 5-3](https://learning.oreilly.com/library/view/llmops/9781098154196/ch05.html#ch05_figure_3_1748896666799717)).

Instead of using the whole model to make inferences, a gating system selects and activates only a few of these experts, based on the input. This means that the model uses only part of its capacity to answer each query. The benefit? You can build a huge model with trillions of parameters but keep the computation cost low, because only a small piece of it runs each time.

This is different from adaptive fine-tuning or parameter-efficient tuning in which you update the model to better handle new tasks. MoE lets the model specialize inside itself, which means that some experts get better at certain types of tasks or data, while others focus elsewhere. The model learns to route inputs dynamically, making it flexible across many domains without retraining the whole thing every time.

That said, MoEs aren’t perfect. If the gating system doesn’t spread the work evenly, only a few experts do most of the work, wasting the rest of the model and reducing efficiency. Also, training these models is more complex and requires special software and hardware support to get the speed and cost benefits.

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098154196/files/assets/llmo_0503.png)

###### Figure 5-3. A visualization of how MoE works (source: [“Mixture of Experts”](https://oreil.ly/r4ys1))

MoE models like GShard, DeepSeek, and others change how LLMs handle scale by splitting the model into many smaller expert subnetworks and selectively activating only a few for each input token. The key to this capability is the gating network, a small module that uses the hidden state of each token to produce a score for every expert. In GShard, these scores go through a softmax function, which converts a vector of raw prediction scores into a probability distribution over all experts. The top two experts per token are selected, and the token’s representation is sent to both experts, weighted by their gating probabilities. This routing of work to two experts can improve the model’s expressiveness but increases communication overhead, since tokens must be sent to multiple experts on different devices.

Switch Transformer, on the other hand, simplifies this by using hard routing. *Hard routing* requires the gating to pick the single expert with the highest score for each token. This means each token activates only one expert, reducing cross-device communication and memory usage. The gating output is a one-shot vector indicating which expert is responsible, and this top-one routing cuts down the data that needs to move between accelerators.

One common challenge for all MoE models is *load balancing*. Without constraints, the gating tends to funnel most tokens to a small set of popular experts, causing some experts to be overloaded while others remain idle. This expert collapse wastes capacity and slows training convergence. To fix this, training adds a load-balancing loss term to the main objective. This loss term measures how tokens are distributed across experts by first calculating the fraction of tokens assigned and the gating probability mass for each expert. It then computes the coefficient of variation across these values and penalizes uneven distributions, forcing the gating network to spread tokens more uniformly. This keeps all experts busy and fully utilizes the model’s parameter budget.

Each expert has a fixed capacity in that it can process only a limited number of tokens per batch to fit within memory constraints. If too many tokens are routed to an expert, excess tokens are either dropped or rerouted. Although such token dropping can prevent memory overflow, it can also cause some input data to be ignored during training—a trade-off that needs careful tuning.

During *backpropagation*, gradients flow only through the experts that were activated for each token. Experts not involved in processing a given token receive no gradient updates. Thus, computation and memory use are less than they would otherwise be, given the model’s huge parameter count. This sparsity in gradient flow is one reason MoEs can scale efficiently.

Training MoEs is tricky, and the process can be unstable. Researchers use several techniques to enhance stability. For example, gating weights are carefully initialized to avoid extreme outputs early on, dropout can be applied to gating outputs to prevent the gating network from becoming overconfident based on a few experts, and gradient clipping can be used to keep updates ​stable. Load balancing losses not only improves utilization but also helps to stabilize routing decisions during training.

Overall, MoE is another way to make huge models more scalable and adaptable. That said, it often complements rather than replaces fine-tuning methods.

# Model Optimization for Resource-Constrained Devices

Optimizing a model for resource-limited devices ensures that it runs smoothly on low-power hardware like mobile devices or edge devices.

*Compression techniques* help reduce the computational and memory footprint of these models while maintaining their performance. This is particularly important for deploying LLMs on edge devices or optimizing their runtime in cloud environments. There are several techniques to compress LLMs. Let’s look into them one by one:

Prompt cachingPrompt caching involves storing previously computed responses for frequently occurring prompts. Instead of rerunning the entire model, the cached results are quickly retrieved and returned. This is particularly useful for scenarios where the same or similar prompts are repeatedly queried, such as with customer support chatbots or knowledge retrieval systems, and for accelerating inference by avoiding redundant computations or reducing costs in high-traffic systems.

Key–value cachingKey–value (KV) caching optimizes transformer-based LLMs by caching attention-related computations, especially in scenarios involving sequential or streaming input data. By storing the key (K) and value (V) tensors computed during forward passes, subsequent tokens can reuse these precomputed tensors, reducing redundancy in computation.

KV caching comes in handy when speeding up autoregressive generation (as with GPT-style models) or improving latency for generating long texts.

QuantizationQuantization reduces the precision of the model’s weights, such as from 32-bit floating point to 8-bit or even 4-bit. This drastically reduces memory requirements and speeds up inference without a substantial loss in model accuracy. There are different types of quantization techniques. In  *static quantization*, weights and activations are quantized before runtime. In  *dynamic quantization*, activations are quantized on the fly during runtime. Finally, with *quantization-aware training* (QAT), the model is trained to account for quantization effects, leading to better accuracy after quantization.

PruningPruning removes less significant weights, neurons, or entire layers from the model, reducing its size and computational complexity. *Structured pruning* removes components systematically (like neurons in a layer), while *unstructured pruning* removes individual weights based on importance.

DistillationModel distillation trains a smaller “student” model to replicate the behavior of a larger “teacher” model. The student model learns by mimicking the teacher’s outputs, including logits or intermediate ​layer representations.

# Lessons for Effective LLM Development

Training LLMs is a complex process requiring precise strategies to balance efficiency, cost, and performance. Best practices in this space keep evolving. This section looks at some optimizations we haven’t covered yet, including scaling laws, model size versus data trade-offs, learning-rate optimizations, pitfalls like overtraining, and innovative techniques like speculative sampling.

## Scaling Law

Scaling laws ([Example 5-11](https://learning.oreilly.com/library/view/llmops/9781098154196/ch05.html#ch05_example_10_1748896666808859)) describe how model performance improves with increases in data, model size, or compute. Research has shown that performance gains often follow a predictable curve, with diminishing returns beyond certain thresholds. The balance lies in optimizing the interplay between model size and training data. Doubling both the model size and the training dataset typically results in better performance than doubling only one. It’s also important to know that models can become undertrained or overparameterized if the data isn’t scaled appropriately.

##### Example 5-11. Scaling law

```
import matplotlib.pyplot as plt
import numpy as np

# Simulate scaling law data
model_sizes = np.logspace(1, 4, 100)  # Model sizes from 10^1 to 10^4
performance = np.log(model_sizes) / np.log(10)  # Simulated performance improvement

# Plot the scaling law
plt.plot(model_sizes, performance, label="Scaling Law")
plt.xscale("log")
plt.xlabel("Model Size (log scale)")
plt.ylabel("Performance")
plt.title("Scaling Law for LLMs")
plt.legend()
plt.show()
```

## Chinchilla Models

Chinchilla models ([Example 5-12](https://learning.oreilly.com/library/view/llmops/9781098154196/ch05.html#ch05_example_11_1748896666808874)) challenge the paradigm of building increasingly larger models. Instead, they prioritize training on more data while keeping the model size fixed. This approach achieves comparable or even better performance at lower costs. For a fixed compute budget, smaller models trained on larger datasets outperform larger models trained on limited data.

##### Example 5-12. Chinchilla model

```
model_size = "medium"  # Fixed model size
data_multiplier = 4    # Increase dataset size

model = load_model(size=model_size)
dataset = augment_dataset(original_dataset, multiplier=data_multiplier)

train_model(model, dataset)
evaluate_model(model)
```

## Learning-Rate Optimization

Choosing the right learning rate is critical for effective training. An optimal learning rate allows models to converge faster and avoid pitfalls like vanishing gradients or oscillations. Gradually increase the learning rate at the start of training to stabilize convergence. Then, smoothly reduce the learning rate over time for better final convergence. To do this, try running the code in [Example 5-13](https://learning.oreilly.com/library/view/llmops/9781098154196/ch05.html#ch05_example_12_1748896666808889).

##### Example 5-13. Optimizing the learning rate

```
print(f"Epoch {epoch}, Learning Rate: {scheduler.get_last_lr()}")
    from torch.optim.lr_scheduler import CosineAnnealingLR import torch

model = torch.nn.Linear(10, 2)
optimizer = torch.optim.Adam(model.parameters(), lr=0.1)

# Cosine learning rate scheduler
scheduler = CosineAnnealingLR(optimizer, T_max=50)

# Training loop
for epoch in range(100):
    # Forward pass, loss computation, backpropagation...
    optimizer.step()
    scheduler.step()
```

*Overtraining *occurs when a model becomes too well adapted to the training dataset and thus overly specialized, leading to poor generalization on unseen data. If you find that validation loss increases while training loss decreases, or if your model’s predictions on test data are overly confident but incorrect, the model may be overtrained. Early stopping and other regularization techniques help mitigate this. *Regularization* involves adding a penalty term to the model’s loss function to discourage it from learning overly complex relationships with the training data. With *early stopping* ([Example 5-14](https://learning.oreilly.com/library/view/llmops/9781098154196/ch05.html#ch05_example_13_1748896666808902)), a performance metric (like accuracy or loss) is monitored on a validation set, and the training is halted when this metric plateaus or deteriorates.

##### Example 5-14. Early stopping

```
from pytorch_lightning.callbacks import EarlyStopping

# Define early stopping
early_stopping = EarlyStopping(monitor="val_loss", patience=3, verbose=True)

trainer = Trainer(callbacks=[early_stopping])
trainer.fit(model, train_dataloader, val_dataloader)
```

## Speculative Sampling

*Speculative sampling* is a method to speed up autoregressive decoding during inference. It involves using a smaller, faster model to predict multiple token candidates, which are then verified by the larger model. This can be really useful for applications requiring low-latency generation, like real-time conversational agents.

Understanding different training strategies and pitfalls is important for optimizing LLMs. Techniques like scaling laws and Chinchilla models guide compute-efficient training, while learning-rate optimization and speculative sampling improve both training and inference dynamics. Also, avoiding overtraining ensures that models generalize well to real-world data. Incorporating these lessons will lead to more robust and cost-effective LLMs.

# Conclusion

In this chapter, you learned about critical aspects of optimizing the deployment of LLMs. From understanding the methods of domain adaptation like prompt engineering, fine-tuning, and retrieval-augmented generation (RAG) to exploring efficient model deployment strategies, the chapter covered the foundational knowledge you need to adapt LLMs for specific tasks and resource constraints. Each method has unique strengths, allowing developers to align the model’s behavior, knowledge, or outputs with organizational needs and technical limitations. We know historically that there will be naming and renaming of a lot terms and techniques in AI/ML. By the time this book comes out, you may hear terms like context engineering, the fundamentals of which we have already covered in this book. Regardless, the term you use doesn’t matter for engineering LLMs as long as you build for the key goals of LLMOps systems: reliability, scalability, robustness, and security.

The chapter also examined how to optimize LLMs for resource-constrained environments through techniques such as quantization, pruning, and distillation, with an emphasis on the importance of balancing computational cost with performance.

# References

Karpathy, Andrej. [“Let’s Build GPT: From Scratch, in Code, Spelled Out”](https://oreil.ly/PfnyZ), YouTube, January 17, 2023.

Kimothi, Abhinav. [“3 LLM Architectures”](https://oreil.ly/A-C1L), *Medium*, July 24, 2023.

Microsoft. [“Introduction to Semantic Kernel”](https://oreil.ly/xrjkE), June 24, 2024.

Wang, Zian (Andy). [“Mixture of Experts: How an Ensemble of AI Models Decide As One”](https://oreil.ly/stFQa), Deepgram, June 27, 2024.
