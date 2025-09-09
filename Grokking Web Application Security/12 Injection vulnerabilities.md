# 12 Injection vulnerabilities

### In this chapter

- How attackers inject code into web applications
- How attackers inject commands into databases
- How attackers inject operating system commands
- How attackers inject the line-feed character maliciously
- How attackers inject malicious regular expressions

[](/book/grokking-web-application-security/chapter-12/)Ransomware has been the scourge of the internet in recent years. Ransomware operators work on a franchise model: they lend their malicious software to affiliates, and then those affiliates—hackers themselves—scour the web for vulnerable servers (or buy the addresses of already compromised servers from the dark web) to which they can deploy ransomware. The victims wake up the next day to find that the contents of their servers have been encrypted and that they must pay a cryptocurrency fee to regain control of their systems. When the fee is paid, the bounty is split between the hacker group and the ransomware vendor, and the dark web economy prospers. (Everyone else suffers.)

To deploy ransomware, an attacker needs to find a way to run malicious code on someone else’s server. Tricking a victim’s server into running malicious code is a type of *injection attack*. The malicious code is injected into the remote server, and bad things result.[](/book/grokking-web-application-security/chapter-12/)

Injection attacks take many forms and can have many consequences besides the installation of ransomware. Injection attacks against a data store allow attackers to bypass authentication and steal data. Even the injection of a single line-feed character into a vulnerable web server can cause chaos, as we will see.

In this chapter, we will look at a whole range of injection vulnerabilities and learn how to prevent them. Because we are web developers, we will begin by looking at injection attacks against the web server itself and then review analogous attacks against downstream systems and the underlying operating system.

## Remote code execution

[](/book/grokking-web-application-security/chapter-12/)Web servers execute code saved in text files. Many programming languages have an intermediate compilation step that transforms the code into runnable form, either binary or bytecode. But programming in essence is the typing (or cutting and pasting, thanks to Stack Overflow and ChatGPT) of text files with custom file extensions, which are passed to the programming language’s runtime for execution.[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)

Running code stored in files is the norm, but many programming languages also support a method of executing code stored in a variable in memory, which is called *dynamic evaluation*. Probably the most notorious example is the `eval()` function in JavaScript. A string passed to the function will be evaluated as code.[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)

In this example, the code being dynamically evaluated is initialized as a literal string, but it could well be passed in as input from an HTTP request. We saw in chapter 11 that passing untrusted input to `eval()` on a Node.js web application allows an attacker to run malicious code on the web server. This type of attack is called *remote code execution* (RCE) and is a liability in any programming language that supports dynamic execution (which is to say basically all of them).[](/book/grokking-web-application-security/chapter-12/)

Your web application should never execute untrusted input coming from the HTTP request as code. The following function allows an attacker to run arbitrary code in your web server’s runtime and then explore the contents of your filesystems or even perform a full system takeover:

```javascript
const express = require('express')
const app     = express()

app.use(express.json())

app.post('/execute-command', (req, res) => {
 const result = eval(command)
 res.json({ result })
})
```

This example is rather artificial; it deliberately rolls out a red carpet for an attacker and should (I hope) raise red flags in code reviews very early. Real-life examples of RCE vulnerabilities usually occur in subtler ways. Let’s look at a couple of scenarios.

### Domain-specific languages

A *domain-specific language* (DSL) is a programming language designed to solve specific tasks in a particular domain. Rather than being general-purpose languages, DSLs have a tailored syntax that allows users to construct simple expression strings to express complex ideas—ideas that would be unwieldy to express in a more traditional user interface. The Google search operators that allow you to tailor your search criteria are a type of DSL, as are the formulas you might use in an online spreadsheet.[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)

If you build a DSL into your web application, you usually end up implementing a method of evaluating those expressions on the server. Note that DSLs in web applications are typically restricted to single lines of code, called *expressions*. Anything more complicated means that users will start asking for the type of tools we developers take for granted: syntax highlighting, code autocomplete, and a debugger. These tools are much more time consuming to implement than you might imagine.

The easiest way to evaluate DSL expressions on a web server is to use dynamic evaluation in whichever server-side language you are programming with. This approach, as you might have guessed, is generally wrong. Unless you have a very strong grasp of how to sandbox the DSL expressions properly, this type of code almost always allows RCE vulnerabilities to creep in. Instead, let’s look at a couple of ways to build DSLs into a web application securely, preventing such vulnerabilities from occurring.

The first approach is to use a scripting language specifically designed to be embedded in other applications. Lua is one such language, often used in video game design, allowing designers to describe the behavior of in-game objects (such as nonplayer characters and enemies) without having to learn C++. Lua can also be embedded in most mainstream programming languages, so it is a qualified candidate for writing DSLs in your web application. Here’s how to embed Lua in a Python application:[](/book/grokking-web-application-security/chapter-12/)

```
import lupa

lua        = lupa.LuaRuntime(
               unpack_returned_tuples=True) #1
expression = "2 + 3"                        #2
result     = lua.execute(expression)        #3
```

Using an embedded language gives you full control of what context is passed when the DSL expression is evaluated. In this example, you can control what (if any) Python objects are made available to the Lua runtime by passing them explicitly during evaluation:

```javascript
from lupa import LuaRuntime

lua         = LuaRuntime(unpack_returned_tuples=True)
add_numbers = lua.eval(
               "function(arg1, arg2) return arg1+ arg2 end")
result      = add_numbers(2, 3)
```

The second way to implementing a DSL safely is to parse and evaluate each expression in code by formally defining the syntax of the DSL and breaking each expression into a series of tokens via lexical analysis. This process can be intimidating. If you have ever studied compilers as part of a computer science program, you know that this field is a complex one that’s full of technical jargon (grammars, LL parsers, context-free languages, and so on).

Many modern programming languages, however, come with toolkits that greatly simplify the problem of building DSLs in this fashion. The Python language provides the `ast` module, which the Python runtime uses itself but which can be repurposed to build DSLs safely. Here’s how we can build a tool for evaluating small mathematical statements in relatively few lines of code:[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)

```
import ast, operator

def eval(expression):
  binary_ops = {
    ast.Add:   operator.add,
    ast.Sub:   operator.sub,
    ast.Mult:  operator.mul,
    ast.Div:   operator.truediv,
    ast.BinOp: ast.BinOp,
  }

  unary_ops = {
    ast.USub:    operator.neg,
    ast.UAdd:    operator.pos,
    ast.UnaryOp: ast.UnaryOp,
  }

  ops = tuple(binary_ops) + tuple(unary_ops)

  syntax_tree = ast.parse(expression, mode='eval')

  def _eval(node):
    if isinstance(node, ast.Expression):
      return _eval(node.body)
    elif isinstance(node, ast.Str):
      return node.s
    elif isinstance(node, ast.Num):
      return node.value
    elif isinstance(node, ast.Constant):
      return node.value
    elif isinstance(node, ast.BinOp):
      if isinstance(node.left,  ops):
        left  = _eval(node.left)   
      else:
        left  = node.left.value
      if isinstance(node.right, ops):
        right = _eval(node.right)  
      else: 
        right = node.right.value

      return binary_ops[type(node.op)](left, right)
    elif isinstance(node, ast.UnaryOp):
      if isinstance(node.operand, ops):
        operand = _eval(node.operand)  
      else:
        operand = node.operand.value

      return unary_ops[type(node.op)](operand)

  return _eval(syntax_tree)

eval("1 + 1")        #1
eval("(100*10)+6")   #2
```

In this code snippet, we explicitly define which operations (add, subtract, multiply, and divide) the DSL can evaluate, which prevents the arbitrary execution of code.

##### TIP

To learn more about this approach, I recommend picking up a copy of *DSLs in Action*, by Debasish Ghosh ([https://www.manning.com/books/dsls-in-action](https://www.manning.com/books/dsls-in-action)), and paying particular attention to the chapters that discuss parser-combinators. Using this technique, you can build and expand a DSL in complete safety, defining the language syntax however you see fit.[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)

### Server-side includes

A second circumstance in which RCE vulnerabilities often occur in web applications is typical of older web applications. HTML evaluated in the browser often incorporates remote elements (such as images and script files) simply by referencing the URL of those elements in the `src` attribute. Some server-side languages have a counterpart process called *server-side includes*, which looks like this:[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)

```
<head>
  <title>Server-Side Includes</title>
</head>
<body>
  <?php include 'https://example.com/header.php'; ?>
  <div>
    <p>This is the main content of the page.</p>
  </div>
</body>
```

Here, the PHP template uses the `include` command to load code from a remote server at `https://example.com/header.php` and execute it inline. The `include` command is usually used to incorporate files stored on the local disk, but it also supports remote protocols. If the URL of the include is taken from the HTTP request itself, however, an attacker has a simple way to include malicious code in the template at run time, leading to an RCE vulnerability.[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)

Server-side includes from a URL are questionably secure at best, so it’s better to avoid them if possible. In PHP, you can disable them by calling the function `allow_url_include(false)` in your initialization code; then you’ll have one less thing to worry about.[](/book/grokking-web-application-security/chapter-12/)

## SQL injection

In the case of many applications, gaining access to the contents of the underlying database is more desirable to an attacker than accessing the application itself. Stolen personal information or credentials can be resold for profit or used to hack accounts on other websites; many databases also store valuable financial data and trade secrets. As a result, injection attacks against databases remain some of the most prevalent types of attacks on the internet.[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)

Web applications commonly use SQLdatabases such as MySQL and PostgreSQL. SQL describes both the way data is stored in the database and the language in which applications issue commands to the database. SQL databases store information in tables, which have columns of specific types. Each data item appears in a row in a given table.

Web applications communicate with a SQL database via a *database driver* that allows data to be inserted, read, updated, or deleted in the database by issuing the appropriate SQL command string. (Read commands are usually called *queries*—hence, the acronym for *Structured Query Language*.) Observe how this simple web service manipulates data in the `books` table of a SQL database by sending commands to the database driver stored in the `db` variable:[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)

```
@app.route('/books', methods=['POST'])
def create_book():
  data = request.json
  db.execute('INSERT INTO books (isbn, title, author) '\
             'VALUES (%s,%s,%s)',
             (data['isbn'], data['title'], data['author']))
  return jsonify({'message': 'Creation successful!'}), 201

@app.route('/books', methods=['GET'])
def get_books():
  books = db.execute('SELECT * FROM books').fetchall()
  
  return jsonify(books)

@app.route('/books/<string:isbn>', methods=['GET'])
def get_book(isbn):
  book = db.execute('SELECT * FROM books WHERE isbn=%s', 
                    (isbn,)).fetchone()
  
  return jsonify(book)

@app.route('/books/<string:isbn>', methods=['PUT'])
def update_book(isbn):
  data = request.json
  
  db.execute('UPDATE books '\
             'SET title=%s, author=%s WHERE isbn=%s',
             (data['title'], data['author'], data['isbn']))

  return jsonify({'message': Update successful'}), 200

@app.route('/books/<string:isbn>', methods=['DELETE'])
def delete_book(isbn):
  db.execute('DELETE FROM books WHERE isbn=%s', (isbn,))

  return jsonify({'message': 'Deletion successful'}, 200
```

[](/book/grokking-web-application-security/chapter-12/)The SQL commands in this example are in boldface. The input parameters passed to each SQL command are demarcated in the command string by the `%s` placeholder and then passed to the database driver separately. This parameterization is done for security reasons. The command strings could instead be constructed via concatenation or interpolation, but these techniques represent a security hazard, as we will see.

SQL injection attacks take advantage of the unsafe construction of SQL command strings via concatenation or interpolation. The following application code constructs SQL commands insecurely, in this case while attempting to authenticate a user:

```
@app.route('/login', methods=['POST'])
def login():
  username = request.json['username']
  password = request.json['password']
  hash     = bcrypt.hashpw(password, PEPPER)

  sql  = "SELECT * FROM users WHERE username = '" + username + 
         "' and password_hash = '" + hash + '"' #1
  user = cursor.execute(sql).fetchone()

  if user:
    session['user'] = user
    return jsonify({'message': 'Login successful'}), 200
  else:
    return jsonify({'error': 'Invalid credentials'}), 401
#1 This SQL command is constructed using string concatenation.
```

The code sample is vulnerable to a SQL injection attack. (It also exhibits another flaw: the password hash is not generated with a salt value. See chapter 8 for further discussion of this topic.) To take advantage of this security flaw, an attacker can supply a username containing the control character (`'`) followed by a SQL comment string (`--`), bypassing the password check.

[](/book/grokking-web-application-security/chapter-12/)The database driver ignores everything after the comment character (`--`), so the password is never checked, and the attacker can log in without having to supply a correct password.

SQL injection attacks can also steal or modify data by adding extra clauses to a query or chaining commands. The following code illustrates how an attacker can insert additional SQL statements into a database call and delete tables via the `DROP` command.[](/book/grokking-web-application-security/chapter-12/)

### Parameterized statements

To protect against SQL injection attacks, your application should use *parameterized statements* when communicating with a database. We encountered parameterized statements in the Python web service code earlier in the chapter: the `%s` represent placeholders to be filled by the parameters. You can make the insecure `login()` function secure against SQL injection attacks by using parameterized statements in the following way:[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)

```
@app.route('/login', methods=['POST'])
def login():
  data = request.json

  username = data['username']
  password = data['password']
  hash     = bcrypt.hashpw(password, SALT)

  sql  = "SELECT * FROM users " \
         "WHERE username      = %s and" \ 
         "      password_hash = %s'             #1
  user = cursor.execute(sql, (username, hash))
           .fetchone()                          #2

  if user:
    session['user'] = user
    return jsonify({'message': 'Login successful'}), 200
  else:
    return jsonify({'error': 'Invalid credentials'}), 401
#1 The parameterized SQL statement is constructed.
#2 The input parameters are supplied to the database driver separately.
```

By supplying the SQL command and parameter values to the database driver separately, the driver ensures that the parameters are inserted into the SQL command safely and that an attacker cannot change the intent of the command. If an attacker supplies the malicious parameter value of `sam'--` to the authentication function, the attack will result in an underwhelming error condition.

Parameterized statements are available for every mainstream programming language and database driver, though the syntax varies slightly in each case. Here’s how these statements look in Java, for example, where the placeholder character is `?` and parameterized statements are referred to as *prepared* statements:[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)

```
Connection connection = DriverManager.getConnection(
                   URL, USER, PASS);
String sql = "SELECT * FROM users WHERE username = ?";
PreparedStatement stmt = connection.prepareStatement(sql);
stmt.setString(1, email);
ResultSet results = stmt.executeQuery(sql);
```

Note that although parameterized statements are essential for constructing SQL commands securely, in some circumstances you may legitimately generate the SQL command dynamically before parameterization. If the columns to be returned by a query or the ordering of results have to be dynamically constructed from input data, for example, you may find yourself writing code that looks like this:

```
@app.route('/books', methods=['GET'])
def get_books():
  order     = request.args.get('order') or ""        #1
  columns   = order.lower().split(",")               #2
  permitted = [ "title", "author", "isbn" ]          #3
  sanitized = [ c for c in columns 
                  if c in permitted ]                #4
  
  if not sanitized :
    sanitized = [ 'isbn ']                           #5
    
  order_by = ",".join(sanitized )                    #6
  
  sql   = f"SELECT * FROM books ORDER BY {order_by}" #7
  books = db.execute(sql).fetchall()

  return jsonify(books)
```

Here, we are constructing the `ORDER BY` clause of the SQL query dynamically according to the values supplied in the `order` parameters. Then the client-side code can fetch results in a particular order by constructing a URL with the form `/books?order=author,title,isbn`.

Complex ordering of results from a query isn’t easy to code with parameterized statements, so it’s common to see code constructing these types of SQL queries dynamically. The preceding snippet instead ensures that each input belongs to an allow list before it is inserted into the query, preventing SQL injection. This use of an allow list is another good way to protect against SQL injection.

### Object-relational mapping

[](/book/grokking-web-application-security/chapter-12/)Many web applications use an *object-relational mapping* (ORM) framework to automate the generation of SQL commands. This pattern was popularized by the Ruby on Rails framework, which makes for succinct application code. This example manipulates data in the `books` table in much the same way as our Python web service:[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)

```javascript
class BooksController < ApplicationController
  before_action :find_book, only: [:show, :update, :destroy]

  def index
    books = Book.all                             #1
    render json: books
  end

  def show
    render json: @book
  end

  def create
    book = Book.new(book_params)                 #2
    render json: book, status: :created
  end

  def update
    @book.update(book_params)                    #3
    render json: @book
  end

  def destroy
    @book.destroy                                #4
    head :no_content
  end

  private

    def find_book
      @book = Book.find_by(isbn: params[:isbn])  #5
    end
  

    def book_params
      params.require(:book).permit(:isbn, :title, :author)
    end
end
```

ORMs generally use parameterized statements under the hood and thus protect you from SQL injection attacks in most use cases. (Double-check the documentation of your ORM to be sure.)

[](/book/grokking-web-application-security/chapter-12/)Most ORMs are leaky abstractions, however, which is to say that they allow you to write SQL commands or snippets of SQL commands explicitly where needed. So you still need to be wary of injection attacks when you color outside the lines. If the `find_book` method had been written as follows, using string interpolation to construct the `WHERE` clause of the query, the code would be vulnerable to SQL injection:[](/book/grokking-web-application-security/chapter-12/)

```
def find_book
 isbn         = params[:isbn]
 where_clause = "isbn = '#{isbn}'"
 @book        = Book.where(where_clause) 
end
```

The `where` method in Rails supports parameterized statements, so be sure to use them if you ever construct a `WHERE` clause manually. You have two distinct ways to construct this clause safely because Rails allows you to name the placeholders and pass a hash of values:[](/book/grokking-web-application-security/chapter-12/)

```
Book.where(["isbn = ?", isbn])                      #1 
Book.where(["isbn = :isbn", { isbn: isbn }])    #2
```

##### Applying the principle of least privilege

SQL is often considered to be four separate sublanguages. Generally speaking, application code requires only permissions to read and/or update data, so restricting the permissions on the database account that your application communicates to the database with is a useful way to mitigate the risks of SQL injection. This feature is generally configured in the database itself, so talk to the database administrator if you have a separate team.

![](https://drek4537l1klr.cloudfront.net/mcdonald/Figures/12-08.png)

## NoSQL injection

[](/book/grokking-web-application-security/chapter-12/)SQL databases put a lot of constraints on what type of data can be written to them and how the integrity of that data is maintained. These constraints often cause the database to be a bottleneck in large web applications, as writes to the database have to be queued up and validated before being committed.[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)

The development and adoption of alternative database technologies—collectively called *NoSQL databases*—have allowed developers to tackle some of these scaling problems. NoSQL is not a formal technology specification, but a family of approaches to storing data that loosens the constrictions of traditional SQL databases.

Some NoSQL databases store information in key-value format; others store it as documents or graphs. Most NoSQL databases abandon strict consistency of writes (which insists that everyone see the same state of the data at all times) in favor of eventual consistency; many allow schemas to be changed in an ad hoc fashion rather than through the strict syntax of *Data Manipulation Language* (DML).

NoSQL databases are still vulnerable to injection attacks, however. Because each database has its particular method of querying and manipulating data (no standard NoSQL query language exists), ways to protect against injection attacks vary slightly. This section describes some examples of the leading NoSQL databases.

### MongoDB

[](/book/grokking-web-application-security/chapter-12/)MongoDB stores data using a document-based data model, which is based on the BSON (Binary JSON) format. BSON is a binary representation of JSON-like documents.[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)

The MongoDB database driver makes it easy to look up and edit records via function calls that accept parameters as arguments. The following snippet shows how to find a given record safely without the risk of injection:

```
client   = MongoClient(MONGO_CONNECTION_STRING)
database = client.database
books    = database.books

book = books.find_one("isbn", isbn})
```

MongoDB also has a low-level API that allows the explicit construction of command strings. This API is where injection vulnerabilities exhibit themselves, so avoid interpolating untrusted content into these command strings. If the `isbn` parameter comes from an untrusted source, as in the following example, you are at risk of an injection attack:[](/book/grokking-web-application-security/chapter-12/)

```
database.command(
 '{ find: "books", "filter" : { "isbn" : "' + isbn + '" }'
)
```

### Couchbase

Couchbase stores documents in JSON format. The database driver allows querying of data in the SQL++ language, which supports parameterized statements, and accepts parameters in key-value format. Use parameterized statements as follows to prevent injection attacks:[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)

```
cluster = Cluster(COUCHBASE_CONNECTION_STRING)
cluster.query(select * from books where isbn = $isbn",    
             isbn=isbn)  
cluster.query("select * from books where isbn = $1", isbn)
```

### Cassandra

[](/book/grokking-web-application-security/chapter-12/)Cassandra organizes data in tables but with a more flexible schema model than traditional SQL databases. The Cassandra Query Language looks a lot like SQL, and the driver supports parameterized statements like the following, which you should use:[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)

```
cluster = Cluster(CASSANDRA_CONNECTION_STRING)
session = cluster.connect()
update  = session.prepare(
 "update books set name = ? and author = ? where isbn = ?")

session.execute(update, [ name, author, email ])
```

### HBase

HBase stores data logically in tables, although individual values for a row often end up being stored in separate data blocks and are accessed atomically. This arrangement allows for the fast storage of very large datasets, which a compactor process can optimize later.[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)

Writing or reading data to or from HBase is usually done one row at a time, so no analogue of the traditional database injection attack exists. But make sure that an attacker can’t manipulate the row keys of the rows you are accessing:

```
connection = happybase.Connection(HBASE_CONNECTION_STRING)
books= connection.table("books")
books.put(isbn, 
 { b'main:author': author, b'main:title': title })
```

## LDAP injection

We should discuss one further technology while we are looking at injection attacks against databases. Lightweight Directory Access Protocol (LDAP) is a method of storing and accessing directory information about users, systems, and devices.[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)

If you program on a Windows platform, you likely have experience with Active Directory, Microsoft’s implementation of LDAP that underpins Windows networks. Web applications that access LDAP servers frequently use parameters from an untrusted source to make queries against user data, which gives rise to the possibility of injection attacks.

Consider an example. When a user attempts to log in to a website, the username parameter supplied in the HTTP request may be incorporated into an LDAP query to check the user’s credentials. The following Python function connects to an LDAP server to validate a username and password:

```
import ldap

def validate_credentials(username, password):
 ldap_query = f"(&(uid={username})(userPassword={password}))"
 connection = ldap.initialize("ldap://127.0.0.1:389")
 user       = connection.search_s(
                "dc=example,dc=com", 
                ldap.SCOPE_SUBTREE, 
                ldap_query) 
 
 return user.length == 1
```

[](/book/grokking-web-application-security/chapter-12/)Because the LDAP query is built through string interpolation and the inputs are not sanitized, an attacker can supply the password parameter as a wildcard pattern (`*`) that matches any value, allowing them to bypass authentication.[](/book/grokking-web-application-security/chapter-12/)

To construct LDAP queries from untrusted data safely, you must remove any characters that have a special meaning in the LDAP query language itself. The following code snippet illustrates a secure way of escaping the username and password in Python in such a way that an attacker cannot inject control characters:

```
import escape_filter_chars from ldap.filter

def validate_credentials(username, password):
  esc_user   = escape_filter_chars(username)
  esc_pass   = escape_filter_chars(password)
  ldap_query = f"(&(uid={esc_user})(userPassword={esc_pass}))"
  connection = ldap.initialize("ldap://127.0.0.1:389")
  user       = connection.search_s(
                 "dc=example,dc=com", 
                 ldap.SCOPE_SUBTREE, 
                 ldap_query) 
  
  return user.length == 1
```

## Command injection

Attackers use a technique called *command injection* to execute operations on the underlying operating system on which an application is running. In web applications, this attack is achieved by crafting malicious HTTP requests to take advantage of code that constructs command-line calls insecurely, subverting the intention of the original code and allowing the attacker to invoke arbitrary operating system functions.[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)

Calling low-level operating system functions from application code is more common in some programming languages than in others. PHP applications often make command-line calls; scripting languages like Python, Node.js, and Ruby make it easy to do but also provide native APIs for functions such as disk and network access. Languages that run on a virtual machine, such as Java, generally insulate your code from the operating system. Though it’s possible to make system calls from Java, the language’s design philosophy discourages this practice.

A typical command injection vulnerability exhibits itself as follows. Suppose that you run a simple site that performs DNS lookups. Your application calls the operating system command `nslookup` and then prints the result. (More realistically, this kind of website is plastered with distracting advertisements, but I omitted them from the illustration for clarity.)[](/book/grokking-web-application-security/chapter-12/)

The code that’s illustrated here takes the `domain` parameter from the URL, binds it into a command string, and calls an operatiing system function. By crafting a malicious parameter value, an attacker can chain extra commands to the end of the `nslookup` command string.[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)

In this example, the attacker used command injection to read the contents of a sensitive file. The `&&` operator allows commands to be chained together in a Linux system, and the code does nothing to sanitize the input. With this type of vulnerability ready to be exploited, an attacker who shows a little persistence will be able to install malicious software on the server. Maybe you will end up being the victim of a ransomware attack.[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)

You have two ways to protect yourself from command injection attacks:

-  Avoid invoking the operating system directly (the preferred approach).
-  Sanitize any inputs you incorporate into command-line calls.

The following minitable shows how to do the latter in various programming languages.

Language

Recommendation

Python

The `subprocess` package allows you to pass individual command arguments to the `run()` function as a list, which protects you from command injection:

```
from subprocess import run
run(["ns_lookup", domain])
```

Ruby

Use the `shellwords` module to escape control characters in command strings:

```
require 'shellwords'
Kernel.open("nslookup #{Shellwords.escape(domain)}")
```

Node.js[](/book/grokking-web-application-security/chapter-12/)

The `child_process` package allows you to pass individual command arguments to the `spawn()` function as an array, which protects you from command injection:

```javascript
const child_process = require('child_process')
child_process.spawn('nslookup', [domain])
```

Java

The `java.lang.Runtime` class allows you to pass individual command arguments to the `exec()` function as a `String` array, which protects you from command injection:

```
String[] command = { "nslookup", domain };
Runtime.getRuntime().exec(command);
```

.NET

Use the `ProcessStartInfo` class from the `System.Diagnostics` namespace to allow structured creation of command-line calls:

```
var process = new ProcessStartInfo()
process.UseShellExecute = true;
process.FileName  = @"C:\Windows\System32\cmd.exe";
process.Verb      = "nslookup";
process.Arguments = domain;
Process.Start(process);
```

PHP

Use the built-in `escapeshellcmd()` function to remove control characters before running command-line calls:[](/book/grokking-web-application-security/chapter-12/)

```
$domain  = $_GET['domain']
$escaped = escapeshellcmd($domain);
$lookup  = system("nslookup {$domain}");
```

## CRLF injection

Not every injection attack is as elaborate as the ones discussed so far in this chapter. Sometimes, injecting a single character is enough to cause problems—when that character is the line feed.[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)

In UNIX-based operating systems, new lines in a file are marked by the line feed (LF), usually written as `\n` in code. In Windows-based operating systems, new lines are marked with two characters: the carriage return (CR) character (written `\r`) followed by the LF character. (*Carriage return* is a holdover from the days of typewriters, when the device had to advance one line and then move the carriage—which held the typehead—back to the start of the next line.)[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)

Attackers can inject LF or CRLF combinations into web applications to cause mischief in a couple of ways. One type of attack is *log injection*, in which the attacker uses LF characters to add extra lines of logging.[](/book/grokking-web-application-security/chapter-12/)

In the following scenario, a hacker knows that software monitoring exists for successive failed login attempts and will raise an alert if they try to brute-force credentials. To avoid raising alerts, they alternate each password-guessing attempt with a log injection attack, making it appear that some login attempts have been successful.

[](/book/grokking-web-application-security/chapter-12/)Sophisticated attackers use log injection in this way to disguise their footprints when attempting to compromise a system. Injecting fake lines of logging disguises their behavior and makes forensics difficult to perform.

The most effective way to mitigate forged log entries is to strip newline characters from untrusted input when incorporating that input into log messages, and then to use a standard logging package that prepends log statements with metadata like the timestamp and code location. The latter approach alone makes it obvious what an attacker is trying to do because the forged log lines lack metadata.

The second use of CRLF injection is to launch *HTTP response splitting* attacks. In these attacks, an attacker takes advantage of an application that incorporates untrusted input into an HTTP response header, tricking the server into terminating the header section of the response early.[](/book/grokking-web-application-security/chapter-12/)

In the HTTP specification, each header row in a request or response must end with a `\r\n` character combination. Two consecutive `\r\n` values indicate that the header section is complete and the body of the response is starting.

If an attacker can inject a `\r\n\r\n` combination into an HTTP header, they can insert their own content into the body of the response. Attacks use this technique to push malicious downloads to a victim or inject malicious JavaScript code into the response.

To mitigate this attack, be sure to strip any CR or LF characters if you incorporate untrusted input into an HTTP response header. The headers most commonly used for HTTP response splitting are `Location` (used in redirects) and `Set-Cookie`, so pay careful attention when setting these values.[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)

## Regex injection

The final injection attack we should discuss is carried out against regular expression libraries. We touched on regular expressions (regexes) in chapter 4; they are a way of describing the expected order and grouping characters in a string by specifying a pattern to match against.[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)

This setup seems to be fairly benign. But if an attacker can control the pattern string and the string being tested, they can perform denial-of-service (DoS) attacks on your web application by supplying so-called *evil regexes*, which require a lot of computational effort to evaluate.[](/book/grokking-web-application-security/chapter-12/)[](/book/grokking-web-application-security/chapter-12/)

These kinds of pattern strings are deliberately ambiguous and cause the regex engine to do a lot of backtracking when testing particular inputs. An attacker can exploit this vulnerability by sending multiple requests with the same computationally expensive regex, eventually exhausting the processing power of a server and taking it offline. This type of attack is called a *regular expression DoS attack* (ReDoS).[](/book/grokking-web-application-security/chapter-12/)

[](/book/grokking-web-application-security/chapter-12/)It’s rare to come across a situation in which the user of the web application needs control of the regex pattern string, so usually, regexes can be defined statically in server-side code. You can check for untrusted input being inserted into regular expressions by using static analysis tools. The SonarSource tool, for example, has rules to detect this vulnerability in various languages; one such rule is available at [https://rules.sonarsource.com/java/RSPEC-2631](https://rules.sonarsource.com/java/RSPEC-2631). You can integrate these rules into your integrated development environment or continuous integration pipeline.[](/book/grokking-web-application-security/chapter-12/)

Where the regex pattern is supplied from client-side code, it’s usually because the application is attempting to implement a rich search syntax to look over large datasets (such as lines in a logging server). These situations are better handled by feeding the datasets into dedicated search indexing software like Elasticsearch, which allows efficient searches using rich search syntax and eliminates the potential security flaws of regular expressions:[](/book/grokking-web-application-security/chapter-12/)

```
from flask import request, jsonify
from elasticsearch import Elasticsearch

es_client = Elasticsearch([ ELASTIC_SEARCH_URL ])  

@app.route("/document", methods=["POST"])
def add_document():
 data   = request.get_json()
 result = es_client.index(index="documents", body=data)
 return jsonify({"message": "Document indexed"}), 201

@app.route("/search/<search_query>", methods=["GET"])
def search(search_query):
 result = es_client.search(
             index="documents", 
             body={"query": 
               {"match": {"content": search_query}}})
 return jsonify({"results": result["hits"]["hits"]}), 200
```

## Summary

-  Never dynamically execute untrusted input as code.
-  [](/book/grokking-web-application-security/chapter-12/)If you need to create a DSL for users of your web application, use an embedded language like Lua, or use a toolkit to parse the grammar of DSL expressions before evaluation to ensure proper sandboxing.
-  If your template language supports server-side includes, disable includes that use remote URLs.
-  Use parameterized statements to avert injection attacks against databases.
-  Where you need to dynamically generate database commands (such as when you’re constructing dynamic `ORDER BY` clauses in SQL queries or when the database driver doesn’t support parameterized statements), sanitize untrusted inputs against an allow list or remove control characters before incorporating them into the command.
-  Avoid using command-line calls from application code if possible.
-  If command-line calls are unavoidable, avoid incorporating untrusted input into commands sent to the operating system.
-  If incorporating untrusted output is unavoidable, sanitize untrusted inputs before they are incorporated into the operating system command to remove any control characters.
-  Strip newline characters from untrusted input incorporated into log messages. Use a standard logging package to prepend logging messages with metadata such as timestamp and code location.
-  Strip newline characters from untrusted input incorporated into HTTP response headers to prevent HTTP response splitting attacks.
-  Use a dedicated search index if you need to provide rich search syntax to users, eliminating the temptation to evaluate untrusted input as a regex pattern. Doing the latter leads to DoS attacks.[](/book/grokking-web-application-security/chapter-12/)
