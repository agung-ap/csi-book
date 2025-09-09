# 11 Payload vulnerabilities

### In this chapter

- How accepting serialized data from an untrusted source is a security risk
- How XML parsers are vulnerable to attack
- How hackers can target file upload functions
- How path traversal vulnerabilities can allow access to sensitive files
- How mass assignment vulnerabilities can allow the manipulation of data

[](/book/grokking-web-application-security/chapter-11/)Most of the vulnerabilities discussed in the preceding chapters have been concerned with indirect attacks against your users. These attacks inject code into users’ browsers, trick users into performing unexpected actions, or steal credentials or sessions. Now we turn our attention to attacks that directly target web servers.

In the coming chapters, we will be particularly concerned with attacks that come across the HTTP protocol. Your web servers (and associated services) may well be vulnerable to other types of attacks—hackers often probe for access by using the Secure Shell (SSH) or Remote Desktop protocol, for example—but they are more properly considered to be the concerns of infrastructure security.[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)

##### TIP

If you want to learn more about that subject, I strongly recommend picking up a copy of *Hacking Exposed 7: Network Security Secrets and Solutions*, by Stuart McClure, Joel Scambray, and George Kurtz (McGraw Hill, 2012).

Even with that caveat, we still have a lot of ground to cover. Hackers have devised numerous ways to launch attacks that use maliciously crafted HTTP requests to cause unintended (and dangerous) effects on your web server. In this chapter, we will look at a variety of payloads that attackers can exploit, starting with a method of injecting malicious objects directly into the web server process itself.

## Deserialization attacks

[](/book/grokking-web-application-security/chapter-11/)*Serialization* is the process of taking an in-memory data structure and saving it to a binary (or text) format, usually so that it can be written to disk or passed across a network. *Deserialization* is the opposite process; it reinitializes the data structure from the binary/text format.[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)

If your web application accepts serialized data from an untrusted source, it may provide an easy way for an attacker to manipulate the web application’s behavior and possibly allow them to execute malicious code within the web server process.

Every mainstream programming language implements serialization in some fashion, and you will see it referred to by various names, such as *pickling* in Python and *marshaling* in Ruby. Programming languages also support serialization to text formats such as JSON, XML, and YAML. Finally, frameworks such as Google Protocol Buffers and Apache Avro allow serialized data structures to be passed between applications running in different programming languages—a useful feature for building distributed computing applications.[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)

Accepting serialized binary content from the browser is relatively rare, but certain types of web applications do implement this feature. If a web application allows the user to manipulate a complex server-side object such as a document editor, serializing the in-memory data structure representing the document is an easy way to save the state of the document. The application might allow the user to download the serialized document, save it locally, and reupload it at a later date to continue editing.

A couple of vulnerabilities can creep in when serialization is used this way. First, many serialization libraries allow serialized data to specify initialization functions that should be called when deserializing the object. If the following object is deserialized using the `pickle` library in Python, for example, the `__setstate__()` method will be invoked.[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)

##### WARNING

*Please don’t try running this code sample.* Your operating system will probably prevent it from executing, but it’s very risky.

```
class Malware(object):
 def __getstate__(self):
   return self.__dict__
 def __setstate__(self, value):
   import os
   os.system("rm -rf /")
   return self.__dict__
```

A web server that accepts this serialized object will execute the malicious code embedded in the `__setstate__()` function, which will attempt to delete every file on a Unix-based system, starting from the root directory.[](/book/grokking-web-application-security/chapter-11/)

If you choose to use serialization in your web application, you should use a format that is less prone to manipulation by an attacker. Here’s how you would deserialize an object from YAML (a text format) safely in Python:

```
import yaml

data = {
 "name"    : "Rammellzee",
 "address" : "Far Rockaway, Queens"
}

serialized_data   = yaml.dump(data)
deserialized_data = yaml.load(serialized_data,  
                             Loader=yaml.SafeLoader)
```

Notice that we are using the `yaml.SafeLoader` object to deserialize the data because the default behavior of the Python `yaml` library allows the creation of arbitrary objects. An attacker might use this object to execute malicious code, as in the preceding example.[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)

The second risk of using serialization in a web application is that an attacker is likely to tamper with serialized data sent to the browser and returned at a later date. The risk isn’t particularly great if the data received is under the user’s control by design, as in our document editor example, but the situation can be a problem if the data sent and received is at all sensitive.

To prevent data tampering, you can digitally sign any serialized data your application generates and sends to the user so you can detect when it has been tampered with. Here’s how to generate and check a Hash-Based Message Authentication Code (HMAC) signature when serializing and deserializing data in Python:[](/book/grokking-web-application-security/chapter-11/)

```
import hmac
import pickle
import hashlib

def save_state(document):
 data      = pickle.dumps(document)
 signature = hmac.new(
               secret_key, 
               data _data,   
               hashlib.sha256).digest()
 return data, signature

def load_state(data, signature):
 computed_signature = hmac.new(
                        secret_key, 
                        data, 
                        hashlib.sha256).digest()
 if not hmac.compare_digest(signature, computed_signature):
   raise ValueError("HMAC signature verification failed." +
                    "The data may have been tampered with.")

 return pickle.loads(data)
```

### JSON vulnerabilities

JavaScript running in the browser often communicates back to the server by using JSON requests. JSON is a serialization format, and if your web application is written in Node.js, you need to be sure that you are treating untrusted JSON input appropriately.[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)

Though JSON parsers exist for all mainstream programming languages, JSON is specifically a valid subset of the JavaScript language; anything written in JSON format can be executed by the JavaScript runtime in a Node.js server, which leads to a security vulnerability when running JavaScript on the server side. Consider the following Node.js code, which handles HTTP requests with the `application/json` content type:[](/book/grokking-web-application-security/chapter-11/)

```javascript
const express = require('express')
const app     = express()

app.post('/api/profile', (request, response) => {
  let data = ''

  request.on('data', chunk => {
    data += chunk.toString()
  })

  request.on('end', () => {
    const edits = eval(data)

    saveProfileChanges(edits)

    response.json({ 
      success: true, message: 'Profile updated.' 
    })
  })
})
```

This code uses the `eval()` function to perform dynamic execution, which we will look at in chapter 12. Essentially, it executes code stored in a string variable rather than using the more traditional method of running code stored as files on disk.[](/book/grokking-web-application-security/chapter-11/)

Although the HTTP handler illustrated here recovers valid JSON objects sent from the client, it also allows an attacker to send raw JavaScript code to be executed within the web server runtime—that is, to conduct a *remote code execution attack*. To safely evaluate JSON sent from the client, the request payload should be deserialized in Node.js with the `JSON.parse()` function:[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)

```
app.post('/api/profile', (request, response) => {
  let data = ''

  request.on('data', chunk => {
    data += chunk.toString()
  })

  request.on('end', () => {
    const edits = JSON.parse(data)

    saveProfileChanges(edits)

    response.json({ 
      success: true, message: 'Profile updated.' 
    })
  })
})
```

This handler rejects anything that is not a valid JSON request and prevents any chance of remote code execution.

##### WARNING

Never use `eval()` on untrusted content if you are writing a Node.js application.[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)

### Prototype pollution

Even with proper deserialization of JSON in a Node.js application, you need to be aware of another risk. The JavaScript language, somewhat unusually, uses *prototype-based inheritance* rather than the class-based inheritance you see in languages like Java and Python. Languages that use prototypes for inheritance require applications to generate new objects by copying existing objects, adding new fields and methods as the copying occurs. Beyond their prototype, JavaScript objects are big bags of fields and methods, which can be modified in code at any time.[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)

This fluidity of design makes it easy to merge two JavaScript objects; you just munge the two objects together and decide what to do when a collision between field names occurs. You often see Node.js code like the following snippet, which updates an existing data object (in this case, a user profile) with some state changes that need to be applied:

```
function saveProfileChanges(edits) {
 let user = db.user.load(currentUserId())

 merge(edits, user)

 db.user.save(user)
}

function merge(target, source) {
 Object.entries(source).forEach(([key, value]) => {
   if (value instanceof Object) {
     if (!target[key]) {
       target[key] = {};
     }
     merge(target[key], value)
   } else {
     target[key] = value
   }
 })
}
```

[](/book/grokking-web-application-security/chapter-11/)If the state changes that you are merging come from an untrusted source, however, an attacker can exploit the merging algorithm. As part of the implementation of prototype-based inheritance, every JavaScript object has a `__proto__` property, which points back to the prototype object from which it was cloned.[](/book/grokking-web-application-security/chapter-11/)

Prototype-based inheritance makes it simple for an attacker who can inject code to modify all objects in memory by crawling up the prototype chain. This type of attack is called *prototype pollution*.[](/book/grokking-web-application-security/chapter-11/)

In this example, the `toString()` method has been replaced by the following function, which tries to delete files from your server recursively when called:[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)

```javascript
const brainWorm = () => {
 require('fs').rm('/', { recursive: true })
}
```

The example is somewhat artificial because if an attacker can execute code to pollute prototypes, they can perform the wipe command directly. But the careless parsing and merging of a JSON object allow for a subtler attack, as shown in the following snippet :

```json
{
 name: "sneaky_pete"
 __proto__: {
   access_code: "brainworms"
 }
}
```

If this JSON is passed to the `merge()` function illustrated earlier, whatever object is before the `User` object in the prototype chain acquires the new field `access_code` with value `"brainworms"`. In this way, an attacker can experiment until they find a field or value that allows them to manipulate the web application in dangerous ways.[](/book/grokking-web-application-security/chapter-11/)

To prevent an attack of `brainworms`, a Node.js web application should merge only in fields that are explicitly expected to appear, either by using an allow list or picking out the fields by name:

```
function saveProfileChanges(edits) {
 let user = db.user.load(currentUserId())

 user.name    = edits.name
 user.address = edits.address
 user.phone   = edits.name

 db.user.save(user)
}
```

Prototype pollution attacks occur in the browser, too, typically as part of a cross-site scripting attack. The mitigations outlined in chapter 6 help prevent this type of attack.

## XML vulnerabilities

[](/book/grokking-web-application-security/chapter-11/)While we are discussing serialization formats that attackers are likely to abuse, *Extensible Markup Language* (XML) deserves its own section. Serialization is only one of many uses for XML. At various points in its history, XML has been used to write configuration files, implement remote procedure calls, perform data labeling, and define build scripts, among many other things.[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)

Nowadays, XML has been replaced in many contexts and has receded in popularity somewhat. JSON has proved to be a more succinct way of passing information between a browser and a server; YAML tends to be more readable for configuration files. Further, formats such as Google Protocol Buffers are more efficient for cross-application communication.

Nevertheless, nearly every web server running today can parse and process XML, and because of some questionable security decisions made by the XML community in the past, XML parsers are popular targets for hackers. Let’s dig into how these vulnerabilities work.

### XML validation

XML was a revolutionary data format when it was introduced because it allowed programmers to check data files for correctness before processing. This period was the dawn of the web, when the need to interchange data in standard and verifiable ways was suddenly of utmost importance; all the world’s computers were talking to one another and had to be sure that they were speaking the same language.[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)

The first popular way to validate XML files was to create a *Document Type Definition* (DTD) file, describing the expected names, types, and ordering of tags within the XML document. The XML document[](/book/grokking-web-application-security/chapter-11/)

```
<?xml version="1.0"?>
<people>
 <person>
   <name>Fred Flintstone</name>
   <age>44</age>
 </person>
 <person>
   <name>Barney Rubble</name>
   <age>45</age>
 </person>
</root>
```

could be described with the following DTD:

```
<!ELEMENT people (person*)   >
<!ELEMENT person (name, age) >
<!ELEMENT name   (#PCDATA)   >
<!ELEMENT age    (#PCDATA)   >
```

[](/book/grokking-web-application-security/chapter-11/)By publishing a DTD, an application could easily specify what format of XML it was able to accept and programmatically verify that any input was valid. (If the format looks familiar, that’s because it is designed to look like *Backus-Naur form*, often used to describe the grammar of a programming language.)[](/book/grokking-web-application-security/chapter-11/)

DTD is now a deprecated technology, having been replaced by *XML schemas* that perform the same function in a more verbose but more flexible manner. Most XML parsers still support DTDs for legacy reasons, however. (Also, if we are being honest about the state of the technology, most of the web is running on legacy software.)

One of the questionable security decisions that we hinted at earlier is that parsers allow XML documents to supply *inline schemas*—DTDs embedded within the document itself. This situation has contributed to a couple of major security vulnerabilities that plague the web to this day.[](/book/grokking-web-application-security/chapter-11/)

### XML bombs

DTDs have a rarely used feature that allows them to specify *entity definitions*—string substitution macros to be applied in the XML document before parsing. These macros are seldom used by developers but often used by attackers, as we will see.[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)

[](/book/grokking-web-application-security/chapter-11/)As an illustration, the following DTD specifies that the entity `company` should be expanded to `Rock and Gravel Company` in the XML document before it is parsed:

```
<?xml version="1.0"?>
<!DOCTYPE employees [
  <!ELEMENT employees (employee)*>
  <!ELEMENT employee (#PCDATA)>
  <!ENTITY  company "Rock and Gravel Company">
]>
<employees>
  <employee>
    Fred Flintstone, &company;
  </employee>
  <employee>
    Barney Rubble, &company;
  </employee>
</employees>
```

In other words, the final XML document will look like this when it is parsed:

```
<?xml version="1.0"?>
<employees>
  <employee>
    Fred Flintstone, Rock and Gravel Company
  </employee>
  <employee>
    Barney Rubble, Rock and Gravel Company
  </employee>
</employees>
```

Note how this DTD has been inlined in the XML document. By design, inline DTDs are under the control of whoever submits the XML document, which gives an attacker an easy way to exhaust memory on the server. Because the substitution macros described by entity definitions can be piled on top of one another, an attacker can launch an *XML bomb attack* against a vulnerable XML parser by submitting a file with the following inline DTD:[](/book/grokking-web-application-security/chapter-11/)

```
<?xml version="1.0"?>
<!DOCTYPE lolz [
 <!ENTITY lol "lol">
 <!ENTITY lol2 "&lol;&lol;&lol;&lol;&lol;">
 <!ENTITY lol3 "&lol2;&lol2;&lol2;&lol2;&lol2;">
 <!ENTITY lol4 "&lol3;&lol3;&lol3;&lol3;&lol3;">
 <!ENTITY lol5 "&lol4;&lol4;&lol4;&lol4;&lol4;">
 <!ENTITY lol6 "&lol5;&lol5;&lol5;&lol5;&lol5;">
 <!ENTITY lol7 "&lol6;&lol6;&lol6;&lol6;&lol6;">
 <!ENTITY lol8 "&lol7;&lol7;&lol7;&lol7;&lol7;">
 <!ENTITY lol9 "&lol8;&lol8;&lol8;&lol8;&lol8;">
]>
<lolz>&lol9;</lolz>
```

[](/book/grokking-web-application-security/chapter-11/)If this inline DTD is processed by an XML parser, the value `&lol9;` in the final line will be replaced by five instances of `&lol8;`, after which each `&lol8;` will be replaced by five occurrences of `&lol7;`—and so on until the full expanded XML document takes up several gigabytes of memory.

This attack is known as the *billion-laughs attack*, a type of XML bomb that explodes the memory of the server with a single HTTP request. An attacker can use this method to perform a denial-of-service (DoS) attack on any web server that accepts XML files with inline DTDs.[](/book/grokking-web-application-security/chapter-11/)

### XML external entity attacks

In a second malicious use of inline DTDs, entities declared within a DTD can refer to external files, effectively acting as a request to insert the external file inline where the entity is declared. The XML specification requires the XML parser to consult the networking protocol of the URL declared in the external entity. If you think that this arrangement sounds like a recipe for disaster, you’re correct. Attackers can abuse these *external entity definitions* in a couple of ways.[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)

First, an attacker can launch malicious network requests by including a URL within an inline DTD—a type of *server-side request forgery* (SSRF), which we will learn about in chapter 14. This type of attack can probe your internal network or launch indirect attacks on other targets.

Second, an attacker may be able to reference sensitive files on the web server itself. If the external entity definition includes a URL with the prefix `file://`, that file will be inserted into the XML document before parsing. The parsing of the XML file is likely to fail because the expanded XML is invalid. But if the error message describes the expanded XML file, that attacker will be able to read the contents of the sensitive file. A request containing the XML file

```
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE sneaky [
 <!ENTITY passwords SYSTEM "file://etc/shadow">
]>
<sneaky>
 &passwords;
</sneaky>
```

might respond with an error message.

This technique allows the attacker to read sensitive files on the server—in this case, the list of user accounts in the operating system.

### Mitigating XML attacks

DTD is legacy technology, and inline DTDs are a security nightmare for the reasons I’ve outlined. Fortunately, most modern XML parsers disable DTDs by default, but this security lapse still occurs surprisingly often in legacy technology stacks.[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)

The recommendations in the following cheat sheet ensure that inline DTDs are disabled in some common programming languages. If your application processes XML in any form, make sure to follow these recommendations.

Language

Recommendation

Python[](/book/grokking-web-application-security/chapter-11/)

Use the `defusedxml` module for XML parsing in place of the standard `xml` module.

Ruby

If you use the Nokogiri parsing library, set the `noent` configuration flag to `true``.```

Node.js

Few XML-parsing packages in Node.js implement DTD parsing, but if you use the `libxmljs` package (which is a binding to the underlying C library `libxml2`), be sure that the `{noent: true}` option is set when parsing XML.[](/book/grokking-web-application-security/chapter-11/)

Java

Disallow inline `doctype` definitions as follows:

```
DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
String FEATURE = "https://apache.org/xml/features/disallow-doctype-decl";
dbf.setFeature(FEATURE, true);
```

.NET

For .NET 3.5 and earlier, disable DTDs in the `reader` object:

```
XmlTextReader reader = new XmlTextReader(stream);
reader.ProhibitDtd = true;
```

In .NET 4.0 and later, prohibit DTDs in the `settings` object:

```
XmlReaderSettings settings = new XmlReaderSettings();
settings.ProhibitDtd = true;
XmlReader reader = XmlReader.Create(stream, settings);
```

PHP

Use `libxml` version 2.9.0 or later or disable entity expansion explicitly by calling `libxml_disable_entity_loader(true)`.

##### TIP

For more comprehensive documentation on how to harden XML parsers, the *Open Worldwide Application Security Project* (OWASP) has a good cheat sheet at [http://mng.bz/lVgy](http://mng.bz/lVgy).[](/book/grokking-web-application-security/chapter-11/)

## File upload vulnerabilities

[](/book/grokking-web-application-security/chapter-11/)File upload functions in a web application are favorite targets for hackers because they require a web application to write a large chunk of data to disk in some fashion. Attackers love this requirement because it gives them a way to plant malicious software on the server or overwrite existing files in the target system.[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)

Your web application might accept file uploads for many reasons, depending on what functions it performs. Social media and messaging apps accept images and video for sharing, for example; uploading Microsoft Excel or CSV files is a common way of bulk-importing data; and many applications (such as Dropbox) are based on the sharing of files. If you find yourself writing or maintaining a web application that accepts file uploads, you should implement several protections.

### Validate uploaded files

When a user uploads a file to your application, you should validate the filename, size, and type. JavaScript running in the browser can perform these validations:[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)

```
function validateFile() {
  const file = document.getElementById('fileInput').files[0]
  const validationPattern = /^[a-zA-Z0-9-]+\.([a-zA-Z0-9]+)$/
  if (!validationPattern .test(file.name)) {
    alert('File name must be alphanumeric.')
    return false
  }
  
  const allowedFileTypes = ['image/jpeg', 'image/png']
  if (!allowedFileTypes.includes(file.type)) {
    alert('Only JPEG and PNG files are allowed.')
    return false
  }
  
  const maxSizeInBytes = 10 * 1024 * 1024 
  if (file.size > maxSizeInBytes) {
    alert('File must be smaller than 10MB.')
    return false
  }
  
  return true
}
```

An attacker can simply disable these checks, of course, so making corresponding server-side checks should be mandatory. Make sure that your server-side code validates the following properties of any uploaded file:[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)

-  *Maximum file size*—Uploading very large files is a simple way for an attacker to perform a DoS attack, so have your code abandon the upload process if the file is too large. Be careful of archive formats, too. *Zip bombs* are `.zip` archive files that keep growing when they’re unzipped, filling all the available disk space if you let them. Ensure that any unzipping algorithms you use have a way of exiting should the opened file grow too large during the unarchiving stage.[](/book/grokking-web-application-security/chapter-11/)
-  *Constraints on filenames and sizes*—Ensure that filenames are less than a maximum length, and limit what characters can appear in them. Also make sure that filenames don’t contain path characters. If you accept filenames with a relative path like `../`, an attacker may be able to overwrite sensitive files on the server and gain control of your system.
-  *Enforced file types*—Make sure that the file extensions match the expected file type, and validate the file type headers during uploading. Here, we ensure an uploaded file is using a valid PNG by using the `magic` library:[](/book/grokking-web-application-security/chapter-11/)

```
import magic

file_type = magic.from_file("upload.png", mime=True)

assert file_type == "image/png"
```

Be aware, however, that attackers can craft files that are valid in multiple formats. Security researchers have been able to craft files that are both valid *Graphics Interchange Format* (GIF) files and *Java Archive Format* (JAR) files, which can be used to attack Java applications that accept image uploads.[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)

### Rename uploaded files

[](/book/grokking-web-application-security/chapter-11/)Generally speaking, it’s safer to rename files as they are uploaded. This approach prevents an attacker from overwriting sensitive files if they find a way to encode path parameters in filenames. To illustrate this vulnerability, the `upload` function in the following Node.js snippet allows an attacker to give a filename relative path syntax like `../../assets/js/login.js`, which may allow them to overwrite JavaScript files hosted on the web server:[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)

```javascript
app.post('/upload', upload.single('file'), (req, res) => {
 const { name, buffer } = req.file;
 const filePath = path.join(__dirname, 'uploads', name)

 require('fs').writeFile(filePath, buffer, (err) => {
   res.status(200).send('File uploaded successfully.')
 })
})
```

Sometimes, it’s best to disregard the name of an uploaded file. If user `sephiroth420` uploads a profile picture, for example, it makes sense to rename the uploaded file `/profile/sephiroth420.png` and ignore the filename supplied in the HTTP request.

If retaining the filename is important (in a photo-sharing app, for example), you should use *indirection*, which means saving the file to disk under an arbitrary filename and recording the real name in a database or search index. This approach allows you to look up and search on filenames without giving attackers an opportunity to overwrite sensitive files.[](/book/grokking-web-application-security/chapter-11/)

### Write to disk without the appropriate permissions

A common aim for an attacker is to upload a web shell to your server. A *web shell* is an executable script that can be invoked via HTTP; it will run a command line on the server’s operating calls at the hacker’s behest. Web shells are deployed by uploading a script file and then finding a way to execute the script in some sort of runtime.[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)

The following PHP script is a web shell that accepts HTTP requests and executes any commands passed in the `cmd` parameter:

```
<?php
 if(isset($_REQUEST['cmd'])) {
   $cmd = ($_REQUEST['cmd']);
   system($cmd);
 } else {
   echo "What is your bidding?";
 }
?>
```

If an attacker can upload this script to a PHP application and trick the application into writing it to the appropriate directory, they have a method of running commands on the server by passing them over HTTP.

Enforcing file types and using indirection provide some protection against this type of attack, but the most important consideration is that you should never write uploaded files to disk with executable permissions. The following code is dangerous because it sets the executable permission to `true` on an uploaded file in UNIX:

```
@app.route('/upload', methods=['POST'])
def upload_file():
  file = request.files['file']
  
  file_path = os.path.join(
                app.config['UPLOAD_FOLDER'], file.filename)
  file.save(filepath)
  os.chmod(file_path, 0o755)         #1

  return jsonify({'message': 'Upload successful'}), 200
#1 This “change mode” command allows all operating system accounts to read and execute the file.
```

Instead, any code you write should save uploaded files to disk with only read-write permissions:

```
@app.route('/upload', methods=['POST'])
def upload_file():
  file = request.files['file']
  
  file_path = os.path.join(
                app.config['UPLOAD_FOLDER'], file.filename)
  file.save(filepath)
  os.chmod(file_path, 0o644)           #1

  return jsonify({'message': 'Upload successful'}), 200
#1 This “change mode” command allows all operating system account users to read the file but gives none of them execute permissions.
```

Additionally, it’s a good idea to restrict the permissions of the web server process itself. Allow it to access only the directories that it needs to access; do not allow it to run executable files in any directory to which an attacker might upload files.

### Use secure file storage

[](/book/grokking-web-application-security/chapter-11/)If you are running your application in the cloud, most of the considerations I’ve described are better handled by a third party. Storing uploaded files in Amazon’s Simple Storage Service (S3) is cheap and easy, and a big cloud provider like Amazon will assume a lot of the risk of the file storage:[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)

```
@app.route('/upload', methods=['POST'])
def upload_file_to_s3():
 file = request.files['file']
 
 tmp_path = os.path.join(
              app.config['TMP_UPLOAD_FOLDER'], 
              str(uuid.uuid4()))
 file.save(tmp_path)

 s3_client = boto3.client('s3', 
               aws_access_key_id.    = AWS_ACCESS_KEY_ID, 
               aws_secret_access_key = AWS_SECRET_ACCESS_KEY)
 try:
   s3_client.upload_file(tmp_path, 
                         S3_BUCKET_NAME, 
                         file.filename)
 except Exception:
   return jsonify({'message': 'Error uploading file.'}), 500
 finally:
   os.remove(tmp_path)

 return jsonify({'message': 'Upload successful.'}), 200
```

## Path traversal

I mentioned in the preceding section that an attacker might specify path characters in an uploaded filename in an attempt to overwrite sensitive files. The converse is also true: if an attacker can supply path characters in a filename referenced in an HTTP request, they may be able to read sensitive files. This vulnerability is called a *path traversal* (or *directory traversal*).[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)

A typical path traversal vulnerability occurs as follows. Suppose that you run a website that hosts menus in PDF format. (For various reasons, restaurants love to store the most important information—what you can eat there—in the least accessible format for a browser to read.) Further suppose that the filename of each menu is referenced directly in the URL.

In this case, an attacker may try to reference a forbidden file by manipulating the URL parameter.

[](/book/grokking-web-application-security/chapter-11/)The best protection is to avoid making direct file references. In this example, it would be better to have each company name stored in a database alongside the path to the corresponding menu PDF file. Failing that, ensure that your files have a restricted set of permitted characters, and reject any filenames that use any characters outside that set:

```
@app.route('/menu', methods=['GET'])
def get_file():
  filename = request.args.get('filename')
  
  if not filename:
    return jsonify({'message': 'File name not provided'}), 400
 
  validation_pattern = r'^[a-zA-Z0-9_-]+$'
  
  if not re.match(validation_pattern, filename):
    return jsonify({'message': 'Invalid file name.'}), 400

  path = os.path.join(app.config['MENU_FOLDER'], filename)
  if not os.path.exists(path):
    return abort(404)

  return send_file(path, as_attachment=True)
```

## Mass assignment

We should discuss one final vulnerability while we are on the topic of malicious payloads. Many web frameworks automate the process of assigning parameters from an incoming HTTP request to the fields of an in-memory object. You need to use this type of assignment logic carefully so that only permitted fields are written to. Otherwise, an attacker can perform a *mass assignment* attack, overwriting sensitive data fields (such as permissions and roles) that they should not be able to change.[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)

[](/book/grokking-web-application-security/chapter-11/)In Java, for example, the assignment of state is often achieved by using *data binding*. Observe in the following code snippet how the JSON request body is automatically bound to a `User` object in the popular Play Framework ([https://www.playframework.com](https://www.playframework.com)): [](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)

```
public class UserController extends Controller {
 public Result updateProfile() {
   User user = Json.fromJson(
     request().body().asJson(), User.class);

   getDatabase().updateProfile(user);
   return ok("User updated successfully");
 }
}
```

Under the hood, Play uses the Jackson library ([https://github.com/FasterXML/jackson](https://github.com/FasterXML/jackson)) to deserialize JSON into Java objects. As written, this code is vulnerable to a mass assignment attack because the properties to be assigned in the `User` object are not specifically enumerated in the code. An attacker can simply modify the names of the form fields (or add extras) and manipulate their profile directly in the database, setting administrative flags as they see fit. If the `User` class has an `isAdmin` field, an attacker can simply pass this extra request parameter to become an admin.[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)

[](/book/grokking-web-application-security/chapter-11/)When you are taking data from an HTTP request, the properties of the data object being updated should be explicitly stated in your server-side code. One way is to manually unpack the fields you need from the JSON request:

```
public class UserController extends Controller {
  public Result updateProfile() {
    User     user = new User();
    JsonNode json = request.body().asJson();

    user.setName(json.get("name").asText());            #1
    user.setAddress(json.get("address").asText());

    getDatabase().updateProfile(user);

    return ok("User updated successfully");
  }
}
```

## Summary

-  Be careful about accepting serialized content from an untrusted source. Prefer text serialization formats such as JSON and YAML if possible, or use digital signatures to prevent data tampering.
-  In Node.js, parse JSON by using the `JSON.parse()` function rather than the `eval()` function. Ensure that the prototypes of JavaScript objects you use cannot be manipulated by attackers.[](/book/grokking-web-application-security/chapter-11/)[](/book/grokking-web-application-security/chapter-11/)
-  Disable processing of inline DTDs in any XML parser you use.
-  Validate filenames, file sizes, and file types on uploads. Prefer to use indirection when writing files to disk, and use cloud storage where feasible. Assume that uploaded files are harmful until proven otherwise.
-  Rename files on upload if you don’t need to keep the filename. This approach prevents a lot of potential security problems.
-  Write files to disk with the minimal set of permissions—certainly without executable permissions. Ensure that your web server process doesn’t have permission to execute any files in directories to which an attacker can upload files.
-  Avoid making direct file references to files that the user can download; use indirection wherever possible. If you must use filenames in the web application, limit them to a restricted character set (and don’t allow path characters).
-  Be careful when using libraries that assign state to data objects from parameters in the HTTP request, in case they allow an attacker to overwrite fields that they shouldn’t be able to control. Specify an allow list of fields that can be edited rather than leave the list ad hoc.[](/book/grokking-web-application-security/chapter-11/)
