# 5 Security as a process

### In this chapter

- Why you should have two people implement changes to critical systems
- How restricting permissions to members of your organization can keep you safe
- How you can use automation and code reuse to prevent human error
- Why automated testing and deployment are key to secure releases
- Why audit trails are important in detecting security events
- How important it is to learn from your security mistakes

[](/book/grokking-web-application-security/chapter-5/)The Forth Bridge is a 8,094 feet long cantilevered railway bridge over the river Forth, to the west of Edinburgh in Scotland. When built, it was considered to be an engineering marvel—the first major structure in Britain to be built from steel. The choice of materials also posed a maintenance problem: to protect the steel from the harsh Scottish winters, all 9 miles of the bridge needed to be covered in paint.

Painting began as soon as construction was complete. Given the length of the bridge, a permanent painting crew worked on upkeep continuously. For the Scots, “Painting the Forth Bridge” became a colloquial expression for a never-ending task; they came to believe that the paint crew would reach one end and then have to begin working on a full repaint at the other.

Maintaining a web application can feel a little like painting the Forth Bridge. Few web applications are ever fully finished, so knowing how to modify and maintain a working application securely is a process. It’s not sufficient to have encyclopedic knowledge of potential vulnerabilities at the code level; you also need to know how to make changes securely.

Writing code is a team sport for most developers, so let’s start by talking about how to take advantage of that fact when implementing changes.

## Using the four-eyes principle

[](/book/grokking-web-application-security/chapter-5/)Highly secure systems often implement the *four-eyes principle*, a control mechanism that requires two people to approve a critical change before it can be implemented. An extreme example is nuclear missile launch crews, who must be careful to prevent accidental launches. To protect against them, launching a missile requires two operators to turn keys at either end of a room before entering the launch code. (Presumably, the launch device plays the national anthem and wishes them a happy apocalypse when they succeed in the operation.)[](/book/grokking-web-application-security/chapter-5/)

Fortunately, the stakes are lower for web applications, but applying the four-eyes principle can help keep your systems secure. Changes to critical systems—releases of code, configuration updates, database migrations, and so on—should be written by one person and approved by another. A second pair of eyes besides the author’s can spot potential security lapses before they happen. Also, because approvals generally take place in a ticketing system, they generate a paper trail that can help support staff in troubleshooting. When unexpected errors start occurring in a web application, the first question a support engineer will ask is “What has changed recently?” A list of recently implemented change tickets and a disciplined source control strategy (more on that later) will help answer that question.

Approvers must take their task seriously, too, rather than rubber-stamp whatever comes their way. When a team member approves a critical system change, they are stating that they believe the change will not be disruptive. If they still have any doubt, they should be empowered to decline approval and to ask for extra assurances and safety measures before the change is allowed to proceed. (They should also be sufficiently trained to provide good judgment. It often helps to have senior engineers or dedicated security team members do reviews.)

##### NOTE

Implementing change-management controls like the four-eyes principle will force you and your team to document each change ahead of time. The act of writing down what you are about to do is helpful in itself: it forces you to clarify how the change will be implemented, why it is necessary, what the risks are, and what success looks like. Making things explicit is a useful technique for clarifying your thoughts when writing code, too. Some programmers believe in the utility of *rubber-duck debugging*, which is the practice of explaining to a rubber duck (or another arbitrary inanimate object) how your code should be working when you’re trying to resolve bugs. The point is not that the rubber duck will offer suggestions, but that when you put your problem into words, you ften realize what is wrong as you are speaking.[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)

## Applying the principle of least privilege to processes

In chapter 4, we discussed the principle of least privilege, which states that a subject should be granted only the minimum set of privileges required to complete its task. We saw how this principle applies to systems, such as web servers and database accounts. It can (and should) apply equally to the people in your organization.[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)

[](/book/grokking-web-application-security/chapter-5/)Restricting the privileges of team members will reduce the risk that an employee will go rogue and make destructive changes. More charitably, these restrictions also reduce the damage an outside attacker can do if they manage to steal or guess the credentials of a member of your organization. Depending on the size of your organization, it is often useful to break responsibilities across several different roles. The following figure shows some common roles in organizations that produce software.

Depending on the size and culture of your organization, the same person may have to play several roles. It can also help to *time-box* privileges: sensitive permissions, such as permission to change servers or upgrade database structures, should be granted for only a short time to reduce the risk that a malicious actor will hijack an account and make destructive changes.[](/book/grokking-web-application-security/chapter-5/)

## Automating everything you can

We have talked a little about how to implement change control to mitigate the risk of human error, but do you know what is more reliable than humans? Computers! Automating any manual processes within your organization reduces the risk of mistakes. Here are some processes you should automate when you manage your web applications:[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)

-  *Building code*—Compiling code and generating assets (such as JavaScript and Cascading Style Sheets [CSS]) should be performed by an automated build process capable of being triggered from the command line or development environment.
-  *Deploying code*—Code should be deployable from source control via a single command. Rolling back code should be equally easy, although stateful systems such as databases typically require a little more work or a manual process to unwind changes.
-  *Adding servers*—Increasing the number of servers that host your web application and subsidiary services should be as scripted as possible. Use DevOps tools and containerization to make bringing up a new server as painless as possible.
-  *Testing*—Build unit tests into your build process. Use automated browser testing tools to identify breaking changes in each release. Use automated penetration testing tools to identify security flaws before attackers do.

As a rule of thumb, any process that your documentation describes as a multistep sequence is a good candidate to be replaced by a script or build tool. We will see in chapter 13 how often security problems arise from misconfigured servers or deployment accidents. Reducing the number of manual steps in your development life cycle will reduce the risk of these problems occurring in your organization.

## Not reinventing the wheel

Most of the software that powers your web application, from the operating system to the web server to the database, won’t have been written by you and your team. Generally, you will have purchased a license or be running open source software—which is good! You can’t expect to be an expert on low-level networking protocols or the niceties of database indexing, so using existing technologies will give you a head start, allowing you to solve the challenges that are unique to your web application rather than reinventing what someone else built.[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)

Code reuse is good for your security stance. By using third-party code—either at operating system level or in separate applications such as databases and libraries imported by your build process—you can take advantage of the expertise of the people who design and maintain this code. The hard-working coders who maintain popular web servers and operating systems are security *experts*, and their work is thoroughly vetted by hundreds of security researchers who are paid to find and report security flaws to the authors of these applications. (You need to be diligent about keeping up with security patches for any third-party code you use, as we will discuss in chapter 13.)

In a couple of domains, you should certainly and without question avoid rolling your own solutions. The first rule is to never implement your own encryption algorithms. Encryption is a fantastically difficult process to get right. To give you a sense of how difficult it is, the National Institute of Standards and Technology (NIST) has been running a competition since 2018 for encryption algorithms that will be secure when quantum computing is widespread. (Quantum computers harness the phenomena of quantum mechanics to perform certain types of mathematical operations much, much faster than today’s computers can. One such problem is integer factorization, which underpins much of modern cryptography.) Of the many algorithms submitted by experts around the world, only a few remain uncracked. Because encryption algorithms created by the world’s leading security experts are routinely proven to be flawed, it makes sense to show some humility as a web developer and follow the guidance of experts.

The second domain in which you should be wary of coding your own solution is session management. You may recall from chapter 4 that a *session* is how your web server recognizes a returning user after authentication. Usually, this process involves setting a session ID in a cookie that can be looked up in a server-side session store or by implementing client-side sessions that write the entire session state in the cookie.[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)

In theory, implementing sessions for your web application sounds straightforward; in practice, it is quite difficult to get right. In chapter 9, we will review how an attacker can exploit predictable or weakly random session IDs and then use them to hack users’ sessions, as well as how insecurely implemented client-side sessions can allow malicious users to escalate privileges. Session management is difficult to implement securely and a frequent target of attack, so always use the session implementation that comes with your web server rather than write your own.

## Keeping audit trails

Knowing who did what and when is key to keeping your web application secure. Just as secure organizations keep visitor logs, your application and processes should keep track of critical activity. Audit trails can help you identify suspicious activity during a security incident, and they are the key to figuring out what happened afterward, during the forensics stages. Here are some common ways that secure applications use audit trails:[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)

-  *Code changes*—Updates to the codebase should be stored in source control so that you can review which lines of code were changed and by whom. Code changes should be digitally signed when they are transmitted to the code repository.
-  *Deployments*—You should keep a log of which versions of the codebase are deployed to which servers, as well as when those releases were rolled out and by whom.
-  *HTTP access logs*—Your web server should log which URLs on your site are accessed, the HTTP response codes, the source Internet Protocol (IP) address and HTTP verb, and when the server was accessed. Make sure to abide by any local regulations on storing *personally identifiable information* (PII) that may pertain to IP addresses written to log files.[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)
-  *User activity*—Significant actions by users such as signing up, logging in, and editing content should be logged and be readily available to support staff. The proviso about PII is doubly relevant if your users use their real names.
-  *Data updates*—Changes to rows in your database should have an audit trail. At the very least, keep a record of when each row is created or updated. For more sensitive data, keep a record of which process or user last updated the data.
-  *Admin access*—Administrative access to systems should be logged and recorded so that you can detect anomalous behavior or accidental changes.
-  *SSH access logs*—If you allow remote access to servers via the Secure Shell (SSH) protocol, the access logs should be recorded on the server and shipped to a centralized location.[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)

The widely loved Twitter/X account @PepitoTheCat takes a photo whenever said cat enters or leaves his cat flap. This account is a good example of an audit trail; should you ever need to know Pepito’s whereabouts, you can find him by checking the posts.

## Writing code securely

So far, the advice in this chapter has been mostly organizational. It’s all good advice, but if you are reading this book, your day job is probably more about writing code than assigning roles to people in your organization. Let’s take a minute to discuss how the principles apply to your *software development life cycle* (SDLC)—the process by which you write and release code.[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)

### Using source control

Your most important tool as a developer is source control. Tracking changes to your codebase with a tool such as `git` is essential to keeping a record of when new features are added to your web applications.[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)

If your team members follow the GitHub flow (popularized by the company of the same name), they should create branches for new features that they are writing and merge them back into the main branch when the code is ready for release. Merge time is a great opportunity to review code, and you should require a team member to review the code for anything that’s being merged into the main branch.

Other organizations choose to implement *trunk-based development* (TBD), in which each developer merges their changes into the main (trunk) branch each day. Because a trunk must always be releasable, features are disabled by feature toggles until they are ready to go live (when the relevant approvals have been made, obviously). This approach is useful if your organization needs to release features to smaller test audiences as part of a staged rollout or wants to implement *blue/green deployment*, whereby two versions of the application can be live in production and traffic is gradually moved from the older version (blue) to the newer one (green) with each release.[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)

### Managing dependencies

Third-party code that your application uses should be imported by a *dependency manager*—a tool designed to import specific versions of third-party libraries *(dependencies)* when building or deploying code. Every modern programming language has a preferred dependency manager.[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)

Programming language

Dependency manager(s)

Node.js

npm, Yarn, pnpm

Ruby

Bundler

Python

pip

Java

Maven, Gradle, Ivy

.NET

NuGet

PHP

Composer

A dependency manager can be compared with a container-ship loading dock. In fact, many dependency managers refer to the list of software modules to be imported as a *manifest*, in the same way that cargo ships have manifests listing their cargo. The dependency manager compiles the modules needed to run your code and packages them for deployment.[](/book/grokking-web-application-security/chapter-5/)

Using a dependency manager allows you to fix the *versions* of each dependency your codebase uses in a deterministic manner, which is important for security. When researchers discover vulnerabilities, they publish security advisories for specific versions of a dependency. Knowing precisely which dependencies are being used in each environment allows you to update to secure versions easily. This process is known as *patching* dependencies, and we cover it in detail in chapter 13.[](/book/grokking-web-application-security/chapter-5/)

### Designing a build process

If you need to compile source code or generate assets like CSS or minified JavaScript before release, you should automate that process. A script that automatically generates software artifacts ready for deployment is called a *build process*, and the tool used to run such scripts is a *build tool*. Like dependency managers, each language has a set of popular build tools, and you should use a well-supported tool to automate the generation of assets. (Dependency managers are often invoked as part of a larger build process that prepares your code for deployment.) Using a build tool reduces the risk of human error while readying code for release.[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)

#####

Programming language

Build tool(s)

Node.js

Webpack, Grunt, Gulp, Babel, Vite

Ruby

Rake

Python

distutils, setuptools

Java

Maven, Gradle, Ivy, Ant

.NET

MSBuild, NAnt

### Writing unit tests

As you add features to your web application, you should test them. The most reliable way to demonstrate that a feature is working correctly is to add *unit tests*—small automated tests that demonstrate whether a feature or function is working as intended—to your codebase. Unit tests, which should be run as part of your build process, are vital for demonstrating that your code is secure. Here are some scenarios that you might verify with unit tests:[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)

-  *Authentication checks*—Ensure that users have to supply a valid username and password to log in.
-  *Authorization checks*—Check that certain routes and actions are accessible only to authenticated users. You might ensure that a user has to be logged in before posting content, for example.
-  *Ownership checks*—Check that users can edit only the content that they have permission to edit. You could ensure that they can edit their own posts but not a colleague’s, for example.
-  *Validation checks*—Ensure that the web application rejects invalid HTTP parameters.

The percentage of lines of code that are executed when all your unit tests are run is called your *coverage* (the amount of your codebase that is covered by testing). You should aim to increase your coverage number as time goes on. Particularly when you’re fixing bugs, it is a good idea to add a unit test that demonstrates the error condition first. As you fix the bug, the test will go from failing to passing and prevent the bug from recurring.

##### WARNING

A coverage report of 100% doesn’t indicate that your code is entirely correct, mind you. Your tests will inevitability fail to check certain conditions and may even have mistaken assumptions in their logic.

When your coverage is good, you should start using a *continuous integration/continuous delivery* (CI/CD) tool. This tool responds to code changes being pushed to source control by running the build process and executing your unit tests, giving your team immediate feedback if unit tests start breaking.[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)

### Performing code reviews

Before code is merged into the main branch and pushed to externally facing environments, you should apply the four-eyes principle and ensure that somebody other than the author reviews and approves the changes. You can enforce this workflow with tools like GitHub, which can be configured to require a code review and approval before a pull request can be merged. Also, you can (and should) require your unit tests to give you a green light before the final merge.[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)

### Automating your release processes

The process of pushing code changes to an externally facing environment—be it a staging or test environment or your real production environment—should be as automated as possible. Your deployment scripts or processes should take code from source control or an artifact from your CI/CD system and push it to servers, running the build process as needed. If you use virtualization or containerization, this process will likely start new servers in the deployment environment. If you are updating existing servers, you should use a DevOps framework such as Puppet, Chef, or Ansible to deploy code in a deterministic manner.[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)

[](/book/grokking-web-application-security/chapter-5/)The key motivation is to remove the possibility of human error in this step, ensuring that a known-good version of the code is deployed and that deployment is verified when it is complete.

### Deploying to preproduction environments

You should deploy code changes to a testing or staging environment before pushing to production. (CD systems often ensure that the latest prerelease code is running in preproduction environments.) This practice allows you or your quality analysis team to verify that the web application works as expected in a production-like environment before hitting the green light.[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)

The utility of this step depends on keeping your production and staging environments as similar as possible, running the same operating systems, web servers, and programming language runtimes, and using similar data stores (albeit with dummy rather than real data). The only significant difference between environments should be in configuration. This approach reduces the risk that novel problems that could have been identified in testing will crop up during production.

When testing is complete in your staging environment, releasing your new code to the production system should (ideally) be a formality. The release process should be identical in each environment except for the sign-offs required to proceed.

You can think of your deployment to a staging environment as a dress rehearsal for a play: all the cast members get to rehearse their lines in front of a test audience (of quality-assurance testers) before performing their first live performance. It’s better to catch any mistakes in a safe environment than in front of a paying audience!

### Rolling back code

[](/book/grokking-web-application-security/chapter-5/)Unfortunately, mistakes do happen. Sometimes, it is necessary to undo a release of code changes. This process is called a *rollback*. Rollbacks are required when unexpected conditions are encountered in a production environment. Maybe an oversight occurred during testing, or some novel data produced unexpected edge cases, or there proved to be some differences from the testing environment.[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)

Rollbacks should be kept to a minimum, but you should also make them easy. The same scripts or processes that deployed the new code or artifacts should be able to put the previous versions back in place with minimum fuss, allowing you to go back to the drawing board and figure out the cause of the problem.

If your organization implements the blue/green deployment described earlier, rolling back a change is as simple as falling back to the blue environment (which will remain unchanged).

Changes to stateful systems such as databases are always more difficult to unwind, particularly if the changes were destructive (such as dropping tables or columns in a SQL database) and data has changed in the interim. Think carefully about how to manage such systems and handle failed releases.

## Using tools to protect yourself

[](/book/grokking-web-application-security/chapter-5/)We’ve talked about the importance of automation in securing your processes, and it should come as no surprise that you can use a host of automated tools to detect security problems at each stage of your SDLC. Because it’s better to catch bugs and vulnerabilities early in the development life cycle, let’s start by looking at tools you can use at development time.[](/book/grokking-web-application-security/chapter-5/)

### Dependency analysis

Many dependency managers have an `audit` command that scans your dependency list and compares it with a database of known vulnerabilities. You can think of these tools as being safety inspectors, ensuring that harmful cargo is not being loaded. npm for Node.js, pip for Python, and Bundler for Ruby can all be invoked from the command line in such a way as to report potential vulnerabilities in your third-party code. Tools like Snyk and GitHub’s Dependabot go even further; they can be configured to open pull requests automatically for upgrades to secure versions of these dependencies. These tools should be run on a scheduled basis so that you are notified about security problems early.[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)

Scanning for insecure dependencies is an easy way to remove vulnerabilities from third-party code before an attacker can exploit them. Not all vulnerabilities in your application will be exploitable, however, and some upgrades will require you to change code that interfaces with the dependency. Make sure that you read the description of the vulnerability before deciding to patch it. Blindly updating dependency versions will end up causing a lot of busywork because, in many cases, the vulnerable functions in a particular dependency won’t be invoked by your code. (The Go language utility `govulncheck` is handy in this respect; it analyzes your codebase to see whether a vulnerability can affect you.)

### Static analysis

After you have secured your third-party code, static analysis tools such as Qwiet.ai, Veracode, and Checkmarx can scan your codebase to determine whether the code contains vulnerabilities. Static code analysis tools should not be treated as a replacement for code reviews—they are severely limited in how they understand the intent of code—but they are very efficient at catching certain classes of bugs. Such tools can detect where untrusted input enters your web application and trace it to see whether it is treated safely when generating database invocations or writing HTTP responses. As such, these tools are helpful for detecting cross-site scripting vulnerabilities and injection vulnerabilities, which we will learn about in chapters 6 and 12, respectively.[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)

### Automated penetration testing

*Penetration testing* is the practice of employing a friendly hacker to find vulnerabilities in your web application before a malicious hacker does. The tools that penetration testers use for security analysis can also be deployed as standalone services. Services such as Invicti and Detectify can be configured to crawl your web application and maliciously modify HTTP parameters, probing for vulnerabilities in the same way that a hacker would.[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)

##### WARNING

Be sure to run the tools in your staging environment if you are worried about data corruption. Also make sure you don’t run afoul of local laws; these products are automated hacking tools, and some countries do not permit their use.

### Firewalls

[](/book/grokking-web-application-security/chapter-5/)A *firewall* is a piece of software that can stop malicious incoming network connections. Most operating systems come with a simple firewall that opens and closes ports for traffic. Firewalls can also be deployed standalone in your network, blocking traffic before they reach application servers.[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)

*Web application firewalls* (WAFs) operate higher in the network stack and can parse HTTP (and other protocol) traffic as it passes through, which allows them to detect and block malicious HTTP requests by spotting common attack patterns. Because WAFs use configurable blocklists, they are useful for quickly deploying protection strategies when a new vulnerability is discovered.

### Intrusion detection systems

Whereas firewalls stop malicious traffic from getting to a computer, *intrusion detection systems* (IDSes) detect malicious activity on a computer. IDSes can check for unexpected changes in sensitive files, suspicious processes, and unusual network activity indicating that your system has been compromised. Systems that handle sensitive data such as credit card numbers often use IDSes to detect potential threats.[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)

### Antivirus software

[](/book/grokking-web-application-security/chapter-5/)*Antivirus* (AV) software scans files on disk and checks them against a database of known malware signatures. Many organizations run AV software on their team’s development machines and servers, especially if they allow users to upload files in any form.[](/book/grokking-web-application-security/chapter-5/)[](/book/grokking-web-application-security/chapter-5/)

Opinions about the effectiveness and resource use of AV software vary in the software community. But many organizations are subject to compliance obligations that require it to be run, so do some research before deploying your chosen tool.

## Owning your mistakes

No organization is perfect, and you can never predict every attack, so security incidents will inevitably happen, no matter how careful you are. It’s important to learn the correct lessons from security, improving your processes to reduce the likelihood that a breach will recur.[](/book/grokking-web-application-security/chapter-5/)

[](/book/grokking-web-application-security/chapter-5/)Your first priority in the event of a security event is to stem the bleeding. This process can mean patching or reimaging servers, rolling back code or deploying new code, updating firewall rules, or shutting down nonessential services that may have been compromised. When that process is complete, carefully plan your way back to stable running and start assessing the damage.

Determining which systems were compromised, and how, in the aftermath of a security incident is called *digital forensics*. This process must be undertaken as dispassionately and accurately as possible. You are looking for a clear timeline of events, a statement of facts, and an indication of which data (if any) was stolen or potentially stolen. If your company communicates security incidents to customers—and many companies are legally obliged to—this investigation will form the basis of your report.[](/book/grokking-web-application-security/chapter-5/)

Determining how the security event happened and what can be done to prevent recurrences is called a *postmortem*. It is important to conduct this process without much finger-pointing because you are looking for ways to improve your processes, not for scapegoats. If human error is to blame, how can you add oversight to prevent the mistake from being repeated? If your failure to plan for specific types of risk is at fault, how can you improve your threat modeling to plan for future risks?[](/book/grokking-web-application-security/chapter-5/)

[](/book/grokking-web-application-security/chapter-5/)An organization that learns from its mistakes can move forward confidently. The tech behemoths that are household names today committed every security mistake that is described in this book at one time or another. The reason they are still in business is that they found ways to improve security in the aftermath of incidents to keep the trust of their users.

## Summary

-  Implementing the four-eyes principle—ensuring that changes to critical systems are reviewed before being implemented—will help catch security errors before they cause problems.
-  Restricting your team members’ permissions will mitigate the risk that employees will go rogue or have their credentials stolen.
-  Automating your processes will reduce the risk of human error—a common cause of security problems.
-  Using third-party software rather than rolling your own solutions allows you to take advantage of the outside experts’ knowledge when securing your systems.
-  Keeping track of who performed which actions when on your critical systems will help you diagnose the cause of security problems as they occur and assist with forensic analysis.
-  Using source control, build tools, unit testing, and code reviews is the key to detecting security defects at code level.
-  Automating your deployment process is the key to avoiding human errors such as misconfiguration.
-  Deploying code to a preproduction environment will help you detect problems before they occur in production. Ensure that your testing environment resembles your production environment as much as possible.
-  Rolling back a release should be a fully automated (and rare) process.
-  Dependency and static analysis tools can detect vulnerabilities and security problems in the codebase. Automated penetration testing can detect problems before release. Firewalls, IDSes, and AV software can block or detect incidents as they happen.
-  Carefully manage the aftermath of a security incident. Communicating to customers clearly is the key to keeping their trust. Diagnosing the cause of an incident is essential for improving your processes so that the incident does not recur.[](/book/grokking-web-application-security/chapter-5/)
