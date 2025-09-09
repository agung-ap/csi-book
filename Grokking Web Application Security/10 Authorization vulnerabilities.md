# 10 Authorization vulnerabilities

### In this chapter

- How authorization is part of the domain logic of your application
- How to document authorization rules
- How to organize your URLs to keep authorization transparent
- How to check authorization at the code level
- How to catch common flaws in authorization

[](/book/grokking-web-application-security/chapter-10/)A typical quick-start guide for a web application covers a bunch of familiar topics: how to initialize the application, how to route URLs to particular classes or functions, how to read HTTP requests, how to write HTTP responses, how to render templates, how to use sessions, and often how to plug in an authentication system. The counterpart of *authentication* (identifying users when they interact with your application) is *authorization* (ensuring that users can access only the parts of the application they are permitted to access).

Implementing authorization correctly is equally as important as implementing authentication correctly when securing your application, but you will notice that the internet is short on good advice on how to build good authorization rules. That topic isn’t covered in most quick-start guides. I call this problem the draw-the-rest-of-the-owl problem: security advice is clear about the importance of implementing authorization correctly, but how to get there is left to the reader as an exercise.

[](/book/grokking-web-application-security/chapter-10/)There’s a good reason why authors are reluctant to offer concrete advice on how to build authorization correctly: authorization rules are part of the domain logic of your application. Formally, *domain logic* is the “core rules and processes that govern the behavior and operation of an application.” More intuitively, domain logic is the part of your web application that is different from everyone else’s web application.[](/book/grokking-web-application-security/chapter-10/)

Most web apps have similar session management, templating, database connection logic, and so on, but in between this generic code is the beating heart of the application: the domain logic, which is the part of your codebase that solves the specific needs of your users or customers.

Because domain logic is unique to each web application, the particular authorization rules that need to be coded into your application are also unique. Hence, internet authors can’t recommend any one-size-fits-all solution for authorization. That said, certain strategies for approaching authorization can keep things organized and help you protect yourself, and we will discuss them in this chapter.

## Modeling authorization

To make matters more concrete, let’s look at some common genres of web applications and make some simplified statements about what authorization rules they implement. These sketches will be helpful to keep in mind as we look at code samples illustrating how to implement authorization rules.[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)

### Case study 1: The web forum

Forums are among the oldest types of web applications, though increasingly, they have been absorbed into the megaforum we call Reddit. You can roughly sketch the authorization rules for Reddit as having three types of users: regular users, moderators, and administrators. These users have the following permissions:[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)

-  *Regular users*—These users can create posts and comments, as well as upvote and downvote comments. They can delete their own comments, but they can only view aggregate vote counts on other users’ posts and comments. They can report questionable posts or comments to admins, and they can send direct messages to other regular users.
-  *Moderators*—Moderators have the same privileges as regular users but can also delete posts or comments by other users, often in response to user reports. Moderators are responsible for creating and enforcing good-behavior policies in the subject areas—called *subreddits*—that they manage. Moderators can promote regular users to moderators on the subreddits they moderate.[](/book/grokking-web-application-security/chapter-10/)
-  *Administrators*—Reddit employs admins to keep the site usable. Admins can ban moderators and delete entire subreddits with questionable content.

### Case study 2: The content platform

The internet was originally designed to be a read-only platform for most users: publishers would put up websites, and the regular internet population would read the content. Nowadays, such static content is usually managed by some sort of content management system (CMS). Everything from blogging sites to the *New York Times* website is essentially a type of CMS. This model entails different roles for readers, writers, and editors:[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)

-  Readers can read any content that has been set to published status.
-  Writers have the same permissions as readers but can also submit content for publishing. Submitted content is set to unpublished status and viewable only by the writer who submitted it and by editors.
-  Editors have the same permissions as readers but can also view content in unpublished status. They can ask writers to make changes in unpublished content and can push content to published status when it is ready.

### Case study 3: The messaging tool

The modern internet is highly interactive, with no shortage of messaging tools and websites that incorporate a direct-messaging function. A typical messaging tool implies the following authorization rules:[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)

-  Users are discoverable in the application. They can make friend requests to other users and accept or deny requests from other users.
-  Users can send messages to, and receive messages from, users who are on their friend lists. Users can read messages sent by themselves or sent to them. They cannot read messages from conversations in which they are not participating.
-  If the tool supports group chat, users can start conversations with multiple other users at one time. Because some users may not be friends, group chats are usually initiated via an invitation, which each recipient can accept or reject.

## Designing authorization

The models of authorization described by the preceding case studies are much simpler than those that a real application would entail, of course. But even in these sketches, you should get a sense of how to clearly describe the authorization rules for an application at an abstract level: specify the categories of users and then define what they can and cannot do. The specifics of what those categories are and what permissions they entail differ by each application.[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)

Because authorization rules vary significantly among web applications, your team needs to agree on a shared vision of the rules. This agreement means coming up with some documentation outside the codebase that describes the correct behavior of the application. This document will necessarily be a living document because, as you add features to the application, new authorization considerations will come up.

Even small changes to authorization can have huge implications. Instagram wisely changed its authorization rules after a few embarrassed users noticed that their likes were public. Take time to think about how authorization rules influence your users’ experience. Good documentation helps clarify how authorization rules affect the user experience.

## Implementing access control

If you review the case studies described earlier, you will notice that many authorization rules come down to assigning each user a particular role and then defining the permissions that the role allows. The formal name for this system is *role-based access control* (RBAC).[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)

More granular authorization rules express the idea that users own particular resources on a web application. You own your emails in a webmail provider, for example, just as you own the content you post on social media (though often not in the legal sense; check the terms and conditions of the web application for clarity).

The idea that particular users have control of particular resources according to their attributes is called *attribute-based access control* (ABAC). In this framework, users or groups have policies applied dictating what actions they (the subject) can and cannot perform on a particular resource (the object), according to the attributes of either the subject or object. The framework allows for more granular setting of permissions defined between specific subjects and objects.[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)

##### DEFINITION

*Access control*, incidentally, is the umbrella term for authentication and authorization. You can’t enforce permissions until you know who your users are.[](/book/grokking-web-application-security/chapter-10/)

Most web applications implement a mix of RBAC and ABAC when verifying whether a user should be able to perform a particular action. RBAC defines the user category; ABAC defines the specific objects with which the user can interact. The ideas that these frameworks express are so intuitive to developers that we often employ them while writing web applications without formally naming them. Let’s look at some concrete ways in which these types of authorization checks are implemented in code.

### URL access restrictions

A large part of access control entails verifying that only suitably authorized users can access certain URLs—and in certain ways. (It’s common for `GET` and `PUT`/`POST` requests to the same URL to require different levels of permission, for example.) You can implement these types of authorization checks in several ways, depending on which programming language and web server you are using.[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)

#### Dynamic routing tables

In web servers on which URL routes are determined dynamically at run time, one method of authorization is to ensure that users see only the URLs they are authorized to see. In Ruby on Rails, for example, the file `config/routes.rb` defines how URLs are routed to controllers, so you can define the list of available URLs dynamically by checking the user’s authentication status and role, as follows:[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)

```
Rails.application.routes.draw do
  unless is_authenticated?
    root 'static#home'
    get  'login',   to: 'authentication#login'
    post 'login',   to: 'authentication#login'
    get  'profile', to: redirect('/login')
  end
  
  if is_authenticated?
    root 'feed#home'
    get   'login',    to: redirect('/profile')
    get   'profile',  to: 'user#profile'
    post  'profile',  to: 'user#profile'
 
    if is_admin?
      get  'admin',  to: 'admin#home'
      put  'admin',  to: 'admin#home'
    end
  end
end
```

#### Decorators

Dynamic routing tables like those implemented in Rails are the exception rather than the rule. Most web servers define their URL patterns statically in configuration files or centralized routing code or by inferring them from the directory structure of the codebase. In these situations, it can be handy to use the *interceptor* pattern, which wraps each HTTP-handling function with an access-control check before the code is called.[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)

Some languages, such as Python and JavaScript, support *decorators* that allow you to add authorization checks seamlessly with a single declaration. Here’s how you might use a decorator to provide an authentication check in Python:

```
@authenticate
def profile_data():
  return jsonify(load_profile_data())
```

A *decorator* is a function that is invoked before the function it decorates and that can intercept the function call if necessary. Here is the code that lies behind the `@authenticate` function, which raises an exception in the HTTP-handling code if a valid authorization token is not supplied:

```
def authenticate(func):
  @wraps(func)
  def wrapper(*args, **kwargs):
    auth_token = request.headers.get('Authorization')

    if not auth_token:
      return jsonify(
        { 'message':'Authorization token missing.' }
      ), 401

    if not validate_token(auth_token):
      return jsonify(
        {'message': 'Invalid authorization token.'}
      ), 401

      return func(*args, **kwargs)              #1

    return wrapper
```

Notice that the failure conditions in the decorator functions return HTTP status codes. We’ll see more on that topic later in this chapter.

#### Hooks

The interceptor pattern can be useful even if you choose not to use decorators or if your language of choice does not implement them. Many web servers offer *hooks*—a method of registering callback functions that should be called at particular stages in the web-request-handling workflow. Ruby on Rails uses this technique so frequently that code can appear to work almost by magic:[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)

```
class Post < ApplicationRecord
  before_action :authorize, only: [:edit_post] #1

  private

  def authorize                                #2
    unless current_user.admin? or current_user == user
      raise UnauthorizedError,
            "You are not authorized to perform this action."
    end
  end
end
#1 Tells Rails to invoke the authorize() method before calling the edit_post() method
#2 The authorize() function that checks permissions before edit_post() is invoked.
```

Some web frameworks allow you to register hooks in the request-response life cycle via configuration settings. The Java Servlet API implements the interceptor pattern by using the `javax.servlet.Filter` interface. Filters can be registered in the standard `web.xml` configuration file. Here, we add a filter to check administrative access for any path with the `/admin` prefix:[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)

```
<web-app version="4.0">
 <filter>
   <filter-name>AdminCheck</filter-name>
   <filter-class>com.example.RoleCheckFilter</filter-class>
   <init-param>
     <param-name>roleRequired</param-name>
     <param-value>admin</param-value>
   </init-param>
 </filter>

 <filter-mapping>
   <filter-name>AdminCheck</filter-name>
   <url-pattern>/admin/*</url-pattern>
 </filter-mapping>
</web-app>
```

Finally, don’t be afraid of rolling your own interceptor logic. Interceptors can be implemented in any language that supports passing functions as arguments to other functions. The following code snippet in Python succinctly chains authorization checks in a readable, unobtrusive fashion:

```
from flask import Flask

from example.auth_checks import authenticated, admin
from example.admin       import all_users_page
from example.users       import profile_page,
                                user_profile_page

app = Flask(__name__)

app.add_url_rule('/user',
                 authenticated(own_profile_page))
app.add_url_rule('/user/<user>',
                 authenticated(user_profile_page))
app.add_url_rule('/admin/users',
                 admin(authenticated(all_users_page)))
```

#### if statements

Dynamic routing tables, decorators, interceptors, and filters are convenient for externalizing authorization checks from the rest of your domain logic. But you will probably implant authorization checks within your URL-handling functions much of the time, particularly for ABAC checks, in which you have to load some object into memory before verifying whether a user can access it:[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)

```
class Post < ApplicationRecord
 def edit_post
   if self.post.user != current_user
     raise UnauthorizedError,
           "You are not permitted to edit this post!"
   end
   
   apply_edits
 end
end
```

### Authorization errors versus redirects

When an access-control check fails, you have several ways to write the HTTP response:[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)

-  With an HTTP `403 Forbidden` status code
-  With an HTTP `404 Not Found` status code
-  With an HTTP `302 Redirect` status code

All these responses are valid, depending on the context. If a user is not yet logged in but attempts to access a page that is available only to authenticated users, for example, it’s appropriate to redirect them to the login page and pass the original URL in the query string:

```
def home():
  user = get_current_user()
  if user:
    return render_template('home.html', user=user)
  else:
    return redirect(url_for('login', next=request.url))
```

##### WARNING

Be careful to avoid the open-redirect vulnerability, which we discuss in chapter 14.

If a user attempts to access a resource that they are not authorized to view, but you want them to know that the resource exists, returning a `403 Forbidden` status code is appropriate. A user sees the following message in Google Docs, for example, if they click a link to a document to which they don’t have access.

[](/book/grokking-web-application-security/chapter-10/)

To prevent frustration in this situation, you should give the user some idea of why they can’t access a certain resource. Access-control systems are notorious for implementing `Computer Says No` messages without providing a justification, which is just plain rude.

Finally, some resources are so sensitive that you don’t want to acknowledge their existence to unauthorized users, so a `404 Not Found` response is appropriate. Administrative pages often fall into this category, typically responding with a `404` message whenever access checks fail. Even acknowledging a URL path like this one can leak sensitive information:[](/book/grokking-web-application-security/chapter-10/)

```
facebook.com/admin/business-plans/lets-burn-four-
 billion-dollars-building-the-metaverse
```

### URL scheme organization

Keeping your URL scheme logical and consistent will help greatly in implementing access-control checks. It’s difficult to refactor URLs after a web application is in active use—bookmarks and inbound links from Google, for example, will break—so it’s worthwhile to put some thought into your URL scheme up front.[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)

A cleanly designed URL schema might be constructed as follows: admin pages begin with an `/admin` path, URLs to be called from JavaScript begin with an `/api` path, and so on. This structure makes reviewing access controls at a glance straightforward. An administrative URL without an access-control check will stick out like a sore thumb.

### Model-View-Controller

Complex software applications often organize their components in separate components according to the *Model-View-Controller* (MVC) philosophy. This architecture is organized as follows:[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)

-  *Model*—The Model component encapsulates the application’s data and domain logic. It is responsible for managing the application’s state, performing data validation, and implementing the application’s core functionality.
-  *View*—The View component is the user interface presented to the user—in a web application, the HTML templates and JavaScript that are sent to the browser.
-  *Controller*—Finally, the Controller acts as an intermediary between the two other components, interpreting input such as HTTP requests as actions to be performed on the Model and updating the View as state changes occur within the Model.

When you follow the MVC design philosophy, it’s best to implement authorization decisions within the Model component because that is where your domain logic resides. When you implement MVC in a web application, access-control checks raise custom exceptions, as in this snippet of Java code:

```
public class Post {
 public void edit(User user, String newContent) {
   if (!post.getAuthor().equals(user)) {
     throw new IllegalEditException(
       "You can only edit your own posts"
     );
   }

   post.setContent(newContent);
 }
}
```

Because the Model is downstream of the Controller component, the Controller that is responsible for converting authorization exceptions raised by the Model into the HTTP response codes:[](/book/grokking-web-application-security/chapter-10/)

```
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.TEXT_PLAIN)
public Response editPost(EditRequest changes) {
  try {
    User   user = this.getCurrentUser();
    Post   post = this.getPost(changes.getPostId());
    post.editPost(user, changes.getContent());
    post.save();
    return Response.ok("Post edited successfully!").build();
  }
  catch (IllegalEditException e) {
    return Response.status(Status.FORBIDDEN)
                   .entity(e.getMessage())
                   .build();
  }
}
```

Implementing MVC promotes loose coupling between the components, allowing for better code organization and reusability. Loose coupling of code greatly improves your ability to test your code’s functionality, as you will see later in this chapter.

##### TIP

For more suggestions on how to design code securely within the MVC paradigm, I strongly recommend reading *Secure by Design*, by Dan Bergh Johnsson, Daniel Deogun, and Daniel Sawano ([https://www.manning.com/books/secure-by-design](https://www.manning.com/books/secure-by-design)). This book will be the second-best security-book purchase you will ever make.[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)

### Client-side authorization

Many web applications are implemented with JavaScript UI frameworks that render the page in the browser. As well as writing directly to the DOM, frameworks like React and Angular can update the URL dynamically without a full-page refresh by using the HTML History API. The React Router package makes this task extremely concise:[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)

```
const router = createBrowserRouter([
 {
   path:         "/",
   element:      <Root />,
   errorElement: <ErrorPage />,
   loader:       rootLoader,
   action:       rootAction,
   children: [
     { path:    "posts",         element: <Feed />    },
     { path:    "posts/:post",   element: <Post />    },
     { path:    "profile",       element: <Profile /> },
     { path:    "profile/:user", element: <Profile /> },
   ],
 },
]);
```

You *should* restrict URLs with access-control checks in your JavaScript code—keeping admin pages only for admins and so on—but you can’t rely on these client-side checks in isolation to keep your application secure. An attacker can easily modify any JavaScript code executed in the browser.

Most pages that perform client-side rendering use the JavaScript Fetch API to populate the state of a page when it is rendered. Every server-side endpoint that responds to these requests must perform its own access checks because an attacker is not likely to tamper with this part of the application.

### Time-boxed authorization

Some resources in a web application are available only for certain periods. I’m not talking about those weird US government websites that have opening hours. Sometimes, content is available for a trial period or until a subscription runs out. Access-control rules need to account for these restrictions. Remember the time dimension when documenting and implementing authorization rules![](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)

For certain types of financial applications, time-boxed authorization is vitally important. Websites that release financial information on behalf of public companies, such as quarterly financial reports, are required by law to make this information available to everyone simultaneously to prevent insider trading. Such reports are prepared in advance and usually stored in a secure document management system. They need to be available only after their approved release time has passed.

## Testing authorization

Every programmer makes mistakes when writing code; bugs in authorization are easy to make and can be difficult to detect. Automated code-scanning tools can tell you about potential cross-site scripting (XSS) and injection attacks, but because access control is inherently unique to an application, automated tools can’t help much.[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)

A dedicated *quality analysis* (QA) team can be a great help in verifying domain logic as long as your organization is large enough to employ dedicated testing staff. A good QA team will be thorough about finding obscure bugs in your access control, as well as forcing you to define the correct behavior of your application in ambiguous situations.[](/book/grokking-web-application-security/chapter-10/)

If you don’t have a dedicated QA team, the burden falls on you and your fellow developers to audit the code critically. Code reviews can help catch errors early. Even walking away from the keyboard and coming back with a fresh pair of eyes can provide enough distance from your code to help you spot any errors you may have implemented.

When testing your authorization code, refer to your original design documents. Testing access-control rules means verifying that the actual behavior of the application matches the described behavior of the application. Cross-referencing your tests to your design documents will produce a virtuous feedback loop; when an ambiguous scenario arises in the course of testing, the correct behavior can be defined in the design document and then implemented in the code.

### Unit tests

Bugs discovered early in the development life cycle are much easier to fix than bugs discovered later. Because bugs in authorization are critical, you should test as much of your access-control scheme with automated tests as you can.[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)

If your application strictly follows the MVC philosophy, the separation of concerns makes writing unit tests for authorization easy. In Java or .NET applications, it’s common to see unit tests that look like the following example:

```
public void testIllegalEdit() {
 User author    = new User(1, "theAuthor");
 Post post      = new Post(author, "Initial content");
 User otherUser = new User(2, "notTheAuthor");
 
 Assertions.assertThrows(IllegalEditException.class, () -> {
   post.edit(otherUser, "Updated content");
 });
}
```

### Mocking libraries

If your web application is less strict about separating concerns, you have to be a bit more clever about your authorization unit tests. It’s not atypical to see functions like the following in Python web apps:[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)

```
@app.route('/post/<int:post_id>', methods=['PUT'])
def edit_post(post_id):
   data        = request.get_json()
   new_title   = data.get('title')
   new_content = data.get('content')

   post = db.get_post(post_id)

   if not post:
     abort(404, "Post not found.")

   if not current_user.can_edit(post):
     abort(401, "You do not have permission to edit this.")

   post.title   = new_title
   post.content = new_content

   # Save the changes to the database
   db.session.commit()

   return jsonify(message='Post updated successfully')
```

This type of mix of concerns in a single function—URL routing, authorization decisions, model logic, and database updates—would likely give your average Java programmer a headache, but it’s undeniably concise and readable. Testing this type of function requires the use of a *mocking library*—a code component that can replace various code objects (such as HTTP requests and database connections) with mock objects that respond in similar ways. This type of library allows a unit test to validate the correct behavior of code functions without making external network connections. (Your unit tests should not rely on external systems, however, because any scheduled or unscheduled downtime on those systems will leave your development team twiddling their thumbs.) The Python `mock` library provides a `patch()` decorator that allows you to write the following unit test for the preceding function:[](/book/grokking-web-application-security/chapter-10/)

```
@patch('app.db')
@patch('app.current_user')
def test_illegal_edit(self, db, current_user):
 current_user.return_value = User(
   id: 1, username: 'notTheAuthor'
 )

 db.get_post.return_value = Post(
   title:   'Original Title',
   content: 'Original Content',
   owner:   User(id: 2, username: 'theAuthor')
 )

 response = self.client.put('/post/1', json={
   'title'   : 'Updated Title',
   'content' : 'Updated content'
 })

 self.assertEqual(response.status_code, 401)

 db.session.commit.assert_not_called()
```

This code mocks out the database connection and the HTTP request and then verifies that the HTTP response is as expected.

## Spotting common authorization flaws

Authorization errors are easy to miss in testing, even with a disciplined development life cycle and well-documented rules. Here are some scenarios to watch out for.[](/book/grokking-web-application-security/chapter-10/)[](/book/grokking-web-application-security/chapter-10/)

### Missing access control

The hardest bugs to detect are those caused by missing code. Try to ensure good unit test coverage for privileged or sensitive actions. In the course of writing those unit tests, it should become obvious where access-control checks are missing.[](/book/grokking-web-application-security/chapter-10/)

### Confusion about which code components enforce access control

Throughout this chapter, I’ve sketched a few ways to implement access controls: at the URL level, within your model objects, with interceptors, and so on. Each design choice is valid, but beware of mixing and matching too much. It’s easy but wrong to assume that authorization checks were performed in an upstream code component (perhaps managed by a different team) when an application has several moving parts.[](/book/grokking-web-application-security/chapter-10/)

### Violations of trust boundaries

Web applications deal with two types of input: trusted and untrusted. Input coming from an HTTP request is *untrusted* until it is validated; input coming from, say, a database is generally *trusted* by default.[](/book/grokking-web-application-security/chapter-10/)

It’s important not to mix trusted and untrusted input in the same data structure. You should establish a *trust boundary* between the two types of input.[](/book/grokking-web-application-security/chapter-10/)

Violating trust boundaries frequently leads to incorrect access-control decisions. A common mistake is to keep unvalidated access claims in a session along with trusted data. Other code components (and other developers) using the data structure may not have the context to know that the access claim hasn’t been validated yet and will end up making authorization decisions based on untrusted input.[](/book/grokking-web-application-security/chapter-10/)

### Access-control decisions based on untrusted input

While we are discussing untrusted input, it’s important to note that authorization decisions should be made only on data that you know can’t be manipulated by an attacker. Access-control decisions based on unvalidated HTTP input can permit *vertical escalation* attacks, in which an attacker manipulates input to gain unwarranted privileges. Those types of decisions can also permit *horizontal escalation* attacks, in which an attacker changes their identity to that of another user who has a similar permission level.[](/book/grokking-web-application-security/chapter-10/)

## Summary

-  Recognize that authorization is part of the domain logic of your application, and produce a design document that describes that aspect of your application.
-  Implement access control by using RBAC and/or ABAC, according to the needs of your application.
-  Organize your URLs to keep authorization rules transparent and consistent. Consider implementing authorization controls at the URL level with dynamic routing tables, decorators, or interceptors.
-  Be explicit about how to respond to a failure of authorization in a particular URL: with a redirect, with a `403 Forbidden` error code, or with an HTTP `404 Not Found` error code. Each choice is appropriate depending on the context.
-  Client-side authorization checks are useful but must be backed up by server-side checks because an attacker can manipulate JavaScript in the browser.
-  If your application follows the MVC architecture, it’s cleaner to implement authorization checks in your model objects.
-  Test your access-control logic critically, preferably by using unit tests. Use a good mocking library if you need to use dummy HTTP requests and database connections.
-  Be consistent about how authorization decisions are made in your codebase. Confusion about which component is responsible for authorization often causes access-control bugs.
-  Don’t mix trusted and untrusted input in the same data structure.
-  Don’t make access-control decisions based on untrusted input that an attacker can manipulate.[](/book/grokking-web-application-security/chapter-10/)
