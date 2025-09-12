# Chapter 17. Cheap and Accurate Enough: Sampling

In the preceding chapter, we covered how a data store must be configured in order to efficiently store and retrieve large quantities of observability data. In this chapter, we’ll look at techniques for reducing the amount of observability data you may need to store. At a large enough scale, the resources necessary to retain and process every single event can become prohibitive and impractical. Sampling events can mitigate the trade-offs between resource consumption and data fidelity.

This chapter examines why sampling is useful (even at a smaller scale), the various strategies typically used to sample data, and trade-offs between those strategies. We use code-based examples to illustrate how these strategies are implemented and progressively introduce concepts that build upon previous examples. The chapter starts with simpler sampling schemes applied to single events as a conceptual introduction to using a statistical representation of data when sampling. We then build toward more complex sampling strategies as they are applied to a series of related events (trace spans) and propagate the information needed to reconstruct your data after sampling.

# Sampling to Refine Your Data Collection

Past a certain scale, the cost to collect, process, and save every log entry, every event, and every trace that your systems generate dramatically outweighs the benefits. At a large enough scale, it is simply not feasible to run an observability infrastructure that is the same size as your production infrastructure. When observability events quickly become a flood of data, the challenge pivots to a trade-off between scaling back the amount of data that’s kept and potentially losing the crucial information your engineering team needs to troubleshoot and understand your system’s production behaviors.

The reality of most applications is that many of their events are virtually identical and successful. The core function of debugging is searching for emergent patterns or examining failed events during an outage. Through that lens, it is then wasteful to transmit 100% of all events to your observability data backend. Certain events can be selected as representative examples of what occurred, and those sample events can be transmitted along with metadata your observability backend needs to reconstruct what actually occurred among the events that weren’t sampled.

To debug effectively, what’s needed is a representative sample of successful, or “good,” events, against which to compare the “bad” events. Using representative events to reconstruct your observability data enables you to reduce the overhead of transmitting every single event, while also faithfully recovering the original shape of that data. Sampling events can help you accomplish your observability goals at a fraction of the resource cost. It is a way to refine the observability process at scale.

Historically in the software industry, when facing resource constraints in reporting high-volume system state, the standard approach to surfacing the signal from the noise has been to generate aggregated metrics containing a limited number of tags. As covered in [Chapter 2](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch02.html#how_debugging_practices_differ_between), aggregated views of system state that cannot be decomposed are far too coarse to troubleshoot the needs of modern distributed systems. Pre-aggregating data before it arrives in your debugging tool means that you can’t dig further past the granularity of the aggregated values.

With observability, you can sample events by using the strategies outlined in this chapter and still provide granular visibility into system state. Sampling gives you the ability to decide which events are useful to transmit and which ones are not. Unlike pre-aggregated metrics that collapse all events into one coarse representation of system state over a given period of time, sampling allows you to make informed decisions about which events can help you surface unusual behavior, while still optimizing for resource constraints. The difference between sampled events and aggregated metrics is that full cardinality is preserved on each dimension included in the representative event.

At scale, the need to refine your data set to optimize for resource costs becomes critical. But even at a smaller scale, where the need to shave resources is less pressing, refining the data you decide to keep can still provide valuable cost savings. First, let’s start by looking at the strategies that can be used to decide which data is worth sampling. Then, we’ll look at when and how that decision can be made when handling trace events.

# Using Different Approaches to Sampling

Sampling is a common approach when solving for resource constraints. Unfortunately, the term *sampling* is used broadly as a one-size-fits-all label for the many types of approaches that might be implemented. Many concepts and implementations of sampling exist, some less effective for observability than others. We need to disambiguate the term by naming each sampling technique that is appropriate for observability and distinguishing how they are different, and similar, to one another.

## Constant-Probability Sampling

Because of its understandable and easy-to-implement approach, *constant-probability sampling* is what most people think of when they think of sampling: a constant percentage of data is kept rather than discarded (e.g., keep 1 out of every 10 requests).

When performing analysis of sampled data, you will need to transform the data to reconstruct the original distribution of requests. Suppose that your service is instrumented with both events and metrics, and receives 100,000 requests. It is misleading for your telemetry systems to report receiving only 100 events if each received event represents approximately 1,000 similar events. Other telemetry systems such as metrics will record increment a counter for each of the 100,000 requests that your service has received. Only a fraction of those requests will have been sampled, so your system will need to adjust the aggregation of events to return data that is approximately correct. For a fixed sampling rate system, you can multiply each event by the sampling rate in effect to get the estimated count of total requests and sum of their latency. Scalar distribution properties such as the p99 and median do not need to be adjusted for a constant probability sampling, as they are not distorted by the sampling process.

The basic idea of constant sampling is that, if you have enough volume, any error that comes up will happen again. If that error is happening enough to matter, you’ll see it. However, if you have a moderate volume of data, constant sampling does not maintain the statistical likelihood that you still see what you need to see. Constant sampling is not effective in the following circumstances:

- You care a lot about error cases and not very much about success cases.

- Some customers send orders of magnitude more traffic than others, and you want all customers to have a good experience.

- You want to ensure that a huge increase in traffic on your servers can’t overwhelm your analytics backend.

For an observable system, a more sophisticated approach ensures that enough telemetry data is captured and retained so that you can see into the true state of any given service at any given time.

## Sampling on Recent Traffic Volume

Instead of using a fixed probability, you can dynamically adjust the rate at which your system samples events. Sampling probability can be adjusted upward if less total traffic was received recently, or decreased if a traffic surge is likely to overwhelm the backend of your observability tool. However, this approach adds a new layer of complexity: without a constant sampling rate, you can no longer multiply out each event by a constant factor when reconstructing the distribution of your data.

Instead, your telemetry system will need to use a weighted algorithm that accounts for the sampling probability in effect at the time the event was collected. If one event represents 1,000 similar events, it should not be directly averaged with another event that represents 100 similar events. Thus, for calculating a count, your system must add together the number of *represented* events, not just the number of collected events. For aggregating distribution properties such as the median or p99, your system must expand each event into many when calculating the total number of events and where the percentile values lie.

For example, suppose you have pairs of values and sample rates: `[{1,5}, {3,2}, {7,9}]`. If you took the median of the values without taking the sample rate into account, you would naively get the value of 3 as a result—because it’s at the center of `[1,3,7]`. However, you must take the sample rate into account. Using the sample rate to reconstruct the entire set of values can be illustrated by writing out the entire set of values in long form: `[1,1,1,1,1,3,3,7,7,7,7,7,7,7,7,7]`. In that view, it becomes clear that the median of the values is 7 after accounting for sampling.

## Sampling Based on Event Content (Keys)

This dynamic sampling approach involves tuning the sample rate based on event payload. At a high level, that means choosing one or more fields in the set of events and designating a sample rate when a certain combination of values is seen. For example, you could partition events based on HTTP response codes and then assign sample rates to each response code. Doing that allows you to specify sampling conditions such as these:

- Events with *errors* are more important than those with *successes*.

- Events for *newly placed orders* are more important than those checking on *order status*.

- Events affecting *paying customers* are more important to keep than those for customers using the *free tier*.

With this approach, you can make the keys as simple (e.g., HTTP method) or complicated (e.g., concatenating the HTTP method, request size, and user-agent) as needed to select samples that can provide the most useful view into service traffic.

Sampling at a constant percentage rate based on event content alone works well when the key space is small (e.g., there are a finite number of HTTP methods: `GET`, `POST`, `HEAD`, etc.) *and* when the relative rates of given keys stay consistent (e.g., when you can assume errors are less frequent than successes). It’s worth noting that sometimes that assumption can be wrong, or it can be reversed in bad cases. For those situations, you should validate your assumptions and have a plan for dealing with event traffic spikes if the assumed conditions reverse.

## Combining per Key and Historical Methods

When the content of traffic is harder to predict, you can instead continue to identify a key (or combination of keys) for each incoming event, and then *also* dynamically adjust the sample rate for each key based on the volume of traffic recently seen for that key. For example, base the sample rate on the number of times a given key combination (such as [customer ID, dataset ID, error code]) is seen in the last 30 seconds. If a specific combination is seen many times in that time, it’s less interesting than combinations that are seen less often. A configuration like that allows proportionally fewer of the events to be propagated verbatim until that rate of traffic changes and it adjusts the sample rate again.

## Choosing Dynamic Sampling Options

To decide which sampling strategy to use, it helps to look at the traffic flowing through a service, as well as the variety of queries hitting that service. Are you dealing with a front-page app, and 90% of the requests hitting it are nearly indistinguishable from one another? The needs of that situation will differ substantially from dealing with a proxy fronting a database, where many query patterns are repeated.

A backend behind a read-through cache, where each request is mostly unique (with the cache already having stripped all the boring ones away) will have different needs from those two. Each of these situations benefits from a slightly different sampling strategy that optimizes for their needs.

## When to Make a Sampling Decision for Traces

So far, each of the preceding strategies has considered *what* criteria to use when selecting samples. For events involving an individual service, that decision solely depends on the preceding criteria. For trace events, *when* a sampling decision gets made is also important.

Trace spans are collected across multiple services—with each service potentially employing its own unique sample strategy and rate. The probability that every span necessary to complete a trace will be the event that each service chooses to sample is relatively low. To ensure that every span in a trace is captured, special care must be taken depending on when the decision about whether to sample is made.

As covered earlier, one strategy is to use a property of the event itself—the return status, latency, endpoint, or a high-cardinality field like customer ID—to decide if it is worth sampling. Some properties within the event, such as endpoint or customer ID, are static and known at the start of the event. In *head-based sampling* (or *up-front sampling*), a sampling decision is made when the trace event is initiated. That decision is then propagated further downstream (e.g., by inserting a “require sampling” header bit) to ensure that every span necessary to complete the trace is sampled.

Some fields, like return status or latency, are known only in retrospect after event execution has completed. If a sampling decision relies on dynamic fields, by the time those are determined, each underlying service will have already independently chosen whether to sample other span events. At best, you may end up keeping the downstream spans deemed interesting outliers, but none of the other context. Properly making a decision on values known only at the end of a request requires *tail-based sampling*.

To collect full traces in the tail-based approach, all spans must first be collected in a buffer and then, retrospectively, a sampling decision can be made. That buffered sampling technique is computationally expensive and not feasible in practice entirely from within the instrumented code. Buffered sampling techniques typically require external collector-side logic.

Additional nuances exist for determining the *what* and *when* of sampling decisions. But at this point, those are best explained using code-based examples.

# Translating Sampling Strategies into Code

So far, we’ve covered sampling strategies on a conceptual level. Let’s look at how these strategies are implemented in code. This pedagogical example uses Go to illustrate implementation details, but the examples would be straightforward to port into any language that supports hashes/dicts/maps, pseudorandom number generation, and concurrency/timers.

## The Base Case

Let’s suppose you would like to instrument a high-volume handler that calls a downstream service, performs some internal work, and then returns a result and unconditionally records an event to your instrumentation sink:

```
func handler(resp http.ResponseWriter, req *http.Request) {
    start := time.Now()
    i, err := callAnotherService()
    resp.Write(i)
    RecordEvent(req, start, err)
}
```

At scale, this instrumentation approach is unnecessarily noisy and would result in sky-high resource consumption. Let’s look at alternate ways of sampling the events this handler would send.

## Fixed-Rate Sampling

A naive approach might be probabilistic sampling using a fixed rate, by randomly choosing to send 1 in 1,000 events:

```
var sampleRate = flag.Int("sampleRate", 1000, "Static sample rate")

func handler(resp http.ResponseWriter, req *http.Request) {
    start := time.Now()
    i, err := callAnotherService()
    resp.Write(i)

    r := rand.Float64()
    if r < 1.0 / *sampleRate {
          RecordEvent(req, start, err)
    }
}
```

Every 1,000th event would be kept, regardless of its relevance, as representative of the other 999 events discarded. To reconstruct your data on the backend, you would need to remember that each event stood for `sampleRate` events and multiply out all counter values accordingly on the receiving end at the instrumentation collector. Otherwise, your tooling would misreport the total number of events actually encountered during that time period.

## Recording the Sample Rate

In the preceding clunky example, you would need to manually remember and set the sample rate at the receiving end. What if you need to change the sample rate value at some point in the future? The instrumentation collector wouldn’t know exactly when the value changed. A better practice is to explicitly pass the current `sampleRate` when sending a sampled event (see [Figure 17-1](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch17.html#different_events_may_be_sampled_at_diff))—indicating that the event statistically represents `sampleRate` similar events. Note that sample rates can vary not only between services but also within a single service.

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492076438/files/assets/oben_1701.png)

###### Figure 17-1. Different events may be sampled at different rates

Recording the sample rate within an event can look like this:

```
var sampleRate = flag.Int("sampleRate", 1000, "Service's sample rate")

func handler(resp http.ResponseWriter, req *http.Request) {
    start := time.Now()
    i, err := callAnotherService()
    resp.Write(i)

    r := rand.Float64()
    if r < 1.0 / *sampleRate {
        RecordEvent(req, *sampleRate, start, err)
    }
}
```

With this approach, you can keep track of the sampling rate in effect when each sampled event was recorded. That gives you the data necessary to accurately calculate values when reconstructing your data, even if the sampling rate dynamically changes. For example, if you were trying to calculate the total number of events meeting a filter such as `"err != nil"`, you would multiply the count of seen events with `"err != nil"` by each one’s `sampleRate` (see [Figure 17-2](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch17.html#total_events_can_be_calculated_using_we)). And, if you were trying to calculate the sum of `durationMs`, you would need to weight each sampled event’s `durationMs` and multiply it by `sampleRate` before adding up the weighted figures.

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492076438/files/assets/oben_1702.png)

###### Figure 17-2. Total events can be calculated using weighted numbers

This example is simplistic and contrived. Already, you may be seeing flaws in this approach when it comes to handling trace events. In the next section, we will look at additional considerations for making dynamic sampling rates and tracing work well together.

## Consistent Sampling

So far in our code, we’ve looked at *how* a sampling decision is made. But we have yet to consider *when* a sampling decision gets made in the case of sampling trace events. The strategy of using head-based, tail-based, or buffered sampling matters when considering how sampling interacts with tracing. We’ll cover how those decisions get implemented toward the end of the chapter. For now, let’s examine how to propagate context to downstream handlers in order to (later) make that decision.

To properly manage trace events, you should use a centrally generated *sampling/tracing ID* propagated to all downstream handlers instead of independently generating a sampling decision inside each one. Doing so lets you make consistent sampling decisions for different manifestations of the same end user’s request (see [Figure 17-3](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch17.html#sampled_events_containing_a_traceid)). In other words, this ensures that you capture a full end-to-end trace for any given sampled request. It would be unfortunate to discover that you have sampled an error far downstream for which the upstream context is missing because it was dropped because of how your sampling strategy was implemented.

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492076438/files/assets/oben_1703.png)

###### Figure 17-3. Sampled events containing a `TraceId`

Consistent sampling ensures that when the sample rate is held constant, traces are either kept or sampled away in their entirety. And if children are sampled at a higher sample rate—for instance, noisy Redis calls being sampled 1 for 1,000, while their parents are kept 1 for 10—it will never be the case that a broken trace is created from a Redis child being kept while its parent is discarded.

Let’s modify the previous code sample to read a value for sampling probability from the `TraceID`/`Sampling-ID`, instead of generating a random value at each step:

```
var sampleRate = flag.Int("sampleRate", 1000, "Service's sample rate")

func handler(resp http.ResponseWriter, req *http.Request) {
    // Use an upstream-generated random sampling ID if it exists.
    // otherwise we're a root span. generate & pass down a random ID.
    var r float64
    if r, err := floatFromHexBytes(req.Header.Get("Sampling-ID")); err != nil {
          r = rand.Float64()
    }

    start := time.Now()
    // Propagate the Sampling-ID when creating a child span
    i, err := callAnotherService(r)
    resp.Write(i)

    if r < 1.0 / *sampleRate {
          RecordEvent(req, *sampleRate, start, err)
    }
}
```

Now, by changing the `sampleRate` feature flag to cause a different proportion of traces to be sampled, you have support for adjusting the sample rate without recompiling, including at runtime. However, if you adopt the technique we’ll discuss next, target rate sampling, you won’t need to manually adjust the rate.

## Target Rate Sampling

You don’t need to manually flag-adjust the sampling rates for each of your services as traffic swells and sags. Instead, you can automate this process by tracking the incoming request rate that you’re receiving (see [Figure 17-4](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch17.html#you_can_automate_the_calculation_of_ove)).

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492076438/files/assets/oben_1704.png)

###### Figure 17-4. You can automate the calculation of overall sample volume

Let’s see how that is done in our code example:

```
var targetEventsPerSec = flag.Int("targetEventsPerSec", 5,
    "The target number of requests per second to sample from this service.")

// Note: sampleRate can be a float! doesn't have to be an integer.
var sampleRate float64 = 1.0
// Track requests from previous minute to decide sampling rate for the next 
// minute.
var requestsInPastMinute *int

func main() {
    // Initialize counters.
    rc := 0
    requestsInPastMinute = &rc

    go func() {
        for {
              time.Sleep(time.Minute)
              newSampleRate = *requestsInPastMinute / (60 * *targetEventsPerSec)
              if newSampleRate < 1 {
                   sampleRate = 1.0
              } else {
                   sampleRate = newSampleRate
              }
              newRequestCounter := 0
              // Real production code would do something less prone to race 
              // conditions
              requestsInPastMinute = &newRequestCounter
        }
    }()
    http.Handle("/", handler)
     [...]
}

func handler(resp http.ResponseWriter, req *http.Request) {
    var r float64
    if r, err := floatFromHexBytes(req.Header.Get("Sampling-ID")); err != nil {
        r = rand.Float64()
    }

    start := time.Now()
    *requestsInPastMinute++
    i, err := callAnotherService(r)
    resp.Write(i)

    if r < 1.0 / sampleRate {
        RecordEvent(req, sampleRate, start, err)
    }
}
```

This example provides predictable experience in terms of resource cost. However, the technique still lacks flexibility for sampling at variable rates depending on the volume of each key.

## Having More Than One Static Sample Rate

If the sampling rate is high, whether due to being dynamically or statically set high, you need to consider that you could miss long-tail events—for instance, errors or high-latency events—because the chance that a 99.9th percentile outlier event will be chosen for random sampling is slim. Likewise, you may want to have at least some data for each of your distinct sources, rather than have the high-volume sources drown out the low-volume ones.

A remedy for that scenario is to set more than one sample rate. Let’s start by varying the sample rates by key. Here, the example code samples any baseline (non-outlier) events at a rate of 1 in 1,000 and chooses to tail-sample any errors or slow queries at a rate of 1 in 1 and 1 in 5, respectively:

```
var sampleRate = flag.Int("sampleRate", 1000, "Service's sample rate")
var outlierSampleRate = flag.Int("outlierSampleRate", 5, "Outlier sample rate")

func handler(resp http.ResponseWriter, req *http.Request) {
    start := time.Now()
    i, err := callAnotherService(r)
    resp.Write(i)

    r := rand.Float64()
    if err != nil || time.Since(start) > 500*time.Millisecond {
        if r < 1.0 / *outlierSampleRate {
              RecordEvent(req, *outlierSampleRate, start, err)
        }
    } else {
        if r < 1.0 / *sampleRate {
              RecordEvent(req, *sampleRate, start, err)
        }
    }
}
```

Although this is a good example of using multiple static sample rates, the approach is still susceptible to spikes of instrumentation traffic. If the application experiences a spike in the rate of errors, every single error gets sampled. Next, we will address that shortcoming with target rate sampling.

## Sampling by Key and Target Rate

Putting two previous techniques together, let’s extend what we’ve already done to target specific rates of instrumentation. If a request is anomalous (for example, has latency above 500ms or is an error), it can be designated for tail sampling at its own guaranteed rate, while rate-limiting the other requests to fit within a budget of sampled requests per second:

```
var targetEventsPerSec = flag.Int("targetEventsPerSec", 4,
    "The target number of ordinary requests/sec to sample from this service.")
var outlierEventsPerSec = flag.Int("outlierEventsPerSec", 1,
    "The target number of outlier requests/sec to sample from this service.")

var sampleRate float64 = 1.0
var requestsInPastMinute *int

var outlierSampleRate float64 = 1.0
var outliersInPastMinute *int

func main() {
    // Initialize counters.
    rc := 0
    requestsInPastMinute = &rc
    oc := 0
    outliersInPastMinute = &oc

    go func() {
         for {
              time.Sleep(time.Minute)
              newSampleRate = *requestsInPastMinute / (60 * *targetEventsPerSec)
              if newSampleRate < 1 {
                   sampleRate = 1.0
              } else {
                   sampleRate = newSampleRate
              }
              newRequestCounter := 0
              requestsInPastMinute = &newRequestCounter

              newOutlierRate = outliersInPastMinute / (60 * *outlierEventsPerSec)
              if newOutlierRate < 1 {
                   outlierSampleRate = 1.0
              } else {
                   outlierSampleRate = newOutlierRate
              }
              newOutlierCounter := 0
              outliersInPastMinute = &newOutlierCounter
         }
    }()
    http.Handle("/", handler)
     [...]
}

func handler(resp http.ResponseWriter, req *http.Request) {
    var r float64
    if r, err := floatFromHexBytes(req.Header.Get("Sampling-ID")); err != nil {
        r = rand.Float64()
    }
    start := time.Now()
    i, err := callAnotherService(r)
    resp.Write(i)
    if err != nil || time.Since(start) > 500*time.Millisecond {
         *outliersInPastMinute++
         if r < 1.0 / outlierSampleRate {
               RecordEvent(req, outlierSampleRate, start, err)
         }
    } else {
         *requestsInPastMinute++
         if r < 1.0 / sampleRate {
               RecordEvent(req, sampleRate, start, err)
         }
    }
}
```

That extremely verbose example uses chunks of duplicate code, but is presented in that manner for clarity. If this example were to support a third category of request, it would make more sense to refactor the code to allow setting sampling rates across an arbitrary number of keys.

## Sampling with Dynamic Rates on Arbitrarily Many Keys

In practice, you likely will not be able to predict a finite set of request quotas that you may want to set. In the preceding example, our code had many duplicate blocks, and we were designating target rates manually for each case (error/latency versus normal).

A more realistic approach is to refactor the code to use a map for each key’s target rate and the number of seen events. The code would then look up each key to make sampling decisions. Doing so modifies our example code like so:

```
var counts map[SampleKey]int
var sampleRates map[SampleKey]float64
var targetRates map[SampleKey]int

func neverSample(k SampleKey) bool {
    // Left to your imagination. Could be a situation where we know request is a 
    // keepalive we never want to record, etc.
    return false
}

// Boilerplate main() and goroutine init to overwrite maps and roll them over 
// every interval goes here.

type SampleKey struct {
    ErrMsg        string
    BackendShard  int
    LatencyBucket int
}

// This might compute for each k: newRate[k] = counts[k] / (interval * 
// targetRates[k]), for instance.

func checkSampleRate(resp http.ResponseWriter, start time.Time, err error,
         sampleRates map[any]float64, counts map[any]int) float64 {
    msg := ""
    if err != nil {
         msg = err.Error()
    }
    roundedLatency := 100 *(time.Since(start) / (100*time.Millisecond))
    k := SampleKey {
         ErrMsg:       msg,
         BackendShard: resp.Header().Get("Backend-Shard"),
         LatencyBucket: roundedLatency,
    }
    if neverSample(k) {
         return -1.0
    }

    counts[k]++
    if r, ok := sampleRates[k]; ok {
         return r
    } else {
         return 1.0
    }
}

func handler(resp http.ResponseWriter, req *http.Request) {
    var r float64
    if r, err := floatFromHexBytes(req.Header.Get("Sampling-ID")); err != nil {
         r = rand.Float64()
    }

    start := time.Now()
    i, err := callAnotherService(r)
    resp.Write(i)

    sampleRate := checkSampleRate(resp, start, err, sampleRates, counts)
    if sampleRate > 0 && r < 1.0 / sampleRate {
         RecordEvent(req, sampleRate, start, err)
    }
}
```

At this point, our code example is becoming quite large, and it still lacks more-sophisticated techniques. Our example has been used to illustrate how sampling concepts are implemented.

Luckily, existing code libraries can handle this type of complex sampling logic. For Go, the [dynsampler-go library](https://github.com/honeycombio/dynsampler-go) maintains a map over any number of sampling keys, allocating a fair share of sampling to each key as long as it is novel. That library also contains more-advanced techniques of computing sample rates, either based on target rates or without explicit target rates at all.

For this chapter, we’re close to having put together a complete introductory tour of applying sampling concepts. Before concluding, let’s make one last improvement by combining the tail-based sampling you’ve done so far with head-based sampling that can request tracing be sampled by all downstream services.

## Putting It All Together: Head and Tail per Key Target Rate Sampling

Earlier in this chapter, we noted that head-based sampling requires setting a header to propagating a sampling decision downstream. For the code example we’ve been iterating, that means the parent span must pass both the head-sampling decision and its corresponding rate to all child spans. Doing so forces sampling to occur for all child spans, even if the dynamic sampling rate at that level would not have chosen to sample the request:

```
var headCounts, tailCounts map[interface{}]int
var headSampleRates, tailSampleRates map[interface{}]float64

// Boilerplate main() and goroutine init to overwrite maps and roll them over
// every interval goes here. checkSampleRate() etc. from above as well

func handler(resp http.ResponseWriter, req *http.Request) {
    var r, upstreamSampleRate, headSampleRate float64
    if r, err := floatFromHexBytes(req.Header.Get("Sampling-ID")); err != nil {
         r = rand.Float64()
    }

    // Check if we have a non-negative upstream sample rate; if so, use it.
    if upstreamSampleRate, err := floatFromHexBytes(
         req.Header.Get("Upstream-Sample-Rate")
    ); err == nil && upstreamSampleRate > 1.0 {
         headSampleRate = upstreamSampleRate
    } else {
         headSampleRate := checkHeadSampleRate(req, headSampleRates, headCounts)
         if headSampleRate > 0 && r < 1.0 / headSampleRate {
              // We'll sample this when recording event below; propagate the 
              // decision downstream though.
         } else {
              // Clear out headSampleRate as this event didn't qualify for 
              // sampling. This is a sentinel value. 
              headSampleRate = -1.0
         }
    }

    start := time.Now()
    i, err := callAnotherService(r, headSampleRate)
    resp.Write(i)

    if headSampleRate > 0 {
         RecordEvent(req, headSampleRate, start, err)
    } else {
         // Same as for head sampling, except here we make a tail sampling 
         // decision we can't propagate downstream.
         tailSampleRate := checkTailSampleRate(
              resp, start, err, tailSampleRates, tailCounts,
         )
         if tailSampleRate > 0 && r < 1.0 / tailSampleRate {
              RecordEvent(req, tailSampleRate, start, err)
         }
    }
}
```

At this point, our code example is rather complicated. However, even at this level, it illustrates a powerful example of the flexibility that sampling can provide to capture all the necessary context needed to debug your code. In high-throughput modern distributed systems, it may be necessary to get even more granular and employ more sophisticated sampling techniques.

For example, you may want to change the `sampleRate` of head-based samples for increased probability whenever a downstream tail-based heuristic captures an error in the response. In that example, collector-side buffered sampling is a mechanism that would allow deferring a sampling decision until after an entire trace has been buffered—bringing together the advantages of head-based sampling to properties only known at the tail.

# Conclusion

Sampling is a useful technique for refining your observability data. While sampling is necessary when running at scale, it can be useful in a variety of circumstances even at smaller scales. The code-based examples illustrate how various sampling strategies are implemented. It’s becoming increasingly common for open source instrumentation libraries—such as OTel—to implement that type of sampling logic for you. As those libraries become the standard for generating application telemetry data, it should become less likely that you would need to reimplement these sampling strategies in your own code.

However, even if you rely on third-party libraries to manage that strategy for you, it is essential that you understand the mechanics behind how sampling is implemented so you can understand which method is right for your particular situation. Understanding how the strategies (static versus dynamic, head versus tail, or a combination thereof) work in practice enables you to use them wisely to achieve data fidelity while also optimizing for resource constraints.

Similar to deciding what and how to instrument your code, deciding *what*, *when*, and *how* to sample is best defined by your unique organizational needs. The fields in your events that influence how interesting they are to sample largely depend on how useful they are to understanding the state of your environment and their impact on achieving your business goals.

In the next chapter, we’ll examine an approach to routing large volumes of telemetry data: telemetry management with pipelines.
