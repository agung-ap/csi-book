# 15 What to do when you get[](/book/grokking-web-application-security/chapter-15/) hacked

### In this chapter

- How to detect cyberattacks
- How to perform forensics in the aftermath of a cyberattack
- How to learn from your mistakes

[](/book/grokking-web-application-security/chapter-15/)We’ve reached the end of the book. When I started writing it, I promised that everything in it would be useful security knowledge for web application developers. So if you have been reading closely and paying attention, you should be able to ride off into the sunset without ever having to worry about being hacked, right?

Well, no, unfortunately. Getting good at web application security is like riding a bike, in that you are inevitably going to fall off a few times and have to dust yourself off and keep trying. In this case, a large number of people with sticks are enthusiastically trying to knock you off.

Rather than hide under a rock in shame when your application gets compromised, you can practice some healthy responses to being the victim of a cyberattack that will help you emerge from the incident stronger and a little wiser. Indeed, a secure organization is one that handles the aftermath of a cybersecurity incident by learning from its mistakes. Your part in this cleanup process may be small, but knowing how such an organization handles an event like a data breach should give you some peace of mind when the sky seems to be falling in.

## Knowing when you’ve been hacked

Successful hacks are usually detected (either in progress or after the fact) by spotting anomalous activity in logs. We discussed logging and monitoring in chapter 5, but it’s worthwhile to emphasize their importance again here. You might imagine that not knowing whether you have been hacked is the easiest way out. After all, if a tree falls in the woods but nobody is around, does the tree make a sound? When that tree’s lumber turns up for sale on the dark web, however (to badly mangle the metaphor), there’s no disputing the fact that the tree toppled over.[](/book/grokking-web-application-security/chapter-15/)[](/book/grokking-web-application-security/chapter-15/)

You should collect logs for everything—HTTP access into and out of your systems, network logs, server access logs, database activity logs, application logs, and error reports—and push them to a centralized logging system. Within the logging server, you should apply metrics to each type of log file and raise alerts when suspicious activity occurs.

Suspicious behavior might include server access from unrecognized IP addresses, wild spikes in traffic or error reports, heavy resource consumption on the server, or egress of large amounts of data. Here’s how you might raise an alert in Amazon Web Services (AWS) for unusual server access, for example:

```json
{
 "version" : "2018-03-01",
 "logGroup" : "/var/log/secure",
 "filterPattern" : 
  "{($.message like '%Failed password%') || 
($.message like '%Failed publickey%')}"
}
```

This filter pattern for the AWS Cloudwatch logging system looks for log entries containing `'Failed password'` or `'Failed publickey'` in the `/var/log/secure` log group, which is a common location for Secure Shell (SSH) logs on Linux systems.[](/book/grokking-web-application-security/chapter-15/)

You also have some more sophisticated ways of implementing alerting metrics, depending on your budget. An *intrusion detection system* (IDS), for example, automates much of the alerting logic and increasingly employs machine learning to detect suspicious activity. Logs and alerts help you do a couple of things: spot an incident in process and figure out how an attacker got access, after the fact.[](/book/grokking-web-application-security/chapter-15/)[](/book/grokking-web-application-security/chapter-15/)

## Stopping an attack in progress

Large organizations typically employ a *security operations center* (SOC), a team of people charged with detecting attacks in progress. These folks love to have large screens of streaming real-time graphs and logs, and they tend to talk to one another in military jargon, so you know how serious they are. If you or your SOC is lucky (!) enough to detect a security incident in progress, there’s generally an easy way to stop the hacker in their tracks: turn off all the computers.[](/book/grokking-web-application-security/chapter-15/)[](/book/grokking-web-application-security/chapter-15/)[](/book/grokking-web-application-security/chapter-15/)[](/book/grokking-web-application-security/chapter-15/)

Taking your system offline is a relatively extreme step but an effective one. Whether taking this step is worth the risk is a matter of judgment and should be decided by someone of seniority. Turning off a high-frequency trading application in the middle of the market day could cost the company millions, but imposing some unscheduled downtime for noncritical systems will prevent any further collateral damage.

For web applications, you can make things a little slicker by implementing a status page that provides real-time information about the operational status of a website. Status pages are often hosted in a subdomain, so the status page of the website `example.com` might be `status.example.com`.

[](/book/grokking-web-application-security/chapter-15/)The primary purpose of a status page is to keep users informed about the current availability and performance of the service or system. *Failing over* to the status page—essentially, redirecting all HTTP traffic to a message such as `The service is down; please come back later`—buys you some breathing room and time to put out a fix. Status pages have an additional benefit: they keep track of historical outages, planned or unplanned, ideally showing users how reliable you are.

Whether you fail over or not, you still need to fix the underlying vulnerability as quickly as possible. The fix may be as simple as rolling back the application to a previous version of the code, rotating passwords to lock out an attacker, or closing ports in the firewall. At the other end of the unpleasantness scale, you may have to write your own code patch and deploy it in real time while cybersecurity professionals breathe down your neck and the chief technology officer curses wildly on a conference call.

## Figuring out what went wrong

After you stem the bleeding, or if you detect a cyberattack after the fact, you need to piece together precisely how it occurred. This task means putting together a timeline of events, starting from when the vulnerability was deployed (or left unpatched), when it was first exploited, what the attacker did during the exploitation, and how the attack was finally mitigated. This process, called *digital forensics*, often involves investigating log files, release logs, and source control commit files in detail.[](/book/grokking-web-application-security/chapter-15/)[](/book/grokking-web-application-security/chapter-15/)[](/book/grokking-web-application-security/chapter-15/)

Forensics is often handled by cybersecurity professionals, either in-house or hired from outside, and you will be expected to provide context for why certain events occurred. This type of interview can be humiliating, but try not to take it personally. A healthy organization is looking for failures in processes rather than scapegoats.

## Preventing the attack from happening again

Fixing the immediate vulnerability is only the beginning of the process. Management (and your team) will be looking for a way to shut the door on similar incidents in the future. You may be asked for suggestions, so be ready with answers.[](/book/grokking-web-application-security/chapter-15/)[](/book/grokking-web-application-security/chapter-15/)

If the underlying problem was something that you previously raised an alarm about, try to avoid the temptation to shout “I told you so!” from the rooftop. Your team members and manager probably feel vulnerable at that moment. Simply note that you communicated the problem on such-and-such date and be ready to share emails or messages that back up your claim. (In my professional experience, all you gain by embarrassing your manager is a manager who resents you.)

The long-term fix is likely a change in your organization’s processes, so think of the big picture. You might suggest or implement any of the following changes:

-  A more frequent patching cycle for dependencies and servers
-  A thorough refactoring of vulnerable sections of the codebase
-  A security audit of the codebase by a third party
-  A more thorough review of changes before deployment
-  Architectural changes to remove various attack vectors
-  Testing strategies that aim to catch vulnerabilities before they hit production
-  Automated scanning of the codebase to detect vulnerabilities
-  A bug bounty system to reward third parties who detect vulnerabilities before they are exploited

## Communicating details about the incident to users

A hack of your web application is a breach of your users’ trust. Your best hope for rebuilding that trust is being completely transparent and clearly explaining the steps you’re taking to prevent a recurrence, even if your country has no mandatory-disclosure laws on data breaches.[](/book/grokking-web-application-security/chapter-15/)[](/book/grokking-web-application-security/chapter-15/)

These announcements are usually crafted by senior management and lawyers. The most effective ones contain technical details and a precise timeline of events, as well as a list of concrete steps the organization is taking to prevent the incident from happening again.

You also need to be clear about what is at stake for your users. Could their credentials have been stolen? Could an attacker backwards-engineer user passwords? What content or functionality might the attacker have accessed during the breach?

Finally, the message should be clear about what, if any, action you expect of your users. A forced rotation of passwords isn’t unusual and should be best practice even if the smallest chance exists that credentials were stolen.

## Deescalating future attacks

Not all cyberattackers are professionals or hackers who mean serious harm. The 2022 breach of the Australian telecommunications company Optus, for example, exposed the personal data of about 40% of the country’s population. The attacker used an unsecured API to enumerate names, email addresses, and passport and driver’s license numbers for 9.7 million current and former customers. This attack was a catastrophic failure of access controls. (Reread chapter 10 if this type of failure of authorization is a worry that keeps you up at night!)[](/book/grokking-web-application-security/chapter-15/)[](/book/grokking-web-application-security/chapter-15/)

The attacker had previously posted a ransom request for $1 million Australian on the (now-defunct) hacking website BreachedForums—quite a discount on the $140 million that Optus coughed up to replace half the country’s passports. The user, charmingly posting as a pink-haired anime avatar, noted that they would have reported the exploit if they had been able to contact Optus.

The company had an easy way to establish lines of communication early, however. The `security.txt` standard is a file posted to a website at the top-level domain at `/security.txt` or under the path `/.well-known/security.txt`. It looks like this:[](/book/grokking-web-application-security/chapter-15/)

```
Contact: security@example.com                     #1
Encryption: https://example.com/pgp-key.txt       #2
Signature: https://example.com/security.txt.sig
Acknowledgments: https://example.com/thanks.txt   #3
```

This file gives a gray-hat hacker a way to contact you if they find a vulnerability and politely ask for a reward before they disclose it. It also provides the location of a public key that will allow them to communicate securely.

I leave it to the philosophers to decide whether publishing a `security.txt` file is tantamount to giving in to blackmail. But you should note that all the major tech companies publish their own, so it’s an effective way to stop attacks from escalating.

## Summary[](/book/grokking-web-application-security/chapter-15/)

-  Implement thorough monitoring, logging, metrics, and alerts to detect cyberattacks in progress or after the fact.
-  Be ready to take your system offline if feasible when anomalous behavior is detected. Patch vulnerabilities as soon as they are discovered to have been exploited (and preferably well before exploitation).
-  Implement a status page to report current and historic outages in your systems.
-  In the aftermath of a cyberattack, examine logs to put together a comprehensive timeline of how you were compromised and what the attacker was able to access.
-  Come up with substantive process changes that would have prevented the incident, and be diligent about implementing them.
-  Be transparent with users in the aftermath of the attack. Give them a timeline of what happened, what data the attacker may have accessed, the steps you are taking to prevent a recurrence, and what steps they need to take to secure their accounts.
-  Deploy a `security.txt` file to your web applications so that hackers can communicate information about vulnerabilities in your system before exploiting them.[](/book/grokking-web-application-security/chapter-15/)
