# 7 Network vulnerabilities

### In this chapter

- How monster-in-the-middle attacks can be used to snoop on unencrypted traffic
- How your users can be misdirected by DNS poisoning attacks and doppelganger domains
- How your certificates and encryption keys could be compromised—and what to do if they are

[](/book/grokking-web-application-security/chapter-7/)In chapter 6, we looked at vulnerabilities that occur in the browser. In chapter 8, we will start to look at how web servers exhibit vulnerabilities. Between the two, however, are a lot of internet and a large class of vulnerabilities that occur as traffic passes back and forth.

Securing traffic passing over the internet is theoretically a solved problem: a modern browser supports strong encryption, and obtaining a certificate for your web application is relatively straightforward. The hacking community is nothing if not ingenious, however; it continues to find ways to throw a wrench into the works.

The network vulnerabilities we will look at in this chapter can be divided into three categories: intercepting and snooping on traffic, misleading the user about where traffic is going, and stealing or spoofing credentials (including keys) to steal traffic at its destination. Let’s start with the first class of network vulnerability.

## Monster-in-the-middle vulnerabilities

A *monster-in-the-middle* (MITM) attack occurs when an adversary sits between two parties and intercepts messages between them. (You may see this type of attack described as *man-in-the-middle*, but *monster* is more fun.) For our purposes in this chapter, we’re considering traffic between a user agent (such as a browser) and the web application to which it is talking.[](/book/grokking-web-application-security/chapter-7/)[](/book/grokking-web-application-security/chapter-7/)[](/book/grokking-web-application-security/chapter-7/)[](/book/grokking-web-application-security/chapter-7/)

Before we rush to outline the solution to this attack (which is to send traffic over HTTPS, of course), we should look at how this type of attack is typically implemented. It’s fun to imagine gremlins living in the wires of the internet and tapping the phone lines, but the actual methods of intercepting traffic are more prosaic and illuminating.

### Intercepting traffic on a network

When a browser sends a request to a web server, the journey typically involves several hops. The browser tells the operating system to connect to the local network (nowadays, often a Wi-Fi network), which sends the request to the internet service provider (ISP), which then routes the request over the internet backbone to the relevant Internet Protocol (IP) address, sometimes via another ISP. (Connecting on a corporate network is a little different, and large organizations often connect to the internet backbone directly.)[](/book/grokking-web-application-security/chapter-7/)[](/book/grokking-web-application-security/chapter-7/)[](/book/grokking-web-application-security/chapter-7/)[](/book/grokking-web-application-security/chapter-7/)[](/book/grokking-web-application-security/chapter-7/)

Any of the interim networks in this process is a good place for an attacker to launch an ambush. Most local networks use the *Address Resolution Protocol* (ARP) to resolve IP addresses to *Media Access Control* (MAC) addresses because IP addresses are used for internet routing, but traversing local network traffic needs to be routed to a MAC address. Your laptop, for example, has a fixed MAC address. Each device connecting to a network advertises its MAC address and asks to be assigned an IP address.[](/book/grokking-web-application-security/chapter-7/)[](/book/grokking-web-application-security/chapter-7/)

ARP is a deliberately simple protocol that allows any device on the network to advertise itself as the endpoint for a particular IP address or range of addresses. This situation allows an attacker to launch an *ARP spoofing attack*, spamming the network with phony ARP packets so that outbound internet traffic is routed to the attacker’s device rather than to the gateway that should be used because devices on a network believe whichever ARP packet they receive.[](/book/grokking-web-application-security/chapter-7/)[](/book/grokking-web-application-security/chapter-7/)

When the intruder’s device is receiving traffic, launching an MITM attack is simple. The attacker can route all traffic to the appropriate gateway, but because the traffic is passing through their device, they can read any unencrypted traffic that passes their way.

Wi-Fi and corporate networks are obvious targets for ARP spoofing attacks. If an attacker wants to avoid the hassle of connecting to someone else’s network, they can set up their own Wi-Fi hotspot and wait for victims to connect. Devices (and users) tend to be quite casual about which networks they connect to, so this approach yields good results, too.[](/book/grokking-web-application-security/chapter-7/)

You can mitigate MITM attacks by ensuring that traffic is encrypted en route. When you ensure that all traffic to your web application is passed over an HTTPS connection, you can be sure that an attacker will be unable to read or manipulate requests to your site or responses on the way back. HTTPS makes the traffic tamperproof and indecipherable by anyone who does not have the private encryption key associated with the certificate.

As we reviewed in chapter 3, implementing HTTPS means acquiring a certificate from a certificate authority and hosting it (with the accompanying private encryption key) on your web server. Because encrypted connections foil MITM, hackers have discovered ways to prevent secure connections from being established in the first place.

### Taking advantage of mixed protocols

Web servers are happy to serve the same content over insecure and secure channels, and by default, they often accept unsecured HTTP traffic on port 80, as well as secure traffic on port 443. For a long time, websites were designed to be indifferent about which protocol they used for perceived low-risk content, upgrading to HTTPS only when the user wanted to log in or do something else that they perceived as being high risk.[](/book/grokking-web-application-security/chapter-7/)[](/book/grokking-web-application-security/chapter-7/)[](/book/grokking-web-application-security/chapter-7/)[](/book/grokking-web-application-security/chapter-7/)

Then Moxie Marlinspike came along. Today, Marlinspike is best known as the creator of the secure messaging app Signal, but he originally made a name for himself by releasing a hacking tool called `sslstrip`. *SSL* stands for *Secure Sockets Layer*, the predecessor to Transport Layer Security (TLS).[](/book/grokking-web-application-security/chapter-7/)[](/book/grokking-web-application-security/chapter-7/)

Marlinspike noticed that many supposedly secure sites (including banking websites) at the time presented content over insecure HTTP connections, upgrading to HTTPS only when the user logged in and provided their credentials. The `sslstrip` tool takes advantage of this security oversight, allowing an attacker to intercept traffic before the upgrade takes place by replacing HTTPS URLs in login forms (for example) with their HTTP equivalents.

When the user supplies their credentials, `sslstrip` can capture their login details but still pass the request to the server via HTTPS. As a result, the attack is undetectable from the web server, which sees only the secure connection.[](/book/grokking-web-application-security/chapter-7/)

The discovery of the SSL-stripping exploit eventually persuaded the web community that they should move all their content to HTTPS. (Incidentally, HTTPS is better for privacy reasons, too. Even if you aren’t logging in to a website, the fact that you’re viewing particular medical conditions on WebMD probably isn’t something that you want an attacker to see because such information might help them curate a social-engineering attack.)

To ensure that all traffic to your website is sent over a secure connection, you should configure your web server to redirect any insecure connections on port 80 to their secure counterpart on port 443. You should also implement an HTTP Strict Transport Security (HSTS) header to tell browsers to make only secure connections to your web server.[](/book/grokking-web-application-security/chapter-7/)

In this example, we tell the browser to upgrade to HTTPS without even waiting for the redirect and to keep the policy in place for the next year:

```
Strict-Transport-Security: max-age=31536000
```

The `Strict-Transport-Security` header was developed as a direct response to Marlinspike’s talk at the DEFCON hacker conference, where he released the details of the SSL-stripping attack. (In case you’re curious, the talk is on YouTube: [https://www.youtube.com/watch?v=MFol6IMbZ7Y](https://www.youtube.com/watch?v=MFol6IMbZ7Y)).[](/book/grokking-web-application-security/chapter-7/)[](/book/grokking-web-application-security/chapter-7/)

If you use NGINX as your web server, a secure configuration looks like this:

```
server {
  listen 80;
  server_name example.com;
  return 301 https://$server_name$request_uri;    #1
}

server {
  listen 443 ssl;
  server_name example.com;
  
  ssl_certificate /path/to/ssl/certificate.crt;   #2
  
  ssl_certificate_key /path/to/ssl/private.key;
  add_header Strict-Transport-Security
  
    "max-age=31536000";                           #3
  ssl_protocols TLSv1.3;                          #4
}
```

### Downgrade attacks

TLS is not a monolithic technology; it’s an evolving standard. In the initial TLS handshake, the client and server negotiate the algorithms that will be used to exchange keys and encrypt traffic. Older algorithms tend to be less secure because the availability of computing power to an attacker increases every year, and exploits that allow for faster decryption are constantly discovered.[](/book/grokking-web-application-security/chapter-7/)[](/book/grokking-web-application-security/chapter-7/)[](/book/grokking-web-application-security/chapter-7/)

Knowing this, attackers perform *downgrade attacks*, inserting themselves into the middle of a TLS handshake and attempting to persuade the client and server to fall back to a less secure algorithm so that the attackers can intercept and snoop on traffic. One such exploit is *POODLE*, which stands for *Padding Oracle on Downgraded Legacy Encryption*. (You feel that the authors were *stre-e-etching* to come up with a dog-related pun.)[](/book/grokking-web-application-security/chapter-7/)

To mitigate downgrade attacks, your web server should be configured to accept a minimally strong version of TLS. At the time of this writing, the recommended minimum version of TLS for systems handling credit card data is 1.3, as illustrated in the earlier NGINX configuration file. (The standards are published at [https://www.pcisecuritystandards.org](https://www.pcisecuritystandards.org/)).

Specifying a minimum TLS version won’t place an undue burden on most web applications because modern browsers are self-updating and generally support the latest encryption standards. Some web applications can’t be quite as strict in their approach, however. If you are maintaining web services for embedded devices, it’s rare for such clients to receive security updates, so unfortunately, you’ll have to support older encryption standards for a longer period.

## Misdirection vulnerabilities

*The Sting* is a 1973 crime caper film in which Paul Newman and Robert Redford play con artists trying to grift an organized crime boss. The pair (spoiler alert) set up an elaborate fake betting shop, persuade their mark to put down a large bet, and make off with his money after the shop is raided by the “police” (who are accomplices of the con men).[](/book/grokking-web-application-security/chapter-7/)[](/book/grokking-web-application-security/chapter-7/)[](/book/grokking-web-application-security/chapter-7/)

This plot is a twist on an old con that is alive and well in the internet age. Setting up a fake website is far easier (and has much greater reach) than setting up a fake business to take a victim’s money. If an attacker cannot intercept communication between you and your users, they may instead try to trick users into visiting their own copycat website to take advantage of users’ trust in your website. Let’s look at some of the techniques that hackers use.

### Doppelganger domains

You are likely familiar with spam emails that attempt to trick the user into visiting fishy-looking links like `www.amazzzon.com` and `safe.paypall.com`. (If you aren’t, you have led a blessed life. Please let the author know which email service provider has protected you thus far.)[](/book/grokking-web-application-security/chapter-7/)[](/book/grokking-web-application-security/chapter-7/)

[](/book/grokking-web-application-security/chapter-7/)These fake websites are known as *doppelganger domains* because they mimic, with ill intent, a domain that the user already trusts. As well as using intentional typos, such domains often use similar characters to confuse victims: 0 (zero) for O (oh, the letter) or 1 (one) for l (L, the letter), and so on.

Other doppelganger domains abuse the International Domain Name standard to swap in characters from non-ASCII character sets, such as replacing the Latin *a* character with the Cyrillic lookalike *а* character*.* In this type of *homograph* *attack*, the domain `wikipedia``.org` becomes `wikipedi`a`.org`, which looks largely indistinguishable to the layperson. (When this book goes to print, they will be probably be indistinguishable on the page!)[](/book/grokking-web-application-security/chapter-7/)

Modern browsers attempt to foil this type of attack by rendering internationalized domain names in *Punycode*—Unicode rendered with the ASCII character set—unless those characters are in a language that the user has set in their preferences. Here’s how our fake Wikipedia looks in Google Chrome (unless your system is set up to use the Cyrillic alphabet).[](/book/grokking-web-application-security/chapter-7/)[](/book/grokking-web-application-security/chapter-7/)

Attackers can also take advantage of a victim’s lack of knowledge about subdomains. One fatal security mistake in the design of the internet is that domains should be read from right to left. The site `www.google.com.etc.com` would actually be hosted on the `etc.com` domain, but less-savvy internet users may not be aware of this fact.

So what can you do to protect your users from doppelganger domains? You aren’t the internet police, after all, and these fake domains aren’t under your control.

Large organizations sometimes launch awareness campaigns to inform their users of the threat, but these campaigns tend to be of limited use. Sending emails to users to tell them to be aware of fake domains will simply annoy more technologically minded users and go over the heads of those who are likely to fall victim to such a scam.

Tools such as `dnstwister` allow you to detect doppelganger domains, and even a Google search alert might help you detect scammers. Some organizations go so far as to buy every potentially misleading domain as a form of protection, though this approach can get expensive very quickly. You should take a couple of concrete steps, though.[](/book/grokking-web-application-security/chapter-7/)

First, if your web application allows users to share links or messages containing links, you need to ensure that links are blocked if they contain malicious domains. If an attacker is trying to make victims of your users, your own comments pages are the best places to trawl for victims. Here’s an example of how you might scan for malicious links in comments in Node.js:

```
function convertUrlsToLinks(comment, blocklist) {
  comment = escapeHtml(comment);

  // Find anything that looks like a link, check
  // it is safe.
  const urlRegex = /(https?:\/\/[^\s]+)/g;
  return comment.replace(urlRegex, (match) => {                   #1
    const url = new URL(match);
  

    if (blocklist.includes(url.hostname)) {                       #2
      throw new Error(`Blocked domain found: ${url.hostname}`);
    }

    return `<a href="${url.href}">${url.href}</a>`;               #3
  });
}
```

Second, you should secure the transactional emails you send out to users so that an attacker cannot pretend to be you and send fake emails from your domain. *Spoofing* the From address in an email is trivially easy for an attacker. In chapter 14, we will look at ways to protect your users from spoofed emails by using DomainKeys Identified Mail (DKIM).[](/book/grokking-web-application-security/chapter-7/)[](/book/grokking-web-application-security/chapter-7/)[](/book/grokking-web-application-security/chapter-7/)

### DNS poisoning

The Domain Name System (DNS) is the guidebook for the internet. Computers that communicate on the internet deal with IP addresses, but humans are better at remembering alphabetic domain names. DNS is the magic that allows a browser (or another internet-connected device) to resolve one to the other.[](/book/grokking-web-application-security/chapter-7/)[](/book/grokking-web-application-security/chapter-7/)

Because DNS is the one place where IP addresses can be definitively resolved, it’s only natural that it’s attacked by hackers who want to divert user traffic to malicious sites. Usually, this type of attack is achieved by means of DNS poisoning. Before we get into the details of that concept, let’s go over briefly how DNS works.

Suppose that a browser wants to resolve a URL like `https://www.example.com` to a specific IP address. This task is typically performed by the DNS resolver supplied by the host operating system, such as the `glibc` library in Linux. In the most straightforward case, the DNS resolver asks a root DNS server (whose IP is hardcoded into the browser) which DNS server can supply IP addresses for the `.com` domain.

The resolver proceeds to make a request to the DNS server described in the initial response and asks where it should look for the `example.com` domain.[](/book/grokking-web-application-security/chapter-7/)

Finally, the resolver takes the answer from that lookup and asks the server hosted at that address for the IP address of the `www.example.com` subdomain.

When these three successive lookups are complete, the browser has its IP address, and the web request can be initiated.

As you may have guessed, this example is a radical simplification of the process because if every internet request hit the root domain servers, they would be extremely busy. (There are only 13 of those servers in the world!) To make things more scalable, each layer of DNS consists of multiple servers, and a lot of caching occurs at each stage of the process.[](/book/grokking-web-application-security/chapter-7/)

The browser caches DNS lookups in memory; the operating system typically keeps its own DNS cache, too. More significantly, your ISP and/or corporate network hosts its own DNS server, which responds to most DNS requests instead of referring them to an authoritative server.

All these DNS caches make juicy targets for hackers who want to divert traffic by using a DNS poisoning attack. For purposes of simple mischief, it’s enough to edit the host files on the victim’s device, which lives at `/etc/hosts` in Linux or at `C:\Windows\System32\drivers\etc\hosts` in Windows.

More serious threats target the root servers and ISPs. In 2019, a hacker group known as Sea Turtle compromised a Swedish ISP and the DNS for the Saudi Arabian top-level domain `.sa`. This sophisticated hacking operation pointed to state-sponsored actors, though nobody was able to pinpoint their motives. (Maybe they had a grudge against countries whose names begin with *S*?)

So what can you do to protect against DNS poisoning? The good news is that having your traffic stolen via DNS poisoning isn’t a huge threat in isolation, provided that you implement HTTPS. If an attacker manages to steal your HTTPS traffic, they’ll also need to present a certificate to the victim’s browser. Their fake website has two alternatives:

-  If they present your certificate, they won’t be able to decrypt traffic sent to their fake site (provided that they haven’t found a way to compromise your encryption keys; for more on that topic, see the end of the chapter).
-  If they present their own certificate, the browser will complain that it is illegitimate.

[](/book/grokking-web-application-security/chapter-7/)For this reason, DNS poisoning attacks are rarely used in isolation. They’re usually combined with the sort of certificate compromise that we look at in the next section.

The other good news is that the DNS system is in the process of being made more secure. A newish set of cryptographic protocols called DNS Security Extensions (DNSSEC) allows DNS servers to sign their responses digitally and hence prevent DNS poisoning attacks. Enabling DNSSEC requires changes to both the client and the server because the DNS server must publish DNS records containing cryptographic keys (and be prepared to validate DNS responses from other DNS servers), whereas the client must validate the encryption keys returned by servers.[](/book/grokking-web-application-security/chapter-7/)

At this writing, among the mainstream browsers, only Chrome enables DNSSEC by default. (Mozilla Firefox, Apple’s Safari, and Microsoft Edge require the user to make configuration changes or install plugins.) DNS servers are ahead of the game here. Nearly all top-level domains support DNSSEC, and the major hosting providers support DNSSEC for the domains they host. Enabling DNSSEC varies in complexity by hosting provider. Google Cloud, for example, makes the process fairly seamless.

[](/book/grokking-web-application-security/chapter-7/)Even if support for DNSSEC is in its infancy, it’s a good idea to enable it for your domains, if feasible. Nothing will break if you do. Browsers that don’t yet support the extensions will simply ignore it.

### Subdomain squatting

When you launch a website, you become an active participant in DNS. Your domain name is registered with DNS, and you have to set up extra DNS registries on your domain itself. This setup might consist of a *mail exchange* (MX) record used to route email to your mail provider, an A record to route web traffic to the IP address of your load balancer, and a CNAME entry to allow for the `www` prefix for web traffic.[](/book/grokking-web-application-security/chapter-7/)[](/book/grokking-web-application-security/chapter-7/)[](/book/grokking-web-application-security/chapter-7/)[](/book/grokking-web-application-security/chapter-7/)

You might also find yourself setting up arbitrary subdomains for specific features of your product. If you own the `example.com` domain, for instance, you might set up the subdomain `blog.example.com` to point to your company blog, hosted in a separate web application. Or you might use `test.example.com` to host your testing environment.

These subdomains are listed publicly in your DNS entries, and attackers actively scan for *dangling* subdomains—ones that point to resources that no longer exist. This situation typically happens when a resource is deprovisioned but the DNS entry for the subdomain is not removed in a timely fashion.[](/book/grokking-web-application-security/chapter-7/)

Suppose that your company decided to host its corporate blog on the blogging website Medium.com, but the marketing department later abandoned the idea and didn’t tell the IT department. You end up with a DNS entry pointing to a nonexistent website.

[](/book/grokking-web-application-security/chapter-7/)In a *subdomain squatting* attack, the attacker claims the namespace of the deprovisioned resource, effectively moving into the space you left vacant. In this case, they might scan your DNS entries for any dangling subdomains and register the abandoned username `example-blog` on `medium.com`.[](/book/grokking-web-application-security/chapter-7/)

A stolen subdomain is a valuable resource for a hacker. Because stolen subdomain resources are accessible under your domain, any malicious website that they host on their stolen subdomain may be able to steal cookies from your web traffic.

Stolen subdomains are also commonly used in phishing attacks and to host links to malware. Victims are more likely to click a link to a trusted domain, and email service providers are less likely to mark emails as malicious if the domain names of links in the email match the domain from which the email is sent.[](/book/grokking-web-application-security/chapter-7/)

You can take a few approaches to prevent subdomain squatting. First, take care to delete subdomain entries before deprovisioning any resource (which means documenting processes that need to be followed internally).

Second, if you implement a lot of subdomains, consider scanning periodically for dangling subdomains, using an automated domain enumeration tool like `Amass` and `Sublist3r`. (These tools are the same ones that hackers use, so they come recommended.)[](/book/grokking-web-application-security/chapter-7/)[](/book/grokking-web-application-security/chapter-7/)

Finally, be conservative about which (if any) subdomains can read cookies and are covered by your certificate. Two different domains—such as `example.com` and `blog.``example.com` or `blog.example.com` and `support.example.com`—can share cookies only if the `domain` attribute is present in the header:[](/book/grokking-web-application-security/chapter-7/)

```
Set-Cookie: session_id=273819272819191; domain=example.com
```

If you don’t need to read the cookie on subdomains, omit the `domain` attribute.

When you apply for a digital certificate, you will be asked which domains this certificate applies to (including subdomains). *Wildcard certificates* can be used on all subdomains for a given domain (and tend to cost money). Avoid using them if you don’t need them; it’s more secure to enumerate your subdomains explicitly when creating the certificate.[](/book/grokking-web-application-security/chapter-7/)

## Certificate compromise

You may recall from chapter 3 that digital certificates are the secret sauce that power encryption on the internet. Each browser trusts a few certificate authorities. These authorities in turn sign certificates for particular domains after the domain owner issues a certificate signing request and demonstrates that they own a particular domain.[](/book/grokking-web-application-security/chapter-7/)[](/book/grokking-web-application-security/chapter-7/)[](/book/grokking-web-application-security/chapter-7/)

The process might involve more interim steps. The root certificate that a certificate authority uses is hugely sensitive, so it’s generally used to generate and sign interim certificates for everyday use before being locked away safely. Also, large organizations often act as their own intermediate certificate authorities, which allows them to issue certificates for their own domains. Thus, verifying a particular certificate involves checking a *chain of trust*.[](/book/grokking-web-application-security/chapter-7/)

Hackers are going to hack, though, so compromises along the chain of trust can and do happen. In 2011, the certificate authority Comodo was compromised, and a hacker was able to issue bogus certificates. In an act of admirable pettiness, the hacker revealed in a separate message that the admin password for Comodo Cybersecurity was `globaltrust` and that they simply guessed the password to achieve access.

Governments and state-sponsored actors also tend to get in on the act. US hacker Edward Snowden, for example, leaked information revealing that the National Security Agency used forged certificates to conduct MITM attacks against the Brazilian oil company Petrobras. Some governments aren’t clandestine about their snooping. The government of Kazakhstan has tried several times to force its citizens to install a “national security certificate” that would allow them to snoop on all internet traffic in the country. Fortunately, Google and Apple refused to honor the certificate in Chrome and Safari, so the scheme never took hold.

### Certificate revocation

[](/book/grokking-web-application-security/chapter-7/)If your certificate authority is compromised or the private encryption keys that correspond to a certificate are stolen, it is important to revoke the certificate with the originating authority. Often, you can perform this task by using a command-line tool like `certbot` or visiting an admin website. The following figure shows the domain registrar NameCheap.[](/book/grokking-web-application-security/chapter-7/)[](/book/grokking-web-application-security/chapter-7/)[](/book/grokking-web-application-security/chapter-7/)

Web browsers can determine whether a certificate has been revoked by checking a *certificate revocation list* (CRL) or an *online certificate status protocol* (OCSP) response.[](/book/grokking-web-application-security/chapter-7/)[](/book/grokking-web-application-security/chapter-7/)

A CRL is a list of revoked certificates published by the certificate authority that issued the certificates. The CRL is downloaded periodically by the web browser and stored locally. When the browser encounters a certificate during a TLS handshake, it checks whether the certificate is listed in the CRL. If it is, the browser displays a warning to the user.

An OCSP request is a real-time query to the OCSP responder associated with a certificate authority to determine the revocation status of a certificate. Most modern web browsers use both CRLs and OCSPs to check the revocation status of TLS certificates and fall back on one or the other, depending on the configuration of the server being accessed.

When a certificate has been revoked, you have to reissue a replacement certificate and deploy it to your servers. It’s important to automate this process to avoid manual errors that may occur when putting keys in place. You don’t want any compromised certificates mistakenly staying in place!

### Certificate transparency

[](/book/grokking-web-application-security/chapter-7/)Being able to revoke certificates quickly is one thing, but determining whether your certificate has been compromised is a whole other challenge—particularly if the compromise happens higher up the trust chain. To help with this task, certificate authorities now implement *certificate transparency* logs; they’re required to publish all certificates they issue. This requirement enables website owners to detect any rogue certificates that have been issued for their domain.[](/book/grokking-web-application-security/chapter-7/)[](/book/grokking-web-application-security/chapter-7/)

You can monitor these certificate transparency logs by using tools that may be built into the dashboard of your hosting provider. Cloudflare, for example, allows you to enable this functionality with a single click.

Scanning for rogue certificates issued against your domain is a helpful way to detect compromises early and is generally painless to implement.

## Stolen keys

We’ve discussed the importance of using cryptography to avoid MITM attacks; we’ve discussed how phony domains and DNS poisoning can be used to steal traffic; and we’ve discussed compromised certificates. The last risk we discuss is probably the simplest to describe: what happens when an attacker steals your private encryption keys.[](/book/grokking-web-application-security/chapter-7/)[](/book/grokking-web-application-security/chapter-7/)[](/book/grokking-web-application-security/chapter-7/)

A typical deployment of a web server and application looks like the following figure. The web server has access to both the certificate (which is public) and the private encryption key (which must be kept private).

I’ve deliberately omitted a lot of the details (typically, many web servers sit behind a load balancer, for example), but this figure illustrates the main points. The web server actively uses the private key that pairs with your certificate to decrypt HTTPS traffic before sending unencrypted HTTP traffic downstream to the application server and encrypting responses going the other way. So the attacker’s goal comes down to accessing this private key in some fashion.

The easiest way to steal an encryption key is to log on to the server with a protocol like Secure Shell (SSH) or a remote desktop on Windows. This approach requires an attacker to have an access key and access to the server on which the web server is running, in the same way that an administrator might when performing server maintenance.[](/book/grokking-web-application-security/chapter-7/)

Make sure that this combination of credentials isn’t easy to achieve. Keep this risk in mind when you issue access keys. It’s a good idea to issue them only on an as-needed basis and remove them when access is no longer needed. Better, restrict server access to automated processes that perform the necessary maintenance and release-time changes.

If the application server and web server are running on the same computer, it may be possible for an attacker to exploit a *command injection* vulnerability in the application server to steal encryption keys from disk. We will learn how to protect against this type of attack in chapter 12, but knowing about this risk is a helpful argument for isolating your web and application servers on separate machines.[](/book/grokking-web-application-security/chapter-7/)

On the computer that hosts the web server, accessing the directory that contains private keys should be possible only by someone who has elevated permissions. Ensure that you practice the *principle of least privilege* (discussed in chapter 4). Only the web server process should have access to that particular directory; low-level users or processes that are logging on to the operating system should not have such permissions.[](/book/grokking-web-application-security/chapter-7/)

Finally, be careful during your deployment process so that sensitive keys aren’t exposed over the internet. A web server like NGINX is typically used to host public assets—images, JavaScript, CSS files, and so on—because these assets are static and generally don’t require the execution of server-side code to deliver to the browser. Writing encryption keys to public directories is an easy and fatally dangerous mistake to make.

If you suspect that your TLS keys have been compromised, you should revoke your certificates immediately, regenerate keys, and make the required disclosures that we will review in chapter 15. Erring on the side of caution is key. *Any* unexplained access to your servers should be regarded as a probable compromise. Reviewing access logs and running an intrusion detection system review can help detect anomalous activity.[](/book/grokking-web-application-security/chapter-7/)

## Summary

-  Acquire a certificate and use HTTPS communication to protect against MITM attacks.
-  Ensure that all communication to your web application is done via HTTPS by implementing HSTS.
-  Require a minimal version of TLS (1.3 as of this writing) to protect against downgrade attacks.
-  Protect against doppelganger domains by filtering harmful links in user-contributed content and using tools to detect lookalike domains.
-  Know what DNS poisoning is, and remember how important it is to use HTTPS to mitigate its risks. Enable DNSSEC on your domains where feasible.
-  Be cautious about creating subdomains, and if you use a lot of them, use automated scanning to detect dangling subdomains.
-  Regularly scan certificate transparency logs for suspicious certificates issued on domains you own.
-  Have a scripted process for revoking certificates and reissuing them, and run the process if you get any hint of unauthorized access to your servers.
-  Limit access to the servers that hold your encryption to people and processes.
-  Deploy your web and application servers on separate machines.
-  Be careful about which directories on your application server are shared publicly (those that contain certificates and assets, for example) and which are not (those that contain private encryption keys).[](/book/grokking-web-application-security/chapter-7/)
