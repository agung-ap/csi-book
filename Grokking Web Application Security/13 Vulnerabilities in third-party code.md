# 13 Vulnerabilities in third-party code

### In this chapter

- How to protect against vulnerabilities in code written by others
- How to avoid advertising what your tech stack is built from
- How to secure your configuration

[](/book/grokking-web-application-security/chapter-13/)Here’s a thought that should keep you up at night: most of the code powering your web applications wasn’t written by you. How can you know it’s secure, then?

To build a modern web application is to stand on the shoulders of giants. Most of the running code that keeps the web application responding to HTTP requests will have been written by other people. This code includes the application server itself, the programming language runtime, all your dependencies and libraries, your supplementary applications (such as web servers, databases, queuing systems, and in-memory caches), the operating system itself, and any type of resource abstraction tools you deploy (such as virtual machines or containerization services). You can picture this stack of technologies as being geological strata.

That’s a whole lot of code that you didn’t write—and you won’t even have read most of it. Worse, pretty much all the vulnerabilities covered in this book so far (and some that are yet to be covered) appear frequently in third-party code. You can chart roughly how often each vulnerability crops up in code and at what layer of abstraction.

In this chapter, we will learn how to cope with the vulnerabilities that exhibit themselves in third-party code, starting at the surface of the tech stack and descending into the depths.

## Dependencies

The places you most frequently find vulnerabilities in code that isn’t your code are your *dependencies*—the third-party libraries and frameworks that your dependency manager imports into your build process. These names of dependencies differ depending on which language you are using, such as *JAR files* in Java, *libraries* in .NET, *gems* in Ruby, *packages* in Python and Node.js, and *crates* in Rust. These dependencies may consist of compiled or uncompiled code. In some cases, a dependency acts as a wrapper around some low-level operating system functions, generally written in C. Libraries that deal with scientific computing (such as SciPy in Python), cryptography (such as OpenSSL), or machine learning (such as OpenCV) tend be implemented in C because these tasks are computationally intensive.[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)

The dependency manager will import dependencies according to your *manifest* file, which declares which dependencies you intend to use in your codebase. Keeping this manifest file under source control is the key when determining which packages are deployed in your running application. When you learn about a new vulnerability in a dependency, this file tells you whether any of your applications are using that dependency.[](/book/grokking-web-application-security/chapter-13/)

One of the simplest manifest formats is `requirements.txt`, used by Python’s `pip` dependency manager. At its simplest, the manifest is a text file listing which dependencies are to be downloaded from the *Python Package Index* (PyPI):[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)

```
flask       #1
lxml
markdown
requests
validators
```

### Dependency versions

You need to appreciate a couple of subtleties when detecting vulnerable dependencies. First, vulnerabilities typically occur in certain versions of a dependency, and the authors typically announce new versions in which the vulnerability is *patched* (fixed). So you need to know which versions of each dependency have been deployed with the running version of the application.[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)

One way is to *pin* your dependencies, stating precisely which version the build process should use. Here’s how in Python:[](/book/grokking-web-application-security/chapter-13/)

```
flask==2.3.3        #1
lxml==4.9.3
markdown==3.4.4
requests==2.31.0
validators==0.22.0
```

Some dependency managers use *lock files*, which record which dependency version was imported at build time whether or not you pinned your dependencies. Because these lock files are typically checked into source control, they ensure that you have a record of what dependency version goes out with each release.[](/book/grokking-web-application-security/chapter-13/)

Here’s a simple lock file used by Node.js. Notice how it records the version of every dependency used, where the dependency version was downloaded from, and a checksum for the package that was downloaded:[](/book/grokking-web-application-security/chapter-13/)

```json
{
 "name": "my-node-app",
 "version": "0.0.1",
 "lockfileVersion": 3,
 "requires": true,
 "packages": {
   "": {
     "name": "my-node-app",
     "version": "0.0.0",
     "dependencies": {
       "express": "~4.16.1"
     }
   },
   "node_modules/express": {
     "version": "4.16.4",
     "resolved": 
"https://registry.npmjs.org/express/-/express-4.16.4.tgz",
     "integrity": "sha512-j12Uuyb4FuCHAkPtO8ksuOg==",
     "dependencies": {
       "cookie": "0.3.1"
     },
     "engines": {
       "node": ">= 0.10.0"
     }
   },
   "node_modules/cookie": {
     "version": "0.4.1",
     "resolved": 
"https://registry.npmjs.org/cookie/-/cookie-0.4.1.tgz",
     "integrity": "sha512-ZwrFkGJxUR3EIozELf3dFNl/kxkUA==",
     "engines": {
       "node": ">= 0.6"
     }
   }
 }
}
```

Lock files also help deal with the second subtlety of dependency management: most code imported with a dependency manager has its own dependencies, which the dependency manager duly imports during the build process. Although they’re not declared in your manifest, these *transitive dependencies* are just as likely to exhibit vulnerabilities, so you need to be able to determine which versions are deployed in your running application when you learn about a new vulnerability. Lock files make the version of each transitive dependency explicit, so you have a complete record of the dependencies deployed.[](/book/grokking-web-application-security/chapter-13/)

### Learning about vulnerabilities

To patch vulnerable dependencies, you first need to be aware that the vulnerabilities exist. You can keep up with news about major vulnerabilities by following tech media. This news will hit the front page of Hacker News ([https://news.ycombinator.com](https://news.ycombinator.com/)) and the large programming subreddits (/r/webdev, /r/programming, and language-specific ones such as /r/python). Following tech people on social media is also a good move. Twitter (now X) was once the main place to find them, but given some the recent tumultuous times in X’s management, you may find it more useful to seek out tech influencers on Mastodon. The advantage of this approach is that these platforms typically feature a lot of discussion of vulnerabilities, which will help you assess the risks and put them in context.[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)

For specific, granular information, you should use tools to compare your deployed dependencies with those in the *Common Vulnerabilities and Exposures* (CVE) database. This database is an exhaustive catalog of every publicly disclosed cybersecurity vulnerability, tirelessly maintained by security researchers.[](/book/grokking-web-application-security/chapter-13/)

If you use the popular source control systems GitHub or GitLab, the good news is that you get this functionality for free. Each source control system analyzes dependencies automatically for you, highlighting vulnerabilities in your code as soon as a record appears in the CVE database.

Modern programming languages have tools that allow you to audit your code from the command line in a similar fashion. These tools can be run on demand, even before you add code to source control. One such tool is `npm audit`, available to Node.js developers, which provides detailed reports on which dependencies contain vulnerabilities, how critical the vulnerabilities are, and how to fix them.[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)

Most modern programming languages have similar tools. Following is a cheat sheet for several languages.

Language

Audit tool

Python

`safety` ([https://github.com/pyupio/safety](https://github.com/pyupio/safety))

Node

`npm audit` ([http://mng.bz/BAwJ](http://mng.bz/BAwJ))

Ruby

`bundler-audit` ([https://github.com/rubysec/bundler-audit](https://github.com/rubysec/bundler-audit))

Java

OWASP Dependency-Check ([https://owasp.org/www-project-dependency-check](https://owasp.org/www-project-dependency-check/))

.NET

NuGet ([http://mng.bz/ddnQ](http://mng.bz/ddnQ))

PHP

`local-php-security-checker` ([http://mng.bz/rjzX](http://mng.bz/rjzX))

Go

`gosec` ([https://github.com/securego/gosec](https://github.com/securego/gosec))

Rust

`cargo_audit` ([https://docs.rs/cargo-audit/latest/cargo_audit](https://docs.rs/cargo-audit/latest/cargo_audit/))

### Deploying patches

After a vulnerability is detected, fixing the vulnerability is simply a matter of updating the version in your manifest, deploying the new code to a testing environment, making sure that nothing breaks, and pushing the secure code to production. Releasing patches isn’t ever quite as frictionless as we might wish, however. Some headaches may occur, including the following:[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)

-  In legacy apps, brittle codebases may make undue changes a risk.
-  If you don’t have a good way of testing whether application behavior is unchanged—a process called *regression testing*—you may have to spend a lot of time checking behavior manually.[](/book/grokking-web-application-security/chapter-13/)
-  Your organization may deliberately implement *code freezes* (time windows in which new releases cannot be pushed out without special permission), preventing you from releasing a patch unless the need is urgent.[](/book/grokking-web-application-security/chapter-13/)
-  New dependency versions may break backward compatibility, so application code has to be updated to use new APIs.

Given these complications, vulnerabilities are usually put through a risk assessment process to see whether patching them is urgent. For high-severity vulnerabilities, you must patch your systems as soon as possible. If an exploit is in the wild, hackers will be actively searching for vulnerable systems, and you are in a race against time.

Sometimes, however, when you drill down on a vulnerability, you find that the specific vulnerable function isn’t used in your application; that it is used only in an offline capacity (such as in scripts used at development time rather than in the deployed application); or that it can be exploited only on the server, whereas you use only Node.js modules on the client side.

In such cases, generally you can mark such patches as nonurgent and release them as time permits. Continually releasing patches for a complex application can feel like being stuck on a treadmill, as your inbox each morning will introduce more busywork to destroy your productivity—not to mention your morale!

##### WARNING

Beware of deferring too much maintenance, however. Putting off patching (and generally failing to update to newer versions of dependencies) is called building up *technical debt*. At some point, you will still have to pay off the debt, and the longer you leave it, the more expensive (in terms of development time) it will be.[](/book/grokking-web-application-security/chapter-13/)

## Farther down the stack

In lower-level code, vulnerabilities tend to be less common but often more severe. This type of code is battle tested but ubiquitous, so newly discovered vulnerabilities tend to be both novel and dangerous. In 2014, a buffer overread bug was discovered in the OpenSSL library that Linux uses to encrypt and decrypt traffic. This vulnerability—called the *Heartbleed bug*—allowed an attacker to read sensitive areas of memory by sending malformed data packets, causing the popular web servers NGINX and Apache to expose encryption keys and other credentials.[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)

Heartbleed has been described as the most expensive bug ever discovered because, suddenly, most of the servers on the internet were vulnerable. The National Vulnerability Database awarded it a 10.0 severity rating—the highest possible score. A patch was made available as soon as the vulnerability was disclosed, but the sheer number of servers that had to be updated meant that chaos reigned for months.

How you cope with this type of low-level vulnerability depends very much on how you host your web application. Typically, your organization falls into one of three camps:

-  You have a dedicated infrastructure team that is in charge of managing servers and deploying patches.
-  You use a hosting provider such as Heroku or Netlify, or a deployment technology like AWS App Runner, which gives you a limited number of options for operating systems.
-  You use Docker, which gives your development team (or DevOps team) control of which operating system libraries are available to the application, with each containerized application being deployable to a standard hosting environment.

In the first case, your infrastructure team will likely approach you when a patch needs to be deployed or will have implemented a regular patching cycle that is pretty much transparent to you. This scenario is great news because your responsibilities are restricted to regression testing in the event of major upgrades.

In the second case, a third-party hosting provider acts as your infrastructure team. In the event that a major security patch is required, you will be notified by email and told whether any actions are required on your part.

In the third case, if you use containerization technology such as Docker, you have to be concerned with patching in exchange for being able to explicitly enumerate your tech stack. Some organizations have a dedicated DevOps team to help with this task.

In any of these scenarios, it’s a great help to have security built into the tech stack from the get-go. Third-party vendors supply so-called *hardened* software components that are configured with security in mind. These components include hardened operating systems that have security firewall rules installed and nonessential services removed; they also have appropriately scoped user roles and a guaranteed patch cycle.[](/book/grokking-web-application-security/chapter-13/)

The Center for Internet Security publishes benchmarks on what is considered to be a secure environment. Try to deploy to servers that meet these benchmarks. Some of them are available in the Amazon Web Services (AWS) Marketplace, for example.[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)

You should review your systems regularly for security holes that creep in after the fact. If you deploy to the cloud by using AWS, Microsoft Azure, or Google, the command-line tools Prowler ([https://github.com/prowler-cloud/prowler](https://github.com/prowler-cloud/prowler)) and Scout Suite ([https://github.com/nccgroup/ScoutSuite](https://github.com/nccgroup/ScoutSuite)) are useful for conducting security reviews.[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)

## Information leakage

To discourage attackers from taking advantage of vulnerabilities in the third-party code you are using, it’s best to avoid advertising what technologies your web app is based on. Revealing system information makes life easier for an attacker since it gives them a playbook of vulnerabilities they can probe for. It may not be feasible to obscure your technology stack completely, but some simple steps can go a long way toward discouraging casual attackers. Let’s see how.[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)

### Removing server headers

By default, many web servers populate the `Server` header information in HTTP response headers with the name of the web server, which is great advertising for the web-server vendor but bad news for you. In your web server configuration, make sure to disable any HTTP response headers that reveal the server technology, language, and version you are running. To disable the `Server` header in NGINX, for example, add the following line to your `nginx.conf` file:[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)

```
http {
   more_clear_headers Server;
}
```

### Changing the session cookie name

The name of the session ID parameter often provides a clue to the server-side technology. If you ever see a cookie named `JSESSIONID`, for example, you can infer that the web server is built with the Java language.[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)

To avoid leaking your choice of web server, make sure that cookies send back nothing that offers a clue about the technology stack. To change the session ID parameter name in a Java web application, for example, include the `<cookie-config>` tag in the `web.xml` configuration:[](/book/grokking-web-application-security/chapter-13/)

```
<web-app>
  <session-config>
    <cookie-config>
      <name>session</name>     #1
    </cookie-config>
  </session-config>
</web-app>
```

### Using clean URLs

Try to avoid telltale file suffixes such as `.php`, `.asp,` and `.jsp` in URLs. These suffixes are common in older technology stacks that map URLs directly to specific template files on disk and immediately tell an attacker what web technology you are using.[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)

Instead, aim to implement *clean URLs* (also known as *semantic URLs*), which are readable URLs that intuitively represent the underlying resource for websites. Implementing a clean URL means doing the following things:[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)

-  *Omitting implementation details for the underlying web server*—The URL should not contain suffixes like `.php`, which denote the underlying technology stack.
-  *Putting key information in the path of the URL*—Clean URLs use the query string only for ephemeral details such as tracking information. A user visiting the same URL without the query string should be taken to the same resource.
-  *Avoiding opaque IDs*—Clean URLs use human-readable *slugs*, which are often generated by stripping the page title of punctuation, converting it to lowercase, and replacing spaces and punctuation with dash (`-`) characters.[](/book/grokking-web-application-security/chapter-13/)

The latter two practices are more concerned with accessibility than with security, but they are worth building into your URL scheme. (They greatly help people who use screen readers, for example.) Here’s an example of a clean URL:

```
https://www.allrecipes.com/recipe/slow-cooker-oats/
```

Notice that you can glean a lot of information about the meaning of this URL because the slug (`slow-cooker-oats`) is human readable. Contrast that URL with the following Microsoft URL:

```
https://msdn.microsoft.com/en-[CA]us/library/ms752838(v=vs.85).aspx
```

This URL tells us about the server software being used but nothing about the contents of the page.

### Scrubbing DNS entries[](/book/grokking-web-application-security/chapter-13/)

[](/book/grokking-web-application-security/chapter-13/)Your DNS entries are a mine of information that an attacker can use. Depending on how much of your technology stack is built in the cloud, they may be able to determine the following information:[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)

-  *Server hosting providers*—If you have Domain Name System (DNS) records that point to AWS, Azure, or Google Cloud, those records are clear indicators of your cloud provider.
-  *Mail servers*—Mail exchange records indicate the mail servers used to send and receive emails for either business or transactional purposes.
-  *Content delivery networks* *(CDNs)*—DNS entries that point to popular CDNs such as Cloudflare, Akamai, and Fastly may suggest that you use these services to accelerate and secure your web content.
-  *Subdomains and services*—The structure of your subdomains can reveal additional services or applications you’re running.
-  *Third-party services*—DNS entries might point to third-party services and integrations, potentially exposing vulnerabilities associated with those services.
-  *Internal network structure*—Attackers might infer information about your internal network structure based on internal DNS records, potentially identifying internal services or hosts.

Much of this information is public by design because it is used in routing traffic over the internet to the appropriate services. But make sure that you keep your DNS entries as minimal as possible whenever you have that option. Also, remove subdomains promptly when they are no longer in use; see chapter 7 for details on how hackers can use dangling subdomains.

### Sanitizing template files

You should conduct code reviews and use static analysis tools to make sure that sensitive data doesn’t end up in template files or client-side code. Hackers will scan comments in client-side code or open source code for sensitive information such as IP addresses, internal URLs, and API keys.[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)

You can use the same tools to preemptively scan your code for information. One such tool is the delightfully named TruffleHog ([https://github.com/trufflesecurity/trufflehog](https://github.com/trufflesecurity/trufflehog)), which you can use to sniff out sensitive information in your source code.[](/book/grokking-web-application-security/chapter-13/)

### Server fingerprinting

Despite your best efforts, sophisticated attackers can still use *fingerprinting* tools to determine your server technology. By submitting nonstandard HTTP requests (such as `DELETE` requests) and broken HTTP headers, these tools heuristically determine the likely server type by examining how it responds in these ambiguous situations. One such tool is Nmap, a network scanner created to probe computer networks, which enables host discovery and operating system detection.[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)

##### WARNING

None of the techniques discussed in this chapter will deter a sophisticated tool like Nmap, so don’t get lulled into a false sense of security. These tools are still very much worth putting in place, however. Most drive-by hacking attempts tend to be fairly low-effort, and preventing information leakage will remove your web application from the pool of easy targets.

## Insecure configuration

Your deployed third-party code is only as secure as you configure it to be, so ensure that all public-facing environments have secure configuration settings. Following are a few common gotchas that can lead to insecure application deployment.[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)

### Configuring your web root directory

Make sure that you strictly separate public and configuration directories and that everyone on your team knows the difference. Web servers such as NGINX and Apache often use sensitive credentials (such as private encryption keys) while serving publicly accessible content (such as images and stylesheets). Mixing them up is a dangerous mistake.[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)

One security problem that plagued older web servers such as Apache involved *open directory listings*; the server would list the contents of a publicly shared directory by generating an index page. This option is disabled by default in modern configurations, but be sure to keep an eye out for any configurations like this in your `httpd.conf` or `apache2.conf` file:[](/book/grokking-web-application-security/chapter-13/)

```
<Directory /var/www/html/static>
  Options +Indexes
</Directory>
```

This configuration enables directory listings for the `/var/www/html/static` directory. Remove the `+Indexes` directive or replace it with `-Indexes` to secure your configuration.

### Disabling client-side error reporting

Most web servers allow verbose error reporting to be turned on when unexpected errors occur, so stack traces and routing information are printed in the HTML of the error page, which helps the development team diagnose errors when writing the application. Here’s how an error might get reported on a Ruby on Rails server when client-side error reporting is enabled with the `better_errors` gem.[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)

Make sure that this type of error reporting is disabled in any public-facing environment. Otherwise, an attacker will be able to take a peek at your codebase.

### Changing default passwords

[](/book/grokking-web-application-security/chapter-13/)Some systems, such as databases and content management systems, come installed with default credentials when you install them. Fortunately, this practice is much less common nowadays; although it was designed to make the installation process less painful, it also gave attackers an easy way to guess passwords when probing for vulnerabilities.[](/book/grokking-web-application-security/chapter-13/)[](/book/grokking-web-application-security/chapter-13/)

Be sure to disable or change any default credentials completely when you install new software components. For many years, the default installation of the Oracle database came with a default user account called `scott` (named for developer Bruce Scott) and password `tiger` (named for his daughter’s cat). Although this story is charming, most modern databases ask you to choose a password upon installation—a much more secure practice.

## Summary

-  Use a dependency manager to import dependencies as part of your build process. Pin your dependencies or use a lock file to ensure that you know which version of each dependency is deployed in a given environment.
-  Use automated dependency analysis or audit tools to check your dependency versions against the CVE database. Patch vulnerable dependencies promptly.
-  Keep on top of patching your operating system and subsidiary services, such as databases and caches. Prefer hardened software when initially building a new system.
-  Avoid leaking information about your tech stack by disabling any `server` headers, making your session cookie name generic, implementing clean URLs, scrubbing DNS entries, and scanning templates and client-side code for sensitive information.
-  Keep your configuration secure by disabling client-side error reports in public environments, disabling directory listings, and removing any default credentials.[](/book/grokking-web-application-security/chapter-13/)
