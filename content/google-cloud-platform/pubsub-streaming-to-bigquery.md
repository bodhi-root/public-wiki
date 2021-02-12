---
title: PubSub Streaming to BigQuery
---

One design pattern we are trying to build is an event stream published to PubSub that is then streamed into BigQuery.  Several methods exist for reading from PubSub and writing to BigQuery:

| Method | Description | Pros | Cons |
|--------|-------------|------|------|
| Cloud Functions | A NodeJS function that would be invoked each time a new message arrives in the PubSub topic. This would insert a row into BigQuery. (Recommended by our Google rep. [Link to code](https://github.com/kevensen/professional-services/tree/simple-pipeline/examples/simple-pipeline/cloud_function)) | Relatively simple. | Bruce pointed out that this is a table load operation and would limit us to 10,000 inserts per table/day. |
| Dataflow | Streaming Dataflow pipeline (written in Java) (Recommended by the book "Data Science on the Google Cloud Platform".) | | |
| GKE	|Docker pod deployed through Kubernetes to read from PubSub and write to BigQuery. Program can be simple Python.
(Recommended by the Google tutorial at: [Link to code](https://github.com/GoogleCloudPlatform/kubernetes-bigquery-python/tree/master/pubsub)) | Kubernetes would let us scale the streaming code to as many nodes as needed. Also manages deployment and can auto-restart nodes as needed. | Kubernetes is kind of a pain. |
| GCE | Deploy a program on Compute Engine that reads from PubSub and writes to BigQuery. Program can be simple Python.	Simple. | Harder to monitor/support than Kubernetes. |

## Google Tutorial using GKE

Google has a tutorial for accomplishing this using GKE:

* https://github.com/GoogleCloudPlatform/kubernetes-bigquery-python/tree/master/pubsub

While most of the steps in this tutorial were relatively straight-forward, I did run into problems when I tried to modify the code to listen for new keywords.  First, I had never compiled docker images before.  This quick start guide was very helpful in walking me through the process of building the image and pushing it to Google's container repository.  The commands to do this were:

```
docker build -t pubsub-bq-pipe .
docker tag pubsub-bq-pipe gcr.io/futurestats-grocery/pubsub-bq-pipe:v1
docker push gcr.io/futurestats-grocery/pubsub-bq-pipe:v1
```

When I deployed this to Kubernetes I ran into a problem with the pods crashing though.  I learned how to view a pods logs with:

```
kubectl logs bigquery-controller-8679747dfc-dgpjk
```

and then saw this error:

```
Traceback (most recent call last):
  File "pubsub-to-bigquery.py", line 25, in <module>
    import utils
  File "/utils.py", line 27, in <module>
    from oauth2client.client import GoogleCredentials
ImportError: No module named oauth2client.client
```

For some reason the Dockerfile was not including this necessary dependency.  I found some help online and modified the Dockerfile to include a line to install and upgrade oauth2client.  My Dockerfile then looked like this:

```
Dockerfile
FROM python:2

RUN pip install --upgrade pip
RUN pip install tweepy
RUN pip install --upgrade oauth2client
RUN pip install --upgrade google-api-python-client
RUN pip install python-dateutil

ADD twitter-to-pubsub.py /twitter-to-pubsub.py
ADD pubsub-to-bigquery.py /pubsub-to-bigquery.py
ADD controller.py /controller.py
ADD utils.py /utils.py

CMD python controller.py
```

Re-building the image, pushing to GCR, and re-deploying to Kubernetes was not fixing the problem though.  I kept getting the same error message each time.  Finally, I realized I had to upgrade the image tag to "v2".  Then I had to modify my Kubernetes deployment descriptors to point to this, and then everything worked.

WARNING: It seems that Kubernetes is using some kind of image cache that wasn't recognizing changes when I kept the same version tag. I could see in GCR that I had pushed a new image with the old tag. I could even see the old image, and I deleted it so that it wouldn't be pulling it by mistake. But it was somehow still deploying the old image. Not until I changed the tag to "v2" did everything work out.

### Final Code Files

For reference, here are the files I finally got working.  The twitter-to-pubsub.py script was modified to change the filter:

___FILE: twitter-to-pubsub.py (snippet)___

```
if os.environ['TWSTREAMMODE'] == 'sample':
    stream.sample()
else:
    stream.filter(
       track=['kroger','publix','costco','heb','walmart','meijer','aldi','lidl','whole foods','hyvee','wegmans','grocery','groceries']
    )
```

Note that if the environmental variable "TWSTREAMMODE" is "sample" that this code will never be invoked.  That was something else I missed the first time.

___FILE: bigquery-controller.yaml___

```
bigquery-controller.yaml
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: bigquery-controller
  labels:
    name: bigquery-controller
spec:
  replicas: 2
  template:
    metadata:
      labels:
        name: bigquery-controller
    spec:
      containers:
      - name: bigquery
        image: gcr.io/futurestats-grocery/pubsub-bq-pipe:v2
        env:
        - name: PROCESSINGSCRIPT
          value: pubsub-to-bigquery
        - name: PUBSUB_TOPIC
          value: projects/futurestats-grocery/topics/twitter_stream
        - name: PROJECT_ID
          value: futurestats-grocery
        - name: BQ_DATASET
          value: twitter_stream
        - name: BQ_TABLE
          value: tweets
```

___FILE: twitter-stream.yaml___

```
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: twitter-stream
  labels:
    name: twitter-stream
spec:
  replicas: 1
  template:
    metadata:
      labels:
        name: twitter-stream
    spec:
      containers:
      - name: twitter-to-pubsub
        image: gcr.io/futurestats-grocery/pubsub-bq-pipe:v2
        env:
        - name: PROCESSINGSCRIPT
          value: twitter-to-pubsub
        - name: PUBSUB_TOPIC
          value: projects/futurestats-grocery/topics/twitter_stream
        - name: CONSUMERKEY
          value: your_info_here
        - name: CONSUMERSECRET
          value: your_info_here
        - name: ACCESSTOKEN
          value: your_info_here
        - name: ACCESSTOKENSEC
          value: your_info_here
        - name: TWSTREAMMODE
          value: prod
```

Note that the last variable, "TWSTREAMMODE" was set to "prod".  Really, anything other than "sample" with work here.  You will also need to insert your own Twitter app credentials, of course.

Unfortunately, I wasn't able to put this code into source control.  I don't want my Twitter credentials to be stored there.  [This page](https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/) has a good example of how to secretly and securely set environment variables, but that will have to be an exercise for another day.

### GCP Costs

I left this running until 2/21 (7 days) and ran up a bill of $26.05.  It looked like it was charging about $4 per day.  The primary costs were for compute.  Details below:

![Cost Screenshot](assets/gcp-costs-pubsub-to-bigquery.png)

In total this collected 892,298 tweets.

## Python Code on Docker

In trying to replicate the Google tutorial for my own project, I ran into several problems.  First, the Python API client for Google cloud is not installed on VMs by default.  I couldn't figure out how to install it either since pip is missing, my VMs seem to be fire-walled off from the internet, and they seem to be firewall-ed off from my company's artifactory (which is needing to install Linux modules and Python modules the correct way).  I thought about building docker images on my desktop, uploading them to the cloud, and then running them there, but that's a pretty complicated code/test cycle.  Instead, I just created a sandbox project, logged directly into the VM, and was able to use the full power of the cloud and the internet directly.  Here are my notes.

### Install Python Libraries

This can be done with:

```
sudo apt update
sudo apt install python3-pip
sudo python3 -m pip install --upgrade google-cloud-pubsub
sudo python3 -m pip install --upgrade google-cloud-bigquery
sudo python3 -m pip install --upgrade oauth2client
```

This allows us to perform the following imports:

```
from google.cloud import pubsub_v1
from google.cloud import bigquery
from oauth2client.client import GoogleCredentials
```

In order to see what specific versions of these modules installed, I used:

```
sudo python3 -m pip freeze
```

This provided the following key information:

```
google-cloud-pubsub==0.39.1
google-cloud-bigquery==1.10.0
oauth2client==4.1.3
```

About 20 other dependencies were also shown, but I'm assuming if we put these key dependencies into a "requirements.txt" file, they will automatically pull in all the rest.

### BigQuery Setup

BigQuery can be setup if we have a JSON file that describes the desired schema.  In this case I created "my-schema.json" and then used the following to create a dataset named "dataset" and a table named "table":

```
bq mk dataset
bq mk -t dataset.table my-schema.json
```

### Python Scripts

The Python scripts weren't too hard to write once the environment was setup.  To make things easy, I wrote them on my desktop and then uploaded them to the VM.  I ended up with the following files:

```
pubsub-test.py         # simple listener that listens to PubSub and prints message as they arrive
file-to-pubsub.py      # generate sample data and push to PubSub
pubsub-to-bigquery.py  # program that listens to PubSub and pushes messages to BigQuery
```

These scripts still need some work to be production-ready, but in order to keep from having to read through all the crazy GCP documentation again, here they are:

___File: pubsub-test.py___

```
import time
from google.cloud import pubsub_v1

PROJECT_ID = "gcp_project_id"
SUBSCRIPTION_NAME = "pubsub_subscription_name"

subscriber = pubsub_v1.SubscriberClient()

subscription_path = subscriber.subscription_path(PROJECT_ID, SUBSCRIPTION_NAME)

def callback(message):
    print('Received message: {}'.format(message))
    message.ack()

subscriber.subscribe(subscription_path, callback=callback)

print('Listening for messages on {}'.format(subscription_path))
while True:
    time.sleep(60)
```

___File: file-to-pubsub.py___

```
import random
import datetime
import time
from google.cloud import pubsub_v1

PROJECT_ID = "gcp_project_id"
TOPIC_NAME = "topic_name"

### Load XML messages into memory

sample_file = "data/sample/sensor-xml.log"
print("Reading file: {}".format(sample_file))

xml_lines = []
with open(sample_file, "r") as file_in:
    for line in file_in:
        xml_lines.append(line)

print("Loaded {} sample messages into memory".format(len(xml_lines)))

### Randomly send message to PubSub

publisher = pubsub_v1.PublisherClient()
FULL_TOPIC_NAME = 'projects/{project_id}/topics/{topic}'.format(
    project_id=PROJECT_ID,
    topic=TOPIC_NAME
)

while True:
    xml_line = random.choice(xml_lines)
    message_bytes = xml_line.encode() # default to utf-8

    print("Writing message at {}".format(datetime.datetime.now()))
    publisher.publish(FULL_TOPIC_NAME, message_bytes)  

    time.sleep(5) # sleep 5 seconds
```

___File: pubsub-to-bigquery.py___

```
import time
from google.cloud import pubsub_v1
from google.cloud import bigquery
from seventyfive.SensorEvent import SensorEvent

PROJECT_ID = "gcp_project_id"
SUBSCRIPTION_NAME = "pubsub_subscription_name"

BQ_DATASET_ID = 'dataset'
BQ_TABLE_NAME = 'table'

subscriber = pubsub_v1.SubscriberClient()

bq_client = bigquery.Client()
bq_table = bq_client.get_table(bq_client.dataset(BQ_DATASET_ID).table(BQ_TABLE_NAME))

subscription_path = subscriber.subscription_path(PROJECT_ID, SUBSCRIPTION_NAME)

def callback(message):
    print('Received message: {}'.format(message))

    xml = message.data.decode()
    sensor_event = SensorEvent.parse_xml(xml)

    bq_rows = sensor_event.to_bq_rows()
    errors = bq_client.insert_rows(bq_table, bq_rows)
    print("Errors: ".format(errors))

    message.ack()

subscriber.subscribe(subscription_path, callback=callback)

print('Listening for messages on {}'.format(subscription_path))
while True:
    time.sleep(60)
```

Nothing too tricky here.  The work to parse the SensorEvent XML file is encapsulated in the SensorEvent object.  The code that generates rows to insert into BigQuery is also in that object.  These rows are simply dictionaries of key/value pairs for the column names and values we are inserting.  These scripts need some more error handling and then I'll put them in git.  We also need to bundle them up and build them into a docker image, but that will be work for another day.

### Writing to PubSub from On-Prem

The code above writes to PubSub from a GCE instance.  If we want to test writing messages from on-prem (which is what the ESB team will have to do in order to publish to our GCP PubSub topic), we need to make a few small changes.  First, we generate a service account and save it's token to a JSON file.  This service account should have permission to publish to PubSub.  Then we modify our Python code that instantiates the client to use this service account file:

```
publisher = pubsub_v1.PublisherClient.from_service_account_file("service-account-file.json")
```

You will also need to use the Proxy to connect to GCP.  This can be set through an environmental variable.  If you do it in Python (which is not recommended) it looks like this:

```
os.environ["https_proxy"] = "http://user:pass@proxy.domain.com:8888/"
```

### Deploying as a Docker Container

WARNING: I can get this to work in the sandbox but not in our corporate project. For some reason, the default application credentials in the corporate project do not appear to have access to the BigQuery APIs.

I tried deploying this app as a docker container using the following Dockerfile:

___File: Dockerfile___

```
FROM python:3.7.2-slim-stretch

WORKDIR /usr/src/app

# Add files to the image, placing them in WORKDIR
COPY requirements.txt ./

# Install python packages
RUN set -x \
    && pip install --upgrade pip \
    && pip install --no-cache -r requirements.txt

COPY pubsub-to-bigquery.py ./
COPY seventyfive ./seventyfive

CMD python3 ./pubsub-to-bigquery.py
```

This uses the slim version of the python 3.7.2 image (as Marcus had recommended).  Python dependencies are then loaded from the requirements.txt file which uses the version info of the dependencies we manually installed earlier:

___File: requirements.txt___

```
google-cloud-pubsub==0.39.1
google-cloud-bigquery==1.10.0
oauth2client==4.1.3
```

It then runs the "pubsub-to-bigquery.py" program.

I am able to build the image locally using:

```
docker build -t baler-sensor-pubsub:1.0-SNAPSHOT .

gcloud auth configure-docker
docker tag my-image:1.0-SNAPSHOT gcr.io/my-image:1.0-SNAPSHOT
docker push gcr.io/my-image:1.0-SNAPSHOT
```

I can then login to the GCE instance (which is using the container-optimized OS), download, and run this image with:

```
docker-credential-gcr configure-docker
docker pull gcr.io/my-image:1.0-SNAPSHOT
docker run --rm gcr.io/my-image:1.0-SNAPSHOT
```

However, I'm running into the following errors:

```
google.api_core.exceptions.Forbidden: 403 GET https://www.googleapis.com/bigquery/v2/projects/<project>/datasets/<dataset>/tables/<table>: Request had insufficient authentication scopes.
```

I was able to run this successfully in my sandbox project.  It's the exact same docker image, but it fails in our corporate dev project.  It looks like our GCE instance does not have the required access to the BigQuery APIs.
