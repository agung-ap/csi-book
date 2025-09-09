# 3 Encryption

### In this chapter

- How to use encryption to hide sensitive data on a public channel
- How to encrypt information in transit and at rest
- How to tell web servers and browsers to make secure connections
- How to use encryption to detect changes in data

The *Copiale cipher* is a manuscript containing 105 pages of text handwritten in secret code, bound in gold-and-brocade paper, and thought to date back to 1760. For many years, the origin of the text remained a mystery; it was discovered by personnel at the East Berlin Academy after the end of the Cold War and remained undecipherable for more than 260 years.[](/book/grokking-web-application-security/chapter-3/)[](/book/grokking-web-application-security/chapter-3/)

In 2011, a team of engineers and scientists from the University of Southern California and the University of Sweden finally decoded its meaning. The text, it turned out, described the rites of an underground society of opticians who called themselves *the Oculists*. Banned by Pope Clement XII, these secretive ophthalmologists were led by a German count, and the text itself describes their initiation ceremony. New initiates to the society were invited to read the words on a blank piece of paper; then, when they were unable to do so, they would have a single eyebrow hair plucked and be asked to repeat the process. Nobody knows quite why these mysterious opticians went to such lengths to hide their activities. Perhaps the papal edicts had declared LensCrafters to be a tool of the devil.[](/book/grokking-web-application-security/chapter-3/)

The Copiale cipher is an example of an encrypted text, albeit a very old and fairly peculiar one. Nowadays, encryption is used everywhere in public life, especially on the internet, because the requirement to move secret information over an open channel makes encryption the key to secure browsing. Encryption is so fundamental to many of the security recommendations we will make in this book that we will spend this chapter getting familiar with the terminology and how to use it on the network, in the browser, and in the web server itself.

## The principles of encryption

*Encryption* describes the process of disguising information by converting it to a form that is unreadable by unauthorized parties. *Cryptography* (the science of encrypting and decrypting data) goes back to ancient times, but we have come a long way from the hand-coded homophonic ciphers of secretive Germanic lens makers, which simply substitute one character for another according to a predefined key. Modern encryption algorithms are designed to be unbreakable in the face of the vast computation power available to a motivated attacker and to make use of advances in number theory (which are relatively straightforward to grasp) and elliptic curves (which are esoteric even by mathematical standards).[](/book/grokking-web-application-security/chapter-3/)[](/book/grokking-web-application-security/chapter-3/)[](/book/grokking-web-application-security/chapter-3/)

As a web application author, you (fortunately) don’t need to fully grasp how encryption algorithms work to make use of them; you only need to employ them in your application and know when doing so is appropriate. In the next few sections, we lay out the key concepts that will help you achieve this goal. It’s time for a bit of theory!

## Encryption keys

Modern encryption algorithms use an *encryption key* to encrypt data into a secure form and a *decryption key* to convert it back to its original form. If the same key is used to encrypt and decrypt data, we have a *symmetric encryption algorithm*. Symmetric encryption algorithms are often implemented as *block ciphers*, which are designed to encrypt streams of data by chopping them into blocks of fixed sizes and encrypting each block in turn.[](/book/grokking-web-application-security/chapter-3/)[](/book/grokking-web-application-security/chapter-3/)[](/book/grokking-web-application-security/chapter-3/)

Encryption keys are generally large numbers but are usually represented as strings of text for ease of parsing. (If the number chosen isn’t sufficiently large, an attacker can guess numbers until they manage to decrypt the message.) Here’s a simple Ruby script that encrypts some data:[](/book/grokking-web-application-security/chapter-3/)

```
require 'openssl'

secret_message = "Top secret message!"                #1
encryption_key = "d928a14b1a73437aac7xa584971f310f"   #2

enc = OpenSSL::Cipher::Cipher.new("aes-256-cbc")      #3
enc.encrypt
enc.key = encryption_key

encrypted = enc.update(secret_message) + enc.final    #4

dec = OpenSSL::Cipher::Cipher.new("aes-256-cbc")      #5
dec.decrypt
dec.key = encryption_key

decrypted = dec.update(encrypted) + dec.final
```

*Asymmetric encryption algorithms*, invented in the 1970s, are the magic ingredient that powers the modern internet. Because a different key is used to encrypt and decrypt data in this type of algorithm, the encryption key can be made public while the decryption key is kept secret. This arrangement allows anyone to send a secure message to the holder of the decryption key, safe in the knowledge that only they will be able to read it. This setup, called *public key cryptography*, allows you (as a web user) to communicate securely with a website using HTTPS, as we will see next. A person who wants to receive secure messages can give away their public key, allowing anyone to secure messages in a way that only their computer can understand.[](/book/grokking-web-application-security/chapter-3/)[](/book/grokking-web-application-security/chapter-3/)

Public key encryption allows a sender to encrypt a message without having access to the decryption key. Anyone can lock the box, but only the recipient of the secret information can open it. The public key permits only locking, not unlocking.

Here’s how public key encryption looks in Ruby. Note that we are generating a new pair of keys each time the code runs, but in real life, the *key pair* (the combination of the encryption and decryption key) would be stored in a secure location:[](/book/grokking-web-application-security/chapter-3/)[](/book/grokking-web-application-security/chapter-3/)

```
require 'openssl'

secret_message = "Top secret message!"

keypair = OpenSSL::PKey::RSA.new(2048)                 #1

public_key  = keypair.public_key                       #2

encrypted = public_key.public_encrypt(secret_message)  #3
decrypted = key_pair.private_decrypt(encrypted_string) #4
```

We should introduce a couple of further concepts while we are on the subject of encryption. A *hash algorithm* can be thought of as an encryption algorithm whose output *cannot* be decrypted. But at the same time, the output is guaranteed to be unique; there is a near-zero chance of two different inputs generating the same output. (This scenario is called a *hash collision*.)[](/book/grokking-web-application-security/chapter-3/)[](/book/grokking-web-application-security/chapter-3/)

Hashing algorithms can be used to determine whether the same input has been entered twice or an input has unexpectedly changed without the application’s having to store the input. This approach can be handy if the input is too large to store or if, for security reasons, you don’t want to keep it around.

The output of the hashing algorithm is called the *hash value* or *hash*. Because the algorithm cannot be used to decrypt a hashed value, the only way to figure out which value was used to generate a hash is to use brute force: feeding the algorithm a huge number of inputs until it generates a hash matching the one you are trying to decrypt.[](/book/grokking-web-application-security/chapter-3/)[](/book/grokking-web-application-security/chapter-3/)[](/book/grokking-web-application-security/chapter-3/)

The power of hash algorithms is that they allow you to detect changes in data without having to store the data itself. This technique has applications for storing credentials and detecting suspicious events on a web server.

## Encryption in transit

Now that we have nailed down some of the terminology of encryption, we can look at how traffic to a web server can be secured by using *encryption in transit—*encrypting data as it passes over a network.[](/book/grokking-web-application-security/chapter-3/)[](/book/grokking-web-application-security/chapter-3/)

Technologies that use the Internet Protocol (IP) implement encryption in transit by using *Transport Layer Security* (TLS), a low-level method of exchanging keys and encrypting data between two computers. The older and less secure predecessor of TLS is *Secure Sockets Layer* (SSL), and you will see both protocols used in a similar context.[](/book/grokking-web-application-security/chapter-3/)[](/book/grokking-web-application-security/chapter-3/)

*Hypertext Transport Protocol Secure* (HTTPS)—the magic behind the little padlock icon in the browser—is HTTP traffic passed over a TLS connection.[](/book/grokking-web-application-security/chapter-3/)[](/book/grokking-web-application-security/chapter-3/)

TLS uses a combination of cryptographic algorithms called the *cipher suite* that the client and server negotiate during the initial TLS handshake. (TLS counterparties are polite—hence, the need to shake hands when meeting.) A cipher suite contains four elements:[](/book/grokking-web-application-security/chapter-3/)[](/book/grokking-web-application-security/chapter-3/)

-  A *key exchange* algorithm[](/book/grokking-web-application-security/chapter-3/)
-  An *authentication* algorithm[](/book/grokking-web-application-security/chapter-3/)
-  A *bulk encryption* algorithm[](/book/grokking-web-application-security/chapter-3/)
-  A *message authentication code* algorithm[](/book/grokking-web-application-security/chapter-3/)

The key exchange algorithm is a public key encryption algorithm that is used only to exchange keys for the bulk encryption algorithm, which operates much faster but requires secure key exchange to work. Authentication ensures that the data is being sent to the right place. Finally, the message authentication code algorithm detects any unexpected changes to data packets as they are passed back and forth.

##### DEFINITION

Establishing a TLS connection requires a *digital certificate*, which incorporates the public key used to establish the secure connection to a given domain or IP address. Clicking the padlock icon in the browser’s address bar allows you to see detailed information about the certificate. Each certificate is issued by a certificate authority, and browsers have a list of certificate authorities that they trust. Anyone can produce a certificate (called a *self-signed certificate*), however, so the browser shows a security warning if it does not recognize the signer of the certificate.[](/book/grokking-web-application-security/chapter-3/)[](/book/grokking-web-application-security/chapter-3/)

Using HTTPS for traffic to and from your web server ensures

-  *Confidentiality*—Traffic cannot be intercepted and read by an attacker.[](/book/grokking-web-application-security/chapter-3/)[](/book/grokking-web-application-security/chapter-3/)
-  *Integrity*—Traffic cannot be manipulated by an attacker.[](/book/grokking-web-application-security/chapter-3/)
-  *Nonrepudiation*—Traffic cannot be spoofed by an attacker.[](/book/grokking-web-application-security/chapter-3/)

These items are essential for a web application, so you should use HTTPS for everything. Let’s review, in practical terms, how to do that.

### Taking practical steps

The good news is that, as the author of a web application, you don’t need to know how TLS operates under the hood. Your responsibilities boil down to

-  Obtaining a digital certificate for your domain
-  Hosting the certificate on your web application
-  Revoking and replacing the certificate if the accompanying private key is compromised or the certificate expires
-  Encouraging all user agents (such as browsers) to use HTTPS, which encrypts traffic by using the public encryption key attached to the certificate

The nuances of certificate management vary depending on how you are hosting your web application. If you don’t have a dedicated team managing this task at your organization, be sure to read the documentation that your hosting provider supplies. Here’s an example of obtaining a certificate by using Amazon Web Services (AWS) via the AWS Certificate Manager.[](/book/grokking-web-application-security/chapter-3/)[](/book/grokking-web-application-security/chapter-3/)[](/book/grokking-web-application-security/chapter-3/)

Certificates need to be managed securely and are often issued and revoked by command-line tools such as `openssl` or via APIs. In chapter 7, we look at some of the ways that certificates can be compromised.[](/book/grokking-web-application-security/chapter-3/)

### Redirecting to HTTPS

Encouraging all user agents to use HTTPS means redirecting HTTP requests to the HTTPS protocol. Although this task can be achieved in application code, the redirect is usually performed by a web server such as NGINX (pronounced “engine X”). Here’s what the configuration might look like in NGINX:[](/book/grokking-web-application-security/chapter-3/)

```
server {
 listen 80 default_server;
 server_name _;
 return 301 https://$host$request_uri;
}
```

##### A note on terminology

[](/book/grokking-web-application-security/chapter-3/)NGINX is a simple but fast web server that typically sits in front of the *application server* that hosts the dynamic code of your web application. Your organization might be using Apache or Microsoft’s Internet Information Services (IIS) to do a similar job. The terminology gets a little blurred because application servers (such as Python’s Gunicorn and Ruby’s Puma) *can* be deployed on a standalone basis. People who write code for web applications tend to refer to application servers as “the web server”—a convention we will adopt for the rest of this book unless we need to make a distinction. The following figure shows some common web servers and application servers.[](/book/grokking-web-application-security/chapter-3/)[](/book/grokking-web-application-security/chapter-3/)[](/book/grokking-web-application-security/chapter-3/)

![](https://drek4537l1klr.cloudfront.net/mcdonald/Figures/03-08.png)

### Telling the browser to always use HTTPS

The code of your web application should also encourage clients to use an encrypted connection. You do this by specifying *HTTP Strict Transport Security* (HSTS) in HTTP response headers:[](/book/grokking-web-application-security/chapter-3/)[](/book/grokking-web-application-security/chapter-3/)

```
Strict-Transport-Security: max-age=604800
```

This line tells the browser to always make an HTTPS connection for the specified period. (The `max-age` value is in seconds, so we are specifying a week in this case.) When encountering an HSTS header for the first time, the browser makes a mental note to always use HTTPS during the period described. We’ll look at HSTS in detail in chapter 7 and illustrate why it is so important to implement.[](/book/grokking-web-application-security/chapter-3/)

## Encryption at rest

*Encryption at rest* describes the process of using encryption to secure data written to disk. Encrypting data on the disk protects against an attacker who manages to gain access to the disk because they will be unable to make sense of the data without the appropriate decryption key.[](/book/grokking-web-application-security/chapter-3/)[](/book/grokking-web-application-security/chapter-3/)

You should use encryption at rest wherever your hosting provider implements it, though describing how the encryption keys should be managed safely usually takes some configuration. (Encryption is no defense against an attacker who can make off with the decryption key.)

Disk encryption is *essential* for any system that contains sensitive data, such as configuration stores, databases (including backups and snapshots), and log files. Often, this feature can be enabled when you set up the system. Here’s an example of setting up encryption at rest for the AWS Relational Database Service.

### Password hashing

*Credentials*—a fancy name for usernames and passwords—are favorite targets of hackers. If you are storing passwords for your web application in a database, you should use encryption to secure them. In particular, you should encrypt passwords with a hashing algorithm and store only hashed values in your database. Do not store passwords in plain text![](/book/grokking-web-application-security/chapter-3/)[](/book/grokking-web-application-security/chapter-3/)[](/book/grokking-web-application-security/chapter-3/)[](/book/grokking-web-application-security/chapter-3/)

The theoretical attacker we are concerned with in this scenario is a hacker who managed to gain access to your database. Maybe one of the database backups was left on an insecure server, or a developer accidentally uploaded the database credentials to a source control system.

Storing passwords in plain text makes things easy for an attacker. In the event of this type of data breach, the attacker will attempt to use the stolen data. Usually, the most sensitive information in a database is the credentials. If the attacker has your users’ usernames and passwords, they can not only log in to your web application as any of those users, but also start trying these credentials in other people’s web applications. (Humans reuse passwords all the time—a regrettable but inevitable aspect of our being fleshy blobs with limited long-term memory.)

If we store hashes instead of passwords, we defend against this attack scenario because hashing is a one-way encryption algorithm. Given a list of password hashes, an attacker cannot recover the password easily. (We’ll see in chapter 8 that risks still occur when your password hashes get leaked, but those risks are less severe than they would be with plain-text passwords.)

[](/book/grokking-web-application-security/chapter-3/)

Your web application can still check the correctness of a password when a user logs back in by recalculating the hash value of the newly entered password and comparing it with the stored value:

```
require 'bcrypt'
include BCrypt::Engine

password = "my_topsecretpassword"
salt     = generate_salt
hash     = hash_secret(password, salt)              #1

password_to_check = "topsecretpassword"

if hash_secret(password, salt) == hashed_password   #2
  puts "Password is correct!"
else
  puts "Password is incorrect."
end
```

##### NOTE

This Ruby code uses the `bcrypt` algorithm, which is a good choice for a strong hashing algorithm. An encryption algorithm is strong if it takes a lot (an unfeasibly huge amount) of computing power to reverse-engineer the values. Older hashing algorithms, such as MD5, are considered weak because the availability of computing resources has grown so much since their invention.

### Salting

[](/book/grokking-web-application-security/chapter-3/)The preceding code snippet also illustrates a *salt*, an element of randomness that means the output of the hashing algorithm will be different each time you run this code, even given the same password. Adding a salt to your hashes is called *salting*. You can use the same salt for each password you store or, better, generate a new one for each password and store it alongside the password. Better yet, you can combine these techniques by peppering. In *peppering*, the element of randomness comes from both a standard value in configuration and a per-password generated value:[](/book/grokking-web-application-security/chapter-3/)[](/book/grokking-web-application-security/chapter-3/)

```
require 'bcrypt'
include BCrypt::Engine

pepper = "e4b1aa34-3a37-4f4a-8e71-83f602bb098e"                   #1

password = "my_topsecretpassword"
salt     = generate_salt
hash     = hash_secret(password + pepper, salt)                   #2

# Store the hashed password and salt in a database
password_to_check = "my_topsecretpassword"

if hash_secret(check _password + pepper, salt) == hashed_password #3
  puts "Password is correct!"
else
  puts "Password is incorrect."
end
```

Salting and/or peppering your hashes helps protect against an attacker who is armed with a *lookup table*, a list of precalculated hash values for common passwords and hash algorithms. Without salted passwords, an attacker can easily backward-engineer a large chunk of your passwords by checking them against the lookup table. With salted passwords, an attacker has to resort to *brute-forcing* passwords—trying common passwords one at a time and checking them against the hash value.

## Integrity checking

[](/book/grokking-web-application-security/chapter-3/)In chapter 2, we saw how to use the subresource integrity attribute to detect malicious changes to JavaScript files. This concept illustrates a broader one called *integrity check**ing*, which allows two communicating software systems to detect unexpected or suspicious-looking changes in data.[](/book/grokking-web-application-security/chapter-3/)[](/book/grokking-web-application-security/chapter-3/)[](/book/grokking-web-application-security/chapter-3/)

Integrity checking has analogues in real life. Tamper-evident packaging, for example, is designed to indicate when a container has been opened, so it is used to package medications or foods that need to be kept free of contamination.

To perform integrity checking on data, you pass the data through a hashing algorithm. Then you can pass the data, the hash value, and the name of the hashing algorithm to downstream systems. At this point, the recipient of the data can recalculate the hash value and detect when the data has been manipulated. (To prevent an attacker from recalculating the hash for maliciously tampered data, hashes are generally stored in separate locations or passed down different channels.)

When you are familiar with integrity checking, you see it everywhere. Some common uses are

-  Ensuring that data packets have not been manipulated during transmission when using TLS
-  Ensuring that software modules have not been manipulated when downloaded by a dependency manager
-  Ensuring that code is deployed cleanly (without errors or modifications) to servers
-  Detecting suspicious changes in sensitive files during intrusion detection
-  Ensuring that session data has not been manipulated when passing the session state in a browser cookie

To avert the risk that an attacker will manipulate the data *and* the hash value, the data and hash value can be passed via separate channels, or the hashing algorithm can be set up so that only the sender and recipient can calculate values. (Often, sender and recipient will have exchanged a set of keys beforehand over a secure channel.)

## Summary

-  Encryption can be used to secure data passing over a network. In particular, public key encryption allows secure communication over IP.
-  Practically speaking, using encryption in transit means acquiring a digital certificate, deploying it to your hosting provider, redirecting HTTP connections to HTTPS, and adding an HSTS to your web application.
-  Encryption can also be used to secure data at rest. You should use this technique to secure databases or log files that contain sensitive information.
-  Passwords for your web application should be hashed with a strong hash and salted and peppered before being stored. Never store passwords in plain text!
-  You can use hashing to perform integrity checking, which enables you to detect unexpected changes in files, data packets, code, or session state.[](/book/grokking-web-application-security/chapter-3/)
