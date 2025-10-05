## Chapter 10. Data Source Architectural Patterns

### Table Data Gateway

*An object that acts as a [Gateway](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#ch18lev1sec1) ([466](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#page_466)) to a database table. One instance handles all the rows in the table.*

![Image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:0321127420/files/graphics/10fig01a.jpg)

Mixing SQL in application logic can cause several problems. Many developers aren’t comfortable with SQL, and many who are comfortable may not write it well. Database administrators need to be able to find SQL easily so they can figure out how to tune and evolve the database.

A *Table Data Gateway* holds all the SQL for accessing a single table or view: selects, inserts, updates, and deletes. Other code calls its methods for all interaction with the database.

#### How It Works

A *Table Data Gateway* has a simple interface, usually consisting of several find methods to get data from the database and update, insert, and delete methods. Each method maps the input parameters into a SQL call and executes the SQL against a database connection. The *Table Data Gateway* is usually stateless, as its role is to push data back and forth.

The trickiest thing about a *Table Data Gateway* is how it returns information from a query. Even a simple find-by-ID query will return multiple data items. In environments where you can return multiple items you can use that for a single row, but many languages give you only a single return value and many queries return multiple rows.

One alternative is to return some simple data structure, such as a map. A map works, but it forces data to be copied out of the record set that comes from the database into the map. I think that using maps to pass data around is bad form because it defeats compile time checking and isn’t a very explicit interface, leading to bugs as people misspell what’s in the map. A better alternative is to use a *[Data Transfer Object](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch15.html#ch15lev1sec2) ([401](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch15.html#page_401)).* It’s another object to create but one that may well be used elsewhere.

To save all this you can return the *[Record Set](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#ch18lev1sec11) ([508](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#page_508))* that comes from the SQL query. This is conceptually messy, as ideally the in-memory object doesn’t have to know anything about the SQL interface. It may also make it difficult to substitute the database for a file if you can’t easily create record sets in your own code. Nevertheless, in many environments that use *[Record Set](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#ch18lev1sec11) ([508](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#page_508))* widely, such as .NET, it’s a very effective approach. A *Table Data Gateway* thus goes very well with *[Table Module](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#ch09lev1sec3) ([125](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#page_125)).* If all of your updates are done through the *Table Data Gateway,* the returned data can be based on views rather than on the actual tables, which reduces the coupling between your code and the database.

If you’re using a *[Domain Model](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#ch09lev1sec2) ([116](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#page_116)),* you can have the *Table Data Gateway* return the appropriate domain object. The problem with this is that you then have bidirectional dependencies between the domain objects and the gateway. The two are closely connected, so that isn’t necessarily a terrible thing, but it’s something I’m always reluctant to do.

Most times when you use *Table Data Gateway,* you’ll have one for each table in the database. For very simple cases, however, you can have a single *Table Data Gateway* that handles all methods for all tables. You can also have one for views or even for interesting queries that aren’t kept in the database as views. Obviously, view-based *Table Data Gateways* often can’t update and so won’t have update behavior. However, if you can make updates to the underlying tables, then encapsulating the updates behind update operations on the *Table Data Gateway* is a very good technique.

#### When to Use It

As with *[Row Data Gateway](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#ch10lev1sec2) ([152](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#page_152))* the decision regarding *Table Data Gateway* is first whether to use a *[Gateway](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#ch18lev1sec1) ([466](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#page_466))* approach at all and then which one.

I find that *Table Data Gateway* is probably the simplest database interface pattern to use, as it maps so nicely onto a database table or record type. It also makes a natural point to encapsulate the precise access logic of the data source. I use it least with *[Domain Model](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#ch09lev1sec2) ([116](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#page_116))* because I find that *[Data Mapper](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#ch10lev1sec4) ([165](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#page_165))* gives a better isolation between the *[Domain Model](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#ch09lev1sec2) ([116](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#page_116))* and the database.

*Table Data Gateway* works particularly well with *[Table Module](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#ch09lev1sec3) ([125](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#page_125)),* where it produces a record set data structure for the *[Table Module](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#ch09lev1sec3) ([125](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#page_125))* to work on. Indeed, I can’t really imagine any other database-mapping approach for *[Table Module](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#ch09lev1sec3) ([125](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#page_125)).*

Just like *[Row Data Gateway](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#ch10lev1sec2) ([152](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#page_152)),* *Table Data Gateway* is very suitable for *[Transaction Scripts](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#ch09lev1sec1) ([110](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#page_110)).* The choice between the two really boils down to how they deal with multiple rows of data. Many people like using a *[Data Transfer Object](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch15.html#ch15lev1sec2) ([401](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch15.html#page_401)),* but that seems to me like more work than is worthwhile, unless the same *[Data Transfer Object](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch15.html#ch15lev1sec2) ([401](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch15.html#page_401))* is used elsewhere. I prefer *Table Data Gateway* when the result set representation is convenient for the *[Transaction Script](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#ch09lev1sec1) ([110](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#page_110))* to work with.

Interestingly, it often makes sense to have the *[Data Mappers](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#ch10lev1sec4) ([165](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#page_165))* talk to the database via *Table Data Gateways.* Although this isn’t useful when everything is handcoded, it can be very effective if you want to use metadata for the *Table Data Gateways* but prefer handcoding for the actual mapping to the domain objects.

One of the benefits of using a *Table Data Gateway* to encapsulate database access is that the same interface can work both for using SQL to manipulate the database and for using stored procedures. Indeed, stored procedures themselves are often organized as *Table Data Gateways.* That way the insert and update stored procedures encapsulate the actual table structure. The find procedures in this case can return views, which helps to hide the underlying table structure.

#### Further Reading

[[Alur et al](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/bib01.html#biblio03).] discusses the *Data Access Object* pattern, which is a *Table Data Gateway.* They show returning a collection of *[Data Transfer Objects](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch15.html#ch15lev1sec2) ([401](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch15.html#page_401))* on the query methods. It’s not clear whether they see this pattern as always being table based; the intent and discussion seems to imply either *Table Data Gateway* or *[Row Data Gateway](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#ch10lev1sec2) ([152](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#page_152)).*

I’ve used a different name, partly because I see this pattern as a particular usage of the more general *[Gateway](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#ch18lev1sec1) ([466](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#page_466))* concept and I want the pattern name to reflect that. Also, the term *Data Access Object* and its abbreviation *DAO* has its own particular meaning within the Microsoft world.

#### Example: Person Gateway (C#)

*Table Data Gateway* is the usual form of database access in the windows world, so it makes sense to illustrate one with C#. I have to stress, however, that this classic form of *Table Data Gateway* doesn’t quite fit in the .NET environment since it doesn’t take advantage of the ADO.NET data set; instead, it uses the data reader, which is a cursor-like interface to database records. The data reader is the right choice for manipulating larger amounts of information when you don’t want to bring everything into memory in one go.

For the example I’m using a Person Gateway class that connects to a person table in a database. The Person Gateway contains the finder code, returning ADO.NET’s data reader to access the returned data.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode21)

class PersonGateway...

public IDataReader FindAll() {
String sql = "select * from person";
return new OleDbCommand(sql, DB.Connection).ExecuteReader();
}
public IDataReader FindWithLastName(String lastName) {
String sql = "SELECT * FROM person WHERE lastname = ?";
IDbCommand comm = new OleDbCommand(sql, DB.Connection);
comm.Parameters.Add(new OleDbParameter("lastname", lastName));
return comm.ExecuteReader();
}
public IDataReader FindWhere(String whereClause) {
String sql = String.Format("select * from person where {0}", whereClause);
return new OleDbCommand(sql, DB.Connection).ExecuteReader();
}

Almost always you’ll want to pull back a bunch of rows with a reader. On a rare occasion you might want to get hold of an individual row of data with a method along these lines:

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode22)

class PersonGateway...

public Object[] FindRow (long key) {
String sql = "SELECT * FROM person WHERE id = ?";
IDbCommand comm = new OleDbCommand(sql, DB.Connection);
comm.Parameters.Add(new OleDbParameter("key",key));
IDataReader reader = comm.ExecuteReader();
reader.Read();
Object  [] result = new Object[reader.FieldCount];
reader.GetValues(result);
reader.Close();
return result;
}

The update and insert methods receive the necessary data in arguments and invoke the appropriate SQL routines.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode23)

class PersonGateway...

public void Update (long key, String lastname, String firstname, long numberOfDependents){
String sql = @"
UPDATE person
SET lastname = ?, firstname = ?, numberOfDependents = ?
WHERE id = ?";
IDbCommand comm = new OleDbCommand(sql, DB.Connection);
comm.Parameters.Add(new OleDbParameter ("last", lastname));
comm.Parameters.Add(new OleDbParameter ("first", firstname));
comm.Parameters.Add(new OleDbParameter ("numDep", numberOfDependents));
comm.Parameters.Add(new OleDbParameter ("key", key));
comm.ExecuteNonQuery();
}

class PersonGateway...

public long Insert(String lastName, String firstName, long numberOfDependents) {
String sql = "INSERT INTO person VALUES (?,?,?,?)";
long key = GetNextID();
IDbCommand comm = new OleDbCommand(sql, DB.Connection);
comm.Parameters.Add(new OleDbParameter ("key", key));
comm.Parameters.Add(new OleDbParameter ("last", lastName));
comm.Parameters.Add(new OleDbParameter ("first", firstName));
comm.Parameters.Add(new OleDbParameter ("numDep", numberOfDependents));
comm.ExecuteNonQuery();
return key;
}

The deletion method just needs a key.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode24)

class PersonGateway...

public void Delete (long key) {
String sql = "DELETE  FROM person WHERE id = ?";
IDbCommand comm = new OleDbCommand(sql, DB.Connection);
comm.Parameters.Add(new OleDbParameter ("key", key));
comm.ExecuteNonQuery();
}

#### Example: Using ADO.NET Data Sets (C#)

The generic *Table Data Gateway* works with pretty much any kind of platform since it’s nothing but a wrapper for SQL statements. With .NET you use data sets more often, but *Table Data Gateway* is still useful although it comes in a different form.

A data set needs data adapters to load the data into it and update the data. In find it useful to define a holder for the data set and the adapters. A gateway then uses the holder to store them. Much of this behavior is generic and can be done in a superclass.

The holder indexes the data sets and adapters by the name of the table.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode25)

class DataSetHolder...

public DataSet Data = new DataSet();
private Hashtable DataAdapters = new Hashtable();

![Image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:0321127420/files/graphics/10fig01.jpg)

Figure 10.1. Class diagram of data-set-oriented gateway and the supporting data holder.

The gateway stores the holder and exposes the data set for its clients.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode26)

class DataGateway...

public DataSetHolder Holder;
public DataSet Data  {
get {return Holder.Data;}
}

The gateway can act on an existing holder, or it can create a new one.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode27)

class DataGateway...

protected DataGateway() {
Holder = new DataSetHolder();
}
protected DataGateway(DataSetHolder holder) {
this.Holder = holder;
}

The find behavior can work a bit differently here. A data set is a container for table-oriented data and can hold data from several tables. For that reason it’s better to load data into a data set.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode28)

class DataGateway...

public void LoadAll() {
String commandString = String.Format("select * from  {0}", TableName);
Holder.FillData(commandString, TableName);
}
public void LoadWhere(String whereClause) {
String commandString =
String.Format("select * from  {0} where {1}", TableName,whereClause);
Holder.FillData(commandString, TableName);
}
abstract public String TableName {get;}

class PersonGateway...

public override String TableName {
get {return  "Person";}
}

class DataSetHolder...

public void FillData(String query, String tableName) {
if (DataAdapters.Contains(tableName)) throw new MutlipleLoadException();
OleDbDataAdapter da = new OleDbDataAdapter(query, DB.Connection);
OleDbCommandBuilder builder = new OleDbCommandBuilder(da);
da.Fill(Data, tableName);
DataAdapters.Add(tableName, da);
}

To update data you manipulate the data set directly in some client code.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode29)

person.LoadAll();
person[key]["lastname"] = "Odell";
person.Holder.Update();

The gateway can have an indexer to make it easier to get to specific rows.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode30)

class DataGateway...

public DataRow this[long key]  {
get {
String filter = String.Format("id = {0}", key);
return Table.Select(filter)[0];
}
}
public override DataTable Table {
get {return Data.Tables[TableName];}
}

The update triggers update behavior on the holder.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode31)

class DataSetHolder...

public void Update() {
foreach (String table in DataAdapters.Keys)
((OleDbDataAdapter)DataAdapters[table]).Update(Data, table);
}
public DataTable this[String tableName]  {
get {return Data.Tables[tableName];}
}

Insertion can be done much the same way: Get a data set, insert a new row in the data table, and fill in each column. However, an update method can do the insertion in one call.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode32)

class DataGateway...

public long Insert(String lastName, String firstname, int numberOfDependents) {
long key = new PersonGatewayDS().GetNextID();
DataRow newRow = Table.NewRow();
newRow["id"] = key;
newRow["lastName"] = lastName;
newRow["firstName"] = firstname;
newRow["numberOfDependents"] = numberOfDependents;
Table.Rows.Add(newRow);
return key;
}

### Row Data Gateway

*An object that acts as a [Gateway](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#ch18lev1sec1) ([466](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#page_466)) to a single record in a data source. There is one instance per row.*

![Image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:0321127420/files/graphics/10fig01b.jpg)

Embedding database access code in in-memory objects can leave you with a few disadvantages. For a start, if your in-memory objects have business logic of their own, adding the database manipulation code increases complexity. Testing is awkward too since, if your in-memory objects are tied to a database, tests are slower to run because of all the database access. You may have to access multiple databases with all those annoying little variations on their SQL.

A *Row Data Gateway* gives you objects that look exactly like the record in your record structure but can be accessed with the regular mechanisms of your programming language. All details of data source access are hidden behind this interface.

#### How It Works

A *Row Data Gateway* acts as an object that exactly mimics a single record, such as one database row. In it each column in the database becomes one field. The *Row Data Gateway* will usually do any type conversion from the data source types to the in-memory types, but this conversion is pretty simple. This pattern holds the data about a row so that a client can then access the *Row Data Gateway* directly. The gateway acts as a good interface for each row of data. This approach works particularly well for *[Transaction Scripts](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#ch09lev1sec1) ([110](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#page_110)).*

With a *Row Data Gateway* you’re faced with the questions of where to put the find operations that generate this pattern. You can use static find methods, but they preclude polymorphism should you want to substitute different finder methods for different data sources. In this case it often makes sense to have separate finder objects so that each table in a relational database will have one finder class and one gateway class for the results ([Figure 10.2](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#ch10fig02)).

![Image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:0321127420/files/graphics/10fig02.jpg)

Figure 10.2. Interactions for a find with a row-based *Row Data Gateway*.

It’s often hard to tell the difference between a *Row Data Gateway* and an *[Active Record](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#ch10lev1sec3) ([160](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#page_160)).* The crux of the matter is whether there’s any domain logic present; if there is, you have an *[Active Record](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#ch10lev1sec3) ([160](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#page_160)).* A *Row Data Gateway* should contain only database access logic and no domain logic.

As with any other form of tabular encapsulation, you can use a *Row Data Gateway* with a view or query as well as a table. Updates often turn out to be more complicated this way, as you have to update the underlying tables. Also, if you have two *Row Data Gateways* that operate on the same underlying tables, you may find that the second *Row Data Gateway* you update undoes the changes on the first. There’s no general way to prevent this; developers just have to be aware of how virtual *Row Data Gateways* are formed. After all, the same thing can happen with updatable views. Of course, you can choose not to provide update operations.

*Row Data Gateways* tend to be somewhat tedious to write, but they’re a very good candidate for code generation based on a *[Metadata Mapping](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch13.html#ch13lev1sec1) ([306](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch13.html#page_306)).* This way all your database access code can be automatically built for you during your automated build process.

#### When to Use It

The choice of *Row Data Gateway* often takes two steps: first whether to use a gateway at all and second whether to use *Row Data Gateway* or *[Table Data Gateway](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#ch10lev1sec1) ([144](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#page_144)).*

I use *Row Data Gateway* most often when I’m using a *[Transaction Script](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#ch09lev1sec1) ([110](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#page_110)).* In this case it nicely factors out the database access code and allows it to be reused easily by different *[Transaction Scripts](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#ch09lev1sec1) ([110](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#page_110)).*

I don’t use a *Row Data Gateway* when I’m using a *[Domain Model](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#ch09lev1sec2) ([116](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#page_116)).* If the mapping is simple, *[Active Record](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#ch10lev1sec3) ([160](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#page_160))* does the same job without an additional layer of code. If the mapping is complex, *[Data Mapper](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#ch10lev1sec4) ([165](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#page_165))* works better, as it’s better at decoupling the data structure from the domain objects because the domain objects don’t need to know the layout of the database. Of course, you can use the *Row Data Gateway* to shield the domain objects from the database structure. That’s a good thing if you’re changing the database structure when using *Row Data Gateway* and you don’t want to change the domain logic. However, doing this on a large scale leads you to three data representations: one in the business logic, one in the *Row Data Gateway,* and one in the database—and that’s one too many. For that reason I usually have *Row Data Gateways* that mirror the database structure.

Interestingly, I’ve seen *Row Data Gateway* used very nicely with *[Data Mapper](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#ch10lev1sec4) ([165](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#page_165)).* Although this seems like extra work, it can be effective iff the *Row Data Gateways* are automatically generated from metadata while the *[Data Mappers](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#ch10lev1sec4) ([165](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#page_165))* are done by hand.

If you use *[Transaction Script](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#ch09lev1sec1) ([110](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#page_110))* with *Row Data Gateway,* you may notice that you have business logic that’s repeated across multiple scripts; logic that would make sense in the *Row Data Gateway.* Moving that logic will gradually turn your *Row Data Gateway* into an *[Active Record](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#ch10lev1sec3) ([160](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#page_160)),* which is often good as it reduces duplication in the business logic.

#### Example: A Person Record (Java)

Here’s an example for *Row Data Gateway*. It’s a simple person table.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode33)

create table people (ID int primary key, lastname varchar,
firstname varchar, number_of_dependents int)

PersonGateway is a gateway for the table. It starts with data fields and accessors.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode34)

class PersonGateway...

private String lastName;
private String firstName;
private int numberOfDependents;
public String getLastName() {
return lastName;
}
public void setLastName(String lastName) {
this.lastName = lastName;
}
public String getFirstName() {
return firstName;
}
public void setFirstName(String firstName) {
this.firstName = firstName;
}
public int getNumberOfDependents() {
return numberOfDependents;
}
public void setNumberOfDependents(int numberOfDependents) {
this.numberOfDependents = numberOfDependents;
}

The gateway class itself can handle updates and inserts.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode35)

class PersonGateway...

private static final String updateStatementString =
"UPDATE people " +
"  set lastname = ?, firstname = ?, number_of_dependents = ? " +
"  where id = ?";
public void update() {
PreparedStatement updateStatement = null;
try {
updateStatement = DB.prepare(updateStatementString);
updateStatement.setString(1, lastName);
updateStatement.setString(2, firstName);
updateStatement.setInt(3, numberOfDependents);
updateStatement.setInt(4, getID().intValue());
updateStatement.execute();
} catch (Exception e) {
throw new ApplicationException(e);
} finally {DB.cleanUp(updateStatement);
}
}
private static final String insertStatementString =
"INSERT INTO people VALUES (?, ?, ?, ?)";
public Long insert() {
PreparedStatement insertStatement = null;
try {
insertStatement = DB.prepare(insertStatementString);
setID(findNextDatabaseId());
insertStatement.setInt(1, getID().intValue());
insertStatement.setString(2, lastName);
insertStatement.setString(3, firstName);
insertStatement.setInt(4, numberOfDependents);
insertStatement.execute();
Registry.addPerson(this);
return getID();
} catch (SQLException e) {
throw new ApplicationException(e);
} finally {DB.cleanUp(insertStatement);
}
}

To pull people out of the database, we have a separate `PersonFinder`. This works with the gateway to create new gateway objects.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode36)

class PersonFinder...

private final static String findStatementString =
"SELECT id, lastname, firstname, number_of_dependents " +
"  from people " +
"  WHERE id = ?";
public PersonGateway find(Long id) {
PersonGateway result = (PersonGateway) Registry.getPerson(id);
if (result  != null) return result;
PreparedStatement findStatement = null;
ResultSet rs = null;
try {
findStatement = DB.prepare(findStatementString);
findStatement.setLong(1, id.longValue());
rs = findStatement.executeQuery();
rs.next();
result = PersonGateway.load(rs);
return result;
} catch (SQLException e) {
throw new ApplicationException(e);
} finally {DB.cleanUp(findStatement, rs);
}
}
public PersonGateway find(long id) {
return find(new Long(id));
}

class PersonGateway...

public static PersonGateway load(ResultSet rs) throws SQLException {
Long id = new Long(rs.getLong(1));
PersonGateway result = (PersonGateway) Registry.getPerson(id);
if (result  != null) return result;
String lastNameArg = rs.getString(2);
String firstNameArg = rs.getString(3);
int numDependentsArg = rs.getInt(4);
result = new PersonGateway(id, lastNameArg, firstNameArg, numDependentsArg);
Registry.addPerson(result);
return result;
}

To find more than one person according to some criteria we can provide a suitable finder method.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode37)

class PersonFinder...

private static final String findResponsibleStatement =
"SELECT id, lastname, firstname, number_of_dependents " +
"  from people " +
"  WHERE number_of_dependents > 0";
public List findResponsibles() {
List result = new ArrayList();
PreparedStatement stmt = null;
ResultSet rs = null;
try {
stmt = DB.prepare(findResponsibleStatement);
rs = stmt.executeQuery();
while (rs.next()) {
result.add(PersonGateway.load(rs));
}
return result;
} catch (SQLException e) {
throw new ApplicationException(e);
} finally {DB.cleanUp(stmt, rs);
}
}

The finder uses a *[Registry](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#ch18lev1sec5) ([480](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#page_480))* to hold *[Identity Maps](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#ch11lev1sec2) ([195](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#page_195)).*

We can now use the gateways from a *[Transaction Script](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#ch09lev1sec1) ([110](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#page_110))*

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode38)

PersonFinder finder = new PersonFinder();
Iterator people = finder.findResponsibles().iterator();
StringBuffer result = new StringBuffer();
while (people.hasNext()) {
PersonGateway each = (PersonGateway) people.next();
result.append(each.getLastName());
result.append("");
result.append(each.getFirstName());
result.append("");
result.append(String.valueOf(each.getNumberOfDependents()));
result.append("\n");

}
return result.toString();

#### Example: A Data Holder for a Domain Object (Java)

I use *Row Data Gateway* mostly with *[Transaction Script](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#ch09lev1sec1) ([110](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#page_110)).* If we want to use the *Row Data Gateway* from a *[Domain Model](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#ch09lev1sec2) ([116](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#page_116)),* the domain objects need to get at the data from the gateway. Instead of copying the data to the domain object we can use the *Row Data Gateway* as a data holder for the domain object.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode39)

class Person...

private PersonGateway data;
public Person(PersonGateway data) {
this.data = data;
}

Accessors on the domain logic can then delegate to the gateway for the data.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode40)

class Person...

public int getNumberOfDependents() {
return data.getNumberOfDependents();
}

The domain logic uses the getters to pull the data from the gateway.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode41)

class Person...

public Money getExemption() {
Money baseExemption = Money.dollars(1500);
Money dependentExemption = Money.dollars(750);
return baseExemption.add(dependentExemption.multiply(this.getNumberOfDependents()));
}

### Active Record

*An object that wraps a row in a database table or view, encapsulates the database access, and adds domain logic on that data.*

![Image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:0321127420/files/graphics/10fig02a.jpg)

An object carries both data and behavior. Much of this data is persistent and needs to be stored in a database. *Active Record* uses the most obvious approach, putting data access logic in the domain object. This way all people know how to read and write their data to and from the database.

#### How It Works

The essence of an *Active Record* is a *[Domain Model](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#ch09lev1sec2) ([116](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#page_116))* in which the classes match very closely the record structure of an underlying database. Each *Active Record* is responsible for saving and loading to the database and also for any domain logic that acts on the data. This may be all the domain logic in the application, or you may find that some domain logic is held in *[Transaction Scripts](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#ch09lev1sec1) ([110](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#page_110))* with common and data-oriented code in the *Active Record.*

The data structure of the *Active Record* should exactly match that of the database: one field in the class for each column in the table. Type the fields the way the SQL interface gives you the data—don’t do any conversion at this stage. You may consider *[Foreign Key Mapping](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch12.html#ch12lev1sec2) ([236](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch12.html#page_236)),* but you may also leave the foreign keys as they are. You can use views or tables with *Active Record,* although updates through views are obviously harder. Views are particularly useful for reporting purposes.

The *Active Record* class typically has methods that do the following:

• Construct an instance of the *Active Record* from a SQL result set row

• Construct a new instance for later insertion into the table

• Static finder methods to wrap commonly used SQL queries and return *Active Record* objects

• Update the database and insert into it the data in the *Active Record*

• Get and set the fields

• Implement some pieces of business logic

The getting and setting methods can do some other intelligent things, such as convert from SQL-oriented types to better in-memory types. Also, if you ask for a related table, the getting method can return the appropriate *Active Record,* even if you aren’t using *[Identity Field](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch12.html#ch12lev1sec1) ([216](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch12.html#page_216))* on the data structure (by doing a lookup).

In this pattern the classes are convenient, but they don’t hide the fact that a relational database is present. As a result you usually see fewer of the other object-relational mapping patterns present when you’re using *Active Record.*

*Active Record* is very similar to *[Row Data Gateway](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#ch10lev1sec2) ([152](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#page_152)).* The principal difference is that a *[Row Data Gateway](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#ch10lev1sec2) ([152](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#page_152))* contains only database access while an *Active Record* contains both data source and domain logic. Like most boundaries in software, the line between the two isn’t terribly sharp, but it’s useful.

Because of the close coupling between the *Active Record* and the database, I more often see static find methods in this pattern. However, there’s no reason that you can’t separate out the find methods into a separate class, as I discussed with *[Row Data Gateway](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#ch10lev1sec2) ([152](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#page_152)),* and that is better for testing.

As with the other tabular patterns, you can use *Active Record* with a view or query as well as a table.

#### When to Use It

*Active Record* is a good choice for domain logic that isn’t too complex, such as creates, reads, updates, and deletes. Derivations and validations based on a single record work well in this structure.

In an initial design for a *[Domain Model](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#ch09lev1sec2) ([116](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#page_116))* the main choice is between *Active Record* and *[Data Mapper](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#ch10lev1sec4) ([165](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#page_165)). Active Record* has the primary advantage of simplicity. It’s easy to build *Active Records,* and they are easy to understand. Their primary problem is that they work well only if the *Active Record* objects correspond directly to the database tables: an isomorphic schema. If your business logic is complex, you’ll soon want to use your object’s direct relationships, collections, inheritance, and so forth. These don’t map easily onto *Active Record,* and adding them piecemeal gets very messy. That’s what will lead you to use *[Data Mapper](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#ch10lev1sec4) ([165](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#page_165))* instead.

Another argument against *Active Record* is the fact that it couples the object design to the database design. This makes it more difficult to refactor either design as a project goes forward.

*Active Record* is a good pattern to consider if you’re using *[Transaction Script](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#ch09lev1sec1) ([110](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#page_110))* and are beginning to feel the pain of code duplication and the difficulty in updating scripts and tables that *[Transaction Script](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#ch09lev1sec1) ([110](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#page_110))* often brings. In this case you can gradually start creating *Active Records* and then slowly refactor behavior into them. It often helps to wrap the tables as a *[Gateway](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#ch18lev1sec1) ([466](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#page_466))* first, and then start moving behavior so that the tables evolve to a *Active Record.*

#### Example: A Simple Person (Java)

This is a simple, even simplistic, example to show how the bones of *Active Record* work. We begin with a basic Person class.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode42)

class Person...

private String lastName;
private String firstName;
private int numberOfDependents;

There’s also an ID field in the superclass.

The database is set up with the same structure.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode43)

create table people (ID int primary key, lastname varchar,
firstname varchar, number_of_dependents int)

To load an object, the person class acts as the finder and also performs the load. It uses static methods on the person class.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode44)

class Person...

private final static String findStatementString =
"SELECT id, lastname, firstname, number_of_dependents" +
"  FROM people" +
"  WHERE id = ?";
public static Person find(Long id) {
Person result = (Person) Registry.getPerson(id);
if (result  != null) return result;
PreparedStatement findStatement = null;
ResultSet rs = null;
try {
findStatement = DB.prepare(findStatementString);
findStatement.setLong(1, id.longValue());
rs = findStatement.executeQuery();
rs.next();
result = load(rs);
return result;
} catch (SQLException e) {
throw new ApplicationException(e);
} finally {
DB.cleanUp(findStatement, rs);
}
}
public static Person find(long id) {
return find(new Long(id));
}
public static Person load(ResultSet rs) throws SQLException {
Long id = new Long(rs.getLong(1));
Person result = (Person) Registry.getPerson(id);
if (result  != null) return result;
String lastNameArg = rs.getString(2);
String firstNameArg = rs.getString(3);
int numDependentsArg = rs.getInt(4);
result = new Person(id, lastNameArg, firstNameArg, numDependentsArg);
Registry.addPerson(result);
return result;
}

Updating an object takes a simple instance method.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode45)

class Person...

private final static String updateStatementString =
"UPDATE people" +
"  set lastname = ?, firstname = ?, number_of_dependents = ?" +
"  where id = ?";
public void update() {
PreparedStatement updateStatement = null;
try {
updateStatement = DB.prepare(updateStatementString);
updateStatement.setString(1, lastName);
updateStatement.setString(2, firstName);
updateStatement.setInt(3, numberOfDependents);
updateStatement.setInt(4, getID().intValue());
updateStatement.execute();
} catch (Exception e) {
throw new ApplicationException(e);
} finally {
DB.cleanUp(updateStatement);
}
}

Insertions are also mostly pretty simple.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode46)

class Person...

private final static String insertStatementString =
"INSERT INTO people VALUES (?, ?, ?, ?)";
public Long insert() {
PreparedStatement insertStatement = null;
try {
insertStatement = DB.prepare(insertStatementString);
setID(findNextDatabaseId());
insertStatement.setInt(1, getID().intValue());
insertStatement.setString(2, lastName);
insertStatement.setString(3, firstName);
insertStatement.setInt(4, numberOfDependents);
insertStatement.execute();
Registry.addPerson(this);
return getID();
} catch (Exception e) {
throw new ApplicationException(e);
} finally {
DB.cleanUp(insertStatement);
}
}

Any business logic, such as calculating the exemption, sits directly in the Person class.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode47)

class Person...

public Money getExemption() {
Money baseExemption = Money.dollars(1500);
Money dependentExemption = Money.dollars(750);
return baseExemption.add(dependentExemption.multiply(this.getNumberOfDependents()));
}

### Data Mapper

*A layer of [Mappers](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#ch18lev1sec2) ([473](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#page_473)) that moves data between objects and a database while keeping them independent of each other and the mapper itself.*

![Image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:0321127420/files/graphics/10fig02b.jpg)

Objects and relational databases have different mechanisms for structuring data. Many parts of an object, such as collections and inheritance, aren’t present in relational databases. When you build an object model with a lot of business logic it’s valuable to use these mechanisms to better organize the data and the behavior that goes with it. Doing so leads to variant schemas; that is, the object schema and the relational schema don’t match up.

You still need to transfer data between the two schemas, and this data transfer becomes a complexity in its own right. If the in-memory objects know about the relational database structure, changes in one tend to ripple to the other.

The *Data Mapper* is a layer of software that separates the in-memory objects from the database. Its responsibility is to transfer data between the two and also to isolate them from each other. With *Data Mapper* the in-memory objects needn’t know even that there’s a database present; they need no SQL interface code, and certainly no knowledge of the database schema. (The database schema is always ignorant of the objects that use it.) Since it’s a form of *[Mapper](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#ch18lev1sec2) ([473](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#page_473)), Data Mapper* itself is even unknown to the domain layer.

#### How It Works

The separation between domain and data source is the main function of a *Data Mapper,* but there are plenty of details that have to be addressed to make this happen. There’s also a lot of variety in how mapping layers are built. Many of the comments here are pretty broad, because I try to give a general overview of what you need to separate the cat from its skin.

We’ll start with a very basic *Data Mapper* example. This is the simplest style of this layer that you can have and might not seem worth doing. With simple database mapping examples other patterns usually are simpler and thus better. If you are going to use *Data Mapper* at all you usually need more complicated cases. However, it’s easier to explain the ideas if we start simple at a very basic level.

A simple case would have a Person and Person Mapper class. To load a person from the database, a client would call a find method on the mapper ([Figure 10.3](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#ch10fig03)). The mapper uses an *[Identity Map](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#ch11lev1sec2) ([195](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#page_195))* to see if the person is already loaded; if not, it loads it.

![Image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:0321127420/files/graphics/10fig03.jpg)

Figure 10.3. Retrieving data from a database.

Updates are shown in [Figure 10.4](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#ch10fig04). A client asks the mapper to save a domain object. The mapper pulls the data out of the domain object and shuttles it to the database.

![Image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:0321127420/files/graphics/10fig04.jpg)

Figure 10.4. Updating data.

The whole layer of *Data Mapper* can be substituted, either for testing purposes or to allow a single domain layer to work with different databases.

A simple *Data Mapper* would just map a database table to an equivalent in-memory class on a field-to-field basis. Of course, things aren’t usually simple. Mappers need a variety of strategies to handle classes that turn into multiple fields, classes that have multiple tables, classes with inheritance, and the joys of connecting together objects once they’ve been sorted out. The various object-relational mapping patterns in this book are all about that. It’s usually easier to deploy these patterns with a *Data Mapper* than it is with the other organizing alternatives.

When it comes to inserts and updates, the database mapping layer needs to understand what objects have changed, which new ones have been created, and which ones have been destroyed. It also has to fit the whole workload into a transactional framework. The *[Unit of Work](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#ch11lev1sec1) ([184](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#page_184))* pattern is a good way to organize this.

[Figure 10.3](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#ch10fig03) suggests that a single request to a find method results in a single SQL query. This isn’t always true. Loading a typical order with multiple order lines may involve loading the order lines as well. The request from the client will usually lead to a graph of objects being loaded, with the mapper designer deciding exactly how much to pull back in one go. The point of this is to minimize database queries, so the finders typically need to know a fair bit about how clients use the objects in order to make the best choices for pulling data back.

This example leads to cases where you load multiple classes of domain objects from a single query. If you want to load orders and order lines, it will usually be faster to do a single query that joins the orders and order line tables. You then use the result set to load both the order and the order line instances ([page 243](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch12.html#page_243)).

Since objects are very interconnected, you usually have to stop pulling the data back at some point. Otherwise, you’re likely to pull back the entire database with a request. Again, mapping layers have techniques to deal with this while minimizing the impact on the in-memory objects, using *[Lazy Load](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#ch11lev1sec3) ([200](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#page_200)).* Hence, the in-memory objects can’t be entirely ignorant of the mapping layer. They may need to know about the finders and a few other mechanisms.

An application can have one *Data Mapper* or several. If you’re hardcoding your mappers, it’s best to use one for each domain class or root of a domain hierarchy. If you’re using *[Metadata Mapping](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch13.html#ch13lev1sec1) ([306](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch13.html#page_306)),* you can get away with a single mapper class. In the latter case the limiting problem is your find methods. With a large application it can be too much to have a single mapper with lots of find methods, so it makes sense to split these methods up by each domain class or head of the domain hierarchy. You get a lot of small finder classes, but it’s easy for a developer to locate the finder she needs.

As with any database find behavior, the finders need to use an *[Identity Map](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#ch11lev1sec2) ([195](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#page_195))* in order to maintain the identity of the objects read from the database. Either you can have a *[Registry](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#ch18lev1sec5) ([480](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#page_480))* of *[Identity Maps](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#ch11lev1sec2) ([195](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#page_195)),* or you can have each finder hold an *[Identity Map](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#ch11lev1sec2) ([195](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#page_195))* (providing there is only one finder per class per session).

##### Handling Finders

In order to work with an object, you have to load it from the database. Usually the presentation layer will initiate things by loading some initial objects. Then control moves into the domain layer, at which point the code will mainly move from object to object using associations between them. This will work effectively providing that the domain layer has all the objects it needs loaded into memory or that you use *[Lazy Load](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#ch11lev1sec3) ([200](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#page_200))* to load in additional objects when needed.

On occasion you may need the domain objects to invoke find methods on the *Data Mapper.* However, I’ve found that with a good *[Lazy Load](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#ch11lev1sec3) ([200](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#page_200))* you can completely avoid this. For simpler applications, though, may not be worth trying to manage everything with associations and *[Lazy Load](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#ch11lev1sec3) ([200](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#page_200)).* Still, you don’t want to add a dependency from your domain objects to your *Data Mapper.*

You can solve this dilemma by using *[Separated Interface](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#ch18lev1sec4) ([476](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#page_476)).* Put any find methods needed by the domain code into an interface class that you can place in the domain package.

##### Mapping Data to Domain Fields

Mappers need access to the fields in the domain objects. Often this can be a problem because you need public methods to support the mappers you don’t want for domain logic. (I’m assuming that you won’t commit the cardinal sin of making fields public.) There’s no easy to answer to this. You could use a lower level of visibility by packaging the mappers closer to the domain objects, such as in the same package in Java, but this confuses the bigger dependency picture because you don’t want other parts of the system that know the domain objects to know about the mappers. You can use reflection, which can often bypass the visibility rules of the language. It’s slower, but the slower speed may end up as just a rounding error compared to the time taken by the SQL call. Or you can use public methods, but guard them with a status field so that they throw an exception if they’re used outside the context of a database load. If so, name them in such a way that they’re not mistaken for regular getters and setters.

Tied to this is the issue of when you create the object. In essence you have two options. One is to create the object with a **rich constructor** so that it’s at least created with all its mandatory data. The other is to create an empty object and then populate it with the mandatory data. I usually prefer the former since it’s nice to have a well-formed object from the start. This also means that, if you have an immutable field, you can enforce it by not providing any method to change its value.

The problem with a rich constructor is that you have to be aware of cyclic references. If you have two objects that reference each other, each time you try to load one it will try to load the other, which will in turn try to load the first one, and so on, until you run out of stack space. Avoiding this requires special case code, often using *[Lazy Load](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#ch11lev1sec3) ([200](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#page_200)).* Writing this special case code is messy, so it’s worth trying to do without it. You can do this by creating an **empty object.** Use a no-arg constructor to create a blank object and insert that empty object immediately into the *[Identity Map](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#ch11lev1sec2) ([195](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#page_195)).* That way, if you have a cycle, the *[Identity Map](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#ch11lev1sec2) ([195](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#page_195))* will return an object to stop the recursive loading.

Using an empty object like this means you may need some setters for values that are truly immutable when the object is loaded. A combination of a naming convention and perhaps some status-checking guards can fix this. You can also use reflection for data loading.

##### Metadata-Based Mappings

One of the decisions you need to make concerns storing the information about how fields in domain objects are mapped to columns in the database. The simplest, and often best, way to do this is with explicit code, which requires a mapper class for each domain object. The mapper does the mapping through assignments and has fields (usually constant strings) to store the SQL for database access. An alternative is to use *[Metadata Mapping](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch13.html#ch13lev1sec1) ([306](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch13.html#page_306)),* which stores the metadata as data, either in a class or in a separate file. The great advantage of metadata is that all the variation in the mappers can be handled through data without the need for more source code, either by use of code generation or reflective programming.

#### When to Use It

The primary occasion for using *Data Mapper* is when you want the database schema and the object model to evolve independently. The most common case for this is with a *[Domain Model](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#ch09lev1sec2) ([116](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#page_116)).* *Data Mapper’s* primary benefit is that when working on the domain model you can ignore the database, both in design and in the build and testing process. The domain objects have no idea what the database structure is, because all the correspondence is done by the mappers.

This helps you in the code because you can understand and work with the domain objects without having to understand how they’re stored in the database. You can modify the *[Domain Model](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#ch09lev1sec2) ([116](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#page_116))* or the database without having to alter either. With complicated mappings, particularly those involving existing databases, this is very valuable.

The price, of course, is the extra layer that you don’t get with *[Active Record](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#ch10lev1sec3) ([160](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#page_160)),* so the test for using these patterns is the complexity of the business logic. If you have fairly simple business logic, you probably won’t need a *[Domain Model](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#ch09lev1sec2) ([116](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#page_116))* or a *Data Mapper.* More complicated logic leads you to *[Domain Model](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#ch09lev1sec2) ([116](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#page_116))* and therefore to *Data Mapper.*

I wouldn’t choose *Data Mapper* without *[Domain Model](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#ch09lev1sec2) ([116](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#page_116)),* but can I use *[Domain Model](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#ch09lev1sec2) ([116](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch09.html#page_116))* without *Data Mapper?* If the domain model is pretty simple, and the database is under the domain model developers’ control, then it’s reasonable for the domain objects to access the database directly with *[Active Record](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#ch10lev1sec3) ([160](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#page_160)).* Effectively this puts the mapper behavior discussed here into the domain objects themselves. As things become more complicated, it’s better to refactor the database behavior out into a separate layer.

Remember that you don’t have to build a full-featured database-mapping layer. It’s a complicated beast to build, and there are products available that do this for you. For most cases I recommend buying a database-mapping layer rather than building one yourself.

#### Example: A Simple Database Mapper (Java)

Here’s an absurdly simple use of *Data Mapper* to give you a feel for the basic structure. Our example is a person with an isomorphic people table.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode48)

class Person...

private String lastName;
private String firstName;
private int numberOfDependents;

The database schema looks like this:

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode49)

create table people (ID int primary key, lastname varchar,
firstname varchar, number_of_dependents int)

We’ll use the simple case here, where the Person Mapper class also implements the finder and *[Identity Map](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#ch11lev1sec2) ([195](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#page_195)).* However, I’ve added an abstract mapper *[Layer Supertype](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#ch18lev1sec3) ([475](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#page_475))* to indicate where I can pull out some common behavior. Loading involves checking that the object isn’t already in the *[Identity Map](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#ch11lev1sec2) ([195](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#page_195))* and then pulling the data from the database.

The find behavior starts in the Person Mapper, which wraps calls to an abstract find method to find by ID.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode50)

class PersonMapper...

protected String findStatement() {
return "SELECT " + COLUMNS +
"  FROM people" +
"  WHERE id = ?";
}
public static final String COLUMNS = " id, lastname, firstname, number_of_dependents ";
public Person find(Long id) {
return (Person) abstractFind(id);
}
public Person find(long id) {
return find(new Long(id));
}
class AbstractMapper...

protected Map loadedMap = new HashMap();
abstract protected String findStatement();
protected DomainObject abstractFind(Long id) {
DomainObject result = (DomainObject) loadedMap.get(id);
if (result  != null) return result;
PreparedStatement findStatement = null;
try {
findStatement = DB.prepare(findStatement());
findStatement.setLong(1, id.longValue());
ResultSet rs = findStatement.executeQuery();
rs.next();
result = load(rs);
return result;
} catch (SQLException e) {
throw new ApplicationException(e);
} finally {
DB.cleanUp(findStatement);
}
}

The find method calls the load method, which is split between the abstract and person mappers. The abstract mapper checks the ID, pulling it from the data and registering the new object in the *[Identity Map](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#ch11lev1sec2) ([195](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#page_195)).*

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode51)

class AbstractMapper...

protected DomainObject load(ResultSet rs) throws SQLException {
Long id = new Long(rs.getLong(1));
if (loadedMap.containsKey(id)) return (DomainObject) loadedMap.get(id);
DomainObject result = doLoad(id, rs);
loadedMap.put(id, result);
return result;
}
abstract protected DomainObject doLoad(Long id, ResultSet rs) throws SQLException;

class PersonMapper...

protected DomainObject doLoad(Long id, ResultSet rs) throws SQLException {
String lastNameArg = rs.getString(2);
String firstNameArg = rs.getString(3);
int numDependentsArg = rs.getInt(4);
return new Person(id, lastNameArg, firstNameArg, numDependentsArg);
}

Notice that the *[Identity Map](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#ch11lev1sec2) ([195](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#page_195))* is checked twice, once by `abstractFind` and once by `load`. There’s a reason for this madness.

I need to check the map in the finder because, if the object is already there, I can save myself a trip to the database—I always want to save myself that long hike if I can. But I also need to check in the load because I may have queries that I can’t be sure of resolving in the *[Identity Map](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#ch11lev1sec2) ([195](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#page_195)).* Say I want to find everyone whose last name matches some search pattern. I can’t be sure that I have all such people already loaded, so I have to go to the database and run a query.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode52)

class PersonMapper...

private static String findLastNameStatement =
"SELECT " + COLUMNS +
"  FROM people " +
"  WHERE UPPER(lastname) like UPPER(?)" +
"  ORDER BY lastname";
public List findByLastName(String name) {
PreparedStatement stmt = null;
ResultSet rs = null;
try {
stmt = DB.prepare(findLastNameStatement);
stmt.setString(1, name);
rs = stmt.executeQuery();
return loadAll(rs);
} catch (SQLException e) {
throw new ApplicationException(e);
} finally {
DB.cleanUp(stmt, rs);
}
}

class AbstractMapper...

protected List loadAll(ResultSet rs) throws SQLException {
List result = new ArrayList();
while (rs.next())
result.add(load(rs));
return result;
}

When I do this I may pull back some rows in the result set that correspond to people I’ve already loaded. I have to ensure that I don’t make a duplicate, so I have to check the *[Identity Map](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#ch11lev1sec2) ([195](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#page_195))* again.

Writing a find method this way in each subclass that needs it involves some basic, but repetitive, coding, which I can eliminate by providing a general method.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode53)

class AbstractMapper...

public List findMany(StatementSource source) {
PreparedStatement stmt = null;
ResultSet rs = null;
try {
stmt = DB.prepare(source.sql());
for (int i = 0; i < source.parameters().length;  i++)
stmt.setObject(i+1, source.parameters()[i]);
rs = stmt.executeQuery();
return loadAll(rs);
} catch (SQLException e) {
throw new ApplicationException(e);
} finally {
DB.cleanUp(stmt, rs);
}
}

For this to work I need an interface that wraps both the SQL string and the loading of parameters into the prepared statement.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode54)

interface StatementSource...

String sql();
Object[] parameters();

I can then use this facility by providing a suitable implementation as an inner class.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode55)

class PersonMapper...

public List findByLastName2(String pattern) {
return findMany(new FindByLastName(pattern));
}
static class FindByLastName implements StatementSource {
private String lastName;
public FindByLastName(String lastName) {
this.lastName = lastName;
}
public String sql() {
return
"SELECT " + COLUMNS +
"  FROM people " +
"  WHERE UPPER(lastname) like UPPER(?)" +
"  ORDER BY lastname";
}
public Object[] parameters() {
Object[] result = {lastName};
return result;
}
}

This kind of work can be done in other places where there’s repetitive statement invocation code. On the whole I’ve made the examples here more straight to make them easier to follow. If you find yourself writing a lot of repetitive straight-ahead code you should consider doing something similar.

With the update the JDBC code is specific to the subtype.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode56)

class PersonMapper...

private static final String updateStatementString =
"UPDATE people " +
"  SET lastname = ?, firstname = ?, number_of_dependents = ? " +
"  WHERE id = ?";
public void update(Person subject) {
PreparedStatement updateStatement = null;
try {
updateStatement = DB.prepare(updateStatementString);
updateStatement.setString(1, subject.getLastName());
updateStatement.setString(2, subject.getFirstName());
updateStatement.setInt(3, subject.getNumberOfDependents());
updateStatement.setInt(4, subject.getID().intValue());
updateStatement.execute();
} catch (Exception e) {
throw new ApplicationException(e);
} finally {
DB.cleanUp(updateStatement);
}
}

For the insert some code can be factored into the *[Layer Supertype](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#ch18lev1sec3) ([475](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#page_475))*

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode57)

class AbstractMapper...

public Long insert(DomainObject subject) {
PreparedStatement insertStatement = null;
try {
insertStatement = DB.prepare(insertStatement());
subject.setID(findNextDatabaseId());
insertStatement.setInt(1, subject.getID().intValue());
doInsert(subject, insertStatement);
insertStatement.execute();
loadedMap.put(subject.getID(), subject);
return subject.getID();
} catch (SQLException e) {
throw new ApplicationException(e);
} finally {
DB.cleanUp(insertStatement);
}
}
abstract protected String insertStatement();
abstract protected void doInsert(DomainObject subject, PreparedStatement insertStatement)
throws SQLException;

class PersonMapper...

protected String insertStatement() {
return  "INSERT INTO people VALUES (?, ?, ?, ?)";
}
protected void doInsert(
DomainObject abstractSubject,
PreparedStatement stmt)
throws SQLException
{
Person subject = (Person) abstractSubject;
stmt.setString(2, subject.getLastName());
stmt.setString(3, subject.getFirstName());
stmt.setInt(4, subject.getNumberOfDependents());
}

#### Example: Separating the Finders (Java)

To allow domain objects to invoke finder behavior I can use *[Separated Interface](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#ch18lev1sec4) ([476](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#page_476))* to separate the finder interfaces from the mappers ([Figure 10.5](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch10.html#ch10fig05)). I can put these finder interfaces in a separate package that’s visible to the domain layer, or, as in this case, I can put them in the domain layer itself.

![Image](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:0321127420/files/graphics/10fig05.jpg)

Figure 10.5. Defining a finder interface in the domain package.

One of the most common finds is one that finds an object according to a particular surrogate ID. Much of this processing is quite generic, so it can be handled by a suitable *[Layer Supertype](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#ch18lev1sec3) ([475](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#page_475)).* All it needs is a *[Layer Supertype](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#ch18lev1sec3) ([475](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#page_475))* for domain objects that know about IDs.

The interface for finding lies in the finder interface. It’s usually best not made generic because you need to know what the return type is.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode58)

interface ArtistFinder...

Artist find(Long id);
Artist find(long id);

The finder interface is best declared in the domain package with the finders held in a *[Registry](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#ch18lev1sec5) ([480](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#page_480)).* In this case I’ve made the mapper class implement the finder interface.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode59)

class ArtistMapper implements ArtistFinder...

public Artist find(Long id) {
return (Artist) abstractFind(id);
}
public Artist find(long id) {
return find(new Long(id));
}

The bulk of the find method is done by the mapper’s *[Layer Supertype](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#ch18lev1sec3) ([475](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#page_475)),* which checks the *[Identity Map](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#ch11lev1sec2) ([195](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#page_195))* to see if the object is already in memory. If not, it completes a prepared statement that’s loaded in by the artist mapper and executes it.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode60)

class AbstractMapper...

abstract protected String findStatement();
protected Map loadedMap = new HashMap();
protected DomainObject abstractFind(Long id) {
DomainObject result = (DomainObject) loadedMap.get(id);
if (result  != null) return result;
PreparedStatement stmt = null;
ResultSet rs = null;
try {
stmt = DB.prepare(findStatement());
stmt.setLong(1, id.longValue());
rs = stmt.executeQuery();
rs.next();
result = load(rs);
return result;
} catch (SQLException e) {
throw new ApplicationException(e);
} finally {cleanUp(stmt, rs);
}
}

class ArtistMapper...

protected String findStatement() {
return  "select " + COLUMN_LIST + "  from artists art where ID = ?";
}
public static String COLUMN_LIST = "art.ID, art.name";

The find part of the behavior is about getting either the existing object or a new one. The load part is about putting the data from the database into a new object.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode61)

class AbstractMapper...

protected DomainObject load(ResultSet rs) throws SQLException {
Long id = new Long(rs.getLong("id"));
if (loadedMap.containsKey(id)) return (DomainObject) loadedMap.get(id);
DomainObject result = doLoad(id, rs);
loadedMap.put(id, result);
return result;
}
abstract protected DomainObject doLoad(Long id, ResultSet rs) throws SQLException;

class ArtistMapper...

protected DomainObject doLoad(Long id, ResultSet rs) throws SQLException {
String name = rs.getString("name");
Artist result = new Artist(id, name);
return result;
}

Notice that the load method also checks the *[Identity Map](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#ch11lev1sec2) ([195](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#page_195)).* Although redundant in this case, the load can be called by other finders that haven’t already done this check. In this scheme all a subclass has to do is develop a `doLoad` method to load the actual data needed, and return a suitable prepared statement from the `findStatement` method.

You can also do a find based on a query. Say we have a database of tracks and albums and we want a finder that will find all the tracks on a specified album. Again the interface declares the finders.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode62)

interface TrackFinder...

Track find(Long id);
Track find(long id);
List findForAlbum(Long albumID);

Since this is a specific find method for this class, it’s implemented in a specific class, such as the track mapper class, rather than in a *[Layer Supertype](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#ch18lev1sec3) ([475](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#page_475)).* As with any finder, there are two methods to the implementation. One sets up the prepared statement; the other wraps the call to the prepared statement and interprets the results.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode63)

class TrackMapper...

public static final String findForAlbumStatement =
"SELECT ID, seq, albumID, title " +
"FROM tracks " +
"WHERE albumID = ? ORDER  BY seq";
public List findForAlbum(Long albumID) {
PreparedStatement stmt = null;
ResultSet rs = null;
try {
stmt = DB.prepare(findForAlbumStatement);
stmt.setLong(1, albumID.longValue());
rs = stmt.executeQuery();
List result = new ArrayList();
while (rs.next())
result.add(load(rs));
return result;
} catch (SQLException e) {
throw new ApplicationException(e);
} finally {cleanUp(stmt, rs);
}
}

The finder calls a load method for each row in the result set. This method has the responsibility of creating the in-memory object and loading it with the data. As in the previous example, some of this can be handled in a *[Layer Supertype](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#ch18lev1sec3) ([475](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#page_475)),* including checking the *[Identity Map](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#ch11lev1sec2) ([195](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch11.html#page_195))* to see if something is already loaded.

#### Example: Creating an Empty Object (Java)

There are two basic approaches for loading an object. One is to create a fully valid object with a constructor, which is what I’ve done in the examples above. This results in the following loading code:

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode64)

class AbstractMapper...

protected DomainObject load(ResultSet rs) throws SQLException {
Long id = new Long(rs.getLong(1));
if (loadedMap.containsKey(id)) return (DomainObject) loadedMap.get(id);
DomainObject result = doLoad(id, rs);
loadedMap.put(id, result);
return result;
}
abstract protected DomainObject doLoad(Long id, ResultSet rs) throws SQLException;

class PersonMapper...

protected DomainObject doLoad(Long id, ResultSet rs) throws SQLException {
String lastNameArg = rs.getString(2);
String firstNameArg = rs.getString(3);
int numDependentsArg = rs.getInt(4);
return new Person(id, lastNameArg, firstNameArg, numDependentsArg);
}

The alternative is to create an empty object and load it with the setters later.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode65)

class AbstractMapper...

protected DomainObjectEL load(ResultSet rs) throws SQLException {
Long id = new Long(rs.getLong(1));
if (loadedMap.containsKey(id)) return (DomainObjectEL) loadedMap.get(id);
DomainObjectEL result = createDomainObject();
result.setID(id);
loadedMap.put(id, result);
doLoad (result, rs);
return result;
}
abstract protected DomainObjectEL createDomainObject();
abstract protected void doLoad(DomainObjectEL obj, ResultSet rs) throws SQLException;

class PersonMapper...

protected DomainObjectEL createDomainObject() {
return new Person();
}
protected void doLoad(DomainObjectEL obj, ResultSet rs) throws SQLException {
Person person = (Person) obj;
person.dbLoadLastName(rs.getString(2));
person.setFirstName(rs.getString(3));
person.setNumberOfDependents(rs.getInt(4));
}

Notice that I’m using a different kind of domain object *[Layer Supertype](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#ch18lev1sec3) ([475](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/ch18.html#page_475))* here, because I want to control the use of the setters. Let’s say that I want the last name of a person to be an immutable field. In this case I don’t want to change the value of the field once it’s loaded, so I add a status field to the domain object.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode66)

class DomainObjectEL...

private int state = LOADING;
private static final int LOADING = 0;
private static final int ACTIVE = 1;
public void beActive() {
state = ACTIVE;
}

I can then check the value of this during a load.

[Click here to view code image](https://learning.oreilly.com/library/view/patterns-of-enterprise/0321127420/images.html#icode67)

class Person...

public void dbLoadLastName(String lastName) {
assertStateIsLoading();
this.lastName = lastName;
}

class DomainObjectEL...

void assertStateIsLoading() {
Assert.isTrue(state == LOADING);
}

What I don’t like about this is that we now have a method in the interface that most clients of the Person class can’t use. This is an argument for the mapper using reflection to set the field, which will completely bypass Java’s protection mechanisms.

Is the status-based guard worth the trouble? I’m not entirely sure. On the one hand it will catch bugs caused by people calling update methods at the wrong time. On the other hand is the seriousness of the bugs worth the cost of the mechanism? At the moment I don’t have a strong opinion either way.
