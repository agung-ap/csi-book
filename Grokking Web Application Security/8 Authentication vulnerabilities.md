# 8 Authentication vulnerabilities

### In this chapter

- How attackers attempt to guess credentials on your web application by using brute-force attacks
- How to stop brute-force attacks by implementing a variety of defenses
- How to store credentials securely
- How your web application might leak the existence of usernames, and why that’s bad

[](/book/grokking-web-application-security/chapter-8/)Many web applications are designed for interaction among users, whether that interaction is sharing cat videos or arguing about recipes in the comments section of the *New York Times* website. User accounts on websites represent our online presence, and as such, they have value to hackers. For some sites, the value is obvious: compromised credentials for banking websites can be used directly for fraud. Other types of stolen accounts can be used for marketing scams or identity theft.

If your website has a login page, you have a responsibility to protect the identity of your users. This responsibility means keeping their *credentials*—the information each user has to enter to gain access to their account—out of the hands of attackers. Let’s look at some of the ways attackers attempt to steal credentials and how to stop them.[](/book/grokking-web-application-security/chapter-8/)

## Brute-force attacks

When we talk about a user’s credentials, we are normally referring to their username and password. A user can identify themselves in ways other than choosing and reentering a password, but these methods are usually offered in addition to, rather than instead of, passwords, as we shall discuss in the “Multifactor authentication” section later in the chapter.[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)

Often, usernames on a website are email addresses—unless the site is designed to allow interaction among users. In that case, each user typically signs up with an email address and then chooses a separate display name.

The most straightforward way for an attacker to steal credentials is to guess them by using a hacking tool to try millions of username-and-password combinations and record which ones return a success code. This method is called a *brute-force attack*.

Unsurprisingly, several hacking tools allow you to launch this attack from the command line. One such tool, Hydra, comes bundled with the Kali Linux distribution and is popular with hackers and penetration testers.

Rather than enumerate every username from `aaaaaaa` to `ZZZZZZZZ`, hackers tend to use lists of usernames and passwords stolen from previous data leaks. A bit of back-of-the-envelope math makes it obvious why. If we simplify our brute-force attack and assume that there are eight characters in the username and eight in the password, each taking an alphabetic (upper- or lowercase) or numeric character, we can generate 476 *nonillion* possible combinations! At the rate of one login attempt per second, executing the attack will take 15 quadrillion years—probably more time than is worthwhile to compromise a meatloaf chat forum.[](/book/grokking-web-application-security/chapter-8/)

A hacking tool like Hydra allows you to plug in wordlists of usernames and passwords to try, which speeds things along significantly. Users often reuse usernames and passwords across websites. (Each of us has limited memory space, after all, and life is too short to spend thinking up a new password for every site we visit.) Applying Hydra to many websites in this way starts to produce results in minutes.[](/book/grokking-web-application-security/chapter-8/)

Relying on only a username and password to authenticate your users, then, is dangerous. How can you strengthen your authentication?

## Single sign-on

One way to ensure that your authentication process is secure is to let someone else do the work. By deferring the responsibilities of authentication to a third party, you push the risk and liabilities to an organization that (presumably) has a great deal of security expertise *and* relieve your users of the task of having to think up yet another password for your web application.[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)

Deferring authentication to a third party is called *single sign-on* (SSO). SSO uses two main technologies, depending on whether you are dealing with individual users or employees of organizations. *OpenID Connect* (along with the related protocol *OAuth*) powers the “Log in with Google” or “Log in with Facebook” buttons you frequently see on websites. Security Assertion Markup Language (SAML) is generally used to support corporate customers who like to manage their user credentials in-house. Let’s look at each of these options in turn.[](/book/grokking-web-application-security/chapter-8/)

### OpenID Connect and OAuth

In the bad old days of the internet, if a web application wanted access to your Gmail contacts, you had to give it your Gmail password, and the application would log in as you to grab that data. This arrangement was decidedly sketchy—like giving the keys to your house to a stranger just because they said they wanted to read your gas meter.[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)

To overcome this flawed design, various internet bodies invented the *Open Authorization* (OAuth) standard, which allows an application to grant limited permissions to a third-party application on behalf of a user. Now apps can ask to import your Gmail contacts by sending an OAuth request to the Gmail API. Then the user logs in to the Google authentication page and grants the app permission to access their contacts. Finally, the Google API issues the application an access token that allows it to look up contact lists for that user in the Google API. At no point does the third-party app see the user’s credentials, and the user can revoke permissions (and, hence, invalidate the access token) at any point via the Google dashboard.[](/book/grokking-web-application-security/chapter-8/)

[](/book/grokking-web-application-security/chapter-8/)

OAuth is generally used for granting permission *(authorization)* rather than identification *(authentication)*. But it’s easy to add an authentication layer on top; the app merely needs to ask permission to know the user’s email address (or possibly more personal profile data, such as a phone number or full name).

This task, in effect, is what OpenID Connect achieves by piggybacking on top of OAuth. The calling app receives a *JSON Web Token* (JWT)—a digitally signed blob of *JavaScript Object Notation* (JSON) containing profile information about the user, such as their email address.[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)

Practically speaking, implementing OAuth/OpenID means following the documentation provided by the *identity provider*, which is the application that will perform the authentication. Usually, you have to register with the identity provider and be granted an access token that identifies your application, which can be used to make OAuth calls. Let’s look at some code to make this concept concrete.[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)

In Ruby, the `omniauth` gem is a popular way to implement Open ID sign-on. You can easily add to your templates a feature to log in with Facebook with the following code snippet:[](/book/grokking-web-application-security/chapter-8/)

```
<%= link_to facebook_omniauth_authorize_path(
     next: params[:next]), method: :post %>
 <div class="login">Log in with Facebook</div>
<% end %>
```

The function that handles the HTTP redirect from Facebook needs only to validate the request, unpack the credentials, and look up a user of that name:

```
def facebook_omniauth_callback
  auth = request.env['omniauth.auth']
  
  if auth.info.email.nil?
    return redirect_to new_user_registration_url,
           alert: 'Please grant access to your email address'
  end
  
  @user = User.find_for_oauth(auth)
  
  if @user.persisted?
    sign_in @user
    redirect_to request.env['omniauth.origin'] || '/',
                event: :authentication
  else
    redirect_to new_user_registration_url
  end
end
```

As you can see, implementing Open ID requires only a few lines of code in a modern web application. One downside, however, is the sheer number of identity providers you may end up supporting. The `omniauth` library supports more than a hundred! Choose carefully the ones that suit your needs before adding so many login buttons to the login page that it ends up looking like the side of a NASCAR vehicle.

### Security Assertion Markup Language

*Security Assertion Markup Language* (SAML) is comparable to OAuth but is used by organizations that run their own identity-provider software. It’s a much older protocol than OAuth but still heavily used in the corporate world. Typically, customers who use SAML are running a *Lightweight Directory Access Protocol* (LDAP) server like Microsoft’s Active Directory, and they want their users to authenticate against this LDAP server when logging in to your web application. This arrangement gives the customer peace of mind in two ways: they can immediately revoke access to your systems for employees who leave the organization (a major headache for large companies), and their employees don’t enter passwords directly into your web application.[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)

Integrating with a SAML identity provider is a little more complicated than using OAuth. In SAML terminology, your web application is a *service provider* (SP) and will need to publish an XML file containing your SAML metadata. This will tell the identity provider the URL at which your assertion control service (ACS) is hosted and the digital certificate the identity provider should use to sign requests. The *ACS* is the callback URL to which the identity provider will send the user after they sign in.[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)

[](/book/grokking-web-application-security/chapter-8/)

## Strengthening your authentication

Not everyone has a social media login or Gmail address, and SAML is generally used only in a corporate setting because supporting your own identity provider is a major undertaking. So even if SSO can lessen some of the burdens of authenticating your users, you’re likely to end up using some sort of in-house authentication. Let’s discuss some ways of making your authentication resilient to brute-force attacks.[](/book/grokking-web-application-security/chapter-8/)

### Password complexity rules

Brute-force guessing of passwords relies heavily on finding users with guessable passwords. Hence, encouraging your users to choose less-guessable passwords reduces the possibility of a successful brute-force attack. This is the philosophy behind enforcing password complexity rules, which require users to choose passwords that match certain criteria. Following are some common criteria:[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)

-  Passwords must be a minimum length.
-  Passwords must contain mixed-case letters, numbers, and symbols.
-  Passwords cannot contain any part of the username.
-  Passwords cannot contain repeating letters.
-  Passwords may not be reused (must differ from previous passwords that the user chose).

All these criteria are useful, but they can irritate users who aren’t using a password manager. (Also, the rules are unevenly applied across the internet. For some reason, my coffee machine demands a more complex password than my bank’s website does.) Like many cybersecurity considerations, this situation is one in which usability and security are pulling in different directions.

Of these password-complexity demands, password length is the most significant. Users who are forced to use symbols or numbers tend to append numbers to the end or add an exclamation point (!) to keep the complexity algorithm happy. But brute-force attacks generally don’t attempt to guess longer passwords; each extra character in the password length multiplies the number of possible password values significantly.

Philosophically speaking, users tend to understand that strong passwords are better but quickly experience password fatigue if you enforce too much complexity. A good compromise is to nudge them into good habits by rating the complexity of the password as they choose it. The `zxcvbn` library is helpful for this purposes. `zxcvbn` is available for virtually every mainstream programming language from C++ to Python to Scala and advertises itself as such (see [https://github.com/dropbox/zxcvbn](https://github.com/dropbox/zxcvbn)):[](/book/grokking-web-application-security/chapter-8/)

`zxcvbn` is a password strength estimator inspired by password crackers. Through pattern matching and conservative estimation, it recognizes and weighs 30K common passwords, common names, and surnames according to US census data, popular English words from Wikipedia and US television and movies, and other common patterns like dates, repeats (`aaa`), sequences (`abcd`), keyboard patterns (`qwertyuiop`), and l33t speak.

Here’s how you would use JavaScript to rate the strength of a password (that is, how difficult it would be to guess) as the user types it:[](/book/grokking-web-application-security/chapter-8/)

```
<script src="/js/zxcvbn.js"></script>

<input type="password" id="password-input">
<p id="password-score"></p>

<script>
 const input    = document.getElementById('password-input');
 const strength = document.getElementById('password-score');
 
 input.addEventListener('input', () => {
   const password = passwordInput.value;
   const result   = zxcvbn(password);

   strength.textContent = `Strength: ${result.score}/4`;

   if (result.score === 0) {
     strength.textContent += ' (Very Weak)';
   } else if (result.score === 1) {
     strength.textContent += ' (Weak)';
   } else if (result.score === 2) {
     strength.textContent += ' (Medium)';
   } else if (result.score === 3) {
     strength.textContent += ' (Strong)';
   } else {
     strength.textContent += ' (Very Strong)';
   }
 });
</script>
```

In addition to password complexity rules, secure systems often enforce *password rotation*, which forces each user to choose a new password every few weeks or months. In theory, this idea is a good one; it reduces the time window in which an attacker can use a compromised password and is the sort of discipline you should apply to passwords in your internal systems (such as databases). If you try to enforce this system on your users, however, don’t be surprised if the response is to simply add a number to the end of the same stem password each time a reset is required.[](/book/grokking-web-application-security/chapter-8/)

### CAPTCHAs

If you can distinguish real human users from hacking tools trying to steal credentials, you can defeat brute-force attacks. Tools that attempt to perform this task are called *Completely Automated Public Turing tests to tell Computers and Humans Apart* (CAPTCHAs). You will recognize them as those widgets that require you to select pictures of traffic lights (for example) or decipher some wavy, grainy text to complete the login process on a website.[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)

CAPTCHAs are generally easy to install on your web application. Modern CAPTCHAs such as Google’s reCAPTCHA 3.0 operate invisibly, using background signals like mouse movements and keyboard input to decide whether a user is human—no more clicking fuzzy pictures of bridges! To install reCAPTCHA, you simply sign up for a Google developer account and then request a site key and the accompanying secret key at [https://developers.google.com/recaptcha](https://developers.google.com/recaptcha).

Integrating the CAPTCHA on a login page requires you to add a new hidden field to your HTML form:

```
<script src="https://www.google.com/recaptcha/api.js?render=SITE_KEY"></script>
<input type="hidden"
      name="recaptcha_token"
      id="recaptcha_token">
```

From there, you add a snippet of JavaScript to populate the hidden field on form submission:

```
<script>
 grecaptcha.ready(() => {
   grecaptcha.execute(SITE_KEY,
     {action: 'form_submit'}).then((token) => {
       document.getElementById('recaptcha_token').value = token;
   });
 });
</script>
```

[](/book/grokking-web-application-security/chapter-8/)This code generates a unique token when the form is submitted. This token can be evaluated on the server side when the request is received. Here’s how to do that in Ruby:

```
require 'net/http'
require 'json'

http_response = Net::HTTP.post_form(
 URI('https://www.google.com/recaptcha/api/siteverify'),
 'secret'   => SECRET_KEY,
 'response' => recaptcha_token)
 
result = JSON.parse(response.body)

if result['success'] == true
 puts('User is human')
end
```

If you use asynchronous HTTP requests to perform the login, you can simply add the token to JSON in the request.

##### NOTE

The secret key is just that. It must be kept on the server side rather than passed to the browser in JavaScript. Otherwise, an attacker will be able to forge tokens and bypass the CAPTCHAs.

Though CAPTCHAs are easy to implement, there is an ongoing debate in the security community about their actual effectiveness. A CAPTCHA certainly deters simple hacking attempts on web applications, but sophisticated hackers have found ways around them.

Computer vision and machine learning, for example, can crack many visual captures. Where those tools aren’t sufficient, the CAPTCHA image can be sent to a CAPTCHA farm of human operators who can solve them for cheap. (At this writing, a company called 2CAPTCHA is offering a rate of $1 for every 1,000 CAPTCHAs it solves.) You also need to ensure that any CAPTCHA you use has accessibility options for users who use screen readers to navigate your site. Nevertheless, CAPTCHAs raise the bar significantly for would-be attackers, so they remain a good way to deter low-level hackers from brute-forcing your login page.

### Rate limiting

You can distinguish a brute-force attack from a human user mistyping their password by counting the number of incorrect password guesses. Many websites account for mistypes and offer a small delay before returning the HTTP response each time an incorrect set of credentials is entered. This delay typically begins as imperceptible but grows with each failure. (A popular algorithm uses *exponential backoff*, doubling the delay with each failure.) Because brute-force attacks generate thousands of failures in quick succession, they quickly get bogged down and stop seeing responses. Meanwhile, genuine users won’t see much of an effect because the initial delays between failures are so small. This situation is a form of *rate limiting*, in which the author of an application restricts how often an actor can access a protected resource, such as a login page.[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)

Rate limiting is helpful except for one small snag: it permits a malicious user to launch a *lockout attack*, which is a form of denial-of-service attack. By using a hacking tool to spam the login page with a victim’s username and repeatedly failing, they can make that account unavailable for use by a legitimate user. Being locked out of a website is better than having one’s account compromised, to be sure, but still an enormous annoyance.[](/book/grokking-web-application-security/chapter-8/)

To work around this situation, rate limiting is often applied by IP address rather than by username—which is to say, repeated failures coming from the same IP address will have a timing penalty applied regardless of the username supplied. When a legitimate user tries to log in from a different IP address, they will still be able to log in.

This arrangement also has a downside, however. Sometimes, legitimate users share an IP address while navigating the internet through a proxy like a virtual private network, from a corporate network, or via the secure TOR network. Additionally, attackers aren’t limited to using a single IP address: sophisticated brute-force attacks can be launched from a network of bots, each with a distinct IP address.

Nevertheless, rate limiting is worth implementing to deter simple attacks. Just ensure that delays don’t become so long that a user can be locked out of their account by a determined adversary.

## Multifactor authentication

The consensus among security experts is that the most effective way to protect your authentication system is to implement *multifactor authentication* (MFA)—a process that requires a user to provide two or more forms of identification as they log themselves in. Usually, the authentication process requires the user to enter a username, a password, and one other secret item. For web applications, this secret item is generally one of the following:[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)

-  A passcode texted to a phone number to which the user has access
-  A passcode generated by an authenticator app that the user previously synched with the web application
-  Acknowledgment of a push notification sent to an app on the user’s smartphone
-  Biometric proof of identity, such as a fingerprint or facial recognition

Before you go full steam on implementing MFA, however, you should consider how accessible it is to your users. Depending on your user base, not all users will have a phone number; not all of those users will have a smartphone; and not all of *those* users will have a device capable of taking biometric measurements. For this reason, MFA is often offered as an option to users but enforced only for secure systems.

Each MFA technique has pros and cons that you should consider. Hackers have been known to clone phones or steal phone numbers through social engineering to compromise the accounts of high-profile people. (Amazingly, the rapper Punchmade Dev released a song called “[Wire Fraud Tutorial](https://www.complex.com/music/a/markelibert/punchmade-dev-wire-fraud-tutorial-viral-hit)” describing how to clone SIM cards and use them to steal cash from banks. The song explains the process far better than 99% of the security documentation on the internet.)

Authenticator apps are easy to plumb into your web application and don’t bear the same associated costs as text message passcodes. These apps use *time-based one-time passwords* (TOTP), typically six-digit numbers that are refreshed with a new value every 30 seconds. They are generated by combining a shared secret with the timestamp and applying a hash algorithm like SHA-256—yet another use of hash algorithms on the internet. To validate these TOTP values, your website and the authenticator app must share the secret “seed” value, usually by asking the user to scan a QR code during the setup process.[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)

When the app and the website know the shared secret, authentication is a simple matter of challenging the user each time they log in for the latest six-digit number shown in their authenticator app and validating on the server side. When registering the app, the TOTP system generates several recovery codes, which the user is asked to store in a secure location in case they ever lose their phone. In reality, most users skip this step (who even has a printer nowadays?) or lose the codes, so account recovery often drops back to password reset links sent to email addresses.

## Biometrics

You can use biometrics to implement MFA by using WebAuthn. This browser API allows web applications to use biometric information to validate their users, provided that the device has some sort of biometric measurement capability such as a fingerprint sensor or facial recognition. No fingerprints or other sensitive information are sent to the server; instead, biometric information is stored locally on the user’s device and used to unlock a token that will be sent to the server to verify the user’s identity. Here’s how you would perform the initial capture of biometric information in the browser using WebAuthn in client-side JavaScript:[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)

```
if (typeof(PublicKeyCredential) == "undefined") { #1
  throw new Error('Web Authentication API not supported.');
}

let credential = navigator.credentials.create({
  publicKey: {
    challenge: new Uint8Array([/* 
      server challenge here 
    */]),                                         #2
    rp: {
      name: 'Example Website',                    #3
    },
    user: {
      id: new Uint8Array([/* user ID here */]),   #4
      name: 'exampleuser@example.com',
      displayName: 'Example User',
    },
    authenticatorSelection: {
      authenticatorAttachment: 'platform',        #5
      userVerification: 'required',
    },
    pubKeyCredParams: [
      {type: 'public-key', alg: -7. },
      {type: 'public-key', alg: -257},
    ],
    timeout: 60000,
    attestation: 'direct',
  },
});
```

You should note a few things here. First, the device may not support WebAuthn, so you need to check compatibility before proceeding. If WebAuthn isn’t supported, you should suggest another method of MFA instead.

The `challenge` value is a strongly random number (32 bytes long) generated on the server and sent to the browser ahead of initialization. The actual value of the number is unimportant as long it’s unguessable, but because it is different each time, it prevents an attacker from using a *replay attack* to redo the initialization phase and forge their own credentials.[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)

The `id` value in the `user` section is an unchanging identifier for the user. You should recognize the fact that users sometimes change usernames or email addresses, so make this value a nonchanging property of your user profiles. (At the same time, try to avoid leaking ID values from database rows in your `users` table. Chapter 13 talks about the dangers of information leakage.)

The last thing to note is that the method of biometric authentication is set simply as `platform`, which means that the device is free to use fingerprint recognition, facial recognition, or even voice recognition if the device supports it. It’s generally best to let the device and the user determine their preferences. (My iPad insists that I take my glasses off before it will recognize me, and it straight up refuses to recognize me when I’m slouched in a reading position on the couch.) More pertinently, keeping users’ options open keeps biometrics accessible to users who may not be able to use one particular form or another.

The call to `create()` in the WebAuthn API returns an object containing a public key that can be stored on the server and used to confirm the user’s identity when they next log in. The call takes the following form:[](/book/grokking-web-application-security/chapter-8/)

```json
{
  type:  'public-key',
  id:    ArrayBuffer,                  #1
  rawId: ArrayBuffer,
  response: {                          #2
    authenticatorData: ArrayBuffer,
    clientDataJSON:    ArrayBuffer,
    signature:         ArrayBuffer,
    userHandle:        ArrayBuffer
  },
  getClientExtensionResults: () => {}
}
```

The public key is embedded in the property `response.authenticatorData` as binary data. Note that this output will differ depending on which domain the JavaScript is running on. Because we are not explicitly stating the *relying party*—the service asking for credentials to be set up—the API takes the host domain for that input.[](/book/grokking-web-application-security/chapter-8/)

The private key that pairs with the public key returned by `create()` is stored securely on the user’s device and used to regenerate a further security assertion when the user logs back in. This arrangement requires the user to provide their biometric proof of identity once again and can be triggered by some JavaScript in the browser in the following method:

```javascript
let credentials = navigator.credentials.get({
 publicKey: {
   challenge: new Uint8Array([/* server challenge here */]),
   allowCredentials: [{
     id:    new Uint8Array([/* credential ID here */]),
     type: 'public-key',
   }],
   userVerification: 'required',
   timeout: 60000,
 },
}).then((assertion) => {
 console.log("User authenticated successfully")
})
```

This security challenge requires a new `challenge` value and the `id` of the public key we generated previously. Because this process is happening in the browser, the returned `credentials` object must be sent to the server for validation. (An attacker can modify client-side JavaScript to their heart’s content.)

Implementing biometric authentication in the browser is extremely secure when it’s done correctly, and according to certain tech pundits, this type of authentication will eventually replace passwords for native apps and websites. Passwordless authentication has been a dream of those in the cybersecurity industry for a long time—rather unsurprisingly, given the various vulnerabilities we have reviewed so far in this chapter.

## Storing credentials

[](/book/grokking-web-application-security/chapter-8/)Early in this chapter, we discussed the Hydra brute-forcing tool. A typical Hydra brute-force attack can be launched from the command line as follows:[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)

```
hydra -l admin -P /usr/share/wordlists/rockyou.txt
     example.com 
     https-post-form 
     "/login:user=admin&password=^PASS^:Invalid credentials"
```

This command launches an attack against the web page `https://example.com/login`, attempting to log in as user `admin` by trying every password in the file `/usr/share/wordlists/rockyou.txt`. With each attempt, the tool notes whether the HTTP response contains the text *Invalid credentials*; if it does not, the password is assumed to be correct, and the tool logs the hacked credentials.

The name of the password file `rockyou.txt` is notable. This file contains 14 million passwords leaked from the 2009 data breach of a company called RockYou. The only truly notable aspect of the company is that it stored the passwords of its 14 million users in unencrypted, plain-text form so when it got hacked, the company’s leaked passwords became the de facto standard for hackers trying to brute-force websites.

Goodness knows what the chief security officer of RockYou is doing now, but I assume that they don’t mention their previous employment on their resume. To help us learn from that person’s mistakes, let’s look at how to store passwords securely.

### Hashing, salting, and peppering your passwords

If you store passwords for users, you should add an element of randomness and pass them through a strong hash function before saving them, as we learned in chapter 3. Here’s how you would hash a password and recheck the hash value at a later date:[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)

```
require 'bcrypt'

def hash_password(password)
 salt   = BCrypt::Engine.generate_salt
 pepper = ENV['PEPPER']
 hashed_password = BCrypt::Engine.hash_secret(
   pepper + password + salt, salt)
 return [hashed_password, salt]
end

def check_password(password, hashed_password, salt)
 pepper = ENV['PEPPER']
 recalculated_hash = BCrypt::Engine.hash_secret(
   pepper + password + salt, salt)

 return hashed_password == recalculated_hash
end
```

Using a Ruby code sample makes these two functions quite succinct, but a lot is going on in these few lines, which we should unpack. What is `BCrypt`, for example, and why is all the “seasoning” necessary?

A good hash function is designed to be *one-way*, meaning that it is computationally unfeasible for an attacker to guess what input was used to generate a hash value simply by passing a large word list through the algorithm and comparing each result with the hash value they are trying to guess. This process is called *password cracking*, and lists of prehashed values of common passwords used in this type of hack are called *rainbow tables*.[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)

To resist password cracking, you should use a hashing algorithm that takes some time to execute and is not prone to hash collisions, so an attacker has to pay a time cost when trying to crack passwords, and each hash value is genuinely unique. Older, once-common hashing functions such as MD5 and SHA-1 are considered to be insecure now because they are prone to collisions. Instead, you should use a modern hash function such as SHA-2, SHA-3, or bcrypt. Bcrypt works well because you can configure how many cycles the algorithm has to complete, increasing the complexity as computing power increases year on year.

The preceding code snippet also shows how to use salt and pepper values when hashing your passwords. These values are necessary because no matter how strong your hashing algorithm is, you are always vulnerable to precomputed values in password-cracking attempts.

The *salt* value differs for each user password (and needs to be stored alongside the hash value in the database). This difference forces an attacker to precompute a set of different hash values for every password they are trying to crack, vastly multiplying their time commitment.[](/book/grokking-web-application-security/chapter-8/)

The *pepper* value adds a further obstacle for an attacker. Because the pepper value is stored in configuration files outside the database (unlike salt values, the same pepper value is used for each password), an attacker would have to seize the contents of your database *and* your configuration store before they can start cracking passwords. As a result, they have to hack two separate parts of your system.

Hashing credentials protect your users from immediate danger if an attacker manages to steal the contents of your database. Should such an unfortunate circumstance occur, however, you should still assume that your users’ passwords will eventually be compromised and require users to change them. Chapter 15 looks at how to handle the fallout from a data breach.

### Secure credentials for outbound access

Hash functions are useful for storing passwords for inbound access when you don’t want anyone (even you!) to read the value. Passwords for outbound access are a different consideration. Your code needs to be able to use a raw password value at run time, for example, when it connects to a database or makes a connection to a third-party API.[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)

Credentials for outbound access need to be stored securely, which means storing them in encrypted form and decrypting them only when needed. You can achieve this task in a couple of ways (which aren’t mutually exclusive): use an encrypted configuration store or perform the encryption/decryption yourself by using application code.[](/book/grokking-web-application-security/chapter-8/)

Every major cloud-hosting platform—such as Amazon Web Services, Google Cloud, and Microsoft Azure—offers some sort of secure configuration store. Configuration values stored in these stores are easily read by application code and encrypted at rest. Hosting platforms also allow you to mark certain configuration values as *sensitive* so that only users or processes that have certain permissions can access those values. (Remember that your web server processes will need this permission!)

If a secure configuration store is not available to you, or if you want to add an extra layer of security, you can have credentials encrypted and decrypted by application code at run time, which involves writing a utility script to encrypt the value before it is set in configuration. Here’s a script written in Ruby that uses the OpenSSL library to perform the encryption:

```
require 'openssl'

if ARGV.length != 2
 puts "Usage: ruby encrypt.rb <password> <key>"
 exit 1
end

password = ARGV[0]
key = ARGV[1]

iv = OpenSSL::Random.random_bytes(16)

cipher = OpenSSL::Cipher.new('aes-256-cbc')
cipher.encrypt
cipher.key = key
cipher.iv = iv
encrypted_password = cipher.update(password) + cipher.final
encrypted_data = iv + encrypted_password

puts encrypted_data.unpack('H*')[0]
```

This script encrypts the supplied credentials with the *Advanced Encryption Standard* (AES) algorithm, using a 256-bit key. AES requires an *initialization vector* (IV) that must be supplied along with the encryption key. Run-time code that uses the encrypted password needs the encryption key, the encrypted value, and the initialization vector to recover the password value:[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)

```
require 'openssl'

encrypted_data = ENV['ENCRYPTED_PASSWORD']

iv                 = encrypted_data.slice(0, 16)
encrypted_password = encrypted_data.slice(16..-1)

cipher = OpenSSL::Cipher.new('aes-256-cbc')
cipher.decrypt
cipher.iv  = iv
cipher.key = ENV['ENCRYPTION_KEY']
decrypted_password = cipher.update(encrypted_password) +
                    cipher.final
```

It’s essential to store this encryption key in a separate location from the encrypted values because if an attacker compromises your configuration store and nabs both pieces of information (the encryption key and the encrypted value), they have only to guess the encryption algorithm, which is generally easy. This fact leaves you in a bit of a conundrum: where do you store encryption keys except in your usual configuration store? The ideal situation is to use a *key management store*, a managed service that allows you to create and store encryption keys outside your usual configuration store.[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)

As a last resort, it’s not the worst practice to store encryption keys in configuration files kept in your codebase. This approach requires a redeployment of code whenever credentials are reencrypted, and you should be reencrypting and rotating credentials regularly. But it’s better than storing encryption keys and encrypted values in the same location.

## User enumeration

A brute-force attack is much easier to pull off if the attacker can determine which usernames exist on the target website so that they can concentrate on guessing passwords for those human users. A web application that allows an attacker to determine which usernames exist is said to exhibit a *user enumeration* vulnerability.[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)

Websites leak this information in a few common ways. If the login page displays a different error message when a username does not exist, or when the username does exist but the password is incorrect, the attacker can infer which usernames exist in the web application:

[](/book/grokking-web-application-security/chapter-8/)A brute-forcing tool like Hydra can easily be set to enumerate users by collecting usernames that respond with the message `Incorrect password`:

```
hydra -L /usr/share/wordlists/usernames.txt
     -p password example.com https-post-form
     "/login:^USER^&=admin&password=password:Incorrect password"
```

Registration and password reset pages often exhibit a similar vulnerability. If a new user attempts to sign up in your web application with their email address, and the sign-up message reveals that another user already used that email address, an attacker can enumerate users from the registration page.

[](/book/grokking-web-application-security/chapter-8/)Similarly, if the password reset page leaks user information, an attacker can use it to infer which user accounts exist.

Incidentally, this example also demonstrates that you should be using CAPTCHAs on sign-up and password-reset pages because an attacker can easily trigger millions of unwanted emails with a brute-forcing tool like Hydra. Even if they have no access to those email accounts, they can effectively turn your web application into a spamming machine.

To protect against user enumeration, you should take the following precautions:

-  Login pages should show the same error message (such as `Invalid credentials`) when a username does not exist or the password is incorrect.
-  Registration pages should show the same welcome message (such as `Check your inbox`) when a user enters their email address, whether or not they have an existing account.
-  Password-reset pages should show the same message (such as `Check your inbox`) when a user enters their email address, whether or not they have an existing account.

You still need to cope with a couple of edge cases. If an existing user attempts to sign up a second time, you still need to send them an email. Generally speaking, you can send them a regular password-reset email, nudging them to reset the password on their existing account.

Finally, if a user attempts to reset their password by using an email address that doesn’t exist, you have a choice:

-  Don’t send an email and change the acknowledgment message to make the situation clear.
-  Better, send a polite email stating that no account exists yet, but they can click a sign-up link if they want to join.

Either way, it helps to repeat the email address in the acknowledgment message so that users can spot their mistyped email address quickly. Few things are more frustrating than being told that you will receive an email and not getting it!

### Public usernames

[](/book/grokking-web-application-security/chapter-8/)Avoiding user enumeration is straightforward for web applications in which each user logs in with their email address. On forums and social media sites, however, users have a display name that is different from their email address, and these usernames are necessarily public.[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)

Often, the username acts as a profile page. On Reddit.com, for example, the profile for the user `sephiroth420` would be here:

```
https://www.reddit.com/user/sephiroth420
```

On X (formerly Twitter), the corresponding user would be here:

```
https://www.twitter.com/sephiroth420
```

With public usernames, the sensitive piece of information you are trying to protect is which email address corresponds to each username. People have good reasons to remain anonymous on the internet. Login pages, registration pages, and password-reset pages should not leak this information.

[](/book/grokking-web-application-security/chapter-8/)When you design a web application to use public usernames, you have a security decision to make: should you allow your users to sign in with their public display name (rather than their email address)? Because an attacker can enumerate these usernames, the most secure option is to require users to supply their email addresses when logging in. You’ll notice, however, that most popular websites do allow a user to log in by using their public username.

In this case, Twitter is prioritizing usability over security and has to rely on other approaches to secure accounts.

### Timing attacks

Generating a password hash via a hash function is a time-consuming process by design. If you generate hashes during the login process only when a user correctly supplies a username, there will be a slight (but measurable) difference in how fast the HTTP response is returned:[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)[](/book/grokking-web-application-security/chapter-8/)

```
def login(username, password, users)
 user = User.find_by_username username
 
 if user.nil?
   render json: { error: 'Invalid email or password.' },
          status: :unauthorized
 end
 
 stored_password = BCrypt::Password.new(user[:password_hash])

 if stored_password == password
   sign_in(:user, user)
   render json: { message: 'Welcome back!' },
          status: :found
 else
   render json: { error: 'Invalid email or password.' },
          status: :unauthorized
 end
end
```

Attackers can measure these differences to enumerate users as a type of *timing attack*. To allow for unreliable network speeds, they can retry the same set of credentials several times and average the response time.

To protect against timing attacks, you should hash the password supplied during login whether or not the supplied username matches an account in your web application:[](/book/grokking-web-application-security/chapter-8/)

```
def login(username, password, users)
 user = User.find_by_username username
 
 stored_password = user.nil? ?
   BCrypt::Password.create("") :
   BCrypt::Password.new(user[:password_hash])

 if stored_password == password and not user.nil?
   sign_in(:user, user)
   render json: { message: 'Welcome back!' },
          status: :found
 else
   render json: { error: 'Invalid email or password.' },
          status: :unauthorized
 end

end
```

This approach means the HTTP response will be generated in approximately the same amount of time regardless of whether an attacker has guessed a username correctly.

## Summary

-  Consider implementing SSO via OAuth or SAML so that your users can keep their credentials with a trusted third-party identity provider (and you can dispense with the security burden of storing credentials).
-  Nudge your users to choose complex passwords, emphasizing password length, to make it harder for an attacker to guess passwords.
-  Protect your login pages, sign-up pages, and password-reset pages from simple brute-force attacks by implementing a CAPTCHA.
-  Consider punishing incorrect password guesses by using rate limiting to bog down attackers who are launching brute-force attacks.
-  Implement MFA by using biometrics (most secure), authenticator apps (still good), or SMS messages (expensive and somewhat flawed).
-  Always store user passwords for inbound access in hashed form, using a strong function (such as SHA-2, SHA-3, or bcrypt), and apply a salt value and a pepper value.
-  Store passwords for outbound access with a strong, two-way encryption algorithm like AES-256. Store the encryption key used in a separate location from the encrypted values.
-  Ensure that your login, sign-up, and password-reset pages do not leak the existence of user accounts via error or acknowledgment messages.
-  During the login process, calculate the hash of the supplied password whether or not the user account exists to prevent timing attacks that allow user accounts to be enumerated.[](/book/grokking-web-application-security/chapter-8/)
