# The Four Types of Work

Because work can be assigned to people in more ways than ever (e.g., via e-mails, phone calls, hallway conversations, text messages, ticketing systems, meetings, and so forth), we want to make visible our existing commitments.

Erik convinces Bill that there are four types of work that IT does:

### Business projects

These are business initiatives, of which most Development projects encompass. These typically reside in the Project Management Office, which tracks all the official projects in an organization.

### Internal IT projects

These include the infrastructure or IT Operations projects that business projects may create, as well as internally generated improvement projects (e.g., create new environment, automate deployment). Often these are not centrally tracked anywhere, instead residing with the budget owners (e.g., database manager, storage manager, distributed systems manager)

This creates a problem when IT Operations is a bottleneck, because there is no easy way to find out how much of capacity is already committed to internal projects.

### Changes

These are often generated from the previous two types of work and are typically tracked in a ticketing system (e.g., Remedy for IT Operations, JIRA, or an Agile planning tool for Development). The fact that two systems exist to track work for two different parts of the value stream can create problems, especially when handoffs are required.

Incidentally, in some dedicated teams that own both the feature development and service delivery responsibilities, all work lives in the same system. This has some advantages, because operational incidents will show up in the backlog and “in work,” alongside feature defects and new feature functionality.

### Unplanned work or recovery work

These include operational incidents and problems, often caused by the previous types of work and always come at the expense of other planned work commitments.

## Why Do We Need To Visualize IT Work And Control WIP?

My favorite (and only) graph in *The Phoenix Project* shows wait time as a function of how busy a resource at a work center is. Erik used this to show why Brent’s simple thirty-minute changes were taking weeks to get completed. The reason, of course, is that as the bottleneck of all work, Brent is constantly at or above one hundred percent utilization, and therefore, anytime we required work from him, the work just languished in queue, never worked on without expediting or escalating.

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781457191350/files/image/wait_time_graph_final1.png)

Here’s what the graph shows: on the x-axis is the percent busy for a given resource at a work center, and on the y-axis is the approximate wait time (or maybe more precisely stated, the queue length). What the shape of the line shows is that, as resource utilization goes past eighty percent, wait time goes through the roof.

In *The Phoenix Project*, here’s how Bill and the team realized the devastating consequences of this property on lead times for the commitments they were making to the project management office:

I tell them what Erik told me at MRP-8, about how wait times depend upon resource utilization. “The wait time is the ‘percentage of time busy’ divided by the ‘percentage of time idle.’ In other words, if a resource is fifty percent busy, then it’s fifty percent idle. The wait time is fifty percent divided by fifty percent, so one unit of time. Let’s call it one hour.

So, on average, our task would wait in the queue for one hour before it gets worked.

“On the other hand, if a resource is ninety percent busy, the wait time is ‘ninety percent divided by ten percent’, or nine hours. In other words, our task would wait in queue nine times longer than if the resource were fifty percent idle.”

I conclude, “So, for the Phoenix task, assuming we have seven handoffs, and that each of those resources is busy ninety percent of the time, the tasks would spend in queue a total of nine hours times the seven steps…”

“What? Sixty-three hours, just in queue time?” Wes says, incredulously. “That’s impossible!”

Bill and team realize that their simple thirty-minute task actually required seven handoffs (e.g., server team, networking team, database team, virtualization team, and, of course, Brent, Brent, Brent). Assuming that all work centers were ninety percent busy, the graph shows us that the average wait time at each work center is nine hours—and because the work had to go through seven work centers, the total wait time is seven times that: sixty-three hours.

In other words, the total “% of value added time” (sometimes known as “touch time”) was only 0.16% of the total lead time (thirty minutes divided by sixty-three hours). That means for 99.8% of our total lead time, the work was simply sitting in queue, waiting to be worked on (e.g., in a ticketing system, in an e-mail).

My fellow coauthor, George Spafford, and I were first introduced to this graph that so brilliantly shows the destructive nature of long queue times caused by high resource utilization when we both took the EM 526 Constraints Management course at Washington State University from Dr. James Holt (described in more detail in the Further Reading section).

Unfortunately, I don’t know the precise derivation of this graph. Some believe, like I do, that this graph is a simplified case of Little’s Law, where we assume a single work center, a uniform work queue (i.e., all tasks require the same time to complete), no delay between jobs, etc.

In the graph, I believe “wait time” is actually a proxy for “queue length.” In other words, because it’s not time elapsed, it has no time units (i.e., it’s neither minutes, hours, days).

The best discussion on the derivation (and validity/invalidity) can be found on *The Phoenix Project* LinkedIn group.[17](https://learning.oreilly.com/library/view/the-phoenix-project/9781457191350/48-resourceNotes.xhtml#note-17) The discussion, although sometimes a bit acerbic, is intellectually top-notch.

My opinion? The goal of science is to explain the largest amount of observed phenomenon with the fewest number of principles, and to reveal surprising insights. I think the graph serves that purpose, and it is the most effective way of communicating the catastrophic consequences of overloaded IT workers and the fallacies of using typical project management techniques for IT Operations.
