# 14 Being an unwitting accomplice

### In this chapter

- How hackers launch HTTP requests from your server
- How hackers spoof emails
- How hackers use open redirects

[](/book/grokking-web-application-security/chapter-14/)“No man is an island,” wrote the 17th-century metaphysical poet John Donne. The same can be said for web applications. Our applications exist on networks that are connected to most of the world’s computers, so they are very much whatever the opposite of an island is. (Donne was less clear on what that is. A hillock? An isthmus? A precinct?)

Because web apps are hyperconnected, it makes sense that attackers sometimes use one web application as a jumping-off point for attacking another. They may use this technique to hide their trail, or they may use it simply because the servers running the web application offer more computational firepower than whatever grease-stained and crumb-riddled laptop they’re angrily tapping away on.

In this chapter, we will look at three ways in which your application may be acting as an unwitting accomplice in these types of attacks. Running a website generally requires you to be a good internet citizen, not least because your hosting provider will eventually shut you down if you fail to close such vulnerabilities.

## Server-side request forgery

The internet is a client-server model, with clients such as browsers and mobile apps sending HTTP requests to web servers and getting HTTP responses in return. But sometimes, servers need to make HTTP requests to other web servers, thus acting as clients in their own right. Your web application might make HTTP outbound requests for many reasons, including these:[](/book/grokking-web-application-security/chapter-14/)[](/book/grokking-web-application-security/chapter-14/)[](/book/grokking-web-application-security/chapter-14/)

-  When calling external APIs to process payments, send emails, look up data, or perform authentication
-  To access data from content delivery networks or cloud storage
-  To notify client applications of important events via webhooks
-  To access a remote URL hosting an image as part of fulfilling an image upload request
-  To generate link previews by looking up the open-graph metadata in the HTML of a web page

Each of these situations is a perfectly valid use case. But if your web application allows a malicious client application to trigger HTTP requests to arbitrary URLs, it is said to be exhibiting a *server-side request forgery* (SSRF) vulnerability.

Attackers use SSRF vulnerabilities in a couple of ways. First, attackers can use these vulnerabilities to launch a *denial-of-service* (DoS) attack against a victim, attempting to overwhelm the victim with HTTP requests and take their application offline.[](/book/grokking-web-application-security/chapter-14/)

In this scenario, the attacker is hiding behind your application because all the traffic is coming from your server. This approach is particularly effective if one request to your server by the attacker triggers several requests to the victim, thus multiplying the attacking power of the hacker.

The second common use of SSRF vulnerabilities is to probe an internal network. Because your web application is often operating in a privileged environment—it may have access to sensitive resources such as databases and caches that are deliberately not exposed to the internet—an attacker can use an SSRF vulnerability to probe for such resources and attempt to compromise them.

Admittedly, the attacker has to get a little lucky for this approach to work. Typically, an error is returned to the attacker in the HTTP response, so to use this approach, they need the error message to reveal sensitive data. Hackers are adept at combining security vulnerabilities, and as software systems age, it’s not unusual for vulnerabilities to go undetected for years before the right combination of circumstances allows them to be exploited.

### Restricting the domains that you access

[](/book/grokking-web-application-security/chapter-14/)The easiest way to mitigate SSRF vulnerabilities is to avoid making HTTP requests to domain names drawn from the original incoming HTTP request. If you make requests to the Google Maps API, for example, the domain name in each outbound HTTP request should be defined in server-side code, rather than pulled from the incoming HTTP request. An easy way to call the API safely is to use the Google Maps software development kit (SDK), which looks like this in Java:[](/book/grokking-web-application-security/chapter-14/)[](/book/grokking-web-application-security/chapter-14/)[](/book/grokking-web-application-security/chapter-14/)

```
DirectionsResult result =
   DirectionsApi.newRequest(ctx)
       .mode(com.google.maps.model.TravelMode.BICYCLING)
       .avoid(
           RouteRestriction.HIGHWAYS,
           RouteRestriction.TOLLS,
           RouteRestriction.FERRIES)
       .region("au")
       .origin("Sydney")
       .destination("Melbourne")
       .await();
```

An SDK will safely construct the HTTP request on your behalf, ensuring that an attacker cannot control the domain being accessed. The most commonly used APIs have SDKs, either published by the API owner or maintained by a third party. These kits are usually available via the dependency manager of your choice and prevent any SSRF vulnerabilities from creeping into your code.

### Making HTTP requests only for real users

Some websites *do* need to make requests to arbitrary third-party URLs. Social media sites, for example, allow sharing of web links and often pull down the open graph metadata from those URLs to generate link previews. (This feature is used to generate a thumbnail and caption when you share a link on a social media page, for example.) In these cases, you need to protect yourself against SSRF attacks. You should do the following things:[](/book/grokking-web-application-security/chapter-14/)[](/book/grokking-web-application-security/chapter-14/)[](/book/grokking-web-application-security/chapter-14/)

-  Make outgoing HTTP requests from your server only in response to actions by authenticated users.
-  For social media sites, limit the number of links that a user can share in a given time to prevent abuse.
-  Consider making each user pass a CAPTCHA test with each link they share.

### Validating the URLs that you access

To prevent an attacker from probing your network, you should make sure that server-side requests are sent only to publicly accessible URLs. To enforce this rule, you should do the following:[](/book/grokking-web-application-security/chapter-14/)[](/book/grokking-web-application-security/chapter-14/)

-  Talk to your networking team about limiting the internal servers that are reachable from your web servers.
-  Validate that supplied URLs contain web domains rather than IP addresses.
-  Disallow URLs with nonstandard ports.
-  Make sure that all URLs are accessed over HTTPS, with valid certificates.

Here’s how you would implement these checks in Python:

```
import requests
from urllib.parse import urlparse
from IPy import IP

def validate_url(url):
 parsed_url = urlparse(url)

 if parsed_url.scheme != 'https':
   return False, "URL does not use HTTPS"

 if parsed_url.port and parsed_url.port != 443:
   return False, "URL does not use the standard HTTPS port"

 if not parsed_url.hostname:
   return False, "URL does not have a domain"

 try:
   IP(parsed_url.hostname)
   return False, "Host name must not be an IP address"
 except ValueError:
   pass

 try:
   response = requests.get(url, verify=True)
   response, "Certificate is valid"
 except requests.exceptions.SSLError:
   return False, "URL has an invalid TLS certificate"
 except requests.exceptions.RequestException:
   return False, "URL could not be reached"
```

##### NOTE

A competent attacker will be able to set up Domain Name System (DNS) records pointing to private IPs, so simply validating that a URL has a domain isn’t sufficient.[](/book/grokking-web-application-security/chapter-14/)[](/book/grokking-web-application-security/chapter-14/)

### Using a domain blocklist

[](/book/grokking-web-application-security/chapter-14/)If your app has to make HTTP requests to arbitrary third-party URLs—perhaps you run a link-sharing website—you should consider maintaining a blocklist of domains you will never access in server-side requests, either in configuration files or in a database. This practice will help you interrupt mischievous requests triggered by attackers and stop any attempted DoS attacks in their tracks.[](/book/grokking-web-application-security/chapter-14/)[](/book/grokking-web-application-security/chapter-14/)

Maintaining this kind of blocklist can be onerous, and it’s certainly not something you can build by hand. Using a trusted blocklist maintained by a third party (such as [https://github.com/StevenBlack/hosts](https://github.com/StevenBlack/hosts)) may be a more practical approach.

## Email spoofing

HTTP is not the only internet protocol that attackers use. Unsolicited or malicious emails are transmitted by the *Simple Mail Transfer Protocol* (SMTP) and often used by attackers in phishing attacks to steal credentials or persuade victims to download malicious software.[](/book/grokking-web-application-security/chapter-14/)[](/book/grokking-web-application-security/chapter-14/)[](/book/grokking-web-application-security/chapter-14/)

In 2004, Bill Gates announced that such spam attacks would be solved “two years from now.” Unfortunately, his prediction didn’t pan out.

While we wait patiently for Bill to complete his task, you need to take steps to ensure that users can differentiate the legitimate emails that your application sends from malicious emails that may attempt to impersonate them. This task has two aspects: advertising which IP ranges are permitted to send emails for the domain(s) you own and allowing an email client to detect whether an email has been modified in transit.

### Sender Policy Framework

By changing your DNS records to list a *Sender Policy Framework* (SPF), you can explicitly state which servers are allowed to send email from your domain. This approach will flag emails sent by malicious actors that pretend to be sent from your domain—that is, that *spoof* the email domain.[](/book/grokking-web-application-security/chapter-14/)[](/book/grokking-web-application-security/chapter-14/)

If you own the domain example.com, and you know that all emails will come from IP addresses in the range 203.0.113.0 to 203.0.113.255, you would implement SPF by adding a DNS record of type `TXT` with the following value:

```
v=spf1              #1
ip4:203.0.113.0/24  #2
-all                #3
```

SMTP travels over *Transmission Control Protocol* (TCP) when traversing the internet. It’s much harder to spoof an IP address than it is to spoof a `From` header field in SMTP; no mechanism can verify that the addressee is who they say they are within the protocol. As a result, SPF provides a simple way for email clients to detect spoofed emails.[](/book/grokking-web-application-security/chapter-14/)

### DomainKeys Identified Mail

You can prevent the emails you send from being tampered with by implementing *DomainKeys Identified Mail* (DKIM). This practice requires adding a public key to your DNS records and signing each email you send with a signature generated from the corresponding private key. Email clients can recalculate the signature when the email arrives and reject one that doesn’t match, which is evidence of tampering.[](/book/grokking-web-application-security/chapter-14/)[](/book/grokking-web-application-security/chapter-14/)

Adding a DKIM header and generating DKIM signatures as emails are sent is more complex than implementing SPF, but the good news is that your email-sending service will do most of the work. Skip to the “Practical steps” section if you are impatient. Before we get to that section, however, we should answer one last question: what happens to those emails that get rejected when they fail the SPF or DKIM test?

### Domain-Based Message Authentication, Reporting and Conformance

[](/book/grokking-web-application-security/chapter-14/)What happens to rejected emails is dictated by your Domain-Based Message Authentication, Reporting, and Conformance (DMARC) policy. (Yes, the full name is quite a mouthful.) The policy for the domain example.com should be a `TXT` record on subdomain `_dmarc.example.com` that looks like this:[](/book/grokking-web-application-security/chapter-14/)[](/book/grokking-web-application-security/chapter-14/)

```
v=DMARC1;                           #1
p=quarantine;                       #2
rua=mailto:admin@example.com"       #3
```

Specifying a DMARC policy allows you to detect emails that may be flagged as malicious due to configuration errors.

### Practical steps

The good news about SPF, DKIM, and DMARC is that you are probably implementing these standards already. Transactional email providers (such as SendGrid, Mailgun, Postmark, or Amazon’s Simple Email Service) will walk you through the steps of creating SPF and DKIM records when you sign up for the service. Indeed, you usually won’t be permitted to send emails until you have completed these steps. The same is usually true of cloud-based email providers that handle your business email (such as Google Workspace or Microsoft 365), as well as digital marketing services like MailChimp and HubSpot.[](/book/grokking-web-application-security/chapter-14/)

If your organization hosts its own email servers, your system administrators will be using *Mail Transfer Agent* (MTA) software. The most common MTAs are Microsoft Exchange (Windows) and SendMail/Postfix (Linux). You can find out how to implement authenticated email on each agent by reading the technical documentation provided by the vendor.[](/book/grokking-web-application-security/chapter-14/)

## Open redirects

[](/book/grokking-web-application-security/chapter-14/)We should look at one further way in which you may be acting as an accomplice to spam emails. This vulnerability is associated with insecure use of redirects. Redirects are useful functions for building a website. If a user attempts to access a secure page before they are logged in, it is conventional to redirect them to the login page, put the original URL in a query parameter, and (after they have logged in) automatically redirect them to their original destination.[](/book/grokking-web-application-security/chapter-14/)[](/book/grokking-web-application-security/chapter-14/)

This type of functionality shows that you are putting thought into the user experience, so it is to be encouraged. But you need to be sure that anywhere you do redirects, you do them safely. Otherwise, you are putting your users in harm’s way by enabling phishing.

You see, webmail service providers excel at spotting spam and other types of malicious messages, and a common detection method is to parse the outbound links in emails. These links are compared with a list of banned domains, and if a domain is deemed to be malicious, the email is redirected to the junk folder.

If your website can be used to redirect users to arbitrary third-party domains, it is said to exhibit an *open-redirect* *vulnerability*. Spam emailers use open redirects to bounce a user off your website (a trusted domain), so their messages are less likely to be marked as malicious. Your website is presumably not regarded as harmful by the spam detection algorithm, so the emails containing links will not be sent to the junk folder.[](/book/grokking-web-application-security/chapter-14/)

If the user clicks the link, they see *your* website in the link, but they will end up on whatever site the attacker wants to direct them to. A confused user might download malware or worse because of the trust they put in your site. In the following illustration, your site (breddit.com) is used as a stepping stone to send the user to a harmful site (burnttoast.com).

### Disallow offsite redirects

An easy way to prevent open-redirect vulnerabilities is to check the URL being passed to the redirect function. Make sure that all redirect URLs are *relative paths*—in other words, that they start with a single backslash (`/)` character and hence redirect the user to a page on your website. URLs that start with two backslashes (`//`) will be interpreted by the browser as protocol-agnostic absolute URLs, so they should be rejected too. Here’s how you might check whether a redirect is safe in Python:[](/book/grokking-web-application-security/chapter-14/)[](/book/grokking-web-application-security/chapter-14/)[](/book/grokking-web-application-security/chapter-14/)[](/book/grokking-web-application-security/chapter-14/)

```
import re
from flask import request, redirect 

@app.route('/login', methods=['POST'])
def do_login():
 username = request.form['username']
 password = request.form['password']
    
 if credentials_are_valid(username, password):
   session['user'] = username
   original_destination = request.args.get('next')
 if is_relative(original_destination):
   return redirect(original_destination)

 return redirect('/')

def is_relative(url):
 return url and re.match(r"^\/[^\/\\]", url)
```

### Check the referrer when doing redirects

Some web applications legitimately need to perform redirects to third-party sites. Interstitial pages, which warn users that they are leaving a web application and going to an external web application, often operate in this manner.[](/book/grokking-web-application-security/chapter-14/)[](/book/grokking-web-application-security/chapter-14/)

These types of redirects should be triggered only by pages on your site. You can ensure that this is the case by checking the `Referer` header in the HTTP request. (Yes, that’s how the name is spelled in the HTTP specification—a typo that the standards committee never caught, unfortunately.) The `Referer` header can be spoofed by an attacker who is in full control of the HTTP request. But in the particular situation we are protecting against, the attacker is sending a harmful link to a victim and generally won’t have control of the HTTP headers. Here’s how you might check the header before doing a redirect in Python:[](/book/grokking-web-application-security/chapter-14/)

```
from urlparse.parse import urlparse

@app.before_request
def check_referer():
   referer = request.headers.get('Referer')

   if not referer:
      return 'Missing referer. Access denied.', 403

   if urlparse(referer).netloc != 'yourdomain.com' :
      return 'Invalid referer. Access denied.', 403
```

## Summary[](/book/grokking-web-application-security/chapter-14/)

-  When calling external APIs via HTTP, ensure that the domain of the URL is drawn from server-side code. It’s generally better to use the SDK provided by the vendor if one is available.
-  If your web app makes HTTP requests to arbitrary third-party URLs, ensure that they are performed only on behalf of real, authenticated users, and apply a per-user rate limit.
-  Validate that the URLs to which you make HTTP requests prevent attackers from probing your internal network. Ensure that they contain domains rather than IP addresses and use the HTTPS protocol, and don’t allow any that use nonstandard ports.
-  Implement SPF so that recipients can verify whether emails sent from your domain came from a permitted server.
-  Implement DKIM so that email clients can detect emails that have been manipulated in transit.
-  Ensure that all redirects on your website are to other pages on your site if possible. Pay special attention to login pages, which often redirect the user to the original destination after logging them in.
-  If you need to redirect to an external resource, verify that the `Referer` header in HTTP corresponds to a page of your web application.[](/book/grokking-web-application-security/chapter-14/)
