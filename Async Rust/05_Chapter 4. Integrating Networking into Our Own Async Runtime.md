# Chapter 4. Integrating Networking into
Our Own Async Runtime

In [Chapter 3](https://learning.oreilly.com/library/view/async-rust/9781098149086/ch03.html#ch03), we built our own async runtime queue to illustrate how async tasks run through an async runtime. However, we used only basic sleep and print operations. Focusing on simple operations is useful initially, but simple sleep and print functions are limiting. In this chapter, we build on the async runtime we defined previously and integrate networking protocols so they can run on our async runtime.

By the end of this chapter, you will be able to use traits to integrate the *hyper* crate for HTTP requests into our runtime. This means you will be able to take this example and integrate other third-party dependencies into our async runtime via traits after reading the documentation of that crate. Finally, we will go to a lower level by implementing the *mio* crate to directly poll sockets in our futures. This will show you how to utilize fine-grained control over the way the socket is polled, read, and written to in our async runtime. With this exposure and further external reading, you will be able to implement your own custom networking protocols.

This is the hardest chapter to follow, and it is not essential if you are not planning to integrate networking into a custom runtime. If you are not feeling it, feel free to skip this chapter and come back after reading the rest of the book. This content is placed in this chapter because it builds off the code written in [Chapter 3](https://learning.oreilly.com/library/view/async-rust/9781098149086/ch03.html#ch03).

Before we progress through the chapter, we need the following additional dependencies alongside the dependencies we used in [Chapter 3](https://learning.oreilly.com/library/view/async-rust/9781098149086/ch03.html#ch03):

```
[dependencies]
hyper = { version = "0.14.26",
features = ["http1", "http2", "client", "runtime"] }
smol = "1.3.0"
anyhow = "1.0.70"
async-native-tls = "0.5.0"
http = "0.2.9"
tokio = "1.14.0"
```

We are using these dependencies:

hyperThis crate is a fast and popular HTTP implementation. We are going to use this to make requests. We need the features `client` to allow us to make HTTP requests and `runtime` to allow compatibility with a custom async runtime.

smolThis crate is a small and fast async runtime. It is particularly good with lightweight tasks with low overhead.

anyhowThis crate is an error-handling library.

async-native-tlsThis crate provides asynchronous Transport Layer Security (TLS) support.

httpThis crate provides types for working with HTTP requests and their responses.

TokioWe used this crate before for demonstrating our async runtime and will use it again in this chapter.

As you can see, we are going to be using *hyper* for this example. This is to give you a different set of tools than those we used in previous examples and to demonstrate that tools like *Tokio* are layered in other commonly used libraries. Before we write any code, however, we must introduce executors and connectors.

# Understanding Executors and Connectors

An *executor* is responsible for running futures to completion. It is the part of the runtime that schedules tasks and makes sure they run (or are executed) when they are ready. We need an executor when we introduce networking into our runtime because without it, our futures such as HTTP requests would be created but never actually run.

A *connector* in networking is a component that establishes a connection between our application and the service we want to connect to. It handles activities like opening TCP connections and maintaining them through the lifetime of the request.

# Integrating hyper into Our Async Runtime

Now that you understand what executors and connectors are, let’s look at how these concepts are essential when integrating a library like *hyper* into our async runtime. Without an appropriate executor and connector, our runtime wouldn’t be able to handle the HTTP requests and connections that *hyper* relies on.

If we look at *hyper* official documentation or various online tutorials, we might get the impression that we can perform a simple GET request using the *hyper* crate with the following code:

```
use hyper::{Request, Client};

let url = "http://www.rust-lang.org";
let uri: Uri = url.parse().unwrap();

let request = Request::builder()
    .method("GET")
    .uri(uri)
    .header("User-Agent", "hyper/0.14.2")
    .header("Accept", "text/html")
    .body(hyper::Body::empty()).unwrap();

let future = async {
    let client = Client::new();
    client.request(request).await.unwrap()
};
let test = spawn_task!(future);
let response = future::block_on(test);
println!("Response status: {}", response.status());
```

However, if we run the tutorial code, we would get the following error:

```
thread '<unnamed>' panicked at 'there is no reactor
running, must be called from the context of a Tokio 1.x runtime
```

This is because under the hood, *hyper* by default runs on the *Tokio* runtime and no executor is specified in our code. If you were going to use the *reqwest* or other popular crates, chances are you will get a similar error.

To address the issue, we will create a custom executor that can handle our tasks within the custom async runtime we’ve built. Then we’ll build a custom connector to manage the actual network connections, allowing our runtime to seamlessly integrate with *hyper* and other similar libraries.

The first step is to import the following into our program:

```
use std::net::Shutdown;
use std::net::{TcpStream, ToSocketAddrs};
use std::pin::Pin;
use std::task::{Context, Poll};

use anyhow::{bail, Context as _, Error, Result};
use async_native_tls::TlsStream;
use http::Uri;
use hyper::{Body, Client, Request, Response};
use smol::{io, prelude::*, Async};
```

We can build our own executor as follows:

```
struct CustomExecutor;

impl<F: Future + Send + 'static> hyper::rt::Executor<F> for CustomExecutor {
    fn execute(&self, fut: F) {
        spawn_task!(async {
            println!("sending request");
            fut.await;
        }).detach();
    }
}
```

This code defines our custom executor and the behavior of the `execute` function. Inside this function, we call our `spawn_task` macro. Inside, we create an `async` block and `await` for the future that was passed into the `execute` function. We employ the `detach` function; otherwise, the channel will be closed, and we will not continue with our request because of the task moving out of scope and simply being dropped. As you may recall from [Chapter 3](https://learning.oreilly.com/library/view/async-rust/9781098149086/ch03.html#ch03), `detach` will send the pointer of the task to a loop to be polled until the task has finished, before dropping the task.

We now have a custom executor that we can pass into the *hyper* client. However, our *hyper* client will still fail to make the request because it is expecting the connection to be managed by the *Tokio* runtime. To fully integrate *hyper* with our custom async runtime, we need to build our own async connector that handles network connections independently of *Tokio*.

# Building an HTTP Connection

When it comes to networking requests, the protocols are well-defined and standardized. For instance, TCP has a three-step handshake to establish a connection before sending packets of bytes through that connection. Implementing the TCP connection from scratch has zero benefit unless you have very specific needs that the standardized connection protocols cannot provide. In [Figure 4-1](https://learning.oreilly.com/library/view/async-rust/9781098149086/ch04.html#fig0401), we can see that HTTP and HTTPS are application layer protocols running over a transport protocol such as TCP.

![networking protocol layers](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098149086/files/assets/asru_0401.png)

###### Figure 4-1. Networking protocol layers

With HTTP, we are sending over a body, header, and so forth. HTTPS has even more steps, as a certificate is checked and sent over to the client before the client starts sending over data. This is because the data needs to be encrypted. Considering all the back-and-forth in these protocols and waiting for responses, networking requests are a sensible target for async. We cannot get rid of the steps in networking without losing security and assurance that the connection is made. However, we can release the CPU from networking requests when waiting for responses with async.

For our connector, we are going to support HTTP and HTTPS, so we need the following enum:

```
enum CustomStream {
    Plain(Async<TcpStream>),
    Tls(TlsStream<Async<TcpStream>>),
}
```

The `Plain` variant is an async TCP stream. Considering [Figure 4-1](https://learning.oreilly.com/library/view/async-rust/9781098149086/ch04.html#fig0401), we can deduce that the `Plain` variant supports HTTP requests. With the `Tls` variant, we remember that HTTPS is merely a TLS layer between the TCP and the HTTP, which means that our `Tls` variant supports HTTPS.

We can now use this custom stream enum to implement the *hyper* `Service` trait for a custom connector struct:

```
#[derive(Clone)]
struct CustomConnector;

impl hyper::service::Service<Uri> for CustomConnector {
    type Response = CustomStream;
    type Error = Error;
    type Future = Pin<Box<dyn Future<Output = Result<
                            Self::Response, Self::Error>> + Send
                        >>;
    fn poll_ready(&mut self, _: &mut Context<'_>)
        -> Poll<Result<(), Self::Error>> {
        . . .
    }
    fn call(&mut self, uri: Uri) -> Self::Future {
        . . .
    }
}
```

The `Service` trait defines the future for the connection. Our connection is a thread-safe future that returns our stream enum. This enum is either an async TCP connection or an async TCP connection that is wrapped in a TLS stream.

We can also see that our `poll_ready` function just returns `Ready`. This function is used by *hyper* to check whether a service is ready to process requests. If we return `Pending`, the task will be polled until the service becomes ready. We return an error when the service can no longer process requests. Because we are using the `Service` trait for a client call, we will always return `Ready` for the `poll_ready`. If we were implementing the `Service` trait for a server, we could have the following `poll_ready` function:

```
fn poll_ready(&mut self, cx: &mut Context<'_>)
    -> Poll<Result<(), Error>> {
    Poll::Ready(Ok(()))
}
```

We can see that our `poll_ready` function returns that the future is ready. We could, ideally, not bother defining `poll_ready`, as our implementation makes calling it redundant. However, this function is a requirement for the `Service` trait.

We can now move on to the response function, which is `call`. The `poll_ready` function needs to return `Ok` before we can use `call`. Our `call` function has the following outline:

```
fn call(&mut self, uri: Uri) -> Self::Future {
    Box::pin(async move {
        let host = uri.host().context("cannot parse host")?;

        match uri.scheme_str() {
            Some("http") => {
                . . .
            }
            Some("https") => {
                . . .
            }
            scheme => bail!("unsupported scheme: {:?}", scheme),
        }
    })
}
```

We remember that the `pin` and `async` block returns a future. So, our pinned future will be the `async` block’s return statement. For our HTTPS block, we build a future with the following code:

```
let socket_addr = {
    let host = host.to_string();
    let port = uri.port_u16().unwrap_or(443);
    smol::unblock(move || (host.as_str(), port).to_socket_addrs())
        .await?
        .next()
        .context("cannot resolve address")?
};
let stream = Async::<TcpStream>::connect(socket_addr).await?;
let stream = async_native_tls::connect(host, stream).await?;
Ok(CustomStream::Tls(stream))
```

The port is 443 because this is the standard port for HTTPS. We then pass a closure into the `unblock` function. The closure returns the socket address. The `unblock` function runs blocking code on a thread pool so we can have the async interface on blocking code. While we are resolving the socket address, we can free up the thread to do something else. We connect our TCP stream and then connect it to our native TLS. Once our connection is achieved, we finally return the `CustomStream` enum.

When it comes to building our HTTP code, it is nearly the same. The port is 80 instead of 443, and the TLS connection is not required, resulting in returning `Ok(CustomStream::Plain(stream))`.

Our `call` function is now defined. However, if we try to make an HTTPS call to a website with our stream enum or connection struct at this point, we will get an error message stating that we have not implemented the `AsyncRead` and `AsyncWrite` *Tokio* traits for our stream trait. This is because *hyper* requires these traits to be implemented in order for our connection enum to be used.

# Implementing the Tokio AsyncRead Trait

The [AsyncRead trait](https://oreil.ly/Y2oLi) is similar to the `std::io::Read` trait but integrates with asynchronous task systems. When implementing our `AsyncRead` trait, we have to define only the `poll_read` function, which returns a `Poll` enum as a result. If we return `Poll::Ready`, we are saying that the data was immediately read and placed into the output buffer. If we return `Poll::Pending`, we are saying that no data was read into the buffer that we provided. We are also saying that the I/O object is not currently readable but may become readable in the future. The return of `Pending` results in the current future’s task being scheduled to be unparked when the object is readable. The final `Poll` enum variant that we can return is `Ready` but with an error that would usually be a standard I/O error.

Our implementation of the `AsyncRead` trait is defined in the code here:

```
impl tokio::io::AsyncRead for CustomStream {
    fn poll_read(
      mut self: Pin<&mut Self>,
        cx: &mut Context<'_>,
        buf: &mut tokio::io::ReadBuf<'_>,
    ) -> Poll<io::Result<()>> {
        match &mut *self {
            CustomStream::Plain(s) => {
                Pin::new(s)
                    .poll_read(cx, buf.initialize_unfilled())
                    .map_ok(|size| {
                        buf.advance(size);
                    })
            }
            CustomStream::Tls(s) => {
                Pin::new(s)
                    .poll_read(cx, buf.initialize_unfilled())
                    .map_ok(|size| {
                        buf.advance(size);
                    })
            }
        }
    }
}
```

Our other streams have essentially the same treatment; we pass in either the async TCP stream or an async TCP stream with TLS. We then pin this stream and execute the stream’s `poll_read` function, which performs a read and returns a `Poll` enum indicating how much the buffer grew because of the read. Once the `poll_read` is done, we execute `map_ok`, which takes in `FnOnce(T)`, which is either a function or a closure that can be called only once.

###### Note

In the context of `map_ok`, the closure’s purpose is to advance the buffer by the size returned from `poll_read`. This is a one-time operation for each read, and hence `FnOnce` is sufficient and preferred. If the closure needed to be called multiple times, `Fn` or `FnMut` would be required. By using `FnOnce`, we ensure that the closure can take ownership of the environment it captures, providing flexibility for what the closure can do. This is particularly useful in async programming, where ownership and lifetimes must be carefully managed.

The `map_ok` also references itself, which is the result from `poll_read`. If the `Poll` result is `Ready` but with an error, `Ready` with the error is returned. If the `Poll` result is `Pending`, `Pending` is returned. We pass the context into `poll_read` so a waker is used if we have a `Pending` result. If we have a `Ready` with an `Ok` result, the closure is called with the result from the `poll_read`, and `Ready` `Ok` is returned from the `map_ok` function. Our closure passed into our `map_ok` function advances the buffer.

A lot is going on under the hood, but essentially, our stream is pinned, a read is performed on the pinned stream, and if the read is successful, we advance the size of the buffer’s filled region because the read data is now in the buffer. The polling in `poll_read`, and the matching of the `Poll` enum in `map_ok`, enable this read process to be compatible with an async runtime.

So we can now read into our buffer asynchronously, but we also need to write asynchronously for our HTTP request to be complete.

# Implementing the Tokio AsyncWrite Trait

The `AsyncWrite` trait is similar to `std::io::Write` but interacts with asynchronous task systems. It write bytes asynchronously, and like the `AsyncRead` we just implemented, comes from *Tokio*.

When implementing the `AsyncWrite` trait, we need the following outline:

```
impl tokio::io::AsyncWrite for CustomStream {
    fn poll_write(
        mut self: Pin<&mut Self>,
        cx: &mut Context<'_>,
        buf: &[u8],
    ) -> Poll<io::Result<usize>> {
        . . .
    }
    fn poll_flush(mut self: Pin<&mut Self>, cx: &mut Context<'_>)
    -> Poll<io::Result<()>> {
        . . .
    }
    fn poll_shutdown(mut self: Pin<&mut Self>, cx: &mut Context<'_>)
    -> Poll<io::Result<()>> {
        . . .
    }
}
```

The `poll_write` function should not be a surprise, but note that we also have `poll_flush` and `poll_shutdown` functions. All the functions return a variant of the `Poll` enum and accept the context. Therefore, we can deduce that all functions are able to put the task to sleep to be woken again and to check whether the future is ready for shutting down, flushing, and writing to the connection.

We should start with our `poll_write` function:

```
match &mut *self {
    CustomStream::Plain(s) => Pin::new(s).poll_write(cx, buf),
    CustomStream::Tls(s) => Pin::new(s).poll_write(cx, buf),
}
```

We are matching the stream, pinning the stream, and executing the `poll_write` function of the stream. At this point in the chapter, it should not come as a surprise that `poll_write` tries to write bytes from the buffer into an object. Like the read, if the write is successful, the number of bytes written is returned. If the object is not ready for writing, we will get `Pending`; if we get `0`, this usually means that the object is no longer able to accept bytes.

Inside the `poll_write` function of the stream, a loop is executed and the mutable reference of the I/O handler is obtained. The loop then repeatedly tries to write to the underlying I/O until all the bytes from the buffer are written. Each write attempt has a result that is handled. If the error of the write is `io::ErrorKind::WouldBlock`, this means that the write could not complete immediately, and the loop repeats until the write is complete. If the result is any other error, the loop waits for the resource to be available again by returning `Pending` for the future to be polled again later.

Now that we have written `poll_write`, we can define the body of the `poll_flush` function:

```
match &mut *self {
    CustomStream::Plain(s) => Pin::new(s).poll_flush(cx),
    CustomStream::Tls(s) => Pin::new(s).poll_flush(cx),
}
```

This has the same outline as our `poll_write` function. However, in this case, we call `poll_flush` on our stream. A flush is like a write except we ensure that all the contents of the buffer immediately reach the destination. The underlying mechanism of the flush is exactly the same as the write with the loop, but the flush function will be called in the loop as opposed to the write function.

We can now move on to our final function, which is `shutdown`:

```
match &mut *self {
    CustomStream::Plain(s) => {
        s.get_ref().shutdown(Shutdown::Write)?;
        Poll::Ready(Ok(()))
    }
    CustomStream::Tls(s) => Pin::new(s).poll_close(cx),
}
```

The way we implement the different types of our custom stream varies slightly. The `Plain` stream is shut down directly. Once it is shut down, we return a `Poll` that is ready. However, the `Tls` stream is an async implementation by itself. Therefore, we need to pin it to avoid having it moved in memory, because it could be put on the task queue multiple times until the poll is complete. We call the `poll_close` function, which will return a poll result by itself.

We have now implemented our async read and write traits for our *hyper* client. All we need to do now is connect and run HTTP requests to test our implementation.

# Connecting and Running Our Client

In this section, we are wrapping up what we have done and testing it. We can create our connection request-sending function as follows:

```
impl hyper::client::connect::Connection for CustomStream {
    fn connected(&self) -> hyper::client::connect::Connected {
        hyper::client::connect::Connected::new()
    }
}

async fn fetch(req: Request<Body>) -> Result<Response<Body>> {
    Ok(Client::builder()
        .executor(CustomExecutor)
        .build::<_, Body>(CustomConnector)
        .request(req)
        .await?)
}
```

Now all we need to do is run our HTTP client on our async runtime in the `main` function:

```
fn main() {
    Runtime::new().with_low_num(2).with_high_num(4).run();

    let future  = async {
        let req = Request::get("https://www.rust-lang.org")
                                         .body(Body::empty())
                                         .unwrap();
        let response = fetch(req).await.unwrap();


        let body_bytes = hyper::body::to_bytes(response.into_body())
                         .await.unwrap();
        let html = String::from_utf8(body_bytes.to_vec()).unwrap();
        println!("{}", html);
    };
    let test = spawn_task!(future);
    let _outcome = future::block_on(test);
}
```

And here we have it: we can run our code to get the HTML code from the Rust website. We can now say that our async runtime can communicate with the internet asynchronously, but what about accepting requests? We already covered
implementing traits from other crates to get an async implementation. So let’s go one step lower and directly listen to events in sockets with the *mio* crate.

# Introducing mio

When it comes to implementing async functionality with sockets, we cannot really get any lower than *mio* (*metal I/O*) without directly calling the OS. This low-level, nonblocking I/O library in Rust provides the building blocks for creating high-performance async applications. It acts as a thin abstraction over the OS’s asynchronous I/O capabilities.

The *mio* crate is so crucial because it serves as a foundation for other higher-level async runtimes, including *Tokio*. These higher-level libraries abstract the complexity away to make them easier to work with. The *mio* crate is useful for developers who need fine-grained control over their I/O operations and want to optimize for performance. [Figure 4-2](https://learning.oreilly.com/library/view/async-rust/9781098149086/ch04.html#fig0402) shows how *Tokio* is built on *mio*.

![How Tokio builds on Mio](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781098149086/files/assets/asru_0402.png)

###### Figure 4-2. How Tokio builds on mio

Previously in this chapter, we connected *hyper* to our runtime. To get the full picture, we are now going to explore *mio* and integrate it in our runtime. Before we proceed, we need the following dependency in *Cargo.toml*:

```
mio = {version = "1.0.2", features = ["net", "os-poll"]}
```

We also need these imports:

```
use mio::net::{TcpListener, TcpStream};
use mio::{Events, Interest, Poll as MioPoll, Token};
use std::io::{Read, Write};
use std::time::Duration;
use std::error::Error;

use std::future::Future;
use std::pin::Pin;
use std::task::{Context, Poll};
```

# mio Versus hyper

Our exploration of *mio* in this chapter is not an optimal approach to creating a TCP server. If you want to create a production server, you should take an approach similar to this *hyper* example:

```
#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    let addr = SocketAddr::from(([127, 0, 0, 1], 3000));
    let listener = TcpListener::bind(addr).await?;
    loop {
        let (stream, _) = listener.accept().await?;
        let io = TokioIo::new(stream);
        tokio::task::spawn(async move {
            if let Err(err) = http1::Builder::new()
                .serve_connection(io, service_fn(hello))
                .await
            {
                println!("Error serving connection: {:?}", err);
            }
        });
    }
}
```

The main thread is waiting for incoming data, and when incoming data arrives, a new task is spawned to handle that data. This keeps the listener ready to accept more incoming data. While our *mio* examples will help you understand how polling TCP connections work, it is most sensible to use the listener that the framework or library gives you when building a web application. We will discuss some web concepts to give context to our example, but a comprehensive overview of web development is beyond the scope of this book.

Now that we have laid all the groundwork, we can move on to polling TCP sockets in futures.

## Polling Sockets in Futures

The *mio* crate is built for handling many sockets (thousands). Therefore, we need to identify which socket triggered the notification. Tokens enable us to do this. When we register a socket with the event loop, we pass it a token, and that token is returned in the handler. The token is a struct tuple around `usize`. This is because every OS allows a pointer amount of data to be associated with a socket. So in the handler we can have a mapping function where the token is the key, and we map it with a socket.

*mio* is not using callbacks here because we want a zero cost abstraction, and tokens are the only way of doing that. We can build callbacks, streams, and futures on top of *mio*.

With tokens, we now have the following steps:

1.

Register the sockets with the event loop.

1.

Wait for socket readiness.

1.

Look up the socket state by using the token.

1.

Operate on the socket.

1.

Repeat.

Our simple example negates the need for mapping, so we are going to define our tokens with the following code:

```
const SERVER: Token = Token(0);
const CLIENT: Token = Token(1);
```

Here, we just have to ensure that our tokens are unique. The integer passed into `Token` is used to differentiate it from other tokens. Now that we have our tokens, we define the future that is going to poll the socket:

```
struct ServerFuture {
    server: TcpListener,
    poll: MioPoll,
}
impl Future for ServerFuture {

    type Output = String;

    fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>)
        -> Poll<Self::Output> {
        . . .
    }
}
```

We are using `TcpListener` to accept incoming data and `MioPoll` to poll the socket and tell the future when the socket is readable. Inside our future `poll` function, we can define the events and poll the socket:

```
let mut events = Events::with_capacity(1);

let _ = self.poll.poll(
    &mut events,
    Some(Duration::from_millis(200))
).unwrap();


for event in events.iter() {
    . . .
}
cx.waker().wake_by_ref();
return Poll::Pending
```

The poll will extract the events from the socket into the events iterator. We also set the socket poll to time out after 200 ms. If there are no events in the socket, we proceed without any events and return `Pending`. We will continue polling until we get an event.

When we do get events, we loop through them. In the preceding code, we set the capacity to `1`, but we can increase the capacity to handle multiple events if needed. When processing an event, we need to clarify the event type. For our future, we need to ensure that the socket is readable and that the token is the `SERVER` token:

```
if event.token() == SERVER && event.is_readable() {
    let (mut stream, _) = self.server.accept().unwrap();
    let mut buffer = [0u8; 1024];
    let mut received_data = Vec::new();

    loop {
        . . .
    }
    if !received_data.is_empty() {
        let received_str = String::from_utf8_lossy(&received_data);
        return Poll::Ready(received_str.to_string())
    }
    cx.waker().wake_by_ref();
    return Poll::Pending
}
```

The event is readable if the socket contains data. If our event is the correct one, we extract `TcpStream` and define a `data_received` collection on the heap with `Vec`, using the buffer slice to perform the reads. If the data is empty, we return `Pending` so we can poll the socket again if the data is not there. We then convert the data to a string and return it with `Ready`. This means that our socket listener is finished after we have the data.

###### Note

If we wanted our socket to be continually polled throughout the lifetime of our program, we would spawn a detached task to pass the data into an async function to handle the data, as shown here:

```javascript
if !received_data.is_empty() {
    spawn_task!(some_async_handle_function(&received_data))
        .detach();
    return Poll::Pending;
}
```

In our loop, we read the data from the socket:

```
loop {
    match stream.read(&mut buffer) {
        Ok(n) if n > 0 => {
            received_data.extend_from_slice(&buffer[..n]);
        }
        Ok(_) => {
            break;
        }
        Err(e) => {
            eprintln!("Error reading from stream: {}", e);
            break;
        }
    }
}
```

It does not matter if the received message is bigger than the buffer; our loop will continue to extract all the bytes to be processed, adding them onto our `Vec`. If there are no more bytes, we can stop our loop to process the data.

We now have a future that will continue to be polled until it accepts data from a socket. After receiving the data, the future will terminate. We can also make this future continually poll the socket. We could argue that we could use this continual polling future to keep track of thousands of sockets if needed. We would have one socket per future and spawn thousands of futures into our runtime. Now that we have defined our `TcpListener` logic, we can move on to our client logic to send data over the socket to our future.

## Sending Data over the Socket

For our client, we are going to run everything in the `main` function:

```
fn main() -> Result<(), Box<dyn Error>> {
    Runtime::new().with_low_num(2).with_high_num(4).run();
    . . .
    Ok(())
}
```

In our `main`, we initially create our listener and our stream for the client:

```
let addr = "127.0.0.1:13265".parse()?;
let mut server = TcpListener::bind(addr)?;
let mut stream = TcpStream::connect(server.local_addr()?)?;
```

Our example requires just one stream, but we can create multiple streams if needed. We register our server with a *mio* poll and use the server and poll to spawn the listener task:

```
let poll: MioPoll = MioPoll::new()?;
poll.registry()
.register(&mut server, SERVER, Interest::READABLE)?;

let server_worker = ServerFuture{
    server,
    poll,
};
let test = spawn_task!(server_worker);
```

Now our task is continually polling the TCP port for incoming events. We then create another poll with the `CLIENT` token for writable events. If the socket is not full, we can write to it. If the socket is full, it is no longer writable and needs to be flushed. Our client poll takes the following form:

```
let mut client_poll: MioPoll = MioPoll::new()?;
client_poll.registry()
.register(&mut stream, CLIENT, Interest::WRITABLE)?;
```

###### Note

With *mio*, we can also create polls that can trigger if the socket is readable or writable:

```
.register(
	&mut server,
	SERVER,
	Interest::READABLE | Interest::WRITABLE
)?;
```

Now that we have created our poll, we can wait for the socket to become writable before writing to it. We use this poll call:

```
let mut events = Events::with_capacity(128);

let _ = client_poll.poll(
    &mut events,
    None
).unwrap();
```

Note that there is a `None` for the timeout. This means that our current thread will be blocked until an event is yielded by the poll call. Once we have the event, we send a simple message to the socket:

```
for event in events.iter() {
    if event.token() == CLIENT && event.is_writable() {
        let message = "that's so dingo!\n";
        let _ = stream.write_all(message.as_bytes());
    }
}
```

The message is sent, so we can block our thread and then print out the message:

```
let outcome = future::block_on(test);
println!("outcome: {}", outcome);
```

When running the code, you might get the following printout:

```
Error reading from stream: Resource temporarily unavailable (os error 35)
outcome: that's so dingo!
```

It works, but we get the initial error. This can be a result of nonblocking TCP listeners; *mio* is nonblocking. The `Resource temporarily unavailable` error is usually caused by no data being available in the socket. This can happen when the TCP stream is created, but it is not a problem because we handle these errors in our loop and are returning `Pending` so the socket continues to be polled, as shown here:

```
use std::io::ErrorKind;
. . .
Err(ref e) if e.kind() == ErrorKind::WouldBlock => {
    waker.cx.waker().wake_by_ref();
    return Poll::Pending;
}
```

###### Note

With the *mio* polling feature, we have implemented async communication through a TCP socket. We can also use *mio* to send data between processes via a `UnixDatagram`. `UnixDatagram`s are sockets that are restricted to sending data on the same machine. Because of this, `UnixDatagram`s are faster, require less context switching, and do not have to go through the network stack.

# Summary

We finally managed to get our async runtime to do something apart from sleep and print. In this chapter, we explored how traits can help us integrate third-party crates into our runtime, and we have gone lower to poll TCP sockets via *mio*. When it comes to getting a custom async runtime running, nothing else is standing in your way as long as you have access to trait documentation. If you want to get a better grip on the async knowledge you’ve gained so far, you are in the position to create a basic web server that handles various endpoints. Implementing all your communication in *mio* would be difficult,  but using it just for async programming is much easier. The *hyper* `HttpListener` will cover the protocol complexity so you can focus on passing the requests as async tasks and on the response to the client.

For our journey in this book, we are exploring async programming as opposed to web programming. Therefore, we are going to move on to how we implement async programming to solve specific problems. We start in [Chapter 5](https://learning.oreilly.com/library/view/async-rust/9781098149086/ch05.html#ch05) with coroutines.
