PART IV: INTRODUCTION

In [Part III](https://learning.oreilly.com/library/view/the-devops-handbook/9781098182281/25-part-3.xhtml), we described the architecture and technical practices required to create fast flow from Development into Operations. Now in Part IV, we describe how to implement the technical practices of the Second Way, which are required to create fast and continuous feedback from Operations to Development.

By doing this, we shorten and amplify feedback loops so that we can see problems as they occur and radiate this information to everyone in the value stream. This allows us to quickly find and fix problems earlier in the software development life cycle, ideally long before they cause a catastrophic failure.

Furthermore, we will create a system of work where knowledge acquired downstream in Operations is integrated into the upstream work of Development and Product Management. This allows us to quickly create improvements and learnings, whether it’s from a production issue, a deployment issue, early indicators of problems, or our customer usage patterns.

Additionally, we will create a process that allows everyone to get feedback on their work, makes information visible to enable learning, and enables us to rapidly test product hypotheses, helping us determine if the features we are building are helping us achieve our organizational goals.

We will also demonstrate how to create telemetry from our build, test, and deploy processes, as well as from user behavior, production issues and outages, audit issues, and security breaches. By amplifying signals as part of our daily work, we make it possible to see and solve problems as they occur, and we grow safe systems of work that allow us to confidently make changes and run product experiments, knowing we can quickly detect and remediate failures. We will do all of this by exploring the following:

•creating telemetry to enable seeing and solving problems

•using our telemetry to better anticipate problems and achieve goals

•integrating user research and feedback into the work of product teams

•enabling feedback so Dev and Ops can safely perform deployments

•enabling feedback to increase the quality of our work through peer reviews and pair programming

The patterns in this chapter help reinforce the common goals of Product Management, Development, QA, Operations, and Infosec, and encourage them to share in the responsibility of ensuring that services run smoothly in production and collaborate on the improvement of the system as a whole. Where possible, we want to link cause to effect. The more assumptions we can invalidate, the faster we can discover and fix problems, but also the more capable we are at learning and innovating.

Throughout the following chapters, we will implement feedback loops, enabling everyone to work together toward shared goals, to see problems as they occur, to enable quick detection and recovery, and to ensure that features not only operate as designed in production but also achieve organizational goals and support organizational learning.
