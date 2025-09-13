# 6 Building autonomous assistants

### This chapter covers

- Behavior trees for robotics and AI apps
- GPT Assistants Playground and creating assistants and actions
- Autonomous control of agentic behavior trees
- Simulating conversational multi-agent systems via agentic behavior trees
- Using back chaining to create behavior trees for complex systems

Now that we’ve covered how actions extend the power/capabilities of agents, we can look at how behavior trees can guide agentic systems. We’ll start by understanding the basics of behavior trees and how they control robotics and AI in games.

We’ll return to agentic actions and examine how actions can be implemented on the OpenAI Assistants platform using the GPT Assistants Playground project. From there, we’ll look at how to build an autonomous agentic behavior tree (ABT) using OpenAI assistants. Then, we’ll move on to understanding the need for controls and guardrails on autonomous agents and using control barrier functions.

In the final section of the chapter, we’ll examine the use of the AgentOps platform to monitor our autonomous behavior-driven agentic systems. This will be an exciting chapter with several challenges. Let’s begin by jumping into the next section, which introduces behavior trees.

## 6.1 Introducing behavior trees

Behavior trees are a long-established pattern used to control robotics and AI in games. Rodney A. Brooks first introduced the concept in his “A Robust Layered Control System for a Mobile Robot” paper in 1986. This laid the groundwork for a pattern that expanded on using the tree and node structure we have today.[](https://livebook.manning.com/book/ai-agents-in-action/chapter-6)

If you’ve ever played a computer game with nonplayer characters (NPCs) or interacted with advanced robotic systems, you’ve witnessed behavior trees at work. Figure 6.1 shows a simple behavior tree. The tree represents all the primary nodes: selector or fallback nodes, sequence nodes, action nodes, and condition nodes.[](https://livebook.manning.com/book/ai-agents-in-action/chapter-6)

![Figure 6.1 A simple behavior tree of eating an apple or a pear](https://drek4537l1klr.cloudfront.net/lanham2/Figures/6-1.png)

Table 6.1 describes the functions and purpose of the primary nodes we’ll explore in this book. There are other nodes and node types, and you can even create custom nodes, but for now, we’ll focus on those in the table.

##### Table 6.1 The primary nodes used in behavior trees

| <br>     <br>       Node <br> | <br>     <br>       Purpose <br> | <br>     <br>       Function <br> | <br>     <br>       Type <br> |
| --- | --- | --- | --- |
| <br>     <br>       Selector (fallback) <br> | <br>     <br>       This node works by selecting the first child that completes successfully. It’s often called the fallback node because it will always fall back to the last successful node that executed. <br> | <br>     <br>       The node calls its children in sequence and stops executing when the first child succeeds. When a child node succeeds, it will return success; if no nodes succeed, it returns failure. <br> | <br>     <br>       Composite <br> |
| <br>     <br>       Sequence <br> | <br>     <br>       This node executes all of its children in sequence until one node fails or they all complete successfully. <br> | <br>     <br>       The node calls each of its children in sequence regardless of whether they fail or succeed. If all children succeed, it returns success, and failure if just one child fails. <br> | <br>     <br>       Composite <br> |
| <br>     <br>       Condition <br> | <br>     <br>       Behavior trees don’t use Boolean logic but rather success or failure as a means of control. The condition returns success if the condition is true and false otherwise. <br> | <br>     <br>       The node returns success or failure based on a condition. <br> | <br>     <br>       Task <br> |
| <br>     <br>       Action <br> | <br>     <br>       This is where the action happens. <br> | <br>     <br>       The node executes and returns success if successful or returns failure otherwise. <br> | <br>     <br>       Task <br> |
| <br>     <br>       Decorator <br> | <br>     <br>       They work by controlling the execution of child nodes. They are often referred to as conditionals because they can determine whether a node is worth executing or safe to execute. <br> | <br>     <br>       The node controls execution of the child nodes. Decorators can operate as control barrier functions to block or prevent unwanted behaviors. <br> | <br>     <br>       Decorator <br> |
| <br>     <br>       Parallel <br> | <br>     <br>       This node executes all of its nodes in parallel. Success or failure is controlled by a threshold of the number of children needed to succeed to return success. <br> | <br>     <br>       The node executes all of its child nodes in sequence regardless of the status of the nodes. <br> | <br>     <br>       Composite <br> |

The primary nodes in table 6.1 can provide enough functionality to handle numerous use cases. However, understanding behavior trees initially can be daunting. You won’t appreciate their underlying complexity until you start using them. Before we build some simple trees, we want to look at execution in more detail in the next section.

### 6.1.1 Understanding behavior tree execution

Understanding how behavior trees execute is crucial to designing and implementing behavior trees. Unlike most concepts in computer science, behavior trees operate in terms of success and failure. When a node in a behavior tree executes, it will return either success or failure; this even applies to conditions and selector nodes.[](https://livebook.manning.com/book/ai-agents-in-action/chapter-6)

Behavior trees execute from top to bottom and left to right. Figure 6.2 shows the process and what happens if a node fails or succeeds. In the example, the AI the tree controls has an apple but no pear. In the first sequence node, a condition checks if the AI has an apple. Because the AI doesn’t have an apple, it aborts the sequence and falls back to the selector. The selector then selects its next child node, another sequence, that checks if the AI has a pear, and because it does, the AI eats the apple.

![Figure 6.2 The execution process of a simple behavior tree](https://drek4537l1klr.cloudfront.net/lanham2/Figures/6-2.png)

Behavior trees provide control over how an AI system will execute at a macro or micro level. Regarding robotics, behavior trees will typically be designed to operate at the micro level, where each action or condition is a small event, such as detecting the apple. Conversely, behavior trees can also control more macro systems, such as NPCs in games, where each action may be a combination of events, like attacking the player.

For agentic systems, behavior trees support controlling an agent or assistant at your chosen level. We’ll explore controlling agents at the task and, in later chapters, the planning levels. After all, with the power of LLMs, agents can construct their own behavior tree.

Of course, several other forms of AI control could be used to control agentic systems. The next section will examine those different systems and compare them to behavior trees.

### 6.1.2 Deciding on behavior trees

Numerous other AI control systems have benefits and are worth exploring in controlling agentic systems. They can demonstrate the benefits of behavior trees and provide other options for specific use cases. The behavior tree is an excellent pattern, but it isn’t the only one, and it’s worth learning about others.[](https://livebook.manning.com/book/ai-agents-in-action/chapter-6)

Table 6.2 highlights several other systems we may consider for controlling AI systems. Each item in the table describes what the method does, its shortcomings, and its possible application to agentic AI control.

##### Table 6.2 Comparison of other AI control systems

| <br>     <br>       Control name <br> | <br>     <br>       Description <br> | <br>     <br>       Shortcomings <br> | <br>     <br>       Control agentic AI? <br> |
| --- | --- | --- | --- |
| <br>     <br>       Finite state machine <br>      a (FSM) <br> | <br>     <br>       FSMs model AI using a set of states and transitions triggered by events or conditions. <br> | <br>     <br>       FSMs can become unwieldy with increasing complexity. <br> | <br>     <br>       FSMs aren’t practical for agents because they don’t scale well. <br> |
| <br>     <br>       Decision tree <br>      b <br> | <br>     <br>       Decision trees use a tree-like model of decisions and their possible consequences. <br> | <br>     <br>       Decision trees can suffer from overfitting and lack generalization in complex scenarios. <br> | <br>     <br>       Decision trees can be adapted and enhanced with behavior trees. <br> |
| <br>     <br>       Utility-based system <br>      b <br> | <br>     <br>       Utility functions evaluate and select the best action based on the current situation. <br> | <br>     <br>       These systems require careful design of utility functions to balance priorities. <br> | <br>     <br>       This pattern can be adopted within a behavior tree. <br> |
| <br>     <br>       Rule-based system <br>      a <br> | <br>     <br>       This set of if-then rules define the behavior of the AI. <br> | <br>     <br>       These systems can become cumbersome with many rules, leading to potential conflicts. <br> | <br>     <br>       These aren’t very practical when paired with agentic systems powered by LLMs. <br> |
| <br>     <br>       Planning system <br>      c <br> | <br>     <br>       Planning systems generate a sequence of actions to achieve a specific goal using planning algorithms. <br> | <br>     <br>       These systems are computationally expensive and require significant domain knowledge. <br> | <br>     <br>       Agents can already implement such patterns on their own as we’ll see in later chapters. <br> |
| <br>     <br>       Behavioral cloning <br>      c <br> | <br>     <br>       Behavioral cloning refers to learning policies by mimicking expert demonstrations. <br> | <br>     <br>       This system may struggle with generalization to unseen situations. <br> | <br>     <br>       This can be incorporated into behavior trees or into a specific task. <br> |
| <br>     <br>       Hierarchical Task Network (HTN) <br>      d <br> | <br>     <br>       HTNs decompose tasks into smaller, manageable subtasks arranged in a hierarchy. <br> | <br>     <br>       These are complex to manage and design for very large tasks. <br> | <br>     <br>       HTNs allow for better organization and execution of complex tasks. This pattern can be used for larger agentic systems. <br> |
| <br>     <br>       Blackboard system <br>      b <br> | <br>     <br>       These systems feature collaborative problem-solving using a shared blackboard for different subsystems. <br> | <br>     <br>       These systems are difficult to implement and manage communication between subsystems. <br> | <br>     <br>       Agentic systems can implement similar patterns using conversation or group chats/threads. <br> |
| <br>     <br>       Genetic algorithm (GA) <br>      d <br> | <br>     <br>       These optimization techniques are inspired by natural selection to evolve solutions to solve problems. <br> | <br>     <br>       GAs are computationally intensive and may not always find the optimal solution. <br> | <br>     <br>       GAs have potential and could even be used to optimize behavior trees. <br> |
| <br>      <br>      a Not practical when considering complex agentic systems <br>      <br>      <br>      b Exists in behavior trees or can easily be incorporated <br>      <br>      <br>      c Typically applied at the task or action/condition level <br>      <br>      <br>      d Advanced systems that would require heavy lifting when applied to agents <br> |  |  |  |

In later chapters of this book, we’ll investigate some of the patterns discussed in table 6.2. Overall, several patterns can be enhanced or incorporated using behavior trees as the base. While other patterns, such as FSMs, may be helpful for small experiments, they lack the scalability of behavior trees.

Behavior trees can provide several benefits as an AI control system, including scalability. The following list highlights other notable benefits of using behavior trees:

-  *Modularity and reusability*—Behavior trees promote a modular approach to designing behaviors, allowing developers to create reusable components. Nodes in a behavior tree can be easily reused across different parts of the tree or even in different projects, enhancing maintainability and reducing development time.
-  *Scalability*—As systems grow in complexity, behavior trees handle the addition of new behaviors more gracefully than other methods, such as FSMs. Behavior trees allow for the hierarchical organization of tasks, making it easier to manage and understand large behavior sets.
-  *Flexibility and extensibility*—Behavior trees offer a flexible framework where new nodes (actions, conditions, decorators) can be added without drastically altering the existing structure. This extensibility makes it straightforward to introduce new behaviors or modify existing ones to adapt to new requirements.
-  *Debugging and visualization*—Behavior trees provide a clear and intuitive visual representation of behaviors, which is beneficial for debugging and understanding the decision-making process. Tools that support behavior trees often include graphical editors that allow developers to visualize and debug the tree structure, making it easier to identify and fix problems.
-  *Decoupling of decision logic*—Behavior trees separate the decision-making and execution logic, promoting a clear distinction between high-level strategy and low-level actions. This decoupling simplifies the design and allows for more straightforward modifications and testing of specific behavior parts without affecting the entire system.

Having made a strong case for behavior trees, we should now consider how to implement them in code. In the next section, we look at how to build a simple behavior tree, using Python code.[](https://livebook.manning.com/book/ai-agents-in-action/chapter-6)

### 6.1.3 Running behavior trees with Python and py_trees

Because behavior trees have been around for so long and have been incorporated into many technologies, creating a sample demonstration is very simple. Of course, the easiest way is to ask ChatGPT or your favorite AI chat tool. Listing 6.1 shows the result of using a prompt to generate the code sample and submitting figure 6.1 as the example tree. The final code had to be corrected for simple naming and parameter errors.[](https://livebook.manning.com/book/ai-agents-in-action/chapter-6)

Note  All the code for this chapter can be found by downloading the GPT Assistants Playground project at [https://mng.bz/Ea0q](https://mng.bz/Ea0q).

##### Listing 6.1 `first_btree.py`

```
import py_trees

class HasApple(py_trees.behaviour.Behaviour):      #1
    def __init__(self, name):
        super(HasApple, self).__init__(name)

    def update(self):        
        if True:  
            return py_trees.common.Status.SUCCESS
        else:
            return py_trees.common.Status.FAILURE
# Other classes omitted…

has_apple = HasApple(name="Has apple")      #2
eat_apple = EatApple(name="Eat apple")      #2
sequence_1 = py_trees.composites.Sequence(name="Sequence 1", memory=True)
sequence_1.add_children([has_apple, eat_apple])                              #3

has_pear = HasPear(name="Has pear")         #4
eat_pear = EatPear(name="Eat pear")         #4
sequence_2 = py_trees.composites.Sequence(name="Sequence 2", memory=True)
sequence_2.add_children([has_pear, eat_pear])               #3                

root = py_trees.composites.Selector(name="Selector", memory=True)
root.add_children([sequence_1, sequence_2])          #3                       

behavior_tree = py_trees.trees.BehaviourTree(root)     #5

py_trees.logging.level = py_trees.logging.Level.DEBUG   
for i in range(1, 4):                                                      #6
    print("\n------------------ Tick {0} ------------------".format(i))
    behavior_tree.tick()                                                  #6

### Start of output
------------------ Tick 1 ------------------
[DEBUG] Selector             : Selector.tick()
[DEBUG] Selector             : Selector.tick() [!RUNNING->reset current_child]
[DEBUG] Sequence 1           : Sequence.tick()
[DEBUG] Has apple            : HasApple.tick()
[DEBUG] Has apple            : HasApple.stop(Status.INVALID->Status.SUCCESS)
[DEBUG] Eat apple            : EatApple.tick()
Eating apple
[DEBUG] Eat apple            : EatApple.stop(Status.INVALID->Status.SUCCESS)
[DEBUG] Sequence 1           : Sequence.stop()[Status.INVALID->Status.SUCCESS]
```

The code in listing 6.1 represents the behavior tree in figure 6.1. You can run this code as is or alter what the conditions return and then run the tree again. You can also change the behavior tree by removing one of the sequence nodes from the root selector.

Now that we have a basic understanding of behavior trees, we can move on to working with agents/assistants. Before doing that, we’ll look at a tool to help us work with OpenAI Assistants. This tool will help us wrap our first ABTs around OpenAI Assistants.[](https://livebook.manning.com/book/ai-agents-in-action/chapter-6)

## 6.2 Exploring the GPT Assistants Playground

For the development of this book[](https://livebook.manning.com/book/ai-agents-in-action/chapter-6), several GitHub projects were created to address various aspects of building agents and assistants. One such project, the GPT Assistants Playground, is built using Gradio for the interface that mimics the OpenAI Assistants Playground but with several extras added.[](https://livebook.manning.com/book/ai-agents-in-action/chapter-6)

The Playground project was developed as both a teaching and demonstration aid. Inside the project, the Python code uses the OpenAI Assistants API to create a chat interface and an agentic system to build and power assistants. There is also a comprehensive collection of actions assistants you can use, and you can easily add your own actions.

### 6.2.1 Installing and running the Playground

The following listing shows installing and running the Playground project from the terminal. There is currently no PyPI package to install. [](https://livebook.manning.com/book/ai-agents-in-action/chapter-6)

##### Listing 6.2 Installing the GPT Assistants Playground

```bash
# change to a working folder and create a new Python virtual environment
git clone 
 https://github.com/cxbxmxcx/GPTAssistantsPlayground     #1
cd GPTAssistantsPlayground      #2
pip install -r requirements.txt      #3
```

You can run the application from the terminal or using Visual Studio Code (VS Code), with the latter giving you more control. Before running the application, you need to set your OpenAI API key through the command line or by creating an `.env` file, as we’ve done a few times already. Listing 6.3 shows an example of setting the environment variable on Linux/Mac or the Git Bash shell (Windows recommended) and running the application.[](https://livebook.manning.com/book/ai-agents-in-action/chapter-6)

##### Listing 6.3 Running the GPT Assistants Playground

```
export OPENAI_API_KEY="your-api-key"      #1
python main.py     #2
```

Open your browser to the URL displayed (typically `http://127.0.0.1:7860`) or what is mentioned in the terminal. You’ll see an interface similar to that shown in figure 6.3. If you’ve already defined the OpenAI Assistants, you’ll see them in the Select Assistant dropdown.

![Figure 6.3 The GPT Assistants Playground interface being used to learn math](https://drek4537l1klr.cloudfront.net/lanham2/Figures/6-3.png)

If you’ve never defined an assistant, you can create one and choose the various options and instructions you need. If you’ve visited the OpenAI Playground, you’ve already experienced a similar interface.

##### GPT vs. an assistant

OpenAI defines a GPT as the assistant you can run and use within the ChatGPT interface. An assistant can only be consumed through the API and requires custom code in most cases. When you run an assistant, you’re charged according to the model token usage and any special tools, including the Code Interpreter and files, whereas a GPT runs within ChatGPT and is covered by account costs.

The reason for creating a local version of the Playground was an exercise to demonstrate the code structure but also provide additional features listed here:

-  *Actions (custom actions)*—Creating your own actions allows you to add any functionality you want to an assistant. As we’ll see, the Playground makes it very easy to create your own actions quickly.
-  *Code runner*—The API does come with a Code Interpreter, but it’s relatively expensive ($.03 per run), doesn’t allow you to install your modules, can’t run code interactively, and runs slowly. The Playground will enable you to run Python code locally in an isolated virtual environment. While not as secure as pushing code out to Docker images, it does execute code windowed and out of process better than other platforms.
-  *Transparency and logging*—The Playground provides for comprehensive capturing of logs and will even show how the assistant uses internal and external tools/actions. This can be an excellent way to see what the assistant is doing behind the scenes.

Each of these features is covered in more detail over the next few sections. We’ll start with a look at using and consuming actions in the next section.

### 6.2.2 Using and building custom actions

Actions and tools are the building blocks that empower agents and assistants. Without access to tools, agents are functionless chatbots. The OpenAI platform is a leader in establishing many of the patterns for tools, as we saw in chapter 3.[](https://livebook.manning.com/book/ai-agents-in-action/chapter-6)

The Playground provides several custom actions that can be attached to assistants through the interface. In this next exercise, we’ll build a simple assistant and attach a couple of custom actions to see what is possible.

Figure 6.4 shows the expanded Actions accordion, which displays many available custom actions. Run the Playground from the terminal or debugger, and create a new assistant. Then, select the actions shown in the figure. After you’re done selecting the actions, scroll to the bottom, and click Add Assistant to add the assistant. Assistants need to be created before they can be used.

![Figure 6.4 Selecting and using custom actions in the interface](https://drek4537l1klr.cloudfront.net/lanham2/Figures/6-4.png)

After you create the assistant, you can ask it to list all available assistants. Listing the assistants also gives you the IDs required to call the assistant. You can also call other assistants and ask them to complete tasks in their area of specialization.

Adding your custom actions is as simple as adding code to a file and dropping it in the right folder. Open the `playground/assistant_actions` folder from the main project folder, and you’ll see several files that define the various actions. Open the `file_actions.py` file in VS Code, as shown in listing 6.4.

##### Listing 6.4 `playground/assistant_actions/file_actions.py`

```
import os

from playground.actions_manager import agent_action

OUTPUT_FOLDER = "assistant_outputs"


@agent_action     #1
def save_file(filename, content):      #2
    """
    Save content to a file.      #3

    :param filename: The name of the file including extension.
    :param content: The content to save in the file.
    """
    file_path = os.path.join(OUTPUT_FOLDER, filename)
    with open(file_path, "w", encoding="utf-8") as file:
        file.write(content)
    print(f"File '{filename}' saved successfully.")      #4
```

You can add any custom action you want by placing the file in the `assistant_actions` folder and decorating it with the `agent_action` decorator. Just make sure to give the function a good name and enter quality documentation for how the function should be used. When the Playground starts up, it loads all the actions in the folder that are decorated correctly and have descriptions/documentation.

It’s that simple. You can add several custom actions as needed. In the next section, we’ll look at a special custom action that allows the assistant to run code locally.

### 6.2.3 Installing the assistants database

To run several of the examples in this chapter, you’ll need to install the assistants database. Fortunately, this can be easily done through the interface and just by asking agents. The upcoming instructions detail the process for installing the assistants and are taken directly from the GPT Assistants Playground README. You can install several of the demo assistants located in the `assistants.db` SQLite database:[](https://livebook.manning.com/book/ai-agents-in-action/chapter-6)

1.  Create a new assistant, or use an existing assistant.
1.  Give the assistant the `create_manager_assistant` action (found under the Actions section).
1.  Ask the assistant to create the manager assistant (i.e., “please create the manager assistant”), and be sure to name the assistant “Manager Assistant.”
1.  Refresh your browser to reload the assistants selector.
1.  Select the new Manager Assistant. This assistant has the instructions and actions that will allow it to install assistants from the `assistants.db` database.
1.  Talk to the Manager Assistant to give you a list of assistants to install, or just ask the Manager Assistant to install all available assistants.

### 6.2.4 Getting an assistant to run code locally

Getting agents and assistants to generate and run executable code has a lot of power. Unlike the Code Interpreter, running code locally provides numerous opportunities to iterate and tune quickly. We saw this earlier with AutoGen, where the agents could keep running the code until it worked as expected.[](https://livebook.manning.com/book/ai-agents-in-action/chapter-6)

In the Playground, it’s a simple matter to select the custom action `run_code`, as shown in figure 6.5. You’ll also want to choose the `run_shell_command` action because it allows the assistant to `pip install` any required modules.

![Figure 6.5 Selecting custom actions for the assistant to run Python code](https://drek4537l1klr.cloudfront.net/lanham2/Figures/6-5.png)

You can now ask an assistant to generate and run the code to be sure it works on your behalf. Try this out by adding the custom actions and asking the assistant to generate and run code, as shown in figure 6.6. If the code doesn’t work as expected, tell the assistant what problems you encountered.

![Figure 6.6 Getting the assistant to generate and run Python code](https://drek4537l1klr.cloudfront.net/lanham2/Figures/6-6.png)

Again, the Python code running in the Playground creates a new virtual environment in a project subfolder. This system works well if you’re not running any operating system–level code or low-level code. If you need something more robust, a good option is AutoGen, which uses Docker containers to run isolated code.

Adding actions to run code or other tasks can make assistants feel like a black box. Fortunately, the OpenAI Assistants API allows you to consume events and see what the assistant is doing behind the scenes. In the next section, we’ll see what this looks like.

### 6.2.5 Investigating the assistant process through logs

OpenAI added a feature into the Assistants API that allows you to listen to events and actions chained through tool/action use. This feature has been integrated into the Playground, capturing action and tool use when an assistant calls another assistant. [](https://livebook.manning.com/book/ai-agents-in-action/chapter-6)

We can try this by asking an assistant to use a tool and then open the log. A great example of how you can do this is by giving an assistant the Code Interpreter tool and then asking it to plot an equation. Figure 6.7 shows an example of this exercise.

![Figure 6.7 Internal assistant logs being captured](https://drek4537l1klr.cloudfront.net/lanham2/Figures/6-7.png)

Usually, when the Assistant Code Interpreter tool is enabled, you don’t see any code generation or execution. This feature allows you to see all tools and actions used by the assistant as they happen. Not only is it an excellent tool for diagnostics, but it also provides additional insights into the functions of LLMs.

We haven’t reviewed the code to do all this because it’s extensive and will likely undergo several changes. That being said, if you plan on working with the Assistants API, this project is a good place to start. With the Playground introduced, we can continue our journey into ABTs in the next section.[](https://livebook.manning.com/book/ai-agents-in-action/chapter-6)

## 6.3 Introducing agentic behavior trees

Agentic behavior trees (ABTs) implement behavior trees on assistant and agent systems. The key difference between regular behavior trees and ABTs is that they use prompts to direct actions and conditions. Because prompts may return a high occurrence of random results, we could also name these trees *stochastic* behavior trees, which do exist. For simplicity, we’ll differentiate behavior trees used to control agents, referring to them as agentic.[](https://livebook.manning.com/book/ai-agents-in-action/chapter-6)

Next, we’ll undertake an exercise to create an ABT. The finished tree will be written in Python but will require the setup and configuration of various assistants. We’ll cover how to manage assistants using the assistants themselves.

### 6.3.1 Managing assistants with assistants

Fortunately, the Playground can help us quickly manage and create the assistants. We’ll first install the Manager Assistant, followed by installing the predefined assistants. let’s get started with installing the Manager Assistant using the following steps:[](https://livebook.manning.com/book/ai-agents-in-action/chapter-6)

1.  Open Playground in your browser, and create a new simple assistant or use an existing assistant. If you need a new assistant, create it and then select it.
1.  With the assistant selected, open the Actions accordion, and select the `create_ manager_assistant` action. You don’t need to save; the interface will update the assistant automatically.[](https://livebook.manning.com/book/ai-agents-in-action/chapter-6)
1.  Now, in the chat interface, prompt the assistant with the following: “Please create the manager assistant.”
1.  After a few seconds, the assistant will say it’s done. Refresh your browser, and confirm that the Manager Assistant is now available. If, for some reason, the new assistant isn’t shown, try restarting the Gradio app itself.

The Manager Assistant is like an admin that has access to everything. When engaging the Manager Assistant, be sure to be specific about your requests. With the Manager Assistant active, you can now install new assistants used in the book using the following steps:

1.  Select the Manager Assistant. If you’ve modified the Manager Assistant, you can delete it and reinstall it anytime. Although it’s possible to have multiple Manager Assistants, it’s not recommended.
1.  Ask the Manager Assistant what assistants can be installed by typing the following in the chat interface:

```
Please list all the installable assistants.
```

1.  Identify which assistant you want installed when you ask the Manager Assistant to install it:

```
Please install the Python Coding Assistant.
```

You can manage and install any available assistants using the Playground. You can also ask the Manager Assistant to save the definitions of all your assistants as JSON:

```
Please save all the assistants as JSON to a file called assistants.json.
```

The Manager Assistant can access all actions, which should be considered unique and used sparingly. When crafting assistants, it’s best to keep them goal specific and limit the actions to just what they need. This not only avoids giving the AI too many decisions but also avoids accidents or mistakes caused by hallucinations.

As we go through the remaining exercises in this chapter, you’ll likely need to install the required assistants. Alternatively, you can ask the Manager Assistant to install all available assistants. Either way, we look at creating an ABT with assistants in the next section.

### 6.3.2 Building a coding challenge ABT

Coding challenges provide a good baseline for testing and evaluating agent and assistant systems. Challenges and benchmarks can quantify how well an agent or agentic system operates. We already applied coding challenges to multi-platform agents in chapter 4 with AutoGen and CrewAI.[](https://livebook.manning.com/book/ai-agents-in-action/chapter-6)

For this coding challenge, we’re going a little further and looking at Python coding challenges from the Edabit site ([https://edabit.com](https://edabit.com/)), which range in complexity from beginner to expert. We’ll stick with the expert code challenges because GPT-4o and other models are excellent coders. Look at the challenge in the next listing, and think about how you would solve it.

##### Listing 6.5 Edabit challenge: Plant the Grass

```
Plant the Grass by AniXDownLoe

    You will be given a matrix representing a field g 
and two numbers x, y coordinate.

    There are three types of possible characters in the matrix:

        x representing a rock.
        o representing a dirt space.
        + representing a grassed space.

    You have to simulate grass growing from the position (x, y). 
    Grass can grow in all four directions (up, left, right, down). 
    Grass can only grow on dirt spaces and can't go past rocks.

    Return the simulated matrix.
    Examples

    simulate_grass([
    "xxxxxxx",
    "xooooox",
    "xxxxoox"
    "xoooxxx"
    "xxxxxxx"
    ], 1, 1) → [
    "xxxxxxx",
    "x+++++x",
    "xxxx++x"
    "xoooxxx"
    "xxxxxxx"
    ]

    Notes

    There will always be rocks on the perimeter
```

You can use any challenge or coding exercise you want, but here are a few things to consider:

-  The challenge should be testable with quantifiable assertions (pass/fail).
-  Avoid opening windows when asking for a game, building a website, or using another interface. At some point, testing full interfaces will be possible, but for now, it’s just text output.
-  Avoid long-running challenges, at least initially. Start by keeping the challenges concise and short lived.

Along with any challenge, you’ll also want a set of tests or assertions to confirm the solution works. On Edabit, a challenge typically provides a comprehensive set of tests. The following listing shows the additional tests provided with the challenge.

##### Listing 6.6 Plant the Grass tests

```
Test.assert_equals(simulate_grass(
["xxxxxxx","xooooox","xxxxoox","xoooxxx","xxxxxxx"],
 1, 1), 
["xxxxxxx","x+++++x","xxxx++x","xoooxxx","xxxxxxx"])
    Test.assert_equals(simulate_grass(
["xxxxxxx","xoxooox","xxoooox","xooxxxx",
"xoxooox","xoxooox","xxxxxxx"],
 2, 3), ["xxxxxxx","xox+++x","xx++++x","x++xxxx",
"x+xooox","x+xooox","xxxxxxx"])
    Test.assert_equals(simulate_grass(
["xxxxxx","xoxoox","xxooox","xoooox","xoooox","xxxxxx"], 
1, 1), 
["xxxxxx","x+xoox","xxooox","xoooox","xoooox","xxxxxx"])
    Test.assert_equals(simulate_grass(
["xxxxx","xooox","xooox","xooox","xxxxx"], 
1, 1),
["xxxxx","x+++x","x+++x","x+++x","xxxxx"])
    Test.assert_equals(simulate_grass(
["xxxxxx","xxxxox","xxooox","xoooxx","xooxxx",
"xooxxx","xxooox","xxxoxx","xxxxxx"], 
4, 1),
["xxxxxx","xxxx+x","xx+++x","x+++xx","x++xxx",
"x++xxx","xx+++x","xxx+xx","xxxxxx"])
    Test.assert_equals(simulate_grass(
["xxxxxxxxxxx", "xoxooooooox", "xoxoxxxxxox", 
"xoxoxoooxox", "xoxoxoxoxox", "xoxoxoxoxox", 
"xoxoxxxoxox", "xoxoooooxox", "xoxxxxxxxox", 
"xooooooooox", "xxxxxxxxxxx"], 1, 1), 
["xxxxxxxxxxx", "x+x+++++++x", "x+x+xxxxx+x", 
"x+x+x+++x+x", "x+x+x+x+x+x", "x+x+x+x+x+x", 
"x+x+xxx+x+x", "x+x+++++x+x", "x+xxxxxxx+x", 
"x+++++++++x", "xxxxxxxxxxx"])
```

The tests will be run as part of a two-step verification to confirm that the solution works. We’ll also use the tests and challenges as written, which will further test the AI.

Figure 6.8 shows the makeup of a straightforward behavior tree that will be used to solve various programming challenges. You’ll notice that this ABT uses a different assistant for the actions and conditions. For the first step, the Python coding assistant (called the Hacker) generates a solution that is then reviewed by the coding challenge Judge (called the Judge), which produces a refined solution that is verified by a different Python coding assistant (called the Verifier).

![Figure 6.8 The ABT for the coding challenge](https://drek4537l1klr.cloudfront.net/lanham2/Figures/6-8.png)

Figure 6.8 also shows how each agent converses on which thread. Assistants use message threads, similar to a Slack or Discord channel, where all assistants conversing on a thread will see all messages. For this ABT, we keep one main conversation thread for the Hacker and Judge to share messages, while the Verifier works on a separate message thread. Keeping the Verifier on its own thread isolates it from the noise of the solution-solving efforts.

Now, building the ABT in code is a matter of combining the `py_trees` package and the Playground API functions. Listing 6.7 shows an excerpt of code that creates each of the action/condition nodes with the assistants and gives them the instructions.[](https://livebook.manning.com/book/ai-agents-in-action/chapter-6)

##### Listing 6.7 `agentic_btree_coding_challenge.py`

```
root = py_trees.composites.Sequence("RootSequence", memory=True)


thread = api.create_thread()     #1
challenge = textwrap.dedent("""
 #2
""")
judge_test_cases = textwrap.dedent("""
 #3
""")

hacker = create_assistant_action_on_thread(   
    thread=thread,      #4
    action_name="Hacker",
    assistant_name="Python Coding Assistant",
    assistant_instructions=textwrap.dedent(f"""
    Challenge goal: 
    {challenge}      #5
    Solve the challenge and output the 
final solution to a file called solution.py        
    """),
)
root.add_child(hacker)

judge = create_assistant_action_on_thread(    
    thread=thread,      #6
    action_name="Judge solution",
    assistant_name="Coding Challenge Judge",
    assistant_instructions=textwrap.dedent(
        f"""
    Challenge goal: 
    {challenge}      #7
    Load the solution from the file solution.py.
    Then confirm is a solution to the challenge 
and test it with the following test cases:
    {judge_test_cases}      #8
    Run the code for the solution and confirm it passes all the test cases.
    If the solution passes all tests save the solution to a file called 
judged_solution.py
    """,
    ),
)
root.add_child(judge)

# verifier operates on a different thread, essentially in closed room
verifier = create_assistant_condition(     #9
    condition_name="Verify solution",
    assistant_name="Python Coding Assistant",
    assistant_instructions=textwrap.dedent(
        f"""
    Challenge goal: 
    {challenge}      #10
    Load the file called judged_solution.py and 
verify that the solution is correct by running the code and confirm it passes 
all the test cases:
    {judge_test_cases}      #11
    If the solution is correct, return only the single word SUCCESS, otherwise 
return the single word FAILURE.
    """,
    ),
)
root.add_child(verifier)

tree = py_trees.trees.BehaviourTree(root)


while True:
    tree.tick()
    time.sleep(20)      #12
    if root.status == py_trees.common.Status.SUCCESS:    #13
        break
### Required assistants – 
### Python Coding Assistant and Coding Challenge Judge 
### install these assistants through the Playground
```

Run the ABT by loading the file in VS Code or using the command line. Follow the output in the terminal, and watch how the assistants work through each step in the tree.

If the solution fails to be verified at the condition node, the process will continue per the tree. Even with this simple solution, you could quickly create numerous variations. You could extend the tree with more nodes/steps and subtrees. Perhaps you want a team of Hackers to break down and analyze the challenge, for example.

This example’s work is done mainly with the Playground code, using the helper functions `create_assistant_condition` and `create_assistant_action_on_thread`. This code uses a couple of classes to integrate the `py_trees` behavior tree code and the OpenAI Assistants code wrapped in the Playground. Review the code within the project if you want to understand the lower-level details[](https://livebook.manning.com/book/ai-agents-in-action/chapter-6).[](https://livebook.manning.com/book/ai-agents-in-action/chapter-6)

### 6.3.3 Conversational AI systems vs. other methods

We already looked at conversational multi-agent systems in chapter 4 when we looked at AutoGen. The ABT can work using a combination of conversations (over threads) and other methods, such as file sharing. Having your assistants/agents pass files around helps reduce the number of noisy and repetitive thoughts/conversations. In contrast, conversational systems benefit from potential emergent behaviors. So, using both can help evolve better control and solutions.[](https://livebook.manning.com/book/ai-agents-in-action/chapter-6)

The simple solution in listing 6.7 could be extended to handle more real-world coding challenges and perhaps even to work as a coding ABT. In the next section, we build a different ABT to handle a different problem.

### 6.3.4 Posting YouTube videos to X

In this section’s exercise, we look at an ABT that can do the following:[](https://livebook.manning.com/book/ai-agents-in-action/chapter-6)

1.  Search for videos on YouTube for a given topic and return the latest videos.
1.  Download the transcripts for all the videos your search provided.
1.  Summarize the transcripts.
1.  Review the summarized transcripts and select a video to write an X (formerly Twitter) post about.
1.  Write an exciting and engaging post about the video, ensuring it’s less than 280 characters.
1.  Review the post and then post it on X.

Figure 6.9 shows the ABT assembled with each of the different assistants. In this exercise, we use a sequence node for the root, and each assistant performs a different action. Also, to keep things simple, each assistant interaction will always occur in a new thread. This isolates each assistant’s interaction into a concise conversation that’s easier to debug if something goes wrong.

![Figure 6.9 The YouTube social media ABT](https://drek4537l1klr.cloudfront.net/lanham2/Figures/6-9.png)

### 6.3.5 Required X setup

If you plan to run the code in this exercise, you must add your X credentials to the `.env` file. The `.env.default` file shows an example of how the credentials need to be, as shown in listing 6.8. You don’t have to enter your credentials. This means the last step, posting, will fail, but you can still look at the file (`youtube_twitter_post.txt`) to see what was generated.[](https://livebook.manning.com/book/ai-agents-in-action/chapter-6)

##### Listing 6.8 Configuring credentials

```
X_EMAIL = "twitter email here"
X_USERNAME = "twitter username here"
X_PASSWORD = "twitter password here"
```

##### YouTube search and spam

If you plan to run this exercise for real and let it post to your X account, be aware that YouTube has a bit of a spam problem. The assistants have been configured to try to avoid video spam, but some of it may get through. Building a working ABT that can wade through videos while avoiding spam has some suitable applications.[](https://livebook.manning.com/book/ai-agents-in-action/chapter-6)

Listing 6.9 shows just the code for creating the assistant actions. This ABT uses three different assistants, each with its own task instructions. Note that each assistant has a unique set of instructions defining its role. You can review the instructions for each assistant by using the Playground.

##### Listing 6.9 `agentic_btree_video_poster_v1.py`

```
root = py_trees.composites.Sequence("RootSequence", memory=True)

search_term = "GPT Agents"
search_youtube_action = create_assistant_action(
    action_name=f"Search YouTube({search_term})",
    assistant_name="YouTube Researcher v2",
    assistant_instructions=f"""
    Search Term: {search_term}
    Use the query "{search_term}" to search for videos on YouTube.
    then for each video download the transcript and summarize it 
for relevance to {search_term}
    be sure to include a link to each of the videos,
    and then save all summarizations to a file called youtube_transcripts.txt
    If you encounter any errors, please return just the word FAILURE.
    """,
)
root.add_child(search_youtube_action)

write_post_action = create_assistant_action(
    action_name="Write Post",
    assistant_name="Twitter Post Writer",
    assistant_instructions="""
    Load the file called youtube_transcripts.txt,
    analyze the contents for references to search term at the top and 
then select
    the most exciting and relevant video related to: 
    educational, entertaining, or informative, to post on Twitter.
    Then write a Twitter post that is relevant to the video,
    and include a link to the video, along
    with exciting highlights or mentions, 
    and save it to a file called youtube_twitter_post.txt.
    If you encounter any errors, please return just the word FAILURE.
    """,
)
root.add_child(write_post_action)

post_action = create_assistant_action(
    action_name="Post",
    assistant_name="Social Media Assistant",
    assistant_instructions="""
    Load the file called youtube_twitter_post.txt and post the content 
to Twitter.
    If the content is empty please do not post anything.
    If you encounter any errors, please return just the word FAILURE.
    """,
)
root.add_child(post_action)
### Required assistants – YouTube Researcher v2, Twitter Post Writer, 
and Social Media Assistant – install these assistants through the Playground
```

Run the code as you normally would, and after a few minutes, a new post will appear in the `assistants_output` folder. Figure 6.10 shows an example of a post generated using this ABT. Running this ABT to generate more than a few posts a day could, and likely will, get your X account blocked. If you’ve configured X credentials, you’ll see the post appear on your feed.[](https://livebook.manning.com/book/ai-agents-in-action/chapter-6)

![Figure 6.10 A sample X post from the ABT](https://drek4537l1klr.cloudfront.net/lanham2/Figures/6-10.png)

This ABT is shown for demonstration purposes and isn’t for production or long-term use. The primary features of this demonstration are to show search and loading data, summarization and filtering, then generating new content, and finally highlighting multiple custom actions and integrations with APIs[](https://livebook.manning.com/book/ai-agents-in-action/chapter-6).

## 6.4 Building conversational autonomous multi-agents

The conversational aspect of multi-agent systems can drive mechanisms such as feedback, reasoning, and emergent behaviors. Driving agents with ABTs that silo assistants/agents can be effective for controlling structured processes, as we saw in the YouTube posting example. However, we also don’t want to miss out on the benefits of conversation across agents/assistants.[](https://livebook.manning.com/book/ai-agents-in-action/chapter-6)

Fortunately, the Playground provides methods to silo or join assistants to conversation threads. Figure 6.11 shows how assistants can be siloed or mixed in various combinations to threads. Combining silos with conversation provides the best of both patterns.

![Figure 6.11 The various layouts of siloed and conversational assistants](https://drek4537l1klr.cloudfront.net/lanham2/Figures/6-11.png)

We’ll examine a simple but practical exercise to demonstrate the effectiveness of the conversational pattern. For the next exercise, we’ll employ two assistants in an ABT that converse over the same thread. The next listing shows the tree’s construction in code with the respective assistants.

##### Listing 6.10 `agentic_conversation_btree.py`

```
root = py_trees.composites.Sequence("RootSequence", memory=True)
bug_file = """
# code not shown
"""

thread = api.create_thread()     #1

debug_code = create_assistant_action_on_thread(     #2
    thread=thread,
    action_name="Debug code",
    assistant_name="Python Debugger",
    assistant_instructions=textwrap.dedent(f"""    
    Here is the code with bugs in it:
    {bug_file}
    Run the code to identify the bugs and fix them. 
    Be sure to test the code to ensure it runs without errors or throws 
any exceptions.
    """),
)
root.add_child(debug_code)

verify = create_assistant_condition_on_thread(     #3
    thread=thread,
    condition_name="Verify",
    assistant_name="Python Coding Assistant",
    assistant_instructions=textwrap.dedent(
        """
    Verify the solution fixes the bug and there are no more issues.
    Verify that no exceptions are thrown when the code is run.
    Reply with SUCCESS if the solution is correct, otherwise return FAILURE.
    If you are happy with the solution, save the code to a file called 
fixed_bug.py.
    """,
    ),
)
root.add_child(verify)
tree = py_trees.trees.BehaviourTree(root)
while True:
    tree.tick()    
    if root.status == py_trees.common.Status.SUCCESS:
        break    #4
    time.sleep(20)
```

Three nodes comprise the tree: the root sequence, the debug code action, and the verify fix condition. Because the tree’s root is a sequence, the two assistants will continue to work one after another until they both return with success. Both assistants converse on the same thread and yet are controlled in a manner that provides constant feedback.

Run the exercise by loading the file in VS Code, or execute it directly from the command line. The example code has a few minor bugs and problems that the assistants will work through to fix. After the ABT completes running successfully, you can open the `assistants_output/fixed_bug.py` file and verify the results are all good.

We’ve now seen a couple of ABTs in action and understand the nuances of using silos or conversations. The following section will teach you some techniques for building your own ABTs.

## 6.5 Building ABTs with back chaining

Back chaining is a method derived from logic and reasoning used to help build behavior trees by working backward from the goal. This section will use the back chaining process to construct an ABT that works to achieve the goal. The following list provides a description of the process in more detail:[](https://livebook.manning.com/book/ai-agents-in-action/chapter-6)

1.  *Identify goal behavior*. Start with the behavior you want the agent to perform.
1.  *Determine the required actions*. Identify the actions that lead to the goal behavior.
1.  *Identify the conditions*. Determine the conditions that must be met for each action to succeed.
1.  *Determine the mode of communication*. Determine how the assistants will pass on information. Will the assistants be siloed or converse over threads, or is a combination of patterns better?
1.  *Construct the tree.* Start by building the behavior tree from the goal behavior, adding nodes for actions and conditions recursively until all necessary conditions are linked to known states or facts.

Behavior trees typically use a pattern called the *blackboard* to communicate across nodes. Blackboards, like those in `py_trees`, use a key/value store to save information and make it accessible across nodes. It also provides for several controls, such as limiting access to specific nodes. [](https://livebook.manning.com/book/ai-agents-in-action/chapter-6)

We deferred to using files for communication because of their simplicity and transparency. At some point, agentic systems are expected to consume much more information and in different formats than those designed for blackboards. Blackboards must either become more sophisticated or be integrated with file storage solutions.

Let’s build an ABT using back chaining. We could tackle a variety of goals, but one interesting and perhaps meta goal is to build an ABT that helps build assistants. So let’s first present our goal as a statement “Create an assistant that can help me do {task}”:

-  *Required actions*: (working backwards)

-  Create an assistant.
-  Verify the assistant.
-  Test the assistant.
-  Name the assistant.
-  Give the assistant the relevant instructions.

-  *Identified condition: *

-  Verify the assistant.

-  *Determine communication patterns*: To keep things interesting, we’ll run all assistants on the same message thread.
-  *Construct the tree*: To construct the tree, let’s first reverse the order of actions and mark each of the element’s actions and conditions accordingly:

-  (action) Give the assistant relevant instructions to help a user with a given task.
-  (action) Name the assistant.
-  (action) Test the assistant.
-  (condition) Verify the assistant.
-  (action) Create the assistant.

Of course, the simple solution to building the tree now is to ask ChatGPT or an otherwise capable model. The result of asking ChatGPT to make the tree is shown in the next listing. You could also work the tree out independently and perhaps introduce other elements.

##### Listing 6.11 ABT for building an assistant

```
Root
│
├── Sequence
│    ├── Action: Give the assistant relevant instructions to help a user 
with a given task
│    ├── Action: Name the assistant
│    ├── Action: Test the assistant
│    ├── Condition: Verify the assistant
│    └── Action: Create the assistant
```

From this point, we can start building the tree by iterating over each action and condition node and determining what instructions the assistant needs. This can also include any tools and custom actions, including ones you may need to develop. On your first pass, keep the instructions generic. Ideally, we want to create as few assistants as necessary.

After determining the assistant, tools, and actions for each assistant and for which task, you can try to generalize things further. Think about where it may be possible to combine actions and reduce the number of assistants. It’s better to start evaluating with insufficient assistants than with too many. However, be sure to maintain the proper divisions of work as tasks: for example, testing and verification are best done with different assistants.[](https://livebook.manning.com/book/ai-agents-in-action/chapter-6)

## 6.6 Exercises

Complete the following exercises to improve your knowledge of the material:[](https://livebook.manning.com/book/ai-agents-in-action/chapter-6)

-  *Exercise 1*—Creating a Travel Planner ABT

*Objective *—Build an agentic behavior tree (ABT) to plan a travel itinerary using assistants.

*Tasks*:

-

-  Set up the GPT Assistants Playground on your local machine.
-  Create an ABT to plan a travel itinerary. The tree should have the following structure:

-  Action: Use the Travel assistant to gather information about potential destinations.
-  Action: Use the Itinerary Planner to create a day-by-day travel plan.
-  Condition: Verify the completeness and feasibility of the itinerary using another Travel Assistant.

-  Implement and run the ABT to create a complete travel itinerary.

-  *Exercise 2*—Building an ABT for Customer Support Automation

*Objective *—Create an ABT that automates customer support responses using assistants.

*Tasks*:

-

-  Set up the GPT Assistants Playground on your local machine.
-  Create an ABT with the following structure:

-  Action: Use the Customer Query Analyzer assistant to categorize customer queries.
-  Action: Use the Response Generator assistant to draft responses based on the query categories.
-  Action: Use the Customer Support assistant to send the responses to customers.

-  Implement and run the ABT to automate the process of analyzing and responding to customer queries.

-  *Exercise 3*—Managing Inventory with an ABT

*Objective *—Learn how to create and manage inventory levels using an ABT.

*Tasks*:

-

-  Set up the GPT Assistants Playground on your local machine.
-  Create an ABT that manages inventory for a retail business:

-  Action: Use the Inventory Checker assistant to review current stock levels.
-  Action: Use the Order assistant to place orders for low-stock items.
-  Condition: Verify that orders have been placed correctly and update inventory records.

-  Implement and run the ABT to manage inventory dynamically.

-  *Exercise 4*—Creating a Personal Fitness Trainer ABT

*Objective *—Create an ABT that provides personalized fitness training plans using assistants.

*Tasks*:

-

-  Set up the GPT Assistants Playground on your local machine.
-  Create an ABT to develop a personalized fitness plan:

-  Action: Use the Fitness Assessment assistant to evaluate the user’s current fitness level.
-  Action: Use the Training Plan Generator to create a custom fitness plan based on the assessment.
-  Condition: Verify the plan’s suitability and safety using another Fitness assistant.

-  Implement and run the ABT to generate and validate a personalized fitness training plan.

-  *Exercise 5*—Using Back Chaining to Build a Financial Advisor ABT

*Objective *—Apply back chaining to construct an ABT that provides financial advice and investment strategies.

*Tasks*:

-

-  Set up the GPT Assistants Playground on your local machine.
-  Define the following goal: “Create an assistant that can provide financial advice and investment strategies.”
-  Using back chaining, determine the actions and conditions needed to achieve this goal.
-  Implement and run the ABT to generate a comprehensive financial advisory service by back chaining the construction of the base actions and conditions for the tree.

## Summary

-  Behavior trees are a robust and scalable AI control pattern, first introduced in robotics by Rodney A. Brooks. They are widely used in gaming and robotics for their modularity and reusability.
-  The primary nodes in behavior trees are the selector, sequence, condition, action, decorator, and parallel nodes. Selectors are like “or” blocks: sequence executes nodes in sequence, condition tests the state, action does the work, decorator is a wrapper, and parallel nodes allow for dual execution.
-  Understanding the execution flow of behavior trees can be critical to designing, building, and operating them to provide control for making clear decision-making paths.
-  The advantages of behavior trees include modularity, scalability, flexibility, debugging ease, and decoupling of decision logic, making behavior trees suitable for complex AI systems.
-  Setting up and running a simple behavior tree in Python requires correctly naming and documenting custom nodes.
-  The GPT Assistants Playground project is a Gradio-based interface that mimics the OpenAI Assistants Playground with additional features for teaching and demonstrating ABTs.
-  The GPT Assistants Playground allows for creating and managing custom actions, which is essential for building versatile assistants.
-  ABTs control agents and assistants by using prompts to direct actions and conditions for assistants. ABTs use the power of LLMs to create dynamic and autonomous systems.
-  Back chaining is a method for constructing behavior trees by working backward from the goal behavior. This process involves identifying required actions, conditions, and communication patterns, and then constructing the tree step by step.
-  Agentic systems benefit from siloed and conversation patterns for communicating between entities. ABTs can benefit from combining siloed and conversational assistants to use structured processes and emergent behaviors.
