# 11 Monitoring and Explainability

### This chapter covers

- Setting up monitoring and logging for ML Applications
- Routing alerts using Alertmanager
- Storing logs in Loki for scalable log aggregation and querying
- Identifying data drift
- Using model explainability to understand how the ML model makes its decisions

With the models now available as a service, our next goal would be to monitor these models. Monitoring models is important to ensure the models are working as expected and meeting the criteria agreed upon by the business and the data science teams. Model monitoring can be split up into two main components.

- Basic monitoring
- Data drift monitoring

Basic monitoring refers to ensuring the operational efficiency of the deployed service. Our model services will eventually integrate with other organizational services and must meet any requiredSLAs (service level agreement). Common SLA metrics include uptime, throughput, response latency, and response quality. Most services deployed in a production environment will have a fixed error budget (an acceptable level of unreliability in a service); therefore, maintaining service stability and ensuring a quick reaction to resolve any unforeseen issues is extremely important.

We also need to set up data drift monitoring to ensure that the incoming data and its relationship with the target variable are consistent with what was observed during model training. Identifying reasons for data drift quickly helps ensure the quality of an ML service meets expectations and can guide efforts to refine feature engineering, update training data, or retrain models to improve performance over time.

We will use BentoML's built-in dashboard for basic monitoring and demonstrate how to add custom metrics to the BentoML service, as well as collect logs for debugging issues. Additionally, we will use Deepchecks to monitor data drift, ensuring the model remains effective and reliable in production.

Finally, we will take a look at model explainability. Explainability allows us to identify specific features or inputs that might contribute to model behavior changes, which is critical for maintaining trust and accountability in our machine-learning systems. By integrating explainability into our monitoring and maintenance strategies, we can detect issues more effectively and communicate the reasons behind model decisions to stakeholders.

## 11.1 Monitoring

No application is considered production-ready without monitoring. It helps minimize downtime and service disruptions via early detection of performance issues, faults, or failures. Monitoring makes it possible to quickly identify and address issues by watching important metrics like resource utilization and response times. This improves the user experience, ensures application stability, and helps maintain service level agreements (SLAs). An effective monitoring solution will keep track of performance and business metrics and alert the necessary personnel who can take action to resolve any issues.

Alerting is crucial because it provides real-time notifications about critical issues or abnormal behavior in applications, systems, or infrastructure. It ensures that potential problems, such as performance degradation, and outages are quickly identified, allowing for swift intervention and minimizing downtime.

In the upcoming sections, we will set up monitoring and alerting for the object detection and movie recommender project.

### 11.1.1 Basic Monitoring

Basic monitoring for a service that is deployed as an API endpoint involves two categories of metrics

- Resource utilization
- Request tracking metrics

Our applications are usually deployed with limited resources, the memory and CPU cannot increase beyond a certain limit which is usually specified during deployment. There is an upper limit to how many pods an application can scale up to. Monitoring these resources is critical to ensure the application remains performant in production. It also gives us an idea to allocate resources more effectively and in an optimum manner.

Tracking request metrics such as response time latency and the number of failing (non-200) status codes helps us identify issues like slow responses or application errors. This enables us to optimize the application, prevent downtime, and ensure it meets performance expectations and service level agreements (SLAs). By monitoring these metrics, we can proactively address problems before they escalate.

As both of our applications are served using BentoML, we will use a pre-built Grafana dashboard provided by BentoML to monitor the above metrics. We have already installed Prometheus and Grafana in chapter 3. We will create a dashboard in Grafana to visualize the BentoML application metrics required for basic monitoring.

BentoML deployments already come with a /metrics endpoint as seen in the last chapter, these predefined metrics are more than enough for the basic monitoring of the application. We have to ensure that these metrics are being scraped by Prometheus.

To verify this, we can check the Prometheus UI by navigating to the "Service Discovery" section. To access the Prometheus UI, use the kubectl port-forward command to map port 80 of the Prometheus-server service to port 9090 on our host.

```bash
kubectl port-forward svc/prometheus-server -n prometheus 9090:80 -n prometheus
```

We will then access the UI `http://localhost:9090` from our browser, we will then click the status tab -> service discovery. In the service discovery, we can see the below UI when searching for BentoML. There should be a PodMonitor object in the list that is monitoring the yatai-deployment.

![Figure 11.1 Searching for BentoML in Prometheus service discovery](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/11__image001.png)

If for some reason we are unable to see this, we should set up the Pod Monitor by running the below Kubectl apply command

```bash
kubectl apply -f https://raw.githubusercontent.com/bentoml/yatai/main/scripts/monitoring/bentodeployment-podmonitor.yaml
```

After a few minutes, we can check the Prometheus UI and should be able to see the PodMonitor. A Pod Monitor is a custom resource typically used with Prometheus to enable the monitoring of specific pods within the cluster. It defines how Prometheus should scrape metrics from the pods by specifying which pods to monitor, which ports and endpoints to target, and the frequency of the scrapes. The Pod Monitor simplifies the process of discovering and collecting metrics from dynamically changing pod environments, ensuring that Prometheus captures the health, performance, and behavior of the applications running inside the pods in real-time. In our case the Pod Monitor monitors all BentoML deployments.

After the PodMonitor is set we can verify that metrics are available in the Prometheus Server by clicking on the graph tab in the UI and searching for bento, we should be able to see some BentoML metrics that are available in the /metrics endpoint

![Figure 11.2 Verifying if BentoML metrics are being scraped by Prometheus](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/11__image002.png)

Now that the metrics are available we can visualize these metrics in the Grafana dashboard. The usual way to build a Grafana dashboard would be to write a few PromQL (Prometheus Query Language) queries and specify the type of visualization we want. As we are using BentoML we have a pre-built dashboard that we can use for our basic monitoring use case. To download this dashboard we first download the dashboard.json file to our local system at `/tmp/bentodeployment-dashboard.json`

```
curl -L https://raw.githubusercontent.com/bentoml/yatai/main/scripts/monitoring/bentodeployment-dashboard.json -o /tmp/bentodeployment-dashboard.json
```

We then proceed to the Grafana UI by again running the port-forward command to map service port 80 to local port 8001.

```bash
kubectl port-forward svc/grafana -n grafana 8001:80
```

We can then access the Grafana UI, and click on the Dashboard tab. We need to import the JSON of the dashboard we downloaded by clicking on new->import. We copy the JSON in the file `bentodeployment-dashboard.json` and click on Load.

![Figure 11.3 Importing BentoML dashboard in Grafana](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/11__image003.png)

We can then see the BentoML Deployment dashboard under the dashboards tab. This dashboard has all the metrics that are necessary for basic monitoring. It includes the number of in-progress requests, the RPS (requests per second metrics), the success rate per endpoint, and CPU and memory usage information—all the metrics we need for our basic monitoring. We can even choose the BentoML deployment from the dropdown tab.

![Figure 11.4 BentoML basic monitoring dashboard.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/11__image004.png)

This dashboard is sufficient for basic monitoring of our deployed services, but what if we wanted to add a few custom metrics for our application? The default metrics may not capture the specific details of our application’s behavior. Custom metrics allow us to track specific application logic that are important for the business, such as transaction success rates, or monitoring.

For our object detection use case, we may want to know the number of times the predicted object was an id_card and get a distribution of the confidence score. These metrics will be useful for alerting and reporting purposes. In the next section, we will enable custom metrics for our BentoML deployments.

### 11.1.2 Custom Metrics

For the object detection project we have two endpoints: *invocation* and *render*. Our invocation endpoint gives us the bounding box of the object along with the category and confidence. It would be good to keep track of the confidence scores and identify periods of time if any when the confidence scores are lower than a predefined threshold. This can indicate that we are getting images of bad quality or our model performance is degrading. To create a custom metric we need to install prometheus-client by running

```
pip install prometheus-client
```

We will then define a Prometheus metric of type Histogram for our confidence score. As discussed in chapter 3 a Prometheus histogram metric collects and counts observations (such as request durations or sizes) and categorizes them into predefined "buckets" based on value ranges. It provides a way to observe the distribution of data over time, offering insights into the frequency and magnitude of specific events, which is useful for performance monitoring and latency analysis. The buckets for our confidence score would be in deciles from 0 to 1. We define the histogram metric by specifying the name of the metric providing some information about what the metric does in documentation, and then we can provide the list of buckets from 0 to 1.

```
confidence_histogram = Histogram(
    name="confidence_score",
    documentation="The confidence score of the prediction",
    buckets=(
      0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1
    ),
)
```

After defining this metric in a metrics.py file, we need to use it by calling the built-in *observe* method whose argument would be the confidence score. We modify the inference function service.py by adding the newly defined metric.

```
@bentoml.Runnable.method(batchable=False)
    def inference(self, input_img):
        results = self.model(input_img)[0]
        response = json.loads(results[0].tojson())
        confidence_histogram.observe(response[0]["confidence"])
        return response
```

If we now serve our service by running the bentoml `serve` command

```
bentoml serve service.py --reload
```

and uploading an image using the /invocation endpoint. We can verify our metric exists by accessing`http://localhost:3000`. We can see all the buckets we listed and the counts under each bucket (le refers to less than or equal).

![Figure 11.5 Custom metrics can be seen at /metrics endpoint](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/11__image005.png)

With the custom metrics now available for scraping by Prometheus, we can easily plot that metric in Grafana. We can create a new dashboard in Grafana and set the chart type as Gauge. If we wish to get the 90th percentile confidence score based on the histogram data, we can use the following promql query for the object detection

```
histogram_quantile(0.9, sum(rate(confidence_score_bucket[5m])) by (le))
```

This will give us the following chart in Grafana, which indicates that our model is quite confident with its prediction in the last 5 minutes.

![Figure 11.6 Visualizing the confidence score custom metric in Grafana as a Gauge](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/11__image006.png)

Similarly for the movie recommender project, we might want to count the number of times the user or service provides ranked movies in the request. To enable this we will define a Prometheus metric of type counter in metrics.py and increment it every time the ranked_movies is not None. Counter metric is used to represent a cumulative value that can only increase or reset to zero upon restart.

```
ranked_movie_present_counter = Counter(
    name="ranked_movie_present_counter",
    documentation="The number of times ranked movies is present in the request",
)
ranked_movie_absent_counter = Counter(
    name="ranked_movie_present_counter",
    documentation="The number of times ranked movies is absent in the request",
)
```

We can plot this metric as a time series chart in Grafana.

![Figure 11.7 Visualizing the ranked movie counter score custom metric in Grafana as a line chart](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/11__image007.png)

By continuously tracking these metrics, teams can monitor the health and trends of their systems and spot anomalies early. However, metrics alone often lack the granular detail needed to understand the intricacies of specific events fully. In the next section, we will talk about logging.

### 11.1.3 Logging

Logging, in addition to metrics, is important for monitoring because it provides detailed, context-rich information about the state and behavior of an application that metrics alone cannot capture. While metrics offer measurable insights (e.g., CPU usage, request counts), logs provide qualitative details, such as specific error messages, stack traces, or unusual events. Logs help in identifying the root cause of issues, debugging complex scenarios, and tracking the sequence of events leading to failures. Combined with metrics, logging offers a complete picture of system health, making monitoring more effective and actionable.

For our BentoML applications, we can use the BentoMLl logger which is an ordinary Python logger to log information which is important for tracing and debugging any issue one might encounter in production. To use the BentoML logger we just need to import the logging library, set the format, retrieve the Bentoml logger, and set the log level. We can specify this in our service.py file.

##### Listing 11.1 Setting up logging for BentoML service

```
import logging
ch = logging.StreamHandler()    #A
# Set a format for the handler
formatter = logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")    #B
ch.setFormatter(formatter)
bentoml_logger = logging.getLogger("bentoml")    #C
# Add the handler to the BentoML logger
bentoml_logger.addHandler(ch)    #D
bentoml_logger.setLevel(logging.DEBUG)
```

For example, in our object detection model we can use the bentoml logger to log cases where the result is empty due to a processing error.

```
if len(results) == 0:
            bentoml_logger.error("Error while processing object detection, model returned 0 results")
            return {"status": "failed"}
```

If we provide an image whose dimensions are too small for inference, we can see the error in the logs

```
2024-08-23T13:54:54+0800 [ERROR] [runner:yolov8runnable:1] Error while processing (trace=dde1822c5c4f36ae1244a7864f38ce97,span=9f3a24ed49c71167,sampled=0,service.name=yolov8runnable)
2024-08-23 13:54:54,400 - bentoml - ERROR - Error while processing
```

We can unify the logging and metrics in one platform if we have deployed the application in a GKE (Google Kubernetes Engine) or EKS (AWS Elastic Kubernetes Service). The logs will be available in their respective monitoring services. However, this would mean that metrics are in Grafana and logs will be either in GCP Stackdriver or AWS CloudWatch. Centralizing logs and metrics is considered a good practice. Some of the advantages are that centralization:

- Provides a single platform for viewing application performance and issues across the entire infrastructure.
- Aggregates data from multiple sources, allowing for quicker identification and resolution of issues with better context.
- Improves teamwork by making logs and metrics easily accessible to multiple teams.

Grafana Labs provides Loki, which is an open-source log aggregating system designed to seamlessly work with Grafana. Loki is lightweight and focuses on indexing metadata rather than the full content of logs, making it highly cost-effective and scalable. Built to integrate seamlessly with Prometheus and Grafana, Loki allows users to correlate logs with metrics, providing a unified observability experience for monitoring applications. Its architecture supports easy deployment in cloud-native environments, making it an ideal choice for teams looking to centralize logging without the overhead of complex indexing.

We can install Loki and integrate it with Grafana by following the instructions in Appendix A.

Once installed, we can navigate to the Grafana dashboard and select Loki as a data source, the app can be one of the BentoML deployments, and we can filter it further if required, select the time range, and search through logs for particular text.

![Figure 11.8 Using Loki as log aggregation system in Grafana](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/11__image008.png)

By collecting metrics and centralizing logs, we can gain valuable insights into system behaviors, swiftly detect and resolve issues, and ensure a smooth user experience. Together, these practices form the foundation of an effective observability strategy, enabling proactive incident management.

In the next section, we'll explore how setting up alerts based on the data collected through monitoring and logging allows for timely notifications of potential issues, ensuring quick responses and minimizing downtime.

### 11.1.4 Alerting

System malfunctions, performance deterioration, or security events may go unreported until they have a major effect if alerting isn't in place. Good alerting means that operations teams can take preemptive measures to preserve the functionality and health of applications, minimize downtime, and lessen the impact on users. Alerting guarantees that responsible parties are notified promptly of major problems by automating the notification process.

One of the key alerts to configure for our applications is monitoring their uptime. Since our service is utilized by users or other services, it is essential to promptly address any issues that may lead to downtime.

*Alertmanager* is an integral component of the Prometheus ecosystem. Prometheus generates alerts, which Alertmanager handles and routes according to preset rules. Prometheus sends an alert to Alertmanager when it notices a problem, such as excessive CPU use or a service outage. After processing the alarm, Alertmanager forwards it, based on its setup, to certain channels such as email, Slack, or another channel. It ensures that appropriate individuals or systems are informed promptly.

![Figure 11.9 Alerts generated by the Prometheus service are sent to Alertmanager, which routes them to various channels such as Slack, Email, or PagerDuty](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/11__image009.png)

We will first set rules for alerting, we will then configure alertmanager for routing the alerts to our email.

A Prometheus Alert rule is simply a PromQL expression with conditions. If we wish to monitor our BentoML deployments to check if they are up or down, we would use the *up* metric. The *up* metric in Prometheus is a special metric used to indicate whether a target or service is successfully scraping data. It has a value of 1 when the target is up and 0 when it is down or unavailable.

```
up{job="yatai/bento-deployment",yatai_ai_bento_deployment_component_type=~"api-server|runner"} == 0
```

The *up* metric is useful when the application encounters an error and the metrics no longer can be scraped. What if the deployment itself was deleted or terminated? In that case, the up metric would not be useful. For such scenarios, we can use the `absent` function. The `absent` function is used to detect the absence of a specific metric over a specified period. It returns a value of `1` if the metric is not present in the data at the time of the query, and `0` if it is present.

```
absent(up{job="yatai/bento-deployment", yatai_ai_bento_deployment_component_type=~"api-server|runner"}) == 1
```

Now that we have our expressions we need to specify for how long the service must be down before alerting, what message should be sent, and we can also assign any labels to the alert (such as severity).

##### Listing 11.2 Setting up alert rules for BentoML service

```
- name: BentoDeploymentServiceAlerts
   rules:
      - alert: ServiceDown
        expr: up{job="yatai/bento-deployment", yatai_ai_bento_deployment_component_type=~"api-server|runner"} == 0    #A
        for: 5m
        labels:
          severity: critical
        annotations:
           summary: "Service {{ $labels.job }} on instance {{ $labels.instance }} is down"
           description: "The job {{ $labels.job }} on instance {{ $labels.instance }} has been 
down for more than 5 minutes."
    - alert: MissingUpMetric
      expr: absent(up{job="yatai/bento-deployment", yatai_ai_bento_deployment_component_type=~"api-server|runner"}) == 1  
      for: 5m    #B
      labels:
        severity: critical    #C
      annotations:
         summary: "Instance is missing the 'up' metric for {{ $labels.instance }}"
         description: "The 'up' metric for {{ $labels.job }} on instance {{ $labels.instance }} has been missing for more than 5 minutes, which may indicate the target is down."
```

To add this alert, we must modify the Prometheus config. As we deployed Prometheus via a Helm chart, we will modify the values file by adding these new rules. We add them under serverFiles -> bentoDeploymentRules.yaml. We define the above rules under a common alerting group. In Prometheus, an alert group is a logical grouping of alerting rules evaluated together. It is part of the Prometheus alerting rule configuration and helps organize and manage multiple alerts based on related criteria.

##### Listing 11.3 Configuring alerts in Prometheus

```
serverFiles:    #A
  bentoDeploymentRules.yaml:
       groups:
          - name: BentoDeploymentServiceAlerts
            rules:
              - alert: ServiceDown
                expr: up{job="yatai/bento-deployment", yatai_ai_bento_deployment_component_type=~"api-server|runner"} == 0
                for: 5m
                labels:
                  severity: critical
                annotations:
                  summary: "Service {{ $labels.job }} on instance {{ $labels.instance }} is down"
                  description: "The job {{ $labels.job }} on instance {{ $labels.instance }} has been down for more than 5 minutes."
              - alert: MissingUpMetric
                expr: absent(up{job="yatai/bento-deployment", yatai_ai_bento_deployment_component_type=~"api-server|runner"}) == 1
                for: 5m
                labels:
                  severity: critical
                annotations:
                  summary: "Instance is missing the 'up' metric for {{ $labels.instance }}"
                  description: "The 'up' metric for {{ $labels.job }} on instance {{ $labels.instance }} has been missing for more than 5 minutes, which may indicate the target is down."
```

We will now update our `helm` installation

```
helm upgrade --install prometheus prometheus-community/prometheus -n prometheus -f values.yaml
```

Once updated we can access the Prometheus UI and check under the Alerts tab, we should be able to see two of the alert rules we defined. We can also see that they have not been triggered and are inactive (green).

![Figure 11.10 When the alerts are green in color it means they have not been triggered yet](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/11__image010.png)

Let's test out the `Missingupmetric` alert by terminating our BentoML deployment. For this we go to Yatai-> deployments and terminate any of our BentoML deployments by clicking on the Terminate button.

After the deployment is terminated we can check the Prometheus UI alerts page again, we can now see the MissingUpMetric is highlighted in yellow, which means the alert is pending, An alert is in the pending state when the condition which triggers it has occurred but for the alert to be activated we need to wait the pre-configured time. In our case we want the alert to be triggered if the metric is missing for five minutes or more.

![Figure 11.11 When the alerts are yellow it means the rule that triggers the alert is active and in a pending state](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/11__image011.png)

If we check the UI in 5 minutes we will now see that the MissingUpMetric is in red, letting us know that the alert is triggered (red).

![Figure 11.12 When the alerts are red it means the alert has been triggered](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/11__image012.png)

The alert is now triggered, we need to route this alert to someone. We can route an alert to multiple channels such as Slack, Gmail, or Pagerduty. We will route the alert to Gmail by modifying the alertmanager config in the helm chart values file. We add `config` under alertmanager in the values file. We need to set up an app password in Gmail. To do so, proceed to your Google account home and set up 2FA (two factor authentication) if you have not done so. After that, proceed to [https://myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords) to create a new app password. This password will be specified in the config to send the alert emails. After generating the app password, we can place the below config under alert manager

##### Listing 11.4 Setting up Alertmanager routing logic

```
config:
      global:    #A
        smtp_smarthost: 'smtp.gmail.com:587'
        smtp_from: '<gmail_address>'
        smtp_auth_username: '<gmail_address>'
        smtp_auth_password: '<app password>' 
        smtp_require_tls: true
 
      route:    #B
        receiver: 'gmail-alerts'
        group_by: ['alertname', 'job']
        group_wait: 30s
        group_interval: 5m
        repeat_interval: 3h
 
      receivers:    #C
        - name: 'gmail-alerts'
          email_configs:
            - to: '<alert-recepient-email-address>'
              send_resolved: true
```

We can then upgrade the helm deployment using the helm upgrade install command. After installing our recipient should get an email with the alert message.

![Figure 11.13 An alert email that states the alert label and pre-defined description](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/11__image013.png)

We can even take a look at the alert manager ui by port-forwarding to it and looking at the alerts.

```bash
kubectl port-forward svc/prometheus-alertmanager -n prometheus 9091:80 -n prometheus
```

We can see that multiple alerts have been triggered apart from our MissingUpMetric alert. This would have triggered a mail for each alert.

![Figure 11.14 Multiple alerts which have been triggered and routed to Gmail by Alertmanager](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/11__image014.png)

The alerts in alert manager can be routed to different receivers (such as email, Slack, or PagerDuty) based on the routing logic. It is possible to route alerts based on the namespace the alert is triggered in or by the label of the alert. For example, we may want to route the severity: critical alerts to Pagerduty while severity: medium and low are routed to Gmail.

```
route:
        receiver: 'gmail-alerts'
        group_by: ['alertname', 'job']
        group_wait: 30s
        group_interval: 5m
        repeat_interval: 3h
        routes:
            - match: severity: medium 
               receiver: 'gmail-alerts' 
            - match: severity: low 
              receiver: 'gmail-alerts'
```

In conclusion, by offering real-time monitoring and incident response capabilities, alerting and Alertmanager play a critical part in guaranteeing the dependability and stability of our ML services. Organizations may identify problems early on with well-configured alerting rules, and Alertmanager effectively distributes notifications to the appropriate teams by utilizing routing. This ensures the developers remain informed and can readily respond to issues and fix them respectively.

In the next section we will learn how to apply data drift techniques to our two projects.

## 11.2 Data Drift Detection

In Chapter 6, we covered the need to detect data drift and explored the different types of data drift. In that chapter, we focused on tabular data from our income classifier project and used statistical tests to identify drift in both real-time and batch use cases. This section will extend this to object detection and movie recommendation projects.

### 11.2.1 Object Detection

The object detection project is a computer vision project, so we must approach data drift detection differently than we would for tabular data. For tabular data like that in the recommender project, we had a predefined set of features that allowed us to monitor changes in distribution relative to the training features. For image data, we can compare differences between image features or properties, such as brightness, contrast, aspect ratio, and more. To do so we would first need to compute the properties of the training images and then compare those with the images we get during inference and check if the data distribution is statistically different.

However, we can use a tool to assist with this. Just as Evidently is used for tabular data, we can use another Python library called Deepchecks to identify drift in image data. Deepchecks is a Python library designed to help data scientists and machine learning practitioners ensure the quality and integrity of their data and models. It offers a wide range of checks and validations for both data and models, focusing on identifying issues such as data drift, data leakage, and model performance degradation over time. Deepchecks can be leveraged to detect drift in applications outside of image-based models as well.

Key features of Deepchecks include:

- **Data Integrity Checks**: Deepchecks allow users to validate the consistency and quality of their data, detecting anomalies, missing values, and data types.
- **Model Validation**: It can test models for common issues like overfitting, class imbalance, and unexpected biases.
- **Data Drift Detection**: One of its core features, Deepchecks can identify data drift by comparing the distribution of features in new datasets against those in the training data. It can highlight changes in feature distribution, which might signal that a model's performance could degrade if retrained or deployed on this new data.
- **Customizable Checks**: Users can customize checks or create new ones based on specific needs, making the library flexible and adaptable to various use cases.

We can install Deepchecks by using the pip install command

```
pip install deepchecks.
```

Deepchecks can be a vital tool in maintaining model reliability over time, especially in environments where data evolves rapidly. We will use Deepchecks to identify drift for our object detection use case.

First, we will generate a dataset with properties that differ from the training image dataset. Specifically, we will adjust the brightness of the test images to differ from that of the training images using the ImageEnhance module from PIL, an image processing package. We will then use Deepchecks to determine if this data drift can be detected with this change to brightness that modifies the new data to potentially be outside the distribution of the training set.

We store a set of ID card images and their respective labels in a directory (around 100 images should be sufficient). Next, we modify the brightness of the images using the `adjust_brightness` function. By setting the `brightness_factor` to less than 1, we reduce the brightness of the images. Conversely, if we want to increase the brightness, we can set the factor to greater than 1. Additionally, we specify the input directory for the images and the output directory where we want to save the modified images.

##### Listing 11.5 Adjust brightness of the images to introduce drift

```
for i, image_file in enumerate(image_files[:100]):
        try:
            img_path = os.path.join(input_dir, image_file)
            img = Image.open(img_path)
            unmodified_path = os.path.join(
                unmodified_dir, f"{os.path.splitext(image_file)[0]}.tif"
            )
            img.save(unmodified_path, format="TIFF")
            label_filename = f"{os.path.splitext(image_file)[0]}.txt"
            input_label_path = os.path.join(
                input_dir.replace("images", "labels"), label_filename
            )
            if os.path.exists(input_label_path):
                unmodified_label_path = os.path.join(
                    unmodified_dir.replace("images", "labels"), label_filename
                )
                with open(input_label_path, "r") as src, open(
                    unmodified_label_path, "w"
                ) as dst:
                    dst.write(src.read())
            # Process and save modified image
            enhancer = ImageEnhance.Brightness(img)    #A
            img_enhanced = enhancer.enhance(brightness_factor)
            output_path = os.path.join(
                output_dir, f"{os.path.splitext(image_file)[0]}.tif"
            )
            img_enhanced.save(output_path, format="TIFF")    #B
```

We can look at one of the images to verify if the brightness has been modified.

![Figure 11.15 Before and after adjusting the brightness of the image. We have reduced the brightness of the original training image.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/11__image015.png)

We now have a directory containing the training data images and their corresponding labels, as well as another directory with images whose brightness has been adjusted along with their labels. To build our custom dataset, we’ll subclass `torchvision.datasets.VisionDataset` using these two directories. We will call thee subclass IDCardDataset. The IDCardDataset will hold the image paths and labels of train and test images. In this scenario, our training and testing datasets consist of a sample of images, where the training dataset contains images with unmodified brightness, and the testing dataset includes images with adjusted brightness. We also need to define a load_dataset function which returns a Deepchecks VisionData for both train and test. We can run Deepchecks ImagePropertyDrift on VisionData. The code for IDCardDataset and load_dataset function can be found in repository for object-detection.

We can use the `load_dataset` functionality to load the training and drifted dataset. Deepchecks `ImagePropertyDrift` can then be run on these two datasets. We can then save the results to a html file. We can even print the raw values of the test.

##### Listing 11.6 Running Deepchecks ImagePropertyDrift

```
from Dataset import load_dataset
from deepchecks.vision.checks import ImagePropertyDrift
train_dataset = load_dataset(train=True, object_type="VisionData")
test_dataset = load_dataset(train=False, object_type="VisionData")
check_result = ImagePropertyDrift().run(train_dataset, test_dataset)    #A
check_result.save_as_html("deepcheck_vision_drift_check.html")    #B
print(check_result.value)    #C
```

We obtain drift scores for various image properties and observe significant drift in the brightness property (the one we modified). However, the area and aspect ratio show zero drift since we did not alter those properties.

```json
{'Aspect Ratio': {'Drift score': 0.0, 'Method': 'Kolmogorov-Smirnov'}, 'Area': {'Drift score': 0.0, 'Method': 'Kolmogorov-Smirnov'}, 'Brightness': {'Drift score': 0.6188968140751308, 'Method': 'Kolmogorov-Smirnov'}, 'RMS Contrast': {'Drift score': 0.3095339990489777, 'Method': 'Kolmogorov-Smirnov'}, 'Mean Red Relative Intensity': {'Drift score': 0.13938183547313365, 'Method': 'Kolmogorov-Smirnov'}, 'Mean Green Relative Intensity': {'Drift score': 0.288525915359011, 'Method': 'Kolmogorov-Smirnov'}, 'Mean Blue Relative Intensity': {'Drift score': 0.06760342368045646, 'Method': 'Kolmogorov-Smirnov'}}
```

The HTML file that stores this report gives us a visualization of the distribution of these properties. We can see that there is a big difference in the distribution of brightness

![Figure 11.16 Difference in data distribution of brightness between train and test dataset.We can see the distribution of the test dataset has more variance than the train dataset.](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/11__image016.png)

Whereas there are no difference in distribution for area and aspect ratio

![Figure 11.17 No difference in data distribution for aspect ratio and area](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/11__image017.png)

For our object detection BentoML service, we need to store all the images being processed for inference, along with their predicted labels, in a bucket or database. We can then periodically calculate the drift score to check if there are any significant differences in the image properties we're observing in production compared to those on which we trained our model.

### 11.2.2 Movie Recommender

In our movie recommender project, we use a matrix factorization model trained on a user-item rating matrix. Once the model is deployed in production, frequent retraining is necessary to accommodate new users or items. However, it is also valuable to detect data drift in the ratings to observe potential shifts in user preferences or item popularity. This can be done by monitoring changes in the user and item factors. To illustrate this, we will take a subset of the MovieLens dataset, introduce drift in the item ratings, and then compare the distribution of user and item factors to see if the drift is detectable.

To introduce drift we will randomly increase the ratings of a few movies by 1 (while still ensuring they remain less than or equal to 5)

```
def introduce_item_drift(df, movie_ids, drift_amount=1):
    drift_indices = df['itemId'].isin(movie_ids)
    df.loc[drift_indices, 'rating'] = df.loc[drift_indices, 'rating'] + drift_amount
    df['rating'] = df['rating'].clip(1, 5)  # Clip ratings to stay within the 1-5 range
    return df
```

We will then generate two datasets one with drift and the other without drift. To generate a dataset with drift we simply need to pass a list of movie ids and the ratings dataframe

```
movie_ids = list(range(1, 101))
drfited_ratings = df['itemId'].isin(movie_ids)
```

After obtaining the dataset, we can retrieve the user and item factors by retraining the model on both the drifted and non-drifted versions. The embeddings can then be extracted directly from the model.

```
item_embedding_layer = model.item_factors.weight
item_embeddings = item_embedding_layer.detach().numpy()
user_embedding_layer = model.user_factors.weight
user_embeddings = user_embedding_layer.detach().numpy()
drifted_item_embedding_layer = model_with_drift.item_factors.weight
drifted_item_embeddings = drifted_item_embedding_layer.detach().numpy()
drifted_user_embedding_layer = model_with_drift.user_factors.weight
drifted_user_embeddings = drifted_user_embedding_layer.detach().numpy()
```

We can now verify the data for the movies whose ratings were modified by using Deepcheck’s `FeatureDrift` which as the name suggests helps one to track individual feature drift. We will transpose our matrix such that each column represents an item or user and then convert it to a pandas dataframe. This dataframe will then be wrapped by Deepcheck’s Dataset format.

```
df_item_factors_t1 = pd.DataFrame(item_embeddings.T, columns=[f'item_factor_{i}' for i in range(item_embeddings.shape[0])])
df_item_factors_t2 = pd.DataFrame(drifted_item_embeddings.T, columns=[f'item_factor_{i}' for i in range(drifted_item_embeddings.shape[0])])
from deepchecks.tabular import Dataset
dataset_item_factors_t1 = Dataset(df_item_factors_t1, label=None)
dataset_item_factors_t2 = Dataset(df_item_factors_t2, label=None)
```

We can then compute feature drift for one of the movies by running Deepcheck’s FeatureDrift

```
from deepchecks.tabular.checks import FeatureDrift
drift_check_item = FeatureDrift(columns=["item_factor_2"]).run(dataset_item_factors_t1, dataset_item_factors_t2)
drift_check_item.save_as_html()
```

We can then see that the distribution of the item latent factors has indeed drifted. Indicating that the user preferences for item/movie number 2 has changed over time.

![Figure 11.18 Differences in data distribution of item latent factors between training and test datasets](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/11__image018.png)

We can establish a monitoring pipeline to track latent factor distributions over time, providing valuable insights about item popularity and user preference.

Data drift monitoring is crucial for ensuring our model performance is consistent in production. By tracking shifts in data distributions over time, such as changes in feature values or target distributions, we can detect when the input data in production has changed significantly from the training data. Regular monitoring of data drift helps prevent model performance degradation, and ensures that models remain aligned with current real-world conditions.

In the next section, we will explore the concept of model explainability, which focuses on making machine learning models more transparent and interpretable. As models become more complex, particularly with techniques like deep learning and ensemble methods which may perform well but act like a black box, it becomes increasingly important to understand how predictions are made.

## 11.3 Explainability

Data science model explainability, also known as interpretable AI or explainable AI (XAI), is a crucial aspect of modern machine learning and artificial intelligence systems. It refers to the ability to understand and interpret the decisions and predictions made by complex models in a human-understandable way. This concept has gained significant importance in recent years due to the increasing complexity of models and their widespread adoption in critical decision-making processes across various industries.

From a technical standpoint, model explainability allows data scientists and engineers to debug, improve, and validate their models more effectively. It helps in identifying biases, understanding the model's strengths and weaknesses, and ensuring that the model is making decisions based on relevant features rather than spurious correlations. This level of insight is crucial for building robust, reliable, and fair AI systems.

From a business perspective, model explainability is essential for several reasons. Firstly, it builds trust among stakeholders, including customers, partners, and regulators. When businesses can explain how their AI systems make decisions, it increases confidence in the technology and its applications. Secondly, explainable models help in meeting regulatory requirements, particularly in highly regulated industries. Lastly, it aids in decision-making processes, allowing business leaders to understand the rationale behind AI-driven recommendations and make informed choices.

A prime example of the importance of model explainability is in the financial sector, particularly with credit risk models. These models are used to determine creditworthiness and make lending decisions, which have significant impacts on individuals and businesses. Regulatory frameworks such as the Equal Credit Opportunity Act (ECOA) in the United States require lenders to provide specific reasons for adverse actions, including credit denials. This necessitates a high degree of model explainability. For instance, if a credit application is denied, the financial institution must be able to explain which factors contributed to this decision, such as credit score, income level, or debt-to-income ratio. This transparency not only meets regulatory requirements but also helps in maintaining fairness and reducing discrimination in lending practices.

Model explainability can be categorized into two primary types: model-based and post hoc explainability. Model-based explainability refers to techniques that are inherently designed to provide insights into the decision-making processes of the model itself. These models, such as linear regression or decision trees, offer transparent structures that allow users to easily understand how input features influence predictions. On the other hand, post hoc explainability involves analyzing complex, often opaque models after they have been trained to extract interpretative insights. This approach utilizes methods like SHAP (Shapley Additive Explanations) and LIME (Local Interpretable Model-agnostic Explanations) to interpret model predictions by approximating the behavior of black-box models and providing explanations for individual predictions.

In the context of object detection systems, explainability is important for several reasons. First, it helps in understanding why certain objects are detected or missed, which is crucial for improving the model's performance and reliability. For example, in autonomous driving systems, it's vital to understand why the model might misclassify a pedestrian or fail to detect a traffic sign. This insight can lead to targeted improvements in the model or data collection process. Additionally, in applications like medical imaging for disease detection, explainability can help doctors understand and verify the model's findings, potentially leading to more accurate diagnoses and increased trust in AI-assisted medical practices.

For movie recommendation engines, explainability serves a different but equally important purpose. While these systems might not face the same regulatory scrutiny as credit risk models, explainability enhances user experience and engagement. When a recommendation system can explain why it suggested a particular movie (e.g., "Because 50 people similar to you rated this movie 5/5"), it provides context to the user, potentially increasing their trust in the recommendations. This transparency can lead to higher user satisfaction and more effective content discovery. From a business perspective, explainable recommendations can also provide valuable insights into user preferences and behaviors, informing content acquisition and production decisions.

Let us set up explainability for our object detection project.

### 11.3.1 Object Detection

In the field of computer vision, object detection models have become increasingly sophisticated, but their decision-making processes often remain opaque. This lack of transparency can be problematic, especially in critical applications where understanding why a model makes certain predictions is crucial. To address this, various explainability techniques have been developed, one of which is EigenCAM ( Class Activation Mapping using Principal Components).

EigenCAM is an extension of the Class Activation Mapping (CAM) family of techniques, specifically designed to provide visual explanations for convolutional neural network (CNN) decisions. Here's how it can be applied to object detection projects:

- **Highlighting Important Regions**: EigenCAM generates heatmaps that highlight the regions of an image that are most influential in the model's decision to detect and classify an object. These heatmaps overlay the original image, showing which areas the model focused on to make its prediction.
- **No Additional Training Require**d: Unlike some explainability methods, EigenCAM doesn't require modifying or retraining the model. It can be applied to existing, pre-trained object detection models, making it a versatile and practical tool.
- **Working with Complex Architectures**: EigenCAM is particularly useful for object detection models with complex architectures, as it can provide insights into the model's decision-making process without requiring access to intermediate feature maps.

By incorporating EigenCAM into an object detection project, developers and researchers can gain deeper insights into their models' behavior, leading to more robust, reliable, and trustworthy object detection systems. This explainability helps in technical improvements and builds confidence among users and stakeholders in the decision-making processes of object detection systems. For thr use case of detection of ID cards we can see if the model is focusing on the face of the ID card, if the face does not matter then we can generalize the model to ID cards that may not have faces!

We will use EigenCAM for our object detection model to generate a heatmap, enabling us to verify if the model is focusing on the ID card during classification. This can be achieved by utilizing the EigenCAM module available at[https://github.com/rigvedrs/YOLO-V8-CAM/tree/main](https://github.com/rigvedrs/YOLO-V8-CAM/tree/main). With this module and our model, we can build heatmaps for images observed during both training and inference, helping us assess what the model is focusing on and guiding decisions on model architecture or the need for retraining.

We load the model and identify the target layers, which typically hold highly abstract features and essential spatial information for predicting bounding boxes and class probabilities in object detection. We then initialize the EigenCam and specify the task as object detection. Afterward, we provide a list of images for which we want to generate heatmaps and plot them.

##### Listing 11.7 Running EigenCAM for generating heatmaps

```
import cv2
import numpy as np
import matplotlib.pyplot as plt
from ultralytics import YOLO
from yolo_cam.eigen_cam import EigenCAM
from yolo_cam.utils.image import show_cam_on_image
model = YOLO("../serving/yolov8_custom.pt")    #A
target_layers =[model.model.model[-2], model.model.model[-3], model.model.model[-4]]    #B
cam = EigenCAM(model, target_layers,task='od')    #C
img_list = ["CA01_06.tif","CA01_02.tif","CA01_30.tif"]
for i in img_list:
    img = cv2.imread(i)
    rgb_img = img.copy()
    img = np.float32(img) / 255
    grayscale_cam = cam(rgb_img)[0, :, :]
    
    cam_image = show_cam_on_image(img, grayscale_cam, use_rgb=True)
    plt.imshow(cam_image)    #D
    plt.show()
```

We can see that the model is correctly focusing on the ID card as intended, while also paying attention to the corners of the image.

![Figure 11.19 EigenCam heatmap visualizing the region of the image that contributes most to model’s decision making](https://drek4537l1klr.cloudfront.net/tanweihao2/v-5/Figures/11__image019.png)

We can run this process periodically to ensure that our model is correctly focusing on the intended objects within the images. Additionally, this approach can be utilized when retraining the model to verify that the model continues to accurately target the relevant objects.

### 11.3.2 Movie Recommendation

For the movie recommender project, we will use a model-based approach for explainability. We will train an explainable matrix factorization (EMF) model on a subset of data to demonstrate explainability. An EMF model’s explanation is based on identifying similar users and/or items in latent space. The explainability is computed based on rating distribution within the user and item neighborhood. We calculate an explainability score which is derived by dividing the number of similar users who have rated an item by all users who have rated an item. This score is then used as weights in the training algorithm with the idea being that if an item is explainable for a user then their representations in the latent space should be close to each other.

To train our EMF model, we will use the movie lens 100k dataset. We will first initialize the EMFModel and fit it on the training data. We will then wrap the model in a Recommender object and build an EMFExplainer which can then be used to explain the recommendations. The code for EMFModel, EMFExplainer, and Recommender can be found in the repository for movie-recommender.

##### Listing 11.8 Explainable Matrix Factorization model

```
emf = EMFModel(learning_rate=0.01,reg_term=0.001,expl_reg_term=0.0,latent_dim=80,epochs=10,positive_threshold=3,knn=10)    #A
emf.fit(train)
recommender = Recommender(train, emf)    #B
recommendations = recommender.recommend_all()
explanations = EMFExplainer(emf, recommendations, data)
recommendations_with_explainations = explanations.explain_recommendations()    #C
```

The `recommendations_with_explanations` have each user's top ten recommendations along with an explainability column. The explainability column consists of explanations that are a dictionary which indicate a {rating: number of similar users who gave the rating}. The explainability column can be empty for some explanations that can be caused by no similar users for certain users. For example, the ranked recommendations and explainability for user 1 are given below. We can see the top-ranked recommendation does not have an explanation. The third-ranked movie explanation can be interpreted as follows, “Out of 9 similar users who rated this movie, 8 gave it a rating of 4 or higher”. This can give the user and business higher confidence in the model prediction.

| <br>      <br>       <br>       <br>           <br>        <br>       <br> | <br>      <br>      <br>        userId <br>       <br> | <br>      <br>      <br>        itemId <br>       <br> | <br>      <br>      <br>        rank <br>       <br> | <br>      <br>      <br>        explanations <br>       <br> |
| --- | --- | --- | --- | --- |
| <br>     <br>       1176 <br> | <br>     <br>       2.0 <br> | <br>     <br>       1450.0 <br> | <br>     <br>       1.0 <br> | <br>     <br>       {} <br> |
| <br>     <br>       12 <br> | <br>     <br>       2.0 <br> | <br>     <br>       286.0 <br> | <br>     <br>       2.0 <br> | <br>     <br>       {5: 1} <br> |
| <br>     <br>       201 <br> | <br>     <br>       2.0 <br> | <br>     <br>       475.0 <br> | <br>     <br>       3.0 <br> | <br>     <br>       {3: 1, 4: 4, 5: 4} <br> |
| <br>     <br>       135 <br> | <br>     <br>       2.0 <br> | <br>     <br>       409.0 <br> | <br>     <br>       4.0 <br> | <br>     <br>       {4: 2, 5: 4} <br> |
| <br>     <br>       1094 <br> | <br>     <br>       2.0 <br> | <br>     <br>       1368.0 <br> | <br>     <br>       5.0 <br> | <br>     <br>       {} <br> |
| <br>     <br>       238 <br> | <br>     <br>       2.0 <br> | <br>     <br>       512.0 <br> | <br>     <br>       6.0 <br> | <br>     <br>       {4: 2, 5: 2} <br> |
| <br>     <br>       384 <br> | <br>     <br>       2.0 <br> | <br>     <br>       658.0 <br> | <br>     <br>       7.0 <br> | <br>     <br>       {} <br> |
| <br>     <br>       29 <br> | <br>     <br>       2.0 <br> | <br>     <br>       303.0 <br> | <br>     <br>       8.0 <br> | <br>     <br>       {4: 1, 5: 2} <br> |
| <br>     <br>       374 <br> | <br>     <br>       2.0 <br> | <br>     <br>       648.0 <br> | <br>     <br>       9.0 <br> | <br>     <br>       {4: 1} <br> |
| <br>     <br>       210 <br> | <br>     <br>       2.0 <br> | <br>     <br>       484.0 <br> | <br>     <br>       10.0 <br> | <br>     <br>       {5: 6} <br> |

Model explainability helps make complex AI systems understandable to humans. It's important in many areas: it ensures financial models meet regulations, makes object detection systems safer and more reliable, and improves user experience in recommendation engines. By making AI decisions clearer, explainability is key to using AI responsibly and effectively in different fields.

## 11.4 Looking Back, Moving Forward!

Building and deploying machine learning models is hard. Throughout this book, we’ve tackled this complexity head-on, equipping you with the practical skills and knowledge to navigate the intricate world of MLOps. From understanding the ML lifecycle to building a robust ML platform and deploying real-world ML systems, we’ve covered a lot of ground. Let’s take a moment to recap the key takeaways and celebrate how far you’ve come.

We began by demystifying the often-confusing landscape of MLOps and ML Engineering. We explored the iterative nature of the ML lifecycle, from problem formulation and data collection to model deployment, monitoring, and retraining. We also highlighted the unique challenges of MLOps, emphasizing the need for a diverse skillset encompassing software engineering, data science, and DevOps principles.

Next, we embarked on the exciting journey of building an ML platform from scratch. We chose Kubernetes as our foundation, recognizing its power and flexibility in managing containerized applications. We then introduced Kubeflow, a powerful ML platform built on Kubernetes, and walked you through setting up Kubeflow Pipelines for orchestrating your ML workflows. We extended our platform with essential components like a feature store (Feast) and a model registry (MLflow), emphasizing the importance of data versioning, experiment tracking, and model management.

With our platform in place, we dived into building two real-world ML systems: an OCR system for detecting identity cards and a movie recommender system. These projects allowed us to apply the concepts we learned in a practical setting. We explored data analysis and preparation techniques, including data versioning, splitting datasets, and handling different data formats (images and tabular data). We trained models using popular frameworks like YOLOv8 and PyTorch, emphasizing the importance of selecting the right model architecture and tuning hyperparameters. We also covered model evaluation, validation, and deployment, highlighting best practices for ensuring model performance and reliability in production.

We then tackled the critical aspect of monitoring and explainability. We set up monitoring and logging for our ML applications, using tools like Prometheus and Grafana. We also discussed the importance of detecting data drift and demonstrated how to use tools like Evidently and Deepchecks to identify and address drift. Finally, we explored model explainability techniques like EigenCAM and EMF, emphasizing the need for transparency and interpretability in ML systems.

As we wrap up the book, the advances in LLMs (Large Language Models) show no signs of slowing down. While we have used the more "classical" models in this book, the skills learned in this book remain highly relevant and transferable to other domains in machine learning.

While LLMs have made significant strides in understanding and generating human language, they are still limited in their ability to reason and draw conclusions from complex data. The skills covered in this book, such as feature engineering, model selection, and hyperparameter tuning, are essential for building robust and interpretable models that can handle real-world problems.

Additionally, LLMs often require large amounts of data and computational resources, making them impractical for many applications. The skills learned in this book can help you develop more efficient and scalable models that can be deployed in production. Monitoring LLM apps for things like hallucination, following policy, bias mitigation, and user privacy is crucial to ensure responsible AI development and deployment.

Thank you so much for joining us on this adventure. We hope this book has empowered you to build, deploy, and manage your own successful ML systems. Now go forth and create amazing things!

## 11.5 Summary

- Monitoring ML applications is crucial for maintaining service reliability and performance. Basic monitoring involves tracking resource utilization and request metrics, which can be visualized using pre-built dashboards like those provided by BentoML.
- Custom metrics allow for tracking application-specific details, such as confidence scores in object detection or ranked movie counts in recommender systems. These custom metrics can be integrated into monitoring dashboards for better insights.
- Logging provides valuable context and detailed information for debugging and troubleshooting. Centralizing logs using tools like Loki enhances observability and facilitates efficient log analysis.
- Alerting is essential for proactive incident management. Setting up alert rules based on monitored metrics and logs, and using Alertmanager for routing notifications, ensures timely responses to critical issues.
- Data drift monitoring is important for maintaining model accuracy. Deepchecks provides tools to detect drift in various data types, including images and embeddings. Regularly monitoring for drift helps prevent model performance degradation.
- Model explainability is crucial for building trust and understanding AI decisions. Techniques like EigenCAM for object detection and model-based approaches for recommender systems provide insights into how models make predictions. Explainability enhances transparency and accountability in ML systems.
