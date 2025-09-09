# 2 Browser security

### In this chapter

- How a web browser protects its users
- How to set HTTP response headers to lock down where your web application can load resources from
- How the browser manages network and disk access
- How the browser secures cookies
- How browsers can inadvertently leak history information

[](/book/grokking-web-application-security/chapter-2/)In his 1975 textbook *States of Matter* (Prentice-Hall), science writer David L. Goodstein starts with the following ominous introduction:

Ludwig Boltzmann, who spent most of his life studying statistical mechanics, died in 1906, by his own hand. Paul Ehrenfest, carrying on the work, died similarly in 1933. Now it is our turn to study statistical mechanics.

We will probably never know why Goodstein strikes up such a depressing note (and we can only hope that he was feeling more cheerful by the end of the book!). Nevertheless, we can relate to the sense of trepidation when cracking open a textbook and immediately diving into abstract principles. So I will warn you up front: the next four chapters of this book deal with the *principles* of web security.

It may be tempting to jump ahead to the second half of the book, which looks at code-level vulnerabilities and how they are exploited. But when you’re learning how to protect against these vulnerabilities, the same handful of security principles present themselves as solutions, so I argue that it’s worthwhile to survey them up front. That way, when we finally reach the second half of the book, these security principles will crop up as old friends we are already familiar with, ready to be put into practice.

So which security principles should we start with? Well, all web applications have a common software component: the web browser. Because the browser will do the most to protect your users from malicious actors, let’s start by looking at the principles of browser security.

## The parts of a browser

Web applications operate on a *client-server* model, in which the author of an application has to write server code that responds to HTTP requests and write the client code that triggers those requests. Unless you are writing a web service, that client code will run in a web browser installed on your computer, phone, or tablet. (Or it will run in your car or refrigerator or doorbell: the *Internet of Things* means that browsers are increasingly being embedded in everyday devices.)[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)

The browser’s responsibility is to take the HTML, JavaScript, CSS, and media resources that make up a given web page and convert them to pixels on the screen. This process is called the *rendering pipeline*, and the code within a browser that executes it is called the *rendering engine*.[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)

The rendering engine of a browser like Mozilla Firefox consists of millions of lines of code. This code processes HTML according to publicly defined web standards, updates the drawing instructions for the underlying operating system as the user interacts with the page, and loads referenced resources (such as images) in parallel. The renderer also has to intelligently allow for malformed HTML and for resources that are missing (or slow to load), falling back to a best-effort guess at what the page is supposed to look like. To achieve all this, the engine will construct the *Document Object Model* (DOM), an internal representation of the structure of the web page that allows the styling and layout of elements to be determined efficiently and reused as the page is updated.[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)

Operating in parallel to the rendering engine is the *JavaScript engine,* which executes any JavaScript embedded in or imported by the web page. Web applications are increasingly JavaScript heavy, and *single-page application* (SPA) frameworks like React and Angular consist mostly of JavaScript that performs *client-side rendering*—editing the DOM directly without having to generate the interim HTML.[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)

Running untrusted code that is loaded from the internet poses all sorts of security risks, so browsers are very careful about what this JavaScript can do. Let’s take a quick look at how the JavaScript engine executes scripts safely.

## The JavaScript sandbox

[](/book/grokking-web-application-security/chapter-2/)In a browser, JavaScript code loaded by `<script>` tags in the HTML of a web page is passed to the JavaScript engine for execution. JavaScript is typically used to make the web page dynamic, waiting for the user to interact with the page and updating parts of the page accordingly.[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)

If the `<script>` tag has a `defer` attribute, the browser waits until the DOM is finalized before executing the JavaScript. Otherwise, the JavaScript executes immediately—if it is included inline in the web page—or as soon as it is loaded from an external URL referenced in the `src` attribute.[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)

Because browsers execute scripts so eagerly, JavaScript engines put a lot of limitations on what JavaScript code is permitted to do. These limitations are called *sandboxing*—making a safe, isolated place where JavaScript can play without causing too much damage to the host system. Modern browsers generally implement sandboxing by running each web page in a separate process and ensuring that each process has limited permissions. JavaScript running in a browser *cannot* do the following things:

-  Access arbitrary files on disk
-  Interfere with or communicate with other operating system processes
-  Read arbitrary locations in the operating system’s memory
-  Make arbitrary network calls

[](/book/grokking-web-application-security/chapter-2/)These rules have specific carve-outs, which we will discuss a little later, but the rules are the high-level safeguards built into the JavaScript engine to ensure that malicious JavaScript cannot do too much damage. (The developers of web browsers learned about security the hard way: plug-ins like Adobe Flash, Microsoft’s Active X, and Java applets that circumvent the sandbox have proved to be major security hazards in the past.)

Though these restrictions may seem to be onerous, most JavaScript code in the browser is concerned with waiting for changes to occur in the DOM—often caused by users scrolling the page, clicking page elements, or typing text—and then updating other elements of the page, loading data, or triggering navigation events in response to these changes. JavaScript that needs to do more can call various browser APIs as long as the browser gives permission.

##### TIP

Because the intended use of JavaScript running in a browser is generally pretty narrow, this topic brings us to our first big security recommendation: *lock down the JavaScript on your web application as much as possible.* The JavaScript sandbox provides a strong degree of protection to your users, but hackers can still cause mischief by smuggling in malicious JavaScript via *cross-site scripting* (XSS) attacks. (We will look in detail at how XSS works in chapter 6.) Locking down your JavaScript mitigates a lot of the risks associated with XSS.[](/book/grokking-web-application-security/chapter-2/)

[](/book/grokking-web-application-security/chapter-2/)You can choose among several key methods of locking down JavaScript on a web page. Before executing any script, the JavaScript engine performs these three checks on the code, which you can think of as questions that the browser asks the web application:

-  What JavaScript code can I run on this page?
-  What tasks should the JavaScript on this page be allowed to perform?
-  How can I be sure that I am executing the correct JavaScript code?

Let’s look at how to answer each of these questions for the browser.

### Content security policies

You can answer the first question (“What JavaScript code can I run on this page?”) by setting a content security policy on your web application. A *content security policy* (CSP) allows you, as the author of the web application, to specify where various types of resources—such as JavaScript files, image files, or stylesheets—can be loaded from. In particular, it can prevent the execution of JavaScript that is loaded from suspicious URLs or injected into a web page.[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)

A CSP can be set as a header in the HTTP response or a `<meta>` tag in the `<head>` tag of the HTML of a web page. Either way, the syntax is largely the same, and the browser will interpret the instructions in the same fashion. Here’s how you might set a CSP in a header when writing a Node.js app:[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)

```javascript
const express = require("express")
const app     = express()
const port    = 3000

app.get("/", (req, res) => {
  res.set("Content-Security-Policy", "default-src 'self'") #1
  res.send("Web app secure!")
})

app.listen(port, () => {
  console.log("Example app listening on port ${port}")
})
```

[](/book/grokking-web-application-security/chapter-2/)Here’s how the same policy would be set in a `<meta>` tag:

```
<!doctype html>
<html>
  <head>
    <meta http-equiv="Content-Security-Policy"
          content="default-src 'self'">                     #1
    <meta charset="utf-8"/>
    <title></title>
  </head>
  <body>
    <p>Web app secure!</p>
  </body>
</html>
```

The first approach is generally more useful because it allows policies to be set in a standard way for all URLs on a web application. (The second approach can be handy if you have hardcoded HTML pages that need special exceptions.) Both these instructions tell the browser the same thing—in this case, that all content (including JavaScript files) should be loaded only from the source domain where the site is hosted. So if your web page lives at `example.com/login`, the browser will execute only JavaScript that is also loaded from the `example.com` domain (as indicated by the `self` keyword). Any attempt to load JavaScript from another domain—such as the JavaScript files that Google hosts under the `googleapis.com` domain, for example—will *not* be permitted by the browser. (These examples show trivially simple code that doesn’t need these protections, but more complex web applications that include dynamic content benefit from CSPs.) CSP policies can lock various types of resources in different ways, as illustrated in the following minitable.[](/book/grokking-web-application-security/chapter-2/)

Content security policy

Interpretation

`default-src 'self';
script-src
ajax.googleapis.com`

JavaScript files can be loaded from the `ajax.googleapis.com` origin; all other resources must come from the host domain.

`script-src 'self'
*.googleapis.com;
img-src *`

JavaScript files can be loaded from `googleapis.com` or any of its subdomains; images can be loaded from anywhere.

`default-src https:
'unsafe-inline'`

All resources must be loaded over HTTPS; inline JavaScript is permitted.

`default-src https:
'unsafe-eval'
'unsafe-inline'`

All resources must be loaded over HTTPS; inline JavaScript is permitted. JavaScript is also permitted to evaluate strings as code by using the `eval(…)` function.

[](/book/grokking-web-application-security/chapter-2/)Note that only the last two CSPs permit *inline* JavaScript (scripts whose content is included in the body of the script tag within the HTML):

```javascript
1234567891011121314<!doctype html>
<html>
  <head>
    <meta http-equiv="Content-Security-Policy"
          content="default-src 'self' unsafe-inline">
    <meta charset="utf-8"/>
    <title></title>
  </head>
  <body>
    <script>
      console.log("I am executing inline!">
    </script>
  </body>
</html>
```

Because most XSS attacks work by injecting JavaScript directly into the HTML of a page, adding a CSP and omitting the `unsafe-inline` parameter is a helpful way to protect your users. (The naming of the attribute is designed to remind you how risky inline JavaScript can be!) If you are maintaining a web application that uses a lot of inline JavaScript, however, it may take some time to refactor scripts into separate files, so make sure to prioritize your development schedule accordingly.[](/book/grokking-web-application-security/chapter-2/)

### The same-origin policy

CSPs allow resources to be locked down by domain. In fact, the browser uses the domain of a website to dictate a lot of what JavaScript can and cannot do in other ways, which answers our second question (“What tasks should the JavaScript on this page be allowed to perform?”).[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)

Recall that the domain is the first part of the *Universal Resource Locator* (URL), which appears in the browser’s navigation bar:[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)

```
https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers
```

Because the domain corresponds to a unique *Internet Protocol* (IP) address in the Domain Name System (DNS) for web traffic, browsers assume that any resources loaded from the same domain should be able to interact. (As far as the browser is concerned, all these resources come from the same source—typically, a bunch of separate web servers sitting behind a load balancer.) In fact, browsers are even more specific. Resources have to agree on the *origin*—which is the combination of protocol, port, and domain—to interact. The following minitable shows which URLs a browser will consider to have the same origin as `https://www.example.com`.[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)

URL

Same origin?

`https://www.example.com/profile`

Yes. The protocol, domain, and port match, even though the path is different.

**http:**`//www.example.com`

No. The protocol differs.

`https://www.example`**.org**

No. The domain differs.

`https://www.example.com`**:8080**

No. The port differs.

`https://`**blog**`.example.com`

No. The subdomain differs.

This *same-origin policy* allows JavaScript to send messages to other windows or tabs that are hosted at the same origin. Websites that pop out separate windows, such as certain webmail clients, use this policy to communicate between windows.[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)

Pages running on different origins are not permitted to interact in the browser.

##### WARNING

JavaScript that is executing in the browser is not permitted to access other tabs or windows hosted on different origins. This vital security principle prevents malicious websites from reading the contents of other tabs that are open in the browser. You would face a security nightmare if a malicious website were able to glance over to the next tab and start reading your banking account details!

### Cross-origin requests

The origin of the web page also dictates how that page can communicate with server-side code. Web pages will communicate back to the same origin when they load images and scripts. They can also communicate with other domains, but this communication must be done in a much more controlled manner.[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)

In a browser, *cross-origin* *writes*, which occur when you click a link to another website and the browser opens that site, are permitted. *Cross-origin embeds* (such as image imports) are permitted as long as the website’s CSPs permit them. But *cross-origin reads* are not permitted unless you explicitly tell the browser so beforehand.[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)

Precisely what do I mean by *cross-origin reads?* Well, JavaScript that is executing in the browser has a couple of ways to read data or resources from a remote URL, potentially hosted at a different origin. Scripts can use the `XMLHttpRequest` object such as[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)

```javascript
function logResponse () {
  console.log(this.responseText)
}

const req = new XMLHttpRequest()
req.addEventListener("load", logResponse)
req.open("GET", "http://www.example.org/example.txt")  #1
req.send()
```

or the newer Fetch API:

```javascript
fetch("http://example.com/movies.json")  #2
  .then((response) => response.json())
  .then((data) => console.log(data))
```

Ordinarily, these read requests can be addressed back only to the same origin as the web page that loaded the JavaScript. This restriction prevents a malicious website from, say, loading in the HTML of a banking website you’ve left but remain logged in to and then reading your sensitive data.

You often have legitimate reasons to load data from a different origin in JavaScript, however. Web services called by JavaScript are often hosted on a different domain, especially where a web application uses a third-party service (such as help or a chat app) to enrich the user experience.

To permit these types of cross-origin reads, you need to set up *cross-origin resource sharing* (CORS) on the web server where the information is being read from. This task means setting various headers explicitly, starting with the prefix `Access-Control` in the HTTP response of the server receiving the cross-origin request. The simplest (though least secure) scenario is to accept *all* cross-origin requests:[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)

```
Access-Control-Allow-Origin: *
```

To lock down cross-origin access further, you can allow requests only from a specific domain such as

```
Access-Control-Allow-Origin: https://trusted.com
```

or limit JavaScript to certain types of HTTP requests:

```
Access-Control-Allow-Methods: POST, GET, OPTIONS
```

##### TIP

In most scenarios, not setting *any* CORS headers is the most secure option. Omitting CORS headers tells any web browser trying to initiate a cross-origin request to your web application not to come sniffing ’round these parts if it knows what’s good for it. (The specification is a little more technically worded, but this wording captures the essence.). If your web application *does* need cross-origin reads, make sure that you set them up conservatively and limit the permissions you are granting to the bare minimum. That way, you are limiting the damage any malicious JavaScript can do. Remember that cross-origin requests may be executing as a user who is logged in to *your* site, so if these requests return sensitive information to JavaScript, it must trust the site that is initiating them.

### Subresource integrity checks

Recall that the third question a browser will ask before running any JavaScript code: “How can I be sure that I am executing the correct JavaScript code?” This line of inquiry may seem to be odd, given that the web server itself decides which JavaScript code to include in or import into the web page. But an attacker could use several methods to swap malicious JavaScript for the code that the author intended.[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)

One such method is to gain command-line access to the web server directly and edit the JavaScript directly where it is hosted. If JavaScript files are hosted on a separate domain or on a *content delivery network* (CDN), an attacker could compromise those systems and swap in malicious scripts. Attackers have also been known to use *monster-in-the-middle (MITM) attacks* to inject malicious JavaScript, effectively sitting between the browser and the server to intercept and replace the intended scripts. To protect against these threats, the `<script>` tags on your web pages can use *subresource integrity checks*.[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)

Here’s what a subresource integrity check looks like at code level:

```
123<script src="/js/application.js"
integrity="sha384-5O3lno38vOKjoSa8HT863w10M7hKzvj+
HjknFmPkOJz50htAHuPtPLj6J6lfziE">
```

The `integrity` attribute is the key element to pay attention to here. The exceedingly long string of text starting with value `5O3lno38vO` is generated by passing the contents of the script hosted at `/js/application.js` through the SHA-384 hashing algorithm. We will learn more about hashing algorithms in chapter 3. For the moment, think of a hashing algorithm as an ultrareliable sausage machine that always produces the same output, called the *hash value*, given the same input and (almost) always produces a different output given different inputs. So any malicious changes to the JavaScript file will generate a different hash value (output) for the `application.js` script. (Generally, the integrity hash is generated by a build process and fixed at deployment time. This security check is intended to catch unexpected changes after deployment, which tend to indicate malicious activity.)[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)

This means the browser can recalculate the hash value when the JavaScript code is loaded. The browser compares this new value to the value supplied in the `integrity` attribute; if the values are different, it can deduce that the JavaScript has been changed. In this scenario, the JavaScript will *not* be executed on the assumption that it isn’t the code that the author intended.[](/book/grokking-web-application-security/chapter-2/)

##### TIP

Subresource integrity checks are optional, but they are a neat way to protect against MITM attacks and malicious edits. Use them whenever you can because they provide an additional layer of protection for your users.

## Disk access

Earlier, I mentioned that JavaScript running in a browser cannot access arbitrary locations on disk. As you might have guessed, this statement was some clever lawyering to brush over the fact that scripts can perform *some* disk access, but only in a tightly controlled manner. Let’s look at how the browser allows this access.[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)

### The File API

The most obvious way for JavaScript running in a browser to access the disk is to use the File API. Web applications can open file picker dialogs with `<input type="file">` or provide an area for a user to drag files into by using the `DataTransfer` object. This API is how Gmail allows you to add attachments to your emails, for example. When either of these actions occurs, the File API permits JavaScript to read the contents of the selected file:

```javascript
const fileInput = document.querySelector
("input[type=file]")                         #1 

fileInput.addEventListener("change", () => {
  const [file] = fileInput.files.            #2
  const reader = new FileReader()
  reader.addEventListener("load", () => {    #3 
    console.log(reader.result)
  })
  reader.readAsText(file)
})
```

JavaScript code is also permitted to validate the file type, size, and modified date, known as the *metadata* of the file:

```javascript
const fileInput = document.querySelector("input[type=file]")

fileInput.addEventListener("change", () => {
 const [file] = fileInput.files
 
 console.log("MIME type: " + file.type)
 console.log("File size: " + file.size)
 console.log("Modified:  " + file.lastModifiedDate)
})
```

With each of these interactions, the user deliberately chose to share the file in question, and the File API does not allow manipulation of the file itself. This restriction prevents malicious JavaScript, for example, from injecting a virus into the file as it sits on disk, so most security risks to the user are mitigated. Notably, the File API does *not* tell the JavaScript code which directory the file was loaded from, which might leak sensitive information (such as the user’s home directory).

### WebStorage

JavaScript can use another couple of methods to access the disk, and unlike the File API, these methods *do* allow scripts to write to disk, albeit in a limited way. The first method uses the `WebStorage` object, which allows up to 5 MB of text to be written to disk as key-value pairs for later use. The browser will ensure that each web application is granted its unique storage location on disk and that any content written to storage is *inert*—that is, it cannot be executed as malicious code.[](/book/grokking-web-application-security/chapter-2/)

The global `window` object provided by the JavaScript engine provides two such storage objects, accessible via the variables `localStorage` and `sessionStorage`:

```
123456789101112const shoppingCartData = localStorage.getItem
("shoppingCart") || "[]";
const shoppingCart = JSON.parse(shoppingCartData);
shoppingCart.push({
  item     : "Tenor Saxophone",
  sku      : "CO9XXVHV35",
  quantity : 1,
  price    : "219.99"
});
localStorage.setItem(
 "shoppingCart", JSON.stringify(shoppingCart)
);
```

Both these objects allow the storage of small snippets of data that persist indefinitely (in the case of `localStorage`) or until the page is closed (in the case of `sessionStorage`).

##### TIP

For security reasons, each `WebStorage` object is segregated by origin. *Different websites cannot access the same storage object, but pages on the same origin can.* This security measure stops malicious websites from reading sensitive data written by your banking website.[](/book/grokking-web-application-security/chapter-2/)

### IndexedDB

In addition to the `WebStorage` API, browsers provide an object called `window.indexedDB` that allows client-side storage in a more structured manner. The `IndexedDB` object allows for larger and more structured objects, and it uses transactions in much the same way as a traditional database.

Here’s a simple illustration of how JavaScript might use the `IndexedDB` object:

```
const request = window.indexedDB.open("shoppingCart", 1); #1
request.onsuccess = (event) => {
  const db = event.target.result;
  db.transaction (["items"], "readwrite")                 #2
    .objectStore ("items")                                #3
    .add ({
      item     : "Tenor Saxophone",
      sku      : "CO9XXVHV35",
      quantity : 1,
      price    : "219.99"
    });                                                   #4
};
```

The `IndexedDB` API also follows the same-origin policy to prevent malicious websites from scooping up sensitive data from the client side. As a result, any data written to the database by your web application can be read only by your web application.

## Cookies

`WebStorage` and `IndexedDB` allow a web application to store state in the browser, which allows a web server to recognize who a user is when their browser makes an HTTP request. This feature is called *stateful browsing*, which is important because HTTP is by design a *stateless* protocol; each HTTP request to the server is supposed to contain all the information necessary to process it. Unless the author of the web application adds a mechanism for maintaining an agreed-on state between the client and the web server, the latter will treat each request as though it were anonymous.[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)

Another, much more common way to implement stateful browsing is to use cookies, which you are probably familiar with. *Cookies* are small snippets of text (up to 4 KB) that a web server can supply in the HTTP response:

```
1234HTTP/2.0 200 OK
Content-Type: text/html
Set-Cookie: session_id=9264be3c7df12505
Set-Cookie: accepted_terms=1
```

When a browser encounters one or more `Set-Cookie` headers, those cookie values are saved locally and sent back with every HTTP request from pages on the same domain:

```
123GET /home HTTP/2.0
Host: www.example.org
Cookie: session_id=9264be3c7df12505; accepted_terms=1
```

[](/book/grokking-web-application-security/chapter-2/)Cookies are the main mechanism by which you, as a web user, authenticate to websites. When you log in to a website, the web application creates a *session*—a record of your identity and what you have done on the website recently. The session identifier, or sometimes all the session data, gets written into the `Set-Cookie` header. Every subsequent interaction you have with the website causes the session information to be sent back in the `Cookie` header, meaning that the web application can recognize who you are. The cookie persists until the expiry time set in the `Set-Cookie` header elapses or until the user or server chooses to clear it.

Because cookies are used to store sensitive data, the browser ensures that they are segregated by domain. The cookies that are set into the browser cache when you log in to `facebook.com`, for example, will be sent back in HTTP requests only to `facebook``.com`. Your Facebook cookies won’t be sent with requests to `pleasehackme.com`, because the malicious web server could use those cookies to access your Facebook account.

Things get more complicated when your web application has subdomains; you need to be sure which (if any) subdomains your cookies should be readable from. We will look at this topic in chapter 7.

##### TIP

Cookies are juicy targets for hackers—especially session cookies. If an attacker can steal a user’s session cookie, they can impersonate that user. Therefore, *you should restrict access to the cookies used by your web application as much as possible.* The cookie specification provides a few ways to restrict access by setting attributes in the `Set-Cookie` header.

### Secure cookies

Your web application should use *HTTPS* (Hypertext Transport Protocol Secure) to ensure that web traffic is encrypted and can’t be intercepted and read by malicious interlopers. We will look at how to configure HTTPS in chapter 3. Generally speaking, setting up HTTPS requires you to register a domain, generate a certificate, and host the certificate on your web server. Then the browser can use the encryption key attached to the certificate to make HTTPS connections.[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)

Sending cookies over HTTPS protects them from being stolen. Web servers are conventionally configured to accept HTTP *and* HTTPS web traffic, but they usually redirect requests on the former protocol to the corresponding HTTPS URL. This feature allows for compatibility with older browsers that may use HTTP as the default protocol (or with users who type the `http://` protocol prefix, for whatever reason). If the browser sends a `Cookie` header in this first, insecure request, an attacker may be able to intercept the insecure request and steal any cookies attached to it. Bad news! To prevent this situation, you should add the `Secure` attribute to the cookie when it is originally sent, telling the browser to send cookies only when making HTTPS requests:

```
HTTP/2.0 200 OK
Content-Type: text/html
Set-Cookie: session_id=9264be3c7df125; Secure     #1
```

### HttpOnly cookies

Cookies are used to pass state between a browser and a web server, but by default, they are also accessible by JavaScript executing in the browser. Generally, there’s no good reason for JavaScript to be playing around in your cookies. This scenario poses a security risk: any attacker who finds a way to inject JavaScript into your web page has a means to steal cookies.[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)

To protect against cookie theft via XSS, you should set the `HttpOnly` attribute in your cookie headers, telling the browser that JavaScript should not be able to access that cookie value:

```
HTTP/2.0 200 OK
Content-Type: text/html
Set-Cookie: session_id=9264be3c7df125; Secure; HttpOnly #1
```

The attribute name, of course, is a bit of a misnomer because you should be using HTTPS rather than HTTP. Make sure to use the `Secure` and `HttpOnly` attributes together; the browser will understand what you mean.

### The SameSite attribute

Websites link to one another all the time, which is part of the magic of the web: you can start researching, say, toothbrush technology in the Byzantine Empire and somehow end up watching videos of what happens inside a dishwasher.[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)

Not every link on the internet is harmless, however, and attackers use *cross-site request forgery* (CSRF) attacks to trick users into performing actions they don’t expect. A maliciously constructed link to your site could well generate an HTTP request that arrives with cookies attached. This request will register as an action performed by your user even if that user clicked the link by mistake. Attackers have used this technique to post clickbait on victims’ social media pages or to trick them into deleting their accounts.[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)

One way to mitigate this threat is to tell the browser to attach cookies to HTTP requests only if the request originates from your own site. You can do this by adding the `SameSite` attribute to your cookie:

```
HTTP/2.0 200 OK
Content-Type: text/html
Set-Cookie: session_id=9264be3c7df125; Secure; 
  HttpOnly; SameSite=Strict                      #1
```

Adding this attribute means that no cookies are sent with cross-site requests; the HTTP request will not be recognized as coming from an existing user. Instead, the user will be redirected to the login screen, preventing whatever harmful action the link is disguising from happening under their account.

Although this behavior is secure, it can irritate users. Having to log back in to, say, YouTube whenever anybody shares a link to a video would quickly get tiring. Hence, most sites allow cookies to be attached to `GET` requests, and only `GET` requests, from other sites by using the `Lax` attribute value:

```
HTTP/2.0 200 OK
Content-Type: text/html
Set-Cookie: session_id=9264be3c7df1250; 
  Secure; HttpOnly; SameSite=Lax           #1
```

With this setting, other types of requests—such as `POST`, `PUT`, and `DELETE`—arrive *without* cookies. Because actions that alter state on the server—and, hence, pose a risk to the user—are typically (and correctly) implemented by these methods, users gain the security benefits without any inconvenience. (We will look at how to safely handle requests that change state on the server in chapter 4.)

##### NOTE

The `SameSite=Lax` for cookies is the default behavior in modern browsers if you add no `SameSite` attribute. But you should still add the header for anyone who might be using your web application in older browsers.

### Expiring cookies

You can and should set cookies to expire after a given time. You can do this by using an `Expires` attribute:[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)

```
HTTP/2.0 200 OK
Content-Type: text/html
Set-Cookie: session_id=9264be3c7df12505; Secure; HttpOnly;
  SameSite=Lax; Expires=Sat, 14 Mar 2026 03:14:15 GMT       #1
```

Or you can set the number of seconds the cookie will stick around by using a `Max-Age` attribute:

```
HTTP/2.0 200 OK
Content-Type: text/html
Set-Cookie: session_id=9264be3c7df12505; Secure; HttpOnly; 
SameSite=Lax; Max-Age=604800       #1
```

##### TIP

Session cookies should be expired in a timely fashion because users face security risks when they are logged in too long. Omitting an `Expires` or `Max-Age` attribute can cause the cookie to hang around indefinitely, depending on the user’s browser and operating system, so avoid this scenario for sensitive cookies! Banking sites typically time out sessions within the hour, whereas social media sites (which prioritize usability over security) have much longer expirations.

### Invalidating cookies

Users can clear cookies in their browsers at any time, which logs them out of any website that uses cookie-based sessions. For a web server to clear cookies, such as when a user clicks a Logout button, the standard way to send back a `Set-Cookie` header with an empty value and a `Max-Age` value of `-1` is[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)

```
HTTP/2.0 200 OK
Content-Type: text/html
Set-Cookie: session_id=; Max-Age=-1     #1
```

The browser interprets this code as “This cookie expired 1 second ago” and discards it. (Presumably, the cookie will end up in recycling or compost, depending on local laws.)

## Cross-site tracking

We should touch on one final topic when discussing browser security because it’s part of an ongoing discussion in the web community. A good deal of browser security is concerned with trying to prevent various websites that are sitting in the same browser from interfering with one another. Knowing what websites you have visited via *cross-site tracking* is valuable information to marketers, and a massive industry of somewhat-creepy internet surveillance exists to capture, commoditize, and resell this information. To combat this surveillance, browsers implement *history isolation*, preventing JavaScript on a page from accessing the browser history and often opening each new website you visit in a separate process.[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)

This prudent security measure has led websites to use third-party cookies to track browsing history. Websites that want to participate in tracking embed a resource from a third-party site that can read the URL of the containing page. Because that third-party site is embedded in many websites and can recognize the user each time they visit a tracked site, the third-party cookie can track a user across websites.

Many browsers ban third-party cookies by default now, so trackers have moved on to newer techniques. *Fingerprinting* describes the process of building a unique profile of a web user by using a combination of IP address, browser version, language preferences, and the system information available to JavaScript. Trackers that use fingerprinting are difficult to combat because all this information is exposed for good reason.[](/book/grokking-web-application-security/chapter-2/)[](/book/grokking-web-application-security/chapter-2/)

Another way to break history isolation is to use *side-channel attacks*, taking advantage of browser APIs that leak details of which websites you have visited. Browsers, for example, allow you to apply different styling information to hyperlinks that have already been visited; at one point, a web page could display a list of links and use JavaScript to inspect the style of each link to see which ones correspond to sites the user has visited. (This approach has been mitigated in modern browsers, though other side-channel attacks continue to plague browser vendors.)[](/book/grokking-web-application-security/chapter-2/)

##### TIP

Cross-site tracking is an arms race between advertisers and browser vendors, so you can expect many more developments in this area. Follow the official blogs of the Mozilla Firefox team if you want to keep abreast of the latest recommendations for the authors of web applications.

## Summary

-  Browsers implement the same-origin policy, whereby JavaScript loaded by a web page can interact with other web pages as long as the domain, port, and protocol match.
-  CSPs can restrict where JavaScript is loaded from in your web application.
-  CSPs can be used to ban inline JavaScript (scripts embedded in HTML).
-  Setting CORS headers conservatively will prevent malicious websites from reading resources.
-  Subresource integrity checks on `<script>` tags can protect against attackers swapping in malicious JavaScript.
-  Setting the `Secure` attribute in the `Set-Cookie` header ensures that cookies can be passed only over a secure channel.
-  Setting the `HttpOnly` attribute in the `Set-Cookie` header prevents JavaScript from accessing that cookie.
-  The `SameSite` attribute in the `Set-Cookie` header can be used to strip cookies from cross-origin requests.
-  The `Expires` or `Max-Age` attributes in the `Set-Cookie` header can be used to expire cookies in a timely fashion.
-  Local disk access via the `WebStorage` and `IndexedDB` APIs also follows the same-origin policy; each domain has its own isolated storage location.[](/book/grokking-web-application-security/chapter-2/)
