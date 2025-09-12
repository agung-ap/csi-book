# Chapter 13. Acting on and Debugging SLO-Based Alerts

In the preceding chapter, we introduced SLOs and an SLO-based approach to monitoring that makes for more effective alerting. This chapter closely examines how observability data is used to make those alerts both actionable and debuggable. SLOs that use traditional monitoring data—or metrics—create alerts that are not actionable since they don’t provide guidance on fixing the underlying issue. Further, using observability data for SLOs makes them both more precise and more debuggable.

While independent from practicing observability, using SLOs to drive alerting can be a productive way to make alerting less noisy and more actionable. SLIs can be defined to measure customer experience of a service in ways that directly align with business objectives. Error budgets set clear expectations between business stakeholders and engineering teams. Error budget *burn alerts* enable teams to ensure a high degree of customer satisfaction, align with business goals, and initiate an appropriate response to production issues without the kind of cacophony that exists in the world of symptom-based alerting, where an excessive alert storm is the norm.

In this chapter, we will examine the role that error budgets play and the mechanisms available to trigger alerts when using SLOs. We’ll look at what an SLO error budget is and how it works, which forecasting calculations are available to predict that your SLO error budget will be exhausted, and why it is necessary to use event-based observability data rather than time-based metrics to make reliable calculations.

# Alerting Before Your Error Budget Is Empty

An *error budget* represents that maximum amount of system unavailability that your business is willing to tolerate. If your SLO is to ensure that 99.9% of requests are successful, a time-based calculation would state that your system could be unavailable for no more than 8 hours, 45 minutes, 57 seconds in one standard year (or 43 minutes, 50 seconds per month). As shown in the previous chapter, an event-based calculation considers each individual event against qualification criteria and keeps a running tally of “good” events versus “bad” (or errored) events.

Because availability targets are represented as percentages, the error budget corresponding to an SLO is based on the number of requests that came in during that time period. For any given period of time, only so many errors can be tolerated. A system is out of compliance with its SLO when its entire error budget has been spent. Subtract the number of failed (*burned*) requests from your total calculated error budget, and that is known colloquially as the *amount of error budget remaining*.

To proactively manage SLO compliance, you need to become aware of and resolve application and system issues long before your entire error budget is burned. Time is of the essence. To take corrective action that averts the burn, you need to know whether you are on a trajectory to consume that entire budget well before it happens. The higher your SLO target, the less time you have to react. [Figure 13-1](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch13.html#a_simple_graph_showing_error_budget_bur) shows an example graph indicating error budget burn.

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492076438/files/assets/oben_1301.png)

###### Figure 13-1. A simple graph showing error budget burn over approximately three weeks

For SLO targets up to about 99.95%—indicating that up to 21 minutes, 54 seconds of full downtime are tolerable per month—a reasonable enough time period exists for your team to be alerted to potential issues and still have enough time to act proactively before the entire error budget is burned.

Error budget burn alerts are designed to provide early warning about future SLO violations that would occur if the current burn rate continues. Therefore, effective burn alerts must forecast the amount of error budget that your system will have burned at some future point in time (anywhere from several minutes to days from now). Various methods are commonly used to make that calculation and decide when to trigger alerts on error budget burn rate.

Before proceeding, it’s worth noting that these types of preemptive calculations work best to prevent violations for SLOs with targets up to 99.95% (as in the previous example). For SLOs with targets exceeding 99.95%, these calculations work less preventatively but can still be used to report on and warn about system degradation.

###### Note

For more information on mitigations for this situation, see “Alerting on SLOs” in [Chapter 5 of The Site Reliability Workbook](https://www.oreilly.com/library/view/the-site-reliability/9781492029496/), edited by Betsy Beyer et al. (O’Reilly). In fact, we recommend reading that chapter in its entirety to those who have a deeper interest in alternative perspectives on this topic.

The rest of this chapter closely examines and contrasts various approaches to making effective calculations to trigger error budget burn alerts. Let’s examine what it takes to get an error budget burn alert working. First, you must start by setting a frame for considering the all-too-relative dimension of time.

# Framing Time as a Sliding Window

The first choice is whether to analyze your SLO across a fixed window or a sliding window. An example of a *fixed window* is one that follows the calendar—starting on the 1st day of the month and ending on the 30th. A counterexample is a *sliding window* that looks at any trailing 30-day period (see [Figure 13-2](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch13.html#a_rolling_three_day_window_left_parenth)).

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492076438/files/assets/oben_1302.png)

###### Figure 13-2. A rolling three-day window (left) and a three-day resetting window (right)

For most SLOs, a 30-day window is the most pragmatic period to use. Shorter windows, like 7 or 14 days, won’t align with customer memories of your reliability or with product-planning cycles. A window of 90 days tends to be too long; you could burn 90% of your budget in a single day and still technically fulfill your SLO even if your customers don’t agree. Long periods also mean that incidents won’t roll off quickly enough.

You might choose a fixed window to start with, but in practice, fixed window availability targets don’t match the expectations of your customers. You might issue a customer a refund for a particular bad outage that happens on the 31st of the month, but that does not wave a magic wand that suddenly makes them tolerant of a subsequent outage on the 2nd of the next month—even if that second outage is legally within a different window.

As covered in [Chapter 12](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch12.html#using_service_level_objectives_for_reli), SLOs should be used as a way to measure customer experience and satisfaction, not legal constraints. The better SLO is one that accounts for human emotions, memories, and recency bias. Human emotions don’t magically reset at the end of a calendar month.

If you use a fixed window to set error budgets, those budgets reset with dramatic results. Any error burns away a sliver of the budget, with a cumulative effect gradually counting down toward zero. That gradual degradation continually chips away at the amount of time your team has to proactively respond to issues. Then, suddenly, on the first day of a new month, everything is reset, and you start the cycle again.

In contrast, using a sliding window to track the amount of error budget you’ve burned over a trailing period offers a smoother experience that more closely resembles human behavior. At every interval, the error budget can be burned a little or restored a little. A constant and low level of burn never completely exhausts the error budget, and even a medium-sized drop will gradually be paid off after a sufficiently stable period of time.

The correct first choice to make when calculating burn trajectories is to frame time as a sliding window, rather than a static fixed window. Otherwise, there isn’t enough data after a window reset to make meaningful decisions.

# Forecasting to Create a Predictive Burn Alert

With a timeframe selected, you can now set up a trigger to alert you about error budget conditions you care about. The easiest alert to set is a *zero-level alert*—one that triggers when your entire error budget is exhausted.

##### What Happens When You Exhaust Your Error Budget

When you transition from having a positive error budget to a negative one, a necessary practice is to shift away from prioritizing work on new features and toward work on service stability. It’s beyond the scope of this chapter to cover exactly what happens after your error budget is exhausted. But your team’s goal should be to prevent the error budget from being entirely spent.

Error-budget overexpenditures translate into stringent actions such as long periods of feature freezes in production. The SLO model creates incentives to minimize actions that jeopardize service stability once the budget is exhausted. For an in-depth analysis of how engineering practices should change in these situations and how to set up appropriate policies, we recommend reading [Implementing Service Level Objectives](https://www.oreilly.com/library/view/implementing-service-level/9781492076803/).

A trickier alert to configure is one that is preemptive. If you can foresee the emptying of your error budget, you have an opportunity to take action and introduce fixes that prevent it from happening. By fixing the most egregious sources of error sooner, you can forestall decisions to drop any new feature work in favor of reliability improvements. Planning and forecasting are better methods than heroism when it comes to sustainably ensuring team morale and stability.

Therefore, a solution is to track your error budget burn rate and watch for drastic changes that threaten to consume the entire budget. At least two models can be used to trigger burn alerts above the zero-level mark. The first is to pick a nonzero threshold on which to alert. For example, you could alert when your remaining error budget dips below 30%, as shown in [Figure 13-3](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch13.html#in_this_modelcomma_an_alert_triggers_wh).

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492076438/files/assets/oben_1303.png)

###### Figure 13-3. In this model, an alert triggers when the remaining error budget (solid line) dips below the selected threshold (dashed line)

A challenge with this model is that it effectively just moves the goalpost by setting a different empty threshold. This type of “early warning” system can be somewhat effective, but it is crude. In practice, after crossing the threshold, your team will act as if the entire error budget has been spent. This model optimizes to ensure a slight bit of headroom so that your team meets its objectives. But that comes at the cost of forfeiting additional time that you could have spent delivering new features. Instead, your team sits in a feature freeze while waiting for the remaining error budget to climb back up above the arbitrary threshold.

A second model for triggering alerts above the zero-level mark is to create *predictive* burn alerts ([Figure 13-4](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch13.html#for_predictive_burn_alertscomma_you_nee)). These forecast whether current conditions will result in burning your entire error budget.

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492076438/files/assets/oben_1304.png)

###### Figure 13-4. For predictive burn alerts, you need a baseline window of recent past data to use in your model and a lookahead window that determines how far into the future your forecast extends

When using predictive burn alerts, you need to consider the *lookahead window* and the *baseline* (or *lookback*) *window*: how far into the future are you modeling your forecast, and how much recent data should you be using to make that prediction? Let’s start by considering the lookahead window since it is simpler to consider.

## The Lookahead Window

In the predictive model, we can see that not every error that affects your error budget requires waking someone up. For example, let’s say you have introduced a performance regression such that your service, with a 99.9% SLO target, is now on track to instead deliver 99.88% reliability one month from now. That is not an emergency situation requiring immediate attention. You could wait for the next business day for someone to investigate and correct the trajectory back above 99.9% reliability overall for the full month.

Conversely, if your service experiences a significant fraction of its requests failing such that you are on track to reach 98% within one hour, that should require paging the on-call engineer. If left uncorrected, such an outage could hemorrhage your error budget for the entire month, quarter, or year within a matter of hours.

Both of these examples illustrate that it’s important to know whether your error budget will become exhausted at some point in the future, based on current trends. In the first example, that happens in days, and in the second, that happens in minutes or hours. But what exactly does “based on current trends” mean in this context?

The scope for current trends depends on how far into the future we want to forecast. On a macroscopic scale, most production traffic patterns exhibit both cyclical behavior and smoothed changes in their utilization curves. Patterns can occur in cycles of either minutes or hours. For example, a periodic cron job that runs a fixed number of transactions through your application without jitter can influence traffic in predictable ways that repeat every few minutes. Cyclical patterns can also occur by day, week, or year. For example, the retail industry experiences seasonal shopping patterns with notable spikes around major holidays.

In practice, that cyclical behavior means that some baseline windows are more appropriate to use than others. The past 30 minutes or hour are somewhat representative of the next few hours. But small minute-by-minute variations can be smoothed out when zooming out to consider daily views. Attempting to use the micro scale of past performance for the last 30 minutes or hour to extrapolate what could happen in the macro scale of performance for the next few days runs the risk of becoming flappy and bouncing in and out of alert conditions.

Similarly, the inverse situation is also dangerous. When a new error condition occurs, it would be impractical to wait for a full day of past performance data to become available before predicting what might happen in the next several minutes. Your error budget for the entire year could be blown by the time you make a prediction. Therefore, your baseline window should be about the same order of magnitude as your lookahead window.

In practice, we’ve found that a given baseline window can linearly predict forward by a factor of four at most without needing to add compensation for seasonality (e.g., peak/off-peak hours of day, weekday versus weekend, or end/beginning of month). Therefore, you can get an accurate enough prediction of whether you’ll exhaust your error budget in four hours by extrapolating the past one hour of observed performance four times over. That extrapolation mechanism is discussed in more detail later in [“Context-aware burn alerts”](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch13.html#context_aware_burn_alerts).

### Extrapolating the future from current burn rate

Calculating what may happen in the lookahead window is a straightforward computation, at least for your first guess at burn rate. As you saw in the preceding section, the approach is to extrapolate future results based on the current burn rate: how long will it take before we exhaust our error budget?

Now that you know the approximate order of magnitude to use as a baseline, you can extrapolate results to predict the future. [Figure 13-5](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch13.html#this_graph_shows_the_level_of_error_bud) illustrates how a trajectory can be calculated from your selected baseline to determine when your entire error budget would be completely exhausted.

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492076438/files/assets/oben_1305.png)

###### Figure 13-5. This graph shows the level of error budget (y-axis) remaining over time (x-axis). By extrapolating a baseline window, you can predict the moment when the error budget will empty.

This same technique of linear extrapolation often surfaces in areas such as capacity planning or project management. For example, if you use a weighted system to estimate task length in your ticketing system, you will have likely used this same approach to extrapolate when a feature might be delivered during your future sprint planning. With SLOs and error budget burn alerts, a similar logic is being applied to help prioritize production issues that require immediate attention.

Calculating a first guess is relatively straightforward. However, you must weigh additional nuances when forecasting predictive burn alerts that determine the quality and accuracy of those future predictions.

In practice, we can use two approaches to calculate the trajectory of predictive burn alerts. *Short-term burn alerts* extrapolate trajectories using only baseline data from the most recent time period and nothing else. *Context-aware burn alerts* take historical performance into account and use the total number of successful and failed events for the SLO’s entire trailing window to make calculations.

The decision to use one method or the other typically hinges on two factors. The first is a trade-off between computational cost and sensitivity or specificity. Context-aware burn alerts are computationally more expensive than short-term burn alerts. However, the second factor is a philosophical stance on whether the total amount of error budget remaining should influence how responsive you are to service degradation. If resolving a significant error when only 10% of your burn budget remains carries more urgency than resolving a significant error when 90% of your burn budget remains, you may favor context-aware burn alerts.

###### Note

In the next two sections, *unit* refers to the granular building block on which SLO burn alert calculations are made. These units can be composed of time-series data like metrics. Coarse measures like metrics have an aggregated granularity that marks a unit of time (like a minute or a second) as being either good or bad. These units can also be composed of event data, with each individual event corresponding to a user transaction that can be marked as either good or bad. In [“Using Observability Data for SLOs Versus Time-Series Data”](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch13.html#using_observability_data_for_slos_versu), we’ll examine the ramifications of which type of data is used. For now, the examples will be agnostic to data types by using arbitrarily specific *units* that correspond to one data point per minute.

Let’s look at examples of how decisions are made when using each of those approaches.

### Short-term burn alerts

When using *short-term*, or *ahistorical*, burn alerts, you record the actual number of failed SLI units along with the total number of SLI-eligible units observed over the baseline window. You then use that data to extrapolate forward, and compute the number of minutes, hours, or weeks it would take to exhaust the error budget. For this calculation, you assume that no errors occurred prior to the events observed in the baseline window as well as the typical number of measurement units that the SLO typically sees.

Let’s work an example. Say you have a service with an SLO target indicating 99% of units will succeed over a moving 30-day window. In a typical month, the service sees 43,800 units. In the past 24 hours, the service has seen 1,440 units, 50 of which failed. In the past 6 hours, the service has seen 360 units, 5 of which failed. To achieve the 99% target, only 1% of units are allowed to fail per month. Based on typical traffic volume (43,800 units), only 438 units are allowed to fail (your error budget). You want to know if, at this rate, you will burn your error budget in the next 24 hours.

A simple short-term burn alert calculates that in the past 6 hours, you burned only 5 units. Therefore, in the next 24 hours, you will burn another 20 units, totalling 25 units. You can reasonably project that you will not exhaust your error budget in 24 hours because 25 units is far less than your budget of 438 units.

A simple short-term burn alert calculation would also consider that in the past 1 day, you’ve burned 50 units. Therefore, in the next 8 days, you will burn another 400 units, totalling 450 units. You can reasonably project that you will exhaust your error budget in 8 days, because 450 units is more than your error budget of 438 units.

This simple math is used to illustrate projection mechanics. In practice, the situation is almost certainly more nuanced since your total amount of eligible traffic would typically fluctuate throughout the day, week, or month. In other words, you can’t reliably estimate that 1 error over the past 6 hours forecasts 4 errors over the next 24 hours if that error happens overnight, over a weekend, or whenever your service is receiving one-tenth of its median traffic levels. If this error happened while you saw a tenth of the traffic, you might instead expect to see something closer to 30 errors over the next 24 hours, since that curve would smooth with rising traffic levels.

So far, in this example, we’ve been using linear extrapolation for simplicity. But proportional extrapolation is far more useful in production. Consider this next change to the preceding example.

Let’s say you have a service with an SLO target indicating 99% of units will succeed over a moving 30-day window. In a typical month, the service sees 43,800 units. In the past 24 hours, the service has seen 1,440 units, 50 of which failed. *In the past 6 hours, the service has seen 50 units, 25 of which failed.* To achieve the 99% target, only 1% of units are allowed to fail per month. Based on typical traffic volume (43,800 units), only 438 units are allowed to fail (your error budget). You want to know if, at this rate, you will burn your error budget in the next 24 hours.

Extrapolating linearly, you would calculate that 25 failures in the past 6 hours mean 100 failures in the next 24 hours, totalling 105 failures, which is far less than 438.

Using *proportional extrapolation*, you would calculate that in any given 24-hour period, you would expect to see 43,800 units / 30 days, or 1,440 units. In the last 6 hours, 25 of 50 units (50%) failed. If that proportional failure rate of 50% continues for the next 24 hours, you will burn 50% of 1,440 units, or 720 units—far more than your budget of 438 units. With this proportional calculation, you can reasonably project that your error budget will be exhausted in about half a day. An alert should trigger to notify an on-call engineer to investigate immediately.

### Context-aware burn alerts

When using *context-aware*, or *historical*, burn alerts, you keep a rolling total of the number of good and bad events that have happened over the entire window of the SLO, rather than just the baseline window. This section unpacks the various calculations you need to make for effective burn alerts. But you should tread carefully when practicing these techniques. The computational expense of calculating these values at each evaluation interval can quickly become financially expensive as well. At Honeycomb, we found this out the hard way when small SLO data sets suddenly started to rack up over $5,000 of AWS Lambda costs per day. :-)

To see how the considerations are different for context-aware burn alerts, let’s work an example. Say you have a service with an SLO target indicating 99% of units will succeed over a moving 30-day window. In a typical month, the service sees 43,800 units. *In the previous 26 days, you have already failed 285 units out of 37,960. In the past 24 hours, the service has seen 1,460 units, 130 of which failed.* To achieve the 99% target, only 1% of units are allowed to fail per month. Based on typical traffic volume (43,800 units), only 438 units are allowed to fail (your error budget). You want to know if, at this rate, you will burn your error budget in the next four days.

In this example, you want to project forward on a scale of days. Using the maximum practical extrapolation factor of 4, as noted previously, you set a baseline window that examines the last one day’s worth of data to extrapolate forward four days from now.

You must also consider the impact that your chosen scale has on your sliding window. If your SLO is a sliding 30-day window, your adjusted lookback window would be 26 days: 26 lookback days + 4 extrapolated days = your 30-day sliding window, as shown in [Figure 13-6](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch13.html#an_adjusted_slo_threezero_day_sliding_w).

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492076438/files/assets/oben_1306.png)

###### Figure 13-6. An adjusted SLO 30-day sliding window. When projecting forward 4 days, the lookback period to consider must be shortened to 26 days before today. The projection is made by replicating results from the baseline window for the next 4 days and adding those to the adjusted sliding window.

With those adjusted timeframes defined, you can now calculate how the future looks four days from now. For that calculation, you would do the following:

1. Examine every entry in the map of SLO events that has occurred in the past 26 days.

1. Store both the total number of events in the past 26 days and the total number of errors.

1. Reexamine map entries that occurred within that last 1 day to determine the baseline window failure rate.

1. Extrapolate the next 4 days of performance by presuming they will behave similarly to the 1-day baseline window.

1. Calculate the adjusted SLO 30-day sliding window as it would appear 4 days from now.

1. Trigger an alert if the error budget would be exhausted by then.

Using a Go-based code example, you could accomplish this task if you had a given time-series map containing the number of failures and successes in each window:

```
func isBurnViolation(
  now time.Time, ba *BurnAlertConfig, slo *SLO, tm *timeseriesMap,
) bool {
  // For each entry in the map, if it's in our adjusted window, add its totals.
  // If it's in our projection use window, store the rate.
  // Then project forward and do the SLO calculation.
  // Then fire off alerts as appropriate.

  // Compute the window we will use to do the projection, with the projection
  // offset as the earliest bound.
  pOffset := time.Duration(ba.ExhaustionMinutes/lookbackRatio) * time.Minute
  pWindow := now.Add(-pOffset)

  // Set the end of the total window to the beginning of the SLO time period,
  // plus ExhaustionMinutes.
  tWindow := now.AddDate(0, 0, -slo.TimePeriodDays).Add(
    time.Duration(ba.ExhaustionMinutes) * time.Minute)

  var runningTotal, runningFails int64
  var projectedTotal, projectedFails int64
  for i := len(tm.Timestamps) - 1; i >= 0; i-- {
    t := tm.Timestamps[i]

    // We can stop scanning backward if we've run off the end.
    if t.Before(tWindow) {
      break
    }

    runningTotal += tm.Total[t]
    runningFails += tm.Fails[t]

    // If we're within the projection window, use this value to project forward,
    // counting it an extra lookbackRatio times.
    if t.After(pWindow) {
      projectedTotal += lookbackRatio * tm.Total[t]
      projectedFails += lookbackRatio * tm.Fails[t]
    }
  }

  projectedTotal = projectedTotal + runningTotal
  projectedFails = projectedFails + runningFails

  allowedFails := projectedTotal * int64(slo.BudgetPPM) / int64(1e6)
  return projectedFails != 0 && projectedFails >= allowedFails
}
```

To calculate an answer to the example problem, you note that in the past 26 days, there have already been 37,960 units, and 285 failed. The baseline window of 1 day will be used to project forward 4 days. At the start of the baseline window, you are at day 25 of the data set (1 day ago).

Visualizing results as a graph, as shown in [Figure 13-7](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch13.html#one_day_agocomma_sixfivepercent_of_the), you see that when the one-day baseline window started, you still had 65% of your error budget remaining. Right now, you have only 35% of your error budget remaining. In one day, you’ve burned 30% of your error budget. If you continue to burn your error budget at that rate, it will be exhausted in far less than four days. You should trigger an alarm.

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492076438/files/assets/oben_1307.png)

###### Figure 13-7. One day ago, 65% of the error budget remained. Now, only 35% of the error budget remains. At the current rate, the error budget will be exhausted in less than two days.

## The Baseline Window

Having considered the lookahead window and the way it’s used, let’s now shift our attention back to the baseline window.

There’s an interesting question of how *much* of a baseline to use when extrapolating forward. If the performance of a production service suddenly turns downhill, you want to be aware of that fairly quickly. At the same time, you also don’t want to set such a small window that it creates noisy alerts. If you used a baseline of 15 minutes to extrapolate three days of performance, a small blip in errors could trigger a false alarm. Conversely, if you used a baseline of three days to extrapolate forward an hour, you’d be unlikely to notice a critical failure until it’s too late.

We previously described a practical choice as a factor of four for the timeline being considered. You may find that other more sophisticated algorithms can be used, but our experience has indicated that the factor of four is generally reliable. The baseline multiplier of 4 also gives us a handy heuristic: a 24-hour alarm is based on the last 6 hours of data, a 4-hour alarm is based on the last 1 hour of data, and so forth. It’s a good place to start when first approaching SLO burn alerts.

An odd implication when setting baseline windows proportionally is also worth mentioning. Setting multiple burn alerts on an SLO by using different lookahead window sizes is common. Therefore, it becomes possible for alarms to trigger in seemingly illogical order. For example, a system issue might trigger a burn alert that says you’ll exhaust your budget within two hours, but it won’t trigger a burn alert that says you’ll exhaust it within a day. That’s because the extrapolation for those two alerts comes from different baselines. In other words, if you keep burning at the rate from the last 30 minutes, you’ll exhaust in two hours—but if you keep burning at the rate from the last day, you’ll be fine for the next four days.

For these reasons, you should measure both, and you should act whenever either projection triggers an alert. Otherwise, you risk potentially waiting hours to surface a problem on the burn-down timescale of one day—when a burn alert with hour-level granularity means you could find out sooner. Launching corrective action at that point could also avert triggering the one-day projection alert. Conversely, while an hourly window allows teams to respond to sudden changes in burn rate, it’s far too noisy to facilitate task prioritization on a longer timescale, like sprint planning.

That last point is worth dwelling on for a moment. To understand why both timescales should be considered, let’s look at the actions that should be taken when an SLO burn alert is triggered.

## Acting on SLO Burn Alerts

In general, when a burn alert is triggered, teams should initiate an investigative response. For a more in-depth look at various ways to respond, refer to Hidalgo’s *Implementing Service Level Objectives*. For this section, we’ll examine a few broader questions you should ask when considering response to a burn alert.

First, you should diagnose the type of burn alert you received. Is a new and unexpected type of burn happening? Or is it a more gradual and expected burn? Let’s first look at various patterns for consuming error budgets.

Figures [13-8](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch13.html#a_gradual_error_budget_burn_ratecomma_w), [13-9](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch13.html#an_error_budget_of_threeonedotfourperce), and [13-10](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch13.html#a_system_that_usually_burns_slowly_but) display *error budget remaining* over *time*, for the duration of the SLO window. Gradual error budget burns, which occur at a slow but steady pace, are a characteristic of most modern production systems. You expect a certain threshold of performance, and a small number of exceptions fall out of that. In some situations, disturbances during a particular period may cause exceptions to occur in bursts.

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492076438/files/assets/oben_1308.png)

###### Figure 13-8. A gradual error budget burn rate, with 51.4% remaining

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492076438/files/assets/oben_1309.png)

###### Figure 13-9. An error budget of 31.4% remaining, which is burned in bursts

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492076438/files/assets/oben_1310.png)

###### Figure 13-10. A system that usually burns slowly but had an incident that burned a significant portion of the error budget all at once, with only 1.3% remaining

When a burn alert is triggered, you should assess whether it is part of a burst condition or is an incident that could burn a significant portion of your error budget all at once. Comparing the current situation to historical rates can add helpful context for triaging its importance.

Instead of showing the instantaneous 31.4% remaining and how we got there over the trailing 30 days as we did in [Figure 13-9](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch13.html#an_error_budget_of_threeonedotfourperce), [Figure 13-11](https://learning.oreilly.com/library/view/observability-engineering/9781492076438/ch13.html#a_ninezero_day_sliding_window_for_an_sl) zooms out to examine the 30-day-cumulative state of the SLO for each day in the past 90 days. Around the beginning of February, this SLO started to recover above its target threshold. This likely occurs, in part, because a large dip in performance aged out of the 90-day window.

![](https://learning.oreilly.com/api/v2/epubs/urn:orm:book:9781492076438/files/assets/oben_1311.png)

###### Figure 13-11. A 90-day sliding window for an SLO performs below a 99% target before recovering toward the start of February

Understanding the general trend of the SLO can also answer questions about how urgent the incident feels—and can give a hint for solving it. Burning budget all at once suggests a different sort of failure than burning budget slowly over time.

# Using Observability Data for SLOs Versus Time-Series Data

Using time-series data for SLOs introduces a few complications. In the examples in earlier sections, we used a generic unit to consider success or failure. In an event-based world, that unit is an *individual user request*: did this request succeed or fail? In a time-series world, that unit is a *particular slice of time*: did the entire system succeed or fail during this time? When using time-series data, an aggregate view of system performance gets measured.

The problem with time-series data becomes particularly pronounced in the case of *stringent SLOs*—those with 99.99% availability targets and higher. With these SLOs, error budgets can be exhausted within minutes or seconds. In that scenario, every second especially matters, and several mitigation steps (for example, automated remediations) must be enacted to achieve that target. The difference between finding out about critical error budget burn in one second versus one minute won’t matter much if a responding human needs three minutes to acknowledge the alert, unlock their laptop, log in, and manually run the first remediation they conjure (or even more time if the issue is complex and requires further debugging).

Another mitigation can come by way of using event data for SLOs rather than time-series data. Consider the way time-series evaluation functions in the context of stringent SLOs. For example, let’s say you have an SLI specifying that requests must have a p95 less than 300 milliseconds. The error budget calculation then needs to classify short time periods as either good or bad. When evaluating on a per minute basis, the calculation must wait until the end of the elapsed minute to declare it either good or bad. If the minute is declared bad, you’ve already lost that minute’s worth of response time. This is a nonstarter for initiating a fast alerting workflow when error budgets can be depleted within seconds or minutes.

The granularity of “good minute” or “bad minute” is simply not enough to measure a four-9s SLO. In the preceding example, if only 94% of requests were less than 300 ms, the entire minute is declared bad. That one evaluation is sufficient enough to burn 25% of your 4.32-minute monthly error budget in one shot. And if your monitoring data is collected in only 5-minute windows (as is the fee-free default in Amazon CloudWatch), using such 5-minute windows for good/bad evaluation can fail only one single evaluation window before you are in breach of your SLO target.

In systems that use time-series data for SLO calculation, a mitigation approach might look something like setting up a system in which once three synthetic probes fail, automatic remediations are deployed and humans are then expected to double-check the results afterward. Another approach can be measuring with metrics the instantaneous percentage of requests that are failing in a shorter window of time, given a sufficiently high volume of traffic.

Rather than making aggregate decisions in the good minute / bad minute scenario, using event data to calculate SLOs gives you request-level granularity to evaluate system health. Using the same previous example SLI scenario, any single request with duration lower than 300 ms is considered good, and any with duration greater than 300 ms is considered bad. In a scenario with 94% of requests that were less than 300 ms, only 6% of those requests are subtracted from your SLO error budget, rather than the 100% that would be subtracted using an aggregate time-series measure like p95.

In modern distributed systems, 100% total failure blackouts are less common than partial failure brownouts, so event-based calculations are much more useful. Consider that a 1% brownout of a 99.99% reliability system is similar to measuring a 100% outage of a 99% reliability system. Measuring partial outages buys you more time to respond, as if it were a full outage of a system with a much less stringent SLO. In both cases, you have more than seven hours to remediate before the monthly error budget is exhausted.

Observability data that traces actual user experience with your services is a more accurate representation of system state than coarsely aggregated time-series data. When deciding which data to use for actionable alerting, using observability data enables teams to focus on conditions that are much closer to the truth of what the business cares about: the overall customer experience that is occurring at this moment.

It’s important to align your reliability goals with what’s feasible for your team. For very stringent SLOs—such as a five-9s system—you must deploy every mitigation strategy available, such as automatic remediation, based on extremely granular and accurate measurements that bypass traditional human-involved fixes requiring minutes or hours. However, even for teams with less stringent SLOs, using granular event-based measures can create more response time buffers than are typically available with time-series-based measures. That additional buffer ensures that reliability goals are much more feasible, regardless of your team’s SLO targets.

# Conclusion

We’ve examined the role that error budgets play and the mechanisms available to trigger alerts when using SLOs. Several forecasting methods are available that can be used to predict when your error budget will be burned. Each method has its own considerations and trade-offs, and the hope is that this chapter shows you which method to use to best meet the needs of your specific organization.

SLOs are a modern form of monitoring that solve many of the problems with noisy monitoring we outlined before. SLOs are not specific to observability. What is specific to observability is the additional power that event data adds to the SLO model. When calculating error budget burn rates, events provide a more accurate assessment of the actual state of production services. Additionally, merely knowing that an SLO is in danger of a breach does not necessarily provide the insight you need to determine which users are impacted, which dependent services are affected, or which combinations of user behavior are triggering errors in your service. Coupling observability data to SLOs helps you see where and when failures happened after a burn budget alert is triggered.

Using SLOs with observability data is an important component of both the SRE approach and the observability-driven-development approach. As seen in previous chapters, analyzing events that fail can give rich and detailed information about what is going wrong and why. It can help differentiate systemic problems and occasional sporadic failures. In the next chapter, we’ll examine how observability can be used to monitor another critical component of a production application: the software supply chain.
