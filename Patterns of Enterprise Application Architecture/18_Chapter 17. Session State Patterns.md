## Chapter 17. Session State Patterns

### Client Session State

*Stores session state on the client.*

#### How It Works

Even the most server-oriented designs need at least a little *Client Session State,* if only to hold a session identifier. With some applications you can consider putting all of the session data on the client, in which case the client sends the full set of session data with each request and the server sends back the full session state with each response. This allows the server to be completely stateless.

Most of the time you’ll want to use *[Data Transfer Object](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch15.html#ch15lev1sec2) ([401](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch15.html#page_401))* to handle the data transfer. The *[Data Transfer Object](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch15.html#ch15lev1sec2) ([401](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch15.html#page_401))* can serialize itself over the wire and thus allow even complex data to be transmitted.

The client also needs to store the data. If it’s a rich-client application it can do this within its own structures, such as the fields in its interface—although I would drink Budweiser rather than do that. A set of nonvisual objects often makes a better bet, such as the *[Data Transfer Object](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch15.html#ch15lev1sec2) ([401](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch15.html#page_401))* itself or a domain model. Either way it’s not usually a big problem.

With an HTML interface, things get a bit more complicated. There are three common ways to do client session state: URL parameters, hidden fields, and cookies.

URL parameters are the easiest to work with for a small amount of data. Essentially all URLs on any response page take the session state as a parameter. The clear limit to doing this is that the size of an URL is limited, but if you only have a couple of data items it works well, that’s why it’s a popular choice for something like a session ID. Some platforms will do automatic URL rewriting to add a session ID. Changing the URL may be a problem with bookmarks, so that’s an argument against using URL parameters for consumer sites.

A hidden field is a field sent to the browser that isn’t displayed on the Web page. You get it with a tag of the form `<INPUT type = "hidden">`. To make a hidden field work you serialize your session state into it when you make a response and read it back in on each request. You’ll need a format for putting the data in the hidden field. XML is an obvious standard choice, but of course it’s rather wordy. You can also encode the data in some text-based encoding scheme. Remember that a hidden field is only hidden from the displayed page; anyone can look at the data by looking at the page source.

Beware a mixed site that has older or fixed Web pages. You can lose all the session data if you navigate to them.

The last, and sometimes controversial, choice is cookies, which are sent back and forth automatically. Just like a hidden field you can use a cookie by serializing the session state into it. You’re limited in how big the cookie can be. Also, many people don’t like cookies and turn them off. If they do that, your site will stop working. However, more and more sites are dependent on cookies now, so that will happen less often, and certainly isn’t a problem for a purely in-house system.

Realize that cookies are no more secure than anything else, so assume that prying of all kinds can happen. Cookies also work only within a single domain name, so if your site is separated into different domain names the cookies won’t travel between them.

Some platforms can detect whether cookies are enabled; and if not, they can use URL rewriting. This can make client session state very easy for very small amounts of data.

#### When to Use It

*Client Session State* contains a number of advantages. In particular, it reacts well in supporting stateless server objects with maximal clustering and failover resiliency. Of course, if the client fails all is lost, but often the user expects that anyway.

The arguments against *Client Session State* vary exponentially with the amount of data involved. With just a few fields everything works nicely. With large amounts of data the issues of where to store the data and the time cost of transferring everything with every request become prohibitive. This is especially true if your stars include an http client.

There’s also the security issue. Any data sent to the client is vulnerable to being looked at and altered. Encryption is the only way to stop this, but encrypting and decrypting with each request are a performance burden. Without encryption you have to be sure you aren’t sending anything you would rather hide from prying eyes. Fingers can pry too, so don’t assume that what got sent out is the same as what gets sent back. Any data coming back will need to be completely revalidated.

You almost always have to use *Client Session State* for session identification. Fortunately, this should be just one number, which won’t burden any of the above schemes. You should still be concerned about session stealing, which is what happens when a malicious user changes his session ID to see if he can snag someone else’s session. Most platforms come up with a random session ID to reduce this risk; if not, run a simple session ID through a hash.

### Server Session State

*Keeps the session state on a server system in a serialized form.*

#### How It Works

In the simplest form of this pattern a session object is held in memory on an application server. You can have some kind of map in memory that holds these session objects keyed by a session ID; all the client needs to do is to give the session ID and the session object can be retrieved from the map to process the request.

This basic scenario assumes, of course, that the application server carries enough memory to perform this task. It also assumes that there’s only one application server—that is, no clustering—and that, if the application server fails, it’s appropriate for the session to be abandoned and all work done so far to be lost in the great bit-bucket in the sky.

For many applications this set of assumptions is actually not a problem. However, for others it may be problematic. There are ways of dealing with cases where the assumptions are no longer valid, and these introduce common variations that add complexity to an essentially simple pattern.

The first issue is that of dealing with memory resources held by the session objects. Indeed, this is the common objection to *Server Session State.* The answer, of course, is not to keep resources in memory but instead serialize all the session state to a memento [[Gang of Four](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/bib01.html#biblio20)] for persistent storage. This presents two questions: In what form do you persist the *Server Session State,* and where do you persist it?

The form to use is usually as simple a form as possible, since the accent of *Server Session State* is its simplicity in programming. Several platforms provide a simple binary serialization mechanism that allows you to serialize a graph of objects quite easily. Another route is to serialize into another form, such as text—fashionably as an XML file.

The binary form is usually easier, since it requires little programming, while the textual form usually requires at least a little code. Binary serializations also require less disk space; although total disk space is rarely a concern, large serialized graphs will take longer to activate into memory.

There are two common issues with binary serialization. First, the serialized form is not human readable—which is a problem if humans want to read it. Second, there may be problems with versioning. If you modify a class by, say, adding a field after you’ve serialized it, you may not be able to read it back. Of course, not many sessions are likely to span an upgrade of the server software unless it’s a 24/7 server where you may have a cluster of machines running, some upgraded and some not.

This brings us to the question of where to store the *Server Session State.* An obvious possibility is on the application server itself, either in the file system or in a local database. This is the simple route, but it may not support efficient clustering or failover. To support these the passivated *Server Session State* needs to be somewhere generally accessible, such as on shared server. This will support clustering and failover at the cost of a longer time to activate the server—although caching may well eliminate much of this cost.

This line of reasoning may lead, ironically to storing the serialized *Server Session State* in the database using a session table indexed by the session ID. This table would require a *[Serialized LOB](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch12.html#ch12lev1sec6) ([272](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch12.html#page_272))* to hold the serialized *Server Session State.* Database performance varies when it comes to handling large objects, so the performance aspects of this one are very database dependent.

At this point we’re right at the boundary between *Server Session State* and *[Database Session State](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch17.html#ch17lev1sec3) ([462](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch17.html#page_462)).* This boundary is completely arbitrary, but I’ve drawn the line at the point where you convert the data in the *Server Session State* into tabular form.

If you’re storing *Server Session State* in a database, you’ll have to worry about handling sessions going away, especially in a consumer application. One route is to have a daemon that looks for aged sessions and deletes them, but this can lead to a lot of contention on the session table. Kai Yu told me about an approach he used with success: partitioning the session table into twelve database segments and every two hours rotating the segments, deleting everything in the oldest segment and then directing all inserts to it. While this meant that any session that was active for twenty-four hours got unceremoniously dumped, that would be sufficiently rare to not be a problem.

All these variations take more and more effort to do, but the good news is that application servers increasingly support these capabilities automatically. Thus, it may well be that application server vendors can worry their ugly little heads about them.

**Java Implementation**
The two most common techniques for *Server Session State* are using the http session and using a stateful session bean. The http session is the simple route and causes the session data to be stored by the Web server. In most cases this leads to server affinity and it can’t cope with failover. Some vendors are implementing a shared http session capability that allows you to store http session data in a database that’s available to all application servers. (You can also do this manually, of course.)

The other common route is via a stateful session bean, which requires an EJB server. The EJB container handles all persistence and passivation, so this makes it very easy to program to. The main disadvantage is that the specification doesn’t ask the application server to avoid server affinity. However, some application servers provide this capability. One, IBM’s WebSphere, can serialize a stateful session bean into a BLOB in DB2, which allows multiple application servers to get at its state.

A lot of people say that, since stateless session beans perform better, you should *always* use them instead of stateful beans. Frankly, that’s hogwash. Load-test with your environment first to see if you fall into the range of speed difference between stateful and stateless that makes any difference to your application. ThoughtWorks has load-tested apps with a couple of hundred of concurrent users and not found any performance problems due to stateful beans on that size of user load. If the performance advantage isn’t significant for your loads, and stateful beans are easier, then you should use them. There are other reasons to be wary of stateful beans—failover may be more problematic depending on your vendor, but the performance difference only appears under a heavy load.

Another alternative is to use an entity bean. On the whole, I’ve been pretty dismissive of entity beans, but you can use one to store a *[Serialized LOB](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch12.html#ch12lev1sec6) ([272](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch12.html#page_272))* of session data. This is pretty simple and less likely to raise many of the issues that usually surround entity beans.

**.NET Implementation**
*Server Session State* is easy to implement with the built-in session state capability. By default .NET stores session data in the server process itself. You can also adjust the storage using a state service, which can reside on the local machine or on any other machine on the network. With a separate state service you can reset the Web server and still retain the session state. You make the change between in-process state and a state service in the configuration file, so you don’t have to change the application.

#### When to Use It

The great appeal of *Server Session State* is its simplicity. In a number of cases you don’t have to do any programming at all to make this work. Whether you can get away with that depends on if you can get away with the in-memory implementation and, if not, how much help your application server platform gives you.

Even without that you may well find that the effort you do need is small. Serializing a BLOB to a database table may turn out to be much less effort than converting the server objects to tabular form.

Where the programming effort comes into play is in session maintenance, particularly if you have to roll your own support to enable clustering and failover. It may work out to be more trouble than your other options, especially if you don’t have much session data to deal with or if your session data is easily converted to tabular form.

### Database Session State

*Stores session data as committed data in the database.*

#### How It Works

When a call goes out from the client to the server, the server object first pulls the data required for the request from the database. Then it does the work it needs to do and saves back to the database all the data required.

In order to pull information from the database, the server object will need some information about the session, which requires at least a session ID number to be stored on the client. Usually, however, this information is nothing more than the appropriate set of keys needed to find the appropriate amount of data in the database.

The data involved is typically a mix of session data that’s only local to the current interaction and committed data that’s relevant to all interactions.

One of the key issues to consider here is the fact that session data is usually considered local to the session and shouldn’t affect other parts of the system until the session as a whole is committed. Thus, if you’re working on an order in a session and you want to save its intermediate state to the database, you usually need to handle it differently from an order that’s confirmed at the end of a session. This is because you don’t want pending orders to appear that often in queries run against the database for such things as book availability and daily revenue.

So how do you separate the session data? Adding a field to each database row that may have session data is one route. The simplest form of this just requires a Boolean `isPending field`. However, a better way is to store a session ID as a pending field, which makes it much easier to find all the data for a particular session. All queries that want only record data now need to be modified with a `sessionID is not NULL` clause, or need a view that filters out that data.

Using a session ID field is a very invasive solution because all applications that touch the record database need to know the field’s meaning to avoid getting session data. Views will sometimes do the trick and remove the invasiveness, but they often impose costs of their own.

A second alternative is a separate set of pending tables. So if you have orders and order lines tables already in your database, you would add tables for pending orders and pending order lines. Pending session data you save to the pending table; when it becomes record data you save it to the real tables. This removes much of the invasiveness. However, you’ll need to add the appropriate table selection logic to your database mapping code, which will certainly add some complications.

Often the record data will have integrity rules that don’t apply to pending data. In this case the pending tables allow you to forgo the rules when you don’t want them but to enforce them when you do. Validation rules as well typically aren’t applied when saving pending data. You may face different validation rules depending on where you are in the session, but this usually appears in server object logic.

If you use pending tables, they should be exact clones of the real tables. That way you can keep your mapping logic as similar as possible. Use the same field names between the two tables, but add a session ID field to the pending tables so you can easily find all the data for a session.

You’ll need a mechanism to clean out the session data if a session is canceled or abandoned. Using a session ID you can find all data with it and delete it. If users abandon the session without telling you, you’ll need some kind of timeout mechanism. A daemon that runs every few minutes can look for old session data. This requires a table in the database that keeps track of the time of the last interaction with the session.

Rollback is made much more complicated by updates. If you update an existing order in a session that allows a rollback of the whole session, how do you perform the rollback? One option is not to allow cancellation of a session like this. Any updates to existing record data become part of the record data at the end of the request. This is simple and often fits the users’ view of the world. The alternative is awkward whether you use pending fields or pending tables. It’s easy to copy all the data that may be modified into pending tables, modify it there, and commit it back to the record tables at the end of the session. You can do this with a pending field, but only if the session ID becomes part of the key. In this way you can keep the old and new IDs in the same table at the same time, which can get very messy.

If you’re going to use separate pending tables that are only read by objects that handle a session, then there may be little point in tabularizing the data. It’s better to use a *[Serialized LOB](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch12.html#ch12lev1sec6) ([272](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch12.html#page_272)).* At this point we’ve crossed the boundary into a *[Server Session State](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch17.html#ch17lev1sec2) ([458](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch17.html#page_458)).*

You can avoid all of the hassles of pending data by not having any. That is, you design your system so that all data is considered record data. This isn’t always possible, of course, and if it is it can be so awkward that designers would be better off thinking about explicit pending data. Still, if you have the option it makes *Database Session State* a lot easier to work with.

#### When to Use It

*Database Session State* is one alternative to handling session state; it should be compared with *[Server Session State](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch17.html#ch17lev1sec2) ([458](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch17.html#page_458))* and *[Client Session State](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch17.html#ch17lev1sec1) ([456](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch17.html#page_456)).*

The first aspect to consider with this pattern is performance. You’ll gain by using stateless objects on the server, thus enabling pooling and easy clustering. However, you’ll pay with the time needed to pull the data in and out of the database with each request. You can reduce this cost by caching the server object so you won’t have to read the data out of the database whenever the cache is hit, but you’ll still pay the write costs.

The second main issue is the programming effort, most of which centers around handling session state. If you have no session state and are able to save all your data as record data in each request, this pattern is an obvious choice because you lose nothing in either effort or performance (if you cache your server objects).

In a choice between *Database Session State* and *[Server Session State](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch17.html#ch17lev1sec2) ([458](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch17.html#page_458))* the biggest issue may be how easy it is to support clustering and failover with *[Server Session State](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch17.html#ch17lev1sec2) ([458](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch17.html#page_458))* in your particular application server. Clustering and failover with *Database Session State* are usually more straightforward, at least with the regular solutions.
