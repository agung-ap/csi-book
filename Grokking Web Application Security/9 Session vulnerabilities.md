# 9 Session vulnerabilities

### In this chapter

- How server-side and client-side sessions are implemented
- How sessions can be hijacked
- How sessions can be forged if session identifiers are guessable
- How client-side sessions can be tampered with unless you digitally sign or encrypt the session state

[](/book/grokking-web-application-security/chapter-9/)In chapter 8, we looked at how attackers try to steal credentials from your users. If that strategy isn’t feasible, the next thing an attacker will try is accessing a victim’s account after they log in.

The continued authenticated interaction between a browser and a web server—when a user visits various pages in your web application and the server recognizes who they are—is called a *session*. *Session hijacking* is the act of stealing a user’s identity while they are browsing the web application.[](/book/grokking-web-application-security/chapter-9/)

If an attacker can hijack sessions from your website, they can act as that user. Hackers are inventive in the ways they have discovered to steal sessions, so we dedicate this chapter to the subject. Before we get started, let’s review how web applications implement sessions.

## How sessions work

Rendering even a single page of a website usually requires a browser to make multiple HTTP requests to the server. The initial HTML of the page is loaded; then the browser makes additional requests to load the JavaScript, images, and stylesheets referenced in that HTML.[](/book/grokking-web-application-security/chapter-9/)[](/book/grokking-web-application-security/chapter-9/)

If the website has user accounts, sending the credentials with each of these HTTP requests is not feasible. We saw in chapter 8 that checking a password is a slow process by design, so the web server would end up doing a lot of unnecessary work. Besides, each time credentials are sent over an internet connection, an attacker has the opportunity to steal them.

Sessions are designed to solve this problem, allowing the web server to recognize the returning user without rechecking credentials for each request. Web servers manage sessions in several distinct ways.

### Server-side sessions

Typically, sessions are implemented by assigning each user a temporary, unguessable random number called the *session identifier* after they log in. This session ID is returned in the HTTP response in the `Set-Cookie` header and simultaneously stored on the server.[](/book/grokking-web-application-security/chapter-9/)[](/book/grokking-web-application-security/chapter-9/)

Subsequent HTTP requests pass back the session ID in a `Cookie` header, which allows the server to recognize the user without having to recheck credentials. Because the session ID is stored on the server so that it can be revalidated for subsequent requests, we call this implementation a *server-side session*.[](/book/grokking-web-application-security/chapter-9/)

Server-side session management is easy to add to most modern web servers. Here’s how to add sessions by using the Express.js web framework in Node.js:

```javascript
const express  = require('express');
const sessions = require('express-session');
const app      = express();

app.use(sessions({
  secret: process.env.PRIVATE_SESSION_KEY,  #1
  cookie: {
    maxAge:   1000 * 60 * 60 * 24,          #2
    secure:   true,                         #3
    httpOnly: true,                         #4 
    sameSite: 'lax'                         #5
  }
}));
```

This code snippet uses the `express-session` library to implement session management. The resource that allows the web server to save and look up session IDs is called a *session store*. In this example, we are simply using an in-memory session store, which is the default.[](/book/grokking-web-application-security/chapter-9/)[](/book/grokking-web-application-security/chapter-9/)

Sessions are used for more than recognizing returning users. The web server also keeps some temporary state for the user in the session store; this temporary state is called the *session state*. Session state might record, for example, the items the user is adding to their shopping basket or a list of recently visited pages—basically, anything the server needs to access quickly when responding to HTTP requests for that user.[](/book/grokking-web-application-security/chapter-9/)[](/book/grokking-web-application-security/chapter-9/)

To work correctly, however, nontrivial applications require a more complex deployment for sessions. Anything but the most trivial web application will be deployed to multiple running web servers, with incoming HTTP requests being dispatched to a particular web server instance by a load balancer.

The load balancer, as its name suggests, attempts to balance the load among web servers, dispatching HTTP requests in such a way that each web server handles a roughly equal number of HTTP requests. As a result, each HTTP request in a session may end up being sent to a different web server. (Load balancers can be configured to be *sticky*—requests from the same IP address will always be sent to the same web server—but this setup isn’t 100% reliable because users occasionally change the IP address midsession.)

Deploying a load balancer means that each web server has to be able to access the same session store, so web servers need a way to share sessions. Each web server runs in a different process and potentially on a different physical machine; hence, no server has access to the other servers’ memory space. Typically, this constraint is addressed by using a session store backed by a database or an in-memory data store like Redis.

In our Express.js example, you can configure the session store to use a shared Redis instance as follows:[](/book/grokking-web-application-security/chapter-9/)

```javascript
const express          = require('express');
const sessions         = require('express-session');
const RedisStore       = require("connect-redis")(session);
const { createClient } = require("redis");
const app              = express();

const redis = createClient();        #1
redis.connect().catch(console.error);

app.use(sessions({
  secret: "8b1b8c46-480b-4ee7-be12-a83953fe79ee",
  store: new RedisStore({            #2
    client: redis
  }),
  cookie: {
    maxAge:   1000 * 60 * 60 * 24,
    secure:   true,
    httpOnly: true,
    sameSite: 'lax'
  }
}))
```

Implementing a shared session store allows the application to use session management deployed behind a load balancer. Reading and writing session state to the session store often creates a bottleneck for large applications, however, particularly if a traditional SQL database is used as a session store. In response to this scalability concern, web server developers found another way to implement sessions.

### Client-side sessions

[](/book/grokking-web-application-security/chapter-9/)Many web servers also support *client-side sessions*, in which the entire session state and the user identifier are sent to the browser in the session cookie. When the cookie is returned in subsequent HTTP requests, whichever web server receives the request has everything it needs to service the request without looking anything up in a shared session store.[](/book/grokking-web-application-security/chapter-9/)

The following code snippet shows how client-side sessions can look in Express.js. You simply tell the web server to use the `cookie-parser` library to handle sessions:[](/book/grokking-web-application-security/chapter-9/)

```javascript
var express      = require('express')
var cookieParser = require('cookie-parser')

var app = express()
app.use(cookieParser())      #1
#1 Uses the cookie-parser library to put the session state in the cookie
```

Session state can be stored in the cookie and recovered in the following manner:

```
app.get('/', (request, response) => {
 request.session.username = 'John';
 response.send('Session data stored on client-side.');
});

app.get('/user', (request, response) => {
 const username = request.session.username;
 response.send(`Username from session: ${username}`);
});
```

Client-side sessions can help greatly with scalability, but as you can probably imagine, they introduce new security risks. A malicious user can easily tamper with the session state in a client-side session, so the web server will need to tamperproof the session cookie either by digitally signing the contents or encrypting it. The preceding code snippet uses digital signatures, and we will dig into how it works later in this chapter.

### JSON Web Tokens

[](/book/grokking-web-application-security/chapter-9/)We should discuss one further way of implementing sessions. Modern web applications often use JSON Web Tokens (JWTs, pronounced “jots”) to hold session state.[](/book/grokking-web-application-security/chapter-9/)[](/book/grokking-web-application-security/chapter-9/)

A *JWT* is a digitally signed data structure that can be read and validated by either client-side or server-side code, encoded in JavaScript Object Notation (JSON) format. Here’s an example of generating a JWT in Node.js:[](/book/grokking-web-application-security/chapter-9/)

```javascript
const tokens    = require('jsonwebtoken');
const payload   = { userId: '123456789', role: 'admin' };
const secretKey = process.env.SECRET_KEY;
const jwt       = tokens.sign(payload, secretKey);
```

JWTs are a convenient way to identify a user when a web application fetches data from multiple *microservices*—small, single-purpose web services often deployed in separate domains. By design, JWTs allow a service to verify the authenticity of an access token without consulting the service that originally issued the token. This design helps with scalability because the authentication service won’t be unnecessarily bombarded with requests.[](/book/grokking-web-application-security/chapter-9/)

When the web application needs to access an authenticated service, the JWT serves as credentials. Often, it is sent in the `Authorization` header of the HTTP request:[](/book/grokking-web-application-security/chapter-9/)

```
fetch('https://api.example.com/endpoint', {
 method: 'GET',
 headers: {
   'Authorization': `Bearer ${jwt}`
 }
})
 .then(response => {
   if (response.ok) {
     return response.json();
   } else {
     throw new Error('Request failed');
   }
 });
```

Passing JWTs directly from client-side JavaScript poses a security risk, however: the JWTs are vulnerable to cross-site scripting (XSS) attacks. For this reason, many applications pass JWT access tokens in the `Cookie` header, marking the cookies as `HttpOnly` to prevent them from being accessible to JavaScript. In a sense, the JWT acts like a client-side session that can be read by each separate microservice.[](/book/grokking-web-application-security/chapter-9/)

## Session hijacking

[](/book/grokking-web-application-security/chapter-9/)Now that we have a clear idea of how sessions work, let’s move on to the juicier business of how attackers attempt to steal or forge sessions—and how you can stop them. A stolen or forged session allows an attacker to log in to your web application as the user whose session has been stolen or forged.[](/book/grokking-web-application-security/chapter-9/)[](/book/grokking-web-application-security/chapter-9/)

### Session hijacking on the network

Chapter 7 looked at monster-in-the-middle (MITM) attacks, in which an attacker sits between a web server and a browser, trying to snoop on sensitive traffic. Session IDs are often targets of this type of attack.[](/book/grokking-web-application-security/chapter-9/)[](/book/grokking-web-application-security/chapter-9/)[](/book/grokking-web-application-security/chapter-9/)

Session hijacking on the network was once so easy to achieve that a developer named Eric Butler released a Firefox extension called Firesheep to demonstrate the risks. When connected to a Wi-Fi network, Firesheep listened for any insecure traffic connecting to major social media sites such as Facebook and Twitter and displayed the victim’s username in a sidebar. Then the hacker could simply click the username and log in as that user.

When Firesheep was released as a proof of concept, the major social networks quickly switched to HTTPS-only communication, ensuring that session cookies were passed only over a secure connection (and therefore were unreadable to MITM attacks). Any web application you maintain should apply the same lesson. All traffic should be passed over HTTPS, and cookies containing session IDs should have the `Secure` attribute added to ensure that cookies are never passed over an unencrypted connection:

```
Set-Cookie: session_id=4b44bd3f-5186; Secure; HttpOnly
```

Most session management tools allow this aspect to be controlled via configuration settings, so protecting against session hijacking is usually a matter of setting the appropriate configuration flag. If you look back at the Express.js samples so far in this chapter, you will notice that the `secure` flag is always set to `true` when the session store is initialized, which means that the session cookie will be sent with the `Secure` attribute.[](/book/grokking-web-application-security/chapter-9/)

### Session hijacking via cross-site scripting

[](/book/grokking-web-application-security/chapter-9/)Sessions can also be hijacked by XSS attacks. We looked at how to defend against XSS in chapter 6. These protections (content security policies and escaping) are important in protecting your session IDs.[](/book/grokking-web-application-security/chapter-9/)[](/book/grokking-web-application-security/chapter-9/)[](/book/grokking-web-application-security/chapter-9/)

If you are using cookies for session management, your cookies should be marked with the `HttpOnly` keyword to ensure that they are not accessible to JavaScript running in the browser:[](/book/grokking-web-application-security/chapter-9/)

```
Set-Cookie: session_id=4b44bd3f-5186; Secure; HttpOnly
```

Omitting this keyword means that sessions are still accessible to JavaScript running in the browser. The `HttpOnly` flag is typically controlled by a configuration flag in a modern web framework (and is often the default setting). In our code snippets, the configuration flag `httpOnly` is always set to `true` for this reason.[](/book/grokking-web-application-security/chapter-9/)

### Weak session identifiers

Assuming that you’ve read the entirety of this chapter, it’s probably abundantly clear to you how many ways a session management system can fail to secure its users. This fact is a handy argument for using a ready-made session manager—like the one that comes with your existing web server—rather than reinventing the wheel and possibly reimplementing the security errors that others have made in the past.[](/book/grokking-web-application-security/chapter-9/)[](/book/grokking-web-application-security/chapter-9/)

One flaw that manifested itself in older server-side session implementations was failing to choose a sufficiently unguessable session ID. This error was caused by using a weak algorithm to generate session IDs, such as a random-number generator that failed to use enough sources of entropy to be truly unpredictable. Most languages come with pseudorandom number generators (PRNGs) that are designed to be fast to execute but should not be used in cryptographic systems.[](/book/grokking-web-application-security/chapter-9/)

An attacker can exploit this security oversight. Because they can narrow down the potential values returned by a PRNG in a given period of time, if they send a high volume of HTTP requests—each with a new guess for a session ID—they will eventually hit on a session ID that is being used. This technique allows them to hijack the session.

The popular Java Tomcat server once exhibited this vulnerability because session IDs were generated by the `java.util.Random` package as a source of randomness. (You can read about the details in the paper “Hold Your Sessions: An Attack on Java Session-Id Generation,” by Zvi Gutterman and Dahlia Malkhi, at [https://link.springer.com/chapter/10.1007/978-3-540-30574-3_5](https://link.springer.com/chapter/10.1007/978-3-540-30574-3_5)). The vulnerability was patched in Tomcat a long time ago, so modern versions of the server get their randomness from the `java.security.SecureRandom` class, which is designed to be cryptographically secure:[](/book/grokking-web-application-security/chapter-9/)[](/book/grokking-web-application-security/chapter-9/)[](/book/grokking-web-application-security/chapter-9/)

```
protected void getRandomBytes(byte bytes[]) {
 SecureRandom random = randoms.poll();
 if (random == null) {
   random = createSecureRandom();
 }
 random.nextBytes(bytes);
 randoms.add(random);
}
```

##### WARNING

Make sure that you use a web framework that does not generate predictable session IDs, and keep an eye out for any security reports that describe such problems in your web framework of choice. Chapter 13 looks at how to monitor risks in this type of third-party code.

### Session fixation

You may have the impression that the internet was invented by a team of all-knowing engineers who foresaw every possible use of the network. In fact, the internet evolved significantly, exhibiting hundreds of needless security flaws as it grew, so it contains a multitude of evolutionary missteps that you just have to live with as a web developer.[](/book/grokking-web-application-security/chapter-9/)[](/book/grokking-web-application-security/chapter-9/)

The cookies we use today for session management didn’t exist in the original version of the HTTP specification, for example. To work around this problem, web servers once allowed session IDs to be passed in URLs. Occasionally, you may notice that very old websites send you to URLs such as this one:

```
https://www.example.com/home?JSESSIONID=83730bh3ufg2
```

[](/book/grokking-web-application-security/chapter-9/)This design is terrible security-wise because anyone who gets access to the URL (by hacking the application’s load balancer logs, for example) can drop the same URL in the browser and immediately hijack the session. In many situations, it also opens the door to a *session fixation* attack, in which an attacker creates a URL with a fictional session ID and shares the corresponding URL. If a victim clicks the link, they will be redirected to the login page.

When the victim logs in, the vulnerable web server creates a new session under that session ID. Then, because the attacker chose the ID, they can hijack the session simply by visiting the same URL.

For this very reason, session management systems should never accept session IDs suggested by the client. More pertinently, your web server should be configured not to allow session IDs in URLs. There’s no good reason to pass session IDs in URLs now that browsers universally support cookies.

This vulnerability tends to occur in older Java applications. You can prevent the passing of session IDs in URLs by making the following configuration setting in the `web.xml` file of your Apache Tomcat server:[](/book/grokking-web-application-security/chapter-9/)

```
<session-config>
 <tracking-mode>COOKIE</tracking-mode>
</session-config>
```

PHP is one of the oldest programming languages used to build web apps, and as a result, it has exhibited every security flaw you can imagine at one time or another—including supporting this questionable behavior. You should disable session IDs in URLs by making the following configuration setting in your `php.ini` file:[](/book/grokking-web-application-security/chapter-9/)

```
session.use_trans_sid = 0
```

## Session tampering

[](/book/grokking-web-application-security/chapter-9/)Client-side sessions and JWTs are uniquely vulnerable to manipulation by an attacker. If the session state contains a username, and if an attacker is able to edit the session cookie to insert another username, the server has no way of knowing that the attacker is an imposter. For this reason, client-side sessions are usually accompanied by a digital signature so that any tampering can be detected. Similarly, the payload of a JWT is usually signed with a *Hash-Based Message Authentication Code* (HMAC) algorithm.[](/book/grokking-web-application-security/chapter-9/)[](/book/grokking-web-application-security/chapter-9/)[](/book/grokking-web-application-security/chapter-9/)

Here’s how the `cookie-parser` library in Node.js detects tampering so that it can reject any malicious changes:[](/book/grokking-web-application-security/chapter-9/)

```javascript
/**
* Unsign and decode the given `input` with `secret`,
* returning `false` if the signature is invalid.
*/
exports.unsign = function(input, secret){
 var tentativeValue = input.slice(0, input.lastIndexOf('.')),
     expectedInput  = exports.sign(tentativeValue, secret),
     expectedBuffer = Buffer.from(expectedInput),
     inputBuffer    = Buffer.from(input);
 return (
   expectedBuffer.length === inputBuffer.length &&
   crypto.timingSafeEqual(expectedBuffer, inputBuffer)
 ) ? tentativeValue : false;
};
```

JWTs use digital signatures in a similar fashion, and any microservice that accepts a JWT must validate the signature before using it as an authentication token. The content is untrusted until it’s proved to be otherwise.

One final note: client-side sessions and JWTs are often readable by the client even when they are digitally signed. A user can simply open their browser debugger if they want to see what you are saving in their session. If you are saving anything in the session state that you don’t want the user to see, you need to encrypt it or hold it somewhere outside the session. Nobody wants to know that their profile has been tagged as *basement dweller* or *owns more cats than is healthy*.[](/book/grokking-web-application-security/chapter-9/)

## Summary

-  Use a proven session management framework and keep it up to date with security patches.
-  Ensure that session cookies are passed over HTTPS by setting the `Secure` keyword.[](/book/grokking-web-application-security/chapter-9/)
-  Ensure that session cookies are not accessible by JavaScript running in the browser by setting the `HttpOnly` keyword.[](/book/grokking-web-application-security/chapter-9/)
-  Ensure that your session management framework generates session IDs from a strong random-number generation algorithm.
-  Ensure that your session management framework does not use session IDs suggested by the client.
-  Disable any configuration settings that might allow session IDs to be passed in URLs.
-  Use digital signatures or encryption to tamperproof your client-side sessions and JWTs.
-  Be aware that digitally signed client-side sessions and JWTs can be read by the client. You should avoid storing in the session data you don't want the user to see.
